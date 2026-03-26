#!/bin/bash
# 每周记忆检查脚本 - 周日 20:00 执行
# 检查记忆完整性，输出报告

LOG_FILE="/root/.openclaw/workspace/memory/check.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$DATE] 开始记忆检查..." >> $LOG_FILE

# 检查数据库状态
cd /root/.openclaw && pnpm exec openclaw memory stats >> $LOG_FILE 2>&1

echo "[$DATE] 记忆检查完成" >> $LOG_FILE