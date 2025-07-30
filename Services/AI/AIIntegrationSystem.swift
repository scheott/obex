import SwiftUI
import Foundation
import Combine

// MARK: - AIResponse (AI response model)
struct AIResponse: Identifiable, Codable {
    var id: UUID = UUID()
    let content: String
    let type: ResponseType
    let confidence: Double // 0.0 to 1.0
    let generatedAt: Date
    let tokenCount: Int
    let model: String
    let context: ResponseContext?
    let suggestions: [String]
    let followUpQuestions: [String]
    
    init(content: String, type: ResponseType, confidence: Double = 0.8, model: String = "gpt-3.5-turbo", context: ResponseContext? = nil, suggestions: [String] = [], followUpQuestions: [String] = []) {
        self.content = content
        self.type = type
        self.confidence = confidence
        self.generatedAt = Date()
        self.tokenCount = content.components(separatedBy: .whitespacesAndNewlines).count
        self.model = model
        self.context = context
        self.suggestions = suggestions
        self.followUpQuestions = followUpQuestions
    }
    
    enum ResponseType: String, Codable {
        case checkIn = "check_in"
        case insight = "insight"
        case summary = "summary"
        case challenge = "challenge"
        case motivation = "motivation"
        case guidance = "guidance"
        
        var displayName: String {
            switch self {
            case .checkIn: return "Check-in Response"
            case .insight: return "Personal Insight"
            case .summary: return "Weekly Summary"
            case .challenge: return "Challenge Feedback"
            case .motivation: return "Motivation Boost"
            case .guidance: return "Guidance"
            }
        }
        
        var icon: String {
            switch self {
            case .checkIn: return "message.fill"
            case .insight: return "lightbulb.fill"
            case .summary: return "doc.text.fill"
            case .challenge: return "target"
            case .motivation: return "flame.fill"
            case .guidance: return "compass.drawing"
            }
        }
    }
    
    struct ResponseContext: Codable {
        let trainingPath: TrainingPath
        let timeOfDay: String?
        let userMood: String?
        let recentActivity: [String]
        let streakInfo: String?
    }
}

// MARK: - PersonalizedPrompt (Custom prompts)
struct PersonalizedPrompt: Identifiable, Codable {
    var id: UUID = UUID()
    let basePrompt: String
    let personalizations: [Personalization]
    let trainingPath: TrainingPath
    let difficulty: PromptDifficulty
    let category: PromptCategory
    let createdAt: Date
    let lastUsed: Date?
    let usageCount: Int
    let effectiveness: Double? // User feedback 0.0 to 1.0
    
    init(basePrompt: String, personalizations: [Personalization] = [], trainingPath: TrainingPath, difficulty: PromptDifficulty = .medium, category: PromptCategory) {
        self.basePrompt = basePrompt
        self.personalizations = personalizations
        self.trainingPath = trainingPath
        self.difficulty = difficulty
        self.category = category
        self.createdAt = Date()
        self.lastUsed = nil
        self.usageCount = 0
        self.effectiveness = nil
    }
    
    struct Personalization: Codable {
        let placeholder: String
        let replacement: String
        let type: PersonalizationType
        
        enum PersonalizationType: String, Codable {
            case name = "name"
            case streak = "streak"
            case recentProgress = "recent_progress"
            case mood = "mood"
            case timeOfDay = "time_of_day"
            case challenge = "challenge"
            case goal = "goal"
        }
    }
    
    enum PromptDifficulty: String, Codable {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
        case expert = "expert"
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
    
    enum PromptCategory: String, Codable {
        case reflection = "reflection"
        case motivation = "motivation"
        case planning = "planning"
        case assessment = "assessment"
        case creativity = "creativity"
        case problemSolving = "problem_solving"
        
        var displayName: String {
            switch self {
            case .reflection: return "Reflection"
            case .motivation: return "Motivation"
            case .planning: return "Planning"
            case .assessment: return "Assessment"
            case .creativity: return "Creativity"
            case .problemSolving: return "Problem Solving"
            }
        }
        
