


import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart';

import '../build_runner/build_runner.dart';
import '../runner/flutter_command.dart';

class GenerateCommand extends FlutterCommand {
  @override
  String get description => 'run build_runner code generation';

  @override
  String get name => 'generate';

  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    if (!await experimentalBuildEnabled) {
      printTrace('Experimental flutter build not enabled. Exiting...');
      return const FlutterCommandResult(ExitStatus.fail);
    }
    final BuildRunner buildRunner = BuildRunner();
    final Status status = logger.startProgress(
      'Running builders...',
      timeout: null,
    );
    try {
      await buildRunner.codegen();
    } on Exception {
      status?.cancel();
      return const FlutterCommandResult(ExitStatus.fail);
    }
    status.stop();
    return const FlutterCommandResult(ExitStatus.success);
  }
}