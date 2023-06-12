library tokenizer;

import 'dart:collection';
import 'package:html/parser.dart' show HtmlParser;
import 'constants.dart';
import 'html_input_stream.dart';
import 'token.dart';
import 'utils.dart';

// Group entities by their first character, for faster lookups

// TODO(jmesserly): we could use a better data structure here like a trie, if
// we had it implemented in Dart.
Map<String, List<String>> entitiesByFirstChar = (() {
  final result = <String, List<String>>{};
  for (var k in entities.keys) {
    result.putIfAbsent(k[0], () => []).add(k);
  }
  return result;
})();

// TODO(jmesserly): lots of ways to make this faster:
// - use char codes everywhere instead of 1-char strings
// - use switch instead of contains, indexOf
// - use switch instead of the sequential if tests
// - avoid string concat

/// This class takes care of tokenizing HTML.
class HtmlTokenizer implements Iterator<Token> {
  // TODO(jmesserly): a lot of these could be made private

  final HtmlInputStream stream;

  final bool lowercaseElementName;

  final bool lowercaseAttrName;

  /// True to generate spans in for [Token.span].
  final bool generateSpans;

  /// True to generate spans for attributes.
  final bool attributeSpans;

  /// This reference to the parser is used for correct CDATA handling.
  /// The [HtmlParser] will set this at construction time.
  HtmlParser? parser;

  final Queue<Token?> tokenQueue;

  /// Holds the token that is currently being processed.
  Token? currentToken;

  /// Holds a reference to the method to be invoked for the next parser state.
  late bool Function() state;

  final StringBuffer _buffer = StringBuffer();

  late int _lastOffset;

  // TODO(jmesserly): ideally this would be a LinkedHashMap and we wouldn't add
  // an item until it's ready. But the code doesn't have a clear notion of when
  // it's "done" with the attribute.
  List<TagAttribute>? _attributes;
  Set<String>? _attributeNames;

  HtmlTokenizer(doc,
      {String? encoding,
      bool parseMeta = true,
      this.lowercaseElementName = true,
      this.lowercaseAttrName = true,
      this.generateSpans = false,
      String? sourceUrl,
      this.attributeSpans = false})
      : stream =
            HtmlInputStream(doc, encoding, parseMeta, generateSpans, sourceUrl),
        tokenQueue = Queue() {
    reset();
  }

  TagToken get currentTagToken => currentToken as TagToken;
  DoctypeToken get currentDoctypeToken => currentToken as DoctypeToken;
  StringToken get currentStringToken => currentToken as StringToken;

  Token? _current;
  @override
  Token get current => _current!;

  final StringBuffer _attributeName = StringBuffer();
  final StringBuffer _attributeValue = StringBuffer();

  void _markAttributeEnd(int offset) {
    _attributes!.last.value = '$_attributeValue';
    if (attributeSpans) _attributes!.last.end = stream.position + offset;
  }

  void _markAttributeValueStart(int offset) {
    if (attributeSpans) _attributes!.last.startValue = stream.position + offset;
  }

  void _markAttributeValueEnd(int offset) {
    if (attributeSpans) _attributes!.last.endValue = stream.position + offset;
    _markAttributeEnd(offset);
  }

  // Note: we could track the name span here, if we need it.
  void _markAttributeNameEnd(int offset) => _markAttributeEnd(offset);

  void _addAttribute(String name) {
    _attributes ??= [];
    _attributeName.clear();
    _attributeName.write(name);
    _attributeValue.clear();
    final attr = TagAttribute();
    _attributes!.add(attr);
    if (attributeSpans) attr.start = stream.position - name.length;
  }

  /// This is where the magic happens.
  ///
  /// We do our usually processing through the states and when we have a token
  /// to return we yield the token which pauses processing until the next token
  /// is requested.
  @override
  bool moveNext() {
    // Start processing. When EOF is reached state will return false;
    // instead of true and the loop will terminate.
    while (stream.errors.isEmpty && tokenQueue.isEmpty) {
      if (!state()) {
        _current = null;
        return false;
      }
    }
    if (stream.errors.isNotEmpty) {
      _current = ParseErrorToken(stream.errors.removeFirst());
    } else {
      assert(tokenQueue.isNotEmpty);
      _current = tokenQueue.removeFirst();
    }
    return true;
  }

  /// Resets the tokenizer state. Calling this does not reset the [stream] or
  /// the [parser].
  void reset() {
    _lastOffset = 0;
    tokenQueue.clear();
    currentToken = null;
    _buffer.clear();
    _attributes = null;
    _attributeNames = null;
    state = dataState;
  }

  /// Adds a token to the queue. Sets the span if needed.
  void _addToken(Token token) {
    if (generateSpans && token.span == null) {
      final offset = stream.position;
      token.span = stream.fileInfo!.span(_lastOffset, offset);
      if (token is! ParseErrorToken) {
        _lastOffset = offset;
      }
    }
    tokenQueue.add(token);
  }