        var icon: String {
            switch self {
            case .reflection: return "thought.bubble"
            case .motivation: return "flame.fill"
            case .planning: return "calendar.badge.plus"
            case .assessment: return "checkmark.circle"
            case .creativity: return "paintbrush.fill"
            case .problemSolving: return "puzzle.piece.fill"
            }
        }
    }
    
    var personalizedContent: String {
        var content = basePrompt
        for personalization in personalizations {
            content = content.replacingOccurrences(of: "{\(personalization.placeholder)}", with: personalization.replacement)
        }
        return content
    }
}

// MARK: - WeeklySummary (Generated insights)
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
    let generationMetadata: GenerationMetadata
    
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
        self.generationMetadata = GenerationMetadata()
    }
    
    struct GenerationMetadata: Codable {
        let generatedAt: Date
        let dataPointsAnalyzed: Int
        let model: String
        let processingTime: TimeInterval
        
        init(dataPointsAnalyzed: Int = 0, model: String = "gpt-3.5-turbo", processingTime: TimeInterval = 0) {
            self.generatedAt = Date()
            self.dataPointsAnalyzed = dataPointsAnalyzed
            self.model = model
            self.processingTime = processingTime
        }
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

// MARK: - MoodAnalysis (Mood trend data)
struct MoodAnalysis: Identifiable, Codable {
    var id: UUID = UUID()
    let period: AnalysisPeriod
    let averageMood: Double // 1.0 to 5.0
    let moodTrend: TrendDirection
    let moodVariability: Double // Standard deviation
    let peakMoodDays: [Date]
    let lowMoodDays: [Date]
    let moodFactors: [MoodFactor]
    let recommendations: [String]
    let confidenceScore: Double
    let dataPoints: [MoodDataPoint]
    
    init(period: AnalysisPeriod, dataPoints: [MoodDataPoint]) {
        self.period = period
        self.dataPoints = dataPoints
        
        // Calculate statistics
        let moodValues = dataPoints.map { $0.averageMood }
        self.averageMood = moodValues.isEmpty ? 0 : moodValues.reduce(0, +) / Double(moodValues.count)
        
        // Determine trend
        if moodValues.count >= 2 {
            let firstHalf = Array(moodValues.prefix(moodValues.count / 2))
            let secondHalf = Array(moodValues.suffix(moodValues.count / 2))
            let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
            
            if secondAvg > firstAvg + 0.2 {
                self.moodTrend = .improving
            } else if secondAvg < firstAvg - 0.2 {
                self.moodTrend = .declining
            } else {
                self.moodTrend = .stable
            }
        } else {
            self.moodTrend = .stable
        }
        
        // Calculate variability (simplified standard deviation)
        let variance = moodValues.map { pow($0 - averageMood, 2) }.reduce(0, +) / Double(moodValues.count)
        self.moodVariability = sqrt(variance)
        
        // Identify peak and low days
        self.peakMoodDays = dataPoints.filter { $0.averageMood >= 4.0 }.map { $0.date }
        self.lowMoodDays = dataPoints.filter { $0.averageMood <= 2.0 }.map { $0.date }
        
        // Placeholder for mood factors (would be analyzed from context)
        self.moodFactors = []
        self.recommendations = []
        self.confidenceScore = min(Double(dataPoints.count) / 7.0, 1.0) // More data = higher confidence
    }
    
    enum AnalysisPeriod: String, Codable {
        case week = "week"
        case month = "month"
        case quarter = "quarter"
        case year = "year"
        
        var displayName: String {
            switch self {
            case .week: return "This Week"
            case .month: return "This Month"
            case .quarter: return "This Quarter"
            case .year: return "This Year"
            }
        }
    }
    
    enum TrendDirection: String, Codable {
        case improving = "improving"
        case stable = "stable"
        case declining = "declining"
        
        var color: Color {
            switch self {
            case .improving: return .green
            case .stable: return .blue
            case .declining: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .declining: return "arrow.down.right"
            }
        }
    }
    
    struct MoodFactor: Identifiable, Codable {
        var id: UUID = UUID()
        let factor: String
        let impact: Double // -1.0 to 1.0
        let confidence: Double // 0.0 to 1.0
        let occurrences: Int
        
        var impactDescription: String {
            if impact > 0.3 {
                return "Strongly positive"
            } else if impact > 0.1 {
                return "Positive"
            } else if impact < -0.3 {
                return "Strongly negative"
            } else if impact < -0.1 {
                return "Negative"
            } else {
                return "Neutral"
            }
        }
    }
}

// MARK: - CustomChallenge (Personalized challenges)
struct CustomChallenge: Identifiable, Codable {
    var id: UUID = UUID()
    let baseChallenge: DailyChallenge
    let personalizations: [ChallengePersonalization]
    let aiReasoning: String
    let difficulty: ChallengeDifficulty
    let estimatedTime: Int // minutes
    let prerequisites: [String]
    let adaptations: [String]
    let successMetrics: [String]
    let fallbackOptions: [String]
    let createdAt: Date
    
    init(baseChallenge: DailyChallenge, personalizations: [ChallengePersonalization] = [], aiReasoning: String = "", difficulty: ChallengeDifficulty = .medium) {
        self.baseChallenge = baseChallenge
        self.personalizations = personalizations
        self.aiReasoning = aiReasoning
        self.difficulty = difficulty
        self.estimatedTime = baseChallenge.estimatedTimeMinutes
        self.prerequisites = []
        self.adaptations = []
        self.successMetrics = []
        self.fallbackOptions = []
        self.createdAt = Date()
    }
    
    struct ChallengePersonalization: Codable {
        let aspect: PersonalizationAspect
        let originalValue: String
        let personalizedValue: String
        let reason: String
        
        enum PersonalizationAspect: String, Codable {
            case title = "title"
            case description = "description"
            case timeFrame = "time_frame"
            case difficulty = "difficulty"
            case context = "context"
            case method = "method"
        }
    }
    
    var personalizedChallenge: DailyChallenge {
        var challenge = baseChallenge
        
        for personalization in personalizations {
            switch personalization.aspect {
            case .title:
                challenge = DailyChallenge(
                    title: personalization.personalizedValue,
                    description: challenge.description,
                    path: challenge.path,
                    difficulty: challenge.difficulty,
                    date: challenge.date,
                    estimatedTimeMinutes: challenge.estimatedTimeMinutes,
                    category: challenge.category,
                    tags: challenge.tags
                )
            case .description:
                challenge = DailyChallenge(
                    title: challenge.title,
                    description: personalization.personalizedValue,
                    path: challenge.path,
                    difficulty: challenge.difficulty,
                    date: challenge.date,
                    estimatedTimeMinutes: challenge.estimatedTimeMinutes,
                    category: challenge.category,
                    tags: challenge.tags
                )
            default:
                break
            }
        }
        
        return challenge
    }
}

// MARK: - AIError (Error handling enum)
enum AIError: Error, LocalizedError {
    case invalidAPIKey
    case rateLimitExceeded
    case networkError(Error)
    case invalidResponse
    case contentFiltered
    case contextTooLong
    case modelOverloaded
    case insufficientData
    case authenticationFailed
    case quotaExceeded
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .rateLimitExceeded:
            return "You've reached your AI usage limit. Please try again later."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received an invalid response from the AI service."
        case .contentFiltered:
            return "Your request was filtered for safety reasons."
        case .contextTooLong:
            return "Your input is too long. Please try with shorter text."
        case .modelOverloaded:
            return "AI service is currently overloaded. Please try again in a moment."
        case .insufficientData:
            return "Not enough data to generate a meaningful response."
        case .authenticationFailed:
            return "Authentication failed. Please check your account status."
        case .quotaExceeded:
            return "Your AI quota has been exceeded. Please upgrade your plan."
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var recoveryAction: String? {
        switch self {
        case .invalidAPIKey:
            return "Contact support for assistance"
        case .rateLimitExceeded:
            return "Wait a moment and try again"
        case .networkError:
            return "Check your internet connection"
        case .invalidResponse:
            return "Try again with different input"
        case .contentFiltered:
            return "Rephrase your request"
        case .contextTooLong:
            return "Shorten your input"
        case .modelOverloaded:
            return "Try again in a few minutes"
        case .insufficientData:
            return "Use the app more to generate better insights"
        case .authenticationFailed:
            return "Sign out and sign back in"
        case .quotaExceeded:
            return "Upgrade to Pro for unlimited AI features"
        case .unknown:
            return "Try again later"
        }
    }
    
    var icon: String {
        switch self {
        case .invalidAPIKey, .authenticationFailed:
            return "key.slash"
        case .rateLimitExceeded, .quotaExceeded:
            return "clock.badge.exclamationmark"
        case .networkError:
            return "wifi.slash"
        case .invalidResponse, .unknown:
            return "exclamationmark.triangle"
        case .contentFiltered:
            return "shield.slash"
        case .contextTooLong:
            return "text.badge.minus"
        case .modelOverloaded:
            return "server.rack"
        case .insufficientData:
            return "chart.bar.doc.horizontal"
        }
    }
}

// MARK: - AI Manager
class AIManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastError: AIError?
    @Published var usageStats: UsageStats = UsageStats()
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let session = URLSession.shared
    
    init() {
        // In production, load from secure storage or environment variables
        self.apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-api-key-here"
    }
    
    struct UsageStats: Codable {
        var requestsToday: Int = 0
        var tokensUsedToday: Int = 0
        var lastResetDate: Date = Date()
        var totalRequests: Int = 0
        var totalTokens: Int = 0
        
        mutating func recordUsage(tokens: Int) {
            let calendar = Calendar.current
            if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
                requestsToday = 0
                tokensUsedToday = 0
                lastResetDate = Date()
            }
            
            requestsToday += 1
            tokensUsedToday += tokens
            totalRequests += 1
            totalTokens += tokens
        }
    }
    
    // MARK: - AI Response Generation
    func generateAIResponse(
        prompt: PersonalizedPrompt,
        context: AIResponse.ResponseContext
    ) async -> Result<AIResponse, AIError> {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            lastError = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let response = try await callOpenAI(
                systemPrompt: createSystemPrompt(for: prompt, context: context),
                userPrompt: prompt.personalizedContent,
                maxTokens: 200
            )
            
            let aiResponse = AIResponse(
                content: response,
                type: determineResponseType(from: prompt.category),
                context: context
            )
            
            await MainActor.run {
                usageStats.recordUsage(tokens: aiResponse.tokenCount)
            }
            
            return .success(aiResponse)
            
        } catch let error as AIError {
            await MainActor.run {
                lastError = error
                errorMessage = error.localizedDescription
            }
            return .failure(error)
        } catch {
            let aiError = AIError.unknown(error.localizedDescription)
            await MainActor.run {
                lastError = aiError
                errorMessage = aiError.localizedDescription
            }
            return .failure(aiError)
        }
    }
    
    func generateWeeklySummary(
        journalEntries: [JournalEntry],
        completedChallenges: [DailyChallenge],
        checkIns: [AICheckIn],
        trainingPath: TrainingPath
    ) async -> Result<WeeklySummary, AIError> {
        
        let startTime = Date()
        
        do {
            let systemPrompt = createWeeklySummarySystemPrompt(trainingPath: trainingPath)
            let weekData = createWeeklyDataPrompt(
                journalEntries: journalEntries,
                completedChallenges: completedChallenges,
                checkIns: checkIns
            )
            
            let summaryText = try await callOpenAI(
                systemPrompt: systemPrompt,
                userPrompt: weekData,
                maxTokens: 300
            )
            
            let keyThemes = try await extractKeyThemes(from: journalEntries)
            let processingTime = Date().timeIntervalSince(startTime)
            
            let summary = WeeklySummary(
                weekStartDate: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date(),
                weekEndDate: Date(),
                summary: summaryText,
                keyThemes: keyThemes,
                challengesCompleted: completedChallenges.count,
                checkinStreak: calculateCheckInStreak(checkIns)
            )
            
            return .success(summary)
            
        } catch let error as AIError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    func generateCustomChallenge(
        baseChallenge: DailyChallenge,
        userContext: String,
        recentProgress: String
    ) async -> Result<CustomChallenge, AIError> {
        
        do {
            let systemPrompt = createChallengeCustomizationPrompt()
            let userPrompt = """
            Base Challenge: \(baseChallenge.title)
            Description: \(baseChallenge.description)
            
            User Context: \(userContext)
            Recent Progress: \(recentProgress)
            
            Please customize this challenge to be more relevant and achievable for this user.
            """
            
            let customizedContent = try await callOpenAI(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                maxTokens: 150
            )
            
            let customChallenge = CustomChallenge(
                baseChallenge: baseChallenge,
                aiReasoning: "Customized based on user context and recent progress"
            )
            
            return .success(customChallenge)
            
        } catch let error as AIError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    func analyzeMood(dataPoints: [MoodDataPoint], period: MoodAnalysis.AnalysisPeriod) -> MoodAnalysis {
        return MoodAnalysis(period: period, dataPoints: dataPoints)
    }
    
    // MARK: - Private Helper Methods
    private func callOpenAI(systemPrompt: String, userPrompt: String, maxTokens: Int) async throws -> String {
        guard !apiKey.isEmpty && apiKey != "your-api-key-here" else {
            throw AIError.invalidAPIKey
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": maxTokens,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.networkError(URLError(.badServerResponse))
            }
            
            switch httpResponse.statusCode {
            case 200:
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    return content.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    throw AIError.invalidResponse
                }
            case 401:
                throw AIError.authenticationFailed
            case 429:
                throw AIError.rateLimitExceeded
            case 503:
                throw AIError.modelOverloaded
            default:
                throw AIError.unknown("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.networkError(error)
        }
    }
    
    private func createSystemPrompt(for prompt: PersonalizedPrompt, context: AIResponse.ResponseContext) -> String {
        return """
        You are an AI mentor specializing in personal development, particularly in \(context.trainingPath.displayName.lowercased()). 
        
        Provide supportive, actionable guidance that helps users grow in their chosen path. Be encouraging but realistic, 
        and tailor your response to their current context and mood.
        
        Current context:
        - Training Path: \(context.trainingPath.displayName)
        - Time of Day: \(context.timeOfDay ?? "Unknown")
        - User Mood: \(context.userMood ?? "Not specified")
        - Recent Activity: \(context.recentActivity.joined(separator: ", "))
        
        Keep responses concise, practical, and motivational.
        """
    }
    
    private func createWeeklySummarySystemPrompt(trainingPath: TrainingPath) -> String {
        return """
        You are an AI mentor creating a weekly summary for someone focused on \(trainingPath.displayName.lowercased()).
        
        Analyze their weekly activity and provide:
        1. Key insights about their progress
        2. Patterns you notice in their growth
        3. Specific acknowledgment of their efforts
        4. Gentle guidance for continued development
        5. Encouragement that feels personal and genuine
        
        Keep the tone warm, wise, and supportive. Focus on growth over perfection.
        """
    }
    
    private func createChallengeCustomizationPrompt() -> String {
        return """
        You are an AI mentor helping customize daily challenges for personal development.
        
        Take the base challenge and modify it to be more personalized and relevant based on the user's 
        context and recent progress. Keep the core intent but make it more specific and achievable.
        
        Return only the customized challenge title and description, maintaining a motivational tone.
        """
    }
    
    private func createWeeklyDataPrompt(
        journalEntries: [JournalEntry],
        completedChallenges: [DailyChallenge],
        checkIns: [AICheckIn]
    ) -> String {
        var prompt = "Weekly Activity Summary:\n\n"
        
        prompt += "Challenges Completed (\(completedChallenges.count)):\n"
        for challenge in completedChallenges.prefix(5) {
            prompt += "- \(challenge.title)\n"
        }
        
        prompt += "\nJournal Entries (\(journalEntries.count)):\n"
        for entry in journalEntries.prefix(3) {
            let preview = String(entry.content.prefix(100))
            prompt += "- \(preview)...\n"
        }
        
        prompt += "\nCheck-ins (\(checkIns.count)):\n"
        for checkIn in checkIns.prefix(3) {
            if let response = checkIn.userResponse {
                let preview = String(response.prefix(100))
                prompt += "- \(preview)...\n"
            }
        }
        
        return prompt
    }
    
    private func extractKeyThemes(from entries: [JournalEntry]) async throws -> [String] {
        // Simplified theme extraction - in production, this would use more sophisticated analysis
        let allText = entries.map { $0.content }.joined(separator: " ")
        let words = allText.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        // Count word frequency and extract themes
        var wordCount: [String: Int] = [:]
        for word in words {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            if cleanWord.count > 4 { // Only meaningful words
                wordCount[cleanWord, default: 0] += 1
            }
        }
        
        // Return most frequent meaningful words as themes
        return Array(wordCount.sorted { $0.value > $1.value }.prefix(5).map { $0.key })
    }
    
    private func calculateCheckInStreak(_ checkIns: [AICheckIn]) -> Int {
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        
        for day in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -day, to: today)!
            let hasCheckIn = checkIns.contains { calendar.isDate($0.date, inSameDayAs: date) }
            
            if hasCheckIn {
                streak += 1
            } else if day == 0 {
                // If no check-in today, streak is broken
                break
            }
        }
        
        return streak
    }
    
    private func determineResponseType(from category: PersonalizedPrompt.PromptCategory) -> AIResponse.ResponseType {
        switch category {
        case .reflection: return .insight
        case .motivation: return .motivation
        case .planning: return .guidance
        case .assessment: return .checkIn
        case .creativity: return .insight
        case .problemSolving: return .guidance
        }
    }
}

