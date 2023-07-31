// Copyright (c) 2014, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// ignore_for_file: constant_identifier_names

import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';
import 'package:string_scanner/string_scanner.dart';

import 'error_listener.dart';
import 'style.dart';
import 'token.dart';
import 'utils.dart';
import 'yaml_exception.dart';

/// A scanner that reads a string of Unicode characters and emits [Token]s.
///
/// This is based on the libyaml scanner, available at
/// https://github.com/yaml/libyaml/blob/master/src/scanner.c. The license for
/// that is available in ../../libyaml-license.txt.
class Scanner {
  static const TAB = 0x9;
  static const LF = 0xA;
  static const CR = 0xD;
  static const SP = 0x20;
  static const DOLLAR = 0x24;
  static const LEFT_PAREN = 0x28;
  static const RIGHT_PAREN = 0x29;
  static const PLUS = 0x2B;
  static const COMMA = 0x2C;
  static const HYPHEN = 0x2D;
  static const PERIOD = 0x2E;
  static const QUESTION = 0x3F;
  static const COLON = 0x3A;
  static const SEMICOLON = 0x3B;
  static const EQUALS = 0x3D;
  static const LEFT_SQUARE = 0x5B;
  static const RIGHT_SQUARE = 0x5D;
  static const LEFT_CURLY = 0x7B;
  static const RIGHT_CURLY = 0x7D;
  static const HASH = 0x23;
  static const AMPERSAND = 0x26;
  static const ASTERISK = 0x2A;
  static const EXCLAMATION = 0x21;
  static const VERTICAL_BAR = 0x7C;
  static const LEFT_ANGLE = 0x3C;
  static const RIGHT_ANGLE = 0x3E;
  static const SINGLE_QUOTE = 0x27;
  static const DOUBLE_QUOTE = 0x22;
  static const PERCENT = 0x25;
  static const AT = 0x40;
  static const GRAVE_ACCENT = 0x60;
  static const TILDE = 0x7E;

  static const NULL = 0x0;
  static const BELL = 0x7;
  static const BACKSPACE = 0x8;
  static const VERTICAL_TAB = 0xB;
  static const FORM_FEED = 0xC;
  static const ESCAPE = 0x1B;
  static const SLASH = 0x2F;
  static const BACKSLASH = 0x5C;
  static const UNDERSCORE = 0x5F;
  static const NEL = 0x85;
  static const NBSP = 0xA0;
  static const LINE_SEPARATOR = 0x2028;
  static const PARAGRAPH_SEPARATOR = 0x2029;
  static const BOM = 0xFEFF;

  static const NUMBER_0 = 0x30;
  static const NUMBER_9 = 0x39;

  static const LETTER_A = 0x61;
  static const LETTER_B = 0x62;
  static const LETTER_E = 0x65;
  static const LETTER_F = 0x66;
  static const LETTER_N = 0x6E;
  static const LETTER_R = 0x72;
  static const LETTER_T = 0x74;
  static const LETTER_U = 0x75;
  static const LETTER_V = 0x76;
  static const LETTER_X = 0x78;
  static const LETTER_Z = 0x7A;

  static const LETTER_CAP_A = 0x41;
  static const LETTER_CAP_F = 0x46;
  static const LETTER_CAP_L = 0x4C;
  static const LETTER_CAP_N = 0x4E;
  static const LETTER_CAP_P = 0x50;
  static const LETTER_CAP_U = 0x55;
  static const LETTER_CAP_X = 0x58;
  static const LETTER_CAP_Z = 0x5A;

  /// Whether this scanner should attempt to recover when parsing invalid YAML.
  final bool _recover;

  /// A listener to report YAML errors to.
  final ErrorListener? _errorListener;

  /// The underlying [SpanScanner] used to read characters from the source text.
  ///
  /// This is also used to track line and column information and to generate
  /// [SourceSpan]s.
  final SpanScanner _scanner;

  /// Whether this scanner has produced a [TokenType.streamStart] token
  /// indicating the beginning of the YAML stream.
  var _streamStartProduced = false;

  /// Whether this scanner has produced a [TokenType.streamEnd] token
  /// indicating the end of the YAML stream.
  var _streamEndProduced = false;

  /// The queue of tokens yet to be emitted.
  ///
  /// These are queued up in advance so that [TokenType.key] tokens can be
  /// inserted once the scanner determines that a series of tokens represents a
  /// mapping key.
  final _tokens = QueueList<Token>();

  /// The number of tokens that have been emitted.
  ///
  /// This doesn't count tokens in [tokens].
  var _tokensParsed = 0;

  /// Whether the next token in [_tokens] is ready to be returned.
  ///
  /// It might not be ready if there may still be a [TokenType.key] inserted
  /// before it.
  var _tokenAvailable = false;

  /// The stack of indent levels for the current nested block contexts.
  ///
  /// The YAML spec specifies that the initial indentation level is -1 spaces.
  final _indents = <int>[-1];

  /// Whether a simple key is allowed in this context.
  ///
  /// A simple key refers to any mapping key that doesn't have an explicit "?".
  var _simpleKeyAllowed = true;

  /// The stack of potential simple keys for each level of flow nesting.
  ///
  /// Entries in this list may be `null`, indicating that there is no valid
  /// simple key for the associated level of nesting.
  ///
  /// When a ":" is parsed and there's a simple key available, a [TokenType.key]
  /// token is inserted in [_tokens] before that key's token. This allows the
  /// parser to tell that the key is intended to be a mapping key.
  final _simpleKeys = <_SimpleKey?>[null];

  /// The current indentation level.
  int get _indent => _indents.last;

  /// Whether the scanner's currently positioned in a block-level structure (as
  /// opposed to flow-level).
  bool get _inBlockContext => _simpleKeys.length == 1;

  /// Whether the current character is a line break or the end of the source.
  bool get _isBreakOrEnd => _scanner.isDone || _isBreak;

  /// Whether the current character is a line break.
  bool get _isBreak => _isBreakAt(0);

  /// Whether the current character is whitespace or the end of the source.
  bool get _isBlankOrEnd => _isBlankOrEndAt(0);

  /// Whether the current character is whitespace.
  bool get _isBlank => _isBlankAt(0);

