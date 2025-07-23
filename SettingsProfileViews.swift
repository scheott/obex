import SwiftUI
import Foundation

// MARK: - Settings Main View
struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var notificationsEnabled = true
    @State private var morningCheckInTime = Date()
    @State private var eveningCheckInTime = Date()
    @State private var showingPathChange = false
    @State private var showingDeleteAccount = false
    @State private var showingAppPreferences = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Training Path Section
                    SettingsSection(title: "Training Path") {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current Focus")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    if let path = dataManager.userProfile?.selectedPath {
                                        HStack(spacing: 8) {
                                            Image(systemName: path.icon)
                                                .foregroundColor(path.color)
                                            Text(path.displayName)
                                                .font(.body)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Button("Change") {
                                    showingPathChange = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Notifications Section
                    SettingsSection(title: "Notifications") {
                        VStack(spacing: 12) {
                            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            if notificationsEnabled {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Morning Check-in")
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        DatePicker("", selection: $morningCheckInTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    
                                    HStack {
                                        Text("Evening Check-in")
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        DatePicker("", selection: $eveningCheckInTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // App Preferences Section
                    SettingsSection(title: "App Preferences") {
                        VStack(spacing: 12) {
                            SettingsRow(
                                icon: "slider.horizontal.3",
                                title: "App Preferences",
                                subtitle: "Customize your app experience",
                                action: { showingAppPreferences = true }
                            )
                        }
                    }
                    
                    // Subscription Section
                    SettingsSection(title: "Subscription") {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current Plan")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(authManager.currentUser?.subscription.displayName ?? "Free")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if authManager.currentUser?.subscription == .free {
                                    Button("Upgrade") {
                                        // Handle upgrade - will be in PaywallViews.swift
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                } else {
                                    Button("Manage") {
                                        // Handle subscription management
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Privacy & Security Section
                    SettingsSection(title: "Privacy & Security") {
                        VStack(spacing: 12) {
                            SettingsRow(
                                icon: "lock",
                                title: "Change Password",
                                subtitle: "Update your account password",
                                action: { /* Handle password change */ }
                            )
                            
                            SettingsRow(
                                icon: "hand.raised",
                                title: "Privacy Settings",
                                subtitle: "Control your data and privacy",
                                action: { /* Handle privacy settings */ }
                            )
                            
                            SettingsRow(
                                icon: "doc.text",
                                title: "Data Export",
                                subtitle: "Download your personal data",
                                action: { /* Handle data export */ }
                            )
                        }
                    }
                    
                    // Support Section
                    SettingsSection(title: "Support") {
                        VStack(spacing: 12) {
                            SettingsRow(
                                icon: "questionmark.circle",
                                title: "Help Center",
                                subtitle: "Get answers to common questions",
                                action: { /* Handle help */ }
                            )
                            
                            SettingsRow(
                                icon: "envelope",
                                title: "Contact Support",
                                subtitle: "Reach out to our support team",
                                action: { /* Handle contact */ }
                            )
                            
                            SettingsRow(
                                icon: "star",
                                title: "Rate the App",
                                subtitle: "Help us improve by leaving a review",
                                action: { /* Handle rating */ }
                            )
                        }
                    }
                    
                    // Danger Zone
                    SettingsSection(title: "Account", isDestructive: true) {
                        VStack(spacing: 12) {
                            SettingsRow(
                                icon: "trash",
                                title: "Delete Account",
                                subtitle: "Permanently delete your account and data",
                                action: { showingDeleteAccount = true },
                                isDestructive: true
                            )
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showingPathChange) {
            PathChangeView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingAppPreferences) {
            AppPreferencesView()
                .environmentObject(dataManager)
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Handle account deletion
                authManager.signOut()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

// MARK: - Path Change View
struct PathChangeView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPath: TrainingPath?
    @State private var isUpdating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Change Your Focus")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Select a new training path. Your progress will be saved and you'll get fresh content tailored to your new focus.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(TrainingPath.allCases) { path in
                            PathChangeCard(
                                path: path,
                                isSelected: selectedPath == path,
                                isCurrent: path == dataManager.userProfile?.selectedPath,
                                action: { 
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedPath = path
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if let selectedPath = selectedPath,
                       selectedPath != dataManager.userProfile?.selectedPath {
                        Button(action: updatePath) {
                            HStack {
                                if isUpdating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Update Training Path")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(selectedPath.color)
                            .cornerRadius(12)
                        }
                        .disabled(isUpdating)
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Training Path")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .onAppear {
            selectedPath = dataManager.userProfile?.selectedPath
        }
    }
    
    private func updatePath() {
        guard let selectedPath = selectedPath else { return }
        
        isUpdating = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dataManager.updateUserPath(selectedPath)
            isUpdating = false
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - App Preferences View
struct AppPreferencesView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var darkModeEnabled = false
    @State private var hapticFeedbackEnabled = true
    @State private var autoAdvanceEnabled = true
    @State private var showCompletionAnimations = true
    @State private var challengeDifficulty: DailyChallenge.ChallengeDifficulty = .micro
    @State private var weekStartsOn = 1 // 1 = Monday, 0 = Sunday
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Appearance Section
                    SettingsSection(title: "Appearance") {
                        VStack(spacing: 12) {
                            Toggle("Dark Mode", isOn: $darkModeEnabled)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            Toggle("Show Completion Animations", isOn: $showCompletionAnimations)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Interaction Section
                    SettingsSection(title: "Interaction") {
                        VStack(spacing: 12) {
                            Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            Toggle("Auto-advance After Completion", isOn: $autoAdvanceEnabled)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Challenge Preferences
                    SettingsSection(title: "Challenge Preferences") {
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Default Challenge Difficulty")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Picker("Difficulty", selection: $challengeDifficulty) {
                                    ForEach(DailyChallenge.ChallengeDifficulty.allCases, id: \.self) { difficulty in
                                        Text(difficulty.displayName).tag(difficulty)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Calendar Preferences
                    SettingsSection(title: "Calendar") {
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Week Starts On")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Picker("Week Start", selection: $weekStartsOn) {
                                    Text("Sunday").tag(0)
                                    Text("Monday").tag(1)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Data & Storage
                    SettingsSection(title: "Data & Storage") {
                        VStack(spacing: 12) {
                            SettingsRow(
                                icon: "icloud",
                                title: "Sync with iCloud",
                                subtitle: "Keep your data synced across devices",
                                action: { /* Handle iCloud sync */ }
                            )
                            
                            SettingsRow(
                                icon: "arrow.clockwise",
                                title: "Reset All Preferences",
                                subtitle: "Restore default app settings",
                                action: { /* Handle reset */ }
                            )
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("App Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                savePreferences()
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func savePreferences() {
        // Save preferences to UserDefaults or DataManager
        UserDefaults.standard.set(darkModeEnabled, forKey: "darkModeEnabled")
        UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")
        UserDefaults.standard.set(autoAdvanceEnabled, forKey: "autoAdvanceEnabled")
        UserDefaults.standard.set(showCompletionAnimations, forKey: "showCompletionAnimations")
        UserDefaults.standard.set(challengeDifficulty.rawValue, forKey: "defaultChallengeDifficulty")
        UserDefaults.standard.set(weekStartsOn, forKey: "weekStartsOn")
    }
}

// MARK: - Enhanced Profile Edit View
struct EnhancedEditProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var bio: String = ""
    @State private var goals: [String] = []
    @State private var newGoal: String = ""
    @State private var isLoading = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Image Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(dataManager.userProfile?.selectedPath.color ?? .blue)
                                .frame(width: 120, height: 120)
                            
                            if let imageURL = authManager.currentUser?.profileImageURL {
                                // AsyncImage would go here in real implementation
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            } else {
                                Text(authManager.currentUser?.initials ?? "??")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            // Camera button overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: { showingImagePicker = true }) {
                                        Image(systemName: "camera.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .frame(width: 120, height: 120)
                        }
                        
                        Button("Change Photo") {
                            showingImagePicker = true
                        }
                        .font(.subheadline)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    }
                    
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("First Name")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("First name", text: $firstName)
                                        .textFieldStyle(ModernTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Last Name")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Last name", text: $lastName)
                                        .textFieldStyle(ModernTextFieldStyle())
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bio")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                                    .textFieldStyle(ModernTextFieldStyle())
                                    .lineLimit(3...6)
                            }
                        }
                    }
                    
                    // Goals Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personal Goals")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            // Add new goal
                            HStack {
                                TextField("Add a personal goal...", text: $newGoal)
                                    .textFieldStyle(ModernTextFieldStyle())
                                
                                Button(action: addGoal) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                                }
                                .disabled(newGoal.isEmpty)
                            }
                            
                            // Display existing goals
                            if !goals.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(goals.indices, id: \.self) { index in
                                        HStack {
                                            Text(goals[index])
                                                .font(.body)
                                            
                                            Spacer()
                                            
                                            Button(action: { removeGoal(at: index) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveProfile()
                }
                .disabled(isLoading)
            )
        }
        .onAppear {
            loadCurrentData()
        }
        .sheet(isPresented: $showingImagePicker) {
            // Image picker would go here
            Text("Image Picker Placeholder")
        }
    }
    
    private func loadCurrentData() {
        firstName = authManager.currentUser?.firstName ?? ""
        lastName = authManager.currentUser?.lastName ?? ""
        bio = authManager.currentUser?.bio ?? ""
        goals = authManager.currentUser?.goals ?? []
    }
    
    private func addGoal() {
        guard !newGoal.isEmpty else { return }
        goals.append(newGoal)
        newGoal = ""
    }
    
    private func removeGoal(at index: Int) {
        goals.remove(at: index)
    }
    
    private func saveProfile() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Update user data
            authManager.currentUser?.firstName = firstName
            authManager.currentUser?.lastName = lastName
            authManager.currentUser?.bio = bio
            authManager.currentUser?.goals = goals
            
            // Save updated session
            if let user = authManager.currentUser,
               let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "user_session")
            }
            
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Supporting Components

// Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    let isDestructive: Bool
    
    init(title: String, isDestructive: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isDestructive = isDestructive
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isDestructive ? .red : .primary)
            
            content
        }
    }
}

// Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    let isDestructive: Bool
    
    init(icon: String, title: String, subtitle: String = "", action: @escaping () -> Void, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : .blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Path Change Card
struct PathChangeCard: View {
    let path: TrainingPath
    let isSelected: Bool
    let isCurrent: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: path.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : path.color)
                
                Spacer()
                
                if isCurrent {
                    Text("CURRENT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : path.color.opacity(0.8))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(path.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(path.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? path.color : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? path.color : Color.clear, lineWidth: 2)
                )
        )
        .onTapGesture(perform: action)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .font(.body)
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthManager())
            .environmentObject(DataManager())
    }
}