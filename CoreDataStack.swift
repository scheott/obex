import CoreData
import Foundation

// MARK: - Core Data Stack
class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MentorApp")
        
        // Configure for CloudKit if needed
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Background Context Operations
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    // MARK: - Fetch Operations
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T] {
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    // MARK: - Delete Operations
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
    
    func deleteAll<T: NSManagedObject>(_ type: T.Type) {
        let request: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            save()
        } catch {
            print("Delete all error: \(error)")
        }
    }
}

// MARK: - Core Data Model Extensions

// MARK: - UserProfile Core Data Model
@objc(CDUserProfile)
public class CDUserProfile: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUserProfile> {
        return NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var selectedPathRaw: String
    @NSManaged public var joinDate: Date
    @NSManaged public var currentStreak: Int32
    @NSManaged public var longestStreak: Int32
    @NSManaged public var totalChallengesCompleted: Int32
    @NSManaged public var subscriptionTierRaw: String
    @NSManaged public var streakBankDays: Int32
    @NSManaged public var lastActiveDate: Date?
    
    // Computed properties
    var selectedPath: TrainingPath {
        get { TrainingPath(rawValue: selectedPathRaw) ?? .discipline }
        set { selectedPathRaw = newValue.rawValue }
    }
    
    var subscriptionTier: SubscriptionTier {
        get { SubscriptionTier(rawValue: subscriptionTierRaw) ?? .free }
        set { subscriptionTierRaw = newValue.rawValue }
    }
    
    // Convert to domain model
    func toDomainModel() -> UserProfile {
        var profile = UserProfile(selectedPath: selectedPath)
        profile.joinDate = joinDate
        profile.currentStreak = Int(currentStreak)
        profile.longestStreak = Int(longestStreak)
        profile.totalChallengesCompleted = Int(totalChallengesCompleted)
        profile.subscriptionTier = subscriptionTier
        profile.streakBankDays = Int(streakBankDays)
        return profile
    }
    
    // Update from domain model
    func updateFromDomainModel(_ profile: UserProfile) {
        selectedPath = profile.selectedPath
        joinDate = profile.joinDate
        currentStreak = Int32(profile.currentStreak)
        longestStreak = Int32(profile.longestStreak)
        totalChallengesCompleted = Int32(profile.totalChallengesCompleted)
        subscriptionTier = profile.subscriptionTier
        streakBankDays = Int32(profile.streakBankDays)
        lastActiveDate = Date()
    }
}

// MARK: - BookRecommendation Core Data Model
@objc(CDBookRecommendation)
public class CDBookRecommendation: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBookRecommendation> {
        return NSFetchRequest<CDBookRecommendation>(entityName: "CDBookRecommendation")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var author: String
    @NSManaged public var pathRaw: String
    @NSManaged public var summary: String
    @NSManaged public var keyInsight: String
    @NSManaged public var dailyAction: String
    @NSManaged public var coverImageURL: String?
    @NSManaged public var amazonURL: String?
    @NSManaged public var dateAdded: Date
    @NSManaged public var isSaved: Bool
    @NSManaged public var isRead: Bool
    @NSManaged public var dateRead: Date?
    @NSManaged public var userRating: Int16
    @NSManaged public var personalNotes: String?
    @NSManaged public var readingProgress: Float
    @NSManaged public var timeSpentReading: Int32 // in minutes
    @NSManaged public var highlights: NSSet?
    
    var path: TrainingPath {
        get { TrainingPath(rawValue: pathRaw) ?? .discipline }
        set { pathRaw = newValue.rawValue }
    }
    
    // Convert to domain model
    func toDomainModel() -> BookRecommendation {
        var book = BookRecommendation(
            title: title,
            author: author,
            path: path,
            summary: summary,
            keyInsight: keyInsight,
            dailyAction: dailyAction,
            coverImageURL: coverImageURL,
            amazonURL: amazonURL,
            dateAdded: dateAdded
        )
        book.isSaved = isSaved
        book.isRead = isRead
        return book
    }
    
