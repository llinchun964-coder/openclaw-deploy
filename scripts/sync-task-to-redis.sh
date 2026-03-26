#!/bin/bash
# 任务状态同步脚本 - 将任务状态同步到 Redis
# 用法: ./sync-task-to-redis.sh TASK-ID STATUS

TASK_ID=$1
STATUS=$2
REDIS_HOST="172.18.0.1"
REDIS_PORT="16379"

if [ -z "$TASK_ID" ]; then
    echo "用法: $0 TASK-ID STATUS"
    exit 1
fi

# 同步到 Redis
docker exec openclaw-redis-shared redis-cli SET "task:$TASK_ID:status" "$STATUS"
docker exec openclaw-redis-shared redis-cli SET "task:$TASK_ID:updated" "$(date +%s)"

echo "✅ 任务 $TASK_ID 状态已同步: $STATUS"