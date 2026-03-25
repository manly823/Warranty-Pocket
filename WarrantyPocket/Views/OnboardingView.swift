import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var manager: PocketManager
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String, color: Color)] = [
        ("shield.fill", "Protect Your Purchases",
         "Store all your warranties in one secure place. Never lose a receipt or miss a warranty deadline again.",
         Theme.accent),
        ("camera.fill", "Scan Receipts with OCR",
         "Take a photo of any receipt and smart text recognition will automatically extract the store name, date, and price.",
         Theme.secondary),
        ("bell.fill", "Expiry Reminders",
         "Get notified 30 days, 7 days, and 1 day before any warranty expires. Never miss a claim window again.",
         Theme.warning),
        ("chart.pie.fill", "Track & Analyze",
         "See your total protected value, category breakdown, expiry timeline, and most valuable items at a glance.",
         Color(red: 0.35, green: 0.55, blue: 0.95)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            if page < pages.count { infoPage } else { readyPage }
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var infoPage: some View {
        VStack(spacing: 30) {
            Spacer()
            let p = pages[page]
            ZStack {
                Circle().fill(p.color.opacity(0.05)).frame(width: 160, height: 160)
                Circle().fill(p.color.opacity(0.1)).frame(width: 120, height: 120)
                Image(systemName: p.icon).font(.system(size: 48)).foregroundStyle(p.color)
            }
            VStack(spacing: 10) {
                Text(p.title).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                Text(p.body).font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.sub)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
            }
            Spacer()
            dots
            nextButton("Next") { withAnimation { page += 1 } }
            Spacer().frame(height: 30)
        }
    }

    private var readyPage: some View {
        VStack(spacing: 30) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accent.opacity(0.05)).frame(width: 160, height: 160)
                Circle().fill(Theme.accent.opacity(0.1)).frame(width: 120, height: 120)
                Image(systemName: "checkmark.shield.fill").font(.system(size: 48)).foregroundStyle(Theme.accent)
            }
            VStack(spacing: 10) {
                Text("You're All Set!").font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                Text("12 sample warranties are pre-loaded so you can explore every feature right away. Add your own anytime with a photo or manual entry!")
                    .font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.sub)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
            }
            Spacer()
            dots
            nextButton("Get Started") {
                NotificationHelper.shared.requestPermission()
                manager.onboardingDone = true
            }
            Spacer().frame(height: 30)
        }
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count + 1, id: \.self) { i in
                Circle().fill(i == page ? Theme.accent : Theme.muted).frame(width: 8, height: 8)
            }
        }
    }

    private func nextButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [Theme.accent, Theme.secondary],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .padding(.horizontal, 30)
    }
}
