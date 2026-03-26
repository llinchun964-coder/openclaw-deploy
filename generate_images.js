
const { createCanvas, loadImage } = require('canvas');
const fs = require('fs');
const path = require('path');

// 确保输出目录存在
const outputDir = path.join(__dirname, 'xiaohongshu_images');
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// 通用文本绘制函数
function drawText(ctx, text, x, y, options = {}) {
  const {
    fontSize = 40,
    fontFamily = 'Arial',
    fontWeight = 'bold',
    color = '#ffffff',
    textAlign = 'center',
    lineHeight = 1.2
  } = options;

  ctx.font = `${fontWeight} ${fontSize}px ${fontFamily}`;
  ctx.fillStyle = color;
  ctx.textAlign = textAlign;
  
  // 处理多行文本
  const lines = text.split('\n');
  lines.forEach((line, index) => {
    ctx.fillText(line, x, y + index * fontSize * lineHeight);
  });
}

// Day1: 35岁想改名，来得及吗？
async function generateDay1Images() {
  console.log('生成Day1图片...');

  // 1. 封面图：35岁改名晚吗？
  const cover1 = createCanvas(1080, 1920);
  const ctx1 = cover1.getContext('2d');
  
  // 深蓝色背景
  ctx1.fillStyle = '#1a1a2e';
  ctx1.fillRect(0, 0, 1080, 1920);
  
  // 主标题
  drawText(ctx1, '35岁改名晚吗？', 540, 800, {
    fontSize: 80,
    color: '#ffffff'
  });
  
  // 副标题
  drawText(ctx1, '我的客户说：早该改了！', 540, 950, {
    fontSize: 40,
    color: '#e94560',
    fontWeight: 'normal'
  });
  
  // 时钟和问号图标（用文本代替）
  drawText(ctx1, '⏰ ❓', 540, 1100, {
    fontSize: 100,
    color: '#ffffff'
  });
  
  fs.writeFileSync(path.join(outputDir, 'day1-cover.png'), cover1.toBuffer('image/png'));

  // 2. 客户案例对比图
  const case1 = createCanvas(1080, 1920);
  const ctx2 = case1.getContext('2d');
  
  ctx2.fillStyle = '#f8f9fa';
  ctx2.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx2, '客户改名案例', 540, 200, {
    fontSize: 50,
    color: '#333333'
  });
  
  // 原名
  drawText(ctx2, '原名', 270, 500, {
    fontSize: 40,
    color: '#666666'
  });
  drawText(ctx2, '李国强', 270, 600, {
    fontSize: 60,
    color: '#999999'
  });
  
  // 箭头
  drawText(ctx2, '→', 540, 600, {
    fontSize: 80,
    color: '#e94560'
  });
  
  // 新名
  drawText(ctx2, '新名', 810, 500, {
    fontSize: 40,
    color: '#666666'
  });
  drawText(ctx2, '李景行', 810, 600, {
    fontSize: 60,
    color: '#1a1a2e'
  });
  
  drawText(ctx2, '取自"高山仰止，景行行止"', 540, 800, {
    fontSize: 35,
    color: '#666666',
    fontWeight: 'normal'
  });
  
  fs.writeFileSync(path.join(outputDir, 'day1-case.png'), case1.toBuffer('image/png'));

  // 3. 改名流程图
  const flow1 = createCanvas(1080, 1920);
  const ctx3 = flow1.getContext('2d');
  
  ctx3.fillStyle = '#ffffff';
  ctx3.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx3, '改名4步走', 540, 200, {
    fontSize: 60,
    color: '#1a1a2e'
  });
  
  const steps = [
    '1️⃣ 法律流程\n户口/身份证/银行卡/社保',
    '2️⃣ 社交成本\n通知亲友/同事/客户',
    '3️⃣ 心理适应\n给自己3-6个月适应期',
    '4️⃣ 开启新生\n新名字=新开始'
  ];
  
  steps.forEach((step, index) => {
    drawText(ctx3, step, 540, 400 + index * 300, {
      fontSize: 35,
      color: '#333333',
      fontWeight: 'normal'
    });
  });
  
  fs.writeFileSync(path.join(outputDir, 'day1-flow.png'), flow1.toBuffer('image/png'));

  // 4. 五行分析示例图
  const wuxing1 = createCanvas(1080, 1920);
  const ctx4 = wuxing1.getContext('2d');
  
  ctx4.fillStyle = '#f0f4f8';
  ctx4.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx4, '姓名评估5维度', 540, 200, {
    fontSize: 55,
    color: '#1a1a2e'
  });
  
  const dimensions = [
    '🎵 音律美感',
    '✍️ 字形结构',
    '⚡ 五行平衡',
    '📖 寓意内涵',
    '📢 传播度'
  ];
  
  dimensions.forEach((dim, index) => {
    drawText(ctx4, dim, 540, 400 + index * 250, {
      fontSize: 45,
      color: '#333333'
    });
  });
  
  fs.writeFileSync(path.join(outputDir, 'day1-wuxing.png'), wuxing1.toBuffer('image/png'));

  // 5. 客户反馈截图
  const feedback1 = createCanvas(1080, 1920);
  const ctx5 = feedback1.getContext('2d');
  
  ctx5.fillStyle = '#f8f9fa';
  ctx5.fillRect(0, 0, 1080, 1920);
  
  // 模拟聊天框
  ctx5.fillStyle = '#ffffff';
  roundRect(ctx5, 100, 200, 880, 600, 20);
  ctx5.fill();
  
  drawText(ctx5, '客户反馈（脱敏）', 540, 150, {
    fontSize: 40,
    color: '#666666'
  });
  
  drawText(ctx5, '李哥', 200, 280, {
    fontSize: 35,
    color: '#1a1a2e',
    textAlign: 'left'
  });
  
  drawText(ctx5, '南老师，改名后感觉整个人都顺了。', 200, 380, {
    fontSize: 32,
    color: '#333333',
    fontWeight: 'normal',
    textAlign: 'left'
  });
  
  drawText(ctx5, '客户更容易记住我，开会发言也更有底气。', 200, 480, {
    fontSize: 32,
    color: '#333333',
    fontWeight: 'normal',
    textAlign: 'left'
  });
  
  fs.writeFileSync(path.join(outputDir, 'day1-feedback.png'), feedback1.toBuffer('image/png'));

  console.log('Day1图片生成完成！');
}

