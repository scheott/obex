import Foundation

// MARK: - Book Generator
struct BookGenerator {
    
    // MARK: - Public Interface
    static func generateRecommendations(for path: TrainingPath, count: Int = 3) -> [BookRecommendation] {
        let allBooks = getBooks(for: path)
        let shuffledBooks = allBooks.shuffled()
        let selectedBooks = Array(shuffledBooks.prefix(count))
        
        return selectedBooks.map { template in
            BookRecommendation(
                title: template.title,
                author: template.author,
                path: path,
                summary: template.summary,
                keyInsight: template.keyInsight,
                dailyAction: template.dailyAction,
                coverImageURL: template.coverImageURL,
                amazonURL: template.amazonURL,
                dateAdded: Date()
            )
        }
    }
    
    static func getBookOfTheDay(for path: TrainingPath) -> BookRecommendation? {
        let books = getBooks(for: path)
        guard let randomBook = books.randomElement() else { return nil }
        
        return BookRecommendation(
            title: randomBook.title,
            author: randomBook.author,
            path: path,
            summary: randomBook.summary,
            keyInsight: randomBook.keyInsight,
            dailyAction: randomBook.dailyAction,
            coverImageURL: randomBook.coverImageURL,
            amazonURL: randomBook.amazonURL,
            dateAdded: Date()
        )
    }
    
    static func searchBooks(for path: TrainingPath, query: String) -> [BookRecommendation] {
        let allBooks = getBooks(for: path)
        let filteredBooks = allBooks.filter { book in
            book.title.localizedCaseInsensitiveContains(query) ||
            book.author.localizedCaseInsensitiveContains(query) ||
            book.summary.localizedCaseInsensitiveContains(query) ||
            book.keyInsight.localizedCaseInsensitiveContains(query)
        }
        
        return filteredBooks.map { template in
            BookRecommendation(
                title: template.title,
                author: template.author,
                path: path,
                summary: template.summary,
                keyInsight: template.keyInsight,
                dailyAction: template.dailyAction,
                coverImageURL: template.coverImageURL,
                amazonURL: template.amazonURL,
                dateAdded: Date()
            )
        }
    }
    
    // MARK: - Book Template
    private struct BookTemplate {
        let title: String
        let author: String
        let summary: String
        let keyInsight: String
        let dailyAction: String
        let coverImageURL: String?
        let amazonURL: String?
    }
    
    // MARK: - Path-Specific Books
    private static func getBooks(for path: TrainingPath) -> [BookTemplate] {
        switch path {
        case .discipline:
            return getDisciplineBooks()
        case .clarity:
            return getClarityBooks()
        case .confidence:
            return getConfidenceBooks()
        case .purpose:
            return getPurposeBooks()
        case .authenticity:
            return getAuthenticityBooks()
        }
    }
    
    // MARK: - Discipline Books
    private static func getDisciplineBooks() -> [BookTemplate] {
        return [
            BookTemplate(
                title: "Atomic Habits",
                author: "James Clear",
                summary: "The definitive guide to building good habits and breaking bad ones. Clear explains how tiny changes compound into remarkable results through the four laws of behavior change.",
                keyInsight: "You don't rise to the level of your goals, you fall to the level of your systems. Focus on systems, not outcomes.",
                dailyAction: "Identify one habit you want to build and make it 1% easier to do today. Remove friction from good behaviors.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0735211299"
            ),
            BookTemplate(
                title: "Can't Hurt Me",
                author: "David Goggins",
                summary: "A Navy SEAL's brutal journey from broken childhood to elite warrior. Goggins shares his philosophy of embracing discomfort and pushing past mental barriers.",
                keyInsight: "The 40% Rule: When you think you're done, you're only 40% done. Your mind will quit long before your body needs to.",
                dailyAction: "Do something hard today that you don't want to do. Practice being comfortable with discomfort.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1544512287"
            ),
            BookTemplate(
                title: "Discipline Equals Freedom",
                author: "Jocko Willink",
                summary: "A former Navy SEAL commander's guide to discipline as the path to freedom. Simple, direct principles for building mental toughness and taking ownership.",
                keyInsight: "Discipline equals freedom. The more disciplined you are, the more freedom you have in life.",
                dailyAction: "Wake up earlier than planned tomorrow. Use the extra time for something that improves your life.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1250156947"
            ),
            BookTemplate(
                title: "The Compound Effect",
                author: "Darren Hardy",
                summary: "How small, smart choices compound over time to create radical differences in your life. The power of consistency and incremental improvement.",
                keyInsight: "Small, smart choices + consistency + time = radical difference. Success is not about massive action, but consistent action.",
                dailyAction: "Choose one small positive action and commit to doing it for the next 7 days without fail.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0985529954"
            ),
            BookTemplate(
                title: "The 5 AM Club",
                author: "Robin Sharma",
                summary: "A formula for early rising that helps you own your morning and elevate your life. The power of starting your day with intention and focus.",
                keyInsight: "How you start your day determines how you live your day. Win the morning, win the day.",
                dailyAction: "Set your alarm 15 minutes earlier tomorrow and use that time for personal development.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1443456624"
            ),
            BookTemplate(
                title: "The Willpower Instinct",
                author: "Kelly McGonigal",
                summary: "Stanford psychologist's science-based approach to understanding and strengthening willpower. How to resist temptation and achieve your goals.",
                keyInsight: "Willpower is like a muscle - it can be strengthened with practice but also gets fatigued with overuse.",
                dailyAction: "Practice saying no to one small temptation today to strengthen your willpower muscle.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1583335080"
            ),
            BookTemplate(
                title: "The Power of Now",
                author: "Eckhart Tolle",
                summary: "A guide to spiritual enlightenment through present-moment awareness. How to stop living in the past and future and find peace in the now.",
                keyInsight: "The present moment is the only time over which we have dominion. Life is now.",
                dailyAction: "When you catch your mind wandering to past or future today, gently bring attention back to the present moment.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1577314808"
            )
        ]
    }
    
