abstract final class AppConstants {
  static const groqModel = 'llama-3.3-70b-versatile';
  static const groqKeyEnv = 'GROQ_KEY';
  /// Persisted Groq key so plain `flutter run` works without --dart-define.
  static const groqKeyPrefsKey = 'groq_api_key';
  static const maxAiRequestsPerDay = 15;
  static const minCoursesForAi = 1;
  static const minTasksForStudyPlan = 3;
  static const sessionUserIdKey = 'user_id';
  static const hasSeenOnboardingKey = 'has_seen_onboarding';
}

enum AiPromptType {
  chat('chat'),
  studyPlan('study_plan'),
  explain('explain'),
  noteSummarize('note_summarize'),
  noteQuiz('note_quiz');

  const AiPromptType(this.value);
  final String value;
}
