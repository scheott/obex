    var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Double-check your email and password, or use 'Forgot Password' if needed."
        case .userNotFound:
            return "Sign up for a new account or verify the email address."
        case .userNotVerified:
            return "Check your email for verification link and click it."
        case .sessionExpired:
            return "Please sign in again to continue."
        case .weakPassword:
            return "Use a password with at least 8 characters, including uppercase, lowercase, and numbers."
        case .networkError:
            return "Check your internet connection and try again."
        case .biometricNotAvailable:
            return "Use email and password to sign in instead."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .rateLimitExceeded, .unknown:
            return true
        default:
            return false
        }
    }
}

// MARK: - Session Manager
class SessionManager {
    private let sessionKey = "user_session"
    private let sessionExpiryKey = "session_expiry"
    private let refreshTokenKey = "refresh_token"
    
    private let sessionDuration: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    
    func saveUserSession(_ user: User) {
        do {
            let userData = try JSONEncoder().encode(user)
            let expiryDate = Date().addingTimeInterval(sessionDuration)
            
            UserDefaults.standard.set(userData, forKey: sessionKey)
            UserDefaults.standard.set(expiryDate, forKey: sessionExpiryKey)
        } catch {
            print("Failed to save user session: \(error)")
        }
    }
    
    func loadUserSession() -> User? {
        guard let userData = UserDefaults.standard.data(forKey: sessionKey) else {
            return nil
        }
        
        do {
            let user = try JSONDecoder().decode(User.self, from: userData)
            return user
        } catch {
            print("Failed to load user session: \(error)")
            clearUserSession()
            return nil
        }
    }
    
    func isSessionValid() -> Bool {
        guard let expiryDate = UserDefaults.standard.object(forKey: sessionExpiryKey) as? Date else {
            return false
        }
        
        return Date() < expiryDate
    }
    
    func clearUserSession() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        UserDefaults.standard.removeObject(forKey: sessionExpiryKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
    
    func extendSession() {
        let newExpiryDate = Date().addingTimeInterval(sessionDuration)
        UserDefaults.standard.set(newExpiryDate, forKey: sessionExpiryKey)
    }
}

// MARK: - Biometric Auth Manager
class BiometricAuthManager {
    
    func isBiometricAuthAvailable() async -> Bool {
        // Simulate biometric availability check
        return true
    }
    
    func authenticateWithBiometrics() async -> Bool {
        // Simulate biometric authentication
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return true
    }
    
    func getBiometricType() -> BiometricType {
        // Simulate detecting biometric type
        return .faceID
    }
    
    enum BiometricType {
        case faceID
        case touchID
        case none
        
        var displayName: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .none: return "None"
            }
        }
        
        var icon: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .none: return "nosign"
            }
        }
    }
}

