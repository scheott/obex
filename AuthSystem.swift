import SwiftUI
import Foundation

// MARK: - Auth Manager
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        checkAuthStatus()
    }
    
    // MARK: - Authentication Methods
    func signUp(email: String, password: String, firstName: String, lastName: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        await MainActor.run {
            // Simulate successful signup
            let newUser = User(
                id: UUID().uuidString,
                email: email,
                firstName: firstName,
                lastName: lastName,
                dateJoined: Date(),
                subscription: .free
            )
            
            self.currentUser = newUser
            self.isAuthenticated = true
            self.isLoading = false
            
            // Save to UserDefaults (in production, use Keychain)
            saveUserSession(newUser)
        }
    }
    
    func signIn(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        await MainActor.run {
            // Simulate validation
            if email.isEmpty || password.isEmpty {
                self.errorMessage = "Please fill in all fields"
                self.isLoading = false
                return
            }
            
            if !email.contains("@") {
                self.errorMessage = "Please enter a valid email"
                self.isLoading = false
                return
            }
            
            if password.count < 6 {
                self.errorMessage = "Password must be at least 6 characters"
                self.isLoading = false
                return
            }
            
            // Simulate successful login
            let user = User(
                id: UUID().uuidString,
                email: email,
                firstName: "John", // Would come from server
                lastName: "Doe",
                dateJoined: Date().addingTimeInterval(-86400 * 30), // 30 days ago
                subscription: .free
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
            
            saveUserSession(user)
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        clearUserSession()
    }
    
    func resetPassword(email: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            // Simulate password reset
            self.isLoading = false
            // Show success message (would be handled by parent view)
        }
    }
    
    // MARK: - Session Management
    private func checkAuthStatus() {
        if let userData = UserDefaults.standard.data(forKey: "user_session"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    private func saveUserSession(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "user_session")
        }
    }
    
    private func clearUserSession() {
        UserDefaults.standard.removeObject(forKey: "user_session")
    }
}

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    var email: String
    var firstName: String
    var lastName: String
    let dateJoined: Date
    var subscription: SubscriptionTier
    var profileImageURL: String?
    var bio: String?
    var goals: [String] = []
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var initials: String {
        "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased()
    }
}

// MARK: - Authentication View
struct AuthenticationView: View {
    @StateObject private var authManager = AuthManager()
    @State private var showingSignUp = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Navigate to main app
                MainAppView()
                    .environmentObject(authManager)
            } else {
                if showingSignUp {
                    SignUpView(showingSignUp: $showingSignUp)
                        .environmentObject(authManager)
                } else {
                    SignInView(showingSignUp: $showingSignUp)
                        .environmentObject(authManager)
                }
            }
        }
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showingSignUp: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingForgotPassword = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.gray.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Sign in to continue your journey")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(AuthTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(AuthTextFieldStyle())
                        }
                        
                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Forgot Password
                        Button("Forgot Password?") {
                            showingForgotPassword = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 32)
                    
                    // Sign In Button
                    VStack(spacing: 16) {
                        Button(action: signIn) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Sign In")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLoading)
                        .padding(.horizontal, 32)
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.white.opacity(0.8))
                            
                            Button("Sign Up") {
                                showingSignUp = true
                            }
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
                .environmentObject(authManager)
        }
    }
    
    private func signIn() {
        Task {
            await authManager.signIn(email: email, password: password)
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showingSignUp: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var agreeToTerms = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.gray.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Start your transformation journey")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Name Fields
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("First Name")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                
                                TextField("First", text: $firstName)
                                    .textFieldStyle(AuthTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last Name")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                
                                TextField("Last", text: $lastName)
                                    .textFieldStyle(AuthTextFieldStyle())
                            }
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(AuthTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password Fields
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            SecureField("Create password", text: $password)
                                .textFieldStyle(AuthTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            SecureField("Confirm password", text: $confirmPassword)
                                .textFieldStyle(AuthTextFieldStyle())
                        }
                        
                        // Terms Agreement
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: { agreeToTerms.toggle() }) {
                                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                    .foregroundColor(agreeToTerms ? .blue : .white.opacity(0.6))
                                    .font(.title3)
                            }
                            
                            Text("I agree to the Terms of Service and Privacy Policy")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.top, 8)
                        
                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Sign Up Button
                    VStack(spacing: 16) {
                        Button(action: signUp) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Create Account")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLoading || !agreeToTerms)
                        .opacity(agreeToTerms ? 1.0 : 0.6)
                        .padding(.horizontal, 32)
                        
                        // Sign In Link
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.white.opacity(0.8))
                            
                            Button("Sign In") {
                                showingSignUp = false
                            }
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
    }
    
    private func signUp() {
        // Validation
        guard !firstName.isEmpty && !lastName.isEmpty else {
            authManager.errorMessage = "Please enter your name"
            return
        }
        
        guard password == confirmPassword else {
            authManager.errorMessage = "Passwords don't match"
            return
        }
        
        guard password.count >= 6 else {
            authManager.errorMessage = "Password must be at least 6 characters"
            return
        }
        
        Task {
            await authManager.signUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var emailSent = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Reset Password")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter your email address and we'll send you instructions to reset your password.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                if !emailSent {
                    VStack(spacing: 20) {
                        TextField("Email address", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        Button(action: resetPassword) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Send Reset Email")
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLoading || email.isEmpty)
                    }
                    .padding(.horizontal, 32)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Check Your Email")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("We've sent password reset instructions to \(email)")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func resetPassword() {
        Task {
            await authManager.resetPassword(email: email)
            emailSent = true
        }
    }
}

