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
/// Search for the accompanying `clang`, `ar`, and `ld`.
Future<CCompilerConfig> cCompilerConfigLinux() async {
  const kClangPlusPlusBinary = 'clang++';
  // NOTE: these binaries sometimes have different names depending on the installation;
  // thus, we check for a few possible options (in order of preference).
  const kClangBinaryOptions = ['clang'];
  const kArBinaryOptions = ['llvm-ar', 'ar'];
  const kLdBinaryOptions = ['ld.lld', 'ld'];

  final ProcessResult whichResult = await globals.processManager.run(<String>[
    'which',
    kClangPlusPlusBinary,
  ]);
  if (whichResult.exitCode != 0) {
    throwToolExit('Failed to find $kClangPlusPlusBinary on PATH.');
  }
  File clangPpFile = globals.fs.file((whichResult.stdout as String).trim());
  clangPpFile = globals.fs.file(await clangPpFile.resolveSymbolicLinks());

  final Directory clangDir = clangPpFile.parent;
  return CCompilerConfig(
    linker: _findExecutableIfExists(path: clangDir, possibleExecutableNames: kLdBinaryOptions),
    compiler: _findExecutableIfExists(path: clangDir, possibleExecutableNames: kClangBinaryOptions),
    archiver: _findExecutableIfExists(path: clangDir, possibleExecutableNames: kArBinaryOptions),
  );
}

/// Searches for an executable with a name in [possibleExecutableNames]
/// at [path] and returns the first one it finds, if one is found.
/// Otherwise, throws an error.
Uri _findExecutableIfExists({
  required List<String> possibleExecutableNames,
  required Directory path,
}) {
  return possibleExecutableNames
          .map((execName) => path.childFile(execName))
          .where((file) => file.existsSync())
          .map((file) => file.uri)
          .firstOrNull ??
      throwToolExit('Failed to find any of $possibleExecutableNames in $path');
}
