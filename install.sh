#!/bin/bash
# ============================================================
# OpenClaw 多实例一键部署 v4（最终版）
# Ubuntu 22.04 | 阿里云模型 + 火山引擎备用 | 飞书
# 基于实际踩坑经验，2026-03-23
# 用法: bash install.sh
# ============================================================

set -e
OPENCLAW_DIR=/root/.openclaw
OPENCLAW_BIN=/root/.npm-global/bin/openclaw

R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; C='\033[0;36m'; NC='\033[0m'
info()   { echo -e "${C}[INFO]${NC}  $1"; }
ok()     { echo -e "${G}[OK]${NC}    $1"; }
warn()   { echo -e "${Y}[WARN]${NC}  $1"; }
error()  { echo -e "${R}[ERROR]${NC} $1"; exit 1; }
header() { echo -e "\n${C}══════════════════════════════════${NC}\n${C}  $1${NC}\n${C}══════════════════════════════════${NC}"; }

header "OpenClaw 多实例部署 v4"

# ── 收集配置 ──────────────────────────────────────────────
read -p "服务器公网 IP: " SERVER_IP
read -p "阿里云 API Key (sk-sp-xxx): " ALIYUN_KEY
read -p "火山引擎 API Key (备用，没有直接回车跳过): " VOLC_KEY
echo ""
read -p "Master 名字（如：南朝译）: " MASTER_NAME
read -p "Master 飞书 AppID: " MASTER_APP_ID
read -p "Master 飞书 AppSecret: " MASTER_APP_SECRET
echo ""
read -p "Worker 数量 (1-5): " WORKER_COUNT

WORKERS=()
for i in $(seq 1 $WORKER_COUNT); do
  echo ""
  echo "--- Worker $i ---"
  read -p "  名字（如：技术员）: " W_NAME
  read -p "  英文ID（如：tech）: " W_ID
  read -p "  飞书 AppID: " W_APP_ID
  read -p "  飞书 AppSecret: " W_APP_SECRET
  read -p "  Docker 镜像（如：openclaw-docker_cto:latest）: " W_IMAGE
  WORKERS+=("${W_NAME}|${W_ID}|${W_APP_ID}|${W_APP_SECRET}|${W_IMAGE}")
done

# 端口规划
GW_PORTS=(18795 18796 18797 18798 18799)
A2A_PORTS=(18811 18812 18813 18814 18815)

# 生成 Token
A2A_TOKEN=$(openssl rand -hex 16)
GW_TOKEN=$(openssl rand -hex 24)

echo ""
info "开始安装..."

# ═══ 步骤 0：清理残留 ════════════════════════════════════
header "步骤 0/9: 清理残留"
pm2 delete all 2>/dev/null || true
docker rm -f $(docker ps -aq --filter "name=openclaw-") 2>/dev/null || true
rm -rf $OPENCLAW_DIR/extensions/a2a-gateway 2>/dev/null || true
ok "清理完成"

# ═══ 步骤 1：系统依赖 ════════════════════════════════════
header "步骤 1/9: 系统依赖"
apt-get update -qq
apt-get install -y -qq curl git jq redis-tools cron
ok "完成"

# ═══ 步骤 2：Node.js 22 ══════════════════════════════════
header "步骤 2/9: Node.js 22"
if ! node --version 2>/dev/null | grep -q "v2[2-9]"; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1
  apt-get install -y -qq nodejs
fi
ok "Node.js $(node --version)"

# ═══ 步骤 3：PM2 + OpenClaw ══════════════════════════════
header "步骤 3/9: PM2 + OpenClaw"
npm config set prefix '/root/.npm-global'
export PATH=/root/.npm-global/bin:$PATH
grep -q '.npm-global' /root/.bashrc || echo 'export PATH=/root/.npm-global/bin:$PATH' >> /root/.bashrc
npm install -g pm2 --silent
npm install -g openclaw --silent
ok "PM2 + OpenClaw 完成"

