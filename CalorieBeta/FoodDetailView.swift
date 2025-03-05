import SwiftUI
import FirebaseAuth

struct FoodDetailView: View {
    var foodItem: FoodItem
    @Binding var dailyLog: DailyLog?
    var onLogUpdated: (DailyLog) -> Void

    @State private var quantity: String
    @State private var customServingSize: String
    @State private var selectedServingUnit: String
    @State private var useCustomServing: Bool

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dailyLogService: DailyLogService
    @Environment(\.presentationMode) var presentationMode // Added for NavigationLink dismissal

    init(foodItem: FoodItem, dailyLog: Binding<DailyLog?>, onLogUpdated: @escaping (DailyLog) -> Void) {
        self.foodItem = foodItem
        self._dailyLog = dailyLog
        self.onLogUpdated = onLogUpdated

        self._quantity = State(initialValue: "1")
        self._customServingSize = State(initialValue: String(Int(foodItem.servingWeight)))
        self._selectedServingUnit = State(initialValue: foodItem.servingSize.contains("oz") ? "oz" : "g")
        self._useCustomServing = State(initialValue: foodItem.servingWeight != 100.0)

        print("✅ Received FoodItem in Detail View: \(foodItem.name)")
        print("🔹 Calories: \(foodItem.calories)")
        print("🔹 Protein: \(foodItem.protein)")
        print("🔹 Carbs: \(foodItem.carbs)")
        print("🔹 Fats: \(foodItem.fats)")
        print("🔹 Serving Weight: \(foodItem.servingWeight)g")
    }

    var baseServingWeight: Double {
        return foodItem.servingWeight > 0 ? foodItem.servingWeight : 100.0
    }

    var conversionFactor: Double {
        return selectedServingUnit == "oz" ? 1 / 28.3495 : 1.0
    }

    var adjustedNutrients: FoodItem {
        let enteredQuantity = Double(quantity) ?? 1.0
        let customWeight = Double(customServingSize) ?? baseServingWeight
        let convertedWeight = useCustomServing ? (customWeight * conversionFactor) : baseServingWeight
        let factor = (convertedWeight / baseServingWeight) * enteredQuantity

        return FoodItem(
            id: foodItem.id,
            name: foodItem.name,
            calories: foodItem.calories * factor,
            protein: foodItem.protein * factor,
            carbs: foodItem.carbs * factor,
            fats: foodItem.fats * factor,
            servingSize: "\(Int(convertedWeight))\(selectedServingUnit)",
            servingWeight: convertedWeight
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nutritional Information")
                        .font(.headline)

                    HStack {
                        Text("Item:")
                            .fontWeight(.bold)
                        Text(foodItem.name)
                    }

                    HStack {
                        Text("Calories:")
                            .fontWeight(.bold)
                        Text("\(adjustedNutrients.calories, specifier: "%.0f") kcal")
                    }

                    HStack {
                        Text("Carbs:")
                            .fontWeight(.bold)
                        Text("\(adjustedNutrients.carbs, specifier: "%.1f")g")
                    }

                    HStack {
                        Text("Proteins:")
                            .fontWeight(.bold)
                        Text("\(adjustedNutrients.protein, specifier: "%.1f")g")
                    }

                    HStack {
                        Text("Fats:")
                            .fontWeight(.bold)
                        Text("\(adjustedNutrients.fats, specifier: "%.1f")g")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Adjust Quantity")
                        .font(.headline)

                    HStack {
                        Text("Servings:")
                        TextField("1", text: $quantity)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                    }

                    Toggle("Use Custom Serving Size", isOn: $useCustomServing)
                        .padding(.top, 5)

                    if useCustomServing {
                        HStack {
                            Text("Custom Size:")
                            TextField("\(Int(baseServingWeight))", text: $customServingSize)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)

                            Picker("Unit", selection: $selectedServingUnit) {
                                Text("g").tag("g")
                                Text("oz").tag("oz")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 100)
                        }
                    } else {
                        HStack {
                            Text("Recommended Size:")
                                .fontWeight(.bold)
                            Text("\(Int(baseServingWeight))g")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                Button(action: {
                    if var log = dailyLog {
                        // Check if this is an update or a new addition
                        let isUpdating = log.meals.contains { meal in
                            meal.foodItems.contains { $0.id == foodItem.id }
                        }

                        if isUpdating {
                            // Remove the old food item
                            for i in log.meals.indices {
                                log.meals[i].foodItems.removeAll { $0.id == foodItem.id }
                            }
                        }

                        // Add the updated/new food item
                        if let userID = Auth.auth().currentUser?.uid {
                            dailyLogService.addFoodToCurrentLog(for: userID, foodItem: adjustedNutrients)
                            onLogUpdated(log)
                        }
                    }
                    // Dismiss back to HomeView
                    presentationMode.wrappedValue.dismiss() // Dismiss FoodDetailView
                    dismiss() // Dismiss FoodSearchView sheet if present
                }) {
                    Text(dailyLog?.meals.contains { $0.foodItems.contains { $0.id == foodItem.id } } == true ? "Update Log" : "Add to Log")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Edit Food")
        .navigationBarTitleDisplayMode(.inline)
    }
}
