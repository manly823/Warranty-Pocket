import SwiftUI

// MARK: - Warranties List
struct WarrantiesView: View {
    @EnvironmentObject var manager: PocketManager
    @Binding var showAddSheet: Bool
    @State private var search = ""
    @State private var selectedCategory: ItemCategory?
    @State private var selectedItem: WarrantyItem?

    private var filteredItems: [WarrantyItem] {
        var items = manager.nonArchivedWarranties
        if let cat = selectedCategory { items = items.filter { $0.category == cat } }
        if !search.isEmpty {
            items = items.filter {
                $0.name.localizedCaseInsensitiveContains(search) ||
                $0.store.localizedCaseInsensitiveContains(search)
            }
        }
        return items
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            searchBar
            categoryChips
            warrantyList
        }
        .padding(.horizontal, 20).padding(.bottom, 30)
        .sheet(item: $selectedItem) { item in WarrantyDetailView(item: item) }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(manager.nonArchivedWarranties.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(Theme.accent)
                Text("Warranties").font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
            }
            Spacer()
            Button { showAddSheet = true } label: {
                Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white).frame(width: 40, height: 40)
                    .background(Theme.accent, in: Circle())
            }
        }
        .glowCard()
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
            TextField("Search warranties…", text: $search)
                .font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.text)
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipBtn("All", selectedCategory == nil) { selectedCategory = nil }
                ForEach(usedCategories, id: \.rawValue) { cat in
                    chipBtn("\(cat.emoji) \(cat.name)", selectedCategory == cat) {
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    }
                }
            }
        }
    }

    private var usedCategories: [ItemCategory] {
        let cats = Set(manager.nonArchivedWarranties.map(\.category))
        return ItemCategory.allCases.filter { cats.contains($0) }
    }

    private func chipBtn(_ label: String, _ selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: selected ? .bold : .medium, design: .rounded))
                .foregroundStyle(selected ? .white : Theme.sub)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(selected ? Theme.accent : Theme.surface, in: Capsule())
        }
    }

    private var warrantyList: some View {
        VStack(spacing: 10) {
            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "shield.slash").font(.system(size: 28)).foregroundStyle(Theme.muted)
                    Text("No warranties found").font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30).glowCard()
            } else {
                ForEach(filteredItems) { item in
                    WarrantyCard(item: item) { selectedItem = item }
                }
            }
        }
    }
}

// MARK: - Warranty Card
struct WarrantyCard: View {
    let item: WarrantyItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                CountdownRing(item: item, size: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text).lineLimit(1)
                    HStack(spacing: 6) {
                        Text(item.category.emoji).font(.system(size: 11))
                        Text(item.store).font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub).lineLimit(1)
                    }
                    HStack(spacing: 8) {
                        Label(item.status.name, systemImage: item.status.icon)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(item.status.color)
                        Text("·").foregroundStyle(Theme.muted)
                        Text(item.warrantyText).font(.system(size: 10, design: .rounded)).foregroundStyle(Theme.muted)
                    }
                }
                Spacer()
                Text(String(format: "$%.0f", item.purchasePrice))
                    .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Theme.secondary)
            }
            .glowCard()
        }
    }
}

// MARK: - Warranty Detail
struct WarrantyDetailView: View {
    @EnvironmentObject var manager: PocketManager
    @Environment(\.dismiss) var dismiss
    let item: WarrantyItem

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statusHeader
                    detailsCard
                    datesCard
                    if let imgName = item.receiptImageName, let img = manager.loadImage(named: imgName) {
                        receiptImageCard(img)
                    }
                    if !item.ocrText.isEmpty { ocrCard }
                    if !item.notes.isEmpty { notesCard }
                    actionButtons
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundStyle(Theme.sub)
                }
            }
        }
    }

    private var statusHeader: some View {
        VStack(spacing: 16) {
            CountdownRing(item: item, size: 100)
            HStack(spacing: 6) {
                Image(systemName: item.status.icon).foregroundStyle(item.status.color)
                Text(item.status.name).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(item.status.color)
            }
            Text(item.status == .expired ? "Warranty expired" : "\(item.daysRemaining) days remaining")
                .font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
        }
        .frame(maxWidth: .infinity).glowCard()
    }

    private var detailsCard: some View {
        VStack(spacing: 10) {
            row("Product", item.name)
            row("Store", item.store)
            row("Category", "\(item.category.emoji) \(item.category.name)")
            row("Price", String(format: "$%.2f", item.purchasePrice))
            row("Warranty", item.warrantyText)
        }
        .glowCard()
    }

    private var datesCard: some View {
        VStack(spacing: 10) {
            row("Purchased", item.purchaseDate.formatted(date: .abbreviated, time: .omitted))
            row("Expires", item.expiryDate.formatted(date: .abbreviated, time: .omitted))
        }
        .glowCard()
    }

    private func receiptImageCard(_ img: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Receipt").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            Image(uiImage: img).resizable().scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .glowCard()
    }

    private var ocrCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.viewfinder").foregroundStyle(Theme.accent)
                Text("Receipt Text").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            }
            Text(item.ocrText).font(.system(size: 12, design: .monospaced)).foregroundStyle(Theme.sub).lineLimit(20)
        }
        .glowCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            Text(item.notes).font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
        }
        .glowCard()
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if !item.isArchived {
                actionRow("archivebox.fill", "Move to Archive", Theme.warning) {
                    manager.archiveWarranty(item); dismiss()
                }
            } else {
                actionRow("arrow.uturn.backward", "Restore from Archive", Theme.accent) {
                    manager.unarchiveWarranty(item); dismiss()
                }
            }
            actionRow("trash.fill", "Delete Warranty", Theme.danger) {
                manager.deleteWarranty(item); dismiss()
            }
        }
    }

    private func actionRow(_ icon: String, _ label: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14))
                Text(label).font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text)
        }
    }
}

