import SwiftUI
import UIKit

final class PocketManager: ObservableObject {
    @Published var warranties: [WarrantyItem] = [] {
        didSet { save("wp_warranties", warranties); NotificationHelper.shared.scheduleAll(for: warranties) }
    }
    @Published var onboardingDone: Bool {
        didSet { UserDefaults.standard.set(onboardingDone, forKey: "wp_onboarding") }
    }

    init() {
        onboardingDone = UserDefaults.standard.bool(forKey: "wp_onboarding")
        warranties = Storage.shared.load(forKey: "wp_warranties", default: Self.sampleWarranties)
    }

    private func save<T: Codable>(_ key: String, _ value: T) { Storage.shared.save(value, forKey: key) }

    // MARK: - CRUD

    func addWarranty(_ item: WarrantyItem) { warranties.append(item) }

    func updateWarranty(_ item: WarrantyItem) {
        guard let idx = warranties.firstIndex(where: { $0.id == item.id }) else { return }
        warranties[idx] = item
    }

    func deleteWarranty(_ item: WarrantyItem) {
        if let imgName = item.receiptImageName { deleteImage(named: imgName) }
        warranties.removeAll { $0.id == item.id }
    }

    func archiveWarranty(_ item: WarrantyItem) {
        guard let idx = warranties.firstIndex(where: { $0.id == item.id }) else { return }
        warranties[idx].isArchived = true
    }

    func unarchiveWarranty(_ item: WarrantyItem) {
        guard let idx = warranties.firstIndex(where: { $0.id == item.id }) else { return }
        warranties[idx].isArchived = false
    }

    // MARK: - Image Storage

