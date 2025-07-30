import SwiftUI
import Foundation

// MARK: - SettingsView (Main settings hub)
struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingProfileEdit = false
    @State private var showingPathChange = false
    @State private var showingDataExport = false
    @State private var showingNotificationSettings = false
    @State private var showingDeleteAccount = false
    @State private var showingSubscription = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeader
                    
                    // Training Path Section
                    SettingsSection(title: "Training") {
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: dataManager.userProfile?.selectedPath.icon ?? "target",
                                title: "Training Path",
                                subtitle: dataManager.userProfile?.selectedPath.displayName ?? "Not Set",
                                iconColor: dataManager.userProfile?.selectedPath.color ?? .gray,
                                showChevron: true,
                                action: { showingPathChange = true }
                            )
                        }
                    }
                    
                    // Account Section
                    SettingsSection(title: "Account") {
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "person.circle",
                                title: "Edit Profile",
                                subtitle: "Update your personal information",
                                showChevron: true,
                                action: { showingProfileEdit = true }
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            SettingsRow(
                                icon: "crown.fill",
                                title: "Subscription",
                                subtitle: authManager.currentUser?.subscription.displayName ?? "Free",
                                iconColor: authManager.currentUser?.subscription == .free ? .gray : .purple,
                                showChevron: true,
                                action: { showingSubscription = true }
                            )
                        }
                    }
                    
                    // Preferences Section
                    SettingsSection(title: "Preferences") {
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "bell",
                                title: "Notifications",
                                subtitle: "Manage your notification preferences",
                                showChevron: true,
                                action: { showingNotificationSettings = true }
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            SettingsRow(
                                icon: "square.and.arrow.up",
                                title: "Export Data",
                                subtitle: "Download your personal data",
                                showChevron: true,
                                action: { showingDataExport = true }
                            )
                        }
                    }
                    
                    // Support Section
                    SettingsSection(title: "Support") {
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "questionmark.circle",
                                title: "Help Center",
                                subtitle: "Get answers to common questions",
                                showChevron: true,
                                action: openHelpCenter
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            SettingsRow(
                                icon: "envelope",
                                title: "Contact Support",
                                subtitle: "Reach out to our support team",
                                showChevron: true,
                                action: contactSupport
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            SettingsRow(
                                icon: "star",
                                title: "Rate the App",
                                subtitle: "Help us improve with your feedback",
                                showChevron: true,
                                action: rateApp
                            )
                        }
                    }
                    
                    // Account Actions Section
                    SettingsSection(title: "Account Actions") {
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "Sign Out",
                                subtitle: "Sign out of your account",
                                iconColor: .orange,
                                showChevron: false,
                                action: signOut
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            SettingsRow(
                                icon: "trash",
                                title: "Delete Account",
                                subtitle: "Permanently delete your account",
                                iconColor: .red,
                                showChevron: false,
                                action: { showingDeleteAccount = true }
                            )
                        }
                    }
                    
                    // App Version
                    VStack(spacing: 4) {
                        Text("Mentor App")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView()
                .environmentObject(authManager)
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingPathChange) {
            PathChangeView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettings()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
                .environmentObject(authManager)
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
    
    private var profileHeader: some View {
        HStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(dataManager.userProfile?.selectedPath.color.opacity(0.2) ?? Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                if let imageURL = authManager.currentUser?.profileImageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            
            // Profile Info
            VStack(alignment: .leading, spacing: 4) {
                Text(authManager.currentUser?.displayName ?? "Welcome")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let email = authManager.currentUser?.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Streak Info
                if let profile = dataManager.userProfile {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("\(profile.currentStreak) day streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Actions
    private func signOut() {
        Task {
            try? await authManager.signOut()
        }
    }
    
    private func deleteAccount() {
        Task {
            try? await authManager.deleteAccount()
        }
    }
    
    private func openHelpCenter() {
        if let url = URL(string: "https://help.mentorapp.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func contactSupport() {
        if let url = URL(string: "mailto:support@mentorapp.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/mentor-app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - SettingsSection (Grouped settings)
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// MARK: - SettingsRow (Individual setting item)
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var iconColor: Color = .primary
    var showChevron: Bool = true
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, iconColor: Color = .primary, showChevron: Bool = true, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                // Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ProfileEditView (Profile management)
struct ProfileEditView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var bio: String = ""
    @State private var isLoading = false
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Profile Image
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 100, height: 100)
                            
                            if let imageURL = authManager.currentUser?.profileImageURL {
                                AsyncImage(url: URL(string: imageURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Edit overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: { showingActionSheet = true }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 30, height: 30)
                                            
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .offset(x: -5, y: -5)
                                }
                            }
                        }
                        .frame(height: 100)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
                
                Section("Personal Information") {
                    HStack {
                        Text("First Name")
                        Spacer()
                        TextField("Enter first name", text: $firstName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Last Name")
                        Spacer()
                        TextField("Enter last name", text: $lastName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        TextField("Enter email", text: $email)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                
                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.subheadline)
                        
                        TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
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
        .onAppear(perform: loadCurrentProfile)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Profile Photo"),
                buttons: [
                    .default(Text("Camera")) {
                        // Handle camera
                    },
                    .default(Text("Photo Library")) {
                        showingImagePicker = true
                    },
                    .destructive(Text("Remove Photo")) {
                        // Handle remove photo
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func loadCurrentProfile() {
        if let user = authManager.currentUser {
            firstName = user.firstName ?? ""
            lastName = user.lastName ?? ""
            email = user.email
            bio = user.bio ?? ""
        }
    }
    
    private func saveProfile() {
        isLoading = true
        
        Task {
            try? await authManager.updateProfile(
                firstName: firstName,
                lastName: lastName,
                email: email,
                bio: bio
            )
            
            await MainActor.run {
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - PathChangeView (Training path switcher)
struct PathChangeView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPath: TrainingPath?
    @State private var isChanging = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Change Training Path")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Switch your focus area to continue growing in different aspects of your life.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Path Selection
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        ForEach(TrainingPath.allCases, id: \.self) { path in
                            PathSelectionCard(
                                path: path,
                                isCurrent: dataManager.userProfile?.selectedPath == path,
                                isSelected: selectedPath == path,
                                action: { selectedPath = path }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: changePath) {
                        HStack {
                            if isChanging {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isChanging ? "Changing Path..." : "Change Path")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedPath != nil && selectedPath != dataManager.userProfile?.selectedPath ? Color.blue : Color.gray)
                        )
                    }
                    .disabled(selectedPath == nil || selectedPath == dataManager.userProfile?.selectedPath || isChanging)
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 20)
            .navigationBarHidden(true)
        }
        .onAppear {
            selectedPath = dataManager.userProfile?.selectedPath
        }
    }
    
    private func changePath() {
        guard let newPath = selectedPath, newPath != dataManager.userProfile?.selectedPath else { return }
        
        isChanging = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dataManager.changeTrainingPath(to: newPath)
            isChanging = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - PathSelectionCard
struct PathSelectionCard: View {
    let path: TrainingPath
    let isCurrent: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(path.color.opacity(isSelected ? 1.0 : 0.3))
                    .frame(width: 50, height: 50)
                
                Image(systemName: path.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : path.color)
            }
            
            Text(path.displayName)
                .font(.headline)
                .fontWeight(.semibold)
            
            if isCurrent {
                Text("Current")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(path.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
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
                .fill(isSelected ? path.color.opacity(0.1) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? path.color : Color.clear, lineWidth: 2)
                )
        )
        .onTapGesture(perform: action)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - NotificationSettings (Notification preferences)
struct NotificationSettings: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var notificationsEnabled = true
    @State private var morningCheckInEnabled = true
    @State private var eveningCheckInEnabled = true
    @State private var challengeRemindersEnabled = true
    @State private var weeklyInsightsEnabled = true
    @State private var streakRemindersEnabled = true
    @State private var morningTime = Date()
    @State private var eveningTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .tint(.blue)
                } footer: {
                    Text("Allow the app to send you notifications for check-ins, reminders, and insights.")
                }
                
                if notificationsEnabled {
                    Section("Check-ins") {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Toggle("Morning Check-in", isOn: $morningCheckInEnabled)
                                        .tint(.blue)
                                    
                                    if morningCheckInEnabled {
                                        Text("Receive a daily morning prompt")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if morningCheckInEnabled {
                                    DatePicker("", selection: $morningTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                            }
                            
                            if morningCheckInEnabled && eveningCheckInEnabled {
                                Divider()
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Toggle("Evening Check-in", isOn: $eveningCheckInEnabled)
                                        .tint(.blue)
                                    
                                    if eveningCheckInEnabled {
                                        Text("Reflect on your day each evening")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if eveningCheckInEnabled {
                                    DatePicker("", selection: $eveningTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                            }
                        }
                    }
                    
                    Section("Reminders") {
                        Toggle("Challenge Reminders", isOn: $challengeRemindersEnabled)
                            .tint(.blue)
                        
                        Toggle("Weekly Insights", isOn: $weeklyInsightsEnabled)
                            .tint(.blue)
                        
                        Toggle("Streak Reminders", isOn: $streakRemindersEnabled)
                            .tint(.blue)
                    } footer: {
                        Text("Get gentle reminders to complete your daily challenges and maintain your streak.")
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveSettings()
                }
            )
        }
        .onAppear(perform: loadCurrentSettings)
    }
    
    private func loadCurrentSettings() {
        if let settings = dataManager.userProfile?.notificationSettings {
            notificationsEnabled = settings.morningCheckInEnabled || settings.eveningCheckInEnabled
            morningCheckInEnabled = settings.morningCheckInEnabled
            eveningCheckInEnabled = settings.eveningCheckInEnabled
            challengeRemindersEnabled = settings.challengeRemindersEnabled
            weeklyInsightsEnabled = settings.weeklyInsightsEnabled
            streakRemindersEnabled = settings.streakRemindersEnabled
            morningTime = settings.morningCheckInTime
            eveningTime = settings.eveningCheckInTime
        }
    }
    
    private func saveSettings() {
        // Update notification settings
        dataManager.updateNotificationSettings(
            morningCheckInEnabled: morningCheckInEnabled,
            eveningCheckInEnabled: eveningCheckInEnabled,
            challengeRemindersEnabled: challengeRemindersEnabled,
            weeklyInsightsEnabled: weeklyInsightsEnabled,
            streakRemindersEnabled: streakRemindersEnabled,
            morningTime: morningTime,
            eveningTime: eveningTime
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - DataExportView (Export functionality)
struct DataExportView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isExporting = false
    @State private var exportComplete = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Download all your personal data including journal entries, progress, and insights in JSON format.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Export Content Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your export will include:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ExportItemRow(icon: "person.circle", text: "Profile information")
                        ExportItemRow(icon: "book.closed", text: "Journal entries")
                        ExportItemRow(icon: "target", text: "Challenge history")
                        ExportItemRow(icon: "chart.line.uptrend.xyaxis", text: "Progress statistics")
                        ExportItemRow(icon: "books.vertical", text: "Reading progress")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Export Actions
                VStack(spacing: 16) {
                    if !exportComplete {
                        Button(action: exportData) {
                            HStack {
                                if isExporting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                
                                Text(isExporting ? "Exporting..." : "Export Data")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                        }
                        .disabled(isExporting)
                    } else {
                        Button(action: { showingShareSheet = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Export File")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ActivityViewController(activityItems: [url])
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Simulate export process
            Thread.sleep(forTimeInterval: 2.0)
            
            let exportData = dataManager.exportUserData()
            let url = createExportFile(exportData)
            
            DispatchQueue.main.async {
                self.exportURL = url
                self.isExporting = false
                self.exportComplete = true
            }
        }
    }
    
    private func createExportFile(_ data: UserDataExport) -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(data)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("mentor_app_export_\(DateFormatter.filenameDateFormatter.string(from: Date())).json")
            
            try jsonData.write(to: tempURL)
            return tempURL
        } catch {
            // Fallback to a simple text file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("mentor_app_export_error.txt")
            
            try? "Export failed: \(error.localizedDescription)".write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        }
    }
}

// MARK: - ExportItemRow
struct ExportItemRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - ActivityViewController for sharing
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Extensions
extension DateFormatter {
    static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthManager())
            .environmentObject(DataManager())
    }
}
