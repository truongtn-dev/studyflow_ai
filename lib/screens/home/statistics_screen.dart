import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/study_session_repository.dart';
import '../../repositories/task_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _sessions = StudySessionRepository();
  final _tasks = TaskRepository();

  Map<String, int> _minutesByDay = {};
  int _totalMinutes = 0;
  int _sessionCount = 0;
  int _tasksDone = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    final byDay = await _sessions.minutesByDay(userId, days: 7);
    final total = await _sessions.totalMinutesAll(userId);
    final count = await _sessions.sessionCount(userId);
    final tasks = await _tasks.getByUserId(userId);
    if (!mounted) return;
    setState(() {
      _minutesByDay = byDay;
      _totalMinutes = total;
      _sessionCount = count;
      _tasksDone = tasks.where((t) => t.status == TaskStatus.done).length;
      _loading = false;
    });
  }

  List<_DayBar> _last7Days() {
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final key =
          '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      // DateTime.weekday: Mon=1 … Sun=7
      return _DayBar(
        label: labels[day.weekday - 1],
        minutes: _minutesByDay[key] ?? 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thống kê')),
        body: const EmptyState(
          title: 'Vui lòng đăng nhập',
          icon: Icons.lock_outline,
        ),
      );
    }

    final bars = _last7Days();
    final maxY = bars.fold<int>(0, (m, b) => b.minutes > m ? b.minutes : m);
    final chartMax = (maxY < 10 ? 10 : maxY * 1.2).toDouble();

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(title: const Text('Thống kê')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Tổng phút',
                          value: '$_totalMinutes',
                          icon: Icons.timer_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Phiên học',
                          value: '$_sessionCount',
                          icon: Icons.play_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Task xong',
                          value: '$_tasksDone',
                          icon: Icons.task_alt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SfCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phút học 7 ngày gần nhất',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              maxY: chartMax,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (v, _) => Text(
                                      v.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      final i = v.toInt();
                                      if (i < 0 || i >= bars.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          bars[i].label,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: AppColors.divider,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                for (var i = 0; i < bars.length; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: bars[i].minutes.toDouble(),
                                        color: AppColors.primary,
                                        width: 18,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(6),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DayBar {
  const _DayBar({required this.label, required this.minutes});
  final String label;
  final int minutes;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SfCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
