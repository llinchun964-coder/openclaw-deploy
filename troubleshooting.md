# OpenClaw 故障排查手册

## 快速诊断命令

```bash
# 一键查看全部状态
pm2 list
docker ps
ss -tlnp | grep -E "18789|18800|187[0-9][0-9]"
redis-cli -p 16379 ping
```

---

## 故障1：飞书发消息没有回复

### 排查步骤

```bash
# 看 Worker 日志
docker logs openclaw-xxx --since 2m 2>&1 | grep -v plugins
```

**情况A：** 看到 `blocked unauthorized sender (dmPolicy=open)`
→ 飞书账号未配对，执行：
```bash
docker exec openclaw-xxx openclaw pairing approve feishu <配对码>
```

**情况B：** 看到 `peer.circuit.open`
→ Worker 连不上 Master，检查 Master 是否运行：
```bash
pm2 list
curl http://127.0.0.1:18800/.well-known/agent-card.json
```

**情况C：** 看到 `received message` 但没有后续
→ 模型调用失败，检查阿里云 API Key：
```bash
curl https://coding.dashscope.aliyuncs.com/v1/models \
  -H "Authorization: Bearer sk-sp-xxx"
```

**情况D：** 没有任何 `received message` 日志
→ 飞书 WebSocket 断了，重启容器：
```bash
docker restart openclaw-xxx
```

---

## 故障2：容器状态是 Created 或 Exited

```bash
# 看具体报错
docker logs openclaw-xxx 2>&1 | tail -20
```

**端口冲突** `address already in use`：
```bash
# 看哪个进程占了端口
ss -tlnp | grep <端口号>
# 如果是 openclaw-gateway 占了 18791/18792，说明 Worker 端口规划错误
# 把 Worker 映射端口改为 18794+
```

**网络不存在** `network openclaw-redis-shared not found`：
```bash
docker network create openclaw-redis-shared
docker start openclaw-xxx
```

---

## 故障3：Master 没有运行

**症状：** `pm2 list` 为空，或者 `ss -tlnp | grep 18800` 无结果

```bash
# 手动启动
pm2 start /root/.openclaw/ecosystem.config.js

# 看启动日志
pm2 logs master --lines 30

# 如果报错 Invalid config
cat ~/.openclaw/master/openclaw.json | python3 -m json.tool
# 检查 JSON 格式是否正确
```

---

## 故障4：幽灵进程占用端口

**症状：** 奇怪的进程占用 18789/18791/18792

```bash
# 查看所有 openclaw 进程用的配置
for pid in $(pgrep -f openclaw-gateway); do
  echo "=== PID $pid ==="
  cat /proc/$pid/environ | tr '\0' '\n' | grep OPENCLAW_CONFIG
done

# 杀掉不认识的进程
kill <pid>
```

---

## 故障5：A2A 熔断（peer.circuit.open）

**症状：** Worker 日志出现 `peer.circuit.open: failure threshold reached`

```bash
# 检查 Master A2A
curl http://127.0.0.1:18800/.well-known/agent-card.json

# 如果无响应，重启 Master
pm2 restart master

# 等 Master 就绪后，重启 Worker 让熔断恢复
sleep 15
docker restart openclaw-tech openclaw-ops openclaw-image openclaw-naming
```

---

## 故障6：重启服务器后全部挂了

```bash
# 检查 PM2 是否自启
systemctl status pm2-root

# 检查 openclaw-startup 是否执行
cat /root/.openclaw/logs/startup.log

# 手动触发
bash /root/openclaw-startup.sh
```

---

## 故障7：docker-compose up 报 ContainerConfig 错误

这是 docker-compose 1.29 的 bug，**不要用 docker-compose**，改用 docker run：

```bash
# 删掉旧容器
docker rm -f openclaw-xxx

# 重新用 docker run 启动（参考 install.sh 里的命令）
docker run -d --name openclaw-xxx ...
```

---

## 日常维护命令

```bash
# 查看所有日志
pm2 logs master --lines 50
docker logs openclaw-xxx --since 1h 2>&1 | tail -50

# 重启单个 Worker
docker restart openclaw-xxx

# 重启 Master
pm2 restart master

# 重启全部
pm2 restart master
docker restart $(docker ps --filter "name=openclaw-" --format "{{.Names}}" | grep -v redis)

# 查看 Redis 状态
redis-cli -p 16379 info memory
redis-cli -p 16379 dbsize

# 更新 OpenClaw
npm update -g openclaw
pm2 restart master
docker restart $(docker ps --filter "name=openclaw-" --format "{{.Names}}" | grep -v redis)
```

---

## 端口速查表

| 端口 | 用途 | 说明 |
|------|------|------|
| 18789 | Master Gateway | 宿主机直接监听 |
| 18790 | ❌禁用 | browser/server 可能占用 |
| 18791 | ❌禁用 | browser/server 自动占用 |
| 18792 | ❌禁用 | browser/server 可能占用 |
| 18793 | ❌禁用 | 安全边界 |
| 18794 | Worker 1 Gateway | docker 映射 |
| 18795 | Worker 2 Gateway | docker 映射 |
| 18796 | Worker 3 Gateway | docker 映射 |
| 18797 | Worker 4 Gateway | docker 映射 |
| 18798 | Worker 5 Gateway | docker 映射 |
| 18799 | Worker 6 Gateway | docker 映射 |
| 18800 | Master A2A | Worker 连接此端口 |
| 18801-18806 | Worker A2A | 每个 Worker 一个 |
| 16379 | Redis | 共享记忆池 |
