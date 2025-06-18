import SwiftUI

struct SleepView: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        VStack(spacing: 16) {
            // top navigation date bar
            HStack {
                // date
                VStack(alignment: .leading) {
                    Text(healthManager.selectedDate, format: .dateTime.weekday(.wide))
                        .font(.title).opacity(1)
                    Text(healthManager.selectedDate, format: .dateTime.day().month().year())
                        .font(.headline).opacity(0.5)
                }
                Spacer()
                // calendar button
                Button(action: {
                    //
                }) {
                    Image(systemName: "calendar")
                        .padding().font(.title)
                }
            }
            
            // MARK: - Day Navigation Header
            HStack {
                Button(action: {
                    healthManager.goToPreviousDay()
                }) {
                    Image(systemName: "chevron.left")
                        .padding()
                }
                
                Spacer()
                
                Text(healthManager.selectedDate, format: .dateTime.day().month().year())
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    healthManager.goToNextDay()
                }) {
                    Image(systemName: "chevron.right")
                        .padding()
                }
                .disabled(Calendar.current.isDateInToday(healthManager.selectedDate))
            }
            .padding(.horizontal)
            // MARK: - Chart or Message
            VStack{
                if healthManager.sleepSegments.isEmpty {
                    Text("No sleep data available")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    SleepChartView(segments: healthManager.sleepSegments)
                }
            }.frame(width: 350, height: 300)
            .background(Color.gray.opacity(0.2)).cornerRadius(15)
            .padding()
            //
            if let sleepActivity = healthManager.activities["todaysSleep"] {
                ActivityCard(activity: sleepActivity)
            }
            
            
            Spacer()
        }
        .navigationTitle("Sleep Data")
        .padding()
        
    }
}

#Preview {
    SleepView()
        .environmentObject(HealthManager())
}
