import SwiftUI

// MARK: - Main App
@main
struct MentorApp: App {
    let persistenceController = CoreDataStack.shared
    @StateObject private var dataManager = EnhancedDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
                .environmentObject(dataManager)
        }
    }
}
// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if dataManager.userProfile == nil {
                OnboardingView()
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            ChallengeView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Challenge")
                }
                .tag(1)
            
            BookStationView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Books")
                }
                .tag(2)
            
            CheckInView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Check-in")
                }
                .tag(3)
            
            JournalView()
                .tabItem {
                    Image(systemName: "book.closed.fill")
                    Text("Journal")
                }
                .tag(4)
        }
        .accentColor(dataManager.userProfile?.selectedPath.color ?? .blue)
    }
}

// MARK: - Data Manager (ObservableObject for state management)
class DataManager: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var todaysChallenge: DailyChallenge?
    @Published var todaysCheckIns: [AICheckIn] = []
    @Published var currentBookRecommendations: [BookRecommendation] = []
    @Published var journalEntries: [JournalEntry] = []
    @Published var weeklySummaries: [WeeklySummary] = []
    
    init() {
        loadUserData()
        generateTodaysContent()
    }
    
    // MARK: - User Profile Management
    func createUserProfile(selectedPath: TrainingPath) {
        userProfile = UserProfile(selectedPath: selectedPath)
        saveUserData()
        generateTodaysContent()
    }
    
    func updateUserPath(_ path: TrainingPath) {
        userProfile?.selectedPath = path
        saveUserData()
        generateTodaysContent()
    }
    
    // MARK: - Challenge Management
    func completeChallenge() {
        guard var challenge = todaysChallenge else { return }
        challenge.isCompleted = true
        challenge.completedAt = Date()
        todaysChallenge = challenge
        
        // Update streak
        userProfile?.currentStreak += 1
        if let currentStreak = userProfile?.currentStreak,
           let longestStreak = userProfile?.longestStreak {
            if currentStreak > longestStreak {
                userProfile?.longestStreak = currentStreak
            }
        }
        userProfile?.totalChallengesCompleted += 1
        
        saveUserData()
    }
    
    // MARK: - Check-in Management
    func submitCheckIn(_ checkIn: AICheckIn) {
        todaysCheckIns.append(checkIn)
        saveUserData()
    }
    
    // MARK: - Journal Management
    func addJournalEntry(_ entry: JournalEntry) {
        journalEntries.append(entry)
        saveUserData()
    }
    
    // MARK: - Data Persistence
    private func loadUserData() {
        // UserDefaults implementation for MVP
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
        }
        
        if let data = UserDefaults.standard.data(forKey: "journalEntries"),
           let entries = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            journalEntries = entries
        }
    }
    
    private func saveUserData() {
        if let userProfile = userProfile,
           let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
        
        if let data = try? JSONEncoder().encode(journalEntries) {
            UserDefaults.standard.set(data, forKey: "journalEntries")
        }
    }
    
    // MARK: - Content Generation
    private func generateTodaysContent() {
        guard let userProfile = userProfile else { return }
        generateTodaysChallenge(for: userProfile.selectedPath)
        generateBookRecommendations(for: userProfile.selectedPath)
        generateTodaysCheckIns(for: userProfile.selectedPath)
    }
    
    private func generateTodaysChallenge(for path: TrainingPath) {
        let challenges = ChallengeGenerator.generateChallenge(for: path, difficulty: .micro)
        todaysChallenge = challenges
    }
    
    private func generateBookRecommendations(for path: TrainingPath) {
        currentBookRecommendations = BookGenerator.generateRecommendations(for: path)
    }
    
    private func generateTodaysCheckIns(for path: TrainingPath) {
        let morningPrompt = CheckInGenerator.generateMorningPrompt(for: path)
        let eveningPrompt = CheckInGenerator.generateEveningPrompt(for: path)
        
        todaysCheckIns = [
            AICheckIn(date: Date(), timeOfDay: .morning, prompt: morningPrompt),
            AICheckIn(date: Date(), timeOfDay: .evening, prompt: eveningPrompt)
        ]
    }
}

// MARK: - Placeholder Views (we'll build these next)
struct DashboardView: View {
    var body: some View {
        NavigationView {
            Text("Dashboard - Coming Next!")
                .navigationTitle("Dashboard")
        }
    }
}

struct ChallengeView: View {
    var body: some View {
        NavigationView {
            Text("Challenge - Coming Soon!")
                .navigationTitle("Today's Challenge")
        }
    }
}

struct BookStationView: View {
    var body: some View {
        NavigationView {
            Text("Book Station - Coming Soon!")
                .navigationTitle("Book Station")
        }
    }
}

struct CheckInView: View {
    var body: some View {
        NavigationView {
            Text("Check-in - Coming Soon!")
                .navigationTitle("Daily Check-in")
        }
    }
}

struct JournalView: View {
    var body: some View {
        NavigationView {
            Text("Journal - Coming Soon!")
                .navigationTitle("Reflection Journal")
        }
    }
}

struct OnboardingView: View {
    var body: some View {
        Text("Onboarding - Coming Soon!")
    }
}
