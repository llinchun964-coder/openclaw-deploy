# openclaw.json 配置模板

## Master 模板

```json
{
  "$schema": "https://openclaw.ai/schema/config.json",
  "meta": { "lastTouchedVersion": "2026.3.13" },
  "models": {
    "mode": "merge",
    "providers": {
      "aliyun": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "sk-sp-你的阿里云KEY",
        "api": "openai-completions",
        "models": [{
          "id": "qwen3.5-plus",
          "name": "qwen3.5-plus",
          "input": ["text", "image"],
          "contextWindow": 30000
        }]
      }
    }
  },
  "agents": {
    "defaults": { "model": { "primary": "aliyun/qwen3.5-plus" } }
  },
  "tools": { "profile": "full", "sessions": { "visibility": "all" } },
  "commands": { "native": "auto", "nativeSkills": "auto", "restart": true, "ownerDisplay": "raw" },
  "session": { "dmScope": "per-channel-peer" },
  "bindings": [{ "agentId": "main", "match": { "channel": "feishu", "accountId": "master-bot" } }],
  "channels": {
    "feishu": {
      "enabled": true,
      "connectionMode": "websocket",
      "domain": "feishu",
      "defaultAccount": "master-bot",
      "accounts": {
        "master-bot": {
          "enabled": true,
          "appId": "飞书AppID",
          "appSecret": "飞书AppSecret",
          "dmPolicy": "open"
        }
      }
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "controlUi": { "allowedOrigins": ["*"] },
    "auth": { "mode": "token", "token": "随机生成的token" }
  },
  "plugins": {
    "allow": ["a2a-gateway", "feishu"],
    "load": { "paths": ["/root/.openclaw/workspace/plugins/a2a-gateway"] },
    "entries": {
      "feishu": { "enabled": true },
      "a2a-gateway": {
        "enabled": true,
        "config": {
          "agentCard": {
            "name": "Master名字",
            "description": "Master描述",
            "url": "http://服务器公网IP:18789/a2a/jsonrpc",
            "skills": [{ "id": "chat", "name": "chat", "description": "描述" }]
          },
          "server": { "host": "0.0.0.0", "port": 18800 },
          "security": { "inboundAuth": "bearer", "token": "A2A共享token" },
          "routing": { "defaultAgentId": "main" },
          "peers": []
        }
      }
    }
  }
}
```

---

## Worker 模板

> 替换：WORKER_ID（英文）、WORKER_NAME（显示名）、GW_PORT（18794-18799）、A2A_PORT（18801-18806）

```json
{
  "$schema": "https://openclaw.ai/schema/config.json",
  "meta": { "lastTouchedVersion": "2026.3.13" },
  "models": {
    "mode": "merge",
    "providers": {
      "aliyun": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "sk-sp-你的阿里云KEY",
        "api": "openai-completions",
        "models": [{
          "id": "qwen3.5-plus",
          "name": "qwen3.5-plus",
          "input": ["text", "image"],
          "contextWindow": 30000
        }]
      }
    }
  },
  "agents": {
    "defaults": { "model": { "primary": "aliyun/qwen3.5-plus" } },
    "list": [{
      "id": "WORKER_ID",
      "default": true,
      "name": "WORKER_NAME",
      "workspace": "/root/.openclaw/WORKER_ID/workspace"
    }]
  },
  "tools": { "profile": "full", "sessions": { "visibility": "all" } },
  "commands": { "native": "auto", "nativeSkills": "auto", "restart": true, "ownerDisplay": "raw" },
  "session": { "dmScope": "per-channel-peer" },
  "bindings": [{ "agentId": "WORKER_ID", "match": { "channel": "feishu", "accountId": "WORKER_ID-bot" } }],
  "channels": {
    "feishu": {
      "enabled": true,
      "connectionMode": "websocket",
      "domain": "feishu",
      "defaultAccount": "WORKER_ID-bot",
      "accounts": {
        "WORKER_ID-bot": {
          "enabled": true,
          "appId": "飞书AppID",
          "appSecret": "飞书AppSecret",
          "dmPolicy": "open"
        }
      }
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "controlUi": { "allowedOrigins": ["*"] },
    "auth": { "mode": "token", "token": "随机token" }
  },
  "plugins": {
    "allow": ["a2a-gateway", "feishu"],
    "load": { "paths": ["/root/.openclaw/workspace/plugins/a2a-gateway"] },
    "entries": {
      "feishu": { "enabled": true },
      "a2a-gateway": {
        "enabled": true,
        "config": {
          "agentCard": {
            "name": "WORKER_NAME",
            "description": "WORKER_NAME",
            "url": "http://172.19.0.1:GW_PORT/a2a/jsonrpc",
            "skills": [{ "id": "chat", "name": "chat", "description": "WORKER_NAME" }]
          },
          "server": { "host": "0.0.0.0", "port": A2A_PORT },
          "security": { "inboundAuth": "bearer", "token": "A2A共享token（与Master一致）" },
          "routing": { "defaultAgentId": "WORKER_ID" },
          "peers": [{
            "name": "Master名字",
            "agentCardUrl": "http://172.19.0.1:18800/.well-known/agent-card.json",
            "auth": { "type": "bearer", "token": "A2A共享token（与Master一致）" }
          }]
        }
      }
    }
  }
}
```

---

## 端口填写参考

| Worker序号 | GW_PORT | A2A_PORT |
|-----------|---------|---------|
| 1 | 18794 | 18801 |
| 2 | 18795 | 18802 |
| 3 | 18796 | 18803 |
| 4 | 18797 | 18804 |
| 5 | 18798 | 18805 |
| 6 | 18799 | 18806 |
