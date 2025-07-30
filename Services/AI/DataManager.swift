import CoreData
import Foundation
import Combine
import SwiftUI

// MARK: - EnhancedDataManager (Main data class)
class EnhancedDataManager: ObservableObject {
    private let coreDataStack = CoreDataStack.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var userProfile: UserProfile?
    @Published var todaysChallenge: DailyChallenge?
    @Published var todaysCheckIns: [AICheckIn] = []
    @Published var currentBookRecommendations: [BookRecommendation] = []
    @Published var journalEntries: [JournalEntry] = []
    @Published var savedBooks: [BookRecommendation] = []
    @Published var readingGoals: [CDReadingGoal] = []
    @Published var currentReadingSession: CDReadingSession?
    @Published var weeklySummaries: [WeeklySummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasNewInsights = false
    @Published var pendingCheckIns: [AICheckIn] = []
    
    // Analytics and Stats
    @Published var readingStats: ReadingStats?
    @Published var streakData: StreakData?
    @Published var moodData: [MoodDataPoint] = []
    @Published var recentActivity: [ActivityItem] = []
    
    init() {
        loadUserProfile()
        setupDataObservers()
        generateTodaysContent()
        loadAnalytics()
    }
    
    // MARK: - Core Data Operations
    
    func createUserProfile(selectedPath: TrainingPath) {
        let profile = UserProfile(selectedPath: selectedPath)
        userProfile = profile
        saveUserProfile()
        generateTodaysContent()
    }
    
    func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        saveUserProfile()
    }
    
    func changeTrainingPath(to path: TrainingPath) {
        userProfile?.selectedPath = path
        saveUserProfile()
        generateTodaysContent()
    }
    
    private func saveUserProfile() {
        guard let profile = userProfile else { return }
        
        // Save to Core Data
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        let existingProfile = coreDataStack.fetch(request).first
        
        if let existing = existingProfile {
            existing.updateFromDomainModel(profile)
        } else {
            let newProfile = CDUserProfile(context: coreDataStack.context)
            newProfile.updateFromDomainModel(profile)
        }
        
        coreDataStack.save()
    }
    
    private func loadUserProfile() {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        
        if let cdProfile = coreDataStack.fetch(request).first {
            userProfile = cdProfile.toDomainModel()
        }
    }
    
    // MARK: - Reading Analytics
    
    func getReadingStats(for period: StatsPeriod) -> ReadingStats {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch period {
        case .thisWeek:
            startDate = calendar.dateInterval(of: .weekOfYear, for: endDate)?.start ?? endDate
        case .thisMonth:
            startDate = calendar.dateInterval(of: .month, for: endDate)?.start ?? endDate
        case .thisYear:
            startDate = calendar.dateInterval(of: .year, for: endDate)?.start ?? endDate
        case .allTime:
            startDate = userProfile?.joinDate ?? endDate
        }
        
        // Fetch reading sessions
        let sessionRequest: NSFetchRequest<CDReadingSession> = CDReadingSession.fetchRequest()
        sessionRequest.predicate = NSPredicate(format: "startTime >= %@ AND endTime != nil", startDate as NSDate)
        
        let sessions = coreDataStack.fetch(sessionRequest)
        
        // Calculate stats
        let totalMinutes = sessions.compactMap { session in
            guard let endTime = session.endTime else { return nil }
            return Int(endTime.timeIntervalSince(session.startTime)) / 60
        }.reduce(0, +)
        
        let pagesRead = sessions.map { Int($0.pagesRead) }.reduce(0, +)
        let averageSession = sessions.isEmpty ? 0 : totalMinutes / sessions.count
        let longestSession = sessions.compactMap { session in
            guard let endTime = session.endTime else { return nil }
            return Int(endTime.timeIntervalSince(session.startTime)) / 60
        }.max() ?? 0
        
        // Count completed books
        let bookRequest: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        bookRequest.predicate = NSPredicate(format: "isRead == YES AND dateRead >= %@", startDate as NSDate)
        let completedBooks = coreDataStack.fetch(bookRequest).count
        
        // Calculate books per month
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let monthsBetween = max(Double(daysBetween) / 30.0, 1.0)
        let booksPerMonth = Double(completedBooks) / monthsBetween
        
        return ReadingStats(
            booksRead: completedBooks,
            totalReadingMinutes: totalMinutes,
            journalEntries: journalEntries.filter { $0.date >= startDate }.count,
            checkIns: todaysCheckIns.filter { $0.date >= startDate }.count,
            challengesCompleted: userProfile?.totalChallengesCompleted ?? 0,
            period: period,
            averageSessionLength: averageSession,
            longestSession: longestSession,
            booksPerMonth: booksPerMonth,
            pagesRead: pagesRead
        )
    }
    