// MARK: - Authentication Views

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var showingForgotPassword = false
    @State private var showingSignUp = false
    
    var body: some View {
        ZStack {
            // Background gradient
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
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Sign in to continue your growth journey")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.top, 40)
                    
                    // Sign In Form
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
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
                                    .autocorrectionDisabled()
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
                            
                            // Remember Me & Forgot Password
                            HStack {
                                Toggle("Remember me", isOn: $rememberMe)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button("Forgot Password?") {
                                    showingForgotPassword = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        // Sign In Button
                        Button(action: signIn) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        
                        // Social Sign In
                        VStack(spacing: 16) {
                            Text("Or continue with")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack(spacing: 16) {
                                SocialSignInButton(
                                    provider: .apple,
                                    action: { signInWithApple() }
                                )
                                
                                SocialSignInButton(
                                    provider: .google,
                                    action: { signInWithGoogle() }
                                )
                            }
                        }
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button("Sign Up") {
                                showingSignUp = true
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
                .environmentObject(authManager)
        }
        .alert("Sign In Error", isPresented: .constant(authManager.errorMessage != nil)) {
            Button("OK") {
                authManager.errorMessage = nil
            }
        } message: {
            Text(authManager.errorMessage ?? "")
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func signIn() {
        let credentials = LoginCredentials(
            email: email,
            password: password,
            rememberMe: rememberMe
        )
        
        Task {
            try? await authManager.signIn(with: credentials)
        }
    }
    
    private func signInWithApple() {
        Task {
            try? await authManager.signInWithApple()
        }
    }
    
    private func signInWithGoogle() {
        Task {
            try? await authManager.signInWithGoogle()
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var acceptedTerms = false
    @State private var acceptedPrivacy = false
    @State private var marketingOptIn = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
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
                            Text("Create Account")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Start your personal development journey")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 20)
                        
                        // Sign Up Form
                        VStack(spacing: 20) {
                            VStack(spacing: 16) {
                                // Name Fields
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("First Name")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        TextField("First", text: $firstName)
                                            .textFieldStyle(AuthTextFieldStyle())
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Last Name")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        TextField("Last", text: $lastName)
                                            .textFieldStyle(AuthTextFieldStyle())
                                    }
                                }
                                
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
                                        .autocorrectionDisabled()
                                }
                                
                                // Password Fields
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Password")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    SecureField("Create password", text: $password)
                                        .textFieldStyle(AuthTextFieldStyle())
                                    
                                    // Password strength indicator
                                    if !password.isEmpty {
                                        PasswordStrengthView(password: password)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    SecureField("Confirm password", text: $confirmPassword)
                                        .textFieldStyle(AuthTextFieldStyle())
                                    
                                    if !confirmPassword.isEmpty && password != confirmPassword {
                                        Text("Passwords don't match")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            // Terms and Privacy
                            VStack(spacing: 12) {
                                HStack {
                                    Toggle("", isOn: $acceptedTerms)
                                        .labelsHidden()
                                    
                                    Text("I agree to the Terms of Service")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Toggle("", isOn: $acceptedPrivacy)
                                        .labelsHidden()
                                    
                                    Text("I agree to the Privacy Policy")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Toggle("", isOn: $marketingOptIn)
                                        .labelsHidden()
                                    
                                    Text("I'd like to receive marketing emails")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Spacer()
                                }
                            }
                            
                            // Sign Up Button
                            Button(action: signUp) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Create Account")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                            .disabled(authManager.isLoading || !isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                        }
                        .padding(.horizontal, 32)
                    }
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            )
        }
        .alert("Sign Up Error", isPresented: .constant(authManager.errorMessage != nil)) {
            Button("OK") {
                authManager.errorMessage = nil
            }
        } message: {
            Text(authManager.errorMessage ?? "")
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        password == confirmPassword &&
        acceptedTerms &&
        acceptedPrivacy
    }
    
    private func signUp() {
        let registrationData = RegistrationData(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            firstName: firstName,
            lastName: lastName,
            acceptedTerms: acceptedTerms,
            acceptedPrivacy: acceptedPrivacy,
            marketingOptIn: marketingOptIn
        )
        
        Task {
            do {
                try await authManager.signUp(with: registrationData)
                presentationMode.wrappedValue.dismiss()
            } catch {
                // Error handled by AuthManager
            }
        }
    }
}

// MARK: - Supporting Views

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

struct SocialSignInButton: View {
    let provider: User.AuthProvider
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: provider.icon)
                    .font(.title3)
                
                Text(provider.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.9))
            .foregroundColor(.black)
            .cornerRadius(12)
        }
    }
}

struct PasswordStrengthView: View {
    let password: String
    
    private var registrationData: RegistrationData {
        RegistrationData(
            email: "",
            password: password,
            confirmPassword: password,
            firstName: "",
            lastName: ""
        )
    }
    
    var body: some View {
        HStack {
            Text("Password strength:")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(registrationData.passwordStrength.description)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(registrationData.passwordStrength.color)
            
            Spacer()
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var isLoading = false
    @State private var emailSent = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if !emailSent {
                    VStack(spacing: 16) {
                        TextField("Email address", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        Button(action: sendResetEmail) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Send Reset Link")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(email.isEmpty || isLoading)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("Email Sent!")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Check your email for password reset instructions.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func sendResetEmail() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            emailSent = true
        }
    }
}

// MARK: - Preview
struct AuthSystem_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(AuthManager())
    }
}import SwiftUI
import Foundation
import Combine
import CryptoKit

// MARK: - AuthManager (Authentication handler)
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authState: AuthState = .unauthenticated
    
    private var cancellables = Set<AnyCancellable>()
    private let sessionManager = SessionManager()
    private let biometricAuth = BiometricAuthManager()
    
