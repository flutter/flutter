// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';

import '../../../base/common.dart';
import '../../../base/file_system.dart';
import '../../../convert.dart';
import '../../../globals.dart' as globals;

/// Returns a [CCompilerConfig] suitable for compiling code assets for Linux apps.
///
/// For app builds, [cmakeDirectory] must be given and point to the CMake build root for the app,
/// e.g. `build/linux/x64/debug`. The compiler configuration is resolved by reading the
/// `CMakeCache.txt` file in that directory to ensure we use the same compiler as the main app.
///
/// Flutter also builds code assets for widget tests. Since there is no app build in that context,
/// [cmakeDirectory] should be set to null for those builds.
Future<CCompilerConfig?> cCompilerConfigLinux({Directory? cmakeDirectory}) async {
  if (cmakeDirectory == null) {
    // No CMake reference (e.g. for a widget test). Hooks can resolve to any
    // compiler.
    return null;
  }

  // For app builds, use the same compiler as the native/GTK parts of the app.
  final File cmakeCacheTxt = cmakeDirectory.childFile('CMakeCache.txt');
  if (!cmakeCacheTxt.existsSync()) {
    throwToolExit(
      'Could not read compiler configurations for build hooks, expected ${cmakeCacheTxt.path} to exist.',
    );
  }

  const archiverVariable = 'CMAKE_AR';
  // Flutter CMake projects use `LANGUAGES CXX`, so we can't read a configured C
  // compiler directly. We read the C++ compiler and infer the C compiler from
  // there.
  const compilerVariable = 'CMAKE_CXX_COMPILER';
  const linkerVariable = 'CMAKE_LINKER';

  String? archiver;
  String? cxxCompiler;
  String? linker;

  final String cmakeCacheContents = await cmakeCacheTxt.readAsString();
  for (final String line in const LineSplitter().convert(cmakeCacheContents)) {
    final RegExpMatch? match = _cmakeCacheEntry.firstMatch(line);
    if (match != null) {
      final String variable = match.group(1)!;
      final String value = match.group(2)!;

      switch (variable) {
        case archiverVariable:
          archiver = value;
        case compilerVariable:
          cxxCompiler = value;
        case linkerVariable:
          linker = value;
      }
    }
  }

  Uri requireTool(String? found, String variableName) {
    if (found == null) {
      throwToolExit('Expected ${cmakeCacheTxt.path} to contain an entry for $variableName');
    }

    final File file = globals.fs.file(found);
    if (!file.existsSync()) {
      throwToolExit(
        'Expected ${file.path} (read from $variableName in ${cmakeCacheTxt.path}) to exist.',
      );
    }

    return file.uri;
  }

  // Find clang next to the clang++ we use in CMake
  File clangPpFile = globals.fs.file(requireTool(cxxCompiler, compilerVariable));
  clangPpFile = globals.fs.file(await clangPpFile.resolveSymbolicLinks());
  final File clangFile = clangPpFile.parent.childFile('clang');
  if (!clangFile.existsSync()) {
    throwToolExit('Expected to find clang next to ${clangPpFile.path}');
  }

  return CCompilerConfig(
    compiler: clangFile.uri,
    linker: requireTool(linker, linkerVariable),
    archiver: requireTool(archiver, archiverVariable),
  );
}

// Format: `VARIABLE_NAME:TYPE=value`;
final RegExp _cmakeCacheEntry = RegExp(r'^(\w+):\w+=(.*)$');
