// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show AnalysisDriver;
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptions;

/// An analysis context whose implementation is based on an analysis driver.
class DriverBasedAnalysisContext implements AnalysisContext {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  @override
  final ContextRoot contextRoot;

  /// The driver on which this context is based.
  late final AnalysisDriver driver;

  /// Initialize a newly created context that uses the given [resourceProvider]
  /// to access the file system and that is based on the given analysis
  /// [driver].
  DriverBasedAnalysisContext(
    this.resourceProvider,
    this.contextRoot, [
    @Deprecated('AnalysisDriver will set itself, remove this')
        AnalysisDriver? analysisDriver,
  ]);

  @override
  AnalysisOptions get analysisOptions => driver.analysisOptions;

  @override
  AnalysisSession get currentSession => driver.currentSession;

  @override
  Folder? get sdkRoot {
    var sdk = driver.sourceFactory.dartSdk;
    if (sdk is FolderBasedDartSdk) {
      return sdk.directory;
    }
    return null;
  }

  @override
  Future<List<String>> applyPendingFileChanges() {
    return driver.applyPendingFileChanges();
  }

  @override
  void changeFile(String path) {
    driver.changeFile(path);
  }
}
