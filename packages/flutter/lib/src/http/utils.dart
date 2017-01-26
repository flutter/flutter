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
String mapToQuery(Map<String, String> map, {Encoding encoding}) {
  List<List<String>> pairs = <List<String>>[];
  map.forEach((String key, String value) =>
      pairs.add(<String>[Uri.encodeQueryComponent(key, encoding: encoding),
                 Uri.encodeQueryComponent(value, encoding: encoding)]));
  return pairs.map((List<String> pair) => "${pair[0]}=${pair[1]}").join("&");
}

/// Like [String.split], but only splits on the first occurrence of the pattern.
/// This will always return an array of two elements or fewer.
///
///     split1("foo,bar,baz", ","); //=> ["foo", "bar,baz"]
///     split1("foo", ","); //=> ["foo"]
///     split1("", ","); //=> []
List<String> split1(String toSplit, String pattern) {
  if (toSplit.isEmpty) return <String>[];

  int index = toSplit.indexOf(pattern);
  if (index == -1) return <String>[toSplit];
  return <String>[
    toSplit.substring(0, index),
    toSplit.substring(index + pattern.length)
  ];
}

/// Returns the [Encoding] that corresponds to [charset]. Returns [fallback] if
/// [charset] is null or if no [Encoding] was found that corresponds to
/// [charset].
Encoding encodingForCharset(String charset, [Encoding fallback = LATIN1]) {
  if (charset == null) return fallback;
  Encoding encoding = Encoding.getByName(charset);
  return encoding == null ? fallback : encoding;
}


/// Returns the [Encoding] that corresponds to [charset]. Throws a
/// [FormatException] if no [Encoding] was found that corresponds to [charset].
/// [charset] may not be null.
Encoding requiredEncodingForCharset(String charset) {
  Encoding encoding = Encoding.getByName(charset);
  if (encoding != null) return encoding;
  throw new FormatException('Unsupported encoding "$charset".');
}

/// A regular expression that matches strings that are composed entirely of
/// ASCII-compatible characters.
final RegExp _kAsciiOnly = new RegExp(r"^[\x00-\x7F]+$");

/// Returns whether [string] is composed entirely of ASCII-compatible
/// characters.
bool isPlainAscii(String string) => _kAsciiOnly.hasMatch(string);

/// Converts [input] into a [Uint8List].
///
/// If [input] is a [TypedData], this just returns a view on [input].
Uint8List toUint8List(dynamic input) {
  if (input is Uint8List)
    return input;
  if (input is TypedData)
    return new Uint8List.view(input.buffer);
  return new Uint8List.fromList(input);
}

/// If [stream] is already a [ByteStream], returns it. Otherwise, wraps it in a
/// [ByteStream].
ByteStream toByteStream(Stream<List<int>> stream) {
  if (stream is ByteStream) return stream;
  return new ByteStream(stream);
}

/// Calls [onDone] once [stream] (a single-subscription [Stream]) is finished.
/// The return value, also a single-subscription [Stream] should be used in
/// place of [stream] after calling this method.
Stream/*<T>*/ onDone/*<T>*/(Stream/*<T>*/ stream, void onDone()) =>
    stream.transform(new StreamTransformer.fromHandlers(handleDone: (EventSink<dynamic> sink) { // ignore: always_specify_types
      sink.close();
      onDone();
    }));

// TODO(nweiz): remove this when issue 7786 is fixed.
/// Pipes all data and errors from [stream] into [sink]. When [stream] is done,
/// [sink] is closed and the returned [Future] is completed.
Future<dynamic> store(Stream<dynamic> stream, EventSink<dynamic> sink) {
  Completer<dynamic> completer = new Completer<dynamic>();
  stream.listen(sink.add,
      onError: sink.addError,
      onDone: () {
        sink.close();
        completer.complete();
      });
  return completer.future;
}

/// Pipes all data and errors from [stream] into [sink]. Completes [Future] once
/// [stream] is done. Unlike [store], [sink] remains open after [stream] is
/// done.
Future<dynamic> writeStreamToSink(Stream<dynamic> stream, EventSink<dynamic> sink) {
  Completer<dynamic> completer = new Completer<dynamic>();
  stream.listen(sink.add,
      onError: sink.addError,
      onDone: () => completer.complete());
  return completer.future;
}

/// A pair of values.
class Pair<E, F> {
  E first;
  F last;

  Pair(this.first, this.last);

  @override
  String toString() => '($first, $last)';

  @override
  bool operator==(dynamic other) {
    if (other is! Pair) return false;
    return other.first == first && other.last == last;
  }

  @override
  int get hashCode => first.hashCode ^ last.hashCode;
}

/// Configures [future] so that its result (success or exception) is passed on
/// to [completer].
void chainToCompleter(Future<dynamic> future, Completer<dynamic> completer) {
  future.then(completer.complete, onError: completer.completeError);
}
