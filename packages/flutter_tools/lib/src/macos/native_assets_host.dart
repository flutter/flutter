// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Shared logic between iOS and macOS implementations of native assets.

import 'package:native_assets_cli/native_assets_cli.dart' hide BuildMode;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../build_info.dart';
import '../convert.dart';
import '../globals.dart' as globals;

/// The target location for native assets on macOS.
///
/// Because we need to have a multi-architecture solution for
/// `flutter run --release`, we use `lipo` to combine all target architectures
/// into a single file.
///
/// We need to set the install name so that it matches what the place it will
/// be bundled in the final app.
///
/// Code signing is also done here, so that we don't have to worry about it
/// in xcode_backend.dart and macos_assemble.sh.
Future<void> copyNativeAssetsMacOSHost(
  Uri buildUri,
  Map<AssetPath, List<Asset>> assetTargetLocations,
  String? codesignIdentity,
  BuildMode buildMode,
  FileSystem fileSystem,
) async {
  if (assetTargetLocations.isNotEmpty) {
    globals.logger.printTrace('Copying native assets to ${buildUri.toFilePath()}.');
    final Directory buildDir = fileSystem.directory(buildUri.toFilePath());
    if (!buildDir.existsSync()) {
      buildDir.createSync(recursive: true);
    }
    for (final MapEntry<AssetPath, List<Asset>> assetMapping in assetTargetLocations.entries) {
      final Uri target = (assetMapping.key as AssetAbsolutePath).uri;
      final List<Uri> sources = <Uri>[for (final Asset source in assetMapping.value) (source.path as AssetAbsolutePath).uri];
      final Uri targetUri = buildUri.resolveUri(target);
      final String targetFullPath = targetUri.toFilePath();
      await lipoDylibs(targetFullPath, sources);
      await setInstallNameDylib(targetUri);
      await codesignDylib(codesignIdentity, buildMode, targetFullPath);
    }
    globals.logger.printTrace('Copying native assets done.');
  }
}

/// Combines dylibs from [sources] into a fat binary at [targetFullPath].
///
/// The dylibs must have different architectures. E.g. a dylib targeting
/// arm64 ios simulator cannot be combined with a dylib targeting arm64
/// ios device or macos arm64.
Future<void> lipoDylibs(String targetFullPath, List<Uri> sources) async {
  final ProcessResult lipoResult = await globals.processManager.run(
    <String>[
      'lipo',
      '-create',
      '-output',
      targetFullPath,
      for (final Uri source in sources) source.toFilePath(),
    ],
  );
  if (lipoResult.exitCode != 0) {
    throwToolExit('Failed to create universal binary:\n${lipoResult.stderr}');
  }
  globals.logger.printTrace(lipoResult.stdout as String);
  globals.logger.printTrace(lipoResult.stderr as String);
}

/// Sets the install name in a dylib with a Mach-O format.
///
/// On macOS and iOS, opening a dylib at runtime fails if the path inside the
/// dylib itself does not correspond to the path that the file is at. Therefore,
/// native assets copied into their final location also need their install name
/// updated with the `install_name_tool`.
Future<void> setInstallNameDylib(Uri targetUri) async {
  final String fileName = targetUri.pathSegments.last;
  final ProcessResult installNameResult = await globals.processManager.run(
    <String>[
      'install_name_tool',
      '-id',
      '@executable_path/Frameworks/$fileName',
      targetUri.toFilePath(),
    ],
  );
  if (installNameResult.exitCode != 0) {
    throwToolExit('Failed to change the install name of $targetUri:\n${installNameResult.stderr}');
  }
}

Future<void> codesignDylib(
  String? codesignIdentity,
  BuildMode buildMode,
  String targetFullPath,
) async {
  if (codesignIdentity == null || codesignIdentity.isEmpty) {
    codesignIdentity = '-';
  }
  final List<String> codesignCommand = <String>[
    'codesign',
    '--force',
    '--sign',
    codesignIdentity,
    if (buildMode != BuildMode.release) ...<String>[
      // Mimic Xcode's timestamp codesigning behavior on non-release binaries.
      '--timestamp=none',
    ],
    targetFullPath,
  ];
  globals.logger.printTrace(codesignCommand.join(' '));
  final ProcessResult codesignResult = await globals.processManager.run(codesignCommand);
  if (codesignResult.exitCode != 0) {
    throwToolExit('Failed to code sign binary:\n${codesignResult.stderr}');
  }
  globals.logger.printTrace(codesignResult.stdout as String);
  globals.logger.printTrace(codesignResult.stderr as String);
}

/// Flutter expects `xcrun` to be on the path on macOS hosts.
///
/// Use the `clang`, `ar`, and `ld` that would be used if run with `xcrun`.
Future<CCompilerConfig> cCompilerConfigMacOS() async {
  final ProcessResult xcrunResult = await globals.processManager.run(<String>['xcrun', 'clang', '--version']);
  if (xcrunResult.exitCode != 0) {
    throwToolExit('Failed to find clang with xcrun:\n${xcrunResult.stderr}');
  }
  final String installPath = LineSplitter.split(xcrunResult.stdout as String)
    .firstWhere((String s) => s.startsWith('InstalledDir: '))
    .split(' ')
    .last;
  return CCompilerConfig(
    cc: Uri.file('$installPath/clang'),
    ar: Uri.file('$installPath/ar'),
    ld: Uri.file('$installPath/ld'),
  );
}
