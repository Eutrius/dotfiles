#!/bin/sh
if [ "$TERM" = "xterm-kitty" ]; then
  tmux set -g default-terminal "xterm-kitty"
else
  tmux set -g default-terminal "xterm-256color"
fi
