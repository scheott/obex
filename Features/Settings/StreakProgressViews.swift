import SwiftUI
import Foundation

// MARK: - Streak Detail View
struct StreakDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTimeRange: TimeRange = .thisWeek
    @State private var showingAchievements = false
    
    enum TimeRange: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case last30Days = "Last 30 Days"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Main Streak Display
                    StreakHeroSection()
                    
                    // Time Range Picker
                    TimeRangePicker(selectedTimeRange: $selectedTimeRange)
                    
                    // Progress Chart
                    ProgressChartView(timeRange: selectedTimeRange)
                    
                    // Streak Milestones
                    StreakMilestonesView()
                    
                    // Weekly Breakdown
                    WeeklyBreakdownView()
                    
                    // Achievements Button
                    Button(action: { showingAchievements = true }) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                            
                            Text("View All Achievements")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Streak & Progress")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementBadgesView()
                .environmentObject(dataManager)
        }
    }
}

// MARK: - Streak Hero Section
struct StreakHeroSection: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Flame animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.orange.opacity(0.3),
                                Color.red.opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            VStack(spacing: 8) {
                Text("\(dataManager.userProfile?.currentStreak ?? 0)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                
                Text("Day Streak")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            // Streak status message
            Text(streakStatusMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.horizontal, 20)
    }
    
    private var streakStatusMessage: String {
        let streak = dataManager.userProfile?.currentStreak ?? 0
        
        switch streak {
        case 0:
            return "Start your journey today! Complete your first challenge to begin your streak."
        case 1:
            return "Great start! Keep the momentum going."
        case 2...6:
            return "Building consistency! You're on your way to forming a habit."
        case 7...29:
            return "Excellent progress! You're developing real discipline."
        case 30...99:
            return "Incredible dedication! You're in the top tier of committed users."
        case 100...:
            return "Legendary status! You're an inspiration to others."
        default:
            return "Keep up the amazing work!"
        }
    }
}

