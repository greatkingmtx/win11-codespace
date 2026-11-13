#!/usr/bin/env bash
set -euo pipefail
command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh
if [ ! -c /dev/net/tun ]; then
  sudo mkdir -p /dev/net
  sudo mknod /dev/net/tun c 10 200
  sudo chmod 666 /dev/net/tun
fi
if ! pgrep -x tailscaled >/dev/null; then
  sudo mkdir -p /var/lib/tailscale
  sudo nohup tailscaled --state=/var/lib/tailscale/tailscaled.state >/tmp/tailscaled.log 2>&1 &
  sleep 3
fi
if [ -n "${TS_AUTH_KEY:-}" ]; then
  sudo tailscale up --hostname=win11-codespace --authkey="$TS_AUTH_KEY"
else
  sudo tailscale up --hostname=win11-codespace
fi
tailscale ip -4
sudo tailscale serve --bg --tcp=3389 tcp://127.0.0.1:3389