// MARK: - AI Usage Tracker
class AIUsageTracker: ObservableObject {
    @Published var requestsToday: Int = 0
    @Published var requestsThisHour: Int = 0
    @Published var lastRequestTime: Date?
    
    private let userDefaults = UserDefaults.standard
    private let requestLimit = 50 // Per hour for pro users
    private let freeUserDailyLimit = 10
    
    init() {
        loadUsageData()
    }
    
    func canMakeRequest(userTier: SubscriptionTier = .free) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // Reset counters if needed
        if let lastRequest = lastRequestTime {
            if !calendar.isDate(lastRequest, inSameDayAs: now) {
                requestsToday = 0
            }
            
            if !calendar.isDate(lastRequest, equalTo: now, toGranularity: .hour) {
                requestsThisHour = 0
            }
        }
        
        // Check limits based on user tier
        switch userTier {
        case .free:
            return requestsToday < freeUserDailyLimit
        case .pro, .premium:
            return requestsThisHour < requestLimit
        }
    }
    
    func recordRequest() {
        requestsToday += 1
        requestsThisHour += 1
        lastRequestTime = Date()
        saveUsageData()
    }
    
    private func loadUsageData() {
        requestsToday = userDefaults.integer(forKey: "ai_requests_day")
        requestsThisHour = userDefaults.integer(forKey: "ai_requests_hour")
        if let lastRequest = userDefaults.object(forKey: "ai_last_request") as? Date {
            lastRequestTime = lastRequest
        }
    }
    
    private func saveUsageData() {
        userDefaults.set(requestsToday, forKey: "ai_requests_day")
        userDefaults.set(requestsThisHour, forKey: "ai_requests_hour")
        userDefaults.set(lastRequestTime, forKey: "ai_last_request")
    }
}

