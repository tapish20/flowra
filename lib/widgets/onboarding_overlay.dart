import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CoachMark — wraps a child with a GlobalKey and optional tooltip that fires
// once (persisted via SharedPreferences).
// ─────────────────────────────────────────────────────────────────────────────

/// Data describing a single coach-mark step.
class CoachMarkData {
  final GlobalKey targetKey;
  final String title;
  final String body;
  final String prefKey; // unique key stored in SharedPreferences

  const CoachMarkData({
    required this.targetKey,
    required this.title,
    required this.body,
    required this.prefKey,
  });
}

/// Call this after the first frame to display a sequence of coach marks.
/// Each one is skipped if it has already been shown (checked via prefs).
Future<void> showCoachMarksIfNeeded(
  BuildContext context,
  List<CoachMarkData> marks,
) async {
  final prefs = await SharedPreferences.getInstance();

  for (final mark in marks) {
    if (!context.mounted) return;
    final alreadySeen = prefs.getBool(mark.prefKey) ?? false;
    if (alreadySeen) continue;

    // Check if target widget is still in the tree
    final keyContext = mark.targetKey.currentContext;
    if (keyContext == null) continue;

    final renderBox = keyContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) continue;

    final overlay = Overlay.of(context);
    final targetOffset = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    final completer = ValueNotifier<bool>(false);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CoachMarkOverlay(
        targetRect: targetOffset & targetSize,
        title: mark.title,
        body: mark.body,
        onDismiss: () {
          entry.remove();
          completer.value = true;
        },
      ),
    );

    overlay.insert(entry);
    await prefs.setBool(mark.prefKey, true);

    // Wait until dismissed
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return !completer.value;
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CoachMarkOverlay — the actual full-screen spotlight + tooltip
// ─────────────────────────────────────────────────────────────────────────────
class _CoachMarkOverlay extends StatefulWidget {
  final Rect targetRect;
  final String title;
  final String body;
  final VoidCallback onDismiss;

  const _CoachMarkOverlay({
    required this.targetRect,
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final target = widget.targetRect;
    final padding = 12.0;
    final spotlightRect = Rect.fromLTWH(
      target.left - padding,
      target.top - padding,
      target.width + padding * 2,
      target.height + padding * 2,
    );

    // Determine tooltip position (below or above target)
    final showBelow = target.bottom + 160 < screen.height;
    final tooltipTop = showBelow ? target.bottom + padding + 10 : target.top - 160;

    return FadeTransition(
      opacity: _fade,
      child: Stack(
        children: [
          // Dark overlay with spotlight cutout
          GestureDetector(
            onTap: widget.onDismiss,
            child: CustomPaint(
              painter: _SpotlightPainter(spotlightRect),
              size: screen,
            ),
          ),
          // Tooltip card
          Positioned(
            left: 20,
            right: 20,
            top: tooltipTop,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEA4C89), Color(0xFF6C5CE7)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tips_and_updates, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: widget.onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA4C89),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Got it!', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpotlightPainter — draws a dark scrim with a rounded-rect cutout
// ─────────────────────────────────────────────────────────────────────────────
class _SpotlightPainter extends CustomPainter {
  final Rect spotlight;

  _SpotlightPainter(this.spotlight);

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(spotlight, const Radius.circular(16));

    final path = Path()
      ..addRect(full)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, scrim);

    // Highlight border around spotlight
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFEA4C89).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.spotlight != spotlight;
}
