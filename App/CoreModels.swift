import Foundation
import SwiftUI

// MARK: - Training Path Enum
enum TrainingPath: String, Codable, CaseIterable {
    case discipline = "discipline"
    case clarity = "clarity" 
    case confidence = "confidence"
    case purpose = "purpose"
    case authenticity = "authenticity"
    
    var displayName: String {
        switch self {
        case .discipline: return "Discipline"
        case .clarity: return "Clarity"
        case .confidence: return "Confidence"
        case .purpose: return "Purpose"
        case .authenticity: return "Authenticity"
        }
    }
    
    var icon: String {
        switch self {
        case .discipline: return "target"
        case .clarity: return "brain.head.profile"
        case .confidence: return "person.fill.questionmark"
        case .purpose: return "compass"
        case .authenticity: return "heart"
        }
    }
    
    var color: Color {
        switch self {
        case .discipline: return .red
        case .clarity: return .blue
        case .confidence: return .orange
        case .purpose: return .purple
        case .authenticity: return .green
        }
    }
    
    var description: String {
        switch self {
        case .discipline:
            return "Build consistency, willpower, and unbreakable routines"
        case .clarity:
            return "Develop mindfulness, emotional regulation, and focus"
        case .confidence:
            return "Cultivate social leadership, voice, and inner courage"
        case .purpose:
            return "Discover values, long-term thinking, and direction"
        case .authenticity:
            return "Embrace vulnerability, truth, and genuine self-expression"
        }
    }
    
    var focusAreas: [String] {
        switch self {
        case .discipline:
            return ["Consistency", "Willpower", "Routines", "Delayed Gratification"]
        case .clarity:
            return ["Mindfulness", "Emotional Regulation", "Focus", "Meditation"]
        case .confidence:
            return ["Social Skills", "Leadership", "Public Speaking", "Self-Advocacy"]
        case .purpose:
            return ["Values", "Vision", "Legacy", "Meaning"]
        case .authenticity:
            return ["Vulnerability", "Truth", "Self-Expression", "Integrity"]
        }
    }
}

// MARK: - Subscription Tier Enum
enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .premium: return "Premium"
        }
    }
    
    var monthlyPrice: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$6.99/month"
        case .premium: return "$12.99/month"
        }
    }
    
    var yearlyPrice: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$49/year"
        case .premium: return "$99/year"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "1 training path",
                "3 challenges per week",
                "Basic AI check-ins",
                "Limited book recommendations"
            ]
        case .pro:
            return [
                "All training paths",
                "Unlimited daily challenges",
                "Full AI coaching",
                "Complete book library",
                "Journal export",
                "Streak insurance"
            ]
        case .premium:
            return [
                "Everything in Pro",
                "Advanced analytics",
                "Priority AI responses",
                "Custom challenge creation",
                "1-on-1 coaching sessions",
                "Early access to features"
            ]
        }
    }
    
    var maxPathsAllowed: Int {
        switch self {
        case .free: return 1
        case .pro, .premium: return TrainingPath.allCases.count
        }
    }
    
    var maxChallengesPerWeek: Int {
        switch self {
        case .free: return 3
        case .pro, .premium: return Int.max
        }
    }
    
    var hasStreakInsurance: Bool {
        switch self {
        case .free: return false
        case .pro, .premium: return true
        }
    }
}

// MARK: - User Profile Model
struct UserProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var selectedPath: TrainingPath
    var joinDate: Date
    var currentStreak: Int
    var longestStreak: Int
    var totalChallengesCompleted: Int
    var subscriptionTier: SubscriptionTier
    var streakBankDays: Int
    var lastActiveDate: Date?
    
    // Enhanced Profile Fields
    var firstName: String?
    var lastName: String?
    var bio: String?
    var profileImageURL: String?
    var timeZone: TimeZone
    var preferredLanguage: String
    var notificationSettings: NotificationSettings
    var privacySettings: PrivacySettings
    
    // Analytics & Insights
    var totalJournalEntries: Int
    var totalCheckIns: Int
    var totalBooksRead: Int
    var averageMoodScore: Double
    var favoriteQuote: String?
    
    init(selectedPath: TrainingPath) {
        self.selectedPath = selectedPath
        self.joinDate = Date()
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalChallengesCompleted = 0
        self.subscriptionTier = .free
        self.streakBankDays = 0
        self.timeZone = TimeZone.current
        self.preferredLanguage = Locale.current.languageCode ?? "en"
        self.notificationSettings = NotificationSettings()
        self.privacySettings = PrivacySettings()
        self.totalJournalEntries = 0
        self.totalCheckIns = 0
        self.totalBooksRead = 0
        self.averageMoodScore = 0.0
    }
    
    var displayName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        } else if let firstName = firstName {
            return firstName
        }
        return "User"
    }
    
    var isOnboarded: Bool {
        return firstName != nil
    }
    
    var streakLevel: StreakLevel {
        return StreakLevel.from(streak: currentStreak)
    }
    
    var progressPercentage: Double {
        let totalActivities = totalChallengesCompleted + totalJournalEntries + totalCheckIns
        return min(Double(totalActivities) / 100.0, 1.0) // Cap at 100%
    }
}

