import SwiftUI

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
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
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
                                } else {
                                    Text("Start My Journey")
                                        .font(.headline)
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .disabled(isCreatingProfile || selectedPath == nil)
                    }
                    
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep -= 1
                            }
                        }
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

// MARK: - Welcome Step
struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.white)
            
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
            
            VStack(spacing: 12) {
                FeatureRow(icon: "target", text: "Daily personalized challenges")
                FeatureRow(icon: "message.fill", text: "AI-powered check-ins")
                FeatureRow(icon: "book.fill", text: "Curated wisdom & insights")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your growth journey")
            }
            .padding(.top, 20)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Path Selection Step
struct PathSelectionStep: View {
    @Binding var selectedPath: TrainingPath?
    @Binding var showingDetail: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Choose Your Focus")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select the area where you want to build strength. You can change this anytime.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(TrainingPath.allCases) { path in
                    PathCard(
                        path: path,
                        isSelected: selectedPath == path,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPath = path
                            }
                        },
                        infoAction: {
                            selectedPath = path
                            showingDetail = true
                        }
                    )
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

struct PathCard: View {
    let path: TrainingPath
    let isSelected: Bool
    let action: () -> Void
    let infoAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon and info button
            HStack {
                Image(systemName: path.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : path.color)
                
                Spacer()
                
                Button(action: infoAction) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(isSelected ? .black.opacity(0.6) : .white.opacity(0.6))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(path.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .black : .white)
                
                Text(path.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .black.opacity(0.7) : .white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : path.color.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture(perform: action)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Final Step
struct FinalStep: View {
    let selectedPath: TrainingPath?
    
    var body: some View {
        VStack(spacing: 32) {
            if let path = selectedPath {
                VStack(spacing: 16) {
                    Image(systemName: path.icon)
                        .font(.system(size: 60))
                        .foregroundColor(path.color)
                    
                    Text("Perfect Choice!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("You've chosen to focus on \(path.displayName.lowercased())")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack(spacing: 16) {
                    Text("Here's what happens next:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        NextStepRow(number: "1", text: "Get your first daily challenge")
                        NextStepRow(number: "2", text: "Start morning & evening check-ins")
                        NextStepRow(number: "3", text: "Build your streak and track progress")
                        NextStepRow(number: "4", text: "Unlock personalized insights")
                    }
                }
            }
        }
    }
}

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

// MARK: - Path Detail Sheet
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
                            Image(systemName: path.icon)
                                .font(.system(size: 60))
                                .foregroundColor(path.color)
                            
                            Text(path.displayName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text(path.description)
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Example content
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What You'll Work On:")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ExampleRow(text: getExampleChallenges(for: path)[0])
                                ExampleRow(text: getExampleChallenges(for: path)[1])
                                ExampleRow(text: getExampleChallenges(for: path)[2])
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Path Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
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

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(DataManager())
    }
}