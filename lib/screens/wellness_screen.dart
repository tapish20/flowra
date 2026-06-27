import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../widgets/card_container.dart';
import '../widgets/animations.dart';
import '../theme.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  static final List<WellnessSession> _allSessions = [
    WellnessSession(
      id: 1,
      title: 'Breathing Exercise - 5 min',
      description: 'Guided breathing to calm anxiety and reduce stress',
      category: 'Breathing',
      duration: '5 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=odADwWzHR24',
      icon: Icons.air,
    ),
    WellnessSession(
      id: 2,
      title: 'Gentle Stretching',
      description: 'Short stretch routine for comfort and flexibility',
      category: 'Stretching',
      duration: '10 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=VaoV1PrYft4',
      icon: Icons.self_improvement,
    ),
    WellnessSession(
      id: 3,
      title: 'Short Guided Meditation',
      description: '5 minute grounding meditation for mindfulness',
      category: 'Meditation',
      duration: '5 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=inpok4MKVLM',
      icon: Icons.spa,
    ),
    WellnessSession(
      id: 4,
      title: 'Yoga for Period Comfort',
      description: 'Gentle yoga poses to ease period discomfort',
      category: 'Yoga',
      duration: '15 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=_Auza-7jCEA',
      icon: Icons.self_improvement,
    ),
    WellnessSession(
      id: 5,
      title: 'Deep Relaxation',
      description: 'Progressive muscle relaxation for deep rest',
      category: 'Relaxation',
      duration: '15 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=X3Z7DZ2dQKU',
      icon: Icons.healing,
    ),
    WellnessSession(
      id: 6,
      title: 'Morning Energizer',
      description: 'Dynamic stretches to start your day energized',
      category: 'Exercise',
      duration: '10 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=L_xrDAtfqIo',
      icon: Icons.energy_savings_leaf,
    ),
    WellnessSession(
      id: 7,
      title: 'Anxiety Relief Meditation',
      description: 'Guided meditation to calm anxious thoughts',
      category: 'Meditation',
      duration: '10 min',
      difficulty: 'Intermediate',
      url: 'https://www.youtube.com/watch?v=SEDuGFVXYFQ',
      icon: Icons.spa,
    ),
    WellnessSession(
      id: 8,
      title: 'Sleep Preparation',
      description: 'Calming routine to prepare for restful sleep',
      category: 'Relaxation',
      duration: '20 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=UZjOPCRB0_4',
      icon: Icons.nights_stay,
    ),
  ];

  String _selectedCategory = 'All';
  final Set<int> _completedSessions = {};
  final Set<int> _favoriteSessions = {};

  List<WellnessSession> get _filteredSessions {
    if (_selectedCategory == 'All') {
      return _allSessions;
    }
    return _allSessions.where((s) => s.category == _selectedCategory).toList();
  }

  Set<String> get _categories {
    final cats = <String>{'All'};
    for (final session in _allSessions) {
      cats.add(session.category);
    }
    return cats;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open video')),
        );
      }
    }
  }

  void _toggleComplete(int sessionId) {
    setState(() {
      if (_completedSessions.contains(sessionId)) {
        _completedSessions.remove(sessionId);
      } else {
        _completedSessions.add(sessionId);
      }
    });
  }

  void _toggleFavorite(int sessionId) {
    setState(() {
      if (_favoriteSessions.contains(sessionId)) {
        _favoriteSessions.remove(sessionId);
      } else {
        _favoriteSessions.add(sessionId);
      }
    });
  }

  void _showBreathingModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BreathingExerciseDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Wellness Sessions'),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
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
                      Text(
                        'Take Care of Yourself',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Explore guided sessions for relaxation and wellness',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 16),
                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_completedSessions.length}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Completed',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_favoriteSessions.length}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Favorites',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Category Filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                labelStyle: TextStyle(
                                  color: isSelected ? AppTheme.primary : const Color(0xFF4A5568),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                selected: isSelected,
                                selectedColor: AppTheme.primary.withValues(alpha: 0.12),
                                backgroundColor: const Color(0xFFF7FAFC),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primary.withValues(alpha: 0.4) : Colors.transparent,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onSelected: (_) {
                                  setState(() => _selectedCategory = category);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Sessions List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _filteredSessions.isEmpty
                      ? Center(
                          key: const ValueKey('empty'),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No sessions in this category',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ),
                        )
                      : Column(
                          key: ValueKey(_selectedCategory),
                          children: [
                            ..._filteredSessions.asMap().entries.map((entry) {
                              final i = entry.key;
                              final session = entry.value;
                              final isCompleted = _completedSessions.contains(session.id);
                              final isFavorite = _favoriteSessions.contains(session.id);
                              return FadeInSlide(
                                key: ValueKey(session.id),
                                duration: const Duration(milliseconds: 380),
                                delay: Duration(milliseconds: i * 60),
                                yOffset: 16,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: CardContainer(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Icon(
                                                session.icon,
                                                color: AppTheme.primary,
                                                size: 32,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    session.title,
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    session.description,
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: Colors.grey.shade600,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.timer, size: 14, color: Colors.grey.shade500),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        session.duration,
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                              color: Colors.grey.shade600,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.accent.withValues(alpha: 0.08),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          session.difficulty,
                                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                color: AppTheme.accent,
                                                                fontSize: 11,
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
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                                    color: isFavorite ? Colors.red : Colors.grey,
                                                  ),
                                                  onPressed: () => _toggleFavorite(session.id),
                                                  constraints: const BoxConstraints(),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                const SizedBox(width: 16),
                                                IconButton(
                                                  icon: Icon(
                                                    isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                                                    color: isCompleted ? Colors.green : Colors.grey,
                                                  ),
                                                  onPressed: () => _toggleComplete(session.id),
                                                  constraints: const BoxConstraints(),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ],
                                            ),
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  if (session.category == 'Breathing') {
                                                    _showBreathingModal(context);
                                                  } else {
                                                    _openUrl(session.url);
                                                  }
                                                },
                                                borderRadius: BorderRadius.circular(24),
                                                child: Ink(
                                                  decoration: BoxDecoration(
                                                    gradient: AppTheme.accentGradient,
                                                    borderRadius: BorderRadius.circular(24),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppTheme.accent.withValues(alpha: 0.3),
                                                        blurRadius: 10,
                                                        offset: const Offset(0, 6),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Watch',
                                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WellnessSession {
  final int id;
  final String title;
  final String description;
  final String category;
  final String duration;
  final String difficulty;
  final String url;
  final IconData icon;

  WellnessSession({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.difficulty,
    required this.url,
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// BreathingExerciseDialog — animated box breathing overlay (4-4-4-4 technique)
// ─────────────────────────────────────────────────────────────────────────────
class BreathingExerciseDialog extends StatefulWidget {
  const BreathingExerciseDialog({super.key});

  @override
  State<BreathingExerciseDialog> createState() => _BreathingExerciseDialogState();
}

class _BreathingExerciseDialogState extends State<BreathingExerciseDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bubbleScale;

  // Box breathing states: 0 = Inhale, 1 = Hold, 2 = Exhale, 3 = Hold
  int _breathState = 0;
  int _secondsRemaining = 4;
  Timer? _timer;

  final List<String> _instructions = [
    'Breathe In...',
    'Hold...',
    'Breathe Out...',
    'Hold...',
  ];

  final List<Color> _colors = [
    const Color(0xFFEA4C89), // Inhale (Pink)
    const Color(0xFF6C5CE7), // Hold (Purple)
    const Color(0xFF3498DB), // Exhale (Blue)
    const Color(0xFF2ECC71), // Hold (Green)
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _bubbleScale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _secondsRemaining = 4;
          _breathState = (_breathState + 1) % 4;

          if (_breathState == 0) {
            _controller.forward();
          } else if (_breathState == 1) {
            // Hold full
          } else if (_breathState == 2) {
            _controller.reverse();
          } else if (_breathState == 3) {
            // Hold empty
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _colors[_breathState];
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Box Breathing',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Follow the circular guide to calm your mind.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Breathing Bubble
            SizedBox(
              height: 220,
              width: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade100, width: 2),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade100, width: 2),
                    ),
                  ),

                  // Animated Pulsating Bubble
                  AnimatedBuilder(
                    animation: _bubbleScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _bubbleScale.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                currentColor.withValues(alpha: 0.55),
                                currentColor.withValues(alpha: 0.15),
                              ],
                            ),
                            border: Border.all(color: currentColor, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: currentColor.withValues(alpha: 0.2),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Ticking number in center
                  Text(
                    '$_secondsRemaining',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: currentColor.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Instruction
            Text(
              _instructions[_breathState],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: currentColor,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 24),

            // Step Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final active = index == _breathState;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 28 : 12,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? currentColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
