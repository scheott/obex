import SwiftUI

// MARK: - OnboardingView (Main onboarding flow)
struct OnboardingView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var currentStep = 0
    @State private var selectedPath: TrainingPath?
    @State private var showingPathDetail = false
    @State private var isCreatingProfile = false
    
    private let totalSteps = 3
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.gray.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        if step < totalSteps - 1 {
                            Rectangle()
                                .fill(step < currentStep ? Color.white : Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 60)
                .padding(.top, 20)
                
                Spacer()
                
                // Content based on current step
                Group {
                    switch currentStep {
                    case 0:
                        WelcomeStep()
                    case 1:
                        PathSelectionStep(selectedPath: $selectedPath, showingDetail: $showingPathDetail)
                    case 2:
                        FinalStep(selectedPath: selectedPath)
                    default:
                        EmptyView()
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                VStack(spacing: 16) {
                    if currentStep < totalSteps - 1 {
                        Button(action: nextStep) {
                            HStack {
                                Text(currentStep == 0 ? "Get Started" : "Continue")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                        }
                        .disabled(currentStep == 1 && selectedPath == nil)
                        .opacity(currentStep == 1 && selectedPath == nil ? 0.6 : 1.0)
                    } else {
                        Button(action: createProfile) {
                            HStack {
                                if isCreatingProfile {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                    Text("Setting up...")
                                } else {
                                    Text("Start Your Journey")
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                        }
                        .disabled(isCreatingProfile || selectedPath == nil)
                    }
                    
                    if currentStep > 0 && currentStep < totalSteps - 1 {
                        Button("Back") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep -= 1
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingPathDetail) {
            if let path = selectedPath {
                PathDetailSheet(path: path, isPresented: $showingPathDetail)
            }
        }
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }
    
    private func createProfile() {
        guard let selectedPath = selectedPath else { return }
        
        isCreatingProfile = true
        
        // Simulate API call or setup time
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dataManager.createUserProfile(selectedPath: selectedPath)
            isCreatingProfile = false
        }
    }
}

// MARK: - WelcomeStep (Welcome screen)
struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 32) {
            // Hero Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            // Welcome Content
            VStack(spacing: 16) {
                Text("Your AI Mentor")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Daily discipline, clarity, and purpose through personalized AI coaching")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Features List
            VStack(spacing: 16) {
                FeatureRow(icon: "target", text: "Daily personalized challenges")
                FeatureRow(icon: "message.fill", text: "AI-powered check-ins")
                FeatureRow(icon: "book.fill", text: "Curated wisdom & insights")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your growth journey")
                FeatureRow(icon: "crown.fill", text: "Build unbreakable streaks")
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - FeatureRow (App feature highlights)
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - PathSelectionStep (Training path picker)
struct PathSelectionStep: View {
    @Binding var selectedPath: TrainingPath?
    @Binding var showingDetail: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("Choose Your Focus")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select the area where you want to grow most")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Path Cards Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(TrainingPath.allCases, id: \.self) { path in
                    PathCard(
                        path: path,
                        isSelected: selectedPath == path,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPath = path
                            }
                        },
                        onInfoTap: {
                            selectedPath = path
                            showingDetail = true
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            
            // Selected Path Info
            if let selectedPath = selectedPath {
                VStack(spacing: 8) {
                    Text("Perfect! You'll focus on building **\(selectedPath.displayName.lowercased())**")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("Tap any path for more details")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - PathCard (Individual path option)
struct PathCard: View {
    let path: TrainingPath
    let isSelected: Bool
    let onTap: () -> Void
    let onInfoTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(path.color.opacity(isSelected ? 1.0 : 0.3))
                    .frame(width: 50, height: 50)
                
                Image(systemName: path.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : path.color)
            }
            
            // Title
            Text(path.displayName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Description
            Text(path.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            // Info Button
            Button(action: onInfoTap) {
                Text("Learn More")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(path.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(path.color.opacity(0.2))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isSelected ? 0.15 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(path.color.opacity(isSelected ? 0.8 : 0.3), lineWidth: isSelected ? 2 : 1)
                )
        )
        .onTapGesture(perform: onTap)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - PathDetailSheet (Path information modal)
struct PathDetailSheet: View {
    let path: TrainingPath
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                path.color.opacity(0.1)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(path.color.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: path.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(path.color)
                            }
                            
                            Text(path.displayName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text(path.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Focus Areas
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Focus Areas")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(path.focusAreas, id: \.self) { area in
                                    Text(area)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(path.color.opacity(0.15))
                                        )
                                        .foregroundColor(path.color)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Example Challenges
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Example Challenges")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 8) {
                                ForEach(getExampleChallenges(for: path), id: \.self) { challenge in
                                    ExampleRow(text: challenge)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    isPresented = false
                }
            )
        }
    }
    
    private func getExampleChallenges(for path: TrainingPath) -> [String] {
        switch path {
        case .discipline:
            return [
                "Complete one task before checking your phone",
                "Take a 2-minute cold shower",
                "Do 10 pushups when you feel like procrastinating"
            ]
        case .clarity:
            return [
                "Write down 3 thoughts you'd like to delete",
                "Spend 5 minutes in meditation",
                "Identify one assumption you're making today"
            ]
        case .confidence:
            return [
                "Start a conversation with a stranger",
                "Share your opinion in a group setting",
                "Take up space - sit with good posture for 1 hour"
            ]
        case .purpose:
            return [
                "Review your 5-year vision for 3 minutes",
                "Identify one value that guided your decisions today",
                "Write down what legacy you want to leave"
            ]
        case .authenticity:
            return [
                "Say no to something that doesn't align with your values",
                "Express a genuine emotion instead of hiding it",
                "Do something that feels true to you, even if it's uncomfortable"
            ]
        }
    }
}

// MARK: - ExampleRow (Challenge examples)
struct ExampleRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.primary.opacity(0.6))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary.opacity(0.8))
            
            Spacer()
        }
    }
}

// MARK: - FinalStep (Final setup screen)
struct FinalStep: View {
    let selectedPath: TrainingPath?
    
    var body: some View {
        VStack(spacing: 32) {
            if let path = selectedPath {
                // Success Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(path.color.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: path.icon)
                            .font(.system(size: 40))
                            .foregroundColor(path.color)
                    }
                    
                    Text("Perfect Choice!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("You've chosen to focus on **\(path.displayName.lowercased())**")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                // Next Steps
                VStack(spacing: 20) {
                    Text("Here's what happens next:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 16) {
                        NextStepRow(number: "1", text: "Get your first daily challenge")
                        NextStepRow(number: "2", text: "Start morning & evening check-ins")
                        NextStepRow(number: "3", text: "Build your streak and track progress")
                        NextStepRow(number: "4", text: "Unlock personalized insights")
                    }
                }
                
                // Benefits Preview
                VStack(spacing: 12) {
                    Text("Free features include:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 20) {
                        BenefitItem(icon: "target", text: "3 challenges/week")
                        BenefitItem(icon: "message", text: "AI check-ins")
                        BenefitItem(icon: "book", text: "Book insights")
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - NextStepRow (Setup steps display)
struct NextStepRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(number)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                )
            
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - BenefitItem (Feature highlights)
struct BenefitItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(DataManager())
    }
}
