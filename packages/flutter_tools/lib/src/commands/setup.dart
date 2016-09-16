// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../base/os.dart';
import '../base/process.dart';
import '../cache.dart';
import '../doctor.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

/// This setup command will install dependencies necessary for Flutter development.
///
/// This is a hidden command, and is currently designed to work in a custom kiosk
/// environment, but may be generalized in the future.
class SetupCommand extends FlutterCommand {
  SetupCommand({ this.hidden: false });

  @override
  final String name = 'setup';

  @override
  final String description = 'Setup a machine to support Flutter development.';

  @override
  final bool hidden;

  @override
  Future<int> runCommand() async {
    printStatus('Running Flutter setup...');

    // setup brew on mac
    if (os.isMacOS) {
      printStatus('\nChecking brew:');

      if (os.which('brew') == null) {
        printError('homebrew is not installed; please install at http://brew.sh/.');
      } else {
        printStatus('brew is installed.');

        await runCommandAndStreamOutput(<String>['brew', 'install', 'ideviceinstaller']);
        await runCommandAndStreamOutput(<String>['brew', 'install', 'ios-deploy']);
      }
    }

    // setup atom
    printStatus('\nChecking Atom:');
    String apmPath = os.which('apm')?.path;
    if (apmPath == null && FileSystemEntity.isFileSync('/usr/local/bin/apm'))
      apmPath = '/usr/local/bin/apm';
    if (apmPath == null && FileSystemEntity.isFileSync('/usr/bin/apm'))
      apmPath = '/usr/bin/apm';
    if (apmPath == null) {
      final String expectedLocation = '/Applications/Atom.app/Contents/Resources/app/apm/bin/apm';
      if (FileSystemEntity.isFileSync(expectedLocation))
        apmPath = expectedLocation;
    }

    if (apmPath == null) {
      printError('Unable to locate the Atom installation.');
    } else {
      printStatus('apm command available at $apmPath');

      AtomValidator atomValidator = new AtomValidator();

      if (!atomValidator.hasPackage('dartlang'))
        await runCommandAndStreamOutput(<String>[apmPath, 'install', 'dartlang']);
      else
        printStatus('dartlang plugin installed');

      if (!atomValidator.hasPackage('flutter'))
        await runCommandAndStreamOutput(<String>[apmPath, 'install', 'flutter']);
      else
        printStatus('flutter plugin installed');

      // Set up the ~/.atom/config.cson file - make sure the path the the
      // flutter and dart sdks are correct.
      _updateAtomConfigFile();
    }

    // run doctor
    printStatus('\nFlutter doctor:');
    bool goodInstall = await doctor.diagnose();

    // Validate that flutter is available on the path.
    if (os.which('flutter') == null) {
      printError(
        '\nThe flutter command is not available on the path.\n'
        'Please set up your PATH environment variable to point to the flutter/bin directory.'
      );
    } else {
      printStatus('\nThe flutter command is available on the path.');
    }

    if (goodInstall)
      printStatus('\nFlutter setup complete!');

    return goodInstall ? 0 : 1;
  }

  // Quick-and-dirty manipulation of the cson file.
  void _updateAtomConfigFile() {
    //   flutter:
    //     flutterRoot: "..."
    //   dartlang:
    //     sdkLocation: "..."

    String flutterRoot = path.normalize(path.absolute(Cache.flutterRoot));
    String sdkLocation = path.join(flutterRoot, 'bin/cache/dart-sdk');

    File file = AtomValidator.getConfigFile();

    if (file.existsSync()) {
      String cson = file.readAsStringSync();
      cson = cson.trimRight() + '\n';

      List<String> lines = cson.split('\n').map((String line) => line.trim()).toList();

      if (!lines.contains('flutter:')) {
        cson += '''
  flutter:
    flutterRoot: "$flutterRoot"
''';
      }

      if (!lines.contains('dartlang:')) {
        cson += '''
  dartlang:
    sdkLocation: "$sdkLocation"
''';
      }

      if (cson.trim() != file.readAsStringSync().trim()) {
        printStatus('Updating ${file.path}');
        file.writeAsStringSync(cson);
      }
    } else {
      // Create a new config file.
      printStatus('Creating ${file.path}');

      String cson = '''
"*":
  flutter:
    flutterRoot: "$flutterRoot"
  dartlang:
    sdkLocation: "$sdkLocation"
''';
      file.writeAsStringSync(cson);
    }
  }
}
