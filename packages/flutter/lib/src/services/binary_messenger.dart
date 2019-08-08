// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'binding.dart';

/// A function which takes a platform message and asynchronously returns an encoded response.
typedef MessageHandler = Future<ByteData> Function(ByteData message);

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
  Future<void> handlePlatformMessage(String channel, ByteData data, ui.PlatformMessageResponseCallback callback);

  /// Send a binary message to the platform plugins on the given channel.
  ///
  /// Returns a [Future] which completes to the received response, undecoded,
  /// in binary form.
  Future<ByteData> send(String channel, ByteData message);

  /// Set a callback for receiving messages from the platform plugins on the
  /// given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered callback for that
  /// channel, if any. To remove the handler, pass null as the [handler]
  /// argument.
  ///
  /// The handler's return value, if non-null, is sent as a response, unencoded.
  void setMessageHandler(String channel, Future<ByteData> handler(ByteData message));

  /// Set a mock callback for intercepting messages from the [send] method on
  /// this class, on the given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// that channel, if any. To remove the mock handler, pass null as the
  /// [handler] argument.
  ///
  /// The handler's return value, if non-null, is used as a response, unencoded.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  void setMockMessageHandler(String channel, Future<ByteData> handler(ByteData message));
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
@Deprecated('Use ServicesBinding.instance.defaultBinaryMessenger instead.')
BinaryMessenger get defaultBinaryMessenger => ServicesBinding.instance.defaultBinaryMessenger;
