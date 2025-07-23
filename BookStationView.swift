import SwiftUI

// MARK: - Book Station View
struct BookStationView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab: BookTab = .recommendations
    @State private var searchText = ""
    @State private var showingBookDetail = false
    @State private var selectedBook: BookRecommendation?
    @State private var showingPathSelector = false
    @State private var featuredBook: BookRecommendation?
    @State private var showingAIBookChat = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Selector
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Recommendations Tab
                    recommendationsTab
                        .tag(BookTab.recommendations)
                    
                    // My Library Tab
                    myLibraryTab
                        .tag(BookTab.library)
                    
                    // Insights Tab
                    insightsTab
                        .tag(BookTab.insights)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Book Station")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingPathSelector = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: dataManager.userProfile?.selectedPath.icon ?? "book.fill")
                            Text(dataManager.userProfile?.selectedPath.displayName ?? "Path")
                                .font(.caption)
                        }
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAIBookChat = true
                    } label: {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    }
                }
            }
            .sheet(isPresented: $showingBookDetail) {
                if let book = selectedBook {
                    BookDetailView(book: book)
                }
            }
            .sheet(isPresented: $showingPathSelector) {
                PathSelectorSheet()
            }
            .sheet(isPresented: $showingAIBookChat) {
                AIBookChatView()
            }
            .onAppear {
                setupFeaturedBook()
            }
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(BookTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        
                        Text(tab.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == tab ? 
                                   (dataManager.userProfile?.selectedPath.color ?? .blue) : 
                                   .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }
    
    // MARK: - Recommendations Tab
    private var recommendationsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Featured Book of the Day
                if let featured = featuredBook {
                    featuredBookSection(featured)
                }
                
                // Search Bar
                searchBar
                
                // Path-Based Recommendations
                pathRecommendationsSection
                
                // Browse All Categories
                browseAllSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .refreshable {
            refreshRecommendations()
        }
    }
    
    // MARK: - My Library Tab
    private var myLibraryTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Library Stats
                libraryStatsSection
                
                // Reading Status Filters
                readingStatusFilters
                
                // Saved Books
                savedBooksSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Insights Tab
    private var insightsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Daily Insight
                dailyInsightSection
                
                // Reading Progress
                readingProgressSection
                
                // Key Takeaways
                keyTakeawaysSection
                
                // Reading Goals
                readingGoalsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Featured Book Section
    private func featuredBookSection(_ book: BookRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📚 Book of the Day")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    setupFeaturedBook()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
            }
            
            VStack(spacing: 16) {
                // Book Header
                HStack(alignment: .top, spacing: 16) {
                    // Mock book cover
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [book.path.color.opacity(0.8), book.path.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 120)
                        .overlay(
                            VStack {
                                Text(book.title.prefix(20))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                
                                Spacer()
                                
                                Text(book.author.components(separatedBy: " ").first ?? "")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(6)
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("by \(book.author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: book.path.icon)
                                .font(.caption)
                                .foregroundColor(book.path.color)
                            
                            Text(book.path.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(book.path.color)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(book.path.color.opacity(0.1))
                        )
                    }
                    
                    Spacer()
                }
                
                // Key Insight
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Today's Insight")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(book.keyInsight)
                        .font(.body)
                        .foregroundColor(.primary)
                        .italic()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Daily Action
                VStack(alignment: .leading, spacing: 8) {
                    Text("🎯 Daily Action")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(book.dailyAction)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button {
                        selectedBook = book
                        showingBookDetail = true
                    } label: {
                        Text("Read More")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(book.path.color)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(book.path.color.opacity(0.1))
                            )
                    }
                    
                    Button {
                        toggleBookSaved(book)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: book.isSaved ? "heart.fill" : "heart")
                            Text(book.isSaved ? "Saved" : "Save")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(book.isSaved ? .red : .secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search books, authors, or topics...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Path Recommendations Section
    private var pathRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("For Your \(dataManager.userProfile?.selectedPath.displayName ?? "Growth") Journey")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    refreshRecommendations()
                } label: {
                    Text("Refresh")
                        .font(.subheadline)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(currentPathBooks) { book in
                        BookCard(book: book) {
                            selectedBook = book
                            showingBookDetail = true
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
    }
    
    // MARK: - Browse All Section
    private var browseAllSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Browse by Focus Area")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(TrainingPath.allCases) { path in
                    PathCategoryCard(path: path) {
                        // Switch to this path and refresh
                        dataManager.updateUserPath(path)
                        refreshRecommendations()
                    }
                }
            }
        }
    }
    
    // MARK: - Library Stats Section
    private var libraryStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Library")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                LibraryStatCard(
                    title: "Saved",
                    count: savedBooks.count,
                    icon: "heart.fill",
                    color: .red
                )
                
                LibraryStatCard(
                    title: "Read",
                    count: readBooks.count,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                LibraryStatCard(
                    title: "Reading",
                    count: currentlyReadingBooks.count,
                    icon: "book.fill",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Reading Status Filters
    private var readingStatusFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter by Status")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPill(title: "All Saved", count: savedBooks.count, isSelected: true)
                    FilterPill(title: "Want to Read", count: savedBooks.filter { !$0.isRead }.count)
                    FilterPill(title: "Currently Reading", count: currentlyReadingBooks.count)
                    FilterPill(title: "Completed", count: readBooks.count)
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
    }
    
    // MARK: - Saved Books Section
    private var savedBooksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if savedBooks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No saved books yet")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Browse recommendations and save books you want to read")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        selectedTab = .recommendations
                    } label: {
                        Text("Browse Books")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(dataManager.userProfile?.selectedPath.color ?? .blue)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(savedBooks) { book in
                        LibraryBookRow(book: book) {
                            selectedBook = book
                            showingBookDetail = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Daily Insight Section
    private var dailyInsightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📖 Today's Reading Insight")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let insight = getTodaysInsight() {
                VStack(alignment: .leading, spacing: 12) {
                    Text(insight.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .italic()
                    
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
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                )
            }
        }
    }
    
    // MARK: - Reading Progress Section
    private var readingProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📈 Your Reading Journey")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ProgressMetric(
                    title: "Books This Month",
                    current: readBooks.filter { Calendar.current.isDate($0.dateAdded, equalTo: Date(), toGranularity: .month) }.count,
                    goal: 2,
                    color: dataManager.userProfile?.selectedPath.color ?? .blue
                )
                
                ProgressMetric(
                    title: "Insights Collected",
                    current: savedBooks.count * 3, // Mock metric
                    goal: 50,
                    color: .green
                )
                
                ProgressMetric(
                    title: "Reading Streak",
                    current: 7, // Mock metric
                    goal: 30,
                    color: .orange
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
    }
    
    // MARK: - Key Takeaways Section
    private var keyTakeawaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("💡 Your Key Takeaways")
                .font(.headline)
                .fontWeight(.semibold)
            
            if savedBooks.isEmpty {
                Text("Save books to collect key insights and takeaways")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                    )
            } else {
                VStack(spacing: 12) {
                    ForEach(savedBooks.prefix(3)) { book in
                        TakeawayCard(book: book)
                    }
                }
            }
        }
    }
    
    // MARK: - Reading Goals Section
    private var readingGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎯 Reading Goals")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                GoalCard(
                    title: "Monthly Reading Goal",
                    description: "Read 2 books this month",
                    progress: min(1.0, Double(readBooks.count) / 2.0),
                    color: dataManager.userProfile?.selectedPath.color ?? .blue
                )
                
                GoalCard(
                    title: "Diversity Goal",
                    description: "Read from 3 different focus areas",
                    progress: 0.67, // Mock progress
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var currentPathBooks: [BookRecommendation] {
        guard let path = dataManager.userProfile?.selectedPath else { return [] }
        return BookGenerator.generateRecommendations(for: path, count: 5)
    }
    
    private var savedBooks: [BookRecommendation] {
        return dataManager.currentBookRecommendations.filter { $0.isSaved }
    }
    
    private var readBooks: [BookRecommendation] {
        return dataManager.currentBookRecommendations.filter { $0.isRead }
    }
    
    private var currentlyReadingBooks: [BookRecommendation] {
        return dataManager.currentBookRecommendations.filter { $0.isSaved && !$0.isRead }
    }
    
    // MARK: - Helper Methods
    private func setupFeaturedBook() {
        guard let path = dataManager.userProfile?.selectedPath else { return }
        featuredBook = BookGenerator.getBookOfTheDay(for: path)
    }
    
    private func refreshRecommendations() {
        guard let path = dataManager.userProfile?.selectedPath else { return }
        dataManager.currentBookRecommendations = BookGenerator.generateRecommendations(for: path, count: 10)
        setupFeaturedBook()
    }
    
    private func toggleBookSaved(_ book: BookRecommendation) {
        if let index = dataManager.currentBookRecommendations.firstIndex(where: { $0.id == book.id }) {
            dataManager.currentBookRecommendations[index].isSaved.toggle()
        }
        
        // Update featured book if it's the same
        if featuredBook?.id == book.id {
            featuredBook?.isSaved.toggle()
        }
    }
    
    private func getTodaysInsight() -> DailyInsight? {
        let insights = [
            DailyInsight(
                content: "The compound effect of small daily habits creates extraordinary results over time.",
                bookTitle: "Atomic Habits",
                category: "Discipline"
            ),
            DailyInsight(
                content: "True confidence isn't about thinking you're perfect—it's about being willing to try despite imperfection.",
                bookTitle: "The Confidence Code",
                category: "Confidence"
            ),
            DailyInsight(
                content: "Clarity comes from engagement, not thought. Take action to discover what you truly want.",
                bookTitle: "Designing Your Life",
                category: "Purpose"
            )
        ]
        return insights.randomElement()
    }
}