// Day2: 宝宝取名，这5个坑千万别踩！
async function generateDay2Images() {
  console.log('生成Day2图片...');

  // 1. 封面图
  const cover2 = createCanvas(1080, 1920);
  const ctx1 = cover2.getContext('2d');
  
  ctx1.fillStyle = '#ffb347';
  ctx1.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx1, '宝宝取名5大禁忌', 540, 800, {
    fontSize: 70,
    color: '#333333'
  });
  
  drawText(ctx1, '90%的家长都踩过！', 540, 950, {
    fontSize: 40,
    color: '#ff6b6b',
    fontWeight: 'normal'
  });
  
  drawText(ctx1, '⚠️ 👶', 540, 1100, {
    fontSize: 100,
    color: '#333333'
  });
  
  fs.writeFileSync(path.join(outputDir, 'day2-cover.png'), cover2.toBuffer('image/png'));

  // 2. 5个坑的图文说明
  const pits2 = createCanvas(1080, 1920);
  const ctx2 = pits2.getContext('2d');
  
  ctx2.fillStyle = '#fff5e6';
  ctx2.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx2, '取名5大坑', 540, 150, {
    fontSize: 55,
    color: '#333333'
  });
  
  const pits = [
    '❌ 坑1：生僻字炫技\n孩子考试写姓名说明',
    '❌ 坑2：谐音梗玩脱\n杜子腾=肚子疼',
    '❌ 坑3：爆款名字扎堆\n一个班3个同名',
    '❌ 坑4：五行缺啥补啥\n金鑫...',
    '❌ 坑5：寓意太满\n龙天霸，孩子压力大'
  ];
  
  pits.forEach((pit, index) => {
    drawText(ctx2, pit, 540, 300 + index * 300, {
      fontSize: 32,
      color: '#333333',
      fontWeight: 'normal'
    });
  });
  
  fs.writeFileSync(path.join(outputDir, 'day2-pits.png'), pits2.toBuffer('image/png'));

  // 3. 正确取名5步法
  const correct2 = createCanvas(1080, 1920);
  const ctx3 = correct2.getContext('2d');
  
  ctx3.fillStyle = '#e8f5e9';
  ctx3.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx3, '正确取名5步法', 540, 150, {
    fontSize: 55,
    color: '#2e7d32'
  });
  
  const steps = [
    '✅ 音律优先 - 读起来顺口',
    '✅ 字形美观 - 写出来好看',
    '✅ 寓意积极 - 有文化内涵',
    '✅ 独特适中 - 不俗也不怪',
    '✅ 成长友好 - 小时候可爱长大也得体'
  ];
  
  steps.forEach((step, index) => {
    drawText(ctx3, step, 540, 300 + index * 300, {
      fontSize: 35,
      color: '#333333',
      fontWeight: 'normal'
    });
  });
  
  fs.writeFileSync(path.join(outputDir, 'day2-correct.png'), correct2.toBuffer('image/png'));

  // 4. 案例对比
  const compare2 = createCanvas(1080, 1920);
  const ctx4 = compare2.getContext('2d');
  
  ctx4.fillStyle = '#ffffff';
  ctx4.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx4, '好名字 vs 踩坑名字', 540, 200, {
    fontSize: 50,
    color: '#333333'
  });
  
  const comparisons = [
    { bad: '李金鑫', good: '李子墨' },
    { bad: '杜子腾', good: '杜明远' },
    { bad: '张梓涵', good: '张语希' }
  ];
  
  comparisons.forEach((comp, index) => {
    const y = 400 + index * 400;
    drawText(ctx4, '❌ ' + comp.bad, 270, y, {
      fontSize: 45,
      color: '#ff6b6b'
    });
    drawText(ctx4, '→', 540, y, {
      fontSize: 60,
      color: '#666666'
    });
    drawText(ctx4, '✅ ' + comp.good, 810, y, {
      fontSize: 45,
      color: '#2e7d32'
    });
  });
  
  fs.writeFileSync(path.join(outputDir, 'day2-compare.png'), compare2.toBuffer('image/png'));

  // 5. 免费评估活动海报
  const poster2 = createCanvas(1080, 1920);
  const ctx5 = poster2.getContext('2d');
  
  ctx5.fillStyle = '#fff3e0';
  ctx5.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx5, '🎁 免费宝宝取名评估', 540, 300, {
    fontSize: 60,
    color: '#ff6b35'
  });
  
  drawText(ctx5, '提供：\n宝宝姓氏\n出生日期\n出生时间\n性别\n父母期望', 540, 500, {
    fontSize: 35,
    color: '#333333',
    fontWeight: 'normal'
  });
  
  drawText(ctx5, '你会得到：\n八字五行分析\n3个名字推荐\n寓意详解', 540, 900, {
    fontSize: 35,
    color: '#333333',
    fontWeight: 'normal'
  });
  
  drawText(ctx5, '前20名免费！\n私信"宝宝取名"', 540, 1300, {
    fontSize: 45,
    color: '#e94560'
  });
  
  fs.writeFileSync(path.join(outputDir, 'day2-poster.png'), poster2.toBuffer('image/png'));

  console.log('Day2图片生成完成！');
}

