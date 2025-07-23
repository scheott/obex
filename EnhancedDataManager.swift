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
        let request: NSFetchRequest