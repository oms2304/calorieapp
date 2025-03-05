import SwiftUI
import Charts

struct WeightTrackingView: View {
    @EnvironmentObject var goalSettings: GoalSettings
    @State private var showingWeightEntry = false
    @State private var selectedTimeframe: Timeframe = .year // Default to Year

    var filteredWeightData: [(date: Date, weight: Double)] {
        let now = Date()
        switch selectedTimeframe {
        case .day:
            return goalSettings.weightHistory.filter { $0.date > Calendar.current.date(byAdding: .day, value: -1, to: now)! }
        case .week:
            return goalSettings.weightHistory.filter { $0.date > Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now)! }
        case .month:
            return goalSettings.weightHistory.filter { $0.date > Calendar.current.date(byAdding: .month, value: -1, to: now)! }
        case .sixMonths:
            return goalSettings.weightHistory.filter { $0.date > Calendar.current.date(byAdding: .month, value: -6, to: now)! }
        case .year:
            return goalSettings.weightHistory.filter { $0.date > Calendar.current.date(byAdding: .year, value: -1, to: now)! }
        }
    }

    var body: some View {
        VStack {
            Text("Weight Tracking")
                .font(.largeTitle)
                .padding()

            Picker("Select Timeframe", selection: $selectedTimeframe) {
                Text("D").tag(Timeframe.day)
                Text("W").tag(Timeframe.week)
                Text("M").tag(Timeframe.month)
                Text("6M").tag(Timeframe.sixMonths)
                Text("Y").tag(Timeframe.year)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // ✅ Updated to use new WeightChartView
            WeightChartView(weightHistory: filteredWeightData)

            Button(action: {
                showingWeightEntry = true
            }) {
                Text("Enter Current Weight")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .sheet(isPresented: $showingWeightEntry) {
                CurrentWeightView()
                    .environmentObject(goalSettings)
            }
        }
        .onAppear {
            goalSettings.loadWeightHistory()
        }
    }
}

enum Timeframe {
    case day, week, month, sixMonths, year
}
