// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';

import '../../../base/common.dart';
import '../../../base/file_system.dart';
import '../../../base/io.dart';
import '../../../globals.dart' as globals;

/// Flutter expects `clang++` to be on the path on Linux hosts.
///
/// Search for the accompanying `clang`, `ar`, and `ld`, if they can be found.
/// Otherwise, default to looking on the `PATH`,
/// as some systems do not ship these executables together.
Future<CCompilerConfig> cCompilerConfigLinux() async {
  const kClangPlusPlusBinary = 'clang++';
  const kClangBinary = 'clang';
  const kArBinary = 'llvm-ar';
  const kLdBinary = 'ld.lld';

  final File clangPpFile = await _findExecutable(kClangPlusPlusBinary);
  final Directory clangDir = clangPpFile.parent;

  return CCompilerConfig(
    linker: (await _findExecutable(kLdBinary, preferredPath: clangDir)).uri,
    archiver: (await _findExecutable(kArBinary, preferredPath: clangDir)).uri,
    compiler: (await _findExecutable(kClangBinary, preferredPath: clangDir)).uri,
  );
}

/// Finds [executableName] if it exists in the [preferredPath] (if provided).
/// Otherwise, defaults to looking in the `PATH`.
///
/// If [executableName] cannot be found in either of these locations,
/// an error is thrown.
Future<File> _findExecutable(String executableName, {Directory? preferredPath}) async {
  // If we can find the executable at the preferred path, use it
  if (preferredPath != null) {
    final File binaryFile = preferredPath.childFile(executableName);
    if (await binaryFile.exists()) {
      return binaryFile;
    }
  }

  // Otherwise, default to checking the PATH
  final ProcessResult whichResult = await globals.processManager.run(<String>[
    'which',
    executableName,
  ]);
  if (whichResult.exitCode != 0) {
    throwToolExit(
      preferredPath != null
          ? 'Failed to find $executableName in $preferredPath and on PATH'
          : 'Failed to find $executableName on PATH.',
    );
  }

  final File executableFile = globals.fs.file((whichResult.stdout as String).trim());
  return globals.fs.file(await executableFile.resolveSymbolicLinks());
}
