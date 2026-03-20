// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/version.dart';
import '../convert.dart';
import '../flutter_plugins.dart';
import '../macos/swift_package_manager.dart';
import '../plugins.dart';
import '../project.dart';
import 'darwin.dart';

final class XcodeBuildFailureDiagnostics {
  static XcodeBuildFailureOutputAnalysis analyzeOutput(String? output) {
    if (output == null || output.isEmpty) {
      return const XcodeBuildFailureOutputAnalysis();
    }

    final duplicateModules = <String>{};
    final missingModules = <String>{};
    XcodeBuildFailurePlatformMismatch? highestPlatformMismatch;

    for (final RegExpMatch match in _swiftPackageManagerMinPlatformMismatchPattern.allMatches(
      output,
    )) {
      final String? requiredByProduct = match.group(1);
      final Version? requiredMinVersion = Version.parse(match.group(2));
      final Version? targetSupportedVersion = Version.parse(match.group(4));
      final String? targetName = match.group(5);
      if (targetName != kFlutterGeneratedPluginSwiftPackageName ||
          requiredByProduct == null ||
          requiredMinVersion == null ||
          targetSupportedVersion == null) {
        continue;
      }
      if (highestPlatformMismatch == null ||
          requiredMinVersion > highestPlatformMismatch.requiredVersion) {
        highestPlatformMismatch = XcodeBuildFailurePlatformMismatch(
          requiredByProduct: requiredByProduct,
          requiredVersion: requiredMinVersion,
          supportedVersion: targetSupportedVersion,
        );
      }
    }

    for (final String line in LineSplitter.split(output)) {
      final String? duplicateModule = parseModuleRedefinition(line);
      if (duplicateModule != null) {
        duplicateModules.add(duplicateModule);
      }

      final String? missingModule = parseMissingModule(line);
      if (missingModule != null) {
        missingModules.add(missingModule);
      }
    }

    final String? duplicateSymbolModule = parseDuplicateSymbols(output);
    if (duplicateSymbolModule != null) {
      duplicateModules.add(duplicateSymbolModule);
    }

    return XcodeBuildFailureOutputAnalysis(
      platformMismatch: highestPlatformMismatch,
      duplicateModules: duplicateModules,
      missingModules: missingModules,
    );
  }

  static String? parseModuleRedefinition(String message) {
    final RegExpMatch? match = _moduleRedefinitionPattern.firstMatch(message);
    return match?.group(1);
  }

  static String? parseDuplicateSymbols(String message) {
    final RegExpMatch? match = _duplicateSymbolsPattern.firstMatch(message);
    final String? module = match?.group(1);
    if (module == null) {
      return null;
    }
    return module.split('/').last.split('[').first.split('(').first;
  }

  static String? parseMissingModule(String message) {
    final RegExpMatch? match = _missingModulePattern.firstMatch(message);
    return match?.group(1);
  }

  static Future<List<String>> findSwiftPackageOnlyPlugins({
    required FlutterDarwinPlatform platform,
    required FlutterProject project,
    required List<String> pluginNames,
    required FileSystem fileSystem,
  }) async {
    final pluginsByName = <String, Plugin>{
      for (final Plugin plugin in await findPlugins(project)) plugin.name.toLowerCase(): plugin,
    };
    final swiftPackageOnlyPlugins = <String>[];
    for (final pluginName in pluginNames) {
      final Plugin? matched = pluginsByName[pluginName.toLowerCase()];
      if (matched == null || matched.platforms[platform.name] == null) {
        continue;
      }

      final String? swiftPackagePath = matched.pluginSwiftPackageManifestPath(
        fileSystem,
        platform.name,
      );
      final bool swiftPackageExists =
          swiftPackagePath != null && fileSystem.file(swiftPackagePath).existsSync();

      final String? podspecPath = matched.pluginPodspecPath(fileSystem, platform.name);
      final bool podspecExists = podspecPath != null && fileSystem.file(podspecPath).existsSync();

      if (swiftPackageExists && !podspecExists) {
        swiftPackageOnlyPlugins.add(pluginName);
      }
    }
    return swiftPackageOnlyPlugins;
  }
}

final class XcodeBuildFailureOutputAnalysis {
  const XcodeBuildFailureOutputAnalysis({
    this.platformMismatch,
    this.duplicateModules = const <String>{},
    this.missingModules = const <String>{},
  });

  final XcodeBuildFailurePlatformMismatch? platformMismatch;
  final Set<String> duplicateModules;
  final Set<String> missingModules;
}

final class XcodeBuildFailurePlatformMismatch {
  const XcodeBuildFailurePlatformMismatch({
    required this.requiredByProduct,
    required this.requiredVersion,
    required this.supportedVersion,
  });

  final String requiredByProduct;
  final Version requiredVersion;
  final Version supportedVersion;
}

final RegExp _swiftPackageManagerMinPlatformMismatchPattern = RegExp(
  r"The package product '([^']+)' requires minimum platform version "
  r'([0-9\.]+) for the (iOS|macOS) platform, but this target supports '
  r"([0-9\.]+)(?: \(in target '([^']+)' from project '[^']+'\))?",
  caseSensitive: false,
);

final RegExp _moduleRedefinitionPattern = RegExp(r"Redefinition of module '(.*?)'");

final RegExp _duplicateSymbolsPattern = RegExp(r'duplicate symbol [\s|\S]*?\/(.*)\.o');

final RegExp _missingModulePattern = RegExp(r"Module '(.*?)' not found");
