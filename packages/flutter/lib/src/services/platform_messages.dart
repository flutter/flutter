// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'binary_messenger.dart';
import 'platform_channel.dart';

/// Sends binary messages to and receives binary messages from platform plugins.
///
/// This class has been deprecated in favor of [defaultBinaryMessenger]. New
/// code should not use [BinaryMessages].
///
/// See also:
///
///  * [BinaryMessenger], the interface which has replaced this class.
///  * [BasicMessageChannel], which provides basic messaging services similar to
///    `BinaryMessages`, but with pluggable message codecs in support of sending
///    strings or semi-structured messages.
///  * [MethodChannel], which provides platform communication using asynchronous
///    method calls.
///  * [EventChannel], which provides platform communication using event streams.
///  * <https://flutter.dev/platform-channels/>
@Deprecated(
  'This class, which was just a collection of static methods, has been '
  'deprecated in favor of BinaryMessenger, and its default implementation, '
  'defaultBinaryMessenger. '
  'This feature was deprecated after v1.6.5.'
)
class BinaryMessages {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  BinaryMessages._();

  /// The messenger which sends the platform messages, not null.
  static final BinaryMessenger _binaryMessenger = defaultBinaryMessenger;

  /// Calls the handler registered for the given channel.
  ///
  /// Typically called by [ServicesBinding] to handle platform messages received
  /// from [Window.onPlatformMessage].
  ///
  /// To register a handler for a given message channel, see [setMessageHandler].
  @Deprecated(
    'Use defaultBinaryMessenger.handlePlatformMessage instead. '
    'This feature was deprecated after v1.6.5.'
  )
  static Future<void> handlePlatformMessage(
    String channel,
    ByteData data,
    ui.PlatformMessageResponseCallback callback,
  ) {
    return _binaryMessenger.handlePlatformMessage(channel, data, callback);
  }

  /// Send a binary message to the platform plugins on the given channel.
  ///
  /// Returns a [Future] which completes to the received response, undecoded, in
  /// binary form.
  @Deprecated(
    'Use defaultBinaryMessenger.send instead. '
    'This feature was deprecated after v1.6.5.'
  )
  static Future<ByteData?> send(String channel, ByteData? message) {
    return _binaryMessenger.send(channel, message);
  }

  /// Set a callback for receiving messages from the platform plugins on the
  /// given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered callback for that
  /// channel, if any. To remove the handler, pass null as the `handler`
  /// argument.
  ///
  /// The handler's return value, if non-null, is sent as a response, unencoded.
  @Deprecated(
    'Use defaultBinaryMessenger.setMessageHandler instead. '
    'This feature was deprecated after v1.6.5.'
  )
  static void setMessageHandler(String channel, Future<ByteData?> Function(ByteData? message) handler) {
    _binaryMessenger.setMessageHandler(channel, handler);
  }

  /// Set a mock callback for intercepting messages from the `send*` methods on
  /// this class, on the given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// that channel, if any. To remove the mock handler, pass null as the
  /// `handler` argument.
  ///
  /// The handler's return value, if non-null, is used as a response, unencoded.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  @Deprecated(
    'Use defaultBinaryMessenger.setMockMessageHandler instead. '
    'This feature was deprecated after v1.6.5.'
  )
  static void setMockMessageHandler(String channel, Future<ByteData?> Function(ByteData? message) handler) {
    _binaryMessenger.setMockMessageHandler(channel, handler);
  }
}
