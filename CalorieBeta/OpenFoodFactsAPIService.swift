import Foundation

struct OpenFoodFactsResponse: Codable {
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let nutriments: OpenFoodFactsNutriments?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
    }
}

struct OpenFoodFactsNutriments: Codable {
    let energyKcal: Double?
    let protein: Double?
    let carbs: Double?
    let fats: Double?
    let servingWeight: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g"
        case protein = "proteins_100g"
        case carbs = "carbohydrates_100g"
        case fats = "fat_100g"
        case servingWeight = "serving_size"
    }
}

class OpenFoodFactsAPIService {
    func fetchFoodByBarcode(barcode: String, completion: @escaping (Result<FoodItem, Error>) -> Void) {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
                if let product = decodedResponse.product {
                    let foodItem = FoodItem(
                        id: barcode,
                        name: product.productName ?? "Unknown",
                        calories: product.nutriments?.energyKcal ?? 0,
                        protein: product.nutriments?.protein ?? 0,
                        carbs: product.nutriments?.carbs ?? 0,
                        fats: product.nutriments?.fats ?? 0,
                        servingSize: "100g",
                        servingWeight: product.nutriments?.servingWeight ?? 100.0
                    )
                    completion(.success(foodItem))
                } else {
                    completion(.failure(APIError.noData))
                }
            } catch {
                completion(.failure(APIError.decodingError))
            }
        }.resume()
    }
}