    // Update from domain model
    func updateFromDomainModel(_ book: BookRecommendation) {
        title = book.title
        author = book.author
        path = book.path
        summary = book.summary
        keyInsight = book.keyInsight
        dailyAction = book.dailyAction
        coverImageURL = book.coverImageURL
        amazonURL = book.amazonURL
        dateAdded = book.dateAdded
        isSaved = book.isSaved
        isRead = book.isRead
        
        if isRead && dateRead == nil {
            dateRead = Date()
        }
    }
}

// MARK: - BookHighlight Core Data Model
@objc(CDBookHighlight)
public class CDBookHighlight: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBookHighlight> {
        return NSFetchRequest<CDBookHighlight>(entityName: "CDBookHighlight")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var text: String
    @NSManaged public var note: String?
    @NSManaged public var pageNumber: Int32
    @NSManaged public var dateCreated: Date
    @NSManaged public var book: CDBookRecommendation?
}

// MARK: - JournalEntry Core Data Model
@objc(CDJournalEntry)
public class CDJournalEntry: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDJournalEntry> {
        return NSFetchRequest<CDJournalEntry>(entityName: "CDJournalEntry")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var content: String
    @NSManaged public var prompt: String?
    @NSManaged public var moodRaw: String?
    @NSManaged public var tagsData: Data?
    @NSManaged public var isSavedToSelf: Bool
    @NSManaged public var isMarkedForReread: Bool
    @NSManaged public var wordCount: Int32
    @NSManaged public var pathRaw: String?
    
    var mood: AICheckIn.MoodRating? {
        get {
            guard let moodRaw = moodRaw else { return nil }
            return AICheckIn.MoodRating(rawValue: moodRaw)
        }
        set { moodRaw = newValue?.rawValue }
    }
    
