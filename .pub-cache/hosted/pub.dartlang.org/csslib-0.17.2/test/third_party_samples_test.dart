@TestOn('vm')
library samples_test;

import 'dart:io';

import 'package:test/test.dart';
import 'package:csslib/parser.dart';
import 'package:path/path.dart' as path;

const testOptions = PreprocessorOptions(
  useColors: false,
  checked: false,
  warningsAsErrors: true,
  inputFile: 'memory',
);

void testCSSFile(File cssFile) {
  final errors = <Message>[];
  final css = cssFile.readAsStringSync();
  final stylesheet = parse(css, errors: errors, options: testOptions);

  expect(stylesheet, isNotNull);
  expect(errors, isEmpty, reason: errors.toString());
}

void main() async {
  // Iterate over all sub-folders of third_party,
  // and then all css files in those.
  final third_party = path.join(Directory.current.path, 'third_party');
  for (var entity in Directory(third_party).listSync()) {
    if (await FileSystemEntity.isDirectory(entity.path)) {
      for (var element in Directory(entity.path).listSync()) {
        if (element is File && element.uri.pathSegments.last.endsWith('.css')) {
          test(element.uri.pathSegments.last, () => testCSSFile(element));
        }
      }
    }
  }
}
