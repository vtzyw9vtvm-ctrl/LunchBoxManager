import SwiftUI
import FirebaseCore
import FirebaseFirestore
import AppKit

struct CafeOrdersView: View {
    @State private var orders: [CafeOrder] = []
    @State private var listener: ListenerRegistration?
    @State private var errorMessage: String?
    @State private var selectedHistoryOrder: CafeOrder?
    @State private var historySearchText = ""
    
    private var activeOrders: [CafeOrder] {
        orders.filter {
            $0.status.lowercased() != "completed"
        }
    }

    private var completedOrders: [CafeOrder] {
        let completed = orders
            .filter {
                $0.status.lowercased() == "completed"
            }
            .sorted {
                $0.placedAt > $1.placedAt
            }

        let search = historySearchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !search.isEmpty else {
            return completed
        }

        return completed.filter { order in
            order.orderNumber.lowercased().contains(search) ||
            order.customerName.lowercased().contains(search)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if let errorMessage {
                ContentUnavailableView(
                    "Unable to Load Cafe Orders",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )

            } else if orders.isEmpty {
                ContentUnavailableView(
                    "No Cafe Orders",
                    systemImage: "cup.and.saucer",
                    description: Text(
                        "New Espresso Cafe orders will appear here."
                    )
                )

            } else {
                HStack(alignment: .top, spacing: 0) {

                    // MARK: - Live Orders
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                HStack(spacing: 10) {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.green)

                                    Text("Live Orders")
                                        .font(.system(size: 22, weight: .bold))
                                }

                                Spacer()

                                Text("\(activeOrders.count) active")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                Color.green.opacity(0.16)
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 10)
                            )

                            if activeOrders.isEmpty {
                                ContentUnavailableView(
                                    "No Active Orders",
                                    systemImage: "checkmark.circle",
                                    description: Text(
                                        "New Cafe orders will appear here."
                                    )
                                )
                                .frame(minHeight: 250)

                            } else {
                                ForEach(activeOrders) { order in
                                    CafeOrderCard(
                                        order: order,
                                        onStatusChange: { newStatus in
                                            updateOrderStatus(
                                                orderID: order.id,
                                                status: newStatus
                                            )
                                        }
                                    )
                                }
                            }
                        }
                        .padding(24)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    // MARK: - History
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("History")
                                    .font(.system(size: 22, weight: .bold))

                                Spacer()

