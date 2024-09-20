// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/// Error thrown by JSON serialization if an object cannot be serialized.
///
/// The [unsupportedObject] field holds that object that failed to be serialized.
///
/// If an object isn't directly serializable, the serializer calls the `toJson`
/// method on the object. If that call fails, the error will be stored in the
/// [cause] field. If the call returns an object that isn't directly
/// serializable, the [cause] is null.
class JsonUnsupportedObjectError extends Error {
  /// The object that could not be serialized.
  final Object? unsupportedObject;

  /// The exception thrown when trying to convert the object.
  final Object? cause;

  /// The partial result of the conversion, up until the error happened.
  ///
  /// May be null.
  final String? partialResult;

  JsonUnsupportedObjectError(this.unsupportedObject,
      {this.cause, this.partialResult});

  String toString() {
    var safeString = Error.safeToString(unsupportedObject);
    String prefix;
    if (cause != null) {
      prefix = "Converting object to an encodable object failed:";
    } else {
      prefix = "Converting object did not return an encodable object:";
    }
    return "$prefix $safeString";
  }
}

/// Reports that an object could not be stringified due to cyclic references.
///
/// An object that references itself cannot be serialized by
/// [JsonCodec.encode]/[JsonEncoder.convert].
/// When the cycle is detected, a [JsonCyclicError] is thrown.
class JsonCyclicError extends JsonUnsupportedObjectError {
  /// The first object that was detected as part of a cycle.
  JsonCyclicError(Object? object) : super(object);
  String toString() => "Cyclic error in JSON stringify";
}

/// An instance of the default implementation of the [JsonCodec].
///
/// This instance provides a convenient access to the most common JSON
/// use cases.
///
/// Examples:
/// ```dart
/// var encoded = json.encode([1, 2, { "a": null }]);
/// var decoded = json.decode('["foo", { "bar": 499 }]');
/// ```
/// The top-level [jsonEncode] and [jsonDecode] functions may be used instead if
/// a local variable shadows the [json] constant.
const JsonCodec json = JsonCodec();

/// Converts [object] to a JSON string.
///
/// If value contains objects that are not directly encodable to a JSON
/// string (a value that is not a number, boolean, string, null, list or a map
/// with string keys), the [toEncodable] function is used to convert it to an
/// object that must be directly encodable.
///
/// If [toEncodable] is omitted, it defaults to a function that returns the
/// result of calling `.toJson()` on the unencodable object.
///
/// Shorthand for `json.encode`. Useful if a local variable shadows the global
/// [json] constant.
///
/// Example:
/// ```dart
/// const data = {'text': 'foo', 'value': 2, 'status': false, 'extra': null};
/// final String jsonString = jsonEncode(data);
/// print(jsonString); // {"text":"foo","value":2,"status":false,"extra":null}
/// ```
///
/// Example of converting an otherwise unsupported object to a
/// custom JSON format:
///
/// ```dart
/// class CustomClass {
///   final String text;
///   final int value;
///   CustomClass({required this.text, required this.value});
///   CustomClass.fromJson(Map<String, dynamic> json)
///       : text = json['text'],
///         value = json['value'];
///
///   static Map<String, dynamic> toJson(CustomClass value) =>
///       {'text': value.text, 'value': value.value};
/// }
///
/// void main() {
///   final CustomClass cc = CustomClass(text: 'Dart', value: 123);
///   final jsonText = jsonEncode({'cc': cc},
///       toEncodable: (Object? value) => value is CustomClass
///           ? CustomClass.toJson(value)
///           : throw UnsupportedError('Cannot convert to JSON: $value'));
///   print(jsonText); // {"cc":{"text":"Dart","value":123}}
/// }
/// ```
String jsonEncode(Object? object,
        {Object? toEncodable(Object? nonEncodable)?}) =>
    json.encode(object, toEncodable: toEncodable);

/// Parses the string and returns the resulting Json object.
///
/// The optional [reviver] function is called once for each object or list
/// property that has been parsed during decoding. The `key` argument is either
/// the integer list index for a list property, the string map key for object
/// properties, or `null` for the final result.
///
/// The default [reviver] (when not provided) is the identity function.
///
/// Shorthand for `json.decode`. Useful if a local variable shadows the global
/// [json] constant.
///
/// Example:
/// ```dart
/// const jsonString =
///     '{"text": "foo", "value": 1, "status": false, "extra": null}';
///
/// final data = jsonDecode(jsonString);
/// print(data['text']); // foo
/// print(data['value']); // 1
/// print(data['status']); // false
/// print(data['extra']); // null
///
/// const jsonArray = '''
///   [{"text": "foo", "value": 1, "status": true},
///    {"text": "bar", "value": 2, "status": false}]
/// ''';
///
/// final List<dynamic> dataList = jsonDecode(jsonArray);
/// print(dataList[0]); // {text: foo, value: 1, status: true}
/// print(dataList[1]); // {text: bar, value: 2, status: false}
///
/// final item = dataList[0];
/// print(item['text']); // foo
/// print(item['value']); // 1
/// print(item['status']); // false
/// ```
dynamic jsonDecode(String source,
        {Object? reviver(Object? key, Object? value)?}) =>
    json.decode(source, reviver: reviver);

