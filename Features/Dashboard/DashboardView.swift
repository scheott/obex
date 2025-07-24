import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingPathSelector = false
    @State private var showingChallengeDetail = false
    @State private var showingMoodSelector = false
    @State private var selectedMood: AICheckIn.MoodRating = .neutral
    @State private var dailyQuote = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Streak Section
                    streakSection
                    
                    // Today's Challenge Section
                    todaysChallengeSection
                    
                    // Quick Mood Check
                    moodCheckSection
                    
                    // Book of the Day
                    bookOfTheDaySection
                    
                    // Progress Overview
                    progressSection
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingPathSelector = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: dataManager.userProfile?.selectedPath.icon ?? "person.circle")
                            Text(dataManager.userProfile?.selectedPath.displayName ?? "Path")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    }
                }
            }
            .sheet(isPresented: $showingPathSelector) {
                PathSelectorSheet()
            }
            .sheet(isPresented: $showingChallengeDetail) {
                ChallengeDetailSheet()
            }
            .sheet(isPresented: $showingMoodSelector) {
                MoodSelectorSheet(selectedMood: $selectedMood)
            }
            .onAppear {
                generateDailyQuote()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Ready to build \(dataManager.userProfile?.selectedPath.displayName.lowercased() ?? "discipline") today?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Current Path Badge
                if let path = dataManager.userProfile?.selectedPath {
                    VStack(spacing: 4) {
                        Image(systemName: path.icon)
                            .font(.title2)
                            .foregroundColor(path.color)
                        
                        Text(path.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(path.color)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(path.color.opacity(0.1))
                    )
                }
            }
            
            // Daily Quote/Insight
            if !dailyQuote.isEmpty {
                Text(dailyQuote)
                    .font(.callout)
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Streak Section
    private var streakSection: some View {
        HStack(spacing: 16) {
            // Current Streak
            VStack(spacing: 4) {
                Text("\(dataManager.userProfile?.currentStreak ?? 0)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                
                Text("Day Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
            
            // Best Streak
            VStack(spacing: 4) {
                Text("\(dataManager.userProfile?.longestStreak ?? 0)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
            
            // Total Completed
            VStack(spacing: 4) {
                Text("\(dataManager.userProfile?.totalChallengesCompleted ?? 0)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
        }
    }
    
    // MARK: - Today's Challenge Section
    private var todaysChallengeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Challenge")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let challenge = dataManager.todaysChallenge {
                    Text(challenge.difficulty.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(dataManager.userProfile?.selectedPath.color.opacity(0.2) ?? Color.blue.opacity(0.2))
                        )
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
            }
            
            if let challenge = dataManager.todaysChallenge {
                VStack(alignment: .leading, spacing: 12) {
                    Text(challenge.title)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(challenge.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    HStack {
                        if challenge.isCompleted {
                            Label("Completed!", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        } else {
                            Button {
                                dataManager.completeChallenge()
                            } label: {
                                Text("Mark Complete")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(dataManager.userProfile?.selectedPath.color ?? .blue)
                                    )
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            showingChallengeDetail = true
                        } label: {
                            Text("View Details")
                                .font(.subheadline)
                                .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                )
            } else {
                Text("Loading today's challenge...")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                    )
            }
        }
    }
    
    // MARK: - Mood Check Section
    private var moodCheckSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Mood Check")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ForEach(AICheckIn.MoodRating.allCases, id: \.self) { mood in
                    Button {
                        selectedMood = mood
                        recordMood(mood)
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.title2)
                            
                            Text(mood.rawValue.capitalized)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMood == mood ? 
                                      (dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.2) : 
                                      Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedMood == mood ? 
                                        (dataManager.userProfile?.selectedPath.color ?? .blue) : 
                                        Color.clear, lineWidth: 2)
                        )
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
        }
    }
    
    // MARK: - Book of the Day Section
    private var bookOfTheDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Book Insight")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let book = BookGenerator.getBookOfTheDay(for: dataManager.userProfile?.selectedPath ?? .discipline) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("by \(book.author)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "book.fill")
                            .font(.title2)
                            .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    }
                    
                    Text(book.keyInsight)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .italic()
                    
                    Text("Today's Action: \(book.dailyAction)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                )
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                // Week Progress
                VStack(alignment: .leading, spacing: 8) {
                    Text("Days Active")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<7) { day in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(day < (dataManager.userProfile?.currentStreak ?? 0) % 7 ? 
                                      (dataManager.userProfile?.selectedPath.color ?? .blue) : 
                                      Color.gray.opacity(0.3))
                                .frame(width: 8, height: 24)
                        }
                    }
                }
                
                Spacer()
                
                // Check-ins
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(dataManager.todaysCheckIns.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Check-ins Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Journal Entry
                NavigationLink(destination: JournalView()) {
                    QuickActionCard(
                        title: "Journal",
                        subtitle: "Reflect & Record",
                        icon: "book.closed.fill",
                        color: .indigo
                    )
                }
                
                // Check-in
                NavigationLink(destination: CheckInView()) {
                    QuickActionCard(
                        title: "Check-in",
                        subtitle: "Share Your Day",
                        icon: "message.fill",
                        color: .green
                    )
                }
                
                // Book Station
                NavigationLink(destination: BookStationView()) {
                    QuickActionCard(
                        title: "Books",
                        subtitle: "Explore Wisdom",
                        icon: "book.fill",
                        color: .orange
                    )
                }
                
                // Change Path
                Button {
                    showingPathSelector = true
                } label: {
                    QuickActionCard(
                        title: "Switch Path",
                        subtitle: "Change Focus",
                        icon: "arrow.triangle.2.circlepath",
                        color: .purple
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Good night"
        }
    }
    
    // MARK: - Helper Methods
    private func generateDailyQuote() {
        guard let path = dataManager.userProfile?.selectedPath else { return }
        
        let quotes = [
            .discipline: [
                "Discipline is the bridge between goals and accomplishment.",
                "We are what we repeatedly do. Excellence is not an act, but a habit.",
                "The pain of discipline weighs ounces, but the pain of regret weighs tons."
            ],
            .clarity: [
                "Clarity comes from engagement, not thought.",
                "The clearer you are, the faster you'll get where you want to go.",
                "In the midst of chaos, there is also opportunity."
            ],
            .confidence: [
                "Confidence is not 'they will like me.' Confidence is 'I'll be fine if they don't.'",
                "You are braver than you believe, stronger than you seem, and smarter than you think.",
                "Confidence comes not from always being right but from not fearing to be wrong."
            ],
            .purpose: [
                "The purpose of life is not to be happy. It is to be useful, honorable, compassionate.",
                "Success is not the key to happiness. Happiness is the key to success.",
                "The best way to find yourself is to lose yourself in the service of others."
            ],
            .authenticity: [
                "Authenticity is the daily practice of letting go of who we think we're supposed to be.",
                "To be yourself in a world that is constantly trying to make you something else is the greatest accomplishment.",
                "The privilege of a lifetime is being who you are."
            ]
        ]
        
        dailyQuote = quotes[path]?.randomElement() ?? ""
    }
    
    private func recordMood(_ mood: AICheckIn.MoodRating) {
        // In a real app, this would save the mood data
        // For now, we'll just provide visual feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Path Selector Sheet
struct PathSelectorSheet: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose Your Focus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Select the area you want to develop most right now. You can change this anytime.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(TrainingPath.allCases) { path in
                        Button {
                            dataManager.updateUserPath(path)
                            dismiss()
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: path.icon)
                                    .font(.title)
                                    .foregroundColor(path.color)
                                
                                Text(path.displayName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(path.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(path == dataManager.userProfile?.selectedPath ? 
                                          path.color.opacity(0.2) : 
                                          Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(path == dataManager.userProfile?.selectedPath ? 
                                            path.color : 
                                            Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Training Path")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Challenge Detail Sheet
struct ChallengeDetailSheet: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                if let challenge = dataManager.todaysChallenge {
                    VStack(alignment: .leading, spacing: 16) {
                        // Challenge Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(challenge.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text(challenge.path.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(challenge.path.color)
                                
                                Spacer()
                                
                                Text(challenge.difficulty.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(challenge.path.color.opacity(0.2))
                                    )
                                    .foregroundColor(challenge.path.color)
                            }
                        }
                        
                        Divider()
                        
                        // Challenge Description
                        Text("Challenge Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(challenge.description)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        // Action Button
                        if !challenge.isCompleted {
                            Button {
                                dataManager.completeChallenge()
                                dismiss()
                            } label: {
                                Text("Mark Complete")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(challenge.path.color)
                                    )
                            }
                            .padding(.top)
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text("Challenge Completed!")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.1))
                            )
                            .padding(.top)
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Today's Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Mood Selector Sheet
struct MoodSelectorSheet: View {
    @Binding var selectedMood: AICheckIn.MoodRating
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("How are you feeling?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                VStack(spacing: 20) {
                    ForEach(AICheckIn.MoodRating.allCases.reversed(), id: \.self) { mood in
                        Button {
                            selectedMood = mood
                            dismiss()
                        } label: {
                            HStack(spacing: 16) {
                                Text(mood.emoji)
                                    .font(.title)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mood.rawValue.capitalized)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(moodDescription(for: mood))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedMood == mood {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedMood == mood ? 
                                          Color.green.opacity(0.1) : 
                                          Color(.systemGray6))
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Mood Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func moodDescription(for mood: AICheckIn.MoodRating) -> String {
        switch mood {
        case .excellent:
            return "Feeling amazing and energized"
        case .great:
            return "Really good and positive"
        case .good:
            return "Pretty good overall"
        case .neutral:
            return "Okay, neither good nor bad"
        case .low:
            return "Not feeling great today"
        }
    }
}
