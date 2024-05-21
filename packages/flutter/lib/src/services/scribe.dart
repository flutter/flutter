// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'system_channels.dart';

/// An interface into system-level handwriting text input.
///
/// This is typically used by implemeting the methods in [ScribeClient] in a
/// class, usually a [State], and setting an instance of it to [client]. The
/// relevant methods on [ScribeClient] will be called in response to method
/// channel calls on [SystemChannels.scribe].
///
/// Currently, handwriting input is supported in the iOS embedder with the Apple
/// Pencil.
///
/// [EditableText] uses this class via [ScribeClient] to automatically support
/// handwriting input when [EditableText.scribbleEnabled] is set to true.
///
/// See also:
///
///  * [SystemChannels.scribe], which is the [MethodChannel] used by this
///    class, and which has a list of the methods that this class handles.
class Scribe {
  Scribe._() {
    //_channel.setMethodCallHandler(_handleScribeInvocation);
  }

  /// Ensure that a [Scribe] instance has been set up so that the platform
  /// can handle messages on the scribe method channel.
  static void ensureInitialized() {
    _instance; // ignore: unnecessary_statements
  }

  static final Scribe _instance = Scribe._();

  /// Set the given [ScribeClient] as the single active client.
  ///
  /// This is usually based on the [ScribeClient] receiving focus.
  static set client(ScribeClient? client) {
    _instance._client = client;
  }

  /// Return the current active [ScribeClient], or null if none.
  static ScribeClient? get client => _instance._client;

  ScribeClient? _client;

  final MethodChannel _channel = SystemChannels.scribe;

  /// Tell Android to begin receiving stylus handwriting input.
  ///
  /// This is typically called after detecting the start of stylus input.
  ///
  /// Supported on Android API 33 and above.
  static void startStylusHandwriting() {
    _instance._channel.invokeMethod<void>(
      'Scribe.startStylusHandwriting',
    );
  }
}

/// An interface to interact with the engine for handwriting text input.
///
/// This is currently only used to handle
/// [UIIndirectScribbleInteraction](https://developer.apple.com/documentation/uikit/uiindirectscribbleinteraction),
/// which is responsible for manually receiving handwritten text input in UIKit.
/// The Flutter engine uses this to receive handwriting input on Flutter text
/// input fields.
mixin ScribeClient {
  /// A unique identifier for this element.
  String get elementIdentifier;

  /// Called by the engine when the [ScribeClient] should receive focus.
  ///
  /// For example, this method is called during a UIIndirectScribbleInteraction.
  ///
  /// The [Offset] indicates the location where the focus event happened, which
  /// is typically where the cursor should be placed.
  void onScribeFocus(Offset offset);

  /// Tests whether the [ScribeClient] overlaps the given rectangle bounds,
  /// where the rectangle bounds are in global coordinates.
  bool isInScribeRect(Rect rect);

  /// The current bounds of the [ScribeClient].
  Rect get bounds;

  /// Requests that the client show the editing toolbar.
  ///
  /// This is used when the platform changes the selection during scribe
  /// input.
  void showToolbar();

  /// Requests that the client add a text placeholder to reserve visual space
  /// in the text.
  ///
  /// For example, this is called when responding to UIKit requesting
  /// a text placeholder be added at the current selection, such as when
  /// requesting additional writing space with iPadOS14 Scribble.
  void insertTextPlaceholder(Size size);

  /// Requests that the client remove the text placeholder.
  void removeTextPlaceholder();
}
