import SwiftUI

// MARK: - Journal View
struct JournalView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingNewEntry = false
    @State private var searchText = ""
    @State private var selectedFilter: JournalFilter = .all
    @State private var showingFilterMenu = false
    @State private var showingWeeklySummary = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Journal Entries List
                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    entriesListView
                }
            }
            .navigationTitle("Reflection Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingWeeklySummary = true
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewEntry = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewJournalEntryView()
            }
            .sheet(isPresented: $showingWeeklySummary) {
                WeeklySummaryView()
            }
            .confirmationDialog("Filter Entries", isPresented: $showingFilterMenu) {
                ForEach(JournalFilter.allCases, id: \.self) { filter in
                    Button(filter.displayName) {
                        selectedFilter = filter
                    }
                }
            }
        }
    }
    
    // MARK: - Search and Filter Bar
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search journal entries...", text: $searchText)
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
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(JournalFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            Text(filter.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedFilter == filter ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedFilter == filter ? 
                                              (dataManager.userProfile?.selectedPath.color ?? .blue) : 
                                              Color(.systemGray5))
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "Start Your Journey" : "No Entries Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty ? 
                     "Begin reflecting and documenting your growth through daily journaling." :
                     "Try adjusting your search or filter to find entries.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if searchText.isEmpty {
                Button {
                    showingNewEntry = true
                } label: {
                    Text("Write First Entry")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(dataManager.userProfile?.selectedPath.color ?? .blue)
                        )
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Entries List View
    private var entriesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredEntries) { entry in
                    JournalEntryCard(entry: entry)
                        .onTapGesture {
                            // Could open detail view here
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
        }
        
        // Sort by date (newest first)
        return entries.sorted { $0.date > $1.date }
    }
}

// MARK: - Journal Filter Enum
enum JournalFilter: String, CaseIterable {
    case all = "all"
    case withPrompts = "prompts"
    case freeform = "freeform"
    case saved = "saved"
    case reread = "reread"
    case thisWeek = "week"
    case thisMonth = "month"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .withPrompts: return "Prompted"
        case .freeform: return "Freeform"
        case .saved: return "Saved"
        case .reread: return "Re-read"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        }
    }
}

// MARK: - Journal Entry Card
struct JournalEntryCard: View {
    @EnvironmentObject var dataManager: DataManager
    let entry: JournalEntry
    @State private var isExpanded = false
    @State private var showingFullEntry = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and mood
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(entry.date))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let prompt = entry.prompt {
                        Text("Prompted Entry")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if let mood = entry.mood {
                        Text(mood.emoji)
                            .font(.title3)
                    }
                    
                    if entry.isSavedToSelf {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if entry.isMarkedForReread {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Prompt (if exists)
            if let prompt = entry.prompt {
                Text(prompt)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    .italic()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.1))
                    )
            }
            
            // Content preview
            Text(entry.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(isExpanded ? nil : 4)
                .onTapGesture {
                    showingFullEntry = true
                }
            
            // Tags
            if !entry.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(entry.tags, id: \.self) { tag in
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
            
            // Action buttons
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show Less" : "Read More")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
                
                Spacer()
                
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .sheet(isPresented: $showingFullEntry) {
            FullJournalEntryView(entry: entry)
        }
    }
    
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
        if let index = dataManager.journalEntries.firstIndex(where: { $0.id == entry.id }) {
            dataManager.journalEntries[index].isSavedToSelf.toggle()
            // In a real app, this would trigger a save to persistence
        }
    }
    
    private func toggleReread() {
        if let index = dataManager.journalEntries.firstIndex(where: { $0.id == entry.id }) {
            dataManager.journalEntries[index].isMarkedForReread.toggle()
            // In a real app, this would trigger a save to persistence
        }
    }
}

