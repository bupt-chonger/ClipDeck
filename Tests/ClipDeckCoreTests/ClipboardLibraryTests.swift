import Foundation
import CoreGraphics
import Testing
@testable import ClipDeckCore

@Suite("Clipboard library")
struct ClipboardLibraryTests {
    @Test("adding duplicate text refreshes existing item instead of creating another")
    func duplicateTextRefreshesExistingItem() {
        let library = ClipboardLibrary(now: { Date(timeIntervalSince1970: 100) })

        library.capture(text: "Quarterly pricing notes", source: "Notes", sourceBundleIdentifier: "com.apple.Notes")
        library.setNow { Date(timeIntervalSince1970: 200) }
        library.capture(text: "Quarterly pricing notes", source: "Safari", sourceBundleIdentifier: "com.apple.Safari")

        #expect(library.items.count == 1)
        #expect(library.items[0].source == "Safari")
        #expect(library.items[0].sourceBundleIdentifier == "com.apple.Safari")
        #expect(library.items[0].updatedAt == Date(timeIntervalSince1970: 200))
    }

    @Test("capturing duplicate image data refreshes one image item")
    func duplicateImageDataRefreshesExistingItem() {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let library = ClipboardLibrary(now: { Date(timeIntervalSince1970: 100) })

        library.captureImage(data: imageData, pasteboardType: "public.png", source: "Preview", sourceBundleIdentifier: "com.apple.Preview")
        library.setNow { Date(timeIntervalSince1970: 200) }
        library.captureImage(data: imageData, pasteboardType: "public.png", source: "Photos", sourceBundleIdentifier: "com.apple.Photos")

        #expect(library.items.count == 1)
        #expect(library.items[0].kind == .image)
        #expect(library.items[0].imageData == imageData)
        #expect(library.items[0].imagePasteboardType == "public.png")
        #expect(library.items[0].source == "Photos")
        #expect(library.items[0].sourceBundleIdentifier == "com.apple.Photos")
        #expect(library.items[0].updatedAt == Date(timeIntervalSince1970: 200))
    }

    @Test("snapshot store preserves image data")
    func snapshotStorePreservesImageData() {
        let imageData = Data([0x49, 0x49, 0x2A, 0x00])
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let store = LibrarySnapshotStore(fileURL: fileURL)
        let item = ClipItem(
            content: "Image from Clipboard",
            kind: .image,
            imageData: imageData,
            imagePasteboardType: "public.tiff"
        )

        store.save([item])
        let loaded = store.load()

        #expect(loaded.first?.imageData == imageData)
        #expect(loaded.first?.imagePasteboardType == "public.tiff")
        #expect(loaded.first?.kind == .image)
    }

    @Test("image preview is available only for image items with data")
    func imagePreviewAvailability() {
        let image = ClipItem(content: "Image", kind: .image, imageData: Data([1]), imagePasteboardType: "public.tiff")
        let placeholder = ClipItem(content: "Image", kind: .image)
        let text = ClipItem(content: "hello", kind: .text, imageData: Data([1]), imagePasteboardType: "public.tiff")

        #expect(image.hasImagePreview)
        #expect(!placeholder.hasImagePreview)
        #expect(!text.hasImagePreview)
    }

    @Test("renaming an image keeps image data and pasteboard type")
    func renamingImageKeepsImageData() {
        let imageData = Data([1, 2, 3])
        let item = ClipItem(content: "Screenshot", kind: .image, imageData: imageData, imagePasteboardType: "public.png")
        let library = ClipboardLibrary(seed: [item], now: { Date(timeIntervalSince1970: 250) })

        library.rename(item, to: "Design mockup")

        #expect(library.items.first?.content == "Design mockup")
        #expect(library.items.first?.kind == .image)
        #expect(library.items.first?.imageData == imageData)
        #expect(library.items.first?.imagePasteboardType == "public.png")
        #expect(library.items.first?.updatedAt == Date(timeIntervalSince1970: 250))
    }

    @Test("search matches title and content case insensitively")
    func searchMatchesTitleAndContent() {
        let library = ClipboardLibrary(seed: [
            ClipItem(content: "Launch checklist", source: "Notes"),
            ClipItem(content: "Invoice total USD 240", source: "Mail")
        ])

        #expect(library.filteredItems(query: "invoice").map(\.content) == ["Invoice total USD 240"])
        #expect(library.filteredItems(query: "notes").map(\.content) == ["Launch checklist"])
    }

