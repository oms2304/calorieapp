import Foundation
import FirebaseFirestore
import FirebaseAuth

class GoalSettings: ObservableObject {
    @Published var calories: Double?
    @Published var protein: Double = 150
    @Published var fats: Double = 70
    @Published var carbs: Double = 250
    @Published var weight: Double = 150.0
    @Published var height: Double = 170.0
    @Published var weightHistory: [(date: Date, weight: Double)] = []
    @Published var isUpdatingGoal: Bool = false

    // 🔹 Macronutrient distribution percentages
    @Published var proteinPercentage: Double = 30.0
    @Published var carbsPercentage: Double = 50.0
    @Published var fatsPercentage: Double = 20.0

    private let db = Firestore.firestore()
    private var isFetchingGoals = false
    private var isGoalsLoaded = false

    // ============================
    // 🔹 **Method: Updates Macronutrients Based on Calories**
    // ============================
    func updateMacros() {
        guard let calorieGoal = calories else { return }

        // Ensure percentages sum up to 100%
        let totalPercentage = proteinPercentage + carbsPercentage + fatsPercentage
        guard totalPercentage == 100 else {
            print("❌ Macronutrient percentages do not sum to 100%")
            return
        }

        // 1g protein = 4 kcal, 1g carbs = 4 kcal, 1g fats = 9 kcal
        let proteinCalories = (proteinPercentage / 100) * calorieGoal
        let carbsCalories = (carbsPercentage / 100) * calorieGoal
        let fatsCalories = (fatsPercentage / 100) * calorieGoal

        self.protein = proteinCalories / 4
        self.carbs = carbsCalories / 4
        self.fats = fatsCalories / 9

        print("✅ Updated Macros: \(self.protein)g Protein, \(self.carbs)g Carbs, \(self.fats)g Fats")
    }

    // ============================
    // 🔹 **Method: Loads User Goals from Firestore**
    // ============================
    func loadUserGoals(userID: String, completion: @escaping () -> Void = {}) {
        guard !isFetchingGoals else { return }
        isFetchingGoals = true

        db.collection("users").document(userID).getDocument { [weak self] document, error in
            defer {
                self?.isFetchingGoals = false
                self?.isGoalsLoaded = true
                completion()
            }
            guard let self = self else { return }

            if let document = document, document.exists, let data = document.data() {
                DispatchQueue.main.async {
                    if let goals = data["goals"] as? [String: Any] {
                        self.calories = goals["calories"] as? Double ?? self.calories
                        self.protein = goals["protein"] as? Double ?? self.protein
                        self.fats = goals["fats"] as? Double ?? self.fats
                        self.carbs = goals["carbs"] as? Double ?? self.carbs
                        self.proteinPercentage = goals["proteinPercentage"] as? Double ?? self.proteinPercentage
                        self.carbsPercentage = goals["carbsPercentage"] as? Double ?? self.carbsPercentage
                        self.fatsPercentage = goals["fatsPercentage"] as? Double ?? self.fatsPercentage
                    }

                    self.weight = data["weight"] as? Double ?? self.weight
                    self.height = data["height"] as? Double ?? self.height

                    // 🔹 Ensure macros are updated after loading from Firestore
                    self.updateMacros()

                    print("✅ Loaded user goals: \(self.calories ?? 0) calories")
                }
            } else {
                print("❌ Error fetching user goals: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    // ============================
    // 🔹 **Method: Saves User Goals to Firestore**
    // ============================
    func saveUserGoals(userID: String) {
        self.isUpdatingGoal = true

        // 🔹 Ensure macros are updated before saving
        self.updateMacros()

        let goalData = [
            "calories": calories ?? 2000,
            "protein": protein,
            "fats": fats,
            "carbs": carbs,
            "proteinPercentage": proteinPercentage,
            "carbsPercentage": carbsPercentage,
            "fatsPercentage": fatsPercentage
        ] as [String: Any]

        let userData = [
            "goals": goalData,
            "weight": weight,
            "height": height
        ] as [String: Any]

        db.collection("users").document(userID).setData(userData, merge: true) { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isUpdatingGoal = false
            }

            if let error = error {
                print("❌ Error saving user goals: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    print("✅ User goals saved successfully.")
                }
            }
        }
    }

    // ============================
    // 🔹 **Weight Management**
    // ============================
    func loadWeightHistory() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userID).collection("weightHistory")
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching weight history: \(error.localizedDescription)")
                    return
                }

                DispatchQueue.main.async {
                    self.weightHistory = snapshot?.documents.compactMap { doc in
                        if let weight = doc.data()["weight"] as? Double,
                           let timestamp = doc.data()["timestamp"] as? Timestamp {
                            return (timestamp.dateValue(), weight)
                        }
                        return nil
                    } ?? []
                }
            }
    }


    func updateUserWeight(_ newWeight: Double) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        weight = newWeight

        let weightData: [String: Any] = [
            "weight": newWeight,
            "timestamp": Timestamp(date: Date())
        ]

        // ✅ Store both in user's document and weight history collection
        db.collection("users").document(userID).setData(["weight": newWeight], merge: true)

        db.collection("users").document(userID).collection("weightHistory")
            .addDocument(data: weightData) { error in
                if let error = error {
                    print("❌ Error saving weight history: \(error.localizedDescription)")
                } else {
                    print("✅ Weight history updated successfully.")
                }
            }
    }



    // ============================
    // 🔹 **Methods for Height Conversion**
    // ============================
    func getHeightInFeetAndInches() -> (feet: Int, inches: Int) {
        let totalInches = Int(height / 2.54)
        let feet = totalInches / 12
        let inches = totalInches % 12
        return (feet, inches)
    }

    func setHeight(feet: Int, inches: Int) {
        let totalInches = (feet * 12) + inches
        height = Double(totalInches) * 2.54
    }
}