    init() {
        checkAuthStatus()
        setupSessionObserver()
    }
    
    enum AuthState {
        case unauthenticated
        case authenticating
        case authenticated
        case sessionExpired
        case biometricRequired
        case passwordResetRequired
    }
    
    // MARK: - Authentication Methods
    
    func signUp(with data: RegistrationData) async throws {
        await setLoadingState(true)
        
        do {
            // Validate registration data
            try validateRegistrationData(data)
            
            // Simulate API call for registration
            try await simulateNetworkDelay()
            
            // Create new user
            let newUser = User(
                id: UUID().uuidString,
                email: data.email,
                firstName: data.firstName,
                lastName: data.lastName,
                dateJoined: Date(),
                subscription: .free,
                authProvider: data.authProvider,
                emailVerified: false,
                phoneNumber: data.phoneNumber,
                preferences: UserPreferences()
            )
            
            await MainActor.run {
                self.currentUser = newUser
                self.isAuthenticated = true
                self.authState = .authenticated
                self.isLoading = false
            }
            
            // Save session
            sessionManager.saveUserSession(newUser)
            
            // Send verification email (simulated)
            try await sendVerificationEmail(to: data.email)
            
        } catch let error as AuthError {
            await handleAuthError(error)
            throw error
        } catch {
            let authError = AuthError.registrationFailed(error.localizedDescription)
            await handleAuthError(authError)
            throw authError
        }
    }
    
