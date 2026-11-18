// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';

import '../../../base/file_system.dart';
import '../../../base/logger.dart';
import '../../../base/process.dart';
import '../../../build_info.dart';
import '../native_assets.dart';
import '../native_assets_manifest.dart';
import 'native_assets_host.dart';

// TODO(dcharkes): Fetch minimum MacOS version from somewhere. https://github.com/flutter/flutter/issues/145104
const targetMacOSVersion = 13;

/// Extract the [Architecture] from a [CpuArch].
Architecture getNativeMacOSArchitecture(CpuArch cpuArch) {
  return switch (cpuArch) {
    .arm64 => Architecture.arm64,
    .x64 => Architecture.x64,
    _ => throw Exception('Unknown macOS CPU arch: $cpuArch.'),
  };
}

/// Groups native assets by their target framework path for macOS
/// multi-architecture bundling.
Map<Uri, List<FlutterCodeAsset>> fatAssetTargetLocationsMacOS(
  List<FlutterCodeAsset> nativeAssets,
  Uri? absolutePath, {
  required Logger logger,
}) {
  return fatAssetTargetLocations(
    assetTargetLocationsMacOS(nativeAssets, absolutePath, logger: logger),
  );
}

Map<FlutterCodeAsset, FlutterCodeAssetTargetLocation> assetTargetLocationsMacOS(
  List<FlutterCodeAsset> nativeAssets,
  Uri? absolutePath, {
  required Logger logger,
}) {
  return assetTargetLocationsApple(nativeAssets, absolutePath: absolutePath, logger: logger);
}

/// Copies native assets into a framework per dynamic library.
///
/// The framework contains symlinks according to
/// https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFrameworks/Concepts/FrameworkAnatomy.html
///
/// For `flutter run -release` a multi-architecture solution is needed. So,
/// `lipo` is used to combine all target architectures into a single file.
///
/// The install name is set so that it matches with the place it will
/// be bundled in the final app. Install names that are referenced in dependent
/// libraries are updated to match the new install name, so that the referenced
/// library can be found the dynamic linker.
///
/// Code signing is also done here, so that it doesn't have to be done in
/// in macos_assemble.sh.
Future<List<File>> copyNativeCodeAssetsMacOS(
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
    final String name = assetTargetUri.pathSegments.last;
    final Directory frameworkDir = fileSystem.file(assetTargetUri).parent;
    if (frameworkDir.existsSync()) {
      await frameworkDir.delete(recursive: true);
    }
    // MyFramework.framework/                           frameworkDir
    //   MyFramework  -> Versions/Current/MyFramework   dylibLink
    //   Resources    -> Versions/Current/Resources     resourcesLink
    //   Versions/                                      versionsDir
    //     A/                                           versionADir
    //       MyFramework                                dylibFile
    //       Resources/                                 resourcesDir
    //         Info.plist
    //     Current  -> A                                currentLink
    final Directory versionsDir = frameworkDir.childDirectory('Versions');
    final Directory versionADir = versionsDir.childDirectory('A');
    final Directory resourcesDir = versionADir.childDirectory('Resources');
    await resourcesDir.create(recursive: true);
    final File dylibFile = versionADir.childFile(name);
    final Link currentLink = versionsDir.childLink('Current');
    final Directory currentLinkAsDirectory = versionsDir.childDirectory('Current');

    await currentLink.create(
      fileSystem.path.relative(versionADir.path, from: currentLink.parent.path),
    );
    final Link resourcesLink = frameworkDir.childLink('Resources');
    await resourcesLink.create(
      fileSystem.path.relative(
        currentLinkAsDirectory.childFile('Resources').path,
        from: resourcesLink.parent.path,
      ),
    );
    await lipoDylibs(dylibFile, sources, processUtils: processUtils);
    if (buildMode != BuildMode.debug) {
      final dsymPath = '${frameworkDir.path}.dSYM';
      await dsymutilDylib(dylibFile, dsymPath, processUtils: processUtils);
      await stripDylib(dylibFile, logger: logger, processUtils: processUtils);
      installedFiles.addAll(
        fileSystem.directory(dsymPath).listSync(recursive: true).whereType<File>(),
      );
    }
    final Link dylibLink = frameworkDir.childLink(name);
    await dylibLink.create(
      fileSystem.path.relative(
        currentLinkAsDirectory.childFile(name).path,
        from: dylibLink.parent.path,
      ),
    );

    final String newInstallName = frameworkInstallName(target);
    final Set<String> oldInstallNames = await getInstallNamesDylib(
      dylibFile,
      processUtils: processUtils,
    );
    for (final oldInstallName in oldInstallNames) {
      oldToNewInstallNames[oldInstallName] = newInstallName;
    }
    dylibs.add((dylibFile, newInstallName, frameworkDir));

    await createInfoPlist(name, resourcesDir);
    installedFiles.addAll(frameworkDir.listSync(recursive: true).whereType<File>());
  }

  for (final (File dylibFile, String newInstallName, Directory frameworkDir) in dylibs) {
    await setInstallNamesDylib(
      dylibFile,
      newInstallName,
      oldToNewInstallNames,
      processUtils: processUtils,
    );
    // Do not code-sign the libraries here with identity. Code-signing
    // for bundled dylibs is done in `macos_assemble.sh embed` because the
    // "Flutter Assemble" target does not have access to the signing identity.
    if (codesignIdentity != null) {
      await codesignDylib(codesignIdentity, buildMode, frameworkDir, processUtils: processUtils);
    }
  }
  return installedFiles;
}

