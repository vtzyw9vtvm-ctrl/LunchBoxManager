import Foundation
import Observation

@Observable
final class SchoolsViewModel {

    private let saveKey = "Schools"

    var schools: [School] = []

    init() {

        load()

    }

    @discardableResult
    func addSchool() -> School {

        let school = School(
            name: "New School",
            shortName: "NEW"
        )

        schools.append(school)

        save()

        return school

    }

    func updateSchool(_ school: School) {
        guard let index = schools.firstIndex(
            where: { $0.id == school.id }
        ) else {
            return
        }

        schools[index] = school

        // Save locally immediately.
        save()

        // Also sync the updated school to Firebase.
        Task {
            do {
                let service = FirebaseSchoolService()

                try await service.saveSchool(school)

                print(
                    "🔥 SCHOOL AUTO-SYNCED:",
                    school.name
                )
            } catch {
                print(
                    "🔥 SCHOOL AUTO-SYNC ERROR:",
                    error.localizedDescription
                )
            }
        }
    }

    func deleteSchool(_ school: School) {

        schools.removeAll {
            $0.id == school.id
        }

        save()

    }

    private func save() {

        do {

            let data = try JSONEncoder().encode(schools)

            UserDefaults.standard.set(
                data,
                forKey: saveKey
            )

        } catch {

            print(error)

        }

    }

    private func load() {

        guard
            let data = UserDefaults.standard.data(forKey: saveKey)
        else {
            return
        }

        do {

            schools = try JSONDecoder().decode(
                [School].self,
                from: data
            )

        } catch {

            print(error)

        }

    }

}