    func signIn(with credentials: LoginCredentials) async throws {
        await setLoadingState(true)
        
        do {
            // Validate credentials
            try validateCredentials(credentials)
            
            // Simulate API call
            try await simulateNetworkDelay()
            
            // Check if using demo credentials
            if credentials.email == "demo@mentorapp.com" && credentials.password == "demo123" {
                let demoUser = createDemoUser()
                await MainActor.run {
                    self.currentUser = demoUser
                    self.isAuthenticated = true
                    self.authState = .authenticated
                    self.isLoading = false
                }
                sessionManager.saveUserSession(demoUser)
                return
            }
            
            // Simulate user retrieval
            let user = User(
                id: UUID().uuidString,
                email: credentials.email,
                firstName: "John",
                lastName: "Doe",
                dateJoined: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
                subscription: .free,
                authProvider: .email,
                emailVerified: true,
                lastLoginDate: Date(),
                preferences: UserPreferences()
            )
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.authState = .authenticated
                self.isLoading = false
            }
            
            sessionManager.saveUserSession(user)
            
        } catch let error as AuthError {
            await handleAuthError(error)
            throw error
        } catch {
            let authError = AuthError.loginFailed(error.localizedDescription)
            await handleAuthError(authError)
            throw authError
        }
    }
    
    func signInWithApple() async throws {
        await setLoadingState(true)
        
        // Simulate Apple Sign In
        try await simulateNetworkDelay()
        
        let appleUser = User(
            id: UUID().uuidString,
            email: "user@privaterelay.appleid.com",
            firstName: "Apple",
            lastName: "User",
            dateJoined: Date(),
            subscription: .free,
            authProvider: .apple,
            emailVerified: true,
            preferences: UserPreferences()
        )
        
        await MainActor.run {
            self.currentUser = appleUser
            self.isAuthenticated = true
            self.authState = .authenticated
            self.isLoading = false
        }
        
        sessionManager.saveUserSession(appleUser)
    }
    
    func signInWithGoogle() async throws {
        await setLoadingState(true)
        
        // Simulate Google Sign In
        try await simulateNetworkDelay()
        
        let googleUser = User(
            id: UUID().uuidString,
            email: "user@gmail.com",
            firstName: "Google",
            lastName: "User",
            dateJoined: Date(),
            subscription: .free,
            authProvider: .google,
            emailVerified: true,
            preferences: UserPreferences()
        )
        
        await MainActor.run {
            self.currentUser = googleUser
            self.isAuthenticated = true
            self.authState = .authenticated
            self.isLoading = false
        }
        
        sessionManager.saveUserSession(googleUser)
    }
    
    func signOut() async throws {
        await setLoadingState(true)
        
        try await simulateNetworkDelay(0.5)
        
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
            self.authState = .unauthenticated
            self.isLoading = false
            self.errorMessage = nil
        }
        
        sessionManager.clearUserSession()
    }
    
    func deleteAccount() async throws {
        await setLoadingState(true)
        
        try await simulateNetworkDelay()
        
        // Simulate account deletion
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
            self.authState = .unauthenticated
            self.isLoading = false
        }
        
        sessionManager.clearUserSession()
    }
    
    func sendPasswordReset(email: String) async throws {
        try validateEmail(email)
        try await simulateNetworkDelay()
        
        // Simulate sending password reset email
        print("Password reset email sent to \(email)")
    }
    
    func updateProfile(firstName: String, lastName: String, email: String, bio: String) async throws {
        guard var user = currentUser else {
            throw AuthError.userNotFound
        }
        
        await setLoadingState(true)
        
        try await simulateNetworkDelay()
        
        // Update user profile
        user.firstName = firstName
        user.lastName = lastName
        user.email = email
        user.bio = bio
        user.lastUpdated = Date()
        
        await MainActor.run {
            self.currentUser = user
            self.isLoading = false
        }
        
        sessionManager.saveUserSession(user)
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        await setLoadingState(true)
        
        try validatePassword(newPassword)
        try await simulateNetworkDelay()
        
        // Simulate password change
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func enableBiometricAuth() async throws {
        let isAvailable = await biometricAuth.isBiometricAuthAvailable()
        guard isAvailable else {
            throw AuthError.biometricNotAvailable
        }
        
        let success = await biometricAuth.authenticateWithBiometrics()
        if success {
            await MainActor.run {
                self.currentUser?.preferences.biometricAuthEnabled = true
            }
            sessionManager.saveUserSession(currentUser!)
        } else {
            throw AuthError.biometricAuthFailed
        }
    }
    
    // MARK: - Session Management
    
    private func checkAuthStatus() {
        if let savedUser = sessionManager.loadUserSession() {
            // Check if session is still valid
            if sessionManager.isSessionValid() {
                currentUser = savedUser
                isAuthenticated = true
                authState = .authenticated
            } else {
                authState = .sessionExpired
                sessionManager.clearUserSession()
            }
        }
    }
    
    private func setupSessionObserver() {
        // Check session validity every 5 minutes
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkSessionValidity()
            }
            .store(in: &cancellables)
    }
    
    private func checkSessionValidity() {
        if isAuthenticated && !sessionManager.isSessionValid() {
            Task {
                await MainActor.run {
                    self.authState = .sessionExpired
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
                sessionManager.clearUserSession()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func setLoadingState(_ loading: Bool) {
        isLoading = loading
        if loading {
            errorMessage = nil
        }
    }
    
    @MainActor
    private func handleAuthError(_ error: AuthError) {
        isLoading = false
        errorMessage = error.localizedDescription
        
        switch error {
        case .sessionExpired:
            authState = .sessionExpired
            isAuthenticated = false
            currentUser = nil
        case .userNotVerified:
            authState = .passwordResetRequired
        default:
            break
        }
    }
    
    private func simulateNetworkDelay(_ seconds: Double = 1.5) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
    
    private func createDemoUser() -> User {
        return User(
            id: "demo-user-id",
            email: "demo@mentorapp.com",
            firstName: "Demo",
            lastName: "User",
            dateJoined: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            subscription: .pro,
            authProvider: .email,
            emailVerified: true,
            profileImageURL: nil,
            bio: "Welcome to the demo! Explore all the features of Mentor App.",
            phoneNumber: nil,
            lastLoginDate: Date(),
            preferences: UserPreferences()
        )
    }
    
    // MARK: - Validation Methods
    
    private func validateRegistrationData(_ data: RegistrationData) throws {
        try validateEmail(data.email)
        try validatePassword(data.password)
        
        if data.firstName.isEmpty || data.lastName.isEmpty {
            throw AuthError.invalidInput("Name fields cannot be empty")
        }
        
        if data.password != data.confirmPassword {
            throw AuthError.passwordMismatch
        }
    }
    
    private func validateCredentials(_ credentials: LoginCredentials) throws {
        try validateEmail(credentials.email)
        
        if credentials.password.isEmpty {
            throw AuthError.invalidInput("Password cannot be empty")
        }
    }
    
    private func validateEmail(_ email: String) throws {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            throw AuthError.invalidEmail
        }
    }
    
    private func validatePassword(_ password: String) throws {
        if password.count < 8 {
            throw AuthError.weakPassword("Password must be at least 8 characters")
        }
        
        let hasUpperCase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowerCase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        
        if !hasUpperCase || !hasLowerCase || !hasNumber {
            throw AuthError.weakPassword("Password must contain uppercase, lowercase, and number")
        }
    }
    
    private func sendVerificationEmail(to email: String) async throws {
        // Simulate sending verification email
        try await simulateNetworkDelay(0.5)
        print("Verification email sent to \(email)")
    }
}

// MARK: - User (User account model)
struct User: Codable, Identifiable {
    let id: String
    var email: String
    var firstName: String
    var lastName: String
    let dateJoined: Date
    var subscription: SubscriptionTier
    var authProvider: AuthProvider
    var emailVerified: Bool
    var profileImageURL: String?
    var bio: String?
    var phoneNumber: String?
    var lastLoginDate: Date?
    var lastUpdated: Date?
    var preferences: UserPreferences
    var deviceTokens: [String] = []
    var timezone: String = TimeZone.current.identifier
    var locale: String = Locale.current.identifier
    
    init(id: String, email: String, firstName: String, lastName: String, dateJoined: Date, subscription: SubscriptionTier, authProvider: AuthProvider = .email, emailVerified: Bool = false, profileImageURL: String? = nil, bio: String? = nil, phoneNumber: String? = nil, lastLoginDate: Date? = nil, preferences: UserPreferences = UserPreferences()) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.dateJoined = dateJoined
        self.subscription = subscription
        self.authProvider = authProvider
        self.emailVerified = emailVerified
        self.profileImageURL = profileImageURL
        self.bio = bio
        self.phoneNumber = phoneNumber
        self.lastLoginDate = lastLoginDate
        self.lastUpdated = Date()
        self.preferences = preferences
    }
    
    var displayName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? email.components(separatedBy: "@").first ?? "User" : name
    }
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var isProfileComplete: Bool {
        return !firstName.isEmpty && !lastName.isEmpty && emailVerified
    }
    
    var accountAge: Int {
        Calendar.current.dateComponents([.day], from: dateJoined, to: Date()).day ?? 0
    }
    
    enum AuthProvider: String, Codable {
        case email = "email"
        case apple = "apple"
        case google = "google"
        case facebook = "facebook"
        
        var displayName: String {
            switch self {
            case .email: return "Email"
            case .apple: return "Apple"
            case .google: return "Google"
            case .facebook: return "Facebook"
            }
        }
        
        var icon: String {
            switch self {
            case .email: return "envelope"
            case .apple: return "applelogo"
            case .google: return "globe"
            case .facebook: return "f.circle"
            }
        }
    }
    
    struct UserPreferences: Codable {
        var biometricAuthEnabled: Bool = false
        var notificationsEnabled: Bool = true
        var emailNotificationsEnabled: Bool = true
        var pushNotificationsEnabled: Bool = true
        var marketingEmailsEnabled: Bool = false
        var dataAnalyticsEnabled: Bool = true
        var language: String = "en"
        var preferredCommunicationTime: String = "morning" // morning, afternoon, evening
        var weeklyReportEnabled: Bool = true
        var dailyReminderEnabled: Bool = true
        var streakReminderEnabled: Bool = true
    }
}

