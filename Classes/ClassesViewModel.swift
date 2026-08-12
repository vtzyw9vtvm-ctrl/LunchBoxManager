import Foundation
import Observation

@Observable
final class ClassesViewModel {

    private let saveKey = "SchoolClasses"

    var classes: [SchoolClass] = []

    init() {
        load()
    }

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

    func updateClass(_ schoolClass: SchoolClass) {

        guard let index = classes.firstIndex(where: { $0.id == schoolClass.id }) else {
            return
        }

        classes[index] = schoolClass

        save()
    }

    func deleteClass(_ schoolClass: SchoolClass) {

        classes.removeAll {
            $0.id == schoolClass.id
        }

        save()
    }

    private func save() {

        do {

            let data = try JSONEncoder().encode(classes)

            UserDefaults.standard.set(data, forKey: saveKey)

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

            classes = try JSONDecoder().decode(
                [SchoolClass].self,
                from: data
            )

        } catch {

            print(error)

        }

    }

}
