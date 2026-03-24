#!/bin/bash
# ============================================================
# OpenClaw 多实例一键部署 v5
# Ubuntu 22.04 | 火山引擎主模型 + 阿里云备用 | 飞书
# 更新：2026-03-24
# 新增：任务管理系统、记忆注入、踩坑记录
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

header "OpenClaw 多实例部署 v5"

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

GW_PORTS=(18795 18796 18797 18798 18799)
A2A_PORTS=(18811 18812 18813 18814 18815)
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
rm -rf $OPENCLAW_DIR/extensions/a2a-gateway 2>/dev/null || true
if [ ! -d "$OPENCLAW_DIR/workspace/plugins/a2a-gateway" ]; then
  cd $OPENCLAW_DIR/workspace/plugins
  git clone https://github.com/win4r/openclaw-a2a-gateway.git a2a-gateway > /dev/null 2>&1
  cd a2a-gateway && npm install --production > /dev/null 2>&1
fi
ok "a2a-gateway 插件就绪"

# ═══ 步骤 6.5：初始化共享 workspace ══════════════════════
header "步骤 6.5/9: 初始化共享 workspace"

mkdir -p $OPENCLAW_DIR/workspace

cat > $OPENCLAW_DIR/workspace/LESSONS.md << 'LESSEOF'
# LESSONS.md - 踩坑记录
# 遇到新问题就补在这里，同步命令：bash /root/.openclaw/task.sh sync

## 飞书能力
- 各机器人本身就是飞书机器人，直接回复就是发消息，不需要额外工具
- 看到 feishu-chat SKILL.md not found 报错，忽略，不影响正常功能

## 飞书场景判断
- 老板私信Master = 私聊，只有Master和老板能看到
- 在私聊里@员工没有意义，他们看不到
- 要让员工在飞书群发言：通过A2A通知员工，让他们自己去群里发，Master不能代替员工发言

## A2A通信
- Worker间通信只用 http://172.19.0.1:端口，不用容器IP
- 容器重启后IP会变，172.19.0.x 会失效

## 任务管理
- 启动时必须先读 TASKS.md，有未完成任务优先处理
- 完成任务后通知Master，任务ID格式：task:时间戳

## 业务踩坑（在此补充本服务器特有的问题）

LESSEOF

cat > $OPENCLAW_DIR/workspace/SOUL.md << 'SOULEOF'
# SOUL.md - Master（CEO）

## 我是谁
我是团队的CEO，运行在宿主机（PM2管理），通过飞书和老板沟通，通过A2A和员工沟通。

## 飞书场景判断（重要）
- 老板私信我 = 私聊，只有我和老板能看到
- 飞书群是独立的群聊，员工各自有自己的飞书机器人账号在群里
- 在私聊里@员工没有意义，他们看不到
- 要让员工在群里发言：通过A2A通知他们，让他们自己去发，我不能代替员工发言

## 启动必读
1. TASKS.md — 全团队任务总览
2. LESSONS.md — 踩过的坑
3. EMPLOYEES.md — 团队成员联系方式
SOULEOF

ok "共享 workspace 初始化完成"

# ═══ 步骤 7：配置并启动 Master ════════════════════════════
header "步骤 7/9: Master（${MASTER_NAME}）"
mkdir -p $OPENCLAW_DIR/master/data

