import SwiftUI

struct EditActivityFilterView: View {
    let allActivities: [String: Activity]
    @Binding var visibleActivityKeys: Set<String>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack() {
                List {
                    ForEach(allActivities.sorted(by: { $0.value.id < $1.value.id }), id: \.key) { key, activity in
                        Toggle(isOn: Binding(
                            get: { visibleActivityKeys.contains(key) },
                            set: { isOn in
                                if isOn {
                                    visibleActivityKeys.insert(key)
                                } else {
                                    visibleActivityKeys.remove(key)
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: activity.image)
                                Text(activity.title)
                            }
                        }
                    }
                    HStack {
                        Spacer()
                        Button("Show All") {
                            visibleActivityKeys = Set(allActivities.keys)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()

                        Button("Close All") {
                            visibleActivityKeys = []
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity) // Stretch to fill horizontally
                    .multilineTextAlignment(.center) // (Optional, for multiple lines)
                    .padding()



                }
            }
            .navigationTitle("Filter Activities")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
