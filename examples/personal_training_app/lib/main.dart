import 'package:flutter/material.dart';
import 'models/workout.dart';
import 'models/client_profile.dart';
import 'screens/home_screen.dart';
import 'screens/workout_history_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/login_screen.dart';
import 'screens/exercise_library_screen.dart';
import 'screens/stretching_screen.dart';
import 'screens/client_profile_screen.dart';
import 'screens/workout_of_week_screen.dart';
import 'utils/storage_helper.dart';
import 'utils/firebase_service.dart';
import 'screens/instructor_dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

bool get _isProductionEnv {
  const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  final normalized = appEnv.trim().toLowerCase();
  return normalized == 'prod' || normalized == 'production';
}

void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _activateFirebaseAppCheck() async {
  try {
    if (kIsWeb) {
      const webSiteKey = String.fromEnvironment(
        'RECAPTCHA_SITE_KEY',
        defaultValue: 'YOUR_RECAPTCHA_SITE_KEY',
      );
      if (webSiteKey == 'YOUR_RECAPTCHA_SITE_KEY') {
        if (_isProductionEnv) {
          throw StateError(
            'RECAPTCHA_SITE_KEY must be set for production web releases.',
          );
        }
        debugPrint(
          'App Check web key not set. Skipping web App Check activation.',
        );
        return;
      }
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(webSiteKey),
      );
      return;
    }

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  } catch (e) {
    if (_isProductionEnv) {
      rethrow;
    }
    debugPrint('App Check activation error: $e');
  }
}

/// Migration: Ensure all locally stored workouts have warmUp and coolDown fields in the pipe-delimited string
Future<void> migrateWorkoutsToIncludeWarmUpCoolDown() async {
  print('🔄 Migration: Checking all workouts for warmUp/coolDown fields...');
  final clientsList = await StorageHelper.getString('clients_list') ?? '';
  if (clientsList.isEmpty) return;
  final usernames = clientsList.split(',').where((u) => u.isNotEmpty);
  for (final username in usernames) {
    final workoutListKey = 'workouts_$username';
    final workoutIdsStr = await StorageHelper.getString(workoutListKey) ?? '';
    final workoutIds = workoutIdsStr.split(',').where((id) => id.isNotEmpty);
    for (final workoutId in workoutIds) {
      final storageKey = 'workout_$workoutId';
      final workoutData = await StorageHelper.getString(storageKey) ?? '';
      if (workoutData.isEmpty) continue;
      // Count number of pipes
      final pipeCount = workoutData.split('|').length - 1;
      // New format: 12 pipes (13 fields)
      if (pipeCount >= 12) continue; // Already migrated
      // If missing, add empty warmUp/coolDown fields
      if (pipeCount == 10) {
        // Add two pipes for warmUp and coolDown
        final migrated = '$workoutData||';
        await StorageHelper.setString(storageKey, migrated);
        print(
          '🔄 Migrated workout $workoutId for $username: added warmUp/coolDown',
        );
      } else if (pipeCount == 11) {
        // Add one pipe for coolDown
        final migrated = '$workoutData|';
        await StorageHelper.setString(storageKey, migrated);
        print('🔄 Migrated workout $workoutId for $username: added coolDown');
      }
    }
  }
  print('✅ Migration complete.');
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _initializeFirebase();
  print('🔔 [FCM] Background message: ${message.messageId}');
}

Future<void> _initializeFirebase() async {
  try {
    if (kIsWeb) {
      // Web platform: use explicit Firebase options
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCJMyeC3fNuvO1RUY-4dgXAmbTN52Feaco',
          authDomain: 'sim-training-55d86.firebaseapp.com',
          projectId: 'sim-training-55d86',
          storageBucket: 'sim-training-55d86.firebasestorage.app',
          messagingSenderId: '1050830167472',
          appId: '1:1050830167472:web:web-app-id',
          databaseURL: 'https://sim-training-55d86-default-rtdb.firebaseio.com',
        ),
      );
    } else {
      // Mobile platforms: use google-services.json / GoogleService-Info.plist
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    rethrow;
  }
}

Future<void> _initializePostLaunchServices() async {
  // FCM setup (mobile only - skip on web to avoid service worker errors)
  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      final fcm = FirebaseMessaging.instance;
      await fcm.requestPermission();
      final token = await fcm.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      _debugLog('🔑 [FCM] Device token: ${token ?? "(null)"}');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _debugLog('🔔 [FCM] Foreground message: ${message.messageId}');
        if (message.notification != null) {
          _debugLog(
            '🔔 [FCM] Notification: ${message.notification!.title} - ${message.notification!.body}',
          );
          // Show a visible notification in-app
          final navigator = navigatorKey.currentState;
          if (navigator != null) {
            final context = navigator.overlay?.context;
            if (context != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${message.notification!.title ?? 'Notification'}: ${message.notification!.body ?? ''}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  duration: const Duration(seconds: 4),
                  backgroundColor: Colors.blueAccent,
                ),
              );
            }
          }
        }
      });
    } catch (e) {
      _debugLog('⚠️ FCM initialization error: $e');
    }
  }

  try {
    await StorageHelper.init();
    print('✅ Storage initialized successfully');
    await migrateWorkoutsToIncludeWarmUpCoolDown();
  } catch (e) {
    print('❌ Error initializing storage: $e');
    // Continue anyway - app can work without storage
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _initializeFirebase();
    await _activateFirebaseAppCheck();
  } catch (e) {
    // Firebase init failed — still launch the app so the UI is visible.
    debugPrint('⚠️ Firebase init failed, continuing without Firebase: $e');
  }
  print('🚀 Starting app...');
  print('✅ Flutter binding initialized');
  print('🎨 Running app...');
  runApp(const PersonalTrainingApp());
  unawaited(_initializePostLaunchServices());
}

