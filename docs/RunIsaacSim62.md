# Running the Isaac Sim 6.2 Renderer

The Isaac Sim renderer is an alternative to the Godot renderer. It uses NVIDIA
RTX ray-tracing via Isaac Sim 6.2 and renders through the same ZMQ/shared-memory
transport as Godot — the launcher doesn't know which backend is running.

> **Prerequisites:** Isaac Sim 6.2 installed at `~/isaacsim6.2` (or set
> `ISAAC_SIM_DIR`), an NVIDIA RTX GPU, and the protocol packages
> (`bullet-simulation-protocol`, `bullet-image-transport`) installed.

## 1. Install protocol packages

From the `bullet_drone` repo:

```bash
cd ~/projects/bullet_drone
pip install -e libs/bullet_simulation_protocol -e libs/bullet_image_transport
```

Or with uv in the workspace:

```bash
uv sync --group isaac
```

## 2. Set `ISAAC_SIM_DIR` (if not at default)

The default location is `~/isaacsim6.2`. Override with:

```bash
export ISAAC_SIM_DIR=/path/to/isaacsim6.2
```

## 3. Run the launcher

All commands below are run from `~/projects/bullet_drone`.

### Physics only (no SITL), Isaac with GUI

```bash
uv run launcher --no-sitl --renderer-backend isaac \
    --render-config external_render/configs/physics.json
```

### Headless (no Isaac GUI window)

```bash
uv run launcher --no-sitl --renderer-backend isaac \
    --render-config external_render/configs/physics.json \
    --isaac-headless
```

### With a USD world

```bash
uv run launcher --no-sitl --renderer-backend isaac \
    --render-config external_render/configs/physics.json \
    --world ~/ov/rivermark.usd
```

World presets (spawn position, target position) are loaded automatically from
`bullet_render/isaac/world_presets.json` when the USD filename matches a known
entry (currently `rivermark.usd`).

### Full stack with SITL

Run each in a separate terminal from `~/projects/bullet_drone`:

**Terminal 1 — Scene + SITL + renderer:**

```bash
uv run --frozen --extra render --extra sitl --extra mavlink launcher \
    --sitl --no-gps --render --renderer-backend isaac \
    --render-config external_render/configs/physics.json
```

Add `--target-scene` for the target-hit mission.

**Terminal 2 — App + Visual (waits for SITL, then starts):**

```bash
bash ~/workspaces/bullet_ng/launch/run_app_after_sitl.sh hover-land
```

For target-hit, use `target-hit` instead of `hover-land`. Both missions
start bullet-visual in the background for bounding box detection.

**Terminal 3 — Viewer** (with Reset App support):

```bash
uv run --project ../bullet_view --locked bullet-view \
    --app-launch-script ~/workspaces/bullet_ng/launch/run_app_after_sitl.sh \
    --app-mission hover-land
```

The `--app-launch-script` and `--app-mission` flags enable the Reset App
button in the Simulation tab. Omit them if you don't need that button.

## CLI options reference

| Flag | Default | Description |
|------|---------|-------------|
| `--renderer-backend isaac` | `godot` | Select the Isaac Sim backend |
| `--render-config PATH` | (required) | Transport and camera config |
| `--isaac-headless` | off | Run Isaac Sim without a GUI window |
| `--world PATH` | none | USD world file to load |

## Architecture

```
launcher (bullet_drone)          bullet_render/isaac/
┌──────────────────────┐         ┌──────────────────────┐
│  PyBullet physics     │         │  main.py              │
│  ↓ poses via ZMQ PUB  │────────→│  Receiver (ZMQ SUB)   │
│                        │         │  ↓                    │
│  RenderPublisher       │         │  Scene (USD stage)    │
│  publishes CONFIG,     │         │  Camera (RTX)         │
│  POSE, STATE           │         │  ↓                    │
│                        │←────────│  Publisher (ZMQ PUB)  │
│  ImageSubscription     │  images │  writes RGB to SHM    │
│  reads frames from SHM │         │                       │
└──────────────────────┘         └──────────────────────┘
```

The launcher owns the physics loop and publishes drone poses on the
`telemetry_endpoint`. The Isaac renderer subscribes, renders each frame with
RTX, and publishes RGB pixels back on the `image_endpoint` via shared memory.

## Transport config

The renderer reads `transport.json` (referenced inside `physics.json`):

```json
{
  "telemetry_endpoint": "tcp://127.0.0.1:5555",
  "image_endpoint": "tcp://127.0.0.1:5556",
  "control_endpoint": "tcp://127.0.0.1:5557"
}
```

The Isaac renderer uses `telemetry_endpoint` (subscribe to poses) and
`image_endpoint` (publish rendered frames). `control_endpoint` is unused.

## Source layout

```
bullet_render/isaac/
├── main.py             # entry point (launched by IsaacRenderer via python.sh)
├── camera.py           # RTX camera wrapper, Bullet→USD axis conversion
├── scene.py            # USD stage management, drone marker, viewport
├── surface.py          # triangle geometry for vertical surface queries
├── scenario.py         # truck geometry, contact detection
├── presets.py          # per-world spawn/target defaults
├── world_presets.json  # known world presets
├── transport.py        # ZMQ receiver (poses in) and publisher (images out)
└── runtime.py          # Isaac directory and dependency paths

bullet_drone/src/launcher/
├── isaac_renderer.py   # IsaacRenderer class (same interface as ExternalRenderer)
├── cli.py              # --renderer-backend isaac, --isaac-headless, --world
└── main.py             # conditionally creates IsaacRenderer or ExternalRenderer
```

