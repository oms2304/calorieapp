import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FoodSearchView: View {
    @Binding var dailyLog: DailyLog?
    var onLogUpdated: (DailyLog) -> Void
    var initialSearchQuery: String?

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dailyLogService: DailyLogService

    @State private var searchQuery = ""
    @State private var searchResults: [FoodItem] = []
    @State private var isLoading = false
    @State private var debounceTimer: Timer?
    @State private var recentFoods: [FoodItem] = []

    private let foodAPIService = FatSecretFoodAPIService()

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search food items...", text: $searchQuery)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .onChange(of: searchQuery) { newValue in
                            handleSearchQueryChange(newValue)
                        }

                    Button(action: performSearch) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    .padding(.trailing, 8)
                }
                .padding(.vertical)

                ScrollView {
                    VStack(spacing: 12) {
                        if isLoading {
                            ProgressView("Searching...")
                                .padding()
                        } else if !searchResults.isEmpty {
                            Text("Search Results")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            ForEach(searchResults, id: \.id) { foodItem in
                                NavigationLink(destination: FoodDetailView(
                                    foodItem: foodItem,
                                    dailyLog: $dailyLog,
                                    onLogUpdated: { updatedLog in
                                        onLogUpdated(updatedLog)
                                        dismiss()
                                    }
                                )) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(foodItem.name)
                                                .font(.headline)
                                            Text("\(foodItem.calories, specifier: "%.0f") kcal")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .shadow(radius: 3)
                                    .padding(.horizontal)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recently Added Foods")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 8)

                            if recentFoods.isEmpty {
                                Text("No recent foods added yet.")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            } else {
                                ForEach(recentFoods.prefix(10), id: \.id) { foodItem in
                                    NavigationLink(destination: FoodDetailView(
                                        foodItem: foodItem,
                                        dailyLog: $dailyLog,
                                        onLogUpdated: { updatedLog in
                                            onLogUpdated(updatedLog)
                                            dismiss()
                                        }
                                    )) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(foodItem.name)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                Text("\(foodItem.calories, specifier: "%.0f") kcal")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                        }
                                        .padding(10)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Food")
            .onAppear {
                searchQuery = initialSearchQuery ?? ""
                if let query = initialSearchQuery, !query.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        performSearch()
                    }
                } else {
                    searchResults = []
                }
                loadRecentFoods()
            }
        }
    }

    // MARK: - Search Handling
    private func handleSearchQueryChange(_ newValue: String) {
        debounceTimer?.invalidate()

        guard !newValue.isEmpty else {
            searchResults.removeAll()
            return
        }

        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            performSearch()
        }
    }

    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        isLoading = true

        if searchQuery.allSatisfy(\.isNumber) {
            print("🔎 Searching by Barcode: \(searchQuery)")
            foodAPIService.fetchFoodByBarcode(barcode: searchQuery) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.handleSearchResults(result)
                }
            }
        } else {
            print("🔎 Searching by Query: \(searchQuery)")
            foodAPIService.fetchFoodByQuery(query: searchQuery) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.handleSearchResults(result)
                }
            }
        }
    }

    private func handleSearchResults(_ result: Result<[FoodItem], Error>) {
        switch result {
        case .success(let foodItems):
            if !foodItems.isEmpty {
                print("✅ Found \(foodItems.count) results.")
                self.searchResults = foodItems
            } else {
                print("⚠️ No results were found in the API response.")
                self.searchResults = []
            }
        case .failure(let error):
            print("❌ API Fetch Error: \(error.localizedDescription)")
            self.searchResults = []
        }
    }

    // MARK: - Load Recent Foods
    private func loadRecentFoods() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user ID found, cannot load recent foods")
            return
        }

        dailyLogService.fetchDailyHistory(for: userID) { result in
            switch result {
            case .success(let logs):
                // Flatten food items and sort by timestamp (newest first)
                let allFoodItems = logs
                    .flatMap { $0.meals.flatMap { $0.foodItems } }
                    .filter { $0.timestamp != nil } // Only include items with timestamps
                    .sorted(by: { $0.timestamp! > $1.timestamp! }) // Sort by timestamp descending
                
                DispatchQueue.main.async {
                    // Remove duplicates by ID (keep newest occurrence), limit to 10
                    var uniqueFoodItems: [FoodItem] = []
                    var seenIDs = Set<String>()
                    for item in allFoodItems {
                        if !seenIDs.contains(item.id) {
                            uniqueFoodItems.append(item)
                            seenIDs.insert(item.id)
                        }
                        if uniqueFoodItems.count >= 10 { break }
                    }
                    self.recentFoods = uniqueFoodItems
                }
            case .failure(let error):
                print("❌ Error fetching daily history: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.recentFoods = []
                }
            }
        }
    }
}
