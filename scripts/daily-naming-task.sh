#!/bin/bash
DATE=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

node /root/.openclaw/naming/workspace/plugins/a2a-gateway/skill/scripts/a2a-send.mjs \
  --peer-url http://172.19.0.1:18804 \
  --token 13ee86891304d966456def36705ed344 \
  --non-blocking \
  --message "今日南南任务（${DATE}）：

任务一：分析昨日评论数据
1. 读取：/root/.openclaw/obsidian-vault/南朝译智库/素材库/评论采集-${YESTERDAY}.md
2. 提炼用户核心痛点和卖点
3. 更新：/root/.openclaw/obsidian-vault/南朝译智库/04_话术库/用户痛点分析.md

任务二：案例脱敏整理（如有新案例）
1. 检查Master是否派发了新的真实案例
2. 脱敏处理（改姓名、改地区、改具体细节）
3. 整理成标准格式写入案例库：
   /root/.openclaw/obsidian-vault/南朝译智库/03_案例库/

任务三：优化话术库
1. 根据今日痛点分析
2. 更新：/root/.openclaw/obsidian-vault/南朝译智库/04_话术库/转化话术.md
3. 更新：/root/.openclaw/obsidian-vault/南朝译智库/04_话术库/异议处理.md

全部完成后A2A告诉Master，附上更新了哪些文件"
