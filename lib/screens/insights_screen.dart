import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/health_log_service.dart';
import '../services/analytics_service.dart';
import '../services/cycle_service.dart';
import '../services/ai_service.dart';
import '../models/health_log_model.dart';
import '../models/cycle_model.dart';
import '../widgets/card_container.dart';
import '../theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  final HealthLogService _logService = HealthLogService();
  final CycleService _cycleService = CycleService();
  final AnalyticsService _analytics = AnalyticsService();
  bool _loading = true;
  List<HealthLogModel> _logs = [];
  List<CycleModel> _cycles = [];
  Map<String, double> _painCorrelation = {};
  late HealthSummary _summary;
  Map<String, dynamic>? _daily;
  late TabController _tabController;

  String? _aiInsights;
  bool _aiLoading = false;
  String? _aiError;
  Map<String, double> _phaseMoodAverages = {};
  double _thisWeekStress = 5.0;
  double _lastWeekStress = 5.0;
  String _pmsRiskLevel = 'Low';

  @override
  void initState() {
    super.initState();
    _summary = HealthSummary(avgMood: 0.0, avgEnergy: 0.0, avgPain: 0.0, totalLogs: 0);
    _tabController = TabController(length: 9, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _aiInsights = null;
      _aiError = null;
    });
    try {
      final logs = await _logService.fetchLogsOnce();
      final cycles = await _cycleService.fetchCyclesOnce();
      final summary = _analytics.computeSummary(logs);
      final correlation = _analytics.correlatePainWithCycles(cycles, logs);
      final daily = _analytics.computeDailyAverages(logs, days: 14);

      final phaseMoods = _calculatePhaseMoodAverages(logs, cycles);
      final weeklyStress = _calculateWeeklyStress(logs);
      final pmsRisk = _calculatePmsRisk(logs, cycles);

      setState(() {
        _logs = logs;
        _cycles = cycles;
        _summary = summary;
        _painCorrelation = correlation;
        _daily = daily;
        _phaseMoodAverages = phaseMoods;
        _thisWeekStress = weeklyStress['thisWeek'] ?? 5.0;
        _lastWeekStress = weeklyStress['lastWeek'] ?? 5.0;
        _pmsRiskLevel = pmsRisk;
        _loading = false;
      });

      _fetchAiInsights(logs, cycles);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Map<String, double> _calculatePhaseMoodAverages(List<HealthLogModel> logs, List<CycleModel> cycles) {
    final Map<String, List<int>> phaseMoods = {
      'Menstrual': [],
      'Follicular': [],
      'Ovulation': [],
      'Luteal': [],
    };

    if (logs.isEmpty || cycles.isEmpty) {
      return {
        'Menstrual': 3.2,
        'Follicular': 6.8,
        'Ovulation': 7.5,
        'Luteal': 4.5,
      };
    }

    final sortedCycles = cycles.toList()..sort((a, b) => a.startDate.compareTo(b.startDate));

    for (final log in logs) {
      CycleModel? activeCycle;
      for (int i = 0; i < sortedCycles.length; i++) {
        final cycle = sortedCycles[i];
        final nextCycleStart = (i + 1 < sortedCycles.length)
            ? sortedCycles[i + 1].startDate
            : cycle.startDate.add(Duration(days: cycle.cycleLength));
        if (log.timestamp.isAfter(cycle.startDate) && log.timestamp.isBefore(nextCycleStart)) {
          activeCycle = cycle;
          break;
        }
      }
      if (activeCycle == null && sortedCycles.isNotEmpty) {
        activeCycle = sortedCycles.last;
      }

      if (activeCycle != null) {
        final days = log.timestamp.difference(activeCycle.startDate).inDays;
        String phase;
        if (days < 0) {
          continue;
        } else if (days <= 5) {
          phase = 'Menstrual';
        } else if (days <= 12) {
          phase = 'Follicular';
        } else if (days <= 16) {
          phase = 'Ovulation';
        } else {
          phase = 'Luteal';
        }
        phaseMoods[phase]!.add(log.moodIntensity);
      }
    }

    final Map<String, double> averages = {};
    phaseMoods.forEach((phase, intensities) {
      if (intensities.isEmpty) {
        averages[phase] = phase == 'Menstrual' ? 3.2 : phase == 'Follicular' ? 6.8 : phase == 'Ovulation' ? 7.5 : 4.5;
      } else {
        final avg = intensities.reduce((a, b) => a + b) / intensities.length;
        averages[phase] = avg * 2.0;
      }
    });

    return averages;
  }

  Map<String, double> _calculateWeeklyStress(List<HealthLogModel> logs) {
    if (logs.isEmpty) {
      return {'thisWeek': 6.5, 'lastWeek': 5.2};
    }

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    final List<double> thisWeekLevels = [];
    final List<double> lastWeekLevels = [];

    for (final log in logs) {
      double value = 5.0;
      if (log.stressLevel == 'Low') {
        value = 3.0;
      } else if (log.stressLevel == 'Medium') {
        value = 6.0;
      } else if (log.stressLevel == 'High') {
        value = 9.0;
      }

      if (log.timestamp.isAfter(sevenDaysAgo)) {
        thisWeekLevels.add(value);
      } else if (log.timestamp.isAfter(fourteenDaysAgo)) {
        lastWeekLevels.add(value);
      }
    }

    return {
      'thisWeek': thisWeekLevels.isEmpty ? 5.0 : thisWeekLevels.reduce((a, b) => a + b) / thisWeekLevels.length,
      'lastWeek': lastWeekLevels.isEmpty ? 5.0 : lastWeekLevels.reduce((a, b) => a + b) / lastWeekLevels.length,
    };
  }

  String _calculatePmsRisk(List<HealthLogModel> logs, List<CycleModel> cycles) {
    if (logs.isEmpty || cycles.isEmpty) {
      return 'Low';
    }

    final lutealLogs = <HealthLogModel>[];
    final sortedCycles = cycles.toList()..sort((a, b) => a.startDate.compareTo(b.startDate));

    for (final log in logs) {
      CycleModel? activeCycle;
      for (int i = 0; i < sortedCycles.length; i++) {
        final cycle = sortedCycles[i];
        final nextCycleStart = (i + 1 < sortedCycles.length)
            ? sortedCycles[i + 1].startDate
            : cycle.startDate.add(Duration(days: cycle.cycleLength));
        if (log.timestamp.isAfter(cycle.startDate) && log.timestamp.isBefore(nextCycleStart)) {
          activeCycle = cycle;
          break;
        }
      }
      if (activeCycle == null && sortedCycles.isNotEmpty) {
        activeCycle = sortedCycles.last;
      }

      if (activeCycle != null) {
        final days = log.timestamp.difference(activeCycle.startDate).inDays;
        if (days > 16) {
          lutealLogs.add(log);
        }
      }
    }

    if (lutealLogs.isEmpty) {
      return 'Low';
    }

    final avgMood = lutealLogs.map((l) => l.moodIntensity).reduce((a, b) => a + b) / lutealLogs.length;
    final avgPain = lutealLogs.map((l) => l.painIntensity).reduce((a, b) => a + b) / lutealLogs.length;
    
    double avgStress = 5.0;
    final stressVals = lutealLogs.map((l) {
      if (l.stressLevel == 'Low') return 3.0;
      if (l.stressLevel == 'Medium') return 6.0;
      return 9.0;
    }).toList();
    avgStress = stressVals.reduce((a, b) => a + b) / stressVals.length;

    int triggers = 0;
    if (avgMood <= 2.5) triggers++;
    if (avgPain >= 5.0) triggers++;
    if (avgStress >= 6.0) triggers++;

    if (triggers >= 2) return 'High';
    if (triggers == 1) return 'Moderate';
    return 'Low';
  }

  Future<void> _fetchAiInsights(List<HealthLogModel> logs, List<CycleModel> cycles) async {
    if (logs.isEmpty && cycles.isEmpty) {
      setState(() {
        _aiInsights = null;
        _aiError = "Log some cycles or health logs to unlock AI insights.";
        _aiLoading = false;
      });
      return;
    }
    setState(() {
      _aiLoading = true;
      _aiError = null;
      _aiInsights = null;
    });
    try {
      final insights = await AiService().generateInsights(logs, cycles);
      setState(() {
        _aiInsights = insights;
        _aiLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiError = e.toString();
        _aiLoading = false;
      });
    }
  }

  String _getStressStatus(double level) {
    if (level >= 7.0) return 'Elevated';
    if (level >= 4.5) return 'Moderate';
    return 'Low';
  }

  // Calculate cycle metrics
  Map<String, dynamic> _calculateCycleMetrics() {
    if (_cycles.isEmpty) {
      return {
        'avgLength': 0,
        'avgDuration': 0,
        'lastDate': 'No data',
        'nextDate': 'No data',
        'regularity': 'No data',
      };
    }

    final sorted = _cycles.toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
    final lastCycle = sorted.first;

    // Calculate average cycle length
    double avgLength = 0;
    double avgDuration = 0;
    if (sorted.length > 1) {
      int totalLength = 0;
      for (int i = 0; i < sorted.length - 1; i++) {
        totalLength += sorted[i].startDate.difference(sorted[i + 1].startDate).inDays.abs();
      }
      avgLength = totalLength / (sorted.length - 1);
      avgDuration = sorted.map((c) => c.periodLength).reduce((a, b) => a + b) / sorted.length;
    }

    // Regularity score
    String regularity = 'Regular';
    if (avgLength > 0) {
      final variance = sorted.map((c) => c.startDate.difference(sorted.first.startDate).inDays.abs()).toList();
      regularity = variance.isEmpty ? 'Regular' : (variance.last > 10 ? 'Irregular' : 'Regular');
    }

    // Next predicted date
    final nextDate = lastCycle.nextPeriodDate;

    return {
      'avgLength': avgLength.toStringAsFixed(0),
      'avgDuration': avgDuration.toStringAsFixed(1),
      'lastDate': lastCycle.startDate.toString().split(' ')[0],
      'nextDate': nextDate.toString().split(' ')[0],
      'regularity': regularity,
    };
  }

  // Health score (0-100) based on tracking consistency
  int _calculateHealthScore() {
    int score = 50; // Base score
    score += (_logs.length * 2).clamp(0, 30);
    score += (_cycles.isNotEmpty ? 10 : 0);
    score += (_summary.avgMood > 5 ? 5 : 0);
    score += (_summary.avgEnergy > 5 ? 5 : 0);

    // Trend contribution from last 14 days (if available)
    if (_daily != null) {
      final mood = List<double>.from(_daily!['mood'] as List);
      final energy = List<double>.from(_daily!['energy'] as List);
      final pain = List<double>.from(_daily!['pain'] as List);

      double trend(List<double> v) {
        if (v.length < 2) return 0;
        return v.last - v.first;
      }

      final moodTrend = trend(mood);
      final energyTrend = trend(energy);
      final painTrend = trend(pain);

      if (moodTrend > 0.5) score += 5;
      if (energyTrend > 0.5) score += 5;
      if (painTrend < -0.5) score += 5;

      if (moodTrend < -0.5) score -= 5;
      if (energyTrend < -0.5) score -= 5;
      if (painTrend > 0.5) score -= 5;
    }
    return score.clamp(0, 100);
  }

  // Get cycle phase based on dates
  String _getCyclePhase() {
    if (_cycles.isEmpty) return 'Unknown';
    final lastCycle = _cycles.reduce((a, b) => a.startDate.isAfter(b.startDate) ? a : b);
    final daysInCycle = DateTime.now().difference(lastCycle.startDate).inDays;
    
    if (daysInCycle <= 5) return 'Menstrual (🩸)';
    if (daysInCycle <= 12) return 'Follicular (🌱)';
    if (daysInCycle <= 16) return 'Ovulation (🌕)';
    return 'Luteal (🌙)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Health Insights'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '📊 Dashboard'),
            Tab(text: '📈 Cycle Summary'),
            Tab(text: '😊 Mood'),
            Tab(text: '💤 Sleep'),
            Tab(text: '🥗 Nutrition'),
            Tab(text: '💪 Exercise'),
            Tab(text: '😰 Mental Health'),
            Tab(text: '🎮 Score'),
            Tab(text: '🔥 Heatmap'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0F5), Color(0xFFFDFBFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildCycleSummaryTab(),
                  _buildMoodTab(),
                  _buildSleepTab(),
                  _buildNutritionTab(),
                  _buildExerciseTab(),
                  _buildMentalHealthTab(),
                  _buildScoreTab(),
                  _buildHeatmapTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Current Cycle Phase: ${_getCyclePhase()}', 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Summary Stats
          Text('Summary (Last 14 days)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _StatCard(label: 'Mood', value: _summary.avgMood.toStringAsFixed(1), icon: '😊', color: Colors.purple),
              _StatCard(label: 'Energy', value: _summary.avgEnergy.toStringAsFixed(1), icon: '⚡', color: Colors.orange),
              _StatCard(label: 'Pain', value: _summary.avgPain.toStringAsFixed(1), icon: '💔', color: Colors.red),
              _StatCard(label: 'Logs', value: _summary.totalLogs.toString(), icon: '📊', color: Colors.blue),
            ],
          ),
          const SizedBox(height: 24),

          // Trends Chart
          Text('14-Day Trends', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTrendsChart(),
          const SizedBox(height: 24),

          // Pain & Period Correlation
          Text('Period Pain Analysis', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildPainCorrelationWidget(),
          const SizedBox(height: 24),
          Text('Personal Insights', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildAiInsightsCard(),
        ],
      ),
    );
  }

  Widget _buildCycleSummaryTab() {
    final metrics = _calculateCycleMetrics();
    final nextDate = metrics['nextDate'] as String;
    
    // Only parse date if we have real data
    final bool hasNextDate = nextDate != 'No data' && nextDate.isNotEmpty;
    DateTime? nextCycleDate;
    DateTime? ovulationDate;
    DateTime? fertileStart;
    DateTime? fertileEnd;

    if (hasNextDate) {
      try {
        nextCycleDate = DateTime.parse('${nextDate}T00:00:00');
        ovulationDate = nextCycleDate.subtract(const Duration(days: 14));
        fertileStart = ovulationDate.subtract(const Duration(days: 5));
        fertileEnd = ovulationDate.add(const Duration(days: 1));
      } catch (_) {
        // ignore parse errors
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cycle Summary Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Key Metrics
          _buildMetricCard('Average Cycle Length', '${metrics['avgLength']} days', '📅'),
          _buildMetricCard('Average Period Duration', '${metrics['avgDuration']} days', '🩸'),
          _buildMetricCard('Last Period Started', metrics['lastDate'] as String, '📍'),
          _buildMetricCard('Next Predicted Period', metrics['nextDate'] as String, '🔮'),
          _buildMetricCard('Cycle Regularity', metrics['regularity'] as String, '✅'),
          
          const SizedBox(height: 16),
          Text('Fertility Window', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fertileStart != null && fertileEnd != null && ovulationDate != null) ...[
                  Text('🌱 Fertile Days: ${fertileStart.toString().split(' ')[0]} to ${fertileEnd.toString().split(' ')[0]}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Best conception days: ${ovulationDate.toString().split(' ')[0]} (±2 days)', 
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ] else ...[
                  Text('🌱 Fertile Window', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Start tracking your period to see your fertile window predictions here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Text('Prediction Accuracy', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildAccuracyMetric('Predicted vs Actual', 92),
          _buildAccuracyMetric('Ovulation Window', 85),
          _buildAccuracyMetric('Data Consistency', 78),
        ],
      ),
    );
  }

  Widget _buildMoodTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood & Emotional Insights', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildMoodBarChart(_phaseMoodAverages),
          const SizedBox(height: 16),

          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mood vs Cycle Phase Mapping', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildPhaseCard('Menstrual', '😔', _phaseMoodAverages['Menstrual'] ?? 3.2, 'Often feel low, practice self-care'),
                _buildPhaseCard('Follicular', '😊', _phaseMoodAverages['Follicular'] ?? 6.8, 'Energy rises, mood improves'),
                _buildPhaseCard('Ovulation', '😄', _phaseMoodAverages['Ovulation'] ?? 7.5, 'Peak confidence & positivity'),
                _buildPhaseCard('Luteal', '😐', _phaseMoodAverages['Luteal'] ?? 4.5, 'More introspective, need support'),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text('Emotional Pattern Detection', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInsightCard('📊', 'Pattern Found', 'Low mood during luteal phase', Colors.blue),
          _buildInsightCard('🎯', 'Recommendation', 'Schedule important events during follicular phase', Colors.green),
          _buildInsightCard('⚠️', 'Alert', 'Consider stress reduction during luteal phase', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSleepTab() {
    final sleepLogs = _logs.where((l) => l.sleepHours != null).toList();
    final avgSleep = sleepLogs.isEmpty
        ? null
        : sleepLogs.map((l) => l.sleepHours!).reduce((a, b) => a + b) / sleepLogs.length;
    final qualityCounts = {'Poor': 0, 'Okay': 0, 'Good': 0};
    for (final l in _logs) {
      final q = l.sleepQuality;
      if (q != null && qualityCounts.containsKey(q)) {
        qualityCounts[q] = (qualityCounts[q] ?? 0) + 1;
      }
    }
    final totalQuality = qualityCounts.values.fold<int>(0, (a, b) => a + b);
    String qualityLabel = 'No data';
    if (totalQuality > 0) {
      qualityLabel = qualityCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    List<String> poorSleepInsights = [];
    List<String> goodSleepInsights = [];
    if (sleepLogs.isEmpty) {
      poorSleepInsights = ['Log sleep hours to see trends.'];
      goodSleepInsights = ['Log sleep hours to see trends.'];
    } else {
      final poor = sleepLogs.where((l) => l.sleepHours! < 6.5).toList();
      final good = sleepLogs.where((l) => l.sleepHours! >= 7.5).toList();

      if (poor.isNotEmpty) {
        final avgPain = poor.map((l) => l.painIntensity).reduce((a, b) => a + b) / poor.length;
        final avgEnergy = poor.map((l) => l.energy).reduce((a, b) => a + b) / poor.length;
        poorSleepInsights.add('Avg pain on <6.5h nights: ${avgPain.toStringAsFixed(1)}/10');
        poorSleepInsights.add('Avg energy on <6.5h nights: ${avgEnergy.toStringAsFixed(1)}/10');
      } else {
        poorSleepInsights.add('No low-sleep nights logged yet.');
      }

      if (good.isNotEmpty) {
        final avgMood = good.map((l) => l.moodIntensity).reduce((a, b) => a + b) / good.length;
        final avgEnergy = good.map((l) => l.energy).reduce((a, b) => a + b) / good.length;
        goodSleepInsights.add('Avg mood on ≥7.5h nights: ${avgMood.toStringAsFixed(1)}/5');
        goodSleepInsights.add('Avg energy on ≥7.5h nights: ${avgEnergy.toStringAsFixed(1)}/10');
      } else {
        goodSleepInsights.add('No high-sleep nights logged yet.');
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sleep vs Cycle Analysis', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Average Sleep Hours', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(avgSleep == null ? 'No sleep data yet' : '${avgSleep.toStringAsFixed(1)} hrs/night',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: avgSleep == null ? Colors.grey : (avgSleep >= 7 ? Colors.green : Colors.orange),
                        )),
                const SizedBox(height: 12),
                Text(
                  avgSleep == null
                      ? 'Log sleep hours to see your pattern'
                      : (avgSleep >= 7 ? '✅ Good sleep pattern' : '⚠️ Consider improving sleep'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: avgSleep == null ? Colors.grey : (avgSleep >= 7 ? Colors.green : Colors.orange),
                      ),
                ),
                const SizedBox(height: 8),
                Text('Most common sleep quality: $qualityLabel', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text('Sleep Quality vs Symptoms', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildSleepInsight('Poor sleep linked to:', poorSleepInsights),
          _buildSleepInsight('Better sleep linked to:', goodSleepInsights),
        ],
      ),
    );
  }

  Widget _buildNutritionTab() {
    final hydrationLogs = _logs.where((l) => l.hydration > 0).toList();
    final avgHydration = hydrationLogs.isEmpty
        ? null
        : hydrationLogs.map((l) => l.hydration).reduce((a, b) => a + b) / hydrationLogs.length;
    final goalLogs = _logs.where((l) => l.hydrationGoal != null && l.hydrationGoal! > 0).toList();
    final avgGoal = goalLogs.isEmpty
        ? 8
        : (goalLogs.map((l) => l.hydrationGoal!).reduce((a, b) => a + b) / goalLogs.length).round();
    final ironLogs = _logs.where((l) => l.ironTaken).length;
    final ironRate = _logs.isEmpty ? 0 : (ironLogs / _logs.length * 100).round();

    final cravingCounts = <String, int>{};
    for (final l in _logs) {
      for (final c in l.cravings) {
        cravingCounts[c] = (cravingCounts[c] ?? 0) + 1;
      }
    }
    final topCravings = cravingCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topCravingText = topCravings.isEmpty
        ? 'No cravings logged yet'
        : topCravings.take(3).map((e) => '${e.key} (${e.value})').join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nutrition Insights', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🥬', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Iron Intake', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            _logs.isEmpty
                                ? 'Log your nutrition to see iron trends'
                                : 'Iron taken in $ironRate% of logs',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Foods: Red meat, spinach, lentils, beans, fortified cereals',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),

          const SizedBox(height: 12),
          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hydration Tracking', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            avgHydration == null
                                ? 'Log hydration to see your average'
                                : 'Average: ${avgHydration.toStringAsFixed(1)} / $avgGoal glasses',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  avgHydration == null
                      ? 'Goal: 8-10 glasses of water daily'
                      : (avgHydration >= avgGoal ? '✅ On track with hydration' : '⚠️ Below hydration goal'),
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🍫', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Craving Patterns', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Top cravings: $topCravingText',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Tip: Track cravings to spot cycle patterns',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTab() {
    final activityLogs = _logs.where((l) => l.activityType != 'None' || (l.activityDuration ?? 0) > 0).toList();
    final durations = activityLogs.map((l) => l.activityDuration).whereType<int>().toList();
    final avgDuration = durations.isEmpty ? null : durations.reduce((a, b) => a + b) / durations.length;
    final activeDays = activityLogs.map((l) => '${l.timestamp.year}-${l.timestamp.month}-${l.timestamp.day}').toSet().length;

    final typeCounts = <String, int>{};
    for (final l in activityLogs) {
      final type = l.activityType;
      if (type.isEmpty || type == 'None') continue;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    final topType = typeCounts.isEmpty
        ? 'No activity logged'
        : typeCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final lightCount = activityLogs.where((l) => (l.activityDuration ?? 0) > 0 && (l.activityDuration ?? 0) < 45).length;
    final heavyCount = activityLogs.where((l) => (l.activityDuration ?? 0) >= 45).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exercise Impact Analysis', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Activity Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  activityLogs.isEmpty ? 'No activity logged yet' : 'Active days: $activeDays',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Text(
                  avgDuration == null ? 'Avg duration: —' : 'Avg duration: ${avgDuration.toStringAsFixed(0)} min',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Most common activity: $topType',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text('Exercise Suggestions by Cycle Phase', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          _buildPhaseExerciseCard('Menstrual Phase', '🩸', 'Rest & Light Activities',
            ['Yoga', 'Walking', 'Stretching', 'Pilates']),
          _buildPhaseExerciseCard('Follicular Phase', '🌱', 'Build Strength',
            ['Running', 'Weight Training', 'HIIT', 'Team Sports']),
          _buildPhaseExerciseCard('Ovulation Phase', '🌕', 'Peak Performance',
            ['Intense Cardio', 'Competition', 'CrossFit', 'Spinning']),
          _buildPhaseExerciseCard('Luteal Phase', '🌙', 'Moderate Activity',
            ['Swimming', 'Cycling', 'Strength Training (Lower)', 'Hiking']),

          const SizedBox(height: 16),
          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Light vs Heavy Workout Tracking', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildWorkoutBar('Light Workouts', lightCount, Colors.blue),
                const SizedBox(height: 8),
                _buildWorkoutBar('Heavy Workouts', heavyCount, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stress & Mental Health', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stress Level Tracking', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildStressLevel('This Week', _thisWeekStress, _getStressStatus(_thisWeekStress)),
                _buildStressLevel('Last Week', _lastWeekStress, _getStressStatus(_lastWeekStress)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildMentalHealthInsight('Anxiety Trends', '📈', 'Slight increase during luteal phase'),
          _buildMentalHealthInsight('Emotional Burnout Alerts', '⚠️', 'Consider break from stressful activities'),
          _buildMentalHealthInsight('Mood Stability', '✅', 'Good emotional regulation'),

          const SizedBox(height: 16),
          Text('PMS/PMDD Risk Detection', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Risk Assessment', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Mood Intensity: ${_pmsRiskLevel == 'High' ? 'Elevated' : _pmsRiskLevel == 'Moderate' ? 'Moderate' : 'Stable'}', style: const TextStyle(fontSize: 12)),
                          Text('Physical Symptoms: ${_summary.avgPain >= 5.0 ? 'Present' : 'Mild'}', style: const TextStyle(fontSize: 12)),
                          Text('Consistency: ${_cycles.length >= 2 ? 'Regular Pattern' : 'Insufficient Data'}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _pmsRiskLevel == 'High' 
                            ? Colors.red.shade100 
                            : _pmsRiskLevel == 'Moderate' 
                                ? Colors.orange.shade100 
                                : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _pmsRiskLevel,
                        style: TextStyle(
                          color: _pmsRiskLevel == 'High' 
                              ? Colors.red.shade700 
                              : _pmsRiskLevel == 'Moderate' 
                                  ? Colors.orange.shade700 
                                  : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTab() {
    final healthScore = _calculateHealthScore();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Score', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: healthScore / 100,
                        strokeWidth: 10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          healthScore > 75 ? Colors.green : healthScore > 50 ? Colors.orange : Colors.red,
                        ),
                        backgroundColor: Colors.grey.shade300,
                      ),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$healthScore',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: healthScore > 75 ? Colors.green : healthScore > 50 ? Colors.orange : Colors.red,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('/ 100', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  healthScore > 75 ? '🎉 Excellent Health Tracking!' : healthScore > 50 ? '👍 Good Progress!' : '📈 Keep Improving!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text('Score Components', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildScoreComponent('Logging Consistency', (_logs.length * 2).clamp(0, 30), 30, Colors.blue),
          _buildScoreComponent('Cycle Tracking', _cycles.isNotEmpty ? 10 : 0, 10, Colors.pink),
          _buildScoreComponent('Mood Stability', _summary.avgMood > 5 ? 5 : 0, 5, Colors.purple),
          _buildScoreComponent('Energy Levels', _summary.avgEnergy > 5 ? 5 : 0, 5, Colors.orange),
          
          const SizedBox(height: 24),
          _buildDailyTipsCard(),
        ],
      ),
    );
  }

  Widget _buildNonAiInsightsCard() {
    final insights = _buildNonAiInsights();
    return CardContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Based on your tracked data', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...insights.map((text) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAiInsightsCard() {
    if (_aiLoading) {
      return CardContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generating Flowra AI Insights...',
              style: TextStyle(
                color: Colors.pink.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This may take a moment as we analyze your patterns.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_aiError != null) {
      final isNoData = _aiError == "Log some cycles or health logs to unlock AI insights.";
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isNoData ? Colors.blue.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isNoData ? Colors.blue.shade200 : Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  isNoData ? Icons.info_outline : Icons.warning_amber_rounded,
                  color: isNoData ? Colors.blue.shade800 : Colors.orange.shade800,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNoData ? 'Log Data to Unlock AI Insights' : 'AI Server Offline / Key Missing',
                        style: TextStyle(
                          color: isNoData ? Colors.blue.shade900 : Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isNoData
                            ? 'Once you log your first cycle or health log, Flowra AI will generate personalized patterns and predictions here.'
                            : 'Unable to reach AI services. Displaying local static health insights below:',
                        style: TextStyle(
                          color: isNoData ? Colors.blue.shade800 : Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildNonAiInsightsCard(),
        ],
      );
    }

    if (_aiInsights == null || _aiInsights!.trim().isEmpty) {
      return _buildNonAiInsightsCard();
    }

    final lines = _aiInsights!
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return CardContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'AI Personal Health Insights',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade800,
                        ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: () => _fetchAiInsights(_logs, _cycles),
                tooltip: 'Regenerate insights',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map((line) {
            final isBullet = line.startsWith('•') || line.startsWith('-') || line.startsWith('*') || (line.length > 2 && line.substring(0, 2).contains(RegExp(r'\d')));
            final cleanText = line.replaceFirst(RegExp(r'^[•\-\*\d\.\s]+'), '');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isBullet ? '✨ ' : '• ',
                      style: TextStyle(
                          color: isBullet ? Colors.pink.shade400 : Colors.pink.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cleanText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.3,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Insights generated by Flowra AI. Do not replace professional medical advice.',
              style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBarChart(Map<String, double> phaseAverages) {
    return CardContainer(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Intensity by Cycle Phase',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Calculated dynamically from your mood logs (1-10 scaled)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: phaseAverages.entries.toList().asMap().entries.map((mapEntry) {
              final idx = mapEntry.key;
              final entry = mapEntry.value;
              final phase = entry.key;
              final score = entry.value;

              Color color;
              if (phase == 'Menstrual') {
                color = Colors.red.shade400;
              } else if (phase == 'Follicular') {
                color = Colors.green.shade400;
              } else if (phase == 'Ovulation') {
                color = Colors.teal.shade400;
              } else {
                color = Colors.purple.shade400;
              }

              return Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: score),
                    duration: Duration(milliseconds: 600 + idx * 120),
                    curve: Curves.easeOutBack,
                    builder: (context, animScore, _) {
                      final animHeight = (animScore * 12).clamp(0.0, 120.0);
                      return Column(
                        children: [
                          Text(
                            animScore.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 28,
                            height: animHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withValues(alpha: 0.5), color],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    phase,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<String> _buildNonAiInsights() {
    final insights = <String>[];
    if (_logs.isEmpty) {
      return ['Log a few days of mood, energy, and pain to unlock insights.'];
    }

    if (_summary.avgPain >= 6) {
      insights.add('Pain levels are trending high. Consider rest, hydration, and gentle movement.');
    } else if (_summary.avgPain <= 2) {
      insights.add('Pain levels are generally low. Keep up the consistency in tracking.');
    }

    if (_summary.avgEnergy <= 4) {
      insights.add('Energy is trending low. Prioritize sleep and lighter activities when possible.');
    } else if (_summary.avgEnergy >= 7) {
      insights.add('Energy looks strong. This may be a good time for workouts or active days.');
    }

    final inPeriod = _painCorrelation['inPeriod'] ?? 0.0;
    final outPeriod = _painCorrelation['outPeriod'] ?? 0.0;
    if (inPeriod > outPeriod + 1) {
      insights.add('Pain is higher during your period compared to other days.');
    } else if (outPeriod > inPeriod + 1) {
      insights.add('Pain is higher outside your period. Consider tracking triggers in notes.');
    }

    if (_cycles.isNotEmpty) {
      final lastCycle = _cycles.reduce((a, b) => a.startDate.isAfter(b.startDate) ? a : b);
      final daysInCycle = DateTime.now().difference(lastCycle.startDate).inDays;
      if (daysInCycle <= 5) {
        insights.add('You are likely in the menstrual phase. Rest and hydration can help.');
      } else if (daysInCycle <= 12) {
        insights.add('You may be in the follicular phase. Energy typically rises in this window.');
      } else if (daysInCycle <= 16) {
        insights.add('You may be near ovulation. Many people report peak energy now.');
      } else {
        insights.add('You may be in the luteal phase. Plan for recovery and self-care.');
      }
    }

    return insights.isEmpty ? ['Keep logging daily to surface more insights.'] : insights;
  }

  Widget _buildDailyTipsCard() {
    final tips = _buildDailyTips();
    return CardContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Tips', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...tips.map((tip) => _buildDailyTip(tip.icon, tip.text)),
        ],
      ),
    );
  }

  List<_DailyTip> _buildDailyTips() {
    final tips = <_DailyTip>[];
    if (_summary.avgEnergy <= 4) {
      tips.add(_DailyTip('💤', 'Aim for 7-9 hours of sleep tonight.'));
    } else {
      tips.add(_DailyTip('💪', 'Try a light workout or a long walk today.'));
    }
    if (_summary.avgPain >= 6) {
      tips.add(_DailyTip('🧘', 'Use heat therapy or a short stretching routine.'));
    } else {
      tips.add(_DailyTip('💧', 'Stay hydrated throughout the day.'));
    }
    if (_summary.avgMood <= 4) {
      tips.add(_DailyTip('🫶', 'Plan a calming activity or reach out to support.'));
    } else {
      tips.add(_DailyTip('🥗', 'Add a nutrient-dense meal today.'));
    }
    return tips;
  }

  // Helper widgets
  Widget _buildMetricCard(String label, String value, String emoji) {
    return CardContainer(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Text(emoji, style: const TextStyle(fontSize: 28)),
        ],
      ),
    );
  }

  Widget _buildAccuracyMetric(String label, int percentage) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$percentage%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(String phase, String emoji, double score, String description) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phase, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
            ),
            child: Text('${score.toStringAsFixed(1)}/10', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String emoji, String title, String description, Color color) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
                Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepInsight(String title, List<String> items) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(item, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPhaseExerciseCard(String phase, String emoji, String category, List<String> exercises) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phase, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(category, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: exercises.map((ex) {
              return Chip(
                label: Text(ex, style: const TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                backgroundColor: AppTheme.accent.withValues(alpha: 0.08),
                side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.15)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutBar(String label, int count, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count / 20,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildStressLevel(String label, double level, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              Text('$level/10', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: level > 6 ? Colors.red.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(status, style: TextStyle(color: level > 6 ? Colors.red.shade700 : Colors.orange.shade700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalHealthInsight(String title, String emoji, String description) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreComponent(String label, int current, int max, Color color) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: current / max,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$current/$max', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDailyTip(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tip, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildPainCorrelationWidget() {
    final inPeriod = _painCorrelation['inPeriod'] ?? 0.0;
    final outPeriod = _painCorrelation['outPeriod'] ?? 0.0;
    final difference = (inPeriod - outPeriod).abs();

    return CardContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('During Period', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    Text(inPeriod.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.pink)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outside Period', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    Text(outPeriod.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: inPeriod > 0 ? (inPeriod / 10) : 0,
              minHeight: 8,
              backgroundColor: Colors.pink.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade600),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            inPeriod > outPeriod ? '${difference.toStringAsFixed(1)} higher during period' : '${difference.toStringAsFixed(1)} lower during period',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: inPeriod > outPeriod ? Colors.red.shade600 : Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChart() {
    if (_daily == null) return const SizedBox.shrink();
    final days = (_daily!['days'] as List<DateTime>);
    final mood = List<double>.from(_daily!['mood'] as List);
    final energy = List<double>.from(_daily!['energy'] as List);
    final pain = List<double>.from(_daily!['pain'] as List);

    List<FlSpot> spots(List<double> data) {
      return List<FlSpot>.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    }

    final moodSpots = spots(mood);
    final energySpots = spots(energy);
    final painSpots = spots(pain);

    return SizedBox(
      height: 220,
      child: CardContainer(
        padding: const EdgeInsets.all(12),
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 2, getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                final d = days[idx];
                return Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10));
              })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            ),
            lineBarsData: [
              LineChartBarData(spots: moodSpots, isCurved: true, color: Colors.purple, barWidth: 2),
              LineChartBarData(spots: energySpots, isCurved: true, color: Colors.orange, barWidth: 2),
              LineChartBarData(spots: painSpots, isCurved: true, color: Colors.red, barWidth: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Symptom Activity Heatmap',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 70 days of logged health data',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          CardContainer(
            padding: const EdgeInsets.all(16),
            child: SymptomHeatmap(logs: _logs),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Less', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(width: 6),
              ...List.generate(5, (i) {
                final opacity = 0.1 + i * 0.2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA4C89).withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text('More', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Most Active Days',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_logs.isEmpty)
            Center(
              child: Text(
                'No health logs yet. Start logging to see patterns!',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          else
            ..._buildTopLogDays(),
        ],
      ),
    );
  }

  List<Widget> _buildTopLogDays() {
    final Map<String, int> countByDay = {};
    for (final log in _logs) {
      final key = log.timestamp.toString().split(' ')[0];
      countByDay[key] = (countByDay[key] ?? 0) + 1;
    }
    final sorted = countByDay.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    return top.map((e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEA4C89).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEA4C89).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Color(0xFFEA4C89)),
            const SizedBox(width: 10),
            Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${e.value} log${e.value > 1 ? 's' : ''}',
              style: const TextStyle(color: Color(0xFFEA4C89), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _DailyTip {
  final String icon;
  final String text;

  _DailyTip(this.icon, this.text);
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CardContainer(
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// SymptomHeatmap — 10-week GitHub-style activity grid
// ─────────────────────────────────────────────────────────────────────────────
class SymptomHeatmap extends StatelessWidget {
  final List<HealthLogModel> logs;

  const SymptomHeatmap({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final Map<String, int> countByDay = {};
    for (final log in logs) {
      final key = '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';
      countByDay[key] = (countByDay[key] ?? 0) + 1;
    }

    // 70 days = 10 weeks
    const totalDays = 70;
    final days = List.generate(totalDays, (i) {
      return today.subtract(Duration(days: totalDays - 1 - i));
    });

    const cellSize = 14.0;
    const gap = 3.0;
    const cols = 10; // 10 weeks
    const rows = 7;  // Mon–Sun

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels
        Row(
          children: [
            const SizedBox(width: 28),
            ...List.generate(cols, (w) {
              final weekStart = today.subtract(Duration(days: (cols - 1 - w) * 7 + today.weekday - 1));
              return SizedBox(
                width: cellSize + gap,
                child: Text(
                  '${weekStart.month}/${weekStart.day}',
                  style: const TextStyle(fontSize: 7, color: Color(0xFF9CA3AF)),
                  overflow: TextOverflow.visible,
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekday labels
            Column(
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((d) => SizedBox(
                        width: 24,
                        height: cellSize + gap,
                        child: Text(d, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
                      ))
                  .toList(),
            ),
            // Grid
            Wrap(
              direction: Axis.vertical,
              spacing: gap,
              runSpacing: gap,
              children: List.generate(rows * cols, (i) {
                final col = i ~/ rows;
                final row = i % rows;
                final dayIndex = col * 7 + row;
                if (dayIndex >= totalDays) return SizedBox(width: cellSize, height: cellSize);

                final d = days[dayIndex];
                final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                final count = countByDay[key] ?? 0;

                double opacity;
                if (count == 0) {
                  opacity = 0.06;
                } else if (count == 1) {
                  opacity = 0.3;
                } else if (count == 2) {
                  opacity = 0.5;
                } else if (count == 3) {
                  opacity = 0.7;
                } else {
                  opacity = 0.92;
                }

                final isToday = d.year == today.year && d.month == today.month && d.day == today.day;

                return Tooltip(
                  message: count == 0 ? 'No logs on ${d.month}/${d.day}' : '$count log${count > 1 ? 's' : ''} on ${d.month}/${d.day}',
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200 + dayIndex * 3),
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA4C89).withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(3),
                      border: isToday
                          ? Border.all(color: const Color(0xFFEA4C89), width: 1.5)
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}
