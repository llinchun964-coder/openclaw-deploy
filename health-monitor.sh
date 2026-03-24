#!/bin/bash
LOG=/root/.openclaw/logs/health-monitor.log
ts() { date '+%Y-%m-%d %H:%M:%S'; }

# 检查 Master
if ! pm2 list | grep -q "master.*online"; then
  echo "[$(ts)] WARN: Master 不在线，重启..." >> $LOG
  pm2 restart master-nanchaoyi >> $LOG 2>&1
else
  echo "[$(ts)] OK: Master 在线" >> $LOG
fi

# 检查 Master A2A（比检查进程更准确）
if ! curl -s --max-time 5 http://127.0.0.1:18800/.well-known/agent-card.json > /dev/null 2>&1; then
  echo "[$(ts)] WARN: Master A2A 18800 无响应，重启..." >> $LOG
  pm2 restart master-nanchaoyi >> $LOG 2>&1
fi

# 检查每个 Worker（同时检查容器状态 + A2A 端口）
declare -A WORKER_PORTS=(
  ["openclaw-tech"]="18811"
  ["openclaw-ops"]="18802"
  ["openclaw-image"]="18803"
  ["openclaw-naming"]="18804"
)

for container in "${!WORKER_PORTS[@]}"; do
  port=${WORKER_PORTS[$container]}
  
  # 先检查容器是否运行
  STATUS=$(docker inspect --format='{{.State.Status}}' $container 2>/dev/null)
  if [ "$STATUS" != "running" ]; then
    echo "[$(ts)] WARN: $container 容器状态=$STATUS，重启..." >> $LOG
    docker start $container >> $LOG 2>&1
    sleep 10
  fi
  
  # 再检查 A2A 端口是否响应
  if ! curl -s --max-time 5 http://127.0.0.1:${port}/.well-known/agent-card.json > /dev/null 2>&1; then
    echo "[$(ts)] WARN: $container A2A:${port} 无响应，重启容器..." >> $LOG
    docker restart $container >> $LOG 2>&1
  else
    echo "[$(ts)] OK: $container A2A:${port} 正常" >> $LOG
  fi
done

# 确保所有容器有 python3
for container in openclaw-tech openclaw-ops openclaw-image openclaw-naming; do
  if ! docker exec $container which python3 > /dev/null 2>&1; then
    echo "[$(ts)] INFO: $container 缺少 python3，安装中..." >> $LOG
    docker exec $container sh -c "apt-get update -qq && apt-get install -y python3 -qq 2>/dev/null || apk add --no-cache python3 2>/dev/null" >> $LOG 2>&1
  fi
done

# 检查 Redis
if ! redis-cli -p 16379 ping | grep -q PONG; then
  echo "[$(ts)] WARN: Redis 无响应，重启..." >> $LOG
  docker restart openclaw-redis-shared >> $LOG 2>&1
else
  echo "[$(ts)] OK: Redis 正常" >> $LOG
fi

# 日志轮转
LINE_COUNT=$(wc -l < $LOG 2>/dev/null || echo 0)
[ "$LINE_COUNT" -gt 500 ] && tail -200 $LOG > ${LOG}.tmp && mv ${LOG}.tmp $LOG
