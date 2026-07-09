import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PomodoroSettingsScreen extends StatefulWidget {
  const PomodoroSettingsScreen({super.key});

  @override
  State<PomodoroSettingsScreen> createState() => _PomodoroSettingsScreenState();
}

class _PomodoroSettingsScreenState extends State<PomodoroSettingsScreen> {
  int _focusMinutes = 25;
  int _breakMinutes = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _focusMinutes = prefs.getInt('focus_minutes') ?? 25;
      _breakMinutes = prefs.getInt('break_minutes') ?? 5;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('focus_minutes', _focusMinutes);
    await prefs.setInt('break_minutes', _breakMinutes);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt Pomodoro", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSettingsCard(
            icon: Icons.timer,
            title: "Thời gian tập trung",
            value: _focusMinutes,
            min: 5, max: 120,
            onChanged: (v) => setState(() => _focusMinutes = v),
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            icon: Icons.coffee,
            title: "Thời gian nghỉ",
            value: _breakMinutes,
            min: 1, max: 30,
            onChanged: (v) => setState(() => _breakMinutes = v),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text("Lưu thay đổi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required int value,
    required double min,
    required double max,
    required Function(int) onChanged,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("$value phút", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Slider(
              value: value.toDouble(),
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: (v) => onChanged(v.toInt()),
            ),
          ],
        ),
      ),
    );
  }
}