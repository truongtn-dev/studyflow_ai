import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/study_session.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/study_session_repository.dart';
import '../../services/achievement_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  Timer? _timer;
  int _focusSeconds = 25 * 60;
  int _breakSeconds = 5 * 60;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  DateTime? _sessionStartedAt;

  @override
  void initState() {
    super.initState();
    _loadInitialSettings();
  }

  Future<void> _loadInitialSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _focusSeconds = (prefs.getInt('focus_minutes') ?? 25) * 60;
    _breakSeconds = (prefs.getInt('break_minutes') ?? 5) * 60;
    if (!mounted) return;
    setState(() {
      _totalSeconds = _focusSeconds;
      _remainingSeconds = _focusSeconds;
    });
  }

  Future<void> _saveStudySession() async {
    if (_isBreak) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final ended = DateTime.now();
    final started = _sessionStartedAt ?? ended.subtract(Duration(seconds: _totalSeconds));
    final durationMin = (_totalSeconds / 60).round().clamp(1, 999);

    await StudySessionRepository().insert(
      StudySession(
        userId: userId,
        durationMin: durationMin,
        type: 'pomodoro',
        startedAt: started.toIso8601String(),
        endedAt: ended.toIso8601String(),
      ),
    );
    await AchievementService().recordStudyDay(userId);
    if (mounted) await context.read<AuthProvider>().refreshUser();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _sessionStartedAt ??= DateTime.now();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          _handleCompletion();
        }
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  Future<void> _handleCompletion() async {
    await _saveStudySession();
    setState(() {
      _isRunning = false;
      _sessionStartedAt = null;
      if (_isBreak) {
        _isBreak = false;
        _totalSeconds = _focusSeconds;
      } else {
        _isBreak = true;
        _totalSeconds = _breakSeconds;
      }
      _remainingSeconds = _totalSeconds;
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_isBreak ? 'Focus hoàn thành' : 'Break hoàn thành'),
        content: Text(_isBreak
            ? 'Đã lưu phiên học vào SQLite.\nĐến giờ nghỉ ${_breakSeconds ~/ 60} phút.'
            : 'Nghỉ xong rồi.\nBắt đầu Focus ${_focusSeconds ~/ 60} phút.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds == 0 ? 0.0 : _remainingSeconds / _totalSeconds;

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        title: Text(
          _isBreak ? 'Break' : 'Focus',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result =
                  await Navigator.pushNamed(context, '/pomodoro-settings');
              if (result == true) await _loadInitialSettings();
            },
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final short = constraints.maxHeight < 520;
          final size = short ? 160.0 : 240.0;
          final fontSize = short ? 36.0 : 56.0;
          final gap = short ? 20.0 : 50.0;

          final timer = Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: const CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  color: AppColors.divider,
                ),
              ),
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  color: _isBreak ? AppColors.secondary : AppColors.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          );

          final controls = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _toggleTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(
                  _isRunning ? 'TẠM DỪNG' : 'BẮT ĐẦU',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 20),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.divider,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    _timer?.cancel();
                    setState(() {
                      _isRunning = false;
                      _sessionStartedAt = null;
                      _remainingSeconds = _totalSeconds;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  color: AppColors.primary,
                ),
              ),
            ],
          );

          final content = short
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    timer,
                    const SizedBox(width: 28),
                    Flexible(child: controls),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    timer,
                    SizedBox(height: gap),
                    controls,
                  ],
                );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
              child: Center(child: content),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