// MARK: - AI Enhanced Views

struct AIResponseView: View {
    let response: AIResponse
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: response.type.icon)
                    .foregroundColor(.purple)
                
                Text(response.type.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Confidence indicator
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index < Int(response.confidence * 5) ? Color.purple : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            
            // Content
            Text(response.content)
                .font(.body)
                .lineLimit(isExpanded ? nil : 4)
                .animation(.easeInOut, value: isExpanded)
            
            // Expand/Collapse
            if response.content.count > 200 {
                Button(isExpanded ? "Show Less" : "Show More") {
                    isExpanded.toggle()
                }
                .font(.caption)
                .foregroundColor(.purple)
            }
            
            // Suggestions
            if !response.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(response.suggestions, id: \.self) { suggestion in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(suggestion)
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 8)
            }
            
            // Metadata
            HStack {
                Text("Generated \(response.generatedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(response.tokenCount) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MoodAnalysisView: View {
    let analysis: MoodAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                
                Text("Mood Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(analysis.period.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Average Mood
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average Mood")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(String(format: "%.1f", analysis.averageMood))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("/ 5.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Trend indicator
                HStack {
                    Image(systemName: analysis.moodTrend.icon)
                        .foregroundColor(analysis.moodTrend.color)
                    
                    Text(analysis.moodTrend.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(analysis.moodTrend.color)
                }
            }
            
            // Mood Chart (simplified)
            if !analysis.dataPoints.isEmpty {
                moodChartView
            }
            
            // Insights
            if !analysis.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Insights:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(analysis.recommendations, id: \.self) { recommendation in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(recommendation)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var moodChartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood Trend")
                .font(.caption)
                .fontWeight(.medium)
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(analysis.dataPoints.prefix(7), id: \.id) { dataPoint in
                    Rectangle()
                        .fill(colorForMood(dataPoint.averageMood))
                        .frame(width: 30, height: CGFloat(dataPoint.averageMood * 20))
                        .cornerRadius(4)
                }
            }
            .frame(height: 100)
        }
    }
    
    private func colorForMood(_ mood: Double) -> Color {
        if mood >= 4.0 {
            return .green
        } else if mood >= 3.0 {
            return .blue
        } else if mood >= 2.0 {
            return .orange
        } else {
            return .red
        }
    }
}

