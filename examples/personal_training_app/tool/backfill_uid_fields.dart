import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:personal_training_app/utils/firebase_service.dart';

Future<void> main(List<String> args) async {
  final emailArg = args
      .firstWhere((arg) => arg.startsWith('--email='), orElse: () => '')
      .replaceFirst('--email=', '');
  final passwordArg = args
      .firstWhere((arg) => arg.startsWith('--password='), orElse: () => '')
      .replaceFirst('--password=', '');

  final instructorEmail = emailArg.isNotEmpty
      ? emailArg
      : (Platform.environment['INSTRUCTOR_EMAIL'] ?? '');
  final instructorPassword = passwordArg.isNotEmpty
      ? passwordArg
      : (Platform.environment['INSTRUCTOR_PASSWORD'] ?? '');

  if (instructorEmail.isEmpty || instructorPassword.isEmpty) {
    stderr.writeln(
      'Missing credentials. Use --email/--password args or set '
      'INSTRUCTOR_EMAIL and INSTRUCTOR_PASSWORD environment variables.',
    );
    exitCode = 2;
    return;
  }

  await FirebaseService.initialize();

  final signedIn = await FirebaseService.signInInstructorAuth(
    instructorEmail,
    instructorPassword,
  );

  if (!signedIn) {
    stderr.writeln('Failed to sign in as instructor. Aborting migration.');
    exitCode = 3;
    return;
  }

  final db = FirebaseDatabase.instance.ref();
  final uidCache = <String, String?>{};
  final unresolvedUsernames = <String>{};

  Future<String?> uidFor(String username) async {
    final key = username.trim();
    if (key.isEmpty) return null;
    if (uidCache.containsKey(key)) return uidCache[key];
    final uid = await FirebaseService.getUidForUsername(key);
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

  final clients = await FirebaseService.getClientsList();
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
    if (profileLegacy.exists && !profileUid.exists) {
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

  stdout.writeln('Backfill complete.');
  stdout.writeln('workouts clientUid added: $workoutsUpdated');
  stdout.writeln('restDays clientUid added: $restDaysUpdated');
  stdout.writeln('profiles copied to uid keys: $profilesCopiedToUid');
  stdout.writeln('users copied to uid keys: $usersCopiedToUid');

  if (unresolvedUsernames.isNotEmpty) {
    final unresolved = unresolvedUsernames.toList()..sort();
    stdout.writeln('Unresolved usernames (${unresolved.length}):');
    for (final username in unresolved) {
      stdout.writeln('- $username');
    }
    stdout.writeln(
      'These users likely have no username->uid mapping yet. Ask them to log in once, then rerun this tool.',
    );
  }

  await FirebaseAuth.instance.signOut();
}

String _firebasePathKey(String rawKey) {
  final invalidKeyChars = RegExp(r'[.#$\[\]/]');
  if (rawKey.isEmpty || !invalidKeyChars.hasMatch(rawKey)) {
    return rawKey;
  }

  final encoded = base64Url.encode(utf8.encode(rawKey)).replaceAll('=', '');
  return '__enc__$encoded';
}