    // MARK: - Mood Tracking
    
    func getMoodData(for period: StatsPeriod) -> [MoodDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch period {
        case .thisWeek:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .thisMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .thisYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        case .allTime:
            startDate = userProfile?.joinDate ?? endDate
        }
        
        let request: NSFetchRequest<CDCheckIn> = CDCheckIn.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND moodRaw != nil", 
                                      startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCheckIn.date, ascending: true)]
        
        let checkIns = coreDataStack.fetch(request)
        
        // Group by day and calculate average mood
        let groupedByDay = Dictionary(grouping: checkIns) { checkIn in
            calendar.startOfDay(for: checkIn.date)
        }
        
        return groupedByDay.compactMap { date, checkIns in
            let moodValues = checkIns.compactMap { checkIn -> Int? in
                guard let mood = checkIn.mood else { return nil }
                switch mood {
                case .low: return 1
                case .neutral: return 2
                case .good: return 3
                case .great: return 4
                case .excellent: return 5
                }
            }
            
            guard !moodValues.isEmpty else { return nil }
            let averageMood = Double(moodValues.reduce(0, +)) / Double(moodValues.count)
            
            return MoodDataPoint(date: date, averageMood: averageMood)
        }.sorted { $0.date < $1.date }
    }
    
    // MARK: - Streak Management
    
    func getStreakData() -> StreakData {
        guard let profile = userProfile else {
            return StreakData(currentStreak: 0, longestStreak: 0, streakHistory: [])
        }
        
        // Get challenge completion history for streak calculation
        let request: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDailyChallenge.date, ascending: true)]
        
        let completedChallenges = coreDataStack.fetch(request)
        let streakHistory = completedChallenges.map { 
            StreakDataPoint(date: $0.date, completed: true, challengeTitle: $0.title) 
        }
        
        return StreakData(
            currentStreak: profile.currentStreak,
            longestStreak: profile.longestStreak,
            streakHistory: streakHistory
        )
    }
    
    func updateStreak(completed: Bool) {
        guard var profile = userProfile else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        if completed {
            // Check if we already have a streak entry for today
            let hasCompletedToday = (streakData?.streakHistory.contains { 
                calendar.isDate($0.date, inSameDayAs: today) && $0.completed 
            }) ?? false
            
            if !hasCompletedToday {
                // Check if streak continues from yesterday
                let completedYesterday = (streakData?.streakHistory.contains { 
                    calendar.isDate($0.date, inSameDayAs: yesterday) && $0.completed 
                }) ?? false
                
                if completedYesterday || profile.currentStreak == 0 {
                    profile.currentStreak += 1
                } else {
                    profile.currentStreak = 1 // Reset streak if gap
                }
                
                // Update longest streak
                if profile.currentStreak > profile.longestStreak {
                    profile.longestStreak = profile.currentStreak
                }
            }
        }
        
        userProfile = profile
        saveUserProfile()
        streakData = getStreakData()
    }
    
    // MARK: - Data Export
    
    func exportUserData() -> UserDataExport {
        let stats = readingStats ?? getReadingStats(for: .allTime)
        
        return UserDataExport(
            userProfile: userProfile ?? UserProfile(selectedPath: .discipline),
            books: currentBookRecommendations + savedBooks,
            journalEntries: journalEntries,
            checkIns: todaysCheckIns,
            challenges: todaysChallenge.map { [$0] } ?? [],
            weeklySummaries: weeklySummaries,
            achievements: [], // Would be populated from achievements system
            readingStats: stats,
            exportDate: Date()
        )
    }
    
    // MARK: - Content Generation
    
    private func generateTodaysContent() {
        generateTodaysChallenge()
        loadTodaysCheckIns()
        generateBookRecommendations()
    }
    
    private func generateTodaysChallenge() {
        guard let userProfile = userProfile else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we already have today's challenge
        let request: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", 
                                      today as NSDate, 
                                      calendar.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        if let existingChallenge = coreDataStack.fetch(request).first {
            todaysChallenge = existingChallenge.toDomainModel()
        } else {
            // Generate new challenge
            let newChallenge = ChallengeGenerator.generateDailyChallenge(
                for: userProfile.selectedPath,
                difficulty: determineDifficulty(),
                userContext: getUserContext()
            )
            
            // Save to Core Data
            let cdChallenge = CDDailyChallenge(context: coreDataStack.context)
            cdChallenge.updateFromDomainModel(newChallenge)
            coreDataStack.save()
            
            todaysChallenge = newChallenge
        }
    }
    
    private func loadTodaysCheckIns() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let request: NSFetchRequest<CDCheckIn> = CDCheckIn.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", 
                                      today as NSDate, 
                                      calendar.date(byAdding: .day, value: 1, to: today)! as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCheckIn.date, ascending: true)]
        
        let cdCheckIns = coreDataStack.fetch(request)
        todaysCheckIns = cdCheckIns.map { $0.toDomainModel() }
        
        // Check for pending check-ins
        updatePendingCheckIns()
    }
    
    private func generateBookRecommendations() {
        guard let userProfile = userProfile else { return }
        
        let newBooks = BookGenerator.generateRecommendations(for: userProfile.selectedPath, count: 5)
        currentBookRecommendations = newBooks
        
        // Save new books to Core Data
        for book in newBooks {
            let cdBook = CDBookRecommendation(context: coreDataStack.context)
            cdBook.updateFromDomainModel(book)
        }
        coreDataStack.save()
    }
    
    // MARK: - Challenge Operations
    
    func completeChallenge(_ challenge: DailyChallenge, effortLevel: Int? = nil, notes: String? = nil) {
        var updatedChallenge = challenge
        updatedChallenge.isCompleted = true
        updatedChallenge.completedAt = Date()
        updatedChallenge.effortLevel = effortLevel
        updatedChallenge.userNotes = notes
        
        // Update in Core Data
        let request: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", challenge.id as CVarArg)
        
        if let cdChallenge = coreDataStack.fetch(request).first {
            cdChallenge.updateFromDomainModel(updatedChallenge)
            coreDataStack.save()
        }
        
        todaysChallenge = updatedChallenge
        updateStreak(completed: true)
        
        // Update user profile stats
        userProfile?.totalChallengesCompleted += 1
        saveUserProfile()
    }
    
    func skipChallenge(_ challenge: DailyChallenge, reason: String) {
        var updatedChallenge = challenge
        updatedChallenge.isSkipped = true
        updatedChallenge.skipReason = reason
        
        // Update in Core Data
        let request: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", challenge.id as CVarArg)
        
        if let cdChallenge = coreDataStack.fetch(request).first {
            cdChallenge.updateFromDomainModel(updatedChallenge)
            coreDataStack.save()
        }
        
        todaysChallenge = updatedChallenge
    }
    
    // MARK: - Check-in Operations
    
    func submitCheckIn(_ checkIn: AICheckIn) {
        // Save to Core Data
        let cdCheckIn = CDCheckIn(context: coreDataStack.context)
        cdCheckIn.updateFromDomainModel(checkIn)
        coreDataStack.save()
        
        // Update local state
        todaysCheckIns.append(checkIn)
        updatePendingCheckIns()
        
        // Update user stats
        userProfile?.totalCheckIns += 1
        saveUserProfile()
    }
    
    private func updatePendingCheckIns() {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        pendingCheckIns.removeAll()
        
        // Check for missing morning check-in (after 10 AM)
        if currentHour >= 10 {
            let hasMorningCheckIn = todaysCheckIns.contains { $0.timeOfDay == .morning }
            if !hasMorningCheckIn {
                let morningCheckIn = AICheckIn(date: now, timeOfDay: .morning, prompt: "How are you feeling as you start your day?")
                pendingCheckIns.append(morningCheckIn)
            }
        }
        
        // Check for missing evening check-in (after 8 PM)
        if currentHour >= 20 {
            let hasEveningCheckIn = todaysCheckIns.contains { $0.timeOfDay == .evening }
            if !hasEveningCheckIn {
                let eveningCheckIn = AICheckIn(date: now, timeOfDay: .evening, prompt: "How did your day go? What did you learn?")
                pendingCheckIns.append(eveningCheckIn)
            }
        }
    }
    
    // MARK: - Journal Operations
    
    func addJournalEntry(_ entry: JournalEntry) {
        journalEntries.append(entry)
        
        // Save to Core Data
        let cdEntry = CDJournalEntry(context: coreDataStack.context)
        cdEntry.updateFromDomainModel(entry)
        coreDataStack.save()
        
        // Update user stats
        userProfile?.totalJournalEntries += 1
        saveUserProfile()
    }
    
    func updateJournalEntry(_ entry: JournalEntry) {
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            journalEntries[index] = entry
            
            // Update in Core Data
            let request: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
            
            if let cdEntry = coreDataStack.fetch(request).first {
                cdEntry.updateFromDomainModel(entry)
                coreDataStack.save()
            }
        }
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) {
        journalEntries.removeAll { $0.id == entry.id }
        
        // Delete from Core Data
        let request: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        if let cdEntry = coreDataStack.fetch(request).first {
            coreDataStack.context.delete(cdEntry)
            coreDataStack.save()
        }
    }
    
    // MARK: - Book Operations
    
    func addBookRecommendation(_ book: BookRecommendation) {
        currentBookRecommendations.append(book)
        
        // Save to Core Data
        let cdBook = CDBookRecommendation(context: coreDataStack.context)
        cdBook.updateFromDomainModel(book)
        coreDataStack.save()
    }
    
    func saveBook(_ book: BookRecommendation) {
        var updatedBook = book
        updatedBook.isSaved = true
        
        if !savedBooks.contains(where: { $0.id == book.id }) {
            savedBooks.append(updatedBook)
        }
        
        // Update in Core Data
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        if let cdBook = coreDataStack.fetch(request).first {
            cdBook.isSaved = true
            coreDataStack.save()
        }
    }
    
    func markBookAsRead(_ book: BookRecommendation, rating: Int? = nil) {
        var updatedBook = book
        updatedBook.isRead = true
        updatedBook.dateRead = Date()
        updatedBook.userRating = rating ?? 0
        
        // Update in arrays
        if let index = currentBookRecommendations.firstIndex(where: { $0.id == book.id }) {
            currentBookRecommendations[index] = updatedBook
        }
        if let index = savedBooks.firstIndex(where: { $0.id == book.id }) {
            savedBooks[index] = updatedBook
        }
        
        // Update in Core Data
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        if let cdBook = coreDataStack.fetch(request).first {
            cdBook.isRead = true
            cdBook.dateRead = Date()
            cdBook.userRating = Int16(rating ?? 0)
            coreDataStack.save()
        }
        
        // Update user stats
        userProfile?.totalBooksRead += 1
        saveUserProfile()
    }
    
    // MARK: - Reading Session Management
    
    func startReadingSession(for bookId: UUID) {
        let session = CDReadingSession(context: coreDataStack.context)
        session.id = UUID()
        session.startTime = Date()
        
        // Link to book
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
        session.book = coreDataStack.fetch(request).first
        
        coreDataStack.save()
        currentReadingSession = session
    }
    
    func endCurrentReadingSession(pagesRead: Int = 0, notes: String? = nil) {
        guard let session = currentReadingSession else { return }
        
        session.endTime = Date()
        session.pagesRead = Int32(pagesRead)
        session.notes = notes
        
        coreDataStack.save()
        currentReadingSession = nil
        
        // Update reading stats
        loadAnalytics()
    }
    
    // MARK: - Notification Settings
    
    func updateNotificationSettings(
        morningCheckInEnabled: Bool,
        eveningCheckInEnabled: Bool,
        challengeRemindersEnabled: Bool,
        weeklyInsightsEnabled: Bool,
        streakRemindersEnabled: Bool,
        morningTime: Date,
        eveningTime: Date
    ) {
        userProfile?.notificationSettings.morningCheckInEnabled = morningCheckInEnabled
        userProfile?.notificationSettings.eveningCheckInEnabled = eveningCheckInEnabled
        userProfile?.notificationSettings.challengeRemindersEnabled = challengeRemindersEnabled
        userProfile?.notificationSettings.weeklyInsightsEnabled = weeklyInsightsEnabled
        userProfile?.notificationSettings.streakRemindersEnabled = streakRemindersEnabled
        userProfile?.notificationSettings.morningCheckInTime = morningTime
        userProfile?.notificationSettings.eveningCheckInTime = eveningTime
        
        saveUserProfile()
    }
    
    // MARK: - Analytics and Insights
    
    private func loadAnalytics() {
        readingStats = getReadingStats(for: .thisMonth)
        streakData = getStreakData()
        moodData = getMoodData(for: .thisMonth)
        loadRecentActivity()
    }
    
    private func loadRecentActivity() {
        recentActivity.removeAll()
        
        // Add recent challenges
        if let challenge = todaysChallenge, challenge.isCompleted {
            recentActivity.append(ActivityItem(
                type: .challengeCompleted,
                title: "Completed daily challenge",
                subtitle: challenge.title,
                date: challenge.completedAt ?? Date(),
                icon: "target"
            ))
        }
        
        // Add recent journal entries
        let recentEntries = journalEntries.suffix(3)
        for entry in recentEntries {
            recentActivity.append(ActivityItem(
                type: .journalEntry,
                title: "New journal entry",
                subtitle: String(entry.content.prefix(50)) + "...",
                date: entry.date,
                icon: "book.closed"
            ))
        }
        
        // Add recent check-ins
        let recentCheckIns = todaysCheckIns.suffix(2)
        for checkIn in recentCheckIns {
            recentActivity.append(ActivityItem(
                type: .checkIn,
                title: "\(checkIn.timeOfDay.displayName) check-in",
                subtitle: checkIn.userResponse ?? "Completed",
                date: checkIn.date,
                icon: "message"
            ))
        }
        
        // Sort by date
        recentActivity.sort { $0.date > $1.date }
    }
    
    func refreshDashboardData() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Simulate data refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            loadAnalytics()
            updatePendingCheckIns()
            isLoading = false
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupDataObservers() {
        // Set up periodic updates
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePendingCheckIns()
                self?.loadRecentActivity()
            }
            .store(in: &cancellables)
        
        // Daily content generation
        Timer.publish(every: 3600, on: .main, in: .common) // Every hour
            .autoconnect()
            .sink { [weak self] _ in
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: Date())
                
                // Generate new content at midnight
                if hour == 0 {
                    self?.generateTodaysContent()
                }
            }
            .store(in: &cancellables)
    }
    
    private func determineDifficulty() -> ChallengeDifficulty {
        guard let profile = userProfile else { return .medium }
        
        // Adjust difficulty based on current streak
        switch profile.currentStreak {
        case 0...3:
            return .easy
        case 4...10:
            return .medium
        case 11...30:
            return .hard
        default:
            return .expert
        }
    }
    
    private func getUserContext() -> String {
        guard let profile = userProfile else { return "" }
        
        return """
        User has been focusing on \(profile.selectedPath.displayName) for \(profile.totalChallengesCompleted) days.
        Current streak: \(profile.currentStreak) days.
        Longest streak: \(profile.longestStreak) days.
        Total journal entries: \(profile.totalJournalEntries).
        Subscription: \(profile.subscriptionTier.displayName).
        """
    }
}

