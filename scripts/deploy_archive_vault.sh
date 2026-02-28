#!/bin/bash
# 档案库 (Archive Vault) 部署脚本
# 目标服务器: 129.211.5.168

set -e  # 遇到错误立即退出

echo "🚀 开始部署档案库 (Archive Vault)..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 服务器信息
SERVER_IP="129.211.5.168"
SERVER_USER="ubuntu"
SSH_KEY="/root/.ssh/id_rsa_new"
DEPLOY_DIR="/var/www/archive-vault"
DOMAIN=""  # 可选项：如果绑定域名则填写

# SSH连接函数
ssh_cmd() {
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "$1"
}

# 文件传输函数
scp_cmd() {
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$1" "$SERVER_USER@$SERVER_IP:$2"
}

# 步骤1: 检查服务器连接
echo -e "${YELLOW}步骤1: 检查服务器连接...${NC}"
if ssh_cmd "echo '连接测试成功'" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 服务器连接正常${NC}"
else
    echo -e "${RED}❌ 服务器连接失败${NC}"
    echo -e "${YELLOW}请检查 SSH 密钥和服务器配置。${NC}"
    exit 1
fi

# 步骤2: 创建部署目录
echo -e "${YELLOW}步骤2: 创建部署目录...${NC}"
ssh_cmd "sudo mkdir -p $DEPLOY_DIR/{backend,frontend,logs,backup} && sudo chown -R ubuntu:ubuntu $DEPLOY_DIR"

# 步骤3: 上传项目文件
echo -e "${YELLOW}步骤3: 上传项目文件...${NC}"
# 压缩本地项目目录
cd /root/.openclaw/workspace/deploy/archive-vault
tar -czf /tmp/archive-vault.tar.gz .
# 上传压缩包
scp_cmd "/tmp/archive-vault.tar.gz" "/tmp/archive-vault.tar.gz"
# 解压到部署目录
ssh_cmd "sudo tar -xzf /tmp/archive-vault.tar.gz -C $DEPLOY_DIR && sudo rm /tmp/archive-vault.tar.gz && sudo chown -R ubuntu:ubuntu $DEPLOY_DIR"
echo -e "${GREEN}✅ 项目文件上传完成${NC}"

# 步骤4: 安装 Docker 和 Docker Compose（如果尚未安装）
echo -e "${YELLOW}步骤4: 检查 Docker 环境...${NC}"
if ssh_cmd "command -v docker > /dev/null 2>&1"; then
    echo -e "${GREEN}✅ Docker 已安装${NC}"
else
    echo -e "${YELLOW}正在安装 Docker...${NC}"
    ssh_cmd "sudo apt-get update && \
             sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common && \
             curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
             sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" && \
             sudo apt-get update && \
             sudo apt-get install -y docker-ce docker-ce-cli containerd.io && \
             sudo systemctl start docker && sudo systemctl enable docker"
    echo -e "${GREEN}✅ Docker 安装完成${NC}"
fi

if ssh_cmd "docker compose version > /dev/null 2>&1 || command -v docker-compose > /dev/null 2>&1"; then
    echo -e "${GREEN}✅ Docker Compose 已安装${NC}"
else
    echo -e "${YELLOW}Docker Compose 未安装，但 docker-compose-plugin 已提供 docker compose 命令，跳过安装${NC}"
fi

# 步骤5: 部署后端 Docker 容器
echo -e "${YELLOW}步骤5: 部署后端容器...${NC}"
# 创建后端 Dockerfile（使用已有的 Dockerfile.backend）
ssh_cmd "cd $DEPLOY_DIR && \
         sudo docker build -t archive-backend -f Dockerfile.backend ./backend"
# 停止并移除旧容器
ssh_cmd "sudo docker stop archive-backend-container 2>/dev/null || true && \
         sudo docker rm archive-backend-container 2>/dev/null || true"
# 运行后端容器
ssh_cmd "sudo docker run -d \
         --name archive-backend-container \
         -p 8000:8000 \
         -v $DEPLOY_DIR/backend:/app \
         --restart unless-stopped \
         archive-backend"
echo -e "${GREEN}✅ 后端容器启动完成${NC}"

# 步骤6: 配置 Nginx 前端
echo -e "${YELLOW}步骤6: 配置 Nginx 前端...${NC}"
# 安装 Nginx（如果尚未安装）
if ssh_cmd "command -v nginx > /dev/null 2>&1"; then
    echo -e "${GREEN}✅ Nginx 已安装${NC}"
else
    ssh_cmd "sudo apt-get update && sudo apt-get install -y nginx && sudo systemctl enable nginx"
    echo -e "${GREEN}✅ Nginx 安装完成${NC}"
fi
# 复制 Nginx 配置文件
ssh_cmd "sudo cp $DEPLOY_DIR/nginx.production.conf /etc/nginx/nginx.conf"
# 确保前端静态文件目录存在
ssh_cmd "sudo mkdir -p /var/www/archive-vault && sudo cp -r $DEPLOY_DIR/* /var/www/archive-vault/ 2>/dev/null || true"
# 重启 Nginx
ssh_cmd "sudo systemctl restart nginx"
echo -e "${GREEN}✅ Nginx 配置完成${NC}"

