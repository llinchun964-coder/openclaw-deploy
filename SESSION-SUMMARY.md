# 南朝译公司 OpenClaw 部署总结
# 最后更新：2026-03-24

## 服务器
- IP：198.200.39.21，Ubuntu 22.04

## 团队架构
| 角色 | 容器名 | Gateway | A2A | Docker镜像 |
|------|--------|---------|-----|-----------|
| 南朝译Master | 宿主机PM2(master-nanchaoyi) | 18789 | 18800 | - |
| 技术员 | openclaw-tech | 18795 | 18811 | openclaw-docker_cto:latest |
| 运营官 | openclaw-ops | 18796 | 18802 | openclaw-docker_xhs:latest |
| 设计师 | openclaw-image | 18797 | 18803 | openclaw-docker_designer:latest |
| 南南 | openclaw-naming | 18798 | 18804 | openclaw-docker_healer:latest |
| Redis | openclaw-redis-shared | - | 16379 | redis:alpine |

## 关键配置路径
- Master配置：/root/.openclaw/master/openclaw.json
- Worker配置：/root/.openclaw/{tech|ops|image|naming}/openclaw.json
- 共享workspace：/root/.openclaw/workspace/
- 私有workspace：/root/.openclaw/{worker}/private-workspace/
- 健康监控：/root/.openclaw/health-monitor.sh（cron每分钟）
- 一键复位：/root/claw-fix.sh
- PM2配置：/root/.openclaw/ecosystem.config.js

## 模型配置
- 主：火山引擎 doubao-seed-2.0-code
- 备：阿里云 qwen3.5-plus
- 图片生成：doubao-seedream-5-0-260128（size必须用"2K"）
- BaseURL火山：https://ark.cn-beijing.volces.com/api/coding/v3
- BaseURL阿里云：https://coding.dashscope.aliyuncs.com/v1

## A2A通信规则
- Worker连Master：http://172.19.0.1:18800
- Master连Worker：http://172.19.0.1:18811（技术员）等
- 禁止用容器IP（172.19.0.2-5），重启会变
- 禁止用localhost，容器内是容器自己

## 已踩过的坑（新服务器必看）
1. agents.list必须配置，否则身份混乱（用main代替真实角色）
2. routing.defaultAgentId必须和agents.list的id一致
3. workspace挂载不能加:ro，否则写文件报EROFS
4. Agent Card URL端口必须和server.port一致
5. 每个Worker的peers必须包含Master+所有其他Worker
6. 端口18790-18794禁用（browser自动占用）
7. 端口18801-18810禁用（Master gRPC）
8. docker-compose 1.29有bug，用docker run
9. A2A响应慢是模型推理慢，不是通信问题（延迟只有15-20ms）
10. 阿里云API会卡死，已切换火山引擎为主模型
11. 容器重启后python3消失，健康监控会自动补装

## 常用命令
```bash
bash /root/claw-fix.sh              # 一键复位
pm2 list                            # Master状态
pm2 logs master-nanchaoyi           # Master日志
docker ps --filter "name=openclaw-" # Worker状态
docker logs openclaw-xxx -f --tail 20 # Worker日志
tail -f /root/.openclaw/logs/health-monitor.log # 健康监控
redis-cli -p 16379 ping             # Redis状态
```

## 遇到问题排查顺序
1. docker logs openclaw-xxx --since 5m 2>&1 | tail -20
2. pm2 logs master-nanchaoyi --lines 20 --nostream
3. 看错误关键词：task.finished state=failed / EROFS / unknown agent id / circuit.open
4. 运行 bash /root/claw-fix.sh

## GitHub仓库
https://github.com/llinchun964-coder/openclaw-deploy
（私有，包含CLAUDE.md、install.sh、templates/）
