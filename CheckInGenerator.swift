import Foundation

// MARK: - Check-In Generator
struct CheckInGenerator {
    
    // MARK: - Public Interface
    static func generateMorningPrompt(for path: TrainingPath) -> String {
        let prompts = getMorningPrompts(for: path)
        return prompts.randomElement() ?? getDefaultMorningPrompt(for: path)
    }
    
    static func generateEveningPrompt(for path: TrainingPath) -> String {
        let prompts = getEveningPrompts(for: path)
        return prompts.randomElement() ?? getDefaultEveningPrompt(for: path)
    }
    
    static func generateAIResponse(to userResponse: String, for path: TrainingPath, timeOfDay: AICheckIn.CheckInTime, mood: AICheckIn.MoodRating?) -> String {
        // This would integrate with actual AI service in production
        // For now, we'll generate contextual responses based on path and mood
        return generateContextualResponse(userResponse: userResponse, path: path, timeOfDay: timeOfDay, mood: mood)
    }
    
    static func generateFollowUpQuestion(for path: TrainingPath, basedon response: String) -> String {
        let questions = getFollowUpQuestions(for: path)
        return questions.randomElement() ?? "What's one thing you could do differently tomorrow?"
    }
    
    // MARK: - Path-Specific Morning Prompts
    private static func getMorningPrompts(for path: TrainingPath) -> [String] {
        switch path {
        case .discipline:
            return [
                "What's the one hard thing you're going to do today that you don't want to do?",
                "If you could only accomplish one thing today, what would move you forward the most?",
                "What temptation will you likely face today, and how will you handle it?",
                "What does winning the first hour of your day look like?",
                "What's one small act of discipline you can commit to before noon?",
                "If your future self could give you advice for today, what would they say?",
                "What's the difference between what you want to do and what you need to do today?",
                "How will you show up as the disciplined version of yourself today?",
                "What's one habit you're building that you can practice today?",
                "What would you do today if you knew you couldn't fail?"
            ]
        case .clarity:
            return [
                "What's taking up mental space that you need to release today?",
                "What are you avoiding thinking about that needs your attention?",
                "If you could only focus on three things today, what would they be?",
                "What emotion are you carrying from yesterday that you can let go of?",
                "What story are you telling yourself that might not be true?",
                "What would you do today if fear wasn't a factor?",
                "What's the most important question you need to answer for yourself right now?",
                "How are you feeling in your body right now, and what is it telling you?",
                "What distraction will you eliminate today to gain more clarity?",
                "What would bring you the most peace of mind today?"
            ]
        case .confidence:
            return [
                "What's one brave thing you could do today that would surprise yourself?",
                "Who do you want to be in your interactions today?",
                "What would you say or do if you knew everyone would support you?",
                "What conversation are you avoiding that could change everything?",
                "How will you use your voice today in a way that matters?",
                "What would confidence look like in your biggest challenge today?",
                "What's one way you can step into leadership today?",
                "How can you show up authentically in a situation where you usually hold back?",
                "What would you do today if rejection wasn't possible?",
                "What's one compliment you could give yourself right now?"
            ]
        case .purpose:
            return [
                "How does what you're doing today connect to what you want most in life?",
                "What would you do today if money wasn't a factor?",
                "How can you serve something bigger than yourself today?",
                "What legacy-building action can you take today?",
                "What would your 80-year-old self want you to focus on today?",
                "How can you use your unique gifts to make a difference today?",
                "What would you do if you knew it would impact someone's life positively?",
                "What calling or pull have you been ignoring that deserves attention?",
                "How can you align your actions today with your deepest values?",
                "What would you do today if you knew it was contributing to your life's work?"
            ]
        case .authenticity:
            return [
                "Where have you been hiding your true self, and how can you show up more authentically today?",
                "What would you do today if you didn't care what anyone thought?",
                "What truth about yourself are you ready to embrace today?",
                "How can you honor your authentic voice in a challenging situation today?",
                "What mask are you wearing that you could drop today?",
                "What would you do if you knew everyone would accept the real you?",
                "What part of yourself have you been suppressing that wants to be expressed?",
                "How can you be more honest about your needs and boundaries today?",
                "What would change if you stopped performing for others' approval?",
                "What would you create or express if you knew it would be well-received?"
            ]
        }
    }
    
