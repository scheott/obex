import SwiftUI

// MARK: - Check-In View
struct CheckInView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTimeOfDay: AICheckIn.CheckInTime = .morning
    @State private var currentPrompt: String = ""
    @State private var userResponse: String = ""
    @State private var selectedMood: AICheckIn.MoodRating?
    @State private var effortLevel: Int = 3
    @State private var showingAIResponse = false
    @State private var aiResponse: String = ""
    @State private var isSubmitting = false
    @State private var hasSubmittedToday = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time of Day Selector
                    timeOfDaySelector
                    
                    // Current Prompt Section
                    promptSection
                    
                    // User Response Section
                    responseSection
                    
                    // Mood & Effort Section
                    moodAndEffortSection
                    
                    // Submit Button
                    submitButton
                    
                    // AI Response Section
                    if showingAIResponse {
                        aiResponseSection
                    }
                    
                    // Previous Check-ins
                    previousCheckInsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupInitialState()
            }
            .onChange(of: selectedTimeOfDay) { _ in
                updatePrompt()
            }
        }
    }
    
    // MARK: - Time of Day Selector
    private var timeOfDaySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Check-in Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 0) {
                ForEach([AICheckIn.CheckInTime.morning, .evening], id: \.self) { timeOfDay in
                    Button {
                        selectedTimeOfDay = timeOfDay
                        isTextFieldFocused = false
                    } label: {
                        HStack {
                            Image(systemName: timeOfDay == .morning ? "sun.max.fill" : "moon.fill")
                                .font(.title3)
                            
                            Text(timeOfDay.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTimeOfDay == timeOfDay ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Rectangle()
                                .fill(selectedTimeOfDay == timeOfDay ? 
                                      (dataManager.userProfile?.selectedPath.color ?? .blue) : 
                                      Color(.systemGray5))
                        )
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Prompt Section
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Question")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    updatePrompt()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text(currentPrompt.isEmpty ? "Loading question..." : currentPrompt)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                if let path = dataManager.userProfile?.selectedPath {
                    HStack {
                        Image(systemName: path.icon)
                            .font(.caption)
                            .foregroundColor(path.color)
                        
                        Text("Focused on \(path.displayName)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(path.color)
                        
                        Spacer()
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
    
    // MARK: - Response Section
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Response")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Text Input
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(minHeight: 120)
                    
                    if userResponse.isEmpty {
                        Text("Share your thoughts, feelings, or experiences...")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }
                    
                    TextEditor(text: $userResponse)
                        .focused($isTextFieldFocused)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isTextFieldFocused ? 
                                (dataManager.userProfile?.selectedPath.color ?? .blue) : 
                                Color.clear, lineWidth: 2)
                )
                
                // Quick Response Options
                if userResponse.isEmpty {
                    quickResponseOptions
                }
                
                // Character Count
                HStack {
                    Spacer()
                    Text("\(userResponse.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Quick Response Options
    private var quickResponseOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Responses")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(getQuickResponses(), id: \.self) { response in
                    Button {
                        userResponse = response
                    } label: {
                        Text(response)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill((dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.1))
                            )
                            .lineLimit(2)
                    }
                }
            }
        }
    }
    
    // MARK: - Mood and Effort Section
    private var moodAndEffortSection: some View {
        VStack(spacing: 20) {
            // Mood Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("How are you feeling?")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    ForEach(AICheckIn.MoodRating.allCases, id: \.self) { mood in
                        Button {
                            selectedMood = mood
                        } label: {
                            VStack(spacing: 6) {
                                Text(mood.emoji)
                                    .font(.title2)
                                
                                Text(mood.rawValue.capitalized)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedMood == mood ? 
                                          (dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.2) : 
                                          Color(.systemGray6))
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
            }
            
            // Effort Level
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Energy/Effort Level")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(effortLevel)/5")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            effortLevel = level
                        } label: {
                            Circle()
                                .fill(level <= effortLevel ? 
                                      (dataManager.userProfile?.selectedPath.color ?? .blue) : 
                                      Color(.systemGray5))
                                .frame(width: 24, height: 24)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(effortLevelDescription)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(effortLevelSubtext)
                            .font(.caption2)
                            .foregroundColor(.secondary)
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
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            submitCheckIn()
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.subheadline)
                }
                
                Text(isSubmitting ? "Submitting..." : "Submit Check-in")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canSubmit ? 
                          (dataManager.userProfile?.selectedPath.color ?? .blue) : 
                          Color(.systemGray4))
            )
        }
        .disabled(!canSubmit || isSubmitting)
    }
    
    // MARK: - AI Response Section
    private var aiResponseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                
                Text("AI Response")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(aiResponse)
                    .font(.body)
                    .foregroundColor(.primary)
                
                // Follow-up question
                if !aiResponse.isEmpty {
                    Divider()
                    
                    Text(CheckInGenerator.generateFollowUpQuestion(for: dataManager.userProfile?.selectedPath ?? .discipline, basedon: userResponse))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                        .italic()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - Previous Check-ins Section
    private var previousCheckInsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Check-ins")
                .font(.headline)
                .fontWeight(.semibold)
            
            if dataManager.todaysCheckIns.isEmpty {
                Text("No check-ins yet today. Start your first one above!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                    )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(dataManager.todaysCheckIns.reversed()) { checkIn in
                        CheckInCard(checkIn: checkIn)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var canSubmit: Bool {
        !userResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedMood != nil
    }
    
    private var effortLevelDescription: String {
        switch effortLevel {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "High"
        case 5: return "Very High"
        default: return "Moderate"
        }
    }
    
    private var effortLevelSubtext: String {
        switch effortLevel {
        case 1: return "Struggling today"
        case 2: return "Taking it easy"
        case 3: return "Steady pace"
        case 4: return "Pushing forward"
        case 5: return "Full intensity"
        default: return "Steady pace"
        }
    }
    
    // MARK: - Helper Methods
    private func setupInitialState() {
        let hour = Calendar.current.component(.hour, from: Date())
        selectedTimeOfDay = hour < 15 ? .morning : .evening
        updatePrompt()
        checkIfSubmittedToday()
    }
    
    private func updatePrompt() {
        guard let path = dataManager.userProfile?.selectedPath else { return }
        
        currentPrompt = selectedTimeOfDay == .morning ? 
            CheckInGenerator.generateMorningPrompt(for: path) :
            CheckInGenerator.generateEveningPrompt(for: path)
    }
    
    private func getQuickResponses() -> [String] {
        guard let path = dataManager.userProfile?.selectedPath else { return [] }
        
        let morningResponses = [
            "I'm feeling motivated and ready to tackle the day",
            "I'm a bit anxious but committed to showing up",
            "I'm grateful for the opportunity to grow today",
            "I'm excited about the challenge ahead"
        ]
        
        let eveningResponses = [
            "I pushed through some resistance today",
            "I learned something important about myself",
            "I'm proud of how I handled a difficult situation",
            "I could have done better, but I showed up"
        ]
        
        return selectedTimeOfDay == .morning ? morningResponses : eveningResponses
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let response = CheckInGenerator.generateAIResponse(
                to: userResponse,
                for: path,
                timeOfDay: selectedTimeOfDay,
                mood: mood
            )
            
            checkIn.aiResponse = response
            aiResponse = response
            
            // Submit to data manager
            dataManager.submitCheckIn(checkIn)
            
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
    
    private func checkIfSubmittedToday() {
        let today = Calendar.current.startOfDay(for: Date())
        hasSubmittedToday = dataManager.todaysCheckIns.contains { checkIn in
            Calendar.current.isDate(checkIn.date, inSameDayAs: today) &&
            checkIn.timeOfDay == selectedTimeOfDay
        }
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
                                        .fill(level <= effort ? Color.blue : Color(.systemGray5))
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
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // User Response Preview
            if let response = checkIn.userResponse {
                Text(response)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(isExpanded ? nil : 2)
            }
            
            // AI Response (when expanded)
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
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
