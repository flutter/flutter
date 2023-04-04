// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';

/// A mock stream handler for an [EventChannel] that mimics the native
/// StreamHandler API.
///
/// {@template flutter.flutter_test.MockStreamHandler}
/// The [onListen] callback is provided a [MockStreamHandlerEventSink] with
/// the following API:
/// - [events.success] sends a success event.
/// - [events.error] sends an error event.
/// - [events.endOfStream] sends an end of stream event.
/// {@endtemplate}
abstract class MockStreamHandler {
  /// Create a new [MockStreamHandler].
  MockStreamHandler();

  /// Create a new [InlineMockStreamHandler] with the given [onListen] and
  /// [onCancel] handlers.
  factory MockStreamHandler.inline({
    required MockStreamHandlerOnListenCallback onListen,
    MockStreamHandlerOnCancelCallback? onCancel,
  }) => InlineMockStreamHandler._(onListen: onListen, onCancel: onCancel);

  /// Handler for the listen event.
  void onListen(Object? arguments, MockStreamHandlerEventSink events);

  /// Handler for the cancel event.
  void onCancel(Object? arguments);
}

/// Typedef for the [InlineMockStreamHandler.onListen] callback.
typedef MockStreamHandlerOnListenCallback = void Function(Object? arguments, MockStreamHandlerEventSink events);

/// Typedef for the [InlineMockStreamHandler.onCancel] callback.
typedef MockStreamHandlerOnCancelCallback = void Function(Object? arguments);

/// Convenience class for creating a [MockStreamHandler] inline.
///
/// {@macro flutter.flutter_test.MockStreamHandler}
class InlineMockStreamHandler extends MockStreamHandler {
  InlineMockStreamHandler._({
    required MockStreamHandlerOnListenCallback onListen,
    MockStreamHandlerOnCancelCallback? onCancel,
  })  : _onListenInline = onListen,
        _onCancelInline = onCancel;

  final MockStreamHandlerOnListenCallback _onListenInline;
  final MockStreamHandlerOnCancelCallback? _onCancelInline;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) => _onListenInline(arguments, events);

  @override
  void onCancel(Object? arguments) => _onCancelInline?.call(arguments);
}

/// A mock event sink for a [MockStreamHandler] that mimics the native
/// [EventSink](https://api.flutter.dev/javadoc/io/flutter/plugin/common/EventChannel.EventSink.html)
/// API.
class MockStreamHandlerEventSink {
  /// Create a new [MockStreamHandlerEventSink] with the given [sink].
  MockStreamHandlerEventSink(EventSink<Object?> sink) : _sink = sink;

  final EventSink<Object?> _sink;

  /// Send a success event.
  void success(Object? event) => _sink.add(event);

  /// Send an error event.
  void error({
    required String code,
    String? message,
    Object? details,
  }) => _sink.addError(PlatformException(code: code, message: message, details: details));

  /// Send an end of stream event.
  void endOfStream() => _sink.close();
}
