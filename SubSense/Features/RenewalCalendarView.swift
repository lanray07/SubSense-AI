import SwiftUI
import SubSenseCore

struct RenewalCalendarView: View {
    @Environment(AppModel.self) private var model
    @State private var month = Date()
    @State private var selection: Date?
    @State private var mode = "Month"
    private let calendar = Calendar.current
    private var start: Date { calendar.dateInterval(of: .month, for: month)!.start }
    private var renewals: [Renewal] {
        if mode == "Upcoming" { return model.engine.renewals(model.active, from: Date(), days: 30) }
        return model.engine.renewals(model.active, from: start, days: calendar.range(of: .day, in: .month, for: month)!.count)
    }
    private var visible: [Renewal] { if mode == "Month", let selection { return renewals.filter { calendar.isDate($0.date, inSameDayAs: selection) } }; return renewals }
    var body: some View {
        SheetShell(title: "Renewal Calendar") {
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 18) {
                Picker("Calendar view", selection: $mode) { ForEach(["Month", "Timeline", "Upcoming"], id: \.self) { Text($0).tag($0) } }.pickerStyle(.segmented)
                if mode != "Upcoming" {
                    HStack {
                        Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Previous month")
                        Spacer(); Text(month, format: .dateTime.month(.wide).year()).font(.headline); Spacer()
                        Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }.accessibilityLabel("Next month")
                    }.buttonStyle(.borderless)
                }
                if mode == "Month" { Card { monthGrid } }
                Text(selection != nil && mode == "Month" ? "Selected day" : "Expected renewals").font(.headline)
                    if visible.isEmpty { Text("No recorded charges in this period.").foregroundStyle(.secondary) }
                    ForEach(visible) { renewal in
                        NavigationLink { SubscriptionDetailView(id: renewal.subscription.id) } label: {
                            Card { VStack(alignment: .leading, spacing: 5) {
                                Text(renewal.date, format: .dateTime.weekday(.wide).month(.abbreviated).day()).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                                SubscriptionRow(subscription: renewal.subscription)
                            } }
                        }
                        .buttonStyle(.plain)
                    }
                    if selection != nil { Button("Show the whole month") { selection = nil } }
                Text("Forecasts recur from your recorded dates. They are not a bank transaction history. Open SubSense periodically to refresh the next 60 reminders.").font(.caption).foregroundStyle(.secondary)
              }.padding(20).frame(maxWidth: 850).frame(maxWidth: .infinity)
            }.background(Theme.canvas)
        }
    }
    private var monthGrid: some View {
        let count = calendar.range(of: .day, in: .month, for: month)!.count
        let offset = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 9) {
            ForEach(0..<7) { index in Text(symbols[(index + calendar.firstWeekday - 1) % 7]).font(.caption2).foregroundStyle(.secondary).accessibilityHidden(true) }
            ForEach(0..<(count + offset), id: \.self) { cell in
                if cell < offset { Color.clear.frame(height: 44) }
                else {
                    let date = calendar.date(byAdding: .day, value: cell - offset, to: start)!
                    let marked = renewals.contains { calendar.isDate($0.date, inSameDayAs: date) }
                    let picked = selection.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    Button { selection = date } label: {
                        VStack(spacing: 4) { Text("\(cell - offset + 1)").font(.subheadline); Circle().fill(marked ? Theme.accent : Color.clear).frame(width: 4, height: 4) }
                            .frame(maxWidth: .infinity, minHeight: 44).background(picked ? Theme.mint : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(.plain).accessibilityLabel("\(date.formatted(date: .complete, time: .omitted))\(marked ? ", has renewals" : "")").accessibilityAddTraits(picked ? .isSelected : [])
                }
            }
        }.padding(.vertical, 8)
    }
    private func changeMonth(_ value: Int) { month = calendar.date(byAdding: .month, value: value, to: month)!; selection = nil }
}

#Preview { RenewalCalendarView().environment(AppModel.preview()) }
