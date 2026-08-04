# Lumina

> 一个提供剪贴板历史、专注计时与媒体控制的原生 macOS 刘海工具。

[English](README.md)

Lumina 在静态时贴合 MacBook 刘海；将鼠标移入刘海区域后，它会以顶部固定的方式展开，提供常用的快捷功能。

## 亮点

- **为刘海而生**：静态时融入刘海，展开时通过弹簧动画向左右与下方延展，顶部始终固定。
- **剪贴板历史**：在本机保存文本、链接与图片，支持恢复、置顶、删除和清空。
- **专注计时**：支持 25、50、90 分钟预设，可直接在岛体中暂停、继续或停止。
- **媒体状态**：读取 Apple Music 与 Spotify 的本地通知；在 macOS 26 上实验性支持 QQ 音乐的歌曲展示与播放/暂停控制。
- **原生体验**：使用 SwiftUI 与 AppKit 构建，可跨 Space 和全屏应用使用。

## 环境要求

- macOS 26 或更高版本
- 支持 Swift 6.2 的 Xcode
- 推荐使用带刘海的 MacBook 显示器

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

可从仓库的 [Releases](../../releases) 页面下载预构建版本。当前未签名版本首次启动时，可能需要按住 Control 点击 App 后选择“打开”，再在 macOS 中确认。

在当前 Mac 架构下创建本地发布包：

```bash
scripts/package-release.sh v0.1.0
```

该命令会在 `dist/` 生成 ZIP 与 SHA-256 校验文件。向 GitHub 推送以 `v` 开头的 Git 标签后，GitHub Actions 会执行相同的打包步骤并自动创建 GitHub Release。

## 使用方式

1. 将鼠标移入刘海区域，打开主岛体。
2. 点击“剪贴板”，浏览并恢复本机历史记录。
3. 点击“专注”，开始计时；运行中可直接在展开岛体里暂停、继续或停止。
4. 点击“媒体”，查看当前媒体状态。
5. 鼠标离开面板后，岛体会自动收起；右键点击岛体可退出应用。

## 数据与隐私

剪贴板历史仅保存在本机：

```text
~/Library/Application Support/Lumina/clipboard-history.json
```

Lumina 不会上传剪贴板内容，也会忽略常见密码管理器使用的隐藏剪贴板类型。QQ 音乐通过 macOS 26 的系统媒体桥接读取；由于 Apple 没有公开的跨应用媒体元数据 API，这项支持属于实验性能力。

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