    // MARK: - Path-Specific Evening Prompts
    private static func getEveningPrompts(for path: TrainingPath) -> [String] {
        switch path {
        case .discipline:
            return [
                "Where did you choose discipline over comfort today?",
                "What temptation did you resist, and how did it feel?",
                "What's one small win you can acknowledge from today?",
                "Where did you hold yourself accountable today?",
                "What habit did you strengthen or weaken today?",
                "When did you do something difficult that you didn't want to do?",
                "How did you show up as the person you're becoming today?",
                "What would you do differently if you could repeat today?",
                "Where did you stay committed when it got hard?",
                "What evidence do you have that you're building stronger discipline?"
            ]
        case .clarity:
            return [
                "What did you learn about yourself today?",
                "What mental clutter can you release before tomorrow?",
                "When did you feel most clear and focused today?",
                "What pattern did you notice in your thoughts or reactions?",
                "What decision are you avoiding that needs your attention?",
                "How did your emotions guide or mislead you today?",
                "What assumption you held was challenged today?",
                "When did you listen to your intuition, and what happened?",
                "What would you like to understand better about today's events?",
                "What insight emerged when you slowed down to reflect?"
            ]
        case .confidence:
            return [
                "When did you speak up or take action despite feeling nervous?",
                "What social risk did you take today?",
                "How did you handle a moment when confidence was required?",
                "When did you advocate for yourself today?",
                "What did you do that pushed you outside your comfort zone?",
                "How did you show leadership in small or big ways?",
                "When did you choose courage over comfort?",
                "What feedback or reaction surprised you in a positive way?",
                "How did you use your voice to make a difference today?",
                "What evidence do you have that you're becoming more confident?"
            ]
        case .purpose:
            return [
                "How did you serve something bigger than yourself today?",
                "What actions felt most aligned with your values?",
                "When did you feel most connected to your deeper purpose?",
                "How did you use your unique gifts today?",
                "What legacy-building action did you take?",
                "When did you feel like you were making a difference?",
                "How did your work today connect to your bigger vision?",
                "What pulled at your heart that you might explore further?",
                "How did you invest in what matters most to you?",
                "What would your future self thank you for doing today?"
            ]
        case .authenticity:
            return [
                "When did you show up as your most authentic self today?",
                "Where did you choose truth over people-pleasing?",
                "What part of yourself did you express that felt genuine?",
                "When did you honor your real feelings instead of hiding them?",
                "How did you practice being vulnerable today?",
                "Where did you stop performing and start being real?",
                "What boundary did you set that honored your authentic self?",
                "When did you choose your truth over others' expectations?",
                "How did being authentic change an interaction today?",
                "What would you like to express more freely tomorrow?"
            ]
        }
    }
    
    // MARK: - AI Response Generation
    private static func generateContextualResponse(userResponse: String, path: TrainingPath, timeOfDay: AICheckIn.CheckInTime, mood: AICheckIn.MoodRating?) -> String {
        let responses = getAIResponses(for: path, timeOfDay: timeOfDay, mood: mood)
        let selectedResponse = responses.randomElement() ?? getDefaultAIResponse(for: path, timeOfDay: timeOfDay)
        
        // In a real implementation, this would use AI to generate personalized responses
        // For now, we'll return contextual responses based on mood and path
        return personalizeResponse(selectedResponse, basedOn: userResponse, mood: mood)
    }
    
