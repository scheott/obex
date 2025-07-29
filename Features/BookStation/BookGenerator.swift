import Foundation

// MARK: - Enhanced Book Generator
struct BookGenerator {
    
    // MARK: - Public Interface
    
    /// Generates personalized book recommendations based on user's path, progress, and preferences
    static func generateRecommendations(
        for path: TrainingPath,
        userLevel: UserLevel = .beginner,
        currentStreak: Int = 0,
        recentChallenges: [String] = [],
        count: Int = 3
    ) -> [BookRecommendation] {
        let templates = getAdvancedBookTemplates(for: path, userLevel: userLevel)
        let scoredBooks = scoreBooks(templates, for: path, userLevel: userLevel, currentStreak: currentStreak, recentChallenges: recentChallenges)
        let selectedBooks = Array(scoredBooks.prefix(count))
        
        return selectedBooks.map { scoredBook in
            var book = scoredBook.template.toBookRecommendation(for: path)
            book.aiRecommendationReason = generateAIRecommendationReason(book, score: scoredBook.score, userLevel: userLevel, path: path)
            book.priorityLevel = min(5, max(1, Int(scoredBook.score * 5)))
            return book
        }
    }
    
    /// Gets the featured book of the day with dynamic AI insights
    static func getBookOfTheDay(for path: TrainingPath, userLevel: UserLevel = .beginner) -> BookRecommendation? {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let templates = getAdvancedBookTemplates(for: path, userLevel: userLevel)
        
        // Use day of year as seed for consistent daily selection
        var generator = SeededRandomNumberGenerator(seed: dayOfYear)
        guard let template = templates.shuffled(using: &generator).first else { return nil }
        
        var book = template.toBookRecommendation(for: path)
        book.dailyInsight = generateDailyInsight(for: book, path: path)
        book.todaysChallenge = generateBookChallenge(for: book, path: path)
        
        return book
    }
    
    /// Searches books with AI-enhanced relevance scoring
    static func searchBooks(
        for path: TrainingPath,
        query: String,
        userLevel: UserLevel = .beginner,
        filters: BookFilters = BookFilters()
    ) -> [BookRecommendation] {
        let allTemplates = getAllBookTemplates()
        let pathTemplates = allTemplates.filter { $0.primaryPath == path || $0.secondaryPaths.contains(path) }
        
        let filteredBooks = pathTemplates.filter { template in
            matchesSearchQuery(template, query: query) && matchesFilters(template, filters: filters)
        }
        
        let scoredBooks = scoreSearchResults(filteredBooks, query: query, path: path, userLevel: userLevel)
        
        return scoredBooks.map { scoredBook in
            var book = scoredBook.template.toBookRecommendation(for: path)
            book.searchRelevanceScore = scoredBook.score
            return book
        }
    }
    
    /// Generates book recommendations based on user's reading history and goals
    static func getPersonalizedRecommendations(
        for path: TrainingPath,
        readBooks: [BookRecommendation],
        savedBooks: [BookRecommendation],
        userGoals: [String] = [],
        count: Int = 5
    ) -> [BookRecommendation] {
        let userProfile = analyzeReadingProfile(readBooks: readBooks, savedBooks: savedBooks)
        let templates = getAdvancedBookTemplates(for: path, userLevel: userProfile.level)
        
        let recommendations = templates.compactMap { template -> ScoredBook? in
            let compatibilityScore = calculateCompatibilityScore(template, with: userProfile)
            let noveltyScore = calculateNoveltyScore(template, against: readBooks + savedBooks)
            let goalAlignmentScore = calculateGoalAlignmentScore(template, goals: userGoals)
            
            let totalScore = (compatibilityScore * 0.4) + (noveltyScore * 0.3) + (goalAlignmentScore * 0.3)
            
            return ScoredBook(template: template, score: totalScore)
        }
        .sorted { $0.score > $1.score }
        .prefix(count)
        
        return Array(recommendations).map { scoredBook in
            var book = scoredBook.template.toBookRecommendation(for: path)
            book.aiRecommendationReason = generatePersonalizedReason(scoredBook.template, score: scoredBook.score, profile: userProfile)
            return book
        }
    }
    