// MARK: - LoginCredentials (Sign-in data)
struct LoginCredentials {
    let email: String
    let password: String
    let rememberMe: Bool
    let deviceId: String?
    
    init(email: String, password: String, rememberMe: Bool = false, deviceId: String? = UIDevice.current.identifierForVendor?.uuidString) {
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.password = password
        self.rememberMe = rememberMe
        self.deviceId = deviceId
    }
    
    var isValid: Bool {
        return !email.isEmpty && !password.isEmpty && isValidEmail
    }
    
    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - RegistrationData (Sign-up data)
struct RegistrationData {
    let email: String
    let password: String
    let confirmPassword: String
    let firstName: String
    let lastName: String
    let phoneNumber: String?
    let authProvider: User.AuthProvider
    let acceptedTerms: Bool
    let acceptedPrivacy: Bool
    let marketingOptIn: Bool
    let referralCode: String?
    
    init(email: String, password: String, confirmPassword: String, firstName: String, lastName: String, phoneNumber: String? = nil, authProvider: User.AuthProvider = .email, acceptedTerms: Bool = false, acceptedPrivacy: Bool = false, marketingOptIn: Bool = false, referralCode: String? = nil) {
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.password = password
        self.confirmPassword = confirmPassword
        self.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phoneNumber = phoneNumber
        self.authProvider = authProvider
        self.acceptedTerms = acceptedTerms
        self.acceptedPrivacy = acceptedPrivacy
        self.marketingOptIn = marketingOptIn
        self.referralCode = referralCode
    }
    
