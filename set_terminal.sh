#!/bin/sh

if [ "$TERM" = "xterm-kitty" ]; then
	tmux set -g default-terminal "xterm-kitty"
	tmux set -as terminal-overrides ",xterm-kitty:Tc"
else
	tmux set -g default-terminal "xterm-256color"
	tmux set -as terminal-overrides ",xterm-256color:Tc"
fi
