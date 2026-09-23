import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/auth_service.dart';
import '../services/cycle_service.dart';
import '../services/health_log_service.dart';
import '../models/health_log_model.dart';
import 'cycle_tracker_screen.dart';
import 'contacts_screen.dart';
import 'insights_screen.dart';
import 'health_logging_screen.dart';
import 'wellness_screen.dart';
import 'chatbot_screen.dart';
import 'sos_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import '../widgets/card_container.dart';
import '../widgets/animations.dart';
import '../widgets/empty_state.dart';
import '../widgets/onboarding_overlay.dart';
import '../utils/responsive.dart';

// ────────────────────────────────────────────────────────────────────────────
// Breakpoint helpers
// ────────────────────────────────────────────────────────────────────────────
const double _kMobileBreakpoint = 700;

// ────────────────────────────────────────────────────────────────────────────
// Nav destination metadata
// ────────────────────────────────────────────────────────────────────────────
const _navItems = [
  (icon: Icons.home_rounded, label: 'Home'),
  (icon: Icons.calendar_today_rounded, label: 'Tracker'),
  (icon: Icons.mood_rounded, label: 'Health'),
  (icon: Icons.show_chart_rounded, label: 'Insights'),
  (icon: Icons.people_rounded, label: 'Contacts'),
  (icon: Icons.self_improvement_rounded, label: 'Wellness'),
  (icon: Icons.chat_rounded, label: 'AI Chat'),
  (icon: Icons.settings_rounded, label: 'Settings'),
];

