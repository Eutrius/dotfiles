bindkey -e

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

zsh_config=~/dotfiles/zsh
for plugin in  $zsh_config/plugins/*/*.{zsh,zsh-theme}(N) ; do
	[[ -f "$plugin" ]] && source "$plugin"
done

source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse"


autoload -Uz compinit && compinit
for config in $zsh_config/*.zsh; do
	if [[ "$(basename "$config")" == "init.zsh" ]]; then
		continue
	fi
	[[ -f "$config" ]] && source "$config"
done

setopt prompt_subst
prompt='%~$(git_branch) %# '
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)EZA_COLORS}"

