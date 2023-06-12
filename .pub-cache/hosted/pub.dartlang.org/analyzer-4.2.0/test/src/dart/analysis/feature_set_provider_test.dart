// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/experiments_impl.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FeatureSetProviderTest);
  });
}

@reflectiveTest
class FeatureSetProviderTest with ResourceProviderMixin {
  late SourceFactory sourceFactory;
  late FeatureSetProvider provider;

  Folder get sdkRoot => newFolder('/sdk');

  void setUp() {
    newFile('/test/lib/test.dart', '');

    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    _createSourceFactory();
  }

  test_getFeatureSet_allowedExperiments() {
    var feature_a = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );

    _newSdkExperimentsFile(r'''
{
  "version": 1,
  "experimentSets": {
    "with_a": ["a"]
  },
  "sdk": {
    "default": {
      "experimentSet": "with_a"
    }
  },
  "packages": {
    "aaa": {
      "experimentSet": "with_a"
    }
  }
}
''');

    var packages = Packages(
      {
        'aaa': Package(
          name: 'aaa',
          rootFolder: newFolder('/packages/aaa'),
          libFolder: newFolder('/packages/aaa/lib'),
          languageVersion: null,
        ),
        'bbb': Package(
          name: 'bbb',
          rootFolder: newFolder('/packages/bbb'),
          libFolder: newFolder('/packages/bbb/lib'),
          languageVersion: null,
        ),
      },
    );

    _createSourceFactory(
      packageUriResolver: _createPackageMapUriResolver(packages),
    );

