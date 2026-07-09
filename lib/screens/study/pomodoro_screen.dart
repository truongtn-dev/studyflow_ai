import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadInitialSettings();
  }

  Future<void> _loadInitialSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _focusSeconds =
        (prefs.getInt('focus_minutes') ?? 25) * 60;

    _breakSeconds =
        (prefs.getInt('break_minutes') ?? 5) * 60;

    setState(() {
      _totalSeconds = _focusSeconds;
      _remainingSeconds = _focusSeconds;
    });
  }
  Future<void> _saveStudySession() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> sessions =
        prefs.getStringList('study_sessions') ?? [];

    sessions.add(jsonEncode({
      'date': DateTime.now().toIso8601String(),
      'duration': _totalSeconds ~/ 60,
    }));

    await prefs.setStringList(
      'study_sessions',
      sessions,
    );
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();

          setState(() {
            _isRunning = false;
          });

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

      if (_isBreak) {
        // Break kết thúc -> quay lại Focus
        _isBreak = false;
        _totalSeconds = _focusSeconds;
      } else {
        // Focus kết thúc -> chuyển sang Break
        _isBreak = true;
        _totalSeconds = _breakSeconds;
      }

      _remainingSeconds = _totalSeconds;
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_isBreak ? "Focus hoàn thành" : "Break hoàn thành"),
        content: Text(
          _isBreak
              ? "Đã lưu phiên học.\nĐến giờ nghỉ ${_breakSeconds ~/ 60} phút."
              : "Nghỉ xong rồi.\nBắt đầu Focus ${_focusSeconds ~/ 60} phút.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress =
    _totalSeconds == 0
        ? 0
        : _remainingSeconds / _totalSeconds;

    return Scaffold(
      appBar: AppBar(title: Text(
        _isBreak ? 'Break' : 'Focus',
      ), actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () async {
            final result = await Navigator.pushNamed(
              context,
              '/pomodoro-settings',
            );

            if (result == true) {
              await _loadInitialSettings();
            }
          },
        )
      ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Vòng tròn Timer
            Stack(alignment: Alignment.center, children: [
              // Vòng tròn nền
              SizedBox(
                width: 240, height: 240,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  color: Colors.grey.withOpacity(0.15),
                ),
              ),
              // Vòng tròn tiến độ chính
              SizedBox(
                width: 240, height: 240,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  color: Theme.of(context).primaryColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Hiển thị thời gian
              Text(
                "${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ]),
            const SizedBox(height: 50),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nút Bắt đầu/Tạm dừng
                ElevatedButton.icon(
                  onPressed: _toggleTimer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 2,
                  ),
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? "TẠM DỪNG" : "BẮT ĐẦU",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 20),
                // Nút Refresh
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      _timer?.cancel();
                      setState(() {
                        _isRunning = false;
                        _remainingSeconds = _totalSeconds;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    color: Theme.of(context).primaryColor,
                  ),
                )
              ],
            )
          ],
        ),
      )
    );
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}