/// A [JsonCodec] encodes JSON objects to strings and decodes strings to
/// JSON objects.
///
/// Examples:
/// ```dart
/// var encoded = json.encode([1, 2, { "a": null }]);
/// var decoded = json.decode('["foo", { "bar": 499 }]');
/// ```
final class JsonCodec extends Codec<Object?, String> {
  final Object? Function(Object? key, Object? value)? _reviver;
  final Object? Function(dynamic)? _toEncodable;

  /// Creates a `JsonCodec` with the given reviver and encoding function.
  ///
  /// The [reviver] function is called during decoding. It is invoked once for
  /// each object or list property that has been parsed.
  /// The `key` argument is either the integer list index for a list property,
  /// the string map key for object properties, or `null` for the final result.
  ///
  /// If [reviver] is omitted, it defaults to returning the value argument.
  ///
  /// The [toEncodable] function is used during encoding. It is invoked for
  /// values that are not directly encodable to a string (a value that is not a
  /// number, boolean, string, null, list or a map with string keys). The
  /// function must return an object that is directly encodable. The elements of
  /// a returned list and values of a returned map do not need to be directly
  /// encodable, and if they aren't, `toEncodable` will be used on them as well.
  /// Please notice that it is possible to cause an infinite recursive regress
  /// in this way, by effectively creating an infinite data structure through
  /// repeated call to `toEncodable`.
  ///
  /// If [toEncodable] is omitted, it defaults to a function that returns the
  /// result of calling `.toJson()` on the unencodable object.
  const JsonCodec(
      {Object? reviver(Object? key, Object? value)?,
      Object? toEncodable(dynamic object)?})
      : _reviver = reviver,
        _toEncodable = toEncodable;

  /// Creates a `JsonCodec` with the given reviver.
  ///
  /// The [reviver] function is called once for each object or list property
  /// that has been parsed during decoding. The `key` argument is either the
  /// integer list index for a list property, the string map key for object
  /// properties, or `null` for the final result.
  JsonCodec.withReviver(dynamic reviver(Object? key, Object? value))
      : this(reviver: reviver);

  /// Parses the string and returns the resulting Json object.
  ///
  /// The optional [reviver] function is called once for each object or list
  /// property that has been parsed during decoding. The `key` argument is either
  /// the integer list index for a list property, the string map key for object
  /// properties, or `null` for the final result.
  ///
  /// The default [reviver] (when not provided) is the identity function.
  dynamic decode(String source,
      {Object? reviver(Object? key, Object? value)?}) {
    reviver ??= _reviver;
    if (reviver == null) return decoder.convert(source);
    return JsonDecoder(reviver).convert(source);
  }

  /// Converts [value] to a JSON string.
  ///
  /// If value contains objects that are not directly encodable to a JSON
  /// string (a value that is not a number, boolean, string, null, list or a map
  /// with string keys), the [toEncodable] function is used to convert it to an
  /// object that must be directly encodable.
  ///
  /// If [toEncodable] is omitted, it defaults to a function that returns the
  /// result of calling `.toJson()` on the unencodable object.
  String encode(Object? value, {Object? toEncodable(dynamic object)?}) {
    toEncodable ??= _toEncodable;
    if (toEncodable == null) return encoder.convert(value);
    return JsonEncoder(toEncodable).convert(value);
  }

  JsonEncoder get encoder {
    if (_toEncodable == null) return const JsonEncoder();
    return JsonEncoder(_toEncodable);
  }

  JsonDecoder get decoder {
    if (_reviver == null) return const JsonDecoder();
    return JsonDecoder(_reviver);
  }
}

/// This class converts JSON objects to strings.
///
/// Example:
///
/// ```dart
/// const JsonEncoder encoder = JsonEncoder();
/// const data = {'text': 'foo', 'value': '2'};
///
/// final String jsonString = encoder.convert(data);
/// print(jsonString); // {"text":"foo","value":"2"}
/// ```
///
/// Example of pretty-printed output:
///
/// ```dart
/// const JsonEncoder encoder = JsonEncoder.withIndent('  ');
///
/// const data = {'text': 'foo', 'value': '2'};
/// final String jsonString = encoder.convert(data);
/// print(jsonString);
/// // {
/// //   "text": "foo",
/// //   "value": "2"
/// // }
/// ```
final class JsonEncoder extends Converter<Object?, String> {
  /// The string used for indention.
  ///
  /// When generating multi-line output, this string is inserted once at the
  /// beginning of each indented line for each level of indentation.
  ///
  /// If `null`, the output is encoded as a single line.
  final String? indent;

  /// Function called on non-encodable objects to return a replacement
  /// encodable object that will be encoded in the orignal's place.
  final Object? Function(dynamic)? _toEncodable;