## Remote setup (split across two machines)

Run physics + SITL on the **local machine** (`10.0.0.16`) and the renderer +
app + viewer on a **remote machine** (`10.0.0.17`). Images use shared memory,
so the renderer must be co-located with the viewer.

See `docs/RemoteViewerSetup.md` for the full architecture and port table.

### Pre-generated config files

Remote transport configs are already in the repo — they differ from the local
ones only in the bind/connect addresses:

| File | Where | Difference from local |
|------|-------|-----------------------|
| `bullet_drone/external_render/configs/physics_remote.json` | 10.0.0.16 | Binds ZMQ on `0.0.0.0` instead of `127.0.0.1` |
| `bullet_render/configs/physics_remote.json` | 10.0.0.17 | Connects ZMQ to `10.0.0.16` |
| `mcap_bagger/config/recorder_remote.yaml` | 10.0.0.17 | Launcher channels point to `10.0.0.16` |

### Local machine (10.0.0.16) — simulation only

```bash
cd ~/projects/bullet_drone
uv run --frozen --extra sitl --extra mavlink launcher \
    --sitl --no-gps --no-render \
    --render-config external_render/configs/physics_remote.json \
    --simulation-control-endpoint tcp://0.0.0.0:5561
```

The two differences from a local run:
1. `--render-config` → `physics_remote.json` (binds on `0.0.0.0`)
2. `--simulation-control-endpoint tcp://0.0.0.0:5561` (default is `127.0.0.1`)

### Remote machine (10.0.0.17)

**SSH tunnel for SITL** (the app waits for ports 5761/5762):

```bash
ssh -L 5761:127.0.0.1:5761 -L 5762:127.0.0.1:5762 10.0.0.16 -N &
```

**Isaac renderer:**

```bash
cd ~/projects/bullet_render
~/isaacsim6.2/python.sh isaac/main.py \
    --transport-config configs/transport_remote.json
```

**Bullet App + Visual** (hover-land or target-hit):

```bash
cd ~/workspaces/bullet_ng
bash launch/run_app_after_sitl.sh hover-land
```

The script starts bullet-visual in the background, then launches bullet-app.

**Bullet View** (with Reset App support):

```bash
cd ~/projects/bullet_drone
uv run --project ../bullet_view --locked bullet-view \
    --simulation-control-endpoint tcp://10.0.0.16:5561 \
    --simulation-state-endpoint tcp://10.0.0.16:5555 \
    --app-launch-script ~/workspaces/bullet_ng/launch/run_app_after_sitl.sh \
    --app-mission hover-land
```

The differences from a local run:
1. `--simulation-control-endpoint` → `tcp://10.0.0.16:5561`
2. `--simulation-state-endpoint` → `tcp://10.0.0.16:5555`
3. `--app-launch-script` / `--app-mission` enable the Reset App button

## Troubleshooting

**Isaac Sim python.sh not found** — Verify `ISAAC_SIM_DIR` points to the
Isaac Sim installation root containing `python.sh`.

**No rendered camera image within 30 seconds** — Isaac Sim takes 15–25 seconds
to initialize the RTX renderer. If it still times out, check the Isaac
subprocess log (printed on failure) for missing USD assets or driver issues.

**Port unavailable** — Another process is using port 5555 or 5556. Kill it or
change the ports in `transport.json`.

**Renderer exited before mission completion** — Isaac Sim crashed. Run with
the GUI (`--isaac-headless` removed) to see the error in the Isaac console.

**Remote: viewer shows no telemetry / "no simulation" state** — The viewer
can't reach the simulation control or state endpoints. Check:
1. The launcher on 10.0.0.16 is using `physics_remote.json` (binds `0.0.0.0`,
   not `127.0.0.1`).
2. `--simulation-control-endpoint tcp://0.0.0.0:5561` was passed to the
   launcher.
3. Firewall on 10.0.0.16 allows TCP 5555 and 5561 from 10.0.0.17:
   `sudo ufw allow from 10.0.0.17 to any port 5555,5561 proto tcp`
4. Verify connectivity: `nc -zv 10.0.0.16 5555` from 10.0.0.17.

**Remote: SSH tunnel for SITL drops / app won't start** — The app waits for
ports 5761 and 5762. If the SSH tunnel died, the `ss -ltn` check in
`run_app_after_sitl.sh` will loop forever. Re-run:
`ssh -L 5761:127.0.0.1:5761 -L 5762:127.0.0.1:5762 10.0.0.16 -N &`
To keep it alive, add `-o ServerAliveInterval=30` to the SSH command.

**Remote: renderer connects but no images in viewer** — Images use shared
memory (`/dev/shm`), which is local to a single machine. The renderer must run
on the same machine as the viewer (10.0.0.17). If you accidentally ran the
renderer on 10.0.0.16, the viewer will receive image metadata over ZMQ but
can't read the pixel data from SHM.
