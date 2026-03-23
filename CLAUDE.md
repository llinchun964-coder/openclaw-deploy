# OpenClaw 多实例部署规范 v4（最终版）
# 基于实际踩坑经验，2026-03-23

## 架构总览

```
用户飞书消息
    ↓
南朝译 Master（宿主机 PM2，18789）
    ↓ A2A 通过 172.19.0.1
技术员      运营官      设计师      南南
Docker      Docker     Docker     Docker
18795       18796      18797      18798
A2A:        A2A:       A2A:       A2A:
18811       18813      18815      18817
gRPC:       gRPC:      gRPC:      gRPC:
18812       18814      18816      18818
    ↓
Redis 记忆池（16379）
```

---

## 第一件事：检查现有环境

安装前必须先检查，不要直接装：

```bash
# 看有没有残留进程
ps aux | grep openclaw | grep -v grep
pm2 list 2>/dev/null

# 看有没有残留容器
docker ps -a | grep openclaw

# 看端口占用
ss -tlnp | grep -E "18789|18800|1879[0-9]|1881[0-9]"

# 如果有残留，先清理
pm2 delete all 2>/dev/null || true
docker rm -f $(docker ps -aq --filter "name=openclaw-") 2>/dev/null || true
```

---

## 端口规划（不可更改）

**重要**：a2a-gateway 的 gRPC 端口 = HTTP 端口 + 1，因此 Worker 之间必须间隔 2 个端口以避免冲突！

| 实例 | Gateway | A2A HTTP | A2A gRPC | 备注 |
|------|---------|----------|----------|------|
| Master | 18789 | 18800 | 18801 | gRPC 自动占用 18801 |
| Worker 1 (Tech) | 18795 | 18811 | 18812 | |
| Worker 2 (Ops) | 18796 | 18813 | 18814 | |
| Worker 3 (Design) | 18797 | 18815 | 18816 | |
| Worker 4 (Naming) | 18798 | 18817 | 18818 | |

**严禁使用：18790-18794（browser/server 自动占用）、18801-18810（Master gRPC 及保留）**

---

## 飞书配置（必须新格式）

```json
"channels": {
  "feishu": {
    "enabled": true,
    "connectionMode": "websocket",
    "domain": "feishu",
    "defaultAccount": "bot-id",
    "accounts": {
      "bot-id": {
        "enabled": true,
        "appId": "xxx",
        "appSecret": "xxx",
        "dmPolicy": "open"
      }
    }
  }
}
```

**dmPolicy 只能是 "open"，不能是 "pairing" 或 "allowall"**

---

## A2A 通信地址规则

- Worker 连 Master：`http://172.19.0.1:18800`（固定，永不变）
- Master 连 Worker：`http://172.19.0.1:18811`（固定，永不变）
- **禁止用容器 IP（172.19.0.2-5）**，容器重启后会变
- **禁止用 localhost**，容器内 localhost 是容器自己

---

## Agent Card URL 必须正确

每个实例的 agentCard.url 必须和实际 A2A 监听端口一致：

```json
"agentCard": {
  "url": "http://172.19.0.1:18811/a2a/jsonrpc"  ← 必须和 server.port 一致
},
"server": {
  "host": "0.0.0.0",
  "port": 18811  ← 这个端口
}
```

**这是最常见的错误，声明端口和实际端口不一致会导致双向调用失败**

---

## Master peers 必须包含所有 Worker

```json
"peers": [
  {"name": "技术员", "agentCardUrl": "http://172.19.0.1:18811/.well-known/agent-card.json", "auth": {...}},
  {"name": "运营官", "agentCardUrl": "http://172.19.0.1:18813/.well-known/agent-card.json", "auth": {...}},
  {"name": "设计师", "agentCardUrl": "http://172.19.0.1:18815/.well-known/agent-card.json", "auth": {...}},
  {"name": "南南",   "agentCardUrl": "http://172.19.0.1:18817/.well-known/agent-card.json", "auth": {...}}
]
```

**peers 为空 = Master 不知道任何 Worker = A2A 无法调度**

---

## Worker peers 必须包含 Master + 所有其他 Worker

每个 Worker 都要能主动调用其他所有人：

