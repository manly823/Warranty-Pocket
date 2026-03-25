import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var manager: PocketManager
    @State private var selectedItem: WarrantyItem?

    var body: some View {
        VStack(spacing: 16) {
            header
            if manager.archivedWarranties.isEmpty && manager.expiredWarranties.isEmpty {
                emptyState
            } else {
                if !manager.expiredWarranties.isEmpty { expiredSection }
                if !manager.archivedWarranties.isEmpty { archivedSection }
            }
        }
        .padding(.horizontal, 20).padding(.bottom, 30)
        .sheet(item: $selectedItem) { item in WarrantyDetailView(item: item) }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(manager.archivedWarranties.count + manager.expiredWarranties.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(Theme.muted)
                Text("Archived & Expired").font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
            }
            Spacer()
            Image(systemName: "archivebox.fill").font(.system(size: 24)).foregroundStyle(Theme.muted)
        }
        .glowCard()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill").font(.system(size: 40)).foregroundStyle(Theme.success.opacity(0.5))
            Text("No expired warranties").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(Theme.sub)
            Text("All your warranties are active — great!").font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.muted)
        }
        .padding(.vertical, 40).frame(maxWidth: .infinity).glowCard()
    }

    private var expiredSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "xmark.shield.fill").foregroundStyle(Theme.danger).font(.system(size: 14))
                Text("Expired").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            }
            ForEach(manager.expiredWarranties) { item in archiveRow(item) }
        }
        .glowCard()
    }

    private var archivedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "archivebox.fill").foregroundStyle(Theme.muted).font(.system(size: 14))
                Text("Archived").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            }
            ForEach(manager.archivedWarranties) { item in archiveRow(item) }
        }
        .glowCard()
    }

    private func archiveRow(_ item: WarrantyItem) -> some View {
        Button { selectedItem = item } label: {
            HStack(spacing: 12) {
                Text(item.category.emoji).font(.system(size: 18))
                    .frame(width: 36, height: 36)
                    .background(Theme.muted.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text).lineLimit(1)
                    Text("Expired \(item.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 11, design: .rounded)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Text(String(format: "$%.0f", item.purchasePrice))
                    .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Theme.muted)
            }
            .padding(.vertical, 2)
        }
    }
}
