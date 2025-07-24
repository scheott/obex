import SwiftUI
import StoreKit

// MARK: - Paywall View
struct PaywallView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isProcessing = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    
    enum SubscriptionPlan: String, CaseIterable {
        case monthly = "monthly"
        case yearly = "yearly"
        
        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "$6.99"
            case .yearly: return "$49.99"
            }
        }
        
        var period: String {
            switch self {
            case .monthly: return "per month"
            case .yearly: return "per year"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Save 40%"
            }
        }
        
        var monthlyEquivalent: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "$4.17/month"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.purple.opacity(0.8),
                    Color.blue.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    PaywallHeader()
                    
                    // Features List
                    ProFeaturesView()
                    
                    // Subscription Plans
                    SubscriptionPlansView(selectedPlan: $selectedPlan)
                    
                    // Subscribe Button
                    SubscribeButton(
                        selectedPlan: selectedPlan,
                        isProcessing: $isProcessing,
                        onSubscribe: handleSubscription
                    )
                    
                    // Legal Links
                    LegalLinksView(
                        showingTerms: $showingTerms,
                        showingPrivacy: $showingPrivacy
                    )
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
            }
        }
        .navigationBarItems(trailing: Button("×") {
            presentationMode.wrappedValue.dismiss()
        }
        .font(.title2)
        .foregroundColor(.white))
        .sheet(isPresented: $showingTerms) {
            LegalDocumentView(type: .terms)
        }
        .sheet(isPresented: $showingPrivacy) {
            LegalDocumentView(type: .privacy)
        }
    }
    
    private func handleSubscription() {
        isProcessing = true
        
        // Simulate subscription process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Update user subscription status
            authManager.currentUser?.subscription = .pro
            
            // Save updated user session
            if let user = authManager.currentUser,
               let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "user_session")
            }
            
            isProcessing = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Paywall Header
struct PaywallHeader: View {
    var body: some View {
        VStack(spacing: 20) {
            // Crown icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.yellow.opacity(0.3),
                                Color.orange.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
            }
            
            VStack(spacing: 12) {
                Text("Unlock Your Full Potential")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Get unlimited access to all training paths, AI insights, and premium features")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Pro Features View
struct ProFeaturesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("What's Included")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "infinity",
                    title: "All Training Paths",
                    description: "Access all 5 training paths and switch anytime",
                    color: .blue
                )
                
                FeatureRow(
                    icon: "brain.head.profile",
                    title: "Advanced AI Insights",
                    description: "Personalized feedback and weekly progress summaries",
                    color: .purple
                )
                
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Detailed Analytics",
                    description: "Track patterns, streaks, and optimize your growth",
                    color: .green
                )
                
                FeatureRow(
                    icon: "book.fill",
                    title: "Premium Content",
                    description: "Exclusive book recommendations and deep insights",
                    color: .orange
                )
                
                FeatureRow(
                    icon: "shield.fill",
                    title: "Streak Insurance",
                    description: "Bank streak days to protect your progress",
                    color: .red
                )
                
                FeatureRow(
                    icon: "square.and.arrow.up",
                    title: "Export & Backup",
                    description: "Export your journal entries and progress data",
                    color: .teal
                )
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Subscription Plans View
struct SubscriptionPlansView: View {
    @Binding var selectedPlan: PaywallView.SubscriptionPlan
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(PaywallView.SubscriptionPlan.allCases, id: \.self) { plan in
                    SubscriptionPlanCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPlan = plan
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Subscription Plan Card
struct SubscriptionPlanCard: View {
    let plan: PaywallView.SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .white : .primary)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(plan.price)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .white : .primary)
                        