// MARK: - Time Range Picker
struct TimeRangePicker: View {
    @Binding var selectedTimeRange: StreakDetailView.TimeRange
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StreakDetailView.TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        withAnimation(.easeInOut) {
                            selectedTimeRange = range
                        }
                    }) {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTimeRange == range ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTimeRange == range ? Color.blue : Color(.systemGray5))
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Progress Chart View
struct ProgressChartView: View {
    let timeRange: StreakDetailView.TimeRange
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Chart placeholder - in real app would use Charts framework
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<14) { day in
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(dayCompleted(day) ? (dataManager.userProfile?.selectedPath.color ?? .blue) : Color(.systemGray5))
                                .frame(width: 20, height: CGFloat.random(in: 20...80))
                                .cornerRadius(4)
                            
                            Text("\(day + 1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Stats summary
                HStack(spacing: 24) {
                    StatPill(title: "Completed", value: "12", color: .green)
                    StatPill(title: "Missed", value: "2", color: .red)
                    StatPill(title: "Success Rate", value: "86%", color: .blue)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }
    
    private func dayCompleted(_ day: Int) -> Bool {
        // Sample data - would be real data in production
        return day % 3 != 0
    }
}

// MARK: - Streak Milestones View
struct StreakMilestonesView: View {
    @EnvironmentObject var dataManager: DataManager
    
    private let milestones = [7, 14, 30, 50, 100, 365]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Milestones")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(milestones, id: \.self) { milestone in
                    MilestoneCard(
                        target: milestone,
                        current: dataManager.userProfile?.currentStreak ?? 0,
                        pathColor: dataManager.userProfile?.selectedPath.color ?? .blue
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Weekly Breakdown View
struct WeeklyBreakdownView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(0..<7) { day in
                        VStack(spacing: 8) {
                            Text(dayLetter(for: day))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Circle()
                                .fill(dayCompleted(day) ? (dataManager.userProfile?.selectedPath.color ?? .blue) : Color(.systemGray5))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Group {
                                        if dayCompleted(day) {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                )
                            
                            Text("\(day + 1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text("5 of 7 days completed this week")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
    
    private func dayLetter(for index: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[index]
    }
    
    private func dayCompleted(_ day: Int) -> Bool {
        // Sample data
        return day < 5
    }
}

// MARK: - Achievement Badges View
struct AchievementBadgesView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Achievements")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Your journey milestones and accomplishments")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Achievement Categories
                    AchievementSection(
                        title: "Streak Achievements",
                        achievements: streakAchievements,
                        currentProgress: dataManager.userProfile?.currentStreak ?? 0
                    )
                    
                    AchievementSection(
                        title: "Challenge Achievements",
                        achievements: challengeAchievements,
                        currentProgress: dataManager.userProfile?.totalChallengesCompleted ?? 0
                    )
                    
                    AchievementSection(
                        title: "Special Achievements",
                        achievements: specialAchievements,
                        currentProgress: 0 // Special achievements don't have simple numeric progress
                    )
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var streakAchievements: [Achievement] {
        [
            Achievement(
                id: "streak_7",
                title: "First Week",
                description: "Complete 7 days in a row",
                icon: "flame",
                target: 7,
                color: .orange
            ),
            Achievement(
                id: "streak_30",
                title: "Monthly Warrior",
                description: "Complete 30 days in a row",
                icon: "flame.fill",
                target: 30,
                color: .red
            ),
            Achievement(
                id: "streak_100",
                title: "Century Club",
                description: "Complete 100 days in a row",
                icon: "crown.fill",
                target: 100,
                color: .purple
            ),
            Achievement(
                id: "streak_365",
                title: "Year of Discipline",
                description: "Complete 365 days in a row",
                icon: "star.fill",
                target: 365,
                color: .yellow
            )
        ]
    }
    
    private var challengeAchievements: [Achievement] {
        [
            Achievement(
                id: "challenges_10",
                title: "Getting Started",
                description: "Complete 10 challenges",
                icon: "target",
                target: 10,
                color: .green
            ),
            Achievement(
                id: "challenges_50",
                title: "Challenge Master",
                description: "Complete 50 challenges",
                icon: "bolt.fill",
                target: 50,
                color: .blue
            ),
            Achievement(
                id: "challenges_200",
                title: "Unstoppable",
                description: "Complete 200 challenges",
                icon: "lightning.fill",
                target: 200,
                color: .purple
            )
        ]
    }
    
    private var specialAchievements: [Achievement] {
        [
            Achievement(
                id: "path_switcher",
                title: "Explorer",
                description: "Try all 5 training paths",
                icon: "map.fill",
                target: 5,
                color: .teal
            ),
            Achievement(
                id: "perfect_week",
                title: "Perfect Week",
                description: "Complete all challenges in a week",
                icon: "checkmark.seal.fill",
                target: 1,
                color: .green
            ),
            Achievement(
                id: "early_bird",
                title: "Early Bird",
                description: "Complete 10 morning check-ins",
                icon: "sun.max.fill",
                target: 10,
                color: .orange
            )
        ]
    }
}

// MARK: - Achievement Section
struct AchievementSection: View {
    let title: String
    let achievements: [Achievement]
    let currentProgress: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementBadge(
                        achievement: achievement,
                        isUnlocked: currentProgress >= achievement.target,
                        progress: currentProgress
                    )
                }
            }
        }
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Badge icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.color : Color(.systemGray5))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .white : .gray)
            }
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Progress indicator
            if !isUnlocked && progress > 0 {
                VStack(spacing: 4) {
                    ProgressView(value: Double(progress), total: Double(achievement.target))
                        .progressViewStyle(LinearProgressViewStyle(tint: achievement.color))
                        .scaleEffect(0.8)
                    
                    Text("\(progress)/\(achievement.target)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else if isUnlocked {
                Text("Unlocked!")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(achievement.color)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUnlocked ? achievement.color.opacity(0.1) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isUnlocked ? achievement.color.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: isUnlocked)
    }
}

