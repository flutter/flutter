// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:convert" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:_internal"
    show
        allocateOneByteString,
        allocateTwoByteString,
        ClassID,
        copyRangeFromUint8ListToOneByteString,
        patch,
        POWERS_OF_TEN,
        unsafeCast,
        writeIntoOneByteString,
        writeIntoTwoByteString,
        createOneByteStringFromCharacters;

import "dart:typed_data" show Uint8List, Uint16List;

/// This patch library has no additional parts.

// JSON conversion.

@patch
dynamic _parseJson(
    String source, Object? Function(Object? key, Object? value)? reviver) {
  _JsonListener listener = new _JsonListener(reviver);
  var parser = new _JsonStringParser(listener);
  parser.chunk = source;
  parser.chunkEnd = source.length;
  parser.parse(0);
  parser.close();
  return listener.result;
}

@patch
class Utf8Decoder {
  @patch
  Converter<List<int>, T> fuse<T>(Converter<String, T> next) {
    if (next is JsonDecoder) {
      return new _JsonUtf8Decoder(
              (next as JsonDecoder)._reviver, this._allowMalformed)
          as dynamic/*=Converter<List<int>, T>*/;
    }
    // TODO(lrn): Recognize a fused decoder where the next step is JsonDecoder.
    return super.fuse<T>(next);
  }
}

class _JsonUtf8Decoder extends Converter<List<int>, Object?> {
  final Object? Function(Object? key, Object? value)? _reviver;
  final bool _allowMalformed;

  _JsonUtf8Decoder(this._reviver, this._allowMalformed);

  Object? convert(List<int> input) {
    var parser = _JsonUtf8DecoderSink._createParser(_reviver, _allowMalformed);
    parser.parseChunk(input, 0, input.length);
    parser.close();
    return parser.result;
  }

  ByteConversionSink startChunkedConversion(Sink<Object?> sink) {
    return new _JsonUtf8DecoderSink(_reviver, sink, _allowMalformed);
  }
}

//// Implementation ///////////////////////////////////////////////////////////

// Simple API for JSON parsing.

/**
 * A [_JsonListener] builds data objects from the parser events.
 *
 * This is a simple stack-based object builder. It keeps the most recently
 * seen value in a variable, and uses it depending on the following event.
 */
class _JsonListener {
  _JsonListener(this.reviver);

  final Object? Function(Object? key, Object? value)? reviver;

  /**
   * Stack used to handle nested containers.
   *
   * The current container is pushed on the stack when a new one is
   * started. If the container is a [Map], there is also a current [key]
   * which is also stored on the stack.
   */
  final List<Object?> stack = [];

  /** The current [Map] or [List] being built, or null if not building a
  * container.
  */
  Object? currentContainer;

  /** The most recently read property key. */
  String key = '';

  /** The most recently read value. */
  Object? value;

  /** Pushes the currently active container (and key, if a [Map]). */
  void pushContainer() {
    if (currentContainer is Map) stack.add(key);
    stack.add(currentContainer);
  }

  /** Pops the top container from the [stack], including a key if applicable. */
  void popContainer() {
    value = currentContainer;
    currentContainer = stack.removeLast();
    if (currentContainer is Map) key = unsafeCast<String>(stack.removeLast());
  }

  void handleString(String value) {
    this.value = value;
  }

  void handleNumber(num value) {
    this.value = value;
  }

  void handleBool(bool value) {
    this.value = value;
  }

  void handleNull() {
    this.value = null;
  }

  void beginObject() {
    pushContainer();
    currentContainer = <String, dynamic>{};
  }

  void propertyName() {
    key = unsafeCast<String>(value);
    value = null;
  }

  void propertyValue() {
    var map = unsafeCast<Map>(currentContainer);
    var reviver = this.reviver;
    if (reviver != null) {
      value = reviver(key, value);
    }
    map[key] = value;
    key = '';
    value = null;
  }

  void endObject() {
    popContainer();
  }

  void beginArray() {
    pushContainer();
    currentContainer = <dynamic>[];
  }

  void arrayElement() {
    var list = unsafeCast<List>(currentContainer);
    var reviver = this.reviver;
    if (reviver != null) {
      value = reviver(list.length, value);
    }
    list.add(value);
    value = null;
  }

  void endArray() {
    popContainer();
  }

  /**
   * Read out the final result of parsing a JSON string.
   *
   * Must only be called when the entire input has been parsed.
   */
  dynamic get result {
    assert(currentContainer == null);
    var reviver = this.reviver;
    if (reviver != null) {
      return reviver(null, value);
    } else {
      return value;
    }
  }
}

/**
 * Buffer holding parts of a numeral.
 *
 * The buffer contains the characters of a JSON number.
 * These are all ASCII, so an [Uint8List] is used as backing store.
 *
 * This buffer is used when a JSON number is split between separate chunks.
 */
class _NumberBuffer {
  static const int minCapacity = 16;
  static const int defaultOverhead = 5;
  Uint8List list;
  int length = 0;
  _NumberBuffer(int initialCapacity)
      : list = new Uint8List(_initialCapacity(initialCapacity));

  int get capacity => list.length;

  // Pick an initial capacity greater than the first part's size.
  // The typical use case has two parts, this is the attempt at
  // guessing the size of the second part without overdoing it.
  // The default estimate of the second part is [defaultOverhead],
  // then round to multiplum of four, and return the result,
  // or [minCapacity] if that is greater.
  static int _initialCapacity(int minCapacity) {
    minCapacity += defaultOverhead;
    if (minCapacity < _NumberBuffer.minCapacity) {
      return _NumberBuffer.minCapacity;
    }
    minCapacity = (minCapacity + 3) & ~3; // Round to multiple of four.
    return minCapacity;
  }

  // Grows to the exact size asked for.
  void ensureCapacity(int newCapacity) {
    Uint8List list = this.list;
    if (newCapacity <= list.length) return;
    Uint8List newList = new Uint8List(newCapacity);
    newList.setRange(0, list.length, list, 0);
    this.list = newList;
  }

  String getString() {
    String result = new String.fromCharCodes(list, 0, length);
    return result;
  }

  // TODO(lrn): See if parsing of numbers can be abstracted to something
  // not only working on strings, but also on char-code lists, without losing
  // performance.
  num parseNum() => num.parse(getString());
  double parseDouble() => double.parse(getString());
}

abstract class _JsonParserWithListener {
  final _JsonListener listener;
  _JsonParserWithListener(this.listener);
}

/**
 * Chunked JSON parser.
 *
 * Receives inputs in chunks, gives access to individual parts of the input,
 * and stores input state between chunks.
 *
 * Implementations include [String] and UTF-8 parsers.
 *
 * Note: this is a mixin instead of the base class to allow compilers
 * to specialize applications otherwise accessing chunk characters becomes
 * polymorphic.
 *
 */
