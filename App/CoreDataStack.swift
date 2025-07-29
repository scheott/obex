import Foundation
import CoreData
import Combine

// MARK: - Core Data Stack Manager
class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    // Published properties for reactive UI updates
    @Published var isInitialized = false
    @Published var hasError = false
    @Published var errorMessage: String?
    
    private init() {
        setupCoreData()
    }
    
    // MARK: - Core Data Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MentorApp")
        
        // Configure for performance
        let description = container.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        description?.type = NSSQLiteStoreType
        
        // Enable history tracking for CloudKit (if needed)
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                print("Core Data error: \(error)")
                DispatchQueue.main.async {
                    self?.hasError = true
                    self?.errorMessage = error.localizedDescription
                }
            } else {
                DispatchQueue.main.async {
                    self?.isInitialized = true
                }
            }
        }
        
        // Configure context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    // MARK: - Context Access
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Save Operations
    func save() {
        let context = persistentContainer.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Save error: \(error)")
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "Failed to save data: \(error.localizedDescription)"
            }
        }
    }
    
    func saveBackground(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Background save error: \(error)")
        }
    }
    
    // MARK: - Background Operations
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            block(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Background task save error: \(error)")
                }
            }
        }
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
    
    func fetchFirst<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> T? {
        request.fetchLimit = 1
        return fetch(request).first
    }
    
    func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> Int {
        do {
            return try context.count(for: request)
        } catch {
            print("Count error: \(error)")
            return 0
        }
    }
    
    // MARK: - Delete Operations
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
    
    func batchDelete<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) {
        let request: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
        request.predicate = predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID]
            let changes = [NSDeletedObjectsKey: objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes as [AnyHashable : Any], into: [context])
        } catch {
            print("Batch delete error: \(error)")
        }
    }
    
    // MARK: - Setup
    private func setupCoreData() {
        // Trigger lazy initialization
        _ = persistentContainer
    }
}

// MARK: - Core Data Model Extensions

// MARK: - CDUserProfile Extension
@objc(CDUserProfile)
public class CDUserProfile: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUserProfile> {
        return NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
    }
    
    // Core Data Attributes
    @NSManaged public var id: UUID
    @NSManaged public var selectedPathRaw: String
    @NSManaged public var joinDate: Date
    @NSManaged public var currentStreak: Int32
    @NSManaged public var longestStreak: Int32
    @NSManaged public var totalChallengesCompleted: Int32
    @NSManaged public var subscriptionTierRaw: String
    @NSManaged public var streakBankDays: Int32
    @NSManaged public var lastActiveDate: Date?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var bio: String?
    @NSManaged public var profileImageURL: String?
    
    // Computed Properties
    var selectedPath: TrainingPath {
        get { TrainingPath(rawValue: selectedPathRaw) ?? .discipline }
        set { selectedPathRaw = newValue.rawValue }
    }
    
    var subscriptionTier: SubscriptionTier {
        get { SubscriptionTier(rawValue: subscriptionTierRaw) ?? .free }
        set { subscriptionTierRaw = newValue.rawValue }
    }
    
    var displayName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        } else if let firstName = firstName {
            return firstName
        }
        return "User"
    }
    
    // Domain Model Conversion
    func toDomainModel() -> UserProfile {
        var profile = UserProfile(selectedPath: selectedPath)
        profile.id = id
        profile.joinDate = joinDate
        profile.currentStreak = Int(currentStreak)
        profile.longestStreak = Int(longestStreak)
        profile.totalChallengesCompleted = Int(totalChallengesCompleted)
        profile.subscriptionTier = subscriptionTier
        profile.streakBankDays = Int(streakBankDays)
        profile.firstName = firstName
        profile.lastName = lastName
        profile.bio = bio
        profile.profileImageURL = profileImageURL
        return profile
    }
    
    func updateFromDomainModel(_ profile: UserProfile) {
        id = profile.id
        selectedPath = profile.selectedPath
        joinDate = profile.joinDate
        currentStreak = Int32(profile.currentStreak)
        longestStreak = Int32(profile.longestStreak)
        totalChallengesCompleted = Int32(profile.totalChallengesCompleted)
        subscriptionTier = profile.subscriptionTier
        streakBankDays = Int32(profile.streakBankDays)
        firstName = profile.firstName
        lastName = profile.lastName
        bio = profile.bio
        profileImageURL = profile.profileImageURL
        lastActiveDate = Date()
    }
    
    // Streak Management
    func incrementStreak() {
        currentStreak += 1
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        lastActiveDate = Date()
    }
    
    func resetStreak() {
        currentStreak = 0
        lastActiveDate = Date()
    }
    
    func useStreakBank() -> Bool {
        guard streakBankDays > 0 else { return false }
        streakBankDays -= 1
        lastActiveDate = Date()
        return true
    }
}

