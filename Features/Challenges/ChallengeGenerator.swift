import Foundation
import CoreData

// MARK: - Challenge Generator
class ChallengeGenerator {
    static let shared = ChallengeGenerator()
    
    private init() {}
    
    // MARK: - Main Generation Methods
    
    /// Generates a daily challenge based on user's training path and preferences
    static func generateDailyChallenge(
        for path: TrainingPath,
        difficulty: DailyChallenge.ChallengeDifficulty = .standard,
        date: Date = Date(),
        excludeRecent: Bool = true
    ) -> DailyChallenge {
        
        // Get challenge templates for the path
        let templates = getChallengeTemplates(for: path, difficulty: difficulty)
        
        // Filter out recently used challenges if requested
        let availableTemplates = excludeRecent ? 
            filterRecentlyUsed(templates, for: path) : templates
        
        // Select challenge based on user patterns and preferences
        let selectedTemplate = selectOptimalChallenge(
            from: availableTemplates,
            for: path,
            difficulty: difficulty
        )
        
        // Create challenge instance
        return createChallenge(from: selectedTemplate, for: date)
    }
    
    /// Generates multiple challenge options for user selection
    static func generateChallengeOptions(
        for path: TrainingPath,
        difficulty: DailyChallenge.ChallengeDifficulty,
        count: Int = 3
    ) -> [DailyChallenge] {
        
        let templates = getChallengeTemplates(for: path, difficulty: difficulty)
        let availableTemplates = filterRecentlyUsed(templates, for: path)
        
        return availableTemplates
            .shuffled()
            .prefix(count)
            .map { createChallenge(from: $0, for: Date()) }
    }
    
    /// Generates a custom challenge using AI/user input
    static func generateCustomChallenge(
        for path: TrainingPath,
        userPrompt: String,
        difficulty: DailyChallenge.ChallengeDifficulty = .custom
    ) async -> DailyChallenge {
        
        // This would integrate with AI service for custom generation
        let customTemplate = await processCustomChallengeRequest(
            userPrompt: userPrompt,
            path: path,
            difficulty: difficulty
        )
        
        return createChallenge(from: customTemplate, for: Date())
    }
    
    // MARK: - Challenge Template Management
    
    private static func getChallengeTemplates(
        for path: TrainingPath,
        difficulty: DailyChallenge.ChallengeDifficulty
    ) -> [ChallengeTemplate] {
        
        // In production, this would fetch from Core Data or Supabase
        return defaultChallengeTemplates
            .filter { $0.path == path && $0.difficulty == difficulty }
    }
    
    private static func filterRecentlyUsed(
        _ templates: [ChallengeTemplate],
        for path: TrainingPath
    ) -> [ChallengeTemplate] {
        
        // Get recently used challenges (last 7 days)
        let recentChallenges = getRecentChallenges(for: path, days: 7)
        let recentTitles = Set(recentChallenges.map { $0.title })
        
        // Filter out recently used templates
        let filtered = templates.filter { !recentTitles.contains($0.title) }
        
        // If too few options remain, include some recent ones
        return filtered.count >= 3 ? filtered : templates
    }
    
    private static func selectOptimalChallenge(
        from templates: [ChallengeTemplate],
        for path: TrainingPath,
        difficulty: DailyChallenge.ChallengeDifficulty
    ) -> ChallengeTemplate {
        
        // Smart selection based on user patterns
        let userStats = getUserChallengeStats(for: path)
        
        // Weight templates based on:
        // 1. User's success rate with similar challenges
        // 2. Time since last challenge of this category
        // 3. Current day of week patterns
        // 4. User's mood/energy trends
        
        let scoredTemplates = templates.map { template in
            (template: template, score: calculateChallengeScore(template, userStats: userStats))
        }
        
        // Select highest scoring template, with some randomness
        let sortedTemplates = scoredTemplates.sorted { $0.score > $1.score }
        
        // 70% chance to pick top choice, 30% chance to pick from top 3
        let randomValue = Double.random(in: 0...1)
        if randomValue < 0.7 || sortedTemplates.count == 1 {
            return sortedTemplates.first?.template ?? templates.randomElement()!
        } else {
            let topThree = Array(sortedTemplates.prefix(3))
            return topThree.randomElement()?.template ?? templates.randomElement()!
        }
    }
    
