import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/client_profile.dart';
import 'security_helper.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? lastAuthError;

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Sign-out cleanup should never block UI flow.
    }
  }

  static bool get _isProductionEnv {
    const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final normalized = appEnv.trim().toLowerCase();
    return normalized == 'prod' || normalized == 'production';
  }

  static bool _isPermissionDeniedError(Object error) {
    return error is FirebaseException && error.code == 'permission-denied';
  }

  static Future<bool> _refreshAuthTokenIfPossible() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.getIdToken(true);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _shouldTryCreateAfterSignInError(String code) {
    return code == 'user-not-found' ||
        code == 'invalid-credential' ||
        code == 'invalid-login-credentials';
  }

  static String? get currentUid => _auth.currentUser?.uid;

  static String _clientAuthEmailFromUsername(String username) {
    final normalized = username.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]'),
      '_',
    );
    if (normalized.isEmpty) {
      return 'client_unknown@client.sim-training.local';
    }
    return '$normalized@client.sim-training.local';
  }

  static String _displayNameFromClientEmail(String email) {
    final localPart = email.split('@').first;
    if (localPart.isEmpty) return 'client_unknown';
    return localPart;
  }

  static Future<void> _ensureUserMappings({
    required String username,
    required String role,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final trimmedUsername = username.trim();
    final usernameKey = _firebasePathKey(trimmedUsername);
    final loweredUsername = trimmedUsername.toLowerCase();
    final loweredUsernameKey = _firebasePathKey(loweredUsername);

    Future<void> writeIfMissing(String path, Object value) async {
      final ref = _database.ref(path);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        await ref.set(value);
      }
    }

    try {
      // These mappings are immutable after first write by design.
      await writeIfMissing('usernameToUid/$usernameKey', uid);
      if (loweredUsername.isNotEmpty && loweredUsernameKey != usernameKey) {
        await writeIfMissing('usernameToUid/$loweredUsernameKey', uid);
      }
      await writeIfMissing('uidToUsername/$uid', trimmedUsername);

      // Role write can be denied by strict rules; do not block login on that.
      if (role == 'instructor') {
        await writeIfMissing('roles/$uid', role);
      }
    } on FirebaseException catch (e) {
      debugPrint('Mapping write skipped (${e.code}): ${e.message}');
    } catch (e) {
      debugPrint('Mapping write skipped: $e');
    }
  }

  static Future<String?> getCurrentUsername() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snapshot = await _database.ref('uidToUsername/$uid').get();
    if (snapshot.exists && snapshot.value is String) {
      return snapshot.value as String;
    }
    final email = _auth.currentUser?.email;
    if (email != null && email.endsWith('@client.sim-training.local')) {
      return _displayNameFromClientEmail(email);
    }
    return null;
  }

  static Future<String?> getUidForUsername(String username) async {
    final trimmed = username.trim();
    final candidateKeys = <String>{trimmed};
    final lowered = trimmed.toLowerCase();
    if (lowered.isNotEmpty) {
      candidateKeys.add(lowered);
    }

    for (final candidate in candidateKeys) {
      final usernameKey = _firebasePathKey(candidate);
      final snapshot = await _database.ref('usernameToUid/$usernameKey').get();
      if (snapshot.exists && snapshot.value is String) {
        return snapshot.value as String;
      }
    }
    return null;
  }

  static Future<bool> signInOrCreateClientAuth(
    String username,
    String password,
  ) async {
    lastAuthError = null;
    try {
      await initialize();
      final email = _clientAuthEmailFromUsername(username);
      final existingUser = _auth.currentUser;
      if (existingUser != null && existingUser.email != email) {
        await _auth.signOut();
      }
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _auth.currentUser?.getIdToken(true);
        await _ensureUserMappings(username: username, role: 'client');
        return true;
      } on FirebaseAuthException catch (e) {
        if (_shouldTryCreateAfterSignInError(e.code)) {
          try {
            await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            await _auth.currentUser?.getIdToken(true);
            await _ensureUserMappings(username: username, role: 'client');
            return true;
          } on FirebaseAuthException catch (createError) {
            lastAuthError = createError.code;
            return false;
          }
        }
        if (e.code == 'wrong-password') {
          lastAuthError = e.code;
          return false;
        }
        lastAuthError = e.code;
        return false;
      }
    } catch (e) {
      lastAuthError = e.toString();
      return false;
    }
  }

  static Future<bool> signInInstructorAuth(
    String email,
    String password,
  ) async {
    lastAuthError = null;
    try {
      await initialize();
      final existingUser = _auth.currentUser;
      if (existingUser != null && existingUser.email != email) {
        await _auth.signOut();
      }
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _auth.currentUser?.getIdToken(true);
        await _ensureUserMappings(username: email.trim(), role: 'instructor');
        return true;
      } on FirebaseAuthException catch (e) {
        if (_shouldTryCreateAfterSignInError(e.code)) {
          try {
            await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            await _auth.currentUser?.getIdToken(true);
            await _ensureUserMappings(
              username: email.trim(),
              role: 'instructor',
            );
            return true;
          } on FirebaseAuthException catch (createError) {
            lastAuthError = createError.code;
            return false;
          }
        }
        if (e.code == 'wrong-password') {
          lastAuthError = e.code;
          return false;
        }
        lastAuthError = e.code;
        return false;
      }
    } catch (e) {
      lastAuthError = e.toString();
      return false;
    }
  }

  static Future<void> updateCurrentAuthPassword(String newPassword) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await currentUser.updatePassword(newPassword);
  }

  static Future<Map<String, dynamic>> runUidBackfill() async {
    await initialize();

    final db = _database.ref();
    final uidCache = <String, String?>{};
    final unresolvedUsernames = <String>{};

    Future<String?> uidFor(String username) async {
      final key = username.trim();
      if (key.isEmpty) return null;
      if (uidCache.containsKey(key)) return uidCache[key];
      final uid = await getUidForUsername(key);
      uidCache[key] = uid;
      return uid;
    }

    var workoutsUpdated = 0;
    var restDaysUpdated = 0;
    var profilesCopiedToUid = 0;
    var usersCopiedToUid = 0;

    final workoutsSnapshot = await db.child('workouts').get();
    if (workoutsSnapshot.exists && workoutsSnapshot.value is Map) {
      final workouts = Map<String, dynamic>.from(workoutsSnapshot.value as Map);
      for (final entry in workouts.entries) {
        if (entry.value is! Map) continue;
        final workoutId = entry.key;
        final workout = Map<String, dynamic>.from(entry.value as Map);

        final existingUid = workout['clientUid']?.toString().trim() ?? '';
        if (existingUid.isNotEmpty) continue;

        final username = (workout['clientUsername']?.toString() ?? '').trim();
        final fallbackName = (workout['clientName']?.toString() ?? '').trim();
        final owner = username.isNotEmpty ? username : fallbackName;
        if (owner.isEmpty) continue;

        final uid = await uidFor(owner);
        if (uid == null || uid.isEmpty) {
          unresolvedUsernames.add(owner);
          continue;
        }

        await db.child('workouts/$workoutId/clientUid').set(uid);
        workoutsUpdated++;
      }
    }

    final restDaysSnapshot = await db.child('restDays').get();
    if (restDaysSnapshot.exists && restDaysSnapshot.value is Map) {
      final restDays = Map<String, dynamic>.from(restDaysSnapshot.value as Map);
      for (final entry in restDays.entries) {
        if (entry.value is! Map) continue;
        final restDayId = entry.key;
        final restDay = Map<String, dynamic>.from(entry.value as Map);

        final existingUid = restDay['clientUid']?.toString().trim() ?? '';
        if (existingUid.isNotEmpty) continue;

        final username = (restDay['clientUsername']?.toString() ?? '').trim();
        final fallbackName = (restDay['clientName']?.toString() ?? '').trim();
        final owner = username.isNotEmpty ? username : fallbackName;
        if (owner.isEmpty) continue;

        final uid = await uidFor(owner);
        if (uid == null || uid.isEmpty) {
          unresolvedUsernames.add(owner);
          continue;
        }

        await db.child('restDays/$restDayId/clientUid').set(uid);
        restDaysUpdated++;
      }
    }

    final clients = await getClientsList();
    for (final username in clients) {
      final trimmed = username.trim();
      if (trimmed.isEmpty) continue;

      final uid = await uidFor(trimmed);
      if (uid == null || uid.isEmpty) {
        unresolvedUsernames.add(trimmed);
        continue;
      }

      final profileLegacy = await db
          .child('profiles/${_firebasePathKey(trimmed)}')
          .get();
      final profileUid = await db.child('profiles/$uid').get();
      if (profileLegacy.exists &&
          !profileUid.exists &&
          profileLegacy.value is Map) {
        final data = Map<String, dynamic>.from(profileLegacy.value as Map);
        data['uid'] = uid;
        data['username'] = (data['username']?.toString() ?? trimmed).trim();
        await db.child('profiles/$uid').set(data);
        profilesCopiedToUid++;
      }

      final userLegacy = await db
          .child('users/${_firebasePathKey(trimmed)}')
          .get();
      final userUid = await db.child('users/$uid').get();
      if (userLegacy.exists && !userUid.exists) {
        await db.child('users/$uid').set(userLegacy.value);
        usersCopiedToUid++;
      }
    }

    final unresolved = unresolvedUsernames.toList()..sort();
    return {
      'workoutsUpdated': workoutsUpdated,
      'restDaysUpdated': restDaysUpdated,
      'profilesCopiedToUid': profilesCopiedToUid,
      'usersCopiedToUid': usersCopiedToUid,
      'unresolvedCount': unresolved.length,
      'unresolved': unresolved,
    };
  }

  /// Delete all clients and their profiles, users, and clear clients list
  static Future<void> deleteAllClients() async {
    try {
      final clients = await getClientsList();
      for (final username in clients) {
        await deleteUser(username);
        await deleteClientProfile(username);
      }
      await saveClientsList([]);
      print('✅ All clients deleted');
    } catch (e) {
      print('❌ Error deleting all clients: $e');
    }
  }

  /// Delete all workouts from Firebase
  static Future<void> deleteAllWorkouts() async {
    try {
      final snapshot = await _database.ref('workouts').get();
      if (snapshot.exists) {
        final workoutsMap = Map<String, dynamic>.from(snapshot.value as Map);
        for (final id in workoutsMap.keys) {
          await deleteWorkout(id);
        }
      }
      print('✅ All workouts deleted');
    } catch (e) {
      print('❌ Error deleting all workouts: $e');
    }
  }

  /// Sync all exercises to Firebase under 'exerciseLibrary/'
  static Future<void> syncExerciseLibraryToFirebase(
    List exerciseLibrary,
  ) async {
    try {
      final data = exerciseLibrary.map((e) => e.toJson()).toList();
      await _database.ref('exerciseLibrary').set(data);
      print('✅ Synced exercise library to Firebase');
    } catch (e) {
      print('❌ Error syncing exercise library: $e');
    }
  }

  /// Sync all stretches to Firebase under 'stretchingLibrary/'
  static Future<void> syncStretchingLibraryToFirebase(
    List stretchingLibrary,
  ) async {
    try {
      final data = stretchingLibrary.map((e) => e.toJson()).toList();
      await _database.ref('stretchingLibrary').set(data);
      print('✅ Synced stretching library to Firebase');
    } catch (e) {
      print('❌ Error syncing stretching library: $e');
    }
  }

  /// Store/update the FCM token for a user (call this after login or token refresh)
  static Future<void> saveUserToken(String userId, String token) async {
    final database = FirebaseDatabase.instance;
    final uidFromUsername = await getUidForUsername(userId);
    final uid = uidFromUsername ?? currentUid;
    if (uid != null) {
      await database.ref('users/$uid').update({
        'fcmToken': token,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    await database.ref('users/$userId').update({
      'fcmToken': token,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Sends a notification to a client: saves to database and optionally sends push notification.
  static Future<void> sendNotification(
    String clientId,
    String message, {
    bool celebration = false,
  }) async {
    // Generate a notification ID
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    // Build notification data
    final notificationData = {
      'title': 'Message from Instructor',
      'message': message,
      'date': DateTime.now().toIso8601String(),
      'acknowledged': false,
      'type': 'message',
      'celebration': celebration,
      'mediaUrl': null,
    };
    // Save notification to client's notifications in database
    await FirebaseService.addNotificationToClient(
      clientId: clientId,
      notification: ClientNotification(
        id: notificationId,
        title: notificationData['title'] as String,
        message: notificationData['message'] as String,
        date: DateTime.now(),
        acknowledged: false,
        type: 'message',
        celebration: celebration,
        mediaUrl: null,
      ),
    );

    // Send push notification if FCM token is available
    final profile = await getClientProfile(clientId);
    final token = profile?['fcmToken'];
    if (token != null && token is String && token.isNotEmpty) {
      await sendPushNotification(
        title: notificationData['title'] as String,
        body: message,
        token: token,
      );
    }
  }

  /// Adds a new client to the clients list and creates a minimal profile with username and password.
  static Future<void> addClient(
    String name,
    String username,
    String password,
  ) async {
    // Get current clients list
    final clients = await getClientsList();
    if (!clients.contains(username)) {
      clients.add(username);
      await saveClientsList(clients);
      // Save user credentials
      final hashedPassword = SecurityHelper.hashPassword(password, username);
      await saveUser(username, hashedPassword);
      // Create a minimal profile for the new client
      await saveClientProfile(username, {
        'username': username,
        'name': name,
        'email': '',
        'isSuspended': false,
        'notifications': [],
        'strengthPRs': {},
        'bodyMeasurementsCm': {},
        'illnessDays': [],
        'restDays': [],
      });
    }
  }

  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static bool _initialized = false;
  static bool _appCheckInitialized = false;
  static final RegExp _invalidKeyChars = RegExp(r'[.#$\[\]/]');

  static Future<void> _activateAppCheckIfNeeded() async {
    if (_appCheckInitialized) return;
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
          return;
        }
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider(webSiteKey),
        );
        _appCheckInitialized = true;
        return;
      }

      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
      _appCheckInitialized = true;
    } catch (e) {
      if (_isProductionEnv) {
        rethrow;
      }
      debugPrint('App Check activation skipped: $e');
    }
  }

  // Add a reaction to a notification
  static Future<void> addNotificationReaction({
    required String clientId,
    required String notificationId,
    required String emoji,
  }) async {
    final ref = _database
        .ref()
        .child('clients')
        .child(clientId)
        .child('notifications')
        .child(notificationId)
        .child('reactions');
    final snapshot = await ref.get();
    List<dynamic> reactions = [];
    if (snapshot.exists) {
      reactions = List<dynamic>.from(snapshot.value as List);
    }
    reactions.add(emoji);
    await ref.set(reactions);
  }

  // Add a reply to a notification
  static Future<void> addNotificationReply({
    required String clientId,
    required String notificationId,
    required String user,
    required String message,
  }) async {
    final ref = _database
        .ref()
        .child('clients')
        .child(clientId)
        .child('notifications')
        .child(notificationId)
        .child('replies');
    final snapshot = await ref.get();
    List<dynamic> replies = [];
    if (snapshot.exists) {
      replies = List<dynamic>.from(snapshot.value as List);
    }
    replies.add({
      'user': user,
      'message': message,
      'date': DateTime.now().toIso8601String(),
    });
    await ref.set(replies);
  }

  static String _firebasePathKey(String rawKey) {
    if (rawKey.isEmpty || !_invalidKeyChars.hasMatch(rawKey)) {
      return rawKey;
    }

    final encoded = base64Url.encode(utf8.encode(rawKey)).replaceAll('=', '');
    return '__enc__$encoded';
  }

  static DatabaseReference? _structuredStorageRefForKey(String key) {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) return null;

    if (trimmedKey == _loginQuoteKey) {
      return _database.ref('storage/loginQuote/text');
    }

    if (trimmedKey.startsWith('workouts_')) {
      final owner = trimmedKey.substring('workouts_'.length).trim();
      if (owner.isEmpty) return null;
      return _database.ref('storage/workoutIndexes/${_firebasePathKey(owner)}');
    }

    if (trimmedKey.startsWith('workout_')) {
      final workoutId = trimmedKey.substring('workout_'.length).trim();
      if (workoutId.isEmpty) return null;
      return _database.ref(
        'storage/workoutPayloads/${_firebasePathKey(workoutId)}',
      );
    }

    if (trimmedKey.startsWith('workout_notifications_')) {
      final owner = trimmedKey
          .substring('workout_notifications_'.length)
          .trim();
      if (owner.isEmpty) return null;
      return _database.ref(
        'storage/workoutNotifications/${_firebasePathKey(owner)}',
      );
    }

    return null;
  }

  static Set<String> _workoutIndexOwners(String owner) {
    final trimmedOwner = owner.trim();
    if (trimmedOwner.isEmpty) return const <String>{};

    final owners = <String>{trimmedOwner};
    final loweredOwner = trimmedOwner.toLowerCase();
    if (loweredOwner.isNotEmpty) {
      owners.add(loweredOwner);
    }
    return owners;
  }

  static Future<void> rebuildWorkoutIndexes({
    List<Map<String, dynamic>>? workouts,
  }) async {
    try {
      final workoutMaps = workouts ?? await getAllWorkouts();
      final workoutIdsByOwner = <String, Set<String>>{};

      for (final workout in workoutMaps) {
        final workoutId = (workout['id'] ?? '').toString().trim();
        if (workoutId.isEmpty) continue;

        final clientUsername = (workout['clientUsername'] ?? '')
            .toString()
            .trim();
        final clientName = (workout['clientName'] ?? '').toString().trim();
        final listOwner = clientUsername.isNotEmpty
            ? clientUsername
            : clientName;
        if (listOwner.isEmpty) continue;

        for (final owner in _workoutIndexOwners(listOwner)) {
          final ownerKey = _firebasePathKey(owner);
          workoutIdsByOwner
              .putIfAbsent(ownerKey, () => <String>{})
              .add(workoutId);
        }
      }

      final serializedIndexes = <String, String>{};
      for (final entry in workoutIdsByOwner.entries) {
        final workoutIds = entry.value.toList()..sort();
        serializedIndexes[entry.key] = workoutIds.join(',');
      }

      final indexesRef = _database.ref('storage/workoutIndexes');
      if (serializedIndexes.isEmpty) {
        await indexesRef.remove();
      } else {
        await indexesRef.set(serializedIndexes);
      }
    } catch (e) {
      print('Error rebuilding workout indexes in Firebase: $e');
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        if (kIsWeb) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "AIzaSyCZo87fb6es_XzacIj-sJNWxS5KtpvNXiM",
              authDomain: "sim-training-55d86.firebaseapp.com",
              databaseURL:
                  "https://sim-training-55d86-default-rtdb.firebaseio.com",
              projectId: "sim-training-55d86",
              storageBucket: "sim-training-55d86.firebasestorage.app",
              messagingSenderId: "1050830167472",
              appId: "1:1050830167472:web:825a1a286346b376318a75",
            ),
          );
        } else {
          await Firebase.initializeApp();
        }
      }

      await _activateAppCheckIfNeeded();
      _initialized = true;
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('⚠️ Firebase initialization error: $e');
      // Continue without Firebase - app will work locally only
    }
  }

  // Real-time streams for listening to changes
  static Stream<DatabaseEvent> watchClientProfile(String username) async* {
    await initialize();

    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      yield* _database.ref('profiles').onValue;
      return;
    }

    final uid = await getUidForUsername(trimmed);
    if (uid != null && uid.isNotEmpty) {
      yield* _database.ref('profiles/$uid').onValue;
      return;
    }

    final legacyKey = _firebasePathKey(trimmed);
    yield* _database.ref('profiles/$legacyKey').onValue;
  }

  static Stream<DatabaseEvent> watchWorkout(String workoutId) {
    return _database.ref('workouts/$workoutId').onValue;
  }

  static Stream<DatabaseEvent> watchAllWorkouts() {
    return _database.ref('workouts').onValue;
  }

  static Stream<DatabaseEvent> watchWorkoutIndex(String username) {
    final trimmed = username.trim();
    return _database
        .ref('storage/workoutIndexes/${_firebasePathKey(trimmed)}')
        .onValue;
  }

  static Stream<DatabaseEvent> watchClientsList() {
    return _database.ref('clientsList').onValue;
  }

  // User authentication data
  static Future<void> saveUser(String username, String password) async {
    try {
      final uid = await getUidForUsername(username);
      final userKey = _firebasePathKey(username);
      final data = {
        'password': password,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (uid != null) {
        await _database.ref('users/$uid').set(data);
      }
      await _database.ref('users/$userKey').set(data);
    } catch (e) {
      print('Error saving user to Firebase: $e');
    }
  }

  static Future<String?> getUser(String username) async {
    try {
      final uid = await getUidForUsername(username);
      if (uid != null) {
        final uidSnapshot = await _database.ref('users/$uid/password').get();
        if (uidSnapshot.exists) {
          return uidSnapshot.value as String;
        }
      }
      final userKey = _firebasePathKey(username);
      final snapshot = await _database.ref('users/$userKey/password').get();
      if (snapshot.exists) {
        return snapshot.value as String;
      }

      final lowered = username.trim().toLowerCase();
      if (lowered.isNotEmpty && lowered != username.trim()) {
        final loweredUserKey = _firebasePathKey(lowered);
        final loweredSnapshot = await _database
            .ref('users/$loweredUserKey/password')
            .get();
        if (loweredSnapshot.exists) {
          return loweredSnapshot.value as String;
        }
      }

      final wanted = username.trim().toLowerCase();

      final uidToUsernameSnapshot = await _database.ref('uidToUsername').get();
      if (uidToUsernameSnapshot.exists && uidToUsernameSnapshot.value is Map) {
        final uidToUsername = Map<String, dynamic>.from(
          uidToUsernameSnapshot.value as Map,
        );
        for (final entry in uidToUsername.entries) {
          final mappedUsername = (entry.value ?? '')
              .toString()
              .trim()
              .toLowerCase();
          if (mappedUsername != wanted) continue;

          final mappedUid = entry.key.trim();
          if (mappedUid.isEmpty) continue;

          final mappedUidSnapshot = await _database
              .ref('users/$mappedUid/password')
              .get();
          if (mappedUidSnapshot.exists) {
            return mappedUidSnapshot.value as String;
          }
        }
      }

      final allUsersSnapshot = await _database.ref('users').get();
      if (allUsersSnapshot.exists && allUsersSnapshot.value is Map) {
        final allUsers = Map<String, dynamic>.from(
          allUsersSnapshot.value as Map,
        );
        for (final entry in allUsers.entries) {
          if (entry.key.trim().toLowerCase() != wanted) continue;
          if (entry.value is! Map) continue;

          final userData = Map<String, dynamic>.from(entry.value as Map);
          final passwordValue = userData['password'];
          if (passwordValue is String && passwordValue.isNotEmpty) {
            return passwordValue;
          }
        }
      }

      final allProfilesSnapshot = await _database.ref('profiles').get();
      if (allProfilesSnapshot.exists && allProfilesSnapshot.value is Map) {
        final allProfiles = Map<String, dynamic>.from(
          allProfilesSnapshot.value as Map,
        );
        for (final entry in allProfiles.entries) {
          if (entry.value is! Map) continue;

          final profileData = Map<String, dynamic>.from(entry.value as Map);
          final profileUsername = (profileData['username'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          if (profileUsername != wanted) continue;

          final profileKey = entry.key.trim();
          if (profileKey.isEmpty) continue;

          final profileUserSnapshot = await _database
              .ref('users/$profileKey/password')
              .get();
          if (profileUserSnapshot.exists) {
            return profileUserSnapshot.value as String;
          }
        }
      }
    } catch (e) {
      print('Error getting user from Firebase: $e');
    }
    return null;
  }

  static Future<void> deleteUser(String username) async {
    try {
      final uid = await getUidForUsername(username);
      if (uid != null) {
        await _database.ref('users/$uid').remove();
      }
      final userKey = _firebasePathKey(username);
      await _database.ref('users/$userKey').remove();
    } catch (e) {
      print('Error deleting user from Firebase: $e');
    }
  }

  // Client profiles
  static Future<void> saveClientProfile(
    String username,
    Map<String, dynamic> profile,
  ) async {
    try {
      final uid = await getUidForUsername(username);
      final profileKey = uid ?? _firebasePathKey(username);
      final existingSnapshot = await _database
          .ref('profiles/$profileKey')
          .get();
      final existingProfile =
          existingSnapshot.exists && existingSnapshot.value is Map
          ? Map<String, dynamic>.from(existingSnapshot.value as Map)
          : <String, dynamic>{};
      await _database.ref('profiles/$profileKey').set({
        ...existingProfile,
        ...profile,
        'uid': ?uid,
        'username': profile['username']?.toString() ?? username,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final legacyKey = _firebasePathKey(username);
      if (uid != null && legacyKey != uid) {
        await _database.ref('profiles/$legacyKey').set({
          ...existingProfile,
          ...profile,
          'uid': uid,
          'username': profile['username']?.toString() ?? username,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving profile to Firebase: $e');
    }
  }

  static Future<Map<String, dynamic>?> getClientProfile(String username) async {
    try {
      final uid = await getUidForUsername(username);
      if (uid != null) {
        final uidSnapshot = await _database.ref('profiles/$uid').get();
        if (uidSnapshot.exists) {
          return Map<String, dynamic>.from(uidSnapshot.value as Map);
        }
      }
      final userKey = _firebasePathKey(username);
      final snapshot = await _database.ref('profiles/$userKey').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }

      // Fallback for partially migrated data where profile is keyed by UID
      // but usernameToUid mapping is missing.
      final allProfilesSnapshot = await _database.ref('profiles').get();
      if (allProfilesSnapshot.exists && allProfilesSnapshot.value is Map) {
        final allProfiles = Map<String, dynamic>.from(
          allProfilesSnapshot.value as Map,
        );
        final wanted = username.trim().toLowerCase();
        for (final entry in allProfiles.entries) {
          if (entry.value is! Map) continue;
          final data = Map<String, dynamic>.from(entry.value as Map);
          final profileUsername = (data['username']?.toString() ?? '')
              .trim()
              .toLowerCase();
          if (profileUsername == wanted) {
            return data;
          }
        }
      }
    } catch (e) {
      if (_isPermissionDeniedError(e) && await _refreshAuthTokenIfPossible()) {
        try {
          final uid = await getUidForUsername(username);
          if (uid != null) {
            final uidSnapshot = await _database.ref('profiles/$uid').get();
            if (uidSnapshot.exists) {
              return Map<String, dynamic>.from(uidSnapshot.value as Map);
            }
          }
          final userKey = _firebasePathKey(username);
          final snapshot = await _database.ref('profiles/$userKey').get();
          if (snapshot.exists) {
            return Map<String, dynamic>.from(snapshot.value as Map);
          }
        } catch (_) {
          // Fall through to the main error log below.
        }
      }
      print('Error getting profile from Firebase: $e');
    }
    return null;
  }

  static Future<void> deleteClientProfile(String username) async {
    try {
      final uid = await getUidForUsername(username);
      if (uid != null) {
        await _database.ref('profiles/$uid').remove();
      }
      final userKey = _firebasePathKey(username);
      await _database.ref('profiles/$userKey').remove();
    } catch (e) {
      print('Error deleting profile from Firebase: $e');
    }
  }

  // Workouts
  static Future<void> saveWorkout(
    String workoutId,
    Map<String, dynamic> workout,
  ) async {
    try {
      print(
        '🔥 Firebase: Saving workout $workoutId to path: workouts/$workoutId',
      );
      print('🔥 Firebase: Client name: ${workout['clientName']}');

      // Check if workout already exists (to distinguish new vs update)
      final existing = await _database.ref('workouts/$workoutId').get();
      final isNew = !existing.exists;

      final requestedClientUsername =
          (workout['clientUsername'] as String?)?.trim() ?? '';
      final requestedClientName =
          (workout['clientName'] as String?)?.trim() ?? '';

      String? resolvedClientUid;
      String resolvedClientUsername = requestedClientUsername;

      if (requestedClientUsername.isNotEmpty) {
        resolvedClientUid = await getUidForUsername(requestedClientUsername);
        final profile = await getClientProfile(requestedClientUsername);
        final profileUid = (profile?['uid'] ?? '').toString().trim();
        final profileUsername = (profile?['username'] ?? '').toString().trim();

        if (profileUid.isNotEmpty) {
          resolvedClientUid = profileUid;
        }
        if (profileUsername.isNotEmpty) {
          resolvedClientUsername = profileUsername;
        }
      }

      await _database.ref('workouts/$workoutId').set({
        ...workout,
        if ((workout['clientUid'] == null ||
                workout['clientUid'].toString().isEmpty) &&
            resolvedClientUid != null &&
            resolvedClientUid.isNotEmpty)
          'clientUid': resolvedClientUid,
        'updatedAt': DateTime.now().toIso8601String(),
        if (resolvedClientUsername.isNotEmpty)
          'clientUsername': resolvedClientUsername,
      });
      print('🔥 Firebase: Workout saved successfully');

      // Update workout ID list for client
      final clientUsername = resolvedClientUsername;
      final clientName = requestedClientName;
      final listOwner = clientUsername.isNotEmpty ? clientUsername : clientName;
      if (listOwner.isNotEmpty) {
        final username = listOwner;
        final workoutListKey = 'workouts_$username';
        // Fetch current list
        String workoutList = await getString(workoutListKey) ?? '';
        List<String> workoutIds = workoutList
            .split(',')
            .where((id) => id.isNotEmpty)
            .toList();
        if (!workoutIds.contains(workoutId)) {
          workoutIds.add(workoutId);
          final updatedList = workoutIds.join(',');
          await setString(workoutListKey, updatedList);
          print(
            '🔥 Firebase: Updated workout list for $username: $updatedList',
          );
        }
      }

      // If new, send notification to client
      if (isNew && listOwner.isNotEmpty) {
        await sendNotification(
          listOwner,
          'A new workout has been assigned to you!',
        );
      }
    } catch (e) {
      print('Error saving workout to Firebase: $e');
    }
  }

  static Future<void> deleteWorkout(String workoutId) async {
    try {
      print('🔥 Firebase: Deleting workout $workoutId');
      final existingWorkout = await getWorkout(workoutId);

      // Remove any locally mirrored serialized payload.
      await remove('workout_$workoutId');

      final clientUsername = (existingWorkout?['clientUsername'] ?? '')
          .toString()
          .trim();
      final clientName = (existingWorkout?['clientName'] ?? '')
          .toString()
          .trim();
      final listOwner = clientUsername.isNotEmpty ? clientUsername : clientName;
      if (listOwner.isNotEmpty) {
        final workoutListKey = 'workouts_$listOwner';
        final rawList = await getString(workoutListKey) ?? '';
        final workoutIds = rawList
            .split(',')
            .where((id) => id.isNotEmpty && id != workoutId)
            .toList();
        await setString(workoutListKey, workoutIds.join(','));
      }

      await _database.ref('workouts/$workoutId').remove();

      print('✅ Firebase: Workout deleted successfully');
    } catch (e) {
      print('❌ Error deleting workout from Firebase: $e');
    }
  }

  static Future<Map<String, dynamic>?> getWorkout(String workoutId) async {
    try {
      final snapshot = await _database.ref('workouts/$workoutId').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('Error getting workout from Firebase: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getClientWorkoutsForCurrentUser({
    String? fallbackUsername,
  }) async {
    final workouts = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    void appendFromSnapshot(DataSnapshot snapshot) {
      if (!snapshot.exists) return;
      final raw = snapshot.value;

      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        for (final entry in map.entries) {
          if (entry.value is! Map) continue;
          final id = entry.key.toString();
          if (!seenIds.add(id)) continue;
          workouts.add({
            'id': id,
            ...Map<String, dynamic>.from(entry.value as Map),
          });
        }
      }
    }

    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        final byUid = await _database
            .ref('workouts')
            .orderByChild('clientUid')
            .equalTo(uid)
            .get();
        appendFromSnapshot(byUid);
      }

      final mappedUsername = await getCurrentUsername();
      final usernameCandidates = <String>{
        if ((mappedUsername ?? '').trim().isNotEmpty) mappedUsername!.trim(),
        if ((fallbackUsername ?? '').trim().isNotEmpty)
          fallbackUsername!.trim(),
      };

      for (final candidate in usernameCandidates) {
        final byUsername = await _database
            .ref('workouts')
            .orderByChild('clientUsername')
            .equalTo(candidate)
            .get();
        appendFromSnapshot(byUsername);

        final lowered = candidate.toLowerCase();
        if (lowered != candidate) {
          final byLowered = await _database
              .ref('workouts')
              .orderByChild('clientUsername')
              .equalTo(lowered)
              .get();
          appendFromSnapshot(byLowered);
        }
      }
    } catch (e) {
      print('Error getting client workouts from Firebase: $e');
    }

    return workouts;
  }

  static Future<List<Map<String, dynamic>>> getAllWorkouts() async {
    try {
      final snapshot = await _database.ref('workouts').get();
      if (!snapshot.exists) {
        return [];
      }

      final raw = snapshot.value;
      final workouts = <Map<String, dynamic>>[];

      if (raw is Map) {
        final workoutsMap = Map<String, dynamic>.from(raw);
        for (final entry in workoutsMap.entries) {
          if (entry.value is! Map) continue;
          workouts.add({
            'id': entry.key,
            ...Map<String, dynamic>.from(entry.value as Map),
          });
        }
        return workouts;
      }

      if (raw is List) {
        for (var i = 0; i < raw.length; i++) {
          final value = raw[i];
          if (value is! Map) continue;
          workouts.add({
            'id': i.toString(),
            ...Map<String, dynamic>.from(value),
          });
        }
        return workouts;
      }
    } catch (e) {
      if (_isPermissionDeniedError(e) && await _refreshAuthTokenIfPossible()) {
        try {
          final snapshot = await _database.ref('workouts').get();
          if (!snapshot.exists) {
            return [];
          }
          final raw = snapshot.value;
          final workouts = <Map<String, dynamic>>[];
          if (raw is Map) {
            final workoutsMap = Map<String, dynamic>.from(raw);
            for (final entry in workoutsMap.entries) {
              if (entry.value is! Map) continue;
              workouts.add({
                'id': entry.key,
                ...Map<String, dynamic>.from(entry.value as Map),
              });
            }
            return workouts;
          }
          if (raw is List) {
            for (var i = 0; i < raw.length; i++) {
              final value = raw[i];
              if (value is! Map) continue;
              workouts.add({
                'id': i.toString(),
                ...Map<String, dynamic>.from(value),
              });
            }
            return workouts;
          }
        } catch (_) {
          // Fall through to the main error log below.
        }
      }
      print('Error getting all workouts from Firebase: $e');
    }
    return [];
  }

  // Client list
  static Future<void> saveClientsList(List<String> clients) async {
    try {
      await _database.ref('clientsList').set(clients);
    } catch (e) {
      print('Error saving clients list to Firebase: $e');
    }
  }

  static Future<void> touchClientsList() async {
    try {
      await _database
          .ref('clientsListUpdatedAt')
          .set(DateTime.now().toIso8601String());
    } catch (e) {
      print('Error touching clients list in Firebase: $e');
    }
  }

  static Future<List<String>> getClientsList() async {
    try {
      final snapshot = await _database.ref('clientsList').get();
      if (!snapshot.exists) {
        return [];
      }

      final raw = snapshot.value;

      if (raw is List) {
        return raw
            .where((item) => item != null)
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }

      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);
        return data.values
            .where((item) => item != null)
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (e) {
      if (_isPermissionDeniedError(e) && await _refreshAuthTokenIfPossible()) {
        try {
          final snapshot = await _database.ref('clientsList').get();
          if (!snapshot.exists) {
            return [];
          }
          final raw = snapshot.value;
          if (raw is List) {
            return raw
                .where((item) => item != null)
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList();
          }
          if (raw is Map) {
            final data = Map<String, dynamic>.from(raw);
            return data.values
                .where((item) => item != null)
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList();
          }
        } catch (_) {
          // Fall through to the main error log below.
        }
      }
      print('Error getting clients list from Firebase: $e');
    }
    return [];
  }

  // Generic key-value storage
  static Future<void> setString(String key, String value) async {
    try {
      if (key.startsWith('workouts_')) {
        final owner = key.substring('workouts_'.length).trim();
        final owners = _workoutIndexOwners(owner);
        if (owners.isEmpty) return;

        for (final variantOwner in owners) {
          final ref = _database.ref(
            'storage/workoutIndexes/${_firebasePathKey(variantOwner)}',
          );
          await ref.set(value);
        }
        return;
      }

      final ref = _structuredStorageRefForKey(key);
      if (ref == null) return;
      await ref.set(value);
    } catch (e) {
      print('Error setting value in Firebase: $e');
    }
  }

  static Future<String?> getString(String key) async {
    try {
      if (key.startsWith('workouts_')) {
        final owner = key.substring('workouts_'.length).trim();
        final owners = _workoutIndexOwners(owner);
        for (final variantOwner in owners) {
          final snapshot = await _database
              .ref('storage/workoutIndexes/${_firebasePathKey(variantOwner)}')
              .get();
          if (snapshot.exists) {
            return snapshot.value?.toString();
          }
        }
        return null;
      }

      final ref = _structuredStorageRefForKey(key);
      if (ref == null) return null;
      final snapshot = await ref.get();
      if (snapshot.exists) {
        return snapshot.value?.toString();
      }
    } catch (e) {
      print('Error getting value from Firebase: $e');
    }
    return null;
  }

  static Future<void> remove(String key) async {
    try {
      if (key.startsWith('workouts_')) {
        final owner = key.substring('workouts_'.length).trim();
        final owners = _workoutIndexOwners(owner);
        for (final variantOwner in owners) {
          await _database
              .ref('storage/workoutIndexes/${_firebasePathKey(variantOwner)}')
              .remove();
        }
        return;
      }

      final ref = _structuredStorageRefForKey(key);
      if (ref == null) return;
      await ref.remove();
    } catch (e) {
      print('Error removing value from Firebase: $e');
    }
  }

  static const String _loginQuoteKey = 'login_quote_text';

  static Future<void> saveLoginQuote(String quote) async {
    final trimmed = quote.trim();
    if (trimmed.isEmpty) return;
    await setString(_loginQuoteKey, trimmed);
  }

  static Future<String?> getLoginQuote() async {
    final quote = await getString(_loginQuoteKey);
    if (quote == null) return null;
    final trimmed = quote.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  // Instructor password
  static Future<void> saveInstructorPassword(String password) async {
    try {
      await _database.ref('instructor/password').set(password);
    } catch (e) {
      print('Error saving instructor password to Firebase: $e');
    }
  }

  static Future<String?> getInstructorPassword() async {
    try {
      final snapshot = await _database.ref('instructor/password').get();
      if (snapshot.exists) {
        return snapshot.value as String;
      }
    } catch (e) {
      print('Error getting instructor password from Firebase: $e');
    }
    return null;
  }

  static Future<void> saveInstructorBio(Map<String, dynamic> bio) async {
    try {
      await _database.ref('instructor/bio').set({
        ...bio,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving instructor bio to Firebase: $e');
    }
  }

  static Future<Map<String, dynamic>?> getInstructorBio() async {
    try {
      final snapshot = await _database.ref('instructor/bio').get();
      if (snapshot.exists && snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('Error getting instructor bio from Firebase: $e');
    }
    return null;
  }

  static Future<void> saveWorkoutOfWeek(Map<String, dynamic> workout) async {
    try {
      await _database.ref('instructor/workoutOfWeek').set({
        ...workout,
        'updatedAt': (workout['updatedAt'] ?? DateTime.now().toIso8601String())
            .toString(),
      });
    } catch (e) {
      print('Error saving workout of week to Firebase: $e');
    }
  }

  static Future<Map<String, dynamic>?> getWorkoutOfWeek() async {
    try {
      final snapshot = await _database.ref('instructor/workoutOfWeek').get();
      if (snapshot.exists && snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('Error getting workout of week from Firebase: $e');
    }
    return null;
  }

  // Rest Day methods
  static Future<void> saveRestDay(Map<String, dynamic> restDayData) async {
    try {
      final restDayId = restDayData['id'];
      await _database.ref('restDays/$restDayId').set(restDayData);
      print('✅ Rest day $restDayId saved to Firebase');
    } catch (e) {
      print('⚠️ Error saving rest day to Firebase: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllRestDays() async {
    try {
      final snapshot = await _database.ref('restDays').get();
      if (!snapshot.exists) {
        return [];
      }

      final raw = snapshot.value;
      final restDays = <Map<String, dynamic>>[];

      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);
        for (final entry in data.entries) {
          if (entry.value is! Map) continue;
          restDays.add(Map<String, dynamic>.from(entry.value as Map));
        }
        return restDays;
      }

      if (raw is List) {
        for (final value in raw) {
          if (value is! Map) continue;
          restDays.add(Map<String, dynamic>.from(value));
        }
        return restDays;
      }
    } catch (e) {
      if (_isPermissionDeniedError(e) && await _refreshAuthTokenIfPossible()) {
        try {
          final snapshot = await _database.ref('restDays').get();
          if (!snapshot.exists) {
            return [];
          }
          final raw = snapshot.value;
          final restDays = <Map<String, dynamic>>[];
          if (raw is Map) {
            final data = Map<String, dynamic>.from(raw);
            for (final entry in data.entries) {
              if (entry.value is! Map) continue;
              restDays.add(Map<String, dynamic>.from(entry.value as Map));
            }
            return restDays;
          }
          if (raw is List) {
            for (final value in raw) {
              if (value is! Map) continue;
              restDays.add(Map<String, dynamic>.from(value));
            }
            return restDays;
          }
        } catch (_) {
          // Fall through to the main error log below.
        }
      }
      print('⚠️ Error loading rest days from Firebase: $e');
    }
    return [];
  }

  static Stream<DatabaseEvent> watchAllRestDays() {
    return _database.ref('restDays').onValue;
  }

  static Future<void> deleteRestDay(String restDayId) async {
    try {
      await _database.ref('restDays/$restDayId').remove();
      print('✅ Rest day $restDayId deleted from Firebase');
    } catch (e) {
      print('⚠️ Error deleting rest day from Firebase: $e');
    }
  }

  // Push notification methods
  static Future<void> sendPushNotification({
    required String title,
    required String body,
    required String token,
  }) async {
    if (kReleaseMode) {
      debugPrint(
        'Client-side FCM send is disabled in release; use a trusted backend.',
      );
      return;
    }

    // TODO: Replace with your real FCM server key. DO NOT commit real keys to source control.
    // For production, load this from a secure config or environment variable.
    const String serverKey = String.fromEnvironment(
      'FCM_SERVER_KEY',
      defaultValue: 'YOUR_FCM_SERVER_KEY',
    );
    if (serverKey == 'YOUR_FCM_SERVER_KEY') {
      print('❌ FCM server key not set! Push notification will not be sent.');
      return;
    }
    final Uri url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body:
          '''{
        "to": "$token",
        "notification": {
          "title": "$title",
          "body": "$body"
        }
      }''',
    );
    if (response.statusCode == 200) {
      print('Push notification sent successfully');
    } else {
      print('Failed to send push notification: \\${response.body}');
    }
  }

  // Firebase notification methods
  static Future<void> addNotificationToClient({
    required String clientId,
    required ClientNotification notification,
  }) async {
    print(
      'addNotificationToClient: clientId = \\$clientId, notificationId = \\${notification.id}, title = \\${notification.title}, message = \\${notification.message}',
    );
    await _database
        .ref()
        .child('clients')
        .child(clientId)
        .child('notifications')
        .child(notification.id)
        .set({
          'title': notification.title,
          'message': notification.message,
          'date': notification.date.toIso8601String(),
          'acknowledged': notification.acknowledged,
          'type': notification.type,
          'celebration': notification.celebration,
          'mediaUrl': notification.mediaUrl,
        });
  }

  static Future<List<ClientNotification>> fetchClientNotifications(
    String clientId,
  ) async {
    final snapshot = await _database
        .ref()
        .child('clients')
        .child(clientId)
        .child('notifications')
        .once();
    final notifications = <ClientNotification>[];
    if (snapshot.snapshot.value != null) {
      (snapshot.snapshot.value as Map).forEach((id, data) {
        List<String>? reactions;
        if (data['reactions'] != null) {
          reactions = List<String>.from(data['reactions'] as List);
        }
        List<NotificationReply>? replies;
        if (data['replies'] != null) {
          replies = (data['replies'] as List)
              .map(
                (r) => NotificationReply(
                  user: r['user'],
                  message: r['message'],
                  date: DateTime.parse(r['date']),
                ),
              )
              .toList();
        }
        notifications.add(
          ClientNotification(
            id: id,
            title: data['title'],
            message: data['message'],
            date: DateTime.parse(data['date']),
            acknowledged: data['acknowledged'] ?? false,
            type: data['type'] ?? 'message',
            celebration: data['celebration'] ?? false,
            mediaUrl: data['mediaUrl'],
            reactions: reactions,
            replies: replies,
          ),
        );
      });
    }
    return notifications;
  }

  static Future<void> acknowledgeNotification(
    String clientId,
    String notificationId,
  ) async {
    await _database
        .ref()
        .child('clients')
        .child(clientId)
        .child('notifications')
        .child(notificationId)
        .update({'acknowledged': true});
  }

  // ── Step Count ───────────────────────────────────────────────────────────────

  /// Save or update a step count for [username] on the given [date].
  static Future<void> saveStepCount(
    String username,
    DateTime date,
    int steps,
  ) async {
    try {
      final userKey = _firebasePathKey(username);
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await _database.ref('stepCounts/$userKey/$dateKey').set({
        'steps': steps,
        'syncedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving step count to Firebase: $e');
    }
  }

  /// Get step counts for [username] for the past [days] days.
  /// Returns a map of 'YYYY-MM-DD' → step count.
  static Future<Map<String, int>> getStepCounts(
    String username, {
    int days = 7,
  }) async {
    try {
      final userKey = _firebasePathKey(username);
      final snapshot = await _database.ref('stepCounts/$userKey').get();
      if (!snapshot.exists) return {};
      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final result = <String, int>{};
      raw.forEach((dateKey, value) {
        try {
          final date = DateTime.parse(dateKey);
          if (date.isAfter(cutoff)) {
            final data = Map<String, dynamic>.from(value as Map);
            result[dateKey] = (data['steps'] as num).toInt();
          }
        } catch (_) {}
      });
      return result;
    } catch (e) {
      print('Error getting step counts from Firebase: $e');
      return {};
    }
  }

  /// Get each client's most recent step count entry.
  /// Returns a map of username → {dateKey, steps}.
  static Future<Map<String, Map<String, dynamic>>>
  getAllClientsLatestSteps() async {
    try {
      final snapshot = await _database.ref('stepCounts').get();
      if (!snapshot.exists) return {};
      final allData = Map<String, dynamic>.from(snapshot.value as Map);
      final result = <String, Map<String, dynamic>>{};
      allData.forEach((encodedUsername, datesMap) {
        if (datesMap is! Map) return;
        final dates = Map<String, dynamic>.from(datesMap);
        if (dates.isEmpty) return;
        // Find the most recent date
        String? latestDate;
        int? latestSteps;
        dates.forEach((dateKey, value) {
          if (latestDate == null || dateKey.compareTo(latestDate!) > 0) {
            latestDate = dateKey;
            final data = Map<String, dynamic>.from(value as Map);
            latestSteps = (data['steps'] as num).toInt();
          }
        });
        if (latestDate != null && latestSteps != null) {
          result[encodedUsername] = {'date': latestDate, 'steps': latestSteps};
        }
      });
      return result;
    } catch (e) {
      print('Error getting all clients latest steps from Firebase: $e');
      return {};
    }
  }

  /// Watch real-time step count updates for a specific client.
  static Stream<DatabaseEvent> watchStepCounts(String username) {
    final userKey = _firebasePathKey(username);
    return _database.ref('stepCounts/$userKey').onValue;
  }

  /// Save the daily step goal for a client (set by instructor).
  static Future<void> saveClientStepGoal(String username, int goal) async {
    try {
      final userKey = _firebasePathKey(username);
      await _database.ref('stepGoals/$userKey').set({
        'goal': goal,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving step goal to Firebase: $e');
    }
  }

  /// Get the daily step goal for a client. Returns null if not set.
  static Future<int?> getClientStepGoal(String username) async {
    try {
      final userKey = _firebasePathKey(username);
      final snapshot = await _database.ref('stepGoals/$userKey/goal').get();
      if (snapshot.exists) return (snapshot.value as num).toInt();
    } catch (e) {
      print('Error getting step goal from Firebase: $e');
    }
    return null;
  }
}