  /// Creates a JSON encoder.
  ///
  /// The JSON encoder handles numbers, strings, booleans, null, lists and
  /// maps with string keys directly.
  ///
  /// Any other object is attempted converted by [toEncodable] to an
  /// object that is of one of the convertible types.
  ///
  /// If [toEncodable] is omitted, it defaults to calling `.toJson()` on
  /// the object.
  const JsonEncoder([Object? toEncodable(dynamic object)?])
      : indent = null,
        _toEncodable = toEncodable;

  /// Creates a JSON encoder that creates multi-line JSON.
  ///
  /// The encoding of elements of lists and maps are indented and put on separate
  /// lines. The [indent] string is prepended to these elements, once for each
  /// level of indentation.
  ///
  /// If [indent] is `null`, the output is encoded as a single line.
  ///
  /// The JSON encoder handles numbers, strings, booleans, null, lists and
  /// maps with string keys directly.
  ///
  /// Any other object is attempted converted by [toEncodable] to an
  /// object that is of one of the convertible types.
  ///
  /// If [toEncodable] is omitted, it defaults to calling `.toJson()` on
  /// the object.
  const JsonEncoder.withIndent(this.indent,
      [Object? toEncodable(dynamic object)?])
      : _toEncodable = toEncodable;

  /// Converts [object] to a JSON [String].
  ///
  /// Directly serializable values are [num], [String], [bool], and [Null], as
  /// well as some [List] and [Map] values. For [List], the elements must all be
  /// serializable. For [Map], the keys must be [String] and the values must be
  /// serializable.
  ///
  /// If a value of any other type is attempted to be serialized, the
  /// `toEncodable` function provided in the constructor is called with the value
  /// as argument. The result, which must be a directly serializable value, is
  /// serialized instead of the original value.
  ///
  /// If the conversion throws, or returns a value that is not directly
  /// serializable, a [JsonUnsupportedObjectError] exception is thrown.
  /// If the call throws, the error is caught and stored in the
  /// [JsonUnsupportedObjectError]'s `cause` field.
  ///
  /// If a [List] or [Map] contains a reference to itself, directly or through
  /// other lists or maps, it cannot be serialized and a [JsonCyclicError] is
  /// thrown.
  ///
  /// [object] should not change during serialization.
  ///
  /// If an object is serialized more than once, [convert] may cache the text
  /// for it. In other words, if the content of an object changes after it is
  /// first serialized, the new values may not be reflected in the result.
  String convert(Object? object) =>
      _JsonStringStringifier.stringify(object, _toEncodable, indent);

  /// Starts a chunked conversion.
  ///
  /// The converter works more efficiently if the given [sink] is a
  /// [StringConversionSink].
  ///
  /// Returns a chunked-conversion sink that accepts at most one object. It is
  /// an error to invoke `add` more than once on the returned sink.
  ChunkedConversionSink<Object?> startChunkedConversion(Sink<String> sink) {
    if (sink is _Utf8EncoderSink) {
      return _JsonUtf8EncoderSink(
          sink._sink,
          _toEncodable,
          JsonUtf8Encoder._utf8Encode(indent),
          JsonUtf8Encoder._defaultBufferSize);
    }
    return _JsonEncoderSink(
        sink is StringConversionSink ? sink : StringConversionSink.from(sink),
        _toEncodable,
        indent);
  }

  // Override the base class's bind, to provide a better type.
  Stream<String> bind(Stream<Object?> stream) => super.bind(stream);

  Converter<Object?, T> fuse<T>(Converter<String, T> other) {
    if (other is Utf8Encoder) {
      // The instance check guarantees that `T` is (a subtype of) List<int>,
      // but the static type system doesn't know that, and so we cast.
      return JsonUtf8Encoder(indent, _toEncodable) as Converter<Object?, T>;
    }
    return super.fuse<T>(other);
  }
}

/// Encoder that encodes a single object as a UTF-8 encoded JSON string.
///
/// This encoder works equivalently to first converting the object to
/// a JSON string, and then UTF-8 encoding the string, but without
/// creating an intermediate string.
final class JsonUtf8Encoder extends Converter<Object?, List<int>> {
  /// Default buffer size used by the JSON-to-UTF-8 encoder.
  static const int _defaultBufferSize = 256;

  /// Indentation used in pretty-print mode, `null` if not pretty.
  final List<int>? _indent;

  /// Function called with each un-encodable object encountered.
  final Object? Function(dynamic)? _toEncodable;

  /// UTF-8 buffer size.
  final int _bufferSize;

