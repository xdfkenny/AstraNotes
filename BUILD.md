# 🏗️ AstraNotes 构建指南（无 Mac 也能构建）

本项目的 macOS 构建完全由 **GitHub Actions 的 macOS runner** 完成——你不需要拥有一台 Mac。

## 工作原理

```
你的代码 (Windows/任何电脑)
        │  git push
        ▼
GitHub Actions  (macos-14 runner = Apple Silicon arm64，与 M4 同架构)
        │
        ├─ 1. brew install xcodegen          ← 命令行生成 Xcode 项目
        ├─ 2. node scripts/generate_icons.js ← 校验图标与映射表同步
        ├─ 3. xcodegen generate              ← 生成 AstraNotes.xcodeproj
        │      · 自动添加全部源码到 target
        │      · 自动把 Resources/Fonts/MaterialSymbolsOutlined.ttf 加入 Copy Bundle Resources
        │      · 自动添加 WhisperKit 依赖 (SPM, v1.1.0)
        │      · 自动生成 Info.plist（含麦克风权限说明）
        ├─ 4. xcodebuild Release 编译
        └─ 5. 打包 AstraNotes-macOS-arm64.zip 作为 Actions artifact
```

## 快速开始

```bash
# 1. 提交并推送到 GitHub（仓库已存在: github.com/xdfkenny/AstraNotes）
git add -A
git commit -m "CI: XcodeGen build pipeline"
git push -u origin master

# 2. 打开 GitHub → 你的仓库 → Actions 标签
#    看到 "Build macOS App" 正在运行（首次约 10-20 分钟，含 WhisperKit 编译）

# 3. 构建完成后，进入该 workflow run 页面底部
#    → Artifacts → 下载 AstraNotes-macOS-arm64.zip
```

也可以在 Actions 页面手动触发：**Actions → Build macOS App → Run workflow**。

## 在 M4 上运行

```bash
# 解压后，首次运行需移除 macOS 的隔离标记（因为未公证）
xattr -dr com.apple.quarantine AstraNotes.app

# 或者：右键 AstraNotes.app → 打开 → 确认
```

### 首次启动配置
1. **Whisper 模型**：进入「Transcription」页，自动下载 large-v3-turbo 模型（约 1.5GB，仅一次，存储在本机）
2. **DeepSeek API Key**：设置 → AI 服务 → 填入 `sk-...`（OpenCode Go / DeepSeek 控制台获取）
3. **Obsidian 仓库**：设置 → AI 服务 → Choose Vault，选择你的 Obsidian 库目录

## 图标系统（Google Material Symbols）

- 字体已打包进 app（`Resources/Fonts/MaterialSymbolsOutlined.ttf`，10.6MB）
- App 启动时 `FontRegistrar.register()` 自动注册，无需手动配置
- **添加新图标**：
  1. 编辑 `scripts/generate_icons.js` 的 `mapping` 表（`['SF别名', 'material图标名']`）
  2. 运行 `node scripts/generate_icons.js`（重新生成 `AstraIcon.swift`）
  3. 提交两个文件
  - CI 中有一个校验步骤：若 `AstraIcon.swift` 与映射表不同步，构建会直接失败提醒你

## 本地构建（如果你之后有 Mac 可用）

```bash
brew install xcodegen
cd AstraNotes
xcodegen generate          # 生成 AstraNotes.xcodeproj
open AstraNotes.xcodeproj  # 或用命令行:
xcodebuild -project AstraNotes.xcodeproj -scheme AstraNotes -configuration Release build
```

## 常见问题

| 问题 | 解决 |
|------|------|
| 打开 app 提示"已损坏/无法验证开发者" | `xattr -dr com.apple.quarantine AstraNotes.app` |
| 麦克风无权限 | 系统设置 → 隐私与安全性 → 麦克风 → 勾选 AstraNotes |
| 图标显示为方块(豆腐块) | 确认 `MaterialSymbolsOutlined.ttf` 在 app 包内: `ls AstraNotes.app/Contents/Resources/` |
| WhisperKit 版本解析失败 | 改 `project.yml` 的 `from: "1.1.0"` 为最新版本 |
| 需要深色/浅色主题 | 设置 → Appearance → Light / Dark / System |

## 已知限制

- **未签名、未公证**：本方案跳过 Apple Developer 签名（$99/年）。本地个人使用完全没问题；若未来要分发给他人，需要 Apple Developer 账号 + 在 CI 中配置签名证书 Secrets。
- **仅 arm64**：macos-14 runner 是 Apple Silicon，产物只适用于 M1-M4 系列 Mac。Intel Mac 需改用 `macos-13` runner 并添加 `ARCHS=x86_64`。
- 音频只在本机处理（Whisper 本地推理），DeepSeek 调用会消耗 API 额度（约 $0.14/百万输入 token，非常便宜）。
