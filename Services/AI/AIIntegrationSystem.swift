import SwiftUI
import Foundation

// MARK: - AI Manager
class AIManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    
    init() {
        // In production, load from secure storage or environment variables
        self.apiKey = "your-openai-api-key-here"
    }
    
    // MARK: - Check-in AI Integration
    func generateCheckInResponse(
        userInput: String,
        timeOfDay: AICheckIn.CheckInTime,
        trainingPath: TrainingPath,
        mood: AICheckIn.MoodRating?
    ) async -> String {
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let systemPrompt = createCheckInSystemPrompt(
            timeOfDay: timeOfDay,
            trainingPath: trainingPath
        )
        
        let userPrompt = createCheckInUserPrompt(
            userInput: userInput,
            mood: mood
        )
        
        do {
            let response = try await callOpenAI(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                maxTokens: 150
            )
            
            await MainActor.run {
                isLoading = false
            }
            
            return response
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to get AI response. Please try again."
            }
            
            // Fallback to template response
            return getTemplateCheckInResponse(
                timeOfDay: timeOfDay,
                trainingPath: trainingPath,
                mood: mood
            )
        }
    }
    
    // MARK: - Weekly Summary Generation
    func generateWeeklySummary(
        journalEntries: [JournalEntry],
        completedChallenges: [DailyChallenge],
        checkIns: [AICheckIn],
        trainingPath: TrainingPath
    ) async -> WeeklySummary {
        
        await MainActor.run {
            isLoading = true
        }
        
        let systemPrompt = """
        You are an AI mentor specializing in personal development. Analyze the user's weekly activity and provide insightful, supportive feedback focused on their \(trainingPath.displayName.lowercased()) journey.
        
        Create a weekly summary that:
        1. Highlights key patterns and growth
        2. Identifies themes from their reflections
        3. Acknowledges their progress and challenges
        4. Provides encouraging, actionable insights
        5. Recommends focus areas for the upcoming week
        
        Keep the tone supportive, wise, and motivational. Be specific about their progress.
        """
        
        let weekData = createWeeklyDataPrompt(
            journalEntries: journalEntries,
            completedChallenges: completedChallenges,
            checkIns: checkIns
        )
        
        do {
            let summaryText = try await callOpenAI(
                systemPrompt: systemPrompt,
                userPrompt: weekData,
                maxTokens: 300
            )
            
            let keyThemes = try await extractKeyThemes(from: journalEntries)
            
            await MainActor.run {
                isLoading = false
            }
            
            return WeeklySummary(
                weekStartDate: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date(),
                weekEndDate: Date(),
                summary: summaryText,
                keyThemes: keyThemes,
                challengesCompleted: completedChallenges.count,
                checkinStreak: calculateCheckInStreak(checkIns),
                recommendedFocus: determineRecommendedFocus(from: journalEntries)
            )
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to generate weekly summary."
            }
            
            // Fallback to template summary
            return createTemplateWeeklySummary(
                journalEntries: journalEntries,
                completedChallenges: completedChallenges,
                checkIns: checkIns,
                trainingPath: trainingPath
            )
        }
    }
    
    // MARK: - Challenge Customization
    func customizeChallenge(
        baseChallenge: DailyChallenge,
        userContext: String,
        recentProgress: String
    ) async -> DailyChallenge {
        
        let systemPrompt = """
        You are an AI mentor helping customize daily challenges for personal development. 
        
        Modify the given challenge to be more personalized and relevant based on the user's context and recent progress. Keep the core intent but make it more specific and achievable for this individual.
        
        Return only the customized challenge title and description, maintaining the motivational and actionable tone.
        """
        
        let userPrompt = """
        Base Challenge: \(baseChallenge.title)
        Description: \(baseChallenge.description)
        
        User Context: \(userContext)
        Recent Progress: \(recentProgress)
        
        Please customize this challenge to be more personal and relevant.
        """
        
        do {
            let customizedText = try await callOpenAI(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                maxTokens: 100
            )
            
            // Parse the response to extract title and description
            let (title, description) = parseCustomizedChallenge(customizedText)
            
            return DailyChallenge(
                title: title,
                description: description,
                path: baseChallenge.path,
                difficulty: baseChallenge.difficulty,
                date: baseChallenge.date
            )
            
        } catch {
            // Return original challenge if customization fails
            return baseChallenge
        }
    }
    
    // MARK: - Smart Insights
    func generateSmartInsight(
        userProfile: UserProfile,
        recentActivity: [String],
        trainingPath: TrainingPath
    ) async -> String {
        
        let systemPrompt = """
        You are a wise AI mentor providing personalized insights for someone on a \(trainingPath.displayName.lowercased()) journey.
        
        Generate a short, powerful insight based on their recent activity. This should be:
        - Encouraging and supportive
        - Specific to their situation
        - Actionable and practical
        - No more than 2 sentences
        
        Focus on patterns, growth opportunities, or celebrating progress.
        """
        
        let userPrompt = """
        User has been working on \(trainingPath.displayName.lowercased()) for \(userProfile.totalChallengesCompleted) days.
        Current streak: \(userProfile.currentStreak) days
        Recent activity: \(recentActivity.joined(separator: ", "))
        
        Provide a supportive insight.
        """
        
        do {
            let insight = try await callOpenAI(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                maxTokens: 80
            )
            
            return insight
        } catch {
            return getTemplateInsight(for: trainingPath, streak: userProfile.currentStreak)
        }
    }
    
    // MARK: - OpenAI API Call
    private func callOpenAI(
        systemPrompt: String,
        userPrompt: String,
        maxTokens: Int = 150
    ) async throws -> String {
        
        guard !apiKey.isEmpty && apiKey != "your-openai-api-key-here" else {
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.networkError
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIError.noResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Helper Methods
    private func createCheckInSystemPrompt(
        timeOfDay: AICheckIn.CheckInTime,
        trainingPath: TrainingPath
    ) -> String {
        let timeContext = timeOfDay == .morning ? "starting their day" : "reflecting on their day"
        
        return """
        You are a supportive AI mentor helping someone build \(trainingPath.displayName.lowercased()). 
        
        The user is \(timeContext). Respond with encouragement, practical advice, or thoughtful questions. 
        
        Keep responses:
        - Warm and supportive
        - Specific to \(trainingPath.displayName.lowercased()) development
        - 1-2 sentences maximum
        - Actionable when possible
        
        Focus on their \(trainingPath.description.lowercased()).
        """
    }
    
    private func createCheckInUserPrompt(
        userInput: String,
        mood: AICheckIn.MoodRating?
    ) -> String {
        var prompt = "User says: \"\(userInput)\""
        
        if let mood = mood {
            prompt += "\nTheir current mood: \(mood.rawValue)"
        }
        
        return prompt
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
        
        prompt += "\nKey Journal Reflections:\n"
        for entry in journalEntries.suffix(3) {
            let excerpt = String(entry.content.prefix(100))
            prompt += "- \(excerpt)...\n"
        }
        
        prompt += "\nCheck-in Highlights:\n"
        for checkIn in checkIns.suffix(3) {
            if let response = checkIn.userResponse {
                let excerpt = String(response.prefix(80))
                prompt += "- \(excerpt)...\n"
            }
        }
        
        return prompt
    }
    
    // MARK: - Template Responses (Fallbacks)
    private func getTemplateCheckInResponse(
        timeOfDay: AICheckIn.CheckInTime,
        trainingPath: TrainingPath,
        mood: AICheckIn.MoodRating?
    ) -> String {
        
        let responses: [String]
        
        switch (timeOfDay, trainingPath) {
        case (.morning, .discipline):
            responses = [
                "Great energy! Start with one small action that builds momentum for your day.",
                "Your commitment to growth is inspiring. What's your first disciplined choice today?",
                "Every morning is a fresh chance to strengthen your discipline muscle. You've got this!"
            ]
        case (.evening, .discipline):
            responses = [
                "Reflect on the disciplined choices you made today. Each one builds your strength.",
                "How did you push through resistance today? Those moments define your growth.",
                "Consistency over perfection. Celebrate the discipline you showed today."
            ]
        case (.morning, .clarity):
            responses = [
                "Take a moment to center yourself. What clarity do you need for today?",
                "Your mind is like water - let it settle and see clearly.",
                "What thoughts will serve your highest good today?"
            ]
        case (.evening, .clarity):
            responses = [
                "What insights emerged from today's experiences?",
                "How did you create space for clarity in the chaos?",
                "Reflect on the moments when your mind felt most clear today."
            ]
        case (.morning, .confidence):
            responses = [
                "You have everything within you to handle today. Trust yourself.",
                "Confidence grows from action. What brave step will you take today?",
                "Your authentic voice matters. How will you share it today?"
            ]
        case (.evening, .confidence):
            responses = [
                "Where did you show courage today, even in small ways?",
                "How did you honor your authentic self today?",
                "Confidence builds through action. Celebrate your brave moments."
            ]
        case (.morning, .purpose):
            responses = [
                "How will your actions today align with your deeper purpose?",
                "What meaningful impact can you create today?",
                "Your unique gifts are needed in the world. How will you share them?"
            ]
        case (.evening, .purpose):
            responses = [
                "How did you live your values today?",
                "What gave you the deepest sense of meaning today?",
                "Reflect on how today's actions moved you toward your purpose."
            ]
        case (.morning, .authenticity):
            responses = [
                "Be courageously yourself today. The world needs your authentic gifts.",
                "What would it look like to be completely true to yourself today?",
                "Your authenticity is your superpower. How will you embrace it?"
            ]
        case (.evening, .authenticity):
            responses = [
                "Where did you feel most like yourself today?",
                "How did you honor your true nature today?",
                "Reflect on the moments when you felt most authentic."
            ]
        }
        
        return responses.randomElement() ?? "Keep growing, one day at a time."
    }
    
    private func getTemplateInsight(for path: TrainingPath, streak: Int) -> String {
        switch path {
        case .discipline:
            if streak < 7 {
                return "Building discipline is like building muscle - every rep counts, even when it's hard."
            } else {
                return "Your consistent effort is creating lasting change. Trust the process."
            }
        case .clarity:
            return "Clarity comes not from having all the answers, but from asking better questions."
        case .confidence:
            return "Confidence isn't about feeling fearless - it's about taking action despite the fear."
        case .purpose:
            return "Purpose isn't found, it's created through the meaning you give your actions."
        case .authenticity:
            return "The more authentic you become, the more magnetic your presence becomes."
        }
    }
    
    private func extractKeyThemes(from entries: [JournalEntry]) async throws -> [String] {
        // Simple keyword extraction - could be enhanced with more sophisticated NLP
        let allText = entries.map { $0.content }.joined(separator: " ").lowercased()
        
        let commonThemes = [
            "growth", "challenge", "fear", "confidence", "progress", "struggle",
            "success", "learning", "change", "habit", "discipline", "focus",
            "clarity", "purpose", "authentic", "relationship", "work", "health"
        ]
        
        return commonThemes.filter { theme in
            allText.contains(theme)
        }.prefix(3).map { $0.capitalized }
    }
    
    private func calculateCheckInStreak(_ checkIns: [AICheckIn]) -> Int {
        // Calculate consecutive days with check-ins
        let calendar = Calendar.current
        let today = Date()
        
        var streak = 0
        var currentDate = today
        
        for _ in 0..<30 { // Check last 30 days
            let dayCheckIns = checkIns.filter { checkIn in
                calendar.isDate(checkIn.date, inSameDayAs: currentDate)
            }
            
            if dayCheckIns.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streak
    }
    
    private func determineRecommendedFocus(from entries: [JournalEntry]) -> TrainingPath? {
        // Simple analysis of journal content to recommend focus area
        let allText = entries.map { $0.content }.joined(separator: " ").lowercased()
        
        let pathKeywords: [TrainingPath: [String]] = [
            .discipline: ["discipline", "habit", "routine", "consistency", "willpower"],
            .clarity: ["clarity", "focus", "mindfulness", "meditation", "thoughts"],
            .confidence: ["confidence", "fear", "courage", "self-doubt", "social"],
            .purpose: ["purpose", "meaning", "values", "direction", "goals"],
            .authenticity: ["authentic", "true", "genuine", "real", "honest"]
        ]
        
        var pathScores: [TrainingPath: Int] = [:]
        
        for (path, keywords) in pathKeywords {
            let score = keywords.reduce(0) { count, keyword in
                count + allText.components(separatedBy: keyword).count - 1
            }
            pathScores[path] = score
        }
        
        return pathScores.max(by: { $0.value < $1.value })?.key
    }
    
    private func parseCustomizedChallenge(_ text: String) -> (String, String) {
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        if lines.count >= 2 {
            return (lines[0], lines[1])
        } else if lines.count == 1 {
            return (lines[0], "Customized challenge for your growth journey.")
        } else {
            return ("Custom Challenge", "A personalized challenge for your development.")
        }
    }
    
    private func createTemplateWeeklySummary(
        journalEntries: [JournalEntry],
        completedChallenges: [DailyChallenge],
        checkIns: [AICheckIn],
        trainingPath: TrainingPath
    ) -> WeeklySummary {
        
        let summaryText = """
        This week you focused on \(trainingPath.displayName.lowercased()) and completed \(completedChallenges.count) challenges. 
        Your dedication to growth is evident in your consistent effort. 
        Keep building on this momentum as you continue your journey.
        """
        
        return WeeklySummary(
            weekStartDate: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date(),
            weekEndDate: Date(),
            summary: summaryText,
            keyThemes: ["Growth", "Progress", "Consistency"],
            challengesCompleted: completedChallenges.count,
            checkinStreak: calculateCheckInStreak(checkIns),
            recommendedFocus: trainingPath
        )
    }
}

// MARK: - AI Error Types
enum AIError: Error, LocalizedError {
    case invalidAPIKey
    case networkError
    case noResponse
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .networkError:
            return "Network error. Please check your connection."
        case .noResponse:
            return "No response from AI service."
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        }
    }
}

