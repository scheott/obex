import SwiftUI
import CoreData

// MARK: - Main Book Station View
struct BookStationView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @State private var selectedTab: BookTab = .discover
    @State private var selectedBook: BookRecommendation?
    @State private var showingBookDetail = false
    @State private var showingReadingSession = false
    @State private var searchText = ""
    @State private var selectedGenre: BookRecommendation.BookGenre?
    @State private var showingGoals = false
    @State private var featuredBook: BookRecommendation?
    @State private var dailyInsight: DailyBookInsight?
    @State private var showingHighlights = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search and profile
                headerSection
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        switch selectedTab {
                        case .discover:
                            discoverContent
                        case .library:
                            libraryContent
                        case .insights:
                            insightsContent
                        case .goals:
                            goalsContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .refreshable {
                await refreshBookData()
            }
        }
        .sheet(isPresented: $showingBookDetail) {
            if let book = selectedBook {
                BookDetailView(book: book)
                    .environmentObject(dataManager)
            }
        }
        .sheet(isPresented: $showingReadingSession) {
            if let book = selectedBook {
                ReadingSessionView(book: book)
                    .environmentObject(dataManager)
            }
        }
        .sheet(isPresented: $showingGoals) {
            ReadingGoalsView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingHighlights) {
            HighlightsView()
                .environmentObject(dataManager)
        }
        .onAppear {
            setupBookStation()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title and stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Book Station")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let streak = dataManager.readingStreak, streak > 0 {
                        Text("\(streak) day reading streak 🔥")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Reading stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(dataManager.booksReadThisMonth)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    
                    Text("books this month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search books, authors, or topics...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(.regularMaterial)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BookTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        count: tabCount(for: tab)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Discover Content
    private var discoverContent: some View {
        VStack(spacing: 24) {
            // Featured book of the day
            if let featured = featuredBook {
                featuredBookSection(featured)
            }
            
            // Daily insight
            if let insight = dailyInsight {
                dailyInsightSection(insight)
            }
            
            // Genre filter
            genreFilterSection
            
            // Recommended books grid
            recommendationsGrid
            
            // Quick actions
            quickActionsSection
        }
    }
    
    // MARK: - Library Content
    private var libraryContent: some View {
        VStack(spacing: 24) {
            // Library stats
            libraryStatsSection
            
            // Currently reading
            if !dataManager.currentlyReadingBooks.isEmpty {
                currentlyReadingSection
            }
            
            // Reading progress
            readingProgressSection
            
            // Saved books
            savedBooksSection
            
            // Completed books
            completedBooksSection
        }
    }
    
    // MARK: - Insights Content
    private var insightsContent: some View {
        VStack(spacing: 24) {
            // Reading analytics
            readingAnalyticsSection
            
            // Highlights collection
            highlightsSection
            
            // Reading patterns
            readingPatternsSection
            
            // Book recommendations based on reading history
            personalizedRecommendationsSection
        }
    }
    
    // MARK: - Goals Content
    private var goalsContent: some View {
        VStack(spacing: 24) {
            // Active goals
            activeGoalsSection
            
            // Monthly challenge
            monthlyReadingChallengeSection
            
            // Reading streaks
            readingStreaksSection
            
            // Achievement badges
            achievementBadgesSection
        }
    }
    
    // MARK: - Featured Book Section
    private func featuredBookSection(_ book: BookRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("📖 Featured Book")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Book of the Day")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(book.path.color.opacity(0.2))
                    .foregroundColor(book.path.color)
                    .cornerRadius(8)
            }
            
            BookCard(
                book: book,
                style: .featured,
                onTap: {
                    selectedBook = book
                    showingBookDetail = true
                },
                onSave: {
                    Task {
                        await dataManager.toggleBookSaved(book)
                    }
                },
                onStartReading: {
                    selectedBook = book
                    showingReadingSession = true
                }
            )
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(20)
    }
    
    // MARK: - Daily Insight Section
    private func dailyInsightSection(_ insight: DailyBookInsight) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("💡 Daily Wisdom")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(insight.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .italic()
                    .lineSpacing(4)
                
                HStack {
                    Text("From: \(insight.bookTitle)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(insight.category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
                
                if let action = insight.actionItem {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's Action:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(action)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill((dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.1))
                            )
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Genre Filter Section
    private var genreFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Genre")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    GenreFilterPill(
                        genre: nil,
                        title: "All",
                        isSelected: selectedGenre == nil
                    ) {
                        selectedGenre = nil
                    }
                    
                    ForEach(BookRecommendation.BookGenre.allCases, id: \.self) { genre in
                        GenreFilterPill(
                            genre: genre,
                            title: genre.displayName,
                            isSelected: selectedGenre == genre
                        ) {
                            selectedGenre = genre
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Recommendations Grid
    private var recommendationsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended for You")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Refresh") {
                    Task {
                        await refreshRecommendations()
                    }
                }
                .font(.subheadline)
                .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(filteredRecommendations) { book in
                    BookCard(
                        book: book,
                        style: .compact,
                        onTap: {
                            selectedBook = book
                            showingBookDetail = true
                        },
                        onSave: {
                            Task {
                                await dataManager.toggleBookSaved(book)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "Reading Goals",
                    icon: "target",
                    color: .green
                ) {
                    showingGoals = true
                }
                
                QuickActionCard(
                    title: "My Highlights",
                    icon: "highlighter",
                    color: .yellow
                ) {
                    showingHighlights = true
                }
                
                QuickActionCard(
                    title: "Reading Timer",
                    icon: "timer",
                    color: .orange
                ) {
                    // Start reading session with no specific book
                    showingReadingSession = true
                }
                
                QuickActionCard(
                    title: "Book Notes",
                    icon: "note.text",
                    color: .purple
                ) {
                    // Navigate to notes view
                }
            }
        }
    }
    
    // MARK: - Library Stats Section
    private var libraryStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Library Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Saved",
                    count: dataManager.savedBooksCount,
                    icon: "heart.fill",
                    color: .red
                )
                
                StatCard(
                    title: "Reading",
                    count: dataManager.currentlyReadingBooks.count,
                    icon: "book.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Completed",
                    count: dataManager.completedBooksCount,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Currently Reading Section
    private var currentlyReadingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Currently Reading")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(dataManager.currentlyReadingBooks) { book in
                        ReadingProgressCard(
                            book: book,
                            onContinueReading: {
                                selectedBook = book
                                showingReadingSession = true
                            },
                            onViewDetails: {
                                selectedBook = book
                                showingBookDetail = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Reading Progress Section
    private var readingProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ProgressMetric(
                    title: "Books This Month",
                    current: dataManager.booksReadThisMonth,
                    goal: dataManager.monthlyReadingGoal,
                    color: dataManager.userProfile?.selectedPath.color ?? .blue
                )
                
                ProgressMetric(
                    title: "Reading Time This Week",
                    current: dataManager.weeklyReadingMinutes,
                    goal: dataManager.weeklyReadingGoal,
                    color: .orange,
                    unit: "min"
                )
                
                ProgressMetric(
                    title: "Highlights Saved",
                    current: dataManager.highlightsThisMonth,
                    goal: dataManager.monthlyHighlightGoal,
                    color: .yellow
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Saved Books Section
    private var savedBooksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Saved Books")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if dataManager.savedBooksCount > 3 {
                    Button("View All") {
                        // Navigate to full saved books view
                    }
                    .font(.subheadline)
                    .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
            }
            
            if dataManager.savedBooks.isEmpty {
                EmptyStateView(
                    icon: "heart",
                    title: "No Saved Books",
                    description: "Books you save will appear here for easy access"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(dataManager.savedBooks.prefix(3)) { book in
                        LibraryBookRow(
                            book: book,
                            onTap: {
                                selectedBook = book
                                showingBookDetail = true
                            },
                            onToggleSaved: {
                                Task {
                                    await dataManager.toggleBookSaved(book)
                                }
                            },
                            onToggleRead: {
                                Task {
                                    await dataManager.toggleBookRead(book)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Completed Books Section
    private var completedBooksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recently Completed")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if dataManager.completedBooksCount > 3 {
                    Button("View All") {
                        // Navigate to full completed books view
                    }
                    .font(.subheadline)
                    .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
            }
            
            if dataManager.completedBooks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No Completed Books",
                    description: "Finished books will appear here with your ratings and notes"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(dataManager.completedBooks.prefix(3)) { book in
                        CompletedBookRow(
                            book: book,
                            onTap: {
                                selectedBook = book
                                showingBookDetail = true
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Reading Analytics Section
    private var readingAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AnalyticsCard(
                    title: "Avg. Session",
                    value: "\(dataManager.averageReadingSession) min",
                    change: "+5 min",
                    isPositive: true,
                    color: .blue
                )
                
                AnalyticsCard(
                    title: "Reading Speed",
                    value: "\(dataManager.averageReadingSpeed) wpm",
                    change: "+12 wpm",
                    isPositive: true,
                    color: .green
                )
                
                AnalyticsCard(
                    title: "Completion Rate",
                    value: "\(Int(dataManager.bookCompletionRate * 100))%",
                    change: "+8%",
                    isPositive: true,
                    color: .orange
                )
                
                AnalyticsCard(
                    title: "Reading Streak",
                    value: "\(dataManager.readingStreak ?? 0) days",
                    change: "Personal best!",
                    isPositive: true,
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Highlights Section
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Highlights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingHighlights = true
                }
                .font(.subheadline)
                .foregroundColor(.yellow)
            }
            
            if dataManager.recentHighlights.isEmpty {
                EmptyStateView(
                    icon: "highlighter",
                    title: "No Highlights Yet",
                    description: "Save meaningful passages as you read"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(dataManager.recentHighlights.prefix(3)) { highlight in
                        HighlightCard(
                            highlight: highlight,
                            onTap: {
                                // Navigate to highlight detail
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var filteredRecommendations: [BookRecommendation] {
        var recommendations = dataManager.bookRecommendations
        
        // Filter by genre if selected
        if let genre = selectedGenre {
            recommendations = recommendations.filter { $0.genre == genre }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            recommendations = recommendations.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText) ||
                book.summary.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    private func setupBookStation() {
        Task {
            await dataManager.loadBookRecommendations()
            await loadFeaturedBook()
            await loadDailyInsight()
        }
    }
    
    private func refreshBookData() async {
        await dataManager.refreshBookData()
        await loadFeaturedBook()
        await loadDailyInsight()
    }
    
    private func refreshRecommendations() async {
        await dataManager.generateNewRecommendations()
    }
    
    private func loadFeaturedBook() async {
        featuredBook = await dataManager.getFeaturedBook()
    }
    
    private func loadDailyInsight() async {
        dailyInsight = await dataManager.getDailyBookInsight()
    }
    
    private func tabCount(for tab: BookTab) -> Int {
        switch tab {
        case .discover:
            return dataManager.bookRecommendations.count
        case .library:
            return dataManager.savedBooksCount
        case .insights:
            return dataManager.totalHighlights
        case .goals:
            return dataManager.activeReadingGoals.count
        }
    }
}

// MARK: - Supporting Enums

enum BookTab: String, CaseIterable {
    case discover = "discover"
    case library = "library"
    case insights = "insights"
    case goals = "goals"
    
    var displayName: String {
        switch self {
        case .discover: return "Discover"
        case .library: return "My Library"
        case .insights: return "Insights"
        case .goals: return "Goals"
        }
    }
    
    var icon: String {
        switch self {
        case .discover: return "books.vertical"
        case .library: return "heart"
        case .insights: return "lightbulb"
        case .goals: return "target"
        }
    }
}

enum BookCardStyle {
    case featured
    case compact
    case list
}

// MARK: - Supporting UI Components

// MARK: - Tab Button
struct TabButton: View {
    let tab: BookTab
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.caption)
                
                Text(tab.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Book Card
struct BookCard: View {
    let book: BookRecommendation
    let style: BookCardStyle
    let onTap: () -> Void
    let onSave: (() -> Void)?
    let onStartReading: (() -> Void)?
    
    init(book: BookRecommendation, style: BookCardStyle = .compact, onTap: @escaping () -> Void, onSave: (() -> Void)? = nil, onStartReading: (() -> Void)? = nil) {
        self.book = book
        self.style = style
        self.onTap = onTap
        self.onSave = onSave
        self.onStartReading = onStartReading
    }
    
    var body: some View {
        Button(action: onTap) {
            switch style {
            case .featured:
                featuredCardContent
            case .compact:
                compactCardContent
            case .list:
                listCardContent
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Featured Card Content
    private var featuredCardContent: some View {
        HStack(spacing: 16) {
            // Book cover
            AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [book.path.color.opacity(0.8), book.path.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        VStack {
                            Text(book.title.prefix(2))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    )
            }
            .frame(width: 100, height: 140)
            .cornerRadius(12)
            
            // Book info
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: book.path.icon)
                            .font(.caption)
                            .foregroundColor(book.path.color)
                        
                        Text(book.path.displayName)
                            .font(.caption)
                            .foregroundColor(book.path.color)
                    }
                }
                
                Text(book.keyInsight)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                // Action buttons
                HStack(spacing: 8) {
                    if let onSave = onSave {
                        Button(action: onSave) {
                            HStack(spacing: 4) {
                                Image(systemName: book.isSaved ? "heart.fill" : "heart")
                                Text(book.isSaved ? "Saved" : "Save")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(book.isSaved ? .red : .secondary)
                        }
                    }
                    
                    if let onStartReading = onStartReading {
                        Button(action: onStartReading) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle")
                                Text("Start Reading")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Compact Card Content
    private var compactCardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book cover
            AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [book.path.color.opacity(0.8), book.path.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Text(book.title.prefix(1))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            .frame(height: 120)
            .cornerRadius(8)
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Reading status
                HStack {
                    Image(systemName: book.readingStatus.icon)
                        .font(.caption2)
                        .foregroundColor(book.readingStatus.color)
                    
                    Text(book.readingStatus.displayName)
                        .font(.caption2)
                        .foregroundColor(book.readingStatus.color)
                    
                    Spacer()
                    
                    if let onSave = onSave {
                        Button(action: onSave) {
                            Image(systemName: book.isSaved ? "heart.fill" : "heart")
                                .font(.caption)
                                .foregroundColor(book.isSaved ? .red : .secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - List Card Content
    private var listCardContent: some View {
        HStack(spacing: 12) {
            // Mini book cover
            AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(book.path.color)
                    .overlay(
                        Text(book.title.prefix(1))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 40, height: 60)
            .cornerRadius(6)
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    Image(systemName: book.path.icon)
                        .font(.caption2)
                        .foregroundColor(book.path.color)
                    
                    Text(book.path.displayName)
                        .font(.caption2)
                        .foregroundColor(book.path.color)
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 8) {
                if let onSave = onSave {
                    Button(action: onSave) {
                        Image(systemName: book.isSaved ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundColor(book.isSaved ? .red : .secondary)
                    }
                }
                
                Image(systemName: book.readingStatus.icon)
                    .font(.caption)
                    .foregroundColor(book.readingStatus.color)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(8)
    }
}

// MARK: - Genre Filter Pill
struct GenreFilterPill: View {
    let genre: BookRecommendation.BookGenre?
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(.regularMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Reading Progress Card
struct ReadingProgressCard: View {
    let book: BookRecommendation
    let onContinueReading: () -> Void
    let onViewDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book cover
            AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(book.path.color)
                    .overlay(
                        Text(book.title.prefix(1))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 100, height: 140)
            .cornerRadius(8)
            
            // Progress info
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(book.readingProgressPercentage)% complete")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: book.readingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: book.path.color))
                        .scaleEffect(y: 0.8)
                }
                
                // Action button
                Button("Continue") {
                    onContinueReading()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(book.path.color)
                .cornerRadius(6)
            }
        }
        .frame(width: 100)
        .onTapGesture {
            onViewDetails()
        }
    }
}

// MARK: - Progress Metric
struct ProgressMetric: View {
    let title: String
    let current: Int
    let goal: Int
    let color: Color
    let unit: String
    
    init(title: String, current: Int, goal: Int, color: Color, unit: String = "") {
        self.title = title
        self.current = current
        self.goal = goal
        self.color = color
        self.unit = unit
    }
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(current) / Double(goal))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(current)/\(goal)\(unit.isEmpty ? "" : " \(unit)")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 1.5)
        }
    }
}

// MARK: - Library Book Row
struct LibraryBookRow: View {
    let book: BookRecommendation
    let onTap: () -> Void
    let onToggleSaved: () -> Void
    let onToggleRead: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Book cover
                AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(book.path.color)
                        .overlay(
                            Text(book.title.prefix(1))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 50, height: 70)
                .cornerRadius(6)
                
                // Book info
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: book.path.icon)
                            .font(.caption2)
                            .foregroundColor(book.path.color)
                        
                        Text(book.path.displayName)
                            .font(.caption2)
                            .foregroundColor(book.path.color)
                    }
                    
                    if book.readingProgress > 0 {
                        ProgressView(value: book.readingProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: book.path.color))
                            .scaleEffect(y: 0.8)
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 8) {
                    Button(action: onToggleRead) {
                        Image(systemName: book.isRead ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(book.isRead ? .green : .secondary)
                    }
                    
                    Button(action: onToggleSaved) {
                        Image(systemName: book.isSaved ? "heart.fill" : "heart")
                            .font(.subheadline)
                            .foregroundColor(book.isSaved ? .red : .secondary)
                    }
                }
            }
            .padding(12)
            .background(.regularMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Completed Book Row
struct CompletedBookRow: View {
    let book: BookRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Book cover
                AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(book.path.color.opacity(0.7))
                        .overlay(
                            Text(book.title.prefix(1))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 40, height: 60)
                .cornerRadius(6)
                .overlay(
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 15, y: -25)
                )
                
                // Book info
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let dateRead = book.dateRead {
                        Text("Completed \(dateRead.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Rating
                    if book.userRating.rawValue > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= book.userRating.starCount ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(star <= book.userRating.starCount ? .orange : .gray)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(.regularMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Analytics Card
struct AnalyticsCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.caption2)
                    .foregroundColor(isPositive ? .green : .red)
                
                Text(change)
                    .font(.caption2)
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Highlight Card
struct HighlightCard: View {
    let highlight: BookHighlight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Text(highlight.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .italic()
                    .lineSpacing(4)
                
                HStack {
                    Text("From: \(highlight.bookTitle)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if highlight.pageNumber > 0 {
                        Text("Page \(highlight.pageNumber)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let note = highlight.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(highlight.highlightColor, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Supporting Models

struct DailyBookInsight {
    let content: String
    let bookTitle: String
    let category: String
    let actionItem: String?
    
    static func forPath(_ path: TrainingPath) -> DailyBookInsight {
        let insights = insightsForPath(path)
        return insights.randomElement() ?? DailyBookInsight(
            content: "Every book holds the potential to transform your perspective.",
            bookTitle: "Unknown",
            category: path.displayName,
            actionItem: nil
        )
    }
    
    private static func insightsForPath(_ path: TrainingPath) -> [DailyBookInsight] {
        switch path {
        case .discipline:
            return [
                DailyBookInsight(
                    content: "The compound effect of small daily habits creates extraordinary results over time.",
                    bookTitle: "Atomic Habits",
                    category: "Discipline",
                    actionItem: "Stack a new 2-minute habit onto an existing routine today."
                ),
                DailyBookInsight(
                    content: "Mental toughness is built through deliberately choosing discomfort.",
                    bookTitle: "Can't Hurt Me",
                    category: "Discipline",
                    actionItem: "Do one thing today that makes you uncomfortable for 10 minutes."
                )
            ]
        case .clarity:
            return [
                DailyBookInsight(
                    content: "The present moment is the only time over which we have any power.",
                    bookTitle: "The Power of Now",
                    category: "Clarity",
                    actionItem: "Take 3 conscious breaths when you feel stressed today."
                )
            ]
        case .confidence:
            return [
                DailyBookInsight(
                    content: "True confidence isn't about thinking you're perfect—it's about being willing to try despite imperfection.",
                    bookTitle: "The Confidence Code",
                    category: "Confidence",
                    actionItem: "Share your opinion in a group conversation today."
                )
            ]
        case .purpose:
            return [
                DailyBookInsight(
                    content: "Those who have a 'why' to live can bear almost any 'how'.",
                    bookTitle: "Man's Search for Meaning",
                    category: "Purpose",
                    actionItem: "Write down one thing that gives your life meaning."
                )
            ]
        case .authenticity:
            return [
                DailyBookInsight(
                    content: "Authenticity is the daily practice of letting go of who we think we're supposed to be.",
                    bookTitle: "The Gifts of Imperfection",
                    category: "Authenticity",
                    actionItem: "Share one authentic thought or feeling with someone you trust."
                )
            ]
        }
    }
}

// MARK: - Enhanced Data Manager Extensions for Books

extension EnhancedDataManager {
    var bookRecommendations: [BookRecommendation] {
        return currentBookRecommendations
    }
    
    var savedBooks: [BookRecommendation] {
        return currentBookRecommendations.filter { $0.isSaved }
    }
    
    var completedBooks: [BookRecommendation] {
        return currentBookRecommendations.filter { $0.isRead }
    }
    
    var currentlyReadingBooks: [BookRecommendation] {
        return currentBookRecommendations.filter { $0.isCurrentlyReading }
    }
    
    var savedBooksCount: Int {
        return savedBooks.count
    }
    
    var completedBooksCount: Int {
        return completedBooks.count
    }
    
    var booksReadThisMonth: Int {
        let calendar = Calendar.current
        return completedBooks.filter { book in
            guard let dateRead = book.dateRead else { return false }
            return calendar.isDate(dateRead, equalTo: Date(), toGranularity: .month)
        }.count
    }
    
    var monthlyReadingGoal: Int {
        return 3 // This would come from user settings
    }
    
    var weeklyReadingMinutes: Int {
        // Calculate from reading sessions this week
        return 120 // Mock value
    }
    
    var weeklyReadingGoal: Int {
        return 300 // This would come from user settings
    }
    
    var highlightsThisMonth: Int {
        return recentHighlights.count
    }
    
    var monthlyHighlightGoal: Int {
        return 20 // This would come from user settings
    }
    
    var totalHighlights: Int {
        return recentHighlights.count
    }
    
    var recentHighlights: [BookHighlight] {
        // This would fetch from Core Data
        return []
    }
    
    var activeReadingGoals: [ReadingGoal] {
        // This would fetch from Core Data
        return []
    }
    
    var readingStreak: Int? {
        // Calculate reading streak from sessions
        return 7 // Mock value
    }
    
    var averageReadingSession: Int {
        return 25 // Mock value in minutes
    }
    
    var averageReadingSpeed: Int {
        return 180 // Mock value in words per minute
    }
    
    var bookCompletionRate: Double {
        guard !savedBooks.isEmpty else { return 0.0 }
        return Double(completedBooks.count) / Double(savedBooks.count)
    }
    
    func loadBookRecommendations() async {
        // Load recommendations from Core Data and/or Supabase
        guard let path = userProfile?.selectedPath else { return }
        currentBookRecommendations = BookGenerator.generateRecommendations(for: path, count: 20)
    }
    
    func refreshBookData() async {
        await loadBookRecommendations()
        // Refresh other book-related data
    }
    
    func generateNewRecommendations() async {
        guard let path = userProfile?.selectedPath else { return }
        currentBookRecommendations = BookGenerator.generateRecommendations(for: path, count: 20)
    }
    
    func getFeaturedBook() async -> BookRecommendation? {
        guard let path = userProfile?.selectedPath else { return nil }
        return BookGenerator.getBookOfTheDay(for: path)
    }
    
    func getDailyBookInsight() async -> DailyBookInsight? {
        guard let path = userProfile?.selectedPath else { return nil }
        return DailyBookInsight.forPath(path)
    }
    
    func toggleBookSaved(_ book: BookRecommendation) async {
        // Update in Core Data
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        if let cdBook = coreDataStack.fetch(request).first {
            cdBook.isSaved.toggle()
            coreDataStack.save()
            
            // Update local model
            if let index = currentBookRecommendations.firstIndex(where: { $0.id == book.id }) {
                currentBookRecommendations[index].isSaved.toggle()
            }
        }
    }
    
    func toggleBookRead(_ book: BookRecommendation) async {
        // Update in Core Data
        let request: NSFetchRequest<CDBookRecommendation> = CDBookRecommendation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        if let cdBook = coreDataStack.fetch(request).first {
            cdBook.isRead.toggle()
            if cdBook.isRead {
                cdBook.dateRead = Date()
                cdBook.readingProgress = 1.0
            } else {
                cdBook.dateRead = nil
                cdBook.readingProgress = 0.0
            }
            coreDataStack.save()
            
            // Update local model
            if let index = currentBookRecommendations.firstIndex(where: { $0.id == book.id }) {
                currentBookRecommendations[index].isRead.toggle()
                if currentBookRecommendations[index].isRead {
                    currentBookRecommendations[index].dateRead = Date()
                    currentBookRecommendations[index].readingProgress = 1.0
                } else {
                    currentBookRecommendations[index].dateRead = nil
                    currentBookRecommendations[index].readingProgress = 0.0
                }
            }
        }
    }
}

// MARK: - Preview Support
struct BookStationView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = EnhancedDataManager()
        
        BookStationView()
            .environmentObject(dataManager)
            .preferredColorScheme(.light)
    }
}
