# 南朝译公司 OpenClaw 部署总结
# 最后更新：2026-03-24

## 服务器信息
- IP：198.200.39.21
- 系统：Ubuntu 22.04

## 团队架构
| 角色 | 容器名 | Gateway | A2A | 飞书账号 |
|------|--------|---------|-----|---------|
| 南朝译Master | 宿主机PM2 | 18789 | 18800 | master-nanchaoyi |
| 技术员 | openclaw-tech | 18795 | 18811 | tech-bot |
| 运营官 | openclaw-ops | 18796 | 18802 | xhs-bot |
| 设计师 | openclaw-image | 18797 | 18803 | image-bot |
| 南南 | openclaw-naming | 18798 | 18804 | naming-bot |
| Redis | openclaw-redis-shared | - | 16379 | - |

## 模型配置
- 主模型：火山引擎 doubao-seed-2.0-code
- 备用：阿里云 qwen3.5-plus
- 图片生成：doubao-seedream-5-0-260128（2K尺寸）
- 图片API Key：c158c7e4-9677-476c-a19d-46e213b712dd

## API Keys
- 阿里云：sk-sp-e6083128df284ca3b4fdbe6d987d576c
- 火山引擎：8c22373b-404a-4f89-8ac0-50992681d1f3

## 常用命令
```bash
# 一键复位
bash /root/claw-fix.sh

# 查看状态
pm2 list
docker ps --filter "name=openclaw-"

# 查看健康监控日志
tail -f /root/.openclaw/logs/health-monitor.log

# 重启所有
pm2 restart master-nanchaoyi
docker restart openclaw-tech openclaw-ops openclaw-image openclaw-naming
```

## 已知问题和解决方案
1. A2A超时 → 通常是模型推理慢，不是通信问题
2. 容器重启后python3消失 → 健康监控会自动重装
3. workspace只读 → docker run 不要加 :ro
4. agents.list必须配置 → 否则身份混乱
5. routing.defaultAgentId → 必须和agents.list id一致

## GitHub仓库
https://github.com/llinchun964-coder/openclaw-deploy

## 新会话告诉Claude的话
"请阅读 /root/.claude/SESSION-SUMMARY.md 和 CLAUDE.md，
了解我们的系统架构后再开始工作"