  /// This function returns either U+FFFD or the character based on the
  /// decimal or hexadecimal representation. It also discards ";" if present.
  /// If not present it will add a [ParseErrorToken].
  String consumeNumberEntity(bool isHex) {
    var allowed = isDigit;
    var radix = 10;
    if (isHex) {
      allowed = isHexDigit;
      radix = 16;
    }

    final charStack = <String?>[];

    // Consume all the characters that are in range while making sure we
    // don't hit an EOF.
    var c = stream.char();
    while (allowed(c) && c != eof) {
      charStack.add(c);
      c = stream.char();
    }

    // Convert the set of characters consumed to an int.
    final charAsInt = int.parse(charStack.join(), radix: radix);

    // Certain characters get replaced with others
    var char = replacementCharacters[charAsInt];
    if (char != null) {
      _addToken(ParseErrorToken('illegal-codepoint-for-numeric-entity',
          messageParams: {'charAsInt': charAsInt}));
    } else if ((0xD800 <= charAsInt && charAsInt <= 0xDFFF) ||
        (charAsInt > 0x10FFFF)) {
      char = '\uFFFD';
      _addToken(ParseErrorToken('illegal-codepoint-for-numeric-entity',
          messageParams: {'charAsInt': charAsInt}));
    } else {
      // Should speed up this check somehow (e.g. move the set to a constant)
      if ((0x0001 <= charAsInt && charAsInt <= 0x0008) ||
          (0x000E <= charAsInt && charAsInt <= 0x001F) ||
          (0x007F <= charAsInt && charAsInt <= 0x009F) ||
          (0xFDD0 <= charAsInt && charAsInt <= 0xFDEF) ||
          const [
            0x000B,
            0xFFFE,
            0xFFFF,
            0x1FFFE,
            0x1FFFF,
            0x2FFFE,
            0x2FFFF,
            0x3FFFE,
            0x3FFFF,
            0x4FFFE,
            0x4FFFF,
            0x5FFFE,
            0x5FFFF,
            0x6FFFE,
            0x6FFFF,
            0x7FFFE,
            0x7FFFF,
            0x8FFFE,
            0x8FFFF,
            0x9FFFE,
            0x9FFFF,
            0xAFFFE,
            0xAFFFF,
            0xBFFFE,
            0xBFFFF,
            0xCFFFE,
            0xCFFFF,
            0xDFFFE,
            0xDFFFF,
            0xEFFFE,
            0xEFFFF,
            0xFFFFE,
            0xFFFFF,
            0x10FFFE,
            0x10FFFF
          ].contains(charAsInt)) {
        _addToken(ParseErrorToken('illegal-codepoint-for-numeric-entity',
            messageParams: {'charAsInt': charAsInt}));
      }
      char = String.fromCharCodes([charAsInt]);
    }

    // Discard the ; if present. Otherwise, put it back on the queue and
    // invoke parseError on parser.
    if (c != ';') {
      _addToken(ParseErrorToken('numeric-entity-without-semicolon'));
      stream.unget(c);
    }
    return char;
  }

  void consumeEntity({String? allowedChar, bool fromAttribute = false}) {
    // Initialise to the default output for when no entity is matched
    String? output = '&';

    final charStack = [stream.char()];
    if (isWhitespace(charStack[0]) ||
        charStack[0] == '<' ||
        charStack[0] == '&' ||
        charStack[0] == eof ||
        allowedChar == charStack[0]) {
      stream.unget(charStack[0]);
    } else if (charStack[0] == '#') {
      // Read the next character to see if it's hex or decimal
      var hex = false;
      charStack.add(stream.char());
      if (charStack.last == 'x' || charStack.last == 'X') {
        hex = true;
        charStack.add(stream.char());
      }

      // charStack.last should be the first digit
      if (hex && isHexDigit(charStack.last) ||
          (!hex && isDigit(charStack.last))) {
        // At least one digit found, so consume the whole number
        stream.unget(charStack.last);
        output = consumeNumberEntity(hex);
      } else {
        // No digits found
        _addToken(ParseErrorToken('expected-numeric-entity'));
        stream.unget(charStack.removeLast());
        output = '&${charStack.join()}';
      }
    } else {
      // At this point in the process might have named entity. Entities
      // are stored in the global variable "entities".
      //
      // Consume characters and compare to these to a substring of the
      // entity names in the list until the substring no longer matches.
      var filteredEntityList = entitiesByFirstChar[charStack[0]!] ?? const [];

      while (charStack.last != eof) {
        final name = charStack.join();
        filteredEntityList = filteredEntityList
            .where((e) => e.startsWith(name))
            .toList(growable: false);

        if (filteredEntityList.isEmpty) {
          break;
        }
        charStack.add(stream.char());
      }

      // At this point we have a string that starts with some characters
      // that may match an entity
      String? entityName;

      // Try to find the longest entity the string will match to take care
      // of &noti for instance.

      int entityLen;
      for (entityLen = charStack.length - 1; entityLen > 1; entityLen--) {
        final possibleEntityName = charStack.sublist(0, entityLen).join();
        if (entities.containsKey(possibleEntityName)) {
          entityName = possibleEntityName;
          break;
        }
      }

      if (entityName != null) {
        final lastChar = entityName[entityName.length - 1];
        if (lastChar != ';') {
          _addToken(ParseErrorToken('named-entity-without-semicolon'));
        }
        if (lastChar != ';' &&
            fromAttribute &&
            (isLetterOrDigit(charStack[entityLen]) ||
                charStack[entityLen] == '=')) {
          stream.unget(charStack.removeLast());
          output = '&${charStack.join()}';
        } else {
          output = entities[entityName];
          stream.unget(charStack.removeLast());
          output = '$output${slice(charStack, entityLen).join()}';
        }
      } else {
        _addToken(ParseErrorToken('expected-named-entity'));
        stream.unget(charStack.removeLast());
        output = '&${charStack.join()}';
      }
    }
    if (fromAttribute) {
      _attributeValue.write(output);
    } else {
      Token token;
      if (isWhitespace(output)) {
        token = SpaceCharactersToken(output);
      } else {
        token = CharactersToken(output);
      }
      _addToken(token);
    }
  }

  /// This method replaces the need for "entityInAttributeValueState".
  void processEntityInAttribute(String allowedChar) {
    consumeEntity(allowedChar: allowedChar, fromAttribute: true);
  }

  /// This method is a generic handler for emitting the tags. It also sets
  /// the state to "data" because that's what's needed after a token has been
  /// emitted.
  void emitCurrentToken() {
    final token = currentToken!;
    // Add token to the queue to be yielded
    if (token is TagToken) {
      if (lowercaseElementName) {
        token.name = token.name?.toAsciiLowerCase();
      }
      if (token is EndTagToken) {
        if (_attributes != null) {
          _addToken(ParseErrorToken('attributes-in-end-tag'));
        }
        if (token.selfClosing) {
          _addToken(ParseErrorToken('this-closing-flag-on-end-tag'));
        }
      } else if (token is StartTagToken) {
        // HTML5 specific normalizations to the token stream.
        // Convert the list into a map where first key wins.
        token.data = LinkedHashMap<Object, String>();
        if (_attributes != null) {
          for (var attr in _attributes!) {
            token.data.putIfAbsent(attr.name!, () => attr.value);
          }
          if (attributeSpans) token.attributeSpans = _attributes;
        }
      }
      _attributes = null;
      _attributeNames = null;
    }
    _addToken(token);
    state = dataState;
  }

  // Below are the various tokenizer states worked out.

