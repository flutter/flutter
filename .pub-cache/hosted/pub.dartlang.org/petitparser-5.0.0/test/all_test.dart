import 'package:test/test.dart';

import 'context_test.dart' as context_test;
import 'debug_test.dart' as debug_test;
import 'definition_test.dart' as definition_test;
import 'example_test.dart' as example_test;
import 'expression_test.dart' as expression_test;
import 'indent_test.dart' as indent_test;
import 'matcher_test.dart' as matcher_test;
import 'parser_test.dart' as parser_test;
import 'reflection_test.dart' as reflection_test;
import 'regression_test.dart' as regression_test;
import 'tutorial_test.dart' as tutorial_test;

void main() {
  group('context', context_test.main);
  group('debug', debug_test.main);
  group('definition', definition_test.main);
  group('example', example_test.main);
  group('expression', expression_test.main);
  group('indent', indent_test.main);
  group('matcher', matcher_test.main);
  group('parser', parser_test.main);
  group('reflection', reflection_test.main);
  group('regression', regression_test.main);
  group('tutorial', tutorial_test.main);
}
