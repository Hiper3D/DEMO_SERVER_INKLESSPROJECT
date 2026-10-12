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
  -> Nginx reverse proxy on 127.0.0.1:8080
  -> application published on 127.0.0.1:3000
  -> app container
  -> PostgreSQL and Redis over the private Compose network

HTTPS terminates at ngrok. Nginx listens only on loopback port 8080
and forwards requests to the Rails application on loopback port 3000.
The unused default Nginx site is disabled; no public port 80 listener
is required for this tunnel-based setup.

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
  --max-time 120 http://127.0.0.1:8080/
sudo nginx -t
systemctl is-enabled nginx
systemctl is-active nginx
sudo ss -ltnp | grep -E ':(80|8080|3000)\b' || true
sudo tail -n 20 /var/log/nginx/access.log
```

Database and Redis ports should not be published to the host or Internet
unless a documented requirement specifically calls for that.

## Start ngrok automatically with systemd

The file `deploy/systemd/ngrok.service.example` is a template, not a
ready-to-install service. It forwards ngrok to Nginx at `127.0.0.1:8080`;
Nginx forwards requests to Rails at `127.0.0.1:3000`.

For startup after a VM reboot, the deployment also includes:

- `deploy/scripts/wait-for-inkless.sh` — waits for the application to
  respond successfully through Nginx before allowing ngrok to start.
- `deploy/systemd/ngrok.service.d/override.conf.example` — makes the
  ngrok service depend on Docker and Nginx and runs the readiness script
  before starting the tunnel.

### Install the readiness check and override

1. Install the readiness script:

```bash
sudo install -m 755 deploy/scripts/wait-for-inkless.sh /usr/local/bin/wait-for-inkless.sh
```

2. Install the systemd override:

```bash
sudo mkdir -p /etc/systemd/system/ngrok.service.d
sudo install -m 644 deploy/systemd/ngrok.service.d/override.conf.example /etc/systemd/system/ngrok.service.d/override.conf
```

3. For a new installation, copy `deploy/systemd/ngrok.service.example`
   to `/etc/systemd/system/ngrok.service` and replace its placeholders
   with the actual Linux username, project path and ngrok domain. Do not
   overwrite an existing working service without inspecting it first.
4. Ensure the ngrok configuration is readable by the service user.
   Keep the authentication token in the local ngrok configuration file;
   never commit it to this repository.
5. Reload systemd and enable/start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ngrok.service
systemctl is-enabled ngrok
systemctl is-active ngrok
sudo systemctl status ngrok --no-pager
sudo systemctl cat ngrok
sudo journalctl -u ngrok -b --no-pager
```

### Verify readiness and public access

```bash
sudo /usr/local/bin/wait-for-inkless.sh
curl -sS -o /dev/null -w 'HTTP %{http_code}, %{time_total}s\n' --max-time 20 -H 'ngrok-skip-browser-warning: 1' https://YOUR-NGROK-DOMAIN/
```

Replace `YOUR-NGROK-DOMAIN` with the assigned public hostname. Do not
start a second ngrok process using the same reserved endpoint.

An HTTP 200 response confirms successful access at the time of testing;
it does not guarantee continuous uptime.

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
