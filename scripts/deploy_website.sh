#!/bin/bash
# Wang Yue 网站部署脚本
# 目标服务器: 129.211.5.168

set -e  # 遇到错误立即退出

echo "🚀 开始部署 Wang Yue 个人网站..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 服务器信息
SERVER_IP="129.211.5.168"
SERVER_USER="root"
SSH_KEY="/root/.ssh/id_rsa_target"
GITHUB_REPO="https://github.com/dsadsasdaddas/wangyue-website.git"
DEPLOY_DIR="/var/www/wangyue-website"
DOMAIN="wangyue-website.com"  # 临时域名，可替换

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
    exit 1
fi

# 步骤2: 创建部署目录
echo -e "${YELLOW}步骤2: 创建部署目录...${NC}"
ssh_cmd "mkdir -p $DEPLOY_DIR/{frontend,backend,database,logs,backup}"

# 步骤3: 克隆GitHub仓库
echo -e "${YELLOW}步骤3: 克隆GitHub仓库...${NC}"
ssh_cmd "cd $DEPLOY_DIR && \
         if [ -d '.git' ]; then \
           echo '仓库已存在，拉取最新代码...' && \
           git pull; \
         else \
           echo '克隆新仓库...' && \
           git clone $GITHUB_REPO .; \
         fi"

# 步骤4: 配置数据库
echo -e "${YELLOW}步骤4: 配置数据库...${NC}"
ssh_cmd "systemctl start mariadb && \
         systemctl enable mariadb && \
         mysql -e \"CREATE DATABASE IF NOT EXISTS wangyue_db; \
         CREATE USER IF NOT EXISTS 'wangyue_user'@'localhost' IDENTIFIED BY 'Wangyue@2026'; \
         GRANT ALL PRIVILEGES ON wangyue_db.* TO 'wangyue_user'@'localhost'; \
         FLUSH PRIVILEGES;\""

# 导入数据库架构
ssh_cmd "cd $DEPLOY_DIR && \
         if [ -f 'database/schema.sql' ]; then \
           mysql -u wangyue_user -pWangyue@2026 wangyue_db < database/schema.sql; \
         fi"

# 步骤5: 配置后端
echo -e "${YELLOW}步骤5: 配置后端...${NC}"
ssh_cmd "cd $DEPLOY_DIR/backend && \
         npm install --production && \
         cat > .env << EOF
DB_HOST=localhost
DB_USER=wangyue_user
DB_PASSWORD=Wangyue@2026
DB_NAME=wangyue_db
DB_PORT=3306
PORT=3000
NODE_ENV=production
EOF"

# 步骤6: 配置前端
echo -e "${YELLOW}步骤6: 配置前端...${NC}"
ssh_cmd "cd $DEPLOY_DIR/frontend && \
         npm install && \
         npm run build"

# 步骤7: 配置Nginx
echo -e "${YELLOW}步骤7: 配置Nginx...${NC}"
ssh_cmd "cat > /etc/nginx/conf.d/wangyue.conf << 'EOF'
server {
    listen 80;
    server_name $DOMAIN;
    
    # 前端静态文件
    location / {
        root $DEPLOY_DIR/frontend/dist;
        try_files \$uri \$uri/ /index.html;
        index index.html;
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control \"public, immutable\";
    }
    
    access_log $DEPLOY_DIR/logs/nginx-access.log;
    error_log $DEPLOY_DIR/logs/nginx-error.log;
}
EOF"

# 步骤8: 配置PM2（进程管理）
echo -e "${YELLOW}步骤8: 配置PM2...${NC}"
ssh_cmd "cd $DEPLOY_DIR/backend && \
         pm2 start server.js --name 'wangyue-backend' && \
         pm2 save && \
         pm2 startup"

# 步骤9: 启动服务
echo -e "${YELLOW}步骤9: 启动服务...${NC}"
ssh_cmd "systemctl restart nginx && \
         systemctl enable nginx"

# 步骤10: 配置防火墙
echo -e "${YELLOW}步骤10: 配置防火墙...${NC}"
ssh_cmd "firewall-cmd --permanent --add-service=http && \
         firewall-cmd --permanent --add-service=https && \
         firewall-cmd --reload"

# 步骤11: 创建监控脚本
echo -e "${YELLOW}步骤11: 创建监控脚本...${NC}"
ssh_cmd "cat > $DEPLOY_DIR/monitor.sh << 'EOF'
#!/bin/bash
# 网站监控脚本

check_service() {
    service_name=\$1
    if systemctl is-active --quiet \$service_name; then
        echo \"✅ \$service_name 运行正常\"
        return 0
    else
        echo \"❌ \$service_name 未运行\"
        return 1
    fi
}

check_port() {
    port=\$1
    if nc -z localhost \$port >/dev/null 2>&1; then
        echo \"✅ 端口 \$port 监听正常\"
        return 0
    else
        echo \"❌ 端口 \$port 未监听\"
        return 1
    fi
}

echo \"=== 网站健康检查 ===\"
echo \"时间: \$(date)\"

# 检查服务
check_service nginx
check_service mariadb

# 检查端口
check_port 80
check_port 3000

# 检查磁盘空间
echo \"=== 磁盘空间 ===\"
df -h /var/www

# 检查内存使用
echo \"=== 内存使用 ===\"
free -h

# 检查进程
echo \"=== 进程状态 ===\"
pm2 list
EOF
chmod +x $DEPLOY_DIR/monitor.sh"