  /// Create converter.
  ///
  /// If [indent] is non-`null`, the converter attempts to "pretty-print" the
  /// JSON, and uses `indent` as the indentation. Otherwise the result has no
  /// whitespace outside of string literals.
  /// If `indent` contains characters that are not valid JSON whitespace
  /// characters, the result will not be valid JSON. JSON whitespace characters
  /// are space (U+0020), tab (U+0009), line feed (U+000a) and carriage return
  /// (U+000d) ([ECMA
  /// 404](http://www.ecma-international.org/publications/standards/Ecma-404.htm)).
  ///
  /// The [bufferSize] is the size of the internal buffers used to collect
  /// UTF-8 code units.
  /// If using [startChunkedConversion], it will be the size of the chunks.
  ///
  /// The JSON encoder handles numbers, strings, booleans, null, lists and maps
  /// directly.
  ///
  /// Any other object is attempted converted by [toEncodable] to an object that
  /// is of one of the convertible types.
  ///
  /// If [toEncodable] is omitted, it defaults to calling `.toJson()` on the
  /// object.
  JsonUtf8Encoder(
      [String? indent, dynamic toEncodable(dynamic object)?, int? bufferSize])
      : _indent = _utf8Encode(indent),
        _toEncodable = toEncodable,
        _bufferSize = bufferSize ?? _defaultBufferSize;

  static List<int>? _utf8Encode(String? string) {
    if (string == null) return null;
    if (string.isEmpty) return Uint8List(0);
    checkAscii:
    {
      for (var i = 0; i < string.length; i++) {
        if (string.codeUnitAt(i) >= 0x80) break checkAscii;
      }
      return string.codeUnits;
    }
    return utf8.encode(string);
  }

  /// Convert [object] into UTF-8 encoded JSON.
  List<int> convert(Object? object) {
    var bytes = <List<int>>[];
    // The `stringify` function always converts into chunks.
    // Collect the chunks into the `bytes` list, then combine them afterwards.
    void addChunk(Uint8List chunk, int start, int end) {
      if (start > 0 || end < chunk.length) {
        var length = end - start;
        chunk =
            Uint8List.view(chunk.buffer, chunk.offsetInBytes + start, length);
      }
      bytes.add(chunk);
    }

    _JsonUtf8Stringifier.stringify(
        object, _indent, _toEncodable, _bufferSize, addChunk);
    if (bytes.length == 1) return bytes[0];
    var length = 0;
    for (var i = 0; i < bytes.length; i++) {
      length += bytes[i].length;
    }
    var result = Uint8List(length);
    for (var i = 0, offset = 0; i < bytes.length; i++) {
      var byteList = bytes[i];
      int end = offset + byteList.length;
      result.setRange(offset, end, byteList);
      offset = end;
    }
    return result;
  }

  /// Start a chunked conversion.
  ///
  /// Only one object can be passed into the returned sink.
  ///
  /// The argument [sink] will receive byte lists in sizes depending on the
  /// `bufferSize` passed to the constructor when creating this encoder.
  ChunkedConversionSink<Object?> startChunkedConversion(Sink<List<int>> sink) {
    ByteConversionSink byteSink;
    if (sink is ByteConversionSink) {
      byteSink = sink;
    } else {
      byteSink = ByteConversionSink.from(sink);
    }
    return _JsonUtf8EncoderSink(byteSink, _toEncodable, _indent, _bufferSize);
  }

  // Override the base class's bind, to provide a better type.
  Stream<List<int>> bind(Stream<Object?> stream) {
    return super.bind(stream);
  }
}

/// Implements the chunked conversion from object to its JSON representation.
///
/// The sink only accepts one value, but will produce output in a chunked way.
class _JsonEncoderSink extends ChunkedConversionSink<Object?> {
  final String? _indent;
  final Object? Function(dynamic)? _toEncodable;
  final StringConversionSink _sink;
  bool _isDone = false;

  _JsonEncoderSink(this._sink, this._toEncodable, this._indent);

  /// Encodes the given object [o].
  ///
  /// It is an error to invoke this method more than once on any instance. While
  /// this makes the input effectively non-chunked the output will be generated
  /// in a chunked way.
  void add(Object? o) {
    if (_isDone) {
      throw StateError("Only one call to add allowed");
    }
    _isDone = true;
    var stringSink = _sink.asStringSink();
    _JsonStringStringifier.printOn(o, stringSink, _toEncodable, _indent);
    stringSink.close();
  }

  void close() {/* do nothing */}
}

/// Sink returned when starting a chunked conversion from object to bytes.
class _JsonUtf8EncoderSink extends ChunkedConversionSink<Object?> {
  /// The byte sink receiving the encoded chunks.
  final ByteConversionSink _sink;
  final List<int>? _indent;
  final Object? Function(dynamic)? _toEncodable;
  final int _bufferSize;
  bool _isDone = false;
  _JsonUtf8EncoderSink(
      this._sink, this._toEncodable, this._indent, this._bufferSize);

  /// Callback called for each slice of result bytes.
  void _addChunk(Uint8List chunk, int start, int end) {
    _sink.addSlice(chunk, start, end, false);
  }

  void add(Object? object) {
    if (_isDone) {
      throw StateError("Only one call to add allowed");
    }
    _isDone = true;
    _JsonUtf8Stringifier.stringify(
        object, _indent, _toEncodable, _bufferSize, _addChunk);
    _sink.close();
  }

  void close() {
    if (!_isDone) {
      _isDone = true;
      _sink.close();
    }
  }
}

