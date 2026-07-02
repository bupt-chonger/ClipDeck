import AppKit
import ClipDeckCore
import SwiftUI

struct FloatingClipboardView: View {
    @Bindable var library: ClipboardLibrary
    let store: LibrarySnapshotStore
    @Bindable var animationState: FloatingClipboardAnimationState
    @AppStorage(AppLanguagePreferenceStore.defaultsKey) private var languageRawValue = AppLanguagePreferenceStore().load().rawValue
    let close: () -> Void
    let pasteIntoTargetApplication: () -> Void
    let openSettings: (ClipItem?) -> Void
    @State private var selectedFilter: ClipboardFilter = .history
    @State private var selectedItemID: ClipItem.ID?
    @State private var query = ""
    @State private var isSearchVisible = false
    @State private var isPinboardCreatorVisible = false
    @State private var pinboardDraft = ShelfPinboardCreationDraft()
    @State private var pendingPinboardItemID: ClipItem.ID?
    @State private var editingPinboardID: String?
    @State private var keyMonitor: Any?
    @FocusState private var isSearchFocused: Bool
    @FocusState private var isPinboardNameFocused: Bool
    @Namespace private var toolbarSelectionNamespace

    private var language: AppLanguagePreference {
        AppLanguagePreference(rawValue: languageRawValue) ?? .simplifiedChinese
    }

    private var strings: AppStrings {
        AppStrings(language)
    }

    private var items: [ClipItem] {
        library.shelfItems(query: query, filter: selectedFilter)
    }

    private var isSearching: Bool {
        isSearchVisible || !query.isEmpty
    }

    private var selectedItem: ClipItem? {
        items.first { $0.id == selectedItemID }
    }

    private var toolbarMorphAnimation: Animation {
        .interactiveSpring(
            response: ShelfToolbarAnimationStyle.response,
            dampingFraction: ShelfToolbarAnimationStyle.dampingFraction,
            blendDuration: ShelfToolbarAnimationStyle.blendDuration
        )
    }

    private var pinboardAssignmentAnimation: Animation {
        .interactiveSpring(
            response: ShelfCardInteractionAnimationStyle.pinboardAssignmentResponse,
            dampingFraction: ShelfCardInteractionAnimationStyle.pinboardAssignmentDampingFraction,
            blendDuration: ShelfCardInteractionAnimationStyle.pinboardAssignmentBlendDuration
        )
    }

