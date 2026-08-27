import Foundation
import Observation

@Observable
final class ClassesViewModel {

    private let saveKey = "SchoolClasses"

    var classes: [SchoolClass] = []

    init() {
        load()
    }

    // MARK: - Add Class

    @discardableResult
    func addClass() -> SchoolClass {

        let schoolClass = SchoolClass(
            name: "Prep A",
            schoolID: UUID()
        )

        classes.append(schoolClass)

        save()

        return schoolClass
    }

    // MARK: - Update Class

    func updateClass(_ schoolClass: SchoolClass) {

        guard let index = classes.firstIndex(
            where: {
                $0.id == schoolClass.id
            }
        ) else {
            return
        }

        classes[index] = schoolClass

        // Save locally.
        save()

        // Automatically sync to Firebase.
        Task { @MainActor in

            do {

                let service = FirebaseClassService()

                try await service.saveClass(
                    schoolClass
                )

                print(
                    "🔥 CLASS AUTO-SYNCED:",
                    schoolClass.name
                )

            } catch {

                print(
                    "🔥 CLASS AUTO-SYNC ERROR:",
                    error.localizedDescription
                )
            }
        }
    }

    // MARK: - Delete Class

    func deleteClass(_ schoolClass: SchoolClass) {

        classes.removeAll {
            $0.id == schoolClass.id
        }

        // Remove locally first.
        save()

        // Also remove from Firebase.
        Task { @MainActor in

            do {

                let service = FirebaseClassService()

                try await service.deleteClass(
                    schoolClass
                )

                print(
                    "🔥 CLASS DELETED FROM FIREBASE:",
                    schoolClass.name
                )

            } catch {

                print(
                    "🔥 CLASS FIREBASE DELETE ERROR:",
                    error.localizedDescription
                )
            }
        }
    }
    
    // MARK: - Assign Missing Year Levels

    func assignMissingYearLevels() {

        var updatedCount = 0

        for schoolClass in classes {

            // Don't overwrite anything already assigned.
            guard schoolClass.yearLevel
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
            else {
                continue
            }

            let name = schoolClass.name
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            let yearLevel: String?

            if name.contains("staff") {

                yearLevel = "Staff"

            } else if name.hasPrefix("prep") {

                yearLevel = "Prep"

            } else if name.hasPrefix("1") ||
                        name.hasPrefix("grade 1") {

                yearLevel = "Grade 1"

            } else if name.hasPrefix("2") ||
                        name.hasPrefix("grade 2") {

                yearLevel = "Grade 2"

            } else if name.hasPrefix("3") ||
                        name.hasPrefix("grade 3") {

                yearLevel = "Grade 3"

            } else if name.hasPrefix("4") ||
                      name.hasPrefix("grade 4") {

                yearLevel = "Grade 4"

            } else if name.hasPrefix("5/6") ||
                      name.hasPrefix("5-6") ||
                      name.hasPrefix("grade 5/6") {

                yearLevel = "Grade 5/6"

            } else if name.hasPrefix("5") ||
                      name.hasPrefix("grade 5") {

                yearLevel = "Grade 5"

            } else if name.hasPrefix("6") ||
                      name.hasPrefix("grade 6") {

                yearLevel = "Grade 6"

            } else {

                yearLevel = nil
            }

            guard let yearLevel else {

                print(
                    "⚠️ COULD NOT DETERMINE YEAR LEVEL:",
                    schoolClass.name
                )

                continue
            }

            var updatedClass = schoolClass
            updatedClass.yearLevel = yearLevel

            updateClass(updatedClass)

            updatedCount += 1
        }

        print(
            "🎓 YEAR LEVEL ASSIGNMENT COMPLETE:",
            updatedCount,
            "classes updated"
        )
    }
    
    // MARK: - Sync All Classes To Firebase

    func syncAllClassesToFirebase() {

        let allClasses = classes

        Task { @MainActor in

            let service = FirebaseClassService()

            var successCount = 0

            for schoolClass in allClasses {

                do {

                    try await service.saveClass(
                        schoolClass
                    )

                    successCount += 1

                    print(
                        "🔥 CLASS SYNCED:",
                        schoolClass.name
                    )

                } catch {

                    print(
                        "🔥 CLASS SYNC FAILED:",
                        schoolClass.name,
                        error.localizedDescription
                    )
                }
            }

            print(
                "🔥 ALL CLASS SYNC COMPLETE:",
                successCount,
                "of",
                allClasses.count
            )
        }
    }
    // MARK: - Local Save

    private func save() {

        do {

            let data = try JSONEncoder().encode(
                classes
            )

            UserDefaults.standard.set(
                data,
                forKey: saveKey
            )

        } catch {

            print(error)
        }
    }

    // MARK: - Local Load

    private func load() {

        guard
            let data = UserDefaults.standard.data(
                forKey: saveKey
            )
        else {
            return
        }

        do {

            classes = try JSONDecoder().decode(
                [SchoolClass].self,
                from: data
            )

        } catch {

            print(error)
        }
    }
}
