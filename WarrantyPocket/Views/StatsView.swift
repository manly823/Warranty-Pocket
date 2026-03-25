import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var manager: PocketManager

    var body: some View {
        VStack(spacing: 16) {
            summaryCards
            categoryChart
            valueChart
            expiryTimeline
            topItems
        }
        .padding(.horizontal, 20).padding(.bottom, 30)
    }

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                insightCard("🛡️", String(format: "$%.0f", manager.totalProtectedValue), "Protected Value", Theme.accent)
                insightCard("📦", "\(manager.warranties.count)", "Total Items", Theme.secondary)
            }
            HStack(spacing: 12) {
                insightCard("📅", String(format: "%.0f mo", manager.avgWarrantyMonths), "Avg Duration", Theme.sub)
                insightCard("⚠️", "\(manager.expiringWarranties.count)", "Expiring Soon", Theme.warning)
            }
        }
    }

    private func insightCard(_ emoji: String, _ value: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(emoji).font(.system(size: 20))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.system(size: 11, design: .rounded)).foregroundStyle(Theme.sub)
        }
        .frame(maxWidth: .infinity, alignment: .leading).glowCard()
    }

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            let data = manager.categoryDistribution()
            let maxVal = data.map(\.value).max() ?? 1
            ForEach(data) { point in
                HStack(spacing: 10) {
                    Text(point.label).font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.text)
                        .frame(width: 80, alignment: .leading)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4).fill(point.color.opacity(0.2)).frame(width: geo.size.width)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(point.color)
                                    .frame(width: max(0, geo.size.width * (point.value / maxVal)))
                            }
                    }
                    .frame(height: 20)
                    Text("\(Int(point.value))").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(point.color)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
        .glowCard()
    }

    private var valueChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Value by Category").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            let data = manager.categoryValueDistribution()
            let maxVal = data.map(\.value).max() ?? 1
            ForEach(data) { point in
                HStack(spacing: 10) {
                    Text(point.label).font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.text)
                        .frame(width: 80, alignment: .leading)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4).fill(point.color.opacity(0.2)).frame(width: geo.size.width)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(point.color)
                                    .frame(width: max(0, geo.size.width * (point.value / maxVal)))
                            }
                    }
                    .frame(height: 20)
                    Text(String(format: "$%.0f", point.value)).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(point.color)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .glowCard()
    }

    private var expiryTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expiry Timeline").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            let data = manager.expiryTimeline()
            ForEach(data) { point in
                HStack(spacing: 10) {
                    Text(point.label).font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.text)
                        .frame(width: 90, alignment: .leading)
                    Spacer()
                    Text("\(Int(point.value))").font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(point.value > 0 ? Theme.accent : Theme.muted)
                    HStack(spacing: 3) {
                        ForEach(0..<min(Int(point.value), 10), id: \.self) { _ in
                            Circle().fill(Theme.accent).frame(width: 8, height: 8)
                        }
                    }
                    .frame(minWidth: 40, alignment: .leading)
                }
            }
        }
        .glowCard()
    }

    private var topItems: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Most Valuable").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            ForEach(Array(manager.topValueItems().enumerated()), id: \.element.id) { idx, item in
                HStack(spacing: 10) {
                    Text("#\(idx + 1)").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Theme.accent)
                        .frame(width: 24)
                    Text(item.category.emoji).font(.system(size: 14))
                    Text(item.name).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text).lineLimit(1)
                    Spacer()
                    Text(String(format: "$%.0f", item.purchasePrice))
                        .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Theme.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .glowCard()
    }
}
