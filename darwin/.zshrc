########## Paths & basics (interactive) ##########
# LM Studio CLI
export PATH="$PATH:$HOME/.lmstudio/bin"

# TinyTeX (pdflatex, etc.)
export PATH="$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"

# Cache Homebrew prefix (tiny speed win; falls back if not defined)
BREW_PREFIX="${BREW_PREFIX:-/opt/homebrew}"

# Ensure Homebrew bin comes early (usually already handled by brew shellenv)
export PATH="/opt/homebrew/bin:$PATH"

########## Zsh options ##########
# History
setopt HIST_IGNORE_DUPS        # Don't save duplicate commands
setopt HIST_IGNORE_ALL_DUPS    # Remove older duplicate entries
setopt HIST_FIND_NO_DUPS       # Don't show duplicates in search
setopt HIST_SAVE_NO_DUPS       # Don't save duplicates to history file
setopt HIST_IGNORE_SPACE       # Don't save commands starting with space
setopt SHARE_HISTORY           # Share history between sessions
setopt APPEND_HISTORY          # Append to history file
setopt INC_APPEND_HISTORY      # Write to history immediately

# Directory navigation
setopt AUTO_CD                 # cd to directory by typing its name
setopt AUTO_PUSHD             # Push old directory to stack
setopt PUSHD_IGNORE_DUPS      # Don't push duplicates to stack

# Globbing
setopt EXTENDED_GLOB          # Extended glob patterns
setopt NO_CASE_GLOB          # Case insensitive globbing

########## Prompt / UI ##########
# Oh My Posh (guarded)
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config "$HOME/.poshthemes/catppuccin_frappe_custom.omp.json")"
fi

PROMPT_RAIN_INDEX=$(( SECONDS % 6 ))
precmd() { PROMPT_RAIN_INDEX=$(( SECONDS % 6 )); export PROMPT_RAIN_INDEX; }
export PROMPT_RAIN_INDEX

########## Completions & UX ##########
# Extra completions
fpath+=("$BREW_PREFIX/share/zsh-completions")

# Run compinit once per ~day for speed
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Better completion behavior
zstyle ':completion:*' menu select                          # Select completions with arrow keys
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # Case insensitive matching
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # Colored completions
zstyle ':completion:*:descriptions' format '[%d]'           # Group descriptions
zstyle ':completion:*' group-name ''                        # Group results by category

# Autosuggestions (ghost text)
if [ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
fi

# Syntax highlighting (load AFTER autosuggestions)
if [ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

########## Key bindings ##########
# Use vim key bindings
bindkey -v

# Better history search
bindkey '^R' history-incremental-search-backward
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Better editing
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^K' kill-line
bindkey '^U' kill-whole-line
bindkey '^W' backward-kill-word
bindkey '^?' backward-delete-char

########## Node / NVM (interactive only) ##########
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
  . "$NVM_DIR/bash_completion"
fi

########## Aliases ##########
# Config shortcuts
alias config='cd ~/.config'
alias nvim-conf="cd ~/.config/nvim"
alias zsh-conf="nvim ~/.zshrc"
alias prof-conf="nvim ~/.zprofile"

# Better defaults
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Directory shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# Python shortcuts
alias py='python3'
alias pip='python3 -m pip'
alias venv='python3 -m venv'

# Utilities
alias reload='source ~/.zshrc'
alias path='echo -e ${PATH//:/\\n}'
alias h='history'
alias c='clear'
alias q='exit'

########## Functions ##########
# Create and cd into directory
mkcd() { mkdir -p "$1" && cd "$1"; }

# Quick file/directory search
ff() { find . -name "*$1*" -type f; }
fd() { find . -name "*$1*" -type d; }

# Extract archives
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Git clone and cd
gclone() {
  git clone "$1" && cd "$(basename "$1" .git)"
}

########## Python: UTF-8 behavior without forcing a locale ##########
export PYTHONUTF8=1

########## Auto-venv with direnv (recommended) ##########
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

########## OPTIONAL fallback: auto-activate .venv on cd (no direnv) ##########
# Safe minimal chpwd hook. Leave enabled if you want auto-venv even without direnv.
autoload -U add-zsh-hook
_vnv_auto() {
  local venv_path=".venv"
  if [[ -f "$venv_path/bin/activate" ]]; then
    # Activate if not already active or pointing elsewhere
    if [[ -z "$VIRTUAL_ENV" || "$VIRTUAL_ENV" != "$(pwd)/$venv_path" ]]; then
      source "$venv_path/bin/activate"
    fi
  else
    # If leaving a project tree, deactivate
    if [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" != "${PWD}"* ]]; then
      deactivate 2>/dev/null || true
    fi
  fi
}
add-zsh-hook chpwd _vnv_auto
# Run once for the initial directory
_vnv_auto

########## Langflow uv env (guarded) ##########
if [ -f "$HOME/.langflow/uv/env" ]; then
  . "$HOME/.langflow/uv/env"
fi

########## Load local customizations (if any) ##########
if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi


# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/facundobautistabarbera/.lmstudio/bin"
# End of LM Studio CLI section

