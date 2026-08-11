import AppKit
import Combine
import ClipDeckCore
import Foundation

@MainActor
final class ClipboardPoller {
    private var timerSubscription: AnyCancellable?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private let library: ClipboardLibrary
    private let store: LibrarySnapshotStore
    private let policyStore: ClipboardCapturePolicyStore
    private let retentionStore: ClipboardRetentionPreferenceStore
    private let contextMonitor: ClipboardContextMonitor

    init(
        library: ClipboardLibrary,
        store: LibrarySnapshotStore,
        policyStore: ClipboardCapturePolicyStore = ClipboardCapturePolicyStore(),
        retentionStore: ClipboardRetentionPreferenceStore = ClipboardRetentionPreferenceStore(),
        contextMonitor: ClipboardContextMonitor = ClipboardContextMonitor()
    ) {
        self.library = library
        self.store = store
        self.policyStore = policyStore
        self.retentionStore = retentionStore
        self.contextMonitor = contextMonitor
    }

    func start() {
        timerSubscription?.cancel()
        contextMonitor.start()
        timerSubscription = Timer.publish(
            every: 0.8,
            tolerance: 0.12,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    func stop() {
        timerSubscription?.cancel()
        timerSubscription = nil
        contextMonitor.stop()
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        if ClipboardWriteTracker.shared.consume(changeCount: lastChangeCount) {
            return
        }
        guard let sourceApp = contextMonitor.sourceApplication() else { return }
        guard sourceApp.bundleIdentifier != Bundle.main.bundleIdentifier else { return }

        let policy = policyStore.load()
        guard policy.shouldCaptureSource(sourceApp) else { return }

        for payload in ClipboardPasteboardBuilder.buildItems(from: pasteboard, sourceName: sourceApp.name) {
            if payload.kind == .image {
                guard policy.shouldCaptureImage(source: sourceApp) else { continue }
                guard let imageData = payload.imageData, let imageType = payload.imagePasteboardType else { continue }
                library.captureImage(
                    data: imageData,
                    pasteboardType: imageType,
                    source: sourceApp.name,
                    sourceBundleIdentifier: sourceApp.bundleIdentifier,
                    pasteboardRepresentations: payload.pasteboardRepresentations
                )
            } else {
                guard policy.shouldCaptureText(payload.content, source: sourceApp) else { continue }
                library.capture(
                    text: payload.content,
                    source: sourceApp.name,
                    sourceBundleIdentifier: sourceApp.bundleIdentifier,
                    kind: payload.kind,
                    pasteboardRepresentations: payload.pasteboardRepresentations
                )
            }

            trimLibraryToRetentionLimit()
            store.save(library)
        }
    }

    private func trimLibraryToRetentionLimit() {
        guard let maxItems = retentionStore.load().maxItems else { return }
        library.trimToMostRecent(maxItems: maxItems)
    }
}