/// Copies native assets for flutter tester.
///
/// For `flutter run -release` a multi-architecture solution is needed. So,
/// `lipo` is used to combine all target architectures into a single file.
///
/// The install names are set to the absolute paths from which the
/// flutter_tester executable with load them. Install names that are
/// referenced in dependent libraries are updated to match the new install name,
/// so that the referenced library can be found the dynamic linker.
///
/// A dylib whose header has no room for the new load commands, such as a
/// prebuilt one linked without `-headerpad_max_install_names`, keeps its own
/// install name, and [logger] prints a warning. Its dependents and the native
/// assets manifest still use the absolute path. dyld matches a load against
/// the path an image was loaded from, so every load of that path gets the same
/// image. After a later run replaced the file this holds only for a canonical
/// path, since dyld records an image under its real path, so a dylib keeps its
/// install name only in a directory without symlinks. The kept install name
/// also stays visible to dyld for the rest of the process: a later load of
/// that `@rpath/` name, or of its bare file name, gets this image. App builds
/// must not keep install names: there the manifest entry is the install name,
/// which has to match (https://github.com/flutter/flutter/issues/190799).
///
/// A dylib without room still fails if changing its references to other code
/// assets makes its load commands larger, as for a prebuilt that references
/// them by `@rpath/` names.
///
/// Code signing is also done here.
Future<List<File>> copyNativeCodeAssetsMacOSFlutterTester(
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
  final dylibs =
      <({File dylibFile, String newInstallName, String assetId, String oldInstallName})>[];

  for (final MapEntry<Uri, List<FlutterCodeAsset>> assetMapping in assetTargetLocations.entries) {
    final Uri target = assetMapping.key;
    final sources = <File>[
      for (final FlutterCodeAsset source in assetMapping.value)
        fileSystem.file(source.codeAsset.file),
    ];
    final Uri assetTargetUri = targetUri.resolveUri(target);
    final File dylibFile = fileSystem.file(assetTargetUri);
    final Directory targetParent = dylibFile.parent;
    if (!targetParent.existsSync()) {
      await targetParent.create(recursive: true);
    }
    await lipoDylibs(dylibFile, sources, processUtils: processUtils);
    installedFiles.add(dylibFile);
    final String newInstallName = dylibFile.path;
    final Set<String> oldInstallNames = await getInstallNamesDylib(
      dylibFile,
      processUtils: processUtils,
    );
    for (final oldInstallName in oldInstallNames) {
      oldToNewInstallNames[oldInstallName] = newInstallName;
    }
    dylibs.add((
      dylibFile: dylibFile,
      newInstallName: newInstallName,
      assetId: assetMapping.value.first.codeAsset.id,
      oldInstallName: oldInstallNames.join(', '),
    ));
  }

  for (final (:File dylibFile, :String newInstallName, :String assetId, :String oldInstallName)
      in dylibs) {
    // Through a symlink, a file replaced under a running tester would load as
    // a second copy unless its install name is the path it is loaded from.
    final Directory directory = dylibFile.parent;
    final canonical = directory.resolveSymbolicLinksSync() == directory.path;
    final bool installNameSet = await setInstallNamesDylib(
      dylibFile,
      newInstallName,
      oldToNewInstallNames,
      processUtils: processUtils,
      keepInstallNameIfItDoesNotFit: canonical,
    );
    if (!installNameSet) {
      // Not fatal: the asset loads correctly, so `--fatal-warnings` should not
      // fail the run of a package that cannot relink a vendor's dylib. (Under
      // `-v`, VerboseLogger still counts every warning, `fatal` or not.)
      logger.printWarning(
        'Code asset "$assetId" keeps its install name "$oldInstallName", because '
        'the header of ${dylibFile.basename} has no room for its new install name '
        'and dependency paths. The asset still loads. Linking the dylib with '
        '-headerpad_max_install_names avoids this.',
        fatal: false,
      );
    }
    await codesignDylib(codesignIdentity, buildMode, dylibFile, processUtils: processUtils);
  }
  return installedFiles;
}