    var body: some View {
        GeometryReader { proxy in
            shelfContent
                .offset(y: animationState.isPresented ? 0 : proxy.size.height)
                .opacity(animationState.isPresented ? 1 : 0)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
        .background(Color.clear)
        .clipped()
        .onAppear {
            installKeyMonitor()
            if animationState.isPresented {
                selectedItemID = nil
                focusSearchField()
            }
        }
        .onDisappear {
            removeKeyMonitor()
        }
        .onChange(of: animationState.isPresented) { _, isPresented in
            if isPresented {
                selectedItemID = nil
                focusSearchField()
            } else {
                selectedItemID = nil
            }
        }
    }

    private var shelfContent: some View {
        VStack(spacing: 14) {
            shelfToolbar

            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: ShelfCardLayout.cardSpacing) {
                        ForEach(items) { item in
                            ShelfClipCard(
                                item: item,
                                isSelected: selectedItemID == item.id,
                                select: { select(item) },
                                paste: { paste(item) },
                                pastePlainText: { pastePlainText(item) },
                                copy: { copy(item) },
                                edit: { edit(item) },
                                rename: { rename(item) },
                                delete: { delete(item) },
                                pinboards: library.pinboards,
                                pinboardName: library.pinboardName(for: item),
                                saveToPinboard: { pinboard in save(item, to: pinboard) },
                                createPinboard: { showPinboardCreator(attaching: item) },
                                quickLook: { quickLook(item) },
                                share: { share(item) },
                                strings: strings
                            )
                            .id(item.id)
                        }
                    }
                    .padding(.horizontal, ShelfCardLayout.horizontalContentInset)
                    .padding(.bottom, 22)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(y: ShelfToolbarAnimationStyle.contentSwitchOffset)),
                            removal: .opacity
                        )
                    )
                    .id(selectedFilter)
                }
                .scrollIndicators(.hidden)
                .animation(toolbarMorphAnimation, value: selectedFilter)
                .onChange(of: selectedItemID) { _, itemID in
                    scrollToSelectedItem(itemID, using: scrollProxy)
                }
                .onChange(of: items) { _, _ in
                    scrollToSelectedItem(selectedItemID, using: scrollProxy)
                }
            }
        }
        .padding(.top, 18)
        .onDeleteCommand {
            deleteSelected()
        }
        .onChange(of: items) { _, newItems in
            if let selectedItemID, newItems.contains(where: { $0.id == selectedItemID }) {
                return
            }
            selectedItemID = nil
        }
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: ShelfWindowChrome.cornerRadius,
                topTrailingRadius: ShelfWindowChrome.cornerRadius
            )
                .fill(.ultraThinMaterial)
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: ShelfWindowChrome.cornerRadius,
                        topTrailingRadius: ShelfWindowChrome.cornerRadius
                    )
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(ShelfGlassStyle.panelHighlightOpacity),
                                    .white.opacity(ShelfGlassStyle.panelMidHighlightOpacity),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                }
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: ShelfWindowChrome.cornerRadius,
                        topTrailingRadius: ShelfWindowChrome.cornerRadius
                    )
                        .stroke(Color.white.opacity(ShelfGlassStyle.panelStrokeOpacity), lineWidth: 1)
                }
        }
    }

    private var shelfToolbar: some View {
        ZStack {
            HStack {
                Spacer()
                Button {
                    openSettings(items.first)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.primary.opacity(0.72))
                        .frame(width: 34, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(strings.settings)
            }

            HStack(spacing: 18) {
                Button {
                    toggleSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3.weight(.medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isSearching ? AnyShapeStyle(.primary) : AnyShapeStyle(.primary.opacity(0.72)))
                        .frame(width: 26, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(strings.search)

                TextField(strings.searchClips, text: $query)
                    .textFieldStyle(.plain)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.primary)
                    .focused($isSearchFocused)
                    .frame(width: isSearching ? 180 : 1, height: 28)
                    .opacity(isSearching ? 1 : ShelfToolbarAnimationStyle.collapsedOpacity)
                    .scaleEffect(x: isSearching ? 1 : ShelfToolbarAnimationStyle.collapsedScale, y: 1, anchor: .leading)
                    .padding(.horizontal, isSearching ? 10 : 0)
                    .background(isSearching ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.clear), in: Capsule())
                    .background(isSearching ? AnyShapeStyle(.primary.opacity(ShelfGlassStyle.searchFieldTintOpacity)) : AnyShapeStyle(.clear), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(isSearching ? Color.primary.opacity(0.08) : .clear, lineWidth: 1)
                    }
                    .animation(toolbarMorphAnimation, value: isSearching)
                    .onChange(of: query) { _, newValue in
                        if !newValue.isEmpty {
                            isSearchVisible = true
                        }
                    }
                    .onExitCommand {
                        handleEscape()
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
                        focusSearchField()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.callout.weight(.semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(strings.clearSearch)
                }

                toolbarFilterButton(.history)

                ForEach(library.pinboards) { pinboard in
                    toolbarFilterButton(.pinboard(pinboard.id))
                }

                inlinePinboardCreator

                Button {
                    showPinboardCreator()
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.primary.opacity(0.72))
                        .frame(width: 24, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(strings.addPinboard)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .animation(toolbarMorphAnimation, value: isSearching)
            .animation(toolbarMorphAnimation, value: isPinboardCreatorVisible)
        }
        .padding(.horizontal, 28)
        .frame(height: 36)
    }

    private var inlinePinboardCreator: some View {
        HStack(spacing: ShelfPinboardCreatorLayout.sectionSpacing) {
            HStack(spacing: ShelfPinboardCreatorLayout.colorChoiceSpacing) {
                ForEach(ShelfPinboardCreationDraft.colorOptions) { option in
                    Button {
                        pinboardDraft.colorHex = option.hex
                        focusPinboardNameField()
                    } label: {
                        Circle()
                            .fill(Color(hex: option.hex))
                            .frame(width: ShelfPinboardCreatorLayout.colorChoiceSize, height: ShelfPinboardCreatorLayout.colorChoiceSize)
                            .overlay {
                                Circle()
                                    .stroke(pinboardDraft.colorHex == option.hex ? Color.primary.opacity(0.68) : Color.white.opacity(0.22), lineWidth: pinboardDraft.colorHex == option.hex ? 2 : 1)
                            }
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(option.name)
                }
            }

            TextField(strings.pinboardPlaceholder, text: $pinboardDraft.name)
                .textFieldStyle(.plain)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .focused($isPinboardNameFocused)
                .frame(width: ShelfPinboardCreatorLayout.textFieldWidth, height: 24)
                .onSubmit {
                    commitPinboardCreator()
                }
                .onExitCommand {
                    cancelPinboardEditor()
                }

            Button {
                commitPinboardCreator()
            } label: {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(pinboardDraft.canCreate ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                    .frame(width: ShelfPinboardCreatorLayout.confirmButtonWidth, height: 22)
            }
            .buttonStyle(.plain)
            .disabled(!pinboardDraft.canCreate)
            .help(editingPinboardID == nil ? strings.createPinboard : strings.renamePinboard)

            Button {
                cancelPinboardEditor()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .frame(width: ShelfPinboardCreatorLayout.cancelButtonWidth, height: 22)
            }
            .buttonStyle(.plain)
            .help(strings.cancel)
        }
        .frame(width: isPinboardCreatorVisible ? ShelfPinboardCreatorLayout.expandedWidth : ShelfPinboardCreatorLayout.collapsedWidth, height: ShelfPinboardCreatorLayout.height)
        .opacity(isPinboardCreatorVisible ? 1 : ShelfToolbarAnimationStyle.collapsedOpacity)
        .scaleEffect(x: isPinboardCreatorVisible ? 1 : ShelfToolbarAnimationStyle.collapsedScale, y: 1, anchor: .leading)
        .padding(.leading, isPinboardCreatorVisible ? ShelfPinboardCreatorLayout.leadingPadding : 0)
        .padding(.trailing, isPinboardCreatorVisible ? ShelfPinboardCreatorLayout.trailingPadding : 0)
        .padding(.vertical, isPinboardCreatorVisible ? ShelfPinboardCreatorLayout.verticalPadding : 0)
        .background(isPinboardCreatorVisible ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.clear), in: Capsule())
        .background(isPinboardCreatorVisible ? AnyShapeStyle(Color.primary.opacity(ShelfGlassStyle.searchFieldTintOpacity)) : AnyShapeStyle(.clear), in: Capsule())
        .overlay {
            Capsule()
                .stroke(isPinboardCreatorVisible ? Color.primary.opacity(0.08) : .clear, lineWidth: 1)
        }
        .clipped()
        .fixedSize(horizontal: true, vertical: false)
        .allowsHitTesting(isPinboardCreatorVisible)
        .animation(toolbarMorphAnimation, value: isPinboardCreatorVisible)
    }

    private func toolbarFilterButton(_ filter: ClipboardFilter) -> some View {
        let isSelected = selectedFilter == filter

        return Button {
            withAnimation(toolbarMorphAnimation) {
                selectedFilter = filter
            }
            focusSearchField()
        } label: {
            HStack(spacing: 6) {
                switch filter {
                case .board(.all):
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                case .board:
                    EmptyView()
                case .pinboard(let pinboardID):
                    Circle()
                        .fill(color(for: pinboardID))
                        .frame(width: 9, height: 9)
                }
                Text(title(for: filter))
                    .font(.caption.weight(isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            .padding(.horizontal, isSelected ? 10 : 0)
            .padding(.vertical, isSelected ? 5 : 0)
            .background {
                if isSelected {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule()
                                .fill(Color.primary.opacity(ShelfGlassStyle.selectedFilterTintOpacity))
                        }
                        .overlay {
                            Capsule()
                                .stroke(Color.primary.opacity(0.075), lineWidth: 1)
                        }
                        .matchedGeometryEffect(id: "selected-toolbar-filter", in: toolbarSelectionNamespace)
                }
            }
            .scaleEffect(isSelected ? 1 : ShelfToolbarAnimationStyle.unselectedFilterScale)
            .contentShape(Rectangle())
            .animation(toolbarMorphAnimation, value: isSelected)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isSelected, case .pinboard(let pinboardID) = filter {
                Button {
                    showPinboardRenamer(id: pinboardID)
                } label: {
                    Label(strings.renamePinboard, systemImage: "rectangle.and.pencil.and.ellipsis")
                }

                Button(role: .destructive) {
                    deletePinboard(id: pinboardID)
                } label: {
                    Label(strings.deletePinboard, systemImage: "trash")
                }
            }
        }
    }

    private func toggleSearch() {
        if isSearching {
            collapseSearch()
        } else {
            let expansion = ShelfToolbarExpansion.resolveOpeningSearch(isPinboardCreatorVisible: isPinboardCreatorVisible)
            withAnimation(toolbarMorphAnimation) {
                if expansion == .showSearchAndHidePinboardCreator {
                    isPinboardCreatorVisible = false
                    isPinboardNameFocused = false
                    pinboardDraft = ShelfPinboardCreationDraft()
                    pendingPinboardItemID = nil
                    editingPinboardID = nil
                }
                isSearchVisible = true
            }
            focusSearchField()
        }
    }

    private func handleEscape() {
        switch ShelfEscapeAction.resolve(isSearching: isSearching) {
        case .collapseSearch:
            collapseSearch()
        case .closeShelf:
            close()
        }
    }

    private func collapseSearch() {
        withAnimation(toolbarMorphAnimation) {
            query = ""
            isSearchVisible = false
            isSearchFocused = false
        }
    }

    private func focusSearchField() {
        DispatchQueue.main.async {
            isSearchFocused = true
        }
    }

    private func focusPinboardNameField() {
        DispatchQueue.main.async {
            isPinboardNameFocused = true
        }
    }

    private func scrollToSelectedItem(_ itemID: ClipItem.ID?, using proxy: ScrollViewProxy) {
        guard let itemID else { return }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: ShelfCardInteractionAnimationStyle.scrollDuration)) {
                proxy.scrollTo(itemID, anchor: .center)
            }
        }
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard animationState.isPresented else { return event }
            if event.keyCode == 53 {
                if isPinboardCreatorVisible {
                    cancelPinboardEditor()
                    return nil
                }
                handleEscape()
                return nil
            }
            if isPinboardCreatorVisible {
                return event
            }
            if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers?.lowercased() == "c" {
                guard query.isEmpty, let selectedItem else { return event }
                copy(selectedItem)
                return nil
            }
            if event.keyCode == 123 || event.keyCode == 124 {
                guard query.isEmpty else { return event }
                moveSelection(event.keyCode == 123 ? .left : .right)
                return nil
            }
            guard event.keyCode == 51 || event.keyCode == 117 else { return event }
            guard query.isEmpty, selectedItem != nil else { return event }
            deleteSelected()
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func select(_ item: ClipItem) {
        switch ShelfItemClickAction.resolve(clickedID: item.id, selectedID: selectedItemID) {
        case .select:
            selectedItemID = item.id
            focusSearchField()
        case .paste:
            paste(item)
        }
    }

    private func moveSelection(_ direction: ShelfSelectionNavigationDirection) {
        selectedItemID = ShelfSelectionNavigation.move(
            direction,
            selectedID: selectedItemID,
            itemIDs: items.map(\.id)
        )
        focusSearchField()
    }

    private func delete(_ item: ClipItem) {
        library.remove(item)
        store.save(library)
        selectedItemID = nil
        focusSearchField()
    }

    private func deleteSelected() {
        guard let selectedItem else { return }
        delete(selectedItem)
    }

    private func showPinboardCreator(attaching item: ClipItem? = nil) {
        pendingPinboardItemID = item?.id
        editingPinboardID = nil
        if !isPinboardCreatorVisible || editingPinboardID != nil {
            pinboardDraft = ShelfPinboardCreationDraft()
        }
        openPinboardEditor()
    }

    private func showPinboardRenamer(id pinboardID: String) {
        guard let pinboard = library.pinboards.first(where: { $0.id == pinboardID }) else {
            focusSearchField()
            return
        }
        pendingPinboardItemID = nil
        editingPinboardID = pinboardID
        pinboardDraft = ShelfPinboardCreationDraft(pinboard: pinboard)
        openPinboardEditor()
    }

    private func openPinboardEditor() {
        let expansion = ShelfToolbarExpansion.resolveOpeningPinboardCreator(isSearching: isSearching)
        withAnimation(toolbarMorphAnimation) {
            if expansion == .showPinboardCreatorAndHideSearch {
                query = ""
                isSearchVisible = false
            }
            isPinboardCreatorVisible = true
            isSearchFocused = false
        }
        focusPinboardNameField()
    }

    private func commitPinboardCreator() {
        guard let request = pinboardDraft.request else {
            focusPinboardNameField()
            return
        }

        if let editingPinboardID {
            guard let updated = library.updatePinboard(id: editingPinboardID, name: request.name, colorHex: request.colorHex) else {
                focusPinboardNameField()
                return
            }
            selectedFilter = .pinboard(updated.id)
            store.save(library)
            cancelPinboardEditor(refocusSearch: true)
            return
        }

        guard let pinboard = library.createPinboard(name: request.name, colorHex: request.colorHex) else {
            focusPinboardNameField()
            return
        }
        withAnimation(pinboardAssignmentAnimation) {
            if let itemID = pendingPinboardItemID, let item = library.items.first(where: { $0.id == itemID }) {
                library.save(item, toPinboard: pinboard.id)
                selectedItemID = item.id
            }
            selectedFilter = .pinboard(pinboard.id)
        }
        store.save(library)
        cancelPinboardEditor(refocusSearch: true)
    }

    private func cancelPinboardEditor(refocusSearch: Bool = true) {
        withAnimation(toolbarMorphAnimation) {
            isPinboardCreatorVisible = false
            isPinboardNameFocused = false
            pinboardDraft = ShelfPinboardCreationDraft()
            pendingPinboardItemID = nil
            editingPinboardID = nil
        }
        if refocusSearch {
            focusSearchField()
        }
    }

    private func save(_ item: ClipItem, to pinboard: UserPinboard) {
        withAnimation(pinboardAssignmentAnimation) {
            library.save(item, toPinboard: pinboard.id)
            selectedItemID = item.id
        }
        store.save(library)
        focusSearchField()
    }

    private func deletePinboard(id pinboardID: String) {
        guard let pinboard = library.pinboards.first(where: { $0.id == pinboardID }) else {
            focusSearchField()
            return
        }
        guard confirmDeletePinboard(pinboard) else {
            focusSearchField()
            return
        }
        library.deletePinboard(id: pinboardID)
        selectedFilter = .history
        selectedItemID = nil
        store.save(library)
        focusSearchField()
    }

    private func edit(_ item: ClipItem) {
        guard !item.hasImagePreview, let content = promptForText(title: strings.edit, message: strings.editClipMessage(), value: item.content, multiline: true) else {
            focusSearchField()
            return
        }
        library.replace(item, content: content)
        store.save(library)
        selectedItemID = item.id
        focusSearchField()
    }

    private func rename(_ item: ClipItem) {
        guard let name = promptForText(title: strings.rename, message: strings.renameClipMessage(), value: item.title, multiline: false) else {
            focusSearchField()
            return
        }
        library.rename(item, to: name)
        store.save(library)
        selectedItemID = item.id
        focusSearchField()
    }

    private func copy(_ item: ClipItem) {
        writeToPasteboard(item)
        close()
    }

    private func paste(_ item: ClipItem) {
        writeToPasteboard(item)
        pasteIntoTargetApplication()
    }

    private func pastePlainText(_ item: ClipItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
        pasteIntoTargetApplication()
    }

    private func writeToPasteboard(_ item: ClipItem) {
        if PasteboardImageTransfer.write(item, to: .general) {
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
    }

    private func quickLook(_ item: ClipItem) {
        if let url = temporaryPreviewURL(for: item) {
            NSWorkspace.shared.open(url)
        }
        focusSearchField()
    }

    private func share(_ item: ClipItem) {
        let pickerItems: [Any]
        if let url = temporaryPreviewURL(for: item) {
            pickerItems = [url]
        } else {
            pickerItems = [item.content]
        }
        let picker = NSSharingServicePicker(items: pickerItems)
        picker.show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
        focusSearchField()
    }

    private func temporaryPreviewURL(for item: ClipItem) -> URL? {
        let directory = FileManager.default.temporaryDirectory.appending(path: "ClipDeckPreview", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if let imageData = item.imageData {
            let ext = item.imagePasteboardType?.contains("png") == true ? "png" : "tiff"
            let url = directory.appending(path: "\(item.id.uuidString).\(ext)")
            try? imageData.write(to: url, options: .atomic)
            return url
        }
        let url = directory.appending(path: "\(item.id.uuidString).txt")
        try? item.content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func promptForText(title: String, message: String, value: String, multiline: Bool) -> String? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: strings.save)
        alert.addButton(withTitle: strings.cancel)

        let textView: NSView
        let getter: () -> String
        if multiline {
            let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 320, height: 120))
            let text = NSTextView(frame: scrollView.bounds)
            text.string = value
            text.isVerticallyResizable = true
            scrollView.documentView = text
            scrollView.hasVerticalScroller = true
            textView = scrollView
            getter = { text.string }
        } else {
            let text = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
            text.stringValue = value
            textView = text
            getter = { text.stringValue }
        }
        alert.accessoryView = textView

        let response = alert.runModal()
        let text = getter().trimmingCharacters(in: .whitespacesAndNewlines)
        guard response == .alertFirstButtonReturn, !text.isEmpty else { return nil }
        return text
    }

    private func confirmDeletePinboard(_ pinboard: UserPinboard) -> Bool {
        let count = library.items.filter { $0.pinboardID == pinboard.id }.count
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = strings.deletePinboardQuestion(pinboard.name)
        alert.informativeText = strings.deletePinboardMessage(count: count)
        alert.addButton(withTitle: strings.delete)
        alert.addButton(withTitle: strings.cancel)
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func title(for filter: ClipboardFilter) -> String {
        switch filter {
        case .board(let board):
            strings.boardTitle(board)
        case .pinboard(let pinboardID):
            library.pinboards.first { $0.id == pinboardID }?.name ?? strings.pinboardFallback
        }
    }

    private func color(for pinboardID: String) -> Color {
        guard let pinboard = library.pinboards.first(where: { $0.id == pinboardID }) else {
            return AppPalette.teal
        }
        return Color(hex: pinboard.colorHex)
    }
}

private extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard trimmed.count == 6, let value = Int(trimmed, radix: 16) else {
            self = AppPalette.teal
            return
        }
        self = Color(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }
}

private struct ShelfClipCard: View {
    let item: ClipItem
    let isSelected: Bool
    let select: () -> Void
    let paste: () -> Void
    let pastePlainText: () -> Void
    let copy: () -> Void
    let edit: () -> Void
    let rename: () -> Void
    let delete: () -> Void
    let pinboards: [UserPinboard]
    let pinboardName: String
    let saveToPinboard: (UserPinboard) -> Void
    let createPinboard: () -> Void
    let quickLook: () -> Void
    let share: () -> Void
    let strings: AppStrings

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: ShelfCardLayout.bodyTopOffset)
                cardBody
                    .frame(width: ShelfCardLayout.cardWidth, height: ShelfCardLayout.bodyHeight)
                    .clipped()
            }
                .zIndex(ShelfCardLayout.bodyZIndex)

            cardHeader
                .zIndex(ShelfCardLayout.headerZIndex)
        }
        .frame(width: ShelfCardLayout.cardWidth, height: ShelfCardLayout.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                    isSelected ? Color.accentColor.opacity(ShelfGlassStyle.selectedCardStrokeOpacity) : Color.white.opacity(ShelfGlassStyle.cardStrokeOpacity),
                    lineWidth: isSelected ? 2.5 : 1
                )
        }
        .shadow(color: .black.opacity(isSelected ? ShelfGlassStyle.selectedCardShadowOpacity : ShelfGlassStyle.cardShadowOpacity), radius: isSelected ? 22 : 14, y: isSelected ? 10 : 6)
        .scaleEffect(isSelected ? 1.025 : 1)
        .animation(
            .interactiveSpring(
                response: ShelfCardInteractionAnimationStyle.selectionResponse,
                dampingFraction: ShelfCardInteractionAnimationStyle.selectionDampingFraction,
                blendDuration: ShelfCardInteractionAnimationStyle.selectionBlendDuration
            ),
            value: isSelected
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(count: 2) {
            paste()
        }
        .onTapGesture(perform: select)
        .contextMenu {
            Button(action: paste) {
                Label(strings.pasteTo(targetAppName), systemImage: "doc.on.clipboard")
            }

            Button(action: pastePlainText) {
                Label(strings.pasteAsPlainText, systemImage: "text.alignleft")
            }
            .disabled(item.hasImagePreview)

            Button(action: copy) {
                Label(strings.copy, systemImage: "doc.on.doc")
            }
            .keyboardShortcut("c", modifiers: .command)

            Divider()

            Button(action: edit) {
                Label(strings.edit, systemImage: "pencil")
            }
            .disabled(item.hasImagePreview)
            .keyboardShortcut("e", modifiers: .command)

            Button(action: rename) {
                Label(strings.rename, systemImage: "rectangle.and.pencil.and.ellipsis")
            }
            .keyboardShortcut("r", modifiers: .command)

            Button(role: .destructive, action: delete) {
                Label(strings.delete, systemImage: "trash")
            }

            Divider()

            Menu {
                if pinboards.isEmpty {
                    Text(strings.noPinboards)
                } else {
                    ForEach(pinboards) { pinboard in
                        Button {
                            saveToPinboard(pinboard)
                        } label: {
                            Label(pinboard.name, systemImage: item.pinboardID == pinboard.id ? "checkmark.circle.fill" : "circle.fill")
                        }
                    }
                }
                Divider()
                Button(action: createPinboard) {
                    Label(strings.createPinboard, systemImage: "plus")
                }
            } label: {
                Label(strings.pin, systemImage: "pin")
            }

            Divider()

            Button(action: quickLook) {
                Label(strings.quickLook, systemImage: "eye")
            }
            .keyboardShortcut(.space, modifiers: [])

            Menu {
                Button(action: share) {
                    Label(strings.shareEllipsis, systemImage: "square.and.arrow.up")
                }
            } label: {
                Label(strings.share, systemImage: "square.and.arrow.up")
            }
        }
    }

    private var cardHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(strings.kindLabel(item.kind))
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                Text(relativeAge)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .opacity(0.82)
            }
            Spacer()
            SourceAppIconView(
                item: item,
                iconSize: ShelfCardLayout.sourceIconSize,
                padding: ShelfCardLayout.sourceIconPadding,
                cornerRadius: 10
            )
        }
        .foregroundStyle(.white)
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .padding(.vertical, ShelfCardLayout.headerVerticalPadding)
        .frame(height: ShelfCardLayout.headerHeight, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .top)
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                headerColor.opacity(ShelfGlassStyle.cardHeaderTintOpacity)
                LinearGradient(
                    colors: [.white.opacity(ShelfGlassStyle.cardHeaderHighlightOpacity), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var cardBody: some View {
        ZStack(alignment: .bottom) {
            if item.hasImagePreview {
                ImagePreviewView(item: item)
                    .frame(width: ShelfCardLayout.cardWidth, height: ShelfCardLayout.bodyHeight)
                    .clipped()
                VStack(spacing: 6) {
                    Text(item.source)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.20), lineWidth: 1)
                        }
                    tagRow(foreground: .white, background: AnyShapeStyle(.thinMaterial))
                }
                .padding(.bottom, 10)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.preview)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                        .lineLimit(pinboardName.isEmpty ? 7 : 6)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    if !pinboardName.isEmpty {
                        tagRow(foreground: .secondary, background: AnyShapeStyle(.thinMaterial))
                            .padding(.bottom, 8)
                    }
                    HStack {
                        Spacer()
                        Text(strings.characters(item.content.count))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: ShelfCardLayout.cardWidth, height: ShelfCardLayout.bodyHeight)
        .clipped()
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Color(nsColor: .controlBackgroundColor)
                    .opacity(ShelfGlassStyle.cardBodyTintOpacity)
                LinearGradient(
                    colors: [.white.opacity(ShelfGlassStyle.cardBodyHighlightOpacity), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        }
    }

    private var targetAppName: String {
        guard let name = NSWorkspace.shared.frontmostApplication?.localizedName, !name.isEmpty, name != "ClipDeck" else {
            return strings.activeApp
        }
        return name
    }

    @ViewBuilder
    private func tagRow(foreground: Color, background: AnyShapeStyle) -> some View {
        if !pinboardName.isEmpty {
            HStack(spacing: 5) {
                Text(pinboardName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(background, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    }
            }
        }
    }

    private var relativeAge: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: strings.localeIdentifier())
        formatter.unitsStyle = .full
        return formatter.localizedString(for: item.updatedAt, relativeTo: Date())
    }

    private var headerColor: Color {
        switch item.kind {
        case .text: Color(red: 0.02, green: 0.53, blue: 0.96)
        case .link: AppPalette.mint
        case .image: Color(red: 1.0, green: 0.20, blue: 0.24)
        case .code: Color(red: 0.96, green: 0.68, blue: 0.00)
        case .color: Color(red: 0.62, green: 0.32, blue: 0.95)
        }
    }
}