    /// Generates AI-powered daily book insight with actionable advice
    static func generateDailyBookInsight(for path: TrainingPath, userLevel: UserLevel = .beginner) -> DailyBookInsight? {
        guard let featuredBook = getBookOfTheDay(for: path, userLevel: userLevel) else { return nil }
        
        let insights = getPathSpecificInsights(for: path)
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let selectedInsight = insights[dayIndex % insights.count]
        
        return DailyBookInsight(
            content: selectedInsight.content,
            bookTitle: featuredBook.title,
            category: path.displayName,
            actionItem: selectedInsight.actionItem,
            deepDive: generateDeepDiveQuestion(insight: selectedInsight, path: path),
            readingTime: estimateReadingTime(selectedInsight.content)
        )
    }
    
    // MARK: - Book Discovery Features
    
    /// Generates "If you liked X, try Y" recommendations
    static func getSimilarBooks(to book: BookRecommendation, count: Int = 3) -> [BookRecommendation] {
        let allTemplates = getAllBookTemplates()
        
        let similarBooks = allTemplates.compactMap { template -> ScoredBook? in
            let similarity = calculateBookSimilarity(book, template: template)
            return similarity > 0.3 ? ScoredBook(template: template, score: similarity) : nil
        }
        .sorted { $0.score > $1.score }
        .prefix(count)
        
        return Array(similarBooks).map { $0.template.toBookRecommendation(for: book.path) }
    }
    
    /// Gets trending books for a specific path based on current events and seasons
    static func getTrendingBooks(for path: TrainingPath, count: Int = 5) -> [BookRecommendation] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let season = getSeason(for: currentMonth)
        
        let templates = getAdvancedBookTemplates(for: path)
        let trendingBooks = templates.filter { template in
            template.seasonalRelevance.contains(season) || template.trendingScore > 0.7
        }
        .sorted { $0.trendingScore > $1.trendingScore }
        .prefix(count)
        
