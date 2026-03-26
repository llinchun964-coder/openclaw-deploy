#!/bin/bash
# 调用 千川操盘手（投手）机器人
if [ $# -eq 0 ]; then
  echo "Usage: $0 <message>"
  exit 1
fi

MESSAGE="$*"

node /root/.openclaw/extensions/a2a-gateway/skill/scripts/a2a-send.mjs \
  --peer-url http://127.0.0.1:18903/a2a \
  --token openclaw-token-2026 \
  --agent-id toushou \
  --message "$MESSAGE"