// MARK: - CDDailyChallenge Extension
@objc(CDDailyChallenge)
public class CDDailyChallenge: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDailyChallenge> {
        return NSFetchRequest<CDDailyChallenge>(entityName: "CDDailyChallenge")
    }
    
    // Core Data Attributes
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
    @NSManaged public var isSkipped: Bool
    @NSManaged public var skipReason: String?
    
    // Computed Properties
    var path: TrainingPath {
        get { TrainingPath(rawValue: pathRaw) ?? .discipline }
        set { pathRaw = newValue.rawValue }
    }
    
    var difficulty: DailyChallenge.ChallengeDifficulty {
        get { DailyChallenge.ChallengeDifficulty(rawValue: difficultyRaw) ?? .micro }
        set { difficultyRaw = newValue.rawValue }
    }
    
    var status: ChallengeStatus {
        if isCompleted {
            return .completed
        } else if isSkipped {
            return .skipped
        } else if Calendar.current.isDateInToday(date) {
            return .active
        } else if date < Date() {
            return .missed
        } else {
            return .upcoming
        }
    }
    
    // Domain Model Conversion
    func toDomainModel() -> DailyChallenge {
        var challenge = DailyChallenge(
            title: title,
            description: challengeDescription,
            path: path,
            difficulty: difficulty,
            date: date
        )
        challenge.id = id
        challenge.isCompleted = isCompleted
        challenge.completedAt = completedAt
        challenge.userNotes = userNotes
        challenge.effortLevel = Int(effortLevel)
        return challenge
    }
    
    func updateFromDomainModel(_ challenge: DailyChallenge) {
        id = challenge.id
        title = challenge.title
        challengeDescription = challenge.description
        path = challenge.path
        difficulty = challenge.difficulty
        date = challenge.date
        isCompleted = challenge.isCompleted
        completedAt = challenge.completedAt
        userNotes = challenge.userNotes
        effortLevel = Int16(challenge.effortLevel ?? 0)
    }
    
    // Challenge Actions
    func markCompleted(effortLevel: Int = 3, notes: String? = nil) {
        isCompleted = true
        completedAt = Date()
        self.effortLevel = Int16(effortLevel)
        userNotes = notes
        isSkipped = false
        skipReason = nil
    }
    
    func markSkipped(reason: String? = nil) {
        isSkipped = true
        skipReason = reason
        isCompleted = false
        completedAt = nil
    }
}

// MARK: - Challenge Status Enum
enum ChallengeStatus: String, CaseIterable {
    case upcoming = "upcoming"
    case active = "active"
    case completed = "completed"
    case skipped = "skipped"
    case missed = "missed"
    
    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .active: return "Active"
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        case .missed: return "Missed"
        }
    }
    
    var color: Color {
        switch self {
        case .upcoming: return .secondary
        case .active: return .blue
        case .completed: return .green
        case .skipped: return .orange
        case .missed: return .red
        }
    }
}

