# Server Deployment Scripts

自动化服务器部署脚本和CI/CD流水线，支持GitOps工作流。

## 📋 功能特性

- **一键部署脚本**：快速部署Web应用到服务器
- **CI/CD流水线**：GitHub Actions自动化部署
- **Docker容器化**：支持容器化部署
- **监控与备份**：内置健康检查和备份脚本
- **GitOps工作流**：代码即配置，自动同步

## 🚀 快速开始

### 1. 克隆仓库
```bash
git clone https://github.com/dsadsasdaddas/server-deployment-scripts.git
cd server-deployment-scripts
```

### 2. 配置环境变量
复制环境模板并配置：
```bash
cp .env.example .env
# 编辑.env文件，设置服务器信息
```

### 3. 手动部署
```bash
# 部署Wang Yue网站
./scripts/deploy_website.sh

# 部署档案库(Archive Vault)
./scripts/deploy_archive_vault.sh
```

## 🔧 CI/CD配置

### GitHub Secrets配置
在GitHub仓库设置中添加以下Secrets：

| Secret名称 | 描述 | 示例值 |
|------------|------|--------|
| `SSH_PRIVATE_KEY` | 服务器SSH私钥 | `-----BEGIN RSA PRIVATE KEY-----...` |
| `SERVER_IP` | 服务器IP地址 | `129.211.5.168` |
| `SERVER_USER` | 服务器用户名 | `root` 或 `ubuntu` |
| `GITHUB_TOKEN` | GitHub API令牌 | `ghp_...` |

### 自动触发部署
- **推送到main分支**：自动触发部署
- **手动触发**：在GitHub Actions页面手动运行工作流
- **定时部署**：可配置定时部署（需修改workflow文件）

## 📁 项目结构

```
server-deployment-scripts/
├── .github/workflows/     # CI/CD流水线
│   └── deploy.yml         # 部署工作流
├── scripts/               # 部署脚本
│   ├── deploy_website.sh      # 网站部署脚本
│   └── deploy_archive_vault.sh # 档案库部署脚本
├── docker/                # Docker配置
│   ├── docker-compose.yml    # Docker Compose配置
│   ├── Dockerfile.backend    # 后端Dockerfile
│   ├── Dockerfile.frontend   # 前端Dockerfile
│   ├── nginx.conf           # Nginx配置
│   └── backend/             # 后端应用代码
├── kubernetes/            # Kubernetes配置（待添加）
├── docs/                  # 文档
└── README.md              # 项目说明
```

## 🛠️ 部署脚本说明

### deploy_website.sh
部署Wang Yue个人网站到服务器。

**功能**：
- 自动安装Node.js、Nginx、MariaDB
- 配置数据库和用户
- 部署前端和后端
- 设置Nginx反向代理
- 配置PM2进程管理
- 创建监控和备份脚本

**使用方法**：
```bash
./scripts/deploy_website.sh
```

### deploy_archive_vault.sh
部署档案库(Archive Vault)应用。

**功能**：
- 部署Docker容器化应用
- 配置FastAPI后端
- 部署Vue.js前端
- 配置Nginx服务
- 创建健康检查和备份

**使用方法**：
```bash
./scripts/deploy_archive_vault.sh
```

## 🔒 安全配置

### SSH密钥配置
1. 生成SSH密钥对：
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_deploy
   ```

2. 将公钥添加到服务器：
   ```bash
   ssh-copy-id -i ~/.ssh/id_rsa_deploy.pub user@server_ip
   ```

3. 在GitHub Secrets中添加私钥

### 防火墙配置
确保服务器开放以下端口：
- `80` - HTTP Web服务
- `443` - HTTPS (如需)
- `3000` - Node.js后端
- `8000` - FastAPI后端
- `3306` - MySQL/MariaDB

## 📊 监控与维护

### 健康检查
部署后自动生成的监控脚本：
```bash
# 在服务器上运行
/var/www/wangyue-website/monitor.sh
/var/www/archive-vault/monitor.sh
```

### 备份与恢复
自动备份脚本：
```bash
# 在服务器上运行
/var/www/wangyue-website/backup.sh
/var/www/archive-vault/backup.sh
```

### 日志查看
```bash
# Nginx日志
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# 应用日志
pm2 logs wangyue-backend
docker logs archive-backend-container
```

## 🔄 GitOps工作流

### 工作原理
1. **代码变更**：开发者在Git仓库提交代码
2. **自动测试**：CI流水线运行测试
3. **自动部署**：通过SSH连接到服务器执行部署脚本
4. **状态同步**：确保服务器状态与代码仓库一致

### 配置GitOps
1. 配置GitHub Actions secrets
2. 设置分支保护规则
3. 配置自动部署触发器
4. 设置通知和告警

## 🐛 故障排除

### 常见问题

1. **SSH连接失败**
   ```
   错误: Permission denied (publickey)
   ```
   **解决方案**：检查SSH密钥配置和服务器授权

2. **端口冲突**
   ```
   错误: Address already in use
   ```
   **解决方案**：修改端口配置或停止占用端口的服务

3. **依赖安装失败**
   ```
   错误: Package not found
   ```
   **解决方案**：更新包管理器或使用镜像源

4. **数据库连接失败**
   ```
   错误: Can't connect to MySQL server
   ```
   **解决方案**：检查数据库服务状态和用户权限

### 调试方法
```bash
# 查看详细部署日志
bash -x ./scripts/deploy_website.sh

# 检查服务器连接
ssh -i ~/.ssh/id_rsa user@server_ip "echo '测试连接'"

# 查看服务状态
systemctl status nginx
systemctl status mariadb
pm2 list
docker ps
```

## 📝 许可证

MIT License

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📞 支持

如有问题，请：
1. 查看[故障排除](#故障排除)部分
2. 提交GitHub Issue
3. 查看部署日志

---

**部署时间**：$(date)
**版本**：1.0.0
**维护者**：OpenClaw AI助手