import SwiftUI
import CoreData

// MARK: - Main Challenge View
struct ChallengeView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @State private var showingCompletionAnimation = false
    @State private var showingStreakDetail = false
    @State private var showingDifficultySelector = false
    @State private var showingChallengeHistory = false
    @State private var showingSkipDialog = false
    @State private var selectedEffortLevel = 3
    @State private var completionNotes = ""
    @State private var skipReason = ""
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background based on path
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        // Header with streak and stats
                        challengeHeaderSection
                        
                        // Today's main challenge card
                        if let challenge = dataManager.todaysChallenge {
                            mainChallengeSection(challenge: challenge)
                        } else {
                            noChallengeSection
                        }
                        
                        // Difficulty selector for future challenges
                        difficultyPreferencesSection
                        
                        // Streak visualization
                        streakVisualizationSection
                        
                        // Challenge history preview
                        challengeHistoryPreview
                        
                        // Weekly stats
                        weeklyStatsSection
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .refreshable {
                await refreshChallenges()
            }
        }
        .sheet(isPresented: $showingStreakDetail) {
            StreakDetailView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingDifficultySelector) {
            DifficultySelector(
                currentDifficulty: dataManager.preferredDifficulty,
                onSelectionChanged: { difficulty in
                    dataManager.updatePreferredDifficulty(difficulty)
                }
            )
        }
        .sheet(isPresented: $showingChallengeHistory) {
            ChallengeHistory()
                .environmentObject(dataManager)
        }
        .alert("Skip Challenge", isPresented: $showingSkipDialog) {
            TextField("Reason (optional)", text: $skipReason)
            Button("Cancel", role: .cancel) { }
            Button("Skip", role: .destructive) {
                Task {
                    await skipTodaysChallenge()
                }
            }
        } message: {
            Text("Are you sure you want to skip today's challenge? You can bank this day if you have streak insurance.")
        }
        .onAppear {
            setupChallengeView()
        }
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                (dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.15),
                (dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.05),
                Color(.systemBackground)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Challenge Header Section
    private var challengeHeaderSection: some View {
        VStack(spacing: 20) {
            // Title and profile integration
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Challenge")
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
                    }
                }
                
                Spacer()
                
                // Quick access to streak
                Button {
                    showingStreakDetail = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("\(dataManager.userProfile?.currentStreak ?? 0)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("streak")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Main Challenge Section
    private func mainChallengeSection(challenge: DailyChallenge) -> some View {
        VStack(spacing: 0) {
            if challenge.status == .completed {
                CompletedChallengeCard(challenge: challenge)
            } else if challenge.status == .skipped {
                SkippedChallengeCard(challenge: challenge)
            } else {
                ActiveChallengeCard(
                    challenge: challenge,
                    onComplete: { effortLevel, notes in
                        await completeChallenge(challenge, effortLevel: effortLevel, notes: notes)
                    },
                    onSkip: {
                        showingSkipDialog = true
                    },
                    showingAnimation: $showingCompletionAnimation
                )
            }
        }
    }
    
    // MARK: - No Challenge Section
    private var noChallengeSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("No Challenge Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Check back tomorrow for your next challenge, or generate a custom one!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button("Generate Custom Challenge") {
                Task {
                    await generateCustomChallenge()
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: dataManager.userProfile?.selectedPath.color ?? .blue))
        }
        .padding(30)
        .background(.regularMaterial)
        .cornerRadius(20)
    }
    
    // MARK: - Difficulty Preferences Section
    private var difficultyPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Challenge Preferences")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Customize") {
                    showingDifficultySelector = true
                }
                .font(.subheadline)
                .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
            }
            
            DifficultyDisplay(difficulty: dataManager.preferredDifficulty)
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Streak Visualization Section
    private var streakVisualizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weekly Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View Details") {
                    showingStreakDetail = true
                }
                .font(.subheadline)
                .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
            }
            
            StreakVisualization(
                weeklyData: dataManager.weeklyProgressData,
                pathColor: dataManager.userProfile?.selectedPath.color ?? .blue
            )
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Challenge History Preview
    private var challengeHistoryPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Challenges")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingChallengeHistory = true
                }
                .font(.subheadline)
                .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(dataManager.recentChallenges.prefix(3)) { challenge in
                    RecentChallengeRow(challenge: challenge)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Weekly Stats Section
    private var weeklyStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                WeeklyStatCard(
                    title: "Completed",
                    value: "\(dataManager.weeklyCompletedChallenges)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                WeeklyStatCard(
                    title: "Success Rate",
                    value: "\(Int(dataManager.weeklyCompletionRate * 100))%",
                    icon: "chart.pie.fill",
                    color: dataManager.userProfile?.selectedPath.color ?? .blue
                )
                
                WeeklyStatCard(
                    title: "Avg. Effort",
                    value: String(format: "%.1f/5", dataManager.weeklyAverageEffort),
                    icon: "star.fill",
                    color: .orange
                )
                
                WeeklyStatCard(
                    title: "Streak Level",
                    value: dataManager.userProfile?.streakLevel.displayName ?? "Beginner",
                    icon: dataManager.userProfile?.streakLevel.icon ?? "seedling",
                    color: dataManager.userProfile?.streakLevel.color ?? .gray
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    private func setupChallengeView() {
        Task {
            await dataManager.loadTodaysChallenge()
            await dataManager.loadChallengeHistory()
        }
    }
    
    private func refreshChallenges() async {
        await dataManager.refreshChallengeData()
    }
    
    private func completeChallenge(_ challenge: DailyChallenge, effortLevel: Int, notes: String) async {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingCompletionAnimation = true
        }
        
        await dataManager.completeChallenge(challenge, effortLevel: effortLevel, notes: notes)
        
        // Celebrate completion
        celebrateCompletion()
        
        // Reset animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showingCompletionAnimation = false
            }
        }
    }
    
    private func skipTodaysChallenge() async {
        guard let challenge = dataManager.todaysChallenge else { return }
        await dataManager.skipChallenge(challenge, reason: skipReason)
        skipReason = ""
    }
    
    private func generateCustomChallenge() async {
        await dataManager.generateCustomChallenge()
    }
    
    private func celebrateCompletion() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Could add confetti animation or sound here
    }
}

