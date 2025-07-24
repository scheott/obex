// MARK: - Package Dependencies
// Add to your Package.swift or through Xcode Package Manager:
// https://github.com/supabase/supabase-swift

import Foundation
import Supabase
import SwiftUI

// MARK: - Supabase Configuration
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    // Replace with your Supabase project URL and anon key
    private let supabaseURL = URL(string: "")!
    private let supabaseKey = ""
    
    let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
        
        // Check for existing session
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Authentication
    @MainActor
    func checkAuthStatus() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    @MainActor
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        if let user = response.user {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        currentUser = response.user
        isAuthenticated = true
    }
    
    @MainActor
    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
}

// MARK: - Database Models (for Supabase tables)

// User Profiles table structure
struct DatabaseUserProfile: Codable {
    let id: UUID
    let user_id: UUID // References auth.users
    let selected_path: String
    let join_date: Date
    let current_streak: Int
    let longest_streak: Int
    let total_challenges_completed: Int
    let subscription_tier: String
    let streak_bank_days: Int
    let created_at: Date
    let updated_at: Date
}

// Daily Challenges table
struct DatabaseDailyChallenge: Codable {
    let id: UUID
    let user_id: UUID
    let title: String
    let description: String
    let path: String
    let difficulty: String
    let date: Date
    let is_completed: Bool
    let completed_at: Date?
    let created_at: Date
}

// Check-ins table
struct DatabaseCheckIn: Codable {
    let id: UUID
    let user_id: UUID
    let date: Date
    let time_of_day: String
    let prompt: String
    let user_response: String?
    let ai_response: String?
    let mood: String?
    let effort_level: Int?
    let created_at: Date
}

// Journal Entries table
struct DatabaseJournalEntry: Codable {
    let id: UUID
    let user_id: UUID
    let date: Date
    let content: String
    let prompt: String?
    let mood: String?
    let tags: [String]
    let is_saved_to_self: Bool
    let is_marked_for_reread: Bool
    let created_at: Date
}

// Book Recommendations table
struct DatabaseBookRecommendation: Codable {
    let id: UUID
    let title: String
    let author: String
    let path: String
    let summary: String
    let key_insight: String
    let daily_action: String
    let cover_image_url: String?
    let amazon_url: String?
    let is_active: Bool
    let created_at: Date
}

// User Book Interactions table
struct DatabaseUserBookInteraction: Codable {
    let id: UUID
    let user_id: UUID
    let book_id: UUID
    let is_saved: Bool
    let is_read: Bool
    let created_at: Date
    let updated_at: Date
}

// MARK: - Enhanced Data Manager with Supabase
class SupabaseDataManager: ObservableObject {
    private let supabase = SupabaseManager.shared
    
    @Published var userProfile: UserProfile?
    @Published var todaysChallenge: DailyChallenge?
    @Published var todaysCheckIns: [AICheckIn] = []
    @Published var currentBookRecommendations: [BookRecommendation] = []
    @Published var journalEntries: [JournalEntry] = []
    @Published var weeklySummaries: [WeeklySummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Listen for auth changes
        Task {
            await loadUserData()
        }
    }
    
