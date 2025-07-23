import SwiftUI

struct ChallengeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingCompletionAnimation = false
    @State private var showingStreakDetail = false
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        dataManager.userProfile?.selectedPath.color.opacity(0.1) ?? Color.blue.opacity(0.1),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with streak info
                        StreakHeaderView(showingDetail: $showingStreakDetail)
                        
                        // Today's Challenge Card
                        if let challenge = dataManager.todaysChallenge {
                            TodaysChallengeCard(
                                challenge: challenge,
                                showingAnimation: $showingCompletionAnimation
                            )
                        } else {
                            EmptyChallengeCard()
                        }
                        
                        // Challenge History
                        ChallengeHistorySection()
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Today's Challenge")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingStreakDetail) {
                StreakDetailView()
            }
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseAnimation.toggle()
        }
    }
}

// MARK: - Streak Header View
struct StreakHeaderView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var showingDetail: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(dataManager.userProfile?.currentStreak ?? 0)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    
                    Text("days")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)
                }
            }
            
            Spacer()
            
            Button(action: { showingDetail = true }) {
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("Best: \(dataManager.userProfile?.longestStreak ?? 0)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Today's Challenge Card
struct TodaysChallengeCard: View {
    @EnvironmentObject var dataManager: DataManager
    let challenge: DailyChallenge
    @Binding var showingAnimation: Bool
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Challenge Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.path.displayName.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(challenge.path.color)
                    
                    Text("TODAY'S CHALLENGE")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: challenge.path.icon)
                    .font(.title2)
                    .foregroundColor(challenge.path.color)
                    .scaleEffect(pulseScale)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: pulseScale
                    )
            }
            
            // Challenge Content
            VStack(alignment: .leading, spacing: 16) {
                Text(challenge.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                
                if !challenge.description.isEmpty {
                    Text(challenge.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                // Difficulty Badge
                HStack {
                    Image(systemName: "target")
                        .font(.caption)
                    Text(challenge.difficulty.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(challenge.path.color.opacity(0.8))
                .cornerRadius(12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Completion Button
            if challenge.isCompleted {
                CompletedChallengeView(challenge: challenge)
            } else {
                Button(action: completeChallenge) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        
                        Text("Mark as Complete")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(challenge.path.color)
                    .cornerRadius(12)
                }
                .scaleEffect(showingAnimation ? 1.05 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingAnimation)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(challenge.path.color.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
    
    private func completeChallenge() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingAnimation = true
            dataManager.completeChallenge()
        }
        
        // Reset animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showingAnimation = false
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Completed Challenge View
struct CompletedChallengeView: View {
    let challenge: DailyChallenge
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Challenge Completed!")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            if let completedAt = challenge.completedAt {
                Text("Completed at \(completedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Motivational message
            Text("🔥 Keep the momentum going!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Empty Challenge Card
struct EmptyChallengeCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Challenge Today")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Check back tomorrow for your next challenge!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
}

// MARK: - Challenge History Section
struct ChallengeHistorySection: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to full history
                }
                .font(.subheadline)
                .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
            }
            
            // Weekly streak visualization
            WeeklyStreakView()
            
            // Stats cards
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Completed",
                    value: "\(dataManager.userProfile?.totalChallengesCompleted ?? 0)",
                    icon: "trophy.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "This Week",
                    value: "5", // This would be calculated
                    icon: "calendar",
                    color: .blue
                )
            }
        }
    }
}

// MARK: - Weekly Streak View
struct WeeklyStreakView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(0..<7) { day in
                    VStack(spacing: 4) {
                        Text(dayLetter(for: day))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .fill(dayCompleted(day) ? (dataManager.userProfile?.selectedPath.color ?? .blue) : Color(.systemGray5))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func dayLetter(for index: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[index]
    }
    
    private func dayCompleted(_ day: Int) -> Bool {
        // This would check actual completion data
        // For now, showing sample data
        return day < 5
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Streak Detail View
struct StreakDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak Stats
                    VStack(spacing: 20) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        VStack(spacing: 8) {
                            Text("\(dataManager.userProfile?.currentStreak ?? 0)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                            
                            Text("Day Streak")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Streak milestones
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Milestones")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            MilestoneRow(target: 7, current: dataManager.userProfile?.currentStreak ?? 0, title: "First Week")
                            MilestoneRow(target: 30, current: dataManager.userProfile?.currentStreak ?? 0, title: "One Month")
                            MilestoneRow(target: 100, current: dataManager.userProfile?.currentStreak ?? 0, title: "Century Club")
                            MilestoneRow(target: 365, current: dataManager.userProfile?.currentStreak ?? 0, title: "Full Year")
                        }
                    }
                    
                    // Personal best
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personal Best")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                            
                            Text("\(dataManager.userProfile?.longestStreak ?? 0) days")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Streak Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Milestone Row
struct MilestoneRow: View {
    let target: Int
    let current: Int
    let title: String
    
    private var isCompleted: Bool {
        current >= target
    }
    
    private var progress: Double {
        min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(current)/\(target) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isCompleted {
                ProgressView(value: progress)
                    .frame(width: 60)
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCompleted ? Color.green.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct ChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeView()
            .environmentObject(DataManager())
    }
}