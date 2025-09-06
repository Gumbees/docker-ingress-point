# Docker Ingress Point - Standalone Traefik

A standalone Traefik reverse proxy setup with automatic SSL certificates via Let's Encrypt and Cloudflare DNS challenge.

## Features

- **Traefik Reverse Proxy**: Latest version with dashboard on port 8081
- **HTTP/HTTPS Access**: Ports 80 and 443 with automatic HTTPS redirect
- **SSL/TLS Certificates**: Automatic Let's Encrypt certificates via Cloudflare DNS challenge
- **Docker Service Discovery**: Automatically discovers services with `traefik.enable=true` label
- **Remote Docker Endpoint**: Connects to remote Docker daemon at `100.101.14.75:2375`
- **Environment-based Configuration**: Full environment variable support via `.env` file

## Quick Start

1. **Create environment file**:
   ```bash
   cp env.example .env
   # Edit .env with your configuration
   nano .env
   ```

2. **Start Traefik**:
   ```bash
   docker-compose up -d
   ```

3. **Access the dashboard**:
   ```bash
   open http://traefik.localhost:8081
   ```

## Environment Configuration

Create a `.env` file with the following variables:

```bash
# Basic Configuration
CONTAINER_NAME_PREFIX=traefik
TZ=America/New_York
CONFIG_BASE=/data/traefik

# Traefik Configuration
TRAEFIK_DASHBOARD_HOST=traefik.localhost
TRAEFIK_LOG_LEVEL=INFO
TRAEFIK_ACCESS_LOG=false

# ACME/SSL Configuration (Required)
ACME_EMAIL=your-email@example.com
ACME_CA_SERVER=https://acme-v02.api.letsencrypt.org/directory

# Cloudflare API Credentials (Required - choose one method)
# Method 1: API Token (Recommended)
CF_DNS_API_TOKEN=your-cloudflare-api-token

# Method 2: Global API Key (Alternative)
CF_API_EMAIL=your-cloudflare-email@example.com
CF_API_KEY=your-cloudflare-global-api-key

# Volume Configuration (Optional)
ACME_VOLUME_TYPE=
ACME_VOLUME_OPTIONS=
```

## Adding Services to Traefik

Services must have the `traefik.enable=true` label and be on the `traefik_public` network:

```yaml
services:
  your-service:
    image: your-image
    networks:
      - traefik_public
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.your-service.rule=Host(`your-service.example.com`)"
      - "traefik.http.routers.your-service.entrypoints=websecure"
      - "traefik.http.routers.your-service.tls=true"
      - "traefik.http.routers.your-service.tls.certresolver=letsencrypt"
      - "traefik.http.services.your-service.loadbalancer.server.port=8080"
```

## Management Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Update and restart
docker-compose pull
docker-compose up -d --force-recreate

# Check status
docker-compose ps
```

## Security Notes

- **Dashboard Security**: The dashboard runs in insecure mode by default (`--api.insecure=true`). For production, change this to `false` and configure proper authentication.
- **Remote Docker Access**: The configuration connects to a remote Docker daemon at `100.101.14.75:2375`. Ensure this endpoint is secure and accessible.
- **Certificate Storage**: ACME certificates are stored in a persistent volume for reliability.

## Troubleshooting

### Common Issues

1. **Services not discovered**:
   - Ensure services have `traefik.enable=true` label
   - Verify services are on the `traefik_public` network
   - Check that the remote Docker endpoint is accessible

2. **SSL certificate issues**:
   - Use staging server first: `ACME_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory`
   - Verify Cloudflare API credentials have correct permissions
   - Check DNS propagation

3. **Network connectivity**:
   - Verify remote Docker endpoint is accessible: `telnet 100.101.14.75 2375`
   - Check that the `traefik_public` network was created: `docker network ls | grep traefik_public`

### Debug Commands

```bash
# Check Traefik configuration
docker exec traefik-ingress traefik version

# View discovered services
curl -s http://localhost:8081/api/http/services | jq 'keys[]'

# Check certificate status
docker exec traefik-ingress ls -la /acme/

# Test remote Docker connectivity
docker -H tcp://100.101.14.75:2375 ps
```

## Production Considerations

1. **Change API security**: Set `--api.insecure=false` and configure authentication
2. **Use production ACME server**: Change `ACME_CA_SERVER` to production URL
3. **Secure remote Docker access**: Use TLS certificates for remote Docker endpoint
4. **Monitor logs**: Set up log aggregation for production monitoring
5. **Backup certificates**: Regularly backup the ACME volume

## Migration from Docker Swarm

This standalone setup replaces the previous Docker Swarm configuration. Key differences:

- Uses Docker Compose instead of Docker Stack
- Connects to remote Docker daemon instead of local Swarm API
- Simplified network configuration with single `traefik_public` network
- Removed Swarm-specific labels and deployment configurations