```json
"peers": [
  {"name": "SEO-Master", "agentCardUrl": "http://172.19.0.1:18800/.well-known/agent-card.json"},
  {"name": "运营官",     "agentCardUrl": "http://172.19.0.1:18813/.well-known/agent-card.json"},
  {"name": "设计师",     "agentCardUrl": "http://172.19.0.1:18815/.well-known/agent-card.json"},
  {"name": "南南",       "agentCardUrl": "http://172.19.0.1:18817/.well-known/agent-card.json"}
]
```

---

## Master 必须 PM2 守护

```bash
pm2 start /root/.openclaw/master/start.sh \
  --name "master-nanchaoyi" --interpreter bash
pm2 save
pm2 startup
```

**禁止用 nohup，禁止用 systemd gateway install（重启就挂）**

---

## Worker 用 docker run（禁止 docker-compose）

docker-compose 1.29 有 ContainerConfig bug：

```bash
docker run -d \
  --name openclaw-tech \
  --network openclaw-redis-shared \
  -p 18795:18789 \
  -p 18811:18811 \
  -v /root/.openclaw/tech/openclaw.json:/root/.openclaw/openclaw.json:ro \
  -v /root/.openclaw/workspace:/root/.openclaw/workspace:ro \
  -v /root/.openclaw/tech/data:/root/.openclaw/agents \
  -e OPENCLAW_CONFIG_PATH=/root/.openclaw/openclaw.json \
  --restart unless-stopped \
  --memory 2g \
  IMAGE:latest
```

**每个 Worker 的 A2A 端口必须同时在容器内监听和宿主机映射**

---

## a2a-gateway 插件只装一处

```bash
# 正确位置
~/.openclaw/workspace/plugins/a2a-gateway/

# 如果 extensions 里也有，必须删掉
rm -rf ~/.openclaw/extensions/a2a-gateway
```

**两处同时存在会导致 duplicate plugin 警告和行为异常**

---

## 备用模型配置

```json
"models": {
  "providers": {
    "aliyun": {
      "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
      "apiKey": "主Key",
      "models": [{"id": "qwen3.5-plus", ...}]
    },
    "volc": {
      "baseUrl": "https://ark.cn-beijing.volces.com/api/coding/v3",
      "apiKey": "备用Key",
      "models": [{"id": "doubao-seed-2.0-code", ...}]
    }
  }
},
"agents": {
  "defaults": {
    "model": {
      "primary": "aliyun/qwen3.5-plus",
      "fallbacks": ["volc/doubao-seed-2.0-code"]
    }
  }
}
```

---

## 飞书配对命令

```bash
# 只传2个参数，不要加名字
docker exec openclaw-xxx openclaw pairing approve feishu <配对码>
```

---

## 安装完必须验证（全部通过才算完成）

```bash
# 1. Master A2A
curl http://127.0.0.1:18800/.well-known/agent-card.json | python3 -m json.tool | grep '"url"'
# 应该是 172.19.0.1:18800

# 2. 每个 Worker A2A
for port in 18811 18813 18815 18817; do
  echo -n "端口 $port: "
  curl -s http://127.0.0.1:$port/.well-known/agent-card.json | python3 -m json.tool | grep '"url"' | head -1
done
# 每个都应该和端口号一致

# 3. 容器状态
docker ps --filter "name=openclaw-" --format "table {{.Names}}\t{{.Status}}"
# 全部 Up

# 4. Redis
redis-cli -p 16379 ping
# PONG

# 5. 健康监控
crontab -l | grep health-monitor
# 应该有 cron 记录

# 6. 等2分钟确认无熔断
pm2 logs master-nanchaoyi --lines 20 --nostream | grep circuit
# 不应出现 circuit.open
```

---

## 常用命令

```bash
# 一键复位
bash /root/claw-fix.sh

# 查看健康监控
tail -f /root/.openclaw/logs/health-monitor.log

# 查看 Master 日志
pm2 logs master-nanchaoyi

# 查看 Worker 日志
docker logs openclaw-xxx -f --tail 50

# 重启全部
pm2 restart master-nanchaoyi
docker restart openclaw-tech openclaw-ops openclaw-image openclaw-naming
```
