import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    @EnvironmentObject var goalSettings: GoalSettings
    @EnvironmentObject var dailyLogService: DailyLogService

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            AIChatbotView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("AI Recipe Bot")
                }

            WeightTrackingView()
                .tabItem {
                    Image(systemName: "scalemass.fill")
                    Text("Weight Tracker")
                }
        }
    }
}

