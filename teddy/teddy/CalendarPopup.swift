import SwiftUI

struct CalendarPopup: View {
    let availableDates: Set<Date>
    let onDateSelected: (Date) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var displayedMonth = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                calendarHeader

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"], id: \.self) { day in
                        Text(day)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    ForEach(generateDays(for: displayedMonth), id: \.self) { day in
                        if let date = day {
                            let dayNumber = Calendar.current.component(.day, from: date)
                            let isAvailable = availableDates.contains(Calendar.current.startOfDay(for: date))

                            Text("\(dayNumber)")
                                .font(.body)
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .background(
                                    Circle()
                                        .fill(Color.accentColor.opacity(isAvailable ? 0.2 : 0))
                                )
                                .overlay(
                                    Circle()
                                        .fill(Color.accentColor)
                                        .opacity(isAvailable ? 0 : 0) // You can adjust if needed
                                )
                                .foregroundColor(isAvailable ? .primary : .secondary)
                                .onTapGesture {
                                    if isAvailable {
                                        onDateSelected(date)
                                        dismiss()
                                    }
                                }
                        } else {
                            Color.clear.frame(height: 36)
                        }
                    }

                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }
            }
        }
    }

    func generateDays(for date: Date) -> [Date?] {
        var days: [Date?] = []
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let range = calendar.range(of: .day, in: .month, for: date)!

        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        days.append(contentsOf: Array(repeating: nil, count: firstWeekday - 1))

        for day in range {
            if let fullDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(fullDate)
            }
        }

        return days
    }

    private var calendarHeader: some View {
        HStack {
            Button(action: {
                displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth)!
            }) {
                Image(systemName: "chevron.left")
                    .padding(8)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(displayedMonth, format: .dateTime.month().year())
                .font(.headline)

            Spacer()

            Button(action: {
                displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth)!
            }) {
                Image(systemName: "chevron.right")
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
}
