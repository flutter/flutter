// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  PartDirectivesTest().buildAll();
}

class PartDirectivesTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'part_directive',
        [
          TestDescriptor(
              'keyword',
              'part',
              [
                // TODO(danrubel): Consider an improved error message
                // ParserErrorCode.MISSING_URI,
                ParserErrorCode.EXPECTED_STRING_LITERAL,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "part '';"),
          TestDescriptor('emptyUri', "part ''",
              [ParserErrorCode.EXPECTED_TOKEN], "part '';"),
          TestDescriptor('uri', "part 'a.dart'",
              [ParserErrorCode.EXPECTED_TOKEN], "part 'a.dart';"),
        ],
        PartialCodeTest.postPartSuffixes);
  }
}
