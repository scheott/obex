import Foundation

// MARK: - Challenge Generator
struct ChallengeGenerator {
    
    // MARK: - Public Interface
    static func generateChallenge(for path: TrainingPath, difficulty: DailyChallenge.ChallengeDifficulty = .micro) -> DailyChallenge {
        let challenges = getChallenges(for: path, difficulty: difficulty)
        let randomChallenge = challenges.randomElement() ?? defaultChallenge(for: path, difficulty: difficulty)
        
        return DailyChallenge(
            title: randomChallenge.title,
            description: randomChallenge.description,
            path: path,
            difficulty: difficulty,
            date: Date()
        )
    }
    
    // MARK: - Challenge Templates
    private struct ChallengeTemplate {
        let title: String
        let description: String
    }
    
    // MARK: - Path-Specific Challenges
    private static func getChallenges(for path: TrainingPath, difficulty: DailyChallenge.ChallengeDifficulty) -> [ChallengeTemplate] {
        switch path {
        case .discipline:
            return getDisciplineChallenges(difficulty: difficulty)
        case .clarity:
            return getClarityChallenges(difficulty: difficulty)
        case .confidence:
            return getConfidenceChallenges(difficulty: difficulty)
        case .purpose:
            return getPurposeChallenges(difficulty: difficulty)
        case .authenticity:
            return getAuthenticityChallenges(difficulty: difficulty)
        }
    }
    
    // MARK: - Discipline Challenges
    private static func getDisciplineChallenges(difficulty: DailyChallenge.ChallengeDifficulty) -> [ChallengeTemplate] {
        switch difficulty {
        case .micro:
            return [
                ChallengeTemplate(title: "No Sugar Until Sunset", description: "Avoid all added sugars, candy, and desserts until the sun goes down. Drink water when you crave something sweet."),
                ChallengeTemplate(title: "Make Your Bed Perfectly", description: "Make your bed with military precision. Smooth corners, aligned pillows. Start your day with one immediate win."),
                ChallengeTemplate(title: "Two-Minute Cold Shower", description: "End your shower with 2 minutes of cold water. Focus on controlled breathing, not fighting the discomfort."),
                ChallengeTemplate(title: "Phone-Free First Hour", description: "Don't check your phone for the first hour after waking up. Use this time for intentional morning activities."),
                ChallengeTemplate(title: "5 Push-ups Every Hour", description: "Set a timer and do 5 push-ups at the top of every hour you're awake. Build micro-habits of movement."),
                ChallengeTemplate(title: "Say No to One Thing", description: "Decline one request, invitation, or temptation today. Practice the discipline of selective commitment."),
                ChallengeTemplate(title: "Eat Lunch Standing", description: "Stand while eating your lunch today. Break the automatic pattern of always sitting while eating."),
                ChallengeTemplate(title: "Take the Stairs", description: "Use stairs instead of elevators/escalators every time today. Choose the harder path when available."),
                ChallengeTemplate(title: "Clean for 5 Minutes", description: "Set a timer for 5 minutes and clean something in your space. Build the habit of maintaining your environment."),
                ChallengeTemplate(title: "No Complaints Out Loud", description: "Catch yourself before complaining verbally. If you notice a complaint coming, reframe it or stay silent.")
            ]
        case .standard:
            return [
                ChallengeTemplate(title: "24-Hour Social Media Fast", description: "Go 24 hours without checking any social media platforms. Notice the urges and redirect that energy productively."),
                ChallengeTemplate(title: "Wake Up 30 Minutes Earlier", description: "Set your alarm 30 minutes earlier than usual. Use the extra time for something that matters to you."),
                ChallengeTemplate(title: "No Processed Food Today", description: "Eat only whole, unprocessed foods today. If it comes in a package with more than 3 ingredients, avoid it."),
                ChallengeTemplate(title: "Complete Your Most Avoided Task", description: "Identify the one task you've been putting off and complete it today. Start within the first 2 hours of your day."),
                ChallengeTemplate(title: "30-Minute Walk Without Distractions", description: "Take a 30-minute walk with no phone, music, or podcasts. Just you, your thoughts, and movement."),
                ChallengeTemplate(title: "Write 500 Words", description: "Write 500 words about anything - thoughts, goals, stories. Build the discipline of daily creative output."),
                ChallengeTemplate(title: "One Meal Prep Session", description: "Prepare at least 3 meals for the week ahead. Build the discipline of planning and preparation."),
                ChallengeTemplate(title: "Read Instead of Watch", description: "Replace all screen entertainment with reading today. Choose growth over passive consumption.")
            ]
        case .advanced:
            return [
                ChallengeTemplate(title: "48-Hour Dopamine Fast", description: "Avoid high-dopamine activities: social media, junk food, entertainment, shopping. Focus on basic needs and meaningful work."),
                ChallengeTemplate(title: "Daily 5AM Club", description: "Wake up at 5 AM for the next 7 days. Use the early hours for personal development activities."),
                ChallengeTemplate(title: "One Week No Excuses", description: "For 7 days, eliminate all excuses from your vocabulary and thoughts. When challenged, find solutions instead of reasons why not."),
                ChallengeTemplate(title: "Create a New Keystone Habit", description: "Establish one new daily habit that will improve multiple areas of your life. Commit to it for 30 days starting today.")
            ]
        }
    }
    
