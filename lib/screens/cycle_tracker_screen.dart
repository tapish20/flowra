import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/cycle_model.dart';
import '../services/cycle_service.dart';
import '../widgets/card_container.dart';
import '../widgets/primary_button.dart';
import '../theme.dart';

class CycleTrackerScreen extends StatefulWidget {
  const CycleTrackerScreen({super.key});

  @override
  State<CycleTrackerScreen> createState() => _CycleTrackerScreenState();
}

class _CycleTrackerScreenState extends State<CycleTrackerScreen> {
  final CycleService _cycleService = CycleService();

  DateTime? _pickedDate;
  int _periodLength = 5;
  DateTime _calendarMonth = DateTime.now();

  Future<void> _confirmSave() async {
    if (_pickedDate == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Save'),
        content: Text('Save period starting ${_pickedDate!.toLocal().toString().split(' ')[0]} with $_periodLength day(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
        await _savePeriod(_pickedDate!, periodLength: _periodLength); // Extracted save logic
    }
  }

  Future<CycleModel?> _savePeriod(DateTime start, {required int periodLength}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final existing = await _cycleService.fetchCyclesOnce();
      int cycleLen = 28;
      if (existing.isNotEmpty) {
        final sorted = List<CycleModel>.from(existing)
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        CycleModel? next;
        CycleModel? prev;
        for (final c in sorted) {
          if (c.startDate.isAfter(start)) {
            next = c;
            break;
          }
          prev = c;
        }
        if (next != null) {
          cycleLen = next.startDate.difference(start).inDays;
        } else if (prev != null) {
          cycleLen = start.difference(prev.startDate).inDays;
        }
        if (cycleLen <= 0) cycleLen = 28; // fallback for bad dates
      }
      final model = CycleModel(startDate: start, cycleLength: cycleLen, periodLength: periodLength);
      await _cycleService.addCycle(model);
      await _cycleService.addRecentCycle(model);
      if (!mounted) return null;
      setState(() => _pickedDate = null);
      messenger.showSnackBar(const SnackBar(content: Text('Period saved!'), backgroundColor: Colors.green));
      return model;
    } catch (e) {
      if (!mounted) return null;
      messenger.showSnackBar(SnackBar(content: Text('Failed to save period: ${e.toString()}'), backgroundColor: Colors.red.shade700));
      return null;
    }
  }

