#!/usr/bin/env python3
"""
小红书内容审批监听器

功能：
- 定期检查飞书多维表格
- 发现"审批通过"的记录
- 通过 A2A Gateway 通知小红书运营官

使用：
- 直接运行：python3 xhs-approval-listener.py
- 后台运行：nohup python3 xhs-approval-listener.py &
"""

import json
import time
import requests
import urllib3
urllib3.disable_warnings()

# ============== 配置 ==============
# 飞书配置
APP_ID = "cli_a9269e44a8b9dcef"
APP_SECRET = "M2iO2Z7Oi0qtBdhcdwkebhGIcqY0lIYa"

# 多维表格配置
APP_TOKEN = "MMiQbM1hvarkJEs8EsvcwMGtncb"
TABLE_ID = "tblFbXCurd8hS0S0"
STATUS_FIELD_NAME = "状态"

# A2A 配置
A2A_HOST = "localhost"
A2A_PORT = 18800
A2A_TOKEN = "58904d79ac233c6d5ec55076065e528a5ef6d2a27fc17b8c"  # 小红书运营官的 token
TARGET_PEER = "xiaohongshu-yunying"

# 检查间隔（秒）
CHECK_INTERVAL = 30

# ============== 飞书 API ==============
def get_tenant_access_token():
    """获取 tenant_access_token"""
    url = "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal"
    data = {"app_id": APP_ID, "app_secret": APP_SECRET}
    response = requests.post(url, json=data, verify=False)
    result = response.json()
    return result.get("tenant_access_token", "")

def get_bitable_records(token):
    """获取多维表格所有记录"""
    url = f"https://open.feishu.cn/open-apis/bitable/v1/apps/{APP_TOKEN}/tables/{TABLE_ID}/records"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(url, headers=headers, verify=False)
    result = response.json()
    return result.get("data", {}).get("records", [])

# ============== A2A 通知 ==============
def notify_xhs_operator(title, content):
    """通过 A2A 通知小红书运营官"""
    # 构建消息
    message = f"""📢 小红书内容审批通过！

**标题**：{title}

**正文**：
{content}

---
请及时发布到小红书！"""

    # A2A JSON-RPC 请求
    a2a_url = f"http://{A2A_HOST}:{A2A_PORT}/a2a/jsonrpc"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {A2A_TOKEN}"
    }
    
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "message/send",
        "params": {
            "message": {
                "messageId": f"approval-{int(time.time())}",
                "role": "user",
                "parts": [{"type": "text", "text": message}]
            }
        }
    }
    
    try:
        response = requests.post(a2a_url, json=payload, headers=headers, timeout=10)
        if response.status_code == 200:
            print(f"✅ 已通知小红书运营官：{title}")
            return True
        else:
            print(f"❌ 通知失败：{response.text}")
            return False
    except Exception as e:
        print(f"❌ 通知出错：{e}")
        return False

# ============== 主逻辑 ==============
def main():
    print("🚀 小红书审批监听器启动...")
    print(f"📋 多维表格：{APP_TOKEN}")
    print(f"⏱️ 检查间隔：{CHECK_INTERVAL} 秒")
    print("-" * 50)
    
    # 记录已处理过的记录
    processed_records = set()
    
    while True:
        try:
            # 获取 token
            token = get_tenant_access_token()
            if not token:
                print("❌ 获取 token 失败，等待重试...")
                time.sleep(CHECK_INTERVAL)
                continue
            
            # 获取记录
            records = get_bitable_records(token)
            
            for record in records:
                record_id = record.get("id", "")
                fields = record.get("fields", {})
                
                # 获取状态字段
                status = fields.get(STATUS_FIELD_NAME, "")
                
                # 只处理"审批通过"的记录
                if status == "审批通过" and record_id not in processed_records:
                    title = fields.get("内容标题", "无标题")
                    content = fields.get("笔记正文", "无正文")
                    
                    print(f"📝 发现审批通过：{title}")
                    
                    # 通知小红书运营官
                    if notify_xhs_operator(title, content):
                        processed_records.add(record_id)
            
            # 定期清理已处理的记录，防止内存溢出
            if len(processed_records) > 1000:
                processed_records = set()
                
        except Exception as e:
            print(f"❌ 错误：{e}")
        
        # 等待下一次检查
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()