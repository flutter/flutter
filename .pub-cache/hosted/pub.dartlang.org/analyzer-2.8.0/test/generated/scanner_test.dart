// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/error_token.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LineInfoTest);
    defineReflectiveTests(ScannerTest);
  });
}

class CharacterRangeReaderTest {
  void test_advance() {
    CharSequenceReader baseReader = CharSequenceReader("xyzzy");
    CharacterRangeReader reader = CharacterRangeReader(baseReader, 1, 4);
    expect(reader.advance(), 0x79);
    expect(reader.advance(), 0x80);
    expect(reader.advance(), 0x80);
    expect(reader.advance(), -1);
    expect(reader.advance(), -1);
  }

  void test_creation() {
    CharSequenceReader baseReader = CharSequenceReader("xyzzy");
    CharacterRangeReader reader = CharacterRangeReader(baseReader, 1, 4);
    expect(reader, isNotNull);
  }

  void test_getOffset() {
    CharSequenceReader baseReader = CharSequenceReader("xyzzy");
    CharacterRangeReader reader = CharacterRangeReader(baseReader, 1, 2);
    expect(reader.offset, 1);
    reader.advance();
    expect(reader.offset, 2);
    reader.advance();
    expect(reader.offset, 2);
  }

  void test_getString() {
    CharSequenceReader baseReader = CharSequenceReader("__xyzzy__");
    CharacterRangeReader reader = CharacterRangeReader(baseReader, 2, 7);
    reader.offset = 5;
    expect(reader.getString(3, 0), "yzz");
    expect(reader.getString(4, 1), "zzy");
  }

  void test_peek() {
    CharSequenceReader baseReader = CharSequenceReader("xyzzy");
    CharacterRangeReader reader = CharacterRangeReader(baseReader, 1, 3);
    expect(reader.peek(), 0x79);
    expect(reader.peek(), 0x79);
    reader.advance();
    expect(reader.peek(), 0x80);
    expect(reader.peek(), 0x80);
    reader.advance();
    expect(reader.peek(), -1);
    expect(reader.peek(), -1);
  }

  void test_setOffset() {
    CharSequenceReader baseReader = CharSequenceReader("xyzzy");
    CharacterRangeReader reader = CharacterRangeReader(baseReader, 1, 4);
    reader.offset = 2;
    expect(reader.offset, 2);
  }
}

@reflectiveTest
class LineInfoTest {
  final featureSet = FeatureSet.latestLanguageVersion();

  void test_lineInfo_multilineComment() {
    String source = "/*\r\n *\r\n */";
    _assertLineInfo(source, [
      ScannerTest_ExpectedLocation(0, 1, 1),
      ScannerTest_ExpectedLocation(5, 2, 2),
      ScannerTest_ExpectedLocation(source.length - 1, 3, 3)
    ]);
  }

  void test_lineInfo_multilineString() {
    String source = "'''a\r\nbc\r\nd'''";
    _assertLineInfo(source, [
      ScannerTest_ExpectedLocation(0, 1, 1),
      ScannerTest_ExpectedLocation(7, 2, 2),
      ScannerTest_ExpectedLocation(source.length - 1, 3, 4)
    ]);
  }

  void test_lineInfo_multilineString_raw() {
    String source = "var a = r'''\nblah\n''';\n\nfoo";
    _assertLineInfo(source, [
      ScannerTest_ExpectedLocation(0, 1, 1),
      ScannerTest_ExpectedLocation(14, 2, 2),
      ScannerTest_ExpectedLocation(source.length - 2, 5, 2)
    ]);
  }

  void test_lineInfo_simpleClass() {
    String source =
        "class Test {\r\n    String s = '...';\r\n    int get x => s.MISSING_GETTER;\r\n}";
    _assertLineInfo(source, [
      ScannerTest_ExpectedLocation(0, 1, 1),
      ScannerTest_ExpectedLocation(source.indexOf("MISSING_GETTER"), 3, 20),
      ScannerTest_ExpectedLocation(source.length - 1, 4, 1)
    ]);
  }

  void test_lineInfo_slashN() {
    String source = "class Test {\n}";
    _assertLineInfo(source, [
      ScannerTest_ExpectedLocation(0, 1, 1),
      ScannerTest_ExpectedLocation(source.indexOf("}"), 2, 1)
    ]);
  }

  void test_linestarts() {
    String source = "var\r\ni\n=\n1;\n";
    GatheringErrorListener listener = GatheringErrorListener();
    Scanner scanner =
        Scanner(TestSource(), CharSequenceReader(source), listener)
          ..configureFeatures(
            featureSetForOverriding: featureSet,
            featureSet: featureSet,
          );
    var token = scanner.tokenize();
    expect(token.lexeme, 'var');
    var lineStarts = scanner.lineStarts;
    expect(lineStarts, orderedEquals([0, 5, 7, 9, 12]));
  }

  void test_translate_missing_closing_gt_error() {
    // Ensure that the UnmatchedToken error for missing '>' is translated
    // to the correct analyzer error code.
    // See https://github.com/dart-lang/sdk/issues/30320
    String source = '<!-- @Component(';
    GatheringErrorListener listener = GatheringErrorListener();
    Scanner scanner =
        Scanner(TestSource(), CharSequenceReader(source), listener)
          ..configureFeatures(
            featureSetForOverriding: featureSet,
            featureSet: featureSet,
          );
    Token token = scanner.tokenize(reportScannerErrors: false);
    expect(token, TypeMatcher<UnmatchedToken>());
    token = token.next!;
    expect(token, TypeMatcher<UnmatchedToken>());
    token = token.next!;
    expect(token, isNot(TypeMatcher<ErrorToken>()));
  }

