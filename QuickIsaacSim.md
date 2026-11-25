# QuickIsaacSim

## VERSION contact-alice

Target contact detection working end-to-end in Isaac Sim. Drone
descends in LOS, enters commit when target clips the camera frame,
and sphere-sweep physics detects the truck hit.

| Repository         | Commit    | contact-alice |
|--------------------|-----------|---------------|
| bullet_ng          | b98d05a   | *             |
| bullet_drone       | 9ac8589   | *             |
| bullet_render      | d86e420   |               |
| bullet_app         | 2a5adcc   | *             |
| beta_client        | 4131d88   | *             |
| bullet_view        | 8f130dc   | *             |
| los_tracking       | 4d7fbfc   | *             |
| bullet_perception  | 0122041   | *             |
| bullet_visual      | 867a4a8   | *             |

### Changes from 0.2-alice

- **bullet_drone**: sphere-sweep `target_contact()` with AABB truck
  parts in Isaac physics; publisher uses wire_sequence for fid so idle
  poses stream correctly to the renderer; target Z set to ground plane
  (0.0) instead of world-space offset; renderer startup timeout raised
  to 360s for heavy worlds; restored stdin reset handler lost during
  bob merge.
- **bullet_app**: allow 100ms clock tolerance in prearm altitude check
  to prevent spurious fault on first tick.
- **los_tracking**: allow LOS commit from `clipped_target` recovery
  using the last processed frame; lowered `commit_coverage_fraction`
  from 0.25 to 0.02 to match actual truck size in camera.
- **beta_client**, **bullet_view**, **bullet_visual**, **bullet_perception**:
  updated uv.lock for 0.2.0.

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
cd ~/workspaces/bullet_ng
bash launch/run_app_after_sitl.sh target-hit
```

### Terminal #3 — View (arm & start)

```bash
cd ~/projects/bullet_view
uv run --locked bullet-view --image-endpoint tcp://127.0.0.1:5556
```

## How to reset simulation

After a mission completes (or to restart mid-flight), use the View
buttons to reset without restarting Terminal #1:

1. **Ctrl+C** Terminal #2 (the App).
2. In the View: **Stop Simulation** → **Reset Simulation** → **Start Simulation**.
3. Rerun Terminal #2:
   ```bash
   cd ~/workspaces/bullet_ng
   bash launch/run_app_after_sitl.sh target-hit
   ```
4. ARM and start the mission from the View.

Terminal #1 (Isaac Sim + SITL) stays running throughout. Only restart
Terminal #1 when you change physics or renderer code on disk.
