import SwiftUI

enum StatsPeriod: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case lifetime = "Lifetime"

    var id: String { rawValue }

    var calendarComponent: Calendar.Component {
        switch self {
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        case .lifetime: return .era
        }
    }

    var bucket: String {
        switch self {
        case .week: return "day"
        case .month: return "week"
        case .year: return "month"
        case .lifetime: return "year"
        }
    }
}

struct PeriodPicker: View {
    @Binding var selectedPeriod: StatsPeriod
    @Binding var referenceDate: Date

    var body: some View {
        VStack(spacing: 8) {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(StatsPeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)

            if selectedPeriod != .lifetime {
                HStack {
                    Button {
                        referenceDate = Calendar.current.date(byAdding: selectedPeriod.calendarComponent, value: -1, to: referenceDate) ?? referenceDate
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()
                    Text(formattedDate)
                        .font(.subheadline.weight(.medium))
                    Spacer()

                    Button {
                        let next = Calendar.current.date(byAdding: selectedPeriod.calendarComponent, value: 1, to: referenceDate) ?? referenceDate
                        if next <= Date() {
                            referenceDate = next
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(isCurrentPeriod)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var isCurrentPeriod: Bool {
        let cal = Calendar.current
        switch selectedPeriod {
        case .week:
            return cal.isDate(referenceDate, equalTo: Date(), toGranularity: .weekOfYear)
        case .month:
            return cal.isDate(referenceDate, equalTo: Date(), toGranularity: .month)
        case .year:
            return cal.isDate(referenceDate, equalTo: Date(), toGranularity: .year)
        case .lifetime:
            return true
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "MMM d, yyyy"
            let start = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)) ?? referenceDate
            let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
            let startStr = formatter.string(from: start)
            formatter.dateFormat = "MMM d"
            let endStr = formatter.string(from: end)
            return "\(startStr) - \(endStr)"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: referenceDate)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: referenceDate)
        case .lifetime:
            return "All Time"
        }
    }

    var dateRange: (from: String?, to: String?) {
        let cal = Calendar.current
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        switch selectedPeriod {
        case .lifetime:
            return (nil, nil)
        case .week:
            let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate))!
            let end = cal.date(byAdding: .day, value: 7, to: start)!
            return (iso.string(from: start), iso.string(from: end))
        case .month:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate))!
            let end = cal.date(byAdding: .month, value: 1, to: start)!
            return (iso.string(from: start), iso.string(from: end))
        case .year:
            let start = cal.date(from: cal.dateComponents([.year], from: referenceDate))!
            let end = cal.date(byAdding: .year, value: 1, to: start)!
            return (iso.string(from: start), iso.string(from: end))
        }
    }
}
