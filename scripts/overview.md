# KDB-X DB Service — Architecture Overview

The DB Service is a distributed, fault-tolerant time-series database built on
KX technology. It separates ingest, storage, and query workloads so each layer
can scale independently. Clients connect via REST, q/IPC, or Python.

References:
- [KDB-X DB Service](https://code.kx.com/kdb-x/services/db-service/introduction.html)
- [kdb Insights microservices](https://code.kx.com/insights/1.18/microservices/index.html)

---

## Services

### RT — Reliable Transport (`kx-db-rt`)

The ingest backbone. RT is a high-performance, log-based message bus built on
the Raft consensus algorithm. Publishers write to local session directories
asynchronously; RT replicates those logs across cluster nodes, merges them into
a single ordered stream, and delivers them to subscribers (primarily SM).

Because publishers and subscribers are fully decoupled, slow subscribers cannot
stall ingest. The Archiver garbage-collects merged logs according to configurable
time, size, or disk-space retention policies.

Key processes: `run-raft-seq.q` (Raft sequencer), `seq.q` (sequencer), `archiver.q`,
`rest.q`, plus `pull_server_static`, `push_server_static`, and `rt_sub_server`
replicator binaries.

Listens on: qIPC 6001 (sequencer), qIPC 4000 (seq), qIPC 4998 (archiver),
qIPC/REST 6000 (rest), TCP 5001/5002/5003 (replicators).

---

### SM — Storage Manager (`kx-db-sm`)

The write tier. SM subscribes to RT and distributes inbound data across three
in-process storage tiers:

| Tier | Process arg | Description |
|------|-------------|-------------|
| RDB  | `-app eoi`  | In-memory real-time data; holds the current intraday partition |
| IDB  | `-app eod`  | Intraday persistence; data written down from RDB at end-of-interval |
| HDB  | `-app dbm`  | Historical on-disk store; receives end-of-day write-downs |

Each tier runs as an independent `mainSingle.q` process. Data migrates
automatically from RDB → IDB → HDB while remaining queryable throughout
transitions. SM also handles schema management and batch ingest operations.

Pull/push replicator clients connect SM to RT for log delivery.

Listens on: qIPC 20001 (startq), qIPC 20002/20003/20004 (RDB/IDB/HDB apps).

---

### DA — Data Access (`kx-db-da`)

The query tier. DA exposes the three storage tiers to the gateway layer through
independent worker processes, one per tier:

| Worker | Mount | Port |
|--------|-------|------|
| `worker.q` | `rdb` | qIPC 5081 |
| `worker.q` | `idb` | qIPC 5082 |
| `worker.q` | `hdb` | qIPC 5083 |

Workers are supervised by `startq.q` and communicate with SM for schema
information. The gateway routes queries to the appropriate worker(s) based on
the time range requested. DA supports horizontal scaling through replicated
worker nodes. A pull replicator client receives real-time data from RT.

Listens on: qIPC 5080 (startq supervisor), qIPC 5081/5082/5083 (workers).

---

### RC — Resource Coordinator (`kx-db-rc`)

The query router. RC receives forwarded API requests from GW, breaks them
into partials, and distributes each partial to the DA worker(s) whose purview
covers the requested data. Routing decisions are based on:

- **Purview** — which time ranges and partitions each DA worker can serve
- **Tier and label matching** — filtering workers by assembly, package, and
  tier (rdb/idb/hdb) specified in the query
- **Time-interval allocation** — iteratively assigning outstanding time ranges
  to the most suitable workers; unassignable ranges are queued until a
  qualifying worker registers or becomes available

DA workers respond asynchronously via q/IPC and forward their results to the
designated AGG instance, which returns the merged response to GW. RC monitors
connection health via configurable heartbeat probes and warns when critical
connections (DA workers or AGG) disconnect.

RC is intentionally lightweight — a single `startq.q` process with no child
workers.

Listens on: qIPC 5050.

---

### AGG — Aggregator (`kx-db-agg`)

The fan-out executor. When a query spans multiple tiers or replicas, the
Gateway delegates to AGG, which dispatches sub-queries in parallel, collects
partial results, and merges them into a single response before returning to
the Gateway.

Like RC, AGG is a single `startq.q` process.

Listens on: qIPC 5060 (host-mapped to 15060; 5060 is blocked by Chrome).

---

### GW — Service Gateway (`kx-db-gw`)

The client-facing entry point. GW is a Java service (not a q process) that
accepts queries over q/IPC (port 5040) and HTTP/REST (port 8080). For each
request it:

1. Consults RC to find available workers for the requested data range
2. Routes single-tier queries directly to DA workers
3. Delegates cross-tier or multi-replica queries to AGG
4. Returns the unified result to the client

GW supports SQL, QSQL, and metadata queries, and enforces request queuing and
load balancing across replicas.

Listens on: TCP 5040 (q/IPC), HTTP 8080.

---

## Data Flow

```
External data
     │
     ▼
  RT (ingest & sequencing)
     │  replication log
     ▼
  SM (storage: RDB → IDB → HDB)
     │  schema / data
     ▼
  DA workers (rdb / idb / hdb)
     ▲
     │  query routing
  RC ──── GW ◄── client (REST / qIPC)
     │
  AGG (fan-out for multi-tier queries)
```