                        Text(plan.period)
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                    
                    if let monthlyEquivalent = plan.monthlyEquivalent {
                        Text(monthlyEquivalent)
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.6) : .secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Subscribe Button
struct SubscribeButton: View {
    let selectedPlan: PaywallView.SubscriptionPlan
    @Binding var isProcessing: Bool
    let onSubscribe: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onSubscribe) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(0.8)
                    } else {
                        Text("Start Your Journey")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white)
                .cornerRadius(16)
            }
            .disabled(isProcessing)
            .scaleEffect(isProcessing ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isProcessing)
            
            Text("3-day free trial, then \(selectedPlan.price) \(selectedPlan.period)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Legal Links View
struct LegalLinksView: View {
    @Binding var showingTerms: Bool
    @Binding var showingPrivacy: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Cancel anytime. No commitments.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 20) {
                Button("Terms of Service") {
                    showingTerms = true
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                
                Button("Privacy Policy") {
                    showingPrivacy = true
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                
                Button("Restore") {
                    // Handle restore purchases
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Feature Gate View
struct FeatureGateView: View {
    let feature: GatedFeature
    @State private var showingPaywall = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.3),
                                Color.blue.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.purple)
                    
                    Text("Pro Feature")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            VStack(spacing: 12) {
                Text(feature.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: { showingPaywall = true }) {
                Text("Upgrade to Pro")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Subscription Management View
struct SubscriptionManagementView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingCancelConfirmation = false
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Plan Section
                    CurrentPlanView()
                    
                    // Subscription Benefits
                    SubscriptionBenefitsView()
                    
                    // Billing Information
                    BillingInformationView()
                    
                    // Manage Subscription
                    ManageSubscriptionView(
                        showingCancelConfirmation: $showingCancelConfirmation,
                        showingPaywall: $showingPaywall
                    )
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .alert("Cancel Subscription", isPresented: $showingCancelConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, Cancel", role: .destructive) {
                cancelSubscription()
            }
        } message: {
            Text("Are you sure you want to cancel your subscription? You'll lose access to Pro features at the end of your current billing period.")
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(authManager)
        }
    }
    
    private func cancelSubscription() {
        // Handle subscription cancellation
        authManager.currentUser?.subscription = .free
        
        // Save updated user session
        if let user = authManager.currentUser,
           let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "user_session")
        }
    }
}

// MARK: - Current Plan View
struct CurrentPlanView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Plan")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(authManager.currentUser?.subscription.displayName ?? "Free")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if authManager.currentUser?.subscription == .pro {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(planDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if authManager.currentUser?.subscription == .pro {
                        Text("Renews on December 15, 2024")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if authManager.currentUser?.subscription == .free {
                    Text("$0")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                } else {
                    Text("$49.99")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var planDescription: String {
        if authManager.currentUser?.subscription == .pro {
            return "Full access to all features and training paths"
        } else {
            return "Limited access to features and one training path"
        }
    }
}

// MARK: - Subscription Benefits View
struct SubscriptionBenefitsView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Benefits")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                BenefitRow(
                    icon: "checkmark.circle.fill",
                    title: "All Training Paths",
                    isIncluded: authManager.currentUser?.subscription == .pro,
                    color: .green
                )
                
                BenefitRow(
                    icon: "brain.head.profile",
                    title: "AI Insights & Summaries",
                    isIncluded: authManager.currentUser?.subscription == .pro,
                    color: .purple
                )
                
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Advanced Analytics",
                    isIncluded: authManager.currentUser?.subscription == .pro,
                    color: .blue
                )
                
                BenefitRow(
                    icon: "shield.fill",
                    title: "Streak Insurance",
                    isIncluded: authManager.currentUser?.subscription == .pro,
                    color: .orange
                )
                
                BenefitRow(
                    icon: "square.and.arrow.up",
                    title: "Export & Backup",
                    isIncluded: authManager.currentUser?.subscription == .pro,
                    color: .teal
                )
            }
        }
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let icon: String
    let title: String
    let isIncluded: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isIncluded ? icon : "xmark.circle.fill")
                .font(.title3)
                .foregroundColor(isIncluded ? color : .gray)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(isIncluded ? .primary : .secondary)
            
            Spacer()
            
            if isIncluded {
                Text("Included")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            } else {
                Text("Pro Only")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Billing Information View
struct BillingInformationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Billing Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Payment Method")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                        Text("•••• 4242")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                HStack {
                    Text("Next Billing Date")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("Dec 15, 2024")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                HStack {
                    Text("Amount")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("$49.99")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Manage Subscription View
struct ManageSubscriptionView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showingCancelConfirmation: Bool
    @Binding var showingPaywall: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage Subscription")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if authManager.currentUser?.subscription == .free {
                    Button(action: { showingPaywall = true }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Upgrade to Pro")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: { /* Handle plan change */ }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                            Text("Change Plan")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showingCancelConfirmation = true }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                            Text("Cancel Subscription")
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: { /* Handle billing history */ }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.gray)
                        Text("Billing History")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Legal Document View
struct LegalDocumentView: View {
    let type: DocumentType
    @Environment(\.presentationMode) var presentationMode
    
    enum DocumentType {
        case terms, privacy
        
        var title: String {
            switch self {
            case .terms: return "Terms of Service"
            case .privacy: return "Privacy Policy"
            }
        }
        
        var content: String {
            switch self {
            case .terms: return termsContent
            case .privacy: return privacyContent
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(type.content)
                    .font(.body)
                    .padding(20)
            }
            .navigationTitle(type.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var termsContent: String {
        """
        Terms of Service
        
        Last updated: [Date]
        
        1. Acceptance of Terms
        By downloading, installing, or using our app, you agree to be bound by these Terms of Service.
        
        2. Description of Service
        Our app provides AI-powered mentorship and personal development tools to help users build discipline, clarity, confidence, and purpose.
        
        3. Subscription Terms
        - Monthly and yearly subscription options are available
        - Subscriptions automatically renew unless cancelled
        - You may cancel at any time through your device's subscription settings
        
        4. User Responsibilities
        - Provide accurate information
        - Use the service in accordance with applicable laws
        - Maintain the security of your account
        
        5. Privacy
        Your privacy is important to us. Please review our Privacy Policy to understand how we collect and use your information.
        
        6. Limitation of Liability
        The service is provided "as is" and we disclaim all warranties and conditions.
        
        7. Changes to Terms
        We may update these terms from time to time. Continued use constitutes acceptance of new terms.
        
        For questions about these terms, please contact us at support@mentorapp.com
        """
    }
    
    private var privacyContent: String {
        """
        Privacy Policy
        
        Last updated: [Date]
        
        1. Information We Collect
        - Account information (email, name)
        - Usage data and app interactions
        - Progress and completion data
        - Device information
        
        2. How We Use Your Information
        - Provide and improve our services
        - Personalize your experience
        - Send important updates and notifications
        - Analyze usage patterns
        
        3. Information Sharing
        We do not sell or rent your personal information. We may share data with:
        - Service providers who help operate our app
        - When required by law
        
        4. Data Security
        We implement appropriate security measures to protect your information.
        
        5. Your Rights
        You have the right to:
        - Access your personal data
        - Correct inaccurate information
        - Delete your account and data
        - Export your data
        
        6. Children's Privacy
        Our service is not intended for children under 13.
        
        7. International Users
        Your information may be transferred to and stored in countries other than your own.
        
        8. Changes to Privacy Policy
        We will notify you of any material changes to this policy.
        
        Contact us at privacy@mentorapp.com with any questions.
        """
    }
}

// MARK: - Supporting Models

// Gated Feature Model
struct GatedFeature {
    let title: String
    let description: String
    let icon: String
    let requiredTier: SubscriptionTier
}

// Common Gated Features
extension GatedFeature {
    static let allPaths = GatedFeature(
        title: "All Training Paths",
        description: "Access all 5 training paths and switch between them anytime to focus on different areas of growth.",
        icon: "infinity",
        requiredTier: .pro
    )
    
    static let aiInsights = GatedFeature(
        title: "AI Insights & Weekly Summaries",
        description: "Get personalized AI-powered feedback on your progress and detailed weekly summaries of your growth.",
        icon: "brain.head.profile",
        requiredTier: .pro
    )
    
    static let analytics = GatedFeature(
        title: "Advanced Analytics",
        description: "Track detailed patterns, analyze your streaks, and get insights to optimize your personal development journey.",
        icon: "chart.line.uptrend.xyaxis",
        requiredTier: .pro
    )
    
    static let streakInsurance = GatedFeature(
        title: "Streak Insurance",
        description: "Bank streak days to protect your progress when life gets in the way. Never lose your momentum again.",
        icon: "shield.fill",
        requiredTier: .pro
    )
    
    static let exportData = GatedFeature(
        title: "Export & Backup",
        description: "Export your journal entries, progress data, and insights. Keep your personal development journey with you forever.",
        icon: "square.and.arrow.up",
        requiredTier: .pro
    )
}

// MARK: - Pro Feature Checker
struct ProFeatureChecker {
    static func hasAccess(to feature: GatedFeature, userTier: SubscriptionTier) -> Bool {
        switch userTier {
        case .free:
            return feature.requiredTier == .free
        case .pro:
            return true
        }
    }
    
    static func gateFeature<Content: View>(
        feature: GatedFeature,
        userTier: SubscriptionTier,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Group {
            if hasAccess(to: feature, userTier: userTier) {
                content()
            } else {
                FeatureGateView(feature: feature)
            }
        }
    }
}

// MARK: - Subscription Status Banner
struct SubscriptionStatusBanner: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingPaywall = false
    
    var body: some View {
        if authManager.currentUser?.subscription == .free {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Pro")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Unlock all training paths and AI insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Upgrade") {
                    showingPaywall = true
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Free Trial Badge
struct FreeTrialBadge: View {
    let daysRemaining: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .foregroundColor(.orange)
            
            Text("\(daysRemaining) days left in trial")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Usage Limit Banner
struct UsageLimitBanner: View {
    let feature: String
    let used: Int
    let limit: Int
    @State private var showingPaywall = false
    
    private var isNearLimit: Bool {
        Double(used) / Double(limit) >= 0.8
    }
    
    var body: some View {
        if isNearLimit {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Usage Limit Warning")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("You've used \(used) of \(limit) \(feature) this month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Upgrade") {
                    showingPaywall = true
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange)
                .cornerRadius(8)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}

// MARK: - Subscription Helper Functions
extension SubscriptionTier {
    var features: [String] {
        switch self {
        case .free:
            return [
                "1 training path",
                "Basic challenges",
                "Simple progress tracking",
                "Community support"
            ]
        case .pro:
            return [
                "All 5 training paths",
                "AI-powered insights",
                "Advanced analytics",
                "Streak insurance",
                "Premium content",
                "Export & backup",
                "Priority support"
            ]
        }
    }
    
    var limits: SubscriptionLimits {
        switch self {
        case .free:
            return SubscriptionLimits(
                trainingPaths: 1,
                challengesPerMonth: 30,
                aiInsightsPerMonth: 0,
                bookRecommendationsPerMonth: 5,
                journalExports: 0
            )
        case .pro:
            return SubscriptionLimits(
                trainingPaths: 5,
                challengesPerMonth: -1, // Unlimited
                aiInsightsPerMonth: -1, // Unlimited
                bookRecommendationsPerMonth: -1, // Unlimited
                journalExports: -1 // Unlimited
            )
        }
    }
}

struct SubscriptionLimits {
    let trainingPaths: Int
    let challengesPerMonth: Int // -1 for unlimited
    let aiInsightsPerMonth: Int // -1 for unlimited
    let bookRecommendationsPerMonth: Int // -1 for unlimited
    let journalExports: Int // -1 for unlimited
    
    func isUnlimited(_ value: Int) -> Bool {
        return value == -1
    }
}

// MARK: - Subscription Utilities
class SubscriptionManager: ObservableObject {
    @Published var hasActiveSubscription = false
    @Published var currentTier: SubscriptionTier = .free
    @Published var trialDaysRemaining: Int = 0
    @Published var isInTrial = false
    
    func checkSubscriptionStatus() {
        // In a real app, this would check with StoreKit
        // For now, we'll use the auth manager's user data
    }
    
    func restorePurchases() async {
        // Handle restore purchases with StoreKit
    }
    
    func purchaseSubscription(plan: PaywallView.SubscriptionPlan) async -> Bool {
        // Handle purchase with StoreKit
        return true
    }
    
    func cancelSubscription() {
        // Handle cancellation
        currentTier = .free
        hasActiveSubscription = false
    }
}

// MARK: - In-App Purchase Products
struct IAPProduct {
    let id: String
    let price: String
    let period: String
    let savings: String?
    
    static let monthlyPro = IAPProduct(
        id: "com.mentorapp.pro.monthly",
        price: "$6.99",
        period: "month",
        savings: nil
    )
    
    static let yearlyPro = IAPProduct(
        id: "com.mentorapp.pro.yearly",
        price: "$49.99",
        period: "year",
        savings: "Save 40%"
    )
}

// MARK: - Feature Access Modifiers
extension View {
    func requiresPro(
        feature: GatedFeature,
        userTier: SubscriptionTier
    ) -> some View {
        ProFeatureChecker.gateFeature(
            feature: feature,
            userTier: userTier
        ) {
            self
        }
    }
    
    func showSubscriptionBanner(if condition: Bool = true) -> some View {
        VStack(spacing: 0) {
            if condition {
                SubscriptionStatusBanner()
                    .padding(.bottom, 16)
            }
            self
        }
    }
    
    func showUsageLimit(
        feature: String,
        used: Int,
        limit: Int
    ) -> some View {
        VStack(spacing: 0) {
            UsageLimitBanner(feature: feature, used: used, limit: limit)
                .padding(.bottom, 16)
            self
        }
    }
}

// MARK: - Example Usage Components

// Example: Gated Training Path Selection
struct GatedTrainingPathView: View {
    @EnvironmentObject var authManager: AuthManager
    let paths: [TrainingPath]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(paths.enumerated()), id: \.element) { index, path in
                if index == 0 || authManager.currentUser?.subscription == .pro {
                    // First path is always free, rest require Pro
                    TrainingPathCard(path: path)
                } else {
                    TrainingPathCard(path: path)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    VStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.white)
                                        Text("Pro Only")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                )
                        )
                        .onTapGesture {
                            // Show paywall
                        }
                }
            }
        }
    }
}

// Training Path Card Component
struct TrainingPathCard: View {
    let path: TrainingPath
    
    var body: some View {
        HStack {
            Image(systemName: path.icon)
                .foregroundColor(path.color)
            Text(path.displayName)
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Usage Examples

// Example of how to use feature gating in your app
struct ExampleFeatureGatingUsage: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Show subscription banner for free users
            Text("Your Dashboard")
                .font(.largeTitle)
                .showSubscriptionBanner(if: authManager.currentUser?.subscription == .free)
            
            // Gate a specific feature
            VStack {
                Text("Analytics")
                    .font(.title2)
            }
            .requiresPro(
                feature: .analytics,
                userTier: authManager.currentUser?.subscription ?? .free
            )
            
            // Show usage limits
            VStack {
                Text("AI Insights")
                    .font(.title2)
            }
            .showUsageLimit(feature: "AI insights", used: 8, limit: 10)
        }
    }
}

// MARK: - Preview
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
            .environmentObject(AuthManager())
    }
}

struct SubscriptionManagementView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionManagementView()
            .environmentObject(AuthManager())
    }
}

struct FeatureGateView_Previews: PreviewProvider {
    static var previews: some View {
        FeatureGateView(feature: .aiInsights)
    }
}