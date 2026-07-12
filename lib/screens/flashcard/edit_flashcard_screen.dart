import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import 'add_flashcard_screen.dart';

/// Thin wrapper that opens [AddFlashcardScreen] in edit mode.
class EditFlashcardScreen extends StatelessWidget {
  const EditFlashcardScreen({super.key, required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    return AddFlashcardScreen(card: card);
  }
}