    // MARK: - Clarity Challenges
    private static func getClarityChallenges(difficulty: DailyChallenge.ChallengeDifficulty) -> [ChallengeTemplate] {
        switch difficulty {
        case .micro:
            return [
                ChallengeTemplate(title: "Three Thoughts to Delete", description: "Write down 3 recurring negative or unproductive thoughts. Acknowledge them, then mentally 'delete' them."),
                ChallengeTemplate(title: "5-Minute Breathing Focus", description: "Spend 5 minutes focusing only on your breath. When your mind wanders, gently return to breathing."),
                ChallengeTemplate(title: "Name Your Current Emotion", description: "Every hour, pause and identify exactly what emotion you're feeling. Build emotional awareness."),
                ChallengeTemplate(title: "Single-Task for One Hour", description: "Pick one important task and work on only that for one full hour. No multitasking, no distractions."),
                ChallengeTemplate(title: "Question One Assumption", description: "Identify one thing you assume to be true about yourself or your situation. Question whether it's actually true."),
                ChallengeTemplate(title: "Write Morning Priorities", description: "Before checking your phone, write down your top 3 priorities for the day. Let intention guide your day."),
                ChallengeTemplate(title: "Observe Without Judging", description: "For 10 minutes, observe people around you without making any judgments. Just notice what you see."),
                ChallengeTemplate(title: "One Distraction-Free Conversation", description: "Have one conversation today without checking your phone or letting your mind wander. Be fully present."),
                ChallengeTemplate(title: "Pause Before Reacting", description: "Before responding to any frustration today, take 3 deep breaths. Create space between stimulus and response."),
                ChallengeTemplate(title: "Mental Declutter", description: "Write down everything on your mind for 5 minutes. Get the mental noise out of your head and onto paper.")
            ]
        case .standard:
            return [
                ChallengeTemplate(title: "Morning Pages", description: "Write 3 pages of stream-of-consciousness thoughts first thing in the morning. Clear mental fog and gain clarity."),
                ChallengeTemplate(title: "Digital Sunset", description: "No screens 2 hours before bedtime. Use this time for reflection, reading, or calming activities."),
                ChallengeTemplate(title: "Mindful Eating Session", description: "Eat one meal in complete silence, focusing entirely on taste, texture, and the eating experience."),
                ChallengeTemplate(title: "Values Inventory", description: "List your top 5 values and evaluate how well your current actions align with them. Identify gaps."),
                ChallengeTemplate(title: "Fear Analysis", description: "Write about something you're afraid of. Break down whether it's rational and what you'd do if the fear wasn't there."),
                ChallengeTemplate(title: "Energy Audit", description: "Track what activities give you energy vs. drain it throughout the day. Identify patterns and plan changes.")
            ]
        case .advanced:
            return [
                ChallengeTemplate(title: "Weekly Solitude Retreat", description: "Spend 4 hours alone with no entertainment, just thinking and reflecting. Create space for deep self-awareness."),
                ChallengeTemplate(title: "Belief System Audit", description: "Examine and write about your core beliefs. Question which ones serve you and which ones limit you."),
                ChallengeTemplate(title: "30-Day Meditation Streak", description: "Commit to meditating for at least 10 minutes every day for the next 30 days. Build consistent clarity practice.")
            ]
        }
    }
    
