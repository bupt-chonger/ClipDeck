import ClipDeckCore
import Foundation

struct AppStrings {
    let language: AppLanguagePreference

    init(_ language: AppLanguagePreference) {
        self.language = language
    }

    var settingsWindowTitle: String { text(en: "ClipDeck Settings", zh: "ClipDeck 设置") }
    var languageSection: String { text(en: "Language", zh: "语言") }
    var appLanguage: String { text(en: "App language", zh: "应用语言") }
    var shortcutsSection: String { text(en: "Shortcut", zh: "快捷键") }
    var showHideClipboard: String { text(en: "Show / hide clipboard", zh: "呼出/隐藏剪贴板") }
    var privacySection: String { text(en: "Privacy Filters", zh: "隐私过滤") }
    var ignorePasswordManagers: String { text(en: "Ignore password managers", zh: "忽略密码管理器") }
    var ignorePasswordManagersHelp: String { text(en: "Automatically ignores common password managers such as 1Password, Bitwarden, Dashlane, LastPass, and KeePass.", zh: "自动忽略 1Password、Bitwarden、Dashlane、LastPass、KeePass 等常见密码管理器来源。") }
    var ignorePrivateBrowsing: String { text(en: "Ignore private browsing", zh: "忽略浏览器隐身/私密模式") }
    var ignorePrivateBrowsingHelp: String { text(en: "When the front browser window title contains Private, Incognito, InPrivate, or similar markers, ClipDeck will not save the clipboard item.", zh: "当前台浏览器窗口标题包含 Private、Incognito、InPrivate、隐身、无痕等标记时，不保存剪贴板内容。") }
    var ignoreSensitiveContent: String { text(en: "Ignore sensitive content", zh: "忽略敏感内容") }
    var ignoreSensitiveContentHelp: String { text(en: "Filters verification codes, private keys, API keys, tokens, and secrets.", zh: "过滤验证码、私钥、API key、token、secret 等文本内容。") }
    var privacyNote: String { text(en: "These filters only affect ClipDeck history and do not clear the system clipboard.", zh: "这些过滤只影响 ClipDeck 的历史记录，不会清空系统剪贴板。") }
    var imagePrivacyNote: String { text(en: "Image contents cannot be inspected reliably, so images are filtered by source app and private browsing state only.", zh: "图片内容无法可靠识别密钥或验证码，因此图片只按来源 App 和隐身窗口过滤。") }
    var ignoredAppsSection: String { text(en: "Ignored Apps", zh: "忽略 App") }
    var noIgnoredApps: String { text(en: "No custom ignored apps.", zh: "暂无自定义忽略 App。") }
    var removeFromIgnoredApps: String { text(en: "Remove from ignored apps", zh: "从忽略列表移除") }
    var clipboardRecordsSection: String { text(en: "Clipboard Records", zh: "剪贴板记录") }
    var allRecords: String { text(en: "All records", zh: "全部记录") }
    var deleteAllDescription: String { text(en: "Delete all clipboard history saved by ClipDeck.", zh: "删除 ClipDeck 保存的全部剪贴板历史。") }
    var deleteAllRecords: String { text(en: "Delete All Records", zh: "删除全部记录") }
    var deleteAllRecordsQuestion: String { text(en: "Delete all records?", zh: "删除全部记录？") }
    var cancel: String { text(en: "Cancel", zh: "取消") }
    var delete: String { text(en: "Delete", zh: "删除") }
    var deleteAllAlertMessage: String { text(en: "This only deletes history saved by ClipDeck. It will not clear the system clipboard.", zh: "此操作只删除 ClipDeck 保存的历史记录，不会清空系统剪贴板。") }
    var recordingShortcut: String { text(en: "Press new shortcut", zh: "按下新的快捷键") }
    var shortcutRecorderHelp: String { text(en: "Click, then press a shortcut that includes Command, Option, Control, or Shift.", zh: "点击后按下包含 Command、Option、Control 或 Shift 的快捷键") }
    var settings: String { text(en: "Settings", zh: "设置") }
    var search: String { text(en: "Search", zh: "搜索") }
    var searchClips: String { text(en: "Search clips", zh: "搜索剪贴板") }
    var clearSearch: String { text(en: "Clear search", zh: "清除搜索") }
    var addPinboard: String { text(en: "Add pinboard", zh: "新增分组") }
    var pinboardPlaceholder: String { text(en: "Pinboard", zh: "分组") }
    var createPinboard: String { text(en: "Create Pinboard", zh: "创建分组") }
    var renamePinboard: String { text(en: "Rename Pinboard", zh: "重命名分组") }
    var deletePinboard: String { text(en: "Delete Pinboard", zh: "删除分组") }
    var pinboardFallback: String { text(en: "Pinboard", zh: "分组") }
    var save: String { text(en: "Save", zh: "保存") }
    var edit: String { text(en: "Edit", zh: "编辑") }
    var rename: String { text(en: "Rename", zh: "重命名") }
    var copy: String { text(en: "Copy", zh: "复制") }
    var pasteAsPlainText: String { text(en: "Paste as Plain Text", zh: "粘贴为纯文本") }
    var noPinboards: String { text(en: "No Pinboards", zh: "暂无分组") }
    var pin: String { text(en: "Pin", zh: "归类") }
    var quickLook: String { text(en: "Quick Look", zh: "快速查看") }
    var share: String { text(en: "Share", zh: "分享") }
    var shareEllipsis: String { text(en: "Share...", zh: "分享...") }
    var activeApp: String { text(en: "Active App", zh: "当前 App") }
    var noClips: String { text(en: "No Clips", zh: "暂无剪贴板条目") }
    var emptyStateDescription: String { text(en: "Copy text anywhere on your Mac and it will appear here.", zh: "在 Mac 任意位置复制文本后，它会出现在这里。") }
    var headerDescription: String { text(en: "Search, pin, edit, and reuse local clipboard history.", zh: "搜索、归类、编辑并复用本地剪贴板历史。") }
    var pinboardsTitle: String { text(en: "Pinboards", zh: "分组") }
    var saveEdit: String { text(en: "Save Edit", zh: "保存编辑") }
    var previewUnavailable: String { text(en: "Preview unavailable", zh: "无法预览") }