struct WeeklySummaryCard: View {
    let summary: WeeklySummary
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(summary.formattedDateRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Mood trend indicator
                HStack {
                    Image(systemName: summary.moodTrend.icon)
                        .foregroundColor(summary.moodTrend.color)
                    
                    Text(summary.moodTrend.displayName)
                        .font(.caption)
                        .foregroundColor(summary.moodTrend.color)
                }
            }
            
            // Summary text
            Text(summary.summary)
                .font(.body)
                .lineLimit(isExpanded ? nil : 4)
                .animation(.easeInOut, value: isExpanded)
            
            if summary.summary.count > 300 {
                Button(isExpanded ? "Show Less" : "Read More") {
                    isExpanded.toggle()
                }
                .font(.caption)
                .foregroundColor(.purple)
            }
            
            // Key themes
            if !summary.keyThemes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Themes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(summary.keyThemes, id: \.self) { theme in
                            Text(theme)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Stats
            HStack {
                StatItem(title: "Challenges", value: "\(summary.challengesCompleted)")
                Spacer()
                StatItem(title: "Check-in Streak", value: "\(summary.checkinStreak)")
                Spacer()
                StatItem(title: "AI Confidence", value: "\(Int(summary.aiConfidenceScore * 100))%")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Error Handling View
struct AIErrorView: View {
    let error: AIError
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: error.icon)
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("AI Error")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let recoveryAction = error.recoveryAction {
                    Text(recoveryAction)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if let retryAction = retryAction {
                Button("Try Again") {
                    retryAction()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct AIIntegrationSystem_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                AIResponseView(response: AIResponse(
                    content: "Great job on completing your daily challenge! I can see you're building consistency in your discipline practice. Consider focusing on one specific area tomorrow to deepen your growth.",
                    type: .checkIn,
                    suggestions: ["Focus on morning routines", "Set specific time blocks"],
                    followUpQuestions: ["What felt most challenging today?", "How can you improve tomorrow?"]
                ))
                
                MoodAnalysisView(analysis: MoodAnalysis(
                    period: .week,
                    dataPoints: [
                        MoodDataPoint(date: Date(), averageMood: 4.2),
                        MoodDataPoint(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, averageMood: 3.8),
                        MoodDataPoint(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, averageMood: 4.5)
                    ]
                ))
                
                AIErrorView(error: .rateLimitExceeded, retryAction: {})
            }
            .padding()
        }
    }
}