// MARK: - Notification Settings
struct NotificationSettings: Codable {
    var morningCheckInEnabled: Bool = true
    var eveningCheckInEnabled: Bool = true
    var challengeRemindersEnabled: Bool = true
    var weeklyInsightsEnabled: Bool = true
    var streakRemindersEnabled: Bool = true
    var morningCheckInTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    var eveningCheckInTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
}

// MARK: - Privacy Settings
struct PrivacySettings: Codable {
    var allowDataCollection: Bool = true
    var allowPersonalization: Bool = true
    var shareProgressWithCoach: Bool = false
    var publicProfile: Bool = false
    var anonymizeExports: Bool = true
}

// MARK: - Streak Level Enum
enum StreakLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case developing = "developing"
    case consistent = "consistent"
    case strong = "strong"
    case champion = "champion"
    case legendary = "legendary"
    
    static func from(streak: Int) -> StreakLevel {
        switch streak {
        case 0...2: return .beginner
        case 3...6: return .developing
        case 7...20: return .consistent
        case 21...49: return .strong
        case 50...99: return .champion
        default: return .legendary
        }
    }
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .developing: return "Developing"
        case .consistent: return "Consistent"
        case .strong: return "Strong"
        case .champion: return "Champion"
        case .legendary: return "Legendary"
        }
    }
    
    var icon: String {
        switch self {
        case .beginner: return "seedling"
        case .developing: return "leaf"
        case .consistent: return "tree"
        case .strong: return "flame"
        case .champion: return "crown"
        case .legendary: return "star.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .gray
        case .developing: return .green
        case .consistent: return .blue
        case .strong: return .orange
        case .champion: return .purple
        case .legendary: return .yellow
        }
    }
}

// MARK: - Daily Challenge Model
struct DailyChallenge: Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let description: String
    let path: TrainingPath
    let difficulty: ChallengeDifficulty
    let date: Date
    var isCompleted: Bool = false
    var completedAt: Date?
    var userNotes: String?
    var effortLevel: Int? // 1-5 scale
    var completionTimeMinutes: Int?
    var isSkipped: Bool = false
    var skipReason: String?
    
    // Challenge Metadata
    let estimatedTimeMinutes: Int
    let category: ChallengeCategory
    let tags: [String]
    var customization: ChallengeCustomization?
    
    init(title: String, description: String, path: TrainingPath, difficulty: ChallengeDifficulty, date: Date, category: ChallengeCategory = .general, estimatedTimeMinutes: Int = 5, tags: [String] = []) {
        self.title = title
        self.description = description
        self.path = path
        self.difficulty = difficulty
        self.date = date
        self.category = category
        self.estimatedTimeMinutes = estimatedTimeMinutes
        self.tags = tags
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
    
    var difficultyColor: Color {
        return difficulty.color
    }
    
    enum ChallengeDifficulty: String, Codable, CaseIterable {
        case micro = "micro"
        case standard = "standard"
        case advanced = "advanced"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .micro: return "Micro (2-5 min)"
            case .standard: return "Standard (10-20 min)"
            case .advanced: return "Advanced (30+ min)"
            case .custom: return "Custom"
            }
        }
        
        var estimatedTime: Int {
            switch self {
            case .micro: return 5
            case .standard: return 15
            case .advanced: return 30
            case .custom: return 10
            }
        }
        
        var color: Color {
            switch self {
            case .micro: return .green
            case .standard: return .orange
            case .advanced: return .red
            case .custom: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .micro: return "leaf"
            case .standard: return "target"
            case .advanced: return "mountain.2"
            case .custom: return "wand.and.rays"
            }
        }
    }
}

