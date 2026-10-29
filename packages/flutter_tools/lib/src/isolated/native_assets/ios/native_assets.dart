// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';

import '../../../base/file_system.dart';
import '../../../base/logger.dart';
import '../../../base/process.dart';
import '../../../build_info.dart';
import '../macos/native_assets_host.dart';
import '../native_assets.dart';
import '../native_assets_manifest.dart';

// TODO(dcharkes): Fetch minimum iOS version from somewhere. https://github.com/flutter/flutter/issues/145104
const targetIOSVersion = 15;

IOSSdk getIOSSdk(EnvironmentType environmentType) {
  return switch (environmentType) {
    EnvironmentType.physical => IOSSdk.iPhoneOS,
    EnvironmentType.simulator => IOSSdk.iPhoneSimulator,
  };
}

/// Extract the [Architecture] from a [CpuArch].
Architecture getNativeIOSArchitecture(CpuArch cpuArch) {
  return switch (cpuArch) {
    CpuArch.armv7 => Architecture.arm,
    CpuArch.arm64 => Architecture.arm64,
    CpuArch.x64 => Architecture.x64,
    CpuArch.x86 ||
    CpuArch.riscv64 ||
    CpuArch.unknown => throw Exception('Unknown iOS CPU arch: $cpuArch.'),
  };
}

/// Groups native assets by their target framework path for iOS
/// multi-architecture bundling.
Map<Uri, List<FlutterCodeAsset>> fatAssetTargetLocationsIOS(
  List<FlutterCodeAsset> nativeAssets, {
  required Logger logger,
}) {
  return fatAssetTargetLocations(assetTargetLocationsIOS(nativeAssets, logger: logger));
}

Map<FlutterCodeAsset, FlutterCodeAssetTargetLocation> assetTargetLocationsIOS(
  List<FlutterCodeAsset> nativeAssets, {
  required Logger logger,
}) {
  return assetTargetLocationsApple(nativeAssets, logger: logger);
}

/// Copies native assets into a framework per dynamic library.
///
/// For `flutter run -release` a multi-architecture solution is needed. So,
/// `lipo` is used to combine all target architectures into a single file.
///
/// The install name is set so that it matches with the place it will
/// be bundled in the final app. Install names that are referenced in dependent
/// libraries are updated to match the new install name, so that the referenced
/// library can be found by the dynamic linker.
///
/// Code signing is also done here, so that it doesn't have to be done in
/// in xcode_backend.dart.
Future<List<File>> copyNativeCodeAssetsIOS(
  Uri targetUri,
  Map<Uri, List<FlutterCodeAsset>> assetTargetLocations,
  String? codesignIdentity,
  BuildMode buildMode,
  FileSystem fileSystem, {
  required Logger logger,
  required ProcessUtils processUtils,
}) async {
  assert(assetTargetLocations.isNotEmpty);
  final installedFiles = <File>[];
  final oldToNewInstallNames = <String, String>{};
  final dylibs = <(File, String, Directory)>[];

  for (final MapEntry<Uri, List<FlutterCodeAsset>> assetMapping in assetTargetLocations.entries) {
    final Uri target = assetMapping.key;
    final sources = <File>[
      for (final FlutterCodeAsset source in assetMapping.value)
        fileSystem.file(source.codeAsset.file),
    ];
    final Uri assetTargetUri = targetUri.resolveUri(target);
    final File dylibFile = fileSystem.file(assetTargetUri);
    final Directory frameworkDir = dylibFile.parent;
    if (!frameworkDir.existsSync()) {
      await frameworkDir.create(recursive: true);
    }
    await lipoDylibs(dylibFile, sources, processUtils: processUtils);
    installedFiles.add(dylibFile);

    if (buildMode != BuildMode.debug) {
      final dsymPath = '${frameworkDir.path}.dSYM';
      await dsymutilDylib(dylibFile, dsymPath, processUtils: processUtils);
      await stripDylib(dylibFile, logger: logger, processUtils: processUtils);
      installedFiles.addAll(
        fileSystem.directory(dsymPath).listSync(recursive: true).whereType<File>(),
      );
    }

    final String newInstallName = frameworkInstallName(target);
    final Set<String> oldInstallNames = await getInstallNamesDylib(
      dylibFile,
      processUtils: processUtils,
    );
    for (final oldInstallName in oldInstallNames) {
      oldToNewInstallNames[oldInstallName] = newInstallName;
    }
    dylibs.add((dylibFile, newInstallName, frameworkDir));

    await createInfoPlist(
      assetTargetUri.pathSegments.last,
      frameworkDir,
      minimumIOSVersion: '$targetIOSVersion.0',
    );
    installedFiles.add(frameworkDir.childFile('Info.plist'));
  }

  for (final (File dylibFile, String newInstallName, Directory frameworkDir) in dylibs) {
    await setInstallNamesDylib(
      dylibFile,
      newInstallName,
      oldToNewInstallNames,
      processUtils: processUtils,
    );
    await codesignDylib(codesignIdentity, buildMode, frameworkDir, processUtils: processUtils);
  }
  return installedFiles;
}
