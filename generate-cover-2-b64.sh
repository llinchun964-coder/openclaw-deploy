#!/bin/bash

# 第2张：古风 - b64_json
curl -X POST "https://ark.cn-beijing.volces.com/api/v3/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer c158c7e4-9677-476c-a19d-46e213b712dd" \
  -d '{
    "model": "doubao-seedream-5-0-260128",
    "prompt": "小红书封面图，中国古风风格，朱红色配金色文字，大字标题：名字，真的影响运气吗？，副标题：传统文化解读，水墨山水背景，有印章样式：南朝译印，3:4比例，高清晰度",
    "response_format": "b64_json",
    "size": "2K",
    "stream": false,
    "watermark": true
  }' 2>&1
