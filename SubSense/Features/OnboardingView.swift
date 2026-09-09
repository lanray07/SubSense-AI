import SwiftUI

struct OnboardingView: View {
    var finish: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    private let titles = ["Take control of your subscriptions.", "Small subscriptions add up.", "Your private subscription audit.", "Meet renewals with a little more calm.", "Your financial data stays yours."]
    private let descriptions = ["Track recurring payments, discover wasted spend, and get intelligent suggestions for reducing your monthly bills.", "A few streaming services. A tool you forgot. A trial that kept going. See the whole picture, in one calm place.", "Understand cost, reported usage, renewal frequency, price changes and possible overlap. Your first audit runs privately on this device using transparent rules.", "Set reminders for upcoming payments, annual renewals and trial endings. Alerts depend on the dates you enter and notification permission.", "Your portfolio is stored on this device. No bank connection. No email account access. No AI uploads. You decide what to add, export or delete."]
    private let symbols = ["arrow.triangle.2.circlepath", "square.stack.3d.up", "sparkles", "bell.badge", "lock.shield"]
    var body: some View {
        VStack(spacing: 0) {
            HStack { BrandMark(size: 32); Text("subsense").font(.title3.weight(.semibold)); Spacer(); Text("\(step + 1) / 5").font(.caption).foregroundStyle(.secondary) }.padding(24)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 38).fill(Theme.ink.gradient)
                        VStack(spacing: 28) {
                            Image(systemName: symbols[step]).font(.system(size: 62, weight: .light)).foregroundStyle(Theme.mint)
                            if step == 1 {
                                Text("£1,400+ / year").font(.system(.largeTitle, design: .rounded).weight(.semibold)).foregroundStyle(.white)
                                Text("An illustrative recurring-spend example").font(.caption).foregroundStyle(.white.opacity(0.65))
                            } else { Text("A little more breathing room.").font(.callout).foregroundStyle(.white.opacity(0.8)) }
                        }.padding(25)
                    }.frame(height: 280)
                    Text(titles[step]).font(.system(.largeTitle, design: .serif).weight(.medium)).tracking(-1)
                    Text(descriptions[step]).font(.body).foregroundStyle(.secondary).lineSpacing(5)
                }.padding(.horizontal, 24).frame(maxWidth: 560)
            }
            VStack(spacing: 18) {
                HStack(spacing: 7) { ForEach(0..<5) { index in Capsule().fill(index == step ? Theme.accent : Theme.accent.opacity(0.15)).frame(width: index == step ? 25 : 6, height: 6) } }.accessibilityHidden(true)
                Button(step == 0 ? "Get Started" : step == 4 ? "Continue" : "Next") {
                    if step == 4 { finish() } else { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { step += 1 } }
                }.buttonStyle(PrimaryButtonStyle())
                Button("Explore the demo") { model.startDemo(); finish() }.font(.subheadline)
            }.padding(24).frame(maxWidth: 560)
        }.background(Theme.canvas)
    }
}

#Preview { OnboardingView {}.environment(AppModel.preview()) }
