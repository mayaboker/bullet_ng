# Hover/land tmux launch

Run the workspace task **Bullet: Run hover/land mission stack (tmux)**. It opens one VS Code terminal with three equal tmux panes: Scene/SITL/Godot, the manual `hover-land` App, and Bullet View. Arm and start the mission from View.

The App pane and the separate-terminal App tasks run [run_app_after_sitl.sh](run_app_after_sitl.sh) from this workspace. It waits up to 60 seconds for Betaflight's MSP port 5761 and MAVLink port 5762, then starts the selected manual mission from the Bullet App checkout. The simulation launcher remains in `bullet_drone`.

Godot opens in the top half of `DP-1-0`, and View opens in the bottom half of the same monitor. Each window fits within its half with a small margin. If that display is missing, both use the corresponding halves of the primary monitor. The terminal stays in VS Code.

View reads the renderer's local camera image on ZMQ port 5556. The hover/land stack shows raw images; the target-hit stack overlays App-relayed, fid-matched detections.

Each pane has a labeled top border, its own tmux scrollback, and a separate Bash command history. To stop one process, select its pane and press `Ctrl+C`. At the shell prompt, press `Up` then `Enter` to rerun that pane's last command, or use `Ctrl+r` to search earlier commands. To browse output, press `Ctrl+b` then `[`, scroll with the arrow or Page Up keys, and press `q` to leave copy mode. Pane histories are saved under `${XDG_STATE_HOME:-$HOME/.local/state}/bullet_ng/history/`.

Bullet App also saves each run to `~/workspaces/bullet_ng/logs/bullet_app_<timestamp>.log`. The App pane prints the exact file path when it starts. These files include detailed target tracking checkpoints that are not shown in the pane.

Press `Ctrl+b`, then `d` to detach. Running the task again reattaches to the same session. To stop the stack, interrupt each pane with `Ctrl+C`, then run `tmux -L bullet-hover-land kill-session -t bullet-hover-land` if the session remains. The launcher checks the SITL, renderer, and View ports before creating a new session.

## Target-hit mission

Run **Bullet: Run target-hit mission stack (tmux)** to open a separate `bullet-target-hit` session with four panes: target-enabled Scene/SITL/Godot, Bullet Visual with `zmq.yaml`, the manual `target-hit` App, and Bullet View. The simulator and View keep the same top/bottom monitor split. Arm and start the mission from View.

The target stack uses the same pane headers, independent histories, and scrollback controls. Detach with `Ctrl+b`, then `d`; rerunning the task reattaches. To stop the target stack, interrupt each pane with `Ctrl+C`, then run `tmux -L bullet-target-hit kill-session -t bullet-target-hit` if needed. The launcher checks the Visual port along with the SITL, renderer, and View ports before creating a session.
