import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var manager: PocketManager
    @Environment(\.dismiss) var dismiss
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    appInfo
                    dataSection
                    notificationSection
                    dangerZone
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(Theme.accent)
                }
            }
            .alert("Reset All Data?", isPresented: $showReset) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { manager.resetAllData(); dismiss() }
            } message: {
                Text("This will permanently delete all warranties, receipt images, and settings. This cannot be undone.")
            }
        }
    }

    private var appInfo: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.1)).frame(width: 70, height: 70)
                Image(systemName: "shield.fill").font(.system(size: 30)).foregroundStyle(Theme.accent)
            }
            Text("Warranty Pocket").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            Text("Version 1.0").font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity).glowCard()
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Data Summary").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            infoRow("Total Warranties", "\(manager.warranties.count)")
            infoRow("Active", "\(manager.activeWarranties.count)")
            infoRow("Expiring Soon", "\(manager.expiringWarranties.count)")
            infoRow("Expired", "\(manager.expiredWarranties.count)")
            infoRow("Archived", "\(manager.archivedWarranties.count)")
            infoRow("Protected Value", String(format: "$%.2f", manager.totalProtectedValue))
        }
        .glowCard()
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notifications").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            Text("Reminders are sent at 30 days, 7 days, and 1 day before each warranty expires.")
                .font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
            Button {
                NotificationHelper.shared.scheduleAll(for: manager.warranties)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 14))
                    Text("Re-sync Reminders").font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Theme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .glowCard()
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Danger Zone").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.danger)
            Button { showReset = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill").font(.system(size: 14))
                    Text("Reset All Data").font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Theme.danger)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Theme.danger.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .glowCard()
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text)
        }
    }
}
