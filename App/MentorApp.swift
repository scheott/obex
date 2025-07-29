import SwiftUI
import CoreData

// MARK: - Main App Entry Point
@main
struct MentorApp: App {
    let persistenceController = CoreDataStack.shared
    @StateObject private var dataManager = EnhancedDataManager()
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
                .environmentObject(dataManager)
                .environmentObject(authManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Initialize app on launch
        dataManager.initializeApp()
        
        // Clean up old data periodically
        dataManager.cleanupOldData()
        
        // Setup notifications if needed
        NotificationManager.shared.requestPermissions()
    }
}

// MARK: - Content View (Main Router)
struct ContentView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if !authManager.isAuthenticated {
                AuthenticationView()
            } else if dataManager.userProfile == nil {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            initializeUserData()
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: dataManager.userProfile != nil)
    }
    
    private func initializeUserData() {
        Task {
            await dataManager.loadInitialData()
            await authManager.checkAuthStatus()
            
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
}

// MARK: - Main Tab View Container
struct MainTabView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @State private var selectedTab: TabSelection = .dashboard
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    TabItemView(
                        icon: "house.fill",
                        title: "Home",
                        isSelected: selectedTab == .dashboard
                    )
                }
                .tag(TabSelection.dashboard)
            
            // Challenge Tab
            ChallengeView()
                .tabItem {
                    TabItemView(
                        icon: "target",
                        title: "Challenge",
                        isSelected: selectedTab == .challenge
                    )
                }
                .tag(TabSelection.challenge)
                .badge(dataManager.todaysChallenge?.isCompleted == false ? "!" : nil)
            
            // Book Station Tab
            BookStationView()
                .tabItem {
                    TabItemView(
                        icon: "book.fill",
                        title: "Books",
                        isSelected: selectedTab == .books
                    )
                }
                .tag(TabSelection.books)
            
            // Check-in Tab
            CheckInView()
                .tabItem {
                    TabItemView(
                        icon: "message.fill",
                        title: "Check-in",
                        isSelected: selectedTab == .checkin
                    )
                }
                .tag(TabSelection.checkin)
                .badge(dataManager.pendingCheckIns.count > 0 ? "\(dataManager.pendingCheckIns.count)" : nil)
            
            // Journal Tab
            JournalView()
                .tabItem {
                    TabItemView(
                        icon: "book.closed.fill",
                        title: "Journal",
                        isSelected: selectedTab == .journal
                    )
                }
                .tag(TabSelection.journal)
        }
        .accentColor(dataManager.userProfile?.selectedPath.color ?? .blue)
        .onAppear {
            setupTabAppearance()
        }
        .onChange(of: selectedTab) { newTab in
            handleTabChange(newTab)
        }
    }
    
    private func setupTabAppearance() {
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func handleTabChange(_ newTab: TabSelection) {
        // Handle tab-specific logic
        switch newTab {
        case .dashboard:
            dataManager.refreshDashboardData()
        case .challenge:
            dataManager.loadTodaysChallenge()
        case .books:
            dataManager.loadBookRecommendations()
        case .checkin:
            dataManager.loadTodaysCheckIns()
        case .journal:
            dataManager.loadRecentJournalEntries()
        }
        
        // Analytics tracking
        AnalyticsManager.shared.trackTabSelection(newTab)
    }
}

// MARK: - Tab Selection Enum
enum TabSelection: String, CaseIterable {
    case dashboard = "dashboard"
    case challenge = "challenge"
    case books = "books"
    case checkin = "checkin"
    case journal = "journal"
    
    var displayName: String {
        switch self {
        case .dashboard: return "Home"
        case .challenge: return "Challenge"
        case .books: return "Books"
        case .checkin: return "Check-in"
        case .journal: return "Journal"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .challenge: return "target"
        case .books: return "book.fill"
        case .checkin: return "message.fill"
        case .journal: return "book.closed.fill"
        }
    }
}

