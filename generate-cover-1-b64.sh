#!/bin/bash

# 第1张：职场风 - b64_json
curl -X POST "https://ark.cn-beijing.volces.com/api/v3/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer c158c7e4-9677-476c-a19d-46e213b712dd" \
  -d '{
    "model": "doubao-seedream-5-0-260128",
    "prompt": "小红书封面图，职场风格，简约专业，商务风格，深蓝色背景配金色文字，大字标题：成年人改名，别踩这5个坑！，副标题：南朝译老师亲测，简约几何图形背景，右下角有logo水印，3:4比例，高清晰度",
    "response_format": "b64_json",
    "size": "2K",
    "stream": false,
    "watermark": true
  }' 2>&1