    // MARK: - Clarity Books
    private static func getClarityBooks() -> [BookTemplate] {
        return [
            BookTemplate(
                title: "Thinking, Fast and Slow",
                author: "Daniel Kahneman",
                summary: "Nobel laureate explores the two systems of thinking: fast, intuitive System 1 and slow, deliberate System 2. Understanding how your mind makes decisions.",
                keyInsight: "We have two thinking systems: fast and emotional vs. slow and rational. Most decisions come from the fast system, which is prone to biases.",
                dailyAction: "Before making any significant decision today, pause and engage your slow thinking system. Ask: 'What am I not considering?'",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0374533555"
            ),
            BookTemplate(
                title: "The Untethered Soul",
                author: "Michael Singer",
                summary: "A journey beyond yourself to find inner peace and freedom. How to observe your thoughts without being controlled by them.",
                keyInsight: "You are not your thoughts. You are the consciousness observing your thoughts. This awareness creates freedom.",
                dailyAction: "When negative thoughts arise today, step back and observe them as clouds passing in the sky of your consciousness.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1572245379"
            ),
            BookTemplate(
                title: "Mindset",
                author: "Carol Dweck",
                summary: "Stanford psychologist reveals how our beliefs about ability shape our success. The difference between fixed and growth mindsets.",
                keyInsight: "People with a growth mindset believe abilities can be developed through effort. This leads to resilience and higher achievement.",
                dailyAction: "When facing a challenge today, ask 'How can I learn from this?' instead of 'Can I do this?'",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0345472322"
            ),
            BookTemplate(
                title: "Man's Search for Meaning",
                author: "Viktor Frankl",
                summary: "Holocaust survivor's profound insights on finding purpose in suffering. How meaning, not happiness, is the key to psychological resilience.",
                keyInsight: "Everything can be taken from you except the freedom to choose your attitude in any given circumstances.",
                dailyAction: "Identify one current challenge and find a way it's helping you grow or serve others.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/080701429X"
            ),
            BookTemplate(
                title: "The Clarity Cleanse",
                author: "Habib Sadeghi",
                summary: "A 12-step process for releasing emotional toxicity and achieving mental clarity. How to identify and release limiting beliefs.",
                keyInsight: "Emotional clarity comes from releasing attachment to outcomes and accepting what is while working toward what could be.",
                dailyAction: "Write down one limiting belief you hold about yourself and question its validity with evidence.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1501154346"
            ),
            BookTemplate(
                title: "Digital Minimalism",
                author: "Cal Newport",
                summary: "A philosophy for living more intentionally in an age of digital distraction. How to reclaim your attention and focus.",
                keyInsight: "Clutter is costly. Digital clutter robs you of attention, which is your most valuable resource in the modern economy.",
                dailyAction: "Remove one app from your phone that provides little value but consumes significant attention.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0525536515"
            ),
            BookTemplate(
                title: "Wherever You Go, There You Are",
                author: "Jon Kabat-Zinn",
                summary: "An introduction to mindfulness meditation and present-moment awareness. How to find peace and clarity through mindful living.",
                keyInsight: "Mindfulness is paying attention in a particular way: on purpose, in the present moment, non-judgmentally.",
                dailyAction: "Spend 5 minutes today eating mindfully - no distractions, just awareness of taste, texture, and sensation.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1401307787"
            )
        ]
    }
    