    // MARK: - Confidence Challenges
    private static func getConfidenceChallenges(difficulty: DailyChallenge.ChallengeDifficulty) -> [ChallengeTemplate] {
        switch difficulty {
        case .micro:
            return [
                ChallengeTemplate(title: "Start a Conversation", description: "Initiate a conversation with a stranger today. Could be a cashier, neighbor, or someone at the gym. Practice social courage."),
                ChallengeTemplate(title: "Speak Up in a Group", description: "Share your opinion in a group conversation today. Don't wait for the perfect moment - just contribute authentically."),
                ChallengeTemplate(title: "Make Eye Contact", description: "Maintain strong eye contact during every conversation today. Practice confident nonverbal communication."),
                ChallengeTemplate(title: "Power Pose for 2 Minutes", description: "Stand in a confident power pose (hands on hips, chest out) for 2 minutes. Embody confidence physically."),
                ChallengeTemplate(title: "Ask for Something", description: "Ask for something you want today - a discount, help with a task, or someone's time. Practice making requests confidently."),
                ChallengeTemplate(title: "Give Someone a Compliment", description: "Give a genuine, specific compliment to someone. Practice positive social interaction and spreading good energy."),
                ChallengeTemplate(title: "Speak 10% Louder", description: "Speak slightly louder than you normally would in conversations today. Project your voice with intention."),
                ChallengeTemplate(title: "Share an Unpopular Opinion", description: "Respectfully share an opinion you hold that might be unpopular. Practice standing by your authentic thoughts."),
                ChallengeTemplate(title: "Introduce Yourself First", description: "In any new social situation today, be the first person to introduce yourself. Take social leadership."),
                ChallengeTemplate(title: "Correct Someone Politely", description: "If someone gets a fact wrong in conversation, politely correct them. Practice asserting truth respectfully.")
            ]
        case .standard:
            return [
                ChallengeTemplate(title: "Give a 5-Minute Presentation", description: "Present something to a group for 5 minutes - at work, with friends, or even record yourself. Practice confident expression."),
                ChallengeTemplate(title: "Negotiate Something", description: "Negotiate a better deal on something today - salary, price, terms, or conditions. Practice advocating for yourself."),
                ChallengeTemplate(title: "Host a Social Gathering", description: "Organize and host a social gathering with friends, colleagues, or neighbors. Take social leadership."),
                ChallengeTemplate(title: "Cold Call/Email Someone", description: "Reach out to someone you don't know personally for networking, learning, or business. Practice bold outreach."),
                ChallengeTemplate(title: "Dress Up for No Reason", description: "Dress better than required for your normal day. Practice carrying yourself with elevated confidence."),
                ChallengeTemplate(title: "Lead a Group Decision", description: "Take charge when your group is indecisive about plans. Practice decisive leadership in social settings.")
            ]
        case .advanced:
            return [
                ChallengeTemplate(title: "Public Speaking Challenge", description: "Sign up for an open mic, Toastmasters, or give a presentation to a large group. Face your fear of public attention."),
                ChallengeTemplate(title: "Week of Bold Asks", description: "For 7 days, make one bold ask each day - for opportunities, connections, or experiences you want."),
                ChallengeTemplate(title: "Social Media Confidence", description: "Post something vulnerable or authentic on social media. Practice being seen for who you truly are.")
            ]
        }
    }
    
