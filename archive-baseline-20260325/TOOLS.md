# Tools & A2A Configuration
## A2A Agents（实际配置，2026-03-23 更新）

| 角色 | 名称 | A2A 地址 | 飞书账号 |
|------|------|---------|---------|
| Master/CEO | SEO-Master | http://172.19.0.1:18800 | 南朝译 |
| CTO | CTO-Worker | http://172.19.0.1:18811 | 技术员 |
| 运营 | Ops-Worker | http://172.19.0.1:18802 | 运营官 |
| 设计 | Design-Worker | http://172.19.0.1:18803 | 设计师 |
| 顾问 | Naming-Worker | http://172.19.0.1:18804 | 南南 |

## 重要说明
- 所有 Agent 通过 172.19.0.1（Docker 网桥）互访
- 不要用容器 IP（172.19.0.2-5），容器重启后 IP 会变
- 不要用 localhost（容器内 localhost 是容器自己）

## A2A Token
- 统一 Token：查看各自 openclaw.json 的 security.token

## Redis 共享记忆池
- 地址：127.0.0.1:16379（宿主机）或 172.19.0.1:16379（容器内）

## 图片生成 API（设计师专用）

### 火山引擎豆包图片生成
- 模型：doubao-seedream-5.0-260128
- API Key：c158c7e4-9677-476c-a19d-46e213b712dd
- BaseURL：https://ark.cn-beijing.volces.com/api/v3

### 调用示例
```bash
curl -X POST "https://ark.cn-beijing.volces.com/api/v3/images/generations" \
  -H "Authorization: Bearer c158c7e4-9677-476c-a19d-46e213b712dd" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "doubao-seedream-5.0-260128",
    "prompt": "图片描述",
    "size": "1024x1024",
    "n": 1
  }'
```

### 返回结果
返回 JSON 里的 `data[0].url` 就是图片链接

### 正确调用参数（已验证）
```bash
curl -X POST "https://ark.cn-beijing.volces.com/api/v3/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer c158c7e4-9677-476c-a19d-46e213b712dd" \
  -d '{
    "model": "doubao-seedream-5-0-260128",
    "prompt": "图片描述",
    "response_format": "url",
    "size": "2K",
    "stream": false,
    "watermark": true
  }'
```
- size 必须用 "2K"，不能用 "1024x1024"
- 返回的 data[0].url 是图片下载链接，有效期24小时