/// This class parses JSON strings and builds the corresponding objects.
///
/// A JSON input must be the JSON encoding of a single JSON value,
/// which can be a list or map containing other values.
///
/// Throws [FormatException] if the input is not valid JSON text.
///
/// Example:
/// ```dart
/// const JsonDecoder decoder = JsonDecoder();
///
/// const String jsonString = '''
///   {
///     "data": [{"text": "foo", "value": 1 },
///              {"text": "bar", "value": 2 }],
///     "text": "Dart"
///   }
/// ''';
///
/// final Map<String, dynamic> object = decoder.convert(jsonString);
///
/// final item = object['data'][0];
/// print(item['text']); // foo
/// print(item['value']); // 1
///
/// print(object['text']); // Dart
/// ```
///
/// When used as a [StreamTransformer], the input stream may emit
/// multiple strings. The concatenation of all of these strings must
/// be a valid JSON encoding of a single JSON value.
final class JsonDecoder extends Converter<String, Object?> {
  final Object? Function(Object? key, Object? value)? _reviver;

  /// Constructs a new JsonDecoder.
  ///
  /// The [reviver] may be `null`.
  const JsonDecoder([Object? reviver(Object? key, Object? value)?])
      : _reviver = reviver;

  /// Converts the given JSON-string [input] to its corresponding object.
  ///
  /// Parsed JSON values are of the types [num], [String], [bool], [Null],
  /// [List]s of parsed JSON values or [Map]s from [String] to parsed JSON
  /// values.
  ///
  /// If `this` was initialized with a reviver, then the parsing operation
  /// invokes the reviver on every object or list property that has been parsed.
  /// The arguments are the property name ([String]) or list index ([int]), and
  /// the value is the parsed value. The return value of the reviver is used as
  /// the value of that property instead the parsed value.
  ///
  /// Throws [FormatException] if the input is not valid JSON text.
  dynamic convert(String input) => _parseJson(input, _reviver);

  /// Starts a conversion from a chunked JSON string to its corresponding object.
  ///
  /// The output [sink] receives exactly one decoded element through `add`.
  external StringConversionSink startChunkedConversion(Sink<Object?> sink);

  // Override the base class's bind, to provide a better type.
  Stream<Object?> bind(Stream<String> stream) => super.bind(stream);
}

// Internal optimized JSON parsing implementation.
external dynamic _parseJson(String source, reviver(key, value)?);

// Implementation of encoder/stringifier.

// ignore: avoid_dynamic_calls
dynamic _defaultToEncodable(dynamic object) => object.toJson();

/// JSON encoder that traverses an object structure and writes JSON source.
///
/// This is an abstract implementation that doesn't decide on the output
/// format, but writes the JSON through abstract methods like [writeString].
abstract class _JsonStringifier {
  // Character code constants.
  static const int backspace = 0x08;
  static const int tab = 0x09;
  static const int newline = 0x0a;
  static const int carriageReturn = 0x0d;
  static const int formFeed = 0x0c;
  static const int quote = 0x22;
  static const int char_0 = 0x30;
  static const int backslash = 0x5c;
  static const int char_b = 0x62;
  static const int char_d = 0x64;
  static const int char_f = 0x66;
  static const int char_n = 0x6e;
  static const int char_r = 0x72;
  static const int char_t = 0x74;
  static const int char_u = 0x75;
  static const int surrogateMin = 0xd800;
  static const int surrogateMask = 0xfc00;
  static const int surrogateLead = 0xd800;
  static const int surrogateTrail = 0xdc00;

  /// List of objects currently being traversed. Used to detect cycles.
  final List _seen = [];

  /// Function called for each un-encodable object encountered.
  final Function(dynamic) _toEncodable;

  _JsonStringifier(dynamic toEncodable(dynamic o)?)
      : _toEncodable = toEncodable ?? _defaultToEncodable;

  String? get _partialResult;

  /// Append a string to the JSON output.
  void writeString(String characters);

  /// Append part of a string to the JSON output.
  void writeStringSlice(String characters, int start, int end);

  /// Append a single character, given by its code point, to the JSON output.
  void writeCharCode(int charCode);

  /// Write a number to the JSON output.
  void writeNumber(num number);

  // ('0' + x) or ('a' + x - 10)
  static int hexDigit(int x) => x < 10 ? 48 + x : 87 + x;

