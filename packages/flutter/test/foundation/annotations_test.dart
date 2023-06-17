import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test Category constructor', () {
    const List<String> sections = [
       'First section',
       'Second section',
       'Third section'
      ];
    const Category category = Category(sections);
    expect(category.sections, sections);
  });
  test('test DocumentationIcon constructor', () {
    const DocumentationIcon docIcon = DocumentationIcon('Test String');
    expect(docIcon.url, contains('Test String'));
  });

  test('test Summary constructor', () {
    const Summary summary = Summary('Test String');
    expect(summary.text, contains('Test String'));
  });
}
