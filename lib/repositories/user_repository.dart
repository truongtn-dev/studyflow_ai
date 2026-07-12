import '../db/database_helper.dart';
import '../models/user.dart';

class UserRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insert(User user) async {
    final database = await _db.database;
    return database.insert('users', user.toMap());
  }

  Future<User?> findByEmail(String email) async {
    final database = await _db.database;
    final maps = await database.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> findById(int id) async {
    final database = await _db.database;
    final maps = await database.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> authenticate({
    required String email,
    required String password,
  }) async {
    final user = await findByEmail(email);
    if (user == null || user.password != password) {
      return null;
    }
    return user;
  }

  Future<bool> emailExists(String email) async {
    final user = await findByEmail(email);
    return user != null;
  }
}
