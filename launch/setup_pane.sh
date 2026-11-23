#!/usr/bin/env bash
# Source this in each tmuxp pane before starting its process.

history_name=${1:?pane history name required}
pane_label=${2:?pane label required}

export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/bullet_ng/history/$history_name"
mkdir -p -- "${HISTFILE%/*}"
history -c
history -r 2>/dev/null || true
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
tmux set-option -p -t "$TMUX_PANE" @bullet_label "$pane_label"

unset history_name pane_label
