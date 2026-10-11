# Inkless Local VM Deployment

## Environment

- Virtualization: Oracle VirtualBox
- Guest OS: Ubuntu Server 24.04.5 LTS
- Deployment: Docker Engine and Docker Compose
- Application: Rails application
- Database: PostgreSQL 16
- Background jobs/cache: Redis 7 and Sidekiq
- Public access: ngrok HTTPS tunnel
- Firewall: UFW

Adjust this information if the actual environment changes.

## Request flow

Internet browser
  -> ngrok public HTTPS endpoint
  -> ngrok agent inside the Ubuntu VM
  -> application published on 127.0.0.1:3000
  -> app container
  -> PostgreSQL and Redis over the private Compose network

HTTPS terminates at ngrok. This lab does not configure a separate Nginx,
Apache or Caddy reverse-proxy service.

## Network and SSH

The VM uses VirtualBox NAT with a configured guest address of
10.0.2.15/24 and gateway 10.0.2.2. These are private guest-network
values, not a public Internet address.

The Windows host connects to SSH through the VirtualBox NAT port-forward:
host 127.0.0.1:2222 -> guest port 22.

Commands to verify the current configuration:

```bash
ip -4 addr
ip route
sudo netplan get
systemctl is-active ssh
sudo ufw status verbose
```

## Application services

The Compose project runs the app, PostgreSQL and Redis. The services use
restart: unless-stopped. Docker is enabled at system startup.

From the project directory:

```bash
sudo docker compose config -q
sudo docker compose ps
sudo docker compose logs --since=15m app
curl -sS -o /dev/null \
  -w 'HTTP %{http_code}, %{time_total}s\n' \
  --max-time 15 http://127.0.0.1:3000/
```

Database and Redis ports should not be published to the host or Internet
unless a documented requirement specifically calls for that.

## Start ngrok automatically with systemd

The file `deploy/systemd/ngrok.service.example` is a TEMPLATE only.
It contains placeholders and is not ready to install unchanged.

1. Copy it to `/etc/systemd/system/ngrok.service`.
2. Replace `YOUR_LINUX_USERNAME`, the home/project path if different,
   and `YOUR-NGROK-DOMAIN` with the actual values.
3. Ensure the ngrok configuration is readable by that service user.
   Keep the authentication token in the local ngrok configuration file;
   never add it to this repository.
4. Reload systemd and enable/start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ngrok.service
systemctl is-enabled ngrok
systemctl is-active ngrok
sudo systemctl status ngrok --no-pager
sudo journalctl -u ngrok -b --no-pager
```

Do not start a second ngrok process with the same reserved endpoint.
The current deployment already has a systemd service; inspect it before
replacing or reinstalling it.

## Verify public access

```bash
curl -sS -L -o /dev/null \
  -w 'Public HTTPS: HTTP %{http_code}, %{time_total}s\n' \
  --max-time 30 \
  https://YOUR-NGROK-DOMAIN.ngrok-free.dev/
```

An HTTP 200 result verifies that the requested URL returned successfully
at that moment. It does not prove continuous uptime.

## Security

- Keep `.env`, credentials, tokens, private keys and database passwords out
  of Git.
- Confirm `.env` is ignored before committing.
- Keep PostgreSQL and Redis on the private Compose network.
- UFW is configured to deny incoming traffic by default and allow SSH.
- Review the effective firewall and Docker port mappings before changing
  networking rules.

## Limitations and troubleshooting

This is a local lab deployment, not independent cloud hosting. It depends
on the Windows laptop, power, Internet connection, VirtualBox and ngrok.
The public tunnel may become unavailable during outages or maintenance.

During testing on 2026-10-11, intermittent slow Rails responses, Redis
read timeouts and Linux kernel soft-lockup warnings were observed. After
reducing the VM from two virtual CPUs to one, later samples improved, but
this is not a long-duration stability guarantee.

Useful diagnostics:

```bash
uptime
free -h
vmstat 1 5
sudo docker stats --no-stream
sudo docker compose logs --since=15m app
sudo journalctl -k --since "10 minutes ago" --no-pager
sudo journalctl -u ngrok --since "10 minutes ago" --no-pager
```

Capture fresh screenshots and logs from the actual machine for an
assessment. Do not represent old samples as current test evidence.