  /// Write, and suitably escape, a string's content as a JSON string literal.
  void writeStringContent(String s) {
    var offset = 0;
    final length = s.length;
    for (var i = 0; i < length; i++) {
      var charCode = s.codeUnitAt(i);
      if (charCode > backslash) {
        if (charCode >= surrogateMin) {
          // Possible surrogate. Check if it is unpaired.
          if (((charCode & surrogateMask) == surrogateLead &&
                  !(i + 1 < length &&
                      (s.codeUnitAt(i + 1) & surrogateMask) ==
                          surrogateTrail)) ||
              ((charCode & surrogateMask) == surrogateTrail &&
                  !(i - 1 >= 0 &&
                      (s.codeUnitAt(i - 1) & surrogateMask) ==
                          surrogateLead))) {
            // Lone surrogate.
            if (i > offset) writeStringSlice(s, offset, i);
            offset = i + 1;
            writeCharCode(backslash);
            writeCharCode(char_u);
            writeCharCode(char_d);
            writeCharCode(hexDigit((charCode >> 8) & 0xf));
            writeCharCode(hexDigit((charCode >> 4) & 0xf));
            writeCharCode(hexDigit(charCode & 0xf));
          }
        }
        continue;
      }
      if (charCode < 32) {
        if (i > offset) writeStringSlice(s, offset, i);
        offset = i + 1;
        writeCharCode(backslash);
        switch (charCode) {
          case backspace:
            writeCharCode(char_b);
            break;
          case tab:
            writeCharCode(char_t);
            break;
          case newline:
            writeCharCode(char_n);
            break;
          case formFeed:
            writeCharCode(char_f);
            break;
          case carriageReturn:
            writeCharCode(char_r);
            break;
          default:
            writeCharCode(char_u);
            writeCharCode(char_0);
            writeCharCode(char_0);
            writeCharCode(hexDigit((charCode >> 4) & 0xf));
            writeCharCode(hexDigit(charCode & 0xf));
            break;
        }
      } else if (charCode == quote || charCode == backslash) {
        if (i > offset) writeStringSlice(s, offset, i);
        offset = i + 1;
        writeCharCode(backslash);
        writeCharCode(charCode);
      }
    }
    if (offset == 0) {
      writeString(s);
    } else if (offset < length) {
      writeStringSlice(s, offset, length);
    }
  }

  /// Check if an encountered object is already being traversed.
  ///
  /// Records the object if it isn't already seen. Should have a matching call to
  /// [_removeSeen] when the object is no longer being traversed.
  void _checkCycle(Object? object) {
    for (var i = 0; i < _seen.length; i++) {
      if (identical(object, _seen[i])) {
        throw JsonCyclicError(object);
      }
    }
    _seen.add(object);
  }

  /// Remove [object] from the list of currently traversed objects.
  ///
  /// Should be called in the opposite order of the matching [_checkCycle]
  /// calls.
  void _removeSeen(Object? object) {
    assert(_seen.isNotEmpty);
    assert(identical(_seen.last, object));
    _seen.removeLast();
  }

  /// Write an object.
  ///
  /// If [object] isn't directly encodable, the [_toEncodable] function gets one
  /// chance to return a replacement which is encodable.
  void writeObject(Object? object) {
    // Tries stringifying object directly. If it's not a simple value, List or
    // Map, call toJson() to get a custom representation and try serializing
    // that.
    if (writeJsonValue(object)) return;
    _checkCycle(object);
    try {
      var customJson = _toEncodable(object);
      if (!writeJsonValue(customJson)) {
        throw JsonUnsupportedObjectError(object, partialResult: _partialResult);
      }
      _removeSeen(object);
    } catch (e) {
      throw JsonUnsupportedObjectError(object,
          cause: e, partialResult: _partialResult);
    }
  }

  /// Serialize a [num], [String], [bool], [Null], [List] or [Map] value.
  ///
  /// Returns true if the value is one of these types, and false if not.
  /// If a value is both a [List] and a [Map], it's serialized as a [List].
  bool writeJsonValue(Object? object) {
    if (object is num) {
      if (!object.isFinite) return false;
      writeNumber(object);
      return true;
    } else if (identical(object, true)) {
      writeString('true');
      return true;
    } else if (identical(object, false)) {
      writeString('false');
      return true;
    } else if (object == null) {
      writeString('null');
      return true;
    } else if (object is String) {
      writeString('"');
      writeStringContent(object);
      writeString('"');
      return true;
    } else if (object is List) {
      _checkCycle(object);
      writeList(object);
      _removeSeen(object);
      return true;
    } else if (object is Map) {
      _checkCycle(object);
      // writeMap can fail if keys are not all strings.
      var success = writeMap(object);
      _removeSeen(object);
      return success;
    } else {
      return false;
    }
  }

  /// Serialize a [List].
  void writeList(List<Object?> list) {
    writeString('[');
    if (list.isNotEmpty) {
      writeObject(list[0]);
      for (var i = 1; i < list.length; i++) {
        writeString(',');
        writeObject(list[i]);
      }
    }
    writeString(']');
  }

  /// Serialize a [Map].
  bool writeMap(Map<Object?, Object?> map) {
    if (map.isEmpty) {
      writeString("{}");
      return true;
    }
    var keyValueList = List<Object?>.filled(map.length * 2, null);
    var i = 0;
    var allStringKeys = true;
    map.forEach((key, value) {
      if (key is! String) {
        allStringKeys = false;
      }
      keyValueList[i++] = key;
      keyValueList[i++] = value;
    });
    if (!allStringKeys) return false;
    writeString('{');
    var separator = '"';
    for (var i = 0; i < keyValueList.length; i += 2) {
      writeString(separator);
      separator = ',"';
      writeStringContent(keyValueList[i] as String);
      writeString('":');
      writeObject(keyValueList[i + 1]);
    }
    writeString('}');
    return true;
  }
}

