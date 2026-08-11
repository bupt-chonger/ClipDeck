import CoreData
import Foundation

private final class SnapshotResultBox: @unchecked Sendable {
    var value: (items: [ClipItem], pinboards: [UserPinboard], customTags: [String])?
}

private final class BoolResultBox: @unchecked Sendable {
    var value = false
}

/// Core Data backed clipboard persistence with a legacy JSON import path.
///
/// The store deliberately keeps the old file as a fallback so existing
/// ClipDeck users do not lose history when upgrading from the JSON format.
/// CloudKit is opt-in because a real container identifier and iCloud
/// entitlements must be supplied by the app distribution configuration.
public final class LibrarySnapshotStore: @unchecked Sendable {
    public static let cloudKitContainerIdentifierKey = "sync.cloudKitContainerIdentifier"

    private static let itemEntityName = "ClipItemRecord"
    private static let pinboardEntityName = "PinboardRecord"
    private static let applicationEntityName = "SourceApplicationRecord"
    private static let metadataEntityName = "LibraryMetadata"

    private let legacyURL: URL
    private let sqliteURL: URL
    private let container: NSPersistentContainer?

    private struct LegacySnapshot: Codable {
        var items: [ClipItem]
        var customPinboards: [UserPinboard]?
        var customTags: [String]?
    }

    public init(fileURL: URL, cloudKitContainerIdentifier: String? = nil) {
        self.legacyURL = fileURL.pathExtension.lowercased() == "json"
            ? fileURL
            : fileURL.appendingPathExtension("json")
        self.sqliteURL = fileURL.pathExtension.lowercased() == "sqlite"
            ? fileURL
            : fileURL.deletingPathExtension().appendingPathExtension("sqlite")

        try? FileManager.default.createDirectory(
            at: sqliteURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let model = Self.makeModel()
        let configuredContainer: NSPersistentContainer
        if let cloudKitContainerIdentifier, !cloudKitContainerIdentifier.isEmpty {
            let cloudContainer = NSPersistentCloudKitContainer(
                name: "ClipDeck",
                managedObjectModel: model
            )
            configuredContainer = cloudContainer
        } else {
            configuredContainer = NSPersistentContainer(
                name: "ClipDeck",
                managedObjectModel: model
            )
        }

        let description = NSPersistentStoreDescription(url: sqliteURL)
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        if let cloudKitContainerIdentifier, !cloudKitContainerIdentifier.isEmpty {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: cloudKitContainerIdentifier
            )
        }
        configuredContainer.persistentStoreDescriptions = [description]

        var loadError: Error?
        configuredContainer.loadPersistentStores { _, error in
            loadError = error
        }

        if loadError == nil {
            Self.configureViewContext(configuredContainer.viewContext)
            self.container = configuredContainer
        } else if cloudKitContainerIdentifier != nil {
            let localContainer = NSPersistentContainer(
                name: "ClipDeck",
                managedObjectModel: model
            )
            let localDescription = NSPersistentStoreDescription(url: sqliteURL)
            localDescription.shouldAddStoreAsynchronously = false
            localDescription.shouldMigrateStoreAutomatically = true
            localDescription.shouldInferMappingModelAutomatically = true
            localContainer.persistentStoreDescriptions = [localDescription]

            var localLoadError: Error?
            localContainer.loadPersistentStores { _, error in
                localLoadError = error
            }
            if localLoadError == nil {
                Self.configureViewContext(localContainer.viewContext)
                self.container = localContainer
            } else {
                self.container = nil
            }
        } else {
            self.container = nil
        }
    }

    public var hasSnapshot: Bool {
        if let container, hasCoreDataSnapshot(in: container.viewContext) {
            return true
        }
        return FileManager.default.fileExists(atPath: legacyURL.path)
    }

    public func load() -> [ClipItem] {
        loadSnapshot().items
    }

    public func loadSnapshot() -> (items: [ClipItem], pinboards: [UserPinboard], customTags: [String]) {
        if let container, let snapshot = loadCoreDataSnapshot(in: container.viewContext) {
            return snapshot
        }
        return loadLegacySnapshot()
    }

    public func save(_ items: [ClipItem]) {
        save(items: items, pinboards: [])
    }

    public func save(_ library: ClipboardLibrary) {
        save(items: library.items, pinboards: library.pinboards)
    }

    public func save(items: [ClipItem], pinboards: [UserPinboard]) {
        guard let container else {
            saveLegacySnapshot(items: items, pinboards: pinboards)
            return
        }

        let context = container.viewContext
        context.performAndWait {
            do {
                try upsertItems(items, in: context)
                try upsertPinboards(pinboards, in: context)
                try upsertSourceApplications(items, in: context)
                try upsertMetadata(in: context)
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                context.rollback()
                assertionFailure("Unable to save ClipDeck library: \(error.localizedDescription)")
            }
        }
    }

