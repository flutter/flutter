// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'javascript_message.dart';

/// Callback type for handling messages sent from JavaScript running in a web view.
typedef JavascriptMessageHandler = void Function(JavascriptMessage message);

final RegExp _validChannelNames = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');

/// A named channel for receiving messaged from JavaScript code running inside a web view.
class JavascriptChannel {
  /// Constructs a JavaScript channel.
  ///
  /// The parameters `name` and `onMessageReceived` must not be null.
  JavascriptChannel({
    required this.name,
    required this.onMessageReceived,
  }) : assert(_validChannelNames.hasMatch(name));

  /// The channel's name.
  ///
  /// Passing this channel object as part of a [WebView.javascriptChannels] adds a channel object to
  /// the JavaScript window object's property named `name`.
  ///
  /// The name must start with a letter or underscore(_), followed by any combination of those
  /// characters plus digits.
  ///
  /// Note that any JavaScript existing `window` property with this name will be overridden.
  ///
  /// See also [WebView.javascriptChannels] for more details on the channel registration mechanism.
  final String name;

  /// A callback that's invoked when a message is received through the channel.
  final JavascriptMessageHandler onMessageReceived;
}