    var isValid: Bool {
        return !email.isEmpty &&
               !password.isEmpty &&
               !firstName.isEmpty &&
               !lastName.isEmpty &&
               password == confirmPassword &&
               acceptedTerms &&
               acceptedPrivacy &&
               isValidEmail &&
               isValidPassword
    }
    
    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private var isValidPassword: Bool {
        return password.count >= 8 &&
               password.rangeOfCharacter(from: .uppercaseLetters) != nil &&
               password.rangeOfCharacter(from: .lowercaseLetters) != nil &&
               password.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    var passwordStrength: PasswordStrength {
        let length = password.count
        let hasUpper = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLower = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
        
        var strength = 0
        if length >= 8 { strength += 1 }
        if length >= 12 { strength += 1 }
        if hasUpper { strength += 1 }
        if hasLower { strength += 1 }
        if hasNumber { strength += 1 }
        if hasSpecial { strength += 1 }
        
        switch strength {
        case 0...2: return .weak
        case 3...4: return .medium
        case 5...6: return .strong
        default: return .weak
        }
    }
    
    enum PasswordStrength {
        case weak, medium, strong
        
        var color: Color {
            switch self {
            case .weak: return .red
            case .medium: return .orange
            case .strong: return .green
            }
        }
        
        var description: String {
            switch self {
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
    }
}

// MARK: - AuthError (Authentication errors)
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case userNotFound
    case userNotVerified
    case accountDisabled
    case accountLocked
    case sessionExpired
    case invalidEmail
    case emailAlreadyExists
    case weakPassword(String)
    case passwordMismatch
    case invalidInput(String)
    case networkError(String)
    case serverError(String)
    case rateLimitExceeded
    case registrationFailed(String)
    case loginFailed(String)
    case biometricNotAvailable
    case biometricAuthFailed
    case twoFactorRequired
    case invalidVerificationCode
    case tokenExpired
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please check your credentials and try again."
        case .userNotFound:
            return "No account found with this email address."
        case .userNotVerified:
            return "Please verify your email address before signing in."
        case .accountDisabled:
            return "Your account has been disabled. Please contact support."
        case .accountLocked:
            return "Account temporarily locked due to multiple failed attempts."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emailAlreadyExists:
            return "An account with this email already exists."
        case .weakPassword(let details):
            return "Password is too weak: \(details)"
        case .passwordMismatch:
            return "Passwords do not match."
        case .invalidInput(let message):
            return message
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .rateLimitExceeded:
            return "Too many attempts. Please try again later."
        case .registrationFailed(let message):
            return "Registration failed: \(message)"
        case .loginFailed(let message):
            return "Login failed: \(message)"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometricAuthFailed:
            return "Biometric authentication failed. Please try again."
        case .twoFactorRequired:
            return "Two-factor authentication is required."
        case .invalidVerificationCode:
            return "Invalid verification code."
        case .tokenExpired:
            return "Authentication token has expired."
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidCredentials:
            return "Incorrect username or password"
        case .userNotFound:
            return "User account does not exist"
        case .networkError:
            return "Unable to connect to server"
        case .sessionExpired:
            return "Authentication session expired"
        default:
            return errorDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Double-check your email and password, or use 'Forgot Password' if needed."
        case .userNotFound:
            return "Sign up for a new account or verify the email address."
        case .userNotVerified:
            return "Check your email for verification link and click it."
        case .sessionExpired:
            return "Please sign in again to continue."
        case .weakPassword:
            return "Use a password with at least 8 characters, including uppercase, lowercase, and numbers."
        case .networkError:
            return "Check your internet connection and try again."
        case .biometricNotAvailable:
            return "Use email and password to sign in instead."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
