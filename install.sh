#!/bin/bash
# ============================================================
# OpenClaw 多实例部署脚本
# 支持 Ubuntu 22.04 | 阿里云模型 | 飞书
# 用法: bash install.sh
# ============================================================

set -e
OPENCLAW_DIR=/root/.openclaw
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色输出
R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; C='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${C}[INFO]${NC}  $1"; }
ok()    { echo -e "${G}[OK]${NC}    $1"; }
warn()  { echo -e "${Y}[WARN]${NC}  $1"; }
error() { echo -e "${R}[ERROR]${NC} $1"; exit 1; }

echo ""
echo "============================================"
echo "  OpenClaw 多实例部署 - Ubuntu 22.04"
echo "============================================"
echo ""

# ── 读取配置 ──────────────────────────────────────
read -p "Master 名字（如：南朝译）: " MASTER_NAME
read -p "Master 飞书 AppID: " MASTER_APP_ID
read -p "Master 飞书 AppSecret: " MASTER_APP_SECRET
read -p "阿里云 API Key (sk-sp-xxx): " ALIYUN_KEY
read -p "Worker 数量 (1-6): " WORKER_COUNT

WORKERS=()
for i in $(seq 1 $WORKER_COUNT); do
  echo ""
  echo "--- Worker $i ---"
  read -p "  名字（如：技术员）: " W_NAME
  read -p "  飞书 AppID: " W_APP_ID
  read -p "  飞书 AppSecret: " W_APP_SECRET
  WORKERS+=("${W_NAME}|${W_APP_ID}|${W_APP_SECRET}")
done

# 端口规划
# Master: 18789(gateway) 18800(a2a) 18791/18792(browser/server 自动占用，不可用)
# Worker 端口从 18794 开始，跳过 18791/18792
SAFE_PORTS=(18794 18795 18796 18797 18798 18799)
A2A_PORTS=(18801 18802 18803 18804 18805 18806)

echo ""
info "开始安装..."

# ── 步骤 1：系统依赖 ──────────────────────────────
info "步骤 1/8: 安装系统依赖..."
apt-get update -qq
apt-get install -y -qq curl git jq redis-tools
ok "系统依赖安装完成"

# ── 步骤 2：安装 Node.js 22 ───────────────────────
info "步骤 2/8: 安装 Node.js 22..."
if ! node --version 2>/dev/null | grep -q "v2[2-9]"; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1
  apt-get install -y -qq nodejs
fi
ok "Node.js $(node --version) 已就绪"

# ── 步骤 3：安装 PM2 + OpenClaw ───────────────────
info "步骤 3/8: 安装 PM2 和 OpenClaw..."
npm config set prefix '/root/.npm-global'
export PATH=/root/.npm-global/bin:$PATH
echo 'export PATH=/root/.npm-global/bin:$PATH' >> /root/.bashrc

npm install -g pm2 --silent
npm install -g openclaw --silent
ok "PM2 $(pm2 --version) + OpenClaw $(openclaw --version 2>/dev/null | head -1) 安装完成"

# ── 步骤 4：安装 Docker ───────────────────────────
info "步骤 4/8: 安装 Docker..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh > /dev/null 2>&1
fi
ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') 已就绪"

# ── 步骤 5：启动 Redis ────────────────────────────
info "步骤 5/8: 启动 Redis 共享容器..."
docker network create openclaw-redis-shared 2>/dev/null || true
docker rm -f openclaw-redis-shared 2>/dev/null || true
docker run -d \
  --name openclaw-redis-shared \
  --network openclaw-redis-shared \
  -p 16379:6379 \
  --restart unless-stopped \
  redis:alpine \
  redis-server --appendonly yes > /dev/null
sleep 2
redis-cli -p 16379 ping | grep -q PONG && ok "Redis 启动成功 (16379)" || error "Redis 启动失败"

# ── 步骤 6：配置 Master ───────────────────────────
info "步骤 6/8: 配置 Master（${MASTER_NAME}）..."
mkdir -p $OPENCLAW_DIR/master/data
mkdir -p $OPENCLAW_DIR/logs

