import SwiftUI

struct DashboardView: View {

    let orders: [LunchOrder]

    private let labelGenerationService = LabelGenerationService()


    // MARK: - Today's Orders

    private var todaysOrders: [LunchOrder] {

        let calendar = Calendar.current

        return orders.filter {
            calendar.isDateInToday($0.deliveryDate)
        }
    }


    // MARK: - Dashboard Totals

    private var totalOrders: Int {
        todaysOrders.count
    }

    private var totalLunches: Int {

        todaysOrders.reduce(0) {
            $0 + $1.studentOrders.count
        }
    }


    // MARK: - Hot Labels Remaining

    private var hotLabelsRemaining: Int {

        todaysOrders.reduce(0) { total, order in

            total + order.studentOrders.filter {
                !$0.hotLabelPrinted
            }.count
        }
    }


    // MARK: - Cold Labels Remaining

    private var coldLabelsRemaining: Int {

        let unprintedOrders = todaysOrders.compactMap {
            order -> LunchOrder? in

            let studentOrders = order.studentOrders.filter {
                !$0.coldLabelPrinted
            }

            guard !studentOrders.isEmpty else {
                return nil
            }

            return LunchOrder(
                id: order.id,
                orderNumber: order.orderNumber,
                school: order.school,
                studentOrders: studentOrders,
                orderDate: order.orderDate,
                deliveryDate: order.deliveryDate,
                status: order.status,
                notes: order.notes
            )
        }

        return labelGenerationService
            .makeColdLabels(from: unprintedOrders)
            .count
    }


    // MARK: - School Breakdown

    private var schoolSummaries: [DashboardSchoolSummary] {

        let groupedOrders = Dictionary(
            grouping: todaysOrders,
            by: { $0.school.id }
        )

        return groupedOrders.compactMap { _, schoolOrders in

            guard let school = schoolOrders.first?.school else {
                return nil
            }

            let lunchCount = schoolOrders.reduce(0) {
                $0 + $1.studentOrders.count
            }

            return DashboardSchoolSummary(
                id: school.id,
                schoolName: school.name,
                shortName: school.shortName,
                orderCount: schoolOrders.count,
                lunchCount: lunchCount
            )
        }
        .sorted {
            $0.schoolName.localizedCaseInsensitiveCompare(
                $1.schoolName
            ) == .orderedAscending
        }
    }


    // MARK: - View

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 24
            ) {

                // MARK: Header

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Dashboard")
                        .font(.largeTitle.bold())

                    Text(
                        Date.now.formatted(
                            .dateTime
                                .weekday(.wide)
                                .day()
                                .month(.wide)
                                .year()
                        )
                    )
                    .foregroundStyle(.secondary)
                }


                // MARK: Today's Overview

                HStack(spacing: 16) {

                    DashboardCard(
                        title: "Parent Orders",
                        value: totalOrders,
                        systemImage: "cart"
                    )

                    DashboardCard(
                        title: "Student Lunches",
                        value: totalLunches,
                        systemImage: "fork.knife"
                    )

                    DashboardCard(
                        title: "Hot Labels Remaining",
                        value: hotLabelsRemaining,
                        systemImage: "flame.fill"
                    )

                    DashboardCard(
                        title: "Cold Labels Remaining",
                        value: coldLabelsRemaining,
                        systemImage: "snowflake"
                    )
                }


                // MARK: School Breakdown

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Today's School Lunches")
                        .font(.title2.bold())

                    if schoolSummaries.isEmpty {

                        ContentUnavailableView(
                            "No School Lunches Today",
                            systemImage: "building.2",
                            description: Text(
                                "Today's school totals will appear here."
                            )
                        )
                        .frame(maxWidth: .infinity)

                    } else {

                        HStack(
                            alignment: .top,
                            spacing: 16
                        ) {

                            ForEach(schoolSummaries) { school in

                                SchoolSummaryCard(
                                    summary: school
                                )
                            }
                        }
                    }
                }

                // MARK: Daily Sales

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Today's Sales")
                        .font(.title2.bold())

                    HStack(spacing: 16) {

                        SalesCard(
                            title: "School Lunch Sales",
                            amount: 0,
                            systemImage: "graduationcap"
                        )

                        SalesCard(
                            title: "Cafe Sales",
                            amount: 0,
                            systemImage: "cup.and.saucer"
                        )

                        SalesCard(
                            title: "Total Sales",
                            amount: 0,
                            systemImage: "dollarsign.circle"
                        )
                    }
                }
                Spacer(minLength: 20)
            }
            .padding(24)
        }
    }
}


// MARK: - Dashboard Card

private struct DashboardCard: View {

    let title: String
    let value: Int
    let systemImage: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(value, format: .number)
                .font(
                    .system(
                        size: 34,
                        weight: .bold
                    )
                )

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(20)
        .background(
            .background.secondary,
            in: RoundedRectangle(
                cornerRadius: 12
            )
        )
    }
}


// MARK: - School Summary

private struct DashboardSchoolSummary: Identifiable {

    let id: UUID
    let schoolName: String
    let shortName: String
    let orderCount: Int
    let lunchCount: Int
}


// MARK: - School Summary Card

private struct SchoolSummaryCard: View {

    let summary: DashboardSchoolSummary

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        summary.shortName.isEmpty
                            ? summary.schoolName
                            : summary.shortName
                    )
                    .font(.title2.bold())

                    if !summary.shortName.isEmpty {

                        Text(summary.schoolName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "building.2")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(spacing: 30) {

                VStack(alignment: .leading) {

                    Text(
                        summary.orderCount,
                        format: .number
                    )
                    .font(.title.bold())

                    Text("Orders")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading) {

                    Text(
                        summary.lunchCount,
                        format: .number
                    )
                    .font(.title.bold())

                    Text("Lunches")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(20)
        .background(
            .background.secondary,
            in: RoundedRectangle(
                cornerRadius: 12
            )
        )
    }
}

// MARK: - Sales Card

private struct SalesCard: View {

    let title: String
    let amount: Decimal
    let systemImage: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(
                amount,
                format: .currency(code: "AUD")
            )
            .font(
                .system(
                    size: 30,
                    weight: .bold
                )
            )

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(20)
        .background(
            .background.secondary,
            in: RoundedRectangle(
                cornerRadius: 12
            )
        )
    }
}
// MARK: - Preview

#Preview {

    DashboardView(
        orders: SampleDataService()
            .makeSampleImport()
            .orders
    )
}
