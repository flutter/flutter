import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:process/process.dart';


class XcodeAutomationPermission {

  File? db;
  File? backup;

  Future<void> updatePermission() async {
    try {
      print('Start automation permission update...');
      const FileSystem fileSystem = LocalFileSystem();
      const ProcessManager processManager = LocalProcessManager();

      final String? home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) {
        print('Unable to get HOME');
        return;
      }

      final Directory tccDir = fileSystem.directory(fileSystem.path.join(
        home,
        'Library',
        'Application Support',
        'com.apple.TCC',
      ));

      final File localDB = db!;
      try {
        if (!localDB.existsSync()) {
          print('File ${localDB.path} does not exist');
          return;
        }
      } on PathAccessException {
        print('Path Access to ${localDB.path} failed');
        return;
      }
      db = tccDir.childFile('TCC.db');

      // Print contents of DB.
      await _queryDB(db: localDB, processManager: processManager);

      // Create backup db if there isn't one.
      // If there is already a backup, it's most likely that a previous run did
      // not complete correctly and did not get reset, so don't overwrite the backup.
      print('Creating backup...');
      backup = tccDir.childFile('TCC.db.backup');
      if (!backup!.existsSync()) {
        localDB.copySync(backup!.path);
      }

      // Run an arbitrary AppleScript Xcode command to trigger permissions dialog.
      final Directory tempDirectory = fileSystem.systemTempDirectory.createTempSync('temp_automation.');
      final Process scriptProcess = await processManager.start(
        <String>[
          'osascript',
          '-e',
          'tell app "Xcode"',
          '-e',
          'launch',
          '-e',
          'make "${tempDirectory.childFile('empty.txt').path}"',
          '-e',
          'end tell',
        ],
      );

      // Give up to five seconds for the dialog to appear.
      await Future.any(<Future<dynamic>>[
        scriptProcess.exitCode,
        Future<void>.delayed(const Duration(seconds: 5)),
      ]);

      // The Applescript will hang if permission hasn't been given, so kill it.
      scriptProcess.kill();
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync();
      }

      // Kill the dialog. After killing the dialog, an entry for the app requesting
      // control of Xcode should automatically be added to the DB.
      final ProcessResult killProcess = await processManager.run(
        <String>[
          'killall',
          'UserNotificationCenter',
        ],
      );
      if (killProcess.exitCode != 0) {
        print('Error killing UserNotificationCenter: ${killProcess.stderr}');
      }

      // Print contents of DB.
      await _queryDB(db: localDB, processManager: processManager);

      // Update the DB to make it think permission was given.
      print('Updating real db...');
      final ProcessResult updateResult = await processManager.run(
        <String>[
          'sqlite3',
          localDB.path,
          "UPDATE access SET auth_value = 2, auth_reason = 3, flags = NULL WHERE service = 'kTCCServiceAppleEvents' AND indirect_object_identifier = 'com.apple.dt.Xcode'"
        ],
      );

      if (updateResult.exitCode != 0) {
        print('Error when updating db: ${updateResult.stderr}');
      }

      // Print contents of DB.
      await _queryDB(db: localDB, processManager: processManager);
    } catch (err, stackTrace) {
      print(err);
      print(stackTrace);
    }
  }

  void resetPermissions() {
    print('Restoring backup...');
    try {
      if (backup != null && db != null) {
        backup!.copySync(db!.path);
        backup!.deleteSync();
      }
    } catch (err, stackTrace) {
      print(err);
      print(stackTrace);
    }
  }

  Future<void> _queryDB({
    required File db,
    required ProcessManager processManager,
  }) async {
    print('Querying db...');
    final ProcessResult result = await processManager.run(
      <String>[
        'sqlite3',
        db.path,
        'SELECT service, client, client_type, auth_value, auth_reason, indirect_object_identifier_type, indirect_object_identifier, flags, last_modified FROM access WHERE service = "kTCCServiceAppleEvents"'
      ],
    );
    if (result.exitCode != 0) {
      print('Failed to query db: ${result.stderr}');
      return;
    }
    print('[stdout]: ${result.stdout.toString().trim()}');
  }
}
