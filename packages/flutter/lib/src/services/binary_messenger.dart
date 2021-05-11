// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:typed_data';
import 'dart:ui' as ui;

import 'binding.dart';

/// A function which takes a platform message and asynchronously returns an encoded response.
typedef MessageHandler = Future<ByteData?>? Function(ByteData? message);

/// A messenger which sends binary data across the Flutter platform barrier.
///
/// This class also registers handlers for incoming messages.
abstract class BinaryMessenger {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const BinaryMessenger();

  /// Calls the handler registered for the given channel.
  ///
  /// Typically called by [ServicesBinding] to handle platform messages received
  /// from [dart:ui.PlatformDispatcher.onPlatformMessage].
  ///
  /// To register a handler for a given message channel, see [setMessageHandler].
  Future<void> handlePlatformMessage(String channel, ByteData? data, ui.PlatformMessageResponseCallback? callback);

  /// Send a binary message to the platform plugins on the given channel.
  ///
  /// Returns a [Future] which completes to the received response, undecoded,
  /// in binary form.
  Future<ByteData?>? send(String channel, ByteData? message);

  /// Set a callback for receiving messages from the platform plugins on the
  /// given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered callback for that
  /// channel, if any. To remove the handler, pass null as the [handler]
  /// argument.
  ///
  /// The handler's return value, if non-null, is sent as a response, unencoded.
  void setMessageHandler(String channel, MessageHandler? handler);

  /// Returns true if the `handler` argument matches the `handler` previously
  /// passed to [setMessageHandler].
  ///
  /// This method is useful for tests or test harnesses that want to assert the
  /// handler for the specified channel has not been altered by a previous test.
  ///
  /// Passing null for the `handler` returns true if the handler for the
  /// `channel` is not set.
  bool checkMessageHandler(String channel, MessageHandler? handler);

  /// Set a mock callback for intercepting messages from the [send] method on
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
  void setMockMessageHandler(String channel, MessageHandler? handler);

  /// Returns true if the `handler` argument matches the `handler` previously
  /// passed to [setMockMessageHandler].
  ///
  /// This method is useful for tests or test harnesses that want to assert the
  /// mock handler for the specified channel has not been altered by a previous
  /// test.
  ///
  /// Passing null for the `handler` returns true if the handler for the
  /// `channel` is not set.
  bool checkMockMessageHandler(String channel, MessageHandler? handler);
}