# 生成 Master openclaw.json
cat > $OPENCLAW_DIR/master/openclaw.json << EOF
{
  "\$schema": "https://openclaw.ai/schema/config.json",
  "meta": { "lastTouchedVersion": "2026.3.13" },
  "models": {
    "mode": "merge",
    "providers": {
      "aliyun": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "${ALIYUN_KEY}",
        "api": "openai-completions",
        "models": [{
          "id": "qwen3.5-plus",
          "name": "qwen3.5-plus",
          "input": ["text", "image"],
          "contextWindow": 30000
        }]
      }
    }
  },
  "agents": {
    "defaults": { "model": { "primary": "aliyun/qwen3.5-plus" } }
  },
  "tools": { "profile": "full", "sessions": { "visibility": "all" } },
  "commands": { "native": "auto", "nativeSkills": "auto", "restart": true, "ownerDisplay": "raw" },
  "session": { "dmScope": "per-channel-peer" },
  "bindings": [{ "agentId": "main", "match": { "channel": "feishu", "accountId": "master-bot" } }],
  "channels": {
    "feishu": {
      "enabled": true,
      "connectionMode": "websocket",
      "domain": "feishu",
      "defaultAccount": "master-bot",
      "accounts": {
        "master-bot": {
          "enabled": true,
          "appId": "${MASTER_APP_ID}",
          "appSecret": "${MASTER_APP_SECRET}",
          "dmPolicy": "open"
        }
      }
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "controlUi": { "allowedOrigins": ["*"] },
    "auth": { "mode": "token", "token": "$(openssl rand -hex 24)" }
  },
  "plugins": {
    "allow": ["a2a-gateway", "feishu"],
    "load": { "paths": ["/root/.openclaw/workspace/plugins/a2a-gateway"] },
    "entries": {
      "feishu": { "enabled": true },
      "a2a-gateway": {
        "enabled": true,
        "config": {
          "agentCard": {
            "name": "${MASTER_NAME}",
            "description": "${MASTER_NAME} - Master",
            "url": "http://$(curl -s ifconfig.me 2>/dev/null || echo '127.0.0.1'):18789/a2a/jsonrpc",
            "skills": [{ "id": "chat", "name": "chat", "description": "${MASTER_NAME}" }]
          },
          "server": { "host": "0.0.0.0", "port": 18800 },
          "security": { "inboundAuth": "bearer", "token": "$(openssl rand -hex 16)" },
          "routing": { "defaultAgentId": "main" },
          "peers": []
        }
      }
    }
  }
}
EOF

# Master start.sh
cat > $OPENCLAW_DIR/master/start.sh << 'STARTSH'
#!/bin/bash
export OPENCLAW_CONFIG_PATH=/root/.openclaw/master/openclaw.json
export OPENCLAW_DATA_DIR=/root/.openclaw/master/data
export OPENCLAW_NO_RESPAWN=1
mkdir -p $OPENCLAW_DATA_DIR
exec /root/.npm-global/bin/openclaw gateway
STARTSH
chmod +x $OPENCLAW_DIR/master/start.sh

ok "Master 配置完成"

# ── 步骤 7：配置并启动 Worker 容器 ────────────────
info "步骤 7/8: 配置 Worker 容器..."

# 从已有镜像里找，或者用官方镜像
WORKER_IMAGE="openclaw/openclaw:latest"
if docker image ls | grep -q "openclaw-docker"; then
  WORKER_IMAGE=$(docker image ls | grep openclaw-docker | head -1 | awk '{print $1":"$2}')
  info "使用已有镜像: $WORKER_IMAGE"
fi

# 安装 a2a-gateway 插件
mkdir -p $OPENCLAW_DIR/workspace/plugins
if [ ! -d "$OPENCLAW_DIR/workspace/plugins/a2a-gateway" ]; then
  info "安装 a2a-gateway 插件..."
  cd $OPENCLAW_DIR/workspace/plugins
  git clone https://github.com/win4r/openclaw-a2a-gateway.git a2a-gateway > /dev/null 2>&1
  cd a2a-gateway && npm install --production > /dev/null 2>&1
fi

A2A_TOKEN=$(openssl rand -hex 16)