mixin _ChunkedJsonParser<T> on _JsonParserWithListener {
  // A simple non-recursive state-based parser for JSON.
  //
  // Literal values accepted in states ARRAY_EMPTY, ARRAY_COMMA, OBJECT_COLON
  // and strings also in OBJECT_EMPTY, OBJECT_COMMA.
  //               VALUE  STRING  :  ,  }  ]        Transitions to
  // EMPTY            X      X                   -> END
  // ARRAY_EMPTY      X      X             @     -> ARRAY_VALUE / pop
  // ARRAY_VALUE                     @     @     -> ARRAY_COMMA / pop
  // ARRAY_COMMA      X      X                   -> ARRAY_VALUE
  // OBJECT_EMPTY            X          @        -> OBJECT_KEY / pop
  // OBJECT_KEY                   @              -> OBJECT_COLON
  // OBJECT_COLON     X      X                   -> OBJECT_VALUE
  // OBJECT_VALUE                    @  @        -> OBJECT_COMMA / pop
  // OBJECT_COMMA            X                   -> OBJECT_KEY
  // END
  // Starting a new array or object will push the current state. The "pop"
  // above means restoring this state and then marking it as an ended value.
  // X means generic handling, @ means special handling for just that
  // state - that is, values are handled generically, only punctuation
  // cares about the current state.
  // Values for states are chosen so bits 0 and 1 tell whether
  // a string/value is allowed, and setting bits 0 through 2 after a value
  // gets to the next state (not empty, doesn't allow a value).

  // State building-block constants.
  static const int TOP_LEVEL = 0;
  static const int INSIDE_ARRAY = 1;
  static const int INSIDE_OBJECT = 2;
  static const int AFTER_COLON = 3; // Always inside object.

  static const int ALLOW_STRING_MASK = 8; // Allowed if zero.
  static const int ALLOW_VALUE_MASK = 4; // Allowed if zero.
  static const int ALLOW_VALUE = 0;
  static const int STRING_ONLY = 4;
  static const int NO_VALUES = 12;

  // Objects and arrays are "empty" until their first property/element.
  // At this position, they may either have an entry or a close-bracket.
  static const int EMPTY = 0;
  static const int NON_EMPTY = 16;
  static const int EMPTY_MASK = 16; // Empty if zero.

  // Actual states               : Context | Is empty? | Next?
  static const int STATE_INITIAL = TOP_LEVEL | EMPTY | ALLOW_VALUE;
  static const int STATE_END = TOP_LEVEL | NON_EMPTY | NO_VALUES;

  static const int STATE_ARRAY_EMPTY = INSIDE_ARRAY | EMPTY | ALLOW_VALUE;
  static const int STATE_ARRAY_VALUE = INSIDE_ARRAY | NON_EMPTY | NO_VALUES;
  static const int STATE_ARRAY_COMMA = INSIDE_ARRAY | NON_EMPTY | ALLOW_VALUE;

  static const int STATE_OBJECT_EMPTY = INSIDE_OBJECT | EMPTY | STRING_ONLY;
  static const int STATE_OBJECT_KEY = INSIDE_OBJECT | NON_EMPTY | NO_VALUES;
  static const int STATE_OBJECT_COLON = AFTER_COLON | NON_EMPTY | ALLOW_VALUE;
  static const int STATE_OBJECT_VALUE = AFTER_COLON | NON_EMPTY | NO_VALUES;
  static const int STATE_OBJECT_COMMA = INSIDE_OBJECT | NON_EMPTY | STRING_ONLY;

  // Bits set in state after successfully reading a value.
  // This transitions the state to expect the next punctuation.
  static const int VALUE_READ_BITS = NON_EMPTY | NO_VALUES;

  // Character code constants.
  static const int BACKSPACE = 0x08;
  static const int TAB = 0x09;
  static const int NEWLINE = 0x0a;
  static const int CARRIAGE_RETURN = 0x0d;
  static const int FORM_FEED = 0x0c;
  static const int SPACE = 0x20;
  static const int QUOTE = 0x22;
  static const int PLUS = 0x2b;
  static const int COMMA = 0x2c;
  static const int MINUS = 0x2d;
  static const int DECIMALPOINT = 0x2e;
  static const int SLASH = 0x2f;
  static const int CHAR_0 = 0x30;
  static const int CHAR_9 = 0x39;
  static const int COLON = 0x3a;
  static const int CHAR_E = 0x45;
  static const int LBRACKET = 0x5b;
  static const int BACKSLASH = 0x5c;
  static const int RBRACKET = 0x5d;
  static const int CHAR_a = 0x61;
  static const int CHAR_b = 0x62;
  static const int CHAR_e = 0x65;
  static const int CHAR_f = 0x66;
  static const int CHAR_l = 0x6c;
  static const int CHAR_n = 0x6e;
  static const int CHAR_r = 0x72;
  static const int CHAR_s = 0x73;
  static const int CHAR_t = 0x74;
  static const int CHAR_u = 0x75;
  static const int LBRACE = 0x7b;
  static const int RBRACE = 0x7d;

  // State of partial value at chunk split.
  static const int NO_PARTIAL = 0;
  static const int PARTIAL_STRING = 1;
  static const int PARTIAL_NUMERAL = 2;
  static const int PARTIAL_KEYWORD = 3;
  static const int MASK_PARTIAL = 3;

  // Partial states for numerals. Values can be |'ed with PARTIAL_NUMERAL.
  static const int NUM_SIGN = 0; // After initial '-'.
  static const int NUM_ZERO = 4; // After '0' as first digit.
  static const int NUM_DIGIT = 8; // After digit, no '.' or 'e' seen.
  static const int NUM_DOT = 12; // After '.'.
  static const int NUM_DOT_DIGIT = 16; // After a decimal digit (after '.').
  static const int NUM_E = 20; // After 'e' or 'E'.
  static const int NUM_E_SIGN = 24; // After '-' or '+' after 'e' or 'E'.
  static const int NUM_E_DIGIT = 28; // After exponent digit.
  static const int NUM_SUCCESS = 32; // Never stored as partial state.

  // Partial states for strings.
  static const int STR_PLAIN = 0; // Inside string, but not escape.
  static const int STR_ESCAPE = 4; // After '\'.
  static const int STR_U = 16; // After '\u' and 0-3 hex digits.
  static const int STR_U_COUNT_SHIFT = 2; // Hex digit count in bits 2-3.
  static const int STR_U_VALUE_SHIFT = 5; // Hex digit value in bits 5+.

  // Partial states for keywords.
  static const int KWD_TYPE_MASK = 12;
  static const int KWD_TYPE_SHIFT = 2;
  static const int KWD_NULL = 0; // Prefix of "null" seen.
  static const int KWD_TRUE = 4; // Prefix of "true" seen.
  static const int KWD_FALSE = 8; // Prefix of "false" seen.
  static const int KWD_BOM = 12; // Prefix of BOM seen.
  static const int KWD_COUNT_SHIFT = 4; // Prefix length in bits 4+.

  // Mask used to mask off two lower bits.
  static const int TWO_BIT_MASK = 3;

  // The current parsing state.
  int state = STATE_INITIAL;
  List<int> states = <int>[];

  /**
   * Stores tokenizer state between chunks.
   *
   * This state is stored when a chunk stops in the middle of a
   * token (string, numeral, boolean or null).
   *
   * The partial state is used to continue parsing on the next chunk.
   * The previous chunk is not retained, any data needed are stored in
   * this integer, or in the [buffer] field as a string-building buffer
   * or a [_NumberBuffer].
   *
   * Prefix state stored in [prefixState] as bits.
   *
   *            ..00 : No partial value (NO_PARTIAL).
   *
   *         ..00001 : Partial string, not inside escape.
   *         ..00101 : Partial string, after '\'.
   *     ..vvvv1dd01 : Partial \u escape.
   *                   The 'dd' bits (2-3) encode the number of hex digits seen.
   *                   Bits 5-16 encode the value of the hex digits seen so far.
   *
   *        ..0ddd10 : Partial numeral.
   *                   The `ddd` bits store the parts of in the numeral seen so
   *                   far, as the constants `NUM_*` defined above.
   *                   The characters of the numeral are stored in [buffer]
   *                   as a [_NumberBuffer].
   *
   *      ..0ddd0011 : Partial 'null' keyword.
   *      ..0ddd0111 : Partial 'true' keyword.
   *      ..0ddd1011 : Partial 'false' keyword.
   *      ..0ddd1111 : Partial UTF-8 BOM byte sequence ("\xEF\xBB\xBF").
   *                   For all keywords, the `ddd` bits encode the number
   *                   of letters seen.
   *                   The BOM byte sequence is only used by [_JsonUtf8Parser],
   *                   and only at the very beginning of input.
   */
  int partialState = NO_PARTIAL;

  /**
   * Extra data stored while parsing a primitive value.
   * May be set during parsing, always set at chunk end if a value is partial.
   *
   * May contain a string buffer while parsing strings.
   */
  dynamic buffer = null;

  /**
   * Push the current parse [state] on a stack.
   *
   * State is pushed when a new array or object literal starts,
   * so the parser can go back to the correct value when the literal ends.
   */
  void saveState(int state) {
    states.add(state);
  }

  /**
   * Restore a state pushed with [saveState].
   */
  int restoreState() {
    return states.removeLast(); // Throws if empty.
  }

  /**
   * Finalizes the parsing.
   *
   * Throws if the source read so far doesn't end up with a complete
   * parsed value. That means it must not be inside a list or object
   * literal, and any partial value read should also be a valid complete
   * value.
   *
   * The only valid partial state is a number that ends in a digit, and
   * only if the number is the entire JSON value being parsed
   * (otherwise it would be inside a list or object).
   * Such a number will be completed. Any other partial state is an error.
   */
  void close() {
    if (partialState != NO_PARTIAL) {
      int partialType = partialState & MASK_PARTIAL;
      if (partialType == PARTIAL_NUMERAL) {
        int numState = partialState & ~MASK_PARTIAL;
        // A partial number might be a valid number if we know it's done.
        // There is an unnecessary overhead if input is a single number,
        // but this is assumed to be rare.
        _NumberBuffer buffer = this.buffer;
        this.buffer = null;
        finishChunkNumber(numState, 0, 0, buffer);
      } else if (partialType == PARTIAL_STRING) {
        fail(chunkEnd, "Unterminated string");
      } else {
        assert(partialType == PARTIAL_KEYWORD);
        fail(chunkEnd); // Incomplete literal.
      }
    }
    if (state != STATE_END) {
      fail(chunkEnd);
    }
  }

  /**
   * Read out the result after successfully closing the parser.
   *
   * The parser is closed by calling [close] or calling [addSourceChunk] with
   * `true` as second (`isLast`) argument.
   */
  dynamic get result {
    return listener.result;
  }

  /** Sets the current source chunk. */
  void set chunk(T source);

  /**
   * Length of current chunk.
   *
   * The valid arguments to [getChar] are 0 .. `chunkEnd - 1`.
   */
  int get chunkEnd;

  /**
   * Returns the chunk itself.
   *
   * Only used by [fail] to include the chunk in the thrown [FormatException].
   */
  T get chunk;

  /**
   * Get character/code unit of current chunk.
   *
   * The [index] must be non-negative and less than `chunkEnd`.
   * In practice, [index] will be no smaller than the `start` argument passed
   * to [parse].
   */
  int getChar(int index);

  /**
   * Returns [true] if [getChar] is returning UTF16 code units.
   *
   * Otherwise it is expected that [getChar] is returning UTF8 bytes.
   */
  bool get isUtf16Input;

  /**
   * Copy ASCII characters from start to end of chunk into a list.
   *
   * Used for number buffer (always copies ASCII, so encoding is not important).
   */
  void copyCharsToList(int start, int end, Uint8List target, int offset);

  /**
   * Build a string using input code units.
   *
   * Creates a string buffer and enables adding characters and slices
   * to that buffer.
   * The buffer is stored in the [buffer] field. If the string is unterminated,
   * the same buffer is used to continue parsing in the next chunk.
   */
  void beginString();
  /**
   * Add single character code to string being built.
   *
   * Used for unparsed escape sequences.
   */
  void addCharToString(int charCode);

  /**
   * Adds slice of current chunk to string being built.
   *
   * The [start] positions is inclusive, [end] is exclusive.
   */
  void addSliceToString(int start, int end);

  /** Finalizes the string being built and returns it as a String. */
  String endString();

  /**
   * Extracts a literal string from a slice of the current chunk.
   *
   * No interpretation of the content is performed, except for converting
   * the source format to string.
   * This can be implemented more or less efficiently depending on the
   * underlying source.
   *
   * This is used for string literals that contain no escapes.
   *
   * The [bits] integer is an upper bound on the code point in the range
   * from `start` to `end`.
   * Usually found by doing bitwise or of all the values.
   * The function may choose to optimize depending on the value.
   */
  String getString(int start, int end, int bits);

  /**
   * Parse a slice of the current chunk as a number.
   *
   * Since integers have a maximal value, and we don't track the value
   * in the buffer, a sequence of digits can be either an int or a double.
   * The `num.parse` function does the right thing.
   *
   * The format is expected to be correct.
   */
  num parseNum(int start, int end) {
    const int asciiBits = 0x7f; // Number literals are ASCII only.
    return num.parse(getString(start, end, asciiBits));
  }

  /**
   * Parse a slice of the current chunk as a double.
   *
   * The format is expected to be correct.
   * This is used by [parseNumber] when the double value cannot be
   * built exactly during parsing.
   */
  double parseDouble(int start, int end) {
    const int asciiBits = 0x7f; // Double literals are ASCII only.
    return double.parse(getString(start, end, asciiBits));
  }

  /**
   * Continues parsing a partial value.
   */
  int parsePartial(int position) {
    if (position == chunkEnd) return position;
    int partialState = this.partialState;
    assert(partialState != NO_PARTIAL);
    int partialType = partialState & MASK_PARTIAL;
    this.partialState = NO_PARTIAL;
    partialState = partialState & ~MASK_PARTIAL;
    assert(partialType != 0);
    if (partialType == PARTIAL_STRING) {
      position = parsePartialString(position, partialState);
    } else if (partialType == PARTIAL_NUMERAL) {
      position = parsePartialNumber(position, partialState);
    } else if (partialType == PARTIAL_KEYWORD) {
      position = parsePartialKeyword(position, partialState);
    }
    return position;
  }

  /**
   * Parses the remainder of a number into the number buffer.
   *
   * Syntax is checked while pasing.
   * Starts at position, which is expected to be the start of the chunk,
   * and returns the index of the first non-number-literal character found,
   * or chunkEnd if the entire chunk is a valid number continuation.
   * Throws if a syntax error is detected.
   */
  int parsePartialNumber(int position, int state) {
    int start = position;
    // Primitive implementation, can be optimized.
    _NumberBuffer buffer = this.buffer;
    this.buffer = null;
    int end = chunkEnd;
    toBailout:
    {
      if (position == end) break toBailout;
      int char = getChar(position);
      int digit = char ^ CHAR_0;
      if (state == NUM_SIGN) {
        if (digit <= 9) {
          if (digit == 0) {
            state = NUM_ZERO;
          } else {
            state = NUM_DIGIT;
          }
          position++;
          if (position == end) break toBailout;
          char = getChar(position);
          digit = char ^ CHAR_0;
        } else {
          fail(position);
        }
      }
      if (state == NUM_ZERO) {
        // JSON does not allow insignificant leading zeros (e.g., "09").
        if (digit <= 9) fail(position);
        state = NUM_DIGIT;
      }
      while (state == NUM_DIGIT) {
        if (digit > 9) {
          if (char == DECIMALPOINT) {
            state = NUM_DOT;
          } else if ((char | 0x20) == CHAR_e) {
            state = NUM_E;
          } else {
            finishChunkNumber(state, start, position, buffer);
            return position;
          }
        }
        position++;
        if (position == end) break toBailout;
        char = getChar(position);
        digit = char ^ CHAR_0;
      }
      if (state == NUM_DOT) {
        if (digit > 9) fail(position);
        state = NUM_DOT_DIGIT;
      }
      while (state == NUM_DOT_DIGIT) {
        if (digit > 9) {
          if ((char | 0x20) == CHAR_e) {
            state = NUM_E;
          } else {
            finishChunkNumber(state, start, position, buffer);
            return position;
          }
        }
        position++;
        if (position == end) break toBailout;
        char = getChar(position);
        digit = char ^ CHAR_0;
      }
      if (state == NUM_E) {
        if (char == PLUS || char == MINUS) {
          state = NUM_E_SIGN;
          position++;
          if (position == end) break toBailout;
          char = getChar(position);
          digit = char ^ CHAR_0;
        }
      }
      assert(state >= NUM_E);
      while (digit <= 9) {
        state = NUM_E_DIGIT;
        position++;
        if (position == end) break toBailout;
        char = getChar(position);
        digit = char ^ CHAR_0;
      }
      finishChunkNumber(state, start, position, buffer);
      return position;
    }
    // Bailout code in case the current chunk ends while parsing the numeral.
    assert(position == end);
    continueChunkNumber(state, start, buffer);
    return chunkEnd;
  }

  /**
   * Continues parsing a partial string literal.
   *
   * Handles partial escapes and then hands the parsing off to
   * [parseStringToBuffer].
   */
  int parsePartialString(int position, int partialState) {
    if (partialState == STR_PLAIN) {
      return parseStringToBuffer(position);
    }
    if (partialState == STR_ESCAPE) {
      position = parseStringEscape(position);
      // parseStringEscape sets partialState if it sees the end.
      if (position == chunkEnd) return position;
      return parseStringToBuffer(position);
    }
    assert((partialState & STR_U) != 0);
    int value = partialState >> STR_U_VALUE_SHIFT;
    int count = (partialState >> STR_U_COUNT_SHIFT) & TWO_BIT_MASK;
    for (int i = count; i < 4; i++, position++) {
      if (position == chunkEnd) return chunkStringEscapeU(i, value);
      int char = getChar(position);
      int digit = parseHexDigit(char);
      if (digit < 0) fail(position, "Invalid hex digit");
      value = 16 * value + digit;
    }
    addCharToString(value);
    return parseStringToBuffer(position);
  }

  /**
   * Continues parsing a partial keyword.
   */
  int parsePartialKeyword(int position, int partialState) {
    int keywordType = partialState & KWD_TYPE_MASK;
    int count = partialState >> KWD_COUNT_SHIFT;
    int keywordTypeIndex = keywordType >> KWD_TYPE_SHIFT;
    String keyword =
        const ["null", "true", "false", "\xEF\xBB\xBF"][keywordTypeIndex];
    assert(count < keyword.length);
    do {
      if (position == chunkEnd) {
        this.partialState =
            PARTIAL_KEYWORD | keywordType | (count << KWD_COUNT_SHIFT);
        return chunkEnd;
      }
      int expectedChar = keyword.codeUnitAt(count);
      if (getChar(position) != expectedChar) {
        if (count == 0) {
          assert(keywordType == KWD_BOM);
          return position;
        }
        fail(position);
      }
      position++;
      count++;
    } while (count < keyword.length);
    if (keywordType == KWD_NULL) {
      listener.handleNull();
    } else if (keywordType != KWD_BOM) {
      listener.handleBool(keywordType == KWD_TRUE);
    }
    return position;
  }

  /** Convert hex-digit to its value. Returns -1 if char is not a hex digit. */
  int parseHexDigit(int char) {
    int digit = char ^ 0x30;
    if (digit <= 9) return digit;
    int letter = (char | 0x20) ^ 0x60;
    // values 1 .. 6 are 'a' through 'f'
    if (letter <= 6 && letter > 0) return letter + 9;
    return -1;
  }

  /**
   * Parses the current chunk as a chunk of JSON.
   *
   * Starts parsing at [position] and continues until [chunkEnd].
   * Continues parsing where the previous chunk (if any) ended.
   */
  @pragma('vm:unsafe:no-interrupts')
  @pragma('vm:unsafe:no-bounds-checks')
  void parse(int position) {
    int length = chunkEnd;
    if (partialState != NO_PARTIAL) {
      position = parsePartial(position);
      if (position == length) return;
    }
    final charAttributes = _characterAttributes;

    int state = this.state;
    outer:
    while (position < length) {
      int char = 0;
      do {
        char = getChar(position);
        if (isUtf16Input && char > 0xFF) {
          break;
        }
        if ((charAttributes.codeUnitAt(char) & CHAR_WHITESPACE) == 0) {
          break;
        }
        position++;
        if (position >= length) {
          break outer;
        }
      } while (true);

      switch (char) {
        case QUOTE:
          if ((state & ALLOW_STRING_MASK) != 0) fail(position);
          state |= VALUE_READ_BITS;
          position = parseString(position + 1);
          break;
        case LBRACKET:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          listener.beginArray();
          saveState(state);
          state = STATE_ARRAY_EMPTY;
          position++;
          break;
        case LBRACE:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          listener.beginObject();
          saveState(state);
          state = STATE_OBJECT_EMPTY;
          position++;
          break;
        case CHAR_n:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          state |= VALUE_READ_BITS;
          position = parseNull(position);
          break;
        case CHAR_f:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          state |= VALUE_READ_BITS;
          position = parseFalse(position);
          break;
        case CHAR_t:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          state |= VALUE_READ_BITS;
          position = parseTrue(position);
          break;
        case COLON:
          if (state != STATE_OBJECT_KEY) fail(position);
          listener.propertyName();
          state = STATE_OBJECT_COLON;
          position++;
          break;
        case COMMA:
          if (state == STATE_OBJECT_VALUE) {
            listener.propertyValue();
            state = STATE_OBJECT_COMMA;
            position++;
          } else if (state == STATE_ARRAY_VALUE) {
            listener.arrayElement();
            state = STATE_ARRAY_COMMA;
            position++;
          } else {
            fail(position);
          }
          break;
        case RBRACKET:
          if (state == STATE_ARRAY_EMPTY) {
            listener.endArray();
          } else if (state == STATE_ARRAY_VALUE) {
            listener.arrayElement();
            listener.endArray();
          } else {
            fail(position);
          }
          state = restoreState() | VALUE_READ_BITS;
          position++;
          break;
        case RBRACE:
          if (state == STATE_OBJECT_EMPTY) {
            listener.endObject();
          } else if (state == STATE_OBJECT_VALUE) {
            listener.propertyValue();
            listener.endObject();
          } else {
            fail(position);
          }
          state = restoreState() | VALUE_READ_BITS;
          position++;
          break;
        default:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          state |= VALUE_READ_BITS;
          position = parseNumber(char, position);
          break;
      }
    }
    this.state = state;
  }

  /**
   * Parses a "true" literal starting at [position].
   *
   * The character `source[position]` must be "t".
   */
  int parseTrue(int position) {
    assert(getChar(position) == CHAR_t);
    if (chunkEnd < position + 4) {
      return parseKeywordPrefix(position, "true", KWD_TRUE);
    }
    if (getChar(position + 1) != CHAR_r ||
        getChar(position + 2) != CHAR_u ||
        getChar(position + 3) != CHAR_e) {
      fail(position);
    }
    listener.handleBool(true);
    return position + 4;
  }

  /**
   * Parses a "false" literal starting at [position].
   *
   * The character `source[position]` must be "f".
   */
  int parseFalse(int position) {
    assert(getChar(position) == CHAR_f);
    if (chunkEnd < position + 5) {
      return parseKeywordPrefix(position, "false", KWD_FALSE);
    }
    if (getChar(position + 1) != CHAR_a ||
        getChar(position + 2) != CHAR_l ||
        getChar(position + 3) != CHAR_s ||
        getChar(position + 4) != CHAR_e) {
      fail(position);
    }
    listener.handleBool(false);
    return position + 5;
  }

  /**
   * Parses a "null" literal starting at [position].
   *
   * The character `source[position]` must be "n".
   */
  int parseNull(int position) {
    assert(getChar(position) == CHAR_n);
    if (chunkEnd < position + 4) {
      return parseKeywordPrefix(position, "null", KWD_NULL);
    }
    if (getChar(position + 1) != CHAR_u ||
        getChar(position + 2) != CHAR_l ||
        getChar(position + 3) != CHAR_l) {
      fail(position);
    }
    listener.handleNull();
    return position + 4;
  }

  int parseKeywordPrefix(int position, String chars, int type) {
    assert(getChar(position) == chars.codeUnitAt(0));
    int length = chunkEnd;
    int start = position;
    int count = 1;
    while (++position < length) {
      int char = getChar(position);
      if (char != chars.codeUnitAt(count)) fail(start);
      count++;
    }
    this.partialState = PARTIAL_KEYWORD | type | (count << KWD_COUNT_SHIFT);
    return length;
  }

  static const int CHAR_SIMPLE_STRING_END = 1;
  static const int CHAR_WHITESPACE = 2;

  /**
   * [_characterAttributes] string was generated using the following code:
   *
   * ```
   * int $(String ch) => ch.codeUnitAt(0);
   * final list = Uint8List(256);
   * for (var i = 0; i < $(' '); i++) {
   *   list[i] |= CHAR_SIMPLE_STRING_END;
   * }
   * list[$('"')] |= CHAR_SIMPLE_STRING_END;
   * list[$('\\')] |= CHAR_SIMPLE_STRING_END;
   * list[$(' ')] |= CHAR_WHITESPACE;
   * list[$('\r')] |= CHAR_WHITESPACE;
   * list[$('\n')] |= CHAR_WHITESPACE;
   * list[$('\t')] |= CHAR_WHITESPACE;
   * for (var i = 0; i < 256; i += 64) {
   *   print("'${String.fromCharCodes([
   *         for (var v in list.skip(i).take(64)) v + $(' '),
   *       ])}'");
   * }
   * ```
   */
  static const String _characterAttributes =
      '!!!!!!!!!##!!#!!!!!!!!!!!!!!!!!!" !                             '
      '                            !                                   '
      '                                                                '
      '                                                                ';

  /**
   * Parses a string value.
   *
   * Initial [position] is right after the initial quote.
   * Returned position right after the final quote.
   */
  @pragma('vm:unsafe:no-interrupts')
  @pragma('vm:unsafe:no-bounds-checks')
  int parseString(int position) {
    final charAttributes = _characterAttributes;

    // Format: '"'([^\x00-\x1f\\\"]|'\\'[bfnrt/\\"])*'"'
    // Initial position is right after first '"'.
    int start = position;
    int end = chunkEnd;
    int bits = 0;
    int char = 0;
    if (position < end) {
      do {
        // Caveat: do not combine the following two lines together. It helps
        // compiler to generate better code (it currently can't reorder operations
        // to reduce register pressure).
        char = getChar(position);
        position++;
        bits |= char; // Includes final '"', but that never matters.
        if (isUtf16Input && char > 0xFF) {
          continue;
        }
        if ((charAttributes.codeUnitAt(char) & CHAR_SIMPLE_STRING_END) != 0) {
          break;
        }
      } while (position < end);
      if (char == QUOTE) {
        int sliceEnd = position - 1;
        listener.handleString(getString(start, sliceEnd, bits));
        return sliceEnd + 1;
      }
      if (char == BACKSLASH) {
        int sliceEnd = position - 1;
        beginString();
        if (start < sliceEnd) addSliceToString(start, sliceEnd);
        return parseStringToBuffer(sliceEnd);
      }
      if (char < SPACE) {
        fail(position - 1, "Control character in string");
      }
    }
    beginString();
    if (start < end) addSliceToString(start, end);
    return chunkString(STR_PLAIN);
  }

  /**
   * Sets up a partial string state.
   *
   * The state is either not inside an escape, or right after a backslash.
   * For partial strings ending inside a Unicode escape, use
   * [chunkStringEscapeU].
   */
  int chunkString(int stringState) {
    partialState = PARTIAL_STRING | stringState;
    return chunkEnd;
  }

  /**
   * Sets up a partial string state for a partially parsed Unicode escape.
   *
   * The partial string state includes the current [buffer] and the
   * number of hex digits of the Unicode seen so far (e.g., for `"\u30')
   * the state knows that two digits have been seen, and what their value is.
   *
   * Returns [chunkEnd] so it can be used as part of a return statement.
   */
  int chunkStringEscapeU(int count, int value) {
    partialState = PARTIAL_STRING |
        STR_U |
        (count << STR_U_COUNT_SHIFT) |
        (value << STR_U_VALUE_SHIFT);
    return chunkEnd;
  }

  /**
   * Parses the remainder of a string literal into a buffer.
   *
   * The buffer is stored in [buffer] and its underlying format depends on
   * the input chunk type. For example UTF-8 decoding happens in the
   * buffer, not in the parser, since all significant JSON characters are ASCII.
   *
   * This function scans through the string literal for escapes, and copies
   * slices of non-escape characters using [addSliceToString].
   */
  @pragma('vm:unsafe:no-interrupts')
  @pragma('vm:unsafe:no-bounds-checks')
  int parseStringToBuffer(int position) {
    final charAttributes = _characterAttributes;

    int end = chunkEnd;
    int start = position;
    while (true) {
      if (position == end) {
        if (position > start) {
          addSliceToString(start, position);
        }
        return chunkString(STR_PLAIN);
      }

      int char = 0;
      do {
        char = getChar(position);
        position++;
        if (isUtf16Input && char > 0xFF) {
          continue;
        }
        if ((charAttributes.codeUnitAt(char) & CHAR_SIMPLE_STRING_END) != 0) {
          break;
        }
      } while (position < end);

      if (char < SPACE) {
        fail(position - 1); // Control character in string.
      }

      if (char == QUOTE) {
        int quotePosition = position - 1;
        if (quotePosition > start) {
          addSliceToString(start, quotePosition);
        }
        listener.handleString(endString());
        return position;
      }

      if (char != BACKSLASH) {
        continue;
      }

      // Handle escape.
      if (position - 1 > start) {
        addSliceToString(start, position - 1);
      }

      if (position == end) return chunkString(STR_ESCAPE);
      position = parseStringEscape(position);
      if (position == end) return position;
      start = position;
    }
    return -1; // UNREACHABLE.
  }

  /**
   * Parse a string escape.
   *
   * Position is right after the initial backslash.
   * The following escape is parsed into a character code which is added to
   * the current string buffer using [addCharToString].
   *
   * Returns position after the last character of the escape.
   */
  int parseStringEscape(int position) {
    int char = getChar(position++);
    int length = chunkEnd;
    switch (char) {
      case CHAR_b:
        char = BACKSPACE;
        break;
      case CHAR_f:
        char = FORM_FEED;
        break;
      case CHAR_n:
        char = NEWLINE;
        break;
      case CHAR_r:
        char = CARRIAGE_RETURN;
        break;
      case CHAR_t:
        char = TAB;
        break;
      case SLASH:
      case BACKSLASH:
      case QUOTE:
        break;
      case CHAR_u:
        int hexStart = position - 1;
        int value = 0;
        for (int i = 0; i < 4; i++) {
          if (position == length) return chunkStringEscapeU(i, value);
          char = getChar(position++);
          int digit = char ^ 0x30;
          value *= 16;
          if (digit <= 9) {
            value += digit;
          } else {
            digit = (char | 0x20) - CHAR_a;
            if (digit < 0 || digit > 5) {
              fail(hexStart, "Invalid unicode escape");
            }
            value += digit + 10;
          }
        }
        char = value;
        break;
      default:
        if (char < SPACE) fail(position, "Control character in string");
        fail(position, "Unrecognized string escape");
    }
    addCharToString(char);
    if (position == length) return chunkString(STR_PLAIN);
    return position;
  }

  /// Sets up a partial numeral state.
  /// Returns chunkEnd to allow easy one-line bailout tests.
  int beginChunkNumber(int state, int start) {
    int end = chunkEnd;
    int length = end - start;
    var buffer = new _NumberBuffer(length);
    copyCharsToList(start, end, buffer.list, 0);
    buffer.length = length;
    this.buffer = buffer;
    this.partialState = PARTIAL_NUMERAL | state;
    return end;
  }

  void addNumberChunk(_NumberBuffer buffer, int start, int end, int overhead) {
    int length = end - start;
    int count = buffer.length;
    int newCount = count + length;
    int newCapacity = newCount + overhead;
    buffer.ensureCapacity(newCapacity);
    copyCharsToList(start, end, buffer.list, count);
    buffer.length = newCount;
  }

  // Continues an already chunked number across an entire chunk.
  int continueChunkNumber(int state, int start, _NumberBuffer buffer) {
    int end = chunkEnd;
    addNumberChunk(buffer, start, end, _NumberBuffer.defaultOverhead);
    this.buffer = buffer;
    this.partialState = PARTIAL_NUMERAL | state;
    return end;
  }

  int finishChunkNumber(int state, int start, int end, _NumberBuffer buffer) {
    if (state == NUM_ZERO) {
      listener.handleNumber(0);
      return end;
    }
    if (end > start) {
      addNumberChunk(buffer, start, end, 0);
    }
    if (state == NUM_DIGIT) {
      num value = buffer.parseNum();
      listener.handleNumber(value);
    } else if (state == NUM_DOT_DIGIT || state == NUM_E_DIGIT) {
      listener.handleNumber(buffer.parseDouble());
    } else {
      fail(chunkEnd, "Unterminated number literal");
    }
    return end;
  }

  int parseNumber(int char, int position) {
    // Also called on any unexpected character.
    // Format:
    //  '-'?('0'|[1-9][0-9]*)('.'[0-9]+)?([eE][+-]?[0-9]+)?
    int start = position;
    int length = chunkEnd;
    // Collects an int value while parsing. Used for both an integer literal,
    // and the exponent part of a double literal.
    // Stored as negative to ensure we can represent -2^63.
    int intValue = 0;
    double doubleValue = 0.0; // Collect double value while parsing.
    // 1 if there is no leading -, -1 if there is.
    int sign = 1;
    bool isDouble = false;
    // Break this block when the end of the number literal is reached.
    // At that time, position points to the next character, and isDouble
    // is set if the literal contains a decimal point or an exponential.
    if (char == MINUS) {
      sign = -1;
      position++;
      if (position == length) return beginChunkNumber(NUM_SIGN, start);
      char = getChar(position);
    }
    int digit = char ^ CHAR_0;
    if (digit > 9) {
      if (sign < 0) {
        fail(position, "Missing expected digit");
      } else {
        // If it doesn't even start out as a numeral.
        fail(position);
      }
    }
    if (digit == 0) {
      position++;
      if (position == length) return beginChunkNumber(NUM_ZERO, start);
      char = getChar(position);
      digit = char ^ CHAR_0;
      // If starting with zero, next character must not be digit.
      if (digit <= 9) fail(position);
    } else {
      int digitCount = 0;
      do {
        if (digitCount >= 18) {
          // Check for overflow.
          // Is 1 if digit is 8 or 9 and sign == 0, or digit is 9 and sign < 0;
          int highDigit = digit >> 3;
          if (sign < 0) highDigit &= digit;
          if (digitCount == 19 || intValue - highDigit < -922337203685477580) {
            isDouble = true;
            // Big value that we know is not trusted to be exact later,
            // forcing reparsing using `double.parse`.
            doubleValue = 9223372036854775808.0;
          }
        }
        intValue = 10 * intValue - digit;
        digitCount++;
        position++;
        if (position == length) return beginChunkNumber(NUM_DIGIT, start);
        char = getChar(position);
        digit = char ^ CHAR_0;
      } while (digit <= 9);
    }
    if (char == DECIMALPOINT) {
      if (!isDouble) {
        isDouble = true;
        doubleValue = (intValue == 0) ? 0.0 : -intValue.toDouble();
      }
      intValue = 0;
      position++;
      if (position == length) return beginChunkNumber(NUM_DOT, start);
      char = getChar(position);
      digit = char ^ CHAR_0;
      if (digit > 9) fail(position);
      do {
        doubleValue = 10.0 * doubleValue + digit;
        intValue -= 1;
        position++;
        if (position == length) return beginChunkNumber(NUM_DOT_DIGIT, start);
        char = getChar(position);
        digit = char ^ CHAR_0;
      } while (digit <= 9);
    }
    if ((char | 0x20) == CHAR_e) {
      if (!isDouble) {
        isDouble = true;
        doubleValue = (intValue == 0) ? 0.0 : -intValue.toDouble();
        intValue = 0;
      }
      position++;
      if (position == length) return beginChunkNumber(NUM_E, start);
      char = getChar(position);
      int expSign = 1;
      int exponent = 0;
      if (((char + 1) | 2) == 0x2e /*+ or -*/) {
        expSign = 0x2C - char; // -1 for MINUS, +1 for PLUS
        position++;
        if (position == length) return beginChunkNumber(NUM_E_SIGN, start);
        char = getChar(position);
      }
      digit = char ^ CHAR_0;
      if (digit > 9) {
        fail(position, "Missing expected digit");
      }
      bool exponentOverflow = false;
      do {
        exponent = 10 * exponent + digit;
        if (exponent > 400) exponentOverflow = true;
        position++;
        if (position == length) return beginChunkNumber(NUM_E_DIGIT, start);
        char = getChar(position);
        digit = char ^ CHAR_0;
      } while (digit <= 9);
      if (exponentOverflow) {
        if (doubleValue == 0.0 || expSign < 0) {
          listener.handleNumber(sign < 0 ? -0.0 : 0.0);
        } else {
          listener.handleNumber(
              sign < 0 ? double.negativeInfinity : double.infinity);
        }
        return position;
      }
      intValue += expSign * exponent;
    }
    if (!isDouble) {
      int bitFlag = -(sign + 1) >> 1; // 0 if sign == -1, -1 if sign == 1
      // Negate if bitFlag is -1 by doing ~intValue + 1
      listener.handleNumber((intValue ^ bitFlag) - bitFlag);
      return position;
    }
    // Double values at or above this value (2 ** 53) may have lost precision.
    // Only trust results that are below this value.
    const double maxExactDouble = 9007199254740992.0;
    if (doubleValue < maxExactDouble) {
      int exponent = intValue;
      double signedMantissa = doubleValue * sign;
      if (exponent >= -22) {
        if (exponent < 0) {
          listener.handleNumber(signedMantissa / POWERS_OF_TEN[-exponent]);
          return position;
        }
        if (exponent == 0) {
          listener.handleNumber(signedMantissa);
          return position;
        }
        if (exponent <= 22) {
          listener.handleNumber(signedMantissa * POWERS_OF_TEN[exponent]);
          return position;
        }
      }
    }
    // If the value is outside the range +/-maxExactDouble or
    // exponent is outside the range +/-22, then we can't trust simple double
    // arithmetic to get the exact result, so we use the system double parsing.
    listener.handleNumber(parseDouble(start, position));
    return position;
  }

  Never fail(int position, [String? message]) {
    if (message == null) {
      message = "Unexpected character";
      if (position == chunkEnd) message = "Unexpected end of input";
    }
    throw new FormatException(message, chunk, position);
  }
}

