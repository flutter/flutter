// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  TryStatementTest().buildAll();
}

class TryStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'try_statement',
        [
          //
          // No clauses.
          //
          TestDescriptor(
              'keyword',
              'try',
              [
                ParserErrorCode.EXPECTED_BODY,
                ParserErrorCode.MISSING_CATCH_OR_FINALLY
              ],
              "try {} finally {}",
              allFailing: true),
          TestDescriptor('noCatchOrFinally', 'try {}',
              [ParserErrorCode.MISSING_CATCH_OR_FINALLY], "try {} finally {}",
              allFailing: true),
          //
          // Single on clause.
          //
          TestDescriptor(
              'on',
              'try {} on',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY
              ],
              "try {} on _s_ {}",
              failing: [
                'block',
                'labeled',
                'localFunctionNonVoid',
                'localFunctionVoid'
              ]),
          TestDescriptor('on_identifier', 'try {} on A',
              [ParserErrorCode.EXPECTED_BODY], "try {} on A {}",
              failing: ['block']),
          //
          // Single catch clause.
          //
          TestDescriptor(
              'catch',
              'try {} catch',
              [ParserErrorCode.CATCH_SYNTAX, ParserErrorCode.EXPECTED_BODY],
              "try {} catch (e) {}",
              failing: ['block']),
          TestDescriptor(
              'catch_leftParen',
              'try {} catch (',
              [
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.CATCH_SYNTAX,
                ParserErrorCode.EXPECTED_BODY
              ],
              "try {} catch (e) {}",
              failing: ['block', 'labeled', 'localFunctionNonVoid']),
          TestDescriptor(
              'catch_identifier',
              'try {} catch (e',
              [
                ParserErrorCode.CATCH_SYNTAX,
                ParserErrorCode.EXPECTED_BODY,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "try {} catch (e) {}",
              failing: ['eof', 'block']),
          TestDescriptor(
              'catch_identifierComma',
              'try {} catch (e, ',
              [
                ParserErrorCode.CATCH_SYNTAX,
                ParserErrorCode.EXPECTED_BODY,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "try {} catch (e, _s_) {}",
              failing: ['block', 'labeled', 'localFunctionNonVoid']),
          TestDescriptor(
              'catch_identifierCommaIdentifier',
              'try {} catch (e, s',
              [
                // TODO(danrubel): Update parser to generate CATCH_SYNTAX
                // because in this situation there are not any extra parameters.
                ParserErrorCode.CATCH_SYNTAX_EXTRA_PARAMETERS,
                ParserErrorCode.EXPECTED_BODY,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "try {} catch (e, s) {}",
              failing: ['eof', 'block']),
          TestDescriptor('catch_rightParen', 'try {} catch (e, s)',
              [ParserErrorCode.EXPECTED_BODY], "try {} catch (e, s) {}",
              failing: ['block']),
          //
          // Single catch clause after an on clause.
          //
          TestDescriptor(
              'on_catch',
              'try {} on A catch',
              [ParserErrorCode.CATCH_SYNTAX, ParserErrorCode.EXPECTED_BODY],
              "try {} on A catch (e) {}",
              failing: ['block']),
          TestDescriptor(
              'on_catch_leftParen',
              'try {} on A catch (',
              [
                ParserErrorCode.CATCH_SYNTAX,
                ParserErrorCode.EXPECTED_BODY,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "try {} on A catch (e) {}",
              failing: ['block', 'labeled', 'localFunctionNonVoid']),
          TestDescriptor(
              'on_catch_identifier',
              'try {} on A catch (e',
              [
                ParserErrorCode.CATCH_SYNTAX,
                ParserErrorCode.EXPECTED_BODY,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "try {} on A catch (e) {}",
              failing: ['eof', 'block']),
          TestDescriptor(
              'on_catch_identifierComma',
              'try {} on A catch (e, ',
              [
                ParserErrorCode.CATCH_SYNTAX,
                ParserErrorCode.EXPECTED_BODY,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "try {} on A catch (e, _s_) {}",
              failing: ['block', 'labeled', 'localFunctionNonVoid']),
          TestDescriptor(
              'on_catch_identifierCommaIdentifier',
              'try {} on A catch (e, s',
              [
                // TODO(danrubel): Update parser to generate CATCH_SYNTAX
                // because in this situation there are not any extra parameters.
                ParserErrorCode.CATCH_SYNTAX_EXTRA_PARAMETERS,
                ParserErrorCode.EXPECTED_BODY,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "try {} on A catch (e, s) {}",
              failing: ['eof', 'block']),
          TestDescriptor('on_catch_rightParen', 'try {} on A catch (e, s)',
              [ParserErrorCode.EXPECTED_BODY], "try {} on A catch (e, s) {}",
              failing: ['block']),
          //
          // Only a finally clause.
          //
          TestDescriptor('finally_noCatch_noBlock', 'try {} finally',
              [ParserErrorCode.EXPECTED_BODY], "try {} finally {}",
              failing: ['block']),
          //
          // A catch and finally clause.
          //
          TestDescriptor('finally_catch_noBlock', 'try {} catch (e) {} finally',
              [ParserErrorCode.EXPECTED_BODY], "try {} catch (e) {} finally {}",
              failing: ['block']),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