// MARK: - CDJournalEntry Extension
@objc(CDJournalEntry)
public class CDJournalEntry: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDJournalEntry> {
        return NSFetchRequest<CDJournalEntry>(entityName: "CDJournalEntry")
    }
    
    // Core Data Attributes
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
    @NSManaged public var entryTypeRaw: String?
    @NSManaged public var isPrivate: Bool
    @NSManaged public var lastEditedDate: Date?
    
    // Computed Properties
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
    
    var entryType: JournalEntryType {
        get {
            guard let entryTypeRaw = entryTypeRaw else { return .reflection }
            return JournalEntryType(rawValue: entryTypeRaw) ?? .reflection
        }
        set { entryTypeRaw = newValue.rawValue }
    }
    
    var readingTime: Int {
        // Estimate reading time (average 200 words per minute)
        return max(1, Int(wordCount) / 200)
    }
    
    // Domain Model Conversion
    func toDomainModel() -> JournalEntry {
        var entry = JournalEntry(
            date: date,
            content: content,
            prompt: prompt,
            mood: mood,
            tags: tags
        )
        entry.id = id
        entry.isSavedToSelf = isSavedToSelf
        entry.isMarkedForReread = isMarkedForReread
        entry.pathContext = pathContext
        entry.entryType = entryType
        entry.isPrivate = isPrivate
        return entry
    }
    
    func updateFromDomainModel(_ entry: JournalEntry) {
        id = entry.id
        date = entry.date
        content = entry.content
        prompt = entry.prompt
        mood = entry.mood
        tags = entry.tags
        isSavedToSelf = entry.isSavedToSelf
        isMarkedForReread = entry.isMarkedForReread
        pathContext = entry.pathContext
        entryType = entry.entryType
        isPrivate = entry.isPrivate
        
        // Update computed fields
        wordCount = Int32(content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)
        lastEditedDate = Date()
    }
}

// MARK: - Journal Entry Type Enum
enum JournalEntryType: String, CaseIterable {
    case reflection = "reflection"
    case gratitude = "gratitude"
    case goal = "goal"
    case challenge = "challenge"
    case insight = "insight"
    case progress = "progress"
    
    var displayName: String {
        switch self {
        case .reflection: return "Reflection"
        case .gratitude: return "Gratitude"
        case .goal: return "Goal"
        case .challenge: return "Challenge"
        case .insight: return "Insight"
        case .progress: return "Progress"
        }
    }
    
    var icon: String {
        switch self {
        case .reflection: return "bubble.left.and.bubble.right"
        case .gratitude: return "heart"
        case .goal: return "target"
        case .challenge: return "mountain.2"
        case .insight: return "lightbulb"
        case .progress: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - CDBookRecommendation Extension
@objc(CDBookRecommendation)
public class CDBookRecommendation: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBookRecommendation> {
        return NSFetchRequest<CDBookRecommendation>(entityName: "CDBookRecommendation")
    }
    
    // Core Data Attributes
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
    @NSManaged public var timeSpentReading: Int32
    @NSManaged public var priorityLevel: Int16
    @NSManaged public var readingGoalId: UUID?
    
    // Relationships
    @NSManaged public var highlights: NSSet?
    @NSManaged public var readingSessions: NSSet?
    
    // Computed Properties
    var path: TrainingPath {
        get { TrainingPath(rawValue: pathRaw) ?? .discipline }
        set { pathRaw = newValue.rawValue }
    }
    
    var rating: BookRating {
        get { BookRating(rawValue: Int(userRating)) ?? .unrated }
        set { userRating = Int16(newValue.rawValue) }
    }
    
    var readingProgressPercentage: Int {
        return Int(readingProgress * 100)
    }
    
    var isCurrentlyReading: Bool {
        return readingProgress > 0 && readingProgress < 1.0
    }
    
    // Domain Model Conversion
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
        book.id = id
        book.isSaved = isSaved
        book.isRead = isRead
        book.dateRead = dateRead
        book.personalNotes = personalNotes
        book.readingProgress = readingProgress
        return book
    }
    
    func updateFromDomainModel(_ book: BookRecommendation) {
        id = book.id
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
        dateRead = book.dateRead
        personalNotes = book.personalNotes
        readingProgress = book.readingProgress
        
        // Auto-set read date if marking as complete
        if isRead && dateRead == nil {
            dateRead = Date()
            readingProgress = 1.0
        }
    }
    
    // Book Actions
    func markAsRead() {
        isRead = true
        dateRead = Date()
        readingProgress = 1.0
        isSaved = true // Auto-save when marked as read
    }
    
    func updateProgress(_ progress: Float) {
        readingProgress = min(max(progress, 0.0), 1.0)
        if readingProgress >= 1.0 && !isRead {
            markAsRead()
        }
    }
}

// MARK: - Book Rating Enum
enum BookRating: Int, CaseIterable {
    case unrated = 0
    case poor = 1
    case fair = 2
    case good = 3
    case veryGood = 4
    case excellent = 5
    