// MARK: - Challenge Status Enum
enum ChallengeStatus: String, Codable, CaseIterable {
    case upcoming = "upcoming"
    case active = "active"
    case completed = "completed"
    case skipped = "skipped"
    case missed = "missed"
    
    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .active: return "Today's Challenge"
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
    
    var icon: String {
        switch self {
        case .upcoming: return "clock"
        case .active: return "play.circle"
        case .completed: return "checkmark.circle.fill"
        case .skipped: return "forward.circle"
        case .missed: return "x.circle"
        }
    }
}

// MARK: - Challenge Category Enum
enum ChallengeCategory: String, Codable, CaseIterable {
    case physical = "physical"
    case mental = "mental"
    case social = "social"
    case spiritual = "spiritual"
    case digital = "digital"
    case creative = "creative"
    case general = "general"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .physical: return "figure.walk"
        case .mental: return "brain"
        case .social: return "person.2"
        case .spiritual: return "leaf"
        case .digital: return "iphone"
        case .creative: return "paintbrush"
        case .general: return "star"
        }
    }
}

// MARK: - Challenge Customization
struct ChallengeCustomization: Codable {
    var userPrompt: String
    var aiSuggestions: [String]
    var selectedSuggestion: String?
    var difficulty: DailyChallenge.ChallengeDifficulty
    var estimatedTime: Int
}

// MARK: - AI Check-in Model
struct AICheckIn: Identifiable, Codable {
    var id: UUID = UUID()
    let date: Date
    let timeOfDay: CheckInTime
    let prompt: String
    var userResponse: String?
    var aiResponse: String?
    var mood: MoodRating?
    var effortLevel: Int? // 1-5 scale
    var duration: TimeInterval? // Time spent on check-in
    var pathContext: TrainingPath?
    var isCompleted: Bool = false
    var insights: [String] = []
    var followUpQuestions: [String] = []
    
    init(date: Date, timeOfDay: CheckInTime, prompt: String, pathContext: TrainingPath? = nil) {
        self.date = date
        self.timeOfDay = timeOfDay
        self.prompt = prompt
        self.pathContext = pathContext
    }
    
    var isExpired: Bool {
        let calendar = Calendar.current
        let checkInDate = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        return checkInDate < today && !isCompleted
    }
    
    enum CheckInTime: String, Codable, CaseIterable {
        case morning = "morning"
        case afternoon = "afternoon"
        case evening = "evening"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .morning: return "Morning Reflection"
            case .afternoon: return "Midday Check-in"
            case .evening: return "Evening Review"
            case .custom: return "Custom Check-in"
            }
        }
        
        var icon: String {
            switch self {
            case .morning: return "sunrise"
            case .afternoon: return "sun.max"
            case .evening: return "sunset"
            case .custom: return "clock"
            }
        }
        
        var defaultTime: Date {
            let calendar = Calendar.current
            let today = Date()
            
            switch self {
            case .morning: return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today) ?? today
            case .afternoon: return calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today) ?? today
            case .evening: return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today) ?? today
            case .custom: return today
            }
        }
    }
    
    enum MoodRating: String, Codable, CaseIterable {
        case terrible = "terrible"
        case low = "low"
        case neutral = "neutral"
        case good = "good"
        case great = "great"
        case excellent = "excellent"
        
        var emoji: String {
            switch self {
            case .terrible: return "😞"
            case .low: return "😔"
            case .neutral: return "😐"
            case .good: return "🙂"
            case .great: return "😊"
            case .excellent: return "🎉"
            }
        }
        
        var displayName: String {
            switch self {
            case .terrible: return "Terrible"
            case .low: return "Low"
            case .neutral: return "Neutral"
            case .good: return "Good"
            case .great: return "Great"
            case .excellent: return "Excellent"
            }
        }
        
        var score: Int {
            switch self {
            case .terrible: return 1
            case .low: return 2
            case .neutral: return 3
            case .good: return 4
            case .great: return 5
            case .excellent: return 6
            }
        }
        
        var color: Color {
            switch self {
            case .terrible: return .red
            case .low: return .orange
            case .neutral: return .gray
            case .good: return .yellow
            case .great: return .mint
            case .excellent: return .green
            }
        }
    }
}

