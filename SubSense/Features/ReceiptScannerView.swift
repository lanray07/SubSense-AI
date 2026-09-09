import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import SubSenseCore

struct ReceiptScannerView: View {
    @Environment(AppModel.self) private var model
    @State private var text = ""
    @State private var importing = false
    @State private var photo: PhotosPickerItem?
    @State private var draft: ReceiptDraft?
    @State private var editing: Subscription?
    @State private var busy = false
    @State private var error: String?
    @FocusState private var editingText: Bool
    var body: some View {
        SheetShell(title: "Receipt Scanner") {
            Form {
                Section {
                    Label("Private by design", systemImage: "lock.shield").font(.headline)
                    Text("Paste a receipt, choose a UTF-8 text file, or select a screenshot. Text recognition and parsing happen on your device. Nothing is saved until you review and confirm.").font(.subheadline).foregroundStyle(.secondary)
                    TextEditor(text: $text).frame(minHeight: 180).accessibilityLabel("Receipt text").focused($editingText)
                    HStack { Button("Import text file") { importing = true }; Spacer(); PhotosPicker("Choose screenshot", selection: $photo, matching: .images) }.disabled(busy)
                }
                Section {
                    Button("Extract subscription") { Task { await extract() } }.disabled(text.isEmpty || busy)
                    if busy { ProgressView("Reading your receipt…") }
                    if let error { Text(error).foregroundStyle(.red) }
                }
                if let draft {
                    Section("Check before saving") {
                        SubscriptionRow(subscription: draft.subscription)
                        ForEach(draft.uncertainties, id: \.self) { Label($0, systemImage: "info.circle").font(.caption).foregroundStyle(.secondary) }
                        Button("Review & edit extracted details") { editing = draft.subscription }
                    }
                }
            }.scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done editing receipt") { editingText = false }
                }
            }
            .onChange(of: text) { _, _ in draft = nil }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
                do {
                    let url = try result.get(); let granted = url.startAccessingSecurityScopedResource(); defer { if granted { url.stopAccessingSecurityScopedResource() } }
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard size <= 100_000 else { throw DomainError.invalid("Choose a text receipt smaller than 100 KB.") }
                    text = try String(contentsOf: url, encoding: .utf8); draft = nil
                } catch { self.error = error.localizedDescription }
            }
            .onChange(of: photo) { _, item in
                guard let item else { return }
                Task {
                    busy = true; defer { busy = false }
                    do { guard let data = try await item.loadTransferable(type: Data.self) else { throw DomainError.invalid("This image couldn't be read.") }; text = try await ReceiptOCR.text(from: data); draft = nil; error = nil }
                    catch { self.error = error.localizedDescription }
                }
            }
            .sheet(item: $editing) { s in SubscriptionEditor(subscription: s) }
        }
    }
    private func extract() async {
        editingText = false
        busy = true; error = nil; defer { busy = false }
        do { draft = try await model.ai.extractSubscriptionFromReceipt(text) } catch { self.error = error.localizedDescription }
    }
}

#Preview { ReceiptScannerView().environment(AppModel.preview()) }
