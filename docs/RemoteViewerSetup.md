# Remote Viewer + App Setup

Run the simulation (physics + SITL) on the **local machine** (`10.0.0.16`) and
the renderer, Bullet App, and Bullet View on a **remote machine** (`10.0.0.17`).

## Architecture

```
Local machine (10.0.0.16)              Remote machine (10.0.0.17)
┌──────────────────────────┐           ┌──────────────────────────┐
│  launcher (bullet_drone)  │           │  Isaac / Godot renderer  │
│    PyBullet / Isaac physics│           │    SUB → 10.0.0.16:5555 │
│    Betaflight SITL         │           │    images → local SHM    │
│                            │           │                          │
│  ZMQ PUB binds on:        │           │  bullet_app              │
│    :5555  telemetry/poses  │◀──SUB────│    SITL via SSH tunnel   │
│                            │           │    PUB → :5558 (local)   │
│  ZMQ REP binds on:        │           │                          │
│    :5557  render control   │◀──REQ────│  bullet_view             │
│    :5561  sim control      │◀──REQ────│    SUB → 10.0.0.16:5555 │
│                            │           │    REQ → 10.0.0.16:5561 │
│  SITL listens:             │           │    SHM images (local)    │
│    :5761  MSP (TCP)        │◀─tunnel──│                          │
│    :5762  MAVLink (TCP)    │◀─tunnel──│  run_app_after_sitl.sh   │
└──────────────────────────┘           └──────────────────────────┘
```

## Config files

Remote config variants are already generated alongside the originals. Each
machine uses the `_remote` variant.

| File | Machine | Purpose |
|------|---------|---------|
| `bullet_drone/external_render/configs/transport_remote.json` | local (10.0.0.16) | ZMQ PUB/REP bind on `0.0.0.0` |
| `bullet_drone/external_render/configs/physics_remote.json`   | local (10.0.0.16) | Physics config pointing at remote transport |
| `bullet_render/configs/transport_remote.json`                | remote (10.0.0.17) | ZMQ SUB/REQ connect to `10.0.0.16` |
| `bullet_render/configs/physics_remote.json`                  | remote (10.0.0.17) | Render config pointing at remote transport |
| `mcap_bagger/config/recorder_remote.yaml`                    | remote (10.0.0.17) | Recorder with remote endpoints for launcher channels |

## Quick start

### 1. Local machine (10.0.0.16) — simulation only

```bash
cd bullet_drone
uv run --frozen --extra sitl --extra mavlink launcher \
    --sitl --no-gps --no-render \
    --render-config external_render/configs/physics_remote.json \
    --simulation-control-endpoint tcp://0.0.0.0:5561
```

`--no-render` because the renderer runs on the remote machine (shared memory
is local, so images must be rendered where the viewer is).

### 2. Remote machine (10.0.0.17) — renderer + app + view

**SSH tunnel for SITL ports** (run first, in background):

```bash
ssh -L 5761:127.0.0.1:5761 -L 5762:127.0.0.1:5762 10.0.0.16 -N &
```

`run_app_after_sitl.sh` checks that MSP (5761) and MAVLink (5762) are
listening locally. The tunnel forwards them from the simulation machine.

**Isaac renderer** (connects to 10.0.0.16 for poses, renders locally):

```bash
cd bullet_render
~/isaacsim6.2/python.sh isaac/main.py \
    --transport-config configs/transport_remote.json
```

**Bullet App + Visual** (hover-land or target-hit):

```bash
cd bullet_ng
bash launch/run_app_after_sitl.sh hover-land
```

The script starts bullet-visual in the background for bounding box detection,
then launches bullet-app. For target-hit use `target-hit` instead.

**Bullet View** (with Reset App support):

```bash
cd bullet_drone
uv run --project ../bullet_view --locked bullet-view \
    --simulation-control-endpoint tcp://10.0.0.16:5561 \
    --simulation-state-endpoint tcp://10.0.0.16:5555 \
    --app-launch-script ~/workspaces/bullet_ng/launch/run_app_after_sitl.sh \
    --app-mission hover-land
```

The `--app-launch-script` and `--app-mission` flags enable the Reset App
button in the Simulation tab. Reset works from the remote machine because
the app runs locally on 10.0.0.17.

**MCAP Recorder** (optional):

```bash
cd mcap_bagger
uv run --locked mcap-bagger --config config/recorder_remote.yaml
```

## How it works

### Shared-memory images

The renderer publishes RGB frames via POSIX shared memory (`/dev/shm`). SHM
is local to a machine, so the renderer **must** run on the same machine as the
viewer. The ZMQ `image_endpoint` carries metadata (width, height, slot name)
but the pixels are read from SHM.

That is why the recommended split puts the renderer on the remote machine:
physics + SITL publish poses over ZMQ (which works across the network), and
the renderer subscribes to those poses and writes images to local SHM where
the viewer can read them.

### Transport architecture

```
Local machine (10.0.0.16)              Remote machine (10.0.0.17)
┌──────────────────────────┐           ┌──────────────────────────┐
│  launcher (bullet_drone)  │           │  Isaac renderer          │
│    PyBullet / Isaac physics│           │    SUB → 10.0.0.16:5555 │
│    Betaflight SITL         │           │    images → local SHM    │
│                            │           │                          │
│  ZMQ PUB binds on:        │           │  bullet_app              │
│    :5555  telemetry/poses  │◀──SUB────│    SITL via SSH tunnel   │
│    :5556  image metadata   │           │    PUB → :5558 (local)  │
│                            │           │                          │
│  ZMQ REP binds on:        │           │  bullet_view             │
│    :5557  render control   │◀──REQ────│    SUB → 10.0.0.16:5555 │
│    :5561  sim control      │◀──REQ────│    REQ → 10.0.0.16:5561 │
│                            │           │    SHM images (local)    │
│  SITL listens:             │           │                          │
│    :5761  MSP (TCP)        │◀─tunnel──│  run_app_after_sitl.sh   │
│    :5762  MAVLink (TCP)    │◀─tunnel──│                          │
└──────────────────────────┘           └──────────────────────────┘
```

## Ports summary

| Port  | Protocol | Direction        | Purpose                     |
|-------|----------|------------------|-----------------------------|
| 5555  | ZMQ PUB  | local → remote   | Telemetry, poses, sim state |
| 5556  | ZMQ PUB  | local → remote   | Image metadata              |
| 5557  | ZMQ REQ/REP | remote → local | Render control              |
| 5559  | ZMQ      | remote (app↔view) | Flight commands            |
| 5561  | ZMQ REQ/REP | remote → local | Simulation commands         |
| 5761  | TCP      | remote → local   | Betaflight MSP              |
| 5762  | TCP      | remote → local   | Betaflight MAVLink          |
| 14550 | UDP      | app → view       | MAVLink telemetry to viewer |

## Firewall

On the local machine, allow inbound TCP on ports 5555, 5556, 5557, 5561 from
10.0.0.17. If not using SSH tunnels, also allow 5761 and 5762.

```bash
# Example with ufw
sudo ufw allow from 10.0.0.17 to any port 5555,5556,5557,5561 proto tcp
```