/**
 * Chunked JSON parser that parses [String] chunks.
 */
class _JsonStringParser extends _JsonParserWithListener
    with _ChunkedJsonParser<String> {
  String chunk = '';
  int chunkEnd = 0;

  _JsonStringParser(_JsonListener listener) : super(listener);

  @pragma('vm:prefer-inline')
  bool get isUtf16Input => true;

  @pragma('vm:prefer-inline')
  int getChar(int position) => chunk.codeUnitAt(position);

  String getString(int start, int end, int bits) {
    return chunk.substring(start, end);
  }

  void beginString() {
    this.buffer = new StringBuffer();
  }

  void addSliceToString(int start, int end) {
    StringBuffer buffer = this.buffer;
    buffer.write(chunk.substring(start, end));
  }

  void addCharToString(int charCode) {
    StringBuffer buffer = this.buffer;
    buffer.writeCharCode(charCode);
  }

  String endString() {
    StringBuffer buffer = this.buffer;
    this.buffer = null;
    return buffer.toString();
  }

  void copyCharsToList(int start, int end, Uint8List target, int offset) {
    int length = end - start;
    for (int i = 0; i < length; i++) {
      target[offset + i] = chunk.codeUnitAt(start + i);
    }
  }

  double parseDouble(int start, int end) {
    return _parseDouble(chunk, start, end);
  }
}

