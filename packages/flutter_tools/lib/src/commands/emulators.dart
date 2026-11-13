// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import '../base/common.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../context/tool_context.dart';
import '../doctor.dart';
import '../doctor_validator.dart';
import '../emulator.dart';
import '../runner/flutter_command.dart';

const _launchOption = 'launch';
const _coldFlag = 'cold';
const _createFlag = 'create';
const _nameOption = 'name';
const _platformOption = 'platform';

/// The `flutter emulators` command, which lists, launches, and creates emulators.
class EmulatorsCommand extends FlutterCommand {
  EmulatorsCommand({
    required this._doctor,
    required this._emulatorManager,
    required super.toolContext,
    super.verboseHelp,
  }) {
    argParser.addOption(_launchOption, help: 'The full or partial ID of the emulator to launch.');
    argParser.addFlag(
      _coldFlag,
      help:
          'Used with the "--launch" flag to cold boot the emulator instance '
          '(Android and supported tool extensions).',
      negatable: false,
    );
    argParser.addFlag(
      _createFlag,
      help: 'Creates a new emulator (for example, an Android AVD or a tool extension emulator).',
      negatable: false,
    );
    argParser.addOption(
      _nameOption,
      help: 'Used with the "--create" flag. Specifies a name for the emulator being created.',
    );
    argParser.addOption(
      _platformOption,
      help:
          'Used with the "--create" flag. Specifies the target platform for the emulator being '
          'created (for example, "android" or a tool extension platform identifier).',
    );
  }

  final Doctor _doctor;
  final EmulatorManager _emulatorManager;

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
    final Platform platform = toolContext.platform;
    final ArgResults argumentResults = argResults!;

    if (argumentResults.wasParsed(_platformOption) && !argumentResults.wasParsed(_createFlag)) {
      throwToolExit('The "--$_platformOption" option can only be used with "--$_createFlag".');
    }

    if (_doctor.workflows.every((Workflow w) => !w.canListEmulators) &&
        !await _emulatorManager.hasExtensionEmulatorSources()) {
      throwToolExit(
        'Unable to find any emulator sources. Please ensure you have some\n'
        'Android AVD images ${platform.isMacOS ? 'or an iOS Simulator ' : ''}available.',
        exitCode: 1,
      );
    }
    if (argumentResults.wasParsed(_launchOption)) {
      final bool coldBoot = argumentResults.wasParsed(_coldFlag);
      await _launchEmulator(stringArg(_launchOption)!, coldBoot: coldBoot);
    } else if (argumentResults.wasParsed(_createFlag)) {
      await _createEmulator(name: stringArg(_nameOption), platform: stringArg(_platformOption));
    } else {
      final String? searchText = argumentResults.rest.firstOrNull;
      await _listEmulators(searchText);
    }