// MARK: - Tab Item View Component
struct TabItemView: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
            Text(title)
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .medium)
        }
        .foregroundColor(isSelected ? .accentColor : .secondary)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App Icon/Logo
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Loading Text
                VStack(spacing: 8) {
                    Text("Mentor")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Preparing your journey...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Loading Indicator
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Authentication View
struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Welcome to Mentor")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Your AI-powered growth companion")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Auth Buttons
                VStack(spacing: 16) {
                    AuthButton(
                        title: "Sign In",
                        isPrimary: true
                    ) {
                        // Handle sign in
                        showingSignUp = false
                    }
                    
                    AuthButton(
                        title: "Create Account",
                        isPrimary: false
                    ) {
                        // Handle sign up
                        showingSignUp = true
                    }
                }
                
                Spacer()
                
                // Terms and Privacy
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Button("Terms of Service") {
                            // Show terms
                        }
                        .font(.caption)
                        
                        Button("Privacy Policy") {
                            // Show privacy policy
                        }
                        .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 40)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - Auth Button Component
struct AuthButton: View {
    let title: String
    let isPrimary: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isPrimary ? .white : .blue)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isPrimary ? Color.blue : Color.blue.opacity(0.1))
                )
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text("Create Your Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Start your growth journey today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Form Fields
                VStack(spacing: 16) {
                    AuthTextField(
                        title: "Email",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                    
                    AuthTextField(
                        title: "Password",
                        text: $password,
                        isSecure: true
                    )
                    
                    AuthTextField(
                        title: "Confirm Password",
                        text: $confirmPassword,
                        isSecure: true
                    )
                }
                
                // Sign Up Button
                Button {
                    signUp()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
                }
                .disabled(isLoading || !isFormValid)
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 40)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        password == confirmPassword &&
        password.count >= 6
    }
    
    private func signUp() {
        isLoading = true
        
        Task {
            do {
                try await authManager.signUp(email: email, password: password)
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                // Handle error
                print("Sign up error: \(error)")
            }
            
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
}

// MARK: - Auth Text Field Component
struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Group {
                if isSecure {
                    SecureField("Enter \(title.lowercased())", text: $text)
                } else {
                    TextField("Enter \(title.lowercased())", text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// MARK: - Enhanced Data Manager Reference
class EnhancedDataManager: ObservableObject {
    // Core Published Properties
    @Published var userProfile: UserProfile?
    @Published var todaysChallenge: DailyChallenge?
    @Published var todaysCheckIns: [AICheckIn] = []
    @Published var pendingCheckIns: [AICheckIn] = []
    @Published var currentBookRecommendations: [BookRecommendation] = []
    @Published var journalEntries: [JournalEntry] = []
    @Published var weeklySummaries: [WeeklySummary] = []
    
    // Loading States
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let coreDataStack = CoreDataStack.shared
    
    // MARK: - Initialization
    func initializeApp() {
        loadUserProfile()
        if userProfile != nil {
            generateTodaysContent()
        }
    }
    
    func loadInitialData() async {
        // Implement initial data loading
    }
    
    func refreshDashboardData() {
        // Refresh dashboard-specific data
    }
    
    func loadTodaysChallenge() {
        // Load today's challenge
    }
    
    func loadBookRecommendations() {
        // Load book recommendations
    }
    
    func loadTodaysCheckIns() {
        // Load check-ins
    }
    
    func loadRecentJournalEntries() {
        // Load journal entries
    }
    
    func cleanupOldData() {
        // Clean up old data
    }
    
    private func loadUserProfile() {
        // Load user profile from Core Data
    }
    
    private func generateTodaysContent() {
        // Generate daily content
    }
}

// MARK: - Supporting Manager Classes
class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermissions() {
        // Request notification permissions
    }
}

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    func trackTabSelection(_ tab: TabSelection) {
        // Track analytics
    }
}