    private var imagesDir: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ReceiptImages")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        let name = UUID().uuidString + ".jpg"
        try? data.write(to: imagesDir.appendingPathComponent(name))
        return name
    }

    func loadImage(named name: String) -> UIImage? {
        guard let data = try? Data(contentsOf: imagesDir.appendingPathComponent(name)) else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(named name: String) {
        try? FileManager.default.removeItem(at: imagesDir.appendingPathComponent(name))
    }

    // MARK: - Queries

    var activeWarranties: [WarrantyItem] {
        warranties.filter { !$0.isArchived && $0.status == .active }.sorted { $0.expiryDate < $1.expiryDate }
    }

    var expiringWarranties: [WarrantyItem] {
        warranties.filter { !$0.isArchived && $0.status == .expiringSoon }.sorted { $0.daysRemaining < $1.daysRemaining }
    }

    var expiredWarranties: [WarrantyItem] {
        warranties.filter { !$0.isArchived && $0.status == .expired }.sorted { $0.expiryDate > $1.expiryDate }
    }

    var archivedWarranties: [WarrantyItem] {
        warranties.filter { $0.isArchived }.sorted { $0.expiryDate > $1.expiryDate }
    }

    var nonArchivedWarranties: [WarrantyItem] {
        warranties.filter { !$0.isArchived }.sorted { $0.expiryDate < $1.expiryDate }
    }

    var recentWarranties: [WarrantyItem] {
        Array(warranties.filter { !$0.isArchived }.sorted { $0.purchaseDate > $1.purchaseDate }.prefix(5))
    }

    // MARK: - Stats

    var totalProtectedValue: Double {
        warranties.filter { !$0.isArchived && $0.status != .expired }.map(\.purchasePrice).reduce(0, +)
    }

    var totalValue: Double {
        warranties.map(\.purchasePrice).reduce(0, +)
    }

    var avgWarrantyMonths: Double {
        guard !warranties.isEmpty else { return 0 }
        return Double(warranties.map(\.warrantyMonths).reduce(0, +)) / Double(warranties.count)
    }

    func categoryDistribution() -> [ChartPoint] {
        let grouped = Dictionary(grouping: warranties.filter { !$0.isArchived }, by: { $0.category })
        return ItemCategory.allCases.compactMap { cat in
            let count = grouped[cat]?.count ?? 0
            guard count > 0 else { return nil }
            return ChartPoint(id: cat.rawValue, label: cat.name, value: Double(count), color: cat.color)
        }
    }

    func categoryValueDistribution() -> [ChartPoint] {
        let grouped = Dictionary(grouping: warranties.filter { !$0.isArchived }, by: { $0.category })
        return ItemCategory.allCases.compactMap { cat in
            let items = grouped[cat] ?? []
            guard !items.isEmpty else { return nil }
            let total = items.map(\.purchasePrice).reduce(0, +)
            return ChartPoint(id: cat.rawValue, label: cat.name, value: total, color: cat.color)
        }.sorted { $0.value > $1.value }
    }

    func expiryTimeline() -> [ChartPoint] {
        let ranges: [(String, Int, Int)] = [
            ("This Month", 0, 30),
            ("1–3 Months", 31, 90),
            ("3–6 Months", 91, 180),
            ("6–12 Months", 181, 365),
            ("1+ Year", 366, 99999)
        ]
        return ranges.map { label, minD, maxD in
            let count = warranties.filter {
                !$0.isArchived && $0.status != .expired && $0.daysRemaining >= minD && $0.daysRemaining <= maxD
            }.count
            return ChartPoint(id: label, label: label, value: Double(count), color: Theme.accent)
        }
    }

    func statusBreakdown() -> [ChartPoint] {
        let active = warranties.filter { !$0.isArchived && $0.status == .active }.count
        let expiring = warranties.filter { !$0.isArchived && $0.status == .expiringSoon }.count
        let expired = warranties.filter { !$0.isArchived && $0.status == .expired }.count
        return [
            ChartPoint(id: "active", label: "Active", value: Double(active), color: Theme.success),
            ChartPoint(id: "expiring", label: "Expiring", value: Double(expiring), color: Theme.warning),
            ChartPoint(id: "expired", label: "Expired", value: Double(expired), color: Theme.danger)
        ]
    }

    func topValueItems() -> [WarrantyItem] {
        Array(warranties.filter { !$0.isArchived }.sorted { $0.purchasePrice > $1.purchasePrice }.prefix(5))
    }

    // MARK: - Reset

    func resetAllData() {
        for w in warranties { if let img = w.receiptImageName { deleteImage(named: img) } }
        warranties = []; onboardingDone = false
        Storage.shared.remove(forKey: "wp_warranties")
        UserDefaults.standard.removeObject(forKey: "wp_onboarding")
    }

    // MARK: - Sample Data

    private static var sampleWarranties: [WarrantyItem] {
        let cal = Calendar.current
        func monthsAgo(_ m: Int) -> Date { cal.date(byAdding: .month, value: -m, to: Date())! }

        return [
            WarrantyItem(name: "MacBook Pro 14\"", store: "Apple Store", category: .electronics,
                         purchaseDate: monthsAgo(8), warrantyMonths: 12, purchasePrice: 1999.00,
                         notes: "Space Gray, M3 Pro chip, base model"),
            WarrantyItem(name: "Samsung 55\" OLED TV", store: "Best Buy", category: .electronics,
                         purchaseDate: monthsAgo(14), warrantyMonths: 24, purchasePrice: 1299.00,
                         notes: "Wall mounted in living room, extended warranty included"),
            WarrantyItem(name: "Dyson V15 Vacuum", store: "Dyson.com", category: .appliances,
                         purchaseDate: monthsAgo(3), warrantyMonths: 24, purchasePrice: 749.00,
                         notes: "Cordless stick vacuum with laser detect head"),
            WarrantyItem(name: "IKEA MALM Desk", store: "IKEA", category: .furniture,
                         purchaseDate: monthsAgo(24), warrantyMonths: 120, purchasePrice: 199.00,
                         notes: "White finish, 140x65 cm, home office setup"),
            WarrantyItem(name: "Apple Watch Ultra 2", store: "Apple Store", category: .electronics,
                         purchaseDate: monthsAgo(11), warrantyMonths: 12, purchasePrice: 799.00,
                         notes: "Titanium, Alpine Loop band — warranty ending soon!"),
            WarrantyItem(name: "Bosch Impact Drill GSB 18V", store: "Home Depot", category: .tools,
                         purchaseDate: monthsAgo(6), warrantyMonths: 36, purchasePrice: 189.00,
                         notes: "18V cordless, 2 batteries and charger included"),
            WarrantyItem(name: "Nike Air Max 90", store: "Nike.com", category: .clothing,
                         purchaseDate: monthsAgo(5), warrantyMonths: 6, purchasePrice: 130.00,
                         notes: "Size 10, white/black colorway"),
            WarrantyItem(name: "Canada Goose Expedition Parka", store: "Nordstrom", category: .clothing,
                         purchaseDate: monthsAgo(9), warrantyMonths: 12, purchasePrice: 1150.00,
                         notes: "Black, size M, keep receipt for lifetime craftsmanship warranty"),
            WarrantyItem(name: "Continental AGM Car Battery", store: "AutoZone", category: .automotive,
                         purchaseDate: monthsAgo(18), warrantyMonths: 36, purchasePrice: 185.00,
                         notes: "Group 48, free replacement in first 24 months"),
            WarrantyItem(name: "KitchenAid Diamond Blender", store: "Williams Sonoma", category: .appliances,
                         purchaseDate: monthsAgo(13), warrantyMonths: 12, purchasePrice: 99.00,
                         notes: "5-speed, empire red — warranty may have expired"),
            WarrantyItem(name: "Sony WH-1000XM5", store: "Amazon", category: .electronics,
                         purchaseDate: monthsAgo(5), warrantyMonths: 12, purchasePrice: 349.00,
                         notes: "Noise canceling headphones, silver finish"),
            WarrantyItem(name: "Herman Miller Aeron Chair", store: "Herman Miller", category: .furniture,
                         purchaseDate: monthsAgo(6), warrantyMonths: 144, purchasePrice: 1395.00,
                         notes: "Size B, fully loaded, graphite, 12-year warranty"),
        ]
    }
}
