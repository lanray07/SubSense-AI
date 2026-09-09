import Foundation
import UIKit
import SubSenseCore

enum ReportKind: String, CaseIterable { case monthly = "Monthly Subscription Report", annual = "Annual Subscription Audit", cancellation = "Cancellation Plan", savings = "Savings Report", business = "Business SaaS Report" }
enum ExportFormat: String, CaseIterable { case csv = "CSV", json = "JSON", pdf = "PDF" }

@MainActor
enum ExportService {
    static var directory: URL { URL.temporaryDirectory.appending(path: "SubSenseExports", directoryHint: .isDirectory) }
    static func clean() throws {
        if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
    }
    static func export(_ portfolio: Portfolio, report: ReportKind, format: ExportFormat) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
        let url = directory.appending(path: "SubSense-\(report.rawValue.replacingOccurrences(of: " ", with: "-"))-\(UUID().uuidString.prefix(8)).\(format.rawValue.lowercased())")
        let data: Data
        switch format {
        case .json:
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
            // JSON is the complete portable archive, with report intent stored alongside it.
            data = try encoder.encode(Archive(report: report.rawValue, exportedAt: Date(), portfolio: portfolio))
        case .csv:
            data = Data(rows(portfolio, report: report).map { $0.map(csvCell).joined(separator: ",") }.joined(separator: "\r\n").utf8)
        case .pdf:
            data = pdf(portfolio, report: report)
        }
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }
    private struct Archive: Encodable { var report: String; var exportedAt: Date; var portfolio: Portfolio }
    private static func csvCell(_ value: String) -> String {
        // Prevent spreadsheet formula injection in provider names, notes and other user-controlled fields.
        let risky = ["=", "+", "-", "@", "\t", "\r", "\n"].contains { value.hasPrefix($0) }
        let safe = risky ? "'" + value : value
        return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
    private static func rows(_ portfolio: Portfolio, report: ReportKind) -> [[String]] {
        if report == .savings {
            return [["Service", "Action date", "Monthly reduction", "Annualised reduction", "Currency", "Basis"]] + portfolio.savingsEvents.map { [$0.name, $0.date.ISO8601Format(), "\($0.monthlySaving)", "\($0.monthlySaving * 12)", $0.currency, "Projected reduction; not cash received"] }
        }
        if report == .cancellation {
            return [["Service", "Status", "Intended date", "Notes"]] + portfolio.cancellationPlans.map { plan in
                [portfolio.subscriptions.first(where: { $0.id == plan.subscriptionID })?.name ?? "Deleted record", plan.status.rawValue, plan.intendedDate.ISO8601Format(), plan.notes]
            }
        }
        let subscriptions = portfolio.subscriptions.filter { report != .business || $0.scope != .personal }
        return [["Name", "Provider", "Category", "Price", "Currency", "Billing", "Monthly equivalent", "Annual equivalent", "Next billing", "Status", "Usage", "Profile", "Notes", "Demo"]] + subscriptions.map {
            [$0.name, $0.provider, $0.category, "\($0.price)", $0.currency, $0.billingFrequency.rawValue, "\($0.monthlyEquivalent)", "\($0.annualEquivalent)", $0.nextBillingDate?.ISO8601Format() ?? "", $0.status.rawValue, $0.usageFrequency.rawValue, $0.household, $0.notes, "\($0.isDemo)"]
        }
    }
    private static func pdf(_ portfolio: Portfolio, report: ReportKind) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        return renderer.pdfData { context in
            var y: CGFloat = 0
            func newPage() {
                context.beginPage(); y = 54
                ("SUBSENSE AI" as NSString).draw(at: CGPoint(x: 42, y: y), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray]); y += 30
            }
            func draw(_ text: String, size: CGFloat = 12, bold: Bool = false) {
                let style = NSMutableParagraphStyle(); style.lineSpacing = 4
                let attributes: [NSAttributedString.Key: Any] = [.font: bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size), .paragraphStyle: style, .foregroundColor: UIColor.black]
                // Bound each paragraph so user notes cannot overflow a whole page.
                var chunks: [String] = []
                var remaining = text[...]
                while !remaining.isEmpty {
                    let end = remaining.index(remaining.startIndex, offsetBy: min(700, remaining.count))
                    chunks.append(String(remaining[..<end])); remaining = remaining[end...]
                }
                for chunk in chunks {
                    let rect = (chunk as NSString).boundingRect(with: CGSize(width: 511, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
                    if y + rect.height > 775 { newPage() }
                    (chunk as NSString).draw(in: CGRect(x: 42, y: y, width: 511, height: rect.height + 3), withAttributes: attributes)
                    y += rect.height + 14
                }
            }
            newPage(); draw(report.rawValue, size: 24, bold: true)
            draw("Created \(Date().formatted(date: .abbreviated, time: .shortened)). \(portfolio.subscriptions.contains(where: \.isDemo) ? "DEMO: illustrative entries and prices." : "Based on user-entered records.")")
            draw("Projections assume unchanged prices. Currencies are kept separate. This is not financial advice or a record of bank transactions.")
            let totals = Money.grouped(portfolio.subscriptions.filter { report != .business || $0.scope != .personal }, annual: report == .annual)
            if report != .savings && report != .cancellation { for code in totals.keys.sorted() { draw("\(code): \(Money.format(totals[code]!, currency: code)) / \(report == .annual ? "year" : "month")", size: 17, bold: true) } }
            let table = rows(portfolio, report: report)
            for row in table.dropFirst() {
                draw(row.first ?? "", size: 15, bold: true)
                draw(zip(table[0].dropFirst(), row.dropFirst()).map { pair in "\(pair.0): \(pair.1)" }.joined(separator: " · "))
            }
        }
    }
}
