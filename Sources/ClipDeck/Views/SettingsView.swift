import AppKit
import ClipDeckCore
import SwiftUI

struct SettingsView: View {
    @Bindable var environment: ClipDeckEnvironment
    @AppStorage(HotKeyPreferenceStore.defaultsKey) private var hotKeyRawValue = KeyboardShortcutPreference.default.rawValue
    @AppStorage(AppLanguagePreferenceStore.defaultsKey) private var languageRawValue = AppLanguagePreferenceStore().load().rawValue
    @State private var policy: ClipboardCapturePolicy = .default
    @State private var isRecordingShortcut = false
    @State private var isConfirmingDelete = false
    @State private var deletionMessage: String?

    private var language: AppLanguagePreference {
        AppLanguagePreference(rawValue: languageRawValue) ?? .simplifiedChinese
    }

    private var strings: AppStrings {
        AppStrings(language)
    }

    private var shortcut: KeyboardShortcutPreference {
        KeyboardShortcutPreference(rawValue: hotKeyRawValue) ?? .default
    }

    private var canIgnoreTargetApp: Bool {
        guard let bundleIdentifier = environment.settingsTargetBundleIdentifier, !bundleIdentifier.isEmpty else { return false }
        return !policy.ignoredBundleIdentifiers.contains(bundleIdentifier)
    }

    var body: some View {
        Form {
            Section(strings.languageSection) {
                Picker(strings.appLanguage, selection: $languageRawValue) {
                    ForEach(AppLanguagePreference.allCases) { language in
                        Text(language.displayName)
                            .tag(language.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: languageRawValue) { _, newValue in
                    if let language = AppLanguagePreference(rawValue: newValue) {
                        AppLanguagePreferenceStore().save(language)
                    }
                }
            }

            Section(strings.shortcutsSection) {
                HStack {
                    Text(strings.showHideClipboard)
                    Spacer()
                    ShortcutRecorderButton(
                        shortcut: shortcut,
                        isRecording: $isRecordingShortcut,
                        recordingTitle: strings.recordingShortcut,
                        helpText: strings.shortcutRecorderHelp,
                        onCapture: updateShortcut
                    )
                }
            }

            Section(strings.privacySection) {
                Toggle(strings.ignorePasswordManagers, isOn: policyBinding(\.ignoresPasswordManagers))
                    .help(strings.ignorePasswordManagersHelp)
                Toggle(strings.ignorePrivateBrowsing, isOn: policyBinding(\.ignoresPrivateBrowsing))
                    .help(strings.ignorePrivateBrowsingHelp)
                Toggle(strings.ignoreSensitiveContent, isOn: policyBinding(\.ignoresSensitiveContent))
                    .help(strings.ignoreSensitiveContentHelp)

                VStack(alignment: .leading, spacing: 6) {
                    Text(strings.privacyNote)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(strings.imagePrivacyNote)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section(strings.ignoredAppsSection) {
                Button {
                    ignoreTargetApp()
                } label: {
                    Label(strings.ignoreApp(environment.settingsTargetTitle), systemImage: "eye.slash")
                }
                .disabled(!canIgnoreTargetApp)

                if policy.ignoredBundleIdentifiers.isEmpty {
                    Text(strings.noIgnoredApps)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(policy.ignoredBundleIdentifiers).sorted(), id: \.self) { bundleIdentifier in
                        HStack(spacing: 10) {
                            AppIconForBundleView(bundleIdentifier: bundleIdentifier)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appName(for: bundleIdentifier))
                                    .font(.body)
                                Text(bundleIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                allow(bundleIdentifier: bundleIdentifier)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                            }
                            .buttonStyle(.plain)
                            .help(strings.removeFromIgnoredApps)
                        }
                    }
                }
            }

            Section(strings.clipboardRecordsSection) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.allRecords)
                        .font(.headline)
                    Text(strings.deleteAllDescription)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    if let deletionMessage {
                        Text(deletionMessage)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Text(strings.deleteAllRecords)
                }
                .disabled(environment.library?.items.isEmpty ?? true)
                .alert(strings.deleteAllRecordsQuestion, isPresented: $isConfirmingDelete) {
                    Button(strings.cancel, role: .cancel) {}
                    Button(strings.delete, role: .destructive) {
                        clearAllRecords()
                    }
                } message: {
                    Text(strings.deleteAllAlertMessage)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .background(.regularMaterial)
        .frame(width: 520)
        .onAppear {
            policy = environment.loadCapturePolicy()
        }
    }

    private func policyBinding(_ keyPath: WritableKeyPath<ClipboardCapturePolicy, Bool>) -> Binding<Bool> {
        Binding {
            policy[keyPath: keyPath]
        } set: { newValue in
            policy[keyPath: keyPath] = newValue
            environment.saveCapturePolicy(policy)
        }
    }

    private func ignoreTargetApp() {
        policy = environment.ignoreSettingsTargetApp()
    }

    private func allow(bundleIdentifier: String) {
        policy = environment.allowCaptureFromBundleIdentifier(bundleIdentifier)
    }

    private func appName(for bundleIdentifier: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return bundleIdentifier
        }
        return FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")
    }

    private func updateShortcut(_ shortcut: KeyboardShortcutPreference) {
        hotKeyRawValue = shortcut.rawValue
        HotKeyPreferenceStore.save(shortcut)
        environment.hotKeyMonitor?.start(shortcut: shortcut)
        isRecordingShortcut = false
    }

    private func clearAllRecords() {
        let count = environment.clearAllRecords()
        deletionMessage = strings.deletedRecords(count)
    }
}

private struct AppIconForBundleView: View {
    let bundleIdentifier: String

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "app.dashed")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 28, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private var image: NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}

private struct ShortcutRecorderButton: View {
    let shortcut: KeyboardShortcutPreference
    @Binding var isRecording: Bool
    let recordingTitle: String
    let helpText: String
    let onCapture: (KeyboardShortcutPreference) -> Void

    var body: some View {
        Button {
            isRecording = true
        } label: {
            Text(isRecording ? recordingTitle : shortcut.displayString)
                .monospacedDigit()
                .frame(minWidth: 150)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .background {
            ShortcutCaptureView(isRecording: $isRecording, onCapture: onCapture)
                .frame(width: 0, height: 0)
        }
        .help(helpText)
    }
}

private struct ShortcutCaptureView: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onCapture: (KeyboardShortcutPreference) -> Void

    func makeNSView(context: Context) -> RecorderView {
        let view = RecorderView()
        view.onCapture = onCapture
        return view
    }

    func updateNSView(_ nsView: RecorderView, context: Context) {
        nsView.onCapture = onCapture
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    final class RecorderView: NSView {
        var onCapture: ((KeyboardShortcutPreference) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            let modifiers = carbonModifiers(from: event.modifierFlags)
            guard modifiers != 0 else {
                NSSound.beep()
                return
            }
            onCapture?(KeyboardShortcutPreference(keyCode: UInt32(event.keyCode), modifiers: modifiers))
        }

        private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
            var modifiers: UInt32 = 0
            if flags.contains(.command) {
                modifiers |= KeyboardShortcutPreference.commandModifier
            }
            if flags.contains(.shift) {
                modifiers |= KeyboardShortcutPreference.shiftModifier
            }
            if flags.contains(.option) {
                modifiers |= KeyboardShortcutPreference.optionModifier
            }
            if flags.contains(.control) {
                modifiers |= KeyboardShortcutPreference.controlModifier
            }
            return modifiers
        }
    }
}
