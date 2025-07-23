import SwiftUI
import CoreData

// MARK: - Updated App File for Core Data Integration
/*
Update your main MentorApp.swift file to use the enhanced data manager:

@main
struct MentorApp: App {
    let persistenceController = CoreDataStack.shared
    @StateObject private var dataManager = EnhancedDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
                .environmentObject(dataManager)
                .onAppear {
                    // Clean up old data periodically
                    dataManager.cleanupOldData()
                }
        }
    }
}
*/

// MARK: - Enhanced Analytics View
struct AnalyticsView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @State private var selectedPeriod: StatsPeriod = .thisMonth
    @State private var readingStats: ReadingStats?
    @State private var moodTrends: [MoodDataPoint] = []
    @State private var streakData: StreakData?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    periodSelector
                    
                    // Reading Stats Cards
                    if let stats = readingStats {
                        readingStatsSection(stats)
                    }
                    
                    // Mood Trends Chart
                    moodTrendsSection
                    
                    // Streak Visualization
                    if let streak = streakData {
                        streakSection(streak)
                    }
                    
                    // Path Distribution
                    pathDistributionSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadAnalytics()
        }
        .onChange(of: selectedPeriod) { _ in
            loadAnalytics()
        }
    }
    
    private var periodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Period")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StatsPeriod.allCases, id: \.self) { period in
                        Button {
                            selectedPeriod = period
                        } label: {
                            Text(period.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedPeriod == period ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedPeriod == period ? Color.blue : Color(.systemGray5))
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
    }
    
    private func readingStatsSection(_ stats: ReadingStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Books Read",
                    value: "\(stats.booksRead)",
                    subtitle: stats.period.displayName,
                    icon: "book.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Reading Time",
                    value: String(format: "%.1fh", stats.totalReadingHours),
                    subtitle: "\(stats.totalReadingMinutes) minutes",
                    icon: "clock.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Journal Entries",
                    value: "\(stats.journalEntries)",
                    subtitle: "Reflections written",
                    icon: "book.closed.fill",
                    color: .purple
                )
                
                StatCard(
                    title: "Check-ins",
                    value: "\(stats.checkIns)",
                    subtitle: "Daily connections",
                    icon: "message.fill",
                    color: .orange
                )
            }
        }
    }
    
    private var moodTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            if moodTrends.isEmpty {
                Text("Start doing daily check-ins to see mood trends")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                    )
            } else {
                MoodTrendChart(dataPoints: moodTrends)
                    .frame(height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                    )
            }
        }
    }
    
    private func streakSection(_ streak: StreakData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streak Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(streak.currentStreak)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(streak.longestStreak)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("Best Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
    }
    
    private var pathDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Focus Area Distribution")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Show distribution of books by path
            let booksByPath = Dictionary(grouping: dataManager.currentBookRecommendations) { $0.path }
            
            VStack(spacing: 8) {
                ForEach(TrainingPath.allCases) { path in
                    let count = booksByPath[path]?.count ?? 0
                    let total = dataManager.currentBookRecommendations.count
                    let percentage = total > 0 ? Double(count) / Double(total) : 0
                    
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: path.icon)
                                .font(.subheadline)
                                .foregroundColor(path.color)
                            
                            Text(path.displayName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: percentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: path.color))
                        .scaleEffect(y: 1.5)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
    }
    
    private func loadAnalytics() {
        readingStats = dataManager.getReadingStats(for: selectedPeriod)
        moodTrends = dataManager.getMoodTrends(for: 30)
        streakData = dataManager.getStreakData()
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Mood Trend Chart
struct MoodTrendChart: View {
    let dataPoints: [MoodDataPoint]
    
    var body: some View {
        GeometryReader { geometry in
            let maxMood = 5.0
            let minMood = 1.0
            let moodRange = maxMood - minMood
            
            ZStack {
                // Background grid
                VStack {
                    ForEach(1...5, id: \.self) { level in
                        Divider()
                            .opacity(0.3)
                        if level < 5 { Spacer() }
                    }
                }
                
                // Mood line
                if dataPoints.count > 1 {
                    Path { path in
                        for (index, point) in dataPoints.enumerated() {
                            let x = CGFloat(index) / CGFloat(dataPoints.count - 1) * geometry.size.width
                            let y = geometry.size.height - (CGFloat(point.averageMood - minMood) / CGFloat(moodRange) * geometry.size.height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 3)
                    
                    // Data points
                    ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                        let x = CGFloat(index) / CGFloat(dataPoints.count - 1) * geometry.size.width
                        let y = geometry.size.height - (CGFloat(point.averageMood - minMood) / CGFloat(moodRange) * geometry.size.height)
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Enhanced Reading Session View
struct ReadingSessionView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @Environment(\.dismiss) private var dismiss
    let book: BookRecommendation
    @State private var isSessionActive = false
    @State private var sessionStartTime: Date?
    @State private var pagesRead = 0
    @State private var sessionNotes = ""
    @State private var readingProgress: Float = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Book info
                bookInfoSection
                
                // Session controls
                sessionControlsSection
                
                // Progress tracking
                progressSection
                
                // Notes section
                notesSection
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .navigationTitle("Reading Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if isSessionActive {
                            endSession()
                        }
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checkActiveSession()
            loadBookProgress()
        }
    }
    
    private var bookInfoSection: some View {
        HStack(spacing: 16) {
            // Book cover placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(book.path.color)
                .frame(width: 60, height: 90)
                .overlay(
                    Text(book.title.prefix(1))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: book.path.icon)
                        .font(.caption)
                        .foregroundColor(book.path.color)
                    
                    Text(book.path.displayName)
                        .font(.caption)
                        .foregroundColor(book.path.color)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
    
    private var sessionControlsSection: some View {
        VStack(spacing: 16) {
            if isSessionActive {
                VStack(spacing: 8) {
                    Text("Reading Session Active")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    if let startTime = sessionStartTime {
                        Text("Started: \(formatTime(startTime))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button {
                    endSession()
                } label: {
                    Text("End Session")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red)
                        )
                }
            } else {
                Button {
                    startSession()
                } label: {
                    Text("Start Reading Session")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                }
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Pages Read")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Stepper(value: $pagesRead, in: 0...999) {
                        Text("\(pagesRead)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Reading Progress")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(Int(readingProgress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(book.path.color)
                    }
                    
                    Slider(value: $readingProgress, in: 0...1) {
                        Text("Progress")
                    }
                    .accentColor(book.path.color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Notes")
                .font(.headline)
                .fontWeight(.semibold)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(minHeight: 100)
                
                if sessionNotes.isEmpty {
                    Text("Add notes about insights, key quotes, or thoughts...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }
                
                TextEditor(text: $sessionNotes)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
            }
        }
    }
    
    private func checkActiveSession() {
        isSessionActive = dataManager.currentReadingSession?.book?.id == book.id
        sessionStartTime = dataManager.currentReadingSession?.startTime
    }
    
    private func loadBookProgress() {
        // Load existing progress from Core Data
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        if let cdBook = CoreDataStack.shared.fetch(request).first {
            readingProgress = cdBook.readingProgress
        }
    }
    
    private func startSession() {
        dataManager.startReadingSession(for: book.id)
        isSessionActive = true
        sessionStartTime = Date()
    }
    
    private func endSession() {
        dataManager.endCurrentReadingSession(pagesRead: pagesRead, notes: sessionNotes.isEmpty ? nil : sessionNotes)
        
        // Update reading progress
        dataManager.updateReadingProgress(book, progress: readingProgress)
        
        isSessionActive = false
        sessionStartTime = nil
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Data Export View
struct DataExportView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @State private var isExporting = false
    @State private var exportedData: UserDataExport?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Export all your journal entries, reading progress, and app data for backup or transfer.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 12) {
                    exportDataButton
                    
                    if exportedData != nil {
                        shareDataButton
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportedData {
                ActivityViewController(activityItems: [createExportFile(data)])
            }
        }
    }
    
    private var exportDataButton: some View {
        Button {
            exportData()
        } label: {
            HStack {
                if isExporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
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
    }
    
    private var shareDataButton: some View {
        Button {
            showingShareSheet = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Export File")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }
    
    private func exportData() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let exported = dataManager.exportUserData()
            
            DispatchQueue.main.async {
                self.exportedData = exported
                self.isExporting = false
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

// MARK: - Activity View Controller for Sharing
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}