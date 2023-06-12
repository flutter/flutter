// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';

export 'package:analyzer/src/context/packages.dart' show Packages, Package;
export 'package:analyzer/src/dart/analysis/experiments.dart'
    show ExperimentStatus;
export 'package:analyzer/src/generated/engine.dart'
    show AnalysisOptions, AnalysisOptionsImpl;
export 'package:analyzer/src/generated/source.dart' show Source, UriResolver;

/// A somewhat low level API to create [AnalysisSession].
///
/// Ideally we want clients to use [AnalysisContextCollection], which
/// encapsulates any internals and is driven by `package_config.json` and
/// `analysis_options.yaml` files. But so far it looks that `build_resolvers`
/// wants to provide [UriResolver], and push [Packages] created by other means
/// than parsing `package_config.json`.
AnalysisDriverForPackageBuild createAnalysisDriver({
  required ResourceProvider resourceProvider,
  required Uint8List sdkSummaryBytes,
  required AnalysisOptions analysisOptions,
  required List<UriResolver> uriResolvers,
  required Packages packages,
}) {
  var sdkBundle = PackageBundleReader(sdkSummaryBytes);
  var sdk = SummaryBasedDartSdk.forBundle(sdkBundle);

  var sourceFactory = SourceFactory([
    DartUriResolver(sdk),
    ...uriResolvers,
  ]);

  var dataStore = SummaryDataStore([]);
  dataStore.addBundle('', sdkBundle);

  var logger = PerformanceLog(null);
  var scheduler = AnalysisDriverScheduler(logger);
  var driver = AnalysisDriver.tmp1(
    scheduler: scheduler,
    logger: logger,
    resourceProvider: resourceProvider,
    byteStore: MemoryByteStore(),
    sourceFactory: sourceFactory,
    analysisOptions: analysisOptions as AnalysisOptionsImpl,
    externalSummaries: dataStore,
    packages: packages,
  );

  scheduler.start();

  return AnalysisDriverForPackageBuild._(driver);
}

/// [AnalysisSession] plus a tiny bit more.
class AnalysisDriverForPackageBuild {
  final AnalysisDriver _driver;

  AnalysisDriverForPackageBuild._(this._driver);

  AnalysisSession get currentSession {
    return _driver.currentSession;
  }

  /// The file with the given [path] might have changed - updated, added or
  /// removed. Or not, we don't know. Or it might have, but then changed back.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [currentSession] most probably will be invalidated.
  /// Note, is does NOT at the time of writing this comment.
  /// But we are going to fix this.
  void changeFile(String path) {
    _driver.changeFile(path);
  }

  /// Return `true` if the [uri] can be resolved to an existing file.
  bool isUriOfExistingFile(Uri uri) {
    var source = _driver.sourceFactory.forUri2(uri);
    return source != null && source.exists();
  }
}
