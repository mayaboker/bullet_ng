# Bullet NG

Bullet NG is the VS Code workspace and launch configuration for the Bullet Drone simulation projects. It keeps the simulator, renderer, flight app, dashboard, and vision tools in separate repositories under `~/projects`.

## Overview

This repository connects the projects for local development and simulated flights. It provides a multi-root VS Code workspace, tmuxp launch layouts, and a script that checks out a matching tag of each project. It is intended for developers running the Bullet Drone SITL stack; a physical drone is not required.

## Features

- One VS Code workspace for the eight project repositories and `bullet_ng`.
- Hover/land and red-target mission tasks, with tmux layouts that start each process in its own pane.
- A tag-based clone script that checks all project remotes before writing to `~/projects`.

## Architecture

| Project | Responsibility |
| --- | --- |
| [bullet_drone](https://github.com/mayaboker/bullet_drone) | PyBullet physics and sensors, the simulation launcher, and Betaflight SITL integration. |
| [bullet_render](https://github.com/mayaboker/bullet_render) | Godot scene and native ZeroMQ/shared-memory camera adapter. |
| [bullet_app](https://github.com/mayaboker/bullet_app) | Flight missions, Betaflight control, and the connection to View and target guidance. |
| [beta_client](https://github.com/mayaboker/beta_client) | Betaflight MSP and MAVLink client code used by the App. |
| [bullet_view](https://github.com/mayaboker/bullet_view) | MAVLink flight dashboard and operator controls. |
| [bullet_perception](https://github.com/mayaboker/bullet_perception) | Red-target bounding-box detection. |
| [los_tracking](https://github.com/mayaboker/los_tracking) | Line-of-sight guidance from bounding boxes and flight measurements. |
| [bullet_visual](https://github.com/mayaboker/bullet_visual) | Camera ingestion, target detection, and bounding-box publication. |

`bullet_drone` runs the physics loop and SITL while `bullet_render` produces camera images. `bullet_visual` applies `bullet_perception` to those images. `bullet_app` uses `beta_client` for flight I/O and `los_tracking` for its target mission; `bullet_view` displays telemetry and sends operator commands to the App.

## Requirements

**Cloning:** Bash, Git, and access to the eight GitHub repositories. The same tag must exist in this checkout of `bullet_ng` and in all eight project remotes.

**Running the stack:** Follow each project's setup instructions for Python/uv, Betaflight SITL, Godot, and native build dependencies. The tmux launch tasks additionally need `tmux`, `tmuxp`, `ss`, and a graphical desktop.

## Installation

Clone this workspace into `~/workspaces/bullet_ng` first:

```bash
mkdir -p "$HOME/workspaces"
git clone https://github.com/mayaboker/bullet_ng.git "$HOME/workspaces/bullet_ng"
cd "$HOME/workspaces/bullet_ng"
```

List its locally available tags, choose one, then clone the eight project repositories into `~/projects/<project-name>`:

```bash
./scripts/clone_workspace.sh
read -r -p 'Tag to install: ' tag
./scripts/clone_workspace.sh "$tag"
```

The script checks the local `bullet_ng` tag and all eight project remotes before cloning. Each project ends on a local `workspace/<tag>` branch at that tag's commit. It stops if any project destination already exists; it does not update existing checkouts. If there are no tags, obtain a `bullet_ng` tag and publish the same tag in the eight project repositories before installation.

## Quick Start

Open `bullet_ng.code-workspace` in VS Code after cloning and installing the projects. Run **Bullet: Run hover/land mission stack (tmux)**, then use Bullet View to arm and start the mission. The task opens SITL/Godot, the manual App, and View in separate tmux panes.

## Usage

Run **Bullet: Run target-hit mission stack (tmux)** for the red-target workflow. It adds Bullet Visual to the simulator, App, and View processes. See [launch/README.md](launch/README.md) for monitor layout, detach, and shutdown instructions. The workspace also has tasks that open each process in a separate VS Code terminal.

Running `./scripts/clone_workspace.sh` without a tag only lists local `bullet_ng` tags and makes no filesystem changes. Running it with a tag verifies all remotes and destinations before cloning. It creates `~/projects` when needed and leaves the `bullet_ng` checkout alone.

## Configuration

| File | Purpose |
| --- | --- |
| [bullet_ng.code-workspace](bullet_ng.code-workspace) | Project folders and VS Code task definitions. |
| [launch/hover_land.tmuxp.yaml](launch/hover_land.tmuxp.yaml) | Three-pane hover/land stack. |
| [launch/target_hit.tmuxp.yaml](launch/target_hit.tmuxp.yaml) | Four-pane target mission stack. |

The tmux configurations place Godot and View on the two halves of monitor `DP-1-0`, with fallback to the primary monitor. Clone destinations are fixed at `~/projects`; the workspace itself is expected at `~/workspaces/bullet_ng`.

## Project Structure

```text
bullet_ng/
├── bullet_ng.code-workspace  # Multi-root workspace and tasks
├── scripts/                  # Tag-based project clone script
├── launch/                   # tmuxp layouts and launch helpers
└── docs/                     # Workspace notes and diagrams
```

The `bullet_drone_plan` and `bullet_drone_external_render` folders are retained historical snapshots. Active source lives in the separate project repositories listed above.

## Development

Edit and build each project in its own repository under `~/projects`; `bullet_ng` has no root Python package or build. Use the project READMEs for dependency installation and development commands. Update `bullet_ng.code-workspace` and the clone script together when the workspace project list changes.

## Testing

Check the shell script and workspace JSON with:

```bash
bash -n scripts/clone_workspace.sh
python3 -m json.tool bullet_ng.code-workspace >/dev/null
```

There is no root test suite. Run each project's tests from that project's checkout. The clone script should be exercised with temporary tagged repositories before changing its clone behavior.

## Documentation

- [Launch layouts and controls](launch/README.md)
- [Commit message and hook setup](docs/dev/pre-commit-commitlint-setup.md)
- [Workspace architecture image](docs/images/projects_architecture.drawio.png)

## Troubleshooting

- **“No tags available”:** this `bullet_ng` checkout has no local tags. Fetch or create the intended release tag before selecting it.
- **Tag missing in a project:** publish the same tag in all eight project repositories. The script stops before cloning anything.
- **Destination already exists:** move or remove that project directory yourself before running the script; it never overwrites or updates a checkout.
- **Tmux stack will not start:** check the required commands, desktop display, and occupied ports described in [launch/README.md](launch/README.md).

## Roadmap

No workspace roadmap is specified here; project plans live in their respective repositories.

## Contributing

Make project code changes in the owning repository. This workspace has no separate contribution policy; review the relevant project guidance before submitting changes.

## License

This repository does not contain a root license file. Check each project repository for its own license terms.