    private static func calculateChallengeScore(
        _ template: ChallengeTemplate,
        userStats: UserChallengeStats
    ) -> Double {
        var score = 1.0
        
        // Factor in success rate for this category
        if let categoryRate = userStats.categorySuccessRates[template.category] {
            score *= (0.5 + categoryRate) // Boost successful categories
        }
        
        // Factor in time since last challenge of this type
        let daysSinceLastCategory = userStats.daysSinceLastCategory[template.category] ?? 7
        score *= min(Double(daysSinceLastCategory) / 7.0, 1.0) // Prefer variety
        
        // Factor in current day of week preferences
        let currentDayOfWeek = Calendar.current.component(.weekday, from: Date())
        if let dayPreference = userStats.dayOfWeekPreferences[currentDayOfWeek] {
            score *= dayPreference
        }
        
        // Factor in estimated completion time vs user's available time
        let currentHour = Calendar.current.component(.hour, from: Date())
        if currentHour >= 19 && template.estimatedTimeMinutes > 15 {
            score *= 0.7 // Prefer shorter challenges in evening
        }
        
        return score
    }
    
    private static func createChallenge(
        from template: ChallengeTemplate,
        for date: Date
    ) -> DailyChallenge {
        
        var challenge = DailyChallenge(
            title: template.title,
            description: template.description,
            path: template.path,
            difficulty: template.difficulty,
            date: date,
            category: template.category,
            estimatedTimeMinutes: template.estimatedTimeMinutes,
            tags: template.tags
        )
        
        // Add some personalization
        challenge = personalizeChallenge(challenge, template: template)
        
        return challenge
    }
    
    private static func personalizeChallenge(
        _ challenge: DailyChallenge,
        template: ChallengeTemplate
    ) -> DailyChallenge {
        var personalizedChallenge = challenge
        
        // Personalize based on user preferences, time of day, etc.
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Morning-specific personalizations
        if currentHour < 12 {
            personalizedChallenge = addMorningContext(personalizedChallenge)
        }
        
        // Evening-specific personalizations
        if currentHour >= 18 {
            personalizedChallenge = addEveningContext(personalizedChallenge)
        }
        
        // Add seasonal or weather-based modifications
        personalizedChallenge = addContextualModifications(personalizedChallenge)
        
        return personalizedChallenge
    }
    
    // MARK: - Helper Methods
    
    private static func getRecentChallenges(for path: TrainingPath, days: Int) -> [DailyChallenge] {
        // This would fetch from Core Data in production
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Simulate fetching recent challenges
        return [] // Would return actual challenges from persistence
    }
    
    private static func getUserChallengeStats(for path: TrainingPath) -> UserChallengeStats {
        // This would analyze user's historical challenge data
        return UserChallengeStats(
            categorySuccessRates: [:],
            daysSinceLastCategory: [:],
            dayOfWeekPreferences: [:],
            averageCompletionTime: [:],
            preferredDifficulty: .standard
        )
    }
    
    private static func addMorningContext(_ challenge: DailyChallenge) -> DailyChallenge {
        var modified = challenge
        
        // Add weather-based modifications (if available)
        let season = getCurrentSeason()
        switch season {
        case .winter:
            if challenge.category == .physical {
                modified.description += " Embrace the energy that comes from moving in colder weather."
            }
        case .summer:
            if challenge.category == .physical && challenge.estimatedTimeMinutes > 20 {
                modified.description += " Stay hydrated and find shade when needed."
            }
        case .spring, .fall:
            if challenge.category == .physical {
                modified.description += " Take advantage of the perfect weather for outdoor activities."
            }
        }
        
        // Add day-of-week contextual modifications
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        switch dayOfWeek {
        case 2...6: // Monday to Friday
            if challenge.estimatedTimeMinutes > 30 {
                modified.description += " Perfect for your focused weekday routine."
            }
        case 1, 7: // Weekend
            if challenge.category == .social {
                modified.description += " Weekends are perfect for connecting with others."
            }
        default:
            break
        }
        
        return modified
    }
    