  bool dataState() {
    final data = stream.char();
    if (data == '&') {
      state = entityDataState;
    } else if (data == '<') {
      state = tagOpenState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addToken(CharactersToken('\u0000'));
    } else if (data == eof) {
      // Tokenization ends.
      return false;
    } else if (isWhitespace(data)) {
      // Directly after emitting a token you switch back to the "data
      // state". At that point spaceCharacters are important so they are
      // emitted separately.
      _addToken(SpaceCharactersToken(
          '$data${stream.charsUntil(spaceCharacters, true)}'));
      // No need to update lastFourChars here, since the first space will
      // have already been appended to lastFourChars and will have broken
      // any <!-- or --> sequences
    } else {
      final chars = stream.charsUntil('&<\u0000');
      _addToken(CharactersToken('$data$chars'));
    }
    return true;
  }

  bool entityDataState() {
    consumeEntity();
    state = dataState;
    return true;
  }

  bool rcdataState() {
    final data = stream.char();
    if (data == '&') {
      state = characterReferenceInRcdata;
    } else if (data == '<') {
      state = rcdataLessThanSignState;
    } else if (data == eof) {
      // Tokenization ends.
      return false;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addToken(CharactersToken('\uFFFD'));
    } else if (isWhitespace(data)) {
      // Directly after emitting a token you switch back to the "data
      // state". At that point spaceCharacters are important so they are
      // emitted separately.
      _addToken(SpaceCharactersToken(
          '$data${stream.charsUntil(spaceCharacters, true)}'));
    } else {
      final chars = stream.charsUntil('&<');
      _addToken(CharactersToken('$data$chars'));
    }
    return true;
  }

  bool characterReferenceInRcdata() {
    consumeEntity();
    state = rcdataState;
    return true;
  }

  bool rawtextState() {
    final data = stream.char();
    if (data == '<') {
      state = rawtextLessThanSignState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addToken(CharactersToken('\uFFFD'));
    } else if (data == eof) {
      // Tokenization ends.
      return false;
    } else {
      final chars = stream.charsUntil('<\u0000');
      _addToken(CharactersToken('$data$chars'));
    }
    return true;
  }

  bool scriptDataState() {
    final data = stream.char();
    if (data == '<') {
      state = scriptDataLessThanSignState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addToken(CharactersToken('\uFFFD'));
    } else if (data == eof) {
      // Tokenization ends.
      return false;
    } else {
      final chars = stream.charsUntil('<\u0000');
      _addToken(CharactersToken('$data$chars'));
    }
    return true;
  }

  bool plaintextState() {
    final data = stream.char();
    if (data == eof) {
      // Tokenization ends.
      return false;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addToken(CharactersToken('\uFFFD'));
    } else {
      _addToken(CharactersToken('$data${stream.charsUntil("\u0000")}'));
    }
    return true;
  }

  bool tagOpenState() {
    final data = stream.char();
    if (data == '!') {
      state = markupDeclarationOpenState;
    } else if (data == '/') {
      state = closeTagOpenState;
    } else if (isLetter(data)) {
      currentToken = StartTagToken(data);
      state = tagNameState;
    } else if (data == '>') {
      // XXX In theory it could be something besides a tag name. But
      // do we really care?
      _addToken(ParseErrorToken('expected-tag-name-but-got-right-bracket'));
      _addToken(CharactersToken('<>'));
      state = dataState;
    } else if (data == '?') {
      // XXX In theory it could be something besides a tag name. But
      // do we really care?
      _addToken(ParseErrorToken('expected-tag-name-but-got-question-mark'));
      stream.unget(data);
      state = bogusCommentState;
    } else {
      // XXX
      _addToken(ParseErrorToken('expected-tag-name'));
      _addToken(CharactersToken('<'));
      stream.unget(data);
      state = dataState;
    }
    return true;
  }

