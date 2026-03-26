#!/usr/bin/env python3
"""
小红书内容审批监听器 v2.1

功能：
- 定期检查飞书多维表格
- 发现"审批通过"的记录
- 通过飞书直接发消息通知老板（李林春）
"""

import json
import time
import requests
import urllib3
urllib3.disable_warnings()

# ============== 配置 ==============
APP_ID = "cli_a9269e44a8b9dcef"
APP_SECRET = "M2iO2Z7Oi0qtBdhcdwkebhGIcqY0lIYa"

# 多维表格配置
APP_TOKEN = "MMiQbM1hvarkJEs8EsvcwMGtncb"
TABLE_ID = "tblFbXCurd8hS0S0"
STATUS_FIELD_NAME = "状态"

# 通知配置 - 直接通知老板（李林春）
BOSS_OPEN_ID = "ou_4c1164b4efebd32811acdf2cbb077bf4"

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

def send_feishu_message(token, open_id, message):
    """发送飞书消息给指定用户"""
    url = f"https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json; charset=utf-8"
    }
    
    data = {
        "receive_id": open_id,
        "msg_type": "text",
        "content": json.dumps({"text": message})
    }
    
    try:
        response = requests.post(url, json=data, headers=headers, timeout=10)
        result = response.json()
        if result.get("code") == 0:
            return True, result
        else:
            return False, result
    except Exception as e:
        return False, str(e)

# ============== 主逻辑 ==============
def main():
    print("🚀 小红书审批监听器 v2.1 启动...")
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
                    
                    # 截取正文前 150 字
                    content_preview = content[:150] + "..." if len(content) > 150 else content
                    
                    # 构建通知消息
                    message = f"""📢 小红书内容审批通过！

📌 标题：{title}

📝 内容预览：
{content_preview}

---
请及时安排发布！"""
                    
                    print(f"📝 发现审批通过：{title}")
                    
                    # 发送飞书消息通知老板
                    success, result = send_feishu_message(token, BOSS_OPEN_ID, message)
                    if success:
                        print(f"✅ 已通知老板（李林春）：{title}")
                        processed_records.add(record_id)
                    else:
                        print(f"❌ 通知失败: {result}")
            
            # 定期清理已处理的记录，防止内存溢出
            if len(processed_records) > 1000:
                processed_records = set()
                
        except Exception as e:
            print(f"❌ 错误：{e}")
        
        # 等待下一次检查
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()