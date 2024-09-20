// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Encoders and decoders for converting between different data representations,
/// including JSON and UTF-8.
///
/// In addition to converters for common data representations, this library
/// provides support for implementing converters in a way which makes them easy
/// to chain and to use with streams.
///
/// To use this library in your code:
/// ```dart
/// import 'dart:convert';
/// ```
/// Two commonly used converters are the top-level instances of
/// [JsonCodec] and [Utf8Codec], named [json] and [utf8], respectively.
///
/// ## JSON
/// JSON is a simple text format for representing structured objects and
/// collections.
///
/// A [JsonCodec] encodes JSON objects to strings and decodes strings to
/// JSON objects. The [json] encoder/decoder transforms between strings and
/// object structures, such as lists and maps, using the JSON format.
///
/// The [json] is the default implementation of [JsonCodec].
///
/// Examples
/// ```dart
/// var encoded = json.encode([1, 2, { "a": null }]);
/// var decoded = json.decode('["foo", { "bar": 499 }]');
/// ```
/// For more information, see also [JsonEncoder] and [JsonDecoder].
///
/// ## UTF-8
/// A [Utf8Codec] encodes strings to UTF-8 code units (bytes) and decodes
/// UTF-8 code units to strings.
///
/// The [utf8] is the default implementation of [Utf8Codec].
///
/// Example:
/// ```dart
/// var encoded = utf8.encode('Îñţérñåţîöñåļîžåţîờñ');
/// var decoded = utf8.decode([
///   195, 142, 195, 177, 197, 163, 195, 169, 114, 195, 177, 195, 165, 197,
///   163, 195, 174, 195, 182, 195, 177, 195, 165, 196, 188, 195, 174, 197,
///   190, 195, 165, 197, 163, 195, 174, 225, 187, 157, 195, 177]);
/// ```
/// For more information, see also [Utf8Encoder] and [Utf8Decoder].
///
/// ## ASCII
/// An [AsciiCodec] encodes strings as ASCII codes stored as bytes and decodes
/// ASCII bytes to strings. Not all characters can be represented as ASCII, so
/// not all strings can be successfully converted.
///
/// The [ascii] is the default implementation of [AsciiCodec].
///
/// Example:
/// ```dart
/// var encoded = ascii.encode('This is ASCII!');
/// var decoded = ascii.decode([0x54, 0x68, 0x69, 0x73, 0x20, 0x69, 0x73,
///                             0x20, 0x41, 0x53, 0x43, 0x49, 0x49, 0x21]);
/// ```
/// For more information, see also [AsciiEncoder] and [AsciiDecoder].
///
/// ## Latin-1
/// A [Latin1Codec] encodes strings to ISO Latin-1 (aka ISO-8859-1) bytes
/// and decodes Latin-1 bytes to strings. Not all characters can be represented
/// as Latin-1, so not all strings can be successfully converted.
///
/// The [latin1] is the default implementation of [Latin1Codec].
///
/// Example:
/// ```dart
/// var encoded = latin1.encode('blåbærgrød');
/// var decoded = latin1.decode([0x62, 0x6c, 0xe5, 0x62, 0xe6,
///                              0x72, 0x67, 0x72, 0xf8, 0x64]);
/// ```
/// For more information, see also [Latin1Encoder] and [Latin1Decoder].
///
/// ## Base64
/// A [Base64Codec] encodes bytes using the default base64 alphabet,
/// decodes using both the base64 and base64url alphabets,
/// does not allow invalid characters and requires padding.
///
/// The [base64] is the default implementation of [Base64Codec].
///
/// Example:
/// ```dart
/// var encoded = base64.encode([0x62, 0x6c, 0xc3, 0xa5, 0x62, 0xc3, 0xa6,
///                              0x72, 0x67, 0x72, 0xc3, 0xb8, 0x64]);
/// var decoded = base64.decode('YmzDpWLDpnJncsO4ZAo=');
/// ```
/// For more information, see also [Base64Encoder] and [Base64Decoder].
///
/// ## Converters
/// Converters are often used with streams
/// to transform the data that comes through the stream
/// as it becomes available.
/// The following code uses two converters.
/// The first is a UTF-8 decoder, which converts the data from bytes to UTF-8
/// as it is read from a file,
/// The second is an instance of [LineSplitter],
/// which splits the data on newline boundaries.
/// ```dart import:io
/// const showLineNumbers = true;
/// var lineNumber = 1;
/// var stream = File('quotes.txt').openRead();
///
/// stream.transform(utf8.decoder)
///       .transform(const LineSplitter())
///       .forEach((line) {
///         if (showLineNumbers) {
///           stdout.write('${lineNumber++} ');
///         }
///         stdout.writeln(line);
///       });
/// ```
/// See the documentation for the [Codec] and [Converter] classes
/// for information about creating your own converters.
///
/// ## HTML Escape
/// [HtmlEscape] converter escapes characters with special meaning in HTML.
/// The converter finds characters that are significant in HTML source and
/// replaces them with corresponding HTML entities.
///
/// Custom escape modes can be created using the [HtmlEscapeMode.new]
/// constructor.
///
/// Example:
/// ```dart
/// const htmlEscapeMode = HtmlEscapeMode(
///   name: 'custom',
///   escapeLtGt: true,
///   escapeQuot: false,
///   escapeApos: false,
///   escapeSlash: false,
///  );
///
/// const HtmlEscape htmlEscape = HtmlEscape(htmlEscapeMode);
/// String unescaped = 'Text & subject';
/// String escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Text &amp; subject
///
/// unescaped = '10 > 1 and 1 < 10';
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // 10 &gt; 1 and 1 &lt; 10
///
/// unescaped = "Single-quoted: 'text'";
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Single-quoted: 'text'
///
/// unescaped = 'Double-quoted: "text"';
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Double-quoted: "text"
///
/// unescaped = 'Path: /system/';
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Path: /system/
/// ```
/// {@category Core}
library dart.convert;

import 'dart:async';
import 'dart:typed_data';
import 'dart:_internal' show CastConverter, checkNotNullable, parseHexByte;

part 'ascii.dart';
part 'base64.dart';
part 'byte_conversion.dart';
part 'chunked_conversion.dart';
part 'codec.dart';
part 'converter.dart';
part 'encoding.dart';
part 'html_escape.dart';
part 'json.dart';
part 'latin1.dart';
part 'line_splitter.dart';
part 'string_conversion.dart';
part 'utf.dart';
