#!/bin/bash
# 任务状态监听同步脚本
# 监听 shared-memory/tasks/ 目录变化，自动同步到 Redis

WATCH_DIR="/root/.openclaw/shared-memory/tasks"
REDIS_CONTAINER="openclaw-redis-shared"
LAST_CHECK=0

echo "🔄 任务监听脚本已启动..."
echo "监听目录: $WATCH_DIR"

# 初始化：同步现有任务
for task_file in $WATCH_DIR/*.md; do
    if [ -f "$task_file" ]; then
        task_id=$(basename "$task_file" .md)
        echo "初始化同步: $task_id"
        # 从文件提取状态
        status=$(grep -m1 "状态" "$task_file" | grep -oP '\🚀\s*\K[^ ]+' || echo "待开始")
        docker exec $REDIS_CONTAINER redis-cli SET "task:$task_id:status" "$status" 2>/dev/null
    fi
done

# 持续监听（每分钟检查一次）
while true; do
    sleep 60
    for task_file in $WATCH_DIR/*.md; do
        if [ -f "$task_file" ]; then
            task_id=$(basename "$task_file" .md)
            status=$(grep -m1 "状态" "$task_file" | grep -oP '\🚀\s*\K[^ ]+' || echo "待开始")
            docker exec $REDIS_CONTAINER redis-cli SET "task:$task_id:status" "$status" 2>/dev/null
        fi
    done
    echo "✅ $(date '+%H:%M:%S') 任务状态已同步"
done