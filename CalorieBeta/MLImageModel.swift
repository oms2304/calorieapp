import Foundation
import UIKit
import CoreML
import Vision

enum ImageRecognitionError: Error {
    case modelNotFound
    case imageProcessingError
    case predictionError(Error)
    case invalidOutputFormat
}

class MLImageModel {
    private let model: VNCoreMLModel
    private let foodCategories: [String] = Food101Categories.allCases.map { $0.rawValue } // Assuming Food-101 categories

    init() {
        do {
            // Load the MobileNetV3 Food-101 model
            let modelConfig = MLModelConfiguration()
            // Access the MLModel instance from the generated model class
            let coreMLModel = try mobilenetv3_food101_full().model // Use .model to get the MLModel instance
            self.model = try VNCoreMLModel(for: coreMLModel)
        } catch {
            fatalError("Failed to load MobileNetV3 Food-101 model: \(error.localizedDescription)")
        }
    }

    /// Classifies a food item from an image using the local MobileNetV3 Food-101 model
    func classifyImage(image: UIImage, completion: @escaping (Result<String, ImageRecognitionError>) -> Void) {
        // Resize image to 224x224 as required by the model
        guard let resizedImage = image.resized(toSize: CGSize(width: 224, height: 224)),
              let ciImage = CIImage(image: resizedImage) else {
            print("❌ Failed to process or resize image to 224x224")
            completion(.failure(.imageProcessingError))
            return
        }

        let requestHandler = VNImageRequestHandler(ciImage: ciImage)
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let observations = request.results as? [VNClassificationObservation], !observations.isEmpty else {
                print("❌ No classification results or error: \(String(describing: error))")
                DispatchQueue.main.async {
                    completion(.failure(.predictionError(error ?? NSError(domain: "NoResults", code: -1, userInfo: nil))))
                }
                return
            }

            // Get the top prediction (highest confidence) from VNClassificationObservation
            let topPrediction = observations[0]
            let foodName = topPrediction.identifier // This should be the food category name (e.g., "pizza", "hamburger")
            let confidence = topPrediction.confidence

            print("✅ Predicted food: \(foodName) (confidence: \(confidence))")
            DispatchQueue.main.async {
                completion(.success(foodName))
            }
        }

        // Ensure the image is scaled to 224x224 (model input size)
        request.imageCropAndScaleOption = .scaleFill

        do {
            try requestHandler.perform([request])
        } catch {
            print("❌ Failed to perform image classification: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(.failure(.predictionError(error)))
            }
        }
    }
}

extension UIImage {
    func resized(toSize size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

// Enum for Food-101 categories (you need to define all 101 categories)
enum Food101Categories: String, CaseIterable {
    case apple_pie, baby_back_ribs, baklava, beef_carpaccio, beef_tartare, // ... Add all 101 categories here
         beef_tongue, beet_salad, beignets, bibimbap, bread_pudding, // Partial list for example
         breakfast_burrito, bruschetta, caesar_salad, cannoli, caprese_salad,
         carrot_cake, ceviche, cheesecake, chicken_curry, chicken_quesadilla,
         chicken_wings, chocolate_cake, chocolate_mousse, churros, clam_chowder,
         club_sandwich, crab_cakes, creme_brulee, croques_monsieur, deviled_eggs,
         donuts, dumplings, edamame, eggs_benedict, escargot, falafel, filet_mignon,
         fish_and_chips, foie_gras, french_fries, french_onion_soup, french_toast,
         fried_calamari, fried_rice, fruit_salad, garlic_bread, gnocchi, greek_salad,
         grilled_cheese_sandwich, grilled_salmon, guacamole, gyoza, hamburger,
         hot_and_sour_soup, hot_dog, huevos_rancheros, hummus, ice_cream, lamb_shanks,
         lasagna, lobster_bisque, lobster_roll_sandwich, macaroni_and_cheese, macarons,
         miso_soup, mussels, nachos, omelette, onion_rings, oysters, pad_thai, paella,
         pancakes, panna_cotta, peking_duck, pho, pizza, pork_chop, pork_gyoza,
         pulled_pork_sandwich, ramen, ravioli, red_velvet_cake, risotto, samosa,
         sashimi, scallops, seafood_pasta, shrimp_and_grits, spaghetti_bolognese,
         spaghetti_carbonara, spring_rolls, steak, strawberry_shortcake, sushi,
         tacos, takoyaki, tiramisu, tuna_tartare, waffles
    // Ensure you list all 101 categories from the Food-101 dataset here
}