// MARK: - ReadingStats (Reading analytics)
struct ReadingStats: Codable {
    let booksRead: Int
    let totalReadingMinutes: Int
    let journalEntries: Int
    let checkIns: Int
    let challengesCompleted: Int
    let period: StatsPeriod
    let averageSessionLength: Int
    let longestSession: Int
    let booksPerMonth: Double
    let pagesRead: Int
    
    var formattedReadingTime: String {
        let hours = totalReadingMinutes / 60
        let minutes = totalReadingMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var readingVelocity: String {
        switch period {
        case .thisWeek:
            return String(format: "%.1f books/week", Double(booksRead))
        case .thisMonth:
            return String(format: "%.1f books/month", booksPerMonth)
        case .thisYear:
            return String(format: "%.1f books/year", booksPerMonth * 12)
        case .allTime:
            return "\(booksRead) total books"
        }
    }
    
    var completionRate: Double {
        let totalActivities = challengesCompleted + journalEntries + checkIns
        return totalActivities > 0 ? Double(challengesCompleted) / Double(totalActivities) : 0.0
    }
}

// MARK: - MoodDataPoint (Mood tracking data)
struct MoodDataPoint: Identifiable, Codable {
    var id: UUID = UUID()
    let date: Date
    let averageMood: Double // 1.0 to 5.0
    let dataPoints: Int // Number of check-ins that day
    let notes: String?
    
