#!/bin/bash

# 方向1：深蓝底+金色大字，视觉主体：卡通头像
curl -s -X POST "https://ark.cn-beijing.volces.com/api/v3/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer c158c7e4-9677-476c-a19d-46e213b712dd" \
  -d '{
    "model": "doubao-seedream-5-0-260128",
    "prompt": "Xiaohongshu cover image, 3:4 vertical ratio, 1080x1440, deep navy blue background with bold gold Chinese text at top: \"成年人改名5大误区\", subtitle below: \"别再踩坑了！\", clear visual subject: cartoon-style Nan Chaoyi teacher avatar, brand color #FF2442 as accent, professional social media design, no pure white background + pure text template, must have clear visual subject, professional typography, high contrast, easy to read on mobile, no AI artifacts.",
    "response_format": "b64_json",
    "size": "2K",
    "stream": false,
    "watermark": true
  }' > /root/.openclaw/workspace/xiaohongshu_images/new/variant-1.json 2>&1
