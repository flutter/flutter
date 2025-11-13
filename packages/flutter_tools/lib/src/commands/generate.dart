// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';

class GenerateCommand extends FlutterCommand {
  GenerateCommand() {
    addSubcommand(_WidgetCommand());
  }

  @override
  String get description => 'Generate code for Flutter projects.';

  @override
  String get name => 'generate';

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

/// Base class for widget generation commands
abstract class _BaseWidgetCommand extends FlutterCommand {
  _BaseWidgetCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'The name of the widget to generate.',
      mandatory: true,
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'The output directory path (relative to lib/).',
      defaultsTo: 'lib',
    );
  }

  String get widgetType;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String? widgetName = stringArg('name');
    final String? outputPath = stringArg('output');

    if (widgetName == null || widgetName.isEmpty) {
      throwToolExit('Widget name is required. Use --name or -n to specify.');
    }

    // Validate widget name (must be valid Dart class name)
    if (!RegExp(r'^[A-Z][a-zA-Z0-9]*$').hasMatch(widgetName)) {
      throwToolExit(
        'Invalid widget name: "$widgetName".\n'
        'Widget names must start with an uppercase letter and contain only letters and numbers.',
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
    final String widgetCode = _generateWidgetCode(widgetName, resolvedOutputPath);

    // Write the file
    targetFile.writeAsStringSync(widgetCode);

    globals.printStatus('✓ Generated $widgetType widget: ${targetFile.path}');
    return FlutterCommandResult.success();
  }

  String _generateWidgetCode(String widgetName, String relativePath);

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (Match match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}

/// Command to generate a widget (defaults to stateless)
class _WidgetCommand extends FlutterCommand {
  _WidgetCommand() {
    addSubcommand(_StatelessWidgetCommand());
    addSubcommand(_StatefulWidgetCommand());
  }

  @override
  String get description => 'Generate Flutter widgets.';

  @override
  String get name => 'widget';

  @override
  List<String> get aliases => const <String>['w'];

  @override
  String get invocation => 'flutter generate widget <subcommand>';

  @override
  Future<FlutterCommandResult> runCommand() async {
    // Default to stateless widget if no subcommand provided
    throw UsageException(
      'Please specify a widget type: stateless or stateful.',
      'Usage: flutter generate widget <stateless|stateful> --name <WidgetName> [--output <path>]',
    );
  }
}

/// Command to generate a stateless widget
class _StatelessWidgetCommand extends _BaseWidgetCommand {
  @override
  String get description => 'Generate a StatelessWidget.';

  @override
  String get name => 'stateless';

  @override
  List<String> get aliases => const <String>['sl'];

  @override
  String get widgetType => 'stateless';

  @override
  String _generateWidgetCode(String widgetName, String relativePath) {
    return '''
import 'package:flutter/material.dart';

class $widgetName extends StatelessWidget {
  const $widgetName({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text('$widgetName'),
      ),
    );
  }
}
''';
  }
}

/// Command to generate a stateful widget
class _StatefulWidgetCommand extends _BaseWidgetCommand {
  @override
  String get description => 'Generate a StatefulWidget.';

  @override
  String get name => 'stateful';

  @override
  List<String> get aliases => const <String>['sf'];

  @override
  String get widgetType => 'stateful';

  @override
  String _generateWidgetCode(String widgetName, String relativePath) {
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
    return Container(
      child: const Center(
        child: Text('$widgetName'),
      ),
    );
  }
}
''';
  }
}