    @Test("pinboard counts include all and semantic kinds")
    func pinboardCounts() {
        let image = ClipItem(content: "Screenshot 2026-06-29", kind: .image)
        let text = ClipItem(content: "Meeting note", kind: .text)
        let link = ClipItem(content: "https://pasteapp.io", kind: .link)
        let library = ClipboardLibrary(seed: [image, text, link])

        #expect(Pinboard.allCases == [.all, .links, .images, .code, .colors])
        #expect(library.count(for: .all) == 3)
        #expect(library.count(for: .images) == 1)
        #expect(library.count(for: .links) == 1)
    }

    @Test("shelf items apply search, board, and display limit")
    func shelfItemsApplySearchBoardAndLimit() {
        let library = ClipboardLibrary(seed: [
            ClipItem(content: "func pasteLatest() {}", source: "Xcode", kind: .code, updatedAt: Date(timeIntervalSince1970: 200)),
            ClipItem(content: "func copyLatest() {}", source: "Xcode", kind: .code, updatedAt: Date(timeIntervalSince1970: 100)),
            ClipItem(content: "Meeting notes", source: "Notes", kind: .text, updatedAt: Date(timeIntervalSince1970: 300)),
            ClipItem(content: "https://pasteapp.io", source: "Safari", kind: .link, updatedAt: Date(timeIntervalSince1970: 400))
        ])

        let results = library.shelfItems(query: "func", board: .code, limit: 1)

        #expect(results.map(\.content) == ["func pasteLatest() {}"])
    }

    @Test("removing app records matches bundle identifier before source name")
    func removeAppRecordsMatchesBundleBeforeSource() {
        let library = ClipboardLibrary(seed: [
            ClipItem(content: "Safari link", source: "Safari", sourceBundleIdentifier: "com.apple.Safari"),
            ClipItem(content: "Safari note", source: "Safari", sourceBundleIdentifier: "com.example.Other"),
            ClipItem(content: "Notes memo", source: "Notes")
        ])

        let removedByBundle = library.removeAppRecords(source: "Safari", sourceBundleIdentifier: "com.apple.Safari")
        let removedBySource = library.removeAppRecords(source: "Notes", sourceBundleIdentifier: nil)

        #expect(removedByBundle == 1)
        #expect(removedBySource == 1)
        #expect(library.items.map(\.content) == ["Safari note"])
    }

    @Test("clearing all records removes every item")
    func clearAllRecordsRemovesEveryItem() {
        let library = ClipboardLibrary(seed: [
            ClipItem(content: "Safari link", source: "Safari"),
            ClipItem(content: "Notes memo", source: "Notes")
        ])

        let removed = library.clearAll()

        #expect(removed == 2)
        #expect(library.items.isEmpty)
    }

    @Test("saving to a pinboard makes pinboard names searchable")
    func savingToPinboardMakesPinboardNamesSearchable() throws {
        let item = ClipItem(content: "Quarterly plan", source: "Notes")
        let library = ClipboardLibrary(seed: [item], now: { Date(timeIntervalSince1970: 300) })

        let pinboard = try #require(library.createPinboard(name: "  Work  ", colorHex: "#007AFF"))
        library.save(item, toPinboard: pinboard.id)

        #expect(library.items.first?.pinboardID == pinboard.id)
        #expect(library.items.first?.updatedAt == Date(timeIntervalSince1970: 300))
        #expect(library.filteredItems(query: "work").map(\.content) == ["Quarterly plan"])
    }

    @Test("snapshot store can distinguish a saved empty library from no snapshot")
    func snapshotStoreDistinguishesSavedEmptyLibrary() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let store = LibrarySnapshotStore(fileURL: fileURL)

        #expect(!store.hasSnapshot)

        store.save([])

