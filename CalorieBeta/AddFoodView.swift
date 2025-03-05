import SwiftUI

struct AddFoodView: View {
    var onFoodLogged: (FoodItem) -> Void

    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 12) {
            TextField("Food Name", text: $foodName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Calories", text: $calories)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Protein (g)", text: $protein)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Carbs (g)", text: $carbs)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Fats (g)", text: $fats)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: logFood) {
                Text("Log Food")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
        }
        .navigationTitle("Add Food")
    }

    private func logFood() {
        guard !foodName.isEmpty, let caloriesValue = Double(calories) else {
            print("Invalid input: food name or calories")
            return
        }

        let proteinValue = Double(protein) ?? 0.0
        let carbsValue = Double(carbs) ?? 0.0
        let fatsValue = Double(fats) ?? 0.0

        let newFood = FoodItem(
            id: UUID().uuidString,
            name: foodName,
            calories: caloriesValue,
            protein: proteinValue,
            carbs: carbsValue,
            fats: fatsValue,
            servingSize: "N/A",
            servingWeight: 0.0
        )

        onFoodLogged(newFood)
        dismiss()
    }
}
