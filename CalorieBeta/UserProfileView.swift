import SwiftUI
import FirebaseAuth

struct UserProfileView: View {
    @EnvironmentObject var dailyLogService: DailyLogService
    @EnvironmentObject var goalSettings: GoalSettings
    @Environment(\.presentationMode) var presentationMode // Added for dismissal
    @State private var posts: [Post] = []
    @State private var achievements: [Achievement] = []
    @State private var dailyHistory: [DailyLog] = []
    @State private var errorMessage: ErrorMessage?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader()

                dailyStats()

                achievementsSection()

                postsSection()

                dailyHistorySection()
            }
            .padding()
        }
        .onAppear {
            loadUserData()
        }
        .alert(item: $errorMessage) { message in
            Alert(title: Text("Error"), message: Text(message.text), dismissButton: .default(Text("OK")))
        }
        .navigationTitle("Profile")
        .navigationBarBackButtonHidden(true) // Hide the default back button
        .navigationBarItems(leading: // Custom back button
            Button(action: {
                // Pop back to HomeView using SwiftUI presentation mode
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                Text("Home")
            }
            .foregroundColor(.blue)
        )
    }

    // MARK: - Profile Header
    func profileHeader() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
            Text("Fitness Journey")
                .font(.title2)
                .fontWeight(.bold)
            Text("@MFP") // Replace with dynamic username if available
                .foregroundColor(.gray)
        }
    }

    // MARK: - Daily Stats
    func dailyStats() -> some View {
        HStack(spacing: 16) {
            statBox(title: calorieGoalText(), subtitle: "Calorie Goal")
            Divider()
            statBox(title: calculateBMI(), subtitle: "BMI")
        }
    }

    func calorieGoalText() -> String {
        if let calories = goalSettings.calories {
            return "\(Int(calories))"
        } else {
            return "Loading..."
        }
    }

    func calculateBMI() -> String {
        let weightInKg = goalSettings.weight * 0.453592 // Convert lbs to kg
        let heightInMeters = goalSettings.height / 100 // Convert cm to meters
        guard heightInMeters > 0 else { return "N/A" }
        let bmi = weightInKg / (heightInMeters * heightInMeters)
        return String(format: "%.1f", bmi)
    }

    func statBox(title: String, subtitle: String) -> some View {
        VStack {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            Text(subtitle)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Achievements Section
    func achievementsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Achievements")
                .font(.headline)
            if achievements.isEmpty {
                Text("No achievements yet.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            } else {
                ForEach(achievements) { achievement in
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(achievement.title)
                    }
                }
            }
        }
    }

    // MARK: - Posts Section
    func postsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Posts")
                .font(.headline)
            if posts.isEmpty {
                Text("You haven’t posted anything yet.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            } else {
                ForEach(posts) { post in
                    postView(post)
                }
            }
        }
    }

    func postView(_ post: Post) -> some View {
        VStack(alignment: .leading) {
            Text(post.content)
                .font(.body)
            Text(post.timestamp, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Daily History Section
    func dailyHistorySection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily History")
                .font(.headline)

            if dailyHistory.isEmpty {
                Text("No daily logs available.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            } else {
                ForEach(groupedDailyHistory(), id: \.date) { groupedLog in
                    VStack(alignment: .leading) {
                        Text(groupedLog.date, style: .date)
                            .font(.headline)
                        ForEach(groupedLog.logs) { log in
                            ForEach(log.meals) { meal in
                                mealView(meal)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }

    func mealView(_ meal: Meal) -> some View {
        VStack(alignment: .leading) {
            Text(meal.name)
                .font(.subheadline)
                .fontWeight(.bold)
            ForEach(meal.foodItems) { item in
                HStack {
                    Text(item.name)
                    Spacer()
                    Text("\(Int(item.calories)) kcal")
                        .foregroundColor(.gray)
                }
                .font(.footnote)
            }
        }
        .padding(.top, 4)
    }

    func groupedDailyHistory() -> [GroupedDailyLog] {
        Dictionary(grouping: dailyHistory, by: { Calendar.current.startOfDay(for: $0.date) })
            .map { GroupedDailyLog(date: $0.key, logs: $0.value) }
            .sorted(by: { $0.date > $1.date })
    }

    // MARK: - Load User Data
    func loadUserData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = ErrorMessage("User not authenticated.")
            return
        }

        // Fetch posts
        dailyLogService.fetchPosts(for: userID) { result in
            handleFetchResult(result: result, setState: { self.posts = $0 })
        }

        // Fetch achievements
        dailyLogService.fetchAchievements(for: userID) { result in
            handleFetchResult(result: result, setState: { self.achievements = $0 })
        }

        // Fetch daily history
        dailyLogService.fetchDailyHistory(for: userID) { result in
            handleFetchResult(result: result, setState: { self.dailyHistory = $0 })
        }
    }

    func handleFetchResult<T>(result: Result<[T], Error>, setState: @escaping ([T]) -> Void) {
        DispatchQueue.main.async {
            switch result {
            case .success(let data):
                setState(data)
            case .failure(let error):
                self.errorMessage = ErrorMessage("Error loading data: \(error.localizedDescription)")
            }
        }
    }
}

// ErrorMessage Wrapper for Identifiable Compliance
struct ErrorMessage: Identifiable {
    let id = UUID()
    let text: String

    init(_ text: String) {
        self.text = text
    }
}

// GroupedDailyLog for grouping logs by date
struct GroupedDailyLog: Identifiable {
    let id = UUID()
    let date: Date
    let logs: [DailyLog]
}
