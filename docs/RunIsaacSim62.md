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

```bash
uv run launcher --renderer-backend isaac \
    --render-config external_render/configs/physics.json
```

This requires `--sitl-binary` and `--sitl-profile` if the checkout defaults
are not present. See `uv run launcher --help` for all options.

## CLI options reference

| Flag | Default | Description |
|------|---------|-------------|
| `--renderer-backend isaac` | `godot` | Select the Isaac Sim backend |
| `--render-config PATH` | `external_render/configs/physics.json` | Transport and camera config |
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
