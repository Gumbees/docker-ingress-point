# Docker Ingress Point - Standalone Traefik

A standalone Traefik reverse proxy setup with automatic SSL certificates via Let's Encrypt and Cloudflare DNS challenge.

## Features

- **Traefik Reverse Proxy**: Latest version with dashboard on configurable ports
- **HTTP/HTTPS Access**: Ports 80 and 443 with automatic HTTPS redirect
- **SSL/TLS Certificates**: Automatic Let's Encrypt certificates via Cloudflare DNS challenge
- **Docker Service Discovery**: Automatically discovers services with `traefik.enable=true` label
- **Multi-Provider Support**: Works with both Docker Compose and Docker Swarm
- **Network Isolation**: Dedicated network for Traefik with connections to app networks for service discovery
- **Multi-Network Discovery**: Connect to multiple app networks dynamically without config changes
- **Netbird VPN**: Zero-configuration VPN client for secure remote access
- **Environment-based Configuration**: Full environment variable support via `.env` file

### Netbird
- **Network Mode**: Connected to `containers_bastion` external network
- **VPN Type**: WireGuard-based mesh VPN with zero-configuration setup
- **Security**: Privileged container with `NET_ADMIN` and `SYS_ADMIN` capabilities
- **Configuration**: Persistent configuration storage via named volume
- **Management**: Requires setup key from Netbird management console
- **Features**: Automatic peer discovery, health checks, TUN/TAP device access
- **Container Name**: `${CONTAINER_NAME_PREFIX}-netbird`

## Quick Start

1. **Create external app networks** (if using multi-network setup):
   ```bash
   # Create external app networks
   docker network create media_center_apps
   docker network create immich-app-network
   docker network create containers_bastion
   # containers-ingress network is created automatically by docker-compose
   ```

2. **Setup Environment**:
   ```bash
   # Copy the example environment configuration
   cp env.example .env
   # Edit .env with your configuration
   nano .env
   ```

3. **Configure Netbird** (optional, if using VPN):
   ```bash
   # Get your setup key from Netbird management console
   # 1. Log into your Netbird management interface
   # 2. Add a new peer and copy the setup key
   # 3. Add the setup key to your .env file:
   # NETBIRD_SETUP_KEY=your-setup-key-here
   ```

4. **Start the services**:
   ```bash
   docker-compose up -d
   ```

5. **Connect Traefik to additional app networks** (optional):
   ```bash
   # Connect Traefik to other app networks as needed
   docker network connect your_other_app_network ${CONTAINER_NAME_PREFIX}-traefik
   ```

6. **Access Traefik Dashboard**:
   ```bash
   # Access via hostname (customize via TRAEFIK_DASHBOARD_HOST in .env)
   open http://traefik.localhost:8080
   
   # Or via static IP if configured (replace with your TRAEFIK_IP)
   open http://192.168.180.10:8080
   ```

## Environment Configuration

Create a `.env` file with the following variables:

### Basic Configuration
- `CONTAINER_NAME_PREFIX`: Prefix for all containers and volumes (default: `traefik`)
- `TZ`: Timezone for all containers (default: `America/New_York`)
- `CONFIG_BASE`: Base path for volume mounts (default: `/data/traefik`)

### Traefik Configuration
- `TRAEFIK_DASHBOARD_HOST`: Dashboard hostname (default: `traefik.localhost`)
- `TRAEFIK_DASHBOARD_TLS`: Enable TLS for dashboard (default: `false`)
- `TRAEFIK_LOG_LEVEL`: Logging level (default: `INFO`)
- `TRAEFIK_ACCESS_LOG`: Enable access logging (default: `false`)
- `TRAEFIK_INSECURE_API`: Enable insecure API access (default: `false`)

### Network Configuration
- External app networks must be created beforehand (optional):
  - `media_center_apps`: For media center services discovery by Traefik
  - `immich-app-network`: For Immich services discovery by Traefik
  - `containers_bastion`: For Netbird VPN client networking
- Services must use `traefik.enable=true` label to be discovered
- `TRAEFIK_IP` environment variable sets the static IP address (if using ipvlan)

### ACME/SSL Configuration
- `ACME_EMAIL`: Email address for Let's Encrypt certificate registration
- `ACME_CA_SERVER`: ACME server URL (staging or production)
- `CF_API_EMAIL`: Cloudflare account email
- `CF_API_KEY`: Cloudflare Global API Key for DNS challenge
- `CF_DNS_API_TOKEN`: Cloudflare API Token for DNS challenge (recommended)
- `ACME_VOLUME_TYPE`, `ACME_VOLUME_OPTIONS`: Certificate storage volume configuration

### Volume Configuration
- ACME certificates stored in persistent volume with custom mount point support
- All other configuration is managed via command-line arguments

### Netbird VPN Configuration
- `NETBIRD_SETUP_KEY`: Setup key from Netbird management console (required)
- `NETBIRD_HOSTNAME`: Optional custom hostname for this peer
- `NETBIRD_LOG_LEVEL`: Logging level (debug, info, warn, error; default: info)

