import SwiftUI

struct Theme {
    static let bg = Color(red: 0.06, green: 0.07, blue: 0.08)
    static let surface = Color(red: 0.10, green: 0.11, blue: 0.13)
    static let card = Color(red: 0.13, green: 0.14, blue: 0.16)
    static let accent = Color(red: 0.78, green: 0.47, blue: 0.25)
    static let secondary = Color(red: 0.83, green: 0.65, blue: 0.44)
    static let text = Color(red: 0.94, green: 0.93, blue: 0.91)
    static let sub = Color(red: 0.55, green: 0.53, blue: 0.50)
    static let muted = Color(red: 0.30, green: 0.29, blue: 0.27)
    static let success = Color(red: 0.2, green: 0.78, blue: 0.45)
    static let warning = Color(red: 0.95, green: 0.75, blue: 0.2)
    static let danger = Color(red: 0.9, green: 0.3, blue: 0.3)

    static let gradient = LinearGradient(
        colors: [accent, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GlowCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.08), lineWidth: 1))
    }
}

extension View {
    func glowCard() -> some View { modifier(GlowCard()) }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    init(progress: Double, color: Color = Theme.accent, size: CGFloat = 60, lineWidth: CGFloat = 6) {
        self.progress = progress
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle().trim(from: 0, to: min(progress, 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

struct CountdownRing: View {
    let item: WarrantyItem
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(item.status.color.opacity(0.15), lineWidth: 5)
            Circle().trim(from: 0, to: 1 - item.progress)
                .stroke(
                    AngularGradient(colors: [item.status.color, item.status.color.opacity(0.3)], center: .center),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\(item.daysRemaining)")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundStyle(item.status.color)
                Text("days")
                    .font(.system(size: size * 0.12, design: .rounded))
                    .foregroundStyle(Theme.sub)
            }
        }
        .frame(width: size, height: size)
    }
}
