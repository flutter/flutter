import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shift_entry.dart'; // adjust path
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ── Shift state ────────────────────────────────────────────────────────────
  bool _termsAccepted = false;
  bool _shiftActive = false;
  DateTime? _shiftStart;
  String _elapsedLabel = '00:00:00';
  Timer? _timer;
  Duration _totalToday = Duration.zero;

  // ── Filter ─────────────────────────────────────────────────────────────────
  final _dateCtrl = TextEditingController();
  List<ShiftGroup> _displayed = groupShifts(kDummyShifts);

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.6,
      upperBound: 1.0,
    )..repeat(reverse: true);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _calcTotalToday();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _calcTotalToday() {
    int minutes = 0;
    final today = kDummyShifts.where((s) => s.date == '06/04/2026').toList();
    for (final s in today) {
      final parts = s.totalHours.split(':');
      minutes += int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    _totalToday = Duration(minutes: minutes);
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _startShift() {
    if (!_termsAccepted) {
      AppToast.show(
        context,
        'Please accept terms & conditions first.',
        isError: true,
      );
      return;
    }
    setState(() {
      _shiftActive = true;
      _shiftStart = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedLabel = _fmtDuration(DateTime.now().difference(_shiftStart!));
      });
    });
    AppToast.show(
      context,
      'Shift started — location tracking active.',
      isSuccess: true,
    );
  }

  void _stopShift() {
    _timer?.cancel();
    final elapsed = DateTime.now().difference(_shiftStart!);
    setState(() {
      _shiftActive = false;
      _elapsedLabel = '00:00:00';
      _totalToday += elapsed;
    });
    AppToast.show(
      context,
      'Shift ended. Duration: ${_fmtDuration(elapsed)}',
      isSuccess: true,
    );
  }

  void _searchByDate() {
    final q = _dateCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _displayed = groupShifts(
        kDummyShifts.where((s) => s.date.contains(q)).toList(),
      );
    });
  }

  void _resetSearch() {
    _dateCtrl.clear();
    setState(() => _displayed = groupShifts(kDummyShifts));
  }

  Future<void> _handleLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _LogoutDialog(),
    );
    if (ok != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    AppToast.show(context, 'Signed out successfully.', isSuccess: true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = _resolveName(auth);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final totalLabel = _fmtDuration(_totalToday);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      drawer: _AppDrawer(
        name: name,
        email: auth.userEmail ?? '',
        role: auth.role ?? 'Staff',
        onLogout: _handleLogout,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _TopBar(
              initial: initial,
              name: name,
              totalLabel: totalLabel,
              termsAccepted: _termsAccepted,
              shiftActive: _shiftActive,
              elapsedLabel: _elapsedLabel,
              onTermsChanged: (v) =>
                  setState(() => _termsAccepted = v ?? false),
              onShiftStart: _startShift,
              onShiftStop: _stopShift,
              onMenuTap: () => Scaffold.of(context).openDrawer(),
              onAvatarTap: _handleLogout,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map card (visible only when shift active)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _shiftActive
                          ? _MapCard(
                              key: const ValueKey('map'),
                              pulseCtrl: _pulseCtrl,
                              elapsed: _elapsedLabel,
                            )
                          : const SizedBox.shrink(key: ValueKey('nomap')),
                    ),
                    if (_shiftActive) const SizedBox(height: 20),
                    _TimesheetSection(
                      dateCtrl: _dateCtrl,
                      displayed: _displayed,
                      onSearch: _searchByDate,
                      onReset: _resetSearch,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveName(AuthProvider auth) {
    if (auth.fullName != null && auth.fullName!.trim().isNotEmpty) {
      return auth.fullName!.trim();
    }
    if (auth.userName != null && auth.userName!.trim().isNotEmpty) {
      final n = auth.userName!.trim();
      return n.contains('@') ? n.split('@').first : n;
    }
    if (auth.userEmail != null && auth.userEmail!.isNotEmpty) {
      return auth.userEmail!.split('@').first;
    }
    return 'Staff';
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String initial, name, totalLabel, elapsedLabel;
  final bool termsAccepted, shiftActive;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onShiftStart, onShiftStop, onMenuTap, onAvatarTap;

  const _TopBar({
    required this.initial,
    required this.name,
    required this.totalLabel,
    required this.termsAccepted,
    required this.shiftActive,
    required this.elapsedLabel,
    required this.onTermsChanged,
    required this.onShiftStart,
    required this.onShiftStop,
    required this.onMenuTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 10,
        left: 12,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hamburger
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: AppTheme.primary,
                size: 26,
              ),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 4),

          // Terms + shift buttons
          Expanded(
            child: _ShiftControl(
              termsAccepted: termsAccepted,
              shiftActive: shiftActive,
              elapsedLabel: elapsedLabel,
              onTermsChanged: onTermsChanged,
              onShiftStart: onShiftStart,
              onShiftStop: onShiftStop,
            ),
          ),
          const SizedBox(width: 12),

          // Total hours
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total Shift Hours',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                totalLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Avatar
          GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shift Control (Terms + Start/Stop) ────────────────────────────────────────

class _ShiftControl extends StatelessWidget {
  final bool termsAccepted, shiftActive;
  final String elapsedLabel;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onShiftStart, onShiftStop;

  const _ShiftControl({
    required this.termsAccepted,
    required this.shiftActive,
    required this.elapsedLabel,
    required this.onTermsChanged,
    required this.onShiftStart,
    required this.onShiftStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Terms checkbox
          if (!shiftActive) ...[
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: termsAccepted,
                onChanged: onTermsChanged,
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showTermsDialog(context),
              child: const Text(
                'Accept terms\n& conditions',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.primary,
                  decoration: TextDecoration.underline,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Elapsed (when active)
          if (shiftActive) ...[
            const Icon(Icons.timer_rounded, color: AppTheme.success, size: 16),
            const SizedBox(width: 4),
            Text(
              elapsedLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Shift Start
          _ShiftBtn(
            label: 'Shift Start',
            active: !shiftActive,
            onTap: onShiftStart,
            activeColor: AppTheme.success,
          ),
          const SizedBox(width: 6),

          // Shift Stop
          _ShiftBtn(
            label: 'Shift Stop',
            active: shiftActive,
            onTap: onShiftStop,
            activeColor: AppTheme.error,
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'By starting your shift you agree to:\n\n'
            '• Your location will be tracked during the shift duration.\n'
            '• Shift start and end times are recorded accurately.\n'
            '• You are responsible for accurate timekeeping.\n'
            '• Location data is used solely for attendance purposes.\n'
            '• Data is stored securely per company privacy policy.\n\n'
            'AP Cabinet Staff Management — © 2026',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ShiftBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;

  const _ShiftBtn({
    required this.label,
    required this.active,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? activeColor : AppTheme.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Map Card ──────────────────────────────────────────────────────────────────

class _MapCard extends StatelessWidget {
  final AnimationController pulseCtrl;
  final String elapsed;

  const _MapCard({super.key, required this.pulseCtrl, required this.elapsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Location Tracking',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Ahmedabad, Gujarat, IN',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: pulseCtrl,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Simulated map
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  // Map grid background
                  CustomPaint(
                    size: const Size(double.infinity, 220),
                    painter: _MapGridPainter(),
                  ),
                  // Location pin + ripple
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple rings
                        ScaleTransition(
                          scale: pulseCtrl,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withOpacity(0.15),
                          ),
                        ),
                        // Pin
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 12,
                              color: AppTheme.primary,
                            ),
                            Container(
                              width: 10,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Coordinates overlay
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        '23.0225° N, 72.5714° E',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Elapsed overlay
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        elapsed,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a stylised map grid
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = const Color(0xFFE8EDF2);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Road-like horizontal/vertical grid
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final thinRoad = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Thick roads
    canvas.drawLine(
      Offset(0, size.height * 0.45),
      Offset(size.width, size.height * 0.45),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.4, size.height),
      roadPaint,
    );

    // Thin roads
    for (double y = 0.2; y < 1.0; y += 0.2) {
      if ((y - 0.45).abs() > 0.02) {
        canvas.drawLine(
          Offset(0, size.height * y),
          Offset(size.width, size.height * y),
          thinRoad,
        );
      }
    }
    for (double x = 0.2; x < 1.0; x += 0.2) {
      if ((x - 0.40).abs() > 0.02) {
        canvas.drawLine(
          Offset(size.width * x, 0),
          Offset(size.width * x, size.height),
          thinRoad,
        );
      }
    }

    // Some "blocks" (light green = park)
    final parkPaint = Paint()..color = const Color(0xFFD4EDDA);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.55,
        size.height * 0.1,
        size.width * 0.18,
        size.height * 0.28,
      ),
      parkPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.55,
        size.width * 0.28,
        size.height * 0.3,
      ),
      parkPaint,
    );

    // Building blocks
    final buildPaint = Paint()..color = const Color(0xFFD5DCE5);
    for (int i = 0; i < 6; i++) {
      final rng = math.Random(i * 37);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rng.nextDouble() * size.width * 0.7,
            rng.nextDouble() * size.height * 0.6 + size.height * 0.05,
            20 + rng.nextDouble() * 30,
            15 + rng.nextDouble() * 25,
          ),
          const Radius.circular(2),
        ),
        buildPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Timesheet Section ─────────────────────────────────────────────────────────

class _TimesheetSection extends StatelessWidget {
  final TextEditingController dateCtrl;
  final List<ShiftGroup> displayed;
  final VoidCallback onSearch, onReset;

  const _TimesheetSection({
    required this.dateCtrl,
    required this.displayed,
    required this.onSearch,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Shift Timesheet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: dateCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search by date (DD/MM/YYYY)',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (_) => onSearch(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _FilterBtn(label: 'Search', filled: true, onTap: onSearch),
                const SizedBox(width: 8),
                _FilterBtn(label: 'Reset', filled: false, onTap: onReset),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF0F1),
              border: Border.symmetric(
                horizontal: BorderSide(color: AppTheme.border),
              ),
            ),
            child: const Row(
              children: [
                _ColHead(label: 'Date', flex: 2),
                _ColHead(label: 'Start Time', flex: 2),
                _ColHead(label: 'End Time', flex: 2),
                _ColHead(label: 'Total Hours', flex: 1, center: true),
              ],
            ),
          ),

          // Rows
          if (displayed.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No records found.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),
            )
          else
            ...displayed.expand((g) => _buildGroup(context, g)).toList(),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Text(
              'Copyright © 2026 AP Cabinet. All rights reserved.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroup(BuildContext ctx, ShiftGroup group) {
    final rows = <Widget>[];
    for (int i = 0; i < group.entries.length; i++) {
      final e = group.entries[i];
      final isFirst = i == 0;
      rows.add(
        _ShiftRow(
          date: isFirst ? group.date : '',
          entry: e,
          isAlternate: i.isOdd,
          isLastInGroup: i == group.entries.length - 1,
        ),
      );
    }
    return rows;
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _FilterBtn({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: filled ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled ? AppTheme.primary : AppTheme.primary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : AppTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ColHead extends StatelessWidget {
  final String label;
  final int flex;
  final bool center;
  const _ColHead({required this.label, this.flex = 1, this.center = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppTheme.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ShiftRow extends StatelessWidget {
  final String date;
  final ShiftEntry entry;
  final bool isAlternate;
  final bool isLastInGroup;

  const _ShiftRow({
    required this.date,
    required this.entry,
    required this.isAlternate,
    required this.isLastInGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isAlternate ? const Color(0xFFFCFCFC) : Colors.white,
        border: isLastInGroup
            ? const Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(flex: 2, child: _TimeCell(time: entry.startTime)),
          Expanded(flex: 2, child: _TimeCell(time: entry.endTime)),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.totalHours,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  final String time;
  const _TimeCell({required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          time,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.location_on_rounded,
          color: AppTheme.primary,
          size: 14,
        ),
      ],
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final String name, email, role;
  final VoidCallback onLogout;

  const _AppDrawer({
    required this.name,
    required this.email,
    required this.role,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Dashboard',
                  selected: true,
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.access_time_rounded,
                  label: 'Shift Timesheet',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.location_history_rounded,
                  label: 'Location History',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.person_rounded,
                  label: 'My Profile',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(indent: 20, endIndent: 20, height: 24),
                _DrawerItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'AP Cabinet Staff v1.0.0',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected, isDestructive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppTheme.error
        : selected
        ? AppTheme.primary
        : AppTheme.textSecondary;

    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      tileColor: selected ? AppTheme.primary.withOpacity(0.06) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }
}

// ── Logout Dialog ─────────────────────────────────────────────────────────────

class _LogoutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppTheme.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sign Out?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You will be returned to the login screen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: const BorderSide(color: AppTheme.border),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
