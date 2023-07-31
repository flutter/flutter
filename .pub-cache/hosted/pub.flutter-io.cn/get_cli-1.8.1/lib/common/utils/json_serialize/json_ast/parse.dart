import 'dart:math';

import './error.dart';
import './location.dart';
import './parse_error_types.dart';
import './tokenize.dart';
import './utils/substring.dart';

enum _ObjectState { _START_, OPEN_OBJECT, PROPERTY, COMMA }

enum _PropertyState { _START_, KEY, COLON }

enum _ArrayState { _START_, OPEN_ARRAY, VALUE, COMMA }

JSONASTException errorEof(
    String input, List<dynamic> tokenList, Settings settings) {
  final loc = (tokenList.isNotEmpty
      ? tokenList[tokenList.length - 1].loc.end as Loc
      : Loc(line: 1, column: 1));

  return JSONASTException(
      unexpectedEnd(), input, settings.source, loc.line, loc.column);
}

/// [hexCode] is the hexCode string without '\u' prefix
String parseHexEscape(String hexCode) {
  var charCode = 0;
  final minLength = min(hexCode.length, 4);
  for (var i = 0; i < minLength; i++) {
    charCode = charCode * 16 + int.tryParse(hexCode[i], radix: 16)!;
  }
  return String.fromCharCode(charCode);
}

final escapes = {
  'b': '\b', // Backspace
  'f': '\f', // Form feed
  'n': '\n', // New line
  'r': '\r', // Carriage return
  't': '\t' // Horizontal tab
};

final passEscapes = ['"', '\\', '/'];

String parseString(String string) {
  final result = StringBuffer();
  for (var i = 0; i < string.length; i++) {
    final char = string[i];
    if (char == '\\') {
      i++;
      final nextChar = string[i];
      if (nextChar == 'u') {
        result.write(parseHexEscape(safeSubstring(string, i + 1, i + 5)));
        i += 4;
      } else if (passEscapes.contains(nextChar)) {
        result.write(nextChar);
      } else if (escapes.containsKey(nextChar)) {
        result.write(escapes[nextChar]);
      } else {
        break;
      }
    } else {
      result.write(char);
    }
  }
  return result.toString();
}

ValueIndex<ObjectNode>? parseObject(
    String input, List<Token> tokenList, int index, Settings settings) {
  // object: LEFT_BRACE (property (COMMA property)*)? RIGHT_BRACE
  late Token startToken;
  var object = ObjectNode();
  var state = _ObjectState._START_;

  while (index < tokenList.length) {
    final token = tokenList[index];

    switch (state) {
      case _ObjectState._START_:
        {
          if (token.type == TokenType.LEFT_BRACE) {
            startToken = token;
            state = _ObjectState.OPEN_OBJECT;
            index++;
          } else {
            return null;
          }
          break;
        }

      case _ObjectState.OPEN_OBJECT:
        {
          if (token.type == TokenType.RIGHT_BRACE) {
            //  if (settings.loc != null) {
            object = object.copyWith(
                loc: Location.create(
                    startToken.loc!.start.line,
                    startToken.loc!.start.column,
                    startToken.loc!.start.offset,
                    token.loc!.end.line,
                    token.loc!.end.column,
                    token.loc!.end.offset,
                    settings.source));
            //  }
            return ValueIndex(object, index + 1);
          } else {
            final property = parseProperty(input, tokenList, index, settings)!;
            object.children.add(property.value);
            state = _ObjectState.PROPERTY;
            index = property.index;
          }
          break;
        }

      case _ObjectState.PROPERTY:
        {
          if (token.type == TokenType.RIGHT_BRACE) {
            if (settings.loc) {
              object = object.copyWith(
                loc: Location.create(
                  startToken.loc!.start.line,
                  startToken.loc!.start.column,
                  startToken.loc!.start.offset,
                  token.loc!.end.line,
                  token.loc!.end.column,
                  token.loc!.end.offset,
                  settings.source,
                ),
              );
            }
            return ValueIndex(object, index + 1);
          } else if (token.type == TokenType.COMMA) {
            state = _ObjectState.COMMA;
            index++;
          } else {
            final msg = unexpectedToken(
                substring(
                    input, token.loc!.start.offset!, token.loc!.end.offset),
                settings.source,
                token.loc!.start.line,
                token.loc!.start.column);
            throw JSONASTException(msg, input, settings.source,
                token.loc!.start.line, token.loc!.start.column);
          }
          break;
        }

      case _ObjectState.COMMA:
        {
          final property = parseProperty(input, tokenList, index, settings);
          if (property != null) {
            index = property.index;
            object.children.add(property.value);
            state = _ObjectState.PROPERTY;
          } else {
            final msg = unexpectedToken(
                substring(
                    input, token.loc!.start.offset!, token.loc!.end.offset),
                settings.source,
                token.loc!.start.line,
                token.loc!.start.column);
            throw JSONASTException(msg, input, settings.source,
                token.loc!.start.line, token.loc!.start.column);
          }
          break;
        }
    }
  }
  throw errorEof(input, tokenList, settings);
}