    // MARK: - Purpose Challenges
    private static func getPurposeChallenges(difficulty: DailyChallenge.ChallengeDifficulty) -> [ChallengeTemplate] {
        switch difficulty {
        case .micro:
            return [
                ChallengeTemplate(title: "Review Your 5-Year Vision", description: "Spend 3 minutes reviewing or creating your vision for where you want to be in 5 years. Connect with your bigger picture."),
                ChallengeTemplate(title: "Ask 'Why' Five Times", description: "Pick one goal or activity and ask 'why' five times in a row. Dig deep into your true motivations."),
                ChallengeTemplate(title: "Write Your Eulogy", description: "Write 2-3 sentences about how you'd want to be remembered. Clarify what legacy you want to create."),
                ChallengeTemplate(title: "Identify Your Gift", description: "Write down one unique skill, perspective, or ability you have that could benefit others. Recognize your value."),
                ChallengeTemplate(title: "Connect Daily Actions to Purpose", description: "Choose 3 activities from today and connect them to your larger life purpose. Find meaning in mundane tasks."),
                ChallengeTemplate(title: "Help Someone Today", description: "Do something helpful for someone else without being asked. Practice being of service to others."),
                ChallengeTemplate(title: "Write a Letter to Future You", description: "Write a short letter to yourself 5 years from now. What do you want to tell your future self?"),
                ChallengeTemplate(title: "List Your Core Values", description: "Write down your top 3 core values and one way you can honor each one today."),
                ChallengeTemplate(title: "Find Meaning in Struggle", description: "Identify one current challenge and write how it's helping you grow or serve a larger purpose."),
                ChallengeTemplate(title: "Practice Gratitude with Purpose", description: "Write 3 things you're grateful for and how each one connects to your life's direction.")
            ]
        case .standard:
            return [
                ChallengeTemplate(title: "Create a Personal Mission Statement", description: "Write a one-paragraph mission statement for your life. What are you here to do and become?"),
                ChallengeTemplate(title: "Volunteer for 2 Hours", description: "Spend 2 hours volunteering for a cause you care about. Connect with purpose through service."),
                ChallengeTemplate(title: "Career Alignment Check", description: "Evaluate how well your current career aligns with your values and purpose. Write an action plan for improvement."),
                ChallengeTemplate(title: "Mentor Someone", description: "Offer to mentor or help someone who's earlier in a journey you've traveled. Share your knowledge and experience."),
                ChallengeTemplate(title: "Create Something Meaningful", description: "Create something (art, writing, video, project) that expresses your values or helps others."),
                ChallengeTemplate(title: "Plan Your Ideal Day", description: "Design what your perfect day would look like if you were living completely aligned with your purpose.")
            ]
        case .advanced:
            return [
                ChallengeTemplate(title: "Purpose-Driven Project", description: "Start a 30-day project that aligns with your purpose and could impact others positively."),
                ChallengeTemplate(title: "Life Design Workshop", description: "Spend 4 hours designing your ideal life 10 years from now. Create a detailed vision and action plan."),
                ChallengeTemplate(title: "Impact Assessment", description: "Evaluate how your current life choices impact others and the world. Make adjustments to increase positive impact.")
            ]
        }
    }
    
