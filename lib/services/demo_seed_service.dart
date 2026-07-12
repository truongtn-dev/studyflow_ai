import '../models/user.dart';
import '../repositories/course_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';

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
    return userId;
  }
}
