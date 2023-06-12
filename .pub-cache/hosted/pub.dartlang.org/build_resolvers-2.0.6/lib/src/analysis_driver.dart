// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:build/build.dart';
import 'package:package_config/package_config.dart' show PackageConfig;
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'build_asset_uri_resolver.dart';

/// Builds an [AnalysisDriverForPackageBuild] backed by a summary SDK.
///
/// Any code must be resolvable through [buildAssetUriResolver].
Future<AnalysisDriverForPackageBuild> analysisDriver(
  BuildAssetUriResolver buildAssetUriResolver,
  AnalysisOptions analysisOptions,
  String sdkSummaryPath,
  PackageConfig packageConfig,
) async {
  return createAnalysisDriver(
    analysisOptions: analysisOptions,
    packages: _buildAnalyzerPackages(
      packageConfig,
      buildAssetUriResolver.resourceProvider,
    ),
    resourceProvider: buildAssetUriResolver.resourceProvider,
    sdkSummaryBytes: File(sdkSummaryPath).readAsBytesSync(),
    uriResolvers: [
      buildAssetUriResolver,
    ],
  );
}

Packages _buildAnalyzerPackages(
        PackageConfig packageConfig, ResourceProvider resourceProvider) =>
    Packages({
      for (var package in packageConfig.packages)
        package.name: Package(
          name: package.name,
          languageVersion: package.languageVersion == null
              ? sdkLanguageVersion
              : Version(package.languageVersion!.major,
                  package.languageVersion!.minor, 0),
          // Analyzer does not see the original file paths at all, we need to
          // make them match the paths that we give it, so we use the `assetPath`
          // function to create those.
          rootFolder: resourceProvider
              .getFolder(p.url.normalize(assetPath(AssetId(package.name, '')))),
          libFolder: resourceProvider.getFolder(
              p.url.normalize(assetPath(AssetId(package.name, 'lib')))),
        ),
    });

/// The language version of the current sdk parsed from the [Platform.version].
final sdkLanguageVersion = () {
  var sdkVersion = Version.parse(Platform.version.split(' ').first);
  return Version(sdkVersion.major, sdkVersion.minor, 0);
}();