// MARK: - Profile Management View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView()
                    
                    // Stats Section
                    ProfileStatsView()
                    
                    // Quick Actions
                    QuickActionsView(
                        showingEditProfile: $showingEditProfile,
                        showingSettings: $showingSettings
                    )
                    
                    // Account Section
                    AccountSectionView()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(authManager)
                    .environmentObject(dataManager)
            }
        }
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(dataManager.userProfile?.selectedPath.color ?? .blue)
                    .frame(width: 100, height: 100)
                
                if let imageURL = authManager.currentUser?.profileImageURL {
                    // AsyncImage would go here in real implementation
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                } else {
                    Text(authManager.currentUser?.initials ?? "??")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(spacing: 4) {
                Text(authManager.currentUser?.fullName ?? "Unknown User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(authManager.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let bio = authManager.currentUser?.bio {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            
            // Current Path Badge
            if let path = dataManager.userProfile?.selectedPath {
                HStack(spacing: 8) {
                    Image(systemName: path.icon)
                        .font(.caption)
                    Text("Focusing on \(path.displayName)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(path.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(path.color.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Profile Stats
struct ProfileStatsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                ProfileStatCard(
                    title: "Current Streak",
                    value: "\(dataManager.userProfile?.currentStreak ?? 0)",
                    subtitle: "days",
                    color: .orange
                )
                
                ProfileStatCard(
                    title: "Total Challenges",
                    value: "\(dataManager.userProfile?.totalChallengesCompleted ?? 0)",
                    subtitle: "completed",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                ProfileStatCard(
                    title: "Member Since",
                    value: membershipDuration,
                    subtitle: "days",
                    color: .blue
                )
                
                ProfileStatCard(
                    title: "Subscription",
                    value: authManager.currentUser?.subscription.displayName ?? "Free",
                    subtitle: "",
                    color: .purple
                )
            }
        }
    }
    
    private var membershipDuration: String {
        guard let joinDate = authManager.currentUser?.dateJoined else { return "0" }
        let days = Calendar.current.dateComponents([.day], from: joinDate, to: Date()).day ?? 0
        return "\(days)"
    }
}

// MARK: - Quick Actions
struct QuickActionsView: View {
    @Binding var showingEditProfile: Bool
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ActionRow(
                    icon: "person.circle",
                    title: "Edit Profile",
                    subtitle: "Update your personal information",
                    action: { showingEditProfile = true }
                )
                
                ActionRow(
                    icon: "gearshape",
                    title: "Settings",
                    subtitle: "Notifications, privacy, and more",
                    action: { showingSettings = true }
                )
                
                ActionRow(
                    icon: "crown",
                    title: "Upgrade to Pro",
                    subtitle: "Unlock all features and paths",
                    action: { /* Handle upgrade */ }
                )
            }
        }
    }
}

