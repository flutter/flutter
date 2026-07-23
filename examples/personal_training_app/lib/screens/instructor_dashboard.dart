import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'manage_exercise_library_screen.dart';
import 'manage_stretching_library_screen.dart';
import 'instructor_dashboard_tabs.dart' show NotificationTab;
import 'add_workout_screen.dart';
import 'clients_tab.dart';
import 'client_profile_screen.dart';
import 'instructor_bio_edit_tab.dart';
import 'workout_of_week_screen.dart';
import '../widgets/instructor_calendar.dart';
import '../models/workout.dart';
import '../models/rest_day.dart';
import '../models/client_profile.dart';
import '../utils/firebase_service.dart';
import '../utils/security_helper.dart';
import 'package:intl/intl.dart';

class _RestDayScheduler extends StatefulWidget {
  final List<ClientProfile> clients;
  final Function(RestDay) onRestDayAdded;
  const _RestDayScheduler({
    required this.clients,
    required this.onRestDayAdded,
  });

  @override
  State<_RestDayScheduler> createState() => _RestDaySchedulerState();
}

class _RestDaySchedulerState extends State<_RestDayScheduler> {
  ClientProfile? _selectedClient;
  DateTime? _selectedDate;
  final TextEditingController _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (_selectedClient == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client and date.')),
      );
      return;
    }
    setState(() {
      _saving = true;
    });
    final restDay = RestDay(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate!,
      clientName: _selectedClient!.username,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    // Save to Firebase using correct structure
    await FirebaseService.saveRestDay({
      'id': restDay.id,
      'date': restDay.date.toIso8601String(),
      'clientName': restDay.clientName,
      'notes': restDay.notes,
    });
    widget.onRestDayAdded(restDay);
    setState(() {
      _saving = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Rest day scheduled!')));
    setState(() {
      _selectedClient = null;
      _selectedDate = null;
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule a Rest Day',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<ClientProfile>(
            initialValue: _selectedClient,
            items: widget.clients
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.name.isNotEmpty ? c.name : c.username),
                  ),
                )
                .toList(),
            onChanged: (c) => setState(() => _selectedClient = c),
            decoration: const InputDecoration(
              labelText: 'Select Client',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: InkWell(
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _selectedDate == null
                            ? 'Pick a date'
                            : '${_selectedDate!.toLocal()}'.split(' ')[0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.hotel),
              label: const Text('Schedule Rest Day'),
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
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

class InstructorDashboardScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const InstructorDashboardScreen({super.key, this.onLogout});

  @override
  _InstructorDashboardScreenState createState() =>
      _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  static const String _defaultLoginQuote =
      '"The hardest part of any workout is turning up"';

  // Helper to convert Workout to Firebase map
  Map<String, dynamic> _workoutToFirebaseMap(Workout workout) {
    return {
      'id': workout.id,
      'name': workout.name,
      'date': workout.date.toIso8601String(),
      'exercises': workout.exercises.map((e) => e.toJson()).toList(),
      'clientName': workout.clientName,
      'clientUsername': workout.clientUsername,
      'isCompleted': workout.isCompleted,
      'isReviewedByInstructor': workout.isReviewedByInstructor,
      'isReviewAcknowledged': workout.isReviewAcknowledged,
      'type': workout.type,
    };
  }

  List<Workout> _workouts = [];
  List<RestDay> _restDays = [];
  List<ClientProfile> _clients = [];
  bool _loading = true;
  bool _runningUidBackfill = false;

  int get _pendingReviewCount =>
      _workouts.where((w) => w.isCompleted && !w.isReviewedByInstructor).length;

  StreamSubscription<DatabaseEvent>? _workoutsSubscription;
  StreamSubscription<DatabaseEvent>? _restDaysSubscription;
  StreamSubscription<DatabaseEvent>? _clientsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _workoutsSubscription?.cancel();
    _restDaysSubscription?.cancel();
    _clientsSubscription?.cancel();
    super.dispose();
  }

  Workout _workoutFromMap(Map<String, dynamic> workoutMap) {
    final rawDate = workoutMap['date']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();

    return Workout(
      id: workoutMap['id']?.toString() ?? '',
      name: workoutMap['name']?.toString() ?? 'Workout',
      date: parsedDate,
      exercises:
          (workoutMap['exercises'] as List?)
              ?.map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      clientName: workoutMap['clientName']?.toString() ?? '',
      clientUsername: (workoutMap['clientUsername'] ?? '').toString(),
      isCompleted: workoutMap['isCompleted'] == true,
      isReviewedByInstructor: workoutMap['isReviewedByInstructor'] == true,
      isReviewAcknowledged: workoutMap['isReviewAcknowledged'] == true,
      type: workoutMap['type'] ?? '',
      feedback: workoutMap['feedback']?.toString(),
      instructorReview: workoutMap['instructorReview']?.toString(),
      notes: workoutMap['notes']?.toString(),
      warmUp: workoutMap['warmUp']?.toString(),
      coolDown: workoutMap['coolDown']?.toString(),
    );
  }

  Future<List<ClientProfile>> _loadClientProfiles() async {
    final clientUsernames = await FirebaseService.getClientsList();
    final clientProfiles = <ClientProfile>[];
    for (final username in clientUsernames) {
      final profileMap = await FirebaseService.getClientProfile(username);
      if (profileMap != null) {
        clientProfiles.add(
          ClientProfile.fromMap(profileMap, fallbackUsername: username),
        );
      } else {
        // Keep dashboard usable if profile docs are temporarily missing or
        // only partially migrated.
        clientProfiles.add(
          ClientProfile(
            username: username,
            email: '',
            name: username,
            notifications: const [],
          ),
        );
      }
    }
    return clientProfiles;
  }

  Future<void> _refreshWorkouts() async {
    final workoutMaps = await FirebaseService.getAllWorkouts();
    await FirebaseService.rebuildWorkoutIndexes(workouts: workoutMaps);
    if (!mounted) return;
    setState(() {
      _workouts = workoutMaps.map(_workoutFromMap).toList();
    });
  }

  Future<void> _refreshRestDays() async {
    final restDayMaps = await FirebaseService.getAllRestDays();
    if (!mounted) return;
    setState(() {
      _restDays = restDayMaps
          .map(
            (r) => RestDay(
              id: r['id'],
              date: DateTime.parse(r['date']),
              clientName: r['clientName'],
              notes: r['notes'],
            ),
          )
          .toList();
    });
  }

  Future<void> _refreshClients() async {
    final clientProfiles = await _loadClientProfiles();
    if (!mounted) return;
    setState(() {
      _clients = clientProfiles;
    });
  }

  void _subscribeToDashboardData() {
    _workoutsSubscription?.cancel();
    _restDaysSubscription?.cancel();
    _clientsSubscription?.cancel();

    _workoutsSubscription = FirebaseService.watchAllWorkouts().listen((_) {
      _refreshWorkouts();
    });
    _restDaysSubscription = FirebaseService.watchAllRestDays().listen((_) {
      _refreshRestDays();
    });
    _clientsSubscription = FirebaseService.watchClientsList().listen((_) {
      _refreshClients();
    });
  }

  Future<void> _loadData() async {
    await FirebaseService.initialize();
    final workoutMaps = await FirebaseService.getAllWorkouts();
    await FirebaseService.rebuildWorkoutIndexes(workouts: workoutMaps);
    final restDayMaps = await FirebaseService.getAllRestDays();
    final clientProfiles = await _loadClientProfiles();
    setState(() {
      _workouts = workoutMaps.map(_workoutFromMap).toList();
      _restDays = restDayMaps
          .map(
            (r) => RestDay(
              id: r['id'],
              date: DateTime.parse(r['date']),
              clientName: r['clientName'],
              notes: r['notes'],
            ),
          )
          .toList();
      _clients = clientProfiles;
      _loading = false;
    });
    _subscribeToDashboardData();
  }

  Future<void> _openClientProfile(ClientProfile client) async {
    final profileMap = await FirebaseService.getClientProfile(client.username);
    final currentProfile = profileMap != null
        ? ClientProfile.fromMap(
            Map<String, dynamic>.from(profileMap),
            fallbackUsername: client.username,
          )
        : client;

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientProfileScreen(
          profile: currentProfile,
          isInstructor: true,
          onProfileUpdated: (updatedProfile) async {
            await FirebaseService.saveClientProfile(
              updatedProfile.username,
              updatedProfile.toMap(),
            );
            if (!mounted) return;
            setState(() {
              final idx = _clients.indexWhere(
                (c) => c.username == updatedProfile.username,
              );
              if (idx != -1) {
                _clients[idx] = updatedProfile;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client profile updated!')),
            );
          },
        ),
      ),
    );
  }

  Future<void> _editLoginQuote() async {
    final currentQuote =
        await FirebaseService.getLoginQuote() ?? _defaultLoginQuote;
    final quoteController = TextEditingController(text: currentQuote);

    final updatedQuote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Login Quote'),
        content: TextField(
          controller: quoteController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter quote shown on login screen',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = quoteController.text.trim();
              if (value.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quote cannot be empty.')),
                );
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updatedQuote == null || updatedQuote.isEmpty) return;
    await FirebaseService.saveLoginQuote(updatedQuote);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Login quote updated.')));
  }

  Future<void> _runUidBackfill() async {
    if (_runningUidBackfill) return;
    setState(() => _runningUidBackfill = true);

    try {
      final result = await FirebaseService.runUidBackfill();
      if (!mounted) return;

      final unresolved = (result['unresolved'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final summary =
          'workouts: ${result['workoutsUpdated']}, '
          'restDays: ${result['restDaysUpdated']}, '
          'profiles: ${result['profilesCopiedToUid']}, '
          'users: ${result['usersCopiedToUid']}';

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('UID Backfill Complete'),
          content: SingleChildScrollView(
            child: Text(
              unresolved.isEmpty
                  ? '$summary\n\nNo unresolved usernames.'
                  : '$summary\n\nUnresolved (${unresolved.length}):\n${unresolved.join('\n')}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('UID backfill failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _runningUidBackfill = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 10,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          title: const Text('Instructor Dashboard'),
          actions: [
            IconButton(
              icon: _runningUidBackfill
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync_alt),
              tooltip: 'Run UID Backfill',
              onPressed: _runningUidBackfill ? null : _runUidBackfill,
            ),
            IconButton(
              icon: const Icon(Icons.format_quote),
              tooltip: 'Edit Login Quote',
              onPressed: _editLoginQuote,
            ),
            IconButton(
              icon: const Icon(Icons.vpn_key),
              tooltip: 'Reset Password',
              onPressed: () async {
                final TextEditingController passwordController =
                    TextEditingController();
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Password'),
                    content: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(passwordController.text.trim()),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  final hashedPassword = SecurityHelper.hashPassword(
                    result,
                    'instructor',
                  );
                  await FirebaseService.saveInstructorPassword(hashedPassword);
                  try {
                    await FirebaseService.updateCurrentAuthPassword(result);
                  } catch (_) {
                    // Ignore auth update failures here; instructor can re-login.
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset successfully!'),
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                if (widget.onLogout != null) {
                  widget.onLogout!();
                }
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                text: 'Calendar',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.calendar_month),
                    if (_pendingReviewCount > 0)
                      Positioned(
                        right: -8,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$_pendingReviewCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
              const Tab(icon: Icon(Icons.add), text: 'Add Workout'),
              const Tab(
                icon: Icon(Icons.workspace_premium),
                text: 'Circuit of the Week',
              ),
              const Tab(icon: Icon(Icons.fitness_center), text: 'Exercises'),
              const Tab(
                icon: Icon(Icons.accessibility_new),
                text: 'Stretching',
              ),
              const Tab(icon: Icon(Icons.people), text: 'Clients'),
              const Tab(icon: Icon(Icons.hotel), text: 'Rest Days'),
              const Tab(icon: Icon(Icons.manage_accounts), text: 'My Profile'),
              const Tab(icon: Icon(Icons.directions_walk), text: 'Steps'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  InstructorCalendar(
                    workouts: _workouts,
                    restDays: _restDays,
                    clients: _clients,
                  ),
                  NotificationTab(clients: _clients),
                  AddWorkoutScreen(
                    onWorkoutAdded: (workout) async {
                      final workoutMap = _workoutToFirebaseMap(workout);

                      // Look up and add clientUid
                      final client = _clients.firstWhere(
                        (c) =>
                            c.username == workout.clientName ||
                            c.name == workout.clientName,
                        orElse: () => ClientProfile(
                          username: workout.clientName,
                          email: '',
                          name: '',
                          notifications: [],
                        ),
                      );
                      final clientUid = await FirebaseService.getUidForUsername(
                        client.username,
                      );
                      if (clientUid != null && clientUid.isNotEmpty) {
                        workoutMap['clientUid'] = clientUid;
                      }

                      await FirebaseService.saveWorkout(workout.id, workoutMap);
                      final usernameKey = client.username;
                      final workoutListKey = 'workouts_$usernameKey';
                      String? workoutList = await FirebaseService.getString(
                        workoutListKey,
                      );
                      List<String> workoutIds = (workoutList?.split(',') ?? [])
                          .where((id) => id.isNotEmpty)
                          .toList();
                      if (!workoutIds.contains(workout.id)) {
                        workoutIds.add(workout.id);
                        await FirebaseService.setString(
                          workoutListKey,
                          workoutIds.join(','),
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Workout added!')),
                      );
                    },
                    clients: _clients,
                  ),
                  const WorkoutOfWeekScreen(canEdit: true),
                  const ManageExerciseLibraryScreen(),
                  const ManageStretchingLibraryScreen(),
                  ClientsTab(
                    clients: _clients,
                    onDeleteClient: (client) async {
                      await FirebaseService.deleteUser(client.username);
                      await FirebaseService.deleteClientProfile(
                        client.username,
                      );
                      setState(() {
                        _clients.removeWhere(
                          (c) => c.username == client.username,
                        );
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Client deleted successfully.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    onAddClient: (username, name, password) async {
                      await FirebaseService.addClient(name, username, password);
                      final profileMap = await FirebaseService.getClientProfile(
                        username,
                      );
                      if (profileMap != null) {
                        setState(() {
                          _clients.add(
                            ClientProfile(
                              username: profileMap['username'] ?? '',
                              email: profileMap['email'] ?? '',
                              name: profileMap['name'] ?? '',
                              notifications: const [],
                            ),
                          );
                        });
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Client added successfully.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    onViewClient: _openClientProfile,
                    onEditClient: _openClientProfile,
                  ),
                  _RestDayScheduler(
                    clients: _clients,
                    onRestDayAdded: (restDay) async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rest day scheduled!')),
                      );
                    },
                  ),
                  const InstructorBioEditTab(),
                  _StepActivityTab(clients: _clients),
                ],
              ),
      ),
    );
  }
}

// -- Step Activity Tab -------------------------------------------------------

class _StepActivityTab extends StatefulWidget {
  final List<ClientProfile> clients;
  const _StepActivityTab({required this.clients});

  @override
  State<_StepActivityTab> createState() => _StepActivityTabState();
}

class _StepActivityTabState extends State<_StepActivityTab> {
  // Map of username → {date, steps}
  Map<String, Map<String, dynamic>> _latestSteps = {};
  // Map of username → Map<date, steps> for selected client
  Map<String, int> _selectedClientWeekSteps = {};
  ClientProfile? _selectedClient;
  int _selectedClientGoal = 10000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSteps();
  }

  Future<void> _loadAllSteps() async {
    setState(() => _loading = true);
    final data = await FirebaseService.getAllClientsLatestSteps();
    if (mounted) {
      setState(() {
        _latestSteps = data;
        _loading = false;
      });
    }
  }

  Future<void> _loadClientWeekSteps(String username) async {
    final results = await Future.wait([
      FirebaseService.getStepCounts(username, days: 7),
      FirebaseService.getClientStepGoal(username),
    ]);
    if (mounted) {
      setState(() {
        _selectedClientWeekSteps = results[0] as Map<String, int>;
        _selectedClientGoal = (results[1] as int?) ?? 10000;
      });
    }
  }

  Future<void> _editStepGoal(ClientProfile client) async {
    final controller = TextEditingController(
      text: _selectedClientGoal.toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Set Daily Step Goal',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client: ${client.name.isNotEmpty ? client.name : client.username}',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily step goal',
                border: OutlineInputBorder(),
                suffixText: 'steps',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [5000, 7500, 10000, 12500, 15000].map((preset) {
                return ActionChip(
                  label: Text(
                    preset >= 1000
                        ? '${(preset / 1000).toStringAsFixed(1).replaceAll('.0', '')}k'
                        : preset.toString(),
                  ),
                  onPressed: () => controller.text = preset.toString(),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) Navigator.of(ctx).pop(val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await FirebaseService.saveClientStepGoal(client.username, result);
      if (mounted) {
        setState(() => _selectedClientGoal = result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Step goal updated to ${result >= 1000 ? '${(result / 1000).toStringAsFixed(1).replaceAll('.0', '')}k' : result} steps/day for ${client.name.isNotEmpty ? client.name : client.username}',
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    }
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }

  Color _stepsColor(int steps) {
    final goal = _selectedClientGoal;
    if (steps >= goal) return const Color(0xFF059669);
    if (steps >= (goal * 0.7).round()) return const Color(0xFF2563EB);
    if (steps >= (goal * 0.4).round()) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFFF0F9FF),
          child: Row(
            children: [
              const Icon(Icons.directions_walk, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Client Step Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
                tooltip: 'Refresh',
                onPressed: () {
                  _loadAllSteps();
                  if (_selectedClient != null) {
                    _loadClientWeekSteps(_selectedClient!.username);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : widget.clients.isEmpty
              ? const Center(child: Text('No clients found.'))
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client list
                    SizedBox(
                      width: 200,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: widget.clients.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final client = widget.clients[i];
                          final username = client.username;
                          final stepInfo = _latestSteps[username];
                          final latestSteps = stepInfo?['steps'] as int? ?? 0;
                          final isSelected = _selectedClient == client;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: const Color(0xFFEFF6FF),
                            dense: true,
                            title: Text(
                              client.name.isNotEmpty
                                  ? client.name
                                  : client.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: stepInfo != null
                                ? Row(
                                    children: [
                                      Icon(
                                        Icons.directions_walk,
                                        size: 12,
                                        color: _stepsColor(latestSteps),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _formatSteps(latestSteps),
                                        style: TextStyle(
                                          color: _stepsColor(latestSteps),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'No data',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                            onTap: () {
                              setState(() {
                                _selectedClient = client;
                                _selectedClientWeekSteps = {};
                              });
                              _loadClientWeekSteps(client.username);
                            },
                          );
                        },
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    // Detail panel
                    Expanded(
                      child: _selectedClient == null
                          ? const Center(
                              child: Text(
                                'Select a client to see their step history',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : _buildClientStepDetail(context),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildClientStepDetail(BuildContext context) {
    final client = _selectedClient!;
    final stepInfo = _latestSteps[client.username];
    final todayKey = _todayKey();
    final todaySteps = _selectedClientWeekSteps[todayKey] ?? 0;
    final goal = _selectedClientGoal;

    // Sort week steps by date descending
    final sortedDays = _selectedClientWeekSteps.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client name header
          Text(
            client.name.isNotEmpty ? client.name : client.username,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 4),
          // Goal row with edit button
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Daily goal: ${_formatSteps(goal)} steps',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _editStepGoal(client),
                child: const Icon(
                  Icons.edit,
                  size: 15,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          if (stepInfo != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Last synced: ${stepInfo['date']}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          const SizedBox(height: 20),
          // Today's steps card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: todaySteps >= goal
                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                    : [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Steps",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _selectedClientWeekSteps.isEmpty
                          ? '...'
                          : _formatSteps(todaySteps),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        '/ ${_formatSteps(goal)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (todaySteps / goal).clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 7-day history
          if (sortedDays.isNotEmpty) ...[
            const Text(
              '7-Day History',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
            ...sortedDays.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        _formatDateLabel(entry.key),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (entry.value / goal).clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFFE5E7EB),
                          color: _stepsColor(entry.value),
                          minHeight: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 42,
                      child: Text(
                        _formatSteps(entry.value),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _stepsColor(entry.value),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_selectedClientWeekSteps.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'No step data recorded yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatDateLabel(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return DateFormat('EEE, MMM d').format(date);
    } catch (_) {
      return dateKey;
    }
  }
}
