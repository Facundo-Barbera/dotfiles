# ===== Homebrew (login-wide PATH) =====
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ===== JetBrains Toolbox scripts =====
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# ===== 1Password SSH agent =====
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# ===== Go user bin =====
export PATH="$HOME/go/bin:$PATH"

# ===== Rust/Cargo =====
if [ -d "$HOME/.cargo/bin" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# ===== Local user bin =====
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# ===== Default editor =====
export EDITOR=nvim
export VISUAL=nvim

# ===== History settings (login-wide) =====
export HISTSIZE=50000
export SAVEHIST=50000

