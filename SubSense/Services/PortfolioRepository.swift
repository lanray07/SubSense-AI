import Foundation
import SwiftData
import SubSenseCore

@Model
final class PortfolioRecord {
    @Attribute(.unique) var key: String
    var payload: Data
    var updatedAt: Date
    init(payload: Data) { key = "portfolio-v1"; self.payload = payload; updatedAt = Date() }
}

@MainActor
protocol PortfolioRepository {
    func load() throws -> Portfolio
    func save(_ portfolio: Portfolio) throws
    func delete() throws
}

@MainActor
final class SwiftDataPortfolioRepository: PortfolioRepository {
    let container: ModelContainer
    private let context: ModelContext
    init(inMemory: Bool = false) throws {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            let directory = URL.applicationSupportDirectory.appending(path: "SubSense", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
            configuration = ModelConfiguration(url: directory.appending(path: "Portfolio.store"), cloudKitDatabase: .none)
        }
        container = try ModelContainer(for: PortfolioRecord.self, configurations: configuration)
        context = ModelContext(container); context.autosaveEnabled = false
    }
    func load() throws -> Portfolio {
        guard let record = try context.fetch(FetchDescriptor<PortfolioRecord>()).first else { return Portfolio() }
        let portfolio = try JSONDecoder().decode(Portfolio.self, from: record.payload)
        guard portfolio.schemaVersion == 1 else { throw DomainError.invalid("This data was created by a newer version of SubSense. Update the app before opening it.") }
        return portfolio
    }
    func save(_ portfolio: Portfolio) throws {
        let data = try JSONEncoder().encode(portfolio)
        do {
            if let record = try context.fetch(FetchDescriptor<PortfolioRecord>()).first {
                record.payload = data; record.updatedAt = Date()
            } else { context.insert(PortfolioRecord(payload: data)) }
            try context.save()
        } catch { context.rollback(); throw error }
    }
    func delete() throws {
        do {
            for record in try context.fetch(FetchDescriptor<PortfolioRecord>()) { context.delete(record) }
            try context.save()
        } catch { context.rollback(); throw error }
    }
}

@MainActor
final class MemoryPortfolioRepository: PortfolioRepository {
    var portfolio: Portfolio
    init(_ portfolio: Portfolio = Portfolio()) { self.portfolio = portfolio }
    func load() throws -> Portfolio { portfolio }
    func save(_ portfolio: Portfolio) throws { self.portfolio = portfolio }
    func delete() throws { portfolio = Portfolio() }
}