  Future<void> _showAddPreviousCycleDialog() async {
    final now = DateTime.now();
    DateTime? dialogDate;
    int dialogPeriodLength = 5;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Previous Cycle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dialogDate ?? now,
                      firstDate: DateTime(now.year - 10),
                      lastDate: now,
                    );
                    if (picked != null) {
                      setDialogState(() => dialogDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    dialogDate == null
                        ? 'Pick previous start date'
                        : dialogDate!.toLocal().toString().split(' ')[0],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Period days ($dialogPeriodLength)',
                    hintText: 'e.g. 5',
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v) ?? 5;
                    setDialogState(() => dialogPeriodLength = parsed.clamp(1, 14));
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: dialogDate == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _savePeriod(dialogDate!, periodLength: dialogPeriodLength);
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showBulkAddDialog() async {
    final now = DateTime.now();
    final entries = <_BulkEntry>[_BulkEntry()];

    bool allDatesPicked() => entries.every((e) => e.date != null);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Multiple Previous Cycles'),
            content: SizedBox(
              width: 420,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: item.date ?? now,
                                  firstDate: DateTime(now.year - 10),
                                  lastDate: now,
                                );
                                if (picked != null) {
                                  setDialogState(() => item.date = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                item.date == null
                                    ? 'Pick start date'
                                    : item.date!.toLocal().toString().split(' ')[0],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Days',
                                hintText: '${item.periodLength}',
                              ),
                              onChanged: (v) {
                                final parsed = int.tryParse(v) ?? item.periodLength;
                                setDialogState(() => item.periodLength = parsed.clamp(1, 14));
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: entries.length == 1
                                ? null
                                : () => setDialogState(() => entries.removeAt(index)),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: () => setDialogState(() => entries.add(_BulkEntry())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: allDatesPicked()
                    ? () async {
                        Navigator.pop(ctx);
                        for (final entry in entries) {
                          if (entry.date != null) {
                            await _savePeriod(entry.date!, periodLength: entry.periodLength);
                          }
                        }
                      }
                    : null,
                child: const Text('Save All'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cycle Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0F5), Color(0xFFFDFBFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cycle Overview',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Icon(Icons.calendar_month, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track patterns and plan with confidence',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _HeaderAction(
                          icon: Icons.calendar_today,
                          label: 'Add Period',
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: DateTime(now.year - 10),
                              lastDate: now,
                            );
                            if (picked != null) setState(() => _pickedDate = picked);
                          },
                        ),
                        const SizedBox(width: 12),
                        _HeaderAction(
                          icon: Icons.history,
                          label: 'Add Previous',
                          onTap: _showAddPreviousCycleDialog,
                        ),
                        const SizedBox(width: 12),
                        _HeaderAction(
                          icon: Icons.library_add,
                          label: 'Add Multiple',
                          onTap: _showBulkAddDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Your Cycles', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              CardContainer(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<List<CycleModel>>(
                  stream: _cycleService.streamCycles(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                    }
                    final cycles = snap.data ?? [];
                    final avg = _cycleService.averageCycleLength(cycles).toStringAsFixed(1);
                    final predicted = _cycleService.predictNextCycleStart(cycles);
                    final last = cycles.isNotEmpty ? cycles.first : null;

                    int currentCycleDay = 1;
                    int cycleLength = 28;
                    int periodLength = 5;
                    bool activeCycle = false;

                    if (last != null) {
                      final today = DateTime.now();
                      final diff = today.difference(last.startDate).inDays + 1;
                      if (diff > 0 && diff <= last.cycleLength) {
                        currentCycleDay = diff;
                        cycleLength = last.cycleLength;
                        periodLength = last.periodLength;
                        activeCycle = true;
                      }
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (activeCycle) ...[
                          RadialCycleRing(
                            cycleDay: currentCycleDay,
                            cycleLength: cycleLength,
                            periodLength: periodLength,
                            size: 130,
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StatPill(
                                title: 'Average Cycle',
                                value: '$avg days',
                                icon: Icons.timeline,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(height: 10),
                              _StatPill(
                                title: 'Next Period',
                                value: predicted != null ? predicted.toLocal().toString().split(' ')[0] : 'No data',
                                icon: Icons.event,
                                color: AppTheme.accent,
                              ),
                              const SizedBox(height: 10),
                              _StatPill(
                                title: 'Last Period',
                                value: last != null ? last.startDate.toLocal().toString().split(' ')[0] : 'No data',
                                icon: Icons.favorite,
                                color: const Color(0xFF2ECC71),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text('Calendar View', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<List<CycleModel>>(
                stream: _cycleService.streamCycles(),
                builder: (context, snap) {
                  final cycles = snap.data ?? [];
                  return _buildCalendarCard(cycles);
                },
              ),
              const SizedBox(height: 24),
              Text('Recent Cycles', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<List<CycleModel>>(
                stream: _cycleService.streamCycles(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                  }
                  final cycles = snap.data ?? [];
                  if (cycles.isEmpty) {
                    return CardContainer(
                      child: Center(child: Text('No cycles recorded yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey))),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cycles.length,
                    itemBuilder: (context, idx) {
                      final c = cycles[idx];
                      return CardContainer(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.water_drop, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Start: ${c.startDate.toLocal().toString().split(' ')[0]}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text('${c.cycleLength}d cycle | ${c.periodLength}d period', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => c.id != null ? _cycleService.deleteCycle(c.id!) : null,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Add New Period', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              CardContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: now,
                                firstDate: DateTime(now.year - 10),
                                lastDate: now,
                              );
                              if (picked != null) setState(() => _pickedDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_pickedDate == null ? 'Pick start date' : _pickedDate!.toLocal().toString().split(' ')[0]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Period days ($_periodLength)', hintText: 'e.g. 5'),
                            onChanged: (v) {
                              final parsed = int.tryParse(v) ?? 5;
                              setState(() => _periodLength = parsed.clamp(1, 14));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Save Period Start',
                      onPressed: _pickedDate == null
                          ? null
                          : () async {
                              await _confirmSave();
                            },
                    ),
                  ],
                ),
              ),
              StreamBuilder<List<CycleModel>>(
                stream: _cycleService.streamRecentCycles(),
                builder: (context, snap) {
                  final recent = snap.data ?? [];
                  if (recent.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text('Recently Added', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CardContainer(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: recent.map((c) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    c.startDate.toLocal().toString().split(' ')[0],
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${c.periodLength}d period',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard(List<CycleModel> cycles) {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    
    // First day of displayed month
    final firstDayOfMonth = DateTime(year, month, 1);
    // Number of days in displayed month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Weekday of the first day (Monday is 1, Sunday is 7 in Dart DateTime)
    final firstWeekday = firstDayOfMonth.weekday;
    
    // Calculate previous period details, predicted next period, fertile window, ovulation day
    final predictedStart = _cycleService.predictNextCycleStart(cycles);
    // Default period duration fallback is 5 days
    final avgPeriodLength = cycles.isNotEmpty ? cycles.first.periodLength : 5;
    
    // Fertile window is usually 5 days leading up to ovulation and the ovulation day itself
    // Ovulation is usually 14 days before the predicted start of the next period
    DateTime? ovulationDate;
    DateTime? fertileStart;
    DateTime? fertileEnd;
    
    if (predictedStart != null) {
      ovulationDate = predictedStart.subtract(const Duration(days: 14));
      fertileStart = ovulationDate.subtract(const Duration(days: 5));
      fertileEnd = ovulationDate;
    }
    
    // Month Names
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    // Weekday letters (starting with Monday = index 0)
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return CardContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppTheme.primary),
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(year, month - 1, 1);
                  });
                },
              ),
              Text(
                '${monthNames[month - 1]} $year',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppTheme.primary),
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(year, month + 1, 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Weekday labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((w) => SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  w,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            // Offset count: we shift the grid cells by (firstWeekday - 1)
            itemCount: daysInMonth + (firstWeekday - 1),
            itemBuilder: (context, index) {
              final offset = firstWeekday - 1;
              if (index < offset) {
                return const SizedBox.shrink();
              }
              
              final dayNum = index - offset + 1;
              final cellDate = DateTime.utc(year, month, dayNum);
              
              // Determine state of the cellDate
              bool isActualPeriod = false;
              bool isPredictedPeriod = false;
              bool isOvulation = false;
              bool isFertileWindow = false;
              
              // 1. Check if cellDate is in actual logged periods
              for (final c in cycles) {
                final start = DateTime.utc(c.startDate.year, c.startDate.month, c.startDate.day);
                final end = start.add(Duration(days: c.periodLength - 1));
                if (!cellDate.isBefore(start) && !cellDate.isAfter(end)) {
                  isActualPeriod = true;
                  break;
                }
              }
              
              // 2. Check if cellDate is in predicted periods
              if (!isActualPeriod && predictedStart != null) {
                final start = DateTime.utc(predictedStart.year, predictedStart.month, predictedStart.day);
                final end = start.add(Duration(days: avgPeriodLength - 1));
                if (!cellDate.isBefore(start) && !cellDate.isAfter(end)) {
                  isPredictedPeriod = true;
                }
              }
              
              // 3. Check if cellDate is predicted ovulation day
              if (!isActualPeriod && !isPredictedPeriod && ovulationDate != null) {
                final oDay = DateTime.utc(ovulationDate.year, ovulationDate.month, ovulationDate.day);
                if (cellDate.isAtSameMomentAs(oDay)) {
                  isOvulation = true;
                }
              }
              
              // 4. Check if cellDate is in predicted fertile window
              if (!isActualPeriod && !isPredictedPeriod && !isOvulation && fertileStart != null && fertileEnd != null) {
                final fStart = DateTime.utc(fertileStart.year, fertileStart.month, fertileStart.day);
                final fEnd = DateTime.utc(fertileEnd.year, fertileEnd.month, fertileEnd.day);
                if (!cellDate.isBefore(fStart) && !cellDate.isAfter(fEnd)) {
                  isFertileWindow = true;
                }
              }
              
              // Highlight selected picked date in input field
              final isPicked = _pickedDate != null &&
                  _pickedDate!.year == year &&
                  _pickedDate!.month == month &&
                  _pickedDate!.day == dayNum;
                  
              // Style variables based on state
              Color? bgColor;
              Color textColor = Colors.black87;
              BoxBorder? border;
              
              if (isPicked) {
                bgColor = AppTheme.primary;
                textColor = Colors.white;
              } else if (isActualPeriod) {
                bgColor = AppTheme.primary.withValues(alpha: 0.15);
                textColor = AppTheme.primary;
                border = Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 1.5);
              } else if (isPredictedPeriod) {
                bgColor = AppTheme.accent.withValues(alpha: 0.12);
                textColor = AppTheme.accent;
                border = Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 1.5);
              } else if (isOvulation) {
                bgColor = const Color(0xFF2ECC71);
                textColor = Colors.white;
              } else if (isFertileWindow) {
                bgColor = const Color(0xFF2ECC71).withValues(alpha: 0.12);
                textColor = const Color(0xFF27AE60);
              }
              
              final isToday = DateTime.now().year == year &&
                  DateTime.now().month == month &&
                  DateTime.now().day == dayNum;
                  
              return InkWell(
                onTap: () {
                  setState(() {
                    _pickedDate = DateTime(year, month, dayNum);
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: border ?? (isToday && !isPicked ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5) : null),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontWeight: (isToday || isPicked || isActualPeriod || isPredictedPeriod) ? FontWeight.bold : FontWeight.normal,
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Legend / Guide
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem('Period', AppTheme.primary.withValues(alpha: 0.15), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4))),
              _buildLegendItem('Predicted Period', AppTheme.accent.withValues(alpha: 0.12), border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3))),
              _buildLegendItem('Ovulation Day', const Color(0xFF2ECC71), textColor: Colors.white),
              _buildLegendItem('Fertile Window', const Color(0xFF2ECC71).withValues(alpha: 0.12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {BoxBorder? border, Color textColor = Colors.black87}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _BulkEntry {
  DateTime? date;
  int periodLength = 5;
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatPill({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RadialCycleRing — animated radial cycle phase visualizer dial
// ─────────────────────────────────────────────────────────────────────────────
class RadialCycleRing extends StatelessWidget {
  final int cycleDay;
  final int cycleLength;
  final int periodLength;
  final double size;

  const RadialCycleRing({
    super.key,
    required this.cycleDay,
    required this.cycleLength,
    required this.periodLength,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final ovulationDay = cycleLength - 14;
    final ovulationStart = ovulationDay - 2;
    final ovulationEnd = ovulationDay + 2;

    String phaseName;
    Color phaseColor;
    if (cycleDay <= periodLength) {
      phaseName = 'Menstrual';
      phaseColor = const Color(0xFFEA4C89);
    } else if (cycleDay < ovulationStart) {
      phaseName = 'Follicular';
      phaseColor = const Color(0xFFF39C12);
    } else if (cycleDay <= ovulationEnd) {
      phaseName = 'Ovulatory';
      phaseColor = const Color(0xFF2ECC71);
    } else {
      phaseName = 'Luteal';
      phaseColor = const Color(0xFF9B59B6);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: cycleDay.toDouble()),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _CycleRingPainter(
                  cycleDay: value.round(),
                  cycleLength: cycleLength,
                  periodLength: periodLength,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Day',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${value.round()}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2D3748),
                      letterSpacing: -1,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: phaseColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      phaseName,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: phaseColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CycleRingPainter extends CustomPainter {
  final int cycleDay;
  final int cycleLength;
  final int periodLength;

  _CycleRingPainter({
    required this.cycleDay,
    required this.cycleLength,
    required this.periodLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 10.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final menstruationAngle = (periodLength / cycleLength) * 2 * math.pi;

    final ovulationDay = cycleLength - 14;
    final ovulationStart = ovulationDay - 2;
    final ovulationEnd = ovulationDay + 2;

    final follicularAngle = ((ovulationStart - 1 - periodLength) / cycleLength) * 2 * math.pi;
    final ovulationAngle = ((ovulationEnd - ovulationStart + 1) / cycleLength) * 2 * math.pi;
    final lutealAngle = 2 * math.pi - (menstruationAngle + follicularAngle + ovulationAngle);

    double startAngle = -math.pi / 2;

    // Menstruation (Pink)
    paint.color = const Color(0xFFEA4C89).withValues(alpha: 0.85);
    canvas.drawArc(rect, startAngle, menstruationAngle, false, paint);

    // Follicular (Yellow/Orange)
    startAngle += menstruationAngle;
    paint.color = const Color(0xFFF39C12).withValues(alpha: 0.85);
    canvas.drawArc(rect, startAngle, follicularAngle, false, paint);

    // Ovulation (Teal/Green)
    startAngle += follicularAngle;
    paint.color = const Color(0xFF2ECC71).withValues(alpha: 0.85);
    canvas.drawArc(rect, startAngle, ovulationAngle, false, paint);

    // Luteal (Purple/Lavender)
    startAngle += ovulationAngle;
    paint.color = const Color(0xFF9B59B6).withValues(alpha: 0.85);
    canvas.drawArc(rect, startAngle, lutealAngle, false, paint);

    // Marker
    final progressAngle = ((cycleDay - 1) / cycleLength) * 2 * math.pi - math.pi / 2;
    final markerOffset = Offset(
      center.dx + radius * math.cos(progressAngle),
      center.dy + radius * math.sin(progressAngle),
    );

    canvas.drawCircle(
      markerOffset,
      8.0,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawCircle(
      markerOffset,
      7.0,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      markerOffset,
      4.0,
      Paint()
        ..color = const Color(0xFFEA4C89)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_CycleRingPainter old) =>
      old.cycleDay != cycleDay ||
      old.cycleLength != cycleLength ||
      old.periodLength != periodLength;
}
