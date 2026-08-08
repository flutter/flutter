import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import '../models/client_profile.dart';
import '../models/rest_day.dart';
// import '../widgets/training_calendar.dart';
import '../utils/storage_helper.dart';
import '../utils/step_count_service.dart';
import 'package:personal_training_app/screens/_notification_reply_input.dart';
import 'package:intl/intl.dart';
import 'active_workout_screen.dart';
import '../utils/firebase_service.dart';
import 'package:workfire/workfire.dart';
import '../widgets/training_calendar.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';

class HomeScreen extends StatefulWidget {
  final List<Workout> workouts;
  final ClientProfile? clientProfile;
  final Function(Workout)? onWorkoutUpdated;

  const HomeScreen({
    super.key,
    required this.workouts,
    this.clientProfile,
    this.onWorkoutUpdated,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<RestDay> _restDays = [];
  List<ClientNotification> _notifications = [];
  bool _showFireworks = false;
  final List<Offset> _fireworkPositions = [];
  late ConfettiController _confettiController;
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;

  // Step count state
  int? _todaySteps;
  Map<String, int> _weekSteps = {};
  bool _stepSyncing = false;
  bool _stepPermissionGranted = false;
  int _stepGoal = 10000;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _confettiControllerLeft = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _confettiControllerRight = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _fetchNotifications();
    _fetchRestDays();
    _loadStepData();
    // Show message pop-up after build if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUnacknowledgedMessagePopup();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    super.dispose();
  }

  Future<void> _loadStepData() async {
    if (widget.clientProfile == null) return;
    final username = widget.clientProfile!.username;
    // Load goal and stored steps from Firebase
    final results = await Future.wait([
      FirebaseService.getStepCounts(username, days: 7),
      FirebaseService.getClientStepGoal(username),
    ]);
    final stored = results[0] as Map<String, int>;
    final goal = results[1] as int?;
    if (mounted) {
      setState(() {
        _weekSteps = stored;
        final todayKey = StepCountService.todayKey();
        _todaySteps = stored[todayKey];
        if (goal != null) _stepGoal = goal;
      });
    }
    // Check health permissions passively (don't prompt on load)
    if (!kIsWeb) {
      final hasPerm = await StepCountService.hasPermissions();
      if (mounted) setState(() => _stepPermissionGranted = hasPerm);
    }
  }

  Future<void> _syncStepsFromWatch() async {
    if (widget.clientProfile == null) return;
    setState(() => _stepSyncing = true);
    try {
      // Request permissions if needed
      if (!_stepPermissionGranted) {
        final granted = await StepCountService.requestPermissions();
        if (mounted) setState(() => _stepPermissionGranted = granted);
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Health permission denied. Please grant it in device Settings.',
                ),
              ),
            );
          }
          return;
        }
      }
      final steps = await StepCountService.syncTodayStepsToFirebase(
        widget.clientProfile!.username,
      );
      if (mounted) {
        setState(() {
          _todaySteps = steps;
          if (steps != null) {
            _weekSteps[StepCountService.todayKey()] = steps;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              steps != null
                  ? 'Steps synced: ${_formatSteps(steps)} steps today'
                  : 'Could not read steps from watch. Make sure your watch is connected.',
            ),
            backgroundColor: steps != null
                ? const Color(0xFF059669)
                : Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _stepSyncing = false);
    }
  }

  Future<void> _enterStepsManually() async {
    if (widget.clientProfile == null) return;
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Step Count'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Steps today',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 0) Navigator.of(ctx).pop(val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await FirebaseService.saveStepCount(
        widget.clientProfile!.username,
        DateTime.now(),
        result,
      );
      if (mounted) {
        setState(() {
          _todaySteps = result;
          _weekSteps[StepCountService.todayKey()] = result;
        });
      }
    }
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }

  Widget _buildStepCountCard(BuildContext context) {
    final goal = _stepGoal;
    final steps = _todaySteps ?? 0;
    final progress = (steps / goal).clamp(0.0, 1.0);
    final isGoalMet = steps >= goal;

    // 7-day average
    int weekAvg = 0;
    if (_weekSteps.isNotEmpty) {
      weekAvg = (_weekSteps.values.fold(0, (a, b) => a + b) / _weekSteps.length)
          .round();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGoalMet
              ? [const Color(0xFF059669), const Color(0xFF10B981)]
              : [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                (isGoalMet ? const Color(0xFF059669) : const Color(0xFF2563EB))
                    .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.watch, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Daily Steps',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (isGoalMet)
                const Icon(Icons.emoji_events, color: Colors.yellow, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _todaySteps != null ? _formatSteps(steps) : '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  '/ ${_formatSteps(goal)} goal',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              color: Colors.white,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% of daily goal',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (_weekSteps.length > 1)
                Text(
                  '7-day avg: ${_formatSteps(weekAvg)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (!kIsWeb)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _stepSyncing ? null : _syncStepsFromWatch,
                    icon: _stepSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync, size: 16, color: Colors.white),
                    label: Text(
                      _stepSyncing ? 'Syncing...' : 'Sync from Watch',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              if (!kIsWeb) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _enterStepsManually,
                  icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                  label: const Text(
                    'Enter Manually',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUnacknowledgedMessagePopup() {
    final unacknowledgedMessages = _notifications
        .where((n) => n.type == 'message' && !n.acknowledged)
        .toList();
    if (unacknowledgedMessages.isNotEmpty) {
      final message = unacknowledgedMessages.first;
      bool confettiTriggered = false;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) => Stack(
            children: [
              // Left corner confetti cannon
              Positioned(
                top: 0,
                left: 0,
                child: IgnorePointer(
                  child: ConfettiWidget(
                    confettiController: _confettiControllerLeft,
                    blastDirection: pi / 5,
                    blastDirectionality: BlastDirectionality.directional,
                    numberOfParticles: 30,
                    emissionFrequency: 0.4,
                    maxBlastForce: 55,
                    minBlastForce: 25,
                    gravity: 0.08,
                    shouldLoop: false,
                    colors: const [
                      Color(0xFFFFD700),
                      Color(0xFF7C3AED),
                      Color(0xFF2563EB),
                      Color(0xFF16A34A),
                      Color(0xFFFF6B6B),
                      Color(0xFF00D4FF),
                    ],
                  ),
                ),
              ),
              // Right corner confetti cannon
              Positioned(
                top: 0,
                right: 0,
                child: IgnorePointer(
                  child: ConfettiWidget(
                    confettiController: _confettiControllerRight,
                    blastDirection: 4 * pi / 5,
                    blastDirectionality: BlastDirectionality.directional,
                    numberOfParticles: 30,
                    emissionFrequency: 0.4,
                    maxBlastForce: 55,
                    minBlastForce: 25,
                    gravity: 0.08,
                    shouldLoop: false,
                    colors: const [
                      Color(0xFFFFD700),
                      Color(0xFF7C3AED),
                      Color(0xFF2563EB),
                      Color(0xFF16A34A),
                      Color(0xFFFF6B6B),
                      Color(0xFF00D4FF),
                    ],
                  ),
                ),
              ),
              // Center explosive confetti burst
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: IgnorePointer(
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      numberOfParticles: 50,
                      emissionFrequency: 0.6,
                      maxBlastForce: 40,
                      minBlastForce: 15,
                      gravity: 0.08,
                      shouldLoop: false,
                      colors: const [
                        Color(0xFFFFD700),
                        Color(0xFF7C3AED),
                        Color(0xFF2563EB),
                        Color(0xFF16A34A),
                        Color(0xFFFF6B6B),
                        Color(0xFF00D4FF),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom center upward confetti
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: IgnorePointer(
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: -pi / 2,
                      blastDirectionality: BlastDirectionality.directional,
                      numberOfParticles: 35,
                      emissionFrequency: 0.5,
                      maxBlastForce: 60,
                      minBlastForce: 30,
                      gravity: 0.08,
                      shouldLoop: false,
                      colors: const [
                        Color(0xFFFFD700),
                        Color(0xFF7C3AED),
                        Color(0xFF2563EB),
                        Color(0xFF16A34A),
                        Color(0xFFFF6B6B),
                        Color(0xFF00D4FF),
                      ],
                    ),
                  ),
                ),
              ),
              // Mid-left horizontal confetti
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IgnorePointer(
                    child: ConfettiWidget(
                      confettiController: _confettiControllerLeft,
                      blastDirection: 0,
                      blastDirectionality: BlastDirectionality.directional,
                      numberOfParticles: 24,
                      emissionFrequency: 0.45,
                      maxBlastForce: 45,
                      minBlastForce: 20,
                      gravity: 0.1,
                      shouldLoop: false,
                      colors: const [
                        Color(0xFFFFD700),
                        Color(0xFF7C3AED),
                        Color(0xFF2563EB),
                        Color(0xFF16A34A),
                        Color(0xFFFF6B6B),
                        Color(0xFF00D4FF),
                      ],
                    ),
                  ),
                ),
              ),
              // Mid-right horizontal confetti
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IgnorePointer(
                    child: ConfettiWidget(
                      confettiController: _confettiControllerRight,
                      blastDirection: pi,
                      blastDirectionality: BlastDirectionality.directional,
                      numberOfParticles: 24,
                      emissionFrequency: 0.45,
                      maxBlastForce: 45,
                      minBlastForce: 20,
                      gravity: 0.1,
                      shouldLoop: false,
                      colors: const [
                        Color(0xFFFFD700),
                        Color(0xFF7C3AED),
                        Color(0xFF2563EB),
                        Color(0xFF16A34A),
                        Color(0xFFFF6B6B),
                        Color(0xFF00D4FF),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: AlertDialog(
                  title: Text('New Message'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.message),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            if (message.celebration == true &&
                                !confettiTriggered) {
                              setStateDialog(() {
                                confettiTriggered = true;
                              });
                              _confettiController.play();
                              _confettiControllerLeft.play();
                              _confettiControllerRight.play();
                              await Future.delayed(const Duration(seconds: 5));
                            }
                            _acknowledgeNotification(message.id);
                            Navigator.of(context).pop();
                            _showUnacknowledgedMessagePopup();
                          },
                          child: const Text('Acknowledge'),
                        ),
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
  }

  Future<void> _fetchRestDays() async {
    final restDayMaps = await FirebaseService.getAllRestDays();
    setState(() {
      _restDays = restDayMaps
          .map(
            (e) => RestDay(
              id: e['id'],
              date: DateTime.parse(e['date']),
              clientName: e['clientName'],
              notes: e['notes'],
            ),
          )
          .where(
            (rd) =>
                widget.clientProfile == null ||
                rd.clientName == widget.clientProfile!.username,
          )
          .toList();
    });
  }

  // Removed duplicate dispose()

  Future<void> _fetchNotifications() async {
    if (widget.clientProfile != null) {
      final notifications = await FirebaseService.fetchClientNotifications(
        widget.clientProfile!.username,
      );
      setState(() {
        _notifications = notifications;
      });
      // Show message pop-up if needed after notifications are fetched
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUnacknowledgedMessagePopup();
      });
      // Auto-trigger confetti for first unacknowledged celebration notification
      final confettiNotification = notifications.firstWhere(
        (n) => n.celebration == true && !n.acknowledged,
        orElse: () => ClientNotification(
          id: '',
          title: '',
          message: '',
          date: DateTime.now(),
          acknowledged: true,
          type: '',
          celebration: false,
        ),
      );
      if (confettiNotification.id.isNotEmpty && !_showFireworks) {
        setState(() {
          _showFireworks = true;
        });
        Future.delayed(const Duration(seconds: 5), () async {
          setState(() {
            _showFireworks = false;
          });
          if (widget.clientProfile != null) {
            await FirebaseService.acknowledgeNotification(
              widget.clientProfile!.username,
              confettiNotification.id,
            );
            await _fetchNotifications();
          }
        });
      }
    }
  }

  void _acknowledgeNotification(String notificationId) async {
    if (widget.clientProfile != null) {
      await FirebaseService.acknowledgeNotification(
        widget.clientProfile!.username,
        notificationId,
      );
      await _fetchNotifications();
    }
  }

  // Special Instructor Notifications with Confetti
  List<Widget> _buildSpecialNotifications(BuildContext context) {
    final specialNotifications = _notifications
        .where((n) => n.celebration == true && !n.acknowledged)
        .toList();
    if (specialNotifications.isEmpty) return [];
    return [
      if (_showFireworks)
        ..._fireworkPositions.map(
          (pos) => Positioned(
            left: pos.dx,
            top: pos.dy,
            child: IgnorePointer(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Firework(
                  particleColors: const [
                    Color(0xFFFFD700),
                    Color(0xFF7C3AED),
                    Color(0xFF2563EB),
                    Color(0xFF16A34A),
                  ],
                  onComplete: () {},
                ),
              ),
            ),
          ),
        ),
      ...specialNotifications.map(
        (n) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.2),
                const Color(0xFF7C3AED).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.celebration,
                    color: Color(0xFFFFD700),
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Special Notification!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (n.mediaUrl != null && n.mediaUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Image.network(
                    n.mediaUrl!,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Icon(Icons.broken_image),
                  ),
                ),
              Text(
                n.message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 10),
              // Reactions row
              Row(
                children: [
                  ...['🎉', '👍', '💪', '🔥', '👏'].map(
                    (emoji) => IconButton(
                      icon: Text(emoji, style: TextStyle(fontSize: 20)),
                      onPressed: () async {
                        if (widget.clientProfile != null) {
                          await FirebaseService.addNotificationReaction(
                            clientId: widget.clientProfile!.username,
                            notificationId: n.id,
                            emoji: emoji,
                          );
                          await _fetchNotifications();
                        }
                      },
                    ),
                  ),
                  if (n.reactions != null && n.reactions!.isNotEmpty)
                    ...n.reactions!.map(
                      (r) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(r, style: TextStyle(fontSize: 18)),
                      ),
                    ),
                ],
              ),
              // Reply input
              NotificationReplyInput(
                notificationId: n.id,
                onReply: (replyText) async {
                  if (widget.clientProfile != null &&
                      replyText.trim().isNotEmpty) {
                    print(
                      'Sending reply: clientId = \\${widget.clientProfile!.username}, notificationId = \\${n.id}, user = \\${widget.clientProfile!.name}, message = \\${replyText.trim()}',
                    );
                    await FirebaseService.addNotificationReply(
                      clientId: widget.clientProfile!.username,
                      notificationId: n.id,
                      user: widget.clientProfile!.name,
                      message: replyText.trim(),
                    );
                    await _fetchNotifications();
                  }
                },
              ),
              // Show replies
              if (n.replies != null && n.replies!.isNotEmpty)
                ...n.replies!.map(
                  (reply) => Padding(
                    padding: const EdgeInsets.only(top: 6, left: 8),
                    child: Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 4),
                        Text(
                          '${reply.user}: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(reply.message)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  // Instructor Feedback Notifications
  List<Widget> _buildFeedbackNotifications(
    BuildContext context,
    List<Workout> workouts,
  ) {
    final reviewedWorkouts =
        workouts
            .where(
              (w) =>
                  w.isReviewedByInstructor &&
                  w.instructorReview != null &&
                  w.instructorReview!.isNotEmpty &&
                  !w.isReviewAcknowledged,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    if (reviewedWorkouts.isEmpty) {
      return [];
    }

    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7C3AED).withValues(alpha: 0.1),
              const Color(0xFF2563EB).withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7C3AED), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.rate_review,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructor Reviews',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                      ),
                      Text(
                        '${reviewedWorkouts.length} workout${reviewedWorkouts.length > 1 ? 's' : ''} awaiting acknowledgement',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...reviewedWorkouts
                .take(3)
                .map(
                  (workout) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                workout.name,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF7C3AED),
                                    ),
                              ),
                            ),
                            Text(
                              DateFormat('MMM d').format(workout.date),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            workout.instructorReview!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF374151),
                                  height: 1.4,
                                ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () {
                              // Mark as acknowledged in backend and refresh
                              _acknowledgeNotification(workout.id);
                              if (widget.onWorkoutUpdated != null) {
                                final updatedWorkout = workout.copyWith(
                                  isReviewAcknowledged: true,
                                  isCompleted: true,
                                );
                                widget.onWorkoutUpdated!(updatedWorkout);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Review accepted and saved to history',
                                  ),
                                  backgroundColor: Color(0xFF059669),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Acknowledge'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayWorkouts = widget.workouts
        .where(
          (w) =>
              w.date.year == today.year &&
              w.date.month == today.month &&
              w.date.day == today.day &&
              !w.isCompleted,
        )
        .toList();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              if (widget.clientProfile != null &&
                  widget.clientProfile!.name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Welcome back ${widget.clientProfile!.name.split(' ')[0]}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              // Logo above the calendar
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Image.asset('assets/logo.png', height: 80),
                ),
              ),
              // Step count card
              if (widget.clientProfile != null) _buildStepCountCard(context),

              // Workouts completed summary
              Text(
                'You have completed ${widget.workouts.where((w) => w.isCompleted).length} workouts',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 28),

              // Special Instructor Notifications with Confetti
              ..._buildSpecialNotifications(context),

              // Instructor Feedback Notifications
              ..._buildFeedbackNotifications(context, widget.workouts),

              // Today's Workout Section
              if (todayWorkouts.isNotEmpty) ...[
                // ...existing code for today's workout section...
                FilledButton(
                  onPressed: () async {
                    if (todayWorkouts.isNotEmpty) {
                      final updatedWorkout = await Navigator.push<Workout>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActiveWorkoutScreen(
                            workout: todayWorkouts[0],
                            clientProfile: widget.clientProfile,
                            onPRsUpdated: (newPRs) async {
                              if (widget.clientProfile == null) return;
                              // Merge new PRs into the existing profile and persist
                              final merged = Map<String, double>.from(
                                widget.clientProfile!.strengthPRs,
                              )..addAll(newPRs);
                              final updatedProfile = widget.clientProfile!
                                  .copyWith(strengthPRs: merged);
                              await FirebaseService.saveClientProfile(
                                updatedProfile.username,
                                updatedProfile.toMap(),
                              );
                            },
                          ),
                        ),
                      );
                      // If workout was completed and updated, notify parent
                      if (updatedWorkout != null &&
                          widget.onWorkoutUpdated != null) {
                        widget.onWorkoutUpdated!(updatedWorkout);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No workout scheduled for today!'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Start Workout',
                    style: TextStyle(
                      color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // Training Calendar - Show all workouts (scheduled and completed) and rest days
              TrainingCalendar(
                workouts: widget.workouts,
                restDays: _restDays.map((r) => r.date).toList(),
                isInstructor:
                    (widget.clientProfile?.username == null ||
                        widget.clientProfile!.username.isEmpty)
                    ? false
                    : StorageHelper.getString('user_role') == 'instructor',
                clientUsername: widget.clientProfile?.username,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}
