# OpenClaw 多实例部署指南 for Claude Code

## 架构说明

本项目部署 1个 Master + N个 Worker 的 OpenClaw 多智能体架构：
- **Master**：跑在宿主机，用 PM2 守护，负责飞书主账号和 A2A 协调
- **Worker**：每个跑在独立 Docker 容器，各自连接飞书独立账号
- **通信**：通过 A2A 协议（a2a-gateway 插件）互联
- **模型**：阿里云 qwen3.5-plus（baseUrl: https://coding.dashscope.aliyuncs.com/v1）

---

## 关键端口规划（必须严格遵守）

| 实例 | Gateway端口 | A2A端口 | 说明 |
|------|------------|---------|------|
| Master | 18789 | 18800 | 宿主机直接运行 |
| Worker 1 | 容器内18789→宿主机**18794** | 18801 | |
| Worker 2 | 容器内18789→宿主机**18795** | 18802 | |
| Worker 3 | 容器内18789→宿主机**18796** | 18803 | |
| Worker 4 | 容器内18789→宿主机**18797** | 18804 | |
| Worker 5 | 容器内18789→宿主机**18798** | 18805 | |
| Worker 6 | 容器内18789→宿主机**18799** | 18806 | |

⚠️ **严禁使用 18790、18791、18792、18793**
原因：Master 的 browser/server 服务会自动占用 gateway端口+2（即18791），
Docker Worker 如果映射这些端口会启动失败。
从 18794 开始是安全的。

---

## 飞书配置格式（必须用新格式）

❌ 错误（旧格式，会导致 blocked unauthorized sender）：
```json
"channels": {
  "feishu": {
    "appId": "xxx",
    "appSecret": "xxx",
    "dmPolicy": "pairing"
  }
}
```

✅ 正确（新格式）：
```json
"channels": {
  "feishu": {
    "enabled": true,
    "connectionMode": "websocket",
    "domain": "feishu",
    "defaultAccount": "bot-name",
    "accounts": {
      "bot-name": {
        "enabled": true,
        "appId": "xxx",
        "appSecret": "xxx",
        "dmPolicy": "open"
      }
    }
  }
}
```

⚠️ **dmPolicy 必须是 "open"，不是 "pairing"，不是 "allowall"**

---

## Master 必须用 PM2 守护

❌ 错误：
```bash
nohup openclaw gateway &
# 或者
./start.sh &
```

✅ 正确：
```bash
pm2 start /root/.openclaw/master/start.sh \
  --name "master" \
  --interpreter bash
pm2 save
pm2 startup
```

---

## Worker 容器必须用 docker run（不用 docker-compose）

系统上的 docker-compose 版本是 1.29，与新版 Docker 引擎有 ContainerConfig bug，
重建容器时会报错。必须用 docker run：

✅ 正确：
```bash
docker run -d \
  --name openclaw-worker \
  --network openclaw-redis-shared \
  -p 18794:18789 \
  -p 18801:18801 \
  -v /root/.openclaw/worker/openclaw.json:/root/.openclaw/openclaw.json:ro \
  -v /root/.openclaw/workspace:/root/.openclaw/workspace:ro \
  -v /root/.openclaw/worker/data:/root/.openclaw/agents \
  -e OPENCLAW_CONFIG_PATH=/root/.openclaw/openclaw.json \
  --restart unless-stopped \
  --memory 2g \
  openclaw-docker_xxx:latest
```

---

## a2a-gateway 插件注意事项

1. 只能有一个 a2a-gateway，不能在 extensions 和 workspace/plugins 同时存在
2. 检查：`ls ~/.openclaw/extensions/` 如果有 a2a-gateway 则删除
3. 保留：`~/.openclaw/workspace/plugins/a2a-gateway`

```bash
# 检查并修复重复插件
if [ -d ~/.openclaw/extensions/a2a-gateway ]; then
  rm -rf ~/.openclaw/extensions/a2a-gateway
fi
```

---

## Worker 的 A2A peers 地址

Worker 在 Docker 容器内，连接宿主机 Master 要用 Docker 网关 IP：
- 标准地址：`http://172.19.0.1:18800/.well-known/agent-card.json`
- 不能用 `127.0.0.1`（容器内的 127.0.0.1 是容器自己）
- 不能用 `localhost`

---

## Redis 共享容器

```bash
# 先建网络，再建容器
docker network create openclaw-redis-shared
docker run -d \
  --name openclaw-redis-shared \
  --network openclaw-redis-shared \
  -p 16379:6379 \
  --restart unless-stopped \
  redis:alpine \
  redis-server --appendonly yes
```

所有 Worker 容器都加 `--network openclaw-redis-shared`。

---

## 安装顺序

1. 安装 Node.js 22（不是 20，不是 18）
2. 安装 PM2 和 OpenClaw
3. 安装 Docker
4. 启动 Redis
5. 配置并用 PM2 启动 Master
6. 克隆并安装 a2a-gateway 插件
7. 用 docker run 启动所有 Worker 容器
8. 注册 openclaw-startup.service（保证重启后 Worker 等 Master 就绪）

---

## 验证步骤

每次安装完必须验证：

```bash
# 1. Master 运行中
pm2 list | grep master

# 2. Master A2A 可访问
curl http://127.0.0.1:18800/.well-known/agent-card.json

# 3. 所有 Worker 容器 Up
docker ps | grep openclaw

# 4. Worker 没有熔断（等2分钟后检查）
docker logs openclaw-xxx 2>&1 | grep -E "circuit|peer"
# 不应该出现 circuit.open

# 5. Redis 运行
redis-cli -p 16379 ping
```

---

## 飞书配对

Worker 容器启动后，用户在飞书发消息，然后：
```bash
# 获取配对码后执行（只传2个参数）
docker exec openclaw-xxx openclaw pairing approve feishu <配对码>
```

注意：`pairing approve` 只接受2个参数（channel + code），不要加名字。

---

## 常见错误快速查表

| 错误信息 | 原因 | 解决 |
|---------|------|------|
| `blocked unauthorized sender (dmPolicy=open)` | 飞书账号未配对 | 执行 pairing approve |
| `blocked unauthorized sender (dmPolicy=allowall)` | dmPolicy 值错误 | 改为 `"open"` |
| `peer.circuit.open` | Worker 连不上 Master A2A | 检查 18800 是否监听 |
| `address already in use 18791` | 端口冲突 | Worker 改用 18794+ |
| `ContainerConfig KeyError` | docker-compose 1.29 bug | 改用 docker run |
| `duplicate plugin id` | extensions 里有重复插件 | 删除 extensions/a2a-gateway |