// MARK: - Book Recommendation Model
struct BookRecommendation: Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let author: String
    let path: TrainingPath
    let summary: String
    let keyInsight: String
    let dailyAction: String
    let coverImageURL: String?
    let amazonURL: String?
    let dateAdded: Date
    var isSaved: Bool = false
    var isRead: Bool = false
    var dateRead: Date?
    var personalNotes: String?
    var readingProgress: Float = 0.0 // 0.0 to 1.0
    var userRating: BookRating = .unrated
    var timeSpentReading: Int = 0 // minutes
    var priorityLevel: Int = 0 // 1-5 scale
    var estimatedReadingTime: Int = 300 // minutes
    var genre: BookGenre = .selfHelp
    var isCurrentlyReading: Bool = false
    
    init(title: String, author: String, path: TrainingPath, summary: String, keyInsight: String, dailyAction: String, coverImageURL: String? = nil, amazonURL: String? = nil, dateAdded: Date = Date()) {
        self.title = title
        self.author = author
        self.path = path
        self.summary = summary
        self.keyInsight = keyInsight
        self.dailyAction = dailyAction
        self.coverImageURL = coverImageURL
        self.amazonURL = amazonURL
        self.dateAdded = dateAdded
    }
    
    var readingProgressPercentage: Int {
        return Int(readingProgress * 100)
    }
    
    var readingStatus: ReadingStatus {
        if isRead {
            return .completed
        } else if isCurrentlyReading || readingProgress > 0 {
            return .inProgress
        } else if isSaved {
            return .saved
        } else {
            return .notStarted
        }
    }
    
    enum BookRating: Int, Codable, CaseIterable {
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
    
    enum BookGenre: String, Codable, CaseIterable {
        case selfHelp = "self_help"
        case psychology = "psychology"
        case philosophy = "philosophy"
        case biography = "biography"
        case business = "business"
        case spirituality = "spirituality"
        case science = "science"
        case fiction = "fiction"
        
        var displayName: String {
            switch self {
            case .selfHelp: return "Self-Help"
            case .psychology: return "Psychology"
            case .philosophy: return "Philosophy"
            case .biography: return "Biography"
            case .business: return "Business"
            case .spirituality: return "Spirituality"
            case .science: return "Science"
            case .fiction: return "Fiction"
            }
        }
    }
    
    enum ReadingStatus: String, Codable {
        case notStarted = "not_started"
        case saved = "saved"
        case inProgress = "in_progress"
        case completed = "completed"
        
        var displayName: String {
            switch self {
            case .notStarted: return "Not Started"
            case .saved: return "Saved"
            case .inProgress: return "Reading"
            case .completed: return "Completed"
            }
        }
        
        var color: Color {
            switch self {
            case .notStarted: return .gray
            case .saved: return .blue
            case .inProgress: return .orange
            case .completed: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .notStarted: return "book"
            case .saved: return "bookmark"
            case .inProgress: return "book.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }
}

// MARK: - Book Highlight Model
struct BookHighlight: Identifiable, Codable {
    var id: UUID = UUID()
    let text: String
    var note: String?
    let pageNumber: Int
    let dateCreated: Date
    let bookTitle: String
    var colorHex: String?
    var topics: [String] = []
    var isPublic: Bool = false
    
    init(text: String, note: String? = nil, pageNumber: Int, dateCreated: Date = Date(), bookTitle: String, colorHex: String? = nil, topics: [String] = []) {
        self.text = text
        self.note = note
        self.pageNumber = pageNumber
        self.dateCreated = dateCreated
        self.bookTitle = bookTitle
        self.colorHex = colorHex
        self.topics = topics
    }
    
    var highlightColor: Color {
        guard let colorHex = colorHex else { return .yellow }
        return Color(hex: colorHex) ?? .yellow
    }
}

// MARK: - Journal Entry Model
struct JournalEntry: Identifiable, Codable {
    var id: UUID = UUID()
    let date: Date
    var content: String
    let prompt: String?
    var mood: AICheckIn.MoodRating?
    var tags: [String] = []
    var isSavedToSelf: Bool = false
    var isMarkedForReread: Bool = false
    var pathContext: TrainingPath?
    var entryType: JournalEntryType = .reflection
    var isPrivate: Bool = false
    var lastEditedDate: Date?
    var wordCount: Int = 0
    var readingTime: Int = 0 // estimated reading time in minutes
    var attachments: [JournalAttachment] = []
    
    init(date: Date = Date(), content: String, prompt: String? = nil, mood: AICheckIn.MoodRating? = nil, tags: [String] = []) {
        self.date = date
        self.content = content
        self.prompt = prompt
        self.mood = mood
        self.tags = tags
        self.updateComputedFields()
    }
    
    mutating func updateComputedFields() {
        wordCount = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        readingTime = max(1, wordCount / 200) // Average reading speed: 200 words per minute
        lastEditedDate = Date()
    }
    
    var formattedWordCount: String {
        return "\(wordCount) word\(wordCount == 1 ? "" : "s")"
    }
    
    var formattedReadingTime: String {
        return "\(readingTime) min read"
    }
    
    enum JournalEntryType: String, Codable, CaseIterable {
        case reflection = "reflection"
        case gratitude = "gratitude"
        case goal = "goal"
        case challenge = "challenge"
        case insight = "insight"
        case progress = "progress"
        case milestone = "milestone"
        case breakthrough = "breakthrough"
        
        var displayName: String {
            switch self {
            case .reflection: return "Reflection"
            case .gratitude: return "Gratitude"
            case .goal: return "Goal"
            case .challenge: return "Challenge"
            case .insight: return "Insight"
            case .progress: return "Progress"
            case .milestone: return "Milestone"
            case .breakthrough: return "Breakthrough"
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
            case .milestone: return "flag"
            case .breakthrough: return "sparkles"
            }
        }
        
        var color: Color {
            switch self {
            case .reflection: return .blue
            case .gratitude: return .pink
            case .goal: return .purple
            case .challenge: return .orange
            case .insight: return .yellow
            case .progress: return .green
            case .milestone: return .indigo
            case .breakthrough: return .mint
            }
        }
    }
}

// MARK: - Journal Attachment Model
struct JournalAttachment: Identifiable, Codable {
    var id: UUID = UUID()
    let type: AttachmentType
    let url: String?
    let filename: String?
    let dateAdded: Date = Date()
    
    enum AttachmentType: String, Codable {
        case image = "image"
        case audio = "audio"
        case video = "video"
        case document = "document"
        
        var icon: String {
            switch self {
            case .image: return "photo"
            case .audio: return "waveform"
            case .video: return "video"
            case .document: return "doc"
            }
        }
    }
}

// MARK: - Weekly Summary Model
struct WeeklySummary: Identifiable, Codable {
    var id: UUID = UUID()
    let weekStartDate: Date
    let weekEndDate: Date
    let summary: String
    let keyThemes: [String]
    let challengesCompleted: Int
    let checkinStreak: Int
    let recommendedFocus: TrainingPath?
    let moodTrend: MoodTrend
    let insights: [WeeklyInsight]
    let achievements: [Achievement]
    let nextWeekGoals: [String]
    let aiConfidenceScore: Double // 0.0 to 1.0
    
    init(weekStartDate: Date, weekEndDate: Date, summary: String, keyThemes: [String], challengesCompleted: Int, checkinStreak: Int, recommendedFocus: TrainingPath? = nil) {
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.summary = summary
        self.keyThemes = keyThemes
        self.challengesCompleted = challengesCompleted
        self.checkinStreak = checkinStreak
        self.recommendedFocus = recommendedFocus
        self.moodTrend = .stable
        self.insights = []
        self.achievements = []
        self.nextWeekGoals = []
        self.aiConfidenceScore = 0.7
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEndDate))"
    }
    
    enum MoodTrend: String, Codable {
        case improving = "improving"
        case stable = "stable"
        case declining = "declining"
        
        var displayName: String {
            switch self {
            case .improving: return "Improving"
            case .stable: return "Stable"
            case .declining: return "Needs Attention"
            }
        }
        
        var color: Color {
            switch self {
            case .improving: return .green
            case .stable: return .blue
            case .declining: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .improving: return "arrow.up.circle"
            case .stable: return "minus.circle"
            case .declining: return "arrow.down.circle"
            }
        }
    }
}

// MARK: - Weekly Insight Model
struct WeeklyInsight: Identifiable, Codable {
    var id: UUID = UUID()
    let type: InsightType
    let title: String
    let description: String
    let actionItem: String?
    let confidence: Double // 0.0 to 1.0
    
    enum InsightType: String, Codable {
        case pattern = "pattern"
        case improvement = "improvement"
        case concern = "concern"
        case milestone = "milestone"
        case recommendation = "recommendation"
        
        var displayName: String {
            switch self {
            case .pattern: return "Pattern Detected"
            case .improvement: return "Improvement"
            case .concern: return "Area for Focus"
            case .milestone: return "Milestone"
            case .recommendation: return "Recommendation"
            }
        }
        
        var icon: String {
            switch self {
            case .pattern: return "chart.dots.scatter"
            case .improvement: return "arrow.up.right.circle"
            case .concern: return "exclamationmark.triangle"
            case .milestone: return "flag.circle"
            case .recommendation: return "lightbulb.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .pattern: return .blue
            case .improvement: return .green
            case .concern: return .orange
            case .milestone: return .purple
            case .recommendation: return .yellow
            }
        }
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    var id: UUID = UUID()
    let type: AchievementType
    let title: String
    let description: String
    let dateEarned: Date
    let iconName: String
    let rarity: AchievementRarity
    let points: Int
    
    init(type: AchievementType, title: String, description: String, dateEarned: Date = Date(), iconName: String, rarity: AchievementRarity = .common, points: Int = 10) {
        self.type = type
        self.title = title
        self.description = description
        self.dateEarned = dateEarned
        self.iconName = iconName
        self.rarity = rarity
        self.points = points
    }
    
    enum AchievementType: String, Codable {
        case streak = "streak"
        case challenge = "challenge"
        case journal = "journal"
        case book = "book"
        case checkin = "checkin"
        case milestone = "milestone"
        case social = "social"
        case consistency = "consistency"
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
    
    enum AchievementRarity: String, Codable {
        case common = "common"
        case uncommon = "uncommon"
        case rare = "rare"
        case epic = "epic"
        case legendary = "legendary"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var color: Color {
            switch self {
            case .common: return .gray
            case .uncommon: return .green
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .yellow
            }
        }
        
        var basePoints: Int {
            switch self {
            case .common: return 10
            case .uncommon: return 25
            case .rare: return 50
            case .epic: return 100
            case .legendary: return 250
            }
        }
    }
}

// MARK: - Reading Goal Model
struct ReadingGoal: Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let targetCount: Int
    var currentCount: Int = 0
    let goalType: GoalType
    let startDate: Date
    let endDate: Date
    var isCompleted: Bool = false
    let path: TrainingPath?
    let description: String?
    
    init(title: String, targetCount: Int, goalType: GoalType, startDate: Date, endDate: Date, path: TrainingPath? = nil, description: String? = nil) {
        self.title = title
        self.targetCount = targetCount
        self.goalType = goalType
        self.startDate = startDate
        self.endDate = endDate
        self.path = path
        self.description = description
    }
    
    var progressPercentage: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }
    
    var isOverdue: Bool {
        return endDate < Date() && !isCompleted
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    enum GoalType: String, Codable, CaseIterable {
        case booksPerMonth = "books_per_month"
        case booksPerYear = "books_per_year"
        case pagesPerDay = "pages_per_day"
        case minutesPerDay = "minutes_per_day"
        case highlightsPerBook = "highlights_per_book"
        case notesPerBook = "notes_per_book"
        
        var displayName: String {
            switch self {
            case .booksPerMonth: return "Books per Month"
            case .booksPerYear: return "Books per Year"
            case .pagesPerDay: return "Pages per Day"
            case .minutesPerDay: return "Minutes per Day"
            case .highlightsPerBook: return "Highlights per Book"
            case .notesPerBook: return "Notes per Book"
            }
        }
        
        var unit: String {
            switch self {
            case .booksPerMonth, .booksPerYear: return "books"
            case .pagesPerDay: return "pages"
            case .minutesPerDay: return "minutes"
            case .highlightsPerBook: return "highlights"
            case .notesPerBook: return "notes"
            }
        }
        
        var icon: String {
            switch self {
            case .booksPerMonth, .booksPerYear: return "book.stack"
            case .pagesPerDay: return "doc.text"
            case .minutesPerDay: return "clock"
            case .highlightsPerBook: return "highlighter"
            case .notesPerBook: return "note.text"
            }
        }
    }
}

// MARK: - Reading Session Model
struct ReadingSession: Identifiable, Codable {
    var id: UUID = UUID()
    let bookId: UUID
    let startTime: Date
    var endTime: Date?
    var durationMinutes: Int = 0
    var pagesRead: Int = 0
    var notes: String?
    let sessionType: SessionType
    
    init(bookId: UUID, startTime: Date = Date(), sessionType: SessionType = .focused) {
        self.bookId = bookId
        self.startTime = startTime
        self.sessionType = sessionType
    }
    
    var isActive: Bool {
        return endTime == nil
    }
    
    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    enum SessionType: String, Codable {
        case focused = "focused"
        case casual = "casual"
        case audiobook = "audiobook"
        case research = "research"
        
        var displayName: String {
            switch self {
            case .focused: return "Focused Reading"
            case .casual: return "Casual Reading"
            case .audiobook: return "Audiobook"
            case .research: return "Research"
            }
        }
        
        var icon: String {
            switch self {
            case .focused: return "brain.head.profile"
            case .casual: return "book"
            case .audiobook: return "speaker.wave.2"
            case .research: return "magnifyingglass"
            }
        }
    }
}

// MARK: - Analytics Models

// MARK: - Mood Data Point
struct MoodDataPoint: Identifiable, Codable {
    var id: UUID = UUID()
    let date: Date
    let averageMood: Double
    let checkInCount: Int
    
    init(date: Date, averageMood: Double, checkInCount: Int = 1) {
        self.date = date
        self.averageMood = averageMood
        self.checkInCount = checkInCount
    }
}

// MARK: - Streak Data
struct StreakData: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let streakHistory: [StreakDataPoint]
    let lastActiveDate: Date?
    let streakBankDays: Int
    
    var streakLevel: StreakLevel {
        return StreakLevel.from(streak: currentStreak)
    }
    
    var averageWeeklyStreak: Double {
        guard !streakHistory.isEmpty else { return 0 }
        
        let weeklyStreaks = Dictionary(grouping: streakHistory) { dataPoint in
            Calendar.current.dateInterval(of: .weekOfYear, for: dataPoint.date)?.start ?? dataPoint.date
        }.mapValues { points in
            points.filter { $0.completed }.count
        }
        
        let total = weeklyStreaks.values.reduce(0, +)
        return Double(total) / Double(weeklyStreaks.count)
    }
}

// MARK: - Streak Data Point
struct StreakDataPoint: Identifiable, Codable {
    var id: UUID = UUID()
    let date: Date
    let completed: Bool
    let challengeTitle: String?
    
    init(date: Date, completed: Bool, challengeTitle: String? = nil) {
        self.date = date
        self.completed = completed
        self.challengeTitle = challengeTitle
    }
}

// MARK: - Reading Stats
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
}

