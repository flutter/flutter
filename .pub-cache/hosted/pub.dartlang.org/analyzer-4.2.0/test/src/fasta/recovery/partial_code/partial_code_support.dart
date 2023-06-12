// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test/test.dart';

import '../../../../generated/test_support.dart';
import '../recovery_test_support.dart';

typedef AdjustValidUnitBeforeComparison = CompilationUnitImpl Function(
    CompilationUnitImpl unit);

/// A base class that adds support for tests that test how well the parser
/// recovers when the user has entered an incomplete (but otherwise correct)
/// construct (such as a top-level declaration, class member, or statement).
///
/// Because users often add new constructs between two existing constructs,
/// these tests effectively test whether the parser is able to recognize where
/// the partially entered construct ends and where the next fully entered
/// construct begins. (The preceding construct is irrelevant.) Given the large
/// number of following constructs the are valid in most contexts, these tests
/// are designed to programmatically generate tests based on a list of possible
/// following constructs.
abstract class PartialCodeTest extends AbstractRecoveryTest {
  /// A list of suffixes that can be used by tests of class members.
  static final List<TestSuffix> classMemberSuffixes = <TestSuffix>[
    TestSuffix('annotation', '@annotation var f;'),
    TestSuffix('field', 'var f;'),
    TestSuffix('fieldConst', 'const f = 0;'),
    TestSuffix('fieldFinal', 'final f = 0;'),
    TestSuffix('methodNonVoid', 'int a(b) => 0;'),
    TestSuffix('methodVoid', 'void a(b) {}'),
    TestSuffix('getter', 'int get a => 0;'),
    TestSuffix('setter', 'set a(b) {}')
  ];

  /// A list of suffixes that can be used by tests of top-level constructs that
  /// can validly be followed by any declaration.
  static final List<TestSuffix> declarationSuffixes = <TestSuffix>[
    TestSuffix('class', 'class A {}'),
    TestSuffix('enum', 'enum E { v }'),
//    new TestSuffix('extension', 'extension E on A {}'),
    TestSuffix('mixin', 'mixin M {}'),
    TestSuffix('typedef', 'typedef A = B Function(C, D);'),
    TestSuffix('functionVoid', 'void f() {}'),
    TestSuffix('functionNonVoid', 'int f() {}'),
    TestSuffix('var', 'var a;'),
    TestSuffix('const', 'const a = 0;'),
    TestSuffix('final', 'final a = 0;'),
    TestSuffix('getter', 'int get a => 0;'),
    TestSuffix('setter', 'set a(b) {}')
  ];

  /// A list of suffixes that can be used by tests of top-level constructs that
  /// can validly be followed by anything that is valid after a part directive.
  static final List<TestSuffix> postPartSuffixes = <TestSuffix>[
    TestSuffix('part', "part 'a.dart';"),
    ...declarationSuffixes
  ];

  /// A list of suffixes that can be used by tests of top-level constructs that
  /// can validly be followed by any directive or declaration other than a
  /// library directive.
  static final List<TestSuffix> prePartSuffixes = <TestSuffix>[
    TestSuffix('import', "import 'a.dart';"),
    TestSuffix('export', "export 'a.dart';"),
    ...postPartSuffixes
  ];

  /// A list of suffixes that can be used by tests of statements.
  static final List<TestSuffix> statementSuffixes = <TestSuffix>[
    TestSuffix('assert', "assert (true);"),
    TestSuffix('block', "{}"),
    TestSuffix('break', "break;"),
    TestSuffix('continue', "continue;"),
    TestSuffix('do', "do {} while (true);"),
    TestSuffix('if', "if (true) {}"),
    TestSuffix('for', "for (var x in y) {}"),
    TestSuffix('labeled', "l: {}"),
    TestSuffix('localFunctionNonVoid', "int f() {}"),
    TestSuffix('localFunctionVoid', "void f() {}"),
    TestSuffix('localVariable', "var x;"),
    TestSuffix('switch', "switch (x) {}"),
    TestSuffix('try', "try {} finally {}"),
    TestSuffix('return', "return;"),
    TestSuffix('while', "while (true) {}"),
  ];

  /// Build a group of tests with the given [groupName]. There will be one test
  /// for every combination of elements in the cross-product of the lists of
  /// [descriptors] and [suffixes], and one additional test for every descriptor
  /// where the suffix is the empty string (to test partial declarations at the
  /// end of the file). In total, there will be
  /// `descriptors.length * (suffixes.length + 1)` tests generated.
  buildTests(String groupName, List<TestDescriptor> descriptors,
      List<TestSuffix> suffixes,
      {FeatureSet? featureSet,
      String? head,
      bool includeEof = true,
      String? tail}) {
    group(groupName, () {
      for (TestDescriptor descriptor in descriptors) {
        if (includeEof) {
          _buildTestForDescriptorAndSuffix(
              descriptor, TestSuffix.eof, 0, head, tail,
              featureSet: featureSet);
        }
        for (int i = 0; i < suffixes.length; i++) {
          _buildTestForDescriptorAndSuffix(
              descriptor, suffixes[i], i + 1, head, tail,
              featureSet: featureSet);
        }
        if (descriptor.failing != null) {
          test('${descriptor.name}_failingList', () {
            Set<String> failing = Set.from(descriptor.failing!);
            if (includeEof) {
              failing.remove('eof');
            }
            failing.removeAll(suffixes.map((TestSuffix suffix) => suffix.name));
            expect(failing, isEmpty,
                reason:
                    'There are tests marked as failing that are not being run');
          });
        }
      }
    });
  }

