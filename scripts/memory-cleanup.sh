#!/bin/bash
# 每月记忆清理脚本 - 月末 23:30 执行
# 清理过期记忆（保留90天）

LOG_FILE="/root/.openclaw/workspace/memory/cleanup.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$DATE] 开始记忆清理..." >> $LOG_FILE

# 清理 90 天前的记忆
cd /root/.openclaw && pnpm exec openclaw memory delete --older-than 90d >> $LOG_FILE 2>&1

echo "[$DATE] 记忆清理完成" >> $LOG_FILE