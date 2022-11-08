// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'message_codec.dart';
import 'platform_channel.dart';
import 'system_channels.dart';

/// An interface into system-level handwriting text input.
///
/// This is typically used by implemeting the methods in [ScribbleClient] in a
/// class, usually a [State], and setting an instance of it to [client]. The
/// relevant methods on [ScribbleClient] will be called in response to method
/// channel calls on [SystemChannels.scribble].
///
/// Currently, handwriting input is supported in the iOS embedder with the Apple
/// Pencil.
///
/// [EditableText] uses this class via [ScribbleClient] to automatically support
/// handwriting input when [EditableText.scribbleEnabled] is set to true.
///
/// See also:
///
///  * [SystemChannels.scribble], which is the [MethodChannel] used by this
///    class, and which has a list of the methods that this class handles.
class Scribble {
  Scribble._() {
    _channel.setMethodCallHandler(_handleScribbleInvocation);
  }

  /// Ensure that a [Scribble] instance has been set up so that the platform
  /// can handle messages on the scribble method channel.
  static void ensureInitialized() {
    _instance; // ignore: unnecessary_statements
  }

  /// Set the [MethodChannel] used to communicate with the system's text input
  /// control.
  ///
  /// This is only meant for testing within the Flutter SDK. Changing this
  /// will break the ability to do handwriting input. This has no effect if
  /// asserts are disabled.
  @visibleForTesting
  static void setChannel(MethodChannel newChannel) {
    assert(() {
      _instance._channel = newChannel..setMethodCallHandler(_instance._handleScribbleInvocation);
      return true;
    }());
  }

  static final Scribble _instance = Scribble._();

  /// Set the given [ScribbleClient] as the single active client.
  ///
  /// This is usually based on the [ScribbleClient] receiving focus.
  static set client(ScribbleClient? client) {
    _instance._client = client;
  }

  /// Return the current active [ScribbleClient], or null if none.
  static ScribbleClient? get client => _instance._client;

  ScribbleClient? _client;

  MethodChannel _channel = SystemChannels.scribble;

  final Map<String, ScribbleClient> _scribbleClients = <String, ScribbleClient>{};
  bool _scribbleInProgress = false;

  /// Used for testing within the Flutter SDK to get the currently registered [ScribbleClient] list.
  @visibleForTesting
  static Map<String, ScribbleClient> get scribbleClients => Scribble._instance._scribbleClients;

  /// Returns true if a scribble interaction is currently happening.
  static bool get scribbleInProgress => _instance._scribbleInProgress;

  Future<dynamic> _handleScribbleInvocation(MethodCall methodCall) async {
    final String method = methodCall.method;
    if (method == 'Scribble.focusElement') {
      final List<dynamic> args = methodCall.arguments as List<dynamic>;
      _scribbleClients[args[0]]?.onScribbleFocus(Offset((args[1] as num).toDouble(), (args[2] as num).toDouble()));
      return;
    } else if (method == 'Scribble.requestElementsInRect') {
      final List<double> args = (methodCall.arguments as List<dynamic>).cast<num>().map<double>((num value) => value.toDouble()).toList();
      return _scribbleClients.keys.where((String elementIdentifier) {
        final Rect rect = Rect.fromLTWH(args[0], args[1], args[2], args[3]);
        if (!(_scribbleClients[elementIdentifier]?.isInScribbleRect(rect) ?? false)) {
          return false;
        }
        final Rect bounds = _scribbleClients[elementIdentifier]?.bounds ?? Rect.zero;
        return !(bounds == Rect.zero || bounds.hasNaN || bounds.isInfinite);
      }).map((String elementIdentifier) {
        final Rect bounds = _scribbleClients[elementIdentifier]!.bounds;
        return <dynamic>[elementIdentifier, ...<dynamic>[bounds.left, bounds.top, bounds.width, bounds.height]];
      }).toList();
    } else if (method == 'Scribble.scribbleInteractionBegan') {
      _scribbleInProgress = true;
      return;
    } else if (method == 'Scribble.scribbleInteractionFinished') {
      _scribbleInProgress = false;
      return;
    }

    // The methods below are only valid when a client exists, i.e. when a field
    // is focused.
    final ScribbleClient? client = _client;
    if (client == null) {
      return;
    }

    final List<dynamic> args = methodCall.arguments as List<dynamic>;
    switch (method) {
      case 'Scribble.showToolbar':
        client.showToolbar();
        break;
      case 'Scribble.insertTextPlaceholder':
        client.insertTextPlaceholder(Size((args[1] as num).toDouble(), (args[2] as num).toDouble()));
        break;
      case 'Scribble.removeTextPlaceholder':
        client.removeTextPlaceholder();
        break;
      default:
        throw MissingPluginException();
    }
  }