// MARK: - Active Challenge Card
struct ActiveChallengeCard: View {
    let challenge: DailyChallenge
    let onComplete: (Int, String) async -> Void
    let onSkip: () -> Void
    @Binding var showingAnimation: Bool
    
    @State private var showingCompletionFlow = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Challenge header with time and difficulty
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: challenge.difficulty.icon)
                            .font(.caption)
                            .foregroundColor(challenge.difficulty.color)
                        
                        Text(challenge.difficulty.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(challenge.difficulty.color)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(challenge.estimatedTimeMinutes) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !challenge.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(challenge.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(challenge.path.color.opacity(0.1))
                                    .foregroundColor(challenge.path.color)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Path icon with pulse animation
                Image(systemName: challenge.path.icon)
                    .font(.title)
                    .foregroundColor(challenge.path.color)
                    .scaleEffect(pulseScale)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: pulseScale
                    )
            }
            
            // Challenge content
            VStack(alignment: .leading, spacing: 16) {
                Text(challenge.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(challenge.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Complete") {
                    showingCompletionFlow = true
                }
                .buttonStyle(PrimaryButtonStyle(color: challenge.path.color))
                .frame(maxWidth: .infinity)
                
                Button("Skip") {
                    onSkip()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(24)
        .background(.regularMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(challenge.path.color.opacity(0.3), lineWidth: 2)
        )
        .scaleEffect(showingAnimation ? 1.05 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingAnimation)
        .sheet(isPresented: $showingCompletionFlow) {
            CompletionFlow(
                challenge: challenge,
                onComplete: onComplete
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Completed Challenge Card
struct CompletedChallengeCard: View {
    let challenge: DailyChallenge
    
    var body: some View {
        VStack(spacing: 20) {
            // Success header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Challenge Completed!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    if let completedAt = challenge.completedAt {
                        Text("Completed at \(completedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Challenge info
            VStack(alignment: .leading, spacing: 12) {
                Text(challenge.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let effortLevel = challenge.effortLevel {
                    HStack {
                        Text("Effort Level:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { level in
                                Image(systemName: level <= effortLevel ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(level <= effortLevel ? .orange : .gray)
                            }
                        }
                    }
                }
                
                if let notes = challenge.userNotes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            // Motivational message
            Text("🔥 Keep the momentum going! You're building unstoppable habits.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(24)
        .background(.regularMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Skipped Challenge Card
struct SkippedChallengeCard: View {
    let challenge: DailyChallenge
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "forward.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Challenge Skipped")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("That's okay - tomorrow is a new opportunity!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let reason = challenge.skipReason, !reason.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reason:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(reason)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Completion Flow
struct CompletionFlow: View {
    let challenge: DailyChallenge
    let onComplete: (Int, String) async -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var effortLevel = 3
    @State private var notes = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Challenge Difficulty")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose your preferred challenge intensity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Difficulty options
                VStack(spacing: 16) {
                    ForEach(DailyChallenge.ChallengeDifficulty.allCases, id: \.self) { difficulty in
                        DifficultyOptionCard(
                            difficulty: difficulty,
                            isSelected: selectedDifficulty == difficulty,
                            onTap: { selectedDifficulty = difficulty }
                        )
                    }
                }
                
                Spacer()
                
                // Save button
                Button("Save Preference") {
                    onSelectionChanged(selectedDifficulty)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(PrimaryButtonStyle(color: .blue))
                .frame(maxWidth: .infinity)
            }
            .padding(24)
            .navigationTitle("")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Difficulty Option Card
struct DifficultyOptionCard: View {
    let difficulty: DailyChallenge.ChallengeDifficulty
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon and color indicator
                ZStack {
                    Circle()
                        .fill(difficulty.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: difficulty.icon)
                        .font(.title2)
                        .foregroundColor(difficulty.color)
                }
                
                // Difficulty info
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(difficultyDescription(for: difficulty))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? difficulty.color.opacity(0.1) : .regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? difficulty.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func difficultyDescription(for difficulty: DailyChallenge.ChallengeDifficulty) -> String {
        switch difficulty {
        case .micro:
            return "Quick wins, 2-5 minute challenges that build momentum"
        case .standard:
            return "Balanced challenges that push you without overwhelming"
        case .advanced:
            return "Deep work sessions that create significant growth"
        case .custom:
            return "AI-generated challenges tailored to your specific needs"
        }
    }
}

// MARK: - Challenge History Sheet
struct ChallengeHistory: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTimeframe: HistoryTimeframe = .thisWeek
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Timeframe picker
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(HistoryTimeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.displayName).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search challenges...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(.regularMaterial)
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Challenge list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredChallenges) { challenge in
                            HistoryChallengeCard(challenge: challenge)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Challenge History")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            Task {
                await dataManager.loadChallengeHistory(for: selectedTimeframe)
            }
        }
        .onChange(of: selectedTimeframe) { _ in
            Task {
                await dataManager.loadChallengeHistory(for: selectedTimeframe)
            }
        }
    }
    
    private var filteredChallenges: [DailyChallenge] {
        let challenges = dataManager.challengeHistory
        
        if searchText.isEmpty {
            return challenges
        } else {
            return challenges.filter { challenge in
                challenge.title.localizedCaseInsensitiveContains(searchText) ||
                challenge.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - History Challenge Card
struct HistoryChallengeCard: View {
    let challenge: DailyChallenge
    @State private var showingDetails = false
    
    var body: some View {
        Button {
            showingDetails = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header with date and status
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(challenge.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(challenge.date.formatted(.dateTime.weekday(.wide)))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: challenge.status.icon)
                            .font(.caption)
                            .foregroundColor(challenge.status.color)
                        
                        Text(challenge.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(challenge.status.color)
                    }
                }
                
                // Challenge content
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                // Footer with difficulty and effort
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: challenge.difficulty.icon)
                            .font(.caption2)
                            .foregroundColor(challenge.difficulty.color)
                        
                        Text(challenge.difficulty.displayName)
                            .font(.caption2)
                            .foregroundColor(challenge.difficulty.color)
                    }
                    
                    Spacer()
                    
                    if let effortLevel = challenge.effortLevel, challenge.isCompleted {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { level in
                                Image(systemName: level <= effortLevel ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(level <= effortLevel ? .orange : .gray)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(challenge.path.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetails) {
            ChallengeDetailView(challenge: challenge)
        }
    }
}

// MARK: - Challenge Detail View
struct ChallengeDetailView: View {
    let challenge: DailyChallenge
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Status header
                    HStack {
                        Image(systemName: challenge.status.icon)
                            .font(.title)
                            .foregroundColor(challenge.status.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(challenge.status.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(challenge.status.color)
                            
                            Text(challenge.date.formatted(date: .complete, time: .omitted))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Challenge content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(challenge.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(challenge.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    // Challenge metadata
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(
                            label: "Training Path",
                            value: challenge.path.displayName,
                            icon: challenge.path.icon,
                            color: challenge.path.color
                        )
                        
                        DetailRow(
                            label: "Difficulty",
                            value: challenge.difficulty.displayName,
                            icon: challenge.difficulty.icon,
                            color: challenge.difficulty.color
                        )
                        
                        DetailRow(
                            label: "Estimated Time",
                            value: "\(challenge.estimatedTimeMinutes) minutes",
                            icon: "clock",
                            color: .blue
                        )
                    }
                    
                    // Completion details (if completed)
                    if challenge.isCompleted {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Completion Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if let completedAt = challenge.completedAt {
                                DetailRow(
                                    label: "Completed At",
                                    value: completedAt.formatted(date: .omitted, time: .standard),
                                    icon: "checkmark.circle",
                                    color: .green
                                )
                            }
                            
                            if let effortLevel = challenge.effortLevel {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    Text("Effort Level:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 2) {
                                        ForEach(1...5, id: \.self) { level in
                                            Image(systemName: level <= effortLevel ? "star.fill" : "star")
                                                .font(.caption)
                                                .foregroundColor(level <= effortLevel ? .orange : .gray)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                            
                            if let notes = challenge.userNotes, !notes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes:")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    Text(notes)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding(12)
                                        .background(.regularMaterial)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(16)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                    }
                    
                    // Skip details (if skipped)
                    if challenge.isSkipped {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Skip Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if let reason = challenge.skipReason, !reason.isEmpty {
                                DetailRow(
                                    label: "Reason",
                                    value: reason,
                                    icon: "info.circle",
                                    color: .orange
                                )
                            }
                        }
                        .padding(16)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Challenge Details")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Supporting Enums and Extensions

enum HistoryTimeframe: String, CaseIterable {
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case last30Days = "last_30_days"
    case allTime = "all_time"
    
    var displayName: String {
        switch self {
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .last30Days: return "Last 30 Days"
        case .allTime: return "All Time"
        }
    }
}

// MARK: - Enhanced Data Manager Extensions for Challenges

extension EnhancedDataManager {
    var preferredDifficulty: DailyChallenge.ChallengeDifficulty {
        // This would be stored in user preferences
        return .standard
    }
    
    var weeklyProgressData: [DayProgress] {
        // Calculate weekly progress from challenges
        return DayProgress.weeklyProgress(from: getWeekChallenges())
    }
    
    var recentChallenges: [DailyChallenge] {
        // Return last 10 challenges
        return challengeHistory.prefix(10).map { $0 }
    }
    
    var challengeHistory: [DailyChallenge] {
        // This would fetch from Core Data
        return []
    }
    
    var weeklyCompletedChallenges: Int {
        return getWeekChallenges().filter { $0.isCompleted }.count
    }
    
    var weeklyAverageEffort: Double {
        let weekChallenges = getWeekChallenges().filter { $0.isCompleted && $0.effortLevel != nil }
        guard !weekChallenges.isEmpty else { return 0.0 }
        
        let totalEffort = weekChallenges.compactMap { $0.effortLevel }.reduce(0, +)
        return Double(totalEffort) / Double(weekChallenges.count)
    }
    
    func updatePreferredDifficulty(_ difficulty: DailyChallenge.ChallengeDifficulty) {
        // Update user preferences
        UserDefaults.standard.set(difficulty.rawValue, forKey: "preferred_difficulty")
    }
    
    func refreshChallengeData() async {
        loadTodaysChallenge()
        await loadChallengeHistory(for: .thisWeek)
    }
    
    func loadChallengeHistory(for timeframe: HistoryTimeframe) async {
        // Load challenge history from Core Data based on timeframe
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch timeframe {
        case .thisWeek:
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .thisMonth:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .allTime:
            startDate = Date.distantPast
        }
        
        let request: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDailyChallenge.date, ascending: false)]
        
        let challenges = coreDataStack.fetch(request).map { $0.toDomainModel() }
        
        DispatchQueue.main.async {
            // Update published property
        }
    }
    
    func generateCustomChallenge() async {
        // Use AI service to generate a custom challenge
        // This would call the AI integration system
        guard let path = userProfile?.selectedPath else { return }
        
        // Simulate AI generation
        let customChallenge = DailyChallenge(
            title: "Custom Challenge",
            description: "AI-generated challenge based on your preferences",
            path: path,
            difficulty: .custom,
            date: Date()
        )
        
        // Save to Core Data
        let cdChallenge = CDDailyChallenge(context: coreDataStack.context)
        cdChallenge.updateFromDomainModel(customChallenge)
        coreDataStack.save()
        
        // Update today's challenge
        loadTodaysChallenge()
    }
    
    func completeChallenge(_ challenge: DailyChallenge, effortLevel: Int, notes: String) async {
        let request: NSFetchRequest<CDDailyChallenge> = CDDailyChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", challenge.id as CVarArg)
        
        if let cdChallenge = coreDataStack.fetch(request).first {
            cdChallenge.markCompleted(effortLevel: effortLevel, notes: notes)
            coreDataStack.save()
            
            // Update user profile streak
            updateUserStreak()
            
            // Reload today's challenge
            loadTodaysChallenge()
            
            // Check for achievements
            checkForChallengeAchievements()
        }
    }
    
    private func checkForChallengeAchievements() {
        // Check if user earned any achievements from completing challenges
        // This would analyze completion patterns and award achievements
    }
}

// MARK: - Preview Support
struct ChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = EnhancedDataManager()
        
        ChallengeView()
            .environmentObject(dataManager)
            .preferredColorScheme(.light)
    }
}Name: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Challenge Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("How did it go?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Effort level selector
                VStack(alignment: .leading, spacing: 16) {
                    Text("Effort Level")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        HStack {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    effortLevel = level
                                } label: {
                                    Image(systemName: level <= effortLevel ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundColor(level <= effortLevel ? .orange : .gray)
                                }
                            }
                        }
                        
                        Text(effortDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Notes section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes (Optional)")
                        .font(.headline)
                    
                    TextField("How did you feel? Any insights?", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                Spacer()
                
                // Submit button
                Button {
                    submitCompletion()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isSubmitting ? "Saving..." : "Complete Challenge")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(challenge.path.color)
                    .cornerRadius(12)
                }
                .disabled(isSubmitting)
            }
            .padding(24)
            .navigationTitle("")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var effortDescription: String {
        switch effortLevel {
        case 1: return "Very Easy"
        case 2: return "Easy"
        case 3: return "Moderate"
        case 4: return "Challenging"
        case 5: return "Very Difficult"
        default: return "Moderate"
        }
    }
    
    private func submitCompletion() {
        isSubmitting = true
        
        Task {
            await onComplete(effortLevel, notes)
            
            DispatchQueue.main.async {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Difficulty Display
struct DifficultyDisplay: View {
    let difficulty: DailyChallenge.ChallengeDifficulty
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: difficulty.icon)
                .font(.title3)
                .foregroundColor(difficulty.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Preferred Difficulty")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(difficulty.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(difficulty.color)
            }
            
            Spacer()
        }
        .padding(12)
        .background(difficulty.color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Streak Visualization
struct StreakVisualization: View {
    let weeklyData: [DayProgress]
    let pathColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            // Week view
            HStack(spacing: 8) {
                ForEach(weeklyData.indices, id: \.self) { index in
                    let dayData = weeklyData[index]
                    
                    VStack(spacing: 6) {
                        Text(dayData.dayLetter)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(dayData.isCompleted ? pathColor : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(pathColor.opacity(0.3), lineWidth: 1)
                            )
                        
                        if dayData.isToday {
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
            
            // Summary stats
            HStack {
                VStack(spacing: 2) {
                    Text("\(weeklyData.filter(\.isCompleted).count)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(pathColor)
                    
                    Text("Days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("\(Int(Double(weeklyData.filter(\.isCompleted).count) / 7.0 * 100))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(pathColor)
                    
                    Text("Success")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Recent Challenge Row
struct RecentChallengeRow: View {
    let challenge: DailyChallenge
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: challenge.status.icon)
                .font(.title3)
                .foregroundColor(challenge.status.color)
                .frame(width: 24)
            
            // Challenge info
            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(challenge.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Difficulty indicator
            Text(challenge.difficulty.displayName)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(challenge.difficulty.color.opacity(0.1))
                .foregroundColor(challenge.difficulty.color)
                .cornerRadius(4)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Weekly Stat Card
struct WeeklyStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Difficulty Selector Sheet
struct DifficultySelector: View {
    let currentDifficulty: DailyChallenge.ChallengeDifficulty
    let onSelectionChanged: (DailyChallenge.ChallengeDifficulty) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDifficulty: DailyChallenge.ChallengeDifficulty
    
    init(currentDifficulty: DailyChallenge.ChallengeDifficulty, onSelectionChanged: @escaping (DailyChallenge.ChallengeDifficulty) -> Void) {
        self.currentDifficulty = currentDifficulty
        self.onSelectionChanged = onSelectionChanged
        self._selectedDifficulty = State(initialValue: currentDifficulty)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(system
