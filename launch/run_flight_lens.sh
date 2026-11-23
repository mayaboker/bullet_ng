#!/usr/bin/env bash
set -euo pipefail

launch_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
flight_lens_root=$(cd -- "$launch_dir/../../../projects/flight_lens" && pwd)
export PYTHONPATH="$flight_lens_root/src${PYTHONPATH:+:$PYTHONPATH}"

for python in "$flight_lens_root/.venv/bin/python" "$HOME/workspaces/bullet/.venv/bin/python" "$(command -v python3 || true)"; do
    if [[ -x $python ]] && "$python" -c 'import flight_lens.app' >/dev/null 2>&1; then
        cd -- "$flight_lens_root"
        exec "$python" -m flight_lens.app "$@"
    fi
done

echo 'Flight Lens dependencies are unavailable; install flight_lens and bullet_msgs in a Python environment.' >&2
exit 1