    func ignoreApp(_ name: String) -> String {
        switch language {
        case .english: "Ignore \(name)"
        case .simplifiedChinese: "忽略 \(name)"
        }
    }

    func deletedRecords(_ count: Int) -> String {
        switch language {
        case .english: "Deleted \(count) records"
        case .simplifiedChinese: "已删除 \(count) 条记录"
        }
    }

    func pasteTo(_ appName: String) -> String {
        switch language {
        case .english: "Paste to \(appName)"
        case .simplifiedChinese: "粘贴到 \(appName)"
        }
    }

    func characters(_ count: Int) -> String {
        switch language {
        case .english: "\(count) characters"
        case .simplifiedChinese: "\(count) 个字符"
        }
    }

    func renamePinboardMessage() -> String { text(en: "Enter a new name for this Pinboard.", zh: "为该分组输入新的名称。") }
    func editClipMessage() -> String { text(en: "Edit this clipboard item.", zh: "修改该剪贴板条目的内容。") }
    func renameClipMessage() -> String { text(en: "Enter a new display name for this clipboard item.", zh: "为该剪贴板条目输入新的显示名称。") }

    func deletePinboardQuestion(_ name: String) -> String {
        switch language {
        case .english: "Delete \(name)?"
        case .simplifiedChinese: "删除 \(name)？"
        }
    }

    func deletePinboardMessage(count: Int) -> String {
        switch language {
        case .english: "This will also delete \(count) clipboard items in this Pinboard. This action cannot be undone."
        case .simplifiedChinese: "这会同时删除该分组下的 \(count) 个剪贴板条目。此操作无法撤销。"
        }
    }

    func kindLabel(_ kind: ClipKind) -> String {
        switch kind {
        case .text: text(en: "Text", zh: "文本")
        case .link: text(en: "Link", zh: "链接")
        case .image: text(en: "Image", zh: "图片")
        case .code: text(en: "Code", zh: "代码")
        case .color: text(en: "Color", zh: "颜色")
        }
    }

    func boardTitle(_ board: Pinboard) -> String {
        switch board {
        case .all: text(en: "History", zh: "历史")
        case .links: text(en: "Links", zh: "链接")
        case .images: text(en: "Images", zh: "图片")
        case .code: text(en: "Code", zh: "代码")
        case .colors: text(en: "Colors", zh: "颜色")
        }
    }

    func localeIdentifier() -> String { language.rawValue }

    private func text(en: String, zh: String) -> String {
        switch language {
        case .english: en
        case .simplifiedChinese: zh
        }
    }
}
