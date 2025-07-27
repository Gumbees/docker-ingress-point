# Docker Ingress Point

This docker-compose setup provides a Traefik reverse proxy that can be dynamically connected to multiple application networks for service discovery and routing.

## Features

- **Traefik Reverse Proxy**: Latest version with dashboard on configurable ports
- **HTTP/HTTPS Access**: Ports 80 and 443 available on static IP for external access
- **Automatic HTTPS Redirect**: All HTTP traffic automatically redirected to HTTPS for security
- **SSL/TLS Certificates**: Automatic Let's Encrypt certificates via Cloudflare DNS challenge
- **Network Isolation**: Dedicated network for Traefik with connections to app networks for service discovery
- **Multi-Network Discovery**: Connect to multiple app networks dynamically without config changes
- **Netbird VPN**: Zero-configuration VPN client for secure remote access
- **Environment-based Configuration**: Full environment variable support via `.env` file
- **Health Checks**: Built-in health monitoring for services
- **Production Ready**: Proper restart policies, logging, and security configurations

## Services

### Traefik
- **Ports**: Available on static IP address (HTTP: 80, HTTPS: 443, Dashboard: 8080)
- **Dashboard**: Available at configured host (default: `http://traefik.localhost:8080`)
- **Configuration**: Managed via command-line arguments in docker-compose.yml
- **Networks**: 
  - `containers-ingress`: Dedicated ipvlan network with static IP on VLAN 180
  - `media_center_apps`: App network for service discovery
  - `immich-app-network`: App network for Immich services
  - Additional app networks can be connected dynamically
- **Service Discovery**: Only discovers services on app networks with `traefik.enable=true`
- **Features**: Docker provider, health checks, configurable logging
- **Container Name**: `${CONTAINER_NAME_PREFIX}-traefik`

### Netbird
- **Network Mode**: Connected to `containers_bastion` external network
- **VPN Type**: WireGuard-based mesh VPN with zero-configuration setup
- **Security**: Privileged container with `NET_ADMIN` and `SYS_ADMIN` capabilities
- **Configuration**: Persistent configuration storage via named volume
- **Management**: Requires setup key from Netbird management console
- **Features**: Automatic peer discovery, health checks, TUN/TAP device access
- **Container Name**: `${CONTAINER_NAME_PREFIX}-netbird`

## Quick Start

1. **Create required networks**:
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
   
   # Edit .env file with your specific configuration
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
   # Access via static IP (replace with your TRAEFIK_IP)
   open http://192.168.180.10:8080
   
   # Or via hostname if configured (customize via TRAEFIK_DASHBOARD_HOST in .env)
   open http://traefik.localhost:8080
   ```

## Environment Configuration

The setup uses a comprehensive environment configuration system. Key variables include:

### Basic Configuration
- `CONTAINER_NAME_PREFIX`: Prefix for all containers and volumes (default: `ingress`)
- `TZ`: Timezone for all containers (default: `America/New_York`)
- `CONFIG_BASE`: Base path for volume mounts (default: `/data/docker-ingress-point`)

### Traefik Configuration
- `TRAEFIK_HTTP_PORT`, `TRAEFIK_HTTPS_PORT`, `TRAEFIK_DASHBOARD_PORT`: Port configuration
- `TRAEFIK_DASHBOARD_HOST`: Dashboard hostname (default: `traefik.localhost`)
- `TRAEFIK_LOG_LEVEL`: Logging level (default: `INFO`)

### Network Configuration
- External app networks must be created beforehand:
  - `media_center_apps`: For media center services discovery by Traefik
  - `immich-app-network`: For Immich services discovery by Traefik
  - `containers_bastion`: For Netbird VPN client networking
- Traefik runs on ipvlan network with static IP address on VLAN 180
- Services must use `traefik.enable=true` label to be discovered
- `TRAEFIK_IP` environment variable sets the static IP address

### ACME/SSL Configuration
- `ACME_EMAIL`: Email address for Let's Encrypt certificate registration
- `ACME_CA_SERVER`: ACME server URL (staging or production)
- `CF_API_EMAIL`: Cloudflare account email
- `CF_API_KEY`: Cloudflare Global API Key for DNS challenge
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

- **containers-ingress**: Dedicated ipvlan network for Traefik with direct VLAN 180 access
- **media_center_apps**: External app network for media center services
- **immich-app-network**: External app network for Immich services
- **containers_bastion**: External app network for Netbird VPN client
- **Additional App Networks**: Connect Traefik to more app networks dynamically as needed

### Network Separation Strategy
- **VLAN Access**: Traefik gets its own IP address on VLAN 180 via ipvlan networking
- **Direct Network Integration**: No port forwarding needed, Traefik has direct network presence
- **Service Discovery**: App networks (`media_center_apps`, `immich-app-network`) are where Traefik finds services to route
- **VPN Networking**: Netbird runs on dedicated `containers_bastion` network for isolated VPN connectivity
- **Infrastructure Integration**: Traefik integrates directly with your VLAN infrastructure

### Prerequisites
App networks must be created externally before starting services:
```bash
# Create required app networks
docker network create media_center_apps
docker network create immich-app-network
docker network create containers_bastion
# Add other app networks as needed
# Note: containers-ingress ipvlan network is created automatically by docker-compose
```

### Network Configuration Requirements
Before starting, ensure your `.env` file has the correct VLAN configuration:
```bash
# Example .env configuration
INGRESS_PARENT_INTERFACE=bond0.180
INGRESS_SUBNET=192.168.180.0/24
INGRESS_GATEWAY=192.168.180.1
TRAEFIK_IP=192.168.180.10
```

**Important**: 
- Adjust the subnet and gateway to match your VLAN 180 network configuration
- Set `TRAEFIK_IP` to a static IP address within your VLAN 180 subnet
- Ensure the chosen IP address doesn't conflict with existing devices

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

# Cloudflare API credentials
CF_API_EMAIL=your-cloudflare-email@example.com
CF_API_KEY=your-cloudflare-global-api-key
```