        return Array(trendingBooks).map { $0.toBookRecommendation(for: path) }
    }
    
    // MARK: - AI Enhancement Methods
    
    private static func generateAIRecommendationReason(
        _ book: BookRecommendation,
        score: Double,
        userLevel: UserLevel,
        path: TrainingPath
    ) -> String {
        let levelText = userLevel == .beginner ? "foundational" : userLevel == .intermediate ? "practical" : "advanced"
        let pathContext = getPathContext(path)
        
        let reasons = [
            "This book offers \(levelText) insights perfect for your current \(pathContext) journey.",
            "Based on your focus on \(pathContext), this author's approach will resonate with your goals.",
            "The practical strategies in this book align perfectly with \(levelText) \(pathContext) development.",
            "This book's unique perspective on \(pathContext) makes it ideal for your current growth stage."
        ]
        
        return reasons.randomElement() ?? reasons[0]
    }
    
    private static func generateDailyInsight(for book: BookRecommendation, path: TrainingPath) -> String {
        let insights = [
            "Today's wisdom from \(book.title): \(book.keyInsight)",
            "Key insight: \(book.keyInsight) - Apply this to your \(path.displayName.lowercased()) practice today.",
            "\(book.author) reminds us: \(book.keyInsight)",
            "From \(book.title): \(book.keyInsight) - Perfect for your \(path.displayName.lowercased()) journey."
        ]
        
        return insights.randomElement() ?? insights[0]
    }
    
    private static func generateBookChallenge(for book: BookRecommendation, path: TrainingPath) -> String {
        let baseAction = book.dailyAction
        let pathSpecificChallenges = getChallengesForPath(path)
        
        return pathSpecificChallenges.randomElement() ?? baseAction
    }
    
    private static func generateDeepDiveQuestion(insight: PathInsight, path: TrainingPath) -> String {
        let questions = [
            "How can you apply this insight to overcome your biggest \(path.displayName.lowercased()) challenge?",
            "What would change in your life if you fully embraced this principle?",
            "How does this insight challenge your current approach to \(path.displayName.lowercased())?",
            "What's one specific action you can take today to embody this wisdom?"
        ]
        
        return questions.randomElement() ?? questions[0]
    }
    
    // MARK: - Scoring and Analysis
    
    private static func scoreBooks(
        _ templates: [AdvancedBookTemplate],
        for path: TrainingPath,
        userLevel: UserLevel,
        currentStreak: Int,
        recentChallenges: [String]
    ) -> [ScoredBook] {
        return templates.map { template in
            var score: Double = template.baseScore
            
            // Level appropriateness
            if template.recommendedLevel == userLevel {
                score += 0.3
            } else if abs(template.recommendedLevel.rawValue - userLevel.rawValue) == 1 {
                score += 0.1
            }
            
            // Streak-based relevance
            if currentStreak > 30 && template.tags.contains("advanced") {
                score += 0.2
            } else if currentStreak < 7 && template.tags.contains("beginner-friendly") {
                score += 0.2
            }
            
            // Recent challenge relevance
            for challenge in recentChallenges {
                if template.tags.contains(challenge.lowercased()) {
                    score += 0.15
                }
            }
            
            // Seasonal relevance
            let currentSeason = getSeason(for: Calendar.current.component(.month, from: Date()))
            if template.seasonalRelevance.contains(currentSeason) {
                score += 0.1
            }
            
            return ScoredBook(template: template, score: score)
        }.sorted { $0.score > $1.score }
    }
    
    private static func analyzeReadingProfile(readBooks: [BookRecommendation], savedBooks: [BookRecommendation]) -> UserReadingProfile {
        let totalBooks = readBooks.count
        let averageRating = readBooks.compactMap { $0.userRating.numericValue }.reduce(0, +) / Double(max(1, readBooks.count))
        
        let level: UserLevel
        if totalBooks < 3 {
            level = .beginner
        } else if totalBooks < 10 {
            level = .intermediate
        } else {
            level = .advanced
        }
        
        let preferredGenres = Dictionary(grouping: readBooks, by: { $0.genre })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        return UserReadingProfile(
            level: level,
            averageRating: averageRating,
            preferredGenres: Array(preferredGenres),
            readingVelocity: calculateReadingVelocity(readBooks),
            focusAreas: extractFocusAreas(from: readBooks + savedBooks)
        )
    }
    
    // MARK: - Helper Methods
    
    private static func matchesSearchQuery(_ template: AdvancedBookTemplate, query: String) -> Bool {
        let lowercaseQuery = query.lowercased()
        return template.title.lowercased().contains(lowercaseQuery) ||
               template.author.lowercased().contains(lowercaseQuery) ||
               template.summary.lowercased().contains(lowercaseQuery) ||
               template.tags.contains { $0.lowercased().contains(lowercaseQuery) }
    }
    
    private static func matchesFilters(_ template: AdvancedBookTemplate, filters: BookFilters) -> Bool {
        if let genre = filters.genre, template.genre != genre { return false }
        if let level = filters.userLevel, template.recommendedLevel != level { return false }
        if let maxReadingTime = filters.maxEstimatedReadingTime, template.estimatedReadingTimeMinutes > maxReadingTime { return false }
        return true
    }
    
    private static func getPathContext(_ path: TrainingPath) -> String {
        switch path {
        case .discipline: return "building consistent habits and mental toughness"
        case .clarity: return "developing focus and emotional regulation"
        case .confidence: return "strengthening self-assurance and leadership"
        case .purpose: return "finding meaning and direction"
        case .authenticity: return "embracing genuine self-expression"
        }
    }
    
    private static func getSeason(for month: Int) -> Season {
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }
    
    private static func getChallengesForPath(_ path: TrainingPath) -> [String] {
        switch path {
        case .discipline:
            return [
                "Do one hard thing before 10 AM",
                "Practice the 2-minute rule on a new habit",
                "Complete a task you've been avoiding for 15 minutes"
            ]
        case .clarity:
            return [
                "Practice 5 minutes of focused breathing",
                "Write down 3 thoughts you'd like to release",
                "Spend 10 minutes in nature without distractions"
            ]
        case .confidence:
            return [
                "Share your opinion in a conversation today",
                "Make eye contact with 5 strangers",
                "Compliment someone genuinely"
            ]
        case .purpose:
            return [
                "Write about what gives your life meaning",
                "Connect with someone who inspires you",
                "Spend 10 minutes visualizing your ideal future"
            ]
        case .authenticity:
            return [
                "Express a genuine feeling to someone you trust",
                "Say no to something that doesn't align with your values",
                "Share something you're passionate about"
            ]
        }
    }
    
    private static func estimateReadingTime(_ text: String) -> Int {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        return max(1, wordCount / 200) // 200 words per minute average
    }
    
    private static func calculateReadingVelocity(_ books: [BookRecommendation]) -> Double {
        // Calculate books per month based on reading history
        let readBooksWithDates = books.filter { $0.dateRead != nil }
        guard !readBooksWithDates.isEmpty else { return 1.0 }
        
        let sortedDates = readBooksWithDates.compactMap { $0.dateRead }.sorted()
        guard let firstDate = sortedDates.first, let lastDate = sortedDates.last else { return 1.0 }
        
        let monthsDifference = Calendar.current.dateComponents([.month], from: firstDate, to: lastDate).month ?? 1
        return Double(readBooksWithDates.count) / Double(max(1, monthsDifference))
    }
    
    private static func extractFocusAreas(from books: [BookRecommendation]) -> [String] {
        // Extract common themes from book titles and summaries
        let allText = books.map { "\($0.title) \($0.summary)" }.joined(separator: " ")
        let words = allText.lowercased().components(separatedBy: .punctuationCharacters)
            .joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
        
        let wordCounts = Dictionary(grouping: words, by: { $0 })
            .mapValues { $0.count }
            .filter { $0.value > 1 }
            .sorted { $0.value > $1.value }
            .prefix(5)
        
        return Array(wordCounts.map { $0.key })
    }
    
    // MARK: - Data Loading Methods
    
    private static func getAdvancedBookTemplates(for path: TrainingPath, userLevel: UserLevel = .beginner) -> [AdvancedBookTemplate] {
        return getAllBookTemplates().filter { template in
            template.primaryPath == path || template.secondaryPaths.contains(path)
        }
    }
    
    private static func getAllBookTemplates() -> [AdvancedBookTemplate] {
        return defaultBookTemplates + communityBookTemplates + aiGeneratedTemplates
    }
    
    private static func getPathSpecificInsights(for path: TrainingPath) -> [PathInsight] {
        switch path {
        case .discipline:
            return disciplineInsights
        case .clarity:
            return clarityInsights
        case .confidence:
            return confidenceInsights
        case .purpose:
            return purposeInsights
        case .authenticity:
            return authenticityInsights
        }
    }
}

