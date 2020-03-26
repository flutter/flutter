// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/utils.dart';
import '../build_info.dart';

/// A service to locate APK files output by Gradle.
class ApkLocator {
  ApkLocator({
    @required FileSystem fileSystem,
  }) : _fileSystem = fileSystem;

  final FileSystem _fileSystem;

  /// Retreive a list of candidate bunldes in [root].
  ///
  /// If more than one APK is located, the returned list is in order of
  /// decreasing likeliness to be correct.
  ///
  /// Only files that match the provided file extension are considered.
  List<File> locate(Directory apkDirectory, {
    Set<String> excludePaths = const <String>{},
    @required AndroidBuildInfo androidBuildInfo,
  }) {
    // First check if the tool can find the exact file.
    final List<File> exactFiles = <File>[];
    final BuildInfo buildInfo = androidBuildInfo.buildInfo;
    final String modeName = camelCase(buildInfo.modeName);

    for (final String fileName in _apkFilesNamesFor(androidBuildInfo)) {
      final File apkFile = apkDirectory
        .childDirectory(modeName)
        .childFile(fileName);
      if (apkFile.existsSync()) {
        exactFiles.add(apkFile);
        continue;
      }

      if (buildInfo.flavor != null) {
        // Android Studio Gradle plugin v3 adds flavor to path.
        final File apkFile = apkDirectory
          .childDirectory(buildInfo.flavor)
          .childDirectory(modeName)
          .childFile(fileName);
        if (apkFile.existsSync()) {
          exactFiles.add(apkFile);
          continue;
        }
      }
    }

    // If at least one APK file was found, skip the heuristics.
    if (exactFiles.isNotEmpty) {
      return exactFiles;
    }
    if (!apkDirectory.existsSync()) {
      return const <File>[];
    }

    // If the process has reached this point, the tool was unable to determine
    // the exact APK name. Apply heursitics to sort more likely candiates towards
    // the start of the list.
    bool filter(File file) {
      // The file is not a .apk
      if (!_fileSystem.path.basename(file.path).endsWith('.apk')) {
        return false;
      }
      // The file is an exclude file, such as app.apk where the output
      // is copied to.
      final String relativePath = _fileSystem.path
        .relative(file.path, from: apkDirectory.path);
      if (excludePaths.contains(relativePath)) {
        return false;
      }
      return true;
    }

    int sort(File a, File b) {
      // Check whether the apk contains a string for the build mode, either
      // in the file name or directory path.
      final String buildModeName = getNameForBuildMode(androidBuildInfo.buildInfo.mode);
      final bool aContainsBuildMode = a.path
        .contains(buildModeName);
      final bool bContainsBuildMode = b.path
        .contains(buildModeName);
      if (aContainsBuildMode && !bContainsBuildMode) {
        return -1;
      } else if (!aContainsBuildMode && bContainsBuildMode) {
        return 1;
      }

      // Check if the flavor name is contained in the apk or path
      // when a flavor is involved.
      if (androidBuildInfo.buildInfo.flavor?.isNotEmpty ?? false) {
        final bool aContainsFlavorName = a.path
          .contains(androidBuildInfo.buildInfo.flavor);
        final bool bContainsFlavorName = b.path
          .contains(androidBuildInfo.buildInfo.flavor);
        if (aContainsFlavorName && !bContainsFlavorName) {
          return -1;
        } else if (!aContainsFlavorName && bContainsFlavorName) {
          return 1;
        }
      }

      // Check which apk file was most recently updated.
      return b.lastModifiedSync().compareTo(a.lastModifiedSync());
    }

    return apkDirectory
      .listSync(recursive: true)
      .whereType<File>()
      .where(filter)
      .toList()
      ..sort(sort);
  }

  /// Returns the output APK file names for a given [AndroidBuildInfo].
  ///
  /// For example, when [splitPerAbi] is true, multiple APKs are created.
  List<String> _apkFilesNamesFor(AndroidBuildInfo androidBuildInfo) {
    final String buildType = getNameForBuildMode(androidBuildInfo.buildInfo.mode);
    final String productFlavor = androidBuildInfo.buildInfo.flavor ?? '';
    final String flavorString = productFlavor.isEmpty ? '' : '-$productFlavor';
    if (androidBuildInfo.splitPerAbi) {
      return androidBuildInfo.targetArchs.map<String>((AndroidArch arch) {
        final String abi = getNameForAndroidArch(arch);
        return 'app$flavorString-$abi-$buildType.apk';
      }).toList();
    }
    return <String>['app$flavorString-$buildType.apk'];
  }
}
