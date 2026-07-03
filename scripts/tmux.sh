#!/usr/bin/env bash

SESSION="0"
RESURRECT="$HOME/dotfiles/tmux/plugins/tmux-resurrect/scripts/restore.sh"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux attach-session -t "$SESSION"
else
    # Create session 0 detached
    tmux new-session -d -s "$SESSION" -c "$HOME"

    # Run resurrect script (it expects a client, so attach first)
    tmux run-shell "$RESURRECT"

    # Attach to restored main session
    tmux switch-client -t main
    tmux attach-session -t main
fi