// MARK: - Add Warranty Sheet
struct AddWarrantySheet: View {
    @EnvironmentObject var manager: PocketManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var store = ""
    @State private var category: ItemCategory = .electronics
    @State private var purchaseDate = Date()
    @State private var warrantyMonths = 12
    @State private var price = ""
    @State private var notes = ""
    @State private var receiptImage: UIImage?
    @State private var ocrText = ""
    @State private var ocrProcessing = false
    @State private var photoSource: PhotoSource?

    private let warrantyOptions = [3, 6, 12, 18, 24, 36, 48, 60, 120]

    enum PhotoSource: Int, Identifiable {
        case camera, library
        var id: Int { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    receiptSection
                    productSection
                    warrantySection
                    notesSection
                    saveButton
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New Warranty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.sub)
                }
            }
            .fullScreenCover(item: $photoSource, onDismiss: runOCR) { source in
                ImagePicker(image: $receiptImage,
                            sourceType: source == .camera ? .camera : .photoLibrary)
                    .ignoresSafeArea()
            }
        }
    }

    private func runOCR() {
        guard let img = receiptImage else { return }
        ocrProcessing = true
        OCR.recognizeText(from: img) { text in
            ocrText = text
            ocrProcessing = false
            if let date = OCR.extractDate(from: text) { purchaseDate = date }
            if let p = OCR.extractPrice(from: text) { price = String(format: "%.2f", p) }
            if let s = OCR.extractStoreName(from: text), store.isEmpty { store = s }
        }
    }

    private var receiptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Receipt").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)

            if let img = receiptImage {
                Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if ocrProcessing {
                    HStack(spacing: 8) {
                        ProgressView().tint(Theme.accent)
                        Text("Reading text…").font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
                    }
                } else if !ocrText.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.success).font(.system(size: 14))
                        Text("Text recognition complete — review fields below").font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.success)
                    }
                }

                Button { receiptImage = nil; ocrText = "" } label: {
                    Text("Remove Photo").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.danger)
                }
            } else {
                HStack(spacing: 12) {
                    scanBtn("camera.fill", "Camera") {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) { photoSource = .camera }
                    }
                    scanBtn("photo.on.rectangle", "Library") { photoSource = .library }
                }
            }
        }
        .glowCard()
    }

    private func scanBtn(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 24)).foregroundStyle(Theme.accent)
                Text(label).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 20)
            .background(Theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6])))
        }
    }

    private var productSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Product").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            formField("Product Name", $name)
            formField("Store Name", $store)

            VStack(alignment: .leading, spacing: 6) {
                Text("Category").font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(ItemCategory.allCases) { cat in
                        Button { category = cat } label: {
                            VStack(spacing: 4) {
                                Text(cat.emoji).font(.system(size: 18))
                                Text(cat.name).font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(category == cat ? .white : Theme.text).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(category == cat ? cat.color : Theme.card,
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Purchase Price").font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub)
                HStack {
                    Text("$").foregroundStyle(Theme.accent).font(.system(size: 16, weight: .bold))
                    TextField("0.00", text: $price)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.text)
                }
                .padding(12)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .glowCard()
    }

    private var warrantySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Warranty").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)

            VStack(alignment: .leading, spacing: 6) {
                Text("Purchase Date").font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub)
                DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                    .datePickerStyle(.compact).labelsHidden().tint(Theme.accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Duration").font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(warrantyOptions, id: \.self) { months in
                            let label = months >= 12 ? "\(months / 12)y" : "\(months)mo"
                            Button { warrantyMonths = months } label: {
                                Text(label)
                                    .font(.system(size: 13, weight: warrantyMonths == months ? .bold : .medium, design: .rounded))
                                    .foregroundStyle(warrantyMonths == months ? .white : Theme.sub)
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(warrantyMonths == months ? Theme.accent : Theme.card, in: Capsule())
                            }
                        }
                    }
                }
            }
        }
        .glowCard()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            TextField("Optional notes…", text: $notes, axis: .vertical)
                .font(.system(size: 14, design: .rounded)).foregroundStyle(Theme.text)
                .lineLimit(3...5).padding(12)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .glowCard()
    }

    private var saveButton: some View {
        Button {
            let n = name.trimmingCharacters(in: .whitespaces)
            guard !n.isEmpty else { return }
            var imageName: String?
            if let img = receiptImage { imageName = manager.saveImage(img) }
            let item = WarrantyItem(
                name: n, store: store.trimmingCharacters(in: .whitespaces),
                category: category, purchaseDate: purchaseDate,
                warrantyMonths: warrantyMonths, purchasePrice: Double(price) ?? 0,
                notes: notes, receiptImageName: imageName, ocrText: ocrText
            )
            manager.addWarranty(item)
            dismiss()
        } label: {
            Text("Save Warranty").font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(
                    name.trimmingCharacters(in: .whitespaces).isEmpty ? AnyShapeStyle(Theme.muted) :
                    AnyShapeStyle(LinearGradient(colors: [Theme.accent, Theme.secondary],
                                                startPoint: .leading, endPoint: .trailing)),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
        }
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func formField(_ placeholder: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(placeholder).font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub)
            TextField(placeholder, text: text)
                .font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.text)
                .padding(12)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