    // MARK: - Authenticity Challenges
    private static func getAuthenticityChallenges(difficulty: DailyChallenge.ChallengeDifficulty) -> [ChallengeTemplate] {
        switch difficulty {
        case .micro:
            return [
                ChallengeTemplate(title: "Express a True Opinion", description: "Share your honest opinion about something, even if it goes against the group. Practice authentic self-expression."),
                ChallengeTemplate(title: "Wear What You Actually Like", description: "Dress in a way that reflects your true taste, not what you think others expect. Express yourself through appearance."),
                ChallengeTemplate(title: "Say No Authentically", description: "Decline something you don't want to do instead of going along with it. Honor your true preferences."),
                ChallengeTemplate(title: "Share a Personal Story", description: "Tell someone a story that reveals something real about you. Practice vulnerable authenticity."),
                ChallengeTemplate(title: "Stop Pretending", description: "Identify one way you're pretending to be someone you're not and stop doing it today."),
                ChallengeTemplate(title: "Express an Emotion", description: "Instead of hiding how you feel, express one authentic emotion to someone appropriate today."),
                ChallengeTemplate(title: "Do Something You Enjoy", description: "Spend time on an activity you genuinely enjoy but might feel embarrassed about. Embrace your authentic interests."),
                ChallengeTemplate(title: "Speak Your Mind", description: "In one conversation, say exactly what you're thinking instead of filtering it through what you think they want to hear."),
                ChallengeTemplate(title: "Admit You Don't Know", description: "When you don't know something, admit it honestly instead of pretending or deflecting."),
                ChallengeTemplate(title: "Show Your Quirks", description: "Let one of your quirky personality traits show today instead of hiding it to fit in.")
            ]
        case .standard:
            return [
                ChallengeTemplate(title: "Have a Difficult Conversation", description: "Address something you've been avoiding discussing with someone important in your life. Choose authenticity over comfort."),
                ChallengeTemplate(title: "Create Authentic Content", description: "Share something genuine about yourself on social media or in writing. Show your real self to the world."),
                ChallengeTemplate(title: "Set a Boundary", description: "Establish a clear boundary with someone in your life. Protect your authentic self by saying what you will and won't accept."),
                ChallengeTemplate(title: "Pursue Your Interest", description: "Take action on something you're genuinely interested in but haven't pursued due to fear of judgment."),
                ChallengeTemplate(title: "Be Vulnerable with Someone", description: "Share a fear, insecurity, or struggle with someone you trust. Practice authentic connection through vulnerability."),
                ChallengeTemplate(title: "Quit Something Inauthentic", description: "Stop doing something you only do because you feel you 'should' but that doesn't align with your true self.")
            ]
        case .advanced:
            return [
                ChallengeTemplate(title: "Live Your Values Publicly", description: "For one week, make decisions based purely on your authentic values, regardless of what others might think."),
                ChallengeTemplate(title: "Authentic Life Audit", description: "Examine all areas of your life and identify what's authentic vs. what's performance. Make a plan to increase authenticity."),
                ChallengeTemplate(title: "Share Your Truth", description: "Write and share (blog, video, conversation) about something you've never been fully honest about but that defines who you are.")
            ]
        }
    }
    
    // MARK: - Fallback Challenge
    private static func defaultChallenge(for path: TrainingPath, difficulty: DailyChallenge.ChallengeDifficulty) -> ChallengeTemplate {
        switch path {
        case .discipline:
            return ChallengeTemplate(title: "Build One Small Habit", description: "Choose one small positive action and commit to doing it consistently today.")
        case .clarity:
            return ChallengeTemplate(title: "5-Minute Reflection", description: "Spend 5 minutes in quiet reflection about your current thoughts and feelings.")
        case .confidence:
            return ChallengeTemplate(title: "Take One Bold Action", description: "Do one thing today that requires courage and pushes your comfort zone.")
        case .purpose:
            return ChallengeTemplate(title: "Connect to Your Why", description: "Spend time connecting your daily actions to your larger life purpose.")
        case .authenticity:
            return ChallengeTemplate(title: "Be True to Yourself", description: "Make one decision today based purely on your authentic self, not what others expect.")
        }
    }
}