# ═══ 步骤 4：Docker ══════════════════════════════════════
header "步骤 4/9: Docker"
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh > /dev/null 2>&1
fi
ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"

# ═══ 步骤 5：Redis ════════════════════════════════════════
header "步骤 5/9: Redis"
docker network create openclaw-redis-shared 2>/dev/null && ok "网络创建" || warn "网络已存在"
docker rm -f openclaw-redis-shared 2>/dev/null || true
docker run -d \
  --name openclaw-redis-shared \
  --network openclaw-redis-shared \
  -p 16379:6379 \
  --restart unless-stopped \
  redis:alpine \
  redis-server --appendonly yes > /dev/null
sleep 3
redis-cli -p 16379 ping | grep -q PONG && ok "Redis (16379)" || error "Redis 启动失败"

# ═══ 步骤 6：a2a-gateway 插件 ═════════════════════════════
header "步骤 6/9: a2a-gateway 插件"
mkdir -p $OPENCLAW_DIR/workspace/plugins $OPENCLAW_DIR/logs
rm -rf $OPENCLAW_DIR/extensions/a2a-gateway 2>/dev/null || true  # 删除重复版本
if [ ! -d "$OPENCLAW_DIR/workspace/plugins/a2a-gateway" ]; then
  cd $OPENCLAW_DIR/workspace/plugins
  git clone https://github.com/win4r/openclaw-a2a-gateway.git a2a-gateway > /dev/null 2>&1
  cd a2a-gateway && npm install --production > /dev/null 2>&1
fi
ok "a2a-gateway 插件就绪"

# ═══ 步骤 7：配置并启动 Master ════════════════════════════
header "步骤 7/9: Master（${MASTER_NAME}）"
mkdir -p $OPENCLAW_DIR/master/data

# 生成所有 Worker 的 peers JSON
PEERS_JSON=""
for i in $(seq 0 $((WORKER_COUNT-1))); do
  IFS='|' read -r W_NAME W_ID _ _ _ <<< "${WORKERS[$i]}"
  A2A_PORT=${A2A_PORTS[$i]}
  [ $i -gt 0 ] && PEERS_JSON="${PEERS_JSON},"
  PEERS_JSON="${PEERS_JSON}
          {\"name\": \"${W_NAME}\", \"agentCardUrl\": \"http://172.19.0.1:${A2A_PORT}/.well-known/agent-card.json\", \"auth\": {\"type\": \"bearer\", \"token\": \"${A2A_TOKEN}\"}}"
done

# 备用模型配置
VOLC_PROVIDER=""
FALLBACKS=""
if [ -n "$VOLC_KEY" ]; then
  VOLC_PROVIDER=',
      "volc": {
        "baseUrl": "https://ark.cn-beijing.volces.com/api/coding/v3",
        "apiKey": "'"${VOLC_KEY}"'",
        "api": "openai-completions",
        "models": [{"id": "doubao-seed-2.0-code", "name": "doubao-seed-2.0-code", "input": ["text","image"], "contextWindow": 30000}]
      }'
  FALLBACKS='"fallbacks": ["volc/doubao-seed-2.0-code"],'
fi

cat > $OPENCLAW_DIR/master/openclaw.json << EOF
{
  "\$schema": "https://openclaw.ai/schema/config.json",
  "meta": {"lastTouchedVersion": "2026.3.13"},
  "models": {
    "mode": "merge",
    "providers": {
      "aliyun": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "${ALIYUN_KEY}",
        "api": "openai-completions",
        "models": [{"id": "qwen3.5-plus", "name": "qwen3.5-plus", "input": ["text","image"], "contextWindow": 30000}]
      }${VOLC_PROVIDER}
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "aliyun/qwen3.5-plus",
        ${FALLBACKS}
        "placeholder": true
      }
    }
  },
  "tools": {"profile": "full", "sessions": {"visibility": "all"}},
  "commands": {"native": "auto", "nativeSkills": "auto", "restart": true, "ownerDisplay": "raw"},
  "session": {"dmScope": "per-channel-peer"},
  "bindings": [{"agentId": "main", "match": {"channel": "feishu", "accountId": "master-bot"}}],
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
    "controlUi": {"allowedOrigins": ["*"]},
    "auth": {"mode": "token", "token": "${GW_TOKEN}"}
  },
  "plugins": {
    "allow": ["a2a-gateway", "feishu"],
    "load": {"paths": ["${OPENCLAW_DIR}/workspace/plugins/a2a-gateway"]},
    "entries": {
      "feishu": {"enabled": true},
      "a2a-gateway": {
        "enabled": true,
        "config": {
          "agentCard": {
            "name": "${MASTER_NAME}",
            "description": "${MASTER_NAME} - Master",
            "url": "http://172.19.0.1:18800/a2a/jsonrpc",
            "skills": [{"id": "chat", "name": "chat", "description": "${MASTER_NAME}"}]
          },
          "server": {"host": "0.0.0.0", "port": 18800},
          "security": {"inboundAuth": "bearer", "token": "${A2A_TOKEN}"},
          "routing": {"defaultAgentId": "main"},
          "peers": [${PEERS_JSON}
          ]
        }
      }
    }
  }
}
EOF

