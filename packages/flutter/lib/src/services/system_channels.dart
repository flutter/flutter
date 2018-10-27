// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'message_codecs.dart';
import 'platform_channel.dart';

/// Platform channels used by the Flutter system.
class SystemChannels {
  SystemChannels._();

  /// A JSON [MethodChannel] for navigation.
  ///
  /// The following incoming methods are defined for this channel (registered
  /// using [MethodChannel.setMethodCallHandler]):
  ///
  ///  * `popRoute`, which is called when the system wants the current route to
  ///    be removed (e.g. if the user hits a system-level back button).
  ///
  ///  * `pushRoute`, which is called with a single string argument when the
  ///    operating system instructs the application to open a particular page.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver.didPopRoute] and
  ///    [WidgetsBindingObserver.didPushRoute], which expose this channel's
  ///    methods.
  static const MethodChannel navigation = MethodChannel(
      'flutter/navigation',
      JSONMethodCodec(),
  );

  /// A JSON [MethodChannel] for invoking miscellaneous platform methods.
  ///
  /// The following outgoing methods are defined for this channel (invoked using
  /// [OptionalMethodChannel.invokeMethod]):
  ///
  ///  * `Clipboard.setData`: Places the data from the `text` entry of the
  ///    argument, which must be a [Map], onto the system clipboard. See
  ///    [Clipboard.setData].
  ///
  ///  * `Clipboard.getData`: Returns the data that has the format specified in
  ///    the argument, a [String], from the system clipboard. The only format
  ///    currently supported is `text/plain` ([Clipboard.kTextPlain]). The
  ///    result is a [Map] with a single key, `text`. See [Clipboard.getData].
  ///
  ///  * `HapticFeedback.vibrate`: Triggers a system-default haptic response.
  ///    See [HapticFeedback.vibrate].
  ///
  ///  * `SystemSound.play`: Triggers a system audio effect. The argument must
  ///    be a [String] describing the desired effect; currently only `click` is
  ///    supported. See [SystemSound.play].
  ///
  ///  * `SystemChrome.setPreferredOrientations`: Informs the operating system
  ///    of the desired orientation of the display. The argument is a [List] of
  ///    values which are string representations of values of the
  ///    [DeviceOrientation] enum. See [SystemChrome.setPreferredOrientations].
  ///
  ///  * `SystemChrome.setApplicationSwitcherDescription`: Informs the operating
  ///    system of the desired label and color to be used to describe the
  ///    application in any system-level application lists (e.g. application
  ///    switchers). The argument is a [Map] with two keys, `label` giving a
  ///    [String] description, and `primaryColor` giving a 32 bit integer value
  ///    (the lower eight bits being the blue channel, the next eight bits being
  ///    the green channel, the next eight bits being the red channel, and the
  ///    high eight bits being set, as from [Color.value] for an opaque color).
  ///    The `primaryColor` can also be zero to indicate that the system default
  ///    should be used. See [SystemChrome.setPreferredOrientations].
  ///
  ///  * `SystemChrome.setEnabledSystemUIOverlays`: Specifies the set of system
  ///    overlays to have visible when the application is running. The argument
  ///    is a [List] of values which are string representations of values of the
  ///    [SystemUiOverlay] enum. See [SystemChrome.setEnabledSystemUIOverlays].
  ///
  ///  * `SystemChrome.setSystemUIOverlayStyle`: Specifies whether system
  ///    overlays (e.g. the status bar on Android or iOS) should be `light` or
  ///    `dark`. The argument is one of those two strings. See
  ///    [SystemChrome.setSystemUIOverlayStyle].
  ///
  ///  * `SystemNavigator.pop`: Tells the operating system to close the
  ///    application, or the closest equivalent. See [SystemNavigator.pop].
  ///
  /// Calls to methods that are not implemented on the shell side are ignored
  /// (so it is safe to call methods when the relevant plugin might be missing).
  static const MethodChannel platform = OptionalMethodChannel(
      'flutter/platform',
      JSONMethodCodec(),
  );

