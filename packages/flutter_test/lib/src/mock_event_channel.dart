// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';

/// A mock stream handler for an [EventChannel] that mimics the native
/// StreamHandler API.
///
/// The [onListen] callback is provided a [MockStreamHandlerEventSink] with
/// the following API:
/// - [MockStreamHandlerEventSink.success] sends a success event.
/// - [MockStreamHandlerEventSink.error] sends an error event.
/// - [MockStreamHandlerEventSink.endOfStream] sends an end of stream event.
abstract class MockStreamHandler {
  /// Create a new [MockStreamHandler].
  MockStreamHandler();

  /// Create a new inline [MockStreamHandler] with the given [onListen] and
  /// [onCancel] handlers.
  factory MockStreamHandler.inline({
    required final MockStreamHandlerOnListenCallback onListen,
    final MockStreamHandlerOnCancelCallback? onCancel,
  }) => _InlineMockStreamHandler(onListen: onListen, onCancel: onCancel);

  /// Handler for the listen event.
  void onListen(final Object? arguments, final MockStreamHandlerEventSink events);

  /// Handler for the cancel event.
  void onCancel(final Object? arguments);
}

/// Typedef for the inline onListen callback.
typedef MockStreamHandlerOnListenCallback = void Function(Object? arguments, MockStreamHandlerEventSink events);

/// Typedef for the inline onCancel callback.
typedef MockStreamHandlerOnCancelCallback = void Function(Object? arguments);

class _InlineMockStreamHandler extends MockStreamHandler {
  _InlineMockStreamHandler({
    required final MockStreamHandlerOnListenCallback onListen,
    final MockStreamHandlerOnCancelCallback? onCancel,
  })  : _onListenInline = onListen,
        _onCancelInline = onCancel;

  final MockStreamHandlerOnListenCallback _onListenInline;
  final MockStreamHandlerOnCancelCallback? _onCancelInline;

  @override
  void onListen(final Object? arguments, final MockStreamHandlerEventSink events) => _onListenInline(arguments, events);

  @override
  void onCancel(final Object? arguments) => _onCancelInline?.call(arguments);
}

/// A mock event sink for a [MockStreamHandler] that mimics the native
/// [EventSink](https://api.flutter.dev/javadoc/io/flutter/plugin/common/EventChannel.EventSink.html)
/// API.
class MockStreamHandlerEventSink {
  /// Create a new [MockStreamHandlerEventSink] with the given [sink].
  MockStreamHandlerEventSink(final EventSink<Object?> sink) : _sink = sink;

  final EventSink<Object?> _sink;

  /// Send a success event.
  void success(final Object? event) => _sink.add(event);

  /// Send an error event.
  void error({
    required final String code,
    final String? message,
    final Object? details,
  }) => _sink.addError(PlatformException(code: code, message: message, details: details));

  /// Send an end of stream event.
  void endOfStream() => _sink.close();
}
