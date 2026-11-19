# Hover/land tmux launch

Run the workspace task **Bullet: Run hover/land mission stack (tmux)**. It opens one VS Code terminal with three equal tmux panes: Scene/SITL/Godot, the manual `hover-land` App, and Bullet View. Arm and start the mission from View.

Godot opens in the top half of `DP-1-0`, and View opens in the bottom half of the same monitor. Each window fits within its half with a small margin. If that display is missing, both use the corresponding halves of the primary monitor. The terminal stays in VS Code.

View reads the renderer's local camera image on ZMQ port 5556. The hover/land stack shows raw images; the target-hit stack overlays App-relayed, fid-matched detections.

Press `Ctrl+b`, then `d` to detach. Running the task again reattaches to the same session. To stop the stack, interrupt each pane with `Ctrl+C`, then run `tmux -L bullet-hover-land kill-session -t bullet-hover-land` if the session remains. The launcher checks the SITL, renderer, and View ports before creating a new session.

## Target-hit mission

Run **Bullet: Run target-hit mission stack (tmux)** to open a separate `bullet-target-hit` session with four panes: target-enabled Scene/SITL/Godot, Bullet Visual with `zmq.yaml`, the manual `target-hit` App, and Bullet View. The simulator and View keep the same top/bottom monitor split. Arm and start the mission from View.

Detach with `Ctrl+b`, then `d`; rerunning the task reattaches. To stop the target stack, interrupt each pane with `Ctrl+C`, then run `tmux -L bullet-target-hit kill-session -t bullet-target-hit` if needed. The launcher checks the Visual port along with the SITL, renderer, and View ports before creating a session.
