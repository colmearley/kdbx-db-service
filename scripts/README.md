# Local Docker Images

Each service has a `Dockerfile` under `images/<service>/` that extends the base KX image with:

- `net-tools`, `lsof`, `file`, and `man` installed
- `KX_LINE` disabled in `startq.sh`
- `customdotz.q` loaded at startup via `ic.init.q`, which wires up `.z.ph`, `.z.pg`, and `.z.ps` handlers via `.customdotz.applyOverrides[]`. Each handler logs to `.customdotz.log` (columns: `time`, `handler`, `handle`, `user`, `ip`, `host`, `args`).

## Building

Build a single service image:

```bash
scripts/build.sh <service>
```

Build all service images:

```bash
scripts/build.sh all
```

Services: `rt sm da rc agg gw`

The built image is tagged `<image-name>:local` (e.g. `kxi-da-single:local`).

## Running

Run a service container using the remote (registry) image:

```bash
scripts/run.sh <service>
```

Run using the locally built image:

```bash
scripts/run.sh <service> --local
```

Alternatively, set `DS_<SERVICE>_IMAGE` in `.env` to point to a local image and use `docker compose up`.

## Service config fragments

Each `scripts/<service>.sh` file defines `LOCAL_IMAGE`, `REMOTE_IMAGE`, `BUILD_DIR`, `BUILD_ARGS`, and `do_run()`. These are sourced by `build.sh` and `run.sh` — edit them to change port mappings, volumes, or environment variables for a specific service.

## Port layout

See `services.md` for the q process tree and port assignments for each service.
