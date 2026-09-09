import SwiftUI
import SubSenseCore

struct CopilotMessage: Identifiable {
    var id = UUID()
    var text: String
    var isUser: Bool
}
struct CopilotView: View {
    @Environment(AppModel.self) private var model
    @State private var question = ""
    @State private var messages: [CopilotMessage] = []
    @State private var busy = false
    @State private var request: Task<Void, Never>?
    private let prompts = ["Where can I save money?", "What should I cancel first?", "Which subscription costs me the most annually?", "Which subscriptions overlap?", "What renews this month?", "Show me subscriptions I rarely use.", "What happens if I cancel my five most expensive subscriptions?"]
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack { BrandMark(size: 46); VStack(alignment: .leading, spacing: 4) { Text("A clearer way forward.").font(.system(.title2, design: .serif)); Text("Local Copilot · No data leaves this device").font(.caption).foregroundStyle(.secondary) } }
                    if !model.canUsePro {
                        Card { VStack(alignment: .leading, spacing: 15) { Text("Meet your subscription copilot").font(.title2); Text("Turn your portfolio into a practical savings conversation with SubSense Pro.").foregroundStyle(.secondary); Button("Explore Pro") { model.sheet = .paywall }.buttonStyle(PrimaryButtonStyle()) } }
                    } else {
                        if messages.isEmpty {
                            Text("Ask about the commitments you keep, and the ones you could leave behind.").foregroundStyle(.secondary).lineSpacing(4)
                            ForEach(prompts, id: \.self) { prompt in Button { send(prompt) } label: { HStack { Text(prompt).multilineTextAlignment(.leading); Spacer(); Image(systemName: "arrow.up.left") }.font(.subheadline).padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Theme.card, in: RoundedRectangle(cornerRadius: 18)) }.buttonStyle(.plain) }
                        }
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser { Spacer(minLength: 30) }
                                Text(message.text).font(.body).lineSpacing(5).textSelection(.enabled).padding(18)
                                    .foregroundStyle(message.isUser ? Color.white : Color.primary).background(message.isUser ? Theme.action : Theme.card, in: RoundedRectangle(cornerRadius: 20))
                                if !message.isUser { Spacer(minLength: 20) }
                            }.id(message.id)
                        }
                        if busy { ProgressView("Reviewing your entries…") }
                        Text("Offline rules provider, not a generative AI model. Usage is self-reported; savings are estimates. Conversations are kept only while this screen is open.").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(22).frame(maxWidth: 850).frame(maxWidth: .infinity)
            }.background(Theme.canvas).onChange(of: messages.count) { _, _ in if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) } }
                .safeAreaInset(edge: .bottom) {
                    if model.canUsePro {
                        HStack(spacing: 12) {
                            TextField("Ask about your subscriptions…", text: $question, axis: .vertical).lineLimit(1...4).padding(13).background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
                            Button { send(question) } label: { Image(systemName: "arrow.up").font(.headline).frame(width: 44, height: 44).foregroundStyle(.white).background(Theme.action, in: Circle()) }.disabled(busy || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityLabel("Send question")
                        }.padding(.horizontal, 20).padding(.vertical, 10).background(.bar)
                    }
                }
        }.navigationTitle("SubSense Copilot").toolbar { Button("Clear") { request?.cancel(); busy = false; messages = [] }.disabled(messages.isEmpty) }
            .onDisappear { request?.cancel(); messages = []; question = ""; busy = false }
    }
    private func send(_ text: String) {
        guard !busy, model.canUsePro else { return }
        let clean = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2000))
        guard !clean.isEmpty else { return }
        question = ""; messages.append(.init(text: clean, isUser: true)); busy = true
        request = Task {
            defer { busy = false }
            do {
                let response = try await model.ai.answerSubscriptionQuestion(clean, subscriptions: model.subscriptions)
                try Task.checkCancellation()
                messages.append(.init(text: response, isUser: false))
            } catch is CancellationError {} catch { messages.append(.init(text: "Couldn't finish that request. Please try again.", isUser: false)) }
        }
    }
}

#Preview { NavigationStack { CopilotView() }.environment(AppModel.preview()) }
