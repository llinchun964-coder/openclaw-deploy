#!/bin/bash
# 调用南南（业务部）机器人
if [ $# -eq 0 ]; then
  echo "Usage: $0 <message>"
  exit 1
fi

MESSAGE="$*"

node /root/.openclaw/extensions/a2a-gateway/skill/scripts/a2a-send.mjs \
  --peer-url http://127.0.0.1:18804 \
  --token healer-token-20260316 \
  --message "$MESSAGE"
