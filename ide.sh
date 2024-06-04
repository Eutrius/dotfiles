#! /bin/fish

if test (count $argv) -gt 0
  switch $argv[1]
  case 1
    tmux splitw -v -p 35
    tmux splitw -h -p 50
  case 2
    tmux splitw -h -p 30
    tmux splitw -v -p 50
    tmux select-pane -t 0
  case update
    sudo apt update && sudo apt upgrade -y && fisher update
  case shutdown
    shutdown.exe /s /t 0
  case time 
    sudo hwclock -s
  end
end

