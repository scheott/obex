import Foundation
import SwiftUI

// MARK: - Core Data Models

// Training Path Types
enum TrainingPath: String, CaseIterable, Identifiable {
    case discipline = "discipline"
    case clarity = "clarity"
    case confidence = "confidence"
    case purpose = "purpose"
    case authenticity = "authenticity"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .discipline: return "Discipline"
        case .clarity: return "Clarity"
        case .confidence: return "Confidence"
        case .purpose: return "Purpose"
        case .authenticity: return "Authenticity"
        }
    }
    
    var description: String {
        switch self {
        case .discipline: return "Build consistency, willpower, and routines"
        case .clarity: return "Develop mindset, emotional regulation, and focus"
        case .confidence: return "Enhance social leadership, voice, and courage"
        case .purpose: return "Clarify values, long-term thinking, and direction"
        case .authenticity: return "Embrace your true self and genuine expression"
        }
    }
    
    var icon: String {
        switch self {
        case .discipline: return "target"
        case .clarity: return "brain.head.profile"
        case .confidence: return "person.badge.plus"
        case .purpose: return "compass"
        case .authenticity: return "heart"
        }
    }
    
    var color: Color {
        switch self {
        case .discipline: return .red
        case .clarity: return .blue
        case .confidence: return .orange
        case .purpose: return .purple
        case .authenticity: return .green
        }
    }
}

// User Profile Model
struct UserProfile: Codable, Identifiable {
    let id = UUID()
    var selectedPath: TrainingPath
    var joinDate: Date
    var currentStreak: Int
    var longestStreak: Int
    var totalChallengesCompleted: Int
    var subscriptionTier: SubscriptionTier
    var streakBankDays: Int // For streak insurance feature
    
    init(selectedPath: TrainingPath = .discipline) {
        self.selectedPath = selectedPath
        self.joinDate = Date()
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalChallengesCompleted = 0
        self.subscriptionTier = .free
        self.streakBankDays = 0
    }
}

// Subscription Tiers
enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        }
    }
    
    var monthlyPrice: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$6.99/month"
        }
    }
    
    var yearlyPrice: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$49/year"
        }
    }
}

// Daily Challenge Model
struct DailyChallenge: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let path: TrainingPath
    let difficulty: ChallengeDifficulty
    let date: Date
    var isCompleted: Bool = false
    var completedAt: Date?
    
    enum ChallengeDifficulty: String, Codable, CaseIterable {
        case micro = "micro"     // 2-minute challenges
        case standard = "standard"
        case advanced = "advanced"
        
        var displayName: String {
            switch self {
            case .micro: return "Micro (2 min)"
            case .standard: return "Standard"
            case .advanced: return "Advanced"
            }
        }
    }
}

// AI Check-in Model
struct AICheckIn: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let timeOfDay: CheckInTime
    let prompt: String
    var userResponse: String?
    var aiResponse: String?
    var mood: MoodRating?
    var effortLevel: Int? // 1-5 scale
    
    enum CheckInTime: String, Codable {
        case morning = "morning"
        case evening = "evening"
        
        var displayName: String {
            switch self {
            case .morning: return "Morning"
            case .evening: return "Evening"
            }
        }
    }
    
    enum MoodRating: String, Codable, CaseIterable {
        case low = "low"
        case neutral = "neutral"
        case good = "good"
        case great = "great"
        case excellent = "excellent"
        
        var emoji: String {
            switch self {
            case .low: return "😔"
            case .neutral: return "😐"
            case .good: return "🙂"
            case .great: return "😊"
            case .excellent: return "🎉"
            }
        }
    }
}

// Book Recommendation Model
struct BookRecommendation: Identifiable, Codable {
    let id = UUID()
    let title: String
    let author: String
    let path: TrainingPath
    let summary: String
    let keyInsight: String
    let dailyAction: String
    let coverImageURL: String?
    let amazonURL: String?
    let dateAdded: Date
    var isSaved: Bool = false
    var isRead: Bool = false
}

// Journal Entry Model
struct JournalEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let content: String
    let prompt: String?
    let mood: AICheckIn.MoodRating?
    var tags: [String] = []
    var isSavedToSelf: Bool = false
    var isMarkedForReread: Bool = false
}

// Weekly Summary Model (AI Generated)
struct WeeklySummary: Identifiable, Codable {
    let id = UUID()
    let weekStartDate: Date
    let weekEndDate: Date
    let summary: String
    let keyThemes: [String]
    let challengesCompleted: Int
    let checkinStreak: Int
    let recommendedFocus: TrainingPath?
}
