import Foundation

/// Generates realistic in-memory data for Release 0.1 UI development.
struct SampleDataService: Sendable {
    func makeSampleImport() -> CSVImportResult {
        let schools = [
            School(name: "Northside Primary School", shortName: "NPS"),
            School(name: "St Marys College", shortName: "SMC"),
            School(name: "Rivergum Grammar", shortName: "RGG")
        ]

        let classNames = [
            ("Prep A", "Prep", 0),
            ("Prep B", "Prep", 0),
            ("1A", "Year 1", 0),
            ("2B", "Year 2", 1),
            ("3A", "Year 3", 1),
            ("4C", "Year 4", 1),
            ("5A", "Year 5", 2),
            ("6B", "Year 6", 2)
        ]

        let classes = classNames.map { name, _, schoolIndex in

            SchoolClass(
                name: name,
                schoolID: schools[schoolIndex].id
            )

        }

        let names = [
            ("Ava", "Nguyen"), ("Noah", "Williams"), ("Mia", "Patel"), ("Oliver", "Brown"),
            ("Grace", "Wilson"), ("Leo", "Taylor"), ("Charlotte", "Singh"), ("Henry", "Martin"),
            ("Amelia", "Johnson"), ("Jack", "Anderson"), ("Isla", "Thomas"), ("Lucas", "Moore"),
            ("Sophie", "Clark"), ("Ethan", "Lee"), ("Ella", "Walker"), ("Liam", "Hall"),
            ("Ruby", "Allen"), ("Mason", "Young"), ("Chloe", "King"), ("Arlo", "Wright"),
            ("Zoe", "Scott"), ("James", "Green"), ("Evie", "Baker"), ("Finn", "Adams"),
            ("Harper", "Nelson"), ("Archie", "Carter"), ("Willow", "Mitchell"), ("Oscar", "Perez"),
            ("Matilda", "Roberts"), ("Hugo", "Turner")
        ]

        let students = names.enumerated().map { index, name in
            let schoolClass = classes[index % classes.count]
            return Student(
                firstName: name.0,
                lastName: name.1,
                classID: schoolClass.id
            )
        }

        let menuItems = [
            MenuItem(name: "Ham and Cheese Toastie", category: "Lunch", variants: ["Wholemeal"], isHot: true),
            MenuItem(name: "Chicken Wrap", category: "Lunch", variants: ["No tomato"], isCold: true),
            MenuItem(name: "Veggie Pasta", category: "Lunch", isHot: true),
            MenuItem(name: "Sushi Pack", category: "Lunch", variants: ["Tuna"], isCold: true),
            MenuItem(name: "Beef Pie", category: "Lunch", isHot: true),
            MenuItem(name: "Fruit Salad", category: "Snack", isCold: true),
            MenuItem(name: "Banana Bread", category: "Snack"),
            MenuItem(name: "Apple Juice", category: "Drink", isCold: true),
            MenuItem(name: "Chocolate Milk", category: "Drink", isCold: true),
            MenuItem(name: "Water", category: "Drink", isCold: true)
        ]

        let calendar = Calendar.current
        var studentOrderIndex = 0
        let orders = (0..<32).map { orderIndex in
            let firstStudentOrder = makeStudentOrder(
                index: studentOrderIndex,
                students: students,
                classes: classes,
                menuItems: menuItems
            )
            studentOrderIndex += 1

            var studentOrders = [firstStudentOrder]
            if orderIndex < 13 {
                studentOrders.append(
                    makeStudentOrder(
                        index: studentOrderIndex,
                        students: students,
                        classes: classes,
                        menuItems: menuItems
                    )
                )
                studentOrderIndex += 1
            }

            let school = schools.first { $0.id == studentOrders[0].schoolClass?.schoolID } ?? schools[0]
            let date = calendar.date(byAdding: .day, value: -(orderIndex % 7), to: Date()) ?? Date()

            return LunchOrder(
                orderNumber: "SLM-\(String(format: "%04d", orderIndex + 1))",
                school: school,
                studentOrders: studentOrders,
                orderDate: date,
                notes: orderIndex.isMultiple(of: 5) ? "Please bag separately" : nil
            )
        }

        let session = ImportSession(
            filename: "Sample Data",
            importDate: Date(),
            totalOrders: orders.count,
            totalStudents: orders.reduce(0) { $0 + $1.studentOrders.count },
            totalClasses: Set(orders.flatMap { $0.studentOrders.compactMap(\.schoolClass?.id) }).count,
            totalSchools: Set(orders.map(\.school.id)).count
        )

        let summary = ImportSummary(
            totalMenuItems: orders.reduce(0) { total, order in
                total + order.studentOrders.reduce(0) { studentTotal, studentOrder in
                    studentTotal + studentOrder.items.reduce(0) { $0 + $1.quantity }
                }
            },
            capitalisationCorrections: 0,
            duplicateClasses: 0,
            skippedRows: 0
        )

        return CSVImportResult(session: session, orders: orders, issues: [], summary: summary)
    }

    private func makeStudentOrder(
        index: Int,
        students: [Student],
        classes: [SchoolClass],
        menuItems: [MenuItem]
    ) -> StudentOrder {
        let student = students[index % students.count]
        let schoolClass = classes.first { $0.id == student.classID }
        let firstItem = menuItems[index % menuItems.count]
        let secondItem = menuItems[(index + 4) % menuItems.count]
        let bananaBread = menuItems.first {
            $0.name == "Banana Bread"
        }

        let veggiePasta = menuItems.first {
            $0.name == "Veggie Pasta"
        }

        let items: [MenuItem]

        if index == 0 {

            var testItems = [firstItem]

            if let bananaBread {
                testItems.append(bananaBread)
            }

            if let veggiePasta {
                testItems.append(veggiePasta)
            }

            items = testItems

        } else {

            items = index.isMultiple(of: 3)
                ? [firstItem, secondItem]
                : [firstItem]
        }

        return StudentOrder(
            student: student,
            schoolClass: schoolClass,
            items: items
        )
    }
}