    private static func getCurrentSeason() -> Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2: return .winter
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .fall
        default: return .spring
        }
    }
    
    // MARK: - AI Integration
    
    private static func processCustomChallengeRequest(
        userPrompt: String,
        path: TrainingPath,
        difficulty: DailyChallenge.ChallengeDifficulty
    ) async -> ChallengeTemplate {
        
        // This would integrate with your AI service
        // For now, return a template based on the prompt
        
        let estimatedTime = difficulty.estimatedTime
        let category = inferCategoryFromPrompt(userPrompt)
        
        return ChallengeTemplate(
            title: "Custom: \(userPrompt.prefix(30))...",
            description: await generateChallengeDescription(from: userPrompt, path: path),
            path: path,
            difficulty: difficulty,
            category: category,
            estimatedTimeMinutes: estimatedTime,
            tags: extractTagsFromPrompt(userPrompt)
        )
    }
    
    private static func inferCategoryFromPrompt(_ prompt: String) -> ChallengeCategory {
        let lowercasePrompt = prompt.lowercased()
        
        if lowercasePrompt.contains("exercise") || lowercasePrompt.contains("workout") || lowercasePrompt.contains("run") {
            return .physical
        } else if lowercasePrompt.contains("meditate") || lowercasePrompt.contains("think") || lowercasePrompt.contains("focus") {
            return .mental
        } else if lowercasePrompt.contains("talk") || lowercasePrompt.contains("call") || lowercasePrompt.contains("meet") {
            return .social
        } else if lowercasePrompt.contains("phone") || lowercasePrompt.contains("social media") || lowercasePrompt.contains("screen") {
            return .digital
        } else if lowercasePrompt.contains("create") || lowercasePrompt.contains("write") || lowercasePrompt.contains("draw") {
            return .creative
        } else if lowercasePrompt.contains("nature") || lowercasePrompt.contains("gratitude") || lowercasePrompt.contains("values") {
            return .spiritual
        }
        
        return .general
    }
    
    private static func extractTagsFromPrompt(_ prompt: String) -> [String] {
        let lowercasePrompt = prompt.lowercased()
        var tags: [String] = []
        
        let tagMappings = [
            "morning": ["morning", "early"],
            "evening": ["evening", "night"],
            "quick": ["quick", "fast", "short"],
            "challenging": ["hard", "difficult", "challenging"],
            "outdoor": ["outside", "outdoor", "nature"],
            "indoor": ["inside", "indoor", "home"],
            "social": ["friends", "family", "people", "social"],
            "solo": ["alone", "solo", "personal", "individual"]
        ]
        
        for (tag, keywords) in tagMappings {
            if keywords.contains(where: { lowercasePrompt.contains($0) }) {
                tags.append(tag)
            }
        }
        
        return tags
    }
    
    private static func generateChallengeDescription(
        from prompt: String,
        path: TrainingPath
    ) async -> String {
        // This would call your AI service to generate a proper description
        // For now, return a formatted version of the prompt
        
        let pathContext = getPathContext(for: path)
        return "\(prompt). \(pathContext)"
    }
    
    private static func getPathContext(for path: TrainingPath) -> String {
        switch path {
        case .discipline:
            return "Focus on building consistency and willpower through this action."
        case .clarity:
            return "Use this practice to develop greater mental clarity and focus."
        case .confidence:
            return "Step into this challenge to build your inner confidence and courage."
        case .purpose:
            return "Engage with this activity to connect with your deeper sense of purpose."
        case .authenticity:
            return "Practice being true to yourself through this authentic expression."
        }
    }
    
    // MARK: - Challenge Validation
    
    static func validateChallenge(_ challenge: DailyChallenge) -> ChallengeValidationResult {
        var issues: [String] = []
        var suggestions: [String] = []
        
        // Check title length
        if challenge.title.count < 5 {
            issues.append("Title is too short")
        } else if challenge.title.count > 100 {
            issues.append("Title is too long")
        }
        
        // Check description length
        if challenge.description.count < 20 {
            issues.append("Description needs more detail")
        } else if challenge.description.count > 500 {
            suggestions.append("Consider shortening the description")
        }
        
        // Check time estimate reasonableness
        if challenge.estimatedTimeMinutes < 1 {
            issues.append("Time estimate is too low")
        } else if challenge.estimatedTimeMinutes > 120 {
            suggestions.append("Very long challenge - consider breaking it down")
        }
        
        // Check difficulty vs time alignment
        let expectedTimeRange = challenge.difficulty.estimatedTime
        if challenge.estimatedTimeMinutes > expectedTimeRange * 2 {
            suggestions.append("Time estimate seems high for \(challenge.difficulty.displayName) difficulty")
        }
        
        return ChallengeValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            suggestions: suggestions
        )
    }
    
    // MARK: - Challenge Analytics
    
    static func analyzeChallengePerformance(for path: TrainingPath) -> ChallengeAnalytics {
        // This would analyze user's challenge completion patterns
        let recentChallenges = getRecentChallenges(for: path, days: 30)
        
        let totalChallenges = recentChallenges.count
        let completedChallenges = recentChallenges.filter { $0.isCompleted }.count
        let completionRate = totalChallenges > 0 ? Double(completedChallenges) / Double(totalChallenges) : 0.0
        
        let averageEffort = recentChallenges
            .compactMap { $0.effortLevel }
            .reduce(0, +) / max(1, recentChallenges.filter { $0.isCompleted }.count)
        
        let preferredCategories = analyzeCategoryPreferences(recentChallenges)
        let optimalDifficulty = analyzeOptimalDifficulty(recentChallenges)
        
        return ChallengeAnalytics(
            completionRate: completionRate,
            averageEffort: Double(averageEffort),
            preferredCategories: preferredCategories,
            optimalDifficulty: optimalDifficulty,
            streakData: analyzeStreakPatterns(recentChallenges)
        )
    }
    
    private static func analyzeCategoryPreferences(_ challenges: [DailyChallenge]) -> [ChallengeCategory: Double] {
        let categoryGroups = Dictionary(grouping: challenges) { $0.category }
        var preferences: [ChallengeCategory: Double] = [:]
        
        for (category, categoryChallenges) in categoryGroups {
            let completedCount = categoryChallenges.filter { $0.isCompleted }.count
            let rate = Double(completedCount) / Double(categoryChallenges.count)
            preferences[category] = rate
        }
        
        return preferences
    }
    
    private static func analyzeOptimalDifficulty(_ challenges: [DailyChallenge]) -> DailyChallenge.ChallengeDifficulty {
        let difficultyGroups = Dictionary(grouping: challenges) { $0.difficulty }
        var bestRate = 0.0
        var optimalDifficulty: DailyChallenge.ChallengeDifficulty = .standard
        
        for (difficulty, difficultyChallenges) in difficultyGroups {
            let completedCount = difficultyChallenges.filter { $0.isCompleted }.count
            let rate = Double(completedCount) / Double(difficultyChallenges.count)
            
            if rate > bestRate {
                bestRate = rate
                optimalDifficulty = difficulty
            }
        }
        
        return optimalDifficulty
    }
    
    private static func analyzeStreakPatterns(_ challenges: [DailyChallenge]) -> StreakAnalysis {
        let sortedChallenges = challenges.sorted { $0.date < $1.date }
        var streaks: [Int] = []
        var currentStreak = 0
        
        for challenge in sortedChallenges {
            if challenge.isCompleted {
                currentStreak += 1
            } else {
                if currentStreak > 0 {
                    streaks.append(currentStreak)
                    currentStreak = 0
                }
            }
        }
        
        if currentStreak > 0 {
            streaks.append(currentStreak)
        }
        
        return StreakAnalysis(
            averageStreakLength: streaks.isEmpty ? 0 : Double(streaks.reduce(0, +)) / Double(streaks.count),
            longestStreak: streaks.max() ?? 0,
            totalStreaks: streaks.count
        )
    }
}

