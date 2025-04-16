if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

bindkey -v

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

zsh_config=~/.config/zsh
for plugin in  $zsh_config/plugins/*/*.{zsh,zsh-theme}(N) ; do
	[[ -f "$plugin" ]] && source "$plugin"
done
source <(fzf --zsh)

autoload -Uz compinit && compinit

for config in $zsh_config/*.zsh; do
	if [[ "$(basename "$config")" == "init.zsh" ]]; then
		continue
	fi
	[[ -f "$config" ]] && source "$config"
done

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)EZA_COLORS}"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
