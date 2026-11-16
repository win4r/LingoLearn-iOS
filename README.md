# [🚀观看我的哔哩哔哩视频](https://space.bilibili.com/3493277319825652)

# LingoLearn 背单词

基于 **SM-2 间隔重复算法** 的 iOS 背单词应用。SwiftUI 全原生实现，预置 **1000+ CET4/CET6 词汇**，零第三方依赖。

| | | |
|---|---|---|
| 技术栈 | SwiftUI · SwiftData · Swift Charts · AVFoundation (TTS) | iOS 17.0+ |
| 开发工具 | Xcode 26（Xcode 16+ 均可打开） | Swift 5.9+ |

## 运行说明

1. 用 Xcode 打开 `LingoLearn.xcodeproj`
2. 选择 `LingoLearn` scheme 和任意 iOS 17+ 模拟器（如 iPhone 17）
3. `⌘R` 运行。首次启动自动导入预置词库（约 1 秒）

> 真机运行：在 *Signing & Capabilities* 中改为自己的开发团队即可，无需任何额外配置。

命令行构建与测试：

```bash
# 构建
xcodebuild -project LingoLearn.xcodeproj -scheme LingoLearn \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# 全量测试（34 个单元测试 + UI 冒烟测试）
xcodebuild -project LingoLearn.xcodeproj -scheme LingoLearn \
  -destination 'platform=iOS Simulator,name=iPhone 17' test -parallel-testing-enabled NO
```

## 功能总览

### 首页
- 环形渐变进度条：今日已学 / 每日目标
- 🔥 连续打卡天数（toolbar 火焰徽标）
- 待复习数量角标（红色 badge + 橙色提示胶囊）
- 快捷入口：开始学习 / 快速复习 / 随机测试
- 今日小结：新学 · 复习 · 练习

### 单词学习（卡片）
- 正面：单词 + 音标；背面：释义 + 例句 + 例句翻译
- 点击卡片 **3D 翻转**（双面 rotation3DEffect + 弹簧动画）
- **右滑认识 / 左滑不认识 / 上滑收藏**，滑动时卡片倾斜 + 颜色渐变 + 印章反馈
- 喇叭图标系统 TTS 发音（en-US），可开关自动播放
- 底部 ✗ / ★ / ✓ 按钮等效手势操作（无障碍友好）
- 每组（≤10 词）结束弹出本轮统计：认识率环 + 三项计数 + 再来一组
- 评分即时落库：每张卡片滑出时即写入 SwiftData，中途退出不丢进度

### 练习测试
- 三种题型 + 随机混合：**选择题**（看词选义）/ **填空题**（看义拼词）/ **听力题**（听音选词）
- 题量（5/10/15/20）与每题时间（10/15/20/30 秒）可配
- 顶部倒计时进度条，剩余 < 30% 变红；超时自动判错
- 答对：绿色对勾弹跳动画 + 成功触感；答错：红色抖动（GeometryEffect）+ 错误触感，并揭示正确答案
- 结算页：正确率环、总用时、对错计数、**错题列表**（可重听发音）
- 支持「错题再练」与「再练一组」

### 学习进度
- **折线图**（Swift Charts LineMark + AreaMark）：近 7 天 / 30 天每日新学单词数
- **日历热力图**：近 15 周学习频率，GitHub 贡献图风格（5 级色阶、周一对齐、今日描边、横向滚动锚定最新）
- **环形占比图**（SectorMark）：新学 / 学习中 / 已掌握 分布
- **成就徽章墙**：10 枚徽章（首次学习、连续 3/7/30 天、累计 100/500 词、掌握 100 词、收藏 10 词、满分练习等）
- 解锁成就时弹出庆祝动画：徽章弹跳 + Canvas 彩带粒子 + 成功触感

### 设置
- 每日学习目标滑块（10–100，步长 5）
- 每日学习提醒（本地通知，权限被拒时引导去系统设置）
- 音效 / 震动反馈 / 自动播放发音 开关
- 外观：跟随系统 / 浅色 / 深色
- 词库统计（CET4 / CET6 词数）
- 重置学习进度（**两步确认**，保留词库只清进度）

## 设计

- 主色 `#0EA5E9`（天蓝）+ 辅助色 `#14B8A6`（青绿），品牌渐变贯穿主按钮 / 进度环 / 图表
- 完整适配 Light / Dark Mode（系统语义色 + 资产目录 AccentColor）
- 所有交互均配触觉反馈（`UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator`，受设置开关控制）
- 空状态（无待复习 / 词库学完 / 无图表数据）、加载态（词库播种）、错误态（数据库初始化失败、词库缺失可重试、通知权限被拒）均有处理

## SM-2 间隔重复算法

每张卡片的作答映射为质量分：右滑认识 = 5，上滑收藏 = 4，左滑不认识 = 1。

```
EF' = max(1.3, EF + 0.1 − (5−q)(0.08 + (5−q) × 0.02))
间隔：第 1 次 1 天 → 第 2 次 6 天 → 之后 间隔 × EF
q < 3：重置重复计数，10 分钟后当天重新复习
掌握判定：重复 ≥ 4 次且间隔 ≥ 21 天 → 已掌握
```

实现见 `Services/SM2.swift`（纯函数，含 8 个单元测试）。

## 词库数据

- `Resources/words-cet4-*.json`（552 词）+ `words-cet6-*.json`（453 词），共 **1005 个去重单词**
- 每词含：单词、IPA 音标、中文释义（含词性）、英文例句、例句翻译
- 紧凑 JSON 格式（`en/ph/zh/ex/tr`），首启幂等播种（按版本号增量，按单词去重）
- 数据完整性由 `SeedDataTests` 保证（≥500 词、无重复、字段非空、音标格式）

## 项目结构

```
LingoLearn/
├── LingoLearnApp.swift          # 入口：注册默认设置、ModelContainer（含失败兜底）
├── Models/                      # SwiftData 模型：Word（含 SM-2 状态）、DailyStudyRecord、Achievement
├── Services/                    # 纯逻辑层（全部可单测）
│   ├── SM2.swift                #   间隔重复算法
│   ├── StudyService.swift       #   取词队列 / 评分落库 / 打卡 / 图表数据 / 重置
│   ├── QuizEngine.swift         #   出题与判分（干扰项去重）
│   ├── AchievementEngine.swift  #   成就判定
│   ├── WordSeeder.swift         #   词库播种
│   ├── SpeechService.swift      #   系统 TTS
│   └── NotificationManager.swift#   每日提醒
├── Views/
│   ├── RootView.swift           # 播种门控 + TabView + 外观
│   ├── Home/ Learn/ Practice/ Stats/ Settings/ Shared/
├── Support/                     # 主题色、设置键、触感音效、抖动/彩带动效、日期工具
└── Resources/                   # 词库 JSON × 4

LingoLearnTests/                 # 34 个单元测试（Swift Testing）
LingoLearnUITests/               # 端到端冒烟（学习流 + 四 Tab 巡检）
```

## 测试

- **单元测试**：SM-2 算法边界（EF 下限、失败重置、质量分钳制）、出题引擎（选项唯一性、混合题型、词池不足）、学习服务（评分调度、打卡连续性、当日去重计数、重置）、成就引擎（解锁幂等、满分练习门槛）、词库数据完整性
- **UI 测试**：真实模拟器走通 首页 → 学习卡翻转 → 评分 → 练习/进度/设置 巡检
- 已验证：浅色 + 深色模式截图、冷启动播种、跨进程数据持久化