    private static func getAIResponses(for path: TrainingPath, timeOfDay: AICheckIn.CheckInTime, mood: AICheckIn.MoodRating?) -> [String] {
        switch (path, timeOfDay) {
        case (.discipline, .morning):
            return [
                "That's a solid commitment. Remember, discipline isn't about perfection—it's about showing up consistently, especially when you don't feel like it.",
                "I hear your intention. The gap between wanting to do something and actually doing it is where discipline is built. Start small if you need to.",
                "Good awareness. The hardest part is often just beginning. Focus on taking the first step, and momentum will follow.",
                "Strong mindset. Remember that every small act of discipline compounds over time. You're building something bigger than today.",
                "I appreciate your honesty. Discipline is a practice, not a destination. Each choice to do the hard thing makes the next one easier."
            ]
        case (.discipline, .evening):
            return [
                "Reflect on what worked and what didn't. Every day is data for building better systems and stronger habits.",
                "Acknowledge your wins, even small ones. Discipline is built through celebrating progress, not just pushing harder.",
                "Consider how today's choices align with who you're becoming. Each disciplined action is a vote for your future self.",
                "Notice the patterns. Where was discipline easy? Where was it hard? Use this insight to prepare for tomorrow.",
                "Remember that building discipline is like building muscle—it requires both effort and recovery. How will you restore tonight?"
            ]
        case (.clarity, .morning):
            return [
                "Starting with awareness is powerful. Mental clarity often comes from first acknowledging what's clouded.",
                "That's an important question to sit with. Sometimes the best insights come when we stop trying to force answers.",
                "Good reflection. Creating space between thoughts and reactions is where true clarity emerges.",
                "I hear you processing this. Remember that clarity isn't about having all the answers—it's about asking better questions.",
                "Thoughtful approach. The mind is like water—it becomes clear when it's allowed to be still."
            ]
        case (.clarity, .evening):
            return [
                "What patterns are you noticing? Often our biggest insights come from stepping back and observing the bigger picture.",
                "That kind of self-awareness is valuable. How might this insight change how you approach tomorrow?",
                "Interesting reflection. What would it look like to trust that inner knowing more fully?",
                "Good observation. Sometimes the most important clarity comes from what we choose to let go of, not what we figure out.",
                "I appreciate that honesty. Clarity often requires being willing to sit with uncertainty while we find our way."
            ]
        case (.confidence, .morning):
            return [
                "That takes courage to even consider. Remember, confidence is built through action, not just positive thinking.",
                "I hear the edge in that challenge. The goal isn't to eliminate nervousness—it's to act despite it.",
                "Good awareness of what's holding you back. Confidence grows when we take small risks consistently.",
                "That's a worthy intention. Remember that most people are too focused on themselves to judge you as harshly as you imagine.",
                "Strong commitment. Confidence isn't about knowing you'll succeed—it's about being willing to try regardless."
            ]
        case (.confidence, .evening):
            return [
                "How did it feel to step into that brave space? Every act of courage makes the next one more accessible.",
                "I'm curious about what you learned about yourself. Often our biggest growth comes from doing things we thought we couldn't.",
                "That kind of authentic expression builds real confidence. How might you bring more of that forward tomorrow?",
                "Good for you for taking that risk. What evidence do you now have about your own capabilities?",
                "That's the kind of action that changes how you see yourself. How has your self-perception shifted?"
            ]
        case (.purpose, .morning):
            return [
                "That connection to something bigger is powerful. How might you honor that calling in concrete ways today?",
                "Good reflection on what truly matters. Purpose often emerges from aligning daily actions with deeper values.",
                "I hear you wrestling with that bigger question. Sometimes purpose reveals itself through service to others.",
                "That's a meaningful intention. Remember that purpose isn't just what you do—it's how you show up while doing it.",
                "Strong awareness of what pulls at you. How might you take one small step toward that vision today?"
            ]
        case (.purpose, .evening):
            return [
                "How did it feel to live in alignment today? Notice what energized you versus what drained you.",
                "That kind of service creates meaning. How might you build on that sense of contribution tomorrow?",
                "Good reflection on what matters most. Purpose often becomes clearer through action, not just thinking.",
                "I hear how that connected you to something bigger. What would it look like to make that a more regular part of your life?",
                "That alignment between values and actions is powerful. How has it shifted your sense of fulfillment?"
            ]
        case (.authenticity, .morning):
            return [
                "That willingness to be real takes courage. Authenticity is often about choosing truth over comfort.",
                "Good awareness of where you might be performing. What would it look like to drop that mask today?",
                "I hear you wanting to show up more genuinely. Remember that authenticity is a practice, not a perfection.",
                "That's a vulnerable intention. How might you honor your true feelings while still navigating social expectations?",
                "Strong commitment to being real. What's one way you could express your authentic self today?"
            ]
        case (.authenticity, .evening):
            return [
                "How did it feel to show up authentically? Often the fear of being ourselves is worse than the actual experience.",
                "That kind of genuine expression builds trust with yourself. What did you learn about who you really are?",
                "Good for you for choosing truth over performance. How did others respond to your authenticity?",
                "I appreciate that vulnerability. What would it look like to bring even more of your real self forward tomorrow?",
                "That alignment between inner truth and outer expression is powerful. How has it affected your relationships?"
            ]
        }
    }
    
    private static func personalizeResponse(_ baseResponse: String, basedOn userResponse: String, mood: AICheckIn.MoodRating?) -> String {
        // Add mood-based personalization
        let moodPrefix = getMoodBasedPrefix(mood)
        
        // In a real implementation, this would use AI to analyze user response content
        // For now, we'll add simple personalization based on mood
        if let prefix = moodPrefix {
            return prefix + " " + baseResponse
        }
        return baseResponse
    }
    
