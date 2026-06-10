# Homebrew — macOS (Apple Silicon) or Linuxbrew, if present. No-op otherwise.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Add .NET Core SDK tools
export PATH="$PATH:$HOME/.dotnet/tools"
