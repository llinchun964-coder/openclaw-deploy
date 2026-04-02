#!/bin/bash
DATE=$(date +%Y-%m-%d)

node /root/.openclaw/ops/workspace/plugins/a2a-gateway/skill/scripts/a2a-send.mjs \
  --peer-url http://172.19.0.1:18811 \
  --token 13ee86891304d966456def36705ed344 \
  --non-blocking \
  --message "今日数据采集任务（${DATE}）：

任务一：爆款笔记采集
1. 小红书搜索「改名」「取名」「宝宝取名」
2. 采集今日爆款TOP5（点赞+收藏最高）
3. 写入：/root/.openclaw/obsidian-vault/南朝译智库/素材库/爆款日报-${DATE}.md

任务二：高赞评论采集
1. 进入今日爆款TOP5每篇笔记
2. 采集点赞最高的评论TOP10
3. 写入：/root/.openclaw/obsidian-vault/南朝译智库/素材库/评论采集-${DATE}.md
格式：
- 评论内容
- 点赞数
- 所属笔记标题
- 反映的用户痛点/需求

参考模板：/root/.openclaw/obsidian-vault/南朝译智库/素材库/评论采集模板.md
两个任务都完成后A2A告诉Master和南南"
