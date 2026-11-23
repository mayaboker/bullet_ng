# QuickIsaacSim

## VERSION 0.2-alice

Merged bob (mission refactor) and relax (tuning) branches. Fixed attitude
timing regression and spawn geometry for rivermark.usd.

| Repository         | Commit    | 0.2-alice |
|--------------------|-----------|-----------|
| bullet_ng          | 2dafb06   | *         |
| bullet_drone       | f79d986   | *         |
| bullet_render      | d86e420   | *         |
| bullet_app         | db674a6   | *         |
| beta_client        | 3fbc039   | *         |
| bullet_view        | f4659fe   | *         |
| los_tracking       | b5fd6d8   | *         |
| bullet_perception  | 37acc3f   |           |
| bullet_visual      | 542f74e   |           |

### Changes from 0.1-alice

- **bullet_app**: merged bob (blackboard, StepContext, YAML config, 20 commits);
  re-applied attitude_at fix for Isaac Sim TIMESYNC timing.
- **bullet_view**: merged bob (MAVLink flight protocol, status display, 9 commits).
- **bullet_render**: aligned rivermark spawn with truck for straight-ahead approach.
- **bullet_drone**: fixed isaacSimKillAll.bash killing Firefox (`omni\.` → `omni\.kit`).
- **los_tracking**: merged relax tuning (wider timing/deviation tolerances).
- **beta_client**: merged bob (MSP board identity).
- **bullet_ng**: merged bob (tmux pane labels, log ignores).

### Known limitations

- `target_contact()` stubbed to `False` in Isaac physics — truck hit detection
  not yet implemented.

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