  /// Whether the current character is a valid tag name character.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#ns-tag-name.
  bool get _isTagChar {
    var char = _scanner.peekChar();
    if (char == null) return false;
    switch (char) {
      case HYPHEN:
      case SEMICOLON:
      case SLASH:
      case COLON:
      case AT:
      case AMPERSAND:
      case EQUALS:
      case PLUS:
      case DOLLAR:
      case PERIOD:
      case TILDE:
      case QUESTION:
      case ASTERISK:
      case SINGLE_QUOTE:
      case LEFT_PAREN:
      case RIGHT_PAREN:
      case PERCENT:
        return true;
      default:
        return (char >= NUMBER_0 && char <= NUMBER_9) ||
            (char >= LETTER_A && char <= LETTER_Z) ||
            (char >= LETTER_CAP_A && char <= LETTER_CAP_Z);
    }
  }

  /// Whether the current character is a valid anchor name character.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#ns-anchor-name.
  bool get _isAnchorChar {
    if (!_isNonSpace) return false;

    switch (_scanner.peekChar()) {
      case COMMA:
      case LEFT_SQUARE:
      case RIGHT_SQUARE:
      case LEFT_CURLY:
      case RIGHT_CURLY:
        return false;
      default:
        return true;
    }
  }

  /// Whether the character at the current position is a decimal digit.
  bool get _isDigit {
    var char = _scanner.peekChar();
    return char != null && (char >= NUMBER_0 && char <= NUMBER_9);
  }

  /// Whether the character at the current position is a hexidecimal
  /// digit.
  bool get _isHex {
    var char = _scanner.peekChar();
    if (char == null) return false;
    return (char >= NUMBER_0 && char <= NUMBER_9) ||
        (char >= LETTER_A && char <= LETTER_F) ||
        (char >= LETTER_CAP_A && char <= LETTER_CAP_F);
  }

  /// Whether the character at the current position is a plain character.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#ns-plain-char(c).
  bool get _isPlainChar => _isPlainCharAt(0);

  /// Whether the character at the current position is a printable character
  /// other than a line break or byte-order mark.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#nb-char.
  bool get _isNonBreak {
    var char = _scanner.peekChar();
    if (char == null) return false;
    switch (char) {
      case LF:
      case CR:
      case BOM:
        return false;
      case TAB:
      case NEL:
        return true;
      default:
        return (char >= 0x00020 && char <= 0x00007E) ||
            (char >= 0x000A0 && char <= 0x00D7FF) ||
            (char >= 0x0E000 && char <= 0x00FFFD) ||
            (char >= 0x10000 && char <= 0x10FFFF);
    }
  }

  /// Whether the character at the current position is a printable character
  /// other than whitespace.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#nb-char.
  bool get _isNonSpace {
    var char = _scanner.peekChar();
    if (char == null) return false;
    switch (char) {
      case LF:
      case CR:
      case BOM:
      case SP:
        return false;
      case NEL:
        return true;
      default:
        return (char >= 0x00020 && char <= 0x00007E) ||
            (char >= 0x000A0 && char <= 0x00D7FF) ||
            (char >= 0x0E000 && char <= 0x00FFFD) ||
            (char >= 0x10000 && char <= 0x10FFFF);
    }
  }

  /// Returns Whether or not the current character begins a documentation
  /// indicator.
  ///
  /// If so, this sets the scanner's last match to that indicator.
  bool get _isDocumentIndicator =>
      _scanner.column == 0 &&
      _isBlankOrEndAt(3) &&
      (_scanner.matches('---') || _scanner.matches('...'));

  /// Creates a scanner that scans [source].
  Scanner(String source,
      {Uri? sourceUrl, bool recover = false, ErrorListener? errorListener})
      : _recover = recover,
        _errorListener = errorListener,
        _scanner = SpanScanner.eager(source, sourceUrl: sourceUrl);

  /// Consumes and returns the next token.
  Token scan() {
    if (_streamEndProduced) throw StateError('Out of tokens.');
    if (!_tokenAvailable) _fetchMoreTokens();

    var token = _tokens.removeFirst();
    _tokenAvailable = false;
    _tokensParsed++;
    _streamEndProduced = token.type == TokenType.streamEnd;
    return token;
  }

  /// Consumes the next token and returns the one after that.
  Token? advance() {
    scan();
    return peek();
  }

  /// Returns the next token without consuming it.
  Token? peek() {
    if (_streamEndProduced) return null;
    if (!_tokenAvailable) _fetchMoreTokens();
    return _tokens.first;
  }

  /// Ensures that [_tokens] contains at least one token which can be returned.
  void _fetchMoreTokens() {
    while (true) {
      if (_tokens.isNotEmpty) {
        _staleSimpleKeys();

        // If there are no more tokens to fetch, break.
        if (_tokens.last.type == TokenType.streamEnd) break;

        // If the current token could be a simple key, we need to scan more
        // tokens until we determine whether it is or not. Otherwise we might
        // not emit the `KEY` token before we emit the value of the key.
        if (!_simpleKeys
            .any((key) => key != null && key.tokenNumber == _tokensParsed)) {
          break;
        }
      }

      _fetchNextToken();
    }
    _tokenAvailable = true;
  }

  /// The dispatcher for token fetchers.
  void _fetchNextToken() {
    if (!_streamStartProduced) {
      _fetchStreamStart();
      return;
    }

    _scanToNextToken();
    _staleSimpleKeys();
    _unrollIndent(_scanner.column);

    if (_scanner.isDone) {
      _fetchStreamEnd();
      return;
    }

    if (_scanner.column == 0) {
      if (_scanner.peekChar() == PERCENT) {
        _fetchDirective();
        return;
      }

      if (_isBlankOrEndAt(3)) {
        if (_scanner.matches('---')) {
          _fetchDocumentIndicator(TokenType.documentStart);
          return;
        }

        if (_scanner.matches('...')) {
          _fetchDocumentIndicator(TokenType.documentEnd);
          return;
        }
      }
    }

    switch (_scanner.peekChar()) {
      case LEFT_SQUARE:
        _fetchFlowCollectionStart(TokenType.flowSequenceStart);
        return;
      case LEFT_CURLY:
        _fetchFlowCollectionStart(TokenType.flowMappingStart);
        return;
      case RIGHT_SQUARE:
        _fetchFlowCollectionEnd(TokenType.flowSequenceEnd);
        return;
      case RIGHT_CURLY:
        _fetchFlowCollectionEnd(TokenType.flowMappingEnd);
        return;
      case COMMA:
        _fetchFlowEntry();
        return;
      case ASTERISK:
        _fetchAnchor(anchor: false);
        return;
      case AMPERSAND:
        _fetchAnchor();
        return;
      case EXCLAMATION:
        _fetchTag();
        return;
      case SINGLE_QUOTE:
        _fetchFlowScalar(singleQuote: true);
        return;
      case DOUBLE_QUOTE:
        _fetchFlowScalar();
        return;
      case VERTICAL_BAR:
        if (!_inBlockContext) _invalidScalarCharacter();
        _fetchBlockScalar(literal: true);
        return;
      case RIGHT_ANGLE:
        if (!_inBlockContext) _invalidScalarCharacter();
        _fetchBlockScalar();
        return;
      case PERCENT:
      case AT:
      case GRAVE_ACCENT:
        _invalidScalarCharacter();
        return;

      // These characters may sometimes begin plain scalars.
      case HYPHEN:
        if (_isPlainCharAt(1)) {
          _fetchPlainScalar();
        } else {
          _fetchBlockEntry();
        }
        return;
      case QUESTION:
        if (_isPlainCharAt(1)) {
          _fetchPlainScalar();
        } else {
          _fetchKey();
        }
        return;
      case COLON:
        if (!_inBlockContext && _tokens.isNotEmpty) {
          // If a colon follows a "JSON-like" value (an explicit map or list, or
          // a quoted string) it isn't required to have whitespace after it
          // since it unambiguously describes a map.
          var token = _tokens.last;
          if (token.type == TokenType.flowSequenceEnd ||
              token.type == TokenType.flowMappingEnd ||
              (token.type == TokenType.scalar &&
                  (token as ScalarToken).style.isQuoted)) {
            _fetchValue();
            return;
          }
        }

        if (_isPlainCharAt(1)) {
          _fetchPlainScalar();
        } else {
          _fetchValue();
        }
        return;
      default:
        if (!_isNonBreak) _invalidScalarCharacter();

        _fetchPlainScalar();
        return;
    }
  }

