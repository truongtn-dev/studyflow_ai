import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _users = UserRepository();

  User? _user;
  bool _loading = true;

  User? get user => _user;
  int? get userId => _user?.id;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _loading;

  Future<void> loadSession() async {
    _loading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(AppConstants.sessionUserIdKey);
    if (id != null) {
      _user = await _users.findById(id);
      if (_user == null) {
        await prefs.remove(AppConstants.sessionUserIdKey);
      }
    } else {
      _user = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final user = await _users.authenticate(email: email, password: password);
    if (user == null) return null;
    await _persist(user);
    return user;
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (await _users.emailExists(normalized)) {
      throw StateError('Email đã được sử dụng.');
    }
    final id = await _users.insert(
      User(email: normalized, password: password, name: name.trim()),
    );
    final user = (await _users.findById(id))!;
    await _persist(user);
    return user;
  }

  Future<void> refreshUser() async {
    final id = _user?.id;
    if (id == null) return;
    _user = await _users.findById(id);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.sessionUserIdKey);
    _user = null;
    notifyListeners();
  }

  Future<void> _persist(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.sessionUserIdKey, user.id!);
    _user = user;
    notifyListeners();
  }
}