// MARK: - Supporting Models

struct ScoredBook {
    let template: AdvancedBookTemplate
    let score: Double
}

struct AdvancedBookTemplate {
    let title: String
    let author: String
    let summary: String
    let keyInsight: String
    let dailyAction: String
    let coverImageURL: String?
    let amazonURL: String?
    let primaryPath: TrainingPath
    let secondaryPaths: [TrainingPath]
    let recommendedLevel: UserLevel
    let genre: BookRecommendation.BookGenre
    let tags: [String]
    let baseScore: Double
    let trendingScore: Double
    let seasonalRelevance: [Season]
    let estimatedReadingTimeMinutes: Int
    let difficultyRating: Int // 1-5
    let practicalityScore: Double // 0-1
    let inspirationScore: Double // 0-1
    
    func toBookRecommendation(for path: TrainingPath) -> BookRecommendation {
        return BookRecommendation(
            title: title,
            author: author,
            path: path,
            summary: summary,
            keyInsight: keyInsight,
            dailyAction: dailyAction,
            coverImageURL: coverImageURL,
            amazonURL: amazonURL,
            dateAdded: Date()
        )
    }
}

struct UserReadingProfile {
    let level: UserLevel
    let averageRating: Double
    let preferredGenres: [BookRecommendation.BookGenre]
    let readingVelocity: Double // books per month
    let focusAreas: [String]
}

struct BookFilters {
    let genre: BookRecommendation.BookGenre?
    let userLevel: UserLevel?
    let maxEstimatedReadingTime: Int? // minutes
    let minRating: Double?
    
    init(genre: BookRecommendation.BookGenre? = nil, 
         userLevel: UserLevel? = nil, 
         maxEstimatedReadingTime: Int? = nil, 
         minRating: Double? = nil) {
        self.genre = genre
        self.userLevel = userLevel
        self.maxEstimatedReadingTime = maxEstimatedReadingTime
        self.minRating = minRating
    }
}

struct PathInsight {
    let content: String
    let actionItem: String
    let category: String
    let depth: InsightDepth
    
    enum InsightDepth {
        case surface, practical, philosophical
    }
}

enum UserLevel: Int, CaseIterable {
    case beginner = 1
    case intermediate = 2
    case advanced = 3
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

enum Season {
    case spring, summer, fall, winter
}

// MARK: - Seeded Random Number Generator
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var seed: UInt64
    
    init(seed: Int) {
        self.seed = UInt64(seed)
    }
    
    mutating func next() -> UInt64 {
        seed = seed &* 1103515245 &+ 12345
        return seed
    }
}

// MARK: - Extensions for Enhanced BookRecommendation

extension BookRecommendation {
    var aiRecommendationReason: String {
        get { return personalNotes ?? "" }
        set { personalNotes = newValue }
    }
    
    var dailyInsight: String? {
        get { return nil } // This would be computed or stored separately
        set { } // Implementation would depend on your data model
    }
    
    var todaysChallenge: String? {
        get { return nil } // This would be computed or stored separately  
        set { } // Implementation would depend on your data model
    }
    