                                Text(
                                    historySearchText
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                        .isEmpty
                                        ? "\(completedOrders.count) completed"
                                        : "\(completedOrders.count) result\(completedOrders.count == 1 ? "" : "s")"
                                )
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            }
                            
                            TextField(
                                "Search name or order number",
                                text: $historySearchText
                            )
                            .textFieldStyle(.roundedBorder)

                            if completedOrders.isEmpty {
                                ContentUnavailableView(
                                    "No History",
                                    systemImage: "clock.arrow.circlepath",
                                    description: Text(
                                        "Completed orders will appear here."
                                    )
                                )
                                .frame(minHeight: 250)

                            } else {
                                ForEach(completedOrders) { order in
                                    CafeOrderHistoryRow(
                                        order: order
                                    )
                                    .onTapGesture {
                                        selectedHistoryOrder = order
                                    }
                                }
                            }
                        }
                        .padding(24)
                    }
                    .frame(
                        minWidth: 420,
                        idealWidth: 500,
                        maxWidth: 560
                    )
                }
            }
        }
        .background(
            Color(nsColor: .windowBackgroundColor)
        )
        .onAppear {
            startListening()
        }
        .onDisappear {
            listener?.remove()
            listener = nil
        }
        .sheet(item: $selectedHistoryOrder) { order in
            CafeOrderDetailView(order: order)
        }
    }
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cafe Orders")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Live orders from the Espresso Cafe app")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                
                Text("Live")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
    }
    
    private func startListening() {
        listener?.remove()
        errorMessage = nil
        
        let espressoApp: FirebaseApp
        
        if let existingApp = FirebaseApp.app(
            name: "EspressoCafe"
        ) {
            espressoApp = existingApp
        } else {
            guard let plistPath = Bundle.main.path(
                forResource: "GoogleService-Info-Espresso",
                ofType: "plist"
            ),
                  let options = FirebaseOptions(
                    contentsOfFile: plistPath
                  ) else {
                errorMessage =
                "Could not load the Espresso Cafe Firebase configuration."
                print("❌ ESPRESSO FIREBASE CONFIG NOT FOUND")
                return
            }
            
            FirebaseApp.configure(
                name: "EspressoCafe",
                options: options
            )
            
            guard let configuredApp = FirebaseApp.app(
                name: "EspressoCafe"
            ) else {
                errorMessage =
                "Could not connect to Espresso Cafe Firebase."
                print("❌ ESPRESSO FIREBASE APP NOT CREATED")
                return
            }
            
            espressoApp = configuredApp
        }
        
        let espressoFirestore = Firestore.firestore(
            app: espressoApp
        )
        
        listener = espressoFirestore
            .collection("orders")
            .whereField(
                "orderSource",
                isEqualTo: "cafe"
            )
            .addSnapshotListener { snapshot, error in
                
                if let error {
                    print(
                        "❌ CAFE ORDERS ERROR:",
                        error
                    )
                    errorMessage =
                    error.localizedDescription
                    return
                }
                
                guard let documents =
                        snapshot?.documents else {
                    orders = []
                    return
                }
                
                print(
                    "☕️ FIRESTORE RETURNED \(documents.count) CAFE DOCUMENTS"
                )
                
                let loadedOrders =
                documents.compactMap {
                    CafeOrder(document: $0)
                }
                
                orders = loadedOrders.sorted {
                    $0.placedAt > $1.placedAt
                }
                
                print(
                    "☕️ LIVE CAFE ORDERS:",
                    orders.count
                )
            }
    }
    
    
    private func updateOrderStatus(
        orderID: String,
        status: String
    ) {
        
        
        guard let espressoApp = FirebaseApp.app(
            name: "EspressoCafe"
        ) else {
            errorMessage =
            "Espresso Cafe Firebase is not connected."
            return
        }
        
        let espressoFirestore = Firestore.firestore(
            app: espressoApp
        )
        
        espressoFirestore
            .collection("orders")
            .document(orderID)
            .updateData([
                "status": status
            ]) { error in
                
                if let error {
                    print(
                        "❌ CAFE STATUS UPDATE ERROR:",
                        error
                    )
                    
                    DispatchQueue.main.async {
                        errorMessage =
                        "Could not update order status: " +
                        error.localizedDescription
                    }
                    
                    return
                }
                
                print(
                    "☕️ ORDER \(orderID) STATUS → \(status)"
                )
            }
    }
}

struct CafeOrder: Identifiable {
    let id: String
    let orderNumber: String
    let customerName: String
    let customerMobile: String
    let customerEmail: String
    let placedAt: Date
    let fulfilmentType: String
    let orderNotes: String

    let deliveryAddress: String
    let deliveryLatitude: Double
    let deliveryLongitude: Double
    let deliveryDistanceKm: Double
    let deliveryFee: Double
    let subtotal: Double

    let scheduledDateTime: Date?
    let status: String
    let total: Double
    let paymentStatus: String
    let paymentProvider: String
    let amountPaidCents: Int
    let items: [CafeOrderItem]

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()

        id = document.documentID

        orderNumber =
            data["orderNumber"] as? String ?? ""

        placedAt =
            (data["placedAt"] as? Timestamp)?.dateValue()
            ?? Date()

        fulfilmentType =
            data["fulfilmentType"] as? String
            ?? "pickup"

        orderNotes =
            data["orderNotes"] as? String
            ?? ""

        deliveryAddress =
            data["deliveryAddress"] as? String
            ?? ""

        deliveryLatitude =
            (data["deliveryLatitude"] as? NSNumber)?
                .doubleValue
            ?? 0

        deliveryLongitude =
            (data["deliveryLongitude"] as? NSNumber)?
                .doubleValue
            ?? 0

        deliveryDistanceKm =
            (data["deliveryDistanceKm"] as? NSNumber)?
                .doubleValue
            ?? 0

        deliveryFee =
            (data["deliveryFee"] as? NSNumber)?
                .doubleValue
            ?? 0