// MARK: - Progress Analytics View
struct ProgressAnalyticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedMetric: AnalyticsMetric = .streaks
    
    enum AnalyticsMetric: String, CaseIterable {
        case streaks = "Streaks"
        case challenges = "Challenges"
        case checkins = "Check-ins"
        case overall = "Overall"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Metric Selector
                    MetricSelector(selectedMetric: $selectedMetric)
                    
                    // Key Metrics Cards
                    KeyMetricsView(metric: selectedMetric)
                    
                    // Detailed Chart
                    DetailedChartView(metric: selectedMetric)
                    
                    // Insights & Recommendations
                    InsightsView(metric: selectedMetric)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Supporting Components

// Achievement Model
struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let target: Int
    let color: Color
}

// Milestone Card
struct MilestoneCard: View {
    let target: Int
    let current: Int
    let pathColor: Color
    
    private var isCompleted: Bool {
        current >= target
    }
    
    private var progress: Double {
        min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .gray)
                    .font(.title3)
                
                Spacer()
                
                Text("\(target)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isCompleted ? pathColor : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(milestoneTitle(for: target))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isCompleted ? .primary : .secondary)
                
                if !isCompleted {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: pathColor))
                        .scaleEffect(0.8)
                    
                    Text("\(current) of \(target) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCompleted ? pathColor.opacity(0.1) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCompleted ? pathColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private func milestoneTitle(for target: Int) -> String {
        switch target {
        case 7: return "First Week"
        case 14: return "Two Weeks"
        case 30: return "One Month"
        case 50: return "50 Days"
        case 100: return "Century"
        case 365: return "Full Year"
        default: return "\(target) Days"
        }
    }
}

// Stat Pill
struct StatPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// Metric Selector
struct MetricSelector: View {
    @Binding var selectedMetric: ProgressAnalyticsView.AnalyticsMetric
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ProgressAnalyticsView.AnalyticsMetric.allCases, id: \.self) { metric in
                    Button(action: {
                        withAnimation(.easeInOut) {
                            selectedMetric = metric
                        }
                    }) {
                        Text(metric.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedMetric == metric ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedMetric == metric ? Color.blue : Color(.systemGray5))
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// Key Metrics View
struct KeyMetricsView: View {
    let metric: ProgressAnalyticsView.AnalyticsMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    MetricCard(title: "Current Streak", value: "15", subtitle: "days", trend: .up)
                    MetricCard(title: "Best Streak", value: "23", subtitle: "days", trend: .neutral)
                    MetricCard(title: "Success Rate", value: "87%", subtitle: "this month", trend: .up)
                    MetricCard(title: "Total Days", value: "142", subtitle: "completed", trend: .up)
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let trend: Trend
    
    enum Trend {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 120)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Detailed Chart View
struct DetailedChartView: View {
    let metric: ProgressAnalyticsView.AnalyticsMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("30-Day Trend")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            // Chart placeholder
            VStack {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<30) { day in
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 8, height: CGFloat.random(in: 10...60))
                            .cornerRadius(2)
                    }
                }
                .padding()
                
                Text("Challenges completed over the last 30 days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
}

// Insights View
struct InsightsView: View {
    let metric: ProgressAnalyticsView.AnalyticsMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights & Tips")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                InsightCard(
                    icon: "lightbulb.fill",
                    title: "Peak Performance",
                    description: "You complete challenges most successfully on weekdays. Consider scheduling more challenging tasks during this time.",
                    color: .yellow
                )
                
                InsightCard(
                    icon: "target",
                    title: "Next Milestone",
                    description: "You're only 8 days away from your 30-day milestone! Keep up the momentum.",
                    color: .blue
                )
                
                InsightCard(
                    icon: "calendar",
                    title: "Weekly Pattern",
                    description: "Your completion rate drops on weekends. Try setting easier challenges for Saturday and Sunday.",
                    color: .purple
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

// Insight Card
struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct StreakDetailView_Previews: PreviewProvider {
    static var previews: some View {
        StreakDetailView()
            .environmentObject(DataManager())
    }
}
                