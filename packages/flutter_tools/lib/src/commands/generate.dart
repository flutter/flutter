// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/terminal.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';

class GenerateCommand extends FlutterCommand {
  GenerateCommand() {
    addSubcommand(_WidgetCommand());
    addSubcommand(_ScreenCommand());
    addSubcommand(_PageCommand());
  }

  @override
  String get description => 'Generate code for Flutter projects.';

  @override
  String get name => 'generate';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  List<String> get aliases => const <String>['g'];

  @override
  String get invocation => '${super.invocation} <subcommand>';

  @override
  bool get hidden => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    // This is just a container for subcommands, shouldn't be called directly
    throw UsageException(
      'Please specify a subcommand to generate.',
      usage,
    );
  }
}

/// Base class for code generation commands
abstract class _BaseGenerateCommand extends FlutterCommand {
  _BaseGenerateCommand(this.componentType) {
    argParser.addFlag(
      'stateful',
      abbr: 's',
      negatable: false,
      help: 'Generate a StatefulWidget instead of StatelessWidget.',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'The output directory path (relative to lib/).',
      defaultsTo: 'lib',
    );
  }

  final String componentType;

  String get componentTypeDisplay;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> args = argResults?.rest ?? <String>[];
    
    if (args.isEmpty) {
      throwToolExit(
        'Please provide a name for the $componentTypeDisplay.\n'
        'Usage: flutter g $componentType <Name> [--stateful] [--output <path>]',
      );
    }

    final String widgetName = args.first;
    final bool isStateful = boolArg('stateful');
    final String? outputPath = stringArg('output');

    // Validate widget name (must be valid Dart class name)
    if (!RegExp(r'^[A-Z][a-zA-Z0-9]*$').hasMatch(widgetName)) {
      throwToolExit(
        'Invalid name: "$widgetName".\n'
        'Names must start with an uppercase letter and contain only letters and numbers.',
      );
    }

    final FlutterProject project = FlutterProject.current();
    final Directory libDir = project.directory.childDirectory('lib');

    if (!libDir.existsSync()) {
      throwToolExit('Could not find lib/ directory in current project.');
    }

    // Construct the full output directory path
    String resolvedOutputPath = outputPath!;
    if (resolvedOutputPath.startsWith('lib/')) {
      resolvedOutputPath = resolvedOutputPath.substring(4);
    } else if (resolvedOutputPath == 'lib') {
      resolvedOutputPath = '';
    }

    final Directory targetDir = resolvedOutputPath.isEmpty
        ? libDir
        : libDir.childDirectory(resolvedOutputPath);

    // Create directory if it doesn't exist
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
      globals.printStatus('Created directory: ${targetDir.path}');
    }

    // Generate the file name (convert PascalCase to snake_case)
    final String fileName = _toSnakeCase(widgetName);
    final File targetFile = targetDir.childFile('$fileName.dart');

    if (targetFile.existsSync()) {
      throwToolExit(
        'File already exists: ${targetFile.path}\n'
        'Please choose a different name or delete the existing file.',
      );
    }

    // Generate the widget code
    final String widgetCode = _generateCode(widgetName, isStateful);

    // Write the file
    targetFile.writeAsStringSync(widgetCode);

    final String widgetType = isStateful ? 'stateful' : 'stateless';
    final String successMessage = globals.terminal.color(
      '✓ Generated $widgetType $componentTypeDisplay:',
      TerminalColor.green,
    );
    final String filePath = globals.terminal.color(
      targetFile.path,
      TerminalColor.blue,
    );
    globals.printStatus('$successMessage $filePath');
    globals.printStatus('');
    return FlutterCommandResult.success();
  }

  String _generateCode(String name, bool isStateful);

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (Match match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}

/// Command to generate a widget
class _WidgetCommand extends _BaseGenerateCommand {
  _WidgetCommand() : super('widget');

  @override
  String get description => 'Generate a Flutter widget (stateless by default).';

  @override
  String get name => 'widget';

  @override
  List<String> get aliases => const <String>['w'];

  @override
  String get componentTypeDisplay => 'widget';

  @override
  String _generateCode(String widgetName, bool isStateful) {
    if (isStateful) {
      return '''
import 'package:flutter/material.dart';

class $widgetName extends StatefulWidget {
  const $widgetName({super.key});

  @override
  State<$widgetName> createState() => _${widgetName}State();
}

class _${widgetName}State extends State<$widgetName> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
''';
    } else {
      return '''
import 'package:flutter/material.dart';

class $widgetName extends StatelessWidget {
  const $widgetName({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
''';
    }
  }
}

/// Command to generate a screen/page with Scaffold
class _ScreenCommand extends _BaseGenerateCommand {
  _ScreenCommand() : super('screen');

  @override
  String get description => 'Generate a Flutter screen with Scaffold (stateless by default).';

  @override
  String get name => 'screen';

  @override
  List<String> get aliases => const <String>['s'];

  @override
  String get componentTypeDisplay => 'screen';

  @override
  String _generateCode(String widgetName, bool isStateful) {
    if (isStateful) {
      return '''
import 'package:flutter/material.dart';

class $widgetName extends StatefulWidget {
  const $widgetName({super.key});

  @override
  State<$widgetName> createState() => _${widgetName}State();
}

class _${widgetName}State extends State<$widgetName> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$widgetName'),
      ),
      body: const Center(
        child: Text('$widgetName'),
      ),
    );
  }
}
''';
    } else {
      return '''
import 'package:flutter/material.dart';

class $widgetName extends StatelessWidget {
  const $widgetName({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$widgetName'),
      ),
      body: const Center(
        child: Text('$widgetName'),
      ),
    );
  }
}
''';
    }
  }
}

/// Command to generate a page (alias for screen)
class _PageCommand extends _ScreenCommand {
  _PageCommand() : super();

  @override
  String get description => 'Generate a Flutter page with Scaffold (alias for screen).';

  @override
  String get name => 'page';

  @override
  List<String> get aliases => const <String>['p'];

  @override
  String get componentTypeDisplay => 'page';
}