    init(date: Date, averageMood: Double, dataPoints: Int = 1, notes: String? = nil) {
        self.date = date
        self.averageMood = averageMood
        self.dataPoints = dataPoints
        self.notes = notes
    }
    
    var moodDescription: String {
        switch averageMood {
        case 4.5...5.0:
            return "Excellent"
        case 3.5..<4.5:
            return "Great"
        case 2.5..<3.5:
            return "Good"
        case 1.5..<2.5:
            return "Neutral"
        default:
            return "Low"
        }
    }
    
    var moodColor: Color {
        switch averageMood {
        case 4.0...5.0:
            return .green
        case 3.0..<4.0:
            return .blue
        case 2.0..<3.0:
            return .yellow
        default:
            return .red
        }
    }
    
    var moodIcon: String {
        switch averageMood {
        case 4.5...5.0:
            return "face.smiling.fill"
        case 3.5..<4.5:
            return "face.smiling"
        case 2.5..<3.5:
            return "face.fill"
        case 1.5..<2.5:
            return "face.dashed"
        default:
            return "face.dashed.fill"
        }
    }
}

// MARK: - StreakData (Streak information)
struct StreakData: Identifiable, Codable {
    var id: UUID = UUID()
    let currentStreak: Int
    let longestStreak: Int
    let streakHistory: [StreakDataPoint]
    let lastActivityDate: Date?
    let streakStartDate: Date?
    
