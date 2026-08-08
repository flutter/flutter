// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import '../base/common.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import '../context/tool_context.dart';
import '../doctor.dart';
import '../doctor_validator.dart';
import '../emulator.dart';
import '../runner/flutter_command.dart';

class EmulatorsCommand extends FlutterCommand {
  EmulatorsCommand({
    required ToolContext toolContext,
    Doctor? doctor,
    EmulatorManager? emulatorManager,
  }) : _toolContext = toolContext,
       _doctor = doctor,
       _emulatorManager = emulatorManager,
       super(toolContext: toolContext) {
    argParser.addOption('launch', help: 'The full or partial ID of the emulator to launch.');
    argParser.addFlag(
      'cold',
      help: 'Used with the "--launch" flag to cold boot the emulator instance (Android only).',
      negatable: false,
    );
    argParser.addFlag(
      'create',
      help: 'Creates a new Android emulator based on a Pixel device.',
      negatable: false,
    );
    argParser.addOption(
      'name',
      help: 'Used with the "--create" flag. Specifies a name for the emulator being created.',
    );
  }

  final ToolContext _toolContext;
  final Doctor? _doctor;
  final EmulatorManager? _emulatorManager;

  @override
  final name = 'emulators';

  @override
  final description = 'List, launch and create emulators.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  final aliases = <String>['emulator'];

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Doctor? doctor = _doctor;
    final Platform platform = _toolContext.platform;

    if (doctor != null && doctor.workflows.every((Workflow w) => !w.canListEmulators)) {
      throwToolExit(
        'Unable to find any emulator sources. Please ensure you have some\n'
        'Android AVD images ${platform.isMacOS ? 'or an iOS Simulator ' : ''}available.',
        exitCode: 1,
      );
    }
    final ArgResults argumentResults = argResults!;
    if (argumentResults.wasParsed('launch')) {
      final bool coldBoot = argumentResults.wasParsed('cold');
      await _launchEmulator(stringArg('launch')!, coldBoot: coldBoot);
    } else if (argumentResults.wasParsed('create')) {
      await _createEmulator(name: stringArg('name'));
    } else {
      final String? searchText = argumentResults.rest.isNotEmpty
          ? argumentResults.rest.first
          : null;
      await _listEmulators(searchText);
    }

    return FlutterCommandResult.success();
  }

  Future<void> _launchEmulator(String id, {required bool coldBoot}) async {
    final Logger logger = _toolContext.logger;
    final List<Emulator> emulators =
        await _emulatorManager?.getEmulatorsMatching(id) ?? <Emulator>[];

    if (emulators.isEmpty) {
      logger.printStatus("No emulator found that matches '$id'.");
    } else if (emulators.length > 1) {
      _printEmulatorList(emulators, "More than one emulator matches '$id':");
    } else {
      await emulators.first.launch(coldBoot: coldBoot);
    }
  }

  Future<void> _createEmulator({String? name}) async {
    final Logger logger = _toolContext.logger;
    final CreateEmulatorResult? createResult = await _emulatorManager?.createEmulator(name: name);

    if (createResult == null) {
      logger.printStatus('Failed to create emulator.\n');
      _printAdditionalInfo();
      return;
    }

    if (createResult.success) {
      logger.printStatus("Emulator '${createResult.emulatorName}' created successfully.");
    } else {
      logger.printStatus("Failed to create emulator '${createResult.emulatorName}'.\n");
      final String? error = createResult.error;
      if (error != null) {
        logger.printStatus(error.trim());
      }
      _printAdditionalInfo();
    }
  }

  Future<void> _listEmulators(String? searchText) async {
    final Logger logger = _toolContext.logger;
    final EmulatorManager? emulatorManager = _emulatorManager;
    final List<Emulator> emulators;
    if (emulatorManager == null) {
      emulators = <Emulator>[];
    } else if (searchText == null) {
      emulators = await emulatorManager.getAllAvailableEmulators();
    } else {
      emulators = await emulatorManager.getEmulatorsMatching(searchText);
    }

    if (emulators.isEmpty) {
      logger.printStatus('No emulators available.');
      _printAdditionalInfo(showCreateInstruction: true);
    } else {
      _printEmulatorList(
        emulators,
        '${emulators.length} available ${pluralize('emulator', emulators.length)}:',
      );
    }
  }

  void _printEmulatorList(List<Emulator> emulators, String message) {
    final Logger logger = _toolContext.logger;
    logger.printStatus('$message\n');
    Emulator.printEmulators(emulators, logger);
    _printAdditionalInfo(showCreateInstruction: true, showRunInstruction: true);
  }

  void _printAdditionalInfo({bool showRunInstruction = false, bool showCreateInstruction = false}) {
    final Logger logger = _toolContext.logger;
    logger.printStatus('');
    if (showRunInstruction) {
      logger.printStatus("To run an emulator, run 'flutter emulators --launch <emulator id>'.");
    }
    if (showCreateInstruction) {
      logger.printStatus(
        "To create a new emulator, run 'flutter emulators --create [--name xyz]'.",
      );
    }

    if (showRunInstruction || showCreateInstruction) {
      logger.printStatus('');
    }
    // TODO(dantup): Update this link to flutter.dev if/when we have a better page.
    // That page can then link out to these places if required.
    logger.printStatus(
      'You can find more information on managing emulators at the links below:\n'
      '  https://developer.android.com/studio/run/managing-avds\n'
      '  https://developer.android.com/studio/command-line/avdmanager',
    );
  }
}
