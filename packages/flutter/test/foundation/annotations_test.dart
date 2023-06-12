import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test DocumentationIcon object', () {
    const DocumentationIcon docIcon = DocumentationIcon('Test String');
    expect(docIcon.url, contains('Test String'));
  });

  test('test Summary object', () {
    const Summary summary = Summary('Test String');
    expect(summary.text, contains('Test String'));
  });
}
