// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../generated/test_support.dart';

abstract class AbstractAnalysisOptionsTest with ResourceProviderMixin {
  late SourceFactory sourceFactory;

  VersionConstraint? get sdkVersionConstraint => null;

  Future<void> assertErrorsInCode(
    String code,
    List<ExpectedError> expectedErrors, {
    LintRuleProvider? provider,
  }) async {
    var path = convertPath('/analysis_options.yaml');
    newFile(path, code);
    var diagnostics = analyzeAnalysisOptions(
      TestSource(path),
      code,
      sourceFactory,
      '/',
      sdkVersionConstraint,
      provider: provider,
    );
    var errorListener = GatheringErrorListener();
    errorListener.addAll(diagnostics);
    errorListener.assertErrors(expectedErrors);
  }

  ExpectedError error(ErrorCode code, int offset, int length,
          {Pattern? correctionContains,
          String? text,
          List<Pattern> messageContains = const [],
          List<ExpectedContextMessage> contextMessages =
              const <ExpectedContextMessage>[]}) =>
      ExpectedError(code, offset, length,
          correctionContains: correctionContains,
          message: text,
          messageContains: messageContains,
          expectedContextMessages: contextMessages);

  void setUp() {
    var resolvers = [ResourceUriResolver(resourceProvider)];
    sourceFactory = SourceFactoryImpl(resolvers);
  }
}
