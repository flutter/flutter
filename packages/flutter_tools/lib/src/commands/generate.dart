// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../context/tool_context.dart';
import '../runner/flutter_command.dart';

class GenerateCommand extends FlutterCommand {
  GenerateCommand({required ToolContext toolContext})
    : _toolContext = toolContext,
      super(toolContext: toolContext) {
    usesTargetOption();
  }

  final ToolContext _toolContext;

  @override
  String get description => 'run code generators.';

  @override
  String get name => 'generate';

  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    _toolContext.logger.printError(
      '"flutter generate" is deprecated, use "dart run build_runner" instead. '
      'The following dependencies must be added to dev_dependencies in pubspec.yaml:\n'
      'build_runner: ^1.10.0\n'
      'including all dependencies under the "builders" key',
    );
    return FlutterCommandResult.fail();
  }
}