@patch
class JsonDecoder {
  @patch
  StringConversionSink startChunkedConversion(Sink<Object?> sink) {
    return new _JsonStringDecoderSink(this._reviver, sink);
  }
}

/**
 * Implements the chunked conversion from a JSON string to its corresponding
 * object.
 *
 * The sink only creates one object, but its input can be chunked.
 */
class _JsonStringDecoderSink extends StringConversionSinkBase {
  _JsonStringParser _parser;
  final Object? Function(Object? key, Object? value)? _reviver;
  final Sink<Object?> _sink;

  _JsonStringDecoderSink(this._reviver, this._sink)
      : _parser = _createParser(_reviver);

  static _JsonStringParser _createParser(
      Object? Function(Object? key, Object? value)? reviver) {
    return new _JsonStringParser(new _JsonListener(reviver));
  }

  void addSlice(String chunk, int start, int end, bool isLast) {
    _parser.chunk = chunk;
    _parser.chunkEnd = end;
    _parser.parse(start);
    if (isLast) _parser.close();
  }

  void add(String chunk) {
    addSlice(chunk, 0, chunk.length, false);
  }

  void close() {
    _parser.close();
    var decoded = _parser.result;
    _sink.add(decoded);
    _sink.close();
  }

  ByteConversionSink asUtf8Sink(bool allowMalformed) {
    return new _JsonUtf8DecoderSink(_reviver, _sink, allowMalformed);
  }
}