    init(currentStreak: Int, longestStreak: Int, streakHistory: [StreakDataPoint]) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.streakHistory = streakHistory
        self.lastActivityDate = streakHistory.last?.date
        
        // Calculate streak start date
        if currentStreak > 0 {
            let calendar = Calendar.current
            self.streakStartDate = calendar.date(byAdding: .day, value: -(currentStreak - 1), to: Date())
        } else {
            self.streakStartDate = nil
        }
    }
    
    var streakLevel: StreakLevel {
        return StreakLevel.from(streak: currentStreak)
    }
    
    var daysSinceLastActivity: Int {
        guard let lastDate = lastActivityDate else { return 0 }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    }
    
    var isStreakAtRisk: Bool {
        return daysSinceLastActivity >= 1
    }
    
    var weeklyCompletionRate: Double {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let recentHistory = streakHistory.filter { $0.date >= weekAgo }
        let weeklyStreaks = Dictionary(grouping: recentHistory) { dataPoint in
            calendar.dateComponents([.weekOfYear, .year], from: dataPoint.date)
        }.mapValues { points in
            points.filter { $0.completed }.count
        }
        
        let total = weeklyStreaks.values.reduce(0, +)
        return Double(total) / 7.0 // Completion rate for the week
    }
}

// MARK: - StreakDataPoint (Individual streak points)
struct StreakDataPoint: Identifiable, Codable {
    var id: UUID = UUID()
    let date: Date
    let completed: Bool
    let challengeTitle: String?
    let effortLevel: Int? // 1-5 scale
    let completionTime: Date?
    let notes: String?
    