    // MARK: - Confidence Books
    private static func getConfidenceBooks() -> [BookTemplate] {
        return [
            BookTemplate(
                title: "The Confidence Code",
                author: "Kay & Shipman",
                summary: "Scientific research on confidence reveals it's more important than competence for success. How to build genuine confidence through action.",
                keyInsight: "Confidence is not about thinking you're perfect. It's about being willing to try despite imperfection.",
                dailyAction: "Do one thing today you're not 100% sure you can do well. Build confidence through action, not preparation.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/006223062X"
            ),
            BookTemplate(
                title: "Presence",
                author: "Amy Cuddy",
                summary: "Harvard psychologist shows how body language shapes who you are. The science of power posing and embodying confidence.",
                keyInsight: "Don't fake it till you make it. Fake it till you become it. Your body language changes your mind.",
                dailyAction: "Before any challenging interaction today, spend 2 minutes in a power pose to embody confidence.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0316256579"
            ),
            BookTemplate(
                title: "Daring Greatly",
                author: "Brené Brown",
                summary: "Research on vulnerability reveals it's the birthplace of courage, creativity, and change. How to show up and be seen.",
                keyInsight: "Vulnerability is not weakness. It's emotional risk, exposure, uncertainty - and the birthplace of courage.",
                dailyAction: "Share something slightly vulnerable with someone you trust today. Practice courage through authentic connection.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1592408419"
            ),
            BookTemplate(
                title: "How to Win Friends and Influence People",
                author: "Dale Carnegie",
                summary: "Timeless principles for building relationships and social influence. The foundation of interpersonal confidence and leadership.",
                keyInsight: "You can make more friends in two months by becoming interested in other people than in two years trying to get people interested in you.",
                dailyAction: "In every conversation today, focus on being genuinely interested in the other person rather than trying to impress them.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0671027034"
            ),
            BookTemplate(
                title: "The Charisma Myth",
                author: "Olivia Fox Cabane",
                summary: "Charisma is not an inborn trait but a learnable skill. Practical techniques for presence, power, and warmth.",
                keyInsight: "Charisma is the result of specific behaviors: presence, power, and warmth. These can be developed through practice.",
                dailyAction: "In one conversation today, practice full presence - put away distractions and give complete attention to the person.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1591845947"
            ),
            BookTemplate(
                title: "The Like Switch",
                author: "Jack Schafer",
                summary: "Former FBI agent reveals techniques for getting people to like you in 90 seconds or less. The science of rapport and influence.",
                keyInsight: "People like people who make them feel good about themselves. Focus on making others feel valued and appreciated.",
                dailyAction: "Give one person a genuine, specific compliment today that makes them feel valued and seen.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1476754489"
            ),
            BookTemplate(
                title: "The Art of Possibility",
                author: "Rosamund & Benjamin Zander",
                summary: "A transformational approach to life and leadership. How to see opportunities instead of obstacles and inspire others.",
                keyInsight: "It's all invented. The stories we tell ourselves about reality are just that - stories. We can choose more empowering narratives.",
                dailyAction: "Reframe one limiting story you tell about yourself into a possibility-focused narrative.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0142001104"
            )
        ]
    }
    
    // MARK: - Purpose Books
    private static func getPurposeBooks() -> [BookTemplate] {
        return [
            BookTemplate(
                title: "Start With Why",
                author: "Simon Sinek",
                summary: "How great leaders inspire action by starting with purpose. The golden circle of why, how, and what.",
                keyInsight: "People don't buy what you do, they buy why you do it. Start with your purpose, not your product.",
                dailyAction: "Write down why you do what you do. What's the deeper purpose behind your work and goals?",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1591846447"
            ),
            BookTemplate(
                title: "The Purpose Driven Life",
                author: "Rick Warren",
                summary: "A spiritual journey to discover your reason for being alive. Five purposes that form the foundation of purposeful living.",
                keyInsight: "You were made by God and for God. Until you understand that, life will never make sense.",
                dailyAction: "Reflect on how you can serve something bigger than yourself today through your unique gifts and abilities.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0310205719"
            ),
            BookTemplate(
                title: "Drive",
                author: "Daniel Pink",
                summary: "The science of motivation reveals autonomy, mastery, and purpose drive performance better than rewards and punishment.",
                keyInsight: "True motivation comes from autonomy (control), mastery (getting better), and purpose (serving something larger).",
                dailyAction: "Identify one skill you want to master and take one small step toward improvement today.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1594484805"
            ),
            BookTemplate(
                title: "The Alchemist",
                author: "Paulo Coelho",
                summary: "A shepherd's journey teaches us about following our dreams and listening to our hearts. The universe conspires to help those who pursue their purpose.",
                keyInsight: "When you want something, all the universe conspires in helping you to achieve it. Follow your personal legend.",
                dailyAction: "Take one concrete step today toward a dream you've been putting off or neglecting.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0061122416"
            ),
            BookTemplate(
                title: "Designing Your Life",
                author: "Burnett & Evans",
                summary: "Stanford design professors apply design thinking to life planning. How to build a well-lived, joyful life through prototyping and iteration.",
                keyInsight: "Life design is not about finding your passion. It's about designing multiple possible lives and choosing the one that works best.",
                dailyAction: "Write down three different versions of your 5-year plan. Explore multiple possibilities for your future.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1101875321"
            ),
            BookTemplate(
                title: "The 7 Habits of Highly Effective People",
                author: "Stephen Covey",
                summary: "Timeless principles for personal and interpersonal effectiveness. Character-based approach to success and leadership.",
                keyInsight: "Begin with the end in mind. All things are created twice - first mentally, then physically.",
                dailyAction: "Write your personal mission statement. What do you want to be and do based on your values?",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1982137274"
            ),
            BookTemplate(
                title: "Ikigai",
                author: "García & Miralles",
                summary: "Japanese concept of life's purpose - the intersection of what you love, what you're good at, what the world needs, and what you can be paid for.",
                keyInsight: "Ikigai is found at the intersection of passion, mission, profession, and vocation. Purpose requires all four elements.",
                dailyAction: "Draw four circles representing what you love, what you're good at, what the world needs, and what pays you. Find overlaps.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0143130722"
            )
        ]
    }
    