/// A modification of [_JsonStringifier] which indents the contents of [List] and
/// [Map] objects using the specified indent value.
///
/// Subclasses should implement [writeIndentation].
mixin _JsonPrettyPrintMixin implements _JsonStringifier {
  int _indentLevel = 0;

  /// Add [indentLevel] indentations to the JSON output.
  void writeIndentation(int indentLevel);

  void writeList(List<Object?> list) {
    if (list.isEmpty) {
      writeString('[]');
    } else {
      writeString('[\n');
      _indentLevel++;
      writeIndentation(_indentLevel);
      writeObject(list[0]);
      for (var i = 1; i < list.length; i++) {
        writeString(',\n');
        writeIndentation(_indentLevel);
        writeObject(list[i]);
      }
      writeString('\n');
      _indentLevel--;
      writeIndentation(_indentLevel);
      writeString(']');
    }
  }

  bool writeMap(Map<Object?, Object?> map) {
    if (map.isEmpty) {
      writeString("{}");
      return true;
    }
    var keyValueList = List<Object?>.filled(map.length * 2, null);
    var i = 0;
    var allStringKeys = true;
    map.forEach((key, value) {
      if (key is! String) {
        allStringKeys = false;
      }
      keyValueList[i++] = key;
      keyValueList[i++] = value;
    });
    if (!allStringKeys) return false;
    writeString('{\n');
    _indentLevel++;
    var separator = "";
    for (var i = 0; i < keyValueList.length; i += 2) {
      writeString(separator);
      separator = ",\n";
      writeIndentation(_indentLevel);
      writeString('"');
      writeStringContent(keyValueList[i] as String);
      writeString('": ');
      writeObject(keyValueList[i + 1]);
    }
    writeString('\n');
    _indentLevel--;
    writeIndentation(_indentLevel);
    writeString('}');
    return true;
  }
}

/// A specialization of [_JsonStringifier] that writes its JSON to a string.
class _JsonStringStringifier extends _JsonStringifier {
  final StringSink _sink;

  _JsonStringStringifier(
      this._sink, dynamic Function(dynamic object)? _toEncodable)
      : super(_toEncodable);

  /// Convert object to a string.
  ///
  /// The [toEncodable] function is used to convert non-encodable objects
  /// to encodable ones.
  ///
  /// If [indent] is not `null`, the resulting JSON will be "pretty-printed"
  /// with newlines and indentation. The `indent` string is added as indentation
  /// for each indentation level. It should only contain valid JSON whitespace
  /// characters (space, tab, carriage return or line feed).
  static String stringify(
      Object? object, dynamic toEncodable(dynamic object)?, String? indent) {
    var output = StringBuffer();
    printOn(object, output, toEncodable, indent);
    return output.toString();
  }

  /// Convert object to a string, and write the result to the [output] sink.
  ///
  /// The result is written piecemally to the sink.
  static void printOn(Object? object, StringSink output,
      dynamic toEncodable(dynamic o)?, String? indent) {
    _JsonStringifier stringifier;
    if (indent == null) {
      stringifier = _JsonStringStringifier(output, toEncodable);
    } else {
      stringifier = _JsonStringStringifierPretty(output, toEncodable, indent);
    }
    stringifier.writeObject(object);
  }

  String? get _partialResult => _sink is StringBuffer ? _sink.toString() : null;

  void writeNumber(num number) {
    _sink.write(number.toString());
  }

  void writeString(String string) {
    _sink.write(string);
  }

  void writeStringSlice(String string, int start, int end) {
    _sink.write(string.substring(start, end));
  }

  void writeCharCode(int charCode) {
    _sink.writeCharCode(charCode);
  }
}

class _JsonStringStringifierPretty extends _JsonStringStringifier
    with _JsonPrettyPrintMixin {
  final String _indent;

  _JsonStringStringifierPretty(
      StringSink sink, dynamic toEncodable(dynamic o)?, this._indent)
      : super(sink, toEncodable);

  void writeIndentation(int count) {
    for (var i = 0; i < count; i++) writeString(_indent);
  }
}

/// Specialization of [_JsonStringifier] that writes the JSON as UTF-8.
///
/// The JSON text is UTF-8 encoded and written to [Uint8List] buffers.
/// The buffers are then passed back to a user provided callback method.
class _JsonUtf8Stringifier extends _JsonStringifier {
  final int bufferSize;
  final void Function(Uint8List list, int start, int end) addChunk;
  Uint8List buffer;
  int index = 0;

  _JsonUtf8Stringifier(
      dynamic toEncodable(dynamic o)?, this.bufferSize, this.addChunk)
      : buffer = Uint8List(bufferSize),
        super(toEncodable);

