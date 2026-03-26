const fs = require('fs');

function cleanAndDecode(jsonPath, outputPath) {
  const content = fs.readFileSync(jsonPath, 'utf8');
  const lines = content.split('\n').filter(line => line.trim());
  const lastLine = lines[lines.length - 1];
  
  try {
    const data = JSON.parse(lastLine);
    const b64 = data.data[0].b64_json;
    const buffer = Buffer.from(b64, 'base64');
    fs.writeFileSync(outputPath, buffer);
    console.log(`Saved: ${outputPath}`);
  } catch (e) {
    console.error(`Error decoding ${jsonPath}:`, e.message);
    console.error('Last line:', lastLine.substring(0, 200));
  }
}

cleanAndDecode(
  '/root/.openclaw/workspace/xiaohongshu_images/new/cover-1.json',
  '/root/.openclaw/workspace/xiaohongshu_images/new/cover-1-workplace.png'
);
cleanAndDecode(
  '/root/.openclaw/workspace/xiaohongshu_images/new/cover-2.json',
  '/root/.openclaw/workspace/xiaohongshu_images/new/cover-2-ancient.png'
);
cleanAndDecode(
  '/root/.openclaw/workspace/xiaohongshu_images/new/cover-3.json',
  '/root/.openclaw/workspace/xiaohongshu_images/new/cover-3-tech.png'
);

console.log('Done!');