/**
 * Chunked JSON parser that parses UTF-8 chunks.
 */
class _JsonUtf8Parser extends _JsonParserWithListener
    with _ChunkedJsonParser<Uint8List> {
  static final Uint8List emptyChunk = Uint8List(0);

  final _Utf8Decoder decoder;
  Uint8List chunk = emptyChunk;
  int chunkEnd = 0;

  _JsonUtf8Parser(_JsonListener listener, bool allowMalformed)
      : decoder = new _Utf8Decoder(allowMalformed),
        super(listener) {
    // Starts out checking for an optional BOM (KWD_BOM, count = 0).
    partialState =
        _ChunkedJsonParser.PARTIAL_KEYWORD | _ChunkedJsonParser.KWD_BOM;
  }

  void parseChunk(List<int> value, int start, int end) {
    if (value is Uint8List) {
      chunk = value;
    } else {
      final bytes = Uint8List(end - start);
      bytes.setRange(0, bytes.length, value, start);
      end = bytes.length;
      start = 0;
      chunk = bytes;
    }
    chunkEnd = end;
    parse(start);
  }

  @pragma('vm:prefer-inline')
  bool get isUtf16Input => false;

  @pragma('vm:prefer-inline')
  int getChar(int position) => chunk[position];

  String getString(int start, int end, int bits) {
    const int maxAsciiChar = 0x7f;
    if (bits <= maxAsciiChar) {
      return createOneByteStringFromCharacters(chunk, start, end);
    }
    beginString();
    if (start < end) addSliceToString(start, end);
    String result = endString();
    return result;
  }

  void beginString() {
    decoder.reset();
    this.buffer = new StringBuffer();
  }

  void addSliceToString(int start, int end) {
    final StringBuffer buffer = this.buffer;
    buffer.write(decoder.convertChunked(chunk, start, end));
  }

  void addCharToString(int charCode) {
    final StringBuffer buffer = this.buffer;
    decoder.flush(buffer);
    buffer.writeCharCode(charCode);
  }

  String endString() {
    final StringBuffer buffer = this.buffer;
    decoder.flush(buffer);
    this.buffer = null;
    return buffer.toString();
  }

  void copyCharsToList(int start, int end, Uint8List target, int offset) {
    int length = end - start;
    target.setRange(offset, offset + length, chunk, start);
  }

  double parseDouble(int start, int end) {
    String string = getString(start, end, 0x7f);
    return _parseDouble(string, 0, string.length);
  }
}