# 步骤12: 创建备份脚本
echo -e "${YELLOW}步骤12: 创建备份脚本...${NC}"
ssh_cmd "cat > $DEPLOY_DIR/backup.sh << 'EOF'
#!/bin/bash
# 网站备份脚本

BACKUP_DIR=\"$DEPLOY_DIR/backup\"
DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_FILE=\"\$BACKUP_DIR/backup_\$DATE.tar.gz\"

echo \"开始备份...\"

# 备份数据库
mysqldump -u wangyue_user -pWangyue@2026 wangyue_db > \$BACKUP_DIR/db_backup_\$DATE.sql

# 备份网站文件
tar -czf \$BACKUP_FILE \
    $DEPLOY_DIR/frontend/dist \
    $DEPLOY_DIR/backend \
    $DEPLOY_DIR/database \
    \$BACKUP_DIR/db_backup_\$DATE.sql \
    /etc/nginx/conf.d/wangyue.conf

# 清理旧备份（保留最近7天）
find \$BACKUP_DIR -name \"backup_*.tar.gz\" -mtime +7 -delete
find \$BACKUP_DIR -name \"db_backup_*.sql\" -mtime +7 -delete

echo \"备份完成: \$BACKUP_FILE\"
echo \"备份大小: \$(du -h \$BACKUP_FILE | cut -f1)\"
EOF
chmod +x $DEPLOY_DIR/backup.sh"

# 步骤13: 创建部署完成页面
echo -e "${YELLOW}步骤13: 创建部署完成页面...${NC}"
ssh_cmd "cat > $DEPLOY_DIR/frontend/dist/deployment-info.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>部署完成 | Wang Yue 个人网站</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
        .container { max-width: 800px; margin: 0 auto; }
        .success { color: #2ecc71; }
        .info { background: #f8f9fa; padding: 20px; border-radius: 5px; }
        .section { margin: 30px 0; }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1 class=\"success\">✅ 网站部署完成！</h1>
        
        <div class=\"section info\">
            <h2>部署信息</h2>
            <p><strong>部署时间:</strong> $(date)</p>
            <p><strong>服务器IP:</strong> $SERVER_IP</p>
            <p><strong>部署目录:</strong> $DEPLOY_DIR</p>
            <p><strong>GitHub仓库:</strong> $GITHUB_REPO</p>
        </div>
        
        <div class=\"section\">
            <h2>访问方式</h2>
            <ul>
                <li>网站首页: <a href=\"http://$SERVER_IP\">http://$SERVER_IP</a></li>
                <li>API接口: <a href=\"http://$SERVER_IP/api/health\">http://$SERVER_IP/api/health</a></li>
                <li>GitHub Pages: <a href=\"https://dsadsasdaddas.github.io/wangyue-website/\">GitHub Pages版本</a></li>
            </ul>
        </div>
        
        <div class=\"section\">
            <h2>管理命令</h2>
            <pre>
# 查看服务状态
systemctl status nginx
systemctl status mariadb
pm2 list

# 查看日志
tail -f $DEPLOY_DIR/logs/nginx-access.log
tail -f $DEPLOY_DIR/logs/nginx-error.log
pm2 logs wangyue-backend

# 监控脚本
$DEPLOY_DIR/monitor.sh

# 备份脚本
$DEPLOY_DIR/backup.sh
            </pre>
        </div>
        
        <div class=\"section\">
            <h2>技术栈</h2>
            <ul>
                <li>前端: Vue.js + Vite + Tailwind CSS</li>
                <li>后端: Node.js + Express.js</li>
                <li>数据库: MariaDB 10.11</li>
                <li>Web服务器: Nginx 1.26</li>
                <li>进程管理: PM2</li>
                <li>部署工具: OpenClaw AI助手</li>
            </ul>
        </div>
        
        <div class=\"section\">
            <p><em>本网站由 OpenClaw AI助手自动部署完成</em></p>
            <p><em>部署时间: $(date)</em></p>
        </div>
    </div>
</body>
</html>
EOF"

# 完成部署
echo -e "${GREEN}🎉 网站部署完成！${NC}"
echo -e "${YELLOW}=== 部署摘要 ===${NC}"
echo -e "服务器: ${GREEN}$SERVER_IP${NC}"
echo -e "访问地址: ${GREEN}http://$SERVER_IP${NC}"
echo -e "部署目录: ${GREEN}$DEPLOY_DIR${NC}"
echo -e "数据库: ${GREEN}wangyue_db (用户: wangyue_user)${NC}"
echo -e "管理工具: ${GREEN}PM2 + Nginx + MariaDB${NC}"
echo -e "监控脚本: ${GREEN}$DEPLOY_DIR/monitor.sh${NC}"
echo -e "备份脚本: ${GREEN}$DEPLOY_DIR/backup.sh${NC}"
echo -e "${YELLOW}=== 下一步 ===${NC}"
echo "1. 访问 http://$SERVER_IP 查看网站"
echo "2. 运行 $DEPLOY_DIR/monitor.sh 检查服务状态"
echo "3. 配置域名和SSL证书（可选）"
echo "4. 设置定期备份任务"

# 测试访问
echo -e "${YELLOW}正在测试网站访问...${NC}"
sleep 3
if curl -s -f "http://$SERVER_IP" > /dev/null; then
    echo -e "${GREEN}✅ 网站访问正常${NC}"
else
    echo -e "${YELLOW}⚠️  网站可能需要几秒钟启动，请稍后访问${NC}"
fi

echo -e "${GREEN}🚀 部署流程全部完成！${NC}"