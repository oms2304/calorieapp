import SwiftUI
import Firebase
import FirebaseAuth

struct CaloricCalculatorView: View {
    @EnvironmentObject var goalSettings: GoalSettings
    @State private var activityLevel: Double = 1.2
    @State private var goal: String = "Maintain"
    @State private var age: String = "25"
    @State private var gender: String = "Male"
    @State private var showSaveConfirmation = false

    private let activityLevels = [
        ("Sedentary", 1.2),
        ("Lightly Active", 1.375),
        ("Moderately Active", 1.55),
        ("Very Active", 1.725),
        ("Extremely Active", 1.9)
    ]

    private let genders = ["Male", "Female"]

    var body: some View {
        Form {
            Section(header: Text("Your Information")) {
                TextField("Age (years)", text: $age)
                    .keyboardType(.numberPad)

                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { gender in
                        Text(gender)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Picker("Activity Level", selection: $activityLevel) {
                    ForEach(activityLevels, id: \.1) { level in
                        Text(level.0).tag(level.1)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            Section(header: Text("Macronutrient Distribution (%)")) {
                VStack {
                    HStack {
                        Text("Protein")
                        Spacer()
                        Slider(value: $goalSettings.proteinPercentage, in: 10...50, step: 5)
                        Text("\(Int(goalSettings.proteinPercentage))%")
                    }
                    HStack {
                        Text("Carbs")
                        Spacer()
                        Slider(value: $goalSettings.carbsPercentage, in: 10...60, step: 5)
                        Text("\(Int(goalSettings.carbsPercentage))%")
                    }
                    HStack {
                        Text("Fats")
                        Spacer()
                        Slider(value: $goalSettings.fatsPercentage, in: 10...40, step: 5)
                        Text("\(Int(goalSettings.fatsPercentage))%")
                    }
                }
            }

            Section(header: Text("Recommended Calorie Intake")) {
                Text("\(calculateCalories(), specifier: "%.0f") kcal")
                    .font(.title)
                    .foregroundColor(.blue)
            }

            Button(action: saveCaloricGoal) {
                Text("Save Calorie Goal")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .navigationTitle("Calorie Calculator")
        .onAppear(perform: fetchCaloricGoal)
        .alert(isPresented: $showSaveConfirmation) {
            Alert(title: Text("Success"), message: Text("Calorie goal saved!"), dismissButton: .default(Text("OK")))
        }
    }

    private func calculateCalories() -> Double {
        guard let ageValue = Int(age), ageValue > 0 else { return 0 }
        let weightInKg = goalSettings.weight * 0.453592
        let heightInCm = goalSettings.height

        let bmr: Double
        if gender == "Male" {
            bmr = 10 * weightInKg + 6.25 * heightInCm - 5 * Double(ageValue) + 5
        } else {
            bmr = 10 * weightInKg + 6.25 * heightInCm - 5 * Double(ageValue) - 161
        }

        var calories = bmr * activityLevel
        switch goal {
        case "Lose":
            calories -= 500
        case "Gain":
            calories += 500
        default:
            break
        }

        return max(calories, 0)
    }

    private func saveCaloricGoal() {
        goalSettings.calories = calculateCalories()
        goalSettings.updateMacros()  // 🔹 Direct method call instead of dynamic lookup
        goalSettings.saveUserGoals(userID: Auth.auth().currentUser?.uid ?? "")
        showSaveConfirmation = true
    }

    private func fetchCaloricGoal() {
        goalSettings.loadUserGoals(userID: Auth.auth().currentUser?.uid ?? "")
    }
}