// MARK: - OpenAI Response Models
struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

// MARK: - AI Configuration
struct AIConfiguration {
    static let maxRetries = 3
    static let timeoutInterval: TimeInterval = 30
    static let defaultModel = "gpt-3.5-turbo"
    
    // Rate limiting
    static let maxRequestsPerHour = 100
    static let maxRequestsPerDay = 1000
}

// MARK: - AI Usage Tracking
class AIUsageTracker: ObservableObject {
    @Published var requestsThisHour = 0
    @Published var requestsToday = 0
    @Published var lastRequestTime = Date()
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadUsageData()
    }
    
    func canMakeRequest() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // Reset hourly count if hour has passed
        if !calendar.isDate(lastRequestTime, equalTo: now, toGranularity: .hour) {
            requestsThisHour = 0
        }
        
        // Reset daily count if day has passed
        if !calendar.isDate(lastRequestTime, equalTo: now, toGranularity: .day) {
            requestsToday = 0
        }
        
        return requestsThisHour < AIConfiguration.maxRequestsPerHour &&
               requestsToday < AIConfiguration.maxRequestsPerDay
    }
    
    func recordRequest() {
        requestsThisHour += 1
        requestsToday += 1
        lastRequestTime = Date()
        saveUsageData()
    }
    
    private func loadUsageData() {
        requestsThisHour = userDefaults.integer(forKey: "ai_requests_hour")
        requestsToday = userDefaults.integer(forKey: "ai_requests_day")
        if let lastRequest = userDefaults.object(forKey: "ai_last_request") as? Date {
            lastRequestTime = lastRequest
        }
    }
    
    private func saveUsageData() {
        userDefaults.set(requestsThisHour, forKey: "ai_requests_hour")
        userDefaults.set(requestsToday, forKey: "ai_requests_day")
        userDefaults.set(lastRequestTime, forKey: "ai_last_request")
    }
}

