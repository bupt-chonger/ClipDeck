import Foundation
import Testing
@testable import ClipDeckCore

@Suite("Clipboard pinboards")
struct ClipboardPinboardTests {
    @Test("creating pinboards trims duplicate names and stores a color")
    func creatingPinboardsStoresNameAndColor() {
        let library = ClipboardLibrary()

        let first = library.createPinboard(name: "  Research  ", colorHex: "#FF3B30")
        let duplicate = library.createPinboard(name: "research", colorHex: "#34C759")

        #expect(first?.name == "Research")
        #expect(first?.colorHex == "#FF3B30")
        #expect(duplicate == nil)
        #expect(library.pinboards.map(\.name) == ["Research"])
    }

    @Test("inline pinboard drafts trim names and require a non-empty value")
    func inlinePinboardDraftsTrimNamesAndRequireValue() {
        var draft = ShelfPinboardCreationDraft()

        #expect(draft.trimmedName.isEmpty)
        #expect(!draft.canCreate)

        draft.name = "  Design "
        draft.colorHex = "#AF52DE"

        #expect(draft.trimmedName == "Design")
        #expect(draft.canCreate)
        #expect(draft.request == UserPinboardCreationRequest(name: "Design", colorHex: "#AF52DE"))
    }


    @Test("pinboard drafts can prefill an existing pinboard for inline rename")
    func pinboardDraftsCanPrefillExistingPinboardForInlineRename() {
        let pinboard = UserPinboard(id: "work", name: "Work", colorHex: "#007AFF")

        let draft = ShelfPinboardCreationDraft(pinboard: pinboard)

        #expect(draft.name == "Work")
        #expect(draft.colorHex == "#007AFF")
        #expect(draft.request == UserPinboardCreationRequest(name: "Work", colorHex: "#007AFF"))
    }

    @Test("saving an item to a pinboard replaces its previous pinboard")
    func savingItemToPinboardReplacesPreviousPinboard() throws {
        let item = ClipItem(content: "Launch plan", source: "Notes")
        let library = ClipboardLibrary(seed: [item], now: { Date(timeIntervalSince1970: 500) })
        let work = try #require(library.createPinboard(name: "Work", colorHex: "#007AFF"))
        let design = try #require(library.createPinboard(name: "Design", colorHex: "#AF52DE"))

        library.save(item, toPinboard: work.id)
        library.save(item, toPinboard: design.id)

        #expect(library.items.first?.pinboardID == design.id)
        #expect(library.filteredItems(query: "", filter: .pinboard(work.id)).isEmpty)
        #expect(library.filteredItems(query: "", filter: .pinboard(design.id)).map(\.content) == ["Launch plan"])
        #expect(library.items.first?.updatedAt == Date(timeIntervalSince1970: 500))
    }

    @Test("saving an item to its current pinboard removes it from that pinboard")
    func savingItemToCurrentPinboardRemovesItFromPinboard() throws {
        let item = ClipItem(content: "Launch plan", source: "Notes")
        let library = ClipboardLibrary(seed: [item], now: { Date(timeIntervalSince1970: 700) })
        let work = try #require(library.createPinboard(name: "Work", colorHex: "#007AFF"))

        library.save(item, toPinboard: work.id)
        library.save(item, toPinboard: work.id)

        #expect(library.items.first?.pinboardID == nil)
        #expect(library.filteredItems(query: "", filter: .pinboard(work.id)).isEmpty)
        #expect(library.items.first?.updatedAt == Date(timeIntervalSince1970: 700))
    }

    @Test("renaming a pinboard keeps its clips attached")
    func renamingPinboardKeepsClipsAttached() throws {
        let item = ClipItem(content: "Launch plan", source: "Notes")
        let library = ClipboardLibrary(seed: [item])
        let work = try #require(library.createPinboard(name: "Work", colorHex: "#007AFF"))
        library.save(item, toPinboard: work.id)

        let renamed = library.renamePinboard(id: work.id, to: "  Projects  ")

        #expect(renamed?.id == work.id)
        #expect(renamed?.name == "Projects")
        #expect(library.pinboardName(for: library.items[0]) == "Projects")
        #expect(library.filteredItems(query: "", filter: .pinboard(work.id)).map(\.content) == ["Launch plan"])
    }


    @Test("updating a pinboard changes its name and color while keeping clips attached")
    func updatingPinboardChangesNameAndColorWhileKeepingClipsAttached() throws {
        let item = ClipItem(content: "Launch plan", source: "Notes")
        let library = ClipboardLibrary(seed: [item])
        let work = try #require(library.createPinboard(name: "Work", colorHex: "#007AFF"))
        library.save(item, toPinboard: work.id)

        let updated = library.updatePinboard(id: work.id, name: "  Projects  ", colorHex: "#AF52DE")

        #expect(updated?.name == "Projects")
        #expect(updated?.colorHex == "#AF52DE")
        #expect(library.pinboardName(for: library.items[0]) == "Projects")
        #expect(library.items[0].pinboardID == work.id)
    }

    @Test("deleting a pinboard removes every clip assigned to it")
    func deletingPinboardRemovesAssignedClips() throws {
        let workItem = ClipItem(content: "Launch plan", source: "Notes")
        let designItem = ClipItem(content: "Mockup", source: "Figma")
        let looseItem = ClipItem(content: "Loose", source: "Clipboard")
        let library = ClipboardLibrary(seed: [workItem, designItem, looseItem])
        let work = try #require(library.createPinboard(name: "Work", colorHex: "#007AFF"))
        let design = try #require(library.createPinboard(name: "Design", colorHex: "#AF52DE"))
        library.save(workItem, toPinboard: work.id)
        library.save(designItem, toPinboard: design.id)

        let removed = library.deletePinboard(id: work.id)

        #expect(removed == 1)
        #expect(!library.pinboards.contains(where: { $0.id == work.id }))
        #expect(library.pinboards.contains(where: { $0.id == design.id }))
        #expect(library.items.map(\.content).sorted() == ["Loose", "Mockup"])
    }

    @Test("legacy tags migrate into user pinboards")
    func legacyTagsMigrateIntoPinboards() {
        let item = ClipItem(content: "Existing clip", tags: ["Work", "Ideas"])
        let library = ClipboardLibrary(seed: [item], customTags: ["Design"])

        #expect(library.pinboards.map(\.name) == ["Design", "Ideas", "Work"])
        #expect(library.items.first?.pinboardID == "work")
    }
}
