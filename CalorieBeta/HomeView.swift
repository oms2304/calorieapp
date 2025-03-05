import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var goalSettings: GoalSettings
    @EnvironmentObject var dailyLogService: DailyLogService

    @State private var showingAddFoodOptions = false
    @State private var showingAddFoodView = false
    @State private var showingSearchView = false
    @State private var showingBarcodeScanner = false
    @State private var showingImagePicker = false
    @State private var scannedFoodName: String?
    @State private var foodPrediction: String = ""
    @State private var selectedFoodItem: FoodItem?
    @State private var navigateToProfile = false
    @State private var navigateToSettings = false

    private let mlModel = MLImageModel()

    private var currentDateString: String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        let day = Calendar.current.component(.day, from: date)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        formatter.dateFormat = "MMMM d'\(suffix)', yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if let currentDailyLog = dailyLogService.currentDailyLog {
                        NutritionProgressView(dailyLog: currentDailyLog, goal: goalSettings)
                    } else {
                        Text("No data available for the graph.")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }

                    foodItemsList()

                    if !foodPrediction.isEmpty {
                        Text(foodPrediction)
                            .font(.headline)
                            .padding()
                    }
                }
                .navigationTitle(currentDateString)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: { navigateToProfile = true }) {
                                Label("Profile", systemImage: "person")
                            }
                            Button(action: { navigateToSettings = true }) {
                                Label("Settings", systemImage: "gearshape")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .background(
                    NavigationLink(
                        destination: UserProfileView(),
                        isActive: $navigateToProfile
                    ) {
                        EmptyView()
                    }
                    .hidden()
                )
                .background(
                    NavigationLink(
                        destination: SettingsView(),
                        isActive: $navigateToSettings
                    ) {
                        EmptyView()
                    }
                    .hidden()
                )
                .onAppear {
                    if !goalSettings.isUpdatingGoal {
                        loadInitialData()
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddFoodOptions.toggle() }) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white)
                                .background(Color.green)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }

                if showingAddFoodOptions {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture { showingAddFoodOptions = false }

                    VStack(spacing: 16) {
                        Button(action: {
                            showingSearchView = true
                            scannedFoodName = nil
                        }) {
                            ActionButtonLabel(title: "Search Food", icon: "magnifyingglass")
                        }
                        Button(action: { showingBarcodeScanner = true }) {
                            ActionButtonLabel(title: "Scan Barcode", icon: "barcode.viewfinder")
                        }
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            ActionButtonLabel(title: "Scan Food Image", icon: "camera")
                        }
                        Button(action: { showingAddFoodView = true }) {
                            ActionButtonLabel(title: "Add Food Manually", icon: "plus.circle")
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                }
            }
            .sheet(isPresented: $showingAddFoodView, onDismiss: {
                showingAddFoodOptions = false
            }) {
                AddFoodView { newFood in
                    if let userID = Auth.auth().currentUser?.uid {
                        dailyLogService.addFoodToCurrentLog(for: userID, foodItem: newFood)
                    }
                }
            }
            .sheet(isPresented: $showingSearchView, onDismiss: {
                showingAddFoodOptions = false
                scannedFoodName = nil
            }) {
                if let currentLog = dailyLogService.currentDailyLog {
                    FoodSearchView(
                        dailyLog: .constant(currentLog),
                        onLogUpdated: { updatedLog in
                            dailyLogService.currentDailyLog = updatedLog
                        },
                        initialSearchQuery: scannedFoodName ?? ""
                    )
                } else {
                    Text("Loading...")
                }
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView { foodItem in
                    DispatchQueue.main.async {
                        print("✅ Scanned Food: \(foodItem.name)")
                        scannedFoodName = foodItem.name
                        showingBarcodeScanner = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingSearchView = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: .camera) { image in
                    DispatchQueue.main.async {
                        mlModel.classifyImage(image: image) { result in
                            switch result {
                            case .success(let foodName):
                                self.foodPrediction = "Predicted: \(foodName)"
                                self.scannedFoodName = foodName
                                self.showingImagePicker = false
                                self.showingSearchView = true // Navigate to search with the prediction
                            case .failure(let error):
                                self.foodPrediction = "No food recognized: \(error.localizedDescription)"
                                self.showingImagePicker = false
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func foodItemsList() -> some View {
        List {
            ForEach(dailyLogService.currentDailyLog?.meals.flatMap { $0.foodItems } ?? []) { foodItem in
                NavigationLink(
                    destination: FoodDetailView(
                        foodItem: foodItem,
                        dailyLog: $dailyLogService.currentDailyLog,
                        onLogUpdated: { updatedLog in
                            dailyLogService.currentDailyLog = updatedLog
                        }
                    ),
                    tag: foodItem,
                    selection: $selectedFoodItem
                ) {
                    HStack {
                        Text(foodItem.name)
                        Spacer()
                        Text("\(Int(foodItem.calories)) kcal")
                    }
                }
            }
            .onDelete(perform: deleteFood)
        }
        .listStyle(InsetGroupedListStyle())
    }

    private func loadInitialData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        goalSettings.loadUserGoals(userID: userID)
        dailyLogService.fetchOrCreateTodayLog(for: userID) { result in
            switch result {
            case .success(let log):
                DispatchQueue.main.async {
                    dailyLogService.currentDailyLog = log
                }
            case .failure(let error):
                print("Error fetching logs: \(error.localizedDescription)")
            }
        }
    }

    private func deleteFood(at offsets: IndexSet) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let foodItems = dailyLogService.currentDailyLog?.meals.flatMap { $0.foodItems } ?? []

        offsets.forEach { index in
            let foodItem = foodItems[index]
            dailyLogService.deleteFoodFromCurrentLog(for: userID, foodItemID: foodItem.id)
        }
    }
}

struct ActionButtonLabel: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            Text(title)
                .foregroundColor(.black)
                .font(.headline)
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}
