import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../repositories/course_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';
import '../utils/constants.dart';

class DemoSeedService {
  DemoSeedService({
    UserRepository? userRepository,
    CourseRepository? courseRepository,
    TaskRepository? taskRepository,
  })  : _users = userRepository ?? UserRepository(),
        _courses = courseRepository ?? CourseRepository(),
        _tasks = taskRepository ?? TaskRepository();

  final UserRepository _users;
  final CourseRepository _courses;
  final TaskRepository _tasks;

  Future<int> ensureDemoUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt(AppConstants.sessionUserIdKey);
    if (savedId != null) return savedId;

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
    await prefs.setInt(AppConstants.sessionUserIdKey, userId);
    return userId;
  }
}
