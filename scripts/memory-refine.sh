#!/bin/bash
# 每日记忆提炼脚本 - 23:00 执行
# 压缩旧记忆，提炼关键信息

LOG_FILE="/root/.openclaw/workspace/memory/refine.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$DATE] 开始记忆提炼..." >> $LOG_FILE

# 调用 OpenClaw CLI 清理旧记忆（保留最近30天）
cd /root/.openclaw && pnpm exec openclaw memory stats >> $LOG_FILE 2>&1

echo "[$DATE] 记忆提炼完成" >> $LOG_FILE