@pragma("vm:external-name", "Double_parse")
external double _parseDouble(String source, int start, int end);

/**
 * Implements the chunked conversion from a UTF-8 encoding of JSON
 * to its corresponding object.
 */
class _JsonUtf8DecoderSink extends ByteConversionSink {
  final _JsonUtf8Parser _parser;
  final Sink<Object?> _sink;

  _JsonUtf8DecoderSink(reviver, this._sink, bool allowMalformed)
      : _parser = _createParser(reviver, allowMalformed);

  static _JsonUtf8Parser _createParser(
      Object? Function(Object? key, Object? value)? reviver,
      bool allowMalformed) {
    return new _JsonUtf8Parser(new _JsonListener(reviver), allowMalformed);
  }

  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    _addChunk(chunk, start, end);
    if (isLast) close();
  }

  void add(List<int> chunk) {
    _addChunk(chunk, 0, chunk.length);
  }

  void _addChunk(List<int> chunk, int start, int end) {
    _parser.parseChunk(chunk, start, end);
  }

  void close() {
    _parser.close();
    var decoded = _parser.result;
    _sink.add(decoded);
    _sink.close();
  }
}

@patch
class _Utf8Decoder {
  /// Flags indicating presence of the various kinds of bytes in the input.
  int _scanFlags = 0;

