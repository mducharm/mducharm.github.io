---
title: Steam Deck SSH Setup
description: Persistent SSH access with key auth, optional Tailscale, and survival across SteamOS updates.
date: 2026-03-23
---

Guide to setting up persistent SSH access to a Steam Deck from another computer (e.g., macOS). Uses SSH key authentication with password login disabled for security. Optionally uses Tailscale for a stable address that works from any network.

## 1. Switch to Desktop Mode

On the Steam Deck:

1. Press the **Steam** button (or hold the **Power** button)
2. Select **Power** > **Switch to Desktop Mode**
3. Open **Konsole** (search for it in the application launcher in the bottom-left)

> To return to Gaming Mode later, double-tap the **Return to Gaming Mode** icon on the desktop.

## 2. Set a Password for the deck User

The `deck` user has no password by default. You need one for `sudo`:

```bash
passwd
```

Choose a strong password. You'll use this for `sudo` commands, not for SSH login.

## 3. Enable the SSH Server

```bash
sudo systemctl enable --now sshd
```

This starts SSH immediately and ensures it starts on every boot.

## 4. Install Tailscale (Optional)

> **Skip this section** if you only need SSH on your local network. Tailscale is useful if you want a stable hostname that works from anywhere — not just your home Wi-Fi.

Tailscale gives the Steam Deck a stable IP and hostname. We install it to the home directory so it survives SteamOS updates.

### Download and install

```bash
mkdir -p ~/.local/bin

curl -fsSL https://tailscale.com/install.sh | sh
```

> If the install script doesn't work on SteamOS, use the standalone tarball instead:
>
> ```bash
> curl -fsSL "https://pkgs.tailscale.com/stable/tailscale_latest_amd64.tgz" -o /tmp/tailscale.tgz
> tar -xzf /tmp/tailscale.tgz -C /tmp
> cp /tmp/tailscale_*/tailscale ~/.local/bin/
> cp /tmp/tailscale_*/tailscaled ~/.local/bin/
> rm -rf /tmp/tailscale*
> ```

### Create a systemd user service for Tailscale

This ensures Tailscale starts on boot without needing root-installed packages:

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/tailscaled.service << 'EOF'
[Unit]
Description=Tailscale Daemon
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=%h/.local/bin/tailscaled \
  --state=%h/.local/share/tailscale/tailscaled.state \
  --socket=%h/.local/share/tailscale/tailscaled.sock \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --outbound-http-proxy-listen=localhost:1055
Restart=on-failure

[Install]
WantedBy=default.target
EOF

mkdir -p ~/.local/share/tailscale
```

> **Note:** This uses userspace networking mode since SteamOS may not allow creating TUN devices without root. If `tailscale up` doesn't work, try the root-based approach instead:
>
> ```bash
> sudo mkdir -p /etc/systemd/system
> sudo cat > /etc/systemd/system/tailscaled.service << 'EOF'
> [Unit]
> Description=Tailscale Daemon
> After=network-online.target
> Wants=network-online.target
>
> [Service]
> ExecStart=/home/deck/.local/bin/tailscaled \
>   --state=/home/deck/.local/share/tailscale/tailscaled.state
> Restart=on-failure
>
> [Install]
> WantedBy=multi-user.target
> EOF
> sudo systemctl enable --now tailscaled
> ```

### Start Tailscale

```bash
systemctl --user enable --now tailscaled

loginctl enable-linger deck

