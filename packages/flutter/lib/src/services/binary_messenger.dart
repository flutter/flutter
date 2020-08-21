// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'binding.dart';

/// A function which takes a platform message and asynchronously returns an encoded response.
typedef MessageHandler = Future<ByteData?> Function(ByteData? message);

/// A messenger which sends binary data across the Flutter platform barrier.
///
/// This class also registers handlers for incoming messages.
abstract class BinaryMessenger {
  /// A const constructor to allow subclasses to be const.
  const BinaryMessenger();

  /// Calls the handler registered for the given channel.
  ///
  /// Typically called by [ServicesBinding] to handle platform messages received
  /// from [Window.onPlatformMessage].
  ///
  /// To register a handler for a given message channel, see [setMessageHandler].
  Future<void> handlePlatformMessage(String channel, ByteData? data, ui.PlatformMessageResponseCallback? callback);

  /// Send a binary message to the platform plugins on the given channel.
  ///
  /// Returns a [Future] which completes to the received response, undecoded,
  /// in binary form.
  Future<ByteData?> send(String channel, ByteData? message);

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
  bool checkMockMessageHandler(String channel, MessageHandler? handler);
}

/// The default instance of [BinaryMessenger].
///
/// This API has been deprecated in favor of [ServicesBinding.defaultBinaryMessenger].
/// Please use [ServicesBinding.defaultBinaryMessenger] as the default
/// instance of [BinaryMessenger].
///
/// This is used to send messages from the application to the platform, and
/// keeps track of which handlers have been registered on each channel so
/// it may dispatch incoming messages to the registered handler.
@Deprecated(
  'Use ServicesBinding.instance.defaultBinaryMessenger instead. '
  'This feature was deprecated after v1.6.5.'
)
BinaryMessenger get defaultBinaryMessenger {
  assert(() {
    if (ServicesBinding.instance == null) {
      throw FlutterError(
        'ServicesBinding.defaultBinaryMessenger was accessed before the '
        'binding was initialized.\n'
        "If you're running an application and need to access the binary "
        'messenger before `runApp()` has been called (for example, during '
        'plugin initialization), then you need to explicitly call the '
        '`WidgetsFlutterBinding.ensureInitialized()` first.\n'
        "If you're running a test, you can call the "
        '`TestWidgetsFlutterBinding.ensureInitialized()` as the first line in '
        "your test's `main()` method to initialize the binding."
      );
    }
    return true;
  }());
  return ServicesBinding.instance!.defaultBinaryMessenger;
}
