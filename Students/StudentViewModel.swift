import Foundation
import Observation

@Observable
final class StudentsViewModel {

    private let saveKey = "Students"

    var students: [Student] = []

    init() {

        load()

    }

    @discardableResult
    func addStudent() -> Student {

        let student = Student(
            firstName: "New",
            lastName: "Student"
        )

        students.append(student)

        save()

        return student

    }

    func updateStudent(_ student: Student) {

        guard let index = students.firstIndex(where: { $0.id == student.id }) else {
            return
        }

        students[index] = student

        save()

    }

    func deleteStudent(_ student: Student) {

        students.removeAll {
            $0.id == student.id
        }

        save()

    }

    func save() {

        do {

            let data = try JSONEncoder().encode(students)

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

            students = try JSONDecoder().decode(
                [Student].self,
                from: data
            )

        } catch {

            print(error)

        }

    }

}
