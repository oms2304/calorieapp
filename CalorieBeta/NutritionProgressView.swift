import SwiftUI
import Charts

struct NutritionProgressView: View {
    var dailyLog: DailyLog
    @ObservedObject var goal: GoalSettings

    @State private var showingBubbles = true // Controls which view is displayed
    @GestureState private var dragOffset: CGFloat = 0 // Tracks swipe gesture offset
    private let swipeThreshold: CGFloat = 50 // Minimum swipe distance to toggle

    var body: some View {
        let totalCalories = max(0, dailyLog.totalCalories())
        let totalMacros = dailyLog.totalMacros()
        let protein = max(0, totalMacros.protein)
        let fats = max(0, totalMacros.fats)
        let carbs = max(0, totalMacros.carbs)

        let caloriesGoal = goal.calories ?? 0
        let proteinGoal = goal.protein
        let fatsGoal = goal.fats
        let carbsGoal = goal.carbs

        let caloriesPercentage = (caloriesGoal > 0) ? min(totalCalories / max(caloriesGoal, 1), 1.0) : 0
        let proteinPercentage = (proteinGoal > 0) ? min(protein / max(proteinGoal, 1), 1.0) : 0
        let fatsPercentage = (fatsGoal > 0) ? min(fats / max(fatsGoal, 1), 1.0) : 0
        let carbsPercentage = (carbsGoal > 0) ? min(carbs / max(carbsGoal, 1), 1.0) : 0

        ZStack {
            if showingBubbles {
                bubblesView(
                    calories: totalCalories, caloriesGoal: caloriesGoal, caloriesPercentage: caloriesPercentage,
                    protein: protein, proteinGoal: proteinGoal, proteinPercentage: proteinPercentage,
                    fats: fats, fatsGoal: fatsGoal, fatsPercentage: fatsPercentage,
                    carbs: carbs, carbsGoal: carbsGoal, carbsPercentage: carbsPercentage
                )
            } else {
                HorizontalBarChartView(dailyLog: dailyLog, goal: goal)
            }
        }
        .frame(maxHeight: 250)
        .padding()
        .offset(x: dragOffset) // Apply swipe offset
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width // Update offset during drag
                }
                .onEnded { value in
                    if abs(value.translation.width) > swipeThreshold {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingBubbles.toggle() // Toggle view if swipe exceeds threshold
                        }
                    }
                }
        )
    }

    @ViewBuilder
    private func bubblesView(
        calories: Double, caloriesGoal: Double, caloriesPercentage: Double,
        protein: Double, proteinGoal: Double, proteinPercentage: Double,
        fats: Double, fatsGoal: Double, fatsPercentage: Double,
        carbs: Double, carbsGoal: Double, carbsPercentage: Double
    ) -> some View {
        HStack(spacing: 20) {
            ProgressBubble(
                value: calories,
                goal: caloriesGoal,
                percentage: caloriesPercentage,
                label: "Calories",
                unit: "kcal",
                color: .red
            )

            ProgressBubble(
                value: protein,
                goal: proteinGoal,
                percentage: proteinPercentage,
                label: "Protein",
                unit: "g",
                color: .blue
            )

            ProgressBubble(
                value: fats,
                goal: fatsGoal,
                percentage: fatsPercentage,
                label: "Fats",
                unit: "g",
                color: .green
            )

            ProgressBubble(
                value: carbs,
                goal: carbsGoal,
                percentage: carbsPercentage,
                label: "Carbs",
                unit: "g",
                color: .orange
            )
        }
    }
}

struct ProgressBubble: View {
    let value: Double
    let goal: Double
    let percentage: Double
    let label: String
    let unit: String
    let color: Color

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.2)
                    .foregroundColor(color)
                
                Circle()
                    .trim(from: 0, to: CGFloat(percentage))
                    .stroke(lineWidth: 8)
                    .foregroundColor(color)
                    .rotationEffect(.degrees(-90)) // Start from top
                
                VStack {
                    Text("\(String(format: "%.0f", value))")
                        .font(.headline)
                    Text("/ \(String(format: "%.0f", goal)) \(unit)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 80, height: 80)

            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}


