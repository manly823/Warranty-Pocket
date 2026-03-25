import SwiftUI

enum AppTab: Int, CaseIterable {
    case home, items, archive, insights

    var icon: String {
        switch self {
        case .home: return "shield.fill"
        case .items: return "list.bullet.rectangle.fill"
        case .archive: return "archivebox.fill"
        case .insights: return "chart.pie.fill"
        }
    }

    var label: String {
        switch self {
        case .home: return "Home"
        case .items: return "Items"
        case .archive: return "Archive"
        case .insights: return "Insights"
        }
    }
}

struct MainView: View {
    @EnvironmentObject var manager: PocketManager
    @State private var selectedTab: AppTab = .home
    @State private var showSettings = false
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    topBar
                    ScrollView(.vertical, showsIndicators: false) {
                        switch selectedTab {
                        case .home: HomeContent(showAddSheet: $showAddSheet)
                        case .items: WarrantiesView(showAddSheet: $showAddSheet)
                        case .archive: ArchiveView()
                        case .insights: InsightsView()
                        }
                    }
                    .padding(.bottom, 90)
                }
                bottomBar
            }
            .background(Theme.bg.ignoresSafeArea())
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showAddSheet) { AddWarrantySheet() }
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                (Text("Warranty")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                 + Text(" Pocket")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accent))
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill").font(.system(size: 17)).foregroundStyle(Theme.sub)
                    .frame(width: 38, height: 38).background(Theme.surface, in: Circle())
            }
        }
        .padding(.horizontal, 20).padding(.top, 8)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.items)
            centerAddButton
            tabButton(.archive)
            tabButton(.insights)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12).padding(.bottom, 28)
        .background(
            Theme.surface
                .overlay(Rectangle().fill(Theme.accent.opacity(0.05)).frame(height: 1).offset(y: -0.5), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let sel = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: sel ? .bold : .regular))
                    .foregroundStyle(sel ? Theme.accent : Theme.muted)
                    .scaleEffect(sel ? 1.1 : 1.0)
                Text(tab.label)
                    .font(.system(size: 10, weight: sel ? .bold : .medium, design: .rounded))
                    .foregroundStyle(sel ? Theme.accent : Theme.muted)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var centerAddButton: some View {
        Button { showAddSheet = true } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Theme.accent, Theme.secondary],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                    .shadow(color: Theme.accent.opacity(0.4), radius: 12, y: 4)
                Image(systemName: "plus").font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
            }
            .offset(y: -16)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Home Dashboard
struct HomeContent: View {
    @EnvironmentObject var manager: PocketManager
    @Binding var showAddSheet: Bool

    var body: some View {
        VStack(spacing: 16) {
            heroCard
            if !manager.expiringWarranties.isEmpty { expiringSection }
            if !manager.recentWarranties.isEmpty { recentSection }
            coverageOverview
        }
        .padding(.horizontal, 20).padding(.bottom, 30)
    }

    private var heroCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                statBubble("\(manager.nonArchivedWarranties.count)", "Total", Theme.accent)
                statBubble("\(manager.activeWarranties.count)", "Active", Theme.success)
                statBubble("\(manager.expiringWarranties.count)", "Expiring", Theme.warning)
                statBubble(String(format: "$%.0f", manager.totalProtectedValue), "Protected", Theme.secondary)
            }
            Button { showAddSheet = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill").font(.system(size: 15))
                    Text("Add Warranty").font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [Theme.accent, Theme.secondary],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
        }
        .glowCard()
    }

    private func statBubble(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10, design: .rounded)).foregroundStyle(Theme.sub)
        }
        .frame(maxWidth: .infinity)
    }

    private var expiringSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.warning).font(.system(size: 14))
                Text("Expiring Soon").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            }
            ForEach(manager.expiringWarranties) { item in
                warrantyMiniRow(item)
            }
        }
        .glowCard()
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recently Added").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            ForEach(manager.recentWarranties) { item in
                warrantyMiniRow(item)
            }
        }
        .glowCard()
    }

    private var coverageOverview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coverage Overview").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            let breakdown = manager.statusBreakdown()
            let total = max(1, breakdown.map(\.value).reduce(0, +))
            ForEach(breakdown) { point in
                HStack(spacing: 10) {
                    Circle().fill(point.color).frame(width: 10, height: 10)
                    Text(point.label).font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.text)
                    Spacer()
                    Text("\(Int(point.value))").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(point.color)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3).fill(point.color.opacity(0.2)).frame(width: geo.size.width)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(point.color)
                                    .frame(width: max(0, geo.size.width * (point.value / total)))
                            }
                    }
                    .frame(width: 60, height: 6)
                }
            }
        }
        .glowCard()
    }

    private func warrantyMiniRow(_ item: WarrantyItem) -> some View {
        HStack(spacing: 12) {
            Text(item.category.emoji).font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(item.category.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text).lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: item.status.icon).font(.system(size: 10)).foregroundStyle(item.status.color)
                    Text(item.store).font(.system(size: 11, design: .rounded)).foregroundStyle(Theme.sub)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.daysRemaining)d").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(item.status.color)
                Text("left").font(.system(size: 9, design: .rounded)).foregroundStyle(Theme.muted)
            }
        }
        .padding(.vertical, 2)
    }
}