        subtotal =
            (data["subtotal"] as? NSNumber)?
                .doubleValue
            ?? (
                (data["total"] as? NSNumber)?
                    .doubleValue
                ?? 0
            )

        scheduledDateTime =
            (data["scheduledDateTime"] as? Timestamp)?
                .dateValue()

        status =
            data["status"] as? String
            ?? "pending"

        total =
            (data["total"] as? NSNumber)?
                .doubleValue
            ?? 0

        paymentStatus =
            data["paymentStatus"] as? String
            ?? ""

        paymentProvider =
            data["paymentProvider"] as? String
            ?? ""

        amountPaidCents =
            (data["amountPaidCents"] as? NSNumber)?
                .intValue
            ?? 0

        let customer =
            data["customer"] as? [String: Any]
            ?? [:]

        customerName =
            customer["name"] as? String
            ?? ""

        customerMobile =
            customer["mobile"] as? String
            ?? ""

        customerEmail =
            customer["email"] as? String
            ?? ""

        let rawItems =
            data["items"] as? [[String: Any]]
            ?? []

        items = rawItems.map {
            CafeOrderItem(data: $0)
        }
    }
}

struct CafeOrderItem: Identifiable {
    let id = UUID()

    let productName: String
    let quantity: Int
    let unitPrice: Double
    let modifiers: [CafeOrderModifier]
    let specialInstructions: String

    init(data: [String: Any]) {
        productName =
            data["productName"] as? String
            ?? ""

        quantity =
            (data["quantity"] as? NSNumber)?
                .intValue
            ?? 1

        unitPrice =
            (data["unitPrice"] as? NSNumber)?
                .doubleValue
            ?? 0
        
        specialInstructions =
            data["specialInstructions"] as? String
            ?? ""

        let rawModifiers =
            data["modifiers"] as? [[String: Any]]
            ?? []

        modifiers = rawModifiers.map {
            CafeOrderModifier(data: $0)
        }
    }
}

struct CafeOrderModifier: Identifiable {

    let id = UUID()

    let groupName: String

    let optionName: String

    let priceAdjustment: Double

    let quantity: Int

    let allowQuantities: Bool

    init(data: [String: Any]) {

        groupName =
            data["groupName"] as? String
            ?? ""

        optionName =
            data["optionName"] as? String
            ?? ""

        priceAdjustment =
            (data["priceAdjustment"] as? NSNumber)?
                .doubleValue
            ?? 0

        quantity =
            (data["quantity"] as? NSNumber)?
                .intValue
            ?? 1

        allowQuantities =
            data["allowQuantities"] as? Bool
            ?? false
    }
}

private struct CafeOrderCard: View {
    let order: CafeOrder
    let onStatusChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {

                HStack {
                    Text("Order #\(order.orderNumber)")
                        .font(.system(size: 18, weight: .bold))

                    Spacer()

                    Text(order.status.capitalized)
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )
                }

                HStack {
                    Label(
                        order.customerName.isEmpty
                            ? "Customer"
                            : order.customerName,
                        systemImage: "person"
                    )

                    Spacer()

                    Text(order.fulfilmentType.capitalized)
                        .fontWeight(
                            order.fulfilmentType.lowercased() == "delivery"
                                ? .bold
                                : .regular
                        )
                        .foregroundStyle(
                            order.fulfilmentType.lowercased() == "delivery"
                                ? .orange
                                : .secondary
                        )
                }

