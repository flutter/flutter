// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../generated/test_support.dart';
import '../src/util/yaml_test.dart';

main() {
  AnalysisError invalid_assignment = AnalysisError(
      TestSource(), 0, 1, CompileTimeErrorCode.INVALID_ASSIGNMENT, [
    ['x'],
    ['y']
  ]);

  AnalysisError missing_return =
      AnalysisError(TestSource(), 0, 1, HintCode.MISSING_RETURN, [
    ['x']
  ]);

  AnalysisError unused_local_variable =
      AnalysisError(TestSource(), 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
    ['x']
  ]);

  AnalysisError use_of_void_result = AnalysisError(
      TestSource(), 0, 1, CompileTimeErrorCode.USE_OF_VOID_RESULT, []);

  // We in-line a lint code here in order to avoid adding a dependency on the
  // linter package.
  AnalysisError annotate_overrides =
      AnalysisError(TestSource(), 0, 1, LintCode('annotate_overrides', ''));

  group('ErrorProcessor', () {
    late _TestContext context;

    setUp(() {
      context = _TestContext();
    });

    test('configureOptions', () {
      context.configureOptions('''
analyzer:
  errors:
    invalid_assignment: error # severity ERROR
    missing_return: false # ignore
    unused_local_variable: true # skipped
    use_of_void_result: unsupported_action # skipped
''');
      expect(context.getProcessor(invalid_assignment)!.severity,
          ErrorSeverity.ERROR);
      expect(context.getProcessor(missing_return)!.severity, isNull);
      expect(context.getProcessor(unused_local_variable), isNull);
      expect(context.getProcessor(use_of_void_result), isNull);
    });

    test('does not upgrade other warnings to errors in strong mode', () {
      context.configureOptions('''
analyzer:
  strong-mode: true
''');
      expect(context.getProcessor(unused_local_variable), isNull);
    });
  });

  group('ErrorConfig', () {
    var config = '''
analyzer:
  errors:
    invalid_assignment: unsupported_action # should be skipped
    missing_return: false
    unused_local_variable: error
''';

    group('processing', () {
      test('yaml map', () {
        var options = AnalysisOptionsProvider().getOptionsFromString(config);
        var errorConfig =
            ErrorConfig((options['analyzer'] as YamlMap)['errors']);
        expect(errorConfig.processors, hasLength(2));

        // ignore
        var missingReturnProcessor = errorConfig.processors
            .firstWhere((p) => p.appliesTo(missing_return));
        expect(missingReturnProcessor.severity, isNull);

        // error
        var unusedLocalProcessor = errorConfig.processors
            .firstWhere((p) => p.appliesTo(unused_local_variable));
        expect(unusedLocalProcessor.severity, ErrorSeverity.ERROR);

        // skip
        var invalidAssignmentProcessor = errorConfig.processors
            .firstWhereOrNull((p) => p.appliesTo(invalid_assignment));
        expect(invalidAssignmentProcessor, isNull);
      });

      test('string map', () {
        var options = wrap({
          'invalid_assignment': 'unsupported_action', // should be skipped
          'missing_return': 'false',
          'unused_local_variable': 'error'
        });
        var errorConfig = ErrorConfig(options);
        expect(errorConfig.processors, hasLength(2));

        // ignore
        var missingReturnProcessor = errorConfig.processors
            .firstWhere((p) => p.appliesTo(missing_return));
        expect(missingReturnProcessor.severity, isNull);

        // error
        var unusedLocalProcessor = errorConfig.processors
            .firstWhere((p) => p.appliesTo(unused_local_variable));
        expect(unusedLocalProcessor.severity, ErrorSeverity.ERROR);

        // skip
        var invalidAssignmentProcessor = errorConfig.processors
            .firstWhereOrNull((p) => p.appliesTo(invalid_assignment));
        expect(invalidAssignmentProcessor, isNull);
      });
    });

    test('configure lints', () {
      var options = AnalysisOptionsProvider().getOptionsFromString(
          'analyzer:\n  errors:\n    annotate_overrides: warning\n');
      var errorConfig = ErrorConfig((options['analyzer'] as YamlMap)['errors']);
      expect(errorConfig.processors, hasLength(1));

      ErrorProcessor processor = errorConfig.processors.first;
      expect(processor.appliesTo(annotate_overrides), true);
      expect(processor.severity, ErrorSeverity.WARNING);
    });
  });
}

class _TestContext {
  final analysisOptions = AnalysisOptionsImpl();

  void configureOptions(String options) {
    final optionMap = AnalysisOptionsProvider().getOptionsFromString(options);
    applyToAnalysisOptions(analysisOptions, optionMap);
  }

  ErrorProcessor? getProcessor(AnalysisError error) {
    return ErrorProcessor.getProcessor(analysisOptions, error);
  }
}
