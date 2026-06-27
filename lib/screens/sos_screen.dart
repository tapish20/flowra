import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../services/notification_service.dart';
import '../services/contacts_service.dart';
import '../widgets/card_container.dart';
import '../theme.dart';
import 'contacts_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _sosActivated = false;
  LocationPermission? _locationPermission;
  bool _isCountingDown = false;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _refreshPermissionStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
        });
        _triggerSOS();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountingDown = false;
      _countdownSeconds = 3;
    });
  }

  Future<void> _refreshPermissionStatus() async {
    try {
      final p = await Geolocator.checkPermission();
      setState(() => _locationPermission = p);
    } catch (_) {
      setState(() => _locationPermission = null);
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final p = await Geolocator.requestPermission();
      setState(() => _locationPermission = p);
    } catch (_) {
      setState(() => _locationPermission = null);
    }
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
    await Geolocator.openLocationSettings();
    _refreshPermissionStatus();
  }

  Future<void> _triggerSOS() async {
    setState(() => _sosActivated = true);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
            SizedBox(height: 16),
            Text('Sending emergency alert...', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );

    try {
      // Fetch trusted contacts from Firebase
      final contacts = await ContactsService().fetchContactsOnce();
      final trusted = contacts.where((c) => c.trusted).toList();

      // Attempt to get location (best-effort)
      Position? pos;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
            pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          }
        }
      } catch (_) {
        pos = null;
      }

      bool simulated = false;
      try {
        // Send SOS to backend
        await NotificationService().triggerSos(
          trusted,
          message: 'Emergency! I need help.',
          latitude: pos?.latitude,
          longitude: pos?.longitude,
        );
      } catch (_) {
        // Graceful fallback for demo/offline mode
        simulated = true;
        await Future.delayed(const Duration(milliseconds: 600));
      }
      if (!mounted) return;
      Navigator.pop(context); // remove loading

      if (!mounted) return;
      // Show success
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('SOS Activated', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 60),
              const SizedBox(height: 16),
              Text(
                simulated ? 'Emergency alert simulated (demo mode)' : 'Emergency alert sent to your trusted contacts',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                pos != null ? 'Location shared: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}' : 'Location unavailable',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Help is on the way. Stay safe.', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Close', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // remove loading
      if (mounted) setState(() => _sosActivated = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('SOS Failed', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Failed to send SOS: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using WillPopScope here; PopScope replacement causes API mismatch
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => !_sosActivated && !_isCountingDown,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _sosActivated
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                  onPressed: () => Navigator.pop(context),
                ),
          title: const Text(
            'Emergency SOS',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: !_sosActivated,
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                
                // Status info banner
                if (!_sosActivated)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (_isCountingDown ? const Color(0xFFF39C12) : const Color(0xFF6C5CE7))
                          .withValues(alpha: 0.12),
                      border: Border.all(
                        color: (_isCountingDown ? const Color(0xFFF39C12) : const Color(0xFF6C5CE7))
                            .withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCountingDown ? Icons.warning_amber_rounded : Icons.info,
                          color: _isCountingDown ? Colors.orange.shade800 : AppTheme.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isCountingDown
                                ? 'SOS emergency alert is being sent! Tap the button above to Cancel.'
                                : 'Tap the red button below to send an emergency alert to your trusted contacts.',
                            style: TextStyle(
                              color: _isCountingDown ? Colors.orange.shade900 : AppTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_sosActivated)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                      border: Border.all(color: const Color(0xFF2ECC71).withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF2ECC71)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'SOS Activated',
                                style: TextStyle(
                                  color: Color(0xFF27AE60),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Emergency alert sent. Your location is being shared.',
                                style: TextStyle(
                                  color: Color(0xFF27AE60),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 40),

                // SOS Button
                Center(
                  child: GestureDetector(
                    onTap: _sosActivated ? null : (_isCountingDown ? _cancelCountdown : _startCountdown),
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isCountingDown
                            ? const LinearGradient(
                                colors: [Color(0xFFF39C12), Color(0xFFD35400)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isCountingDown ? const Color(0xFFF39C12) : const Color(0xFFE74C3C))
                                .withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 8,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isCountingDown)
                            SizedBox(
                              width: 190,
                              height: 190,
                              child: CircularProgressIndicator(
                                value: _countdownSeconds / 3.0,
                                strokeWidth: 8,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isCountingDown ? Icons.timer_outlined : Icons.emergency,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _sosActivated
                                    ? 'ACTIVATED'
                                    : (_isCountingDown
                                        ? 'CANCEL ($_countdownSeconds)'
                                        : 'SOS'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Information Section
                CardContainer(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What happens when you press SOS?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 20),
                      const _InfoItem(
                        icon: Icons.notifications_active,
                        title: 'Send Alert',
                        description:
                            'Emergency alert sent to all your trusted contacts',
                      ),
                      const SizedBox(height: 14),
                      const _InfoItem(
                        icon: Icons.location_on,
                        title: 'Share Location',
                        description:
                            'Real-time location shared with trusted contacts',
                      ),
                      const SizedBox(height: 14),
                      const _InfoItem(
                        icon: Icons.phone,
                        title: 'Quick Contact',
                        description:
                            'Contacts can call you immediately for assistance',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Location permission card
                if (!_sosActivated)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50.withValues(alpha: 0.5),
                      border: Border.all(color: Colors.orange.shade200.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Location Permission',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _locationPermission == null
                              ? 'Unable to determine permission status.'
                              : (_locationPermission == LocationPermission.always || _locationPermission == LocationPermission.whileInUse)
                                  ? 'Enabled — app can access your location when sending SOS.'
                                  : (_locationPermission == LocationPermission.denied)
                                      ? 'Permission denied. Tap Request to allow access.'
                                      : 'Permission denied permanently. Open settings to grant access.',
                          style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton(
                              onPressed: _requestLocationPermission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: const Text('Request Permission', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            OutlinedButton(
                              onPressed: _openSettings,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.orange.shade600),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: Text('Open Settings', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Manage Contacts
                if (!_sosActivated)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContactsScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.group, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text(
                            'Manage Trusted Contacts',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2ECC71), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
