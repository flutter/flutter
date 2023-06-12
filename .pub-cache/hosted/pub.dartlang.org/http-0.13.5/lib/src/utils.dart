// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'byte_stream.dart';

/// Converts a [Map] from parameter names to values to a URL query string.
///
///     mapToQuery({"foo": "bar", "baz": "bang"});
///     //=> "foo=bar&baz=bang"
String mapToQuery(Map<String, String> map, {Encoding? encoding}) {
  var pairs = <List<String>>[];
  map.forEach((key, value) => pairs.add([
        Uri.encodeQueryComponent(key, encoding: encoding ?? utf8),
        Uri.encodeQueryComponent(value, encoding: encoding ?? utf8)
      ]));
  return pairs.map((pair) => '${pair[0]}=${pair[1]}').join('&');
}

/// Returns the [Encoding] that corresponds to [charset].
///
/// Returns [fallback] if [charset] is null or if no [Encoding] was found that
/// corresponds to [charset].
Encoding encodingForCharset(String? charset, [Encoding fallback = latin1]) {
  if (charset == null) return fallback;
  return Encoding.getByName(charset) ?? fallback;
}

/// Returns the [Encoding] that corresponds to [charset].
///
/// Throws a [FormatException] if no [Encoding] was found that corresponds to
/// [charset].
///
/// [charset] may not be null.
Encoding requiredEncodingForCharset(String charset) =>
    Encoding.getByName(charset) ??
    (throw FormatException('Unsupported encoding "$charset".'));

/// A regular expression that matches strings that are composed entirely of
/// ASCII-compatible characters.
final _asciiOnly = RegExp(r'^[\x00-\x7F]+$');

/// Returns whether [string] is composed entirely of ASCII-compatible
/// characters.
bool isPlainAscii(String string) => _asciiOnly.hasMatch(string);

/// Converts [input] into a [Uint8List].
///
/// If [input] is a [TypedData], this just returns a view on [input].
Uint8List toUint8List(List<int> input) {
  if (input is Uint8List) return input;
  if (input is TypedData) {
    // TODO(nweiz): remove "as" when issue 11080 is fixed.
    return Uint8List.view((input as TypedData).buffer);
  }
  return Uint8List.fromList(input);
}

ByteStream toByteStream(Stream<List<int>> stream) {
  if (stream is ByteStream) return stream;
  return ByteStream(stream);
}

/// Calls [onDone] once [stream] (a single-subscription [Stream]) is finished.
///
/// The return value, also a single-subscription [Stream] should be used in
/// place of [stream] after calling this method.
Stream<T> onDone<T>(Stream<T> stream, void Function() onDone) =>
    stream.transform(StreamTransformer.fromHandlers(handleDone: (sink) {
      sink.close();
      onDone();
    }));