// MARK: - AI Enhanced Views

// Enhanced Check-In View with AI
struct AIEnhancedCheckInView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var aiManager = AIManager()
    @StateObject private var usageTracker = AIUsageTracker()
    
    @State private var userInput = ""
    @State private var selectedMood: AICheckIn.MoodRating?
    @State private var timeOfDay: AICheckIn.CheckInTime = .morning
    @State private var aiResponse = ""
    @State private var showingResponse = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: timeOfDay == .morning ? "sun.max.fill" : "moon.stars.fill")
                            .font(.system(size: 50))
                            .foregroundColor(timeOfDay == .morning ? .orange : .indigo)
                        
                        Text("\(timeOfDay.displayName) Check-in")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(timeOfDay == .morning ? 
                             "How are you feeling as you start your day?" :
                             "How did your day go? What did you learn?")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Mood Selection
                    MoodSelectionView(selectedMood: $selectedMood)
                    
                    // Text Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Share your thoughts")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("How are you feeling? What's on your mind?", text: $userInput, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(4...8)
                    }
                    .padding(.horizontal, 20)
                    
                    // AI Response Section
                    if showingResponse {
                        AIResponseCard(response: aiResponse, isLoading: aiManager.isLoading)
                    }
                    
                    // Submit Button
                    Button(action: submitCheckIn) {
                        HStack {
                            if aiManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Get AI Feedback")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    dataManager.userProfile?.selectedPath.color ?? .blue,
                                    (dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(userInput.isEmpty || aiManager.isLoading || !canUseAI)
                    .padding(.horizontal, 20)
                    
                    // Usage limit warning
                    if !canUseAI {
                        AIUsageLimitView()
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var canUseAI: Bool {
        guard let user = authManager.currentUser else { return false }
        
        if user.subscription == .pro {
            return usageTracker.canMakeRequest()
        } else {
            // Free users have limited AI check-ins
            return usageTracker.requestsToday < 3 && usageTracker.canMakeRequest()
        }
    }
    
    private func submitCheckIn() {
        guard let userProfile = dataManager.userProfile,
              !userInput.isEmpty else { return }
        
        usageTracker.recordRequest()
        
        Task {
            let response = await aiManager.generateCheckInResponse(
                userInput: userInput,
                timeOfDay: timeOfDay,
                trainingPath: userProfile.selectedPath,
                mood: selectedMood
            )
            
            await MainActor.run {
                aiResponse = response
                showingResponse = true
                
                // Save the check-in
                let checkIn = AICheckIn(
                    date: Date(),
                    timeOfDay: timeOfDay,
                    prompt: timeOfDay == .morning ? 
                        "How are you feeling as you start your day?" :
                        "How did your day go? What did you learn?",
                    userResponse: userInput,
                    aiResponse: response,
                    mood: selectedMood
                )
                
                dataManager.submitCheckIn(checkIn)
                
                // Clear form
                userInput = ""
                selectedMood = nil
            }
        }
    }
}

// MARK: - Supporting Views

// Mood Selection View
struct MoodSelectionView: View {
    @Binding var selectedMood: AICheckIn.MoodRating?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you feeling?")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AICheckIn.MoodRating.allCases, id: \.self) { mood in
                        Button(action: {
                            withAnimation(.easeInOut) {
                                selectedMood = selectedMood == mood ? nil : mood
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(mood.emoji)
                                    .font(.system(size: 30))
                                
                                Text(mood.rawValue.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedMood == mood ? .white : .primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedMood == mood ? Color.blue : Color(.systemGray6))
                            )
                        }
                        .scaleEffect(selectedMood == mood ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: selectedMood)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// AI Response Card
struct AIResponseCard: View {
    let response: String
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                
                Text("AI Mentor Response")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            if !response.isEmpty {
                Text(response)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating personalized response...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .padding(.horizontal, 20)
    }
}

// AI Usage Limit View
struct AIUsageLimitView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingPaywall = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Limit Reached")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(authManager.currentUser?.subscription == .free ? 
                         "Free users get 3 AI responses per day" :
                         "You've reached your hourly limit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if authManager.currentUser?.subscription == .free {
                    Button("Upgrade") {
                        showingPaywall = true
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - Weekly Summary View
struct WeeklySummaryView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var aiManager = AIManager()
    
    @State private var weeklySummary: WeeklySummary?
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let summary = weeklySummary {
                        // Generated Summary Display
                        WeeklySummaryCard(summary: summary)
                        
                        // Key Themes
                        if !summary.keyThemes.isEmpty {
                            KeyThemesView(themes: summary.keyThemes)
                        }
                        
                        // Stats
                        WeeklyStatsView(summary: summary)
                        
                        // Recommended Focus
                        if let recommendedFocus = summary.recommendedFocus {
                            RecommendedFocusView(path: recommendedFocus)
                        }
                        
                    } else {
                        // Generate Summary Prompt
                        VStack(spacing: 20) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Weekly Insights")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Get AI-powered insights about your week's progress, patterns, and growth opportunities.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: generateSummary) {
                                HStack {
                                    if isGenerating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "brain.head.profile")
                                        Text("Generate AI Summary")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .disabled(isGenerating || !canUseAI)
                            .padding(.horizontal, 40)
                            
                            if !canUseAI {
                                Text("AI summaries require Pro subscription")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Weekly Summary")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshSummary()
            }
        }
        .onAppear {
            loadExistingSummary()
        }
    }
    
    private var canUseAI: Bool {
        authManager.currentUser?.subscription == .pro
    }
    
    private func generateSummary() {
        guard canUseAI else { return }
        
        isGenerating = true
        
        Task {
            let summary = await aiManager.generateWeeklySummary(
                journalEntries: dataManager.journalEntries,
                completedChallenges: getWeeksChallenges(),
                checkIns: getWeeksCheckIns(),
                trainingPath: dataManager.userProfile?.selectedPath ?? .discipline
            )
            
            await MainActor.run {
                weeklySummary = summary
                dataManager.weeklySummaries.append(summary)
                isGenerating = false
            }
        }
    }
    
    private func refreshSummary() async {
        if canUseAI {
            await generateSummary()
        }
    }
    
    private func loadExistingSummary() {
        // Check if we already have this week's summary
        let calendar = Calendar.current
        let currentWeek = calendar.dateInterval(of: .weekOfYear, for: Date())
        
        weeklySummary = dataManager.weeklySummaries.first { summary in
            guard let weekInterval = currentWeek else { return false }
            return calendar.isDate(summary.weekStartDate, equalTo: weekInterval.start, toGranularity: .day)
        }
    }
    
    private func getWeeksChallenges() -> [DailyChallenge] {
        // Return challenges from the current week
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        // This would be implemented based on your challenge storage
        return []
    }
    
    private func getWeeksCheckIns() -> [AICheckIn] {
        // Return check-ins from the current week
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return dataManager.todaysCheckIns.filter { checkIn in
            checkIn.date >= weekAgo
        }
    }
}

// MARK: - Weekly Summary Supporting Views

struct WeeklySummaryCard: View {
    let summary: WeeklySummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                
                Text("AI Weekly Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(formatDateRange(start: summary.weekStartDate, end: summary.weekEndDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(summary.summary)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct KeyThemesView: View {
    let themes: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Themes")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(themes, id: \.self) { theme in
                        Text(theme)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct WeeklyStatsView: View {
    let summary: WeeklySummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Challenges",
                    value: "\(summary.challengesCompleted)",
                    subtitle: "completed",
                    color: .green
                )
                
                StatCard(
                    title: "Check-in Streak",
                    value: "\(summary.checkinStreak)",
                    subtitle: "days",
                    color: .orange
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

struct RecommendedFocusView: View {
    let path: TrainingPath
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Focus")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                Image(systemName: path.icon)
                    .font(.title2)
                    .foregroundColor(path.color)
                    .frame(width: 40, height: 40)
                    .background(path.color.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(path.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Consider focusing on \(path.displayName.lowercased()) for continued growth")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Smart Insights Widget
struct SmartInsightsWidget: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var aiManager = AIManager()
    
    @State private var insight = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("Smart Insight")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            if !insight.isEmpty {
                Text(insight)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(2)
            } else {
                Text("Tap to get a personalized insight about your progress")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            generateInsight()
        }
    }
    
    private func generateInsight() {
        guard !isLoading,
              let userProfile = dataManager.userProfile else { return }
        
        isLoading = true
        
        Task {
            let generatedInsight = await aiManager.generateSmartInsight(
                userProfile: userProfile,
                recentActivity: getRecentActivity(),
                trainingPath: userProfile.selectedPath
            )
            
            await MainActor.run {
                insight = generatedInsight
                isLoading = false
            }
        }
    }
    
    private func getRecentActivity() -> [String] {
        // Gather recent user activity
        var activity: [String] = []
        
        if let challenge = dataManager.todaysChallenge, challenge.isCompleted {
            activity.append("Completed daily challenge")
        }
        
        if !dataManager.todaysCheckIns.isEmpty {
            activity.append("Completed check-in")
        }
        
        if !dataManager.journalEntries.isEmpty {
            activity.append("Made journal entry")
        }
        
        activity.append("Current streak: \(dataManager.userProfile?.currentStreak ?? 0) days")
        
        return activity
    }
}

// MARK: - AI Configuration View
struct AIConfigurationView: View {
    @AppStorage("ai_model") private var selectedModel = "gpt-3.5-turbo"
    @AppStorage("ai_temperature") private var temperature = 0.7
    @AppStorage("ai_max_tokens") private var maxTokens = 150
    @AppStorage("ai_enabled") private var aiEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("AI Settings") {
                    Toggle("Enable AI Features", isOn: $aiEnabled)
                    
                    Picker("AI Model", selection: $selectedModel) {
                        Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                        Text("GPT-4").tag("gpt-4")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Response Creativity")
                        Slider(value: $temperature, in: 0...1, step: 0.1)
                        Text("Current: \(temperature, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper("Max Response Length: \(maxTokens)", value: $maxTokens, in: 50...300, step: 50)
                }
                
                Section("Usage Guidelines") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• AI responses are generated based on your input")
                        Text("• Your data is used to personalize responses")
                        Text("• AI advice should not replace professional help")
                        Text("• Report any inappropriate responses")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Integration Helpers

extension DataManager {
    // Enhanced methods for AI integration
    
    func getRecentJournalEntries(days: Int = 7) -> [JournalEntry] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return journalEntries.filter { $0.date >= cutoffDate }
    }
    
    func getRecentCheckIns(days: Int = 7) -> [AICheckIn] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return todaysCheckIns.filter { $0.date >= cutoffDate }
    }
    
    func getUserContext() -> String {
        guard let profile = userProfile else { return "" }
        
        return """
        User has been focusing on \(profile.selectedPath.displayName) for \(profile.totalChallengesCompleted) days.
        Current streak: \(profile.currentStreak) days.
        Longest streak: \(profile.longestStreak) days.
        Recent progress shows consistent engagement with personal development.
        """
    }
}

// MARK: - AI Response Cache
class AIResponseCache {
    private var cache: [String: String] = [:]
    private let maxCacheSize = 100
    
    func getCachedResponse(for key: String) -> String? {
        return cache[key]
    }
    
    func cacheResponse(_ response: String, for key: String) {
        if cache.count >= maxCacheSize {
            // Remove oldest entries
            let oldestKey = cache.keys.first
            if let key = oldestKey {
                cache.removeValue(forKey: key)
            }
        }
        cache[key] = response
    }
    
    private func generateCacheKey(userInput: String, context: String) -> String {
        return "\(userInput.hashValue)_\(context.hashValue)"
    }
}

// MARK: - Preview
struct AIEnhancedCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        AIEnhancedCheckInView()
            .environmentObject(DataManager())
            .environmentObject(AuthManager())
    }
}

struct WeeklySummaryView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklySummaryView()
            .environmentObject(DataManager())
            .environmentObject(AuthManager())
    }
}