#!/bin/bash
# 调用 选品专家（数据官）机器人
if [ $# -eq 0 ]; then
  echo "Usage: $0 <message>"
  exit 1
fi

MESSAGE="$*"

node /root/.openclaw/extensions/a2a-gateway/skill/scripts/a2a-send.mjs \
  --peer-url http://127.0.0.1:18901/a2a \
  --token openclaw-token-2026 \
  --agent-id shujuguan \
  --message "$MESSAGE"
