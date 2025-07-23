import CoreData
import Foundation
import Combine

// MARK: - Enhanced Data Manager with Core Data
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
    
    // MARK: - Initialization
    init() {
        loadAllData()
        setupNotifications()
    }
    
    // MARK: - Data Loading
    private func loadAllData() {
        loadUserProfile()
        loadTodaysChallenge()
        loadTodaysCheckIns()
        loadBookRecommendations()
        loadJournalEntries()
        loadReadingGoals()
        loadCurrentReadingSession()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.loadAllData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - User Profile Management
    func loadUserProfile() {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        let profiles = coreDataStack.fetch(request)
        
        if let cdProfile = profiles.first {
            userProfile = cdProfile.toDomainModel()
        } else {
            // Create default profile if none exists
            createDefaultUserProfile()
        }
    }
    
    func createUserProfile(selectedPath: TrainingPath) {
        let cdProfile = CDUserProfile(context: coreDataStack.context)
        cdProfile.id = UUID()
        
        var profile = UserProfile(selectedPath: selectedPath)
        cdProfile.updateFromDomainModel(profile)
        
        coreDataStack.save()
        userProfile = profile
        generateTodaysContent()
    }
    
    func updateUserPath(_ path: TrainingPath) {
        guard var profile = userProfile else { return }
        profile.selectedPath = path
        
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        if let cdProfile = coreDataStack.fetch(request).first {
            cdProfile.updateFromDomainModel(profile)
            coreDataStack.save()
            userProfile = profile
            generateTodaysContent()
        }
    }
    
    func updateUserProfile(_ profile: UserProfile) {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        if let cdProfile = coreDataStack.fetch(request).first {
            cdProfile.updateFromDomainModel(profile)
            coreDataStack.save()
            userProfile = profile
        }
    }
    
    private func createDefaultUserProfile() {
        createUserProfile(selectedPath: .discipline)
    }
    
    // MARK: - Challenge Management
    func loadTodaysChallenge() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let request: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", 
                                      today as NSDate, 
                                      calendar.date(byAdding: .day, value: 1, to: today)! as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDailyChallenge.date, ascending: false)]
        
        let challenges = coreDataStack.fetch(request)
        
        if let cdChallenge = challenges.first {
            todaysChallenge = cdChallenge.toDomainModel()
        } else {
            generateTodaysChallenge()
        }
    }
    
    func generateTodaysChallenge() {
        guard let userProfile = userProfile else { return }
        
        // Generate new challenge
        let challenge = ChallengeGenerator.generateChallenge(for: userProfile.selectedPath, difficulty: .micro)
        
        // Save to Core Data
        let cdChallenge = CDDailyChallenge(context: coreDataStack.context)
        cdChallenge.id = UUID()
        cdChallenge.updateFromDomainModel(challenge)
        
        coreDataStack.save()
        todaysChallenge = challenge
    }
    
    func completeChallenge() {
        guard var challenge = todaysChallenge,
              var profile = userProfile else { return }
        
        challenge.isCompleted = true
        challenge.completedAt = Date()
        
        // Update streak
        profile.currentStreak += 1
        if profile.currentStreak > profile.longestStreak {
            profile.longestStreak = profile.currentStreak
        }
        profile.totalChallengesCompleted += 1
        
        // Update Core Data
        let challengeRequest: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        challengeRequest.predicate = NSPredicate(format: "id == %@", challenge.id as CVarArg)
        
        if let cdChallenge = coreDataStack.fetch(challengeRequest).first {
            cdChallenge.updateFromDomainModel(challenge)
            cdChallenge.completionTimeMinutes = Int32(Date().timeIntervalSince(challenge.date) / 60)
        }
        
        updateUserProfile(profile)
        todaysChallenge = challenge
    }
    
    // MARK: - Check-In Management
    func loadTodaysCheckIns() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let request: NSFetchRequest<CDCheckIn> = CDCheckIn.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                      today as NSDate,
                                      calendar.date(byAdding: .day, value: 1, to: today)! as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCheckIn.date, ascending: true)]
        
        let checkIns = coreDataStack.fetch(request)
        todaysCheckIns = checkIns.map { $0.toDomainModel() }
    }
    
    func submitCheckIn(_ checkIn: AICheckIn) {
        guard let userPath = userProfile?.selectedPath else { return }
        
        let cdCheckIn = CDCheckIn(context: coreDataStack.context)
        cdCheckIn.id = UUID()
        cdCheckIn.updateFromDomainModel(checkIn, path: userPath)
        
        coreDataStack.save()
        loadTodaysCheckIns()
    }
    
    func getCheckInsForDateRange(from startDate: Date, to endDate: Date) -> [AICheckIn] {
        let request: NSFetchRequest<CDCheckIn> = CDCheckIn.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@",
                                      startDate as NSDate,
                                      endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCheckIn.date, ascending: false)]
        
        let checkIns = coreDataStack.fetch(request)
        return checkIns.map { $0.toDomainModel() }
    }
    
    // MARK: - Journal Management
    func loadJournalEntries() {
        let request: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDJournalEntry.date, ascending: false)]
        
        let entries = coreDataStack.fetch(request)
        journalEntries = entries.map { $0.toDomainModel() }
    }
    
    func addJournalEntry(_ entry: JournalEntry) {
        let cdEntry = CDJournalEntry(context: coreDataStack.context)
        cdEntry.id = UUID()
        cdEntry.updateFromDomainModel(entry)
        cdEntry.pathContext = userProfile?.selectedPath
        
        coreDataStack.save()
        loadJournalEntries()
    }
    
    func updateJournalEntry(_ entry: JournalEntry) {
        let request: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        if let cdEntry = coreDataStack.fetch(request).first {
            cdEntry.updateFromDomainModel(entry)
            coreDataStack.save()
            loadJournalEntries()
        }
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) {
        let request: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        if let cdEntry = coreDataStack.fetch(request).first {
            coreDataStack.delete(cdEntry)
            loadJournalEntries()
        }
    }
    
    func searchJournalEntries(query: String) -> [JournalEntry] {
        let request: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "content CONTAINS[cd] %@ OR prompt CONTAINS[cd] %@", query, query)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDJournalEntry.date, ascending: false)]
        
        let entries = coreDataStack.fetch(request)
        return entries.map { $0.toDomainModel() }
    }
    
    // MARK: - Book Management
    func loadBookRecommendations() {
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBookRecommendation.dateAdded, ascending: false)]
        
        let books = coreDataStack.fetch(request)
        currentBookRecommendations = books.map { $0.toDomainModel() }
        savedBooks = currentBookRecommendations.filter { $0.isSaved }
    }
    
    func addBookRecommendation(_ book: BookRecommendation) {
        // Check if book already exists
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@ AND author == %@", book.title, book.author)
        
        if coreDataStack.fetch(request).isEmpty {
            let cdBook = CDBookRecommendation(context: coreDataStack.context)
            cdBook.id = UUID()
            cdBook.updateFromDomainModel(book)
            
            coreDataStack.save()
            loadBookRecommendations()
        }
    }
    
    func updateBookStatus(_ book: BookRecommendation, isSaved: Bool? = nil, isRead: Bool? = nil) {
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        if let cdBook = coreDataStack.fetch(request).first {
            if let isSaved = isSaved {
                cdBook.isSaved = isSaved
            }
            if let isRead = isRead {
                cdBook.isRead = isRead
                if isRead {
                    cdBook.dateRead = Date()
                    cdBook.readingProgress = 1.0
                    // Auto-save if marked as read
                    cdBook.isSaved = true
                }
            }
            
            coreDataStack.save()
            loadBookRecommendations()
        }
    }
    
    func addBookNote(_ book: BookRecommendation, note: String) {
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        if let cdBook = coreDataStack.fetch(request).first {
            cdBook.personalNotes = note
            coreDataStack.save()
            loadBookRecommendations()
        }
    }
    
    func rateBook(_ book: BookRecommendation, rating: Int) {
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        if let cdBook = coreDataStack.fetch(request).first {
            cdBook.userRating = Int16(rating)
            coreDataStack.save()
            loadBookRecommendations()
        }
    }
    
    func updateReadingProgress(_ book: BookRecommendation, progress: Float) {
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        if let cdBook = coreDataStack.fetch(request).first {
            cdBook.readingProgress = progress
            
            // Mark as read if progress is 100%
            if progress >= 1.0 {
                cdBook.isRead = true
                cdBook.dateRead = Date()
            }
            
            coreDataStack.save()
            loadBookRecommendations()
        }
    }
    
    func getSavedBooks() -> [BookRecommendation] {
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "isSaved == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBookRecommendation.dateAdded, ascending: false)]
        
        let books = coreDataStack.fetch(request)
        return books.map { $0.toDomainModel() }
    }
    
    func getReadBooks() -> [BookRecommendation] {
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "isRead == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBookRecommendation.dateRead, ascending: false)]
        
        let books = coreDataStack.fetch(request)
        return books.map { $0.toDomainModel() }
    }
    
    func getBooksForPath(_ path: TrainingPath) -> [BookRecommendation] {
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "pathRaw == %@", path.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBookRecommendation.dateAdded, ascending: false)]
        
        let books = coreDataStack.fetch(request)
        return books.map { $0.toDomainModel() }
    }
    
    func searchBooks(query: String) -> [BookRecommendation] {
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR author CONTAINS[cd] %@ OR summary CONTAINS[cd] %@", 
                                      query, query, query)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBookRecommendation.dateAdded, ascending: false)]
        
        let books = coreDataStack.fetch(request)
        return books.map { $0.toDomainModel() }
    }
    
    // MARK: - Book Highlights Management
    func addBookHighlight(bookId: UUID, text: String, note: String? = nil, pageNumber: Int = 0) {
        let bookRequest: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        bookRequest.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
        
        guard let cdBook = coreDataStack.fetch(bookRequest).first else { return }
        
        let highlight = CDBookHighlight(context: coreDataStack.context)
        highlight.id = UUID()
        highlight.text = text
        highlight.note = note
        highlight.pageNumber = Int32(pageNumber)
        highlight.dateCreated = Date()
        highlight.book = cdBook
        
        coreDataStack.save()
    }
    
    func getBookHighlights(for bookId: UUID) -> [CDBookHighlight] {
        let request: NSFetchRequest<CDBookHighlight> = CDBookHighlight.fetchRequest()
        request.predicate = NSPredicate(format: "book.id == %@", bookId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBookHighlight.pageNumber, ascending: true)]
        
        return coreDataStack.fetch(request)
    }
    
    func deleteBookHighlight(_ highlight: CDBookHighlight) {
        coreDataStack.delete(highlight)
    }
    
    // MARK: - Reading Goals Management
    func loadReadingGoals() {
        let request: NSFetchRequest<CDReadingGoal> = CDReadingGoal.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDReadingGoal.endDate, ascending: true)]
        
        readingGoals = coreDataStack.fetch(request)
    }
    
    func createReadingGoal(title: String, targetCount: Int, type: ReadingGoalType, endDate: Date, path: TrainingPath? = nil) {
        let goal = CDReadingGoal(context: coreDataStack.context)
        goal.id = UUID()
        goal.title = title
        goal.targetCount = Int32(targetCount)
        goal.currentCount = 0
        goal.type = type
        goal.startDate = Date()
        goal.endDate = endDate
        goal.isCompleted = false
        goal.targetPath = path
        
        coreDataStack.save()
        loadReadingGoals()
    }
    
    func updateReadingGoalProgress(_ goal: CDReadingGoal, increment: Int = 1) {
        goal.currentCount += Int32(increment)
        
        if goal.currentCount >= goal.targetCount {
            goal.isCompleted = true
        }
        
        coreDataStack.save()
        loadReadingGoals()
    }
    
    func deleteReadingGoal(_ goal: CDReadingGoal) {
        coreDataStack.delete(goal)
        loadReadingGoals()
    }
    
    // MARK: - Reading Session Management
    func loadCurrentReadingSession() {
        let request: NSFetchRequest<CDReadingSession> = CDReadingSession.fetchRequest()
        request.predicate = NSPredicate(format: "endTime == nil")
        request.fetchLimit = 1
        
        currentReadingSession = coreDataStack.fetch(request).first
    }
    
    func startReadingSession(for bookId: UUID) {
        // End any existing session
        endCurrentReadingSession()
        
        let bookRequest: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        bookRequest.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
        
        guard let cdBook = coreDataStack.fetch(bookRequest).first else { return }
        
        let session = CDReadingSession(context: coreDataStack.context)
        session.id = UUID()
        session.startTime = Date()
        session.book = cdBook
        session.pagesRead = 0
        
        coreDataStack.save()
        currentReadingSession = session
    }
    
    func endCurrentReadingSession(pagesRead: Int = 0, notes: String? = nil) {
        guard let session = currentReadingSession else { return }
        
        session.endTime = Date()
        session.durationMinutes = Int32(session.endTime!.timeIntervalSince(session.startTime) / 60)
        session.pagesRead = Int32(pagesRead)
        session.notes = notes
        
        // Update book reading time
        if let book = session.book {
            book.timeSpentReading += session.durationMinutes
        }
        
        coreDataStack.save()
        currentReadingSession = nil
    }
    
    func getReadingSessions(for bookId: UUID) -> [CDReadingSession] {
        let request: NSFetchRequest<CDReadingSession> = CDReadingSession.fetchRequest()
        request.predicate = NSPredicate(format: "book.id == %@ AND endTime != nil", bookId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDReadingSession.startTime, ascending: false)]
        
        return coreDataStack.fetch(request)
    }
    
    // MARK: - Analytics and Insights
    func getReadingStats(for period: StatsPeriod = .thisMonth) -> ReadingStats {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch period {
        case .thisWeek:
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .thisMonth:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .thisYear:
            startDate = calendar.dateInterval(of: .year, for: now)?.start ?? now
        case .allTime:
            startDate = Date.distantPast
        }
        
        // Books read in period
        let booksRequest: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        booksRequest.predicate = NSPredicate(format: "isRead == YES AND dateRead >= %@", startDate as NSDate)
        let booksRead = coreDataStack.fetch(booksRequest).count
        
        // Reading time in period
        let sessionsRequest: NSFetchRequest<CDReadingSession> = CDReadingSession.fetchRequest()
        sessionsRequest.predicate = NSPredicate(format: "startTime >= %@ AND endTime != nil", startDate as NSDate)
        let sessions = coreDataStack.fetch(sessionsRequest)
        let totalMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }
        
        // Journal entries in period
        let journalRequest: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
        journalRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        let journalEntries = coreDataStack.fetch(journalRequest).count
        
        // Check-ins in period
        let checkInRequest: NSFetchRequest<CDCheckIn> = CDCheckIn.fetchRequest()
        checkInRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        let checkIns = coreDataStack.fetch(checkInRequest).count
        
        // Challenges completed in period
        let challengeRequest: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        challengeRequest.predicate = NSPredicate(format: "isCompleted == YES AND completedAt >= %@", startDate as NSDate)
        let challengesCompleted = coreDataStack.fetch(challengeRequest).count
        
        return ReadingStats(
            booksRead: booksRead,
            totalReadingMinutes: Int(totalMinutes),
            journalEntries: journalEntries,
            checkIns: checkIns,
            challengesCompleted: challengesCompleted,
            period: period
        )
    }
    
    func getMoodTrends(for days: Int = 30) -> [MoodDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
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
    
    func getStreakData() -> StreakData {
        guard let profile = userProfile else {
            return StreakData(currentStreak: 0, longestStreak: 0, streakHistory: [])
        }
        
        // Get challenge completion history for streak calculation
        let request: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDailyChallenge.date, ascending: true)]
        
        let completedChallenges = coreDataStack.fetch(request)
        let streakHistory = completedChallenges.map { StreakDataPoint(date: $0.date, completed: true) }
        
        return StreakData(
            currentStreak: profile.currentStreak,
            longestStreak: profile.longestStreak,
            streakHistory: streakHistory
        )
    }
    
    // MARK: - Content Generation
    private func generateTodaysContent() {
        guard let userProfile = userProfile else { return }
        generateTodaysChallenge()
        generateBookRecommendations(for: userProfile.selectedPath)
    }
    
    private func generateBookRecommendations(for path: TrainingPath) {
        let newBooks = BookGenerator.generateRecommendations(for: path, count: 5)
        
        // Add books that don't already exist
        for book in newBooks {
            addBookRecommendation(book)
        }
    }
    
    // MARK: - Data Export
    func exportUserData() -> UserDataExport? {
        guard let profile = userProfile else { return nil }
        
        let books = getSavedBooks()
        let entries = journalEntries
        let checkIns = getCheckInsForDateRange(from: Date.distantPast, to: Date())
        let stats = getReadingStats(for: .allTime)
        
        return UserDataExport(
            userProfile: profile,
            books: books,
            journalEntries: entries,
            checkIns: checkIns,
            readingStats: stats,
            exportDate: Date()
        )
    }
    
    // MARK: - Data Cleanup
    func cleanupOldData() {
        coreDataStack.performBackgroundTask { context in
            let calendar = Calendar.current
            let cutoffDate = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            
            // Delete old uncompleted challenges
            let challengeRequest: NSFetchRequest<NSFetchRequestResult> = CDDailyChallenge.fetchRequest()
            challengeRequest.predicate = NSPredicate(format: "isCompleted == NO AND date < %@", cutoffDate as NSDate)
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: challengeRequest)
            try? context.execute(deleteRequest)
            
            // Delete old check-ins (keep last 30 days)
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let checkInRequest: NSFetchRequest<NSFetchRequestResult> = CDCheckIn.fetchRequest()
            checkInRequest.predicate = NSPredicate(format: "date < %@", thirtyDaysAgo as NSDate)
            
            let deleteCheckInRequest = NSBatchDeleteRequest(fetchRequest: checkInRequest)
            try? context.execute(deleteCheckInRequest)
            
            try? context.save()
        }
    }
}

