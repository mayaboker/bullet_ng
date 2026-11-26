#!/usr/bin/env bash
set -euo pipefail

launch_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

mission=${1:?Usage: run_app_after_sitl.sh hover-land|target-hit}
if [[ "$mission" != hover-land && "$mission" != target-hit ]]; then
    echo "Unknown mission: $mission" >&2
    exit 2
fi

drone_root=$(cd -- "$launch_dir/../../../projects/bullet_drone" && pwd)
app_root=$(cd -- "$launch_dir/../../../projects/bullet_app" && pwd)
visual_root=$(cd -- "$launch_dir/../../../projects/bullet_visual" && pwd)

cd -- "$app_root"
for attempt in {1..120}; do
    if ss -ltn | awk '$4 ~ /:5761$/ { msp=1 } $4 ~ /:5762$/ { mavlink=1 } END { exit !(msp && mavlink) }'; then
        app_args=(--mode manual --mission "$mission")
        if [[ "$mission" == target-hit ]]; then
            app_args+=(--config "$launch_dir/target_hit.app.yaml")
        else
            app_args+=(--config "$launch_dir/hover_land.app.yaml")
        fi

        cd -- "$drone_root"
        uv run --project "$visual_root" --locked bullet-visual \
            --config "$visual_root/config/zmq.yaml" &
        visual_pid=$!
        trap 'kill $visual_pid 2>/dev/null; wait $visual_pid 2>/dev/null' EXIT
        cd -- "$app_root"
        exec uv run --locked bullet-app "${app_args[@]}"
    fi
    sleep 0.5
done

echo 'Timed out waiting for Betaflight MSP (5761) and MAVLink (5762) listeners' >&2
exit 1