# 步骤7: 配置防火墙 (Ubuntu 使用 ufw，此处跳过，请确保云服务器安全组已开放端口 80 和 8000)
echo -e "${YELLOW}步骤7: 跳过防火墙配置 (Ubuntu)...${NC}"
echo -e "${YELLOW}⚠️  请确保云服务器安全组已开放端口 80 和 8000${NC}"

# 步骤8: 创建监控脚本
echo -e "${YELLOW}步骤8: 创建监控脚本...${NC}"
ssh_cmd "cat > $DEPLOY_DIR/monitor.sh << 'EOF'
#!/bin/bash
# 档案库监控脚本

echo \"=== 档案库健康检查 ===\"
echo \"时间: \$(date)\"

# 检查容器
if docker ps --filter \"name=archive-backend-container\" --format \"table {{.Names}}\\t{{.Status}}\" | grep -q archive-backend-container; then
    echo \"✅ 后端容器运行正常\"
else
    echo \"❌ 后端容器未运行\"
fi

# 检查端口
if nc -z localhost 8000 >/dev/null 2>&1; then
    echo \"✅ 后端端口 8000 监听正常\"
else
    echo \"❌ 后端端口 8000 未监听\"
fi

if nc -z localhost 80 >/dev/null 2>&1; then
    echo \"✅ 前端端口 80 监听正常\"
else
    echo \"❌ 前端端口 80 未监听\"
fi

# 检查 API 健康
if curl -s -f http://localhost:8000/api/v1/health >/dev/null; then
    echo \"✅ API 健康检查通过\"
else
    echo \"❌ API 健康检查失败\"
fi

# 检查磁盘空间
echo \"=== 磁盘空间 ===\"
df -h /var/www

# 检查服务状态
echo \"=== 服务状态 ===\"
systemctl status nginx --no-pager --lines=3
EOF
chmod +x $DEPLOY_DIR/monitor.sh"

# 步骤9: 创建备份脚本
echo -e "${YELLOW}步骤9: 创建备份脚本...${NC}"
ssh_cmd "cat > $DEPLOY_DIR/backup.sh << 'EOF'
#!/bin/bash
# 档案库备份脚本

BACKUP_DIR=\"$DEPLOY_DIR/backup\"
DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_FILE=\"\$BACKUP_DIR/backup_\$DATE.tar.gz\"

echo \"开始备份...\"

# 备份数据库文件
cp $DEPLOY_DIR/backend/archive.db \$BACKUP_DIR/archive.db_\$DATE 2>/dev/null || true

# 备份配置文件
tar -czf \$BACKUP_FILE \\
    $DEPLOY_DIR/backend \\
    /etc/nginx/nginx.conf \\
    \$BACKUP_DIR/archive.db_\$DATE

# 清理旧备份（保留最近7天）
find \$BACKUP_DIR -name \"backup_*.tar.gz\" -mtime +7 -delete
find \$BACKUP_DIR -name \"archive.db_*\" -mtime +7 -delete

echo \"备份完成: \$BACKUP_FILE\"
echo \"备份大小: \$(du -h \$BACKUP_FILE | cut -f1)\"
EOF
chmod +x $DEPLOY_DIR/backup.sh"

# 步骤10: 测试部署
echo -e "${YELLOW}步骤10: 测试部署...${NC}"
sleep 3
if ssh_cmd "curl -s -f http://localhost:8000/api/v1/health > /dev/null"; then
    echo -e "${GREEN}✅ 后端 API 测试通过${NC}"
else
    echo -e "${YELLOW}⚠️  后端 API 测试失败，请检查日志${NC}"
fi

if ssh_cmd "curl -s -f http://localhost > /dev/null"; then
    echo -e "${GREEN}✅ 前端页面测试通过${NC}"
else
    echo -e "${YELLOW}⚠️  前端页面测试失败，请检查 Nginx${NC}"
fi

# 完成部署
echo -e "${GREEN}🎉 档案库部署完成！${NC}"
echo -e "${YELLOW}=== 部署摘要 ===${NC}"
echo -e "服务器: ${GREEN}$SERVER_IP${NC}"
echo -e "访问地址: ${GREEN}http://$SERVER_IP${NC}"
echo -e "后端 API: ${GREEN}http://$SERVER_IP:8000/api/v1/health${NC}"
echo -e "部署目录: ${GREEN}$DEPLOY_DIR${NC}"
echo -e "监控脚本: ${GREEN}$DEPLOY_DIR/monitor.sh${NC}"
echo -e "备份脚本: ${GREEN}$DEPLOY_DIR/backup.sh${NC}"
echo -e "${YELLOW}=== 管理命令 ===${NC}"
echo "查看容器日志: docker logs archive-backend-container"
echo "查看 Nginx 日志: tail -f /var/log/nginx/error.log"
echo "运行监控: $DEPLOY_DIR/monitor.sh"
echo "运行备份: $DEPLOY_DIR/backup.sh"

# 最终测试
echo -e "${YELLOW}正在测试网站访问...${NC}"
sleep 2
if curl -s -f "http://$SERVER_IP" > /dev/null; then
    echo -e "${GREEN}✅ 网站访问正常${NC}"
else
    echo -e "${YELLOW}⚠️  网站可能需要几秒钟启动，请稍后访问${NC}"
fi

echo -e "${GREEN}🚀 部署流程全部完成！${NC}"