    // MARK: - User Profile Management
    @MainActor
    func createUserProfile(selectedPath: TrainingPath) async {
        guard let userId = supabase.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let profile = DatabaseUserProfile(
                id: UUID(),
                user_id: userId,
                selected_path: selectedPath.rawValue,
                join_date: Date(),
                current_streak: 0,
                longest_streak: 0,
                total_challenges_completed: 0,
                subscription_tier: SubscriptionTier.free.rawValue,
                streak_bank_days: 0,
                created_at: Date(),
                updated_at: Date()
            )
            
            try await supabase.client
                .from("user_profiles")
                .insert(profile)
                .execute()
            
            // Convert to local model
            userProfile = UserProfile(selectedPath: selectedPath)
            await generateTodaysContent()
            
        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func loadUserData() async {
        guard let userId = supabase.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load user profile
            let profileResponse: [DatabaseUserProfile] = try await supabase.client
                .from("user_profiles")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let dbProfile = profileResponse.first {
                userProfile = UserProfile(
                    selectedPath: TrainingPath(rawValue: dbProfile.selected_path) ?? .discipline
                )
                userProfile?.currentStreak = dbProfile.current_streak
                userProfile?.longestStreak = dbProfile.longest_streak
                userProfile?.totalChallengesCompleted = dbProfile.total_challenges_completed
                userProfile?.subscriptionTier = SubscriptionTier(rawValue: dbProfile.subscription_tier) ?? .free
                userProfile?.streakBankDays = dbProfile.streak_bank_days
            }
            
            // Load today's challenge
            await loadTodaysChallenge()
            
            // Load recent journal entries
            await loadJournalEntries()
            
            // Load book recommendations
            await loadBookRecommendations()
            
            // Generate today's check-ins
            await generateTodaysCheckIns()
            
        } catch {
            errorMessage = "Failed to load user data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Challenge Management
    @MainActor
    func loadTodaysChallenge() async {
        guard let userId = supabase.currentUser?.id else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        do {
            let challengeResponse: [DatabaseDailyChallenge] = try await supabase.client
                .from("daily_challenges")
                .select()
                .eq("user_id", value: userId)
                .gte("date", value: today)
                .order("date", ascending: false)
                .limit(1)
                .execute()
                .value
            
            if let dbChallenge = challengeResponse.first {
                todaysChallenge = DailyChallenge(
                    title: dbChallenge.title,
                    description: dbChallenge.description,
                    path: TrainingPath(rawValue: dbChallenge.path) ?? .discipline,
                    difficulty: DailyChallenge.ChallengeDifficulty(rawValue: dbChallenge.difficulty) ?? .micro,
                    date: dbChallenge.date,
                    isCompleted: dbChallenge.is_completed,
                    completedAt: dbChallenge.completed_at
                )
            } else {
                // Generate new challenge if none exists
                await generateTodaysChallenge()
            }
        } catch {
            errorMessage = "Failed to load today's challenge: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func completeChallenge() async {
        guard let userId = supabase.currentUser?.id,
              var challenge = todaysChallenge else { return }
        
        do {
            // Update challenge in database
            try await supabase.client
                .from("daily_challenges")
                .update([
                    "is_completed": true,
                    "completed_at": Date()
                ])
                .eq("user_id", value: userId)
                .eq("date", value: Calendar.current.startOfDay(for: Date()))
                .execute()
            
            // Update local state
            challenge.isCompleted = true
            challenge.completedAt = Date()
            todaysChallenge = challenge
            
            // Update user profile streak
            if let userProfile = userProfile {
                let newStreak = userProfile.currentStreak + 1
                let newLongestStreak = max(newStreak, userProfile.longestStreak)
                let newTotalCompleted = userProfile.totalChallengesCompleted + 1
                
                try await supabase.client
                    .from("user_profiles")
                    .update([
                        "current_streak": newStreak,
                        "longest_streak": newLongestStreak,
                        "total_challenges_completed": newTotalCompleted,
                        "updated_at": Date()
                    ])
                    .eq("user_id", value: userId)
                    .execute()
                
                // Update local profile
                self.userProfile?.currentStreak = newStreak
                self.userProfile?.longestStreak = newLongestStreak
                self.userProfile?.totalChallengesCompleted = newTotalCompleted
            }
            
        } catch {
            errorMessage = "Failed to complete challenge: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Journal Management
    @MainActor
    func addJournalEntry(_ entry: JournalEntry) async {
        guard let userId = supabase.currentUser?.id else { return }
        
        do {
            let dbEntry = DatabaseJournalEntry(
                id: entry.id,
                user_id: userId,
                date: entry.date,
                content: entry.content,
                prompt: entry.prompt,
                mood: entry.mood?.rawValue,
                tags: entry.tags,
                is_saved_to_self: entry.isSavedToSelf,
                is_marked_for_reread: entry.isMarkedForReread,
                created_at: Date()
            )
            
            try await supabase.client
                .from("journal_entries")
                .insert(dbEntry)
                .execute()
            
            journalEntries.append(entry)
            
        } catch {
            errorMessage = "Failed to save journal entry: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func loadJournalEntries() async {
        guard let userId = supabase.currentUser?.id else { return }
        
        do {
            let entriesResponse: [DatabaseJournalEntry] = try await supabase.client
                .from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .order("date", ascending: false)
                .limit(50)
                .execute()
                .value
            
            journalEntries = entriesResponse.map { dbEntry in
                JournalEntry(
                    date: dbEntry.date,
                    content: dbEntry.content,
                    prompt: dbEntry.prompt,
                    mood: dbEntry.mood != nil ? AICheckIn.MoodRating(rawValue: dbEntry.mood!) : nil
                )
            }
            
        } catch {
            errorMessage = "Failed to load journal entries: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Book Recommendations
    @MainActor
    func loadBookRecommendations() async {
        guard let userProfile = userProfile else { return }
        
        do {
            let booksResponse: [DatabaseBookRecommendation] = try await supabase.client
                .from("book_recommendations")
                .select()
                .eq("path", value: userProfile.selectedPath.rawValue)
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .limit(10)
                .execute()
                .value
            
            currentBookRecommendations = booksResponse.map { dbBook in
                BookRecommendation(
                    title: dbBook.title,
                    author: dbBook.author,
                    path: TrainingPath(rawValue: dbBook.path) ?? .discipline,
                    summary: dbBook.summary,
                    keyInsight: dbBook.key_insight,
                    dailyAction: dbBook.daily_action,
                    coverImageURL: dbBook.cover_image_url,
                    amazonURL: dbBook.amazon_url,
                    dateAdded: dbBook.created_at
                )
            }
            
        } catch {
            errorMessage = "Failed to load book recommendations: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Helper Methods
    @MainActor
    private func generateTodaysChallenge() async {
        guard let userProfile = userProfile,
              let userId = supabase.currentUser?.id else { return }
        
        let challenge = ChallengeGenerator.generateChallenge(
            for: userProfile.selectedPath,
            difficulty: .micro
        )
        
        do {
            let dbChallenge = DatabaseDailyChallenge(
                id: challenge.id,
                user_id: userId,
                title: challenge.title,
                description: challenge.description,
                path: challenge.path.rawValue,
                difficulty: challenge.difficulty.rawValue,
                date: challenge.date,
                is_completed: false,
                completed_at: nil,
                created_at: Date()
            )
            
            try await supabase.client
                .from("daily_challenges")
                .insert(dbChallenge)
                .execute()
            
            todaysChallenge = challenge
            
        } catch {
            errorMessage = "Failed to generate today's challenge: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func generateTodaysCheckIns() async {
        guard let userProfile = userProfile else { return }
        
        let morningPrompt = CheckInGenerator.generateMorningPrompt(for: userProfile.selectedPath)
        let eveningPrompt = CheckInGenerator.generateEveningPrompt(for: userProfile.selectedPath)
        
        todaysCheckIns = [
            AICheckIn(date: Date(), timeOfDay: .morning, prompt: morningPrompt),
            AICheckIn(date: Date(), timeOfDay: .evening, prompt: eveningPrompt)
        ]
    }
    
    @MainActor
    private func generateTodaysContent() async {
        await generateTodaysChallenge()
        await loadBookRecommendations()
        await generateTodaysCheckIns()
    }
}

// MARK: - Updated Main App with Supabase
@main
struct MentorApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var dataManager = SupabaseDataManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if supabaseManager.isAuthenticated {
                    if dataManager.userProfile == nil {
                        OnboardingView()
                    } else {
                        MainTabView(selectedTab: .constant(0))
                    }
                } else {
                    AuthenticationView()
                }
            }
            .environmentObject(supabaseManager)
            .environmentObject(dataManager)
            .alert("Error", isPresented: .constant(dataManager.errorMessage != nil)) {
                Button("OK") {
                    dataManager.errorMessage = nil
                }
            } message: {
                Text(dataManager.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Authentication View
struct AuthenticationView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App branding
                VStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("MentorApp")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Build discipline, clarity, confidence, and purpose")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
                
                // Auth form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: authenticate) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isSignUp ? "Sign Up" : "Sign In")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    
                    Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                        isSignUp.toggle()
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private func authenticate() {
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await supabaseManager.signUp(email: email, password: password)
                } else {
                    try await supabaseManager.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}