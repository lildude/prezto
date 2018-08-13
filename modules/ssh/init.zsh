#
# Provides for an easier use of SSH by setting up ssh-agent.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Return if requirements are not found.
if (( ! $+commands[ssh-agent] )); then
  return 1
fi

if [[ "$OSTYPE" == darwin* ]]; then
    _ssh_add_cmd="ssh-add -A"
else
    _ssh_add_cmd="ssh-add"
fi

# Set the path to the SSH directory.
_ssh_dir="$HOME/.ssh"

# Set the path to the environment file if not set by another module.
_ssh_agent_env="${_ssh_agent_env:-${TMPDIR:-/tmp}/ssh-agent.env.$UID}"

# Set the path to the persistent authentication socket.
_ssh_agent_sock="${TMPDIR:-/tmp}/ssh-agent.sock.$UID"

# Start ssh-agent if not started.
if [[ ! -S "$SSH_AUTH_SOCK" ]]; then
  # Export environment variables.
  source "$_ssh_agent_env" 2> /dev/null
  eval "$(ssh-agent -s)"
fi

# Load identities.
if ssh-add -l 2>&1 | grep -q 'The agent has no identities'; then
  zstyle -a ':prezto:module:ssh:load' identities '_ssh_identities'
  # Check for Linux system and ssh-askpass presence
  if [[ "$OSTYPE" == linux* ]] && [[ ! -a /usr/lib/ssh/x11-ssh-askpass ]]; then
    ssh-add "${_ssh_identities:+$_ssh_dir/${^_ssh_identities[@]}}"  2> /dev/null
  else
    ssh-add "${_ssh_identities:+$_ssh_dir/${^_ssh_identities[@]}}"  < /dev/null 2> /dev/null
  fi
fi

# Clean up.
unset _ssh_{dir,identities} _ssh_agent_{env,sock} _ssh_add_cmd