  /// How many bytes of the BOM have been read so far. Set to -1 when the BOM
  /// has been skipped (or was not present).
  int _bomIndex = 0;

  // Table for the scanning phase, which quickly scans through the input.
  //
  // Each input byte is looked up in the table, providing a size and some flags.
  // The sizes are summed, and the flags are or'ed together.
  //
  // The resulting size and flags indicate:
  // A) How many UTF-16 code units will be emitted by the decoding of this
  //    input. This can be used to allocate a string of the correct length up
  //    front.
  // B) Which decoder and resulting string representation is appropriate. There
  //    are three cases:
  //    1) Pure ASCII (flags == 0): The input can simply be put into a
  //       OneByteString without further decoding.
  //    2) Latin1 (flags == (flagLatin1 | flagExtension)): The result can be
  //       represented by a OneByteString, and the decoder can assume that only
  //       Latin1 characters are present.
  //    3) Arbitrary input (otherwise): Needs a full-featured decoder. Output
  //       can be represented by a TwoByteString.

  static const int sizeMask = 0x03;
  static const int flagsMask = 0x3C;

  static const int flagExtension = 1 << 2;
  static const int flagLatin1 = 1 << 3;
  static const int flagNonLatin1 = 1 << 4;
  static const int flagIllegal = 1 << 5;

  // ASCII     'A' = 64 + (1);
  // Extension 'D' = 64 + (0 | flagExtension);
  // Latin1    'I' = 64 + (1 | flagLatin1);
  // BMP       'Q' = 64 + (1 | flagNonLatin1);
  // Non-BMP   'R' = 64 + (2 | flagNonLatin1);
  // Illegal   'a' = 64 + (1 | flagIllegal);
  // Illegal   'b' = 64 + (2 | flagIllegal);
  static const String scanTable = ""
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 00-1F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 20-3F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 40-5F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 60-7F
      "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD" // 80-9F
      "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD" // A0-BF
      "aaIIQQQQQQQQQQQQQQQQQQQQQQQQQQQQ" // C0-DF
      "QQQQQQQQQQQQQQQQRRRRRbbbbbbbbbbb" // E0-FF
      ;

  /// Max chunk to scan at a time.
  ///
  /// Avoids staying away from safepoints too long.
  /// The Utf8ScanInstr relies on this being small enough to ensure the
  /// decoded length stays within Smi range.
  static const int scanChunkSize = 65536;

  /// Reset the decoder to a state where it is ready to decode a new string but
  /// will not skip a leading BOM. Used by the fused UTF-8 / JSON decoder.
  void reset() {
    _state = initial;
    _bomIndex = -1;
  }

