import 'package:test/test.dart';

import 'builder_test.dart' as builder_test;
import 'entity_test.dart' as entity_test;
import 'examples_test.dart' as examples_test;
import 'exceptions_test.dart' as exceptions_test;
import 'iterable_test.dart' as iterable_test;
import 'mutate_test.dart' as mutate_test;
import 'namespace_test.dart' as namespace_test;
import 'navigation_test.dart' as navigation_test;
import 'node_test.dart' as node_test;
import 'parse_test.dart' as parse_test;
import 'query_test.dart' as query_test;
import 'regression_test.dart' as regression_test;
import 'stream_test.dart' as stream_test;
import 'tutorial_test.dart' as tutorial_test;
import 'utils_test.dart' as utils_test;
import 'visitor_test.dart' as visitor_test;

void main() {
  group('builder', builder_test.main);
  group('entity', entity_test.main);
  group('examples', examples_test.main);
  group('exceptions', exceptions_test.main);
  group('iterable', iterable_test.main);
  group('mutate', mutate_test.main);
  group('namespace', namespace_test.main);
  group('navigation', navigation_test.main);
  group('node', node_test.main);
  group('parse', parse_test.main);
  group('query', query_test.main);
  group('regression', regression_test.main);
  group('stream', stream_test.main);
  group('tutorial', tutorial_test.main);
  group('utils', utils_test.main);
  group('visitor', visitor_test.main);
}
