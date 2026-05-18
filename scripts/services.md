# Service Process Hierarchies and Ports

---

## RT — kx-db-rt

```
q startq.q
        -p 6000 -in /s/in -out /s/out -cp /s/state -size 1
└── q run-raft-seq.q                                      qIPC  6001
        -in /s/in -out /s/out -cp /s/state -size 1 -limit  -time  -disk  -p 6000
    ├── q seq.q                                           qIPC  4000  |  TCP  7100 (raft)  |  UDP  7000 (raftUdp)  9000 (seqUdp)
    │       -q -p 4000 -raftSelf 0 -cp /s/state -in /s/in -out /s/out
    │       -raftPort 7100 -raftUdp 7000 -watchUdp 8000 -seqUdp 9000
    │       -raftPeerEndpoints rt-data-0:7100 -raftCmdLog /s/state/raft_log
    │   └── q watch.q                                     UDP  8000 (watchUdp)
    │           -raftSelf 0 -cp /s/state -in /s/in -out /s/out
    │           -raftPort 7100 -raftUdp 7000 -watchUdp 8000 -seqUdp 9000
    │           -raftPeerEndpoints rt-data-0:7100 -raftCmdLog /s/state/raft_log
    ├── pull_server_static                                TCP  5001
    │       --logging-level-file NONE --logging-level-console INFO
    │       --endpoint 0:5001 --base-dir /s/out/OUT --truncate-archived 1
    │       --errors-on-stdout 1 --ignore-inconsistent 1 --fw-drain-interval 5
    │       --ignore-prefix . --server-name int-pull#rt-data-0
    │       --diagnostics-file /s/state/replicator/diag.new.int-pull.json
    │       --inactive-timeout 24 --rest-client-port 6000 --renice 5 --delete-files 1
    ├── push_server_static                                TCP  5002
    │       --logging-level-file NONE --logging-level-console INFO
    │       --endpoint 0:5002 --base-dir /s/in --errors-on-stdout 1
    │       --server-name int-push#rt-data-0
    │       --diagnostics-file /s/state/replicator/diag.new.int-push.json
    │       --inactive-timeout 24 --rest-client-port 6000 --renice 5 --delete-files 1
    ├── rt_sub_server                                     TCP  5003
    │       --source-dir /s/out/OUT --logging-level-console INFO
    │       --host 0.0.0.0 --suppress-fw-warnings 1 --ignore-prefix . --errors-on-stdout 1
    │       --renice 5 --inactive-timeout 24 --header-cache-size 5000
    │       --header-cache-stats-interval 0 --header-cache-purge-interval 1000
    │       --payload-cache-size 250 --payload-cache-stats-interval 0
    │       --payload-cache-purge-interval 100 --server-name int-sub#rt-data-0
    │       --port 5003 --diagnostics-file /s/state/replicator/diag.new.int-sub.json
    ├── q archiver.q                                      qIPC  4998
    │       -p 4998 -in /s/in -out /s/out -cp /s/state -limit  -time  -disk
    └── q rest.q                                          qIPC  6000
            -p 6000 -in /s/in -out /s/out -cp /s/state
            -raft-srv rt-data- -seq-tcp-port 4000 -sup-adm-port 6001
            -rest-tcp-port 6000 -self 0 -size 1
```

---

## SM — kx-db-sm

