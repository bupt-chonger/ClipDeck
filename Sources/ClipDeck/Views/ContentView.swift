import AppKit
import ClipDeckCore
import SwiftUI

struct ContentView: View {
    @Bindable var library: ClipboardLibrary
    let store: LibrarySnapshotStore
    @State private var selectedBoard: Pinboard = .all
    @State private var selectedItemID: ClipItem.ID?
    @State private var query = ""
    @State private var poller: ClipboardPoller?

    private var filteredItems: [ClipItem] {
        library.filteredItems(query: query, board: selectedBoard)
    }

    private var selectedItem: ClipItem? {
        filteredItems.first { $0.id == selectedItemID } ?? filteredItems.first
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedBoard: $selectedBoard,
                counts: Dictionary(uniqueKeysWithValues: Pinboard.allCases.map { ($0, library.count(for: $0)) })
            )
        } detail: {
            VStack(spacing: 0) {
                HeaderView(query: $query)
                Divider()
                ClipCarouselView(
                    items: filteredItems,
                    selectedItemID: $selectedItemID,
                    onCopy: copy,
                    onDelete: delete
                )
                Divider()
                if let selectedItem {
                    InspectorView(
                        item: selectedItem,
                        onCopy: copy,
                        onDelete: delete,
                        onSave: edit
                    )
                } else {
                    EmptyStateView()
                }
            }
            .background(AppPalette.canvas)
        }
        .navigationTitle("ClipDeck")
        .task {
            let newPoller = ClipboardPoller(library: library, store: store)
            poller = newPoller
            newPoller.start()
        }
        .onDisappear {
            poller?.stop()
        }
        .onChange(of: filteredItems) { _, newItems in
            if selectedItemID == nil || !newItems.contains(where: { $0.id == selectedItemID }) {
                selectedItemID = newItems.first?.id
            }
        }
    }

    private func copy(_ item: ClipItem) {
        if PasteboardImageTransfer.write(item, to: .general) {
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
    }

    private func delete(_ item: ClipItem) {
        library.remove(item)
        store.save(library)
    }

    private func edit(_ item: ClipItem, content: String) {
        library.replace(item, content: content)
        store.save(library)
    }
}