    private static func getMoodBasedPrefix(_ mood: AICheckIn.MoodRating?) -> String? {
        guard let mood = mood else { return nil }
        
        switch mood {
        case .excellent:
            return "I love that energy!"
        case .great:
            return "That positivity comes through."
        case .good:
            return "I can feel your motivation."
        case .neutral:
            return "I hear where you're at."
        case .low:
            return "I appreciate your honesty about how you're feeling."
        }
    }
    
    // MARK: - Follow-Up Questions
    private static func getFollowUpQuestions(for path: TrainingPath) -> [String] {
        switch path {
        case .discipline:
            return [
                "What's one small thing you could do right now to build momentum?",
                "What would help you stay consistent with this tomorrow?",
                "What obstacles might you face, and how will you handle them?",
                "What's the smallest version of this you could commit to?",
                "How will you reward yourself for following through?"
            ]
        case .clarity:
            return [
                "What would it look like to sit with this uncertainty a bit longer?",
                "What assumptions might you be making that need questioning?",
                "How could you create more space for this insight to develop?",
                "What would your wisest self say about this situation?",
                "What are you not seeing that might be important here?"
            ]
        case .confidence:
            return [
                "What would you do if you knew you couldn't fail?",
                "How could you take a smaller version of this risk tomorrow?",
                "What support would help you move forward with this?",
                "What evidence do you have that you're more capable than you think?",
                "How could you prepare yourself to handle potential rejection or failure?"
            ]
        case .purpose:
            return [
                "How does this connect to what you want your legacy to be?",
                "What would you do if resources weren't a limitation?",
                "How could you serve others while pursuing this?",
                "What would 80-year-old you want you to focus on?",
                "What small experiment could you try to explore this further?"
            ]
        case .authenticity:
            return [
                "What would it look like to honor your true feelings here?",
                "How could you express this more authentically tomorrow?",
                "What boundary would your authentic self set in this situation?",
                "What are you afraid would happen if you were completely honest?",
                "How could you show up more genuinely in your relationships?"
            ]
        }
    }
    
    // MARK: - Default Prompts
    private static func getDefaultMorningPrompt(for path: TrainingPath) -> String {
        switch path {
        case .discipline:
            return "What's one thing you can do today that your future self will thank you for?"
        case .clarity:
            return "What needs your attention today that you've been avoiding?"
        case .confidence:
            return "How can you use your voice today in a way that matters?"
        case .purpose:
            return "How can you serve something bigger than yourself today?"
        case .authenticity:
            return "How can you show up more authentically today?"
        }
    }
    
    private static func getDefaultEveningPrompt(for path: TrainingPath) -> String {
        switch path {
        case .discipline:
            return "Where did you choose discipline over comfort today?"
        case .clarity:
            return "What did you learn about yourself today?"
        case .confidence:
            return "When did you choose courage over comfort today?"
        case .purpose:
            return "How did you serve something bigger than yourself today?"
        case .authenticity:
            return "When did you show up as your most authentic self today?"
        }
    }
    
    private static func getDefaultAIResponse(for path: TrainingPath, timeOfDay: AICheckIn.CheckInTime) -> String {
        switch (path, timeOfDay) {
        case (.discipline, .morning):
            return "That's a solid intention. Remember, discipline is built one choice at a time. Focus on showing up consistently."
        case (.discipline, .evening):
            return "Every choice you made today was practice. Celebrate the wins and learn from what didn't work."
        case (.clarity, .morning):
            return "Good awareness. Sometimes the most important clarity comes from being willing to sit with uncertainty."
        case (.clarity, .evening):
            return "That kind of reflection builds wisdom. How might you carry this insight forward?"
        case (.confidence, .morning):
            return "That takes courage to even consider. Remember, confidence grows through action, not just thinking."
        case (.confidence, .evening):
            return "Every brave action you took today builds your confidence for tomorrow. How did it feel to step up?"
        case (.purpose, .morning):
            return "That connection to something bigger is powerful. How might you honor that today?"
        case (.purpose, .evening):
            return "Living in alignment with your purpose is meaningful work. How did it feel to serve something bigger?"
        case (.authenticity, .morning):
            return "That willingness to be real takes courage. How might you show up authentically today?"
        case (.authenticity, .evening):
            return "Choosing authenticity over performance builds trust with yourself. How did being real feel today?"
        }
    }
}