  /// Throws an error about a disallowed character.
  void _invalidScalarCharacter() =>
      _scanner.error('Unexpected character.', length: 1);

  /// Checks the list of potential simple keys and remove the positions that
  /// cannot contain simple keys anymore.
  void _staleSimpleKeys() {
    for (var i = 0; i < _simpleKeys.length; i++) {
      var key = _simpleKeys[i];
      if (key == null) continue;

      // libyaml requires that all simple keys be a single line and no longer
      // than 1024 characters. However, in section 7.4.2 of the spec
      // (http://yaml.org/spec/1.2/spec.html#id2790832), these restrictions are
      // only applied when the curly braces are omitted. It's difficult to
      // retain enough context to know which keys need to have the restriction
      // placed on them, so for now we go the other direction and allow
      // everything but multiline simple keys in a block context.
      if (!_inBlockContext) continue;

      if (key.line == _scanner.line) continue;

      if (key.required) {
        _reportError(YamlException("Expected ':'.", _scanner.emptySpan));
        _tokens.insert(key.tokenNumber - _tokensParsed,
            Token(TokenType.key, key.location.pointSpan() as FileSpan));
      }

      _simpleKeys[i] = null;
    }
  }

  /// Checks if a simple key may start at the current position and saves it if
  /// so.
  void _saveSimpleKey() {
    // A simple key is required at the current position if the scanner is in the
    // block context and the current column coincides with the indentation
    // level.
    var required = _inBlockContext && _indent == _scanner.column;

    // A simple key is required only when it is the first token in the current
    // line. Therefore it is always allowed. But we add a check anyway.
    assert(_simpleKeyAllowed || !required);

    if (!_simpleKeyAllowed) return;

    // If the current position may start a simple key, save it.
    _removeSimpleKey();
    _simpleKeys[_simpleKeys.length - 1] = _SimpleKey(
        _tokensParsed + _tokens.length,
        _scanner.line,
        _scanner.column,
        _scanner.location,
        required: required);
  }

  /// Removes a potential simple key at the current flow level.
  void _removeSimpleKey() {
    var key = _simpleKeys.last;
    if (key != null && key.required) {
      throw YamlException("Could not find expected ':' for simple key.",
          key.location.pointSpan());
    }

    _simpleKeys[_simpleKeys.length - 1] = null;
  }

  /// Increases the flow level and resizes the simple key list.
  void _increaseFlowLevel() {
    _simpleKeys.add(null);
  }

  /// Decreases the flow level.
  void _decreaseFlowLevel() {
    if (_inBlockContext) return;
    _simpleKeys.removeLast();
  }

  /// Pushes the current indentation level to the stack and sets the new level
  /// if [column] is greater than [_indent].
  ///
  /// If it is, appends or inserts the specified token into [_tokens]. If
  /// [tokenNumber] is provided, the corresponding token will be replaced;
  /// otherwise, the token will be added at the end.
  void _rollIndent(int column, TokenType type, SourceLocation location,
      {int? tokenNumber}) {
    if (!_inBlockContext) return;
    if (_indent != -1 && _indent >= column) return;

    // Push the current indentation level to the stack and set the new
    // indentation level.
    _indents.add(column);

    // Create a token and insert it into the queue.
    var token = Token(type, location.pointSpan() as FileSpan);
    if (tokenNumber == null) {
      _tokens.add(token);
    } else {
      _tokens.insert(tokenNumber - _tokensParsed, token);
    }
  }

  /// Pops indentation levels from [_indents] until the current level becomes
  /// less than or equal to [column].
  ///
  /// For each indentation level, appends a [TokenType.blockEnd] token.
  void _unrollIndent(int column) {
    if (!_inBlockContext) return;

    while (_indent > column) {
      _tokens.add(Token(TokenType.blockEnd, _scanner.emptySpan));
      _indents.removeLast();
    }
  }

  /// Pops indentation levels from [_indents] until the current level resets to
  /// -1.
  ///
  /// For each indentation level, appends a [TokenType.blockEnd] token.
  void _resetIndent() => _unrollIndent(-1);

  /// Produces a [TokenType.streamStart] token.
  void _fetchStreamStart() {
    // Much of libyaml's initialization logic here is done in variable
    // initializers instead.
    _streamStartProduced = true;
    _tokens.add(Token(TokenType.streamStart, _scanner.emptySpan));
  }

  /// Produces a [TokenType.streamEnd] token.
  void _fetchStreamEnd() {
    _resetIndent();
    _removeSimpleKey();
    _simpleKeyAllowed = false;
    _tokens.add(Token(TokenType.streamEnd, _scanner.emptySpan));
  }

  /// Produces a [TokenType.versionDirective] or [TokenType.tagDirective]
  /// token.
  void _fetchDirective() {
    _resetIndent();
    _removeSimpleKey();
    _simpleKeyAllowed = false;
    var directive = _scanDirective();
    if (directive != null) _tokens.add(directive);
  }