    var tags: [String] {
        get {
            guard let tagsData = tagsData,
                  let tags = try? JSONDecoder().decode([String].self, from: tagsData) else { return [] }
            return tags
        }
        set {
            tagsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var pathContext: TrainingPath? {
        get {
            guard let pathRaw = pathRaw else { return nil }
            return TrainingPath(rawValue: pathRaw)
        }
        set { pathRaw = newValue?.rawValue }
    }
    
    // Convert to domain model
    func toDomainModel() -> JournalEntry {
        var entry = JournalEntry(
            date: date,
            content: content,
            prompt: prompt,
            mood: mood,
            tags: tags
        )
        entry.isSavedToSelf = isSavedToSelf
        entry.isMarkedForReread = isMarkedForReread
        return entry
    }
    
    // Update from domain model
    func updateFromDomainModel(_ entry: JournalEntry) {
        date = entry.date
        content = entry.content
        prompt = entry.prompt
        mood = entry.mood
        tags = entry.tags
        isSavedToSelf = entry.isSavedToSelf
        isMarkedForReread = entry.isMarkedForReread
        wordCount = Int32(entry.content.components(separatedBy: .whitespacesAndNewlines).count)
    }
}

// MARK: - DailyChallenge Core Data Model
@objc(CDDailyChallenge)
public class CDDailyChallenge: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDailyChallenge> {
        return NSFetchRequest<CDDailyChallenge>(entityName: "CDDailyChallenge")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var challengeDescription: String
    @NSManaged public var pathRaw: String
    @NSManaged public var difficultyRaw: String
    @NSManaged public var date: Date
    @NSManaged public var isCompleted: Bool
    @NSManaged public var completedAt: Date?
    @NSManaged public var completionTimeMinutes: Int32
    @NSManaged public var userNotes: String?
    @NSManaged public var effortLevel: Int16
    
    var path: TrainingPath {
        get { TrainingPath(rawValue: pathRaw) ?? .discipline }
        set { pathRaw = newValue.rawValue }
    }
    
    var difficulty: DailyChallenge.ChallengeDifficulty {
        get { DailyChallenge.ChallengeDifficulty(rawValue: difficultyRaw) ?? .micro }
        set { difficultyRaw = newValue.rawValue }
    }
    
    // Convert to domain model
    func toDomainModel() -> DailyChallenge {
        var challenge = DailyChallenge(
            title: title,
            description: challengeDescription,
            path: path,
            difficulty: difficulty,
            date: date
        )
        challenge.isCompleted = isCompleted
        challenge.completedAt = completedAt
        return challenge
    }
    
    // Update from domain model
    func updateFromDomainModel(_ challenge: DailyChallenge) {
        title = challenge.title
        challengeDescription = challenge.description
        path = challenge.path
        difficulty = challenge.difficulty
        date = challenge.date
        isCompleted = challenge.isCompleted
        completedAt = challenge.completedAt
    }
}

// MARK: - CheckIn Core Data Model
@objc(CDCheckIn)
public class CDCheckIn: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCheckIn> {
        return NSFetchRequest<CDCheckIn>(entityName: "CDCheckIn")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var timeOfDayRaw: String
    @NSManaged public var prompt: String
    @NSManaged public var userResponse: String?
    @NSManaged public var aiResponse: String?
    @NSManaged public var moodRaw: String?
    @NSManaged public var effortLevel: Int16
    @NSManaged public var pathRaw: String
    
    var timeOfDay: AICheckIn.CheckInTime {
        get { AICheckIn.CheckInTime(rawValue: timeOfDayRaw) ?? .morning }
        set { timeOfDayRaw = newValue.rawValue }
    }
    
    var mood: AICheckIn.MoodRating? {
        get {
            guard let moodRaw = moodRaw else { return nil }
            return AICheckIn.MoodRating(rawValue: moodRaw)
        }
        set { moodRaw = newValue?.rawValue }
    }
    
    var path: TrainingPath {
        get { TrainingPath(rawValue: pathRaw) ?? .discipline }
        set { pathRaw = newValue.rawValue }
    }
    
    // Convert to domain model
    func toDomainModel() -> AICheckIn {
        var checkIn = AICheckIn(
            date: date,
            timeOfDay: timeOfDay,
            prompt: prompt
        )
        checkIn.userResponse = userResponse
        checkIn.aiResponse = aiResponse
        checkIn.mood = mood
        checkIn.effortLevel = effortLevel > 0 ? Int(effortLevel) : nil
        return checkIn
    }
    
    // Update from domain model
    func updateFromDomainModel(_ checkIn: AICheckIn, path: TrainingPath) {
        date = checkIn.date
        timeOfDay = checkIn.timeOfDay
        prompt = checkIn.prompt
        userResponse = checkIn.userResponse
        aiResponse = checkIn.aiResponse
        mood = checkIn.mood
        effortLevel = Int16(checkIn.effortLevel ?? 0)
        self.path = path
    }
}

// MARK: - Reading Goal Core Data Model
@objc(CDReadingGoal)
public class CDReadingGoal: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDReadingGoal> {
        return NSFetchRequest<CDReadingGoal>(entityName: "CDReadingGoal")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var targetCount: Int32
    @NSManaged public var currentCount: Int32
    @NSManaged public var typeRaw: String
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var isCompleted: Bool
    @NSManaged public var pathRaw: String?
    
    var type: ReadingGoalType {
        get { ReadingGoalType(rawValue: typeRaw) ?? .booksPerMonth }
        set { typeRaw = newValue.rawValue }
    }
    
    var targetPath: TrainingPath? {
        get {
            guard let pathRaw = pathRaw else { return nil }
            return TrainingPath(rawValue: pathRaw)
        }
        set { pathRaw = newValue?.rawValue }
    }
    
    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(1.0, Double(currentCount) / Double(targetCount))
    }
}

enum ReadingGoalType: String, CaseIterable {
    case booksPerMonth = "books_per_month"
    case booksPerYear = "books_per_year"
    case pagesPerDay = "pages_per_day"
    case minutesPerDay = "minutes_per_day"
    case diversityGoal = "diversity_goal"
    
    var displayName: String {
        switch self {
        case .booksPerMonth: return "Books per Month"
        case .booksPerYear: return "Books per Year"
        case .pagesPerDay: return "Pages per Day"
        case .minutesPerDay: return "Minutes per Day"
        case .diversityGoal: return "Diversity Goal"
        }
    }
}

// MARK: - Reading Session Core Data Model
@objc(CDReadingSession)
public class CDReadingSession: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDReadingSession> {
        return NSFetchRequest<CDReadingSession>(entityName: "CDReadingSession")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date?
    @NSManaged public var durationMinutes: Int32
    @NSManaged public var pagesRead: Int32
    @NSManaged public var notes: String?
    @NSManaged public var book: CDBookRecommendation?
    
    var isActive: Bool {
        return endTime == nil
    }
}
