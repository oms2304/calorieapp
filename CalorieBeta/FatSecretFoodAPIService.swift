import Foundation

// 🔹 FatSecret API Response Models
struct FatSecretResponse: Decodable {
    let foods: FoodList?
}

struct FoodList: Decodable {
    let food: [FatSecretFoodItem]?
}

struct FoodItem: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double
    var servingSize: String
    var servingWeight: Double
    var timestamp: Date? // Added for exact addition time

    enum CodingKeys: String, CodingKey {
        case id = "food_id"
        case name = "food_name"
        case calories
        case protein
        case carbs = "carbohydrate"
        case fats = "fat"
        case servingSize = "serving_description"
        case servingWeight = "metric_serving_amount"
        case timestamp // Add this to Firestore encoding
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FoodItem, rhs: FoodItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// ✅ FatSecretFoodItem for API search results
struct FatSecretFoodItem: Decodable {
    let foodID: String
    let foodName: String?
    let brandName: String?
    let foodDescription: String?
    let servingSize: String?
    let servingWeight: Double?

    enum CodingKeys: String, CodingKey {
        case foodID = "food_id"
        case foodName = "food_name"
        case brandName = "brand_name"
        case foodDescription = "food_description"
        case servingSize, servingWeight
    }
}

// ✅ API Response Model for Food Details
struct FatSecretFoodResponse: Decodable {
    let food: FatSecretFood?
}

struct FatSecretFood: Decodable {
    let foodID: String
    let foodName: String
    let brandName: String?
    let servings: FatSecretServings

    enum CodingKeys: String, CodingKey {
        case foodID = "food_id"
        case foodName = "food_name"
        case brandName = "brand_name"
        case servings
    }
}

// ✅ Handles cases where "serving" is either an object or an array
struct FatSecretServings: Decodable {
    let serving: [FatSecretServing]

    enum CodingKeys: String, CodingKey {
        case serving
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try decoding as an array first
        if let servingArray = try? container.decode([FatSecretServing].self, forKey: .serving) {
            self.serving = servingArray
        }
        // If it's a single object, wrap it in an array
        else if let singleServing = try? container.decode(FatSecretServing.self, forKey: .serving) {
            self.serving = [singleServing]
        } else {
            self.serving = [] // Default to empty if no servings found
        }
    }
}

// ✅ Improved FatSecretServing Parsing
struct FatSecretServing: Decodable {
    let calories: String?
    let protein: String?
    let carbohydrate: String?
    let fat: String?
    let servingDescription: String?
    let metricServingAmount: String?

    enum CodingKeys: String, CodingKey {
        case calories, protein, carbohydrate, fat
        case servingDescription = "serving_description"
        case metricServingAmount = "metric_serving_amount"
    }

    // ✅ Improved Utility function to clean and parse numbers
    private func parseDouble(from string: String?) -> Double {
        guard let string = string else { return 0.0 }
        
     
        let cleanedString = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        return Double(cleanedString) ?? 0.0
    }

    var parsedCalories: Double {
        return parseDouble(from: calories)
    }

    var parsedProtein: Double {
        return parseDouble(from: protein)
    }

    var parsedCarbs: Double {
        return parseDouble(from: carbohydrate)
    }

    var parsedFats: Double {
        return parseDouble(from: fat)
    }

    var parsedServingWeight: Double {
        return parseDouble(from: metricServingAmount) != 0.0 ? parseDouble(from: metricServingAmount) : 100.0
    }
}




class FatSecretFoodAPIService {
    private let proxyURL = "http://34.75.143.244:8080"
    private var barcodeCache = Set<String>()  // ✅ Prevents duplicate searches

    // 🔹 Fetch food by barcode
    func fetchFoodByBarcode(barcode: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        if barcodeCache.contains(barcode) {
            print("🔄 Skipping duplicate barcode search: \(barcode)")
            return
        }
        barcodeCache.insert(barcode)  // ✅ Adds barcode to cache to prevent looping

        guard let url = URL(string: "\(proxyURL)/barcode?barcode=\(barcode)") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { data, _, error in
            defer { self.barcodeCache.remove(barcode) }  // ✅ Ensure cache is cleared after search

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode([String: [String: String]].self, from: data)
                if let foodId = decodedResponse["food_id"]?["value"] {
                    print("✅ Found Food ID: \(foodId). Fetching full food details...")

                    // Fetch Full Food Details
                    self.fetchFoodDetails(foodId: foodId) { result in
                        switch result {
                        case .success(let foodItem):
                            completion(.success([foodItem])) // ✅ Ensures array format
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    print("⚠️ FatSecret Barcode Lookup Failed.")
                    completion(.failure(APIError.noData))
                }
            } catch {
                print("❌ Decoding Error: \(error.localizedDescription)")
                completion(.failure(APIError.decodingError))
            }
        }.resume()
    }


    // 🔹 Fetch full food details using food.get
    private func fetchFoodDetails(foodId: String, completion: @escaping (Result<FoodItem, Error>) -> Void) {
        guard let url = URL(string: "\(proxyURL)/food?food_id=\(foodId)") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            let jsonString = String(data: data, encoding: .utf8) ?? ""
            print("📥 Raw FatSecret API Response (Food Details):\n\(jsonString)")

            do {
                let decodedResponse = try JSONDecoder().decode(FatSecretFoodResponse.self, from: data)

                guard let food = decodedResponse.food else {
                    print("⚠️ No food object found in response.")
                    completion(.failure(APIError.noData))
                    return
                }
                print("✅ Successfully parsed food: \(food.foodName)")

                if food.servings.serving.isEmpty {
                    print("⚠️ No serving data found in response.")
                    completion(.failure(APIError.noData))
                    return
                }

                let serving = food.servings.serving.first!

                let foodItem = FoodItem(
                    id: food.foodID,
                    name: food.brandName.map { "\($0) \(food.foodName)" } ?? food.foodName,
                    calories: serving.parsedCalories,  // ✅ Make sure this is assigned
                    protein: serving.parsedProtein,    // ✅ Same here
                    carbs: serving.parsedCarbs,        // ✅ Same here
                    fats: serving.parsedFats,          // ✅ Same here
                    servingSize: serving.servingDescription ?? "N/A",
                    servingWeight: serving.parsedServingWeight
                )


                print("✅ Successfully created FoodItem: \(foodItem.name) with \(foodItem.calories) kcal")
                completion(.success(foodItem))

            } catch {
                print("❌ Detailed Decoding Error: \(error)")
                completion(.failure(APIError.decodingError))
            }
        }.resume()
    }



    // 🔹 Fetch food by search query
    func fetchFoodByQuery(query: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        guard let url = URL(string: "\(proxyURL)/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            completion(.success([])) // ✅ Return an empty list instead of an error
            return
        }

        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            let jsonString = String(data: data, encoding: .utf8) ?? ""
            print("📥 Raw FatSecret API Response (Query):\n\(jsonString)")

            do {
                let decodedResponse = try JSONDecoder().decode(FatSecretResponse.self, from: data)
                if let foods = decodedResponse.foods?.food {
                    let foodItems = foods.map { self.parseFoodSearchItem(from: $0) }
                    completion(.success(foodItems))
                } else {
                    print("⚠️ FatSecret returned no search results.")
                    completion(.failure(APIError.noData))
                }
            } catch {
                print("❌ Decoding Error: \(error.localizedDescription)")
                completion(.failure(APIError.decodingError))
            }
        }.resume()
    }

    // ✅ Restored: Parse food item for detailed lookups
    private func parseFoodItem(from fatSecretFood: FatSecretFood) -> FoodItem {
        let fullName = fatSecretFood.brandName.map { "\($0) \(fatSecretFood.foodName)" } ?? fatSecretFood.foodName
        let serving = fatSecretFood.servings.serving.first!

        return FoodItem(
            id: fatSecretFood.foodID,
            name: fullName,
            calories: Double(serving.calories ?? "0") ?? 0.0,
            protein: Double(serving.protein ?? "0") ?? 0.0,
            carbs: Double(serving.carbohydrate ?? "0") ?? 0.0,
            fats: Double(serving.fat ?? "0") ?? 0.0,
            servingSize: serving.servingDescription ?? "N/A",
            servingWeight: Double(serving.metricServingAmount ?? "100") ?? 100.0
        )
    }

    // ✅ Restored: Parse food item for search queries
    private func parseFoodSearchItem(from fatSecretFoodItem: FatSecretFoodItem) -> FoodItem {
        let fullName = fatSecretFoodItem.brandName.map { "\($0) \(fatSecretFoodItem.foodName ?? "")" } ?? (fatSecretFoodItem.foodName ?? "Unknown")
        let nutrients = parseNutrients(from: fatSecretFoodItem.foodDescription)
        
        return FoodItem(
            id: fatSecretFoodItem.foodID,
            name: fullName,
            calories: nutrients.calories,
            protein: nutrients.protein,
            carbs: nutrients.carbs,
            fats: nutrients.fats,
            servingSize: fatSecretFoodItem.servingSize ?? "N/A",
            servingWeight: fatSecretFoodItem.servingWeight ?? 100.0
        )
    }
    
    private func parseNutrients(from description: String?) -> (calories: Double, protein: Double, carbs: Double, fats: Double) {
        guard let description = description else { return (0.0, 0.0, 0.0, 0.0) }
        
        var calories = 0.0
        var protein = 0.0
        var carbs = 0.0
        var fats = 0.0
        
        let components = description.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        for component in components {
            print("🔍 Parsing component: \(component)") // Debug
            if component.contains("Calories:") {
                let caloriesPart = component.split(separator: "-").last?.trimmingCharacters(in: .whitespaces) ?? component
                let cleaned = caloriesPart.replacingOccurrences(of: "Calories:", with: "").replacingOccurrences(of: "kcal", with: "").trimmingCharacters(in: .whitespaces)
                print("🔍 Calories cleaned: \(cleaned)") // Debug
                if let value = Double(cleaned) {
                    calories = value
                    print("🔍 Calories set to: \(value)") // Debug
                } else {
                    print("🔍 Failed to parse calories from: \(cleaned)") // Debug
                }
            } else if component.contains("Fat:") {
                let cleaned = component.replacingOccurrences(of: "Fat:", with: "").replacingOccurrences(of: "g", with: "").trimmingCharacters(in: .whitespaces)
                if let value = Double(cleaned) {
                    fats = value
                }
            } else if component.contains("Carbs:") {
                let cleaned = component.replacingOccurrences(of: "Carbs:", with: "").replacingOccurrences(of: "g", with: "").trimmingCharacters(in: .whitespaces)
                if let value = Double(cleaned) {
                    carbs = value
                }
            } else if component.contains("Protein:") {
                let cleaned = component.replacingOccurrences(of: "Protein:", with: "").replacingOccurrences(of: "g", with: "").trimmingCharacters(in: .whitespaces)
                if let value = Double(cleaned) {
                    protein = value
                }
            }
        }
        
        print("🔍 Final nutrients: calories=\(calories), protein=\(protein), carbs=\(carbs), fats=\(fats)") // Debug
        return (calories, protein, carbs, fats)
    }
}