**Note**: Netbird runs on the `containers_bastion` network, which must be created externally. This provides network isolation for VPN traffic separate from Traefik's service discovery networks.

## Network Configuration

- **traefik_public**: Main network for Traefik service discovery
- **media_center_apps**: External app network for media center services (optional)
- **immich-app-network**: External app network for Immich services (optional)
- **containers_bastion**: External app network for Netbird VPN client (optional)
- **Additional App Networks**: Connect Traefik to more app networks dynamically as needed

### Network Separation Strategy
- **Service Discovery**: App networks are where Traefik finds services to route
- **VPN Networking**: Netbird runs on dedicated `containers_bastion` network for isolated VPN connectivity
- **Infrastructure Integration**: Traefik integrates directly with your Docker infrastructure

### Prerequisites
App networks must be created externally before starting services (if using multi-network setup):
```bash
# Create required app networks
docker network create media_center_apps
docker network create immich-app-network
docker network create containers_bastion
# Add other app networks as needed
```

## Cloudflare DNS Challenge Setup

To use automatic SSL certificates with Let's Encrypt via Cloudflare DNS challenge, you need to configure Cloudflare API access:

### Step 1: Domain Setup in Cloudflare
1. **Add your domain** to Cloudflare (if not already added)
2. **Update nameservers** to point to Cloudflare
3. **Verify DNS records** are working correctly

### Step 2: Get Cloudflare API Credentials
You have two options for API authentication:

#### Option A: Global API Key (Recommended for simplicity)
1. **Log into Cloudflare Dashboard**
2. **Go to Profile > API Tokens**
3. **In "API Keys" section, find "Global API Key"**
4. **Click "View"** and copy the key
5. **Use your Cloudflare email and this Global API Key** in your `.env` file

#### Option B: Custom API Token (More secure)
1. **Log into Cloudflare Dashboard**
2. **Go to Profile > API Tokens**
3. **Click "Create Token"**
4. **Choose "Custom token"**
5. **Configure permissions:**
   - **Permissions:** `Zone:Read, DNS:Edit`
   - **Zone Resources:** `Include - All zones` (or specific zone)
   - **Account Resources:** `Include - All accounts`
6. **Click "Continue to summary"** and **"Create Token"**
7. **Copy the token** and use it as `CF_API_KEY` in your `.env` file
8. **For custom tokens, you can use either approach:**
   ```bash
   # Option B1: Use token as API key (simpler)
   CF_API_EMAIL=your-cloudflare-email@example.com
   CF_API_KEY=your-custom-token-here
   
   # Option B2: Use dedicated token variables (more secure)
   # Leave CF_API_EMAIL and CF_API_KEY empty and add:
   CF_DNS_API_TOKEN=your-custom-token-here
   CF_ZONE_API_TOKEN=your-custom-token-here
   ```

### Step 3: Configure Environment Variables
Update your `.env` file with:
```bash
# ACME configuration
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

```yaml
      - "traefik.http.routers.your-service.tls.domains[0].main=example.com"
      - "traefik.http.routers.your-service.tls.domains[0].sans=*.example.com"
```

### Service Discovery Control

Traefik only discovers services that you explicitly enable:

1. **Services behind Traefik** must have `traefik.enable=true` and be on app networks
2. **Services NOT behind Traefik** should not have the enable label
3. **Example of a service that should NOT be discovered**:

```yaml
services:
  direct-access-service:
    # ... your service configuration
    # NO traefik.enable=true label
    networks:
      - your_other_network  # Not connected to Traefik's app networks
    # This service will not be discovered by Traefik
```

4. **Example of a service behind Traefik**:

```yaml
services:
  proxied-service:
    # ... your service configuration
    labels:
      - "traefik.enable=true"  # Required for Traefik discovery
      - "traefik.http.routers.proxied.rule=Host(`proxied.example.com`)"
      - "traefik.http.routers.proxied.entrypoints=web"
      - "traefik.http.services.proxied.loadbalancer.server.port=8080"
    networks:
      - traefik_public  # Must be on same network as Traefik
```

## Health Monitoring

Traefik includes health checks:

```bash
# Check service health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# View health check logs
docker inspect ${CONTAINER_NAME_PREFIX}-traefik --format='{{json .State.Health}}'
```

## Configuration Files

- `docker-compose.yml`: Main service definitions with Traefik configuration via command-line arguments
- `env.example`: Example environment configuration (copy to `.env`)
- `.gitignore`: Git ignore rules for environment files and development artifacts

### Managing Traefik Configuration

Traefik is configured entirely through command-line arguments in the docker-compose.yml file. To modify Traefik settings:

1. Edit the `command:` section in the docker-compose.yml file
2. Restart the container: `docker-compose restart traefik`

Key configuration options available via environment variables:
- `TRAEFIK_INSECURE_API`: Enable/disable insecure API access
- `TRAEFIK_LOG_LEVEL`: Set logging level (INFO, DEBUG, WARN, ERROR)
- `TRAEFIK_ACCESS_LOG`: Enable/disable access logging

## Maintenance

### Starting and Stopping
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