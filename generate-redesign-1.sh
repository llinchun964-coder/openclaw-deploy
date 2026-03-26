#!/bin/bash

# 重做封面图 - 方向1：大字海报风格（基于参考图）
curl -s -X POST "https://ark.cn-beijing.volces.com/api/v3/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer c158c7e4-9677-476c-a19d-46e213b712dd" \
  -d '{
    "model": "doubao-seedream-5-0-260128",
    "prompt": "Based on reference image style, Xiaohongshu (Little Red Book) cover image, 3:4 vertical ratio, 1080x1440, high quality, professional social media design. Deep navy blue background with gold text, bold eye-catching Chinese title at top: \"成年人改名5大误区\", subtitle below: \"别再踩坑了！\", clear visual subject: cartoon-style Nan Chaoyi teacher avatar, brand color #FF2442 as accent, clean modern design, clear information hierarchy, easy to read on mobile from 3 meters away, no pure white background + pure text template, must have clear visual subject, professional typography, high contrast, no AI artifacts, no watermark.",
    "response_format": "b64_json",
    "size": "2K",
    "stream": false,
    "watermark": true
  }' > /root/.openclaw/workspace/xiaohongshu_images/new/redesign-1.json 2>&1