// MARK: - Supporting Models

struct ChallengeTemplate {
    let title: String
    let description: String
    let path: TrainingPath
    let difficulty: DailyChallenge.ChallengeDifficulty
    let category: ChallengeCategory
    let estimatedTimeMinutes: Int
    let tags: [String]
    let priority: Int // Higher number = higher priority
    let isActive: Bool
    
    init(title: String, description: String, path: TrainingPath, difficulty: DailyChallenge.ChallengeDifficulty, category: ChallengeCategory, estimatedTimeMinutes: Int, tags: [String] = [], priority: Int = 1, isActive: Bool = true) {
        self.title = title
        self.description = description
        self.path = path
        self.difficulty = difficulty
        self.category = category
        self.estimatedTimeMinutes = estimatedTimeMinutes
        self.tags = tags
        self.priority = priority
        self.isActive = isActive
    }
}

struct UserChallengeStats {
    let categorySuccessRates: [ChallengeCategory: Double]
    let daysSinceLastCategory: [ChallengeCategory: Int]
    let dayOfWeekPreferences: [Int: Double] // Weekday (1-7) to preference score
    let averageCompletionTime: [ChallengeCategory: Double]
    let preferredDifficulty: DailyChallenge.ChallengeDifficulty
}

struct ChallengeValidationResult {
    let isValid: Bool
    let issues: [String]
    let suggestions: [String]
}

