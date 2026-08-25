# Lumina

> 一个提供剪贴板历史、专注计时、媒体控制与 AI 完成提醒的原生 macOS 刘海工具。

[English](README.md)

Lumina 在静态时贴合 MacBook 刘海；将鼠标移入刘海区域后，它会以顶部固定的方式展开，提供常用的快捷功能。

## 亮点

- **为刘海而生**：静态时融入刘海，展开时通过弹簧动画向左右与下方延展，顶部始终固定。
- **剪贴板历史**：在本机保存文本、链接与图片，支持恢复、置顶、删除和清空。
- **专注计时**：支持 25、50、90 分钟预设，可直接在岛体中暂停、继续或停止。
- **定时提醒**：可创建带名称的提醒任务，支持仅一次、每天或工作日重复；到点后岛体会展开提醒 5 秒。
- **媒体状态**：读取 Apple Music 与 Spotify 的本地通知；在 macOS 26 上实验性支持 QQ 音乐的歌曲展示与播放/暂停控制。
- **AI 完成提醒**：当 Codex 或 Trae 完成长任务、且你正在使用其他应用时，岛体会展开提醒 3 秒；点击提醒可直接回到对应应用。
- **原生体验**：使用 SwiftUI 与 AppKit 构建，可跨 Space 和全屏应用使用。

## 环境要求

- 运行发布版需要 macOS 26 或更高版本
- 推荐使用带刘海的 MacBook 显示器
- 仅从源码构建时需要支持 Swift 6.2 的 Xcode

## 快速开始

### Xcode

```bash
open Package.swift
```

在 Xcode 中选择 `Lumina` 可执行方案后运行。

### 终端

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open .build/Lumina.app
```

应用包会生成在 `.build/Lumina.app`。

## 发布版本

可从仓库的 [Releases](../../releases) 页面下载与自己 Mac 架构匹配的预构建版本，下载版不需要安装 Xcode。

1. Apple 芯片 Mac 下载 `Lumina-v*-macos-arm64.zip`；Intel Mac 下载对应的 `x86_64` 压缩包。
2. 解压后将 `Lumina.app` 拖到 `/Applications` 或任意常用目录。
3. 首次启动时按住 Control 点击 App，选择“打开”，再在 macOS 中确认。当前版本尚未签名和公证。

在当前 Mac 架构下创建本地发布包：

```bash
scripts/package-release.sh v0.2.1
```

该命令会在 `dist/` 生成 ZIP 与 SHA-256 校验文件。向 GitHub 推送以 `v` 开头的 Git 标签后，GitHub Actions 会执行相同的打包步骤并自动创建 GitHub Release。

## 使用方式

1. 将鼠标移入刘海区域，打开主岛体。
2. 点击“剪贴板”，浏览并恢复本机历史记录。
3. 点击“专注”，开始计时；运行中可直接在展开岛体里暂停、继续或停止。
4. 点击“提醒”，创建、编辑、启用或删除仅一次、每天和工作日提醒。
5. 媒体无需单独进入：歌曲播放时，岛体会自动展示状态并提供播放/暂停。
6. Codex 或 Trae 在后台完成工具任务或较长响应时，Lumina 会弹出 3 秒完成提醒；点击提醒卡可回到对应应用。
7. 鼠标离开面板后，岛体会自动收起；右键点击岛体可退出应用。

## 数据与隐私

剪贴板历史仅保存在本机：

```text
~/Library/Application Support/Lumina/clipboard-history.json
```

Lumina 不会上传剪贴板内容，提醒任务保存在本机 macOS 偏好设置中，也会忽略常见密码管理器使用的隐藏剪贴板类型。AI 完成提醒只读取本机 Codex 会话事件与 Trae Agent 活动，不会上传任务内容或活动数据。QQ 音乐通过 macOS 26 的系统媒体桥接读取；由于 Apple 没有公开的跨应用媒体元数据 API，这项支持属于实验性能力。

## 开发

```text
Sources/Lumina/   SwiftUI 与 AppKit 源码
Resources/        应用包元数据
scripts/          本地构建脚本
Package.swift     Swift Package 配置
```

提交 Pull Request 前，请执行：

```bash
xcrun swift-format format --in-place --recursive Sources Package.swift
./scripts/build-app.sh
xcrun swift-format lint --recursive Sources Package.swift
```

## 贡献

欢迎参与贡献。参与前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)、[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) 与 [SECURITY.md](SECURITY.md)。

## 路线图

- 已启用模块与历史保留数量的偏好设置
- 全局快捷键
- 已签名和公证的发布包
- 更多媒体播放器集成

## 许可证

Lumina 使用 [MIT License](LICENSE) 发布。
