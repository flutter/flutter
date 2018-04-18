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
  EmulatorsCommand() {
    argParser.addOption('start',
        help: 'The full or partial ID of the emulator to start.');
  }

  @override
  final String name = 'emulators';

  @override
  final String description = 'List all available emulators.';

  @override
  Future<Null> runCommand() async {
    if (doctor.workflows.every((Workflow w) => !w.canListEmulators)) {
      throwToolExit(
          "Unable to query emulators; please run 'flutter doctor' for "
          'information about installing additional components.',
          exitCode: 1);
    }

    if (argResults.wasParsed('start')) {
      await _startEmulator(argResults['start']);
    } else {
      await _listEmulators();
    }
  }

  Future<Null> _startEmulator(String id) async {
    final List<Emulator> emulators =
        await emulatorManager.getEmulatorsById(id).toList();

    if (emulators.isEmpty) {
      printStatus("No emulator found that matches the ID '$id'.");
    } else if (emulators.length > 1) {
      printStatus("More than one emulator matches the ID '$id':\n");
      Emulator.printEmulators(emulators);
    } else {
      emulators.first.launch();
    }
  }

  Future<Null> _listEmulators() async {
    final List<Emulator> emulators =
        await emulatorManager.getAllAvailableEmulators().toList();

    if (emulators.isEmpty) {
      printStatus('No emulators available.\n\n'
          // TODO: Change these when we support creation
          // 'You may need to create images using "flutter emulators --create"\n'
          'You may need to create one using Android Studio\n'
          'or visit https://flutter.io/setup/ for troubleshooting tips.');
      final List<String> diagnostics =
          await emulatorManager.getEmulatorDiagnostics();
      if (diagnostics.isNotEmpty) {
        printStatus('');
        for (String diagnostic in diagnostics) {
          printStatus('• ${diagnostic.replaceAll('\n', '\n  ')}');
        }
      }
    } else {
      printStatus(
          '${emulators.length} available ${pluralize('emulators', emulators.length)}:\n');
      await Emulator.printEmulators(emulators);
    }
  }
}
