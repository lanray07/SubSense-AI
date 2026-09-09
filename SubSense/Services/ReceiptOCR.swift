import Foundation
import Vision
import UIKit
import SubSenseCore

enum ReceiptOCR {
    static func text(from data: Data) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            guard data.count < 20_000_000 else { throw DomainError.invalid("Choose an image smaller than 20 MB.") }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(data: data)
            try handler.perform([request])
            return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        }.value
    }
}
