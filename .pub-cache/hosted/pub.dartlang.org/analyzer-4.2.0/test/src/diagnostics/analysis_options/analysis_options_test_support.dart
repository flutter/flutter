// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';

import '../../../generated/test_support.dart';

class AbstractAnalysisOptionsTest {
  Future<void> assertErrorsInCode(
      String code, List<ExpectedError> expectedErrors) async {
    var diagnostics =
        analyzeAnalysisOptions(TestSource(), code, SourceFactory([]), '/');
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
}