ValueIndex<PropertyNode>? parseProperty(
    String input, List<Token> tokenList, int index, Settings settings) {
  // property: STRING COLON value
  late Token startToken;
  var property = PropertyNode();
  var state = _PropertyState._START_;

  while (index < tokenList.length) {
    final token = tokenList[index];

    switch (state) {
      case _PropertyState._START_:
        {
          if (token.type == TokenType.STRING) {
            final value = parseString(safeSubstring(input,
                token.loc!.start.offset! + 1, token.loc!.end.offset! - 1));
            var key = ValueNode(value, token.value);
            if (settings.loc) {
              key = key.copyWith(loc: token.loc);
            }
            startToken = token;
            property = property.copyWith(key: key);
            state = _PropertyState.KEY;
            index++;
          } else {
            return null;
          }
          break;
        }

      case _PropertyState.KEY:
        {
          if (token.type == TokenType.COLON) {
            state = _PropertyState.COLON;
            index++;
          } else {
            final msg = unexpectedToken(
                substring(
                    input, token.loc!.start.offset!, token.loc!.end.offset),
                settings.source,
                token.loc!.start.line,
                token.loc!.start.column);
            throw JSONASTException(msg, input, settings.source,
                token.loc!.start.line, token.loc!.start.column);
          }
          break;
        }

      case _PropertyState.COLON:
        {
          final value = _parseValue<Node?>(input, tokenList, index, settings);
          property = property.copyWith(value: value.value);
          if (settings.loc) {
            property = property.copyWith(
                loc: Location.create(
                    startToken.loc?.start.line,
                    startToken.loc?.start.column,
                    startToken.loc?.start.offset,
                    value.value?.loc?.end.line,
                    value.value?.loc?.end.column,
                    value.value?.loc?.end.offset,
                    settings.source));
          }
          return ValueIndex(property, value.index);
        }
    }
  }
  return null;
}

ValueIndex<ArrayNode>? parseArray(
    String input, List<Token> tokenList, int index, Settings settings) {
  // array: LEFT_BRACKET (value (COMMA value)*)? RIGHT_BRACKET
  late Token startToken;
  var array = ArrayNode();
  var state = _ArrayState._START_;
  Token token;
  while (index < tokenList.length) {
    token = tokenList[index];
    switch (state) {
      case _ArrayState._START_:
        {
          if (token.type == TokenType.LEFT_BRACKET) {
            startToken = token;
            state = _ArrayState.OPEN_ARRAY;
            index++;
          } else {
            return null;
          }
          break;
        }

      case _ArrayState.OPEN_ARRAY:
        {
          if (token.type == TokenType.RIGHT_BRACKET) {
            if (settings.loc) {
              array = array.copyWith(
                  loc: Location.create(
                      startToken.loc!.start.line,
                      startToken.loc!.start.column,
                      startToken.loc!.start.offset,
                      token.loc!.end.line,
                      token.loc!.end.column,
                      token.loc!.end.offset,
                      settings.source));
            }
            return ValueIndex(array, index + 1);
          } else {
            final value = _parseValue<Node>(input, tokenList, index, settings);
            index = value.index;
            array.children.add(value.value);
            state = _ArrayState.VALUE;
          }
          break;
        }

      case _ArrayState.VALUE:
        {
          if (token.type == TokenType.RIGHT_BRACKET) {
            if (settings.loc) {
              array = array.copyWith(
                  loc: Location.create(
                      startToken.loc!.start.line,
                      startToken.loc!.start.column,
                      startToken.loc!.start.offset,
                      token.loc!.end.line,
                      token.loc!.end.column,
                      token.loc!.end.offset,
                      settings.source));
            }
            return ValueIndex(array, index + 1);
          } else if (token.type == TokenType.COMMA) {
            state = _ArrayState.COMMA;
            index++;
          } else {
            final msg = unexpectedToken(
                substring(
                    input, token.loc!.start.offset!, token.loc!.end.offset),
                settings.source,
                token.loc!.start.line,
                token.loc!.start.column);
            throw JSONASTException(msg, input, settings.source,
                token.loc!.start.line, token.loc!.start.column);
          }
          break;
        }

      case _ArrayState.COMMA:
        {
          final value = _parseValue<Node>(input, tokenList, index, settings);
          index = value.index;
          array.children.add(value.value);
          state = _ArrayState.VALUE;
          break;
        }
    }
  }
  throw errorEof(input, tokenList, settings);
}

