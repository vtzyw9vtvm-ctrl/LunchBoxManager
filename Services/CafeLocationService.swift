import Foundation
import FirebaseCore
import FirebaseFunctions

struct CafeLocationResult {
    let address: String
    let latitude: Double
    let longitude: Double
}

@MainActor
final class CafeLocationService {

    static let shared = CafeLocationService()

    private init() {}

    private var functions: Functions? {

        guard let espressoApp = FirebaseApp.app(
            name: "EspressoCafe"
        ) else {
            print(
                "❌ CAFE LOCATION: EspressoCafe Firebase app not configured"
            )
            return nil
        }

        return Functions.functions(
            app: espressoApp,
            region: "australia-southeast1"
        )
    }

    func geocodeCafeAddress(
        _ address: String
    ) async throws -> CafeLocationResult {

        guard let functions else {
            throw CafeLocationServiceError.firebaseNotConfigured
        }

        let trimmedAddress =
            address.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard trimmedAddress.count >= 5 else {
            throw CafeLocationServiceError.invalidAddress
        }

        let result = try await functions
            .httpsCallable("geocodeCafeAddress")
            .call([
                "address": trimmedAddress
            ])

        guard
            let data = result.data as? [String: Any],
            let formattedAddress =
                data["address"] as? String,
            let latitude =
                (data["latitude"] as? NSNumber)?.doubleValue,
            let longitude =
                (data["longitude"] as? NSNumber)?.doubleValue
        else {
            throw CafeLocationServiceError.invalidResponse
        }

        return CafeLocationResult(
            address: formattedAddress,
            latitude: latitude,
            longitude: longitude
        )
    }
}

enum CafeLocationServiceError: LocalizedError {

    case firebaseNotConfigured
    case invalidAddress
    case invalidResponse

    var errorDescription: String? {

        switch self {

        case .firebaseNotConfigured:
            return "Espresso Cafe Firebase is not configured."

        case .invalidAddress:
            return "Please enter a valid cafe address."

        case .invalidResponse:
            return "The cafe address could not be verified."
        }
    }
}