  /// Convert [object] to UTF-8 encoded JSON.
  ///
  /// Calls [addChunk] with slices of UTF-8 code units.
  /// These will typically have size [bufferSize], but may be shorter.
  /// The buffers are not reused, so the [addChunk] call may keep and reuse the
  /// chunks.
  ///
  /// If [indent] is non-`null`, the result will be "pretty-printed" with extra
  /// newlines and indentation, using [indent] as the indentation.
  static void stringify(
      Object? object,
      List<int>? indent,
      dynamic toEncodable(dynamic o)?,
      int bufferSize,
      void addChunk(Uint8List chunk, int start, int end)) {
    _JsonUtf8Stringifier stringifier;
    if (indent != null) {
      stringifier =
          _JsonUtf8StringifierPretty(toEncodable, indent, bufferSize, addChunk);
    } else {
      stringifier = _JsonUtf8Stringifier(toEncodable, bufferSize, addChunk);
    }
    stringifier.writeObject(object);
    stringifier.flush();
  }

  /// Must be called at the end to push the last chunk to the [addChunk]
  /// callback.
  void flush() {
    if (index > 0) {
      addChunk(buffer, 0, index);
    }
    buffer = Uint8List(0);
    index = 0;
  }

  String? get _partialResult => null;

  void writeNumber(num number) {
    writeAsciiString(number.toString());
  }

  /// Write a string that is known to not have non-ASCII characters.
  void writeAsciiString(String string) {
    // TODO(lrn): Optimize by copying directly into buffer instead of going
    // through writeCharCode;
    for (var i = 0; i < string.length; i++) {
      var char = string.codeUnitAt(i);
      assert(char <= 0x7f);
      writeByte(char);
    }
  }

  void writeString(String string) {
    writeStringSlice(string, 0, string.length);
  }

  void writeStringSlice(String string, int start, int end) {
    // TODO(lrn): Optimize by copying directly into buffer instead of going
    // through writeCharCode/writeByte. Assumption is the most characters
    // in strings are plain ASCII.
    for (var i = start; i < end; i++) {
      var char = string.codeUnitAt(i);
      if (char <= 0x7f) {
        writeByte(char);
      } else {
        if ((char & 0xF800) == 0xD800) {
          // Surrogate.
          if (char < 0xDC00 && i + 1 < end) {
            // Lead surrogate.
            var nextChar = string.codeUnitAt(i + 1);
            if ((nextChar & 0xFC00) == 0xDC00) {
              // Tail surrogate.
              char = 0x10000 + ((char & 0x3ff) << 10) + (nextChar & 0x3ff);
              writeFourByteCharCode(char);
              i++;
              continue;
            }
          }
          // Unpaired surrogate.
          writeMultiByteCharCode(unicodeReplacementCharacterRune);
          continue;
        }
        writeMultiByteCharCode(char);
      }
    }
  }

  void writeCharCode(int charCode) {
    if (charCode <= 0x7f) {
      writeByte(charCode);
      return;
    }
    writeMultiByteCharCode(charCode);
  }

  void writeMultiByteCharCode(int charCode) {
    if (charCode <= 0x7ff) {
      writeByte(0xC0 | (charCode >> 6));
      writeByte(0x80 | (charCode & 0x3f));
      return;
    }
    if (charCode <= 0xffff) {
      writeByte(0xE0 | (charCode >> 12));
      writeByte(0x80 | ((charCode >> 6) & 0x3f));
      writeByte(0x80 | (charCode & 0x3f));
      return;
    }
    writeFourByteCharCode(charCode);
  }

  void writeFourByteCharCode(int charCode) {
    assert(charCode <= 0x10ffff);
    writeByte(0xF0 | (charCode >> 18));
    writeByte(0x80 | ((charCode >> 12) & 0x3f));
    writeByte(0x80 | ((charCode >> 6) & 0x3f));
    writeByte(0x80 | (charCode & 0x3f));
  }

  void writeByte(int byte) {
    assert(byte <= 0xff);
    if (index == buffer.length) {
      addChunk(buffer, 0, index);
      buffer = Uint8List(bufferSize);
      index = 0;
    }
    buffer[index++] = byte;
  }
}

/// Pretty-printing version of [_JsonUtf8Stringifier].
class _JsonUtf8StringifierPretty extends _JsonUtf8Stringifier
    with _JsonPrettyPrintMixin {
  final List<int> indent;
  _JsonUtf8StringifierPretty(dynamic toEncodable(dynamic o)?, this.indent,
      int bufferSize, void addChunk(Uint8List buffer, int start, int end))
      : super(toEncodable, bufferSize, addChunk);

  void writeIndentation(int count) {
    var indent = this.indent;
    var indentLength = indent.length;
    if (indentLength == 1) {
      var char = indent[0];
      while (count > 0) {
        writeByte(char);
        count -= 1;
      }
      return;
    }
    while (count > 0) {
      count--;
      var end = index + indentLength;
      if (end <= buffer.length) {
        buffer.setRange(index, end, indent);
        index = end;
      } else {
        for (var i = 0; i < indentLength; i++) {
          writeByte(indent[i]);
        }
      }
    }
  }
}