ValueIndex<LiteralNode>? parseLiteral(
    String input, List<Token> tokenList, int index, Settings settings) {
  // literal: STRING | NUMBER | TRUE | FALSE | NULL
  final token = tokenList[index];
  dynamic value;

  switch (token.type) {
    case TokenType.STRING:
      {
        value = parseString(safeSubstring(
            input, token.loc!.start.offset! + 1, token.loc!.end.offset! - 1));
        break;
      }
    case TokenType.NUMBER:
      {
        value = int.tryParse(token.value!);
        value ??= double.tryParse(token.value!);
        break;
      }
    case TokenType.TRUE:
      {
        value = true;
        break;
      }
    case TokenType.FALSE:
      {
        value = false;
        break;
      }
    case TokenType.NULL:
      {
        value = null;
        break;
      }
    default:
      {
        return null;
      }
  }

  var literal = LiteralNode(value, token.value);
  if (settings.loc) {
    literal = literal.copyWith(loc: token.loc);
  }
  return ValueIndex(literal, index + 1);
}

typedef ParserFun<T> = ValueIndex<T>? Function(
    String input, List<Token> tokenList, int index, Settings settings);

List<ParserFun> _parsersList = [parseLiteral, parseObject, parseArray];

ValueIndex<T>? _findValueIndex<T>(
    String input, List<Token> tokenList, int index, Settings settings) {
  for (var i = 0; i < _parsersList.length; i++) {
    final parser = _parsersList.elementAt(i) as ValueIndex<T>? Function(
        String, List<Token>, int, Settings);
    final valueIndex = parser(input, tokenList, index, settings);
    if (valueIndex != null) {
      return valueIndex;
    }
  }
  return null;
}

ValueIndex<T> _parseValue<T>(
    String input, List<Token> tokenList, int index, Settings settings) {
  // value: literal | object | array
  final token = tokenList[index];

  final value = _findValueIndex<T>(input, tokenList, index, settings);

  if (value != null) {
    return value;
  } else {
    final msg = unexpectedToken(
        substring(input, token.loc!.start.offset!, token.loc!.end.offset),
        settings.source,
        token.loc!.start.line,
        token.loc!.start.column);
    throw JSONASTException(msg, input, settings.source, token.loc!.start.line,
        token.loc!.start.column);
  }
}

Node parse(String input, Settings settings) {
  final tokenList = tokenize(input, settings);

  if (tokenList.isEmpty) {
    throw errorEof(input, tokenList, settings);
  }

  final value = _parseValue<Node>(input, tokenList, 0, settings);

  if (value.index == tokenList.length) {
    return value.value;
  }

  final token = tokenList[value.index];

  final msg = unexpectedToken(
      substring(input, token.loc!.start.offset!, token.loc!.end.offset),
      settings.source,
      token.loc!.start.line,
      token.loc!.start.column);
  throw JSONASTException(msg, input, settings.source, token.loc!.start.line,
      token.loc!.start.column);
}