struct ChallengeAnalytics {
    let completionRate: Double
    let averageEffort: Double
    let preferredCategories: [ChallengeCategory: Double]
    let optimalDifficulty: DailyChallenge.ChallengeDifficulty
    let streakData: StreakAnalysis
}

struct StreakAnalysis {
    let averageStreakLength: Double
    let longestStreak: Int
    let totalStreaks: Int
}

enum Season {
    case spring, summer, fall, winter
}

// MARK: - Default Challenge Templates

extension ChallengeGenerator {
    static let defaultChallengeTemplates: [ChallengeTemplate] = [
        
        // MARK: - Discipline Challenges
        
        // Micro Discipline Challenges
        ChallengeTemplate(
            title: "No Phone First Hour",
            description: "Keep your phone in another room for the first hour after waking up. Start your day with intention instead of distraction.",
            path: .discipline,
            difficulty: .micro,
            category: .digital,
            estimatedTimeMinutes: 60,
            tags: ["morning", "digital detox"],
            priority: 3
        ),
        
        ChallengeTemplate(
            title: "Cold Shower Finish",
            description: "End your regular shower with 30 seconds of cold water. Build mental toughness through voluntary discomfort.",
            path: .discipline,
            difficulty: .micro,
            category: .physical,
            estimatedTimeMinutes: 1,
            tags: ["cold exposure", "morning"],
            priority: 2
        ),
        
        ChallengeTemplate(
            title: "Make Your Bed",
            description: "Make your bed immediately after getting up. Start your day with a completed task and an organized space.",
            path: .discipline,
            difficulty: .micro,
            category: .general,
            estimatedTimeMinutes: 3,
            tags: ["morning", "organization"],
            priority: 1
        ),
        
        ChallengeTemplate(
            title: "10 Push-ups Now",
            description: "Drop and do 10 push-ups right now, regardless of where you are. Build the habit of immediate action.",
            path: .discipline,
            difficulty: .micro,
            category: .physical,
            estimatedTimeMinutes: 2,
            tags: ["exercise", "immediate action"],
            priority: 2
        ),
        
        // Standard Discipline Challenges
        ChallengeTemplate(
            title: "No Social Media Until Noon",
            description: "Avoid all social media platforms until 12 PM. Use your morning mental energy for productive activities instead.",
            path: .discipline,
            difficulty: .standard,
            category: .digital,
            estimatedTimeMinutes: 15,
            tags: ["digital detox", "morning"],
            priority: 3
        ),
        
        ChallengeTemplate(
            title: "Complete Your Most Important Task First",
            description: "Identify your most important task for today and complete it before checking email, messages, or news.",
            path: .discipline,
            difficulty: .standard,
            category: .mental,
            estimatedTimeMinutes: 45,
            tags: ["productivity", "priorities"],
            priority: 4
        ),
        
        ChallengeTemplate(
            title: "20-Minute Walk",
            description: "Take a 20-minute walk outside without your phone, podcasts, or music. Practice being present with your thoughts.",
            path: .discipline,
            difficulty: .standard,
            category: .physical,
            estimatedTimeMinutes: 20,
            tags: ["walking", "mindfulness", "outdoor"],
            priority: 2
        ),
        
        // MARK: - Clarity Challenges
        
        // Micro Clarity Challenges
        ChallengeTemplate(
            title: "Three Deep Breaths",
            description: "Take three slow, deep breaths focusing only on the sensation of breathing. Reset your mental state in under a minute.",
            path: .clarity,
            difficulty: .micro,
            category: .mental,
            estimatedTimeMinutes: 1,
            tags: ["breathing", "mindfulness"],
            priority: 1
        ),
        
        ChallengeTemplate(
            title: "Write Down 3 Thoughts to Delete",
            description: "Identify three negative or unproductive thoughts you've had today and write them down to release them.",
            path: .clarity,
            difficulty: .micro,
            category: .mental,
            estimatedTimeMinutes: 3,
            tags: ["journaling", "mental clarity"],
            priority: 3
        ),
        
        ChallengeTemplate(
            title: "5-Minute Mind Dump",
            description: "Set a timer for 5 minutes and write down everything on your mind without stopping or editing.",
            path: .clarity,
            difficulty: .micro,
            category: .mental,
            estimatedTimeMinutes: 5,
            tags: ["journaling", "mental clarity"],
            priority: 2
        ),
        
        // Standard Clarity Challenges
        ChallengeTemplate(
            title: "10-Minute Meditation",
            description: "Sit quietly for 10 minutes focusing on your breath. Notice when your mind wanders and gently return to breathing.",
            path: .clarity,
            difficulty: .standard,
            category: .mental,
            estimatedTimeMinutes: 10,
            tags: ["meditation", "mindfulness"],
            priority: 4
        ),
        
        ChallengeTemplate(
            title: "Digital Sunset",
            description: "Turn off all screens 1 hour before your planned bedtime. Use this time for reading, journaling, or reflection.",
            path: .clarity,
            difficulty: .standard,
            category: .digital,
            estimatedTimeMinutes: 60,
            tags: ["digital detox", "evening", "sleep"],
            priority: 3
        ),
        
        // MARK: - Confidence Challenges
        
        // Micro Confidence Challenges
        ChallengeTemplate(
            title: "Compliment a Stranger",
            description: "Give a genuine compliment to someone you don't know. Practice expressing positivity and connecting with others.",
            path: .confidence,
            difficulty: .micro,
            category: .social,
            estimatedTimeMinutes: 2,
            tags: ["social", "kindness"],
            priority: 3
        ),
        
        ChallengeTemplate(
            title: "Speak Up in a Conversation",
            description: "The next time you're in a group conversation, share your opinion on the topic being discussed.",
            path: .confidence,
            difficulty: .micro,
            category: .social,
            estimatedTimeMinutes: 5,
            tags: ["social", "voice"],
            priority: 4
        ),
        
        ChallengeTemplate(
            title: "Stand Tall for 5 Minutes",
            description: "Spend 5 minutes standing or sitting with perfect posture. Embody confidence through your physical presence.",
            path: .confidence,
            difficulty: .micro,
            category: .physical,
            estimatedTimeMinutes: 5,
            tags: ["posture", "embodiment"],
            priority: 1
        ),
        
        // Standard Confidence Challenges
        ChallengeTemplate(
            title: "Start a Conversation with Someone New",
            description: "Initiate a conversation with someone you haven't talked to before. Practice stepping outside your social comfort zone.",
            path: .confidence,
            difficulty: .standard,
            category: .social,
            estimatedTimeMinutes: 10,
            tags: ["social", "networking"],
            priority: 4
        ),
        
        ChallengeTemplate(
            title: "Record a 2-Minute Video of Yourself",
            description: "Record yourself talking about something you're passionate about. Practice being comfortable with your own voice and image.",
            path: .confidence,
            difficulty: .standard,
            category: .creative,
            estimatedTimeMinutes: 15,
            tags: ["self-expression", "video"],
            priority: 3
        ),
        
        // MARK: - Purpose Challenges
        
        // Micro Purpose Challenges
        ChallengeTemplate(
            title: "Write Your 'Why' for Today",
            description: "Write one sentence describing why today matters to you and what you want to accomplish.",
            path: .purpose,
            difficulty: .micro,
            category: .spiritual,
            estimatedTimeMinutes: 3,
            tags: ["reflection", "purpose"],
            priority: 2
        ),
        
        ChallengeTemplate(
            title: "Identify One Core Value in Action",
            description: "Notice when you acted in alignment with one of your core values today and write it down.",
            path: .purpose,
            difficulty: .micro,
            category: .spiritual,
            estimatedTimeMinutes: 4,
            tags: ["values", "reflection"],
            priority: 3
        ),
        
        // Standard Purpose Challenges
        ChallengeTemplate(
            title: "Review Your 5-Year Vision",
            description: "Spend 15 minutes reviewing and refining your vision for where you want to be in 5 years.",
            path: .purpose,
            difficulty: .standard,
            category: .spiritual,
            estimatedTimeMinutes: 15,
            tags: ["vision", "planning"],
            priority: 4
        ),
        
        ChallengeTemplate(
            title: "Write a Letter to Future You",
            description: "Write a letter to yourself one year from now. Share your current challenges, hopes, and advice.",
            path: .purpose,
            difficulty: .standard,
            category: .creative,
            estimatedTimeMinutes: 20,
            tags: ["reflection", "future self"],
            priority: 3
        ),
        
        // MARK: - Authenticity Challenges
        
        // Micro Authenticity Challenges
        ChallengeTemplate(
            title: "Express One Genuine Emotion",
            description: "Share how you're really feeling with someone instead of giving the default 'I'm fine' response.",
            path: .authenticity,
            difficulty: .micro,
            category: .social,
            estimatedTimeMinutes: 3,
            tags: ["emotions", "honesty"],
            priority: 3
        ),
        
        ChallengeTemplate(
            title: "Say No to Something",
            description: "Practice saying no to a request that doesn't align with your priorities or values today.",
            path: .authenticity,
            difficulty: .micro,
            category: .social,
            estimatedTimeMinutes: 2,
            tags: ["boundaries", "saying no"],
            priority: 4
        ),
        
        // Standard Authenticity Challenges
        ChallengeTemplate(
            title: "Share Something Vulnerable",
            description: "Share something personal or vulnerable with someone you trust. Practice authentic connection.",
            path: .authenticity,
            difficulty: .standard,
            category: .social,
            estimatedTimeMinutes: 15,
            tags: ["vulnerability", "connection"],
            priority: 4
        ),
        
        ChallengeTemplate(
            title: "Do Something That Feels True to You",
            description: "Engage in an activity that feels authentically 'you,' even if others might not understand or approve.",
            path: .authenticity,
            difficulty: .standard,
            category: .creative,
            estimatedTimeMinutes: 30,
            tags: ["self-expression", "authenticity"],
            priority: 3
        )
    ]
}// Add morning-specific context to description
        if challenge.path == .discipline && challenge.category == .physical {
            modified.description += " Start your day with intention and energy."
        } else if challenge.path == .clarity && challenge.category == .mental {
            modified.description += " Begin your day with clarity and focus."
        }
        
        return modified
    }
    
    private static func addEveningContext(_ challenge: DailyChallenge) -> DailyChallenge {
        var modified = challenge
        
        // Add evening-specific context
        if challenge.category == .physical {
            modified.description += " Wind down your day with purposeful movement."
        } else if challenge.category == .mental {
            modified.description += " Reflect on your day and prepare for tomorrow."
        }
        
        return modified
    }
    
    private static func addContextualModifications(_ challenge: DailyChallenge) -> DailyChallenge {
        var modified = challenge
        
        
