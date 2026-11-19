#!/usr/bin/env bash
set -euo pipefail

launch_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export BULLET_DRONE_ROOT=$(cd -- "$launch_dir/../../../projects/bullet_drone" && pwd)
socket_name=bullet-hover-land
session_name=bullet-hover-land

for required in tmux tmuxp uv ss; do
    if ! command -v "$required" >/dev/null 2>&1; then
        echo "Missing required command: $required" >&2
        exit 1
    fi
done

if tmux -L "$socket_name" has-session -t "$session_name" 2>/dev/null; then
    exec tmux -L "$socket_name" attach-session -t "$session_name"
fi

if [[ -z ${DISPLAY:-} ]]; then
    echo 'DISPLAY is unset; start this task from the graphical desktop.' >&2
    exit 1
fi

if [[ ! -t 0 || ! -t 1 ]]; then
    echo 'This launcher needs an interactive terminal so tmux can attach.' >&2
    exit 1
fi

occupied=$(ss -H -ltnu | awk '$5 ~ /:(5761|5762|5555|5556|14550)$/ { print $1 " " $5 }')
if [[ -n $occupied ]]; then
    printf 'Hover/land ports are already in use; stop the existing stack before launching:\n%s\n' "$occupied" >&2
    exit 1
fi

exec tmuxp load -L "$socket_name" --yes "$launch_dir/hover_land.tmuxp.yaml"