// Day3: 公司取名，价值千万的第一印象
async function generateDay3Images() {
  console.log('生成Day3图片...');

  // 1. 封面图
  const cover3 = createCanvas(1080, 1920);
  const ctx1 = cover3.getContext('2d');
  
  // 深蓝色背景配金色文字
  ctx1.fillStyle = '#0f3460';
  ctx1.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx1, '公司名字值多少钱？', 540, 800, {
    fontSize: 65,
    color: '#ffd700'
  });
  
  drawText(ctx1, '好名字=免费广告！', 540, 950, {
    fontSize: 40,
    color: '#ffffff',
    fontWeight: 'normal'
  });
  
  drawText(ctx1, '🏢 ™️', 540, 1100, {
    fontSize: 100,
    color: '#ffd700'
  });
  
  fs.writeFileSync(path.join(outputDir, 'day3-cover.png'), cover3.toBuffer('image/png'));

  // 2. 真实案例对比
  const case3 = createCanvas(1080, 1920);
  const ctx2 = case3.getContext('2d');
  
  ctx2.fillStyle = '#f5f5f5';
  ctx2.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx2, '真实改名案例', 540, 150, {
    fontSize: 55,
    color: '#333333'
  });
  
  // 案例1
  drawText(ctx2, '科技公司', 540, 280, {
    fontSize: 40,
    color: '#666666',
    fontWeight: 'normal'
  });
  drawText(ctx2, 'XX市华兴科技有限公司', 540, 380, {
    fontSize: 32,
    color: '#999999',
    fontWeight: 'normal'
  });
  drawText(ctx2, '↓', 540, 450, {
    fontSize: 60,
    color: '#e94560'
  });
  drawText(ctx2, '云启科技', 540, 550, {
    fontSize: 50,
    color: '#0f3460'
  });
  drawText(ctx2, '客户记忆度↑300%，传播成本↓70%', 540, 650, {
    fontSize: 28,
    color: '#2e7d32',
    fontWeight: 'normal'
  });
  
  // 案例2
  drawText(ctx2, '餐饮品牌', 540, 800, {
    fontSize: 40,
    color: '#666666',
    fontWeight: 'normal'
  });
  drawText(ctx2, '老王家常菜', 540, 900, {
    fontSize: 32,
    color: '#999999',
    fontWeight: 'normal'
  });
  drawText(ctx2, '↓', 540, 970, {
    fontSize: 60,
    color: '#e94560'
  });
  drawText(ctx2, '筷乐时光', 540, 1070, {
    fontSize: 50,
    color: '#0f3460'
  });
  drawText(ctx2, '成功注册商标，3年开15家分店', 540, 1170, {
    fontSize: 28,
    color: '#2e7d32',
    fontWeight: 'normal'
  });
  
  fs.writeFileSync(path.join(outputDir, 'day3-case.png'), case3.toBuffer('image/png'));

  // 3. 公司取名5大原则
  const principles3 = createCanvas(1080, 1920);
  const ctx3 = principles3.getContext('2d');
  
  ctx3.fillStyle = '#e3f2fd';
  ctx3.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx3, '公司取名5大原则', 540, 150, {
    fontSize: 55,
    color: '#0d47a1'
  });
  
  const principles = [
    '1️⃣ 易记易传播\n2-4个字，发音响亮',
    '2️⃣ 行业属性清晰\n科技→云智创科，餐饮→味香厨食',
    '3️⃣ 可注册商标\n先查数据库，避免通用词',
    '4️⃣ 寓意吉祥\n符合传统文化，避免负面联想',
    '5️⃣ 预留发展空间\n不局限地域和业务'
  ];
  
  principles.forEach((p, index) => {
    drawText(ctx3, p, 540, 300 + index * 300, {
      fontSize: 32,
      color: '#333333',
      fontWeight: 'normal'
    });
  });
  
  fs.writeFileSync(path.join(outputDir, 'day3-principles.png'), principles3.toBuffer('image/png'));

  // 4. 常见误区表格
  const mistakes3 = createCanvas(1080, 1920);
  const ctx4 = mistakes3.getContext('2d');
  
  ctx4.fillStyle = '#fff8e1';
  ctx4.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx4, '公司取名常见误区', 540, 150, {
    fontSize: 55,
    color: '#f57c00'
  });
  
  const mistakes = [
    '直接用法人名字\n→ 难传播，无品牌感',
    '追求高大上\n→ 空洞，无记忆点',
    '跟风热门词\n→ 同质化严重',
    '忽视商标查询\n→ 无法注册，白干',
    '名字太长\n→ 难记难传播'
  ];
  
  mistakes.forEach((m, index) => {
    drawText(ctx4, '❌ ' + m, 540, 300 + index * 300, {
      fontSize: 32,
      color: '#333333',
      fontWeight: 'normal'
    });
  });
  
  fs.writeFileSync(path.join(outputDir, 'day3-mistakes.png'), mistakes3.toBuffer('image/png'));

  // 5. 服务套餐海报
  const package3 = createCanvas(1080, 1920);
  const ctx5 = package3.getContext('2d');
  
  ctx5.fillStyle = '#0f3460';
  ctx5.fillRect(0, 0, 1080, 1920);
  
  drawText(ctx5, '💼 企业取名服务', 540, 300, {
    fontSize: 60,
    color: '#ffd700'
  });
  
  drawText(ctx5, '包含：\n✅ 5个精选名字方案\n✅ 名字寓意详解\n✅ 商标可注册性分析\n✅ 工商核名协助\n✅ 品牌故事撰写', 540, 500, {
    fontSize: 35,
    color: '#ffffff',
    fontWeight: 'normal'
  });
  
  drawText(ctx5, '限时优惠：2980元', 540, 1000, {
    fontSize: 60,
    color: '#e94560'
  });
  
  drawText(ctx5, '适合：初创公司/品牌升级/连锁扩张', 540, 1150, {
    fontSize: 30,
    color: '#cccccc',
    fontWeight: 'normal'
  });
  
  drawText(ctx5, '私信"公司取名"获取方案！', 540, 1350, {
    fontSize: 45,
    color: '#ffd700'
  });
  
  fs.writeFileSync(path.join(outputDir, 'day3-package.png'), package3.toBuffer('image/png'));

  console.log('Day3图片生成完成！');
}

// 辅助函数：绘制圆角矩形
function roundRect(ctx, x, y, width, height, radius) {
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.lineTo(x + width - radius, y);
  ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
  ctx.lineTo(x + width, y + height - radius);
  ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
  ctx.lineTo(x + radius, y + height);
  ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
  ctx.lineTo(x, y + radius);
  ctx.quadraticCurveTo(x, y, x + radius, y);
  ctx.closePath();
}

// 主函数
async function main() {
  try {
    await generateDay1Images();
    await generateDay2Images();
    await generateDay3Images();
    console.log('所有图片生成完成！保存在 xiaohongshu_images/ 目录下');
  } catch (error) {
    console.error('生成图片时出错:', error);
  }
}

main();

