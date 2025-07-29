import SwiftUI
import CoreData

// MARK: - Main Dashboard View
struct DashboardView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showingPathSelector = false
    @State private var showingSettings = false
    @State private var showingStreakDetail = false
    @State private var selectedQuickAction: QuickAction?
    @State private var dailyQuote: DailyQuote?
    @State private var showingAchievements = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    // Header with greeting and user info
                    headerSection
                    
                    // Daily quote section
                    if let quote = dailyQuote {
                        dailyQuoteSection(quote: quote)
                    }
                    
                    // Main metrics cards
                    metricsSection
                    
                    // Today's challenge preview
                    if let challenge = dataManager.todaysChallenge {
                        challengePreviewSection(challenge: challenge)
                    }
                    
                    // Book insight card
                    if let book = dataManager.currentBookRecommendations.first {
                        bookInsightSection(book: book)
                    }
                    
                    // Progress visualization
                    progressSection
                    
                    // Quick actions grid
                    quickActionsSection
                    
                    // Recent achievements
                    if !dataManager.recentAchievements.isEmpty {
                        achievementsSection
                    }
                    
                    // Weekly insights preview
                    if let summary = dataManager.weeklySummaries.first {
                        weeklyInsightsSection(summary: summary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .refreshable {
                await refreshDashboard()
            }
        }
        .onAppear {
            setupDashboard()
        }
        .sheet(isPresented: $showingPathSelector) {
            PathSelectionView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(dataManager)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingStreakDetail) {
            StreakDetailView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView()
                .environmentObject(dataManager)
        }
        .fullScreenCover(item: $selectedQuickAction) { action in
            quickActionDestination(for: action)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(dataManager.userProfile?.displayName ?? "User")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let path = dataManager.userProfile?.selectedPath {
                    HStack(spacing: 6) {
                        Image(systemName: path.icon)
                            .font(.caption)
                            .foregroundColor(path.color)
                        
                        Text("Focus: \(path.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                // Profile image or avatar
                Button {
                    showingSettings = true
                } label: {
                    AsyncImage(url: URL(string: dataManager.userProfile?.profileImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                }
                
                // Notification indicator
                if dataManager.hasUnreadNotifications {
                    Button {
                        // Handle notifications
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Daily Quote Section
    private func dailyQuoteSection(quote: DailyQuote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble")
                    .font(.title3)
                    .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                
                Text("Daily Wisdom")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text(quote.text)
                .font(.body)
                .foregroundColor(.primary)
                .italic()
                .lineSpacing(2)
            
            if let author = quote.author {
                Text("— \(author)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(dataManager.userProfile?.selectedPath.color ?? .blue, lineWidth: 1)
                        .opacity(0.3)
                )
        )
    }
    
    // MARK: - Metrics Section
    private var metricsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Streak card
            StreakCard(
                currentStreak: dataManager.userProfile?.currentStreak ?? 0,
                longestStreak: dataManager.userProfile?.longestStreak ?? 0,
                streakLevel: dataManager.userProfile?.streakLevel ?? .beginner,
                pathColor: dataManager.userProfile?.selectedPath.color ?? .blue,
                onTap: { showingStreakDetail = true }
            )
            
            // Completion rate card
            CompletionRateCard(
                completionRate: dataManager.weeklyCompletionRate,
                totalChallenges: dataManager.weeklyChallengesTotal,
                pathColor: dataManager.userProfile?.selectedPath.color ?? .blue
            )
        }
    }
    
    // MARK: - Challenge Preview Section
    private func challengePreviewSection(challenge: DailyChallenge) -> some View {
        ChallengeCard(
            challenge: challenge,
            onComplete: {
                Task {
                    await dataManager.completeChallenge(challenge)
                }
            },
            onSkip: {
                Task {
                    await dataManager.skipChallenge(challenge, reason: "Not today")
                }
            },
            onViewDetails: {
                selectedQuickAction = .challenge
            }
        )
    }
    
    // MARK: - Book Insight Section
    private func bookInsightSection(book: BookRecommendation) -> some View {
        BookInsightCard(
            book: book,
            onSave: {
                Task {
                    await dataManager.saveBook(book)
                }
            },
            onViewMore: {
                selectedQuickAction = .books
            }
        )
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        ProgressSection(
            weeklyProgress: dataManager.weeklyProgress,
            moodTrend: dataManager.weeklyMoodTrend,
            pathColor: dataManager.userProfile?.selectedPath.color ?? .blue
        )
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(QuickAction.allCases, id: \.self) { action in
                    QuickActionCard(
                        action: action,
                        hasNotification: action.hasNotification(dataManager: dataManager),
                        onTap: { selectedQuickAction = action }
                    )
                }
            }
        }
    }
    
    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingAchievements = true
                }
                .font(.subheadline)
                .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dataManager.recentAchievements.prefix(5)) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Weekly Insights Section
    private func weeklyInsightsSection(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Text("AI Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View Full") {
                    selectedQuickAction = .insights
                }
                .font(.subheadline)
                .foregroundColor(.purple)
            }
            
            Text(summary.summary.prefix(120) + "...")
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(2)
            
            if !summary.keyThemes.isEmpty {
                HStack {
                    Text("Themes:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(summary.keyThemes.prefix(3), id: \.self) { theme in
                        Text(theme)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Helper Properties
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    // MARK: - Helper Methods
    private func setupDashboard() {
        generateDailyQuote()
        Task {
            await dataManager.refreshDashboardData()
        }
    }
    
    private func refreshDashboard() async {
        await dataManager.refreshDashboardData()
        generateDailyQuote()
    }
    
    private func generateDailyQuote() {
        guard let path = dataManager.userProfile?.selectedPath else { return }
        dailyQuote = DailyQuote.forPath(path)
    }
    
    @ViewBuilder
    private func quickActionDestination(for action: QuickAction) -> some View {
        switch action {
        case .challenge:
            ChallengeView()
                .environmentObject(dataManager)
        case .checkin:
            CheckInView()
                .environmentObject(dataManager)
        case .journal:
            JournalView()
                .environmentObject(dataManager)
        case .books:
            BookStationView()
                .environmentObject(dataManager)
        case .insights:
            WeeklyInsightsView()
                .environmentObject(dataManager)
        case .settings:
            SettingsView()
                .environmentObject(dataManager)
                .environmentObject(authManager)
        }
    }
}

// MARK: - Streak Card Component
struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let streakLevel: StreakLevel
    let pathColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: streakLevel.icon)
                        .font(.title3)
                        .foregroundColor(streakLevel.color)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(pathColor)
                    
                    Text("Day Streak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if longestStreak > currentStreak {
                        Text("Best: \(longestStreak)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(streakLevel.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(streakLevel.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Completion Rate Card Component
struct CompletionRateCard: View {
    let completionRate: Double
    let totalChallenges: Int
    let pathColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.title3)
                    .foregroundColor(pathColor)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(completionRate * 100))%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(pathColor)
                
                Text("Completion Rate")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("This Week")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(pathColor)
                            .frame(width: geometry.size.width * completionRate, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Challenge Card Component
struct ChallengeCard: View {
    let challenge: DailyChallenge
    let onComplete: () -> Void
    let onSkip: () -> Void
    let onViewDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Challenge")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Image(systemName: challenge.difficulty.icon)
                            .font(.caption)
                            .foregroundColor(challenge.difficulty.color)
                        
                        Text(challenge.difficulty.displayName)
                            .font(.caption)
                            .foregroundColor(challenge.difficulty.color)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(challenge.estimatedTimeMinutes) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Details") {
                    onViewDetails()
                }
                .font(.caption)
                .foregroundColor(challenge.path.color)
            }
            
            // Challenge content
            VStack(alignment: .leading, spacing: 12) {
                Text(challenge.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(challenge.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            
            // Action buttons
            if !challenge.isCompleted && !challenge.isSkipped {
                HStack(spacing: 12) {
                    Button("Complete") {
                        onComplete()
                    }
                    .buttonStyle(PrimaryButtonStyle(color: challenge.path.color))
                    .frame(maxWidth: .infinity)
                    
                    Button("Skip") {
                        onSkip()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            } else {
                HStack {
                    Image(systemName: challenge.isCompleted ? "checkmark.circle.fill" : "forward.circle.fill")
                        .font(.title3)
                        .foregroundColor(challenge.isCompleted ? .green : .orange)
                    
                    Text(challenge.isCompleted ? "Completed!" : "Skipped")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(challenge.isCompleted ? .green : .orange)
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(challenge.path.color, lineWidth: 2)
                        .opacity(0.3)
                )
        )
    }
}

// MARK: - Book Insight Card Component
struct BookInsightCard: View {
    let book: BookRecommendation
    let onSave: () -> Void
    let onViewMore: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Book Wisdom")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Image(systemName: book.path.icon)
                            .font(.caption)
                            .foregroundColor(book.path.color)
                        
                        Text(book.path.displayName)
                            .font(.caption)
                            .foregroundColor(book.path.color)
                    }
                }
                
                Spacer()
                
                Button("Save") {
                    onSave()
                }
                .font(.caption)
                .foregroundColor(book.isSaved ? .green : book.path.color)
                .disabled(book.isSaved)
            }
            
            // Book info
            HStack(spacing: 12) {
                // Mock book cover
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [book.path.color.opacity(0.8), book.path.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 80)
                    .overlay(
                        Text(book.title.prefix(1))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Key insight
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Insight")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(book.keyInsight)
                    .font(.body)
                    .foregroundColor(.primary)
                    .italic()
                    .lineSpacing(2)
            }
            
            // Daily action
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Action")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(book.dailyAction)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(book.path.color.opacity(0.1))
                    )
            }
            
            // View more button
            Button("Explore Books") {
                onViewMore()
            }
            .font(.subheadline)
            .foregroundColor(book.path.color)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Progress Section Component
struct ProgressSection: View {
    let weeklyProgress: [DayProgress]
    let moodTrend: WeeklySummary.MoodTrend
    let pathColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week's Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: moodTrend.icon)
                        .font(.caption)
                        .foregroundColor(moodTrend.color)
                    
                    Text(moodTrend.displayName)
                        .font(.caption)
                        .foregroundColor(moodTrend.color)
                }
            }
            
            // Week visualization
            HStack(spacing: 8) {
                ForEach(weeklyProgress.indices, id: \.self) { index in
                    let progress = weeklyProgress[index]
                    
                    VStack(spacing: 6) {
                        Text(progress.dayLetter)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progress.isCompleted ? pathColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(pathColor.opacity(0.3), lineWidth: 1)
                            )
                        
                        if progress.isToday {
                            Circle()
                                .fill(pathColor)
                                .frame(width: 4, height: 4)
                        } else {
                            Spacer()
                                .frame(height: 4)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Stats row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(weeklyProgress.filter(\.isCompleted).count)/7")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(pathColor)
                    
                    Text("Days Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(Double(weeklyProgress.filter(\.isCompleted).count) / 7.0 * 100))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(pathColor)
                    
                    Text("Success Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Quick Action Card Component
struct QuickActionCard: View {
    let action: QuickAction
    let hasNotification: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Image(systemName: action.icon)
                        .font(.title2)
                        .foregroundColor(action.color)
                    
                    if hasNotification {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 12, y: -12)
                    }
                }
                
                Text(action.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Achievement Badge Component
struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.rarity.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.iconName)
                    .font(.title3)
                    .foregroundColor(achievement.rarity.color)
            }
            
            Text(achievement.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
    }
}

// MARK: - Supporting Models

// MARK: - Quick Action Enum
enum QuickAction: String, CaseIterable {
    case challenge = "challenge"
    case checkin = "checkin"
    case journal = "journal"
    case books = "books"
    case insights = "insights"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .challenge: return "Challenge"
        case .checkin: return "Check-in"
        case .journal: return "Journal"
        case .books: return "Books"
        case .insights: return "Insights"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .challenge: return "target"
        case .checkin: return "message.fill"
        case .journal: return "book.closed.fill"
        case .books: return "books.vertical.fill"
        case .insights: return "brain.head.profile"
        case .settings: return "gearshape.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .challenge: return .red
        case .checkin: return .green
        case .journal: return .indigo
        case .books: return .orange
        case .insights: return .purple
        case .settings: return .gray
        }
    }
    
    func hasNotification(dataManager: EnhancedDataManager) -> Bool {
        switch self {
        case .challenge:
            return dataManager.todaysChallenge?.isCompleted == false
        case .checkin:
            return dataManager.pendingCheckIns.count > 0
        case .journal:
            return false // Could check for missed entries
        case .books:
            return false // Could check for reading goals
        case .insights:
            return dataManager.hasNewInsights
        case .settings:
            return false
        }
    }
}

// MARK: - Daily Quote Model
struct DailyQuote {
    let text: String
    let author: String?
    let path: TrainingPath
    
    static func forPath(_ path: TrainingPath) -> DailyQuote {
        let quotes = quotesForPath(path)
        return quotes.randomElement() ?? DailyQuote(
            text: "Every day is a new opportunity to grow.",
            author: nil,
            path: path
        )
    }
    
    private static func quotesForPath(_ path: TrainingPath) -> [DailyQuote] {
        switch path {
        case .discipline:
            return [
                DailyQuote(text: "Discipline is the bridge between goals and accomplishment.", author: "Jim Rohn", path: path),
                DailyQuote(text: "We are what we repeatedly do. Excellence is not an act, but a habit.", author: "Aristotle", path: path),
                DailyQuote(text: "The pain of discipline weighs ounces, but the pain of regret weighs tons.", author: "Jim Rohn", path: path),
                DailyQuote(text: "Success is nothing more than a few simple disciplines, practiced every day.", author: "Jim Rohn", path: path),
                DailyQuote(text: "Discipline is choosing between what you want now and what you want most.", author: "Abraham Lincoln", path: path)
            ]
        case .clarity:
            return [
                DailyQuote(text: "Clarity comes from engagement, not thought.", author: "Marie Forleo", path: path),
                DailyQuote(text: "The clearer you are, the faster you'll get where you want to go.", author: "Oprah Winfrey", path: path),
                DailyQuote(text: "In the midst of chaos, there is also opportunity.", author: "Sun Tzu", path: path),
                DailyQuote(text: "Muddy water is best cleared by leaving it alone.", author: "Alan Watts", path: path),
                DailyQuote(text: "The present moment is the only time over which we have any power.", author: "Thích Nhất Hạnh", path: path)
            ]
        case .confidence:
            return [
                DailyQuote(text: "Confidence is not 'they will like me.' Confidence is 'I'll be fine if they don't.'", author: "Christina Grimmie", path: path),
                DailyQuote(text: "You have been assigned this mountain to show others it can be moved.", author: "Mel Robbins", path: path),
                DailyQuote(text: "The way to develop self-confidence is to do the thing you fear.", author: "William Jennings Bryan", path: path),
                DailyQuote(text: "Confidence comes not from always being right but from not fearing to be wrong.", author: "Peter T. Mcintyre", path: path),
                DailyQuote(text: "Your opinion of yourself is your most important viewpoint.", author: "Denis Waitley", path: path)
            ]
        case .purpose:
            return [
                DailyQuote(text: "The meaning of life is to find your gift. The purpose of life is to give it away.", author: "Pablo Picasso", path: path),
                DailyQuote(text: "Those who have a 'why' to live, can bear with almost any 'how'.", author: "Viktor Frankl", path: path),
                DailyQuote(text: "Your purpose in life is to find your purpose and give your whole heart and soul to it.", author: "Buddha", path: path),
                DailyQuote(text: "The two most important days in your life are the day you are born and the day you find out why.", author: "Mark Twain", path: path),
                DailyQuote(text: "Purpose is the reason you journey. Passion is the fire that lights your way.", author: "Unknown", path: path)
            ]
        case .authenticity:
            return [
                DailyQuote(text: "Authenticity is the daily practice of letting go of who we think we're supposed to be.", author: "Brené Brown", path: path),
                DailyQuote(text: "To be yourself in a world that is constantly trying to make you something else is the greatest accomplishment.", author: "Ralph Waldo Emerson", path: path),
                DailyQuote(text: "The privilege of a lifetime is being who you are.", author: "Joseph Campbell", path: path),
                DailyQuote(text: "Your authentic self is who you are when you have nothing left to lose.", author: "Unknown", path: path),
                DailyQuote(text: "Authenticity requires vulnerability, transparency, and integrity.", author: "Janet Louise Stephenson", path: path)
            ]
        }
    }
}

// MARK: - Day Progress Model
struct DayProgress {
    let dayLetter: String
    let isCompleted: Bool
    let isToday: Bool
    let date: Date
    
    static func weeklyProgress(from challenges: [DailyChallenge]) -> [DayProgress] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) ?? today
            let dayLetter = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1].prefix(1).uppercased()
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isCompleted = challenges.contains { challenge in
                calendar.isDate(challenge.date, inSameDayAs: date) && challenge.isCompleted
            }
            
            return DayProgress(
                dayLetter: String(dayLetter),
                isCompleted: isCompleted,
                isToday: isToday,
                date: date
            )
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Enhanced Data Manager Extensions

extension EnhancedDataManager {
    var weeklyCompletionRate: Double {
        let weekChallenges = getWeekChallenges()
        guard !weekChallenges.isEmpty else { return 0.0 }
        let completed = weekChallenges.filter { $0.isCompleted }.count
        return Double(completed) / Double(weekChallenges.count)
    }
    
    var weeklyChallengesTotal: Int {
        return getWeekChallenges().count
    }
    
    var weeklyProgress: [DayProgress] {
        let challenges = getWeekChallenges()
        return DayProgress.weeklyProgress(from: challenges)
    }
    
    var weeklyMoodTrend: WeeklySummary.MoodTrend {
        return weeklySummaries.first?.moodTrend ?? .stable
    }
    
    var recentAchievements: [Achievement] {
        // In a real implementation, this would fetch from Core Data
        return []
    }
    
    var hasUnreadNotifications: Bool {
        // Check for unread notifications
        return pendingCheckIns.count > 0 || (todaysChallenge?.isCompleted == false)
    }
    
    var hasNewInsights: Bool {
        // Check if there are new AI insights available
        return weeklySummaries.first?.insights.isEmpty == false
    }
    
    var pendingCheckIns: [AICheckIn] {
        return todaysCheckIns.filter { !$0.isCompleted }
    }
    
    // MARK: - Helper Methods
    
    func refreshDashboardData() async {
        // Refresh all dashboard-relevant data
        loadTodaysChallenge()
        loadTodaysCheckIns()
        loadBookRecommendations()
        loadRecentJournalEntries()
        generateWeeklySummaryIfNeeded()
    }
    
    func completeChallenge(_ challenge: DailyChallenge) async {
        guard let index = getChallengeIndex(challenge) else { return }
        
        // Update challenge in Core Data
        let request: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", challenge.id as CVarArg)
        
        if let cdChallenge = coreDataStack.fetch(request).first {
            cdChallenge.markCompleted(effortLevel: 3)
            coreDataStack.save()
            
            // Update user profile streak
            updateUserStreak()
            
            // Reload data
            loadTodaysChallenge()
            
            // Generate achievement if needed
            checkForAchievements()
        }
    }
    
    func skipChallenge(_ challenge: DailyChallenge, reason: String?) async {
        let request: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", challenge.id as CVarArg)
        
        if let cdChallenge = coreDataStack.fetch(request).first {
            cdChallenge.markSkipped(reason: reason)
            coreDataStack.save()
            
            loadTodaysChallenge()
        }
    }
    
    func saveBook(_ book: BookRecommendation) async {
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        if let cdBook = coreDataStack.fetch(request).first {
            cdBook.isSaved = true
            coreDataStack.save()
            loadBookRecommendations()
        }
    }
    
    private func getWeekChallenges() -> [DailyChallenge] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? Date()
        
        let request: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfWeek as NSDate, endOfWeek as NSDate)
        
        return coreDataStack.fetch(request).map { $0.toDomainModel() }
    }
    
    private func getChallengeIndex(_ challenge: DailyChallenge) -> Int? {
        // Helper to find challenge index in current data
        return nil // Implementation would depend on how you store current challenges
    }
    
    private func updateUserStreak() {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        if let profile = coreDataStack.fetch(request).first {
            profile.incrementStreak()
            coreDataStack.save()
            loadUserProfile()
        }
    }
    
    private func checkForAchievements() {
        // Check if user has earned any new achievements
        // Implementation would analyze user progress and generate achievements
    }
    
    private func generateWeeklySummaryIfNeeded() {
        // Check if we need to generate a new weekly summary
        // Implementation would use AI service to analyze the week's data
    }
}

// MARK: - Preview Support

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = EnhancedDataManager()
        let authManager = AuthManager()
        
        DashboardView()
            .environmentObject(dataManager)
            .environmentObject(authManager)
            .preferredColorScheme(.light)
    }
}