        #expect(store.hasSnapshot)
        #expect(store.load().isEmpty)
    }

    @Test("keyboard shortcut preference round trips and displays symbols")
    func keyboardShortcutPreferenceRoundTrips() {
        let shortcut = KeyboardShortcutPreference(keyCode: 49, modifiers: KeyboardShortcutPreference.optionModifier)

        #expect(KeyboardShortcutPreference(rawValue: shortcut.rawValue) == shortcut)
        #expect(KeyboardShortcutPreference.default.rawValue == "49:2048")
        #expect(shortcut.displayString == "Option Space")
    }

    @Test("shelf click selects a new item and pastes the selected item")
    func shelfClickSelectsNewItemAndPastesSelectedItem() {
        let itemID = UUID()
        let otherID = UUID()

        #expect(ShelfItemClickAction.resolve(clickedID: itemID, selectedID: nil) == .select)
        #expect(ShelfItemClickAction.resolve(clickedID: itemID, selectedID: otherID) == .select)
        #expect(ShelfItemClickAction.resolve(clickedID: itemID, selectedID: itemID) == .paste)
        #expect(ShelfItemClickAction.resolveDoubleClick() == .paste)
    }

    @Test("paste shortcut waits until the shelf is hidden")
    func pasteShortcutWaitsUntilShelfIsHidden() {
        #expect(ShelfPasteTiming.shortcutDelay >= ShelfPasteTiming.hideAnimationDuration + ShelfPasteTiming.activationDelay)
    }

    @Test("opening the shelf checks accessibility without prompting")
    func openingShelfChecksAccessibilityWithoutPrompting() {
        #expect(!AccessibilityPermissionPromptPolicy.silent.shouldPromptSystemDialog)
        #expect(AccessibilityPermissionPromptPolicy.promptOnce(hasPrompted: false).shouldPromptSystemDialog)
        #expect(!AccessibilityPermissionPromptPolicy.promptOnce(hasPrompted: true).shouldPromptSystemDialog)
    }

    @Test("bottom shelf glass uses shaped shadow instead of the system rectangular window shadow")
    func bottomShelfGlassUsesShapedShadow() {
        #expect(!ShelfWindowChrome.usesSystemWindowShadow)
        #expect(!ShelfWindowChrome.usesOuterContentShadow)
        #expect(ShelfWindowChrome.cornerRadius == 26)
    }

    @Test("liquid glass styling stays translucent and layered")
    func liquidGlassStylingStaysTranslucentAndLayered() {
        #expect(ShelfGlassStyle.panelHighlightOpacity <= 0.14)
        #expect(ShelfGlassStyle.panelStrokeOpacity <= 0.18)
        #expect(ShelfGlassStyle.cardBodyTintOpacity <= 0.18)
        #expect(ShelfGlassStyle.cardBodyTintOpacity < ShelfGlassStyle.cardHeaderTintOpacity)
        #expect(ShelfGlassStyle.cardShadowOpacity <= 0.12)
        #expect(ShelfGlassStyle.selectedCardShadowOpacity <= 0.20)
    }

    @Test("shelf card keeps a fixed header and body layout for image previews")
    func shelfCardKeepsFixedHeaderAndBodyLayout() {
        #expect(ShelfCardLayout.cardHeight == ShelfCardLayout.headerHeight + ShelfCardLayout.bodyHeight)
        #expect(ShelfCardLayout.sourceIconContainerSize <= ShelfCardLayout.headerHeight - (ShelfCardLayout.headerVerticalPadding * 2))
        #expect(ShelfCardLayout.bodyTopOffset == ShelfCardLayout.headerHeight)
        #expect(ShelfCardLayout.headerZIndex > ShelfCardLayout.bodyZIndex)
    }

    @Test("image previews are clipped to the card body below the fixed header")
    func imagePreviewsAreClippedBelowTheFixedHeader() {
        #expect(ShelfCardLayout.bodyTopOffset >= ShelfCardLayout.headerHeight)
        #expect(ShelfCardLayout.bodyHeight == ShelfCardLayout.cardHeight - ShelfCardLayout.bodyTopOffset)
        #expect(ShelfCardLayout.bodyHeight > 0)
    }

    @Test("shelf carousel can show two complete cards in compact widths")
    func shelfCarouselCanShowTwoCompleteCardsInCompactWidths() {
        let twoCardWidth = (ShelfCardLayout.cardWidth * 2) + ShelfCardLayout.cardSpacing + (ShelfCardLayout.horizontalContentInset * 2)

        #expect(twoCardWidth <= ShelfCardLayout.compactTwoCardViewportWidth)
    }

    @Test("pinboard creator keeps color choices away from the leading edge")
    func pinboardCreatorKeepsColorChoicesAwayFromLeadingEdge() {
        #expect(ShelfPinboardCreatorLayout.leadingPadding >= 18)
        #expect(ShelfPinboardCreatorLayout.expandedWidth > 238)
        #expect(ShelfPinboardCreatorLayout.expandedWidth >= ShelfPinboardCreatorLayout.contentWidth)
        #expect(ShelfPinboardCreatorLayout.collapsedWidth == 1)
    }

    @Test("toolbar expansions are mutually exclusive")
    func toolbarExpansionsAreMutuallyExclusive() {
        #expect(ShelfToolbarExpansion.resolveOpeningSearch(isPinboardCreatorVisible: true) == .showSearchAndHidePinboardCreator)
        #expect(ShelfToolbarExpansion.resolveOpeningPinboardCreator(isSearching: true) == .showPinboardCreatorAndHideSearch)
        #expect(ShelfToolbarExpansion.resolveOpeningPinboardCreator(isSearching: false) == .showPinboardCreator)
    }

    @Test("toolbar glass expansion uses a gentle morph animation")
    func toolbarGlassExpansionUsesGentleMorphAnimation() {
        #expect(ShelfToolbarAnimationStyle.response >= 0.38)
        #expect(ShelfToolbarAnimationStyle.dampingFraction >= 0.90)
        #expect(ShelfToolbarAnimationStyle.blendDuration >= 0.10)
        #expect(ShelfToolbarAnimationStyle.collapsedScale < 1)
        #expect(ShelfToolbarAnimationStyle.collapsedOpacity == 0)
        #expect(ShelfToolbarAnimationStyle.unselectedFilterScale < 1)
        #expect(ShelfToolbarAnimationStyle.contentSwitchOffset > 0)
    }

    @Test("hide completions queued while hiding run after hide finishes")
    func hideCompletionsQueuedWhileHidingRunAfterHideFinishes() {
        var queue = ShelfHideCompletionQueue()
        var calls: [String] = []

        #expect(queue.beginHide(afterHide: { calls.append("first") }) == .startHide)
        #expect(queue.beginHide(afterHide: { calls.append("second") }) == .alreadyHiding)

        let completions = queue.finishHide()
        completions.forEach { $0() }

        #expect(calls == ["first", "second"])
    }

    @Test("escape collapses search before closing the shelf")
    func escapeCollapsesSearchBeforeClosingShelf() {
        #expect(ShelfEscapeAction.resolve(isSearching: true) == .collapseSearch)
        #expect(ShelfEscapeAction.resolve(isSearching: false) == .closeShelf)
    }

    @Test("shelf keyboard navigation moves selection left and right")
    func shelfKeyboardNavigationMovesSelectionLeftAndRight() {
        let firstID = UUID()
        let secondID = UUID()
        let thirdID = UUID()
        let ids = [firstID, secondID, thirdID]

        #expect(ShelfSelectionNavigation.move(.right, selectedID: nil, itemIDs: ids) == firstID)
        #expect(ShelfSelectionNavigation.move(.left, selectedID: secondID, itemIDs: ids) == firstID)
        #expect(ShelfSelectionNavigation.move(.right, selectedID: secondID, itemIDs: ids) == thirdID)
        #expect(ShelfSelectionNavigation.move(.left, selectedID: firstID, itemIDs: ids) == firstID)
        #expect(ShelfSelectionNavigation.move(.right, selectedID: thirdID, itemIDs: ids) == thirdID)
        #expect(ShelfSelectionNavigation.move(.right, selectedID: UUID(), itemIDs: ids) == firstID)
        #expect(ShelfSelectionNavigation.move(.right, selectedID: nil, itemIDs: []) == nil)
    }

    @Test("bottom shelf placement hugs the active screen bottom and full width")
    func bottomShelfPlacement() {
        let visibleFrame = CGRect(x: 1920, y: 40, width: 1440, height: 860)

        let frame = BottomShelfPlacement.panelFrame(in: visibleFrame)

        #expect(frame.minY == 40)
        #expect(frame.height == 340)
        #expect(frame.minX == 1920)
        #expect(frame.width == 1440)
    }
}
