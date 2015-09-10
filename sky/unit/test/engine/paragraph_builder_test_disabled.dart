import 'dart:sky';

import 'package:test/test.dart';

void main() {
  test("Should be able to build and layout a paragraph", () {
    ParagraphBuilder builder = new ParagraphBuilder();
    builder.addText('Hello');
    Paragraph paragraph = builder.build(new ParagraphStyle());
    expect(paragraph, isNotNull);
    paragraph.layout();
  });
}
