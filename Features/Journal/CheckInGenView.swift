import SwiftUI
import Foundation

// MARK: - Main Check-In View
struct CheckInView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @State private var selectedTimeOfDay: AICheckIn.CheckInTime = .morning
    @State private var currentPrompt = ""
    @State private var userResponse = ""
    @State private var selectedMood: AICheckIn.MoodRating?
    @State private var effortLevel = 3
    @State private var isSubmitting = false
    @State private var showingAIResponse = false
    @State private var aiResponse = ""
    @State private var hasSubmittedToday = false
    @State private var showingHistory = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Today's Check-ins Status
                    todaysStatusSection
                    
                    // Time of Day Selector
                    timeOfDaySelector
                    
                    // Current Prompt
                    promptCard
                    
                    // Response Input Section
                    if !hasSubmittedToday {
                        responseInputSection
                    }
                    
                    // AI Response
                    if showingAIResponse && !aiResponse.isEmpty {
                        aiResponseCard
                    }
                    
                    // Recent Check-ins
                    recentCheckInsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .refreshable {
                await refreshData()
            }
        }
        .sheet(isPresented: $showingHistory) {
            CheckInHistory()
                .environmentObject(dataManager)
        }
        .onAppear {
            setupCheckIn()
        }
        .onChange(of: selectedTimeOfDay) { _ in
            generateNewPrompt()
            checkIfSubmittedToday()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Check-In")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(getCheckInSubtitle())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // History Button
                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    }
                    
                    // Streak indicator
                    if dataManager.userProfile?.currentStreak ?? 0 > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text("\\(dataManager.userProfile?.currentStreak ?? 0)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
            }
            
            // Daily stats
            checkInStatsRow
        }
    }
    
    // MARK: - Check-In Stats Row
    private var checkInStatsRow: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Today",
                value: "\\(todaysCheckInCount)",
                subtitle: "check-ins",
                color: dataManager.userProfile?.selectedPath.color ?? .blue
            )
            
            StatCard(
                title: "This Week",
                value: "\\(weeklyCheckInCount)",
                subtitle: "total",
                color: .green
            )
            
            StatCard(
                title: "Avg Mood",
                value: averageMoodEmoji,
                subtitle: "this week",
                color: .purple
            )
            
            Spacer()
        }
    }
    
    // MARK: - Today's Status Section
    private var todaysStatusSection: some View {
        if !dataManager.todaysCheckIns.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today's Check-ins")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(dataManager.todaysCheckIns.count) completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    ForEach(dataManager.todaysCheckIns.prefix(2)) { checkIn in
                        CheckInSummaryCard(checkIn: checkIn)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
        }
    }
    
    // MARK: - Time of Day Selector
    private var timeOfDaySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Check-in Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ForEach(AICheckIn.CheckInTime.allCases, id: \.self) { timeOption in
                    Button {
                        selectedTimeOfDay = timeOption
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: timeOption.icon)
                                .font(.title3)
                            
                            Text(timeOption.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTimeOfDay == timeOption ? .white : (dataManager.userProfile?.selectedPath.color ?? .blue))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTimeOfDay == timeOption ? (dataManager.userProfile?.selectedPath.color ?? .blue) : Color(.systemGray6))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Prompt Card
    private var promptCard: some View {
        PromptCard(
            prompt: currentPrompt,
            timeOfDay: selectedTimeOfDay,
            onRefresh: {
                generateNewPrompt()
            }
        )
    }
    
    // MARK: - Response Input Section
    private var responseInputSection: some View {
        VStack(spacing: 20) {
            // Response Input
            ResponseInput(
                response: $userResponse,
                isTextFieldFocused: $isTextFieldFocused,
                placeholder: getResponsePlaceholder()
            )
            
            // Mood Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("How are you feeling?")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                MoodSelector(selectedMood: $selectedMood)
            }
            
            // Effort Level Picker
            EffortLevelPicker(effortLevel: $effortLevel)
            
            // Submit Button
            submitButton
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            submitCheckIn()
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.subheadline)
                }
                
                Text(isSubmitting ? "Submitting..." : "Submit Check-in")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canSubmit ? (dataManager.userProfile?.selectedPath.color ?? .blue) : Color(.systemGray4))
            )
        }
        .disabled(!canSubmit || isSubmitting)
    }
    
    // MARK: - AI Response Card
    private var aiResponseCard: some View {
        AIResponseCard(
            response: aiResponse,
            followUpQuestion: CheckInGenerator.generateFollowUpQuestion(
                for: dataManager.userProfile?.selectedPath ?? .discipline,
                basedOn: userResponse
            )
        )
    }
    
    // MARK: - Recent Check-ins Section
    private var recentCheckInsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Check-ins")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingHistory = true
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
            }
            
            if dataManager.recentCheckIns.isEmpty {
                Text("No recent check-ins. Start your first one above!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(dataManager.recentCheckIns.prefix(3)) { checkIn in
                        CheckInCard(checkIn: checkIn)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canSubmit: Bool {
        return !userResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
               selectedMood != nil
    }
    
    private var todaysCheckInCount: Int {
        return dataManager.todaysCheckIns.count
    }
    
    private var weeklyCheckInCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return dataManager.recentCheckIns.filter { $0.date >= weekAgo }.count
    }
    
    private var averageMoodEmoji: String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyCheckIns = dataManager.recentCheckIns.filter { $0.date >= weekAgo }
        let moods = weeklyCheckIns.compactMap { $0.mood }
        
        guard !moods.isEmpty else { return "😐" }
        
        let averageScore = moods.reduce(0) { $0 + $1.score } / moods.count
        
        switch averageScore {
        case 5...6: return "😊"
        case 4: return "🙂"
        case 3: return "😐"
        case 2: return "😔"
        default: return "😞"
        }
    }
    
    // MARK: - Helper Methods
    private func setupCheckIn() {
        determineTimeOfDay()
        generateNewPrompt()
        checkIfSubmittedToday()
        dataManager.loadTodaysCheckIns()
    }
    
    private func determineTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5...11:
            selectedTimeOfDay = .morning
        case 12...17:
            selectedTimeOfDay = .afternoon
        default:
            selectedTimeOfDay = .evening
        }
    }
    
    private func generateNewPrompt() {
        guard let path = dataManager.userProfile?.selectedPath else { return }
        
        currentPrompt = CheckInGenerator.generatePrompt(
            for: path,
            timeOfDay: selectedTimeOfDay
        )
    }
    
    private func checkIfSubmittedToday() {
        let today = Calendar.current.startOfDay(for: Date())
        hasSubmittedToday = dataManager.todaysCheckIns.contains { checkIn in
            Calendar.current.isDate(checkIn.date, inSameDayAs: today) &&
            checkIn.timeOfDay == selectedTimeOfDay
        }
    }
    
    private func submitCheckIn() {
        guard let mood = selectedMood,
              let path = dataManager.userProfile?.selectedPath else { return }
        
        isSubmitting = true
        isTextFieldFocused = false
        
        // Create check-in
        var checkIn = AICheckIn(
            date: Date(),
            timeOfDay: selectedTimeOfDay,
            prompt: currentPrompt
        )
        
        checkIn.userResponse = userResponse
        checkIn.mood = mood
        checkIn.effortLevel = effortLevel
        
        // Generate AI response
        Task {
            let response = await CheckInGenerator.generateAIResponse(
                to: userResponse,
                for: path,
                timeOfDay: selectedTimeOfDay,
                mood: mood,
                recentCheckIns: Array(dataManager.recentCheckIns.prefix(3))
            )
            
            await MainActor.run {
                checkIn.aiResponse = response
                aiResponse = response
                
                // Submit to data manager
                Task {
                    await dataManager.submitCheckIn(checkIn)
                    
                    // Reset form
                    userResponse = ""
                    selectedMood = nil
                    effortLevel = 3
                    hasSubmittedToday = true
                    isSubmitting = false
                    showingAIResponse = true
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
        }
    }
    
    private func refreshData() async {
        await dataManager.refreshCheckInData()
        checkIfSubmittedToday()
        generateNewPrompt()
    }
    
    private func getCheckInSubtitle() -> String {
        if hasSubmittedToday {
            return "You've checked in for \(selectedTimeOfDay.displayName.lowercased()) today"
        } else {
            return "How are you doing this \(selectedTimeOfDay.displayName.lowercased())?"
        }
    }
    
    private func getResponsePlaceholder() -> String {
        switch selectedTimeOfDay {
        case .morning:
            return "Share what's on your mind as you start the day..."
        case .afternoon:
            return "How has your day been going so far..."
        case .evening:
            return "Reflect on your day and how you're feeling..."
        }
    }
}

// MARK: - Prompt Card
struct PromptCard: View {
    let prompt: String
    let timeOfDay: AICheckIn.CheckInTime
    let onRefresh: () -> Void
    @EnvironmentObject var dataManager: EnhancedDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: timeOfDay.icon)
                        .font(.title3)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    
                    Text("\(timeOfDay.displayName) Reflection")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button {
                    onRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
            }
            
            Text(prompt)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Response Input
struct ResponseInput: View {
    @Binding var response: String
    var isTextFieldFocused: FocusState<Bool>.Binding
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Your Response")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(response.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextEditor(text: $response)
                .font(.body)
                .frame(minHeight: 100)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .focused(isTextFieldFocused)
                .overlay(
                    Group {
                        if response.isEmpty {
                            VStack {
                                HStack {
                                    Text(placeholder)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 16)
                                        .padding(.top, 20)
                                    
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                )
        }
    }
}

// MARK: - Mood Selector (Enhanced)
struct MoodSelector: View {
    @Binding var selectedMood: AICheckIn.MoodRating?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AICheckIn.MoodRating.allCases, id: \.self) { mood in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMood = selectedMood == mood ? nil : mood
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(mood.emoji)
                                .font(.title2)
                                .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                            
                            Text(mood.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedMood == mood ? .white : .primary)
                        .frame(width: 70, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMood == mood ? mood.color : Color(.systemGray6))
                                .shadow(color: selectedMood == mood ? mood.color.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                        )
                    }
                    .animation(.easeInOut(duration: 0.2), value: selectedMood)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Effort Level Picker
struct EffortLevelPicker: View {
    @Binding var effortLevel: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Energy Level")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(effortLevelDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            effortLevel = level
                        }
                    } label: {
                        Circle()
                            .fill(level <= effortLevel ? effortLevelColor : Color(.systemGray5))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("\(level)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(level <= effortLevel ? .white : .secondary)
                            )
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var effortLevelDescription: String {
        switch effortLevel {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "High"
        case 5: return "Very High"
        default: return ""
        }
    }
    
    private var effortLevelColor: Color {
        switch effortLevel {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .gray
        }
    }
}

// MARK: - Check-In History
struct CheckInHistory: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: TimePeriod = .thisWeek
    
    enum TimePeriod: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Period selector
                periodSelector
                
                // Check-ins list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCheckIns) { checkIn in
                            CheckInCard(checkIn: checkIn)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Check-in History")
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
    
    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Button {
                        selectedPeriod = period
                    } label: {
                        Text(period.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedPeriod == period ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedPeriod == period ? Color.blue : Color(.systemGray6))
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    private var filteredCheckIns: [AICheckIn] {
        let allCheckIns = dataManager.recentCheckIns
        
        switch selectedPeriod {
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return allCheckIns.filter { $0.date >= weekAgo }
        case .thisMonth:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return allCheckIns.filter { $0.date >= monthAgo }
        case .lastMonth:
            let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return allCheckIns.filter { $0.date >= twoMonthsAgo && $0.date < monthAgo }
        case .allTime:
            return allCheckIns
        }
    }
}

// MARK: - AI Response Card
struct AIResponseCard: View {
    let response: String
    let followUpQuestion: String
    @EnvironmentObject var dataManager: EnhancedDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                
                Text("AI Response")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(response)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                
                if !followUpQuestion.isEmpty {
                    Divider()
                    
                    Text(followUpQuestion)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                        .italic()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Check-In Card
struct CheckInCard: View {
    let checkIn: AICheckIn
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(checkIn.timeOfDay.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if let mood = checkIn.mood {
                            Text(mood.emoji)
                                .font(.subheadline)
                        }
                        
                        if let effort = checkIn.effortLevel {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { level in
                                    Circle()
                                        .fill(level <= effort ? Color.green : Color(.systemGray5))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    }
                    
                    Text(formatDate(checkIn.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // User response
            if let userResponse = checkIn.userResponse {
                Text(isExpanded ? userResponse : String(userResponse.prefix(100)) + (userResponse.count > 100 ? "..." : ""))
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(isExpanded ? nil : 3)
            }
            
            // AI response
            if isExpanded, let aiResponse = checkIn.aiResponse {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("AI Response")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Text(aiResponse)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.timeStyle = .short
            return "Yesterday at \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Check-In Summary Card
struct CheckInSummaryCard: View {
    let checkIn: AICheckIn
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 4) {
                Image(systemName: checkIn.timeOfDay.icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(checkIn.timeOfDay.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Content preview
            VStack(alignment: .leading, spacing: 4) {
                if let userResponse = checkIn.userResponse {
                    Text(String(userResponse.prefix(60)) + (userResponse.count > 60 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let mood = checkIn.mood {
                        Text(mood.emoji)
                            .font(.caption2)
                    }
                    
                    Text(formatTime(checkIn.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Enhanced Check-In Generator
struct CheckInGenerator {
    
    // MARK: - Public Interface
    static func generatePrompt(for path: TrainingPath, timeOfDay: AICheckIn.CheckInTime) -> String {
        let prompts = getPrompts(for: path, timeOfDay: timeOfDay)
        return prompts.randomElement() ?? getDefaultPrompt(for: timeOfDay)
    }
    
    static func generateAIResponse(
        to userResponse: String,
        for path: TrainingPath,
        timeOfDay: AICheckIn.CheckInTime,
        mood: AICheckIn.MoodRating?,
        recentCheckIns: [AICheckIn] = []
    ) async -> String {
        // In production, this would call your AI service
        // For now, we generate contextual responses based on path, mood, and patterns
        return generateContextualResponse(
            userResponse: userResponse,
            path: path,
            timeOfDay: timeOfDay,
            mood: mood,
            recentCheckIns: recentCheckIns
        )
    }
    
    static func generateFollowUpQuestion(for path: TrainingPath, basedOn response: String) -> String {
        let questions = getFollowUpQuestions(for: path)
        return questions.randomElement() ?? "What's one thing you could do differently tomorrow?"
    }
    
    // MARK: - Prompts by Path and Time
    private static func getPrompts(for path: TrainingPath, timeOfDay: AICheckIn.CheckInTime) -> [String] {
        switch (path, timeOfDay) {
        case (.discipline, .morning):
            return [
                "What's the one hard thing you're going to do today that you don't want to do?",
                "If you could only accomplish one thing today, what would move you forward the most?",
                "What temptation will you likely face today, and how will you handle it?",
                "What does winning the first hour of your day look like?",
                "What's one small act of discipline you can commit to before noon?"
            ]
            
        case (.discipline, .afternoon):
            return [
                "How have you shown discipline so far today?",
                "What challenge are you facing right now that requires willpower?",
                "Where can you push through resistance this afternoon?",
                "What habit are you building that you can practice right now?",
                "How can you finish today strong?"
            ]
            
        case (.discipline, .evening):
            return [
                "Where did you show discipline today, and where did you struggle?",
                "What disciplined choice are you most proud of today?",
                "How did today's actions align with your long-term goals?",
                "What pattern are you noticing in your willpower throughout the day?",
                "How will you set yourself up for disciplined success tomorrow?"
            ]
            
        case (.clarity, .morning):
            return [
                "What's taking up mental space that you need to release today?",
                "What are you avoiding thinking about that needs your attention?",
                "If you could only focus on three things today, what would they be?",
                "What emotion are you carrying from yesterday that you can let go of?",
                "What story are you telling yourself that might not be true?"
            ]
            
        case (.clarity, .afternoon):
            return [
                "How clear is your thinking right now, and what's influencing it?",
                "What assumptions have you made today that you could question?",
                "Where do you need more mental clarity in this moment?",
                "What's one thought pattern you've noticed today?",
                "How can you create more mental space for the rest of your day?"
            ]
            
        case (.clarity, .evening):
            return [
                "What moments of clarity did you experience today?",
                "How did your emotions guide or mislead you today?",
                "What assumption you held was challenged today?",
                "When did you listen to your intuition, and what happened?",
                "What would you like to understand better about today's events?"
            ]
            
        case (.confidence, .morning):
            return [
                "What social risk are you willing to take today?",
                "How will you use your voice to make a difference today?",
                "What's one way you can step outside your comfort zone today?",
                "Where might you need to advocate for yourself today?",
                "What would you do today if you knew you couldn't fail?"
            ]
            
        case (.confidence, .afternoon):
            return [
                "How have you shown confidence so far today?",
                "What opportunity to speak up or lead have you noticed?",
                "Where can you be more assertive in this moment?",
                "What feedback or reaction surprised you today?",
                "How can you finish the day with more confidence?"
            ]
            
        case (.confidence, .evening):
            return [
                "When did you speak up or take action despite feeling nervous?",
                "What social risk did you take today?",
                "How did you handle a moment when confidence was required?",
                "When did you advocate for yourself today?",
                "What evidence do you have that you're becoming more confident?"
            ]
            
        case (.purpose, .morning):
            return [
                "How will you serve something bigger than yourself today?",
                "What actions can you take that align with your deepest values?",
                "How can you use your unique gifts today?",
                "What legacy-building action will you take today?",
                "What would make today feel meaningful and purposeful?"
            ]
            
        case (.purpose, .afternoon):
            return [
                "How connected do you feel to your purpose right now?",
                "What impact have you made on others so far today?",
                "How does your current work connect to your bigger vision?",
                "What's pulling at your heart that you might explore further?",
                "How can you invest in what matters most this afternoon?"
            ]
            
        case (.purpose, .evening):
            return [
                "How did you serve something bigger than yourself today?",
                "What actions felt most aligned with your values?",
                "When did you feel most connected to your deeper purpose?",
                "How did you use your unique gifts today?",
                "What would your future self thank you for doing today?"
            ]
            
        case (.authenticity, .morning):
            return [
                "How will you show up as your most authentic self today?",
                "Where might you need to choose truth over people-pleasing today?",
                "What part of yourself do you want to express more freely today?",
                "How can you honor your real feelings instead of hiding them?",
                "What boundary might you need to set to stay true to yourself?"
            ]
            
        case (.authenticity, .afternoon):
            return [
                "How authentically have you been showing up today?",
                "Where have you chosen truth over performance so far?",
                "What part of yourself have you been hiding that wants to be expressed?",
                "How can you be more vulnerable and genuine this afternoon?",
                "What would it look like to drop the mask right now?"
            ]
            
        case (.authenticity, .evening):
            return [
                "When did you show up as your most authentic self today?",
                "Where did you choose truth over people-pleasing?",
                "What part of yourself did you express that felt genuine?",
                "When did you honor your real feelings instead of hiding them?",
                "How did being authentic change an interaction today?"
            ]
        }
    }
    
    // MARK: - AI Response Generation
    private static func generateContextualResponse(
        userResponse: String,
        path: TrainingPath,
        timeOfDay: AICheckIn.CheckInTime,
        mood: AICheckIn.MoodRating?,
        recentCheckIns: [AICheckIn]
    ) -> String {
        
        // Analyze user patterns from recent check-ins
        let responseContext = analyzeUserContext(userResponse, recentCheckIns: recentCheckIns)
        
        // Get base responses for this path and time
        let baseResponses = getAIResponses(for: path, timeOfDay: timeOfDay, mood: mood)
        let selectedResponse = baseResponses.randomElement() ?? getDefaultAIResponse(for: path, timeOfDay: timeOfDay)
        
        // Personalize based on mood and context
        return personalizeResponse(selectedResponse, basedOn: userResponse, mood: mood, context: responseContext)
    }
    
    private static func getAIResponses(for path: TrainingPath, timeOfDay: AICheckIn.CheckInTime, mood: AICheckIn.MoodRating?) -> [String] {
        switch (path, timeOfDay) {
        case (.discipline, .morning):
            return [
                "That's a solid commitment. Remember, discipline isn't about perfection—it's about showing up consistently, especially when you don't feel like it.",
                "I hear your intention. The gap between wanting to do something and actually doing it is where discipline is built. Start small if you need to.",
                "Good awareness. The hardest part is often just beginning. Focus on taking the first step, and momentum will follow.",
                "Strong mindset. Remember that every small act of discipline compounds over time. You're building something bigger than today."
            ]
            
        case (.discipline, .evening):
            return [
                "Reflect on what worked and what didn't. Every day is data for building better systems and stronger habits.",
                "Acknowledge your wins, even small ones. Discipline is built through celebrating progress, not just pushing harder.",
                "Consider how today's choices align with who you're becoming. Each disciplined action is a vote for your future self.",
                "Notice the patterns. Where was discipline easy? Where was it hard? Use this insight to prepare for tomorrow."
            ]
            
        case (.clarity, .morning):
            return [
                "Starting with awareness is powerful. Mental clarity often comes from first acknowledging what's clouded.",
                "Those questions you're asking are the beginning of clarity. Sometimes the answer isn't as important as asking the right question.",
                "I appreciate that mindful approach. Clarity comes not from thinking more, but from thinking better.",
                "Good focus on what matters. When we try to think about everything, we end up clear about nothing."
            ]
            
        case (.clarity, .evening):
            return [
                "That kind of reflection creates real insight. The patterns you notice today become the wisdom you use tomorrow.",
                "I hear you processing the day thoughtfully. That emotional awareness is the foundation of mental clarity.",
                "Good for noticing those thought patterns. Awareness is always the first step toward change.",
                "That introspection serves you well. The more you understand your inner world, the clearer your outer decisions become."
            ]
            
        case (.confidence, .morning):
            return [
                "I love that bold intention. Confidence is built by doing things that scare us, one small act at a time.",
                "That willingness to be uncomfortable is how confidence grows. Every time you do it scared, you get a little braver.",
                "Good for you for planning to take that risk. Confidence isn't about feeling ready—it's about acting before you feel ready.",
                "I appreciate that courage. Remember, confidence comes from keeping promises to yourself about who you want to become."
            ]
            
        case (.confidence, .evening):
            return [
                "That took real courage. How did it feel to push through that discomfort and do it anyway?",
                "I'm proud of you for showing up that way. Every time you act despite fear, you prove to yourself that you can handle more than you think.",
                "That kind of authentic expression builds lasting confidence. How did others respond to the real you?",
                "Good for you for using your voice. Confidence isn't about being perfect—it's about being willing to be imperfect in front of others."
            ]
            
        case (.purpose, .morning):
            return [
                "That sense of purpose will guide your decisions today. When you're clear on your 'why,' the 'how' becomes easier.",
                "I love that focus on service. Purpose often emerges at the intersection of your gifts and the world's needs.",
                "That values-driven approach is powerful. When your actions align with your deepest beliefs, you feel unstoppable.",
                "Good for connecting to something bigger. Purpose isn't just about what you do—it's about why it matters."
            ]
            
        case (.purpose, .evening):
            return [
                "That alignment you felt today is precious. Hold onto those moments when your work feels deeply meaningful.",
                "I can hear how connected you felt to your purpose. Those experiences are guideposts for the direction you want to go.",
                "That impact you made matters more than you know. Sometimes we plant seeds without seeing how they grow.",
                "Good for you for living your values today. That integrity between belief and action is what purpose feels like."
            ]
            
        case (.authenticity, .morning):
            return [
                "I hear you wanting to show up more genuinely. Remember that authenticity is a practice, not a perfection.",
                "That's a vulnerable intention. How might you honor your true feelings while still navigating social expectations?",
                "Strong commitment to being real. What's one way you could express your authentic self today?",
                "I appreciate that courage to be yourself. Authenticity requires the bravery to disappoint others in service of your truth."
            ]
            
        case (.authenticity, .evening):
            return [
                "How did it feel to show up authentically? Often the fear of being ourselves is worse than the actual experience.",
                "That kind of genuine expression builds trust with yourself. What did you learn about who you really are?",
                "Good for you for choosing truth over performance. How did others respond to your authenticity?",
                "I appreciate that vulnerability. What would it look like to bring even more of your real self forward tomorrow?"
            ]
            
        default:
            return [
                "I appreciate you sharing that with me. Your self-awareness is growing stronger each day.",
                "That kind of reflection is powerful. Keep paying attention to these patterns and insights.",
                "Thank you for being so thoughtful about your growth. Every check-in is a step forward."
            ]
        }
    }
    
    private static func analyzeUserContext(_ response: String, recentCheckIns: [AICheckIn]) -> ResponseContext {
        // Analyze sentiment and themes from recent responses
        let positiveWords = ["good", "great", "accomplished", "proud", "successful", "happy", "excited"]
        let challengeWords = ["hard", "difficult", "struggle", "tired", "stressed", "overwhelmed"]
        
        let responseWords = response.lowercased().components(separatedBy: .punctuationCharacters)
            .joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let positiveCount = responseWords.filter { word in positiveWords.contains(word) }.count
        let challengeCount = responseWords.filter { word in challengeWords.contains(word) }.count
        
        let sentiment: ResponseContext.Sentiment
        if positiveCount > challengeCount {
            sentiment = .positive
        } else if challengeCount > positiveCount {
            sentiment = .challenging
        } else {
            sentiment = .neutral
        }
        
        return ResponseContext(sentiment: sentiment, wordCount: responseWords.count)
    }
    
    private static func personalizeResponse(
        _ baseResponse: String,
        basedOn userResponse: String,
        mood: AICheckIn.MoodRating?,
        context: ResponseContext
    ) -> String {
        
        var personalizedResponse = baseResponse
        
        // Add mood-based personalization
        if let mood = mood {
            let moodPrefix = getMoodBasedPrefix(mood, sentiment: context.sentiment)
            if let prefix = moodPrefix {
                personalizedResponse = prefix + " " + baseResponse
            }
        }
        
        // Add length-based personalization
        if context.wordCount < 10 {
            personalizedResponse += " I'd love to hear more about what's on your mind."
        } else if context.wordCount > 50 {
            personalizedResponse += " I appreciate you taking the time to share so thoughtfully."
        }
        
        return personalizedResponse
    }
    
    private static func getMoodBasedPrefix(_ mood: AICheckIn.MoodRating, sentiment: ResponseContext.Sentiment) -> String? {
        switch (mood, sentiment) {
        case (.excellent, .positive):
            return "I love that energy!"
        case (.excellent, _):
            return "That positivity comes through even with the challenges."
        case (.great, .positive):
            return "That positivity is contagious."
        case (.great, _):
            return "I can feel your resilience."
        case (.good, _):
            return "I can sense your steady determination."
        case (.neutral, .challenging):
            return "I hear the weight you're carrying."
        case (.neutral, _):
            return "I appreciate your honest reflection."
        case (.low, _):
            return "Thank you for sharing what's really going on."
        default:
            return nil
        }
    }
    
    private static func getFollowUpQuestions(for path: TrainingPath) -> [String] {
        switch path {
        case .discipline:
            return [
                "What's one small thing you could do right now to build momentum?",
                "What would help you stay consistent with this tomorrow?",
                "What obstacles might you face, and how will you handle them?",
                "What's the smallest version of this you could commit to?",
                "How will you reward yourself for following through?"
            ]
        case .clarity:
            return [
                "What would it look like to sit with this uncertainty a bit longer?",
                "What assumptions might you be making that need questioning?",
                "How could you create more mental space for this?",
                "What would help you see this situation more clearly?",
                "What's the most important question you need to answer for yourself?"
            ]
        case .confidence:
            return [
                "What's the smallest way you could practice this courage tomorrow?",
                "How might you prepare yourself for the next opportunity like this?",
                "What evidence do you have that you're capable of more than you think?",
                "Who could support you in building this confidence?",
                "How would your future confident self handle this situation?"
            ]
        case .purpose:
            return [
                "How could you align your daily actions more closely with this purpose?",
                "What's one way you could serve others through this?",
                "How does this connect to your larger vision for your life?",
                "What would it look like to trust this calling more deeply?",
                "How could you use your unique gifts in service of this purpose?"
            ]
        case .authenticity:
            return [
                "What would it look like to express this part of yourself more fully?",
                "How could you honor these feelings while still being considerate of others?",
                "What boundaries might you need to set to protect your authenticity?",
                "How could you practice being more vulnerable in safe relationships?",
                "What would change if you trusted others to accept the real you?"
            ]
        }
    }
    
    private static func getDefaultPrompt(for timeOfDay: AICheckIn.CheckInTime) -> String {
        switch timeOfDay {
        case .morning:
            return "How are you feeling as you start your day, and what's your intention for today?"
        case .afternoon:
            return "How has your day been going so far, and what are you noticing about your energy and mood?"
        case .evening:
            return "As you reflect on your day, what stands out to you most about how you showed up today?"
        }
    }
    
    private static func getDefaultAIResponse(for path: TrainingPath, timeOfDay: AICheckIn.CheckInTime) -> String {
        let pathName = path.displayName.lowercased()
        let timeContext = timeOfDay == .morning ? "starting your day" : timeOfDay == .afternoon ? "in the middle of your day" : "reflecting on your day"
        
        return "Thank you for sharing your thoughts about \(pathName) while \(timeContext). Your self-awareness and commitment to growth are inspiring."
    }
}

// MARK: - Supporting Models for CheckInGenerator

struct ResponseContext {
    let sentiment: Sentiment
    let wordCount: Int
    
    enum Sentiment {
        case positive, neutral, challenging
    }
}

// MARK: - Extensions for AICheckIn.CheckInTime

extension AICheckIn.CheckInTime {
    var icon: String {
        switch self {
        case .morning: return "sunrise"
        case .afternoon: return "sun.max"
        case .evening: return "sunset"
        }
    }
    
    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon" 
        case .evening: return "Evening"
        }
    }
}

// MARK: - Extensions for AICheckIn.MoodRating

extension AICheckIn.MoodRating {
    var score: Int {
        switch self {
        case .low: return 1
        case .neutral: return 3
        case .good: return 4
        case .great: return 5
        case .excellent: return 6
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .red
        case .neutral: return .gray
        case .good: return .yellow
        case .great: return .mint
        case .excellent: return .green
        }
    }
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .great: return "Great"
        case .excellent: return "Excellent"
        }
    }
    
    var emoji: String {
        switch self {
        case .low: return "😔"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .great: return "😊"
        case .excellent: return "🎉"
        }
    }
}
