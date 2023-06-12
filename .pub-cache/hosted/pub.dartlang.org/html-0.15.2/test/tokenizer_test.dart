@TestOn('vm')
library tokenizer_test;

import 'dart:convert';
import 'dart:io';
// Note: mirrors used to match the getattr usage in the original test
import 'dart:mirrors' show reflect;

import 'package:html/src/token.dart';
import 'package:html/src/tokenizer.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';

import 'support.dart';

void main() async {
  await for (var path in dataFiles('tokenizer')) {
    if (!path.endsWith('.test')) continue;

    final text = File(path).readAsStringSync();
    final tests = jsonDecode(text) as Map<String, dynamic>;
    final testName = pathos.basenameWithoutExtension(path);
    final testList = tests['tests'] as List?;
    if (testList == null) continue;

    group(testName, () {
      for (var index = 0; index < testList.length; index++) {
        final testInfo = testList[index] as Map<String, dynamic>;

        testInfo.putIfAbsent('initialStates', () => ['Data state']);
        for (var initialState in testInfo['initialStates'] as List) {
          test(testInfo['description'], () {
            testInfo['initialState'] = camelCase(initialState as String);
            runTokenizerTest(testInfo);
          });
        }
      }
    });
  }
}

class TokenizerTestParser {
  final String? _state;
  final String? _lastStartTag;
  final bool _generateSpans;
  List<List<Object?>>? outputTokens;

  TokenizerTestParser(String? initialState,
      [String? lastStartTag, bool generateSpans = false])
      : _state = initialState,
        _lastStartTag = lastStartTag,
        _generateSpans = generateSpans;

  List<dynamic>? parse(String str) {
    // Note: we need to pass bytes to the tokenizer if we want it to handle BOM.
    final bytes = utf8.encode(str);
    final tokenizer =
        HtmlTokenizer(bytes, encoding: 'utf-8', generateSpans: _generateSpans);
    outputTokens = [];

    // Note: we can't get a closure of the state method. However, we can
    // create a new closure to invoke it via mirrors.
    final mtok = reflect(tokenizer);
    tokenizer.state =
        () => mtok.invoke(Symbol(_state!), const []).reflectee as bool;

    if (_lastStartTag != null) {
      tokenizer.currentToken = StartTagToken(_lastStartTag);
    }

    while (tokenizer.moveNext()) {
      final token = tokenizer.current;
      switch (token.kind) {
        case TokenKind.characters:
          processCharacters(token as CharactersToken);
          break;
        case TokenKind.spaceCharacters:
          processSpaceCharacters(token as SpaceCharactersToken);
          break;
        case TokenKind.startTag:
          processStartTag(token as StartTagToken);
          break;
        case TokenKind.endTag:
          processEndTag(token as EndTagToken);
          break;
        case TokenKind.comment:
          processComment(token as CommentToken);
          break;
        case TokenKind.doctype:
          processDoctype(token as DoctypeToken);
          break;
        case TokenKind.parseError:
          processParseError(token as ParseErrorToken);
          break;
      }
    }

    return outputTokens;
  }

  void processDoctype(DoctypeToken token) {
    addOutputToken(token,
        ['DOCTYPE', token.name, token.publicId, token.systemId, token.correct]);
  }

  void processStartTag(StartTagToken token) {
    addOutputToken(
        token, ['StartTag', token.name, token.data, token.selfClosing]);
  }

  void processEndTag(EndTagToken token) {
    addOutputToken(token, ['EndTag', token.name, token.selfClosing]);
  }

  void processComment(StringToken token) {
    addOutputToken(token, ['Comment', token.data]);
  }

  void processSpaceCharacters(StringToken token) {
    processCharacters(token);
  }

  void processCharacters(StringToken token) {
    addOutputToken(token, ['Character', token.data]);
  }

  void processEOF(StringToken token) {}

  void processParseError(StringToken token) {
    // TODO(jmesserly): when debugging test failures it can be useful to add
    // logging here like `print('ParseError $token');`. It would be nice to
    // use the actual logging library.
    addOutputToken(token, ['ParseError', token.data]);
  }

  void addOutputToken(Token token, List<Object?> array) {
    outputTokens!.add([
      ...array,
      if (token.span != null && _generateSpans) token.span!.start.offset,
      if (token.span != null && _generateSpans) token.span!.end.offset,
    ]);
  }
}

/// [tokens] can contain strings, lists, and maps.
List<dynamic> concatenateCharacterTokens(List<dynamic> tokens) {
  final outputTokens = <dynamic>[];
  for (var token in tokens) {
    if (token != 'ParseError' && (token as List)[0] == 'Character') {
      if (outputTokens.isNotEmpty &&
          outputTokens.last != 'ParseError' &&
          (outputTokens.last as List)[0] == 'Character') {
        (outputTokens.last as List)[1] =
            '${(outputTokens.last as List)[1]}${token[1]}';
      } else {
        outputTokens.add(token);
      }
    } else {
      outputTokens.add(token);
    }
  }
  return outputTokens;
}