    init(date: Date, completed: Bool, challengeTitle: String? = nil, effortLevel: Int? = nil, notes: String? = nil) {
        self.date = date
        self.completed = completed
        self.challengeTitle = challengeTitle
        self.effortLevel = effortLevel
        self.completionTime = completed ? Date() : nil
        self.notes = notes
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - UserDataExport (Export data model)
struct UserDataExport: Codable {
    let userProfile: UserProfile
    let books: [BookRecommendation]
    let journalEntries: [JournalEntry]
    let checkIns: [AICheckIn]
    let challenges: [DailyChallenge]
    let weeklySummaries: [WeeklySummary]
    let achievements: [Achievement]
    let readingStats: ReadingStats
    let streakData: StreakData?
    let moodData: [MoodDataPoint]
    let exportDate: Date
    let appVersion: String
    let exportMetadata: ExportMetadata
    
    init(userProfile: UserProfile, books: [BookRecommendation], journalEntries: [JournalEntry], checkIns: [AICheckIn], challenges: [DailyChallenge] = [], weeklySummaries: [WeeklySummary] = [], achievements: [Achievement] = [], readingStats: ReadingStats, exportDate: Date = Date()) {
        self.userProfile = userProfile
        self.books = books
        self.journalEntries = journalEntries
        self.checkIns = checkIns
        self.challenges = challenges
        self.weeklySummaries = weeklySummaries
        self.achievements = achievements
        self.readingStats = readingStats
        self.streakData = nil
        self.moodData = []
        self.exportDate = exportDate
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        self.exportMetadata = ExportMetadata(
            totalDataPoints: journalEntries.count + checkIns.count + challenges.count,
            dataRangeStart: journalEntries.first?.date ?? userProfile.joinDate,
            dataRangeEnd: exportDate
        )
    }
    
    struct ExportMetadata: Codable {
        let totalDataPoints: Int
        let dataRangeStart: Date
        let dataRangeEnd: Date
        let exportFormat: String = "JSON"
        let compressionUsed: Bool = false
        let includedDataTypes: [String]
        
        init(totalDataPoints: Int, dataRangeStart: Date, dataRangeEnd: Date) {
            self.totalDataPoints = totalDataPoints
            self.dataRangeStart = dataRangeStart
            self.dataRangeEnd = dataRangeEnd
            self.includedDataTypes = [
                "UserProfile", "BookRecommendations", "JournalEntries", 
                "CheckIns", "Challenges", "WeeklySummaries", "Achievements", 
                "ReadingStats", "StreakData", "MoodData"
            ]
        }
    }
    
    var fileSizeEstimate: String {
        // Rough estimate based on content
        let estimatedBytes = (journalEntries.count * 500) + 
                           (checkIns.count * 200) + 
                           (books.count * 300) + 
                           (challenges.count * 150)
        
        if estimatedBytes < 1024 {
            return "\(estimatedBytes) bytes"
        } else if estimatedBytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(estimatedBytes) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(estimatedBytes) / (1024.0 * 1024.0))
        }
    }
}