    // MARK: - Authenticity Books
    private static func getAuthenticityBooks() -> [BookTemplate] {
        return [
            BookTemplate(
                title: "The Gifts of Imperfection",
                author: "Brené Brown",
                summary: "A guide to wholehearted living through self-compassion and vulnerability. How to let go of perfectionism and embrace your authentic self.",
                keyInsight: "Authenticity is the daily practice of letting go of who we think we're supposed to be and embracing who we are.",
                dailyAction: "Choose authenticity over approval in one situation today. Be real rather than what you think others want.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/159285849X"
            ),
            BookTemplate(
                title: "The Four Agreements",
                author: "Don Miguel Ruiz",
                summary: "Ancient Toltec wisdom for personal freedom. Four simple agreements that can transform your life and relationships.",
                keyInsight: "Don't take anything personally. What others say and do is a projection of their own reality, not yours.",
                dailyAction: "Practice one of the four agreements today: be impeccable with your word, don't take things personally, don't make assumptions, or always do your best.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1878424319"
            ),
            BookTemplate(
                title: "Radical Acceptance",
                author: "Tara Brach",
                summary: "Buddhist teacher's guide to embracing your life with the heart of a Buddha. How to stop fighting yourself and find peace through acceptance.",
                keyInsight: "Radical acceptance is the willingness to experience ourselves and our lives as it is. This creates the foundation for authentic change.",
                dailyAction: "Identify one aspect of yourself you've been fighting or trying to change. Practice accepting it as it is today.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0553380990"
            ),
            BookTemplate(
                title: "The Authentic Self",
                author: "James Masterson",
                summary: "Psychotherapist's guide to recovering your true self from the false self created by early adaptations to family dynamics.",
                keyInsight: "The authentic self emerges when we stop performing for approval and start expressing our genuine thoughts and feelings.",
                dailyAction: "Notice when you're performing or adapting for others' approval today. Practice expressing your genuine thoughts instead.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1138127124"
            ),
            BookTemplate(
                title: "Being Yourself",
                author: "Teal Swan",
                summary: "A guide to authenticity in a world that pressures conformity. How to find and express your true self despite social conditioning.",
                keyInsight: "You cannot be authentic while simultaneously seeking approval. Authenticity requires choosing truth over comfort.",
                dailyAction: "Express one genuine opinion today that you normally keep to yourself out of fear of judgment.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1401952321"
            ),
            BookTemplate(
                title: "The Mask of Masculinity",
                author: "Lewis Howes",
                summary: "Former pro athlete's journey to authentic manhood. How to drop the masks that hide your true self and embrace vulnerability.",
                keyInsight: "The masks we wear to appear strong actually make us weak. True strength comes from vulnerability and authenticity.",
                dailyAction: "Identify one 'mask' you wear (stoic, people-pleaser, aggressive, etc.) and practice dropping it in one interaction today.",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/1623367395"
            ),
            BookTemplate(
                title: "A New Earth",
                author: "Eckhart Tolle",
                summary: "Awakening to your life's purpose through ego transcendence. How to move beyond identification with thoughts and roles to find your authentic being.",
                keyInsight: "You are not your thoughts, emotions, or the roles you play. Your authentic self is the awareness behind all mental noise.",
                dailyAction: "When you catch yourself in a reactive pattern today, pause and ask: 'Who is aware of this reaction?'",
                coverImageURL: nil,
                amazonURL: "https://amazon.com/dp/0452289963"
            )
        ]
    }
}