    private func upsertItems(_ items: [ClipItem], in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.itemEntityName)
        let existing = try context.fetch(request)
        let existingByID = Dictionary(uniqueKeysWithValues: existing.compactMap { object -> (UUID, NSManagedObject)? in
            guard let id = object.value(forKey: "id") as? UUID else { return nil }
            return (id, object)
        })
        let incomingIDs = Set(items.map(\.id))

        for object in existing {
            guard let id = object.value(forKey: "id") as? UUID else { continue }
            if !incomingIDs.contains(id) {
                context.delete(object)
            }
        }

        for item in items {
            let object = existingByID[item.id]
                ?? NSEntityDescription.insertNewObject(forEntityName: Self.itemEntityName, into: context)
            object.setValue(item.id, forKey: "id")
            object.setValue(item.content, forKey: "content")
            object.setValue(item.source, forKey: "source")
            object.setValue(item.sourceBundleIdentifier, forKey: "sourceBundleIdentifier")
            object.setValue(item.kind.rawValue, forKey: "kind")
            object.setValue(item.imageData, forKey: "imageData")
            object.setValue(item.imagePasteboardType, forKey: "imagePasteboardType")
            object.setValue(try JSONEncoder().encode(item.pasteboardRepresentations), forKey: "pasteboardRepresentationsData")
            object.setValue(item.pinboardID, forKey: "pinboardID")
            object.setValue(try JSONEncoder().encode(item.tags), forKey: "tagsData")
            object.setValue(item.createdAt, forKey: "createdAt")
            object.setValue(item.updatedAt, forKey: "updatedAt")
        }
    }

    private func upsertPinboards(_ pinboards: [UserPinboard], in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.pinboardEntityName)
        let existing = try context.fetch(request)
        let existingByID = Dictionary(uniqueKeysWithValues: existing.compactMap { object -> (String, NSManagedObject)? in
            guard let id = object.value(forKey: "id") as? String else { return nil }
            return (id, object)
        })
        let incomingIDs = Set(pinboards.map(\.id))

        for object in existing {
            guard let id = object.value(forKey: "id") as? String else { continue }
            if !incomingIDs.contains(id) {
                context.delete(object)
            }
        }

        for pinboard in pinboards {
            let object = existingByID[pinboard.id]
                ?? NSEntityDescription.insertNewObject(forEntityName: Self.pinboardEntityName, into: context)
            object.setValue(pinboard.id, forKey: "id")
            object.setValue(pinboard.name, forKey: "name")
            object.setValue(pinboard.colorHex, forKey: "colorHex")
        }
    }

    private func upsertSourceApplications(_ items: [ClipItem], in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.applicationEntityName)
        let existing = try context.fetch(request)
        let existingByID = Dictionary(uniqueKeysWithValues: existing.compactMap { object -> (String, NSManagedObject)? in
            guard let id = object.value(forKey: "id") as? String else { return nil }
            return (id, object)
        })

        for item in items {
            let id = item.sourceBundleIdentifier?.isEmpty == false
                ? item.sourceBundleIdentifier!
                : "name:\(item.source)"
            let object = existingByID[id]
                ?? NSEntityDescription.insertNewObject(forEntityName: Self.applicationEntityName, into: context)
            object.setValue(id, forKey: "id")
            object.setValue(item.source, forKey: "name")
            object.setValue(item.sourceBundleIdentifier, forKey: "bundleIdentifier")
            object.setValue(item.updatedAt, forKey: "lastSeenAt")
        }
    }

    private func upsertMetadata(in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.metadataEntityName)
        request.fetchLimit = 1
        let object = try context.fetch(request).first
            ?? NSEntityDescription.insertNewObject(forEntityName: Self.metadataEntityName, into: context)
        object.setValue("library", forKey: "id")
        object.setValue(Date(), forKey: "updatedAt")
    }

    private func loadCoreDataSnapshot(in context: NSManagedObjectContext) -> (items: [ClipItem], pinboards: [UserPinboard], customTags: [String])? {
        let result = SnapshotResultBox()
        context.performAndWait {
            do {
                let metadataRequest = NSFetchRequest<NSManagedObject>(entityName: Self.metadataEntityName)
                metadataRequest.fetchLimit = 1
                guard try !context.fetch(metadataRequest).isEmpty else { return }

                let itemRequest = NSFetchRequest<NSManagedObject>(entityName: Self.itemEntityName)
                itemRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
                let items = try context.fetch(itemRequest).compactMap(Self.decodeItem)

                let pinboardRequest = NSFetchRequest<NSManagedObject>(entityName: Self.pinboardEntityName)
                pinboardRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                let pinboards = try context.fetch(pinboardRequest).compactMap(Self.decodePinboard)
                result.value = (items, pinboards, [])
            } catch {
                result.value = nil
            }
        }
        return result.value
    }

    private func hasCoreDataSnapshot(in context: NSManagedObjectContext) -> Bool {
        let hasSnapshot = BoolResultBox()
        context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: Self.metadataEntityName)
            request.fetchLimit = 1
            hasSnapshot.value = (try? context.count(for: request)) ?? 0 > 0
        }
        return hasSnapshot.value
    }

    private func loadLegacySnapshot() -> (items: [ClipItem], pinboards: [UserPinboard], customTags: [String]) {
        guard let data = try? Data(contentsOf: legacyURL) else { return ([], [], []) }
        if let snapshot = try? JSONDecoder().decode(LegacySnapshot.self, from: data) {
            return (snapshot.items, snapshot.customPinboards ?? [], snapshot.customTags ?? [])
        }
        return ((try? JSONDecoder().decode([ClipItem].self, from: data)) ?? [], [], [])
    }

    private func saveLegacySnapshot(items: [ClipItem], pinboards: [UserPinboard]) {
        do {
            try FileManager.default.createDirectory(
                at: legacyURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(
                LegacySnapshot(items: items, customPinboards: pinboards, customTags: nil)
            )
            try data.write(to: legacyURL, options: .atomic)
        } catch {
            assertionFailure("Unable to save ClipDeck legacy library: \(error.localizedDescription)")
        }
    }

    private static func decodeItem(_ object: NSManagedObject) -> ClipItem? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let content = object.value(forKey: "content") as? String,
            let source = object.value(forKey: "source") as? String,
            let kindRawValue = object.value(forKey: "kind") as? String,
            let kind = ClipKind(rawValue: kindRawValue),
            let createdAt = object.value(forKey: "createdAt") as? Date,
            let updatedAt = object.value(forKey: "updatedAt") as? Date
        else { return nil }

        let representations = decodeRepresentations(object.value(forKey: "pasteboardRepresentationsData") as? Data)
        let tags = decodeTags(object.value(forKey: "tagsData") as? Data)
        return ClipItem(
            id: id,
            content: content,
            source: source,
            sourceBundleIdentifier: object.value(forKey: "sourceBundleIdentifier") as? String,
            kind: kind,
            imageData: object.value(forKey: "imageData") as? Data,
            imagePasteboardType: object.value(forKey: "imagePasteboardType") as? String,
            pasteboardRepresentations: representations,
            pinboardID: object.value(forKey: "pinboardID") as? String,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private static func decodePinboard(_ object: NSManagedObject) -> UserPinboard? {
        guard
            let id = object.value(forKey: "id") as? String,
            let name = object.value(forKey: "name") as? String,
            let colorHex = object.value(forKey: "colorHex") as? String
        else { return nil }
        return UserPinboard(id: id, name: name, colorHex: colorHex)
    }

    private static func decodeRepresentations(_ data: Data?) -> [String: Data] {
        guard let data else { return [:] }
        return (try? JSONDecoder().decode([String: Data].self, from: data)) ?? [:]
    }

    private static func decodeTags(_ data: Data?) -> [String] {
        guard let data else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private static func makeModel() -> NSManagedObjectModel {
        let item = NSEntityDescription()
        item.name = itemEntityName
        item.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        item.properties = [
            attribute("id", type: .UUIDAttributeType),
            attribute("content", type: .stringAttributeType),
            attribute("source", type: .stringAttributeType),
            attribute("sourceBundleIdentifier", type: .stringAttributeType, optional: true),
            attribute("kind", type: .stringAttributeType),
            attribute("imageData", type: .binaryDataAttributeType, optional: true, externalBinaryData: true),
            attribute("imagePasteboardType", type: .stringAttributeType, optional: true),
            attribute("pasteboardRepresentationsData", type: .binaryDataAttributeType, optional: true, externalBinaryData: true),
            attribute("pinboardID", type: .stringAttributeType, optional: true),
            attribute("tagsData", type: .binaryDataAttributeType, optional: true),
            attribute("createdAt", type: .dateAttributeType),
            attribute("updatedAt", type: .dateAttributeType)
        ]

        let pinboard = NSEntityDescription()
        pinboard.name = pinboardEntityName
        pinboard.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        pinboard.properties = [
            attribute("id", type: .stringAttributeType),
            attribute("name", type: .stringAttributeType),
            attribute("colorHex", type: .stringAttributeType)
        ]

        let application = NSEntityDescription()
        application.name = applicationEntityName
        application.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        application.properties = [
            attribute("id", type: .stringAttributeType),
            attribute("name", type: .stringAttributeType),
            attribute("bundleIdentifier", type: .stringAttributeType, optional: true),
            attribute("lastSeenAt", type: .dateAttributeType)
        ]

        let metadata = NSEntityDescription()
        metadata.name = metadataEntityName
        metadata.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        metadata.properties = [
            attribute("id", type: .stringAttributeType),
            attribute("updatedAt", type: .dateAttributeType)
        ]

        let model = NSManagedObjectModel()
        model.entities = [item, pinboard, application, metadata]
        return model
    }

    private static func attribute(
        _ name: String,
        type: NSAttributeType,
        optional: Bool = false,
        externalBinaryData: Bool = false
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        attribute.allowsExternalBinaryDataStorage = externalBinaryData
        return attribute
    }

    private static func configureViewContext(_ context: NSManagedObjectContext) {
        context.mergePolicy = NSMergePolicy(
            merge: .mergeByPropertyObjectTrumpMergePolicyType
        )
        context.undoManager = nil
    }
}
