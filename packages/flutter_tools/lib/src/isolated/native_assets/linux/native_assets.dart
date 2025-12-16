// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';

import '../../../base/common.dart';
import '../../../base/file_system.dart';
import '../../../base/io.dart';
import '../../../globals.dart' as globals;

/// Returns a [CCompilerConfig] matching a toolchain that would be used to compile the main app with
/// CMake on Linux.
///
/// Flutter expects `clang++` to be on the path on Linux hosts, which this uses to search for the
/// accompanying `clang`, `ar`, and `ld`.
///
/// If [throwIfNotFound] is false, this is allowed to fail (in which case `null`) is returned. This
/// is used for `flutter test` setups, where no main app is compiled and we thus don't want a
/// `clang` toolchain to be a requirement.
Future<CCompilerConfig?> cCompilerConfigLinux({required bool throwIfNotFound}) async {
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
    if (throwIfNotFound) {
      throwToolExit('Failed to find $kClangPlusPlusBinary on PATH.');
    } else {
      return null;
    }
  }
  File clangPpFile = globals.fs.file((whichResult.stdout as String).trim());
  clangPpFile = globals.fs.file(await clangPpFile.resolveSymbolicLinks());

  final Directory clangDir = clangPpFile.parent;
  Uri? findExecutable({required List<String> possibleExecutableNames, required Directory path}) {
    final Uri? found = _findExecutableIfExists(
      possibleExecutableNames: possibleExecutableNames,
      path: path,
    );

    if (found == null && throwIfNotFound) {
      throwToolExit('Failed to find any of $possibleExecutableNames in $path');
    }

    return found;
  }

  final Uri? linker = findExecutable(path: clangDir, possibleExecutableNames: kLdBinaryOptions);
  final Uri? compiler = findExecutable(
    path: clangDir,
    possibleExecutableNames: kClangBinaryOptions,
  );
  final Uri? archiver = findExecutable(path: clangDir, possibleExecutableNames: kArBinaryOptions);

  if (linker == null || compiler == null || archiver == null) {
    assert(!throwIfNotFound); // otherwise, findExecutable would have thrown
    return null;
  }
  return CCompilerConfig(linker: linker, compiler: compiler, archiver: archiver);
}

/// Searches for an executable with a name in [possibleExecutableNames]
/// at [path] and returns the first one it finds, if one is found.
/// Otherwise, returns `null`.
Uri? _findExecutableIfExists({
  required List<String> possibleExecutableNames,
  required Directory path,
}) {
  return possibleExecutableNames
      .map((execName) => path.childFile(execName))
      .where((file) => file.existsSync())
      .map((file) => file.uri)
      .firstOrNull;
}