// MARK: - StatsPeriod (Analytics time periods)
enum StatsPeriod: String, Codable, CaseIterable {
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case thisYear = "this_year"
    case allTime = "all_time"
    
    var displayName: String {
        switch self {
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .thisYear: return "This Year"
        case .allTime: return "All Time"
        }
    }
    
    var icon: String {
        switch self {
        case .thisWeek: return "calendar.badge.clock"
        case .thisMonth: return "calendar"
        case .thisYear: return "calendar.badge.plus"
        case .allTime: return "infinity"
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .thisWeek: return "Week"
        case .thisMonth: return "Month"
        case .thisYear: return "Year"
        case .allTime: return "All"
        }
    }
    
    func dateRange(from endDate: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        
        switch self {
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: endDate)?.start ?? endDate
            return (start, endDate)
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: endDate)?.start ?? endDate
            return (start, endDate)
        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: endDate)?.start ?? endDate
            return (start, endDate)
        case .allTime:
            // Return a very early date for all time
            let start = calendar.date(byAdding: .year, value: -10, to: endDate) ?? endDate
            return (start, endDate)
        }
    }
}

// MARK: - Activity Item (Recent activity tracking)
struct ActivityItem: Identifiable, Codable {
    var id: UUID = UUID()
    let type: ActivityType
    let title: String
    let subtitle: String
    let date: Date
    let icon: String
    let metadata: [String: String]
    
