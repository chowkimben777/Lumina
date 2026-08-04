# Lumina

Lumina 是一个原生 macOS 刘海交互工具。静态时它贴合 MacBook 顶部刘海；鼠标进入后，岛体从顶部向左右与下方展开，提供剪贴板历史、专注计时和媒体状态等常用功能。

当前项目针对带刘海的 MacBook 与 macOS 26 设计，使用 SwiftUI 和 AppKit 实现。

## 功能

- 静态刘海状态：无任务时保持贴合刘海；专注或媒体活动时展示精简状态。
- 悬停展开：顶部位置固定，岛体以弹簧动画向左右和下方扩展。
- 剪贴板历史：保存文本、链接与图片；支持恢复、置顶、删除和清空。
- 专注计时：提供 25、50、90 分钟预设；支持暂停、继续和停止，并在紧凑状态显示倒计时。
- 媒体状态：读取 Apple Music 与 Spotify 的通知信息，并提供播放/暂停入口。
- 多桌面可用：浮层可出现在不同 Space 和全屏应用上方。

## 环境要求

- macOS 26 或更高版本
- 支持 Swift 6.2 的 Xcode
- 推荐使用带刘海的 MacBook 显示器

## 运行

### 在 Xcode 中运行

```bash
open Package.swift
```

在 Xcode 中选择 `Lumina` 可执行方案后运行即可。

### 在终端中构建

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open .build/Lumina.app
```

应用会构建到 `.build/Lumina.app`。右键点击岛体可退出应用。

## 使用方式

- 将鼠标移入刘海区域以展开主面板。
- 点击“剪贴板”查看并恢复历史记录。
- 点击“专注”设置计时；计时开始后，可在展开面板直接暂停、继续或停止。
- 点击“媒体”查看当前媒体状态。
- 鼠标离开面板后，岛体会自动收起。

## 数据与隐私

剪贴板历史仅保存在本机：

```text
~/Library/Application Support/Lumina/clipboard-history.json
```

Lumina 不会上传剪贴板内容，也会忽略常见密码管理器使用的隐藏剪贴板类型。媒体状态来自 Apple Music 和 Spotify 的本地分布式通知；未发布这类通知的播放器不会被识别。

## 项目结构

```text
Sources/Lumina/   SwiftUI 与 AppKit 源码
Resources/        应用包元数据
scripts/          本地构建脚本
Package.swift     Swift Package 配置
```

## 当前范围

这是一个面向个人工作流的原型，尚未提供设置页、全局快捷键、签名或公证后的发布包。
