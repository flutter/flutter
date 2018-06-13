// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import '../doctor.dart';
import '../emulator.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class EmulatorsCommand extends FlutterCommand {
  EmulatorsCommand() {
    argParser.addOption('launch',
        help: 'The full or partial ID of the emulator to launch.');
  }

  @override
  final String name = 'emulators';

  @override
  final String description = 'List and launch available emulators.';

  @override
  final List<String> aliases = <String>['emulator'];

  @override
  Future<Null> runCommand() async {
    if (doctor.workflows.every((Workflow w) => !w.canListEmulators)) {
      throwToolExit(
          'Unable to find any emulator sources. Please ensure you have some\n'
              'Android AVD images ' +
              (platform.isMacOS ? 'or an iOS Simulator ' : '') +
              'available.',
          exitCode: 1);
    }

    if (argResults.wasParsed('launch')) {
      await _launchEmulator(argResults['launch']);
    } else {
      final String searchText =
          argResults.rest != null && argResults.rest.isNotEmpty
              ? argResults.rest.first
              : null;
      await _listEmulators(searchText);
    }
  }

  Future<void> _launchEmulator(String id) async {
    final List<Emulator> emulators =
        await emulatorManager.getEmulatorsMatching(id);

    if (emulators.isEmpty) {
      printStatus("No emulator found that matches '$id'.");
    } else if (emulators.length > 1) {
      _printEmulatorList(
        emulators,
        "More than one emulator matches '$id':",
      );
    } else {
      try {
      await emulators.first.launch();
      }
      catch (e) {
        printError(e);
      }
    }
  }

  Future<void> _listEmulators(String searchText) async {
    final List<Emulator> emulators = searchText == null
        ? await emulatorManager.getAllAvailableEmulators()
        : await emulatorManager.getEmulatorsMatching(searchText);

    if (emulators.isEmpty) {
      printStatus('No emulators available.\n\n'
          // TODO(dantup): Change these when we support creation
          // 'You may need to create images using "flutter emulators --create"\n'
          'You may need to create one using Android Studio '
          'or visit https://flutter.io/setup/ for troubleshooting tips.');
    } else {
      _printEmulatorList(
        emulators,
        '${emulators.length} available ${pluralize('emulator', emulators.length)}:',
      );
    }
  }

  void _printEmulatorList(List<Emulator> emulators, String message) {
    printStatus('$message\n');
    Emulator.printEmulators(emulators);
    printStatus(
        "\nTo run an emulator, run 'flutter emulators --launch <emulator id>'.");
  }
}
