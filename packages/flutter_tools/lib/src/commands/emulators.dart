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
        help: 'Creates a new Android emulator based on a Pixel device.',
        negatable: false);
    argParser.addOption('name',
        help: 'Used with flag --create. Specifies a name for the emulator being created.');
  }

  @override
  final String name = 'emulators';

  @override
  final String description = 'List, launch and create emulators.';

  @override
  final List<String> aliases = <String>['emulator'];

  @override
  Future<FlutterCommandResult> runCommand() async {
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
      await _createEmulator(name: argResults['name']);
    } else {
      final String searchText =
          argResults.rest != null && argResults.rest.isNotEmpty
              ? argResults.rest.first
              : null;
      await _listEmulators(searchText);
    }

    return null;
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
        if (e is String) {
          printError(e);
        } else {
          rethrow;
        }
      }
    }
  }

  Future<void> _createEmulator({ String name }) async {
    final CreateEmulatorResult createResult =
        await emulatorManager.createEmulator(name: name);

    if (createResult.success) {
      printStatus("Emulator '${createResult.emulatorName}' created successfully.");
    } else {
      printStatus("Failed to create emulator '${createResult.emulatorName}'.\n");
      printStatus(createResult.error.trim());
      _printAdditionalInfo();
    }
  }

  Future<void> _listEmulators(String searchText) async {
    final List<Emulator> emulators = searchText == null
        ? await emulatorManager.getAllAvailableEmulators()
        : await emulatorManager.getEmulatorsMatching(searchText);

    if (emulators.isEmpty) {
      printStatus('No emulators available.');
      _printAdditionalInfo(showCreateInstruction: true);
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
    _printAdditionalInfo(showCreateInstruction: true, showRunInstruction: true);
  }

  void _printAdditionalInfo({
    bool showRunInstruction = false,
    bool showCreateInstruction = false,
  }) {
    printStatus('');
    if (showRunInstruction) {
      printStatus(
          "To run an emulator, run 'flutter emulators --launch <emulator id>'.");
    }
    if (showCreateInstruction) {
      printStatus(
          "To create a new emulator, run 'flutter emulators --create [--name xyz]'.");
    }

    if (showRunInstruction || showCreateInstruction) {
      printStatus('');
    }
    // TODO(dantup): Update this link to flutter.dev if/when we have a better page.
    // That page can then link out to these places if required.
    printStatus('You can find more information on managing emulators at the links below:\n'
        '  https://developer.android.com/studio/run/managing-avds\n'
        '  https://developer.android.com/studio/command-line/avdmanager');
  }
}
