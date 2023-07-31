// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/sdk/allowed_experiments.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:pub_semver/pub_semver.dart';

class FeatureSetProvider {
  final Version _sdkLanguageVersion;
  final AllowedExperiments _allowedExperiments;
  final ResourceProvider _resourceProvider;
  final Packages _packages;
  final FeatureSet _packageDefaultFeatureSet;
  final Version _nonPackageDefaultLanguageVersion;
  final FeatureSet _nonPackageDefaultFeatureSet;

  FeatureSetProvider._({
    required Version sdkLanguageVersion,
    required AllowedExperiments allowedExperiments,
    required ResourceProvider resourceProvider,
    required Packages packages,
    required FeatureSet packageDefaultFeatureSet,
    required Version nonPackageDefaultLanguageVersion,
    required FeatureSet nonPackageDefaultFeatureSet,
  })  : _sdkLanguageVersion = sdkLanguageVersion,
        _allowedExperiments = allowedExperiments,
        _resourceProvider = resourceProvider,
        _packages = packages,
        _packageDefaultFeatureSet = packageDefaultFeatureSet,
        _nonPackageDefaultLanguageVersion = nonPackageDefaultLanguageVersion,
        _nonPackageDefaultFeatureSet = nonPackageDefaultFeatureSet;

  FeatureSet featureSetForExperiments(List<String> experiments) {
    return FeatureSet.fromEnableFlags2(
      sdkLanguageVersion: _sdkLanguageVersion,
      flags: experiments,
    );
  }

  /// Return the [FeatureSet] for the package that contains the file.
  ///
  /// Note, that [getLanguageVersion] returns the default language version
  /// for libraries in the package, but this method does not restrict the
  /// [FeatureSet] of this version. The reason is that we allow libraries to
  /// "upgrade" to higher version than the default package language version,
  /// and want this to preserve experimental features.
  FeatureSet getFeatureSet(String path, Uri uri) {
    if (uri.isScheme('dart')) {
      var pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        var libraryName = pathSegments.first;
        var experiments = _allowedExperiments.forSdkLibrary(libraryName);
        return featureSetForExperiments(experiments);
      } else {
        return featureSetForExperiments([]);
      }
    }

    var package = _findPackage(uri, path);
    if (package != null) {
      var experiments = _allowedExperiments.forPackage(package.name);
      if (experiments != null) {
        return featureSetForExperiments(experiments);
      }

      return _packageDefaultFeatureSet;
    }

    return _nonPackageDefaultFeatureSet;
  }

  /// Return the language version for the package that contains the file.
  ///
  /// Each individual file might use `// @dart` to override this version, to
  /// be either lower, or higher than the package language version.
  Version getLanguageVersion(String path, Uri uri) {
    if (uri.isScheme('dart')) {
      return _sdkLanguageVersion;
    }
    var package = _findPackage(uri, path);
    if (package != null) {
      var languageVersion = package.languageVersion;
      if (languageVersion != null) {
        return languageVersion;
      }
      return _sdkLanguageVersion;
    }

    return _nonPackageDefaultLanguageVersion;
  }

  /// Return the package corresponding to the [uri] or [path], `null` if none.
  ///
  /// For `package` and `asset` schemes the package name is retrieved from the
  /// first path segment of [uri].
  ///
  /// For `file` schemes this tries to look up by the normalized [uri] path.
  ///
  /// If unable to find a package through other mechanisms mechanisms, or it is
  /// an unrecognized uri scheme, then the package is looked up by [path].
  Package? _findPackage(Uri uri, String path) {
    if (uri.isScheme('package') || uri.isScheme('asset')) {
      var pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        var packageName = pathSegments.first;
        var package = _packages[packageName];
        if (package != null) {
          return package;
        }
      }
    } else if (uri.isScheme('file')) {
      var uriPath = fileUriToNormalizedPath(_resourceProvider.pathContext, uri);
      var package = _packages.packageForPath(uriPath);
      if (package != null) {
        return package;
      }
    }

    return _packages.packageForPath(path);
  }

  static FeatureSetProvider build({
    required SourceFactory sourceFactory,
    required ResourceProvider resourceProvider,
    required Packages packages,
    required FeatureSet packageDefaultFeatureSet,
    required Version nonPackageDefaultLanguageVersion,
    required FeatureSet nonPackageDefaultFeatureSet,
  }) {
    var sdk = sourceFactory.dartSdk!;
    var allowedExperiments = _experimentsForSdk(sdk);
    return FeatureSetProvider._(
      sdkLanguageVersion: sdk.languageVersion,
      allowedExperiments: allowedExperiments,
      resourceProvider: resourceProvider,
      packages: packages,
      packageDefaultFeatureSet: packageDefaultFeatureSet,
      nonPackageDefaultLanguageVersion: nonPackageDefaultLanguageVersion,
      nonPackageDefaultFeatureSet: nonPackageDefaultFeatureSet,
    );
  }

  static AllowedExperiments _experimentsForSdk(DartSdk sdk) {
    var experimentsContent = sdk.allowedExperimentsJson;
    if (experimentsContent != null) {
      try {
        return parseAllowedExperiments(experimentsContent);
      } catch (_) {}
    }

    return AllowedExperiments(
      sdkDefaultExperiments: [],
      sdkLibraryExperiments: {},
      packageExperiments: {},
    );
  }
}
