# Core Data Model Definition - MentorApp.xcdatamodeld

This file represents the Core Data model structure that you'll need to create in Xcode. Create a new Core Data model file named `MentorApp.xcdatamodeld` and add the following entities:

## Entities and Attributes

### 1. CDUserProfile
**Entity Name:** `CDUserProfile`
- `id` (UUID, Optional: NO)
- `selectedPathRaw` (String, Optional: NO)
- `joinDate` (Date, Optional: NO)
- `currentStreak` (Integer 32, Optional: NO, Default: 0)
- `longestStreak` (Integer 32, Optional: NO, Default: 0)
- `totalChallengesCompleted` (Integer 32, Optional: NO, Default: 0)
- `subscriptionTierRaw` (String, Optional: NO, Default: "free")
- `streakBankDays` (Integer 32, Optional: NO, Default: 0)
- `lastActiveDate` (Date, Optional: YES)

### 2. CDBookRecommendation
**Entity Name:** `CDBookRecommendation`
- `id` (UUID, Optional: NO)
- `title` (String, Optional: NO)
- `author` (String, Optional: NO)
- `pathRaw` (String, Optional: NO)
- `summary` (String, Optional: NO)
- `keyInsight` (String, Optional: NO)
- `dailyAction` (String, Optional: NO)
- `coverImageURL` (String, Optional: YES)
- `amazonURL` (String, Optional: YES)
- `dateAdded` (Date, Optional: NO)
- `isSaved` (Boolean, Optional: NO, Default: NO)
- `isRead` (Boolean, Optional: NO, Default: NO)
- `dateRead` (Date, Optional: YES)
- `userRating` (Integer 16, Optional: NO, Default: 0)
- `personalNotes` (String, Optional: YES)
- `readingProgress` (Float, Optional: NO, Default: 0)
- `timeSpentReading` (Integer 32, Optional: NO, Default: 0)

**Relationships:**
- `highlights` (To Many, CDBookHighlight, Inverse: book, Delete Rule: Cascade)
- `readingSessions` (To Many, CDReadingSession, Inverse: book, Delete Rule: Cascade)

### 3. CDBookHighlight
**Entity Name:** `CDBookHighlight`
- `id` (UUID, Optional: NO)
- `text` (String, Optional: NO)
- `note` (String, Optional: YES)
- `pageNumber` (Integer 32, Optional: NO, Default: 0)
- `dateCreated` (Date, Optional: NO)

**Relationships:**
- `book` (To One, CDBookRecommendation, Inverse: highlights, Delete Rule: Nullify)

### 4. CDJournalEntry
**Entity Name:** `CDJournalEntry`
- `id` (UUID, Optional: NO)
- `date` (Date, Optional: NO)
- `content` (String, Optional: NO)
- `prompt` (String, Optional: YES)
- `moodRaw` (String, Optional: YES)
- `tagsData` (Binary Data, Optional: YES)
- `isSavedToSelf` (Boolean, Optional: NO, Default: NO)
- `isMarkedForReread` (Boolean, Optional: NO, Default: NO)
- `wordCount` (Integer 32, Optional: NO, Default: 0)
- `pathRaw` (String, Optional: YES)

### 5. CDDailyChallenge
**Entity Name:** `CDDailyChallenge`
- `id` (UUID, Optional: NO)
- `title` (String, Optional: NO)
- `challengeDescription` (String, Optional: NO)
- `pathRaw` (String, Optional: NO)
- `difficultyRaw` (String, Optional: NO)
- `date` (Date, Optional: NO)
- `isCompleted` (Boolean, Optional: NO, Default: NO)
- `completedAt` (Date, Optional: YES)
- `completionTimeMinutes` (Integer 32, Optional: NO, Default: 0)
- `userNotes` (String, Optional: YES)
- `effortLevel` (Integer 16, Optional: NO, Default: 0)

### 6. CDCheckIn
**Entity Name:** `CDCheckIn`
- `id` (UUID, Optional: NO)
- `date` (Date, Optional: NO)
- `timeOfDayRaw` (String, Optional: NO)
- `prompt` (String, Optional: NO)
- `userResponse` (String, Optional: YES)
- `aiResponse` (String, Optional: YES)
- `moodRaw` (String, Optional: YES)
- `effortLevel` (Integer 16, Optional: NO, Default: 0)
- `pathRaw` (String, Optional: NO)

### 7. CDReadingGoal
**Entity Name:** `CDReadingGoal`
- `id` (UUID, Optional: NO)
- `title` (String, Optional: NO)
- `targetCount` (Integer 32, Optional: NO)
- `currentCount` (Integer 32, Optional: NO, Default: 0)
- `typeRaw` (String, Optional: NO)
- `startDate` (Date, Optional: NO)
- `endDate` (Date, Optional: NO)
- `isCompleted` (Boolean, Optional: NO, Default: NO)
- `pathRaw` (String, Optional: YES)

### 8. CDReadingSession
**Entity Name:** `CDReadingSession`
- `id` (UUID, Optional: NO)
- `startTime` (Date, Optional: NO)
- `endTime` (Date, Optional: YES)
- `durationMinutes` (Integer 32, Optional: NO, Default: 0)
- `pagesRead` (Integer 32, Optional: NO, Default: 0)
- `notes` (String, Optional: YES)

**Relationships:**
- `book` (To One, CDBookRecommendation, Inverse: readingSessions, Delete Rule: Nullify)

## Indexes

For better performance, add the following indexes:

### CDUserProfile
- `selectedPathRaw`
- `lastActiveDate`

### CDBookRecommendation
- `pathRaw`
- `isSaved`
- `isRead`
- `dateAdded`
- `dateRead`

### CDJournalEntry
- `date`
- `pathRaw`
- `isSavedToSelf`
- `isMarkedForReread`

### CDDailyChallenge
- `date`
- `pathRaw`
- `isCompleted`
- `completedAt`

### CDCheckIn
- `date`
- `pathRaw`
- `timeOfDayRaw`

### CDReadingGoal
- `endDate`
- `isCompleted`
- `pathRaw`

### CDReadingSession
- `startTime`
- `endTime`

## Configuration

### CloudKit Integration (Optional)
If you want to sync data across devices:

1. Enable CloudKit for the Core Data model
2. Mark all entities as "Publishable to CloudKit"
3. Set appropriate CloudKit container settings
4. Add CloudKit capability to your app

### Versioning
- Set the model version to 1.0
- Enable automatic lightweight migration
- Plan for future schema migrations as features evolve

## Usage Notes

1. **Create the Model**: In Xcode, create a new Core Data model file named `MentorApp.xcdatamodeld`
2. **Add Entities**: Create each entity with the specified attributes and relationships
3. **Set Data Types**: Ensure all attribute types match the specifications above
4. **Configure Relationships**: Set up the relationships with proper inverse relationships and delete rules
5. **Add Indexes**: Create indexes on frequently queried attributes for better performance
6. **Generate Classes**: Let Xcode generate NSManagedObject subclasses or use the manual classes provided

## Migration Strategy

For future updates:
1. Create a new model version
2. Set up mapping models for complex migrations
3. Use lightweight migration when possible
4. Test migrations thoroughly with real data

This Core Data model provides:
- **Robust offline storage** for all app data
- **Efficient querying** with proper indexes
- **Relationship management** between related entities
- **Performance optimization** for common operations
- **Scalability** for future feature additions
- **CloudKit readiness** for cross-device sync