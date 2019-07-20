// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../compile.dart';
import '../globals.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommand, FlutterCommandResult;

class BuildKernelCommand extends FlutterCommand {
  BuildKernelCommand({bool verboseHelp = false}) {
    usesTargetOption();
    usesFilesystemOptions(hide: !verboseHelp);
    argParser.addOption(
      'output',
      abbr: 'o',
      defaultsTo: 'app.dill',
      help: 'The name of the output dill file.',
    );
  }

  @override
  bool get hidden => true;

  @override
  final String name = 'kernel';

  @override
  final String description = 'Build a dart script into a kernel file.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(FlutterProject.current());
    final CompilerOutput output = await kernelCompiler.compile(
      trackWidgetCreation: false,
      targetModel: TargetModel.vm,
      mainPath: targetFile,
      packagesPath: '.packages',
      sdkRoot: fs.path.join(artifacts.getArtifactPath(Artifact.engineDartSdkPath), 'lib', '_internal'),
      platformDill: 'vm_platform_strong.dill',
      outputFilePath: argResults['output']
    );
    if (output.errorCount != 0) {
      throwToolExit('Failed to compile $targetFile');
    }
    printStatus(output.outputFilename);
    return null;
  }
}