// MARK: - Supporting Models and Views

enum BookTab: String, CaseIterable {
    case recommendations = "recommendations"
    case library = "library"
    case insights = "insights"
    
    var displayName: String {
        switch self {
        case .recommendations: return "Discover"
        case .library: return "My Books"
        case .insights: return "Insights"
        }
    }
    
    var icon: String {
        switch self {
        case .recommendations: return "books.vertical.fill"
        case .library: return "heart.fill"
        case .insights: return "lightbulb.fill"
        }
    }
}

struct DailyInsight {
    let content: String
    let bookTitle: String
    let category: String
}

// MARK: - Book Card
struct BookCard: View {
    let book: BookRecommendation
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mock book cover
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [book.path.color.opacity(0.8), book.path.color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 120, height: 160)
                .overlay(
                    VStack {
                        Text(book.title.prefix(25))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                        
                        Spacer()
                        
                        Text(book.author.components(separatedBy: " ").first ?? "")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(8)
                )
            
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
            }
        }
        .frame(width: 120)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Path Category Card
struct PathCategoryCard: View {
    let path: TrainingPath
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: path.icon)
                .font(.title)
                .foregroundColor(path.color)
            
            VStack(spacing: 4) {
                Text(path.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(path.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(path.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(path.color.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Library Stat Card
struct LibraryStatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    
    init(title: String, count: Int, isSelected: Bool = false) {
        self.title = title
        self.count = count
        self.isSelected = isSelected
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            
            if count > 0 {
                Text("(\(count))")
                    .foregroundColor(.secondary)
            }
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(isSelected ? .white : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isSelected ? Color.blue : Color(.systemGray5))
        )
    }
}

// MARK: - Library Book Row
struct LibraryBookRow: View {
    @EnvironmentObject var dataManager: DataManager
    let book: BookRecommendation
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Mini book cover
            RoundedRectangle(cornerRadius: 6)
                .fill(book.path.color)
                .frame(width: 40, height: 60)
                .overlay(
                    Text(book.title.prefix(1))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: book.path.icon)
                        .font(.caption2)
                        .foregroundColor(book.path.color)
                    
                    Text(book.path.displayName)
                        .font(.caption2)
                        .foregroundColor(book.path.color)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button {
                    toggleReadStatus()
                } label: {
                    Image(systemName: book.isRead ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(book.isRead ? .green : .secondary)
                }
                
                Button {
                    toggleSavedStatus()
                } label: {
                    Image(systemName: book.isSaved ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .foregroundColor(book.isSaved ? .red : .secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private func toggleReadStatus() {
        if let index = dataManager.currentBookRecommendations.firstIndex(where: { $0.id == book.id }) {
            dataManager.currentBookRecommendations[index].isRead.toggle()
        }
    }
    
    private func toggleSavedStatus() {
        if let index = dataManager.currentBookRecommendations.firstIndex(where: { $0.id == book.id }) {
            dataManager.currentBookRecommendations[index].isSaved.toggle()
        }
    }
}

// MARK: - Progress Metric
struct ProgressMetric: View {
    let title: String
    let current: Int
    let goal: Int
    let color: Color
    
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
                
                Text("\(current)/\(goal)")
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

// MARK: - Takeaway Card
struct TakeawayCard: View {
    let book: BookRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: book.path.icon)
                    .font(.caption)
                    .foregroundColor(book.path.color)
            }
            
            Text(book.keyInsight)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .lineLimit(3)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Goal Card
struct GoalCard: View {
    let title: String
    let description: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(Int(progress * 100))% Complete")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Book Detail View
struct BookDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    let book: BookRecommendation
    @State private var localBook: BookRecommendation
    
    init(book: BookRecommendation) {
        self.book = book
        self._localBook = State(initialValue: book)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Book Header
                    bookHeader
                    
                    // Summary Section
                    summarySection
                    
                    // Key Insight Section
                    keyInsightSection
                    
                    // Daily Action Section
                    dailyActionSection
                    
                    // Action Buttons Section
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var bookHeader: some View {
        HStack(alignment: .top, spacing: 20) {
            // Large book cover
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [localBook.path.color.opacity(0.8), localBook.path.color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 120, height: 180)
                .overlay(
                    VStack(spacing: 8) {
                        Text(localBook.title)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                        
                        Spacer()
                        
                        Text(localBook.author)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(12)
                )
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localBook.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("by \(localBook.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: localBook.path.icon)
                        .font(.subheadline)
                        .foregroundColor(localBook.path.color)
                    
                    Text(localBook.path.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(localBook.path.color)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(localBook.path.color.opacity(0.1))
                )
                
                // Status indicators
                HStack(spacing: 16) {
                    if localBook.isSaved {
                        Label("Saved", systemImage: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if localBook.isRead {
                        Label("Read", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About This Book")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(localBook.summary)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
    }
    
    private var keyInsightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 Key Insight")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(localBook.keyInsight)
                .font(.body)
                .foregroundColor(.primary)
                .italic()
                .lineSpacing(4)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(localBook.path.color.opacity(0.1))
                )
        }
    }
    
    private var dailyActionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 Daily Action")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(localBook.dailyAction)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                )
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary actions
            HStack(spacing: 12) {
                Button {
                    toggleSaved()
                } label: {
                    HStack {
                        Image(systemName: localBook.isSaved ? "heart.fill" : "heart")
                        Text(localBook.isSaved ? "Saved" : "Save to Library")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(localBook.isSaved ? .white : localBook.path.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(localBook.isSaved ? Color.red : localBook.path.color.opacity(0.1))
                    )
                }
                
                Button {
                    toggleRead()
                } label: {
                    HStack {
                        Image(systemName: localBook.isRead ? "checkmark.circle.fill" : "circle")
                        Text(localBook.isRead ? "Mark Unread" : "Mark as Read")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(localBook.isRead ? .white : .green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(localBook.isRead ? Color.green : Color.green.opacity(0.1))
                    )
                }
            }
            
            // External link
            if let amazonURL = localBook.amazonURL {
                Button {
                    if let url = URL(string: amazonURL) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("View on Amazon")
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
        }
        .padding(.top, 8)
    }
    
    private func toggleSaved() {
        localBook.isSaved.toggle()
        updateBookInDataManager()
    }
    
    private func toggleRead() {
        localBook.isRead.toggle()
        if localBook.isRead && !localBook.isSaved {
            localBook.isSaved = true
        }
        updateBookInDataManager()
    }
    
    private func updateBookInDataManager() {
        if let index = dataManager.currentBookRecommendations.firstIndex(where: { $0.id == localBook.id }) {
            dataManager.currentBookRecommendations[index] = localBook
        }
    }
}

// MARK: - AI Book Chat View
struct AIBookChatView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var userQuestion = ""
    @State private var chatHistory: [ChatMessage] = []
    @State private var isLoading = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Welcome message
                        if chatHistory.isEmpty {
                            welcomeMessage
                        }
                        
                        ForEach(chatHistory) { message in
                            ChatBubble(message: message)
                        }
                        
                        if isLoading {
                            loadingIndicator
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Divider()
                
                // Input area
                inputArea
            }
            .navigationTitle("AI Book Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
            
            Text("Ask me about books!")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("I can recommend books, explain concepts, or help you find specific insights for your \(dataManager.userProfile?.selectedPath.displayName.lowercased() ?? "growth") journey.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                Text("Try asking:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 6) {
                    SuggestedQuestion("What book should I read to build better habits?")
                    SuggestedQuestion("Explain the key idea from Atomic Habits")
                    SuggestedQuestion("Books for overcoming fear and building confidence?")
                }
            }
        }
        .padding(.vertical, 40)
    }
    
    private var loadingIndicator: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Thinking...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Ask about books, authors, or concepts...", text: $userQuestion, axis: .vertical)
                .focused($isTextFieldFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .lineLimit(1...4)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(canSend ? (dataManager.userProfile?.selectedPath.color ?? .blue) : Color(.systemGray4))
                    )
            }
            .disabled(!canSend || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var canSend: Bool {
        !userQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendMessage() {
        let question = userQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        
        // Add user message
        chatHistory.append(ChatMessage(content: question, isUser: true))
        userQuestion = ""
        isLoading = true
        isTextFieldFocused = false
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = generateAIResponse(to: question)
            chatHistory.append(ChatMessage(content: response, isUser: false))
            isLoading = false
        }
    }
    
    private func generateAIResponse(to question: String) -> String {
        // In a real app, this would call an AI service
        // For now, we'll return contextual responses based on keywords
        
        let lowercaseQuestion = question.lowercased()
        
        if lowercaseQuestion.contains("habit") {
            return "For building habits, I'd recommend 'Atomic Habits' by James Clear. It teaches you how small changes compound into remarkable results. The key insight is that you don't rise to the level of your goals; you fall to the level of your systems. Start with habits that are 1% better each day."
        } else if lowercaseQuestion.contains("confidence") {
            return "For confidence building, try 'The Confidence Code' by Kay and Shipman. It shows that confidence isn't about thinking you're perfect—it's about being willing to try despite imperfection. The book reveals that confidence is more important than competence for success."
        } else if lowercaseQuestion.contains("discipline") {
            return "For discipline, 'Can't Hurt Me' by David Goggins is powerful. He teaches the 40% rule: when you think you're done, you're only 40% done. Your mind will quit long before your body needs to. True strength comes from pushing past mental barriers."
        } else if lowercaseQuestion.contains("purpose") || lowercaseQuestion.contains("meaning") {
            return "For finding purpose, read 'Start With Why' by Simon Sinek. People don't buy what you do, they buy why you do it. Also consider 'Man's Search for Meaning' by Viktor Frankl—everything can be taken from you except the freedom to choose your attitude."
        } else if lowercaseQuestion.contains("authentic") {
            return "For authenticity, 'The Gifts of Imperfection' by Brené Brown is excellent. Authenticity is the daily practice of letting go of who we think we're supposed to be and embracing who we are. It's about choosing courage over comfort."
        } else {
            return "That's a great question! Based on your current focus on \(dataManager.userProfile?.selectedPath.displayName ?? "personal growth"), I'd recommend exploring books that align with your goals. What specific area would you like to develop most?"
        }
    }
}

// MARK: - Supporting Views for AI Chat

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .font(.body)
                .foregroundColor(message.isUser ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.isUser ? Color.blue : .regularMaterial)
                )
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct SuggestedQuestion: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text("• \(text)")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}