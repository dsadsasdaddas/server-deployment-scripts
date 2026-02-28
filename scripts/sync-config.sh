#!/bin/bash
# GitOps配置同步脚本
# 自动将配置文件同步到服务器

set -e

echo "🔄 GitOps配置同步开始..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 加载环境变量
if [ -f ../.env ]; then
    source ../.env
elif [ -f .env.example ]; then
    echo -e "${YELLOW}⚠️  使用示例环境变量，请创建.env文件${NC}"
    source .env.example
else
    echo -e "${RED}❌ 找不到环境变量文件${NC}"
    exit 1
fi

# SSH连接函数
ssh_cmd() {
    ssh -i "$SSH_KEY_PATH" -p "${SSH_PORT:-22}" -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_IP}" "$1"
}

# 文件同步函数
sync_files() {
    local source_dir="$1"
    local target_dir="$2"
    
    echo -e "${YELLOW}同步 $source_dir 到 $target_dir...${NC}"
    
    # 使用rsync同步文件
    rsync -avz -e "ssh -i $SSH_KEY_PATH -p ${SSH_PORT:-22} -o StrictHostKeyChecking=no" \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='.env' \
        --delete \
        "$source_dir/" "${SERVER_USER}@${SERVER_IP}:$target_dir/"
        
    echo -e "${GREEN}✅ 同步完成${NC}"
}

# 步骤1: 检查连接
echo -e "${YELLOW}步骤1: 检查服务器连接...${NC}"
if ssh_cmd "echo '连接测试成功'" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 服务器连接正常${NC}"
else
    echo -e "${RED}❌ 服务器连接失败${NC}"
    exit 1
fi

# 步骤2: 同步网站配置
echo -e "${YELLOW}步骤2: 同步Wang Yue网站配置...${NC}"
sync_files "docker" "${WANGYUE_DEPLOY_DIR}/config"

# 步骤3: 同步档案库配置
echo -e "${YELLOW}步骤3: 同步档案库配置...${NC}"
sync_files "docker" "${ARCHIVE_VAULT_DEPLOY_DIR}/config"

# 步骤4: 同步部署脚本
echo -e "${YELLOW}步骤4: 同步部署脚本...${NC}"
ssh_cmd "mkdir -p /opt/deployment-scripts"
sync_files "scripts" "/opt/deployment-scripts"

# 步骤5: 应用配置更新
echo -e "${YELLOW}步骤5: 应用配置更新...${NC}"

# 网站配置更新
if [ -n "$WANGYUE_DEPLOY_DIR" ]; then
    echo -e "${YELLOW}重新加载网站配置...${NC}"
    ssh_cmd "cd $WANGYUE_DEPLOY_DIR && \
             if [ -f docker-compose.yml ]; then \
               docker-compose down && \
               docker-compose up -d; \
             fi" || echo -e "${YELLOW}⚠️  网站配置更新跳过${NC}"
fi

# 档案库配置更新
if [ -n "$ARCHIVE_VAULT_DEPLOY_DIR" ]; then
    echo -e "${YELLOW}重新加载档案库配置...${NC}"
    ssh_cmd "cd $ARCHIVE_VAULT_DEPLOY_DIR && \
             if [ -f docker-compose.yml ]; then \
               docker-compose down && \
               docker-compose up -d; \
             fi" || echo -e "${YELLOW}⚠️  档案库配置更新跳过${NC}"
fi

# 步骤6: 验证服务状态
echo -e "${YELLOW}步骤6: 验证服务状态...${NC}"

# 检查网站服务
if ssh_cmd "curl -s -f http://localhost:${PORT:-80} > /dev/null 2>&1"; then
    echo -e "${GREEN}✅ 网站服务运行正常${NC}"
else
    echo -e "${YELLOW}⚠️  网站服务检查失败${NC}"
fi

# 检查档案库服务
if ssh_cmd "curl -s -f http://localhost:8000/api/v1/health > /dev/null 2>&1"; then
    echo -e "${GREEN}✅ 档案库服务运行正常${NC}"
else
    echo -e "${YELLOW}⚠️  档案库服务检查失败${NC}"
fi

echo -e "${GREEN}🎉 GitOps配置同步完成！${NC}"
echo ""
echo -e "${YELLOW}=== 同步摘要 ===${NC}"
echo "服务器: ${GREEN}${SERVER_IP}${NC}"
echo "同步时间: $(date)"
echo "同步内容:"
echo "  - 网站配置: ${WANGYUE_DEPLOY_DIR}/config"
echo "  - 档案库配置: ${ARCHIVE_VAULT_DEPLOY_DIR}/config"
echo "  - 部署脚本: /opt/deployment-scripts"
echo ""
echo -e "${YELLOW}=== 后续步骤 ===${NC}"
echo "1. 检查服务日志:"
echo "   ssh ${SERVER_USER}@${SERVER_IP} 'docker logs archive-backend-container'"
echo "2. 运行健康检查:"
echo "   ssh ${SERVER_USER}@${SERVER_IP} '${WANGYUE_DEPLOY_DIR}/monitor.sh'"
echo "3. 查看同步文件:"
echo "   ssh ${SERVER_USER}@${SERVER_IP} 'ls -la /opt/deployment-scripts/'"

# 清理敏感信息（可选）
if [ "$CLEANUP" = "true" ]; then
    echo -e "${YELLOW}清理临时文件...${NC}"
    rm -f ~/.ssh/id_rsa_deploy_temp
fi