    overrideKnownFeatures({'a': feature_a}, () {
      provider = FeatureSetProvider.build(
        sourceFactory: sourceFactory,
        resourceProvider: resourceProvider,
        packages: packages,
        packageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
        nonPackageDefaultLanguageVersion: ExperimentStatus.currentVersion,
        nonPackageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
      );

      void assertHasFeature(String path, bool expected) {
        _assertHasFeatureForPath(path, feature_a, expected);
      }

      assertHasFeature('/packages/aaa/lib/a.dart', true);
      assertHasFeature('/packages/aaa/bin/b.dart', true);
      assertHasFeature('/packages/aaa/test/c.dart', true);

      assertHasFeature('/packages/bbb/lib/a.dart', false);
      assertHasFeature('/packages/bbb/bin/b.dart', false);
      assertHasFeature('/packages/bbb/test/c.dart', false);

      assertHasFeature('/other/file.dart', false);
    });
  }

  test_getFeatureSet_defaultForContext_hasExperiment() {
    var feature_a = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: Version.parse('2.12.0'),
      releaseVersion: null,
    );

    var packages = Packages(
      {
        'aaa': Package(
          name: 'aaa',
          rootFolder: newFolder('/packages/aaa'),
          libFolder: newFolder('/packages/aaa/lib'),
          languageVersion: null,
        ),
        'bbb': Package(
          name: 'bbb',
          rootFolder: newFolder('/packages/bbb'),
          libFolder: newFolder('/packages/bbb/lib'),
          languageVersion: Version(2, 12, 0),
        ),
      },
    );

    _createSourceFactory(
      packageUriResolver: _createPackageMapUriResolver(packages),
    );

    overrideKnownFeatures({'a': feature_a}, () {
      provider = FeatureSetProvider.build(
        sourceFactory: sourceFactory,
        resourceProvider: resourceProvider,
        packages: packages,
        packageDefaultFeatureSet: FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: Version.parse('2.12.0'),
          flags: [feature_a.enableString],
        ),
        nonPackageDefaultLanguageVersion: ExperimentStatus.currentVersion,
        nonPackageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
      );

      void assertHasFeature(String path, bool expected) {
        _assertHasFeatureForPath(path, feature_a, expected);
      }

      assertHasFeature('/packages/aaa/a.dart', true);
      assertHasFeature('/packages/aaa/lib/b.dart', true);
      assertHasFeature('/packages/aaa/test/c.dart', true);

      assertHasFeature('/packages/bbb/a.dart', true);
      assertHasFeature('/packages/bbb/lib/b.dart', true);
      assertHasFeature('/packages/bbb/test/c.dart', true);
    });
  }

  test_getFeatureSet_defaultForContext_noExperiments() {
    var feature_a = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: Version.parse('2.12.0'),
      releaseVersion: null,
    );

    var packages = Packages(
      {
        'aaa': Package(
          name: 'aaa',
          rootFolder: newFolder('/packages/aaa'),
          libFolder: newFolder('/packages/aaa/lib'),
          languageVersion: null,
        ),
        'bbb': Package(
          name: 'bbb',
          rootFolder: newFolder('/packages/bbb'),
          libFolder: newFolder('/packages/bbb/lib'),
          languageVersion: Version(2, 12, 0),
        ),
      },
    );

    _createSourceFactory(
      packageUriResolver: _createPackageMapUriResolver(packages),
    );

    overrideKnownFeatures({'a': feature_a}, () {
      provider = FeatureSetProvider.build(
        sourceFactory: sourceFactory,
        resourceProvider: resourceProvider,
        packages: packages,
        packageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
        nonPackageDefaultLanguageVersion: ExperimentStatus.currentVersion,
        nonPackageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
      );

      void assertHasFeature(String path, bool expected) {
        _assertHasFeatureForPath(path, feature_a, expected);
      }

      assertHasFeature('/packages/aaa/a.dart', false);
      assertHasFeature('/packages/aaa/lib/b.dart', false);
      assertHasFeature('/packages/aaa/test/c.dart', false);

      assertHasFeature('/packages/bbb/a.dart', false);
      assertHasFeature('/packages/bbb/lib/b.dart', false);
      assertHasFeature('/packages/bbb/test/c.dart', false);
    });
  }

  test_packages_contextExperiments_nested() {
    var packages = Packages(
      {
        'aaa': Package(
          name: 'aaa',
          rootFolder: getFolder('/packages/aaa'),
          libFolder: getFolder('/packages/aaa/lib'),
          languageVersion: Version.parse('2.5.0'),
        ),
        'bbb': Package(
          name: 'bbb',
          rootFolder: getFolder('/packages/aaa/bbb'),
          libFolder: getFolder('/packages/aaa/bbb/lib'),
          languageVersion: Version.parse('2.6.0'),
        ),
        'ccc': Package(
          name: 'ccc',
          rootFolder: getFolder('/packages/ccc'),
          libFolder: getFolder('/packages/ccc/lib'),
          languageVersion: Version.parse('2.7.0'),
        ),
      },
    );

    provider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      resourceProvider: resourceProvider,
      packages: packages,
      packageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
      nonPackageDefaultLanguageVersion: ExperimentStatus.currentVersion,
      nonPackageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
    );

    void check({
      required String uriStr,
      required String posixPath,
      required Version expected,
    }) {
      var uri = Uri.parse(uriStr);
      var path = convertPath(posixPath);
      expect(
        provider.getLanguageVersion(path, uri),
        expected,
      );
    }

    check(
      uriStr: 'package:aaa/a.dart',
      posixPath: '/packages/aaa/a.dart',
      expected: Version.parse('2.5.0'),
    );

    check(
      uriStr: toUriStr('/packages/aaa/test/a.dart'),
      posixPath: '/packages/aaa/test/a.dart',
      expected: Version.parse('2.5.0'),
    );

    check(
      uriStr: 'package:bbb/b.dart',
      posixPath: '/packages/aaa/bbb/b.dart',
      expected: Version.parse('2.6.0'),
    );

    check(
      uriStr: 'package:ccc/c.dart',
      posixPath: '/packages/ccc/c.dart',
      expected: Version.parse('2.7.0'),
    );

    check(
      uriStr: 'package:ddd/a.dart',
      posixPath: '/packages/ddd/d.dart',
      expected: ExperimentStatus.currentVersion,
    );
  }

  test_sdk_allowedExperiments_default() {
    var feature_a = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );

    _newSdkExperimentsFile(r'''
{
  "version": 1,
  "experimentSets": {
    "with_a": ["a"]
  },
  "sdk": {
    "default": {
      "experimentSet": "with_a"
    }
  }
}
''');

    overrideKnownFeatures({'a': feature_a}, () {
      provider = FeatureSetProvider.build(
        sourceFactory: sourceFactory,
        resourceProvider: resourceProvider,
        packages: findPackagesFrom(resourceProvider, getFolder('/test')),
        packageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
        nonPackageDefaultLanguageVersion: ExperimentStatus.currentVersion,
        nonPackageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
      );

      var core_featureSet = _getSdkFeatureSet('dart:core');
      expect(core_featureSet.isEnabled(feature_a), isTrue);

      var math_featureSet = _getSdkFeatureSet('dart:math');
      expect(math_featureSet.isEnabled(feature_a), isTrue);
    });
  }

  test_sdk_allowedExperiments_library() {
    var feature_a = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );

    _newSdkExperimentsFile(r'''
{
  "version": 1,
  "experimentSets": {
    "none": [],
    "with_a": ["a"]
  },
  "sdk": {
    "default": {
      "experimentSet": "none"
    },
    "libraries": {
      "math": {
        "experimentSet": "with_a"
      }
    }
  }
}
''');

    overrideKnownFeatures({'a': feature_a}, () {
      provider = FeatureSetProvider.build(
        sourceFactory: sourceFactory,
        resourceProvider: resourceProvider,
        packages: findPackagesFrom(resourceProvider, getFolder('/test')),
        packageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
        nonPackageDefaultLanguageVersion: ExperimentStatus.currentVersion,
        nonPackageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
      );

      var core_featureSet = _getSdkFeatureSet('dart:core');
      expect(core_featureSet.isEnabled(feature_a), isFalse);

      var math_featureSet = _getSdkFeatureSet('dart:math');
      expect(math_featureSet.isEnabled(feature_a), isTrue);
    });
  }

  test_sdk_allowedExperiments_mockDefault() {
    provider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      resourceProvider: resourceProvider,
      packages: findPackagesFrom(resourceProvider, getFolder('/test')),
      packageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
      nonPackageDefaultLanguageVersion: ExperimentStatus.currentVersion,
      nonPackageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
    );

    var featureSet = _getSdkFeatureSet('dart:math');
    expect(featureSet.isEnabled(Feature.non_nullable), isTrue);
  }

  _assertHasFeatureForPath(String path, Feature feature, bool expected) {
    var featureSet = _getPathFeatureSet(path);
    expect(featureSet.isEnabled(feature), expected);
  }

  PackageMapUriResolver _createPackageMapUriResolver(Packages packages) {
    var map = <String, List<Folder>>{};
    for (var package in packages.packages) {
      map[package.name] = [package.libFolder];
    }
    return PackageMapUriResolver(resourceProvider, map);
  }

  void _createSourceFactory({UriResolver? packageUriResolver}) {
    var resolvers = <UriResolver>[];
    if (packageUriResolver != null) {
      resolvers.add(packageUriResolver);
    }
    resolvers.addAll([
      DartUriResolver(
        FolderBasedDartSdk(resourceProvider, sdkRoot),
      ),
      ResourceUriResolver(resourceProvider),
    ]);
    sourceFactory = SourceFactoryImpl(resolvers);
  }

  FeatureSet _getPathFeatureSet(String path) {
    path = convertPath(path);
    var uri = sourceFactory.pathToUri(path)!;
    return provider.getFeatureSet(path, uri);
  }

  FeatureSet _getSdkFeatureSet(String uriStr) {
    var uri = Uri.parse(uriStr);
    var path = sourceFactory.forUri2(uri)!.fullName;
    return provider.getFeatureSet(path, uri);
  }

  void _newSdkExperimentsFile(String content) {
    newFile('$sdkRoot/lib/_internal/allowed_experiments.json', content);
  }
}