  /// Produces a [TokenType.documentStart] or [TokenType.documentEnd] token.
  void _fetchDocumentIndicator(TokenType type) {
    _resetIndent();
    _removeSimpleKey();
    _simpleKeyAllowed = false;

    // Consume the indicator token.
    var start = _scanner.state;
    _scanner.readChar();
    _scanner.readChar();
    _scanner.readChar();

    _tokens.add(Token(type, _scanner.spanFrom(start)));
  }

  /// Produces a [TokenType.flowSequenceStart] or
  /// [TokenType.flowMappingStart] token.
  void _fetchFlowCollectionStart(TokenType type) {
    _saveSimpleKey();
    _increaseFlowLevel();
    _simpleKeyAllowed = true;
    _addCharToken(type);
  }

  /// Produces a [TokenType.flowSequenceEnd] or [TokenType.flowMappingEnd]
  /// token.
  void _fetchFlowCollectionEnd(TokenType type) {
    _removeSimpleKey();
    _decreaseFlowLevel();
    _simpleKeyAllowed = false;
    _addCharToken(type);
  }

  /// Produces a [TokenType.flowEntry] token.
  void _fetchFlowEntry() {
    _removeSimpleKey();
    _simpleKeyAllowed = true;
    _addCharToken(TokenType.flowEntry);
  }

  /// Produces a [TokenType.blockEntry] token.
  void _fetchBlockEntry() {
    if (_inBlockContext) {
      if (!_simpleKeyAllowed) {
        throw YamlException(
            'Block sequence entries are not allowed here.', _scanner.emptySpan);
      }

      _rollIndent(
          _scanner.column, TokenType.blockSequenceStart, _scanner.location);
    } else {
      // It is an error for the '-' indicator to occur in the flow context, but
      // we let the Parser detect and report it because it's able to point to
      // the context.
    }

    _removeSimpleKey();
    _simpleKeyAllowed = true;
    _addCharToken(TokenType.blockEntry);
  }

  /// Produces the [TokenType.key] token.
  void _fetchKey() {
    if (_inBlockContext) {
      if (!_simpleKeyAllowed) {
        throw YamlException(
            'Mapping keys are not allowed here.', _scanner.emptySpan);
      }

      _rollIndent(
          _scanner.column, TokenType.blockMappingStart, _scanner.location);
    }

    // Simple keys are allowed after `?` in a block context.
    _simpleKeyAllowed = _inBlockContext;
    _addCharToken(TokenType.key);
  }

  /// Produces the [TokenType.value] token.
  void _fetchValue() {
    var simpleKey = _simpleKeys.last;
    if (simpleKey != null) {
      // Add a [TokenType.KEY] directive before the first token of the simple
      // key so the parser knows that it's part of a key/value pair.
      _tokens.insert(simpleKey.tokenNumber - _tokensParsed,
          Token(TokenType.key, simpleKey.location.pointSpan() as FileSpan));

      // In the block context, we may need to add the
      // [TokenType.BLOCK_MAPPING_START] token.
      _rollIndent(
          simpleKey.column, TokenType.blockMappingStart, simpleKey.location,
          tokenNumber: simpleKey.tokenNumber);

      // Remove the simple key.
      _simpleKeys[_simpleKeys.length - 1] = null;

      // A simple key cannot follow another simple key.
      _simpleKeyAllowed = false;
    } else if (_inBlockContext) {
      if (!_simpleKeyAllowed) {
        throw YamlException(
            'Mapping values are not allowed here. Did you miss a colon '
            'earlier?',
            _scanner.emptySpan);
      }

      // If we're here, we've found the ':' indicator following a complex key.

      _rollIndent(
          _scanner.column, TokenType.blockMappingStart, _scanner.location);
      _simpleKeyAllowed = true;
    } else if (_simpleKeyAllowed) {
      // If we're here, we've found the ':' indicator with an empty key. This
      // behavior differs from libyaml, which disallows empty implicit keys.
      _simpleKeyAllowed = false;
      _addCharToken(TokenType.key);
    }

    _addCharToken(TokenType.value);
  }

  /// Adds a token with [type] to [_tokens].
  ///
  /// The span of the new token is the current character.
  void _addCharToken(TokenType type) {
    var start = _scanner.state;
    _scanner.readChar();
    _tokens.add(Token(type, _scanner.spanFrom(start)));
  }

  /// Produces a [TokenType.alias] or [TokenType.anchor] token.
  void _fetchAnchor({bool anchor = true}) {
    _saveSimpleKey();
    _simpleKeyAllowed = false;
    _tokens.add(_scanAnchor(anchor: anchor));
  }

  /// Produces a [TokenType.tag] token.
  void _fetchTag() {
    _saveSimpleKey();
    _simpleKeyAllowed = false;
    _tokens.add(_scanTag());
  }

  /// Produces a [TokenType.scalar] token with style [ScalarStyle.LITERAL] or
  /// [ScalarStyle.FOLDED].
  void _fetchBlockScalar({bool literal = false}) {
    _removeSimpleKey();
    _simpleKeyAllowed = true;
    _tokens.add(_scanBlockScalar(literal: literal));
  }

  /// Produces a [TokenType.scalar] token with style [ScalarStyle.SINGLE_QUOTED]
  /// or [ScalarStyle.DOUBLE_QUOTED].
  void _fetchFlowScalar({bool singleQuote = false}) {
    _saveSimpleKey();
    _simpleKeyAllowed = false;
    _tokens.add(_scanFlowScalar(singleQuote: singleQuote));
  }

  /// Produces a [TokenType.scalar] token with style [ScalarStyle.PLAIN].
  void _fetchPlainScalar() {
    _saveSimpleKey();
    _simpleKeyAllowed = false;
    _tokens.add(_scanPlainScalar());
  }

  /// Eats whitespace and comments until the next token is found.
  void _scanToNextToken() {
    var afterLineBreak = false;
    while (true) {
      // Allow the BOM to start a line.
      if (_scanner.column == 0) _scanner.scan('\uFEFF');

      // Eat whitespace.
      //
      // libyaml disallows tabs after "-", "?", or ":", but the spec allows
      // them. See section 6.2: http://yaml.org/spec/1.2/spec.html#id2778241.
      while (_scanner.peekChar() == SP ||
          ((!_inBlockContext || !afterLineBreak) &&
              _scanner.peekChar() == TAB)) {
        _scanner.readChar();
      }

      if (_scanner.peekChar() == TAB) {
        _scanner.error('Tab characters are not allowed as indentation.',
            length: 1);
      }

      // Eat a comment until a line break.
      _skipComment();

      // If we're at a line break, eat it.
      if (_isBreak) {
        _skipLine();

        // In the block context, a new line may start a simple key.
        if (_inBlockContext) _simpleKeyAllowed = true;
        afterLineBreak = true;
      } else {
        // Otherwise we've found a token.
        break;
      }
    }
  }

