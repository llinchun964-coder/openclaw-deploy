#!/bin/bash
# 跨容器共享同步脚本
# 将共享记忆同步到各个容器

SHARED_DIR="/root/.openclaw/shared-memory"

# 复制到各个容器的工作空间
for container in cto designer xhs healer; do
    target_dir="/workspace/shared-memory"
    docker cp $SHARED_DIR openclaw-$container:$target_dir 2>/dev/null
    echo "✅ 已同步到 openclaw-$container"
done

echo "✅ 全量同步完成"