PEERS_JSON=""
for i in $(seq 0 $((WORKER_COUNT-1))); do
  IFS='|' read -r W_NAME W_ID _ _ _ <<< "${WORKERS[$i]}"
  A2A_PORT=${A2A_PORTS[$i]}
  [ $i -gt 0 ] && PEERS_JSON="${PEERS_JSON},"
  PEERS_JSON="${PEERS_JSON}
          {\"name\": \"${W_NAME}\", \"agentCardUrl\": \"http://172.19.0.1:${A2A_PORT}/.well-known/agent-card.json\", \"auth\": {\"type\": \"bearer\", \"token\": \"${A2A_TOKEN}\"}}"
done

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

info "等待 Master A2A 18800..."
for i in $(seq 1 24); do
  if curl -s --max-time 2 http://127.0.0.1:18800/.well-known/agent-card.json > /dev/null 2>&1; then
    ok "Master A2A 就绪"; break
  fi
  [ $i -eq 24 ] && warn "Master A2A 超时，继续..." || sleep 5
done

# ═══ 步骤 8：Worker 容器 ══════════════════════════════════
header "步骤 8/9: Worker 容器"

for i in $(seq 0 $((WORKER_COUNT-1))); do
  IFS='|' read -r W_NAME W_ID W_APP_ID W_APP_SECRET W_IMAGE <<< "${WORKERS[$i]}"
  GW_PORT=${GW_PORTS[$i]}
  A2A_PORT=${A2A_PORTS[$i]}

  W_PEERS="{\"name\": \"${MASTER_NAME}\", \"agentCardUrl\": \"http://172.19.0.1:18800/.well-known/agent-card.json\", \"auth\": {\"type\": \"bearer\", \"token\": \"${A2A_TOKEN}\"}}"
  for j in $(seq 0 $((WORKER_COUNT-1))); do
    [ $j -eq $i ] && continue
    IFS='|' read -r OTHER_NAME OTHER_ID _ _ _ <<< "${WORKERS[$j]}"
    OTHER_A2A=${A2A_PORTS[$j]}
    W_PEERS="${W_PEERS},{\"name\": \"${OTHER_NAME}\", \"agentCardUrl\": \"http://172.19.0.1:${OTHER_A2A}/.well-known/agent-card.json\", \"auth\": {\"type\": \"bearer\", \"token\": \"${A2A_TOKEN}\"}}"
  done

  mkdir -p $OPENCLAW_DIR/${W_ID}/data
  mkdir -p $OPENCLAW_DIR/${W_ID}/private-workspace

  # Worker SOUL.md
  cat > $OPENCLAW_DIR/${W_ID}/private-workspace/SOUL.md << 'SOULEOF'
# SOUL.md - Who You Are

_You're not a chatbot. You're becoming someone._

## Core Truths

**Be genuinely helpful, not performatively helpful.** Skip the filler — just help.
**Be resourceful before asking.** Try to figure it out. Read the file. Check the context. Then ask if stuck.
**Earn trust through competence.** Be careful with external actions, bold with internal ones.

## Continuity

Each session, you wake up fresh. These files are your memory. Read them. Update them.

---

## 启动必读规则

每次会话开始时，第一件事是读取以下文件：
1. TASKS.md — 我的待办任务，有未完成任务必须优先处理
2. LESSONS.md — 团队踩过的坑，遇到问题先查这里

如果 TASKS.md 里有未完成任务：
- 主动向Master汇报："我有未完成任务 [任务ID]：[描述]，正在处理"
- 优先完成当前任务，再接新任务
- 完成后通知Master

任务完成汇报格式：
【完成】任务ID：xxx
内容：做了什么
产出：文件路径或结果
SOULEOF

  # Worker TASKS.md 初始为空
  cat > $OPENCLAW_DIR/${W_ID}/private-workspace/TASKS.md << 'TASKEOF'
# 我的待办任务

**启动时必读。有未完成任务时，优先完成，完成后通知Master。**

## 未完成任务
- 暂无待办任务
TASKEOF

  # 同步 LESSONS.md
  cp $OPENCLAW_DIR/workspace/LESSONS.md $OPENCLAW_DIR/${W_ID}/private-workspace/LESSONS.md

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
    "list": [{"id": "${W_ID}", "default": true, "name": "${W_NAME}", "workspace": "${OPENCLAW_DIR}/${W_ID}/private-workspace"}]
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
    -v $OPENCLAW_DIR/workspace:/root/.openclaw/workspace \
    -v $OPENCLAW_DIR/${W_ID}/private-workspace:/root/.openclaw/private-workspace \
    -v $OPENCLAW_DIR/${W_ID}/openclaw.json:/root/.openclaw/openclaw.json:ro \
    -v $OPENCLAW_DIR/${W_ID}/data:/root/.openclaw/agents \
    -e OPENCLAW_CONFIG_PATH=/root/.openclaw/openclaw.json \
    --restart unless-stopped \
    --memory 2g \
    ${W_IMAGE} > /dev/null

  ok "Worker ${W_NAME} (gw:${GW_PORT} a2a:${A2A_PORT}) 已启动"
done

# ═══ 步骤 9：健康监控 + 任务系统 ══════════════════════════
header "步骤 9/9: 健康监控 + 任务系统"

cat > $OPENCLAW_DIR/health-monitor.sh << 'MONEOF'
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

# Redis
if ! redis-cli -p 16379 ping | grep -q PONG; then
  echo "[$(ts)] WARN: Redis 无响应，重启..." >> $LOG
  docker restart openclaw-redis-shared >> $LOG 2>&1
else
  echo "[$(ts)] OK: Redis 正常" >> $LOG
fi

# Worker重启后自动同步任务上下文
for container in $(docker ps -a --filter "name=openclaw-" --format "{{.Names}}" | grep -v redis); do
  STARTED_AT=$(docker inspect --format='{{.State.StartedAt}}' $container 2>/dev/null)
  [ -z "$STARTED_AT" ] && continue
  START_TS=$(date -d "$STARTED_AT" +%s 2>/dev/null)
  [ -z "$START_TS" ] && continue
  DIFF=$(( $(date +%s) - START_TS ))
  if [ $DIFF -lt 120 ]; then
    echo "[$(ts)] INFO: $container 刚重启，同步任务上下文..." >> $LOG
    bash /root/.openclaw/task.sh sync >> $LOG 2>&1
    break
  fi
done

# 日志轮转
LINE_COUNT=$(wc -l < $LOG 2>/dev/null || echo 0)
[ "$LINE_COUNT" -gt 500 ] && tail -200 $LOG > ${LOG}.tmp && mv ${LOG}.tmp $LOG
MONEOF
chmod +x $OPENCLAW_DIR/health-monitor.sh

cat > $OPENCLAW_DIR/task.sh << 'TASKSHEOF'
#!/bin/bash
# 用法：
#   新建任务：bash /root/.openclaw/task.sh new <worker_id> "任务描述"
#   完成任务：bash /root/.openclaw/task.sh done task:ID
#   查看全部：bash /root/.openclaw/task.sh list
#   同步文件：bash /root/.openclaw/task.sh sync

REDIS="redis-cli -p 16379"
ACTION=$1

get_workers() {
  ls -d /root/.openclaw/*/private-workspace 2>/dev/null | \
    sed 's|/root/.openclaw/||' | sed 's|/private-workspace||'
}

sync_tasks_to_files() {
  for worker in $(get_workers); do
    DIR="/root/.openclaw/$worker/private-workspace"
    FILE="$DIR/TASKS.md"
    echo "# 我的待办任务 - $(date '+%Y-%m-%d %H:%M')" > $FILE
    echo "" >> $FILE
    echo "**启动时必读。有未完成任务时，优先完成，完成后通知Master。**" >> $FILE
    echo "" >> $FILE
    echo "## 未完成任务" >> $FILE
    HAS_TASK=0
    for id in $($REDIS SMEMBERS "tasks:pending:$worker" 2>/dev/null); do
      desc=$($REDIS HGET $id desc 2>/dev/null)
      created=$($REDIS HGET $id created 2>/dev/null)
      echo "- [ ] **[$id]** $desc（创建于 $created）" >> $FILE
      HAS_TASK=1
    done
    [ $HAS_TASK -eq 0 ] && echo "- 暂无待办任务" >> $FILE
    echo "" >> $FILE
    echo "## 最近完成（最近3条）" >> $FILE
    $REDIS LRANGE "tasks:done:$worker" 0 2 2>/dev/null | while read id; do
      [ -z "$id" ] && continue
      desc=$($REDIS HGET $id desc 2>/dev/null)
      [ -n "$desc" ] && echo "- [x] $desc" >> $FILE
    done
  done
  MASTER_FILE="/root/.openclaw/workspace/TASKS.md"
  echo "# 全团队任务总览 - $(date '+%Y-%m-%d %H:%M')" > $MASTER_FILE
  echo "" >> $MASTER_FILE
  for worker in $(get_workers); do
    echo "## $worker" >> $MASTER_FILE
    for id in $($REDIS SMEMBERS "tasks:pending:$worker" 2>/dev/null); do
      desc=$($REDIS HGET $id desc 2>/dev/null)
      echo "- [ ] $desc" >> $MASTER_FILE
    done
    COUNT=$($REDIS SCARD "tasks:pending:$worker" 2>/dev/null || echo 0)
    [ "$COUNT" -eq 0 ] && echo "- 暂无待办" >> $MASTER_FILE
    echo "" >> $MASTER_FILE
  done
  echo "已同步任务到所有Worker"
}

case $ACTION in
  new)
    WORKER=$2; DESC=$3
    [ -z "$WORKER" ] || [ -z "$DESC" ] && echo "用法：bash task.sh new <worker_id> <描述>" && exit 1
    ID="task:$(date +%Y%m%d%H%M%S)"
    $REDIS HSET $ID worker "$WORKER" desc "$DESC" status "pending" created "$(date '+%Y-%m-%d %H:%M')" > /dev/null
    $REDIS SADD "tasks:pending:$WORKER" $ID > /dev/null
    sync_tasks_to_files
    echo "任务已创建：$ID | 执行人：$WORKER | $DESC"
    ;;
  done)
    ID=$2
    WORKER=$($REDIS HGET $ID worker 2>/dev/null)
    [ -z "$WORKER" ] && echo "找不到任务：$ID" && exit 1
    $REDIS HSET $ID status "done" > /dev/null
    $REDIS SREM "tasks:pending:$WORKER" $ID > /dev/null
    $REDIS LPUSH "tasks:done:$WORKER" $ID > /dev/null
    $REDIS LTRIM "tasks:done:$WORKER" 0 9 > /dev/null
    sync_tasks_to_files
    echo "任务完成：$ID"
    ;;
  list)
    echo "========== 全团队任务 $(date '+%Y-%m-%d %H:%M') =========="
    for worker in $(get_workers); do
      COUNT=$($REDIS SCARD "tasks:pending:$worker" 2>/dev/null || echo 0)
      echo ""
      echo "【$worker】待办 $COUNT 条"
      for id in $($REDIS SMEMBERS "tasks:pending:$worker" 2>/dev/null); do
        desc=$($REDIS HGET $id desc 2>/dev/null)
        created=$($REDIS HGET $id created 2>/dev/null)
        echo "  - [$id] $desc（$created）"
      done
      [ "$COUNT" -eq 0 ] && echo "  （无待办）"
    done
    echo ""
    echo "================================================"
    ;;
  sync)
    sync_tasks_to_files
    ;;
  *)
    echo "用法："
    echo "  bash /root/.openclaw/task.sh new <worker_id> <描述>   # 新建任务"
    echo "  bash /root/.openclaw/task.sh done <task:ID>           # 标记完成"
    echo "  bash /root/.openclaw/task.sh list                     # 查看全部"
    echo "  bash /root/.openclaw/task.sh sync                     # 手动同步"
    ;;
esac
TASKSHEOF
chmod +x $OPENCLAW_DIR/task.sh

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
bash /root/.openclaw/task.sh sync
pm2 list
docker ps --filter "name=openclaw-" --format "table {{.Names}}\t{{.Status}}"
EOF
chmod +x /root/claw-fix.sh

cat > /root/openclaw-startup.sh << 'EOF'
#!/bin/bash
LOG=/root/.openclaw/logs/startup.log
echo "[$(date)] 开机启动..." >> $LOG
for i in $(seq 1 30); do
  curl -s --max-time 2 http://127.0.0.1:18800/.well-known/agent-card.json > /dev/null 2>&1 && \
    docker ps -a --filter "name=openclaw-" --format "{{.Names}}" | grep -v redis | xargs docker restart >> $LOG 2>&1 && \
    bash /root/.openclaw/task.sh sync >> $LOG 2>&1 && \
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

(crontab -l 2>/dev/null | grep -v "health-monitor"; \
  echo "* * * * * /root/.openclaw/health-monitor.sh") | crontab -

ok "健康监控、一键复位、开机自启、任务系统全部就绪"

# ═══ 最终验证 ════════════════════════════════════════════
header "验证中..."
sleep 15

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
check "task.sh" "[ -x /root/.openclaw/task.sh ]"

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
echo "任务管理："
echo "  新建任务: bash /root/.openclaw/task.sh new <worker_id> \"任务描述\""
echo "  查看进度: bash /root/.openclaw/task.sh list"
echo "  标记完成: bash /root/.openclaw/task.sh done task:ID"
echo ""
echo "新服务器踩坑补充到："
echo "  /root/.openclaw/workspace/LESSONS.md"
echo "  记录后同步: bash /root/.openclaw/task.sh sync"
echo ""
echo "飞书配对命令："
for i in $(seq 0 $((WORKER_COUNT-1))); do
  IFS='|' read -r W_NAME W_ID _ _ _ <<< "${WORKERS[$i]}"
  echo "  docker exec openclaw-${W_ID} openclaw pairing approve feishu <配对码>"
done
echo ""
echo "一键复位: bash /root/claw-fix.sh"