    var displayName: String {
        switch self {
        case .unrated: return "Not Rated"
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .veryGood: return "Very Good"
        case .excellent: return "Excellent"
        }
    }
    
    var starCount: Int {
        return rawValue
    }
}

// MARK: - CDBookHighlight Extension
@objc(CDBookHighlight)
public class CDBookHighlight: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBookHighlight> {
        return NSFetchRequest<CDBookHighlight>(entityName: "CDBookHighlight")
    }
    
    // Core Data Attributes
    @NSManaged public var id: UUID
    @NSManaged public var text: String
    @NSManaged public var note: String?
    @NSManaged public var pageNumber: Int32
    @NSManaged public var dateCreated: Date
    @NSManaged public var colorHex: String?
    @NSManaged public var isPublic: Bool
    @NSManaged public var taggedTopics: String?
    
    // Relationships
    @NSManaged public var book: CDBookRecommendation?
    
    // Computed Properties
    var highlightColor: Color {
        guard let colorHex = colorHex else { return .yellow }
        return Color(hex: colorHex) ?? .yellow
    }
    
    var topics: [String] {
        get {
            guard let taggedTopics = taggedTopics else { return [] }
            return taggedTopics.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            taggedTopics = newValue.joined(separator: ", ")
        }
    }
    
    // Domain Model Conversion
    func toDomainModel() -> BookHighlight {
        return BookHighlight(
            id: id,
            text: text,
            note: note,
            pageNumber: Int(pageNumber),
            dateCreated: dateCreated,
            bookTitle: book?.title ?? "",
            colorHex: colorHex,
            topics: topics
        )
    }
}

// MARK: - CDCheckIn Extension (Additional Check-in Model)
@objc(CDCheckIn)
public class CDCheckIn: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCheckIn> {
        return NSFetchRequest<CDCheckIn>(entityName: "CDCheckIn")
    }
    
    // Core Data Attributes
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var timeOfDayRaw: String
    @NSManaged public var prompt: String
    @NSManaged public var userResponse: String?
    @NSManaged public var aiResponse: String?
    @NSManaged public var moodRaw: String?
    @NSManaged public var effortLevel: Int16
    @NSManaged public var pathRaw: String
    @NSManaged public var duration: Int32
    @NSManaged public var isCompleted: Bool
    
    // Computed Properties
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
    
    // Domain Model Conversion
    func toDomainModel() -> AICheckIn {
        var checkIn = AICheckIn(
            date: date,
            timeOfDay: timeOfDay,
            prompt: prompt
        )
        checkIn.id = id
        checkIn.userResponse = userResponse
        checkIn.aiResponse = aiResponse
        checkIn.mood = mood
        checkIn.effortLevel = Int(effortLevel)
        return checkIn
    }
    
    func updateFromDomainModel(_ checkIn: AICheckIn) {
        id = checkIn.id
        date = checkIn.date
        timeOfDay = checkIn.timeOfDay
        prompt = checkIn.prompt
        userResponse = checkIn.userResponse
        aiResponse = checkIn.aiResponse
        mood = checkIn.mood
        effortLevel = Int16(checkIn.effortLevel ?? 0)
        isCompleted = checkIn.userResponse != nil
    }
}