  void _assertLineInfo(
      String source, List<ScannerTest_ExpectedLocation> expectedLocations) {
    GatheringErrorListener listener = GatheringErrorListener();
    _scanWithListener(source, listener);
    listener.assertNoErrors();
    LineInfo info = listener.getLineInfo(TestSource())!;
    expect(info, isNotNull);
    int count = expectedLocations.length;
    for (int i = 0; i < count; i++) {
      ScannerTest_ExpectedLocation expectedLocation = expectedLocations[i];
      var location = info.getLocation(expectedLocation._offset);
      expect(location.lineNumber, expectedLocation._lineNumber,
          reason: 'Line number in location $i');
      expect(location.columnNumber, expectedLocation._columnNumber,
          reason: 'Column number in location $i');
    }
  }

  Token _scanWithListener(
    String source,
    GatheringErrorListener listener,
  ) {
    Scanner scanner =
        Scanner(TestSource(), CharSequenceReader(source), listener)
          ..configureFeatures(
            featureSetForOverriding: featureSet,
            featureSet: featureSet,
          );
    Token result = scanner.tokenize();
    listener.setLineInfo(TestSource(), scanner.lineStarts);
    return result;
  }
}

@reflectiveTest
class ScannerTest with ResourceProviderMixin {
  test_featureSet() {
    var scanner = _createScanner(r'''
// @dart = 2.0
''');
    var defaultFeatureSet = FeatureSet.latestLanguageVersion();
    expect(defaultFeatureSet.isEnabled(Feature.extension_methods), isTrue);

    scanner.configureFeatures(
      featureSetForOverriding: FeatureSet.latestLanguageVersion(),
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    scanner.tokenize();

    var featureSet = scanner.featureSet;
    expect(featureSet.isEnabled(Feature.extension_methods), isFalse);
  }

  test_featureSet_majorOverflow() {
    var scanner = _createScanner(r'''
// @dart = 99999999999999999999999999999999.0
''');
    var featureSet = FeatureSet.latestLanguageVersion();
    scanner.configureFeatures(
      featureSetForOverriding: featureSet,
      featureSet: featureSet,
    );
    scanner.tokenize();
    // Don't check features, but should not crash.
  }

  test_featureSet_minorOverflow() {
    var scanner = _createScanner(r'''
// @dart = 2.99999999999999999999999999999999
''');
    var featureSet = FeatureSet.latestLanguageVersion();
    scanner.configureFeatures(
      featureSetForOverriding: featureSet,
      featureSet: featureSet,
    );
    scanner.tokenize();
    // Don't check features, but should not crash.
  }

  Scanner _createScanner(String content) {
    var path = convertPath('/test/lib/a.dart');
    var source = StringSource(content, path);
    var reader = CharSequenceReader(content);
    var errorCollector = RecordingErrorListener();
    return Scanner(source, reader, errorCollector);
  }
}

/// An `ExpectedLocation` encodes information about the expected location of a
/// given offset in source code.
class ScannerTest_ExpectedLocation {
  final int _offset;

  final int _lineNumber;

  final int _columnNumber;

  ScannerTest_ExpectedLocation(
      this._offset, this._lineNumber, this._columnNumber);
}

/// A `TokenStreamValidator` is used to validate the correct construction of a
/// stream of tokens.
class TokenStreamValidator {
  /// Validate that the stream of tokens that starts with the given [token] is
  /// correct.
  void validate(Token token) {
    StringBuffer buffer = StringBuffer();
    _validateStream(buffer, token);
    if (buffer.length > 0) {
      fail(buffer.toString());
    }
  }

  void _validateStream(StringBuffer buffer, Token? token) {
    if (token == null) {
      return;
    }
    late Token previousToken;
    int previousEnd = -1;
    Token? currentToken = token;
    while (currentToken != null && currentToken.type != TokenType.EOF) {
      _validateStream(buffer, currentToken.precedingComments);
      TokenType type = currentToken.type;
      if (type == TokenType.OPEN_CURLY_BRACKET ||
          type == TokenType.OPEN_PAREN ||
          type == TokenType.OPEN_SQUARE_BRACKET ||
          type == TokenType.STRING_INTERPOLATION_EXPRESSION) {
        if (currentToken is! BeginToken) {
          buffer.write("\r\nExpected BeginToken, found ");
          buffer.write(currentToken.runtimeType.toString());
          buffer.write(" ");
          _writeToken(buffer, currentToken);
        }
      }
      int currentStart = currentToken.offset;
      int currentLength = currentToken.length;
      int currentEnd = currentStart + currentLength - 1;
      if (currentStart <= previousEnd) {
        buffer.write("\r\nInvalid token sequence: ");
        _writeToken(buffer, previousToken);
        buffer.write(" followed by ");
        _writeToken(buffer, currentToken);
      }
      previousEnd = currentEnd;
      previousToken = currentToken;
      currentToken = currentToken.next;
    }
  }

  void _writeToken(StringBuffer buffer, Token token) {
    buffer.write("[");
    buffer.write(token.type);
    buffer.write(", '");
    buffer.write(token.lexeme);
    buffer.write("', ");
    buffer.write(token.offset);
    buffer.write(", ");
    buffer.write(token.length);
    buffer.write("]");
  }
}