// MARK: - Account Section
struct AccountSectionView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ActionRow(
                    icon: "questionmark.circle",
                    title: "Help & Support",
                    subtitle: "Get help and contact support",
                    action: { /* Handle support */ }
                )
                
                ActionRow(
                    icon: "doc.text",
                    title: "Privacy Policy",
                    subtitle: "Read our privacy policy",
                    action: { /* Handle privacy */ }
                )
                
                ActionRow(
                    icon: "arrow.right.square",
                    title: "Sign Out",
                    subtitle: "Sign out of your account",
                    action: { authManager.signOut() },
                    isDestructive: true
                )
            }
        }
    }
}

// MARK: - Action Row
struct ActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    let isDestructive: Bool
    
    init(icon: String, title: String, subtitle: String, action: @escaping () -> Void, isDestructive: Bool = false) {
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
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
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

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var bio: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Image Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 120, height: 120)
                            
                            Text(authManager.currentUser?.initials ?? "??")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Button("Change Photo") {
                            // Handle photo change
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("First name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Last name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    .padding(.horizontal, 20)
                }
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
    }
    
    private func loadCurrentData() {
        firstName = authManager.currentUser?.firstName ?? ""
        lastName = authManager.currentUser?.lastName ?? ""
        bio = authManager.currentUser?.bio ?? ""
    }
    
    private func saveProfile() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Update user data
            authManager.currentUser?.firstName = firstName
            authManager.currentUser?.lastName = lastName
            authManager.currentUser?.bio = bio
            
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

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var notificationsEnabled = true
    @State private var morningCheckInTime = Date()
    @State private var eveningCheckInTime = Date()
    @State private var showingPathChange = false
    @State private var showingDeleteAccount = false
    
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
                                        // Handle upgrade
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
                                action: { /* Handle password change */ }
                            )
                            
                            SettingsRow(
                                icon: "hand.raised",
                                title: "Privacy Settings",
                                action: { /* Handle privacy settings */ }
                            )
                            
                            SettingsRow(
                                icon: "doc.text",
                                title: "Data Export",
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
                                action: { /* Handle help */ }
                            )
                            
                            SettingsRow(
                                icon: "envelope",
                                title: "Contact Support",
                                action: { /* Handle contact */ }
                            )
                            
                            SettingsRow(
                                icon: "star",
                                title: "Rate the App",
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

// MARK: - Settings Section
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

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    let isDestructive: Bool
    
    init(icon: String, title: String, action: @escaping () -> Void, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
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
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : .primary)
                
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

// MARK: - Path Change View
struct PathChangeView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPath: TrainingPath?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Change Your Focus")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Select a new training path. Your progress will be saved.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
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
                                action: { selectedPath = path }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if let selectedPath = selectedPath,
                       selectedPath != dataManager.userProfile?.selectedPath {
                        Button("Update Training Path") {
                            dataManager.updateUserPath(selectedPath)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedPath.color)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
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
}

// MARK: - Path Change Card
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

// MARK: - Auth Text Field Style
struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .font(.body)
    }
}

// MARK: - Main App View (Updated to include auth)
struct MainAppView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var dataManager = DataManager()
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if dataManager.userProfile == nil {
                OnboardingView()
                    .environmentObject(dataManager)
            } else {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(0)
                    
                    ChallengeView()
                        .tabItem {
                            Image(systemName: "target")
                            Text("Challenge")
                        }
                        .tag(1)
                    
                    BookStationView()
                        .tabItem {
                            Image(systemName: "book.fill")
                            Text("Books")
                        }
                        .tag(2)
                    
                    CheckInView()
                        .tabItem {
                            Image(systemName: "message.fill")
                            Text("Check-in")
                        }
                        .tag(3)
                    
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person.fill")
                            Text("Profile")
                        }
                        .tag(4)
                }
                .accentColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                .environmentObject(dataManager)
                .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Profile Stat Card
struct ProfileStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}