  bool closeTagOpenState() {
    final data = stream.char();
    if (isLetter(data)) {
      currentToken = EndTagToken(data);
      state = tagNameState;
    } else if (data == '>') {
      _addToken(ParseErrorToken('expected-closing-tag-but-got-right-bracket'));
      state = dataState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('expected-closing-tag-but-got-eof'));
      _addToken(CharactersToken('</'));
      state = dataState;
    } else {
      // XXX data can be _'_...
      _addToken(ParseErrorToken('expected-closing-tag-but-got-char',
          messageParams: {'data': data}));
      stream.unget(data);
      state = bogusCommentState;
    }
    return true;
  }

  bool tagNameState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      state = beforeAttributeNameState;
    } else if (data == '>') {
      emitCurrentToken();
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-tag-name'));
      state = dataState;
    } else if (data == '/') {
      state = selfClosingStartTagState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentTagToken.name = '${currentTagToken.name}\uFFFD';
    } else {
      currentTagToken.name = '${currentTagToken.name}$data';
      // (Don't use charsUntil here, because tag names are
      // very short and it's faster to not do anything fancy)
    }
    return true;
  }

  bool rcdataLessThanSignState() {
    final data = stream.char();
    if (data == '/') {
      _buffer.clear();
      state = rcdataEndTagOpenState;
    } else {
      _addToken(CharactersToken('<'));
      stream.unget(data);
      state = rcdataState;
    }
    return true;
  }

  bool rcdataEndTagOpenState() {
    final data = stream.char();
    if (isLetter(data)) {
      _buffer.write(data);
      state = rcdataEndTagNameState;
    } else {
      _addToken(CharactersToken('</'));
      stream.unget(data);
      state = rcdataState;
    }
    return true;
  }

  bool _tokenIsAppropriate() {
    // TODO(jmesserly): this should use case insensitive compare instead.
    return currentToken is TagToken &&
        currentTagToken.name!.toLowerCase() == '$_buffer'.toLowerCase();
  }

  bool rcdataEndTagNameState() {
    final appropriate = _tokenIsAppropriate();
    final data = stream.char();
    if (isWhitespace(data) && appropriate) {
      currentToken = EndTagToken('$_buffer');
      state = beforeAttributeNameState;
    } else if (data == '/' && appropriate) {
      currentToken = EndTagToken('$_buffer');
      state = selfClosingStartTagState;
    } else if (data == '>' && appropriate) {
      currentToken = EndTagToken('$_buffer');
      emitCurrentToken();
      state = dataState;
    } else if (isLetter(data)) {
      _buffer.write(data);
    } else {
      _addToken(CharactersToken('</$_buffer'));
      stream.unget(data);
      state = rcdataState;
    }
    return true;
  }

  bool rawtextLessThanSignState() {
    final data = stream.char();
    if (data == '/') {
      _buffer.clear();
      state = rawtextEndTagOpenState;
    } else {
      _addToken(CharactersToken('<'));
      stream.unget(data);
      state = rawtextState;
    }
    return true;
  }

  bool rawtextEndTagOpenState() {
    final data = stream.char();
    if (isLetter(data)) {
      _buffer.write(data);
      state = rawtextEndTagNameState;
    } else {
      _addToken(CharactersToken('</'));
      stream.unget(data);
      state = rawtextState;
    }
    return true;
  }

  bool rawtextEndTagNameState() {
    final appropriate = _tokenIsAppropriate();
    final data = stream.char();
    if (isWhitespace(data) && appropriate) {
      currentToken = EndTagToken('$_buffer');
      state = beforeAttributeNameState;
    } else if (data == '/' && appropriate) {
      currentToken = EndTagToken('$_buffer');
      state = selfClosingStartTagState;
    } else if (data == '>' && appropriate) {
      currentToken = EndTagToken('$_buffer');
      emitCurrentToken();
      state = dataState;
    } else if (isLetter(data)) {
      _buffer.write(data);
    } else {
      _addToken(CharactersToken('</$_buffer'));
      stream.unget(data);
      state = rawtextState;
    }
    return true;
  }

  bool scriptDataLessThanSignState() {
    final data = stream.char();
    if (data == '/') {
      _buffer.clear();
      state = scriptDataEndTagOpenState;
    } else if (data == '!') {
      _addToken(CharactersToken('<!'));
      state = scriptDataEscapeStartState;
    } else {
      _addToken(CharactersToken('<'));
      stream.unget(data);
      state = scriptDataState;
    }
    return true;
  }

  bool scriptDataEndTagOpenState() {
    final data = stream.char();
    if (isLetter(data)) {
      _buffer.write(data);
      state = scriptDataEndTagNameState;
    } else {
      _addToken(CharactersToken('</'));
      stream.unget(data);
      state = scriptDataState;
    }
    return true;
  }

  bool scriptDataEndTagNameState() {
    final appropriate = _tokenIsAppropriate();
    final data = stream.char();
    if (isWhitespace(data) && appropriate) {
      currentToken = EndTagToken('$_buffer');
      state = beforeAttributeNameState;
    } else if (data == '/' && appropriate) {
      currentToken = EndTagToken('$_buffer');
      state = selfClosingStartTagState;
    } else if (data == '>' && appropriate) {
      currentToken = EndTagToken('$_buffer');
      emitCurrentToken();
      state = dataState;
    } else if (isLetter(data)) {
      _buffer.write(data);
    } else {
      _addToken(CharactersToken('</$_buffer'));
      stream.unget(data);
      state = scriptDataState;
    }
    return true;
  }

  bool scriptDataEscapeStartState() {
    final data = stream.char();
    if (data == '-') {
      _addToken(CharactersToken('-'));
      state = scriptDataEscapeStartDashState;
    } else {
      stream.unget(data);
      state = scriptDataState;
    }
    return true;
  }

  bool scriptDataEscapeStartDashState() {
    final data = stream.char();
    if (data == '-') {
      _addToken(CharactersToken('-'));
      state = scriptDataEscapedDashDashState;
    } else {
      stream.unget(data);
      state = scriptDataState;
    }
    return true;
  }

  bool scriptDataEscapedState() {
    final data = stream.char();
    if (data == '-') {
      _addToken(CharactersToken('-'));
      state = scriptDataEscapedDashState;
    } else if (data == '<') {
      state = scriptDataEscapedLessThanSignState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addToken(CharactersToken('\uFFFD'));
    } else if (data == eof) {
      state = dataState;
    } else {
      final chars = stream.charsUntil('<-\u0000');
      _addToken(CharactersToken('$data$chars'));
    }
    return true;
  }

  bool scriptDataEscapedDashState() {
    final data = stream.char();
    if (data == '-') {
      _addToken(CharactersToken('-'));
      state = scriptDataEscapedDashDashState;
    } else if (data == '<') {
      state = scriptDataEscapedLessThanSignState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addToken(CharactersToken('\uFFFD'));
      state = scriptDataEscapedState;
    } else if (data == eof) {
      state = dataState;
    } else {
      _addToken(CharactersToken(data));
      state = scriptDataEscapedState;
    }
    return true;
  }

  bool scriptDataEscapedDashDashState() {
    final data = stream.char();
    if (data == '-') {
      _addToken(CharactersToken('-'));
    } else if (data == '<') {
      state = scriptDataEscapedLessThanSignState;
    } else if (data == '>') {
      _addToken(CharactersToken('>'));
      state = scriptDataState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addToken(CharactersToken('\uFFFD'));
      state = scriptDataEscapedState;
    } else if (data == eof) {
      state = dataState;
    } else {
      _addToken(CharactersToken(data));
      state = scriptDataEscapedState;
    }
    return true;
  }

  bool scriptDataEscapedLessThanSignState() {
    final data = stream.char();
    if (data == '/') {
      _buffer.clear();
      state = scriptDataEscapedEndTagOpenState;
    } else if (isLetter(data)) {
      _addToken(CharactersToken('<$data'));
      _buffer.clear();
      _buffer.write(data);
      state = scriptDataDoubleEscapeStartState;
    } else {
      _addToken(CharactersToken('<'));
      stream.unget(data);
      state = scriptDataEscapedState;
    }
    return true;
  }

  bool scriptDataEscapedEndTagOpenState() {
    final data = stream.char();
    if (isLetter(data)) {
      _buffer.clear();
      _buffer.write(data);
      state = scriptDataEscapedEndTagNameState;
    } else {
      _addToken(CharactersToken('</'));
      stream.unget(data);
      state = scriptDataEscapedState;
    }
    return true;
  }

  bool scriptDataEscapedEndTagNameState() {
    final appropriate = _tokenIsAppropriate();
    final data = stream.char();
    if (isWhitespace(data) && appropriate) {
      currentToken = EndTagToken('$_buffer');
      state = beforeAttributeNameState;
    } else if (data == '/' && appropriate) {
      currentToken = EndTagToken('$_buffer');
      state = selfClosingStartTagState;
    } else if (data == '>' && appropriate) {
      currentToken = EndTagToken('$_buffer');
      emitCurrentToken();
      state = dataState;
    } else if (isLetter(data)) {
      _buffer.write(data);
    } else {
      _addToken(CharactersToken('</$_buffer'));
      stream.unget(data);
      state = scriptDataEscapedState;
    }
    return true;
  }

  bool scriptDataDoubleEscapeStartState() {
    final data = stream.char();
    if (isWhitespace(data) || data == '/' || data == '>') {
      _addToken(CharactersToken(data));
      if ('$_buffer'.toLowerCase() == 'script') {
        state = scriptDataDoubleEscapedState;
      } else {
        state = scriptDataEscapedState;
      }
    } else if (isLetter(data)) {
      _addToken(CharactersToken(data));
      _buffer.write(data);
    } else {
      stream.unget(data);
      state = scriptDataEscapedState;
    }
    return true;
  }

  bool scriptDataDoubleEscapedState() {
    final data = stream.char();
    if (data == '-') {
      _addToken(CharactersToken('-'));
      state = scriptDataDoubleEscapedDashState;
    } else if (data == '<') {
      _addToken(CharactersToken('<'));
      state = scriptDataDoubleEscapedLessThanSignState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addToken(CharactersToken('\uFFFD'));
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-script-in-script'));
      state = dataState;
    } else {
      _addToken(CharactersToken(data));
    }
    return true;
  }

  bool scriptDataDoubleEscapedDashState() {
    final data = stream.char();
    if (data == '-') {
      _addToken(CharactersToken('-'));
      state = scriptDataDoubleEscapedDashDashState;
    } else if (data == '<') {
      _addToken(CharactersToken('<'));
      state = scriptDataDoubleEscapedLessThanSignState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addToken(CharactersToken('\uFFFD'));
      state = scriptDataDoubleEscapedState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-script-in-script'));
      state = dataState;
    } else {
      _addToken(CharactersToken(data));
      state = scriptDataDoubleEscapedState;
    }
    return true;
  }

  // TODO(jmesserly): report bug in original code
  // (was "Dash" instead of "DashDash")
  bool scriptDataDoubleEscapedDashDashState() {
    final data = stream.char();
    if (data == '-') {
      _addToken(CharactersToken('-'));
    } else if (data == '<') {
      _addToken(CharactersToken('<'));
      state = scriptDataDoubleEscapedLessThanSignState;
    } else if (data == '>') {
      _addToken(CharactersToken('>'));
      state = scriptDataState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addToken(CharactersToken('\uFFFD'));
      state = scriptDataDoubleEscapedState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-script-in-script'));
      state = dataState;
    } else {
      _addToken(CharactersToken(data));
      state = scriptDataDoubleEscapedState;
    }
    return true;
  }

  bool scriptDataDoubleEscapedLessThanSignState() {
    final data = stream.char();
    if (data == '/') {
      _addToken(CharactersToken('/'));
      _buffer.clear();
      state = scriptDataDoubleEscapeEndState;
    } else {
      stream.unget(data);
      state = scriptDataDoubleEscapedState;
    }
    return true;
  }

  bool scriptDataDoubleEscapeEndState() {
    final data = stream.char();
    if (isWhitespace(data) || data == '/' || data == '>') {
      _addToken(CharactersToken(data));
      if ('$_buffer'.toLowerCase() == 'script') {
        state = scriptDataEscapedState;
      } else {
        state = scriptDataDoubleEscapedState;
      }
    } else if (isLetter(data)) {
      _addToken(CharactersToken(data));
      _buffer.write(data);
    } else {
      stream.unget(data);
      state = scriptDataDoubleEscapedState;
    }
    return true;
  }

  bool beforeAttributeNameState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      stream.charsUntil(spaceCharacters, true);
    } else if (data != null && isLetter(data)) {
      _addAttribute(data);
      state = attributeNameState;
    } else if (data == '>') {
      emitCurrentToken();
    } else if (data == '/') {
      state = selfClosingStartTagState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('expected-attribute-name-but-got-eof'));
      state = dataState;
    } else if ("'\"=<".contains(data!)) {
      _addToken(ParseErrorToken('invalid-character-in-attribute-name'));
      _addAttribute(data);
      state = attributeNameState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addAttribute('\uFFFD');
      state = attributeNameState;
    } else {
      _addAttribute(data);
      state = attributeNameState;
    }
    return true;
  }

  bool attributeNameState() {
    final data = stream.char();
    var leavingThisState = true;
    var emitToken = false;
    if (data == '=') {
      state = beforeAttributeValueState;
    } else if (isLetter(data)) {
      _attributeName.write(data);
      _attributeName.write(stream.charsUntil(asciiLetters, true));
      leavingThisState = false;
    } else if (data == '>') {
      // XXX If we emit here the attributes are converted to a dict
      // without being checked and when the code below runs we error
      // because data is a dict not a list
      emitToken = true;
    } else if (isWhitespace(data)) {
      state = afterAttributeNameState;
    } else if (data == '/') {
      state = selfClosingStartTagState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _attributeName.write('\uFFFD');
      leavingThisState = false;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-attribute-name'));
      state = dataState;
    } else if ("'\"<".contains(data!)) {
      _addToken(ParseErrorToken('invalid-character-in-attribute-name'));
      _attributeName.write(data);
      leavingThisState = false;
    } else {
      _attributeName.write(data);
      leavingThisState = false;
    }

    if (leavingThisState) {
      _markAttributeNameEnd(-1);

      // Attributes are not dropped at this stage. That happens when the
      // start tag token is emitted so values can still be safely appended
      // to attributes, but we do want to report the parse error in time.
      var attrName = _attributeName.toString();
      if (lowercaseAttrName) {
        attrName = attrName.toAsciiLowerCase();
      }
      _attributes!.last.name = attrName;
      _attributeNames ??= {};
      if (_attributeNames!.contains(attrName)) {
        _addToken(ParseErrorToken('duplicate-attribute'));
      }
      _attributeNames!.add(attrName);

      // XXX Fix for above XXX
      if (emitToken) {
        emitCurrentToken();
      }
    }
    return true;
  }

  bool afterAttributeNameState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      stream.charsUntil(spaceCharacters, true);
    } else if (data == '=') {
      state = beforeAttributeValueState;
    } else if (data == '>') {
      emitCurrentToken();
    } else if (data != null && isLetter(data)) {
      _addAttribute(data);
      state = attributeNameState;
    } else if (data == '/') {
      state = selfClosingStartTagState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _addAttribute('\uFFFD');
      state = attributeNameState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('expected-end-of-tag-but-got-eof'));
      state = dataState;
    } else if ("'\"<".contains(data!)) {
      _addToken(ParseErrorToken('invalid-character-after-attribute-name'));
      _addAttribute(data);
      state = attributeNameState;
    } else {
      _addAttribute(data);
      state = attributeNameState;
    }
    return true;
  }

  bool beforeAttributeValueState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      stream.charsUntil(spaceCharacters, true);
    } else if (data == '"') {
      _markAttributeValueStart(0);
      state = attributeValueDoubleQuotedState;
    } else if (data == '&') {
      state = attributeValueUnQuotedState;
      stream.unget(data);
      _markAttributeValueStart(0);
    } else if (data == "'") {
      _markAttributeValueStart(0);
      state = attributeValueSingleQuotedState;
    } else if (data == '>') {
      _addToken(
          ParseErrorToken('expected-attribute-value-but-got-right-bracket'));
      emitCurrentToken();
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _markAttributeValueStart(-1);
      _attributeValue.write('\uFFFD');
      state = attributeValueUnQuotedState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('expected-attribute-value-but-got-eof'));
      state = dataState;
    } else if ('=<`'.contains(data!)) {
      _addToken(ParseErrorToken('equals-in-unquoted-attribute-value'));
      _markAttributeValueStart(-1);
      _attributeValue.write(data);
      state = attributeValueUnQuotedState;
    } else {
      _markAttributeValueStart(-1);
      _attributeValue.write(data);
      state = attributeValueUnQuotedState;
    }
    return true;
  }

  bool attributeValueDoubleQuotedState() {
    final data = stream.char();
    if (data == '"') {
      _markAttributeValueEnd(-1);
      _markAttributeEnd(0);
      state = afterAttributeValueState;
    } else if (data == '&') {
      processEntityInAttribute('"');
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _attributeValue.write('\uFFFD');
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-attribute-value-double-quote'));
      _markAttributeValueEnd(-1);
      state = dataState;
    } else {
      _attributeValue.write(data);
      _attributeValue.write(stream.charsUntil('"&'));
    }
    return true;
  }

  bool attributeValueSingleQuotedState() {
    final data = stream.char();
    if (data == "'") {
      _markAttributeValueEnd(-1);
      _markAttributeEnd(0);
      state = afterAttributeValueState;
    } else if (data == '&') {
      processEntityInAttribute("'");
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _attributeValue.write('\uFFFD');
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-attribute-value-single-quote'));
      _markAttributeValueEnd(-1);
      state = dataState;
    } else {
      _attributeValue.write(data);
      _attributeValue.write(stream.charsUntil("'&"));
    }
    return true;
  }

  bool attributeValueUnQuotedState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      _markAttributeValueEnd(-1);
      state = beforeAttributeNameState;
    } else if (data == '&') {
      processEntityInAttribute('>');
    } else if (data == '>') {
      _markAttributeValueEnd(-1);
      emitCurrentToken();
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-attribute-value-no-quotes'));
      _markAttributeValueEnd(-1);
      state = dataState;
    } else if ('"\'=<`'.contains(data!)) {
      _addToken(
          ParseErrorToken('unexpected-character-in-unquoted-attribute-value'));
      _attributeValue.write(data);
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      _attributeValue.write('\uFFFD');
    } else {
      _attributeValue.write(data);
      _attributeValue.write(stream.charsUntil("&>\"'=<`$spaceCharacters"));
    }
    return true;
  }

  bool afterAttributeValueState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      state = beforeAttributeNameState;
    } else if (data == '>') {
      emitCurrentToken();
    } else if (data == '/') {
      state = selfClosingStartTagState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('unexpected-EOF-after-attribute-value'));
      stream.unget(data);
      state = dataState;
    } else {
      _addToken(ParseErrorToken('unexpected-character-after-attribute-value'));
      stream.unget(data);
      state = beforeAttributeNameState;
    }
    return true;
  }

  bool selfClosingStartTagState() {
    final data = stream.char();
    if (data == '>') {
      currentTagToken.selfClosing = true;
      emitCurrentToken();
    } else if (data == eof) {
      _addToken(ParseErrorToken('unexpected-EOF-after-solidus-in-tag'));
      stream.unget(data);
      state = dataState;
    } else {
      _addToken(ParseErrorToken('unexpected-character-after-soldius-in-tag'));
      stream.unget(data);
      state = beforeAttributeNameState;
    }
    return true;
  }

  bool bogusCommentState() {
    // Make a new comment token and give it as value all the characters
    // until the first > or EOF (charsUntil checks for EOF automatically)
    // and emit it.
    var data = stream.charsUntil('>');
    data = data.replaceAll('\u0000', '\uFFFD');
    _addToken(CommentToken(data));

    // Eat the character directly after the bogus comment which is either a
    // ">" or an EOF.
    stream.char();
    state = dataState;
    return true;
  }

  bool markupDeclarationOpenState() {
    final charStack = [stream.char()];
    if (charStack.last == '-') {
      charStack.add(stream.char());
      if (charStack.last == '-') {
        currentToken = CommentToken();
        state = commentStartState;
        return true;
      }
    } else if (charStack.last == 'd' || charStack.last == 'D') {
      var matched = true;
      for (var expected in const ['oO', 'cC', 'tT', 'yY', 'pP', 'eE']) {
        final char = stream.char();
        charStack.add(char);
        if (char == eof || !expected.contains(char!)) {
          matched = false;
          break;
        }
      }
      if (matched) {
        currentToken = DoctypeToken(correct: true);
        state = doctypeState;
        return true;
      }
    } else if (charStack.last == '[' &&
        parser != null &&
        parser!.tree.openElements.isNotEmpty &&
        parser!.tree.openElements.last.namespaceUri !=
            parser!.tree.defaultNamespace) {
      var matched = true;
      for (var expected in const ['C', 'D', 'A', 'T', 'A', '[']) {
        charStack.add(stream.char());
        if (charStack.last != expected) {
          matched = false;
          break;
        }
      }
      if (matched) {
        state = cdataSectionState;
        return true;
      }
    }

    _addToken(ParseErrorToken('expected-dashes-or-doctype'));

    while (charStack.isNotEmpty) {
      stream.unget(charStack.removeLast());
    }
    state = bogusCommentState;
    return true;
  }

  bool commentStartState() {
    final data = stream.char();
    if (data == '-') {
      state = commentStartDashState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentStringToken.add('\uFFFD');
    } else if (data == '>') {
      _addToken(ParseErrorToken('incorrect-comment'));
      _addToken(currentToken!);
      state = dataState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-comment'));
      _addToken(currentToken!);
      state = dataState;
    } else {
      currentStringToken.add(data!);
      state = commentState;
    }
    return true;
  }

  bool commentStartDashState() {
    final data = stream.char();
    if (data == '-') {
      state = commentEndState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentStringToken.add('-\uFFFD');
    } else if (data == '>') {
      _addToken(ParseErrorToken('incorrect-comment'));
      _addToken(currentToken!);
      state = dataState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-comment'));
      _addToken(currentToken!);
      state = dataState;
    } else {
      currentStringToken.add('-').add(data!);
      state = commentState;
    }
    return true;
  }

  bool commentState() {
    final data = stream.char();
    if (data == '-') {
      state = commentEndDashState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentStringToken.add('\uFFFD');
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-comment'));
      _addToken(currentToken!);
      state = dataState;
    } else {
      currentStringToken.add(data!).add(stream.charsUntil('-\u0000'));
    }
    return true;
  }

  bool commentEndDashState() {
    final data = stream.char();
    if (data == '-') {
      state = commentEndState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentStringToken.add('-\uFFFD');
      state = commentState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-comment-end-dash'));
      _addToken(currentToken!);
      state = dataState;
    } else {
      currentStringToken.add('-').add(data!);
      state = commentState;
    }
    return true;
  }

  bool commentEndState() {
    final data = stream.char();
    if (data == '>') {
      _addToken(currentToken!);
      state = dataState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentStringToken.add('--\uFFFD');
      state = commentState;
    } else if (data == '!') {
      _addToken(
          ParseErrorToken('unexpected-bang-after-double-dash-in-comment'));
      state = commentEndBangState;
    } else if (data == '-') {
      _addToken(
          ParseErrorToken('unexpected-dash-after-double-dash-in-comment'));
      currentStringToken.add(data!);
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-comment-double-dash'));
      _addToken(currentToken!);
      state = dataState;
    } else {
      // XXX
      _addToken(ParseErrorToken('unexpected-char-in-comment'));
      currentStringToken.add('--').add(data!);
      state = commentState;
    }
    return true;
  }

  bool commentEndBangState() {
    final data = stream.char();
    if (data == '>') {
      _addToken(currentToken!);
      state = dataState;
    } else if (data == '-') {
      currentStringToken.add('--!');
      state = commentEndDashState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentStringToken.add('--!\uFFFD');
      state = commentState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-comment-end-bang-state'));
      _addToken(currentToken!);
      state = dataState;
    } else {
      currentStringToken.add('--!').add(data!);
      state = commentState;
    }
    return true;
  }

  bool doctypeState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      state = beforeDoctypeNameState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('expected-doctype-name-but-got-eof'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      _addToken(ParseErrorToken('need-space-after-doctype'));
      stream.unget(data);
      state = beforeDoctypeNameState;
    }
    return true;
  }

  bool beforeDoctypeNameState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      return true;
    } else if (data == '>') {
      _addToken(ParseErrorToken('expected-doctype-name-but-got-right-bracket'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentDoctypeToken.name = '\uFFFD';
      state = doctypeNameState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('expected-doctype-name-but-got-eof'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      currentDoctypeToken.name = data;
      state = doctypeNameState;
    }
    return true;
  }

  bool doctypeNameState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      currentDoctypeToken.name = currentDoctypeToken.name?.toAsciiLowerCase();
      state = afterDoctypeNameState;
    } else if (data == '>') {
      currentDoctypeToken.name = currentDoctypeToken.name?.toAsciiLowerCase();
      _addToken(currentToken!);
      state = dataState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentDoctypeToken.name = '${currentDoctypeToken.name}\uFFFD';
      state = doctypeNameState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype-name'));
      currentDoctypeToken.correct = false;
      currentDoctypeToken.name = currentDoctypeToken.name?.toAsciiLowerCase();
      _addToken(currentToken!);
      state = dataState;
    } else {
      currentDoctypeToken.name = '${currentDoctypeToken.name}$data';
    }
    return true;
  }

  bool afterDoctypeNameState() {
    var data = stream.char();
    if (isWhitespace(data)) {
      return true;
    } else if (data == '>') {
      _addToken(currentToken!);
      state = dataState;
    } else if (data == eof) {
      currentDoctypeToken.correct = false;
      stream.unget(data);
      _addToken(ParseErrorToken('eof-in-doctype'));
      _addToken(currentToken!);
      state = dataState;
    } else {
      if (data == 'p' || data == 'P') {
        // TODO(jmesserly): would be nice to have a helper for this.
        var matched = true;
        for (var expected in const ['uU', 'bB', 'lL', 'iI', 'cC']) {
          data = stream.char();
          if (data == eof || !expected.contains(data!)) {
            matched = false;
            break;
          }
        }
        if (matched) {
          state = afterDoctypePublicKeywordState;
          return true;
        }
      } else if (data == 's' || data == 'S') {
        var matched = true;
        for (var expected in const ['yY', 'sS', 'tT', 'eE', 'mM']) {
          data = stream.char();
          if (data == eof || !expected.contains(data!)) {
            matched = false;
            break;
          }
        }
        if (matched) {
          state = afterDoctypeSystemKeywordState;
          return true;
        }
      }

      // All the characters read before the current 'data' will be
      // [a-zA-Z], so they're garbage in the bogus doctype and can be
      // discarded; only the latest character might be '>' or EOF
      // and needs to be ungetted
      stream.unget(data);
      _addToken(ParseErrorToken('expected-space-or-right-bracket-in-doctype',
          messageParams: {'data': data}));
      currentDoctypeToken.correct = false;
      state = bogusDoctypeState;
    }
    return true;
  }

  bool afterDoctypePublicKeywordState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      state = beforeDoctypePublicIdentifierState;
    } else if (data == "'" || data == '"') {
      _addToken(ParseErrorToken('unexpected-char-in-doctype'));
      stream.unget(data);
      state = beforeDoctypePublicIdentifierState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      stream.unget(data);
      state = beforeDoctypePublicIdentifierState;
    }
    return true;
  }

  bool beforeDoctypePublicIdentifierState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      return true;
    } else if (data == '"') {
      currentDoctypeToken.publicId = '';
      state = doctypePublicIdentifierDoubleQuotedState;
    } else if (data == "'") {
      currentDoctypeToken.publicId = '';
      state = doctypePublicIdentifierSingleQuotedState;
    } else if (data == '>') {
      _addToken(ParseErrorToken('unexpected-end-of-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      _addToken(ParseErrorToken('unexpected-char-in-doctype'));
      currentDoctypeToken.correct = false;
      state = bogusDoctypeState;
    }
    return true;
  }

  bool doctypePublicIdentifierDoubleQuotedState() {
    final data = stream.char();
    if (data == '"') {
      state = afterDoctypePublicIdentifierState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentDoctypeToken.publicId = '${currentDoctypeToken.publicId}\uFFFD';
    } else if (data == '>') {
      _addToken(ParseErrorToken('unexpected-end-of-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      currentDoctypeToken.publicId = '${currentDoctypeToken.publicId}$data';
    }
    return true;
  }

  bool doctypePublicIdentifierSingleQuotedState() {
    final data = stream.char();
    if (data == "'") {
      state = afterDoctypePublicIdentifierState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentDoctypeToken.publicId = '${currentDoctypeToken.publicId}\uFFFD';
    } else if (data == '>') {
      _addToken(ParseErrorToken('unexpected-end-of-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      currentDoctypeToken.publicId = '${currentDoctypeToken.publicId}$data';
    }
    return true;
  }

  bool afterDoctypePublicIdentifierState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      state = betweenDoctypePublicAndSystemIdentifiersState;
    } else if (data == '>') {
      _addToken(currentToken!);
      state = dataState;
    } else if (data == '"') {
      _addToken(ParseErrorToken('unexpected-char-in-doctype'));
      currentDoctypeToken.systemId = '';
      state = doctypeSystemIdentifierDoubleQuotedState;
    } else if (data == "'") {
      _addToken(ParseErrorToken('unexpected-char-in-doctype'));
      currentDoctypeToken.systemId = '';
      state = doctypeSystemIdentifierSingleQuotedState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      _addToken(ParseErrorToken('unexpected-char-in-doctype'));
      currentDoctypeToken.correct = false;
      state = bogusDoctypeState;
    }
    return true;
  }

  bool betweenDoctypePublicAndSystemIdentifiersState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      return true;
    } else if (data == '>') {
      _addToken(currentToken!);
      state = dataState;
    } else if (data == '"') {
      currentDoctypeToken.systemId = '';
      state = doctypeSystemIdentifierDoubleQuotedState;
    } else if (data == "'") {
      currentDoctypeToken.systemId = '';
      state = doctypeSystemIdentifierSingleQuotedState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      _addToken(ParseErrorToken('unexpected-char-in-doctype'));
      currentDoctypeToken.correct = false;
      state = bogusDoctypeState;
    }
    return true;
  }

  bool afterDoctypeSystemKeywordState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      state = beforeDoctypeSystemIdentifierState;
    } else if (data == "'" || data == '"') {
      _addToken(ParseErrorToken('unexpected-char-in-doctype'));
      stream.unget(data);
      state = beforeDoctypeSystemIdentifierState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      stream.unget(data);
      state = beforeDoctypeSystemIdentifierState;
    }
    return true;
  }

  bool beforeDoctypeSystemIdentifierState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      return true;
    } else if (data == '"') {
      currentDoctypeToken.systemId = '';
      state = doctypeSystemIdentifierDoubleQuotedState;
    } else if (data == "'") {
      currentDoctypeToken.systemId = '';
      state = doctypeSystemIdentifierSingleQuotedState;
    } else if (data == '>') {
      _addToken(ParseErrorToken('unexpected-char-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      _addToken(ParseErrorToken('unexpected-char-in-doctype'));
      currentDoctypeToken.correct = false;
      state = bogusDoctypeState;
    }
    return true;
  }

  bool doctypeSystemIdentifierDoubleQuotedState() {
    final data = stream.char();
    if (data == '"') {
      state = afterDoctypeSystemIdentifierState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentDoctypeToken.systemId = '${currentDoctypeToken.systemId}\uFFFD';
    } else if (data == '>') {
      _addToken(ParseErrorToken('unexpected-end-of-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      currentDoctypeToken.systemId = '${currentDoctypeToken.systemId}$data';
    }
    return true;
  }

  bool doctypeSystemIdentifierSingleQuotedState() {
    final data = stream.char();
    if (data == "'") {
      state = afterDoctypeSystemIdentifierState;
    } else if (data == '\u0000') {
      _addToken(ParseErrorToken('invalid-codepoint'));
      currentDoctypeToken.systemId = '${currentDoctypeToken.systemId}\uFFFD';
    } else if (data == '>') {
      _addToken(ParseErrorToken('unexpected-end-of-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      currentDoctypeToken.systemId = '${currentDoctypeToken.systemId}$data';
    }
    return true;
  }

  bool afterDoctypeSystemIdentifierState() {
    final data = stream.char();
    if (isWhitespace(data)) {
      return true;
    } else if (data == '>') {
      _addToken(currentToken!);
      state = dataState;
    } else if (data == eof) {
      _addToken(ParseErrorToken('eof-in-doctype'));
      currentDoctypeToken.correct = false;
      _addToken(currentToken!);
      state = dataState;
    } else {
      _addToken(ParseErrorToken('unexpected-char-in-doctype'));
      state = bogusDoctypeState;
    }
    return true;
  }

  bool bogusDoctypeState() {
    final data = stream.char();
    if (data == '>') {
      _addToken(currentToken!);
      state = dataState;
    } else if (data == eof) {
      // XXX EMIT
      stream.unget(data);
      _addToken(currentToken!);
      state = dataState;
    }
    return true;
  }

  bool cdataSectionState() {
    final data = <String>[];
    var matchedEnd = 0;
    while (true) {
      var ch = stream.char();
      if (ch == null) {
        break;
      }
      // Deal with null here rather than in the parser
      if (ch == '\u0000') {
        _addToken(ParseErrorToken('invalid-codepoint'));
        ch = '\uFFFD';
      }
      data.add(ch);
      // TODO(jmesserly): it'd be nice if we had an easier way to match the end,
      // perhaps with a "peek" API.
      if (ch == ']' && matchedEnd < 2) {
        matchedEnd++;
      } else if (ch == '>' && matchedEnd == 2) {
        // Remove "]]>" from the end.
        data.removeLast();
        data.removeLast();
        data.removeLast();
        break;
      } else {
        matchedEnd = 0;
      }
    }

    if (data.isNotEmpty) {
      _addToken(CharactersToken(data.join()));
    }
    state = dataState;
    return true;
  }
}
