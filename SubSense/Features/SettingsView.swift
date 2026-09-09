import SwiftUI
import LocalAuthentication
import SubSenseCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("appLockEnabled") private var appLock = false
    @State private var deletion = false
    @State private var message: String?
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) { BrandMark(size: 52); VStack(alignment: .leading, spacing: 4) { Text("Your space, thoughtfully managed.").font(.headline); Text(model.store.hasPro ? "SubSense Pro" : "SubSense Free · Up to 5 subscriptions").font(.caption).foregroundStyle(.secondary) } }.padding(.vertical, 10)
                Button(model.store.hasPro ? "Manage SubSense Pro" : "Discover SubSense Pro") { model.sheet = .paywall }
            }
            Section("Make it yours") {
                NavigationLink("Profile & savings goal") { PreferencesView() }
                NavigationLink("Renewal reminders") { NotificationSettingsView() }
                Button("Import a receipt") { model.sheet = .scanner }
                Button("Export reports") { model.requirePro(.export) }
            }
            Section("Privacy & security") {
                Toggle("Face ID / device passcode lock", isOn: Binding(get: { appLock }, set: { value in Task { await setLock(value) } }))
                Button("How your data is handled") { model.sheet = .privacy }
                Text("The portfolio stays on this device and is protected by iOS Data Protection. Your device backup settings may include app data.").font(.caption).foregroundStyle(.secondary)
                if let message { Text(message).font(.caption).foregroundStyle(.secondary) }
            }
            Section("Explore") {
                Button(model.isDemo ? "Exit demo" : "Explore demo portfolio") { if model.isDemo { model.endDemo() } else { model.startDemo() } }
                Text("Demo data is temporary and separate from your saved portfolio. Prices are illustrative; no demo alerts are scheduled.").font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button("Delete All Data", role: .destructive) { deletion = true }
            } footer: { Text("Deletes the saved portfolio, history, plans, goals and pending reminders on this device. Exported copies outside the app and Apple purchase records remain under your control.") }
            Section { Text("SubSense AI · Version 1.0\nKnow what you're paying for. Keep more of your money.").font(.caption).foregroundStyle(.secondary) }
        }.navigationTitle("Settings")
            .confirmationDialog("Delete all SubSense data from this device?", isPresented: $deletion, titleVisibility: .visible) {
                Button("Export before deleting") { model.sheet = .export }
                Button("Delete all data permanently", role: .destructive) {
                    do { try ExportService.clean(); try model.deleteAllData(); appLock = false; message = "Your local data and reminders have been deleted." } catch { model.error = error.localizedDescription }
                }
            } message: { Text("This cannot be undone. It does not cancel any provider subscriptions or your SubSense Pro plan. Export is available here even without Pro.") }
    }
    private func setLock(_ enabled: Bool) async {
        do {
            let result = try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: enabled ? "Enable a lock for your subscription data." : "Confirm turning off your SubSense app lock.")
            if result { appLock = enabled }; message = nil
        } catch { message = "Authentication was not completed. Your app lock setting is unchanged." }
    }
}

struct PreferencesView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var user = User()
    @State private var goal = ""
    @State private var income = ""
    @State private var member = ""
    @State private var error: String?
    var body: some View {
        Form {
            Section("Profile") {
                TextField("Your name (optional)", text: $user.name)
                Picker("Display & income currency", selection: $user.currency) { ForEach(Locale.commonISOCurrencyCodes.sorted(), id: \.self) { Text($0).tag($0) } }
                TextField("Monthly savings goal", text: $goal).keyboardType(.decimalPad)
                TextField("Monthly income (optional)", text: $income).keyboardType(.decimalPad)
                Text("Income is stored locally and only affects the score for matching-currency spending. No foreign exchange conversion is performed.").font(.caption).foregroundStyle(.secondary)
            }
            if model.canUsePro {
                Section("Household profiles · local only") {
                    ForEach(user.household.members, id: \.self) { Text($0) }
                    TextField("New profile", text: $member)
                    Button("Add profile") {
                        let name = member.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !name.isEmpty && !user.household.members.contains(name) { user.household.members.append(name); member = "" }
                    }
                }
            }
            if let error { Text(error).foregroundStyle(.red) }
            Button("Save preferences") {
                do {
                    guard let value = Money.parseInput(goal) else { throw DomainError.invalid("Enter a valid savings goal, or zero to disable it.") }
                    user.monthlySavingsGoal = value
                    if income.isEmpty { user.monthlyIncome = nil }
                    else { guard let value = Money.parseInput(income), value > 0 else { throw DomainError.invalid("Enter a positive monthly income or leave it blank.") }; user.monthlyIncome = value }
                    try model.savePreferences(user: user, notifications: model.data.notifications); dismiss()
                } catch { self.error = error.localizedDescription }
            }
        }.navigationTitle("Profile & goals").onAppear { user = model.data.user; goal = Money.input(user.monthlySavingsGoal); income = user.monthlyIncome.map { Money.input($0) } ?? "" }
    }
}