cat > $OPENCLAW_DIR/master/start.sh << STARTSH
#!/bin/bash
export OPENCLAW_CONFIG_PATH=${OPENCLAW_DIR}/master/openclaw.json
export OPENCLAW_DATA_DIR=${OPENCLAW_DIR}/master/data
export OPENCLAW_NO_RESPAWN=1
mkdir -p \$OPENCLAW_DATA_DIR
exec ${OPENCLAW_BIN} gateway
STARTSH
chmod +x $OPENCLAW_DIR/master/start.sh

cat > $OPENCLAW_DIR/ecosystem.config.js << 'ECOEOF'
module.exports = {
  apps: [{
    name: "master-nanchaoyi",
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
ECOEOF

pm2 start $OPENCLAW_DIR/ecosystem.config.js
pm2 save
pm2 startup systemd -u root --hp /root 2>/dev/null | grep "systemctl\|env PATH" | bash 2>/dev/null || true

# 等 Master A2A 就绪
info "等待 Master A2A 18800..."
for i in $(seq 1 24); do
  if curl -s --max-time 2 http://127.0.0.1:18800/.well-known/agent-card.json > /dev/null 2>&1; then
    ok "Master A2A 就绪"
    break
  fi
  [ $i -eq 24 ] && warn "Master A2A 超时，继续..." || sleep 5
done

# ═══ 步骤 8：Worker 容器 ══════════════════════════════════
header "步骤 8/9: Worker 容器"

for i in $(seq 0 $((WORKER_COUNT-1))); do
  IFS='|' read -r W_NAME W_ID W_APP_ID W_APP_SECRET W_IMAGE <<< "${WORKERS[$i]}"
  GW_PORT=${GW_PORTS[$i]}
  A2A_PORT=${A2A_PORTS[$i]}

  # 构建该 Worker 的 peers（Master + 其他所有 Worker）
  W_PEERS=""
  # 先加 Master
  W_PEERS="{\"name\": \"${MASTER_NAME}\", \"agentCardUrl\": \"http://172.19.0.1:18800/.well-known/agent-card.json\", \"auth\": {\"type\": \"bearer\", \"token\": \"${A2A_TOKEN}\"}}"
  # 再加其他 Worker
  for j in $(seq 0 $((WORKER_COUNT-1))); do
    [ $j -eq $i ] && continue  # 跳过自己
    IFS='|' read -r OTHER_NAME OTHER_ID _ _ _ <<< "${WORKERS[$j]}"
    OTHER_A2A=${A2A_PORTS[$j]}
    W_PEERS="${W_PEERS},{\"name\": \"${OTHER_NAME}\", \"agentCardUrl\": \"http://172.19.0.1:${OTHER_A2A}/.well-known/agent-card.json\", \"auth\": {\"type\": \"bearer\", \"token\": \"${A2A_TOKEN}\"}}"
  done

  mkdir -p $OPENCLAW_DIR/${W_ID}/{data,workspace}

  cat > $OPENCLAW_DIR/${W_ID}/openclaw.json << EOF
{
  "\$schema": "https://openclaw.ai/schema/config.json",
  "meta": {"lastTouchedVersion": "2026.3.13"},
  "models": {
    "mode": "merge",
    "providers": {
      "aliyun": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "${ALIYUN_KEY}",
        "api": "openai-completions",
        "models": [{"id": "qwen3.5-plus", "name": "qwen3.5-plus", "input": ["text","image"], "contextWindow": 30000}]
      }${VOLC_PROVIDER}
    }
  },
  "agents": {
    "defaults": {"model": {"primary": "aliyun/qwen3.5-plus", ${FALLBACKS} "placeholder": true}},
    "list": [{"id": "${W_ID}", "default": true, "name": "${W_NAME}", "workspace": "${OPENCLAW_DIR}/${W_ID}/workspace"}]
  },
  "tools": {"profile": "full", "sessions": {"visibility": "all"}},
  "commands": {"native": "auto", "nativeSkills": "auto", "restart": true, "ownerDisplay": "raw"},
  "session": {"dmScope": "per-channel-peer"},
  "bindings": [{"agentId": "${W_ID}", "match": {"channel": "feishu", "accountId": "${W_ID}-bot"}}],
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
    "controlUi": {"allowedOrigins": ["*"]},
    "auth": {"mode": "token", "token": "${GW_TOKEN}"}
  },
  "plugins": {
    "allow": ["a2a-gateway", "feishu"],
    "load": {"paths": ["${OPENCLAW_DIR}/workspace/plugins/a2a-gateway"]},
    "entries": {
      "feishu": {"enabled": true},
      "a2a-gateway": {
        "enabled": true,
        "config": {
          "agentCard": {
            "name": "${W_NAME}",
            "description": "${W_NAME}",
            "url": "http://172.19.0.1:${A2A_PORT}/a2a/jsonrpc",
            "skills": [{"id": "chat", "name": "chat", "description": "${W_NAME}"}]
          },
          "server": {"host": "0.0.0.0", "port": ${A2A_PORT}},
          "security": {"inboundAuth": "bearer", "token": "${A2A_TOKEN}"},
          "routing": {"defaultAgentId": "${W_ID}"},
          "peers": [${W_PEERS}]
        }
      }
    }
  }
}
EOF

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
    ${W_IMAGE} > /dev/null

  ok "Worker ${W_NAME} (gw:${GW_PORT} a2a:${A2A_PORT}) 已启动"
done

# ═══ 步骤 9：健康监控 + 自动化 ════════════════════════════
header "步骤 9/9: 健康监控 + 自动化"

# 健康监控脚本
cat > $OPENCLAW_DIR/health-monitor.sh << 'EOF'
#!/bin/bash
LOG=/root/.openclaw/logs/health-monitor.log
ts() { date '+%Y-%m-%d %H:%M:%S'; }

# Master
if ! pm2 list | grep -q "master.*online"; then
  echo "[$(ts)] WARN: Master 不在线，重启..." >> $LOG
  pm2 restart master-nanchaoyi >> $LOG 2>&1
else
  echo "[$(ts)] OK: Master 在线" >> $LOG
fi

if ! curl -s --max-time 5 http://127.0.0.1:18800/.well-known/agent-card.json > /dev/null 2>&1; then
  echo "[$(ts)] WARN: Master A2A 无响应，重启..." >> $LOG
  pm2 restart master-nanchaoyi >> $LOG 2>&1
fi

# Workers
for container in $(docker ps -a --filter "name=openclaw-" --format "{{.Names}}" | grep -v redis); do
  STATUS=$(docker inspect --format='{{.State.Status}}' $container 2>/dev/null)
  if [ "$STATUS" != "running" ]; then
    echo "[$(ts)] WARN: $container=$STATUS，重启..." >> $LOG
    docker start $container >> $LOG 2>&1
  else
    echo "[$(ts)] OK: $container" >> $LOG
  fi
done

LINE_COUNT=$(wc -l < $LOG 2>/dev/null || echo 0)
[ "$LINE_COUNT" -gt 500 ] && tail -200 $LOG > ${LOG}.tmp && mv ${LOG}.tmp $LOG
EOF
chmod +x $OPENCLAW_DIR/health-monitor.sh

# 一键复位脚本
cat > /root/claw-fix.sh << 'EOF'
#!/bin/bash
C='\033[0;36m'; G='\033[0;32m'; NC='\033[0m'
echo -e "${C}=== OpenClaw 一键复位 ===${NC}"
pm2 restart master-nanchaoyi
sleep 10
for i in $(seq 1 12); do
  curl -s --max-time 2 http://127.0.0.1:18800/.well-known/agent-card.json > /dev/null 2>&1 && break
  sleep 5
done
docker ps -a --filter "name=openclaw-" --format "{{.Names}}" | grep -v redis | xargs docker restart
sleep 5
pm2 list
docker ps --filter "name=openclaw-" --format "table {{.Names}}\t{{.Status}}"
EOF
chmod +x /root/claw-fix.sh

# 开机启动顺序
cat > /root/openclaw-startup.sh << 'EOF'
#!/bin/bash
LOG=/root/.openclaw/logs/startup.log
echo "[$(date)] 开机启动..." >> $LOG
for i in $(seq 1 30); do
  curl -s --max-time 2 http://127.0.0.1:18800/.well-known/agent-card.json > /dev/null 2>&1 && \
    docker ps -a --filter "name=openclaw-" --format "{{.Names}}" | grep -v redis | xargs docker restart >> $LOG 2>&1 && \
    echo "[$(date)] 完成" >> $LOG && exit 0
  sleep 5
done
EOF
chmod +x /root/openclaw-startup.sh

cat > /etc/systemd/system/openclaw-startup.service << 'EOF'
[Unit]
Description=OpenClaw startup order
After=network.target docker.service pm2-root.service
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

# Cron
(crontab -l 2>/dev/null | grep -v "health-monitor"; \
  echo "* * * * * /root/.openclaw/health-monitor.sh") | crontab -

ok "健康监控、一键复位、开机自启全部就绪"

# ═══ 最终验证 ════════════════════════════════════════════
header "验证中..."
sleep 15

echo ""
PASS=0; FAIL=0
check() {
  if eval "$2" > /dev/null 2>&1; then
    ok "$1"; PASS=$((PASS+1))
  else
    warn "$1 未就绪"; FAIL=$((FAIL+1))
  fi
}

check "Master A2A (18800)" "curl -s --max-time 3 http://127.0.0.1:18800/.well-known/agent-card.json"
check "Redis (16379)" "redis-cli -p 16379 ping | grep -q PONG"
check "健康监控 cron" "crontab -l | grep -q health-monitor"

for i in $(seq 0 $((WORKER_COUNT-1))); do
  IFS='|' read -r W_NAME W_ID _ _ _ <<< "${WORKERS[$i]}"
  A2A_PORT=${A2A_PORTS[$i]}
  check "Worker ${W_NAME} A2A (${A2A_PORT})" "curl -s --max-time 3 http://127.0.0.1:${A2A_PORT}/.well-known/agent-card.json"
done

echo ""
pm2 list
docker ps --filter "name=openclaw-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "══════════════════════════════════"
echo "  通过: ${PASS}  未就绪: ${FAIL}"
echo "  A2A Token:     ${A2A_TOKEN}"
echo "  Gateway Token: ${GW_TOKEN}"
echo "══════════════════════════════════"
echo ""
echo "飞书配对命令："
for i in $(seq 0 $((WORKER_COUNT-1))); do
  IFS='|' read -r W_NAME W_ID _ _ _ <<< "${WORKERS[$i]}"
  echo "  docker exec openclaw-${W_ID} openclaw pairing approve feishu <配对码>"
done
echo ""
echo "一键复位: bash /root/claw-fix.sh"
