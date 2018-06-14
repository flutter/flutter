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
    argParser.addFlag('create',
        help: 'Creates a new Android emulator.',
        negatable: false);
    argParser.addOption('name',
        help: 'Used with flag --create. Specifies a name for the emulator being created.');
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
    } else if (argResults.wasParsed('create')) {
      await _createEmulator(argResults['name']);
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

  Future<Null> _createEmulator(String name) async {
    if (name == null) {
      const String autoName = "flutter_emulator";
      final Set<String> takenNames =
          (await emulatorManager.getEmulatorsMatching(autoName))
          .map((Emulator e) => e.id)
          .toSet();
      int suffix = 1;
      name = autoName;
      while (takenNames.contains(name)) {
        name = '${name}_${++suffix}';
      }
    }
    final CreateEmulatorResult createResult =
        await emulatorManager.createEmulator(name);

    if (createResult.success) {
      printStatus("Emulator '$name' created successfully.");
    } else {
      printStatus("Failed to create emulator '$name'.\n");
      printStatus(createResult.error);
      printStatus('You can find more information on managing emulators at the links below:\n'
        '  https://developer.android.com/studio/run/managing-avds\n'
        '  https://developer.android.com/studio/command-line/avdmanager');
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
