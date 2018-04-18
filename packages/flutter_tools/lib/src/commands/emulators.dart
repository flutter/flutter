// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/utils.dart';
import '../doctor.dart';
import '../emulator.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class EmulatorsCommand extends FlutterCommand {
  @override
  final String name = 'emulators';

  @override
  final String description = 'List all available emulators.';

  @override
  Future<Null> runCommand() async {
    if (!doctor.canListAnything) {
      throwToolExit(
        "Unable to locate emulators; please run 'flutter doctor' for "
        'information about installing additional components.',
        exitCode: 1);
    }

    final List<Emulator> emulators = await emulatorManager.getAllAvailableEmulators().toList();

    if (emulators.isEmpty) {
      printStatus(
        'No emulators available.\n\n'
        // TODO: Change these when we support creation
        // 'You may need to create images using "flutter emulators --create"\n'
        'You may need to create one using Android Studio\n'
        'or visit https://flutter.io/setup/ for troubleshooting tips.');
      final List<String> diagnostics = await emulatorManager.getEmulatorDiagnostics();
      if (diagnostics.isNotEmpty) {
        printStatus('');
        for (String diagnostic in diagnostics) {
          printStatus('• ${diagnostic.replaceAll('\n', '\n  ')}');
        }
      }
    } else {
      printStatus('${emulators.length} available ${pluralize('emulators', emulators.length)}:\n');
      await Emulator.printEmulators(emulators);
    }
  }
}
