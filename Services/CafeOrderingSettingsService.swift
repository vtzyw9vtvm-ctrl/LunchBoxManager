import Foundation
import FirebaseCore
import FirebaseFirestore

struct CafeDayHours: Codable, Equatable {
    var isClosed: Bool
    var openTime: String
    var closeTime: String

    static let standard = CafeDayHours(
        isClosed: false,
        openTime: "07:00",
        closeTime: "15:00"
    )
}

struct CafeOrderingSettings: Codable, Equatable {

    var onlineOrderingEnabled: Bool
    var pickupEnabled: Bool
    var deliveryEnabled: Bool
    var asapEnabled: Bool
    var scheduledOrderingEnabled: Bool

    // Minimum preparation time before an order
    // can be collected.
    var preparationTimeMinutes: Int
    
    // Delivery settings
    var cafeAddress: String
    var cafeLatitude: Double
    var cafeLongitude: Double

    var deliveryRadiusKm: Double
    var deliveryFee: Double
    var minimumDeliveryOrder: Double

    var monday: CafeDayHours
    var tuesday: CafeDayHours
    var wednesday: CafeDayHours
    var thursday: CafeDayHours
    var friday: CafeDayHours
    var saturday: CafeDayHours
    var sunday: CafeDayHours

    static let defaultSettings = CafeOrderingSettings(
        onlineOrderingEnabled: true,
        pickupEnabled: true,
        deliveryEnabled: true,
        asapEnabled: true,
        scheduledOrderingEnabled: true,

        preparationTimeMinutes: 30,
        cafeAddress: "",
        cafeLatitude: 0.0,
        cafeLongitude: 0.0,
        deliveryRadiusKm: 5.0,
        deliveryFee: 5.0,
        minimumDeliveryOrder: 20.0,

        monday: CafeDayHours(
            isClosed: false,
            openTime: "05:30",
            closeTime: "15:00"
        ),

        tuesday: CafeDayHours(
            isClosed: false,
            openTime: "05:30",
            closeTime: "15:00"
        ),

        wednesday: CafeDayHours(
            isClosed: false,
            openTime: "05:30",
            closeTime: "15:00"
        ),

        thursday: CafeDayHours(
            isClosed: false,
            openTime: "05:30",
            closeTime: "15:00"
        ),

        friday: CafeDayHours(
            isClosed: false,
            openTime: "05:30",
            closeTime: "19:30"
        ),

        saturday: CafeDayHours(
            isClosed: false,
            openTime: "06:00",
            closeTime: "14:00"
        ),

        sunday: CafeDayHours(
            isClosed: false,
            openTime: "07:00",
            closeTime: "14:00"
        )
    )
}

@MainActor
final class CafeOrderingSettingsService {

    static let shared = CafeOrderingSettingsService()

    private init() {}

    private var firestore: Firestore? {

        guard let espressoApp = FirebaseApp.app(
            name: "EspressoCafe"
        ) else {
            print(
                "❌ CAFE SETTINGS: EspressoCafe Firebase app not configured"
            )
            return nil
        }

        return Firestore.firestore(
            app: espressoApp
        )
    }