// ────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final CycleService _cycleService = CycleService();
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  // GlobalKeys for onboarding coach marks
  final GlobalKey _sosFabKey = GlobalKey();
  final GlobalKey _trackerNavKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pages = [
      _HomeContent(
        cycleService: _cycleService,
        onTabSelected: (i) => setState(() => _selectedIndex = i),
      ),
      const CycleTrackerScreen(),
      const HealthLoggingScreen(),
      const InsightsScreen(),
      const ContactsScreen(),
      const WellnessScreen(),
      const ChatbotScreen(),
      const SettingsScreen(),
    ];
    // Show coach marks after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showCoachMarksIfNeeded(context, [
          CoachMarkData(
            targetKey: _sosFabKey,
            title: 'Emergency SOS',
            body: 'Hold this button in an emergency to send your location and an alert to your trusted contacts.',
            prefKey: 'coach_sos_fab',
          ),
          CoachMarkData(
            targetKey: _trackerNavKey,
            title: 'Cycle Tracker',
            body: 'Track your period, log symptoms, and see a radial view of your cycle phases here.',
            prefKey: 'coach_tracker_nav',
          ),
        ]);
      }
    });
  }

  // ── Pulsing SOS FAB ──────────────────────────────────────────────────────
  Widget _buildSosFab() {
    return RippleAnimation(
      color: Colors.red.shade400,
      maxRadius: 65,
      child: PulseAnimation(
        minScale: 1.0,
        maxScale: 1.06,
        duration: const Duration(milliseconds: 950),
        child: FloatingActionButton.extended(
          key: _sosFabKey,
          heroTag: 'sos_fab',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SosScreen()),
          ),
          backgroundColor: Colors.red.shade600,
          elevation: 6,
          icon: const Icon(Icons.emergency_rounded, color: Colors.white),
          label: const Text(
            'SOS',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
      ),
    );
  }

  // ── Animated content switcher ────────────────────────────────────────────
  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.015, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey<int>(_selectedIndex),
        child: _pages[_selectedIndex],
      ),
    );
  }

  // ── Desktop sidebar layout ───────────────────────────────────────────────
  Widget _buildDesktop() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildSosFab(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade50, const Color(0xFFFFF7FA), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            // Sidebar with Glassmorphism
            Container(
              width: 270,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Column(
                children: [
                  // Sidebar header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFEA4C89), Color(0xFF6C5CE7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Flowra',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'DASHBOARD',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              for (int i = 0; i < 7; i++)
                                _SidebarItem(
                                  key: i == 1 ? _trackerNavKey : null,
                                  icon: _navItems[i].icon,
                                  label: _navItems[i].label,
                                  isSelected: _selectedIndex == i,
                                  onTap: () =>
                                      setState(() => _selectedIndex = i),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _SidebarItem(
                                icon: Icons.settings_rounded,
                                label: 'Settings',
                                isSelected: _selectedIndex == 7,
                                onTap: () =>
                                    setState(() => _selectedIndex = 7),
                              ),
                              _SidebarItem(
                                icon: Icons.logout_rounded,
                                label: 'Logout',
                                isSelected: false,
                                onTap: _logout,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // ── Mobile bottom nav layout ─────────────────────────────────────────────
  Widget _buildMobile() {
    // Only show first 5 items in bottom nav; settings in drawer
    const bottomItems = [0, 1, 2, 3, 6]; // Home, Tracker, Health, Insights, AI

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      floatingActionButton: _buildSosFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEA4C89), Color(0xFF6C5CE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            const Text(
              'Flowra',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF4A5568)),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      endDrawer: _buildDrawer(),
      body: _buildContent(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: bottomItems.map((pageIdx) {
                final item = _navItems[pageIdx];
                final selected = _selectedIndex == pageIdx;
                return Expanded(
                  key: pageIdx == 1 ? _trackerNavKey : null,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = pageIdx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFEA4C89).withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              item.icon,
                              size: 22,
                              color: selected
                                  ? const Color(0xFFEA4C89)
                                  : const Color(0xFF718096),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? const Color(0xFFEA4C89)
                                  : const Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEA4C89), Color(0xFF6C5CE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              width: double.infinity,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text('Flowra',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20)),
                  Text('More options',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final idx in [4, 5, 7]) // Contacts, Wellness, Settings
              ListTile(
                leading: Icon(_navItems[idx].icon,
                    color: _selectedIndex == idx
                        ? const Color(0xFFEA4C89)
                        : const Color(0xFF4A5568)),
                title: Text(_navItems[idx].label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _selectedIndex == idx
                            ? const Color(0xFFEA4C89)
                            : const Color(0xFF2D3748))),
                selected: _selectedIndex == idx,
                selectedTileColor:
                    const Color(0xFFEA4C89).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  setState(() => _selectedIndex = idx);
                  Navigator.pop(context);
                },
              ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: Color(0xFF4A5568)),
              title: const Text('Logout',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748))),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await _authService.logout();
    if (!mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _kMobileBreakpoint) {
          return _buildMobile();
        }
        return _buildDesktop();
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sidebar Item
// ────────────────────────────────────────────────────────────────────────────
class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;
    final showHover = _isHovered && !active;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.diagonal3Values(_isHovered && !active ? 1.025 : 1.0, _isHovered && !active ? 1.025 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          padding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFEA4C89), Color(0xFFF5576C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : showHover
                    ? LinearGradient(colors: [
                        const Color(0xFFEA4C89).withValues(alpha: 0.08),
                        const Color(0xFFEA4C89).withValues(alpha: 0.03),
                      ])
                    : const LinearGradient(
                        colors: [Colors.transparent, Colors.transparent]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color:
                          const Color(0xFFEA4C89).withValues(alpha: 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 3,
                height: (active || _isHovered) ? 18 : 0,
                decoration: BoxDecoration(
                  color: active ? Colors.white : const Color(0xFFEA4C89),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: (active || _isHovered) ? 10 : 0,
              ),
              Icon(
                widget.icon,
                color: active
                    ? Colors.white
                    : showHover
                        ? const Color(0xFFEA4C89)
                        : const Color(0xFF718096),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : showHover
                          ? const Color(0xFFEA4C89)
                          : const Color(0xFF4A5568),
                  fontWeight:
                      active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Home Content (dashboard body)
// ────────────────────────────────────────────────────────────────────────────
class _HomeContent extends StatelessWidget {
  final CycleService cycleService;
  final Function(int) onTabSelected;

  const _HomeContent({
    required this.cycleService,
    required this.onTabSelected,
  });

  // ── Streak computation ──────────────────────────────────────────────────
  int _computeStreak(List<HealthLogModel> logs) {
    if (logs.isEmpty) return 0;
    final loggedDays = logs
        .map((l) => DateTime(
            l.timestamp.year, l.timestamp.month, l.timestamp.day))
        .toSet();

    int streak = 0;
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);

    // If today isn't logged yet, start checking from yesterday
    if (!loggedDays.contains(day)) {
      day = day.subtract(const Duration(days: 1));
    }

    while (loggedDays.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hPad = isMobile ? 16.0 : 24.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Glassmorphism hero banner ───────────────────────────────
            FadeInSlide(
              duration: const Duration(milliseconds: 450),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Background gradient
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 20 : 26),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEA4C89), Color(0xFF6C5CE7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Welcome back! 👋',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: isMobile ? 20 : 24,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Today',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Take charge of your health and safety today',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _QuickActionCard(
                                label: 'Log Health',
                                icon: Icons.mood_rounded,
                                onTap: () => onTabSelected(2),
                              ),
                              _QuickActionCard(
                                label: 'Track Period',
                                icon: Icons.calendar_today_rounded,
                                onTap: () => onTabSelected(1),
                              ),
                              _QuickActionCard(
                                label: 'Insights',
                                icon: Icons.show_chart_rounded,
                                onTap: () => onTabSelected(3),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Glassmorphism overlay (top-right corner shimmer)
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Health Log Streak ───────────────────────────────────────
            FadeInSlide(
              duration: const Duration(milliseconds: 420),
              delay: const Duration(milliseconds: 80),
              child: FutureBuilder<List<HealthLogModel>>(
                future: HealthLogService().fetchLogsOnce(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final streak = _computeStreak(snap.data!);
                  if (streak == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade50,
                          Colors.amber.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.orange.shade200, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥',
                            style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$streak-Day Logging Streak!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Colors.orange.shade800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                'Keep it up — consistency unlocks better insights',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Quick Actions ───────────────────────────────────────────
            FadeInSlide(
              duration: const Duration(milliseconds: 420),
              delay: const Duration(milliseconds: 120),
              child: const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D3748),
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            isMobile
                ? Column(
                    children: [
                      FadeInSlide(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 150),
                        child: _FeatureCard(
                          title: 'Wellness',
                          subtitle: 'Guided self-care',
                          icon: Icons.self_improvement_rounded,
                          color: Colors.green.shade600,
                          onTap: () => onTabSelected(5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInSlide(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 230),
                        child: _FeatureCard(
                          title: 'Trusted Contacts',
                          subtitle: 'Manage safety circle',
                          icon: Icons.people_rounded,
                          color: Colors.indigo.shade600,
                          onTap: () => onTabSelected(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInSlide(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 310),
                        child: _FeatureCard(
                          title: 'AI Assistant',
                          subtitle: 'Ask Flowra anything',
                          icon: Icons.chat_bubble_outline_rounded,
                          color: Colors.pink.shade600,
                          onTap: () => onTabSelected(6),
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FadeInSlide(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 150),
                        child: _FeatureCard(
                          title: 'Wellness',
                          subtitle: 'Guided self-care',
                          icon: Icons.self_improvement_rounded,
                          color: Colors.green.shade600,
                          onTap: () => onTabSelected(5),
                        ),
                      ),
                      FadeInSlide(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 230),
                        child: _FeatureCard(
                          title: 'Trusted Contacts',
                          subtitle: 'Manage safety circle',
                          icon: Icons.people_rounded,
                          color: Colors.indigo.shade600,
                          onTap: () => onTabSelected(4),
                        ),
                      ),
                      FadeInSlide(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 310),
                        child: _FeatureCard(
                          title: 'AI Assistant',
                          subtitle: 'Ask Flowra anything',
                          icon: Icons.chat_bubble_outline_rounded,
                          color: Colors.pink.shade600,
                          onTap: () => onTabSelected(6),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 28),

            // ── Period Insight with Animated Ring ──────────────────────
            FadeInSlide(
              duration: const Duration(milliseconds: 420),
              delay: const Duration(milliseconds: 200),
              child: const Text(
                'Period Insight',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D3748),
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeInSlide(
              duration: const Duration(milliseconds: 420),
              delay: const Duration(milliseconds: 240),
              child: FutureBuilder(
                future: cycleService.fetchCyclesOnce(),
                builder: (context, snapshot) {
                  // Loading skeleton
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return CardContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const ShimmerBox(height: 18, width: 140),
                          const SizedBox(height: 16),
                          Row(
                            children: const [
                              Expanded(child: ShimmerBox(height: 50)),
                              SizedBox(width: 12),
                              Expanded(child: ShimmerBox(height: 50)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const ShimmerBox(height: 80),
                        ],
                      ),
                    );
                  }

                  // Empty state
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return CardContainer(
                      padding: EdgeInsets.zero,
                      child: EmptyStateWidget(
                        icon: Icons.calendar_today_rounded,
                        title: 'No Cycle Data Yet',
                        subtitle:
                            'Start tracking your period to see personalized insights and predictions here.',
                        buttonLabel: 'Track My Period',
                        onButtonTap: () => onTabSelected(1),
                      ),
                    );
                  }

                  final cycles = snapshot.data!;
                  final last = cycles.first;
                  final today = DateTime.now();
                  final cycleDay = today.difference(last.startDate).inDays + 1;
                  final cycleProgress =
                      (cycleDay / last.cycleLength).clamp(0.0, 1.0);
                  final nextPeriod = last.startDate
                      .add(Duration(days: last.cycleLength));
                  final daysUntil =
                      nextPeriod.difference(today).inDays;

                  return CardContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cycle Status',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        // Animated ring + stats row
                        Row(
                          children: [
                            // Animated progress ring
                            AnimatedProgressRing(
                              progress: cycleProgress,
                              size: isMobile ? 100 : 120,
                              strokeWidth: 10,
                              trackColor: Colors.pink.shade50,
                              progressColor: const Color(0xFFEA4C89),
                              duration:
                                  const Duration(milliseconds: 1000),
                              center: Column(
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
                                    '$cycleDay',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFEA4C89),
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  Text(
                                    'of ${last.cycleLength}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _StatRow(
                                    label: 'Last Period',
                                    value:
                                        '${last.startDate.month}/${last.startDate.day}/${last.startDate.year}',
                                    color: Colors.pink.shade600,
                                  ),
                                  const SizedBox(height: 12),
                                  _StatRow(
                                    label: 'Cycle Length',
                                    value: '${last.cycleLength} days',
                                    color: Colors.teal.shade600,
                                  ),
                                  const SizedBox(height: 12),
                                  _StatRow(
                                    label: 'Next Period',
                                    value: daysUntil > 0
                                        ? 'In $daysUntil days'
                                        : 'Today or soon',
                                    color: Colors.purple.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Small stat row
// ────────────────────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Quick action chip inside hero banner
// ────────────────────────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.3), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Feature card (hover-lift on desktop, full-width on mobile)
// ────────────────────────────────────────────────────────────────────────────
class _FeatureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -5.0 : 0.0, 0),
        width: isMobile ? double.infinity : 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.25)
                : widget.color.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: _isHovered ? 20 : 14,
              offset: Offset(0, _isHovered ? 8 : 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.13),
                        widget.color.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon,
                      color: widget.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade300, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
