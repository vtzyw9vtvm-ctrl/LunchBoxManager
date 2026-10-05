import AppKit
import AVFoundation
import FirebaseCore
import FirebaseFirestore

@MainActor
final class CafeOrderAlertService {

    static let shared = CafeOrderAlertService()

    private var listener: ListenerRegistration?
    private var alertTimer: Timer?


    private var hasLoadedInitialOrders = false
    private var knownOrderIDs: Set<String> = []
    private var unacknowledgedOrderIDs: Set<String> = []

    private init() {}

    func start() {
        guard listener == nil else {
            return
        }

        guard let espressoApp = FirebaseApp.app(
            name: "EspressoCafe"
        ) else {
            print(
                "❌ CAFE ALERT: EspressoCafe Firebase app not configured"
            )
            return
        }

        let firestore = Firestore.firestore(
            app: espressoApp
        )

        listener = firestore
            .collection("orders")
            .whereField(
                "orderSource",
                isEqualTo: "cafe"
            )
            .addSnapshotListener { snapshot, error in

                if let error {
                    print(
                        "❌ CAFE ALERT LISTENER ERROR:",
                        error
                    )
                    return
                }

                guard let documents = snapshot?.documents else {
                    return
                }

                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }

                    self.process(documents)
                }
            }
    }

    private func process(
        _ documents: [QueryDocumentSnapshot]
    ) {
        let currentIDs = Set(
            documents.map(\.documentID)
        )

        // First snapshot establishes the baseline.
        // Existing orders must not trigger an alert.
        if !hasLoadedInitialOrders {
            knownOrderIDs = currentIDs
            hasLoadedInitialOrders = true

            refreshUnacknowledgedOrders(
                from: documents
            )

            return
        }

        let newIDs = currentIDs.subtracting(
            knownOrderIDs
        )

        for document in documents {
            guard newIDs.contains(document.documentID) else {
                continue
            }

            let data = document.data()

            let status =
                data["status"] as? String
                ?? ""

            if status.lowercased() == "confirmed" {
                unacknowledgedOrderIDs.insert(
                    document.documentID
                )
            }
        }

        knownOrderIDs = currentIDs

        refreshUnacknowledgedOrders(
            from: documents
        )

        if !newIDs.isEmpty &&
            !unacknowledgedOrderIDs.isEmpty {

            playNewOrderAlert()
            startRepeatingAlert()
        }
    }

    private func refreshUnacknowledgedOrders(
        from documents: [QueryDocumentSnapshot]
    ) {
        let confirmedIDs = Set(
            documents.compactMap { document -> String? in

                let status =
                    document.data()["status"] as? String
                    ?? ""

                return status.lowercased() == "confirmed"
                    ? document.documentID
                    : nil
            }
        )

        unacknowledgedOrderIDs.formIntersection(
            confirmedIDs
        )

        if unacknowledgedOrderIDs.isEmpty {
            stopRepeatingAlert()
        }
    }

    private func startRepeatingAlert() {
        guard alertTimer == nil else {
            return
        }

        alertTimer = Timer.scheduledTimer(
            withTimeInterval: 10.0,
            repeats: true
        ) { _ in

            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }

                guard !self.unacknowledgedOrderIDs.isEmpty else {
                    self.stopRepeatingAlert()
                    return
                }

                self.playNewOrderAlert()
            }
        }
    }

    private func stopRepeatingAlert() {
        alertTimer?.invalidate()
        alertTimer = nil
    }

    private func playNewOrderAlert() {
        NSSound(named: "Glass")?.play()
    }
}
