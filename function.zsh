function lt() {
  local level=${1:-3}
  eza -T --level="$level" --icons
}

function lta() {
  local level=${1:-3}
  eza -Ta --level="$level" --icons
}

function cd() {
  if [[ $# -gt 0 ]]; then
    builtin cd "$@" 2>/dev/null || z "$@"
  else
    builtin cd
  fi
}

function _custom_cd() {
	_cd && return 0
	_zshz
}
compdef _custom_cd cd