  @pragma("vm:prefer-inline")
  int scan(Uint8List bytes, int start, int end) {
    // Assumes 0 <= start <= end <= bytes.length
    int size = 0;
    _scanFlags = 0;
    int localStart = start;
    while (end - localStart > scanChunkSize) {
      int localEnd = localStart + scanChunkSize;
      size += _scan(bytes, localStart, localEnd, scanTable);
      localStart = localEnd;
    }
    size += _scan(bytes, localStart, end, scanTable);
    return size;
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  int _scan(Uint8List bytes, int start, int end, String scanTable) {
    int size = 0;
    int flags = 0;
    for (int i = start; i < end; i++) {
      int t = scanTable.codeUnitAt(bytes[i]);
      size += t & sizeMask;
      flags |= t;
    }
    _scanFlags |= flags & flagsMask;
    return size;
  }

  // The VM decoder handles BOM explicitly instead of via the state machine.
  @patch
  _Utf8Decoder(this.allowMalformed) : _state = initial;

  @patch
  String convertSingle(List<int> codeUnits, int start, int? maybeEnd) {
    int end = RangeError.checkValidRange(start, maybeEnd, codeUnits.length);

    // Have bytes as Uint8List.
    Uint8List bytes;
    int errorOffset;
    if (codeUnits is Uint8List) {
      bytes = unsafeCast<Uint8List>(codeUnits);
      errorOffset = 0;
    } else {
      bytes = _makeUint8List(codeUnits, start, end);
      errorOffset = start;
      end -= start;
      start = 0;
    }

    // Skip initial BOM.
    start = skipBomSingle(bytes, start, end);

    // Special case empty input.
    if (start == end) return "";

    // Scan input to determine size and appropriate decoder.
    int size = scan(bytes, start, end);
    int flags = _scanFlags;

    if (flags == 0) {
      // Pure ASCII.
      assert(size == end - start);
      String result = allocateOneByteString(size);
      copyRangeFromUint8ListToOneByteString(bytes, result, start, 0, size);
      return result;
    }

    String result;
    if (flags == (flagLatin1 | flagExtension)) {
      // Latin1.
      result = decode8(bytes, start, end, size);
    } else {
      // Arbitrary Unicode.
      result = decode16(bytes, start, end, size);
    }
    if (_state == accept) {
      return result;
    }

    if (!allowMalformed) {
      if (!isErrorState(_state)) {
        // Unfinished sequence.
        _state = errorUnfinished;
        _charOrIndex = end;
      }
      final String message = errorDescription(_state);
      throw FormatException(message, codeUnits, errorOffset + _charOrIndex);
    }

    // Start over on slow path.
    _state = initial;
    result = decodeGeneral(bytes, start, end, true);
    assert(!isErrorState(_state));
    return result;
  }

  @patch
  String convertChunked(List<int> codeUnits, int start, int? maybeEnd) {
    int end = RangeError.checkValidRange(start, maybeEnd, codeUnits.length);

    // Have bytes as Uint8List.
    Uint8List bytes;
    int errorOffset;
    if (codeUnits is Uint8List) {
      bytes = unsafeCast<Uint8List>(codeUnits);
      errorOffset = 0;
    } else {
      bytes = _makeUint8List(codeUnits, start, end);
      errorOffset = start;
      end -= start;
      start = 0;
    }

    // Skip initial BOM.
    start = skipBomChunked(bytes, start, end);

    // Special case empty input.
    if (start == end) return "";

    // Scan input to determine size and appropriate decoder.
    int size = scan(bytes, start, end);
    int flags = _scanFlags;

    // Adjust scan flags and size based on carry-over state.
    switch (_state) {
      case IA:
        break;
      case X1:
        flags |= _charOrIndex < (0x100 >> 6) ? flagLatin1 : flagNonLatin1;
        if (end - start >= 1) {
          size += _charOrIndex < (0x10000 >> 6) ? 1 : 2;
        }
        break;
      case X2:
        flags |= flagNonLatin1;
        if (end - start >= 2) {
          size += _charOrIndex < (0x10000 >> 12) ? 1 : 2;
        }
        break;
      case TO:
      case TS:
        flags |= flagNonLatin1;
        if (end - start >= 2) size += 1;
        break;
      case X3:
      case QO:
      case QR:
        flags |= flagNonLatin1;
        if (end - start >= 3) size += 2;
        break;
    }

    if (flags == 0) {
      // Pure ASCII.
      assert(_state == accept);
      assert(size == end - start);
      String result = allocateOneByteString(size);
      copyRangeFromUint8ListToOneByteString(bytes, result, start, 0, size);
      return result;
    }

    // Do not include any final, incomplete character in size.
    int extensionCount = 0;
    int i = end - 1;
    while (i >= start && (bytes[i] & 0xC0) == 0x80) {
      extensionCount++;
      i--;
    }
    if (i >= start && bytes[i] >= ((~0x3F >> extensionCount) & 0xFF)) {
      size -= bytes[i] >= 0xF0 ? 2 : 1;
    }

    final int carryOverState = _state;
    final int carryOverChar = _charOrIndex;
    String result;
    if (flags == (flagLatin1 | flagExtension)) {
      // Latin1.
      result = decode8(bytes, start, end, size);
    } else {
      // Arbitrary Unicode.
      result = decode16(bytes, start, end, size);
    }
    if (!isErrorState(_state)) {
      return result;
    }
    assert(_bomIndex == -1);

    if (!allowMalformed) {
      final String message = errorDescription(_state);
      _state = initial; // Ready for more input.
      throw FormatException(message, codeUnits, errorOffset + _charOrIndex);
    }

    // Start over on slow path.
    _state = carryOverState;
    _charOrIndex = carryOverChar;
    result = decodeGeneral(bytes, start, end, false);
    assert(!isErrorState(_state));
    return result;
  }

  @pragma("vm:prefer-inline")
  int skipBomSingle(Uint8List bytes, int start, int end) {
    if (end - start >= 3 &&
        bytes[start] == 0xEF &&
        bytes[start + 1] == 0xBB &&
        bytes[start + 2] == 0xBF) {
      return start + 3;
    }
    return start;
  }

  @pragma("vm:prefer-inline")
  int skipBomChunked(Uint8List bytes, int start, int end) {
    assert(start <= end);
    int bomIndex = _bomIndex;
    // Already skipped?
    if (bomIndex == -1) return start;

    const bomValues = <int>[0xEF, 0xBB, 0xBF];
    int i = start;
    while (bomIndex < 3) {
      if (i == end) {
        // Unfinished BOM.
        _bomIndex = bomIndex;
        return start;
      }
      if (bytes[i++] != bomValues[bomIndex++]) {
        // No BOM.
        _bomIndex = -1;
        return start;
      }
    }
    // Complete BOM.
    _bomIndex = -1;
    _state = initial;
    return i;
  }

  String decode8(Uint8List bytes, int start, int end, int size) {
    assert(start < end);
    String result = allocateOneByteString(size);
    int i = start;
    int j = 0;
    if (_state == X1) {
      // Half-way though 2-byte sequence
      assert(_charOrIndex == 2 || _charOrIndex == 3);
      final int e = bytes[i++] ^ 0x80;
      if (e >= 0x40) {
        _state = errorMissingExtension;
        _charOrIndex = i - 1;
        return "";
      }
      writeIntoOneByteString(result, j++, (_charOrIndex << 6) | e);
      _state = accept;
    }
    assert(_state == accept);
    while (i < end) {
      int byte = bytes[i++];
      if (byte >= 0x80) {
        if (byte < 0xC0) {
          _state = errorUnexpectedExtension;
          _charOrIndex = i - 1;
          return "";
        }
        assert(byte == 0xC2 || byte == 0xC3);
        if (i == end) {
          _state = X1;
          _charOrIndex = byte & 0x1F;
          break;
        }
        final int e = bytes[i++] ^ 0x80;
        if (e >= 0x40) {
          _state = errorMissingExtension;
          _charOrIndex = i - 1;
          return "";
        }
        byte = (byte << 6) | e;
      }
      writeIntoOneByteString(result, j++, byte);
    }
    // Output size must match, unless we are doing single conversion and are
    // inside an unfinished sequence (which will trigger an error later).
    assert(_bomIndex == 0 && _state != accept
        ? (j == size - 1 || j == size - 2)
        : (j == size));
    return result;
  }

  String decode16(Uint8List bytes, int start, int end, int size) {
    assert(start < end);
    final String typeTable = _Utf8Decoder.typeTable;
    final String transitionTable = _Utf8Decoder.transitionTable;
    String result = allocateTwoByteString(size);
    int i = start;
    int j = 0;
    int state = _state;
    int char;

    // First byte
    assert(!isErrorState(state));
    final int byte = bytes[i++];
    final int type = typeTable.codeUnitAt(byte) & typeMask;
    if (state == accept) {
      char = byte & (shiftedByteMask >> type);
      state = transitionTable.codeUnitAt(type);
    } else {
      char = (byte & 0x3F) | (_charOrIndex << 6);
      state = transitionTable.codeUnitAt(state + type);
    }

    while (i < end) {
      final int byte = bytes[i++];
      final int type = typeTable.codeUnitAt(byte) & typeMask;
      if (state == accept) {
        if (char >= 0x10000) {
          assert(char < 0x110000);
          writeIntoTwoByteString(result, j++, 0xD7C0 + (char >> 10));
          writeIntoTwoByteString(result, j++, 0xDC00 + (char & 0x3FF));
        } else {
          writeIntoTwoByteString(result, j++, char);
        }
        char = byte & (shiftedByteMask >> type);
        state = transitionTable.codeUnitAt(type);
      } else if (isErrorState(state)) {
        _state = state;
        _charOrIndex = i - 2;
        return "";
      } else {
        char = (byte & 0x3F) | (char << 6);
        state = transitionTable.codeUnitAt(state + type);
      }
    }

    // Final write?
    if (state == accept) {
      if (char >= 0x10000) {
        assert(char < 0x110000);
        writeIntoTwoByteString(result, j++, 0xD7C0 + (char >> 10));
        writeIntoTwoByteString(result, j++, 0xDC00 + (char & 0x3FF));
      } else {
        writeIntoTwoByteString(result, j++, char);
      }
    } else if (isErrorState(state)) {
      _state = state;
      _charOrIndex = end - 1;
      return "";
    }

    _state = state;
    _charOrIndex = char;
    // Output size must match, unless we are doing single conversion and are
    // inside an unfinished sequence (which will trigger an error later).
    assert(_bomIndex == 0 && _state != accept
        ? (j == size - 1 || j == size - 2)
        : (j == size));
    return result;
  }
}
