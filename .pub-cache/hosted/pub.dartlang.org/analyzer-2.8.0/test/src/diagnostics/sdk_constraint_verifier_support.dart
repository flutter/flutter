// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

/// A base class designed to be used by tests of the hints produced by the
/// SdkConstraintVerifier.
class SdkConstraintVerifierTest extends PubPackageResolutionTest {
  /// Verify that the [expectedErrors] are produced if the [source] is analyzed
  /// in a context that specifies the minimum SDK version to be [version].
  Future<void> verifyVersion(String version, String source,
      {List<ExpectedError>? expectedErrors}) async {
    writeTestPackagePubspecYamlFile(
      PubspecYamlFileConfig(
        sdkVersion: '>=$version',
      ),
    );

    await assertErrorsInCode(source, expectedErrors ?? []);
  }
}
