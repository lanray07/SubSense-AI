import SwiftUI
import LocalAuthentication
import SubSenseCore

@main
struct SubSenseApp: App {
    @State private var model: AppModel?
    @State private var startupError: String?
    var body: some Scene {
        WindowGroup {
            Group {
                if let model { RootView().environment(model).environment(model.store) }
                else if let startupError {
                    ContentUnavailableView {
                        Label("Your data couldn't be opened", systemImage: "externaldrive.badge.exclamationmark")
                    } description: { Text(startupError) } actions: { Button("Try again", action: load) }
                } else { ProgressView("Opening SubSense…").task { load() } }
            }.tint(Theme.accent)
        }
    }
    private func load() {
        do {
            try ExportService.clean()
            let preview = ProcessInfo.processInfo.arguments.contains("--demo")
            let repository: any PortfolioRepository = preview ? MemoryPortfolioRepository() : try SwiftDataPortfolioRepository()
            #if DEBUG
            // Isolated simulator acceptance tests exercise real disk persistence.
            if ProcessInfo.processInfo.arguments.contains("--uitesting-reset") {
                try repository.delete()
                UserDefaults.standard.removeObject(forKey: "onboardingComplete")
                UserDefaults.standard.removeObject(forKey: "appLockEnabled")
            }
            #endif
            let appModel = try AppModel(repository: repository)
            if preview { appModel.startDemo() }
            model = appModel; startupError = nil
            // StoreKit must outlive the loading view's cancellable SwiftUI task.
            Task { await appModel.store.start() }
        } catch { startupError = "Local storage is unavailable. Your existing data has not been replaced. \(error.localizedDescription)" }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("onboardingComplete") private var onboarded = false
    @AppStorage("appLockEnabled") private var appLock = false
    @State private var unlocked = false
    @State private var authenticating = false
    @State private var lockError: String?
    @State private var tab = 0
    private var protected: Bool { appLock && !unlocked }
    var body: some View {
        @Bindable var model = model
        ZStack {
            if protected {
                VStack(spacing: 24) {
                    BrandMark(size: 76)
                    Text("Your space. Your subscriptions.").font(.title2.bold())
                    Button("Unlock SubSense") { Task { await unlock() } }.buttonStyle(PrimaryButtonStyle()).disabled(authenticating)
                    if let lockError { Text(lockError).font(.footnote).foregroundStyle(.secondary) }
                }.padding(32)
            } else if !onboarded && !model.isDemo {
                OnboardingView { onboarded = true }
            } else {
                VStack(spacing: 0) {
                    if model.isDemo {
                        HStack { Label("DEMO · Illustrative prices", systemImage: "eye"); Spacer(); Button("Exit") { model.endDemo() } }
                            .font(.caption.weight(.semibold)).padding(.horizontal, 20).padding(.vertical, 9).background(Theme.mint).foregroundStyle(Theme.ink)
                    }
                TabView(selection: $tab) {
                    NavigationStack { HomeView() }.tabItem { Label("Home", systemImage: "square.grid.2x2") }.tag(0)
                    NavigationStack { SubscriptionsView() }.tabItem { Label("Subscriptions", systemImage: "square.stack") }.tag(1)
                    NavigationStack { InsightsView() }.tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }.tag(2)
                    NavigationStack { CopilotView() }.tabItem { Label("Copilot", systemImage: "sparkles") }.tag(3)
                    NavigationStack { SettingsView() }.tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(4)
                }
                }
                .sheet(item: $model.sheet) { destination in
                    Group {
                    switch destination {
                    case .add: SubscriptionEditor(subscription: Subscription(currency: model.data.user.currency))
                    case .edit(let s): SubscriptionEditor(subscription: s)
                    case .scanner: ReceiptScannerView()
                    case .paywall: PaywallView()
                    case .health: HealthView()
                    case .audit: AuditView()
                    case .simulator: SimulatorView()
                    case .renewals: RenewalCalendarView()
                    case .privacy: PrivacyView()
                    case .export: ExportView()
                    }
                    }.overlay {
                        if scenePhase != .active { Theme.canvas.ignoresSafeArea().overlay { BrandMark(size: 70) } }
                    }
                }
            }
            if scenePhase != .active { Theme.canvas.ignoresSafeArea().overlay { BrandMark(size: 70) } }
        }
        .alert("Something needs attention", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) { Button("OK") { model.error = nil } } message: { Text(model.error ?? "") }
        .alert("More room for what matters", isPresented: Binding(get: { model.celebration != nil }, set: { if !$0 { model.celebration = nil } })) { Button("Lovely") { model.celebration = nil } } message: { Text(model.celebration ?? "") }
        .task { if appLock { await unlock() }; model.refreshReminders() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { unlocked = false; if appLock { model.sheet = nil } }
            if phase == .active { model.refreshReminders(); Task { await model.store.refreshEntitlements() } }
        }
    }
    private func unlock() async {
        guard !authenticating else { return }
        authenticating = true; defer { authenticating = false }
        do {
            unlocked = try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your private subscription portfolio.")
            lockError = nil
        } catch { lockError = "Couldn't unlock. Try Face ID, Touch ID, or your device passcode again." }
    }
}