  /// Registers a [ScribbleClient] with [elementIdentifier] that can be focused
  /// by the engine.
  ///
  /// For example, the registered [ScribbleClient] list is used to respond to
  /// UIIndirectScribbleInteraction on an iPad.
  static void registerScribbleElement(String elementIdentifier, ScribbleClient scribbleClient) {
    _instance._scribbleClients[elementIdentifier] = scribbleClient;
  }

  /// Unregisters a [ScribbleClient] with [elementIdentifier].
  static void unregisterScribbleElement(String elementIdentifier) {
    _instance._scribbleClients.remove(elementIdentifier);
  }

  List<SelectionRect> _cachedSelectionRects = <SelectionRect>[];

  /// Send the bounding boxes of the current selected glyphs in the client to
  /// the platform's text input plugin.
  ///
  /// These are used by the engine during a UIDirectScribbleInteraction.
  static void setSelectionRects(List<SelectionRect> selectionRects) {
    if (!listEquals(_instance._cachedSelectionRects, selectionRects)) {
      _instance._cachedSelectionRects = selectionRects;
      _instance._channel.invokeMethod<void>(
        'Scribble.setSelectionRects',
        selectionRects.map((SelectionRect rect) {
          return <num>[rect.bounds.left, rect.bounds.top, rect.bounds.width, rect.bounds.height, rect.position];
        }).toList(),
      );
    }
  }
}

/// An interface to interact with the engine for handwriting text input.
///
/// This is currently only used to handle
/// [UIIndirectScribbleInteraction](https://developer.apple.com/documentation/uikit/uiindirectscribbleinteraction),
/// which is responsible for manually receiving handwritten text input in UIKit.
/// The Flutter engine uses this to receive handwriting input on Flutter text
/// input fields.
mixin ScribbleClient {
  /// A unique identifier for this element.
  String get elementIdentifier;

  /// Called by the engine when the [ScribbleClient] should receive focus.
  ///
  /// For example, this method is called during a UIIndirectScribbleInteraction.
  ///
  /// The [Offset] indicates the location where the focus event happened, which
  /// is typically where the cursor should be placed.
  void onScribbleFocus(Offset offset);

  /// Tests whether the [ScribbleClient] overlaps the given rectangle bounds,
  /// where the rectangle bounds are in global coordinates.
  bool isInScribbleRect(Rect rect);

  /// The current bounds of the [ScribbleClient].
  Rect get bounds;

  /// Requests that the client show the editing toolbar.
  ///
  /// This is used when the platform changes the selection during scribble
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

/// Represents a selection rect for a character and it's position in the text.
///
/// This is used to report the current text selection rect and position data
/// to the engine for Scribble support on iPadOS 14.
@immutable
class SelectionRect {
  /// Constructor for creating a [SelectionRect] from a text [position] and
  /// [bounds].
  const SelectionRect({required this.position, required this.bounds});

  /// The position of this selection rect within the text String.
  final int position;

  /// The rectangle representing the bounds of this selection rect within the
  /// currently focused [RenderEditable]'s coordinate space.
  final Rect bounds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is SelectionRect
        && other.position == position
        && other.bounds == bounds;
  }

  @override
  int get hashCode => Object.hash(position, bounds);

  @override
  String toString() => 'SelectionRect($position, $bounds)';
}