                if order.fulfilmentType.lowercased() == "delivery",
                   !order.deliveryAddress.isEmpty {

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("DELIVERY ADDRESS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.orange)

                            Text(order.deliveryAddress)
                                .font(.system(size: 15, weight: .semibold))

                            if order.deliveryDistanceKm > 0 {
                                Text(
                                    String(
                                        format: "%.1f km from cafe",
                                        order.deliveryDistanceKm
                                    )
                                )
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(
                        Color.orange.opacity(0.10)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 8)
                    )
                }
            }
            .padding(14)
            .background(
                order.status.lowercased() == "confirmed"
                    ? Color.blue.opacity(0.28)
                    : Color.blue.opacity(0.10)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 10)
            )

            Divider()

            ForEach(order.items) { item in
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    HStack {
                        Text(
                            "\(item.quantity) × \(item.productName)"
                        )
                        .fontWeight(.semibold)

                        Spacer()

                        Text(
                            "$\(item.unitPrice * Double(item.quantity), specifier: "%.2f")"
                        )
                    }

                    ForEach(item.modifiers) { modifier in
                        Text(
                            modifier.allowQuantities
                                ? "\(modifier.quantity) × \(modifier.optionName)"
                            : modifier.optionName
                        )
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    }
                    if !item.specialInstructions
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty {

                        Text("Notes: \(item.specialInstructions)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.orange)
                            .padding(.top, 2)
                    }
                }
            }
            let trimmedOrderNotes =
                order.orderNotes.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            if !trimmedOrderNotes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        Image(systemName: "note.text")
                            .foregroundStyle(.orange)

                        Text("ORDER NOTES")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.orange)
                    }

                    Text(trimmedOrderNotes)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(12)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .background(
                    Color.orange.opacity(0.10)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
            }
            Divider()
            
            if order.paymentProvider.lowercased() == "cash" &&
                order.paymentStatus.lowercased() != "paid" {

                HStack(spacing: 8) {
                    Image(systemName: "banknote.fill")

                    Text(
                        "CASH ON PICKUP — $\(order.total, specifier: "%.2f") DUE"
                    )
                    .fontWeight(.bold)

                    Spacer()
                }
                .font(.system(size: 15))
                .foregroundStyle(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Color.orange.opacity(0.12)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
            }

            if order.fulfilmentType.lowercased() == "delivery" {

                VStack(spacing: 6) {
                    HStack {
                        Text("Subtotal")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(
                            "$\(order.subtotal, specifier: "%.2f")"
                        )
                    }

                    HStack {
                        Text("Delivery Fee")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(
                            "$\(order.deliveryFee, specifier: "%.2f")"
                        )
                    }

                    HStack {
                        Text("Total")
                            .fontWeight(.bold)

                        Spacer()

                        Text(
                            "$\(order.total, specifier: "%.2f")"
                        )
                        .font(.system(size: 17, weight: .bold))
                    }
                }

                HStack {
                    Text(
                        order.placedAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                    .foregroundStyle(.secondary)

                    Spacer()
                }

            } else {

                HStack {
                    Text(
                        order.placedAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                    .foregroundStyle(.secondary)

                    Spacer()

                    Text(
                        "$\(order.total, specifier: "%.2f")"
                    )
                    .font(.system(size: 17, weight: .bold))
                }
            }
            if order.status.lowercased() != "completed" {

                Divider()

                HStack {
                    Spacer()

                    if order.status.lowercased() == "confirmed" {

                        Button("Accept Order") {
                            onStatusChange("accepted")
                        }
                        .buttonStyle(.borderedProminent)

                    } else if order.status.lowercased() == "accepted"
                                || order.status.lowercased() == "ready"
                                || order.status.lowercased() == "preparing" {

                        Button("Complete Order") {
                            onStatusChange("completed")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    Color.secondary.opacity(0.15),
                    lineWidth: 1
                )
        )
    }
}
private struct CafeOrderHistoryRow: View {

    let order: CafeOrder

    var body: some View {
        HStack(spacing: 20) {

            Text(
                order.placedAt.formatted(
                    date: .abbreviated,
                    time: .omitted
                )
            )
            .foregroundStyle(.secondary)
            .frame(width: 110, alignment: .leading)

            Text("#\(order.orderNumber)")
                .fontWeight(.semibold)
                .frame(width: 100, alignment: .leading)

            Text(
                order.customerName.isEmpty
                    ? "Customer"
                    : order.customerName
            )

            Spacer()

            Text("$\(order.total, specifier: "%.2f")")
                .fontWeight(.semibold)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    Color.secondary.opacity(0.12),
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
    }
}

private struct CafeOrderDetailView: View {

    let order: CafeOrder

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.orderNumber)")
                        .font(.system(size: 24, weight: .bold))

                    Text(
                        order.placedAt.formatted(
                            date: .long,
                            time: .shortened
                        )
                    )
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Close") {
                    dismiss()
                }
            }
            .padding(24)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Customer
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Customer")
                            .font(.headline)

                        Text(
                            order.customerName.isEmpty
                                ? "Customer"
                                : order.customerName
                        )

                        if !order.customerMobile.isEmpty {
                            Text(order.customerMobile)
                                .foregroundStyle(.secondary)
                        }

                        if !order.customerEmail.isEmpty {
                            Text(order.customerEmail)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // Order information
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Order Type")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(order.fulfilmentType.capitalized)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Status")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(order.status.capitalized)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    if order.fulfilmentType.lowercased() == "delivery",
                       !order.deliveryAddress.isEmpty {

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                    .foregroundStyle(.orange)

                                Text("DELIVERY ADDRESS")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.orange)
                            }

                            Text(order.deliveryAddress)
                                .font(.system(size: 15, weight: .semibold))

                            if order.deliveryDistanceKm > 0 {
                                Text(
                                    String(
                                        format: "%.1f km from cafe",
                                        order.deliveryDistanceKm
                                    )
                                )
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Color.orange.opacity(0.10)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8)
                        )
                    }

                    if let scheduledDateTime =
                        order.scheduledDateTime {

                        HStack {
                            Text("Scheduled for")
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(
                                scheduledDateTime.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .fontWeight(.semibold)
                        }
                    }

                    Divider()

                    // Items
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order")
                            .font(.headline)

                        ForEach(order.items) { item in
                            VStack(
                                alignment: .leading,
                                spacing: 5
                            ) {
                                HStack {
                                    Text(
                                        "\(item.quantity) × \(item.productName)"
                                    )
                                    .fontWeight(.semibold)

                                    Spacer()

                                    Text(
                                        "$\(item.unitPrice * Double(item.quantity), specifier: "%.2f")"
                                    )
                                }

                                ForEach(item.modifiers) { modifier in
                                    Text(
                                        modifier.allowQuantities
                                            ? "\(modifier.quantity) × \(modifier.optionName)"
                                        : modifier.optionName
                                    )
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                }
                                if !item.specialInstructions
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty {

                                    Text("Notes: \(item.specialInstructions)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.orange)
                                        .padding(.top, 2)
                                }
                            }
                        }
                    }
                    let trimmedOrderNotes =
                        order.orderNotes.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )

                    if !trimmedOrderNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "note.text")
                                    .foregroundStyle(.orange)

                                Text("ORDER NOTES")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.orange)
                            }

                            Text(trimmedOrderNotes)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(14)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .background(
                            Color.orange.opacity(0.10)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8)
                        )
                    }
                    
                    Divider()
                    
                    if order.paymentProvider.lowercased() == "cash" {
                        HStack(spacing: 8) {
                            Image(systemName: "banknote.fill")

                            Text("CASH ON PICKUP")
                                .fontWeight(.bold)

                            Spacer()

                            Text("$\(order.total, specifier: "%.2f")")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 15))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            Color.orange.opacity(0.12)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8)
                        )
                    }

                    if order.fulfilmentType.lowercased() == "delivery" {

                        VStack(spacing: 8) {
                            HStack {
                                Text("Subtotal")
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(
                                    "$\(order.subtotal, specifier: "%.2f")"
                                )
                            }

                            HStack {
                                Text("Delivery Fee")
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(
                                    "$\(order.deliveryFee, specifier: "%.2f")"
                                )
                            }

                            Divider()

                            HStack {
                                Text("Total")
                                    .font(.system(size: 18, weight: .bold))

                                Spacer()

                                Text(
                                    "$\(order.total, specifier: "%.2f")"
                                )
                                .font(.system(size: 20, weight: .bold))
                            }
                        }

                    } else {

                        HStack {
                            Text("Total")
                                .font(.system(size: 18, weight: .bold))

                            Spacer()

                            Text(
                                "$\(order.total, specifier: "%.2f")"
                            )
                            .font(.system(size: 20, weight: .bold))
                        }
                    }
                }
                .padding(24)
            }

            Divider()

            // Printing will be connected here next.
            HStack {
                Spacer()

                Button {
                    let receipt =
                        CafeReceiptFormatter.receiptText(
                            for: order
                        )

                    print("\n🖨️ CAFE RECEIPT\n")
                    print(receipt)
                    print("\n🖨️ END RECEIPT\n")

                } label: {
                    Label(
                        "Reprint Order",
                        systemImage: "printer"
                    )
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
        }
        .frame(
            minWidth: 600,
            idealWidth: 650,
            minHeight: 600,
            idealHeight: 700
        )
    }
}