### Step 4: Testing with Staging Environment
**IMPORTANT:** Start with Let's Encrypt staging environment to avoid rate limits:

1. **Set staging server** in your `.env`:
   ```bash
   ACME_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory
   ```

2. **Test your configuration** with a service

3. **Switch to production** once working:
   ```bash
   ACME_CA_SERVER=https://acme-v02.api.letsencrypt.org/directory
   ```

4. **Clear staging certificates** and restart:
   ```bash
   docker-compose down
   docker volume rm ingress-acme-certificates
   docker-compose up -d
   ```

### Troubleshooting Cloudflare Setup
- **DNS propagation:** Allow 5-10 minutes for DNS changes to propagate
- **API permissions:** Ensure your API key/token has `Zone:Read` and `DNS:Edit` permissions
- **Zone settings:** Check that your domain's SSL/TLS setting is "Full (strict)" for best security
- **Rate limits:** Let's Encrypt has rate limits - use staging environment for testing

### Connecting Traefik to App Networks
Traefik automatically discovers services on any network it's connected to. This dynamic approach allows you to:
- Add new app networks without modifying the compose file
- Isolate different application stacks on separate networks
- Connect/disconnect networks as needed without restarting Traefik

After Traefik is running, connect it to your app networks:
```bash
# Connect Traefik to any app network (repeat for multiple networks)
docker network connect your_app_network ${CONTAINER_NAME_PREFIX}-traefik

# Example: Connect to media center network
docker network connect media_center_apps ${CONTAINER_NAME_PREFIX}-traefik

# List all networks Traefik is connected to
docker inspect ${CONTAINER_NAME_PREFIX}-traefik | jq '.[0].NetworkSettings.Networks | keys[]'

# Disconnect from a network if needed
docker network disconnect your_app_network ${CONTAINER_NAME_PREFIX}-traefik

### Automating Network Connections
You can automate connecting to multiple networks with a script:
```bash
#!/bin/bash
# connect-traefik-networks.sh
TRAEFIK_CONTAINER="${CONTAINER_NAME_PREFIX:-ingress}-traefik"
APP_NETWORKS=("media_center_apps" "app1_network" "app2_network")

for network in "${APP_NETWORKS[@]}"; do
    echo "Connecting Traefik to $network..."
    docker network connect "$network" "$TRAEFIK_CONTAINER" 2>/dev/null || echo "Already connected to $network"
done

echo "Traefik is now connected to:"
docker inspect "$TRAEFIK_CONTAINER" | jq -r '.[0].NetworkSettings.Networks | keys[]'
```
```

## Adding Services to Traefik

### Network-Specific Service Discovery

**IMPORTANT**: Traefik will only discover services that:
1. Have `traefik.enable=true` label (since `exposedbydefault=false`)
2. Are connected to the same app networks as Traefik
3. Traefik runs on its own isolated network and connects only to app networks for service discovery

**Network Isolation**: Since Traefik doesn't specify a default network with `--providers.docker.network`, it will attempt to discover services on ALL networks it's connected to. However, by using `--providers.docker.exposedbydefault=false`, only services with `traefik.enable=true` are discovered. This gives you complete control over which services are exposed, regardless of which networks they're on.

### Basic HTTP Service
To add a service behind Traefik, add these labels:

```yaml
services:
  your-service:
    # ... your service configuration
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.your-service.rule=Host(`your-service.example.com`)"
      - "traefik.http.routers.your-service.entrypoints=web"
      - "traefik.http.services.your-service.loadbalancer.server.port=YOUR_SERVICE_PORT"
    networks:
      - media_center_apps  # Use the same app network that Traefik is connected to
```

### Immich Service Example
For Immich services with HTTPS, use the dedicated network:

