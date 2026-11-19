# Hover/land tmux launch

Run the workspace task **Bullet: Run hover/land mission stack (tmux)**. It opens one VS Code terminal with three equal tmux panes: Scene/SITL/Godot, the manual `hover-land` App, and Bullet View. Arm and start the mission from View.

Godot opens in the top half of `DP-1-0`, and View opens in the bottom half of the same monitor. Each window fits within its half with a small margin. If that display is missing, both use the corresponding halves of the primary monitor. The terminal stays in VS Code.

Press `Ctrl+b`, then `d` to detach. Running the task again reattaches to the same session. To stop the stack, interrupt each pane with `Ctrl+C`, then run `tmux -L bullet-hover-land kill-session -t bullet-hover-land` if the session remains. The launcher checks the SITL, renderer, and View ports before creating a new session.