  /// A JSON [MethodChannel] for handling text input.
  ///
  /// This channel exposes a system text input control for interacting with IMEs
  /// (input method editors, for example on-screen keyboards). There is one
  /// control, and at any time it can have one active transaction. Transactions
  /// are represented by an integer. New Transactions are started by
  /// `TextInput.setClient`. Messages that are sent are assumed to be for the
  /// current transaction (the last "client" set by `TextInput.setClient`).
  /// Messages received from the shell side specify the transaction to which
  /// they apply, so that stale messages referencing past transactions can be
  /// ignored.
  ///
  /// The methods described below are wrapped in a more convenient form by the
  /// [TextInput] and [TextInputConnection] class.
  ///
  /// The following outgoing methods are defined for this channel (invoked using
  /// [OptionalMethodChannel.invokeMethod]):
  ///
  ///  * `TextInput.setClient`: Establishes a new transaction. The arguments is
  ///    a [List] whose first value is an integer representing a previously
  ///    unused transaction identifier, and the second is a [String] with a
  ///    JSON-encoded object with five keys, as obtained from
  ///    [TextInputConfiguration.toJSON]. This method must be invoked before any
  ///    others (except `TextInput.hide`). See [TextInput.attach].
  ///
  ///  * `TextInput.show`: Show the keyboard. See [TextInputConnection.show].
  ///
  ///  * `TextInput.setEditingState`: Update the value in the text editing
  ///    control. The argument is a [String] with a JSON-encoded object with
  ///    seven keys, as obtained from [TextEditingValue.toJSON]. See
  ///    [TextInputConnection.setEditingState].
  ///
  ///  * `TextInput.clearClient`: End the current transaction. The next method
  ///    called must be `TextInput.setClient` (or `TextInput.hide`). See
  ///    [TextInputConnection.close].
  ///
  ///  * `TextInput.hide`: Hide the keyboard. Unlike the other methods, this can
  ///    be called at any time. See [TextInputConnection.close].
  ///
  /// The following incoming methods are defined for this channel (registered
  /// using [MethodChannel.setMethodCallHandler]). In each case, the first argument
  /// is a transaction identifier. Calls for stale transactions should be ignored.
  ///
  ///  * `TextInputClient.updateEditingState`: The user has changed the contents
  ///    of the text control. The second argument is a [String] containing a
  ///    JSON-encoded object with seven keys, in the form expected by [new
  ///    TextEditingValue.fromJSON].
  ///
  ///  * `TextInputClient.performAction`: The user has triggered an action. The
  ///    second argument is a [String] consisting of the stringification of one
  ///    of the values of the [TextInputAction] enum.
  ///
  /// Calls to methods that are not implemented on the shell side are ignored
  /// (so it is safe to call methods when the relevant plugin might be missing).
  static const MethodChannel textInput = OptionalMethodChannel(
      'flutter/textinput',
      JSONMethodCodec(),
  );

  /// A JSON [BasicMessageChannel] for keyboard events.
  ///
  /// Each incoming message received on this channel (registered using
  /// [BasicMessageChannel.setMessageHandler]) consists of a [Map] with
  /// platform-specific data, plus a `type` field which is either `keydown`, or
  /// `keyup`.
  ///
  /// On Android, the available fields are those described by
  /// [RawKeyEventDataAndroid]'s properties.
  ///
  /// On Fuchsia, the available fields are those described by
  /// [RawKeyEventDataFuchsia]'s properties.
  ///
  /// No messages are sent on other platforms currently.
  ///
  /// See also:
  ///
  ///  * [RawKeyboard], which uses this channel to expose key data.
  ///  * [new RawKeyEvent.fromMessage], which can decode this data into the [RawKeyEvent]
  ///    subclasses mentioned above.
  static const BasicMessageChannel<dynamic> keyEvent = BasicMessageChannel<dynamic>(
      'flutter/keyevent',
      JSONMessageCodec(),
  );

  /// A string [BasicMessageChannel] for lifecycle events.
  ///
  /// Valid messages are string representations of the values of the
  /// [AppLifecycleState] enumeration. A handler can be registered using
  /// [BasicMessageChannel.setMessageHandler].
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver.didChangeAppLifecycleState], which triggers
  ///    whenever a message is received on this channel.
  static const BasicMessageChannel<String> lifecycle = BasicMessageChannel<String>(
      'flutter/lifecycle',
      StringCodec(),
  );

  /// A JSON [BasicMessageChannel] for system events.
  ///
  /// Events are exposed as [Map]s with string keys. The `type` key specifies
  /// the type of the event; the currently supported system event types are
  /// those listed below. A handler can be registered using
  /// [BasicMessageChannel.setMessageHandler].
  ///
  ///  * `memoryPressure`: Indicates that the operating system would like
  ///    applications to release caches to free up more memory. See
  ///    [WidgetsBindingObserver.didHaveMemoryPressure], which triggers whenever
  ///    a message is received on this channel.
  static const BasicMessageChannel<dynamic> system = BasicMessageChannel<dynamic>(
      'flutter/system',
      JSONMessageCodec(),
  );

  /// A [BasicMessageChannel] for accessibility events.
  ///
  /// See also:
  ///
  /// * [SemanticsEvent] and its subclasses for a list of valid accessibility
  ///   events that can be sent over this channel.
  /// * [SemanticsNode.sendEvent], which uses this channel to dispatch events.
  static const BasicMessageChannel<dynamic> accessibility = BasicMessageChannel<dynamic>(
    'flutter/accessibility',
    StandardMessageCodec(),
  );

  /// A [MethodChannel] for controlling platform views.
  ///
  /// See also: [PlatformViewsService] for the available operations on this channel.
  static const MethodChannel platform_views = MethodChannel(
    'flutter/platform_views',
    StandardMethodCodec(),
  );

}