    return FlutterCommandResult.success();
  }

  Future<void> _launchEmulator(String id, {required bool coldBoot}) async {
    final Logger logger = toolContext.logger;
    final List<Emulator> emulators = await _emulatorManager.getEmulatorsMatching(id);

    if (emulators.isEmpty) {
      logger.printStatus("No emulator found that matches '$id'.");
    } else if (emulators.length > 1) {
      _printEmulatorList(emulators, "More than one emulator matches '$id':");
    } else {
      await emulators.first.launch(coldBoot: coldBoot);
    }
  }

  Future<void> _createEmulator({String? name, String? platform}) async {
    final ToolContext(:Logger logger, :AnsiTerminal terminal) = toolContext;
    final String resolvedPlatform;
    if (platform != null) {
      if (platform.isEmpty) {
        throwToolExit('The "--$_platformOption" option must not be empty.');
      }
      if (platform != EmulatorManager.androidPlatform) {
        final List<String> availablePlatforms = await _emulatorManager
            .getAvailableCreatePlatforms();
        if (!availablePlatforms.contains(platform)) {
          throwToolExit(
            availablePlatforms.isEmpty
                ? 'Unknown emulator creation platform "$platform". '
                      'No emulator creation platforms are available.'
                : 'Unknown emulator creation platform "$platform". '
                      'Available platforms: ${availablePlatforms.join(', ')}.',
          );
        }
      }
      resolvedPlatform = platform;
    } else {
      final List<String> availablePlatforms = await _emulatorManager.getAvailableCreatePlatforms();
      switch (availablePlatforms) {
        case []:
          resolvedPlatform = EmulatorManager.androidPlatform;
        case [final String singlePlatform]:
          resolvedPlatform = singlePlatform;
        default:
          if (!terminal.stdinHasTerminal) {
            throwToolExit(
              'Multiple emulator creation platforms are available '
              '(${availablePlatforms.join(', ')}). '
              'Specify one using "--$_platformOption <platform>".',
            );
          }
          resolvedPlatform = await _promptForPlatform(
            availablePlatforms,
            logger: logger,
            terminal: terminal,
          );
      }
    }

    final CreateEmulatorResult createResult = await _emulatorManager.createEmulator(
      name: name,
      platform: resolvedPlatform,
    );

    if (createResult.success) {
      logger.printStatus("Emulator '${createResult.emulatorName}' created successfully.");
    } else {
      if (createResult.emulatorName.isEmpty) {
        logger.printStatus('Failed to create emulator.\n');
      } else {
        logger.printStatus("Failed to create emulator '${createResult.emulatorName}'.\n");
      }
      final String? error = createResult.error;
      if (error != null && error.trim().isNotEmpty) {
        logger.printStatus(error.trim());
      }
      if (resolvedPlatform == EmulatorManager.androidPlatform) {
        _printAdditionalInfo();
      }
    }
  }

  Future<String> _promptForPlatform(
    List<String> platforms, {
    required Logger logger,
    required AnsiTerminal terminal,
  }) async {
    const prompt = 'Please choose one (or "q" to quit)';
    logger.printStatus('Multiple emulator creation platforms are available:');
    for (final (int index, String platform) in platforms.indexed) {
      logger.printStatus('[${index + 1}]: $platform');
    }
    final String choice;
    if (platforms.length < 10) {
      terminal.usesTerminalUi = true;
      choice = await terminal.promptForCharInput(
        <String>[for (var i = 0; i < platforms.length; i++) '${i + 1}', 'q', 'Q'],
        displayAcceptedCharacters: false,
        logger: logger,
        prompt: prompt,
      );
    } else {
      choice = await _readPlatformChoiceLine(
        logger: logger,
        optionCount: platforms.length,
        prompt: prompt,
        terminal: terminal,
      );
    }
    if (choice.toLowerCase() == 'q') {
      throwToolExit('');
    }
    final String selected = platforms[int.parse(choice) - 1];
    logger.printStatus('To skip this prompt in the future, pass "--$_platformOption $selected".');
    return selected;
  }

  Future<String> _readPlatformChoiceLine({
    required Logger logger,
    required int optionCount,
    required String prompt,
    required AnsiTerminal terminal,
  }) async {
    while (true) {
      logger.printStatus('$prompt: ', emphasis: true, newline: false);
      final String line = (await terminal.readLine()).trim();
      final int? number = int.tryParse(line);
      if (line.toLowerCase() == 'q' || (number != null && number >= 1 && number <= optionCount)) {
        return line;
      }
    }
  }

  Future<void> _listEmulators(String? searchText) async {
    final Logger logger = toolContext.logger;
    final List<Emulator> emulators = searchText == null
        ? await _emulatorManager.getAllAvailableEmulators()
        : await _emulatorManager.getEmulatorsMatching(searchText);

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
    final Logger logger = toolContext.logger;
    logger.printStatus('$message\n');
    Emulator.printEmulators(emulators, logger);
    _printAdditionalInfo(showCreateInstruction: true, showRunInstruction: true);
  }

  void _printAdditionalInfo({bool showRunInstruction = false, bool showCreateInstruction = false}) {
    final Logger logger = toolContext.logger;
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