```yaml
services:
  immich-server:
    # ... your service configuration
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.immich.rule=Host(`immich.example.com`)"
      - "traefik.http.routers.immich.entrypoints=websecure"
      - "traefik.http.routers.immich.tls=true"
      - "traefik.http.routers.immich.tls.certresolver=letsencrypt"
      - "traefik.http.services.immich.loadbalancer.server.port=3001"
      # Optional: Redirect HTTP to HTTPS
      - "traefik.http.routers.immich-http.rule=Host(`immich.example.com`)"
      - "traefik.http.routers.immich-http.entrypoints=web"
      - "traefik.http.routers.immich-http.middlewares=redirect-to-https"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
    networks:
      - immich-app-network  # Use the same app network that Traefik is connected to
```

### HTTPS Service with Automatic SSL
For HTTPS with automatic Let's Encrypt certificates using Cloudflare DNS challenge:

```yaml
services:
  your-service:
    # ... your service configuration
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.your-service.rule=Host(`your-service.example.com`)"
      - "traefik.http.routers.your-service.entrypoints=websecure"
      - "traefik.http.routers.your-service.tls=true"
      - "traefik.http.routers.your-service.tls.certresolver=letsencrypt"
      - "traefik.http.services.your-service.loadbalancer.server.port=YOUR_SERVICE_PORT"
      # Optional: Redirect HTTP to HTTPS
      - "traefik.http.routers.your-service-http.rule=Host(`your-service.example.com`)"
      - "traefik.http.routers.your-service-http.entrypoints=web"
      - "traefik.http.routers.your-service-http.middlewares=redirect-to-https"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
    networks:
      - media_center_apps  # Use the same app network that Traefik is connected to
```

### Wildcard Certificate
For wildcard certificates (*.example.com), configure the main domain in your DNS provider and add:

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
      - media_center_apps  # Must be on same app network as Traefik
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
- `connect-networks.sh`: Helper script for connecting Traefik to multiple app networks

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

# Stop and remove volumes
docker-compose down -v
```

### Updates
```bash
# Pull latest images
docker-compose pull

# Recreate containers with new images
docker-compose up -d --force-recreate
```

## Security Considerations

- Traefik dashboard runs in insecure mode by default (configure `TRAEFIK_INSECURE_API=false` for production)
- ZeroTier runs with necessary privileges for network management
- All services include health checks for monitoring
- Volume configurations support secure storage backends

## Troubleshooting

### Common Issues
1. **Port conflicts**: Adjust port configuration in `.env` file
2. **Services not discovered**: Ensure services have `traefik.enable=true` and are on the same app networks as Traefik
3. **Network access issues**: Check that Traefik container is connected to the same app networks as your services
4. **Service routing fails**: Verify the service is on an app network that Traefik is also connected to
5. **SSL certificate issues**: 
   - **Use staging server first** to avoid rate limits: `ACME_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory`
   - **Check Cloudflare API credentials** are correct and have proper permissions
   - **Verify DNS propagation** with `dig TXT _acme-challenge.your-domain.com`
   - **Check Cloudflare SSL/TLS mode** is set to "Full (strict)"
   - **Review Traefik logs** for ACME errors: `docker-compose logs traefik | grep -i acme`
6. **Rate limits exceeded**: Let's Encrypt has strict rate limits - always test with staging first
7. **DNS challenge fails**: Ensure Cloudflare API key has `Zone:Read` and `DNS:Edit` permissions

### Debugging Commands
```bash
# Check container status
docker-compose ps

# View detailed logs
docker-compose logs --tail=50 traefik

# Check which networks Traefik is connected to
docker inspect ${CONTAINER_NAME_PREFIX}-traefik | jq -r '.[0].NetworkSettings.Networks | keys[]'

# List all services discovered by Traefik
curl -s http://localhost:8080/api/http/services | jq 'keys[]'

# List all routers configured in Traefik
curl -s http://localhost:8080/api/http/routers | jq '.[] | {name: .name, rule: .rule, service: .service}'

# Check if a specific service is discovered
curl -s http://localhost:8080/api/http/services | jq '.["your-service@docker"]'

# Test network connectivity from Traefik container
docker exec ${CONTAINER_NAME_PREFIX}-traefik ping -c 3 your-service-container-name

# Check which containers are on specific networks
docker network inspect media_center_apps | jq '.[0].Containers'
docker network inspect immich-app-network | jq '.[0].Containers'

# ACME/SSL certificate debugging
# Check ACME certificate storage
docker exec ${CONTAINER_NAME_PREFIX}-traefik ls -la /acme/
docker exec ${CONTAINER_NAME_PREFIX}-traefik cat /acme/acme.json | jq '.'

# Check certificate status via Traefik API
curl -s http://192.168.180.10:8080/api/http/routers | jq '.[] | select(.rule | contains("your-domain")) | .tls'

# View ACME logs in Traefik
docker-compose logs traefik | grep -i acme

# Test DNS challenge manually (replace with your domain)
dig +short TXT _acme-challenge.your-domain.com

# Check if certificate is working
openssl s_client -connect your-domain.com:443 -servername your-domain.com
``` 