// MARK: - Cafe Receipt Formatter

private struct CafeReceiptFormatter {

    static func receiptText(for order: CafeOrder) -> String {
        var lines: [String] = []

        lines.append(center("ESPRESSO CAFE"))
        lines.append("")
        lines.append(center("ORDER #\(order.orderNumber)"))
        lines.append("")

        if !order.customerName.isEmpty {
            lines.append(order.customerName.uppercased())
        }

        lines.append("")
        lines.append(
            center(order.fulfilmentType.uppercased())
        )
        if order.fulfilmentType.lowercased() == "delivery",
           !order.deliveryAddress.isEmpty {

            lines.append("")
            lines.append("DELIVERY ADDRESS:")
            lines.append(order.deliveryAddress)

            if order.deliveryDistanceKm > 0 {
                lines.append(
                    String(
                        format: "%.1f km from cafe",
                        order.deliveryDistanceKm
                    )
                )
            }
        }
        if let scheduledDateTime = order.scheduledDateTime {
            lines.append(
                center(formatPickupDate(scheduledDateTime))
            )
        } else {
            lines.append(
                center("ASAP")
            )
        }

        lines.append("")
        lines.append(separator)
        lines.append("")

        for item in order.items {

            lines.append(
                "\(item.quantity) x \(item.productName)"
            )

            for modifier in item.modifiers {
                if modifier.allowQuantities {
                    lines.append(
                        "   \(modifier.quantity) x \(modifier.optionName)"
                    )
                } else {
                    lines.append(
                        "   \(modifier.optionName)"
                    )
                }
            }

            let notes = item.specialInstructions
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !notes.isEmpty {
                lines.append("   NOTES: \(notes)")
            }

            lines.append("")
        }

        let orderNotes =
            order.orderNotes.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !orderNotes.isEmpty {
            lines.append("ORDER NOTES:")
            lines.append(orderNotes)
            lines.append("")
        }
        
        lines.append(separator)
        lines.append("")

        if order.fulfilmentType.lowercased() == "delivery" {
            lines.append(
                priceLine(
                    label: "SUBTOTAL",
                    amount: order.subtotal
                )
            )

            lines.append(
                priceLine(
                    label: "DELIVERY FEE",
                    amount: order.deliveryFee
                )
            )

            lines.append("")
        }

        lines.append(
            totalLine(order.total)
        )

        lines.append("")
        lines.append(center("THANK YOU"))
        lines.append("")
        lines.append("")
        lines.append("")

        return lines.joined(separator: "\n")
    }