    init(type: ActivityType, title: String, subtitle: String, date: Date, icon: String, metadata: [String: String] = [:]) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.icon = icon
        self.metadata = metadata
    }
    
    enum ActivityType: String, Codable {
        case challengeCompleted = "challenge_completed"
        case journalEntry = "journal_entry"
        case checkIn = "check_in"
        case bookRead = "book_read"
        case streakMilestone = "streak_milestone"
        case pathChanged = "path_changed"
        
        var displayName: String {
            switch self {
            case .challengeCompleted: return "Challenge Completed"
            case .journalEntry: return "Journal Entry"
            case .checkIn: return "Check-in"
            case .bookRead: return "Book Read"
            case .streakMilestone: return "Streak Milestone"
            case .pathChanged: return "Path Changed"
            }
        }
        
        var color: Color {
            switch self {
            case .challengeCompleted: return .green
            case .journalEntry: return .blue
            case .checkIn: return .purple
            case .bookRead: return .orange
            case .streakMilestone: return .yellow
            case .pathChanged: return .red
            }
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview Support
extension EnhancedDataManager {
    static func preview() -> EnhancedDataManager {
        let manager = EnhancedDataManager()
        
        // Mock data for previews
        manager.userProfile = UserProfile(selectedPath: .discipline)
        manager.todaysChallenge = DailyChallenge(
            title: "Complete 10 pushups",
            description: "Start your day with physical activity",
            path: .discipline,
            difficulty: .medium,
            date: Date(),
            estimatedTimeMinutes: 5,
            category: .physical,
            tags: ["exercise", "morning"]
        )
        
        return manager
    }
}

// MARK: - Extension for Challenge Generator
extension EnhancedDataManager {
    static let challengeTemplates: [TrainingPath: [String]] = [
        .discipline: [
            "Complete one important task before checking your phone",
            "Exercise for 10 minutes without stopping",
            "Spend 15 minutes organizing your workspace",
            "Practice saying 'no' to one unnecessary commitment",
            "Wake up 15 minutes earlier than usual"
        ],
        .clarity: [
            "Meditate for 5 minutes in silence",
            "Write down 3 thoughts you want to release",
            "Practice deep breathing for 2 minutes",
            "Identify one assumption you're making today",
            "Observe your emotions without judgment for 10 minutes"
        ],
        .confidence: [
            "Start a conversation with someone new",
            "Share your opinion in a group discussion",
            "Take up space - sit with good posture for 1 hour",
            "Give someone a genuine compliment",
            "Practice speaking louder and clearer"
        ],
        .purpose: [
            "Review your 5-year vision for 3 minutes",
            "Identify one value that will guide your decisions today",
            "Write down what legacy you want to leave",
            "Connect with someone who shares your values",
            "Take one small action toward your biggest goal"
        ],
        .authenticity: [
            "Express a genuine emotion instead of hiding it",
            "Say no to something that doesn't align with your values",
            "Do something that feels true to you, even if uncomfortable",
            "Share something real about yourself with someone",
            "Practice being vulnerable in a small way"
        ]
    ]
}

// MARK: - Simple Challenge Generator
struct ChallengeGenerator {
    static func generateDailyChallenge(for path: TrainingPath, difficulty: ChallengeDifficulty, userContext: String) -> DailyChallenge {
        let templates = EnhancedDataManager.challengeTemplates[path] ?? []
        let selectedTemplate = templates.randomElement() ?? "Focus on your personal growth today"
        
        return DailyChallenge(
            title: selectedTemplate,
            description: "A personalized challenge to help you grow in \(path.displayName.lowercased())",
            path: path,
            difficulty: difficulty,
            date: Date(),
            estimatedTimeMinutes: difficulty.estimatedMinutes,
            category: .mindset,
            tags: [path.rawValue, difficulty.rawValue]
        )
    }
}

extension ChallengeDifficulty {
    var estimatedMinutes: Int {
        switch self {
        case .easy: return 5
        case .medium: return 15
        case .hard: return 30
        case .expert: return 60
        }
    }
}
