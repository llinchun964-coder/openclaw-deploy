#!/bin/bash
# content-validator.sh - 数据校验脚本
# CEO-ORDER-001 第三条：数据校验强制要求
# 用途：检查写入内容是否有效，自动拦截空白汇报

set -e

# 配置
MIN_SIZE_BYTES=1024  # 1KB 最小阈值
LOG_FILE="/root/.openclaw/workspace/memory/content-validator-log.txt"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S UTC")

# 颜色输出（用于日志）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "[$TIMESTAMP] $*" >> "$LOG_FILE"
    echo "$*"
}

usage() {
    echo "用法：$0 <文件路径> [任务名称]"
    echo ""
    echo "参数:"
    echo "  文件路径    要检查的文件或文档路径"
    echo "  任务名称    可选，任务标识（用于日志）"
    echo ""
    echo "退出码:"
    echo "  0 - 验证通过（文件大小 >= 1KB）"
    echo "  1 - 验证失败（文件不存在或太小）"
    echo "  2 - 参数错误"
    exit 2
}

# 参数检查
if [ $# -lt 1 ]; then
    usage
fi

FILE_PATH="$1"
TASK_NAME="${2:-unknown-task}"

log "🔍 开始验证：$FILE_PATH (任务：$TASK_NAME)"

# 检查文件是否存在
if [ ! -f "$FILE_PATH" ]; then
    log -e "${RED}❌ 验证失败：文件不存在 - $FILE_PATH${NC}"
    echo "VALIDATION_FAILED:FILE_NOT_FOUND"
    exit 1
fi

# 获取文件大小（字节）
FILE_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null || stat -f%z "$FILE_PATH" 2>/dev/null || echo "0")

log "📊 文件大小：$FILE_SIZE 字节（阈值：$MIN_SIZE_BYTES 字节）"

# 验证大小
if [ "$FILE_SIZE" -lt "$MIN_SIZE_BYTES" ]; then
    log -e "${RED}❌ 验证失败：文件太小 ($FILE_SIZE < $MIN_SIZE_BYTES 字节)${NC}"
    log "🚨 拦截汇报，触发自动重启..."
    
    # 记录失败详情
    cat >> "$LOG_FILE" << EOF

--- 验证失败详情 ---
时间：$TIMESTAMP
任务：$TASK_NAME
文件：$FILE_PATH
大小：$FILE_SIZE 字节
阈值：$MIN_SIZE_BYTES 字节
状态：拦截汇报，自动重启
----------------------

EOF
    
    echo "VALIDATION_FAILED:FILE_TOO_SMALL"
    exit 1
fi

# 验证通过
log -e "${GREEN}✅ 验证通过：文件大小正常 ($FILE_SIZE >= $MIN_SIZE_BYTES 字节)${NC}"

# 提取前 5 行作为摘要（用于汇报）
SUMMARY=$(head -n 5 "$FILE_PATH" 2>/dev/null | tr '\n' ' | ' | head -c 200)
log "📝 内容摘要：$SUMMARY"

# 输出成功信号
cat << EOF
VALIDATION_PASSED
FILE_SIZE:$FILE_SIZE
SUMMARY:$SUMMARY
EOF

exit 0
