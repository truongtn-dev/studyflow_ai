import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow_ai/models/flashcard.dart';
import 'package:studyflow_ai/services/srs_engine.dart';

void main() {
  const engine = SrsEngine();

  Flashcard baseCard({
    int reviewCount = 0,
    int intervalDays = 1,
    double easeFactor = 2.5,
  }) {
    return Flashcard(
      id: 1,
      userId: 1,
      front: 'Q',
      back: 'A',
      reviewCount: reviewCount,
      intervalDays: intervalDays,
      easeFactor: easeFactor,
    );
  }

  group('SrsEngine.applyReview', () {
    test('correct on first review sets interval to 1 and increases ease', () {
      final card = baseCard(reviewCount: 0, easeFactor: 2.5);
      final updated = engine.applyReview(card, correct: true);

      expect(updated.intervalDays, 1);
      expect(updated.easeFactor, closeTo(2.5, 0.001)); // clamped at 2.5
      expect(updated.reviewCount, 1);
      expect(updated.nextReview, isNotNull);
      expect(updated.mastered, isFalse);
    });

    test('correct on second review sets interval to 3', () {
      final card = baseCard(reviewCount: 1, intervalDays: 1, easeFactor: 2.4);
      final updated = engine.applyReview(card, correct: true);

      expect(updated.intervalDays, 3);
      expect(updated.easeFactor, closeTo(2.5, 0.001));
      expect(updated.reviewCount, 2);
    });

    test('correct later multiplies interval by ease', () {
      final card = baseCard(reviewCount: 2, intervalDays: 3, easeFactor: 2.0);
      final updated = engine.applyReview(card, correct: true);

      expect(updated.intervalDays, 6); // 3 * 2.1 ≈ 6.3 → 6
      expect(updated.easeFactor, closeTo(2.1, 0.001));
      expect(updated.reviewCount, 3);
    });

    test('incorrect resets interval to 1 and decreases ease', () {
      final card = baseCard(reviewCount: 3, intervalDays: 10, easeFactor: 2.0);
      final updated = engine.applyReview(card, correct: false);

      expect(updated.intervalDays, 1);
      expect(updated.easeFactor, closeTo(1.8, 0.001));
      expect(updated.reviewCount, 4);
      expect(updated.mastered, isFalse);
    });

    test('incorrect does not drop ease below 1.3', () {
      final card = baseCard(easeFactor: 1.3);
      final updated = engine.applyReview(card, correct: false);

      expect(updated.easeFactor, closeTo(1.3, 0.001));
      expect(updated.intervalDays, 1);
    });
  });

  group('SrsEngine.reset', () {
    test('resets SRS fields to defaults', () {
      final card = baseCard(reviewCount: 5, intervalDays: 30, easeFactor: 1.8)
          .copyWith(mastered: true);
      final reset = engine.reset(card);

      expect(reset.intervalDays, 1);
      expect(reset.easeFactor, 2.5);
      expect(reset.reviewCount, 0);
      expect(reset.mastered, isFalse);
      expect(reset.nextReview, isNotNull);
    });
  });
}
