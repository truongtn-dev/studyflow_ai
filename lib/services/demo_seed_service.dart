import '../models/flashcard.dart';
import '../models/user.dart';
import '../repositories/course_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';

class DemoSeedService {
  DemoSeedService({
    UserRepository? userRepository,
    CourseRepository? courseRepository,
    TaskRepository? taskRepository,
    FlashcardRepository? flashcardRepository,
  })  : _users = userRepository ?? UserRepository(),
        _courses = courseRepository ?? CourseRepository(),
        _tasks = taskRepository ?? TaskRepository(),
        _cards = flashcardRepository ?? FlashcardRepository();

  final UserRepository _users;
  final CourseRepository _courses;
  final TaskRepository _tasks;
  final FlashcardRepository _cards;

  Future<int> ensureDemoUser() async {
    var user = await _users.findByEmail('demo@fpt.edu.vn');
    if (user == null) {
      final id = await _users.insert(
        const User(
          email: 'demo@fpt.edu.vn',
          password: '123456',
          name: 'Thành Trương',
        ),
      );
      user = await _users.findById(id);
    }

    final userId = user!.id!;
    await _courses.seedDemoCourses(userId);
    await _tasks.seedDemoTasks(userId);
    await _seedDemoFlashcards(userId);
    return userId;
  }

  Future<void> _seedDemoFlashcards(int userId) async {
    final count = await _cards.countByUserId(userId);
    if (count >= 3) return;
    final courses = await _courses.getByUserId(userId);
    final courseId = courses.isNotEmpty ? courses.first.id : null;
    final demos = [
      Flashcard(
        userId: userId,
        courseId: courseId,
        front: 'Widget là gì?',
        back: 'Thành phần UI bất biến trong Flutter.',
      ),
      Flashcard(
        userId: userId,
        courseId: courseId,
        front: 'StatefulWidget dùng khi nào?',
        back: 'Khi UI cần thay đổi theo state nội bộ.',
      ),
      Flashcard(
        userId: userId,
        courseId: courseId,
        front: 'SQLite dùng package nào?',
        back: 'sqflite (+ path).',
      ),
    ];
    for (final card in demos) {
      await _cards.insert(card);
    }
  }
}