    var searchRelevanceScore: Double {
        get { return Double(priorityLevel) / 5.0 }
        set { priorityLevel = min(5, max(1, Int(newValue * 5))) }
    }
}

extension BookRecommendation.BookRating {
    var numericValue: Double? {
        switch self {
        case .unrated: return nil
        case .poor: return 1.0
        case .fair: return 2.0
        case .good: return 3.0
        case .great: return 4.0
        case .excellent: return 5.0
        }
    }
}

// MARK: - Book Data Collections (These would be moved to separate files in a real implementation)

private let defaultBookTemplates: [AdvancedBookTemplate] = [
    // Discipline Books
    AdvancedBookTemplate(
        title: "Atomic Habits",
        author: "James Clear",
        summary: "A practical guide to building good habits and breaking bad ones through tiny changes that deliver remarkable results.",
        keyInsight: "You do not rise to the level of your goals. You fall to the level of your systems.",
        dailyAction: "Stack a new 2-minute habit onto an existing routine",
        coverImageURL: "https://example.com/atomic-habits-cover.jpg",
        amazonURL: "https://amazon.com/atomic-habits",
        primaryPath: .discipline,
        secondaryPaths: [.clarity, .purpose],
        recommendedLevel: .beginner,
        genre: .selfHelp,
        tags: ["habits", "systems", "practical", "beginner-friendly"],
        baseScore: 0.9,
        trendingScore: 0.95,
        seasonalRelevance: [.winter, .spring],
        estimatedReadingTimeMinutes: 480,
        difficultyRating: 2,
        practicalityScore: 0.95,
        inspirationScore: 0.8
    ),
    
    AdvancedBookTemplate(
        title: "Can't Hurt Me",
        author: "David Goggins",
        summary: "A memoir and self-help guide about mastering your mind and defying the odds through extreme mental toughness.",
        keyInsight: "The only way you gain mental toughness is to do things you're not happy doing.",
        dailyAction: "Do one hard thing before 10 AM that makes you uncomfortable",
        coverImageURL: "https://example.com/cant-hurt-me-cover.jpg",
        amazonURL: "https://amazon.com/cant-hurt-me",
        primaryPath: .discipline,
        secondaryPaths: [.confidence],
        recommendedLevel: .intermediate,
        genre: .biography,
        tags: ["mental toughness", "extreme", "military", "advanced"],
        baseScore: 0.85,
        trendingScore: 0.8,
        seasonalRelevance: [.fall, .winter],
        estimatedReadingTimeMinutes: 600,
        difficultyRating: 4,
        practicalityScore: 0.7,
        inspirationScore: 0.95
    ),
    
    // Add more book templates for other paths...
]

private let communityBookTemplates: [AdvancedBookTemplate] = []
private let aiGeneratedTemplates: [AdvancedBookTemplate] = []

// Insights collections
private let disciplineInsights: [PathInsight] = [
    PathInsight(
        content: "Discipline isn't about perfection—it's about showing up consistently, even when motivation fails.",
        actionItem: "Commit to one small action every day for the next 7 days, regardless of how you feel.",
        category: "Consistency",
        depth: .practical
    ),
    PathInsight(
        content: "The compound effect of small daily habits creates extraordinary results over time.",
        actionItem: "Identify one 2-minute habit you can add to your morning routine starting tomorrow.",
        category: "Habits",
        depth: .practical
    )
]

private let clarityInsights: [PathInsight] = [
    PathInsight(
        content: "Clarity comes not from thinking more, but from thinking better—with focus and intention.",
        actionItem: "Spend 5 minutes writing down your thoughts without judgment, then identify the most important one.",
        category: "Mental Clarity",
        depth: .practical
    )
]

private let confidenceInsights: [PathInsight] = [
    PathInsight(
        content: "Confidence isn't about being perfect—it's about being willing to be imperfect in front of others.",
        actionItem: "Share one authentic thought or opinion in a conversation today, even if you're not 100% sure.",
        category: "Authentic Confidence",
        depth: .practical
    )
]

private let purposeInsights: [PathInsight] = [
    PathInsight(
        content: "Purpose isn't found—it's created through the intersection of your values, strengths, and the world's needs.",
        actionItem: "Write down one way you can use your unique strengths to help someone else today.",
        category: "Life Purpose",
        depth: .philosophical
    )
]

private let authenticityInsights: [PathInsight] = [
    PathInsight(
        content: "Authenticity requires the courage to disappoint others in service of your true self.",
        actionItem: "Say no to one request today that doesn't align with your values or priorities.",
        category: "Authentic Living",
        depth: .practical
    )
]
