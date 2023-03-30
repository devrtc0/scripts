#!/usr/bin/env sh

set -x SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
ssh-agent -a $SSH_AUTH_SOCK
