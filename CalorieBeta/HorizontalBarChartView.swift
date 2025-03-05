import SwiftUI
import Charts

struct HorizontalBarChartView: View {
    var dailyLog: DailyLog
    @ObservedObject var goal: GoalSettings // Observing GoalSettings

    var body: some View {
        if let caloriesGoal = goal.calories {
            let totalCalories = max(0, dailyLog.totalCalories())
            let totalMacros = dailyLog.totalMacros()

            let protein = max(0, totalMacros.protein)
            let fats = max(0, totalMacros.fats)
            let carbs = max(0, totalMacros.carbs)

            let proteinGoal = goal.protein
            let fatsGoal = goal.fats
            let carbsGoal = goal.carbs

            let caloriesPercentage = (caloriesGoal > 0) ? min((totalCalories / max(caloriesGoal, 1)) * 100, 100) : 0
            let proteinPercentage = (proteinGoal > 0) ? min((protein / max(proteinGoal, 1)) * 100, 100) : 0
            let fatsPercentage = (fatsGoal > 0) ? min((fats / max(fatsGoal, 1)) * 100, 100) : 0
            let carbsPercentage = (carbsGoal > 0) ? min((carbs / max(carbsGoal, 1)) * 100, 100) : 0

            Chart {
                BarMark(
                    x: .value("Calories", caloriesPercentage),
                    y: .value("Type", "Calories")
                )
                .foregroundStyle(.red)
                .annotation(position: .trailing) {
                    Text("\(Int(totalCalories)) / \(Int(caloriesGoal)) kcal")
                        .font(.caption)
                }

                BarMark(
                    x: .value("Protein", proteinPercentage),
                    y: .value("Type", "Protein")
                )
                .foregroundStyle(.blue)
                .annotation(position: .trailing) {
                    Text("\(String(format: "%.1f", protein)) / \(String(format: "%.1f", proteinGoal))g")
                        .font(.caption)
                }

                BarMark(
                    x: .value("Fats", fatsPercentage),
                    y: .value("Type", "Fats")
                )
                .foregroundStyle(.green)
                .annotation(position: .trailing) {
                    Text("\(String(format: "%.1f", fats)) / \(String(format: "%.1f", fatsGoal))g")
                        .font(.caption)
                }

                BarMark(
                    x: .value("Carbs", carbsPercentage),
                    y: .value("Type", "Carbs")
                )
                .foregroundStyle(.orange)
                .annotation(position: .trailing) {
                    Text("\(String(format: "%.1f", carbs)) / \(String(format: "%.1f", carbsGoal))g")
                        .font(.caption)
                }
            }
            .chartXAxis { AxisMarks(position: .bottom) }
            .chartYAxis { AxisMarks(position: .leading) }
            .chartXScale(domain: 0...100)
            .frame(maxHeight: 250)
            .padding()
        } else {
            // Show loading state while `calories` is `nil`
            Text("Loading data...")
                .foregroundColor(.gray)
                .frame(maxHeight: 250)
                .padding()
        }
    }
}
