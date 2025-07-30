import Foundation
import Supabase
import SwiftUI
import Combine

// MARK: - SupabaseManager (Backend integration)
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    // Replace with your Supabase project URL and anon key
    private let supabaseURL = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://your-project.supabase.co")!
    private let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "your-anon-key"
    
    let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var connectionStatus: ConnectionStatus = .unknown
    
    private var cancellables = Set<AnyCancellable>()
    private let syncQueue = DispatchQueue(label: "supabase.sync", qos: .utility)
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
        
        setupRealtimeSubscriptions()
        checkInitialAuthStatus()
        startConnectionMonitoring()
    }
    
    // MARK: - Authentication
    
    @MainActor
    func checkAuthStatus() async {
        syncStatus = .syncing
        
        do {
            let session = try await client.auth.session
            if let user = session.user {
                currentUser = await convertSupabaseUserToAppUser(user)
                isAuthenticated = true
                syncStatus = .synced
            } else {
                currentUser = nil
                isAuthenticated = false
                syncStatus = .idle
            }
        } catch {
            print("Auth check error: \(error)")
            isAuthenticated = false
            currentUser = nil
            syncStatus = .error("Authentication failed")
        }
    }
    
    @MainActor
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        syncStatus = .syncing
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            if let user = response.user {
                // Create user profile in database
                let userProfile = DatabaseUserProfile(
                    id: UUID(),
                    user_id: UUID(uuidString: user.id) ?? UUID(),
                    selected_path: "discipline",
                    join_date: Date(),
                    current_streak: 0,
                    longest_streak: 0,
                    total_challenges_completed: 0,
                    subscription_tier: "free",
                    streak_bank_days: 0,
                    first_name: firstName,
                    last_name: lastName,
                    email_verified: false,
                    created_at: Date(),
                    updated_at: Date()
                )
                
                try await insertUserProfile(userProfile)
                
                currentUser = await convertSupabaseUserToAppUser(user, firstName: firstName, lastName: lastName)
                isAuthenticated = true
                syncStatus = .synced
            }
        } catch {
            syncStatus = .error("Sign up failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        syncStatus = .syncing
        
        do {
            let response = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            currentUser = await convertSupabaseUserToAppUser(response.user)
            isAuthenticated = true
            syncStatus = .synced
            
        } catch {
            syncStatus = .error("Sign in failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func signOut() async throws {
        syncStatus = .syncing
        
        do {
            try await client.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            syncStatus = .idle
        } catch {
            syncStatus = .error("Sign out failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - User Profile Operations
    
    func getUserProfile(userId: UUID) async throws -> DatabaseUserProfile {
        let response: [DatabaseUserProfile] = try await client.database
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        guard let profile = response.first else {
            throw SupabaseError.userProfileNotFound
        }
        
        return profile
    }
    
    func insertUserProfile(_ profile: DatabaseUserProfile) async throws {
        try await client.database
            .from("user_profiles")
            .insert(profile)
            .execute()
    }
    
    func updateUserProfile(_ profile: DatabaseUserProfile) async throws {
        try await client.database
            .from("user_profiles")
            .update(profile)
            .eq("user_id", value: profile.user_id.uuidString)
            .execute()
        
        await updateSyncStatus(.synced)
    }
    
    // MARK: - Daily Challenge Operations
    
    func getDailyChallenges(userId: UUID, date: Date) async throws -> [DatabaseDailyChallenge] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let response: [DatabaseDailyChallenge] = try await client.database
            .from("daily_challenges")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: startOfDay.iso8601)
            .lt("date", value: endOfDay.iso8601)
            .execute()
            .value
        
        return response
    }
    
    func insertDailyChallenge(_ challenge: DatabaseDailyChallenge) async throws {
        try await client.database
            .from("daily_challenges")
            .insert(challenge)
            .execute()
        
        await updateSyncStatus(.synced)
    }
    
    func updateDailyChallenge(_ challenge: DatabaseDailyChallenge) async throws {
        try await client.database
            .from("daily_challenges")
            .update(challenge)
            .eq("id", value: challenge.id.uuidString)
            .execute()
        
        await updateSyncStatus(.synced)
    }
    
    // MARK: - Check-in Operations
    
    func getCheckIns(userId: UUID, startDate: Date, endDate: Date) async throws -> [DatabaseCheckIn] {
        let response: [DatabaseCheckIn] = try await client.database
            .from("check_ins")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: startDate.iso8601)
            .lte("date", value: endDate.iso8601)
            .order("date", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func insertCheckIn(_ checkIn: DatabaseCheckIn) async throws {
        try await client.database
            .from("check_ins")
            .insert(checkIn)
            .execute()
        
        await updateSyncStatus(.synced)
    }
    
    // MARK: - Journal Entry Operations
    
    func getJournalEntries(userId: UUID, limit: Int = 50) async throws -> [DatabaseJournalEntry] {
        let response: [DatabaseJournalEntry] = try await client.database
            .from("journal_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return response
    }
    
    func insertJournalEntry(_ entry: DatabaseJournalEntry) async throws {
        try await client.database
            .from("journal_entries")
            .insert(entry)
            .execute()
        
        await updateSyncStatus(.synced)
    }
    
    func updateJournalEntry(_ entry: DatabaseJournalEntry) async throws {
        try await client.database
            .from("journal_entries")
            .update(entry)
            .eq("id", value: entry.id.uuidString)
            .execute()
        
        await updateSyncStatus(.synced)
    }
    
    func deleteJournalEntry(id: UUID) async throws {
        try await client.database
            .from("journal_entries")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        
        await updateSyncStatus(.synced)
    }
    
    // MARK: - Book Recommendation Operations
    
    func getBookRecommendations(path: String? = nil, limit: Int = 20) async throws -> [DatabaseBookRecommendation] {
        var query = client.database
            .from("book_recommendations")
            .select()
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .limit(limit)
        
        if let path = path {
            query = query.eq("path", value: path)
        }
        
        let response: [DatabaseBookRecommendation] = try await query.execute().value
        return response
    }
    
    func getUserBookInteractions(userId: UUID) async throws -> [DatabaseUserBookInteraction] {
        let response: [DatabaseUserBookInteraction] = try await client.database
            .from("user_book_interactions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return response
    }
    
    func saveBookInteraction(_ interaction: DatabaseUserBookInteraction) async throws {
        // Upsert book interaction
        try await client.database
            .from("user_book_interactions")
            .upsert(interaction)
            .execute()
        
        await updateSyncStatus(.synced)
    }
    
    // MARK: - Real-time Subscriptions
    
    private func setupRealtimeSubscriptions() {
        guard let userId = currentUser?.id else { return }
        
        // Subscribe to user profile changes
        let profileChannel = client.channel("user_profile_changes")
        
        profileChannel.onPostgresChanges(
            event: .update,
            schema: "public",
            table: "user_profiles",
            filter: "user_id=eq.\(userId)"
        ) { [weak self] payload in
            Task { @MainActor in
                self?.handleUserProfileUpdate(payload)
            }
        }
        
        profileChannel.subscribe()
    }
    
    @MainActor
    private func handleUserProfileUpdate(_ payload: PostgresChangePayload) {
        syncStatus = .syncing
        // Handle real-time profile updates
        Task {
            await updateSyncStatus(.synced)
        }
    }
    
    // MARK: - Sync Management
    
    func performFullSync() async {
        await updateSyncStatus(.syncing)
        
        guard let userId = UUID(uuidString: currentUser?.id ?? "") else {
            await updateSyncStatus(.error("Invalid user ID"))
            return
        }
        
        do {
            // Sync user profile
            let profile = try await getUserProfile(userId: userId)
            
            // Sync recent data
            let challenges = try await getDailyChallenges(userId: userId, date: Date())
            let checkIns = try await getCheckIns(
                userId: userId,
                startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                endDate: Date()
            )
            let journalEntries = try await getJournalEntries(userId: userId, limit: 50)
            let bookInteractions = try await getUserBookInteractions(userId: userId)
            
            await updateSyncStatus(.synced)
            
        } catch {
            await updateSyncStatus(.error("Sync failed: \(error.localizedDescription)"))
        }
    }
    
    @MainActor
    private func updateSyncStatus(_ status: SyncStatus) {
        syncStatus = status
    }
    
    // MARK: - Connection Monitoring
    
    private func startConnectionMonitoring() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkConnection()
            }
            .store(in: &cancellables)
    }
    
    private func checkConnection() {
        Task {
            do {
                // Simple health check
                let _: [String: Any] = try await client.database
                    .from("user_profiles")
                    .select("id")
                    .limit(1)
                    .execute()
                    .value
                
                await MainActor.run {
                    connectionStatus = .connected
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .disconnected
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkInitialAuthStatus() {
        Task {
            await checkAuthStatus()
        }
    }
    
    private func convertSupabaseUserToAppUser(_ supabaseUser: AuthChangeEvent.Session.User, firstName: String? = nil, lastName: String? = nil) async -> User {
        // Try to get user profile from database
        var userFirstName = firstName ?? "User"
        var userLastName = lastName ?? ""
        
        if let userId = UUID(uuidString: supabaseUser.id) {
            do {
                let profile = try await getUserProfile(userId: userId)
                userFirstName = profile.first_name
                userLastName = profile.last_name
            } catch {
                print("Could not fetch user profile: \(error)")
            }
        }
        
        return User(
            id: supabaseUser.id,
            email: supabaseUser.email ?? "",
            firstName: userFirstName,
            lastName: userLastName,
            dateJoined: supabaseUser.createdAt,
            subscription: .free, // This would be determined from profile
            authProvider: .email,
            emailVerified: supabaseUser.emailConfirmedAt != nil,
            preferences: User.UserPreferences()
        )
    }
}

// MARK: - DatabaseUserProfile (Cloud user model)
struct DatabaseUserProfile: Codable {
    let id: UUID
    let user_id: UUID
    let selected_path: String
    let join_date: Date
    var current_streak: Int
    var longest_streak: Int
    var total_challenges_completed: Int
    let subscription_tier: String
    var streak_bank_days: Int
    let first_name: String
    let last_name: String
    var email_verified: Bool
    var profile_image_url: String?
    var bio: String?
    var phone_number: String?
    var timezone: String?
    var locale: String?
    var notification_settings: NotificationSettingsData?
    var privacy_settings: PrivacySettingsData?
    let created_at: Date
    var updated_at: Date
    
    init(id: UUID, user_id: UUID, selected_path: String, join_date: Date, current_streak: Int, longest_streak: Int, total_challenges_completed: Int, subscription_tier: String, streak_bank_days: Int, first_name: String, last_name: String, email_verified: Bool, created_at: Date = Date(), updated_at: Date = Date()) {
        self.id = id
        self.user_id = user_id
        self.selected_path = selected_path
        self.join_date = join_date
        self.current_streak = current_streak
        self.longest_streak = longest_streak
        self.total_challenges_completed = total_challenges_completed
        self.subscription_tier = subscription_tier
        self.streak_bank_days = streak_bank_days
        self.first_name = first_name
        self.last_name = last_name
        self.email_verified = email_verified
        self.created_at = created_at
        self.updated_at = updated_at
    }
    
    struct NotificationSettingsData: Codable {
        var morning_checkin_enabled: Bool = true
        var evening_checkin_enabled: Bool = true
        var challenge_reminders_enabled: Bool = true
        var weekly_insights_enabled: Bool = true
        var streak_reminders_enabled: Bool = true
        var marketing_emails_enabled: Bool = false
        var push_notifications_enabled: Bool = true
    }
    
    struct PrivacySettingsData: Codable {
        var allow_data_collection: Bool = true
        var allow_personalization: Bool = true
        var share_progress_with_coach: Bool = false
        var public_profile: Bool = false
        var anonymize_exports: Bool = true
    }
    
    func toDomainModel() -> UserProfile {
        return UserProfile(
            selectedPath: TrainingPath(rawValue: selected_path) ?? .discipline,
            joinDate: join_date,
            currentStreak: current_streak,
            longestStreak: longest_streak,
            totalChallengesCompleted: total_challenges_completed,
            subscriptionTier: SubscriptionTier(rawValue: subscription_tier) ?? .free,
            streakBankDays: streak_bank_days
        )
    }
}

// MARK: - DatabaseDailyChallenge (Cloud challenge model)
struct DatabaseDailyChallenge: Codable {
    let id: UUID
    let user_id: UUID
    let title: String
    let description: String
    let path: String
    let difficulty: String
    let date: Date
    var is_completed: Bool
    var completed_at: Date?
    var effort_level: Int?
    var user_notes: String?
    var completion_time_minutes: Int?
    let estimated_time_minutes: Int
    let category: String
    let tags: [String]
    var is_skipped: Bool
    var skip_reason: String?
    let created_at: Date
    var updated_at: Date
    
    init(id: UUID = UUID(), user_id: UUID, title: String, description: String, path: String, difficulty: String, date: Date, estimated_time_minutes: Int = 15, category: String = "mindset", tags: [String] = []) {
        self.id = id
        self.user_id = user_id
        self.title = title
        self.description = description
        self.path = path
        self.difficulty = difficulty
        self.date = date
        self.is_completed = false
        self.estimated_time_minutes = estimated_time_minutes
        self.category = category
        self.tags = tags
        self.is_skipped = false
        self.created_at = Date()
        self.updated_at = Date()
    }
    
    func toDomainModel() -> DailyChallenge {
        return DailyChallenge(
            title: title,
            description: description,
            path: TrainingPath(rawValue: path) ?? .discipline,
            difficulty: ChallengeDifficulty(rawValue: difficulty) ?? .medium,
            date: date,
            estimatedTimeMinutes: estimated_time_minutes,
            category: ChallengeCategory(rawValue: category) ?? .mindset,
            tags: tags
        )
    }
    
    mutating func updateFromDomainModel(_ challenge: DailyChallenge) {
        title = challenge.title
        description = challenge.description
        path = challenge.path.rawValue
        difficulty = challenge.difficulty.rawValue
        date = challenge.date
        is_completed = challenge.isCompleted
        completed_at = challenge.completedAt
        effort_level = challenge.effortLevel
        user_notes = challenge.userNotes
        completion_time_minutes = challenge.completionTimeMinutes
        is_skipped = challenge.isSkipped
        skip_reason = challenge.skipReason
        updated_at = Date()
    }
}

// MARK: - DatabaseCheckIn (Cloud check-in model)
struct DatabaseCheckIn: Codable {
    let id: UUID
    let user_id: UUID
    let date: Date
    let time_of_day: String
    let prompt: String
    var user_response: String?
    var ai_response: String?
    var mood: String?
    var effort_level: Int?
    var duration_minutes: Int?
    let path: String
    var tags: [String]
    var is_completed: Bool
    let created_at: Date
    var updated_at: Date
    
    init(id: UUID = UUID(), user_id: UUID, date: Date, time_of_day: String, prompt: String, path: String = "discipline") {
        self.id = id
        self.user_id = user_id
        self.date = date
        self.time_of_day = time_of_day
        self.prompt = prompt
        self.path = path
        self.tags = []
        self.is_completed = false
        self.created_at = Date()
        self.updated_at = Date()
    }
    
    func toDomainModel() -> AICheckIn {
        var checkIn = AICheckIn(
            date: date,
            timeOfDay: AICheckIn.CheckInTime(rawValue: time_of_day) ?? .morning,
            prompt: prompt
        )
        checkIn.id = id
        checkIn.userResponse = user_response
        checkIn.aiResponse = ai_response
        checkIn.mood = mood.flatMap { AICheckIn.MoodRating(rawValue: $0) }
        checkIn.effortLevel = effort_level
        return checkIn
    }
    
    mutating func updateFromDomainModel(_ checkIn: AICheckIn) {
        user_response = checkIn.userResponse
        ai_response = checkIn.aiResponse
        mood = checkIn.mood?.rawValue
        effort_level = checkIn.effortLevel
        is_completed = checkIn.userResponse != nil
        updated_at = Date()
    }
}

// MARK: - DatabaseJournalEntry (Cloud journal model)
struct DatabaseJournalEntry: Codable {
    let id: UUID
    let user_id: UUID
    let date: Date
    let content: String
    var prompt: String?
    var mood: String?
    var tags: [String]
    var is_saved_to_self: Bool
    var is_marked_for_reread: Bool
    var is_private: Bool
    let word_count: Int
    let path: String?
    let entry_type: String
    var attachments: [AttachmentData]
    let created_at: Date
    var updated_at: Date
    
    init(id: UUID = UUID(), user_id: UUID, date: Date, content: String, prompt: String? = nil, path: String? = nil, entry_type: String = "reflection") {
        self.id = id
        self.user_id = user_id
        self.date = date
        self.content = content
        self.prompt = prompt
        self.path = path
        self.entry_type = entry_type
        self.tags = []
        self.is_saved_to_self = false
        self.is_marked_for_reread = false
        self.is_private = false
        self.word_count = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        self.attachments = []
        self.created_at = Date()
        self.updated_at = Date()
    }
    
    struct AttachmentData: Codable {
        let id: UUID
        let filename: String
        let file_url: String
        let file_type: String
        let file_size: Int
        let created_at: Date
    }
    
    func toDomainModel() -> JournalEntry {
        var entry = JournalEntry(
            date: date,
            content: content,
            prompt: prompt,
            mood: mood,
            tags: tags
        )
        entry.id = id
        entry.isSavedToSelf = is_saved_to_self
        entry.isMarkedForReread = is_marked_for_reread
        entry.pathContext = path.flatMap { TrainingPath(rawValue: $0) }
        entry.entryType = JournalEntryType(rawValue: entry_type) ?? .reflection
        entry.isPrivate = is_private
        return entry
    }
    
    mutating func updateFromDomainModel(_ entry: JournalEntry) {
        content = entry.content
        prompt = entry.prompt
        mood = entry.mood
        tags = entry.tags
        is_saved_to_self = entry.isSavedToSelf
        is_marked_for_reread = entry.isMarkedForReread
        path = entry.pathContext?.rawValue
        entry_type = entry.entryType.rawValue
        is_private = entry.isPrivate
        updated_at = Date()
    }
}

// MARK: - DatabaseBookRecommendation (Cloud book model)
struct DatabaseBookRecommendation: Codable {
    let id: UUID
    let title: String
    let author: String
    let path: String
    let summary: String
    let key_insight: String
    let daily_action: String
    var cover_image_url: String?
    var amazon_url: String?
    var goodreads_url: String?
    let isbn: String?
    let publication_year: Int?
    let page_count: Int?
    let reading_difficulty: String
    let genre: String
    let tags: [String]
    var rating: Double
    var review_count: Int
    let recommended_for_levels: [String]
    var seasonal_relevance: [String]
    var is_active: Bool
    let created_at: Date
    var updated_at: Date
    
    init(id: UUID = UUID(), title: String, author: String, path: String, summary: String, key_insight: String, daily_action: String) {
        self.id = id
        self.title = title
        self.author = author
        self.path = path
        self.summary = summary
        self.key_insight = key_insight
        self.daily_action = daily_action
        self.isbn = nil
        self.publication_year = nil
        self.page_count = nil
        self.reading_difficulty = "medium"
        self.genre = "self_help"
        self.tags = []
        self.rating = 0.0
        self.review_count = 0
        self.recommended_for_levels = ["beginner", "intermediate"]
        self.seasonal_relevance = []
        self.is_active = true
        self.created_at = Date()
        self.updated_at = Date()
    }
    
    func toDomainModel() -> BookRecommendation {
        return BookRecommendation(
            title: title,
            author: author,
            path: TrainingPath(rawValue: path) ?? .discipline,
            summary: summary,
            keyInsight: key_insight,
            dailyAction: daily_action,
            coverImageURL: cover_image_url,
            amazonURL: amazon_url,
            dateAdded: created_at
        )
    }
}

// MARK: - DatabaseUserBookInteraction
struct DatabaseUserBookInteraction: Codable {
    let id: UUID
    let user_id: UUID
    let book_id: UUID
    var is_saved: Bool
    var is_read: Bool
    var user_rating: Int?
    var reading_progress: Double
    var time_spent_reading_minutes: Int
    var personal_notes: String?
    var date_started: Date?
    var date_completed: Date?
    var reading_sessions: [ReadingSessionData]
    var highlights: [HighlightData]
    let created_at: Date
    var updated_at: Date
    
    init(id: UUID = UUID(), user_id: UUID, book_id: UUID) {
        self.id = id
        self.user_id = user_id
        self.book_id = book_id
        self.is_saved = false
        self.is_read = false
        self.reading_progress = 0.0
        self.time_spent_reading_minutes = 0
        self.reading_sessions = []
        self.highlights = []
        self.created_at = Date()
        self.updated_at = Date()
    }
    
    struct ReadingSessionData: Codable {
        let id: UUID
        let start_time: Date
        let end_time: Date?
        let pages_read: Int
        let notes: String?
        let created_at: Date
    }
    
    struct HighlightData: Codable {
        let id: UUID
        let text: String
        let note: String?
        let page_number: Int
        let created_at: Date
    }
}

// MARK: - SyncStatus (Synchronization state)
enum SyncStatus: Equatable {
    case idle
    case syncing
    case synced
    case error(String)
    case conflict([String])
    case offline
    
    var displayText: String {
        switch self {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing..."
        case .synced:
            return "Synced"
        case .error(let message):
            return "Error: \(message)"
        case .conflict(let conflicts):
            return "Conflicts: \(conflicts.count)"
        case .offline:
            return "Offline"
        }
    }
    
    var icon: String {
        switch self {
        case .idle:
            return "circle"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .conflict:
            return "exclamationmark.triangle"
        case .offline:
            return "wifi.slash"
        }
    }
    
    var color: Color {
        switch self {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .synced:
            return .green
        case .error:
            return .red
        case .conflict:
            return .orange
        case .offline:
            return .gray
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .syncing:
            return true
        default:
            return false
        }
    }
}

// MARK: - Connection Status
enum ConnectionStatus {
    case unknown
    case connected
    case disconnected
    case reconnecting
    
    var displayText: String {
        switch self {
        case .unknown: return "Unknown"
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .reconnecting: return "Reconnecting..."
        }
    }
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .connected: return .green
        case .disconnected: return .red
        case .reconnecting: return .orange
        }
    }
}

// MARK: - Supabase Errors
enum SupabaseError: Error, LocalizedError {
    case userProfileNotFound
    case invalidData
    case networkError
    case authenticationRequired
    case syncConflict
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .userProfileNotFound:
            return "User profile not found"
        case .invalidData:
            return "Invalid data format"
        case .networkError:
            return "Network connection error"
        case .authenticationRequired:
            return "Authentication required"
        case .syncConflict:
            return "Data synchronization conflict"
        case .quotaExceeded:
            return "Storage quota exceeded"
        }
    }
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
    @Published var hasNewInsights = false
    @Published var pendingCheckIns: [AICheckIn] = []
    
    init() {
        setupSupabaseObservers()
        loadInitialData()
    }
    
    private func setupSupabaseObservers() {
        supabase.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    Task {
                        await self?.loadUserData()
                    }
                } else {
                    self?.clearLocalData()
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func loadInitialData() {
        Task {
            await loadUserData()
        }
    }
    
    @MainActor
    private func loadUserData() async {
        guard let userId = UUID(uuidString: supabase.currentUser?.id ?? "") else { return }
        
        isLoading = true
        
        do {
            // Load user profile
            let dbProfile = try await supabase.getUserProfile(userId: userId)
            userProfile = dbProfile.toDomainModel()
            
            // Load today's challenges
            let challenges = try await supabase.getDailyChallenges(userId: userId, date: Date())
            todaysChallenge = challenges.first?.toDomainModel()
            
            // Load recent check-ins
            let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let checkIns = try await supabase.getCheckIns(userId: userId, startDate: startDate, endDate: Date())
            todaysCheckIns = checkIns.map { $0.toDomainModel() }
            
            // Load journal entries
            let dbJournalEntries = try await supabase.getJournalEntries(userId: userId, limit: 50)
            journalEntries = dbJournalEntries.map { $0.toDomainModel() }
            
            // Load book recommendations
            let dbBooks = try await supabase.getBookRecommendations(limit: 20)
            currentBookRecommendations = dbBooks.map { $0.toDomainModel() }
            
            isLoading = false
            
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func clearLocalData() {
        userProfile = nil
        todaysChallenge = nil
        todaysCheckIns.removeAll()
        journalEntries.removeAll()
        currentBookRecommendations.removeAll()
        weeklySummaries.removeAll()
    }
    
    // MARK: - Data Operations
    
    func createUserProfile(selectedPath: TrainingPath) {
        guard let userId = UUID(uuidString: supabase.currentUser?.id ?? "") else { return }
        
        let dbProfile = DatabaseUserProfile(
            id: UUID(),
            user_id: userId,
            selected_path: selectedPath.rawValue,
            join_date: Date(),
            current_streak: 0,
            longest_streak: 0,
            total_challenges_completed: 0,
            subscription_tier: "free",
            streak_bank_days: 0,
            first_name: supabase.currentUser?.firstName ?? "",
            last_name: supabase.currentUser?.lastName ?? "",
            email_verified: false
        )
        
        Task {
            do {
                try await supabase.insertUserProfile(dbProfile)
                await MainActor.run {
                    userProfile = dbProfile.toDomainModel()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create profile: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func submitCheckIn(_ checkIn: AICheckIn) {
        guard let userId = UUID(uuidString: supabase.currentUser?.id ?? "") else { return }
        
        var dbCheckIn = DatabaseCheckIn(
            id: checkIn.id,
            user_id: userId,
            date: checkIn.date,
            time_of_day: checkIn.timeOfDay.rawValue,
            prompt: checkIn.prompt
        )
        dbCheckIn.updateFromDomainModel(checkIn)
        
        Task {
            do {
                try await supabase.insertCheckIn(dbCheckIn)
                await MainActor.run {
                    todaysCheckIns.append(checkIn)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save check-in: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func addJournalEntry(_ entry: JournalEntry) {
        guard let userId = UUID(uuidString: supabase.currentUser?.id ?? "") else { return }
        
        var dbEntry = DatabaseJournalEntry(
            id: entry.id,
            user_id: userId,
            date: entry.date,
            content: entry.content,
            prompt: entry.prompt
        )
        dbEntry.updateFromDomainModel(entry)
        
        Task {
            do {
                try await supabase.insertJournalEntry(dbEntry)
                await MainActor.run {
                    journalEntries.insert(entry, at: 0)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save journal entry: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func refreshDashboardData() async {
        await loadUserData()
    }
}

// MARK: - Date Extensions
extension Date {
    var iso8601: String {
        return ISO8601DateFormatter().string(from: self)
    }
}

// MARK: - Sync Status View
struct SyncStatusView: View {
    @ObservedObject var supabaseManager: SupabaseManager
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: supabaseManager.syncStatus.icon)
                .foregroundColor(supabaseManager.syncStatus.color)
                .font(.caption)
            
            Text(supabaseManager.syncStatus.displayText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(supabaseManager.syncStatus.color.opacity(0.1))
        )
    }
}

// MARK: - Preview
struct SupabaseIntegration_Previews: PreviewProvider {
    static var previews: some View {
        SyncStatusView(supabaseManager: SupabaseManager.shared)
    }
}