  /// Scans a [TokenType.YAML_DIRECTIVE] or [TokenType.tagDirective] token.
  ///
  ///     %YAML    1.2    # a comment \n
  ///     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  ///     %TAG    !yaml!  tag:yaml.org,2002:  \n
  ///     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Token? _scanDirective() {
    var start = _scanner.state;

    // Eat '%'.
    _scanner.readChar();

    Token token;
    var name = _scanDirectiveName();
    if (name == 'YAML') {
      token = _scanVersionDirectiveValue(start);
    } else if (name == 'TAG') {
      token = _scanTagDirectiveValue(start);
    } else {
      warn('Warning: unknown directive.', _scanner.spanFrom(start));

      // libyaml doesn't support unknown directives, but the spec says to ignore
      // them and warn: http://yaml.org/spec/1.2/spec.html#id2781147.
      while (!_isBreakOrEnd) {
        _scanner.readChar();
      }

      return null;
    }

    // Eat the rest of the line, including any comments.
    _skipBlanks();
    _skipComment();

    if (!_isBreakOrEnd) {
      throw YamlException('Expected comment or line break after directive.',
          _scanner.spanFrom(start));
    }

    _skipLine();
    return token;
  }

  /// Scans a directive name.
  ///
  ///      %YAML   1.2     # a comment \n
  ///       ^^^^
  ///      %TAG    !yaml!  tag:yaml.org,2002:  \n
  ///       ^^^
  String _scanDirectiveName() {
    // libyaml only allows word characters in directive names, but the spec
    // disagrees: http://yaml.org/spec/1.2/spec.html#ns-directive-name.
    var start = _scanner.position;
    while (_isNonSpace) {
      _scanner.readChar();
    }

    var name = _scanner.substring(start);
    if (name.isEmpty) {
      throw YamlException('Expected directive name.', _scanner.emptySpan);
    } else if (!_isBlankOrEnd) {
      throw YamlException(
          'Unexpected character in directive name.', _scanner.emptySpan);
    }

    return name;
  }

  /// Scans the value of a version directive.
  ///
  ///      %YAML   1.2     # a comment \n
  ///           ^^^^^^
  Token _scanVersionDirectiveValue(LineScannerState start) {
    _skipBlanks();

    var major = _scanVersionDirectiveNumber();
    _scanner.expect('.');
    var minor = _scanVersionDirectiveNumber();

    return VersionDirectiveToken(_scanner.spanFrom(start), major, minor);
  }

  /// Scans the version number of a version directive.
  ///
  ///      %YAML   1.2     # a comment \n
  ///              ^
  ///      %YAML   1.2     # a comment \n
  ///                ^
  int _scanVersionDirectiveNumber() {
    var start = _scanner.position;
    while (_isDigit) {
      _scanner.readChar();
    }

    var number = _scanner.substring(start);
    if (number.isEmpty) {
      throw YamlException('Expected version number.', _scanner.emptySpan);
    }

    return int.parse(number);
  }

  /// Scans the value of a tag directive.
  ///
  ///      %TAG    !yaml!  tag:yaml.org,2002:  \n
  ///          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Token _scanTagDirectiveValue(LineScannerState start) {
    _skipBlanks();

    var handle = _scanTagHandle(directive: true);
    if (!_isBlank) {
      throw YamlException('Expected whitespace.', _scanner.emptySpan);
    }

    _skipBlanks();

    var prefix = _scanTagUri();
    if (!_isBlankOrEnd) {
      throw YamlException('Expected whitespace.', _scanner.emptySpan);
    }

    return TagDirectiveToken(_scanner.spanFrom(start), handle, prefix);
  }

  /// Scans a [TokenType.anchor] token.
  Token _scanAnchor({bool anchor = true}) {
    var start = _scanner.state;

    // Eat the indicator character.
    _scanner.readChar();

    // libyaml only allows word characters in anchor names, but the spec
    // disagrees: http://yaml.org/spec/1.2/spec.html#ns-anchor-char.
    var startPosition = _scanner.position;
    while (_isAnchorChar) {
      _scanner.readChar();
    }
    var name = _scanner.substring(startPosition);

    var next = _scanner.peekChar();
    if (name.isEmpty ||
        (!_isBlankOrEnd &&
            next != QUESTION &&
            next != COLON &&
            next != COMMA &&
            next != RIGHT_SQUARE &&
            next != RIGHT_CURLY &&
            next != PERCENT &&
            next != AT &&
            next != GRAVE_ACCENT)) {
      throw YamlException(
          'Expected alphanumeric character.', _scanner.emptySpan);
    }

    if (anchor) {
      return AnchorToken(_scanner.spanFrom(start), name);
    } else {
      return AliasToken(_scanner.spanFrom(start), name);
    }
  }

  /// Scans a [TokenType.tag] token.
  Token _scanTag() {
    String? handle;
    String suffix;
    var start = _scanner.state;

    // Check if the tag is in the canonical form.
    if (_scanner.peekChar(1) == LEFT_ANGLE) {
      // Eat '!<'.
      _scanner.readChar();
      _scanner.readChar();

      handle = '';
      suffix = _scanTagUri();

      _scanner.expect('>');
    } else {
      // The tag has either the '!suffix' or the '!handle!suffix' form.

      // First, try to scan a handle.
      handle = _scanTagHandle();

      if (handle.length > 1 && handle.startsWith('!') && handle.endsWith('!')) {
        suffix = _scanTagUri(flowSeparators: false);
      } else {
        suffix = _scanTagUri(head: handle, flowSeparators: false);

        // There was no explicit handle.
        if (suffix.isEmpty) {
          // This is the special '!' tag.
          handle = null;
          suffix = '!';
        } else {
          handle = '!';
        }
      }
    }

    // libyaml insists on whitespace after a tag, but example 7.2 indicates
    // that it's not required: http://yaml.org/spec/1.2/spec.html#id2786720.

    return TagToken(_scanner.spanFrom(start), handle, suffix);
  }

  /// Scans a tag handle.
  String _scanTagHandle({bool directive = false}) {
    _scanner.expect('!');

    var buffer = StringBuffer('!');

    // libyaml only allows word characters in tags, but the spec disagrees:
    // http://yaml.org/spec/1.2/spec.html#ns-tag-char.
    var start = _scanner.position;
    while (_isTagChar) {
      _scanner.readChar();
    }
    buffer.write(_scanner.substring(start));

    if (_scanner.peekChar() == EXCLAMATION) {
      buffer.writeCharCode(_scanner.readChar());
    } else {
      // It's either the '!' tag or not really a tag handle. If it's a %TAG
      // directive, it's an error. If it's a tag token, it must be part of a
      // URI.
      if (directive && buffer.toString() != '!') _scanner.expect('!');
    }

    return buffer.toString();
  }

  /// Scans a tag URI.
  ///
  /// [head] is the initial portion of the tag that's already been scanned.
  /// [flowSeparators] indicates whether the tag URI can contain flow
  /// separators.
  String _scanTagUri({String? head, bool flowSeparators = true}) {
    var length = head == null ? 0 : head.length;
    var buffer = StringBuffer();

    // Copy the head if needed.
    //
    // Note that we don't copy the leading '!' character.
    if (length > 1) buffer.write(head!.substring(1));

    // The set of characters that may appear in URI is as follows:
    //
    //      '0'-'9', 'A'-'Z', 'a'-'z', '_', '-', ';', '/', '?', ':', '@', '&',
    //      '=', '+', '$', ',', '.', '!', '~', '*', '\'', '(', ')', '[', ']',
    //      '%'.
    //
    // In a shorthand tag annotation, the flow separators ',', '[', and ']' are
    // disallowed.
    var start = _scanner.position;
    var char = _scanner.peekChar();
    while (_isTagChar ||
        (flowSeparators &&
            (char == COMMA || char == LEFT_SQUARE || char == RIGHT_SQUARE))) {
      _scanner.readChar();
      char = _scanner.peekChar();
    }

    // libyaml manually decodes the URL, but we don't have to do that.
    return Uri.decodeFull(_scanner.substring(start));
  }

  /// Scans a block scalar.
  Token _scanBlockScalar({bool literal = false}) {
    var start = _scanner.state;

    // Eat the indicator '|' or '>'.
    _scanner.readChar();

    // Check for a chomping indicator.
    var chomping = _Chomping.clip;
    var increment = 0;
    var char = _scanner.peekChar();
    if (char == PLUS || char == HYPHEN) {
      chomping = char == PLUS ? _Chomping.keep : _Chomping.strip;
      _scanner.readChar();

      // Check for an indentation indicator.
      if (_isDigit) {
        // Check that the indentation is greater than 0.
        if (_scanner.peekChar() == NUMBER_0) {
          throw YamlException('0 may not be used as an indentation indicator.',
              _scanner.spanFrom(start));
        }

        increment = _scanner.readChar() - NUMBER_0;
      }
    } else if (_isDigit) {
      // Do the same as above, but in the opposite order.
      if (_scanner.peekChar() == NUMBER_0) {
        throw YamlException('0 may not be used as an indentation indicator.',
            _scanner.spanFrom(start));
      }

      increment = _scanner.readChar() - NUMBER_0;

      char = _scanner.peekChar();
      if (char == PLUS || char == HYPHEN) {
        chomping = char == PLUS ? _Chomping.keep : _Chomping.strip;
        _scanner.readChar();
      }
    }

    // Eat whitespace and comments to the end of the line.
    _skipBlanks();
    _skipComment();

    // Check if we're at the end of the line.
    if (!_isBreakOrEnd) {
      throw YamlException(
          'Expected comment or line break.', _scanner.emptySpan);
    }

    _skipLine();

    // If the block scalar has an explicit indentation indicator, add that to
    // the current indentation to get the indentation level for the scalar's
    // contents.
    var indent = 0;
    if (increment != 0) {
      indent = _indent >= 0 ? _indent + increment : increment;
    }

    // Scan the leading line breaks to determine the indentation level if
    // needed.
    var pair = _scanBlockScalarBreaks(indent);
    indent = pair.first;
    var trailingBreaks = pair.last;

    // Scan the block scalar contents.
    var buffer = StringBuffer();
    var leadingBreak = '';
    var leadingBlank = false;
    var trailingBlank = false;
    var end = _scanner.state;
    while (_scanner.column == indent && !_scanner.isDone) {
      // Check for a document indicator. libyaml doesn't do this, but the spec
      // mandates it. See example 9.5:
      // http://yaml.org/spec/1.2/spec.html#id2801606.
      if (_isDocumentIndicator) break;

      // We are at the beginning of a non-empty line.

      // Is there trailing whitespace?
      trailingBlank = _isBlank;

      // Check if we need to fold the leading line break.
      if (!literal &&
          leadingBreak.isNotEmpty &&
          !leadingBlank &&
          !trailingBlank) {
        // Do we need to join the lines with a space?
        if (trailingBreaks.isEmpty) buffer.writeCharCode(SP);
      } else {
        buffer.write(leadingBreak);
      }
      leadingBreak = '';

      // Append the remaining line breaks.
      buffer.write(trailingBreaks);

      // Is there leading whitespace?
      leadingBlank = _isBlank;

      var startPosition = _scanner.position;
      while (!_isBreakOrEnd) {
        _scanner.readChar();
      }
      buffer.write(_scanner.substring(startPosition));
      end = _scanner.state;

      // libyaml always reads a line here, but this breaks on block scalars at
      // the end of the document that end without newlines. See example 8.1:
      // http://yaml.org/spec/1.2/spec.html#id2793888.
      if (!_scanner.isDone) leadingBreak = _readLine();

      // Eat the following indentation and spaces.
      var pair = _scanBlockScalarBreaks(indent);
      indent = pair.first;
      trailingBreaks = pair.last;
    }

    // Chomp the tail.
    if (chomping != _Chomping.strip) buffer.write(leadingBreak);
    if (chomping == _Chomping.keep) buffer.write(trailingBreaks);

    return ScalarToken(_scanner.spanFrom(start, end), buffer.toString(),
        literal ? ScalarStyle.LITERAL : ScalarStyle.FOLDED);
  }

  /// Scans indentation spaces and line breaks for a block scalar.
  ///
  /// Determines the intendation level if needed. Returns the new indentation
  /// level and the text of the line breaks.
  Pair<int, String> _scanBlockScalarBreaks(int indent) {
    var maxIndent = 0;
    var breaks = StringBuffer();

    while (true) {
      while ((indent == 0 || _scanner.column < indent) &&
          _scanner.peekChar() == SP) {
        _scanner.readChar();
      }

      if (_scanner.column > maxIndent) maxIndent = _scanner.column;

      // libyaml throws an error here if a tab character is detected, but the
      // spec treats tabs like any other non-space character. See example 8.2:
      // http://yaml.org/spec/1.2/spec.html#id2794311.

      if (!_isBreak) break;
      breaks.write(_readLine());
    }

    if (indent == 0) {
      indent = maxIndent;
      if (indent < _indent + 1) indent = _indent + 1;

      // libyaml forces indent to be at least 1 here, but that doesn't seem to
      // be supported by the spec.
    }

    return Pair(indent, breaks.toString());
  }

  // Scans a quoted scalar.
  Token _scanFlowScalar({bool singleQuote = false}) {
    var start = _scanner.state;
    var buffer = StringBuffer();

    // Eat the left quote.
    _scanner.readChar();

    while (true) {
      // Check that there are no document indicators at the beginning of the
      // line.
      if (_isDocumentIndicator) {
        _scanner.error('Unexpected document indicator.');
      }

      if (_scanner.isDone) {
        throw YamlException('Unexpected end of file.', _scanner.emptySpan);
      }

      var leadingBlanks = false;
      while (!_isBlankOrEnd) {
        var char = _scanner.peekChar();
        if (singleQuote &&
            char == SINGLE_QUOTE &&
            _scanner.peekChar(1) == SINGLE_QUOTE) {
          // An escaped single quote.
          _scanner.readChar();
          _scanner.readChar();
          buffer.writeCharCode(SINGLE_QUOTE);
        } else if (char == (singleQuote ? SINGLE_QUOTE : DOUBLE_QUOTE)) {
          // The closing quote.
          break;
        } else if (!singleQuote && char == BACKSLASH && _isBreakAt(1)) {
          // An escaped newline.
          _scanner.readChar();
          _skipLine();
          leadingBlanks = true;
          break;
        } else if (!singleQuote && char == BACKSLASH) {
          var escapeStart = _scanner.state;

          // An escape sequence.
          int? codeLength;
          switch (_scanner.peekChar(1)) {
            case NUMBER_0:
              buffer.writeCharCode(NULL);
              break;
            case LETTER_A:
              buffer.writeCharCode(BELL);
              break;
            case LETTER_B:
              buffer.writeCharCode(BACKSPACE);
              break;
            case LETTER_T:
            case TAB:
              buffer.writeCharCode(TAB);
              break;
            case LETTER_N:
              buffer.writeCharCode(LF);
              break;
            case LETTER_V:
              buffer.writeCharCode(VERTICAL_TAB);
              break;
            case LETTER_F:
              buffer.writeCharCode(FORM_FEED);
              break;
            case LETTER_R:
              buffer.writeCharCode(CR);
              break;
            case LETTER_E:
              buffer.writeCharCode(ESCAPE);
              break;
            case SP:
            case DOUBLE_QUOTE:
            case SLASH:
            case BACKSLASH:
              // libyaml doesn't support an escaped forward slash, but it was
              // added in YAML 1.2. See section 5.7:
              // http://yaml.org/spec/1.2/spec.html#id2776092
              buffer.writeCharCode(_scanner.peekChar(1)!);
              break;
            case LETTER_CAP_N:
              buffer.writeCharCode(NEL);
              break;
            case UNDERSCORE:
              buffer.writeCharCode(NBSP);
              break;
            case LETTER_CAP_L:
              buffer.writeCharCode(LINE_SEPARATOR);
              break;
            case LETTER_CAP_P:
              buffer.writeCharCode(PARAGRAPH_SEPARATOR);
              break;
            case LETTER_X:
              codeLength = 2;
              break;
            case LETTER_U:
              codeLength = 4;
              break;
            case LETTER_CAP_U:
              codeLength = 8;
              break;
            default:
              throw YamlException(
                  'Unknown escape character.', _scanner.spanFrom(escapeStart));
          }

          _scanner.readChar();
          _scanner.readChar();

          if (codeLength != null) {
            var value = 0;
            for (var i = 0; i < codeLength; i++) {
              if (!_isHex) {
                _scanner.readChar();
                throw YamlException(
                    'Expected $codeLength-digit hexidecimal number.',
                    _scanner.spanFrom(escapeStart));
              }

              value = (value << 4) + _asHex(_scanner.readChar());
            }

            // Check the value and write the character.
            if ((value >= 0xD800 && value <= 0xDFFF) || value > 0x10FFFF) {
              throw YamlException('Invalid Unicode character escape code.',
                  _scanner.spanFrom(escapeStart));
            }

            buffer.writeCharCode(value);
          }
        } else {
          buffer.writeCharCode(_scanner.readChar());
        }
      }

      // Check if we're at the end of a scalar.
      if (_scanner.peekChar() == (singleQuote ? SINGLE_QUOTE : DOUBLE_QUOTE)) {
        break;
      }

      var whitespace = StringBuffer();
      var leadingBreak = '';
      var trailingBreaks = StringBuffer();
      while (_isBlank || _isBreak) {
        if (_isBlank) {
          // Consume a space or a tab.
          if (!leadingBlanks) {
            whitespace.writeCharCode(_scanner.readChar());
          } else {
            _scanner.readChar();
          }
        } else {
          // Check if it's a first line break.
          if (!leadingBlanks) {
            whitespace.clear();
            leadingBreak = _readLine();
            leadingBlanks = true;
          } else {
            trailingBreaks.write(_readLine());
          }
        }
      }

      // Join the whitespace or fold line breaks.
      if (leadingBlanks) {
        if (leadingBreak.isNotEmpty && trailingBreaks.isEmpty) {
          buffer.writeCharCode(SP);
        } else {
          buffer.write(trailingBreaks);
        }
      } else {
        buffer.write(whitespace);
        whitespace.clear();
      }
    }

    // Eat the right quote.
    _scanner.readChar();

    return ScalarToken(_scanner.spanFrom(start), buffer.toString(),
        singleQuote ? ScalarStyle.SINGLE_QUOTED : ScalarStyle.DOUBLE_QUOTED);
  }

  /// Scans a plain scalar.
  Token _scanPlainScalar() {
    var start = _scanner.state;
    var end = _scanner.state;
    var buffer = StringBuffer();
    var leadingBreak = '';
    var trailingBreaks = '';
    var whitespace = StringBuffer();
    var indent = _indent + 1;

    while (true) {
      // Check for a document indicator.
      if (_isDocumentIndicator) break;

      // Check for a comment.
      if (_scanner.peekChar() == HASH) break;

      if (_isPlainChar) {
        // Join the whitespace or fold line breaks.
        if (leadingBreak.isNotEmpty) {
          if (trailingBreaks.isEmpty) {
            buffer.writeCharCode(SP);
          } else {
            buffer.write(trailingBreaks);
          }
          leadingBreak = '';
          trailingBreaks = '';
        } else {
          buffer.write(whitespace);
          whitespace.clear();
        }
      }

      // libyaml's notion of valid identifiers differs substantially from YAML
      // 1.2's. We use [_isPlainChar] instead of libyaml's character here.
      var startPosition = _scanner.position;
      while (_isPlainChar) {
        _scanner.readChar();
      }
      buffer.write(_scanner.substring(startPosition));
      end = _scanner.state;

      // Is it the end?
      if (!_isBlank && !_isBreak) break;

      while (_isBlank || _isBreak) {
        if (_isBlank) {
          // Check for a tab character messing up the intendation.
          if (leadingBreak.isNotEmpty &&
              _scanner.column < indent &&
              _scanner.peekChar() == TAB) {
            _scanner.error('Expected a space but found a tab.', length: 1);
          }

          if (leadingBreak.isEmpty) {
            whitespace.writeCharCode(_scanner.readChar());
          } else {
            _scanner.readChar();
          }
        } else {
          // Check if it's a first line break.
          if (leadingBreak.isEmpty) {
            leadingBreak = _readLine();
            whitespace.clear();
          } else {
            trailingBreaks = _readLine();
          }
        }
      }

      // Check the indentation level.
      if (_inBlockContext && _scanner.column < indent) break;
    }

    // Allow a simple key after a plain scalar with leading blanks.
    if (leadingBreak.isNotEmpty) _simpleKeyAllowed = true;

    return ScalarToken(
        _scanner.spanFrom(start, end), buffer.toString(), ScalarStyle.PLAIN);
  }

  /// Moves past the current line break, if there is one.
  void _skipLine() {
    var char = _scanner.peekChar();
    if (char != CR && char != LF) return;
    _scanner.readChar();
    if (char == CR && _scanner.peekChar() == LF) _scanner.readChar();
  }

  // Moves past the current line break and returns a newline.
  String _readLine() {
    var char = _scanner.peekChar();

    // libyaml supports NEL, PS, and LS characters as line separators, but this
    // is explicitly forbidden in section 5.4 of the YAML spec.
    if (char != CR && char != LF) {
      throw YamlException('Expected newline.', _scanner.emptySpan);
    }

    _scanner.readChar();
    // CR LF | CR | LF -> LF
    if (char == CR && _scanner.peekChar() == LF) _scanner.readChar();
    return '\n';
  }

  // Returns whether the character at [offset] is whitespace.
  bool _isBlankAt(int offset) {
    var char = _scanner.peekChar(offset);
    return char == SP || char == TAB;
  }

  // Returns whether the character at [offset] is a line break.
  bool _isBreakAt(int offset) {
    // Libyaml considers NEL, LS, and PS to be line breaks as well, but that's
    // contrary to the spec.
    var char = _scanner.peekChar(offset);
    return char == CR || char == LF;
  }

  // Returns whether the character at [offset] is whitespace or past the end of
  // the source.
  bool _isBlankOrEndAt(int offset) {
    var char = _scanner.peekChar(offset);
    return char == null ||
        char == SP ||
        char == TAB ||
        char == CR ||
        char == LF;
  }

  /// Returns whether the character at [offset] is a plain character.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#ns-plain-char(c).
  bool _isPlainCharAt(int offset) {
    switch (_scanner.peekChar(offset)) {
      case COLON:
        return _isPlainSafeAt(offset + 1);
      case HASH:
        var previous = _scanner.peekChar(offset - 1);
        return previous != SP && previous != TAB;
      default:
        return _isPlainSafeAt(offset);
    }
  }

  /// Returns whether the character at [offset] is a plain-safe character.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#ns-plain-safe(c).
  bool _isPlainSafeAt(int offset) {
    var char = _scanner.peekChar(offset);
    switch (char) {
      case COMMA:
      case LEFT_SQUARE:
      case RIGHT_SQUARE:
      case LEFT_CURLY:
      case RIGHT_CURLY:
        // These characters are delimiters in a flow context and thus are only
        // safe in a block context.
        return _inBlockContext;
      case SP:
      case TAB:
      case LF:
      case CR:
      case BOM:
        return false;
      case NEL:
        return true;
      default:
        return char != null &&
            ((char >= 0x00020 && char <= 0x00007E) ||
                (char >= 0x000A0 && char <= 0x00D7FF) ||
                (char >= 0x0E000 && char <= 0x00FFFD) ||
                (char >= 0x10000 && char <= 0x10FFFF));
    }
  }

  /// Returns the hexidecimal value of [char].
  int _asHex(int char) {
    if (char <= NUMBER_9) return char - NUMBER_0;
    if (char <= LETTER_CAP_F) return 10 + char - LETTER_CAP_A;
    return 10 + char - LETTER_A;
  }

  /// Moves the scanner past any blank characters.
  void _skipBlanks() {
    while (_isBlank) {
      _scanner.readChar();
    }
  }

  /// Moves the scanner past a comment, if one starts at the current position.
  void _skipComment() {
    if (_scanner.peekChar() != HASH) return;
    while (!_isBreakOrEnd) {
      _scanner.readChar();
    }
  }

  /// Reports a [YamlException] to [_errorListener] if [_recover] is true,
  /// otherwise throws the exception.
  void _reportError(YamlException exception) {
    if (!_recover) {
      throw exception;
    }
    _errorListener?.onError(exception);
  }
}

/// A record of the location of a potential simple key.
class _SimpleKey {
  /// The index of the token that begins the simple key.
  ///
  /// This is the index relative to all tokens emitted, rather than relative to
  /// [_tokens].
  final int tokenNumber;

  /// The source location of the beginning of the simple key.
  ///
  /// This is used for error reporting and for determining when a simple key is
  /// no longer on the current line.
  final SourceLocation location;

  /// The line on which the key appears.
  ///
  /// We could get this from [location], but that requires a binary search
  /// whereas this is O(1).
  final int line;

  /// The column on which the key appears.
  ///
  /// We could get this from [location], but that requires a binary search
  /// whereas this is O(1).
  final int column;

  /// Whether this key must exist for the document to be scanned.
  final bool required;

  _SimpleKey(
    this.tokenNumber,
    this.line,
    this.column,
    this.location, {
    required this.required,
  });
}

/// The ways to handle trailing whitespace for a block scalar.
///
/// See http://yaml.org/spec/1.2/spec.html#id2794534.
enum _Chomping {
  /// All trailing whitespace is discarded.
  strip,

  /// A single trailing newline is retained.
  clip,

  /// All trailing whitespace is preserved.
  keep
}
