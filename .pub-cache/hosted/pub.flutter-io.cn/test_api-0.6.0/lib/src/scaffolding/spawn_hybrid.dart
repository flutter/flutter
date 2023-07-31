// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:stream_channel/stream_channel.dart';

import '../backend/remote_exception.dart';
import '../utils.dart';
import 'test_structure.dart' show addTearDown;

/// A transformer that handles messages from the spawned isolate and ensures
/// that messages sent to it are JSON-encodable.
///
/// The spawned isolate sends three kinds of messages. Data messages are emitted
/// as data events, error messages are emitted as error events, and print
/// messages are printed using `print()`.
// package:test will only send a `Map` across this channel, but users of
// `hybridMain` can send any json encodeable type.
final _transformer = StreamChannelTransformer<dynamic, dynamic>(
    StreamTransformer.fromHandlers(handleData: (message, sink) {
  switch (message['type'] as String) {
    case 'data':
      sink.add(message['data']);
      break;

    case 'print':
      print(message['line']);
      break;

    case 'error':
      var error = RemoteException.deserialize(message['error']);
      sink.addError(error.error, error.stackTrace);
      break;
  }
}), StreamSinkTransformer.fromHandlers(handleData: (message, sink) {
  // This is called synchronously from the user's `Sink.add()` call, so if
  // [ensureJsonEncodable] throws here they'll get a helpful stack trace.
  ensureJsonEncodable(message);
  sink.add(message);
}));

/// Spawns a VM isolate for the given [uri], which may be a [Uri] or a [String].
///
/// This allows browser tests to spawn servers with which they can communicate
/// to test client/server interactions. It can also be used by VM tests to
/// easily spawn an isolate.
///
/// The Dart file at [uri] must define a top-level `hybridMain()` function that
/// takes a `StreamChannel` argument and, optionally, an `Object` argument to
/// which [message] will be passed. Note that [message] must be JSON-encodable.
/// For example:
///
/// ```dart
/// import "package:stream_channel/stream_channel.dart";
///
/// hybridMain(StreamChannel channel, Object message) {
///   // ...
/// }
/// ```
///
/// If [uri] is relative, it will be interpreted relative to the `file:` URL for
/// the test suite being executed. If it's root-relative (that is, if it begins
/// with `/`) it will be interpreted relative to the root of the package (the
/// directory that contains `pubspec.yaml`, *not* the `test/` directory). If
/// it's a `package:` URL, it will be resolved using the current package's
/// dependency constellation.
///
/// Returns a [StreamChannel] that's connected to the channel passed to
/// `hybridMain()`. Only JSON-encodable objects may be sent through this
/// channel. If the channel is closed, the hybrid isolate is killed. If the
/// isolate is killed, the channel's stream will emit a "done" event.
///
/// Any unhandled errors loading or running the hybrid isolate will be emitted
/// as errors over the channel's stream. Any calls to `print()` in the hybrid
/// isolate will be printed as though they came from the test that created the
/// isolate.
///
/// Code in the hybrid isolate is not considered to be running in a test
/// context, so it can't access test functions like `expect()` and
/// `expectAsync()`.
///
/// By default, the hybrid isolate is automatically killed when the test
/// finishes running. If [stayAlive] is `true`, it won't be killed until the
/// entire test suite finishes running.
///
/// **Note**: If you use this API, be sure to add a dependency on the
/// **`stream_channel` package, since you're using its API as well!
StreamChannel spawnHybridUri(uri, {Object? message, bool stayAlive = false}) {
  if (uri is String) {
    // Ensure that it can be parsed as a uri.
    Uri.parse(uri);
  } else if (uri is! Uri) {
    throw ArgumentError.value(uri, 'uri', 'must be a Uri or a String.');
  }
  return _spawn(uri.toString(), message, stayAlive: stayAlive);
}

/// Spawns a VM isolate that runs the given [dartCode], which is loaded as the
/// contents of a Dart library.
///
/// This allows browser tests to spawn servers with which they can communicate
/// to test client/server interactions. It can also be used by VM tests to
/// easily spawn an isolate.
///
/// The [dartCode] must define a top-level `hybridMain()` function that takes a
/// `StreamChannel` argument and, optionally, an `Object` argument to which
/// [message] will be passed. Note that [message] must be JSON-encodable. For
/// example:
///
/// ```dart
/// import "package:stream_channel/stream_channel.dart";
///
/// hybridMain(StreamChannel channel, Object message) {
///   // ...
/// }
/// ```
///
/// Returns a [StreamChannel] that's connected to the channel passed to
/// `hybridMain()`. Only JSON-encodable objects may be sent through this
/// channel. If the channel is closed, the hybrid isolate is killed. If the
/// isolate is killed, the channel's stream will emit a "done" event.
///
/// Any unhandled errors loading or running the hybrid isolate will be emitted
/// as errors over the channel's stream. Any calls to `print()` in the hybrid
/// isolate will be printed as though they came from the test that created the
/// isolate.
///
/// Code in the hybrid isolate is not considered to be running in a test
/// context, so it can't access test functions like `expect()` and
/// `expectAsync()`.
///
/// By default, the hybrid isolate is automatically killed when the test
/// finishes running. If [stayAlive] is `true`, it won't be killed until the
/// entire test suite finishes running.
///
/// **Note**: If you use this API, be sure to add a dependency on the
/// **`stream_channel` package, since you're using its API as well!
StreamChannel spawnHybridCode(String dartCode,
    {Object? message, bool stayAlive = false}) {
  var uri = Uri.dataFromString(dartCode,
      encoding: utf8, mimeType: 'application/dart');
  return _spawn(uri.toString(), message, stayAlive: stayAlive);
}

/// Like [spawnHybridUri], but doesn't take [Uri] objects.
StreamChannel _spawn(String uri, Object? message, {bool stayAlive = false}) {
  var channel = Zone.current[#test.runner.test_channel] as MultiChannel?;
  if (channel == null) {
    throw UnsupportedError("Can't connect to the test runner.\n"
        'spawnHybridUri() is currently only supported within "dart test".');
  }

  ensureJsonEncodable(message);

  var virtualChannel = channel.virtualChannel();
  StreamChannel isolateChannel = virtualChannel;
  channel.sink.add({
    'type': 'spawn-hybrid-uri',
    'url': uri,
    'message': message,
    'channel': virtualChannel.id
  });

  if (!stayAlive) {
    var disconnector = Disconnector();
    addTearDown(() => disconnector.disconnect());
    isolateChannel = isolateChannel.transform(disconnector);
  }

  return isolateChannel.transform(_transformer);
}