class PersonalTrainingApp extends StatelessWidget {
  const PersonalTrainingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SIM Training partner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with SingleTickerProviderStateMixin {
  bool _isLoadingUser = false;
  String? _userRole; // 'client', 'instructor', or null
  String? _currentUserEmail;
  late ClientProfile _clientProfile;
  late List<Workout> _workouts;
  bool _showSplash = true;
  late AnimationController _splashController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  StreamSubscription<DatabaseEvent>? _clientProfileSubscription;
  final List<StreamSubscription<DatabaseEvent>> _clientWorkoutSubscriptions =
      [];

  @override
  void initState() {
    super.initState();

    _workouts = [];
    _clientProfile = ClientProfile(
      username: '',
      email: '',
      name: '',
      age: 0,
      heightCm: 0,
      weightKg: 0,
      fitnessGoals: '',
      trainingExperience: '',
      trainingLocation: '',
      hobbiesInterests: '',
      injuriesLimitations: '',
      strengthPRs: {},
    );

    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeInOutCubic),
    );

    // Always show splash on app start
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        await _splashController.forward();
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
        }
        _splashController.reset();
      }
    });
  }

  @override
  void dispose() {
    _clientProfileSubscription?.cancel();
    for (final subscription in _clientWorkoutSubscriptions) {
      subscription.cancel();
    }
    _clientWorkoutSubscriptions.clear();
    _splashController.dispose();
    super.dispose();
  }

  Future<void> _cacheProfileLocally(ClientProfile profile) async {
    final username = profile.username;
    await StorageHelper.setString(
      'profile_json_$username',
      jsonEncode(profile.toMap()),
    );
    await StorageHelper.setString('profile_email_$username', profile.email);
    await StorageHelper.setString('profile_name_$username', profile.name);
    await StorageHelper.setString(
      'profile_age_$username',
      profile.age?.toString() ?? '0',
    );
    await StorageHelper.setString(
      'profile_height_$username',
      profile.heightCm?.toString() ?? '0',
    );
    await StorageHelper.setString(
      'profile_weight_$username',
      profile.weightKg?.toString() ?? '0',
    );
    await StorageHelper.setString(
      'profile_goals_$username',
      profile.fitnessGoals,
    );
    await StorageHelper.setString(
      'profile_smart_goals_$username',
      profile.smartGoals,
    );
    await StorageHelper.setString(
      'profile_experience_$username',
      profile.trainingExperience,
    );
    await StorageHelper.setString(
      'profile_location_$username',
      profile.trainingLocation,
    );
    await StorageHelper.setString(
      'profile_hobbies_$username',
      profile.hobbiesInterests,
    );
    await StorageHelper.setString(
      'profile_limitations_$username',
      profile.injuriesLimitations,
    );
    await StorageHelper.setString(
      'profile_picture_$username',
      profile.profilePictureUrl ?? '',
    );
  }

  Future<ClientProfile> _loadCachedProfile(String username) async {
    final profileJson = await StorageHelper.getString('profile_json_$username');
    if (profileJson != null && profileJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(profileJson) as Map<String, dynamic>;
        return ClientProfile.fromMap(decoded, fallbackUsername: username);
      } catch (_) {}
    }

    final email =
        await StorageHelper.getString('profile_email_$username') ?? '';
    final name = await StorageHelper.getString('profile_name_$username') ?? '';
    final ageStr =
        await StorageHelper.getString('profile_age_$username') ?? '0';
    final heightStr =
        await StorageHelper.getString('profile_height_$username') ?? '0';
    final weightStr =
        await StorageHelper.getString('profile_weight_$username') ?? '0';
    final fitnessGoals =
        await StorageHelper.getString('profile_goals_$username') ?? '';
    final smartGoals =
        await StorageHelper.getString('profile_smart_goals_$username') ?? '';
    final trainingExperience =
        await StorageHelper.getString('profile_experience_$username') ?? '';
    final trainingLocation =
        await StorageHelper.getString('profile_location_$username') ?? '';
    final hobbiesInterests =
        await StorageHelper.getString('profile_hobbies_$username') ?? '';
    final injuriesLimitations =
        await StorageHelper.getString('profile_limitations_$username') ?? '';
    final profilePicture =
        await StorageHelper.getString('profile_picture_$username') ?? '';
    return ClientProfile(
      username: username,
      email: email,
      name: name,
      age: int.tryParse(ageStr) ?? 0,
      heightCm: double.tryParse(heightStr) ?? 0.0,
      weightKg: double.tryParse(weightStr) ?? 0.0,
      fitnessGoals: fitnessGoals,
      smartGoals: smartGoals,
      trainingExperience: trainingExperience,
      trainingLocation: trainingLocation,
      hobbiesInterests: hobbiesInterests,
      injuriesLimitations: injuriesLimitations,
      profilePictureUrl: profilePicture.isNotEmpty ? profilePicture : null,
      strengthPRs: const {},
    );
  }

  Future<void> _persistProfile(ClientProfile profile) async {
    await FirebaseService.saveClientProfile(profile.username, profile.toMap());
    await _cacheProfileLocally(profile);
  }

  void _subscribeToClientProfile(String username) {
    _clientProfileSubscription?.cancel();
    _clientProfileSubscription = FirebaseService.watchClientProfile(username)
        .listen((event) async {
          if (!event.snapshot.exists || _currentUserEmail != username) return;
          final profileMap = await FirebaseService.getClientProfile(username);
          if (profileMap == null || _currentUserEmail != username) return;
          final updatedProfile = ClientProfile.fromMap(
            profileMap,
            fallbackUsername: username,
          );
          await _cacheProfileLocally(updatedProfile);
          _subscribeToClientWorkouts(
            username,
            clientName: updatedProfile.name,
            resolvedUsername: updatedProfile.username,
          );
          await _syncClientWorkoutsFromFirebase(
            username,
            clientName: updatedProfile.name,
            resolvedUsername: updatedProfile.username,
          );
          if (!mounted || _currentUserEmail != username) return;
          setState(() {
            _clientProfile = updatedProfile;
          });
        });
  }

  void _subscribeToClientWorkouts(
    String username, {
    String? clientName,
    String? resolvedUsername,
  }) {
    for (final subscription in _clientWorkoutSubscriptions) {
      subscription.cancel();
    }
    _clientWorkoutSubscriptions.clear();

    final workoutListKeys = _workoutListKeysForClient(
      username,
      clientName: clientName,
      resolvedUsername: resolvedUsername,
    );

    final watchedOwners = <String>{};
    for (final workoutListKey in workoutListKeys) {
      if (!workoutListKey.startsWith('workouts_')) continue;
      final owner = workoutListKey.substring('workouts_'.length).trim();
      if (owner.isEmpty || !watchedOwners.add(owner)) continue;

      final subscription = FirebaseService.watchWorkoutIndex(owner).listen((_) {
        if (_currentUserEmail != username) return;
        _syncClientWorkoutsFromFirebase(
          username,
          clientName: clientName,
          resolvedUsername: resolvedUsername,
        );
      });
      _clientWorkoutSubscriptions.add(subscription);
    }
  }

  String _canonicalClientValue(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('micheal', 'michael')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Set<String> _clientNameVariants(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return {};
    final variants = <String>{trimmed};
    final lower = trimmed.toLowerCase();
    if (lower.contains('michael')) {
      variants.add(
        trimmed.replaceAll(RegExp('michael', caseSensitive: false), 'micheal'),
      );
    }
    if (lower.contains('micheal')) {
      variants.add(
        trimmed.replaceAll(RegExp('micheal', caseSensitive: false), 'michael'),
      );
    }
    return variants;
  }

  List<String> _workoutListKeysForClient(
    String username, {
    String? clientName,
    String? resolvedUsername,
  }) {
    final keys = <String>{'workouts_$username'};
    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isNotEmpty) {
      keys.add('workouts_$normalizedUsername');
    }

    final resolved = (resolvedUsername ?? '').trim();
    if (resolved.isNotEmpty) {
      keys.add('workouts_$resolved');
      final normalizedResolved = resolved.toLowerCase();
      if (normalizedResolved.isNotEmpty) {
        keys.add('workouts_$normalizedResolved');
      }
    }

    final legacyName = (clientName ?? '').trim();
    for (final variant in _clientNameVariants(legacyName)) {
      if (variant != username) {
        keys.add('workouts_$variant');
      }
    }
    return keys.toList();
  }

  Future<void> _loadUserData(String username) async {
    setState(() {
      _isLoadingUser = true;
    });
    _currentUserEmail = username;
    _subscribeToClientProfile(username);

    // Load full profile from Firebase (source of truth) — falls back to local cache
    final firebaseProfile = await FirebaseService.getClientProfile(username);
    final ClientProfile loadedProfile;
    if (firebaseProfile != null) {
      loadedProfile = ClientProfile.fromMap(
        firebaseProfile,
        fallbackUsername: username,
      );
      await _cacheProfileLocally(loadedProfile);
    } else {
      loadedProfile = await _loadCachedProfile(username);
    }

    await _syncClientWorkoutsFromFirebase(
      username,
      clientName: loadedProfile.name,
      resolvedUsername: loadedProfile.username,
    );

    _subscribeToClientWorkouts(
      username,
      clientName: loadedProfile.name,
      resolvedUsername: loadedProfile.username,
    );

    // Load workouts for this specific user (start fresh if none exist)
    final userWorkouts = <Workout>[];
    final workoutIds = <String>{};
    final workoutListKeys = _workoutListKeysForClient(
      username,
      clientName: loadedProfile.name,
      resolvedUsername: loadedProfile.username,
    );
    for (final workoutListKey in workoutListKeys) {
      final workoutListStr =
          await StorageHelper.getString(workoutListKey) ?? '';
      workoutIds.addAll(workoutListStr.split(',').where((id) => id.isNotEmpty));
      _debugLog(
        '🔍 DEBUG: Loading workouts for $username - Key: $workoutListKey',
      );
    }
    _debugLog('🔍 DEBUG: Workout IDs found: ${workoutIds.toList()}');

    for (final workoutId in workoutIds) {
      final storageKey = 'workout_$workoutId';
      final workoutData = await StorageHelper.getString(storageKey) ?? '';
      _debugLog(
        '🔍 DEBUG: Loading workout $workoutId - Key: $storageKey - Data: $workoutData',
      );
      if (workoutData.isNotEmpty) {
        try {
          final workout = _deserializeWorkout(workoutData);
          userWorkouts.add(workout);
          _debugLog('✅ DEBUG: Successfully loaded workout: \\${workout.name}');
        } catch (e) {
          _debugLog('❌ DEBUG: Error loading workout $workoutId: $e');
          final firebaseWorkout = await FirebaseService.getWorkout(workoutId);
          if (firebaseWorkout != null) {
            final workout = _workoutFromFirebaseMap(workoutId, firebaseWorkout);
            await _saveWorkoutToStorage(workout, syncFirebase: false);
            userWorkouts.add(workout);
            _debugLog(
              '✅ DEBUG: Loaded fallback Firebase workout: ${workout.name}',
            );
          }
        }
      } else {
        _debugLog('❌ DEBUG: No data found for workout $workoutId');
        final firebaseWorkout = await FirebaseService.getWorkout(workoutId);
        if (firebaseWorkout != null) {
          final workout = _workoutFromFirebaseMap(workoutId, firebaseWorkout);
          await _saveWorkoutToStorage(workout, syncFirebase: false);
          userWorkouts.add(workout);
          _debugLog(
            '✅ DEBUG: Loaded missing workout from Firebase: ${workout.name}',
          );
        }
      }
    }
    _debugLog(
      '✅ DEBUG: Loaded \\${userWorkouts.length} total workouts for $username',
    );

    // Update state with loaded profile and workouts
    setState(() {
      _clientProfile = loadedProfile;
      _workouts = userWorkouts; // Clear workouts for new client
      _isLoadingUser = false;
    });
  }

  Future<void> _syncClientWorkoutsFromFirebase(
    String username, {
    String? clientName,
    String? resolvedUsername,
  }) async {
    final profile = await FirebaseService.getClientProfile(username);
    final profileName = (clientName ?? '').trim().isNotEmpty
        ? clientName!.trim()
        : profile?['name']?.toString() ?? '';
    final profileUsername = (resolvedUsername ?? '').trim().isNotEmpty
        ? resolvedUsername!.trim()
        : profile?['username']?.toString() ?? '';
    final workoutListKeys = _workoutListKeysForClient(
      username,
      clientName: profileName,
      resolvedUsername: profileUsername,
    );
    final workoutIds = <String>{};

    for (final workoutListKey in workoutListKeys) {
      final firebaseWorkoutList = await FirebaseService.getString(
        workoutListKey,
      );
      if (firebaseWorkoutList != null && firebaseWorkoutList.isNotEmpty) {
        await StorageHelper.setString(workoutListKey, firebaseWorkoutList);
        workoutIds.addAll(
          firebaseWorkoutList.split(',').where((id) => id.isNotEmpty),
        );
      } else {
        final localWorkoutList =
            await StorageHelper.getString(workoutListKey) ?? '';
        workoutIds.addAll(
          localWorkoutList.split(',').where((id) => id.isNotEmpty),
        );
      }
    }

    // Always augment from workouts collection directly to catch stale/missing
    // index entries and name-variant assignments.
    final clientWorkouts =
        await FirebaseService.getClientWorkoutsForCurrentUser(
          fallbackUsername: profileUsername.isNotEmpty
              ? profileUsername
              : username,
        );
    final matchedWorkoutMapsById = <String, Map<String, dynamic>>{};
    for (final w in clientWorkouts) {
      final id = (w['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      // Query methods are already user-scoped by clientUid/clientUsername.
      // Trust those results to avoid filtering out legacy or partially-migrated
      // workouts that are valid for this client but have mismatched name fields.
      workoutIds.add(id);
      matchedWorkoutMapsById[id] = Map<String, dynamic>.from(w);
    }

    if (workoutIds.isEmpty) {
      _debugLog(
        '⚠️ DEBUG: No workout IDs found for $username after all fallbacks',
      );
      return;
    }

    await StorageHelper.setString('workouts_$username', workoutIds.join(','));

    for (final workoutId in workoutIds) {
      final firebaseWorkout =
          matchedWorkoutMapsById[workoutId] ??
          await FirebaseService.getWorkout(workoutId);
      if (firebaseWorkout == null) {
        continue;
      }

      // Debug: Print the workout data loaded from Firebase
      _debugLog('DEBUG: Loaded workout from Firebase for client sync:');
      _debugLog('  id: $workoutId');
      _debugLog('  name: \\${firebaseWorkout['name']}');
      _debugLog('  warmUp: \\${firebaseWorkout['warmUp']}');
      _debugLog('  coolDown: \\${firebaseWorkout['coolDown']}');
      _debugLog('  full data: $firebaseWorkout');

      try {
        final workout = _workoutFromFirebaseMap(workoutId, firebaseWorkout);
        await _saveWorkoutToStorage(workout, syncFirebase: false);
      } catch (e) {
        _debugLog(
          '❌ DEBUG: Error mapping workout $workoutId from Firebase: $e',
        );
      }
    }

    // After syncing, reload workouts from local storage to update UI
    final userWorkouts = <Workout>[];
    final reloadWorkoutListStr =
        await StorageHelper.getString('workouts_$username') ?? '';
    final reloadWorkoutIds = reloadWorkoutListStr
        .split(',')
        .where((id) => id.isNotEmpty)
        .toList();
    _debugLog(
      '🔄 DEBUG: Reloading workouts from local storage after sync: $reloadWorkoutIds',
    );
    for (final workoutId in reloadWorkoutIds) {
      final storageKey = 'workout_$workoutId';
      final workoutData = await StorageHelper.getString(storageKey) ?? '';
      _debugLog(
        '🔄 DEBUG: Reloading workout $workoutId - Key: $storageKey - Data: $workoutData',
      );
      if (workoutData.isNotEmpty) {
        try {
          final workout = _deserializeWorkout(workoutData);
          userWorkouts.add(workout);
          _debugLog('✅ DEBUG: Reloaded workout: \\${workout.name}');
        } catch (e) {
          _debugLog('❌ DEBUG: Error reloading workout $workoutId: $e');
          final firebaseWorkout = await FirebaseService.getWorkout(workoutId);
          if (firebaseWorkout != null) {
            final workout = _workoutFromFirebaseMap(workoutId, firebaseWorkout);
            await _saveWorkoutToStorage(workout, syncFirebase: false);
            userWorkouts.add(workout);
            _debugLog(
              '✅ DEBUG: Reload fallback from Firebase: ${workout.name}',
            );
          }
        }
      } else {
        _debugLog(
          '❌ DEBUG: No data found for workout $workoutId during reload',
        );
        final firebaseWorkout = await FirebaseService.getWorkout(workoutId);
        if (firebaseWorkout != null) {
          final workout = _workoutFromFirebaseMap(workoutId, firebaseWorkout);
          await _saveWorkoutToStorage(workout, syncFirebase: false);
          userWorkouts.add(workout);
          _debugLog(
            '✅ DEBUG: Reloaded missing workout from Firebase: ${workout.name}',
          );
        }
      }
    }
    setState(() {
      _workouts = userWorkouts;
    });
  }

  Workout _workoutFromFirebaseMap(
    String workoutId,
    Map<String, dynamic> workoutData,
  ) {
    final rawExercises = workoutData['exercises'];
    final exercisesData = <Exercise>[];

    if (rawExercises is List) {
      for (final exerciseMap in rawExercises) {
        if (exerciseMap is! Map) continue;
        final data = Map<String, dynamic>.from(exerciseMap);
        exercisesData.add(Exercise.fromJson(data));
      }
    } else if (rawExercises is Map) {
      for (final exerciseMap in rawExercises.values) {
        if (exerciseMap is! Map) continue;
        final data = Map<String, dynamic>.from(exerciseMap);
        exercisesData.add(Exercise.fromJson(data));
      }
    }

    return Workout(
      id: workoutId,
      name: workoutData['name']?.toString() ?? 'Workout',
      date:
          DateTime.tryParse(workoutData['date']?.toString() ?? '') ??
          DateTime.now(),
      exercises: exercisesData,
      warmUp: workoutData['warmUp']?.toString(),
      coolDown: workoutData['coolDown']?.toString(),
      notes: workoutData['notes']?.toString(),
      feedback: workoutData['feedback']?.toString(),
      instructorReview: workoutData['instructorReview']?.toString(),
      clientName: workoutData['clientName']?.toString() ?? '',
      clientUsername:
          workoutData['clientUsername']?.toString() ?? _currentUserEmail ?? '',
      isCompleted: workoutData['isCompleted'] == true,
      isReviewedByInstructor: workoutData['isReviewedByInstructor'] == true,
      isReviewAcknowledged: workoutData['isReviewAcknowledged'] == true,
    );
  }

  Map<String, dynamic> _workoutToFirebaseMap(Workout workout) {
    final clientUid = _userRole == 'client'
        ? FirebaseService.currentUid ?? ''
        : '';
    return {
      'name': workout.name,
      'date': workout.date.toIso8601String(),
      'clientName': workout.clientName,
      'clientUsername': workout.clientUsername.isNotEmpty
          ? workout.clientUsername
          : (_userRole == 'client' ? _clientProfile.username : ''),
      'clientUid': clientUid,
      'warmUp': workout.warmUp,
      'coolDown': workout.coolDown,
      'notes': workout.notes,
      'feedback': workout.feedback,
      'instructorReview': workout.instructorReview,
      'isCompleted': workout.isCompleted,
      'isReviewedByInstructor': workout.isReviewedByInstructor,
      'isReviewAcknowledged': workout.isReviewAcknowledged,
      'exercises': workout.exercises
          .map((exercise) => exercise.toJson())
          .toList(),
    };
  }

  Workout _deserializeWorkout(String jsonStr) {
    // Split only the first 8 pipes to separate workout metadata from exercises
    // Format: id|name|timestamp|clientName|notes|exercisesJson|isCompleted|isReviewedByInstructor|feedback
    // But exercisesJson contains pipes too, so we can't split everything

    final firstPipeIndex = jsonStr.indexOf('|');
    if (firstPipeIndex == -1) {
      _debugLog('❌ DEBUG: No pipe found in workout data');
      return Workout(
        id: '',
        name: 'Workout',
        date: DateTime.now(),
        exercises: [],
      );
    }

    final id = jsonStr.substring(0, firstPipeIndex);
    var remaining = jsonStr.substring(firstPipeIndex + 1);

    final secondPipeIndex = remaining.indexOf('|');
    if (secondPipeIndex == -1) {
      return Workout(
        id: id,
        name: remaining,
        date: DateTime.now(),
        exercises: [],
      );
    }

    final name = remaining.substring(0, secondPipeIndex);
    remaining = remaining.substring(secondPipeIndex + 1);

    final thirdPipeIndex = remaining.indexOf('|');
    if (thirdPipeIndex == -1) {
      return Workout(id: id, name: name, date: DateTime.now(), exercises: []);
    }

    final dateStr = remaining.substring(0, thirdPipeIndex);
    remaining = remaining.substring(thirdPipeIndex + 1);

    final fourthPipeIndex = remaining.indexOf('|');
    if (fourthPipeIndex == -1) {
      return Workout(
        id: id,
        name: name,
        date: DateTime.fromMillisecondsSinceEpoch(int.tryParse(dateStr) ?? 0),
        exercises: [],
      );
    }

    final clientName = remaining.substring(0, fourthPipeIndex);
    remaining = remaining.substring(fourthPipeIndex + 1);

    final fifthPipeIndex = remaining.indexOf('|');
    if (fifthPipeIndex == -1) {
      return Workout(
        id: id,
        name: name,
        date: DateTime.fromMillisecondsSinceEpoch(int.tryParse(dateStr) ?? 0),
        clientName: clientName,
        exercises: [],
      );
    }

    final notes = remaining.substring(0, fifthPipeIndex);
    remaining = remaining.substring(fifthPipeIndex + 1);

    // Now find the next double semicolon or the last |true/false pattern to identify where exercises end
    // Format of remaining: exercisesJson|isCompleted|isReviewedByInstructor|feedback|instructorReview|isReviewAcknowledged
    // We need to find up to the last seven pipes to support
    // ...|isReviewAcknowledged|warmUp|coolDown payloads.
    final lastPipes = <int>[];
    for (int i = remaining.length - 1; i >= 0; i--) {
      if (remaining[i] == '|') {
        lastPipes.add(i);
        if (lastPipes.length == 7) break;
      }
    }

    String exercisesStr = '';
    bool isCompleted = false;
    bool isReviewedByInstructor = false;
    bool isReviewAcknowledged = false;
    String? feedback;
    String? instructorReview;
    String? warmUp;
    String? coolDown;

    if (lastPipes.length >= 7) {
      // New format with warmUp and coolDown at the end
      final lastPipeIdx = lastPipes[0]; // Before coolDown
      final secondLastPipeIdx = lastPipes[1]; // Before warmUp
      final thirdLastPipeIdx = lastPipes[2]; // Before isReviewAcknowledged
      final fourthLastPipeIdx = lastPipes[3]; // Before instructorReview
      final fifthLastPipeIdx = lastPipes[4]; // Before feedback
      final sixthLastPipeIdx = lastPipes[5]; // Before isReviewedByInstructor
      final seventhLastPipeIdx = lastPipes[6]; // Before isCompleted

      exercisesStr = remaining.substring(0, seventhLastPipeIdx);
      isCompleted =
          remaining.substring(seventhLastPipeIdx + 1, sixthLastPipeIdx) ==
          'true';
      isReviewedByInstructor =
          remaining.substring(sixthLastPipeIdx + 1, fifthLastPipeIdx) == 'true';

      feedback = remaining.substring(fifthLastPipeIdx + 1, fourthLastPipeIdx);
      if (feedback.isEmpty) feedback = null;

      instructorReview = remaining.substring(
        fourthLastPipeIdx + 1,
        thirdLastPipeIdx,
      );
      if (instructorReview.isEmpty) instructorReview = null;

      isReviewAcknowledged =
          remaining.substring(thirdLastPipeIdx + 1, secondLastPipeIdx) ==
          'true';

      warmUp = remaining.substring(secondLastPipeIdx + 1, lastPipeIdx);
      if (warmUp.isEmpty) warmUp = null;

      coolDown = remaining.substring(lastPipeIdx + 1);
      if (coolDown.isEmpty) coolDown = null;
    } else if (lastPipes.length >= 5) {
      // We found 5 pipes from the end
      final lastPipeIdx = lastPipes[0]; // Before isReviewAcknowledged
      final secondLastPipeIdx = lastPipes[1]; // Before instructorReview
      final thirdLastPipeIdx = lastPipes[2]; // Before feedback
      final fourthLastPipeIdx = lastPipes[3]; // Before isReviewedByInstructor
      final fifthLastPipeIdx = lastPipes[4]; // Before isCompleted

      exercisesStr = remaining.substring(0, fifthLastPipeIdx);
      isCompleted =
          remaining.substring(fifthLastPipeIdx + 1, fourthLastPipeIdx) ==
          'true';
      isReviewedByInstructor =
          remaining.substring(fourthLastPipeIdx + 1, thirdLastPipeIdx) ==
          'true';

      feedback = remaining.substring(thirdLastPipeIdx + 1, secondLastPipeIdx);
      if (feedback.isEmpty) feedback = null;

      instructorReview = remaining.substring(
        secondLastPipeIdx + 1,
        lastPipeIdx,
      );
      if (instructorReview.isEmpty) instructorReview = null;

      isReviewAcknowledged = remaining.substring(lastPipeIdx + 1) == 'true';
    } else if (lastPipes.length >= 4) {
      // Fallback for old format without isReviewAcknowledged
      final lastPipeIdx = lastPipes[0];
      final secondLastPipeIdx = lastPipes[1];
      final thirdLastPipeIdx = lastPipes[2];
      final fourthLastPipeIdx = lastPipes[3];

      exercisesStr = remaining.substring(0, fourthLastPipeIdx);
      isCompleted =
          remaining.substring(fourthLastPipeIdx + 1, thirdLastPipeIdx) ==
          'true';
      isReviewedByInstructor =
          remaining.substring(thirdLastPipeIdx + 1, secondLastPipeIdx) ==
          'true';

      feedback = remaining.substring(secondLastPipeIdx + 1, lastPipeIdx);
      if (feedback.isEmpty) feedback = null;

      instructorReview = remaining.substring(lastPipeIdx + 1);
      if (instructorReview.isEmpty) instructorReview = null;
    } else if (lastPipes.length >= 3) {
      // Even older format
      final lastPipeIdx = lastPipes[0];
      final secondLastPipeIdx = lastPipes[1];
      final thirdLastPipeIdx = lastPipes[2];

      exercisesStr = remaining.substring(0, thirdLastPipeIdx);
      isCompleted =
          remaining.substring(thirdLastPipeIdx + 1, secondLastPipeIdx) ==
          'true';
      isReviewedByInstructor =
          remaining.substring(secondLastPipeIdx + 1, lastPipeIdx) == 'true';

      feedback = remaining.substring(lastPipeIdx + 1);
      if (feedback.isEmpty) feedback = null;
    } else if (lastPipes.length >= 2) {
      // Even older format
      final lastPipeIdx = lastPipes[0];
      final secondLastPipeIdx = lastPipes[1];

      exercisesStr = remaining.substring(0, secondLastPipeIdx);
      isCompleted =
          remaining.substring(secondLastPipeIdx + 1, lastPipeIdx) == 'true';
      isReviewedByInstructor = remaining.substring(lastPipeIdx + 1) == 'true';
    } else {
      exercisesStr = remaining;
    }

    _debugLog('🔍 DEBUG: Deserializing workout - ID: $id, Name: $name');
    _debugLog('🔍 DEBUG: Exercises string: $exercisesStr');

    final exercises = <Exercise>[];
    if (exercisesStr.isNotEmpty &&
        exercisesStr != 'true' &&
        exercisesStr != 'false') {
      try {
        final decodedExercisesJson = utf8.decode(
          base64Url.decode(base64Url.normalize(exercisesStr)),
        );
        final decodedExercises =
            jsonDecode(decodedExercisesJson) as List<dynamic>;
        for (final exerciseMap in decodedExercises) {
          exercises.add(
            Exercise.fromJson(Map<String, dynamic>.from(exerciseMap as Map)),
          );
        }
        _debugLog(
          '✅ DEBUG: Parsed ${exercises.length} exercises from JSON payload',
        );
      } catch (_) {
        final exercisesList = exercisesStr.split(';;');
        _debugLog('🔍 DEBUG: Parsing ${exercisesList.length} legacy exercises');
        for (final exStr in exercisesList) {
          if (exStr.isNotEmpty) {
            final exParts = exStr.split('|');
            _debugLog(
              '🔍 DEBUG: Legacy exercise parts (${exParts.length}): $exParts',
            );
            if (exParts.length >= 4) {
              exercises.add(
                Exercise(
                  name: exParts[0],
                  type: 'strength',
                  sets: int.tryParse(exParts[1]),
                  reps: int.tryParse(exParts[2]),
                  weight: double.tryParse(exParts[3]),
                  notes: exParts.length > 4 && exParts[4].isNotEmpty
                      ? exParts[4]
                      : null,
                ),
              );
            }
          }
        }
      }
    }
    _debugLog('✅ DEBUG: Total exercises parsed: ${exercises.length}');

    final date = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(dateStr) ?? 0,
    );

    return Workout(
      id: id,
      name: name,
      date: date,
      exercises: exercises,
      warmUp: warmUp,
      coolDown: coolDown,
      notes: notes,
      feedback: feedback,
      instructorReview: instructorReview,
      clientName: clientName,
      clientUsername: _currentUserEmail ?? '',
      isCompleted: isCompleted,
      isReviewedByInstructor: isReviewedByInstructor,
      isReviewAcknowledged: isReviewAcknowledged,
    );
  }

  Future<void> _loadAllWorkouts() async {
    final allWorkouts = <Workout>[];

    // Get all registered client emails
    final clientsList = await StorageHelper.getString('clients_list') ?? '';
    if (clientsList.isEmpty) {
      setState(() {
        _workouts = [];
      });
      return;
    }

    final usernames = clientsList.split(',');
    _debugLog(
      '🔍 DEBUG: Loading workouts for instructor from \\${usernames.length} clients',
    );

    for (final username in usernames) {
      if (username.isEmpty) continue;

      // Get workout IDs for this client
      final workoutListKey = 'workouts_$username';
      final workoutIdsStr = await StorageHelper.getString(workoutListKey) ?? '';
      final workoutIds = workoutIdsStr
          .split(',')
          .where((id) => id.isNotEmpty)
          .toList();
      _debugLog(
        '🔍 DEBUG: Client $username has \\${workoutIds.length} workouts',
      );

      for (final workoutId in workoutIds) {
        final firebaseWorkout = await FirebaseService.getWorkout(workoutId);

        if (firebaseWorkout != null) {
          final workout = _workoutFromFirebaseMap(workoutId, firebaseWorkout);
          await _saveWorkoutToStorage(workout, syncFirebase: false);
          allWorkouts.add(workout);
          continue;
        }

        final storageKey = 'workout_$workoutId';
        final workoutData = await StorageHelper.getString(storageKey) ?? '';
        if (workoutData.isNotEmpty) {
          try {
            final workout = _deserializeWorkout(workoutData);
            allWorkouts.add(workout);
            _debugLog(
              '✅ DEBUG: Loaded workout (local): \\${workout.name} for \\${workout.clientName}',
            );
          } catch (e) {
            _debugLog('❌ DEBUG: Error loading workout $workoutId: $e');
          }
        }
      }
    }

    _debugLog(
      '✅ DEBUG: Total workouts loaded for instructor: \\${allWorkouts.length}',
    );

    setState(() {
      _workouts = allWorkouts;
    });
  }

  Future<void> _saveWorkoutToStorage(
    Workout workout, {
    bool syncFirebase = true,
  }) async {
    final exercisesJson = workout.exercises.map((e) => e.toJson()).toList();
    final encodedExercises = base64Url.encode(
      utf8.encode(jsonEncode(exercisesJson)),
    );

    final workoutJson =
        '${workout.id}|${workout.name}|${workout.date.millisecondsSinceEpoch}|${workout.clientName}|${workout.notes ?? ''}|$encodedExercises|${workout.isCompleted}|${workout.isReviewedByInstructor}|${workout.feedback ?? ''}|${workout.instructorReview ?? ''}|${workout.isReviewAcknowledged}|${workout.warmUp ?? ''}|${workout.coolDown ?? ''}';

    _debugLog(
      '✅ DEBUG (main): Saving workout ${workout.id} with ${workout.exercises.length} exercises',
    );
    _debugLog('✅ DEBUG (main): Encoded exercises payload saved');

    // Save to localStorage and optionally sync to Firebase.
    await StorageHelper.setString('workout_${workout.id}', workoutJson);
    if (syncFirebase) {
      await FirebaseService.saveWorkout(
        workout.id,
        _workoutToFirebaseMap(workout),
      );
    }
    _debugLog('✅ DEBUG: Saved workout ${workout.id} to localStorage');
  }

  Future<void> _triggerSplash() async {
    if (!_showSplash) {
      setState(() {
        _showSplash = true;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        await _splashController.forward();
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
        }
        _splashController.reset();
      }
    }
  }

  Future<void> _onRoleSelected(String role) async {
    await _triggerSplash();
    setState(() {
      _userRole = role;
    });
    if (role == 'instructor') {
      _loadAllWorkouts();
    }
  }

  Future<void> _onClientLogin(String email) async {
    await _triggerSplash();
    _loadUserData(email);
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent;
    if (_userRole == null) {
      mainContent = LoginScreen(
        onRoleSelected: _onRoleSelected,
        onClientLogin: _onClientLogin,
      );
    } else if (_userRole == 'instructor') {
      mainContent = InstructorDashboardScreen(
        onLogout: () {
          print('🚪 Logging out instructor...');
          setState(() {
            _userRole = null;
            _currentUserEmail = null;
          });
          print(
            '✅ Instructor logged out, _userRole=$_userRole, _currentUserEmail=$_currentUserEmail',
          );
        },
      );
    } else {
      mainContent = MainNavigation(
        isInstructor: _userRole == 'instructor',
        onLogout: () {
          print('🚪 Logging out client...');
          _clientProfileSubscription?.cancel();
          _clientProfileSubscription = null;
          for (final subscription in _clientWorkoutSubscriptions) {
            subscription.cancel();
          }
          _clientWorkoutSubscriptions.clear();
          setState(() {
            _userRole = null;
            _currentUserEmail = null;
          });
          print(
            '✅ Client logged out, _userRole=$_userRole, _currentUserEmail=$_currentUserEmail',
          );
        },
        currentUserEmail: _currentUserEmail,
        clientProfile: _clientProfile,
        workouts: _workouts,
        onWorkoutUpdated: (updatedWorkout) async {
          setState(() {
            final index = _workouts.indexWhere(
              (w) => w.id == updatedWorkout.id,
            );
            if (index != -1) {
              _workouts[index] = updatedWorkout;
            }
          });
          await _saveWorkoutToStorage(updatedWorkout);
        },
        onProfileUpdated: (profile) async {
          setState(() {
            _clientProfile = profile;
          });
          await _persistProfile(profile);
        },
      );
    }

    if (_showSplash) {
      return Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            color: Colors.white,
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/logo.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        mainContent,
        if (_isLoadingUser)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.85),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class MainNavigation extends StatefulWidget {
  final VoidCallback onLogout;
  final String? currentUserEmail;
  final ClientProfile clientProfile;
  final Function(ClientProfile) onProfileUpdated;
  final List<Workout> workouts;
  final Function(Workout) onWorkoutUpdated;
  final bool isInstructor;

  const MainNavigation({
    super.key,
    required this.onLogout,
    required this.currentUserEmail,
    required this.clientProfile,
    required this.onProfileUpdated,
    required this.workouts,
    required this.onWorkoutUpdated,
    required this.isInstructor,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        workouts: widget.workouts,
        clientProfile: widget.clientProfile,
        onWorkoutUpdated: widget.onWorkoutUpdated,
      ),
      ClientProfileScreen(
        profile: widget.clientProfile,
        onProfileUpdated: widget.onProfileUpdated,
        isInstructor: widget.isInstructor,
        onLogout: widget.onLogout,
      ),
      WorkoutHistoryScreen(workouts: widget.workouts),
      ProgressScreen(
        workouts: widget.workouts,
        clientProfile: widget.clientProfile,
        onProfileUpdated: widget.onProfileUpdated,
      ),
      const WorkoutOfWeekScreen(),
      const ExerciseLibraryScreen(),
      const StretchingScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF2563EB),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            label: 'Home',
            icon: Builder(
              builder: (context) {
                final pendingCount = widget.workouts
                    .where(
                      (w) =>
                          w.isReviewedByInstructor &&
                          !w.isReviewAcknowledged &&
                          w.instructorReview != null &&
                          w.instructorReview!.isNotEmpty,
                    )
                    .length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.home),
                    if (pendingCount > 0)
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
                            '$pendingCount',
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
                );
              },
            ),
          ),
          BottomNavigationBarItem(
            label: 'Profile',
            icon: Icon(
              Icons.person,
              color: widget.currentUserEmail != null &&
                      widget.currentUserEmail!.isNotEmpty &&
                      widget.clientProfile.username.isNotEmpty &&
                      widget.clientProfile.username != widget.currentUserEmail
                  ? Colors.orange
                  : null,
            ),
          ),
          const BottomNavigationBarItem(
            label: 'History',
            icon: Icon(Icons.history),
          ),
          const BottomNavigationBarItem(
            label: 'Progress',
            icon: Icon(Icons.timeline),
          ),
          const BottomNavigationBarItem(
            label: 'Workout of Week',
            icon: Icon(Icons.star),
          ),
          const BottomNavigationBarItem(
            label: 'Exercise Library',
            icon: Icon(Icons.fitness_center),
          ),
          const BottomNavigationBarItem(
            label: 'Stretching',
            icon: Icon(Icons.self_improvement),
          ),
        ],
      ),
    );
  }
}
