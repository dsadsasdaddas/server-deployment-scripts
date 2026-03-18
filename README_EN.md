# Server Deployment Scripts

[中文](README.md) | English

Automated server deployment scripts and CI/CD pipelines with GitOps workflow support.

## 📋 Features

- **One-Click Deployment**: Quickly deploy web applications to servers
- **CI/CD Pipeline**: GitHub Actions automated deployment
- **Docker Containerization**: Support for containerized deployment
- **Monitoring & Backup**: Built-in health checks and backup scripts
- **GitOps Workflow**: Configuration as code, automatic synchronization

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/dsadsasdaddas/server-deployment-scripts.git
cd server-deployment-scripts
```

### 2. Configure Environment Variables
Copy the environment template and configure:
```bash
cp .env.example .env
# Edit .env file and set server information
```

### 3. Manual Deployment
```bash
# Deploy Wang Yue Website
./scripts/deploy_website.sh

# Deploy Archive Vault
./scripts/deploy_archive_vault.sh
```

## 🔧 CI/CD Configuration

### GitHub Secrets Setup
Add the following secrets in your GitHub repository settings:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `SSH_PRIVATE_KEY` | Server SSH private key | `-----BEGIN RSA PRIVATE KEY-----...` |
| `SERVER_IP` | Server IP address | `129.211.5.168` |
| `SERVER_USER` | Server username | `root` or `ubuntu` |
| `GITHUB_TOKEN` | GitHub API token | `ghp_...` |

### Automatic Deployment Triggers
- **Push to main branch**: Automatically triggers deployment
- **Manual trigger**: Run workflow manually from GitHub Actions page
- **Scheduled deployment**: Configure scheduled deployment (modify workflow file)

## 📁 Project Structure

```
server-deployment-scripts/
├── .github/workflows/     # CI/CD pipelines
│   └── deploy.yml         # Deployment workflow
├── scripts/               # Deployment scripts
│   ├── deploy_website.sh      # Website deployment script
│   └── deploy_archive_vault.sh # Archive vault deployment script
├── docker/                # Docker configuration
│   ├── docker-compose.yml    # Docker Compose config
│   ├── Dockerfile.backend    # Backend Dockerfile
│   ├── Dockerfile.frontend   # Frontend Dockerfile
│   ├── nginx.conf           # Nginx configuration
│   └── backend/             # Backend application code
├── kubernetes/            # Kubernetes configuration (coming soon)
├── docs/                  # Documentation
└── README.md              # Project documentation
```

## 🛠️ Deployment Scripts

### deploy_website.sh
Deploy Wang Yue personal website to server.

**Features**:
- Auto-install Node.js, Nginx, MariaDB
- Configure SSL certificates
- Set up reverse proxy
- Enable automatic backup

### deploy_archive_vault.sh
Deploy Archive Vault application.

**Features**:
- Docker containerized deployment
- SQLite database
- Health monitoring
- Automatic restart on failure

## 🐳 Docker Deployment

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 📊 Monitoring

- **Health Check**: `./scripts/health_check.sh`
- **Backup**: `./scripts/backup.sh`
- **Log Viewer**: `./scripts/view_logs.sh`

## 🔒 Security Recommendations

1. **Change default passwords** in `.env` file
2. **Use SSH key authentication** instead of password
3. **Enable firewall** (ufw/iptables)
4. **Regular backups** with cron jobs
5. **Keep dependencies updated**

## 📄 License

MIT License

## 👤 Author

Wang Yue - Wenzhou University Student