struct NotificationSettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var preference = NotificationPreference()
    @State private var message: String?
    var body: some View {
        Form {
            Toggle("Renewal reminders", isOn: $preference.enabled)
            Picker("Remind me", selection: $preference.daysBefore) { ForEach([1, 3, 7, 14, 30], id: \.self) { Text("\($0) days before").tag($0) } }
            Toggle("Hide names and amounts in alerts", isOn: $preference.privateContent)
            Section { Text("Reminders use your entered renewal and trial dates. SubSense schedules the nearest 60 events, including cancellation plans, and refreshes them when you open the app. It cannot detect provider price changes automatically.").font(.caption).foregroundStyle(.secondary) }
            Button("Save reminder preferences") {
                Task {
                    do {
                        if preference.enabled && !model.isDemo {
                            guard try await model.notifications.requestPermission() else { message = "Permission wasn't granted. Enable notifications in iOS Settings to receive alerts."; return }
                        }
                        try model.savePreferences(user: model.data.user, notifications: preference)
                        message = model.isDemo ? "Demo preferences updated. No real reminders scheduled." : "Preferences saved."
                    } catch { message = error.localizedDescription }
                }
            }
            Link("Open iOS Settings", destination: URL(string: UIApplication.openSettingsURLString)!)
            if let message { Text(message).font(.subheadline) }
        }.navigationTitle("Renewal reminders").onAppear { preference = model.data.notifications }
    }
}

struct PrivacyView: View {
    var body: some View {
        SheetShell(title: "Your data stays yours") {
            List {
                Section { Label("Private by design", systemImage: "lock.shield").font(.title2); Text("SubSense stores the subscriptions, costs, usage ratings, notes, profiles and savings actions you enter in a local SwiftData store, protected by iOS Data Protection.") }
                Section("Processing") { Text("Scoring, receipt parsing, screenshot text recognition, audits and Copilot responses run locally. The current Copilot is a deterministic rules provider. There is no generative AI connection, cloud sync, bank connection or email inbox access.") }
                Section("Third parties") { Text("Apple processes SubSense Pro purchases and receives the information necessary for StoreKit. SubSense does not retrieve subscriptions purchased from other apps. There is no advertising SDK, analytics SDK or external AI upload in this build.") }
                Section("Your controls") { Text("Enable the device authentication lock and private notification content in Settings. Export a copy or use Delete All Data to remove the portfolio and reminders. Exported files you share and device backups are managed separately by you. Export is also available before deletion without Pro.") }
                Section("Device backups") { Text("Depending on your device settings, iOS backups may include the local app store. Manage those backups through Apple. Disabling or deleting this app does not cancel any subscription.") }
            }
        }
    }
}

struct ExportView: View {
    @Environment(AppModel.self) private var model
    @State private var report: ReportKind = .monthly
    @State private var format: ExportFormat = .pdf
    @State private var url: URL?
    @State private var error: String?
    var body: some View {
        SheetShell(title: "Export your clarity") {
            Form {
                Picker("Report", selection: $report) { ForEach(ReportKind.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                Picker("Format", selection: $format) { ForEach(ExportFormat.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                Text("CSV and PDF contain the selected report. JSON includes your complete portable portfolio archive. Shared files contain personal financial information.").font(.caption).foregroundStyle(.secondary)
                Button("Prepare export") { do { url = try ExportService.export(model.data, report: report, format: format); error = nil } catch { self.error = error.localizedDescription } }
                if let url { ShareLink(item: url) { Label("Share or save report", systemImage: "square.and.arrow.up") } }
                if let error { Text(error).foregroundStyle(.red) }
            }.onChange(of: report) { _, _ in url = nil }.onChange(of: format) { _, _ in url = nil }
        }
    }
}

#Preview { NavigationStack { SettingsView() }.environment(AppModel.preview()) }
#Preview("Privacy") { PrivacyView() }
#Preview("Export") { ExportView().environment(AppModel.preview()) }
