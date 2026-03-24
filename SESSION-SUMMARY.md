# 南朝译公司 OpenClaw 部署总结
# 最后更新：2026-03-24

## 服务器
- IP：198.200.39.21

## 端口规划
- Master: gateway=18789, A2A=18800
- 技术员: gateway=18795, A2A=18811
- 运营官: gateway=18796, A2A=18802
- 设计师: gateway=18797, A2A=18803
- 南南: gateway=18798, A2A=18804
- Redis: 16379

## 模型
- 主：火山引擎 doubao-seed-2.0-code
- 备：阿里云 qwen3.5-plus
- 图片：doubao-seedream-5-0-260128

## 常用命令
bash /root/claw-fix.sh  # 一键复位
pm2 list                # Master状态
docker ps               # Worker状态

## 遇到问题先运行
docker logs openclaw-xxx --since 5m 2>&1 | tail -20
pm2 logs master-nanchaoyi --lines 20 --nostream
