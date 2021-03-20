// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../macos/xcode.dart';

const bool kBitcodeEnabledDefault = false;

Future<void> validateBitcode(BuildMode buildMode, TargetPlatform targetPlatform, EnvironmentType environmentType) async {
  final Artifacts localArtifacts = globals.artifacts;
  final String flutterFrameworkPath = localArtifacts.getArtifactPath(
    Artifact.flutterFramework,
    mode: buildMode,
    platform: targetPlatform,
    environmentType: environmentType,
  );
  final Xcode xcode = context.get<Xcode>();

  final RunResult clangResult = await xcode.clang(<String>['--version']);
  final String clangVersion = clangResult.stdout.split('\n').first;
  final String engineClangVersion = globals.plistParser.getValueFromFile(
    globals.fs.path.join(flutterFrameworkPath, 'Info.plist'),
    'ClangVersion',
  );
  final Version engineClangSemVer = _parseVersionFromClang(engineClangVersion);
  final Version clangSemVer = _parseVersionFromClang(clangVersion);
  if (engineClangSemVer > clangSemVer) {
    throwToolExit(
      'The Flutter.framework at $flutterFrameworkPath was built '
      'with "${engineClangVersion ?? 'unknown'}", but the current version '
      'of clang is "$clangVersion". This will result in failures when trying to '
      'archive an IPA. To resolve this issue, update your version of Xcode to '
      'at least $engineClangSemVer.',
    );
  }
}

Version _parseVersionFromClang(String clangVersion) {
  final RegExp pattern = RegExp(r'Apple (LLVM|clang) version (\d+\.\d+\.\d+) ');
  void _invalid() {
    throwToolExit('Unable to parse Clang version from "$clangVersion". '
                  'Expected a string like "Apple (LLVM|clang) #.#.# (clang-####.#.##.#)".');
  }

  if (clangVersion == null || clangVersion.isEmpty) {
    _invalid();
  }
  final RegExpMatch match = pattern.firstMatch(clangVersion);
  if (match == null || match.groupCount != 2) {
    _invalid();
  }
  final Version version = Version.parse(match.group(2));
  if (version == null) {
    _invalid();
  }
  return version;
}
