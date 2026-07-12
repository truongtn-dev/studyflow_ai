import '../models/flashcard.dart';

/// SM-2 spaced repetition engine (simplified).
class SrsEngine {
  const SrsEngine();

  Flashcard applyReview(Flashcard card, {required bool correct}) {
    final now = DateTime.now();
    if (!correct) {
      return card.copyWith(
        intervalDays: 1,
        easeFactor: (card.easeFactor - 0.2).clamp(1.3, 2.5),
        reviewCount: card.reviewCount + 1,
        mastered: false,
        nextReview: now.add(const Duration(days: 1)).toIso8601String(),
      );
    }

    final newEase = (card.easeFactor + 0.1).clamp(1.3, 2.5);
    final newInterval = card.reviewCount == 0
        ? 1
        : card.reviewCount == 1
            ? 3
            : (card.intervalDays * newEase).round().clamp(1, 365);
    final mastered = card.reviewCount + 1 >= 3 || newInterval >= 21;

    return card.copyWith(
      intervalDays: newInterval,
      easeFactor: newEase,
      reviewCount: card.reviewCount + 1,
      mastered: mastered,
      nextReview: now.add(Duration(days: newInterval)).toIso8601String(),
    );
  }

  /// Reset SRS progress when editing a card.
  Flashcard reset(Flashcard card) {
    return card.copyWith(
      intervalDays: 1,
      easeFactor: 2.5,
      reviewCount: 0,
      mastered: false,
      nextReview: DateTime.now().toIso8601String(),
    );
  }
}