    private static let charactersPerLine = 48

    private static let separator =
        String(
            repeating: "-",
            count: charactersPerLine
        )

    private static func center(_ text: String) -> String {
        guard text.count < charactersPerLine else {
            return text
        }

        let spaces =
            (charactersPerLine - text.count) / 2

        return String(
            repeating: " ",
            count: spaces
        ) + text
    }
    private static func priceLine(
        label: String,
        amount: Double
    ) -> String {

        let right = String(
            format: "$%.2f",
            amount
        )

        let spaces = max(
            1,
            charactersPerLine
                - label.count
                - right.count
        )

        return label
            + String(
                repeating: " ",
                count: spaces
            )
            + right
    }
    private static func totalLine(
        _ total: Double
    ) -> String {

        let left = "TOTAL"
        let right = String(
            format: "$%.2f",
            total
        )

        let spaces = max(
            1,
            charactersPerLine
                - left.count
                - right.count
        )

        return left
            + String(
                repeating: " ",
                count: spaces
            )
            + right
    }

    private static func formatDate(
        _ date: Date
    ) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat =
            "d MMM yyyy  h:mm a"

        return formatter.string(
            from: date
        )
    }
    private static func formatPickupDate(
        _ date: Date
    ) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat =
            "EEE d MMM  h:mm a"

        return formatter.string(
            from: date
        ).uppercased()
    }
}