  /// Build a single test based on the given [descriptor] and [suffix].
  _buildTestForDescriptorAndSuffix(TestDescriptor descriptor, TestSuffix suffix,
      int suffixIndex, String? head, String? tail,
      {FeatureSet? featureSet}) {
    test('${descriptor.name}_${suffix.name}', () {
      //
      // Compose the invalid and valid pieces of code.
      //
      StringBuffer invalid = StringBuffer();
      StringBuffer valid = StringBuffer();
      StringBuffer base = StringBuffer();
      if (head != null) {
        invalid.write(head);
        valid.write(head);
        base.write(head);
      }
      invalid.write(descriptor.invalid);
      valid.write(descriptor.valid);
      if (suffix.text.isNotEmpty) {
        invalid.write(' ');
        invalid.write(suffix.text);
        valid.write(' ');
        valid.write(suffix.text);
        base.write(' ');
        base.write(suffix.text);
      }
      if (tail != null) {
        invalid.write(tail);
        valid.write(tail);
        base.write(tail);
      }
      //
      // Determine the existing errors in the code without either valid or
      // invalid code.
      //
      GatheringErrorListener listener =
          GatheringErrorListener(checkRanges: true);
      parseCompilationUnit2(base.toString(), listener, featureSet: featureSet);
      var baseErrorCodes = <ErrorCode>[];
      for (var error in listener.errors) {
        if (error.errorCode == ParserErrorCode.BREAK_OUTSIDE_OF_LOOP ||
            error.errorCode == ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP ||
            error.errorCode == ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE) {
          baseErrorCodes.add(error.errorCode);
        }
      }

      var expectedValidCodeErrors = <ErrorCode>[];
      expectedValidCodeErrors.addAll(baseErrorCodes);
      if (descriptor.expectedErrorsInValidCode != null) {
        expectedValidCodeErrors.addAll(descriptor.expectedErrorsInValidCode!);
      }

      var expectedInvalidCodeErrors = <ErrorCode>[];
      expectedInvalidCodeErrors.addAll(baseErrorCodes);
      if (descriptor.errorCodes != null) {
        expectedInvalidCodeErrors.addAll(descriptor.errorCodes!);
      }
      //
      // Run the test.
      //
      var failing = descriptor.failing;
      if (descriptor.allFailing ||
          (failing != null && failing.contains(suffix.name))) {
        bool failed = false;
        try {
          testRecovery(
              invalid.toString(), expectedInvalidCodeErrors, valid.toString(),
              adjustValidUnitBeforeComparison:
                  descriptor.adjustValidUnitBeforeComparison,
              expectedErrorsInValidCode: expectedValidCodeErrors);
          failed = true;
        } catch (e) {
          // Expected to fail.
        }
        if (failed) {
          fail('Expected to fail, but passed');
        }
      } else {
        testRecovery(
            invalid.toString(), expectedInvalidCodeErrors, valid.toString(),
            adjustValidUnitBeforeComparison:
                descriptor.adjustValidUnitBeforeComparison,
            expectedErrorsInValidCode: expectedValidCodeErrors,
            featureSet: featureSet);
      }
    });
  }
}

/// A description of a set of tests that are to be built.
class TestDescriptor {
  /// The name of the test.
  final String name;

  /// Invalid code that the parser is expected to recover from.
  final String invalid;

  /// Error codes that the parser is expected to produce.
  final List<ErrorCode>? errorCodes;

  /// Valid code that is equivalent to what the parser should produce as part of
  /// recovering from the invalid code.
  final String valid;

  /// Error codes that the parser is expected to produce in the valid code.
  final List<ErrorCode>? expectedErrorsInValidCode;

  /// A flag indicating whether all of the tests are expected to fail.
  final bool allFailing;

  /// A list containing the names of the suffixes for which the test is expected
  /// to fail.
  final List<String>? failing;

  /// A function that modifies the valid compilation unit before it is compared
  /// with the invalid compilation unit, or `null` if no modification needed.
  AdjustValidUnitBeforeComparison? adjustValidUnitBeforeComparison;

  /// Initialize a newly created test descriptor.
  TestDescriptor(this.name, this.invalid, this.errorCodes, this.valid,
      {this.allFailing = false,
      this.failing,
      this.expectedErrorsInValidCode,
      this.adjustValidUnitBeforeComparison});
}

/// A description of a set of suffixes that are to be used to construct tests.
class TestSuffix {
  static final TestSuffix eof = TestSuffix('eof', '');

  /// The name of the suffix.
  final String name;

  /// The code to be appended to the test code.
  final String text;

  /// Initialize a newly created suffix.
  TestSuffix(this.name, this.text);
}