for i in $(seq 0 $((WORKER_COUNT-1))); do
  IFS='|' read -r W_NAME W_APP_ID W_APP_SECRET <<< "${WORKERS[$i]}"
  W_ID=$(echo "$W_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
  GW_PORT=${SAFE_PORTS[$i]}
  A2A_PORT=${A2A_PORTS[$i]}

  mkdir -p $OPENCLAW_DIR/${W_ID}/{data,workspace}

  # Worker openclaw.json
  cat > $OPENCLAW_DIR/${W_ID}/openclaw.json << EOF
{
  "\$schema": "https://openclaw.ai/schema/config.json",
  "meta": { "lastTouchedVersion": "2026.3.13" },
  "models": {
    "mode": "merge",
    "providers": {
      "aliyun": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "${ALIYUN_KEY}",
        "api": "openai-completions",
        "models": [{ "id": "qwen3.5-plus", "name": "qwen3.5-plus", "input": ["text","image"], "contextWindow": 30000 }]
      }
    }
  },
  "agents": {
    "defaults": { "model": { "primary": "aliyun/qwen3.5-plus" } },
    "list": [{ "id": "${W_ID}", "default": true, "name": "${W_NAME}", "workspace": "/root/.openclaw/${W_ID}/workspace" }]
  },
  "tools": { "profile": "full", "sessions": { "visibility": "all" } },
  "commands": { "native": "auto", "nativeSkills": "auto", "restart": true, "ownerDisplay": "raw" },
  "session": { "dmScope": "per-channel-peer" },
  "bindings": [{ "agentId": "${W_ID}", "match": { "channel": "feishu", "accountId": "${W_ID}-bot" } }],
  "channels": {
    "feishu": {
      "enabled": true,
      "connectionMode": "websocket",
      "domain": "feishu",
      "defaultAccount": "${W_ID}-bot",
      "accounts": {
        "${W_ID}-bot": {
          "enabled": true,
          "appId": "${W_APP_ID}",
          "appSecret": "${W_APP_SECRET}",
          "dmPolicy": "open"
        }
      }
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "controlUi": { "allowedOrigins": ["*"] },
    "auth": { "mode": "token", "token": "$(openssl rand -hex 24)" }
  },
  "plugins": {
    "allow": ["a2a-gateway", "feishu"],
    "load": { "paths": ["/root/.openclaw/workspace/plugins/a2a-gateway"] },
    "entries": {
      "feishu": { "enabled": true },
      "a2a-gateway": {
        "enabled": true,
        "config": {
          "agentCard": {
            "name": "${W_NAME}",
            "description": "${W_NAME}",
            "url": "http://172.19.0.1:${GW_PORT}/a2a/jsonrpc",
            "skills": [{ "id": "chat", "name": "chat", "description": "${W_NAME}" }]
          },
          "server": { "host": "0.0.0.0", "port": ${A2A_PORT} },
          "security": { "inboundAuth": "bearer", "token": "${A2A_TOKEN}" },
          "routing": { "defaultAgentId": "${W_ID}" },
          "peers": [{
            "name": "${MASTER_NAME}",
            "agentCardUrl": "http://172.19.0.1:18800/.well-known/agent-card.json",
            "auth": { "type": "bearer", "token": "${A2A_TOKEN}" }
          }]
        }
      }
    }
  }
}
EOF

  # 启动 Worker 容器
  docker rm -f openclaw-${W_ID} 2>/dev/null || true
  docker run -d \
    --name openclaw-${W_ID} \
    --network openclaw-redis-shared \
    -p ${GW_PORT}:18789 \
    -p ${A2A_PORT}:${A2A_PORT} \
    -v $OPENCLAW_DIR/workspace:/root/.openclaw/workspace:ro \
    -v $OPENCLAW_DIR/${W_ID}/openclaw.json:/root/.openclaw/openclaw.json:ro \
    -v $OPENCLAW_DIR/${W_ID}/data:/root/.openclaw/agents \
    -e OPENCLAW_CONFIG_PATH=/root/.openclaw/openclaw.json \
    --restart unless-stopped \
    --memory 2g \
    $WORKER_IMAGE > /dev/null

  ok "Worker ${W_NAME} 启动 (gateway:${GW_PORT} a2a:${A2A_PORT})"
done

# ── 步骤 8：PM2 守护 Master + 启动顺序服务 ────────
info "步骤 8/8: PM2 守护 Master + 开机自启..."

cat > $OPENCLAW_DIR/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: "master",
    script: "/root/.openclaw/master/start.sh",
    interpreter: "bash",
    max_memory_restart: "2G",
    restart_delay: 3000,
    max_restarts: 100,
    autorestart: true,
    watch: false,
    log_file: "/root/.openclaw/logs/master.log",
    error_file: "/root/.openclaw/logs/master-error.log",
    time: true
  }]
};
EOF

pm2 start $OPENCLAW_DIR/ecosystem.config.js
pm2 save
pm2 startup systemd -u root --hp /root | tail -1 | bash 2>/dev/null || true

# 启动顺序服务
cat > /root/openclaw-startup.sh << 'EOF'
#!/bin/bash
LOG=/root/.openclaw/logs/startup.log
echo "[$(date)] 等待 Master A2A 18800 就绪..." >> $LOG
for i in $(seq 1 30); do
  if curl -s --max-time 2 http://127.0.0.1:18800/.well-known/agent-card.json > /dev/null 2>&1; then
    echo "[$(date)] Master 就绪，重启所有 Worker..." >> $LOG
    docker ps --filter "name=openclaw-" --format "{{.Names}}" | grep -v "redis" | xargs docker restart >> $LOG 2>&1
    echo "[$(date)] 完成" >> $LOG
    exit 0
  fi
  sleep 5
done
echo "[$(date)] 超时" >> $LOG
EOF
chmod +x /root/openclaw-startup.sh

cat > /etc/systemd/system/openclaw-startup.service << 'EOF'
[Unit]
Description=OpenClaw Worker startup order
After=network.target docker.service pm2-root.service
Wants=pm2-root.service

[Service]
Type=oneshot
ExecStart=/root/openclaw-startup.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openclaw-startup.service

echo ""
echo "============================================"
ok "安装完成！"
echo "============================================"
echo ""
echo "验证命令："
echo "  pm2 list"
echo "  docker ps"
echo "  curl http://127.0.0.1:18800/.well-known/agent-card.json"
echo ""
echo "飞书配对命令（每个 Worker 在飞书发消息后）："
for i in $(seq 0 $((WORKER_COUNT-1))); do
  IFS='|' read -r W_NAME _ _ <<< "${WORKERS[$i]}"
  W_ID=$(echo "$W_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
  echo "  docker exec openclaw-${W_ID} openclaw pairing approve feishu <配对码>"
done
