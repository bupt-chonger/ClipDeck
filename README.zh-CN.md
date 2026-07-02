# ClipDeck

[English](README.md) | 中文简体

ClipDeck 是一个面向 macOS 的剪贴板工具。它以贴合屏幕底部的浮层面板呈现剪贴板历史，支持文本、图片、搜索、预览、快捷键呼出和自定义分组归类。

项目使用 SwiftUI 和 AppKit 构建，界面参考 macOS 的 Liquid Glass 视觉方向：轻量、透明、低干扰，适合在日常复制、整理和粘贴流程中快速调用。

## 功能特性

- 全局快捷键呼出或隐藏底部剪贴板面板
- 自动保存文本和图片剪贴板历史
- 图片预览，以及图片剪贴板内容的复制/粘贴恢复
- 根据内容、类型、来源 App、分组名称搜索条目
- 自定义分组，支持颜色、重命名、删除和条目归类
- 键盘左右方向键切换选中条目
- `Delete` / `Backspace` 删除选中条目
- `Command-C` 复制选中条目
- 再次点击或双击条目可粘贴到之前聚焦的 App
- 支持删除全部历史记录，或删除指定来源 App 的记录
- 本地存储，不上传剪贴板内容

## 隐私过滤

ClipDeck 提供可配置的隐私过滤能力，用来减少敏感内容进入本地历史记录的概率：

- 忽略常见密码管理器来源，例如 1Password、Bitwarden、Dashlane、LastPass、KeePass 等
- 忽略浏览器隐身/私密窗口来源，例如 Private Browsing、Incognito、InPrivate、隐身、无痕、私密浏览等窗口标题
- 忽略常见敏感文本，例如验证码、私钥、API key、access token、refresh token、client secret 等
- 支持将某个来源 App 加入自定义忽略列表，也可以从设置中移除

需要注意：图片内容无法可靠识别是否包含验证码、密钥或敏感文档，因此图片目前只按来源 App 和隐身窗口进行过滤。

## 使用方式

启动后，ClipDeck 会作为后台辅助类应用运行，并显示底部剪贴板面板。默认快捷键为：

```text
Option Space
```

在剪贴板面板中可以直接输入进行搜索，也可以点击搜索图标展开或折叠搜索框。选中条目后，可以使用快捷键复制、删除，或通过鼠标点击完成粘贴。

## 构建和运行

环境要求：

- macOS 14 或更高版本
- Swift 6 工具链

运行测试：

```bash
swift test
```

构建并启动应用：

```bash
./script/build_and_run.sh
```

只验证应用能否构建和启动：

```bash
./script/build_and_run.sh --verify
```

## 辅助功能权限

ClipDeck 可能会请求 macOS 辅助功能权限。该权限用于在选择剪贴板条目后，将焦点恢复到之前的应用，并发送粘贴快捷键，从而实现“直接粘贴到当前位置”。

剪贴板采集、本地历史记录和搜索不依赖网络访问。

## 数据存储

ClipDeck 将历史记录保存在当前用户的 Application Support 目录中，通过 `LibrarySnapshotStore` 读写本地 JSON 快照。

如果你经常复制密码、密钥、验证码、个人信息、截图或公司内部资料，建议开启隐私过滤，并定期清理历史记录。

## 开源说明

ClipDeck 的交互和组织方式参考了现代剪贴板 shelf 工作流，以及 Pinboard 风格的信息整理方式。

本项目是独立开源项目，与 Paste 或 pasteapp.io 没有关联、授权、赞助或背书关系。Paste 和 pasteapp.io 是其各自权利人的商标或资产。

## License

ClipDeck 使用 MIT License 开源，详见 [LICENSE](LICENSE)。