List<dynamic> normalizeTokens(List<dynamic> tokens) {
  // TODO: convert tests to reflect arrays
  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i] as List;
    if (token[0] == 'ParseError') {
      tokens[i] = token[0];
    }
  }
  return tokens;
}

/// Test whether the test has passed or failed
///
/// If the ignoreErrorOrder flag is set to true we don't test the relative
/// positions of parse errors and non parse errors.
void expectTokensMatch(List<dynamic> expectedTokens,
    List<dynamic> receivedTokens, bool ignoreErrorOrder,
    [bool ignoreErrors = false, String? message]) {
  // If the 'selfClosing' attribute is not included in the expected test tokens,
  // remove it from the received token.
  var removeSelfClosing = false;
  for (var token in expectedTokens.whereType<List<dynamic>>()) {
    if (token[0] == 'StartTag' && token.length == 3 ||
        token[0] == 'EndTag' && token.length == 2) {
      removeSelfClosing = true;
      break;
    }
  }

  if (removeSelfClosing) {
    for (var token in receivedTokens.whereType<List<dynamic>>()) {
      if (token[0] == 'StartTag' || token[0] == 'EndTag') {
        token.removeLast();
      }
    }
  }

  if (!ignoreErrorOrder && !ignoreErrors) {
    expect(receivedTokens, equals(expectedTokens), reason: message);
  } else {
    // Sort the tokens into two groups; non-parse errors and parse errors
    final expectedNonErrors = expectedTokens.where((t) => t != 'ParseError');
    final receivedNonErrors = receivedTokens.where((t) => t != 'ParseError');

    expect(receivedNonErrors, equals(expectedNonErrors), reason: message);
    if (!ignoreErrors) {
      final expectedParseErrors =
          expectedTokens.where((t) => t == 'ParseError');
      final receivedParseErrors =
          receivedTokens.where((t) => t == 'ParseError');
      expect(receivedParseErrors, equals(expectedParseErrors), reason: message);
    }
  }
}

void runTokenizerTest(Map<String, dynamic> testInfo) {
  // XXX - move this out into the setup function
  // concatenate all consecutive character tokens into a single token
  if (testInfo.containsKey('doubleEscaped')) {
    testInfo = unescape(testInfo);
  }

  final expected = concatenateCharacterTokens(testInfo['output'] as List);
  if (!testInfo.containsKey('lastStartTag')) {
    testInfo['lastStartTag'] = null;
  }
  final parser = TokenizerTestParser(
      testInfo['initialState'] as String?,
      testInfo['lastStartTag'] as String?,
      testInfo['generateSpans'] as bool? ?? false);
  var tokens = parser.parse(testInfo['input'] as String)!;
  tokens = concatenateCharacterTokens(tokens);
  final received = normalizeTokens(tokens);
  final errorMsg = [
    '\n\nInitial state:',
    testInfo['initialState'],
    '\nInput:',
    testInfo['input'],
    '\nExpected:',
    expected,
    '\nreceived:',
    tokens
  ].map((s) => '$s').join('\n');
  final ignoreErrorOrder = testInfo['ignoreErrorOrder'] as bool? ?? false;

  expectTokensMatch(expected, received, ignoreErrorOrder, true, errorMsg);
}

Map<String, dynamic> unescape(Map<String, dynamic> testInfo) {
  // TODO(sigmundch,jmesserly): we currently use jsonDecode to unescape the
  // unicode characters in the string, we should use a decoding that works with
  // any control characters.
  dynamic decode(String inp) => inp == '\u0000' ? inp : jsonDecode('"$inp"');

  testInfo['input'] = decode(testInfo['input'] as String);

  for (var token in testInfo['output'] as List) {
    if (token == 'ParseError') {
      continue;
    }

    token as List;
    token[1] = decode(token[1] as String);

    if (token.length > 2) {
      for (var pair in token[2] as List) {
        pair as List;
        final key = pair[0] as String;
        final value = pair[1] as String;

        (token[2] as Map).remove(key);
        (token[2] as Map)[decode(key)] = decode(value);
      }
    }
  }

  return testInfo;
}

String camelCase(String s) {
  s = s.toLowerCase();
  final result = StringBuffer();
  for (var match in RegExp(r'\W+(\w)(\w+)').allMatches(s)) {
    if (result.length == 0) result.write(s.substring(0, match.start));
    result.write(match.group(1)!.toUpperCase());
    result.write(match.group(2));
  }
  return result.toString();
}
