# QuickIsaacSim

## VERSION 0.1-alpha

Base commits before Isaac Sim integration changes.

| Repository         | Commit    | 0.1-alice |
|--------------------|-----------|-----------|
| bullet_ng          | 1eaedba   | *         |
| bullet_drone       | 2405ebf   | *         |
| bullet_render      | 359868b   | *         |
| bullet_app         | 6741a1c   | *         |
| beta_client        | f7849e4   |           |
| bullet_view        | 3a57335   | *         |
| bullet_perception  | 37acc3f   |           |
| los_tracking       | 069f3b8   |           |
| bullet_visual      | 542f74e   |           |

## How to run

### Terminal #1 — Scene + SITL + Isaac renderer

```bash
cd ~/projects/bullet_drone
tools/run_target_scene.sh --isaac-physics --world ~/ov/rivermark.usd
```

### Terminal #2 — App (after SITL is ready)

```bash
cd ~/projects/bullet_drone
bash tools/run_app_after_sitl.sh target-hit
```

### Terminal #3 — View (arm & start)

```bash
cd ~/projects/bullet_view
uv run --locked bullet-view --image-endpoint tcp://127.0.0.1:5556
```
