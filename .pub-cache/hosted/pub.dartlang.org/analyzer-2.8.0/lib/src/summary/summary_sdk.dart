// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';
import 'package:pub_semver/pub_semver.dart';

/// An implementation of [DartSdk] which provides analysis results for `dart:`
/// libraries from the given summary file.  This implementation is limited and
/// suitable only for command-line tools, but not for IDEs - it does not
/// implement [sdkLibraries], [uris] and [fromFileUri].
class SummaryBasedDartSdk implements DartSdk {
  late final PackageBundleReader _bundle;
  late final SummaryDataStore _dataStore;
  late final InSummaryUriResolver _uriResolver;

  /// TODO(scheglov) Remove it when the default constructor.
  ResourceProvider? resourceProvider;

  @Deprecated('Use SummaryBasedDartSdk.forBundle() instead')
  SummaryBasedDartSdk(String summaryPath, bool _, {this.resourceProvider}) {
    _dataStore = SummaryDataStore(<String>[summaryPath],
        resourceProvider: resourceProvider);
    _uriResolver = InSummaryUriResolver(resourceProvider, _dataStore);
    _bundle = _dataStore.bundles.single;
  }

  SummaryBasedDartSdk.forBundle(PackageBundleReader bundle) {
    _bundle = bundle;

    _dataStore = SummaryDataStore([]);
    // TODO(scheglov) We need a solution to avoid these paths at all.
    _dataStore.addBundle('', bundle);

    _uriResolver = InSummaryUriResolver(resourceProvider, _dataStore);
  }

  @override
  String get allowedExperimentsJson {
    return _bundle.sdk!.allowedExperimentsJson;
  }

  /// Return the [PackageBundleReader] for this SDK, not `null`.
  PackageBundleReader get bundle => _bundle;

  @override
  Version get languageVersion {
    return Version(
      _bundle.sdk!.languageVersionMajor,
      _bundle.sdk!.languageVersionMinor,
      0,
    );
  }

  @override
  List<SdkLibrary> get sdkLibraries {
    throw UnimplementedError();
  }

  @override
  String get sdkVersion {
    throw UnimplementedError();
  }

  bool get strongMode => true;

  @override
  List<String> get uris {
    throw UnimplementedError();
  }

  @override
  Source? fromFileUri(Uri uri) {
    return null;
  }

  @override
  SdkLibrary? getSdkLibrary(String uri) {
    // This is not quite correct, but currently it's used only in
    // to report errors on importing or exporting of internal libraries.
    return null;
  }

  @override
  Source? mapDartUri(String uriStr) {
    Uri uri = Uri.parse(uriStr);
    return _uriResolver.resolveAbsolute(uri);
  }

  @override
  Uri? pathToUri(String path) {
    // Libraries from summaries don't have corresponding Dart files.
    return null;
  }
}
