import SwiftUI

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case electronics, appliances, furniture, clothing, automotive, sports, tools, jewelry, other

    var id: String { rawValue }

    var name: String {
        switch self {
        case .electronics: return "Electronics"
        case .appliances: return "Appliances"
        case .furniture: return "Furniture"
        case .clothing: return "Clothing"
        case .automotive: return "Automotive"
        case .sports: return "Sports"
        case .tools: return "Tools"
        case .jewelry: return "Jewelry"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .electronics: return "laptopcomputer"
        case .appliances: return "refrigerator.fill"
        case .furniture: return "sofa.fill"
        case .clothing: return "tshirt.fill"
        case .automotive: return "car.fill"
        case .sports: return "figure.run"
        case .tools: return "wrench.and.screwdriver.fill"
        case .jewelry: return "sparkles"
        case .other: return "shippingbox.fill"
        }
    }

    var emoji: String {
        switch self {
        case .electronics: return "💻"
        case .appliances: return "🏠"
        case .furniture: return "🪑"
        case .clothing: return "👕"
        case .automotive: return "🚗"
        case .sports: return "⚽"
        case .tools: return "🔧"
        case .jewelry: return "💎"
        case .other: return "📦"
        }
    }

    var color: Color {
        switch self {
        case .electronics: return Color(red: 0.35, green: 0.55, blue: 0.95)
        case .appliances: return Color(red: 0.2, green: 0.78, blue: 0.65)
        case .furniture: return Color(red: 0.78, green: 0.55, blue: 0.3)
        case .clothing: return Color(red: 0.85, green: 0.4, blue: 0.6)
        case .automotive: return Color(red: 0.55, green: 0.55, blue: 0.55)
        case .sports: return Color(red: 0.3, green: 0.75, blue: 0.4)
        case .tools: return Color(red: 0.9, green: 0.65, blue: 0.2)
        case .jewelry: return Color(red: 0.8, green: 0.6, blue: 0.9)
        case .other: return Color(red: 0.6, green: 0.6, blue: 0.65)
        }
    }
}

enum WarrantyStatus {
    case active, expiringSoon, expired

    var name: String {
        switch self {
        case .active: return "Active"
        case .expiringSoon: return "Expiring Soon"
        case .expired: return "Expired"
        }
    }

    var color: Color {
        switch self {
        case .active: return Color(red: 0.2, green: 0.78, blue: 0.45)
        case .expiringSoon: return Color(red: 0.95, green: 0.75, blue: 0.2)
        case .expired: return Color(red: 0.9, green: 0.3, blue: 0.3)
        }
    }

    var icon: String {
        switch self {
        case .active: return "checkmark.shield.fill"
        case .expiringSoon: return "exclamationmark.triangle.fill"
        case .expired: return "xmark.shield.fill"
        }
    }
}

struct WarrantyItem: Codable, Identifiable {
    let id: UUID
    var name: String
    var store: String
    var category: ItemCategory
    var purchaseDate: Date
    var warrantyMonths: Int
    var purchasePrice: Double
    var notes: String
    var receiptImageName: String?
    var ocrText: String
    var isArchived: Bool

    init(name: String, store: String, category: ItemCategory, purchaseDate: Date,
         warrantyMonths: Int, purchasePrice: Double, notes: String = "",
         receiptImageName: String? = nil, ocrText: String = "") {
        self.id = UUID()
        self.name = name
        self.store = store
        self.category = category
        self.purchaseDate = purchaseDate
        self.warrantyMonths = warrantyMonths
        self.purchasePrice = purchasePrice
        self.notes = notes
        self.receiptImageName = receiptImageName
        self.ocrText = ocrText
        self.isArchived = false
    }

    var expiryDate: Date {
        Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate) ?? purchaseDate
    }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0)
    }

    var totalDays: Int {
        max(1, Calendar.current.dateComponents([.day], from: purchaseDate, to: expiryDate).day ?? 1)
    }

    var progress: Double {
        let elapsed = totalDays - daysRemaining
        return min(1, max(0, Double(elapsed) / Double(totalDays)))
    }

    var status: WarrantyStatus {
        if daysRemaining == 0 { return .expired }
        if daysRemaining <= 30 { return .expiringSoon }
        return .active
    }

    var warrantyText: String {
        if warrantyMonths >= 12 && warrantyMonths % 12 == 0 {
            let years = warrantyMonths / 12
            return years == 1 ? "1 year" : "\(years) years"
        }
        return warrantyMonths == 1 ? "1 month" : "\(warrantyMonths) months"
    }
}

struct ChartPoint: Identifiable {
    let id: String
    let label: String
    let value: Double
    var color: Color = .white
}
