// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:process/process.dart';

import '../../../base/common.dart';
import '../../../base/file_system.dart';
import '../../../base/logger.dart';
import '../../../base/os.dart';
import '../../../base/platform.dart';
import '../../../context/tool_context.dart';
import '../../../windows/visual_studio.dart';

/// Returns the [CCompilerConfig] for Windows by locating the active Visual Studio toolchain.
///
/// If a suitable Visual Studio installation is not found:
/// * Throws a [ToolExit] if [throwIfNotFound] is true.
/// * Returns null if [throwIfNotFound] is false.
Future<CCompilerConfig?> cCompilerConfigWindows({
  required bool throwIfNotFound,
  required ToolContext toolContext,
}) async {
  final ToolContext(
    :FileSystem fs,
    :Logger logger,
    :OperatingSystemUtils os,
    :Platform platform,
    :ProcessManager processManager,
  ) = toolContext;
  final visualStudio = VisualStudio(
    fileSystem: fs,
    platform: platform,
    logger: logger,
    processManager: processManager,
    osUtils: os,
  );

  final Uri? compiler = _toOptionalFileUri(visualStudio.clPath);
  final Uri? archiver = _toOptionalFileUri(visualStudio.libPath);
  final Uri? linker = _toOptionalFileUri(visualStudio.linkPath);
  final Uri? envScript = _toOptionalFileUri(visualStudio.vcvarsPath);

  if (compiler == null || archiver == null || linker == null || envScript == null) {
    if (throwIfNotFound) {
      throwToolExit(
        'Unable to find suitable Visual Studio toolchain. '
        'Please run `flutter doctor` for more details.',
      );
    }
    return null;
  }

  return CCompilerConfig(
    compiler: compiler,
    archiver: archiver,
    linker: linker,
    windows: WindowsCCompilerConfig(
      developerCommandPrompt: DeveloperCommandPrompt(script: envScript, arguments: <String>[]),
    ),
  );
}

Uri? _toOptionalFileUri(String? string) {
  if (string == null) {
    return null;
  }
  return Uri.file(string);
}
