// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverForPackageBuildTest);
  });
}

@reflectiveTest
class AnalysisDriverForPackageBuildTest with ResourceProviderMixin {
  test_sdkLibraryUris() async {
    var sdkRoot = getFolder('/sdk');

    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    var sdkSummaryBytes = await buildSdkSummary(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );

    var analysisDriver = createAnalysisDriver(
      resourceProvider: resourceProvider,
      sdkSummaryBytes: sdkSummaryBytes,
      analysisOptions: AnalysisOptionsImpl(),
      uriResolvers: [],
      packages: Packages({}),
    );

    expect(
      analysisDriver.sdkLibraryUris,
      containsAll([
        Uri.parse('dart:core'),
        Uri.parse('dart:async'),
        Uri.parse('dart:io'),
        Uri.parse('dart:_internal'),
      ]),
    );
  }
}
