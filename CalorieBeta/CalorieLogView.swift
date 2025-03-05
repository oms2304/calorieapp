import SwiftUI
import FirebaseFirestore

struct CalorieLogView: View {
    @State private var dailyLog = DailyLog(
        date: Date(),
        meals: [],
        totalCaloriesOverride: nil
    )
    
    @State private var showAddFoodSheet = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Total Calories: \(dailyLog.totalCalories()) kcal")
                    .font(.title)
                    .padding()

                
                List {
                    ForEach(dailyLog.meals) { meal in
                        Section(header: Text(meal.name)) {
                            ForEach(meal.foodItems) { food in
                                VStack(alignment: .leading) {
                                    Text(food.name)
                                        .font(.headline)
                                    
                                    Text("\(food.calories, specifier: "%.1f") kcal • Protein: \(food.protein, specifier: "%.1f")g • Carbs: \(food.carbs, specifier: "%.1f")g • Fats: \(food.fats, specifier: "%.1f")g")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }

                Spacer()

                
                Button(action: {
                    showAddFoodSheet = true
                }) {
                    Text("Add Food")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .sheet(isPresented: $showAddFoodSheet) {
                    AddFoodView { newFood in
                        addFoodToLog(newFood)
                    }
                }
            }
            .navigationTitle("Calorie Log")
        }
    }

    private func addFoodToLog(_ newFood: FoodItem) {
   
        if let firstMealIndex = dailyLog.meals.firstIndex(where: { !$0.foodItems.isEmpty }) {
            dailyLog.meals[firstMealIndex].foodItems.append(newFood)
        } else {
            let newMeal = Meal(id: UUID().uuidString, name: "All Meals", foodItems: [newFood])
            dailyLog.meals.append(newMeal)
        }
    }
}