// MARK: - New Journal Entry View
struct NewJournalEntryView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var selectedMood: AICheckIn.MoodRating?
    @State private var tags: [String] = []
    @State private var tagInput = ""
    @State private var usePrompt = false
    @State private var selectedPrompt = ""
    @State private var availablePrompts: [String] = []
    @FocusState private var isContentFocused: Bool
    @FocusState private var isTagFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Prompt Section
                    promptSection
                    
                    // Content Section
                    contentSection
                    
                    // Mood Section
                    moodSection
                    
                    // Tags Section
                    tagsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
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
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                generatePrompts()
            }
        }
    }
    
    // MARK: - Prompt Section
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Use Writing Prompt", isOn: $usePrompt)
                .font(.headline)
                .fontWeight(.semibold)
            
            if usePrompt {
                VStack(spacing: 12) {
                    ForEach(availablePrompts, id: \.self) { prompt in
                        Button {
                            selectedPrompt = prompt
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prompt)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                if selectedPrompt == prompt {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedPrompt == prompt ? 
                                          (dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.1) : 
                                          Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedPrompt == prompt ? 
                                            (dataManager.userProfile?.selectedPath.color ?? .blue) : 
                                            Color.clear, lineWidth: 2)
                            )
                        }
                    }
                    
                    Button {
                        generatePrompts()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Get New Prompts")
                        }
                        .font(.subheadline)
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    }
                }
            }
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Reflection")
                .font(.headline)
                .fontWeight(.semibold)
            
            if usePrompt && !selectedPrompt.isEmpty {
                Text(selectedPrompt)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                    .italic()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.1))
                    )
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(minHeight: 200)
                
                if content.isEmpty {
                    Text("Write about your thoughts, feelings, experiences, or insights...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }
                
                TextEditor(text: $content)
                    .focused($isContentFocused)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isContentFocused ? 
                            (dataManager.userProfile?.selectedPath.color ?? .blue) : 
                            Color.clear, lineWidth: 2)
            )
            
            HStack {
                Spacer()
                Text("\(content.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Mood Section
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Mood (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 8) {
                ForEach(AICheckIn.MoodRating.allCases, id: \.self) { mood in
                    Button {
                        selectedMood = selectedMood == mood ? nil : mood
                    } label: {
                        VStack(spacing: 6) {
                            Text(mood.emoji)
                                .font(.title2)
                            
                            Text(mood.rawValue.capitalized)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMood == mood ? 
                                      (dataManager.userProfile?.selectedPath.color ?? .blue).opacity(0.2) : 
                                      Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedMood == mood ? 
                                        (dataManager.userProfile?.selectedPath.color ?? .blue) : 
                                        Color.clear, lineWidth: 2)
                        )
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Tag input
            HStack {
                TextField("Add a tag...", text: $tagInput)
                    .focused($isTagFocused)
                    .onSubmit {
                        addTag()
                    }
                
                Button {
                    addTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(dataManager.userProfile?.selectedPath.color ?? .blue)
                }
                .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            
            // Current tags
            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Button {
                                removeTag(tag)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(dataManager.userProfile?.selectedPath.color ?? .blue)
                        )
                    }
                }
            }
            
            // Suggested tags
            let suggestedTags = getSuggestedTags()
            if !suggestedTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Tags")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(suggestedTags, id: \.self) { tag in
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
    
    // MARK: - Helper Methods
    private func generatePrompts() {
        guard let path = dataManager.userProfile?.selectedPath else { return }
        
        let prompts = JournalPromptGenerator.generatePrompts(for: path)
        availablePrompts = Array(prompts.prefix(3))
        selectedPrompt = availablePrompts.first ?? ""
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
    
    private func getSuggestedTags() -> [String] {
        guard let path = dataManager.userProfile?.selectedPath else { return [] }
        
        let pathTags = [
            .discipline: ["habits", "willpower", "consistency", "goals", "routine"],
            .clarity: ["mindfulness", "thoughts", "emotions", "focus", "awareness"],
            .confidence: ["courage", "social", "leadership", "voice", "boldness"],
            .purpose: ["values", "meaning", "service", "vision", "legacy"],
            .authenticity: ["truth", "vulnerability", "genuine", "real", "expression"]
        ]
        
        let baseTags = pathTags[path] ?? []
        return baseTags.filter { !tags.contains($0) }
    }
    
    private func saveEntry() {
        let entry = JournalEntry(
            date: Date(),
            content: content,
            prompt: usePrompt ? selectedPrompt : nil,
            mood: selectedMood,
            tags: tags
        )
        
        dataManager.addJournalEntry(entry)
        dismiss()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Full Journal Entry View
struct FullJournalEntryView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formatFullDate(entry.date))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if let mood = entry.mood {
                            HStack {
                                Text(mood.emoji)
                                Text("Feeling \(mood.rawValue)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Prompt
                    if let prompt = entry.prompt {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prompt")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(prompt)
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(.blue)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Entry")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(entry.content)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    // Tags
                    if !entry.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            FlowLayout(spacing: 6) {
                                ForEach(entry.tags, id: \.self) { tag in
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
                .padding(20)
            }
            .navigationTitle("Journal Entry")
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
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Weekly Summary View
struct WeeklySummaryView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Weekly insights and patterns from your journal entries coming soon!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle("Weekly Summary")
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

// MARK: - Journal Prompt Generator
struct JournalPromptGenerator {
    static func generatePrompts(for path: TrainingPath) -> [String] {
        switch path {
        case .discipline:
            return [
                "What habit am I most proud of building, and what habit do I want to develop next?",
                "When did I choose discipline over comfort this week, and how did it feel?",
                "What resistance am I feeling right now, and what is it trying to teach me?",
                "If I could give my past self one piece of advice about discipline, what would it be?",
                "What small act of discipline could I commit to that would compound over time?"
            