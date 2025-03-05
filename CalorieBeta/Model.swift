

import Foundation
import FirebaseFirestore

struct DailyLog: Codable, Identifiable {
    var id: String?
    var date: Date
    var meals: [Meal]
    var totalCaloriesOverride: Double?
    
    func totalCalories() -> Double {
        meals.flatMap { $0.foodItems }.reduce(0) { $0 + $1.calories }
    }

    func totalMacros() -> (protein: Double, fats: Double, carbs: Double) {
        let protein = meals.flatMap { $0.foodItems }.reduce(0) { $0 + $1.protein }
        let fats = meals.flatMap { $0.foodItems }.reduce(0) { $0 + $1.fats }
        let carbs = meals.flatMap { $0.foodItems }.reduce(0) { $0 + $1.carbs }
        return (protein, fats, carbs)
    }
}

struct Meal: Codable, Identifiable {
    var id: String
    var name: String
    var foodItems: [FoodItem]
}


struct CommunityPost: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString
    let author: String
    let content: String
    var likes: Int
    var isLikedByCurrentUser: Bool
    var reactions: [String: Int]
    var comments: [Comment]
    var timestamp: Date = Date()
    var groupID: String

    struct Comment: Identifiable, Codable {
        let id: String = UUID().uuidString
        let author: String
        let content: String
        var replies: [Reply] = []

        struct Reply: Identifiable, Codable {
            let id: String = UUID().uuidString
            let author: String
            let content: String
        }
    }
}

struct CommunityGroup: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
    var creatorID: String
    var isPreset: Bool
}

struct GroupMembership: Codable {
    var groupID: String
    var userID: String
}

struct CalorieRecord: Identifiable, Codable {
    var id: String = UUID().uuidString
    var date: Date
    var calories: Double
    var description: String
}

struct Post: Identifiable {
    let id: String
    let content: String
    let timestamp: Date
}

struct Achievement: Identifiable {
    let id: String
    let title: String
}
