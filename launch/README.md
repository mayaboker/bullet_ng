# Hover/land tmux launch

Run the workspace task **Bullet: Run hover/land mission stack (tmux)**. It opens one VS Code terminal with a three-pane mission window (Scene/SITL/Godot, the manual `hover-land` App, and Bullet View) and a separate `mcap-bagger` window. Arm and start the mission from View.

The App pane and the separate-terminal App tasks run [run_app_after_sitl.sh](run_app_after_sitl.sh) from this workspace. It waits up to 60 seconds for Betaflight's MSP port 5761 and MAVLink port 5762, then starts the selected manual mission from the Bullet App checkout. It uses the launch-specific [hover/land](hover_land.app.yaml) or [target-hit](target_hit.app.yaml) config. The target-hit config enables simulator contact; both enable blackboard telemetry publishing on port 5558. The simulation launcher remains in `bullet_drone`.

Both stacks start the launcher with `--no-gps`, selecting the GPS-disabled Betaflight profile while still placing synthetic latitude and longitude in FDM position X/Y. App retains requests for GPS_RAW_INT and GLOBAL_POSITION_INT. App publishes each GPS topic at 2 Hz to port 5558, where the bagger's recorder config subscribes. GPS data appears only after Betaflight produces the corresponding MAVLink message.

Godot opens in the top half of `DP-1-0`, and View opens in the bottom half of the same monitor. Each window fits within its half with a small margin. If that display is missing, both use the corresponding halves of the primary monitor. The terminal stays in VS Code.

View reads the renderer's local camera image on ZMQ port 5556. The hover/land stack shows raw images; the target-hit stack overlays App-relayed, fid-matched detections.

The `mcap-bagger` window starts `mcap-bagger run --config config/recorder.yaml` from the `~/projects/mcap_bagger` checkout. It records the configured camera, sensor, and App topics to `~/projects/mcap_bagger/recordings/`. Switch between windows with `Ctrl+b` then `n` or `p`. Recording continues after the mission ends; use `Ctrl+C` in the bagger window to drain accepted messages and finalize the `.mcap` file. Stopping a mission pane alone does not stop recording.

Each mission pane has a labeled top border, its own tmux scrollback, and a separate Bash command history. To stop one process, select its pane and press `Ctrl+C`. At the shell prompt, press `Up` then `Enter` to rerun that pane's last command, or use `Ctrl+r` to search earlier commands. To browse output, press `Ctrl+b` then `[`, scroll with the arrow or Page Up keys, and press `q` to leave copy mode. Pane histories are saved under `${XDG_STATE_HOME:-$HOME/.local/state}/bullet_ng/history/`.

Bullet App also saves each run to `~/workspaces/bullet_ng/logs/bullet_app_<timestamp>.log`. The App pane prints the exact file path when it starts. These files include detailed target tracking checkpoints that are not shown in the pane.

Press `Ctrl+b`, then `d` to detach. Running the task again reattaches to the same session. To stop the stack, stop the bagger with `Ctrl+C` so the MCAP file finalizes, interrupt the mission panes, then run `tmux -L bullet-hover-land kill-session -t bullet-hover-land` if the session remains. The launcher checks the SITL, renderer, and View ports before creating a new session.

## Target-hit mission

Run **Bullet: Run target-hit mission stack (tmux)** to open a separate `bullet-target-hit` session with a four-pane mission window (target-enabled Scene/SITL/Godot, Bullet Visual with `zmq.yaml`, the manual `target-hit` App, and Bullet View) plus its own `mcap-bagger` window. The simulator and View keep the same top/bottom monitor split. Arm and start the mission from View.

The launcher reads [target_hit.scene.yaml](target_hit.scene.yaml) for the drone's starting pose. `initial_position_m: [0, 0, 0.015]` keeps it at the original world X/Y location; `initial_yaw_deg: 90` turns it in place. Edit the yaw and restart the scene pane or stack to use a different heading. The truck remains at world X=50, Y=0.

At this origin position, 90° points the camera toward world +Y, away from the truck at +X. The target detector will not see the truck until the drone turns toward it; use 0° to face it from the origin.

The target stack uses the same pane headers, independent histories, and scrollback controls. Detach with `Ctrl+b`, then `d`; rerunning the task reattaches. To stop the target stack, stop its bagger with `Ctrl+C`, interrupt each mission pane, then run `tmux -L bullet-target-hit kill-session -t bullet-target-hit` if needed. The launcher checks the Visual port along with the SITL, renderer, and View ports before creating a session.