~/.local/bin/tailscale --socket=$HOME/.local/share/tailscale/tailscaled.sock up
```

Follow the link to authenticate with your Tailscale account. Once connected, your Steam Deck will appear in your Tailscale dashboard.

### Verify

```bash
~/.local/bin/tailscale --socket=$HOME/.local/share/tailscale/tailscaled.sock status
```

You should see your Steam Deck listed. Note the Tailscale IP (`100.x.x.x`) and the MagicDNS hostname (usually `steamdeck`).

### Optional: add a shell alias

```bash
echo 'alias tailscale="~/.local/bin/tailscale --socket=$HOME/.local/share/tailscale/tailscaled.sock"' >> ~/.bashrc
```

Then you can just run `tailscale status`, `tailscale up`, etc.

## 5. Get the Steam Deck's IP Address

```bash
ip -4 addr show wlan0 | grep inet
```

Note the IP (e.g., `192.168.1.x`). You may want to assign a static IP or DHCP reservation in your router so this doesn't change.

If you set up Tailscale in step 4, you can also use the MagicDNS hostname `steamdeck` or the Tailscale IP (`100.x.x.x` from `tailscale status`), which works from any network.

## 6. Set Up SSH Key Authentication (from your computer)

On your Mac/PC (not the Steam Deck):

### Generate a key (skip if you already have one)

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

Press Enter to accept the default location (`~/.ssh/id_ed25519`). Add a passphrase if you want extra local security.

### Copy the key to the Steam Deck

```bash
ssh-copy-id deck@<steam-deck-ip>
```

Replace `<steam-deck-ip>` with the local IP from step 5, or the Tailscale hostname `steamdeck` if you set that up.

This will ask for the `deck` password one last time. After this, key auth is set up.

### Test it

```bash
ssh deck@<steam-deck-ip>
```

You should connect without being prompted for a password.

## 7. Disable Password Authentication

Now that key auth works, lock down SSH to key-only access. On the **Steam Deck**:

```bash
sudo mkdir -p /etc/ssh/sshd_config.d
echo -e "PasswordAuthentication no\nKbdInteractiveAuthentication no" \
  | sudo tee /etc/ssh/sshd_config.d/no-password.conf
sudo systemctl restart sshd
```

Using a drop-in config file (`sshd_config.d/`) is more resilient to SteamOS updates than editing the main config directly.

## 8. Add an SSH Config Alias (optional, on your computer)

Add this to `~/.ssh/config` on your Mac/PC:

```
Host steamdeck
    HostName <steam-deck-ip>
    User deck
```

For `HostName`, use either:

- The **local IP** (e.g., `192.168.1.x`) — works on your home network
- The **Tailscale hostname** `steamdeck` — works from anywhere (if you set up step 4)

Now you can just run:

```bash
ssh steamdeck
```

## Surviving SteamOS Updates

SteamOS has a read-only root filesystem that gets replaced on major updates. Some things to know:

- **sshd enabled state** should persist across updates (systemd enables are stored in `/etc`, which is preserved)
- **Your password** may get reset on major updates — just run `passwd` again
- **The drop-in sshd config** in `/etc/ssh/sshd_config.d/` should persist, but verify after major updates
- **Your `~/.ssh/authorized_keys`** lives in the home directory and will survive updates
- **Tailscale** (if installed) — the binary and user service live in `~/.local/`, which survives updates. The systemd user service auto-starts via lingering. If Tailscale stops connecting, re-run `tailscale up`

If SSH stops working after an update, switch to Desktop Mode and re-run:

```bash
passwd
sudo systemctl enable --now sshd
# If you have Tailscale and it's down too:
systemctl --user restart tailscaled
tailscale up
```

## Troubleshooting

| Problem | Fix |
|---|---|
| Connection refused | Is sshd running? `sudo systemctl status sshd` |
| Permission denied | Check `~/.ssh/authorized_keys` exists on the Deck. Re-run `ssh-copy-id` if needed |
| Can't find Steam Deck | If using Tailscale: is it running on both devices? `tailscale status`. If using local IP: are both on the same network? Re-check with `ip -4 addr show wlan0` |
| Tailscale won't start | Check the service: `systemctl --user status tailscaled`. Check lingering: `loginctl show-user deck \| grep Linger` |
| Password stopped working | Expected if you disabled password auth. Use your SSH key |
| SSH broke after SteamOS update | See "Surviving SteamOS Updates" above |