    func loadSettings() async throws -> CafeOrderingSettings {

        guard let firestore else {
            throw CafeOrderingSettingsError.firebaseNotConfigured
        }

        let document = try await firestore
            .collection("settings")
            .document("ordering")
            .getDocument()

        guard document.exists,
              let data = document.data()
        else {
            return .defaultSettings
        }

        return CafeOrderingSettings(
            onlineOrderingEnabled:
                data["onlineOrderingEnabled"] as? Bool
                ?? true,

            pickupEnabled:
                data["pickupEnabled"] as? Bool
                ?? true,

            deliveryEnabled:
                data["deliveryEnabled"] as? Bool
                ?? true,

            asapEnabled:
                data["asapEnabled"] as? Bool
                ?? true,

            scheduledOrderingEnabled:
                data["scheduledOrderingEnabled"] as? Bool
                ?? true,

            preparationTimeMinutes:
                data["preparationTimeMinutes"] as? Int
                ?? 30,
            
            cafeAddress:
                data["cafeAddress"] as? String
                ?? "",

            cafeLatitude:
                (data["cafeLatitude"] as? NSNumber)?.doubleValue
                ?? 0.0,

            cafeLongitude:
                (data["cafeLongitude"] as? NSNumber)?.doubleValue
                ?? 0.0,
            
            deliveryRadiusKm:
                (data["deliveryRadiusKm"] as? NSNumber)?.doubleValue
                ?? 5.0,

            deliveryFee:
                (data["deliveryFee"] as? NSNumber)?.doubleValue
                ?? 5.0,

            minimumDeliveryOrder:
                (data["minimumDeliveryOrder"] as? NSNumber)?.doubleValue
                ?? 20.0,

            monday: dayHours(
                from: data["monday"]
            ),

            tuesday: dayHours(
                from: data["tuesday"]
            ),

            wednesday: dayHours(
                from: data["wednesday"]
            ),

            thursday: dayHours(
                from: data["thursday"]
            ),

            friday: dayHours(
                from: data["friday"]
            ),

            saturday: dayHours(
                from: data["saturday"]
            ),

            sunday: dayHours(
                from: data["sunday"]
            )
        )
    }

    func saveSettings(
        _ settings: CafeOrderingSettings
    ) async throws {

        guard let firestore else {
            throw CafeOrderingSettingsError.firebaseNotConfigured
        }

        try await firestore
            .collection("settings")
            .document("ordering")
            .setData(
                [
                    "onlineOrderingEnabled":
                        settings.onlineOrderingEnabled,

                    "pickupEnabled":
                        settings.pickupEnabled,

                    "deliveryEnabled":
                        settings.deliveryEnabled,

                    "asapEnabled":
                        settings.asapEnabled,

                    "scheduledOrderingEnabled":
                        settings.scheduledOrderingEnabled,

                    "preparationTimeMinutes":
                        settings.preparationTimeMinutes,

                    "cafeAddress":
                        settings.cafeAddress,

                    "cafeLatitude":
                        settings.cafeLatitude,

                    "cafeLongitude":
                        settings.cafeLongitude,
                    
                    "deliveryRadiusKm":
                        settings.deliveryRadiusKm,

                    "deliveryFee":
                        settings.deliveryFee,

                    "minimumDeliveryOrder":
                        settings.minimumDeliveryOrder,

                    "monday":
                        dayDictionary(settings.monday),

                    "tuesday":
                        dayDictionary(settings.tuesday),

                    "wednesday":
                        dayDictionary(settings.wednesday),

                    "thursday":
                        dayDictionary(settings.thursday),

                    "friday":
                        dayDictionary(settings.friday),

                    "saturday":
                        dayDictionary(settings.saturday),

                    "sunday":
                        dayDictionary(settings.sunday),

                    "updatedAt":
                        FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }

    private func dayHours(
        from value: Any?,
        defaultClosed: Bool = false
    ) -> CafeDayHours {

        guard let data = value as? [String: Any] else {
            return CafeDayHours(
                isClosed: defaultClosed,
                openTime: "07:00",
                closeTime: "15:00"
            )
        }

        return CafeDayHours(
            isClosed:
                data["isClosed"] as? Bool
                ?? defaultClosed,

            openTime:
                data["openTime"] as? String
                ?? "07:00",

            closeTime:
                data["closeTime"] as? String
                ?? "15:00"
        )
    }

    private func dayDictionary(
        _ hours: CafeDayHours
    ) -> [String: Any] {

        [
            "isClosed": hours.isClosed,
            "openTime": hours.openTime,
            "closeTime": hours.closeTime
        ]
    }
}

enum CafeOrderingSettingsError: LocalizedError {

    case firebaseNotConfigured

    var errorDescription: String? {

        switch self {

        case .firebaseNotConfigured:
            return "Espresso Cafe Firebase is not configured."
        }
    }
}