// MARK: - Supporting Models
enum StatsPeriod: String, CaseIterable {
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
}

struct ReadingStats {
    let booksRead: Int
    let totalReadingMinutes: Int
    let journalEntries: Int
    let checkIns: Int
    let challengesCompleted: Int
    let period: StatsPeriod
    
    var totalReadingHours: Double {
        return Double(totalReadingMinutes) / 60.0
    }
    
    var averageReadingMinutesPerDay: Double {
        let days: Double
        switch period {
        case .thisWeek: days = 7
        case .thisMonth: days = 30
        case .thisYear: days = 365
        case .allTime: days = max(1, Double(Date().timeIntervalSince(Date.distantPast)) / 86400)
        }
        return Double(totalReadingMinutes) / days
    }
}

struct MoodDataPoint {
    let date: Date
    let averageMood: Double
}

struct StreakDataPoint {
    let date: Date
    let completed: Bool
}

struct StreakData {
    let currentStreak: Int
    let longestStreak: Int
    let streakHistory: [StreakDataPoint]
}

struct UserDataExport: Codable {
    let userProfile: UserProfile
    let books: [BookRecommendation]
    let journalEntries: [JournalEntry]
    let checkIns: [AICheckIn]
    let readingStats: ReadingStats
    let exportDate: Date
}

extension ReadingStats: Codable {}
extension MoodDataPoint: Codable {}
extension StreakDataPoint: Codable {}
extension StreakData: Codable {}