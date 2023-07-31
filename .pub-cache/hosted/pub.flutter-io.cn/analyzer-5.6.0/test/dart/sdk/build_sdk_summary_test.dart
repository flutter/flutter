// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuildSdkSummaryTest);
  });
}

@reflectiveTest
class BuildSdkSummaryTest with ResourceProviderMixin {
  Folder get sdkRoot => getFolder('/sdk');

  test_embedderYamlPath() async {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    // The idea of the embedder is probably to replace the SDK.
    // But the current implementation only adds new libraries.
    final skyEngineLib = getFolder('/home/sky_engine/lib');
    newFile('${skyEngineLib.path}/core/core.dart', r'''
class NotObject {}
''');
    newFile('${skyEngineLib.path}/ui/ui.dart', r'''
library dart.ui;
part 'text.dart';
class Offset {}
''');
    newFile('${skyEngineLib.path}/ui/text.dart', r'''
part of dart.ui;
class FontStyle {}
''');
    final embedderFile = newFile('${skyEngineLib.path}/_embedder.yaml', r'''
embedded_libs:
  "dart:core": "core/core.dart"
  "dart:ui": "ui/ui.dart"
''');

    final sdkSummaryBytes = await buildSdkSummary(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      embedderYamlPath: embedderFile.path,
    );

    // Delete SDK files, to prove that we don't read them later.
    sdkRoot.delete();
    skyEngineLib.delete();

    // Write the summary bytes, will be read later.
    final sdkSummaryFile = getFile('/home/sdk_summary.bytes');
    sdkSummaryFile.writeAsBytesSync(sdkSummaryBytes);

    // Pub workspace does not support SDK summaries.
    // So, we use Blaze workspace.
    const workspacePath = '/workspace';
    newFile('$workspacePath/${file_paths.blazeWorkspaceMarker}', '');
    final myPackageRoot = getFolder('$workspacePath/dart/my');

    final collection = AnalysisContextCollectionImpl(
      includedPaths: [myPackageRoot.path],
      librarySummaryPaths: [],
      resourceProvider: resourceProvider,
      sdkSummaryPath: sdkSummaryFile.path,
    );

    final analysisContext = collection.contextFor(myPackageRoot.path);
    final analysisSession = analysisContext.currentSession;

    // We can ask for SDK libraries and classes.
    // They should be created from the summary bytes.
    final dartAsync = await analysisSession.getLibrary('dart:async');
    final dartCore = await analysisSession.getLibrary('dart:core');
    final dartMath = await analysisSession.getLibrary('dart:math');
    final dartUi = await analysisSession.getLibrary('dart:ui');
    expect(dartAsync.getClass('Stream'), isNotNull);
    expect(dartCore.getClass('String'), isNotNull);
    expect(dartMath.getClass('Random'), isNotNull);
    expect(dartUi.getClass('FontStyle'), isNotNull);
    expect(dartUi.getClass('Offset'), isNotNull);
  }

  test_it() async {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    final sdkSummaryBytes = await buildSdkSummary(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );

    // Delete SDK files, to prove that we don't read them later.
    sdkRoot.delete();

    // Write the summary bytes, will be read later.
    final sdkSummaryFile = getFile('/home/sdk_summary.bytes');
    sdkSummaryFile.writeAsBytesSync(sdkSummaryBytes);

    // Pub workspace does not support SDK summaries.
    // So, we use Blaze workspace.
    const workspacePath = '/workspace';
    newFile('$workspacePath/${file_paths.blazeWorkspaceMarker}', '');
    final myPackageRoot = getFolder('$workspacePath/dart/my');

    final collection = AnalysisContextCollectionImpl(
      includedPaths: [myPackageRoot.path],
      librarySummaryPaths: [],
      resourceProvider: resourceProvider,
      sdkSummaryPath: sdkSummaryFile.path,
    );

    final analysisContext = collection.contextFor(myPackageRoot.path);
    final analysisSession = analysisContext.currentSession;

    // We can ask for SDK libraries and classes.
    // They should be created from the summary bytes.
    final dartAsync = await analysisSession.getLibrary('dart:async');
    final dartCore = await analysisSession.getLibrary('dart:core');
    final dartMath = await analysisSession.getLibrary('dart:math');
    expect(dartAsync.getClass('Stream'), isNotNull);
    expect(dartCore.getClass('String'), isNotNull);
    expect(dartMath.getClass('Random'), isNotNull);
  }
}

extension on AnalysisSession {
  Future<LibraryElement> getLibrary(String uriStr) async {
    final libraryResult = await getLibraryByUri(uriStr);
    libraryResult as LibraryElementResult;
    return libraryResult.element;
  }
}
