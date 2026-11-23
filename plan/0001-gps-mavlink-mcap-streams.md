# GPS MAVLink streams for MCAP

## Goal

Enable the workspace mission stacks to publish GPS_RAW_INT and GLOBAL_POSITION_INT to the configured MCAP bagger at 2 Hz.

## Implementation steps

1. Change both launch App YAML files to 2 Hz for the existing GPS topics.
2. Start the simulator with its opt-in virtual GPS path in both tmux stacks and separate-terminal tasks.
3. Document the behavior in the workspace README.

## Interface changes

No new channels or endpoints; the existing App publisher and bagger configuration are reused.

## Scope and defaults

Applies to hover/land and target-hit workspace launch profiles. Packaged App defaults remain disabled.

## Verification

Passed: both YAML configurations parsed with 2 Hz GPS rates, both tmux and separate-terminal tasks select `--gps`, and 21 focused App tests passed. A live check was not run because ports 5761 and 5762 were already occupied.

## Status

Implemented. Implementation commit: Pending (no commit requested).
