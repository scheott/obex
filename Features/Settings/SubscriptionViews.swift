import SwiftUI
import StoreKit

// MARK: - SubscriptionView (Subscription management)
struct SubscriptionView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingCancelConfirmation = false
    @State private var isLoading = false
    @State private var selectedPlan: SubscriptionTier = .pro
    
    private var currentTier: SubscriptionTier {
        authManager.currentUser?.subscription ?? .free
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    subscriptionHeader
                    
                    // Current Plan
                    if currentTier != .free {
                        currentPlanSection
                    }
                    
                    // Tier Comparison
                    tierComparisonSection
                    
                    // Features List
                    featuresSection
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    // Terms & Privacy
                    termsSection
                    
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
    }
    
    private var subscriptionHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Unlock Your Full Potential")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Access all training paths, unlimited challenges, and AI-powered insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var currentPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Plan")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(currentTier.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if currentTier != .free {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                        }
                    }
                    
                    Text(currentTier.monthlyPrice)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if currentTier != .free {
                    Button("Manage") {
                        showingCancelConfirmation = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private var tierComparisonSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Choose Your Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
                TierComparisonCard(
                    tier: .free,
                    isSelected: currentTier == .free,
                    isCurrentPlan: currentTier == .free,
                    action: { selectedPlan = .free }
                )
                
                TierComparisonCard(
                    tier: .pro,
                    isSelected: selectedPlan == .pro || currentTier == .pro,
                    isCurrentPlan: currentTier == .pro,
                    isRecommended: true,
                    action: { selectedPlan = .pro }
                )
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "infinity",
                    title: "All Training Paths",
                    description: "Access all 5 paths and switch anytime",
                    isPro: true
                )
                
                FeatureRow(
                    icon: "target",
                    title: "Unlimited Challenges",
                    description: "Daily personalized challenges",
                    isPro: true
                )
                
                FeatureRow(
                    icon: "brain.head.profile",
                    title: "AI Insights & Summaries",
                    description: "Weekly AI-powered progress analysis",
                    isPro: true
                )
                
                FeatureRow(
                    icon: "shield.fill",
                    title: "Streak Insurance",
                    description: "Bank streak days for protection",
                    isPro: true
                )
                
                FeatureRow(
                    icon: "square.and.arrow.up",
                    title: "Data Export",
                    description: "Export your progress and journals",
                    isPro: true
                )
                
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Advanced Analytics",
                    description: "Detailed progress tracking",
                    isPro: true
                )
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if currentTier == .free {
                UpgradeButton(
                    tier: selectedPlan,
                    isLoading: isLoading,
                    action: upgradeSubscription
                )
            }
            
            if currentTier != .free {
                Button("Restore Purchases") {
                    restorePurchases()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
    }
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Terms of Service") {
                    // Open terms
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Text("Subscriptions automatically renew unless cancelled. Cancel anytime in Settings.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Actions
    private func upgradeSubscription() {
        isLoading = true
        
        Task {
            // Simulate subscription purchase
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                authManager.currentUser?.subscription = selectedPlan
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func cancelSubscription() {
        authManager.currentUser?.subscription = .free
        
        // Save updated user session
        if let user = authManager.currentUser,
           let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "user_session")
        }
    }
    
    private func restorePurchases() {
        // Handle restore purchases
    }
}

// MARK: - TierComparisonCard (Free vs Pro comparison)
struct TierComparisonCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let isCurrentPlan: Bool
    var isRecommended: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Text(tier.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        if isRecommended {
                            Text("POPULAR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                )
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tier.monthlyPrice)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if tier != .free {
                                Text(tier.yearlyPrice)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(tier.features.prefix(4).enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(tier == .free ? .green : .purple)
                                .font(.caption)
                            
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    
                    if tier.features.count > 4 {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                            
                            Text("\(tier.features.count - 4) more features")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
                
                // Current plan indicator
                if isCurrentPlan {
                    Text("Current Plan")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                } else {
                    Spacer(minLength: 24)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? (tier == .free ? Color.green : Color.purple) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - FeatureRow (Feature listings)
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isPro: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPro ? Color.purple.opacity(0.15) : Color.green.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isPro ? .purple : .green)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if isPro {
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(Color.purple)
                            )
                    }
                    
                    Spacer()
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - BillingCard (Payment information)
struct BillingCard: View {
    let isMonthly: Bool
    let price: String
    let savings: String?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isMonthly ? "Monthly" : "Yearly")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text(price)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        if let savings = savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.2))
                                )
                        }
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.secondary, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - UpgradeButton (Subscription upgrade)
struct UpgradeButton: View {
    let tier: SubscriptionTier
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "crown.fill")
                }
                
                Text(isLoading ? "Processing..." : "Upgrade to \(tier.displayName)")
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.purple, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
}

// MARK: - Paywall View (Alternative upgrade flow)
struct PaywallView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedBilling: BillingPeriod = .yearly
    @State private var isLoading = false
    
    enum BillingPeriod: CaseIterable {
        case monthly, yearly
        
        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "$6.99/month"
            case .yearly: return "$49/year"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Save 41%"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Unlock Pro Features")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Transform your growth with unlimited access to all training paths and AI insights.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Features
                ScrollView {
                    VStack(spacing: 20) {
                        // Billing Options
                        VStack(spacing: 12) {
                            ForEach(BillingPeriod.allCases, id: \.self) { period in
                                BillingCard(
                                    isMonthly: period == .monthly,
                                    price: period.price,
                                    savings: period.savings,
                                    isSelected: selectedBilling == period,
                                    action: { selectedBilling = period }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Features List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Everything in Pro:")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                FeatureRow(
                                    icon: "infinity",
                                    title: "All Training Paths",
                                    description: "Switch between all 5 paths anytime",
                                    isPro: true
                                )
                                
                                FeatureRow(
                                    icon: "target",
                                    title: "Unlimited Daily Challenges",
                                    description: "Never run out of growth opportunities",
                                    isPro: true
                                )
                                
                                FeatureRow(
                                    icon: "brain.head.profile",
                                    title: "AI Insights & Weekly Summaries",
                                    description: "Personalized feedback on your progress",
                                    isPro: true
                                )
                                
                                FeatureRow(
                                    icon: "shield.fill",
                                    title: "Streak Insurance",
                                    description: "Protect your progress when life happens",
                                    isPro: true
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                // Action Button
                VStack(spacing: 16) {
                    UpgradeButton(
                        tier: .pro,
                        isLoading: isLoading,
                        action: startTrial
                    )
                    .padding(.horizontal, 20)
                    
                    Button("Restore Purchases") {
                        // Handle restore
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    
                    VStack(spacing: 4) {
                        Text("Cancel anytime. Terms apply.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button("Terms") { }
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Privacy") { }
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func startTrial() {
        isLoading = true
        
        Task {
            // Simulate purchase process
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                authManager.currentUser?.subscription = .pro
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Preview
struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
            .environmentObject(AuthManager())
    }
}
