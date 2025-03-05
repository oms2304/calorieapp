

import SwiftUI
import FirebaseFirestore

struct FoodLogView: View {
    var meals: [Meal]
    var body: some View {
        List {
            ForEach(meals) { meal in
                Section(header: Text(meal.name)) {
                    ForEach(meal.foodItems, id: \.name) { item in  
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                Text("\(item.calories, specifier: "%.1f") kcal")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("Protein: \(String(format: "%.1f", item.protein))g")
                            Text("Fats: \(String(format: "%.1f", item.fats))g")
                            Text("Carbs: \(String(format: "%.1f", item.carbs))g")
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}
