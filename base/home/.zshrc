# History
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# Completion
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Key bindings — emacs-style by default; uncomment for vi
bindkey -e

# Path
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Sensible defaults
export LESS="-R -F -X -i"
export PAGER=less

# Aliases that don't change semantics
alias ll='ls -lh'
alias la='ls -lAh'
alias g=git
alias gs='git status'
alias gd='git diff'

# Tool integrations
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v fzf >/dev/null && eval "$(fzf --zsh)" 2>/dev/null

# Per-host overrides (gitignored by convention)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
