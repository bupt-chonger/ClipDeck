import Foundation

public struct ClipboardSourceApp: Codable, Equatable, Hashable, Sendable {
    public var name: String
    public var bundleIdentifier: String?
    public var windowTitle: String?

    public init(name: String, bundleIdentifier: String? = nil, windowTitle: String? = nil) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.windowTitle = windowTitle
    }
}

public struct ClipboardCapturePolicy: Codable, Equatable, Sendable {
    public var ignoresPasswordManagers: Bool
    public var ignoresPrivateBrowsing: Bool
    public var ignoresSensitiveContent: Bool
    public var ignoredBundleIdentifiers: Set<String>

    public init(
        ignoresPasswordManagers: Bool = true,
        ignoresPrivateBrowsing: Bool = true,
        ignoresSensitiveContent: Bool = true,
        ignoredBundleIdentifiers: Set<String> = []
    ) {
        self.ignoresPasswordManagers = ignoresPasswordManagers
        self.ignoresPrivateBrowsing = ignoresPrivateBrowsing
        self.ignoresSensitiveContent = ignoresSensitiveContent
        self.ignoredBundleIdentifiers = ignoredBundleIdentifiers
    }

    public static let `default` = ClipboardCapturePolicy()

    public func shouldCaptureText(_ text: String, source: ClipboardSourceApp) -> Bool {
        guard shouldCaptureSource(source) else { return false }
        guard !ignoresSensitiveContent || !ClipboardCapturePolicy.containsSensitiveContent(text) else { return false }
        return true
    }

    public func shouldCaptureImage(source: ClipboardSourceApp) -> Bool {
        shouldCaptureSource(source)
    }

    public func shouldCaptureSource(_ source: ClipboardSourceApp) -> Bool {
        if let bundleIdentifier = source.bundleIdentifier, ignoredBundleIdentifiers.contains(bundleIdentifier) {
            return false
        }
        if ignoresPasswordManagers, ClipboardCapturePolicy.isPasswordManager(source) {
            return false
        }
        if ignoresPrivateBrowsing, ClipboardCapturePolicy.isPrivateBrowsing(source) {
            return false
        }
        return true
    }

    public func ignoring(source: ClipboardSourceApp) -> ClipboardCapturePolicy {
        guard let bundleIdentifier = source.bundleIdentifier, !bundleIdentifier.isEmpty else { return self }
        var updated = self
        updated.ignoredBundleIdentifiers.insert(bundleIdentifier)
        return updated
    }

    public func allowingBundleIdentifier(_ bundleIdentifier: String) -> ClipboardCapturePolicy {
        var updated = self
        updated.ignoredBundleIdentifiers.remove(bundleIdentifier)
        return updated
    }

    public static func isPasswordManager(_ source: ClipboardSourceApp) -> Bool {
        let bundle = source.bundleIdentifier?.lowercased() ?? ""
        let name = source.name.lowercased()
        let knownBundleFragments = [
            "1password",
            "bitwarden",
            "dashlane",
            "lastpass",
            "keeper",
            "keepass",
            "enpass",
            "nordpass",
            "roboform",
            "secrets",
            "password",
            "proton.pass"
        ]
        let knownNameFragments = [
            "1password",
            "bitwarden",
            "dashlane",
            "lastpass",
            "keeper",
            "keepass",
            "enpass",
            "nordpass",
            "roboform",
            "password manager",
            "proton pass"
        ]
        return knownBundleFragments.contains { bundle.contains($0) } ||
            knownNameFragments.contains { name.contains($0) }
    }

    public static func isPrivateBrowsing(_ source: ClipboardSourceApp) -> Bool {
        let title = source.windowTitle?.lowercased() ?? ""
        guard !title.isEmpty else { return false }
        let markers = [
            "private browsing",
            "private window",
            "private tab",
            "incognito",
            "inprivate",
            "隐身",
            "无痕",
            "私密浏览"
        ]
        return markers.contains { title.contains($0) }
    }

    public static func containsSensitiveContent(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let lower = trimmed.lowercased()

        if lower.contains("-----begin ") && lower.contains(" private key-----") { return true }
        if lower.contains("-----begin openSSH private key-----".lowercased()) { return true }
        if lower.contains("password=") || lower.contains("passwd=") || lower.contains("pwd=") { return true }
        if lower.contains("secret_key") || lower.contains("client_secret") || lower.contains("access_token") || lower.contains("refresh_token") { return true }

        let compact = trimmed.replacingOccurrences(of: " ", with: "")
        if compact.range(of: #"(?i)(verification|verify|otp|code|验证码|校验码|动态码).{0,24}\d{4,8}"#, options: .regularExpression) != nil {
            return true
        }
        if compact.range(of: #"(?i)\b(otp|mfa|2fa)[-_:]?\d{4,8}\b"#, options: .regularExpression) != nil {
            return true
        }
        if trimmed.range(of: #"(?i)\b(sk|pk|rk|ghp|github_pat|xox[baprs])-[-_A-Za-z0-9]{20,}\b"#, options: .regularExpression) != nil {
            return true
        }
        if trimmed.range(of: #"(?i)\b[A-Za-z0-9_]*(api[_-]?key|auth[_-]?token|secret|token)[A-Za-z0-9_]*\s*[:=]\s*['"]?[-_A-Za-z0-9./+=]{16,}"#, options: .regularExpression) != nil {
            return true
        }
        if trimmed.range(of: #"(?i)\b[A-Za-z0-9._%+-]+:[^\s:@]{8,}@[^\s]+"#, options: .regularExpression) != nil {
            return true
        }
        return false
    }
}
