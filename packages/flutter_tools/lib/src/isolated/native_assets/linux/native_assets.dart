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
  const kClangBinary = 'clang';
  const kArBinary = 'llvm-ar';
  const kLdBinary = 'ld.lld';

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
  final binaryPaths = <String, Uri>{};
  for (final binary in <String>[kClangBinary, kArBinary, kLdBinary]) {
    final File binaryFile = clangDir.childFile(binary);
    if (!await binaryFile.exists()) {
      throwToolExit("Failed to find $binary relative to $clangPpFile: $binaryFile doesn't exist.");
    }
    binaryPaths[binary] = binaryFile.uri;
  }
  final Uri? archiver = binaryPaths[kArBinary];
  final Uri? compiler = binaryPaths[kClangBinary];
  final Uri? linker = binaryPaths[kLdBinary];
  if (archiver == null || compiler == null || linker == null) {
    throwToolExit('Clang could not be found.');
  }
  return CCompilerConfig(archiver: archiver, compiler: compiler, linker: linker);
}