```
q startq.q                                                qIPC  20001
├── q src/sm/mainSingle.q                                 qIPC  20002
│       -s 0 -app eoi
│   └── pull_client_static
│           --endpoint rt-data-0:5001 --logging-level-console WARN
│           --logging-level-file NONE --errors-on-stdout 1
│           --truncate-archived 1 --delete-files 0
│           --target-dir /logs/rt/eoi/data --use-ssl 0
│           --reparent-check 10 --connect-timeout 300
│           --client-name 11c27fc95b69 --start-point log.0.0
│           --renice 5 --exchange-archived 0
├── q src/sm/mainSingle.q                                 qIPC  20003
│       -s 0 -app eod
├── q src/sm/mainSingle.q                                 qIPC  20004
│       -s 0 -app dbm
├── push_client_static
│       --endpoint rt-data-0:5002 --logging-level-console WARN
│       --logging-level-file NONE --errors-on-stdout 1
│       --truncate-archived 1 --delete-files 0 --use-ssl 0
│       --connect-timeout 300 --ignore-prefix . --exit-on-inconsistent 1
│       --reparent-check 10 --fw-drain-interval 0
│       --client-name 11c27fc95b69 --renice 5
│       --server-sub-dir 11c27fc95b69.data
│       --source-dir /logs/rt/sm/11c27fc95b69.data
├── push_client_static
│       [common args as above]
│       --server-sub-dir 11c27fc95b69.sm-batchIngest
│       --source-dir /logs/rt/sm/11c27fc95b69.sm-batchIngest
├── push_client_static
│       [common args as above]
│       --server-sub-dir 11c27fc95b69.sm-batchDelete
│       --source-dir /logs/rt/sm/11c27fc95b69.sm-batchDelete
├── push_client_static
│       [common args as above]
│       --server-sub-dir 11c27fc95b69.sm-schemaChange
│       --source-dir /logs/rt/sm/11c27fc95b69.sm-schemaChange
├── push_client_static
│       [common args as above]
│       --server-sub-dir 11c27fc95b69.sm-prtnend-eoi.dedup
│       --source-dir /logs/rt/sm/11c27fc95b69.sm-prtnend-eoi.dedup
└── push_client_static
        [common args as above]
        --server-sub-dir 11c27fc95b69.sm-prtnend-eod.dedup
        --source-dir /logs/rt/sm/11c27fc95b69.sm-prtnend-eod.dedup
```

---

## DA — kx-db-da

```
q startq.q                                                qIPC  5080
├── q src/da/dap/worker.q                                 qIPC  5081
│       -s 0 -port 5081 -supervisor 5080 -mount rdb -disable 0 -rtprotocol
│   └── push_client_static
│           --endpoint rt-data-0:5002 --logging-level-console WARN
│           --logging-level-file NONE --errors-on-stdout 1
│           --truncate-archived 1 --delete-files 0 --use-ssl 0
│           --connect-timeout 300 --ignore-prefix . --exit-on-inconsistent 1
│           --reparent-check 10 --fw-drain-interval 0
│           --client-name e835c3070ec6 --renice 5
│           --server-sub-dir e835c3070ec6,rdbdata
│           --source-dir /logs/dae835c3070ec6/_pub_rdb/e835c3070ec6,rdbdata
├── q src/da/dap/worker.q                                 qIPC  5082
│       -s 0 -port 5082 -supervisor 5080 -mount idb -disable 0 -rtprotocol
│   └── push_client_static
│           [common args as above]
│           --server-sub-dir e835c3070ec6,idbdata
│           --source-dir /logs/dae835c3070ec6/_pub_idb/e835c3070ec6,idbdata
├── q src/da/dap/worker.q                                 qIPC  5083
│       -s 0 -port 5083 -supervisor 5080 -mount hdb -disable 0 -rtprotocol
│   └── push_client_static
│           [common args as above]
│           --server-sub-dir e835c3070ec6,hdbdata
│           --source-dir /logs/dae835c3070ec6/_pub_hdb/e835c3070ec6,hdbdata
└── pull_client_static
        --endpoint rt-data-0:5001 --logging-level-console WARN
        --logging-level-file NONE --errors-on-stdout 1
        --truncate-archived 1 --delete-files 0
        --target-dir /logs/dae835c3070ec6/data --use-ssl 0
        --reparent-check 10 --connect-timeout 300
        --client-name e835c3070ec6 --start-point log.0.0
        --renice 5 --exchange-archived 0
```

---

## RC — kx-db-rc

```
q startq.q                                                qIPC  5050
```

---

## AGG — kx-db-agg

```
q startq.q                                                qIPC  5060
```

---

## GW — kx-db-gw

```
java                                                      TCP  5040  |  HTTP  8080
        -Djdk.nio.maxCachedBufferSize=65536
        -Dio.netty.allocator.type=unpooled
        --add-opens java.base/jdk.internal.misc=ALL-UNNAMED
        -Dio.netty.tryReflectionSetAccessible=true
        -Dlogback.configurationFile=logback.xml
        --illegal-access=permit
        -jar kxi-service-gateway-0.1.0-beta.1-jar-with-dependencies.jar
```