// MARK: - Stats Period Enum
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
}

// MARK: - User Data Export Model
struct UserDataExport: Codable {
    let userProfile: UserProfile
    let books: [BookRecommendation]
    let journalEntries: [JournalEntry]
    let checkIns: [AICheckIn]
    let challenges: [DailyChallenge]
    let weeklySummaries: [WeeklySummary]
    let achievements: [Achievement]
    let readingStats: ReadingStats
    let exportDate: Date
    let appVersion: String
    
    init(userProfile: UserProfile, books: [BookRecommendation], journalEntries: [JournalEntry], checkIns: [AICheckIn], challenges: [DailyChallenge] = [], weeklySummaries: [WeeklySummary] = [], achievements: [Achievement] = [], readingStats: ReadingStats, exportDate: Date = Date()) {
        self.userProfile = userProfile
        self.books = books
        self.journalEntries = journalEntries
        self.checkIns = checkIns
        self.challenges = challenges
        self.weeklySummaries = weeklySummaries
        self.achievements = achievements
        self.readingStats = readingStats
        self.exportDate = exportDate
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Supporting Extensions

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    var hexString: String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// MARK: - Date Extensions
extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    var endOfWeek: Date {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: self)?.start else { return self }
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek)?.endOfDay ?? self
    }
    
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
    
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
