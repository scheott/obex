import SwiftUI
import Foundation

// MARK: - Main Journal View
struct JournalView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @State private var selectedFilter: JournalFilter = .all
    @State private var searchText = ""
    @State private var showingNewEntry = false
    @State private var showingSearch = false
    @State private var showingSavedEntries = false
    @State private var selectedEntry: JournalEntry?
    @State private var showingAnalytics = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                // Filter and Search Bar
                filterAndSearchSection
                
                // Content based on filter
                contentSection
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .refreshable {
                await dataManager.refreshJournalData()
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            EntryComposer()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingSavedEntries) {
            SavedEntriesView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingAnalytics) {
            JournalAnalyticsView()
                .environmentObject(dataManager)
        }
        .fullScreenCover(item: $selectedEntry) { entry in
            FullJournalEntryView(entry: entry)
                .environmentObject(dataManager)
        }
        .onAppear {
            dataManager.loadJournalEntries()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Journal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(getJournalSubtitle())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Analytics Button
                    Button {
                        showingAnalytics = true
                    } label: {
                        Image(systemName: "chart.bar")
                            .font(.title3)
                            .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    }
                    
                    // Saved Entries Button
                    Button {
                        showingSavedEntries = true
                    } label: {
                        ZStack {
                            Image(systemName: "heart")
                                .font(.title3)
                                .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                            
                            if savedEntriesCount > 0 {
                                Text("\\(savedEntriesCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    
                    // New Entry Button
                    Button {
                        showingNewEntry = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(dataManager.userProfile?.selectedPath.color ?? .blue)
                            .clipShape(Circle())
                    }
                }
            }
            
            // Journal Stats Row
            journalStatsRow
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Journal Stats Row
    private var journalStatsRow: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "This Week",
                value: "\\(weeklyEntryCount)",
                subtitle: "entries",
                color: dataManager.userProfile?.selectedPath.color ?? .blue
            )
            
            StatCard(
                title: "Streak",
                value: "\\(journalStreak)",
                subtitle: "days",
                color: .orange
            )
            
            StatCard(
                title: "Words",
                value: weeklyWordCount > 1000 ? "\\(weeklyWordCount / 1000)k" : "\\(weeklyWordCount)",
                subtitle: "written",
                color: .green
            )
            
            Spacer()
        }
    }
    
    // MARK: - Filter and Search Section
    private var filterAndSearchSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            if showingSearch {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search entries...", text: $searchText)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Search Toggle
                    FilterPill(
                        title: "Search",
                        icon: "magnifyingglass",
                        isSelected: showingSearch,
                        color: .gray
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingSearch.toggle()
                            if !showingSearch {
                                searchText = ""
                            }
                        }
                    }
                    
                    ForEach(JournalFilter.allCases, id: \\.self) { filter in
                        FilterPill(
                            title: filter.displayName,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter,
                            color: dataManager.userProfile?.selectedPath.color ?? .blue,
                            badge: filter.badge(for: dataManager)
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        Group {
            if filteredEntries.isEmpty {
                emptyStateView
            } else {
                entriesListView
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: getEmptyStateIcon())
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(getEmptyStateTitle())
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(getEmptyStateMessage())
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if selectedFilter == .all && searchText.isEmpty {
                Button {
                    showingNewEntry = true
                } label: {
                    Text("Write Your First Entry")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(dataManager.userProfile?.selectedPath.color ?? .blue)
                        .cornerRadius(20)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }
    
    // MARK: - Entries List View
    private var entriesListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(filteredEntries) { entry in
                    JournalEntryCard(entry: entry)
                        .onTapGesture {
                            selectedEntry = entry
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Computed Properties
    private var filteredEntries: [JournalEntry] {
        var entries = dataManager.journalEntries
        
        // Apply search filter
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.content.localizedCaseInsensitiveContains(searchText) ||
                entry.tags.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                (entry.prompt?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .withPrompts:
            entries = entries.filter { $0.prompt != nil }
        case .freeform:
            entries = entries.filter { $0.prompt == nil }
        case .saved:
            entries = entries.filter { $0.isSavedToSelf }
        case .reread:
            entries = entries.filter { $0.isMarkedForReread }
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            entries = entries.filter { $0.date >= weekAgo }
        case .thisMonth:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            entries = entries.filter { $0.date >= monthAgo }
        case .insights:
            entries = entries.filter { $0.entryType == .insight }
        case .goals:
            entries = entries.filter { $0.entryType == .goal }
        }
        
        // Sort by date (newest first)
        return entries.sorted { $0.date > $1.date }
    }
    
    private var savedEntriesCount: Int {
        return dataManager.journalEntries.filter { $0.isSavedToSelf }.count
    }
    
    private var weeklyEntryCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return dataManager.journalEntries.filter { $0.date >= weekAgo }.count
    }
    
    private var journalStreak: Int {
        return dataManager.calculateJournalStreak()
    }
    
    private var weeklyWordCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return dataManager.journalEntries
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.wordCount }
    }
    
    // MARK: - Helper Methods
    private func getJournalSubtitle() -> String {
        if dataManager.journalEntries.isEmpty {
            return "Start your reflection journey"
        } else {
            return "\\(dataManager.journalEntries.count) entries written"
        }
    }
    
    private func getEmptyStateIcon() -> String {
        switch selectedFilter {
        case .all: return "book.closed"
        case .withPrompts: return "bubble.left.and.bubble.right"
        case .freeform: return "pencil"
        case .saved: return "heart"
        case .reread: return "bookmark"
        case .thisWeek, .thisMonth: return "calendar"
        case .insights: return "lightbulb"
        case .goals: return "target"
        }
    }
    
    private func getEmptyStateTitle() -> String {
        switch selectedFilter {
        case .all: return "No Entries Yet"
        case .withPrompts: return "No Prompted Entries"
        case .freeform: return "No Freeform Entries"
        case .saved: return "No Saved Entries"
        case .reread: return "Nothing Marked to Re-read"
        case .thisWeek: return "No Entries This Week"
        case .thisMonth: return "No Entries This Month"
        case .insights: return "No Insights Captured"
        case .goals: return "No Goals Recorded"
        }
    }
    
    private func getEmptyStateMessage() -> String {
        switch selectedFilter {
        case .all:
            return "Your journal is waiting for your thoughts, reflections, and insights. Start writing to track your growth journey."
        case .withPrompts:
            return "Prompted entries help guide your reflection. Try using AI-generated prompts for deeper insights."
        case .freeform:
            return "Freeform entries are your space to express thoughts without structure. Write whatever comes to mind."
        case .saved:
            return "Mark entries as saved by tapping the heart icon. These become your personal collection of meaningful reflections."
        case .reread:
            return "Mark entries to re-read later by tapping the bookmark icon. Perfect for revisiting important insights."
        case .thisWeek:
            return "No journal entries this week yet. Consistent reflection accelerates personal growth."
        case .thisMonth:
            return "No journal entries this month yet. Regular journaling builds self-awareness over time."
        case .insights:
            return "Capture your breakthrough moments and realizations. Insights are the gems of your growth journey."
        case .goals:
            return "Document your goals and aspirations. Writing them down makes them more likely to become reality."
        }
    }
}

// MARK: - Journal Entry Card
struct JournalEntryCard: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    let entry: JournalEntry
    @State private var isExpanded = false
    @State private var showingFullEntry = false
    
    private let previewLength = 120
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and metadata
            headerSection
            
            // Content preview
            contentSection
            
            // Tags and actions
            footerSection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .contentShape(Rectangle())
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(formatDate(entry.date))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let mood = entry.mood {
                        Text(mood.emoji)
                            .font(.subheadline)
                    }
                    
                    if entry.entryType != .reflection {
                        Text(entry.entryType.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill((dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.1))
                            )
                    }
                }
                
                HStack(spacing: 12) {
                    if let prompt = entry.prompt {
                        Label("Prompted", systemImage: "bubble.left.and.bubble.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if entry.wordCount > 0 {
                        Label("\\(entry.wordCount) words", systemImage: "textformat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if entry.readingTime > 0 {
                        Label("\\(entry.readingTime) min read", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button {
                    toggleSaved()
                } label: {
                    Image(systemName: entry.isSavedToSelf ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .foregroundColor(entry.isSavedToSelf ? .red : .secondary)
                }
                
                Button {
                    toggleReread()
                } label: {
                    Image(systemName: entry.isMarkedForReread ? "bookmark.fill" : "bookmark")
                        .font(.subheadline)
                        .foregroundColor(entry.isMarkedForReread ? .orange : .secondary)
                }
            }
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Prompt if exists
            if let prompt = entry.prompt, !isExpanded {
                Text(prompt)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    .italic()
                    .lineLimit(2)
            }
            
            // Content
            Group {
                if entry.content.count <= previewLength || isExpanded {
                    Text(entry.content)
                        .font(.body)
                        .foregroundColor(.primary)
                } else {
                    Text(String(entry.content.prefix(previewLength)) + "...")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            .lineLimit(isExpanded ? nil : 4)
            
            // Read more/less button
            if entry.content.count > previewLength {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show Less" : "Read More")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
            }
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        if !entry.tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(entry.tags, id: \\.self) { tag in
                        Text("#\\(tag)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill((dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.1))
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func toggleSaved() {
        Task {
            await dataManager.toggleJournalEntrySaved(entry)
        }
    }
    
    private func toggleReread() {
        Task {
            await dataManager.toggleJournalEntryReread(entry)
        }
    }
}

// MARK: - Entry Composer
struct EntryComposer: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @Environment(\\.dismiss) private var dismiss
    @State private var content = ""
    @State private var selectedMood: AICheckIn.MoodRating?
    @State private var tags: [String] = []
    @State private var tagInput = ""
    @State private var usePrompt = false
    @State private var selectedPrompt = ""
    @State private var availablePrompts: [String] = []
    @State private var entryType: JournalEntryType = .reflection
    @State private var isPrivate = false
    @FocusState private var isContentFocused: Bool
    @FocusState private var isTagInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Content Editor
                    contentEditorSection
                    
                    // Prompt Section
                    if usePrompt {
                        promptSection
                    }
                    
                    // Metadata Section
                    metadataSection
                    
                    // Tags Section
                    tagsSection
                }
                .padding(20)
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            generatePrompts()
            isContentFocused = true
        }
    }
    
    // MARK: - Content Editor Section
    private var contentEditorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Thoughts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\\(content.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextEditor(text: $content)
                .font(.body)
                .frame(minHeight: 120)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .focused($isContentFocused)
        }
    }
    
    // MARK: - Prompt Section
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Writing Prompt")
                .font(.headline)
                .fontWeight(.semibold)
            
            PromptSuggestions(
                prompts: availablePrompts,
                selectedPrompt: $selectedPrompt,
                onSelect: { prompt in
                    selectedPrompt = prompt
                }
            )
        }
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(spacing: 16) {
            // Prompt Toggle
            HStack {
                Text("Use Writing Prompt")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Toggle("", isOn: $usePrompt)
                    .tint(dataManager.userProfile?.selectedPath.color ?? .blue)
            }
            
            // Entry Type Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Entry Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(JournalEntryType.allCases, id: \\.self) { type in
                            Button {
                                entryType = type
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: type.icon)
                                        .font(.caption)
                                    Text(type.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(entryType == type ? .white : (dataManager.userProfile?.selectedPath.color ?? .blue))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(entryType == type ? (dataManager.userProfile?.selectedPath.color ?? .blue) : Color(.systemGray6))
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Mood Selector
            if selectedMood != nil || content.count > 50 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Mood")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    MoodSelector(selectedMood: $selectedMood)
                }
            }
            
            // Privacy Toggle
            HStack {
                Text("Private Entry")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Toggle("", isOn: $isPrivate)
                    .tint(dataManager.userProfile?.selectedPath.color ?? .blue)
            }
        }
    }
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .fontWeight(.semibold)
            
            TagSelector(
                tags: $tags,
                tagInput: $tagInput,
                isFocused: $isTagInputFocused,
                availableTags: getSuggestedTags()
            )
        }
    }
    
    // MARK: - Helper Methods
    private func generatePrompts() {
        guard let path = dataManager.userProfile?.selectedPath else { return }
        availablePrompts = JournalPromptGenerator.generatePrompts(for: path, type: entryType)
        selectedPrompt = availablePrompts.first ?? ""
    }
    
    private func getSuggestedTags() -> [String] {
        guard let path = dataManager.userProfile?.selectedPath else { return [] }
        
        let pathTags = [
            TrainingPath.discipline: ["habits", "willpower", "consistency", "goals", "routine", "focus"],
            TrainingPath.clarity: ["mindfulness", "thoughts", "emotions", "awareness", "meditation"],
            TrainingPath.confidence: ["courage", "social", "leadership", "voice", "boldness", "growth"],
            TrainingPath.purpose: ["values", "meaning", "service", "vision", "legacy", "impact"],
            TrainingPath.authenticity: ["truth", "vulnerability", "genuine", "real", "expression", "honesty"]
        ]
        
        return pathTags[path] ?? []
    }
    
    private func saveEntry() {
        var entry = JournalEntry(
            date: Date(),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            prompt: usePrompt ? selectedPrompt : nil,
            mood: selectedMood,
            tags: tags
        )
        
        entry.entryType = entryType
        entry.isPrivate = isPrivate
        entry.pathContext = dataManager.userProfile?.selectedPath
        
        Task {
            await dataManager.addJournalEntry(entry)
        }
        
        dismiss()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Prompt Suggestions
struct PromptSuggestions: View {
    let prompts: [String]
    @Binding var selectedPrompt: String
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(prompts.prefix(3), id: \\.self) { prompt in
                Button {
                    selectedPrompt = prompt
                    onSelect(prompt)
                } label: {
                    HStack {
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if selectedPrompt == prompt {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedPrompt == prompt ? Color(.systemBlue).opacity(0.1) : Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Tag Selector
struct TagSelector: View {
    @Binding var tags: [String]
    @Binding var tagInput: String
    var isFocused: FocusState<Bool>.Binding
    let availableTags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current tags
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Button {
                                removeTag(tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                    }
                }
            }
            
            // Tag input
            HStack {
                TextField("Add tags...", text: $tagInput)
                    .focused(isFocused)
                    .onSubmit {
                        addTag()
                    }
                
                if !tagInput.isEmpty {
                    Button {
                        addTag()
                    } label: {
                        Text("Add")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            
            // Suggested tags
            let suggestions = availableTags.filter { !tags.contains($0) }
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(suggestions.prefix(6), id: \.self) { tag in
                            Button {
                                addSuggestedTag(tag)
                            } label: {
                                Text("#\(tag)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemGray6))
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            tagInput = ""
        }
    }
    
    private func addSuggestedTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

// MARK: - Entry Search View
struct EntrySearchView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @State private var searchQuery = ""
    @State private var searchResults: [JournalEntry] = []
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search your journal...", text: $searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchQuery) { _ in
                        performSearch()
                    }
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Search results
            if isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults) { entry in
                            JournalEntryCard(entry: entry)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else if !searchQuery.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No Results Found")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Try different keywords or check your spelling")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 60)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            searchResults = dataManager.searchJournalEntries(query: searchQuery)
            isSearching = false
        }
    }
}

// MARK: - Saved Entries View
struct SavedEntriesView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    @Environment(\.dismiss) private var dismiss
    
    private var savedEntries: [JournalEntry] {
        dataManager.journalEntries.filter { $0.isSavedToSelf }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if savedEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Saved Entries")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Tap the heart icon on any entry to save it to this collection")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(savedEntries) { entry in
                                JournalEntryCard(entry: entry)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Saved Entries")
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
}

// MARK: - Full Journal Entry View
struct FullJournalEntryView: View {
    @EnvironmentObject var dataManager: EnhancedDataManager
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                    
                    // Prompt
                    if let prompt = entry.prompt {
                        promptSection(prompt)
                    }
                    
                    // Content
                    contentSection
                    
                    // Tags
                    if !entry.tags.isEmpty {
                        tagsSection
                    }
                    
                    // Metadata
                    metadataSection
                }
                .padding(20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            Task {
                                await dataManager.toggleJournalEntrySaved(entry)
                            }
                        } label: {
                            Image(systemName: entry.isSavedToSelf ? "heart.fill" : "heart")
                                .foregroundColor(entry.isSavedToSelf ? .red : .primary)
                        }
                        
                        Button {
                            Task {
                                await dataManager.toggleJournalEntryReread(entry)
                            }
                        } label: {
                            Image(systemName: entry.isMarkedForReread ? "bookmark.fill" : "bookmark")
                                .foregroundColor(entry.isMarkedForReread ? .orange : .primary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EntryEditView(entry: entry)
                .environmentObject(dataManager)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formatFullDate(entry.date))
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                if let mood = entry.mood {
                    HStack(spacing: 6) {
                        Text(mood.emoji)
                        Text(mood.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if entry.entryType != .reflection {
                    HStack(spacing: 6) {
                        Image(systemName: entry.entryType.icon)
                            .font(.caption)
                        Text(entry.entryType.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private func promptSection(_ prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prompt")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(prompt)
                .font(.subheadline)
                .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                .italic()
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.1))
                )
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Entry")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(entry.content)
                .font(.body)
                .lineSpacing(4)
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
                .fontWeight(.semibold)
            
            FlowLayout(spacing: 8) {
                ForEach(entry.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill((dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.1))
                        )
                }
            }
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                MetadataRow(label: "Word Count", value: "\(entry.wordCount) words")
                MetadataRow(label: "Reading Time", value: "\(entry.readingTime) min")
                
                if let lastEdited = entry.lastEditedDate {
                    MetadataRow(label: "Last Edited", value: formatFullDate(lastEdited))
                }
                
                if entry.isPrivate {
                    MetadataRow(label: "Privacy", value: "Private entry")
                }
            }
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

struct FilterPill: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let color: Color
    let badge: Int?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isSelected: Bool, color: Color, badge: Int? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.color = color
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MoodSelector: View {
    @Binding var selectedMood: AICheckIn.MoodRating?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AICheckIn.MoodRating.allCases, id: \.self) { mood in
                    Button {
                        selectedMood = selectedMood == mood ? nil : mood
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.title2)
                            
                            Text(mood.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedMood == mood ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMood == mood ? mood.color : Color(.systemGray6))
                        )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: proposal).offsets
        
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        let containerWidth = proposal.width ?? 0
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxY: CGFloat = 0
        
        for size in sizes {
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY = maxY + spacing
            }
            
            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            maxY = max(maxY, currentY + size.height)
        }
        
        return (offsets, CGSize(width: containerWidth, height: maxY))
    }
}

// MARK: - Enhanced Journal Filter Enum
enum JournalFilter: String, CaseIterable {
    case all = "all"
    case withPrompts = "prompts"
    case freeform = "freeform"
    case saved = "saved"
    case reread = "reread"
    case thisWeek = "week"
    case thisMonth = "month"
    case insights = "insights"
    case goals = "goals"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .withPrompts: return "Prompted"
        case .freeform: return "Freeform"
        case .saved: return "Saved"
        case .reread: return "Re-read"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .insights: return "Insights"
        case .goals: return "Goals"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "doc.text"
        case .withPrompts: return "bubble.left.and.bubble.right"
        case .freeform: return "pencil"
        case .saved: return "heart"
        case .reread: return "bookmark"
        case .thisWeek, .thisMonth: return "calendar"
        case .insights: return "lightbulb"
        case .goals: return "target"
        }
    }
    
    func badge(for dataManager: EnhancedDataManager) -> Int? {
        switch self {
        case .saved:
            let count = dataManager.journalEntries.filter { $0.isSavedToSelf }.count
            return count > 0 ? count : nil
        case .reread:
            let count = dataManager.journalEntries.filter { $0.isMarkedForReread }.count
            return count > 0 ? count : nil
        default:
            return nil
        }
    }
}

// MARK: - Journal Prompt Generator
struct JournalPromptGenerator {
    static func generatePrompts(for path: TrainingPath, type: JournalEntryType = .reflection) -> [String] {
        switch (path, type) {
        case (.discipline, .reflection):
            return [
                "What habit did I practice consistently today, and how did it make me feel?",
                "When did I choose discipline over comfort today?",
                "What challenged my willpower today, and how did I respond?",
                "How did I show up differently today compared to yesterday?",
                "What's one area where I need more discipline in my life?"
            ]
        case (.discipline, .goal):
            return [
                "What specific discipline-related goal do I want to achieve this month?",
                "How will building stronger discipline serve my long-term vision?",
                "What systems can I create to make discipline easier?",
                "What would my life look like with unshakeable discipline?"
            ]
        case (.clarity, .reflection):
            return [
                "What thoughts kept recurring in my mind today?",
                "When did I feel most mentally clear and focused?",
                "What emotions am I carrying that I need to process?",
                "How did I practice mindfulness or presence today?",
                "What beliefs am I holding that might not serve me?"
            ]
        case (.confidence, .reflection):
            return [
                "When did I step outside my comfort zone today?",
                "How did I use my voice to advocate for myself or others?",
                "What feedback did I receive that surprised me?",
                "When did I feel most confident today, and why?",
                "What social risk did I take, and what did I learn?"
            ]
        case (.purpose, .reflection):
            return [
                "How did my actions today align with my deeper values?",
                "When did I feel most connected to my sense of purpose?",
                "What impact did I make on others today?",
                "How did I invest in what matters most to me?",
                "What pulled at my heart that I want to explore further?"
            ]
        case (.authenticity, .reflection):
            return [
                "When did I show up as my most genuine self today?",
                "Where did I choose truth over people-pleasing?",
                "How did I honor my real feelings instead of hiding them?",
                "What part of myself did I express that felt authentic?",
                "When did I set a boundary that honored my true self?"
            ]
        default:
            return generateGeneralPrompts(for: type)
        }
    }
    
    private static func generateGeneralPrompts(for type: JournalEntryType) -> [String] {
        switch type {
        case .gratitude:
            return [
                "What am I most grateful for today?",
                "Who made a positive impact on my life recently?",
                "What simple pleasure brought me joy today?"
            ]
        case .insight:
            return [
                "What did I learn about myself today?",
                "What assumption was challenged today?",
                "What pattern in my behavior am I noticing?"
            ]
        case .goal:
            return [
                "What do I want to accomplish in the next 30 days?",
                "How will I measure progress toward this goal?",
                "What obstacles might I face, and how will I overcome them?"
            ]
        case .challenge:
            return [
                "What's the biggest challenge I'm facing right now?",
                "How can I reframe this challenge as an opportunity?",
                "What resources do I have to help me through this?"
            ]
        case .progress:
            return [
                "What progress have I made toward my goals this week?",
                "How have I grown compared to a month ago?",
                "What evidence do I have that I'm moving in the right direction?"
            ]
        case .reflection:
            return [
                "How am I feeling right now, and why?",
                "What was the highlight of my day?",
                "What would I do differently if I could repeat today?"
            ]
        }
    }
}
