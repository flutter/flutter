// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'message_codec.dart';
import 'system_channels.dart';

/// An interface into Android's stylus handwriting text input.
///
/// This is typically used by implemeting the methods in [ScribeClient] in a
/// class, usually a [State], and setting an instance of it to [client]. The
/// relevant methods on [ScribeClient] will be called in response to method
/// channel calls on [SystemChannels.scribe].
///
/// See also:
///
///  * [EditableText.stylusHandwritingEnabled], which controls whether Flutter's
///    built-in text fields support handwriting input. On Android it uses this
///    class via [ScribeClient].
///  * [SystemChannels.scribe], which is the [MethodChannel] used by this
///    class, and which has a list of the methods that this class handles.
class Scribe {
  Scribe._() {
    _channel.setMethodCallHandler(_loudlyHandleScribeInputInvocation);
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

  static const MethodChannel _channel = SystemChannels.scribe;

  final Set<ScribeClient> _scribeClients = <ScribeClient>{};

  /// Returns true if the InputMethodManager supports Scribe stylus handwriting
  /// input.
  ///
  /// Call this before calling [startStylusHandwriting] to make sure it's
  /// available.
  ///
  /// Supported on Android API 34 and above.
  ///
  /// See also:
  ///
  /// * [https://developer.android.com/reference/android/view/inputmethod/InputMethodManager#isStylusHandwritingAvailable()],
  ///   which is the corresponding API on Android.
  static Future<bool?> isStylusHandwritingAvailable() {
    return _channel.invokeMethod<bool?>(
      'Scribe.isStylusHandwritingAvailable',
    );
  }

  /// Tell Android to begin receiving stylus handwriting input.
  ///
  /// This is typically called after detecting the start of stylus input.
  ///
  /// Supported on Android API 33 and above.
  ///
  /// See also:
  ///
  /// * [https://developer.android.com/reference/android/view/inputmethod/InputMethodManager#startStylusHandwriting(android.view.View)],
  ///   which is the corresponding API on Android.
  static Future<void> startStylusHandwriting() {
    return _channel.invokeMethod<void>(
      'Scribe.startStylusHandwriting',
    );
  }

  static Rect _getSelectionArea(List<dynamic> args, double devicePixelRatio) {
    final Map<dynamic, dynamic> argsMap = args.first as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> selectionAreaMap = argsMap['selectionArea'] as Map<dynamic, dynamic>;
    final Map<String, double> selectionAreaJson = selectionAreaMap.cast<String, double>();
    return Rect.fromLTRB(
      // Flutter uses logical pixels while Android uses physical pixels, so we
      // need to divide by the devicePixelRatio to convert.
      selectionAreaJson['left']! / devicePixelRatio,
      selectionAreaJson['top']! / devicePixelRatio,
      selectionAreaJson['right']! / devicePixelRatio,
      selectionAreaJson['bottom']! / devicePixelRatio,
    );
  }

  /// Registers a [ScribeClient] to receive Scribe input when
  /// [ScribeClient.isActive] is true.
  ///
  /// See also:
  ///
  ///  * [unregisterScribeClient], which removes a [ScribeClient] that has
  ///    previously been registered.
  static void registerScribeClient(ScribeClient scribeClient) {
    _instance._scribeClients.add(scribeClient);
    // TODO(justinmc): Support Scribe hover icon by sending the Rect of each
    // ScribeClient currently on screen to the engine.
    // https://github.com/flutter/flutter/issues/155948
  }

  /// Unregisters a [ScribeClient] that has previously been registered to
  /// receive Scribe input.
  ///
  /// See also:
  ///
  ///  * [registerScribeClient], which registers a [ScribeClient] to receive
  ///    Scribe input.
  static void unregisterScribeClient(ScribeClient scribeClient) {
    _instance._scribeClients.remove(scribeClient);
  }

  /// Returns the active registered [ScribeClient] with [ScribeClient.isActive].
  ///
  /// There should be a maximum of one active [ScribeClient] at any time.
  ///
  /// See also:
  ///
  ///  * [ScribeClient.registerScribeClient], which is how [ScribeClient]s
  ///    become registered.
  ///  * [ScribeClient.unregisterScribeClient], which is how [ScribeClient]s
  ///    that have previously been registered are removed.
  ScribeClient? get activeScribeClient {
    assert(() {
      final Iterable<ScribeClient> activeClients = _scribeClients.where((ScribeClient client) {
        return client.isActive;
      });
      return activeClients.length <= 1;
    }());

    for (final ScribeClient client in _scribeClients) {
      if (client.isActive) {
        return client;
      }
    }
    return null;
  }

  Future<dynamic> _loudlyHandleScribeInputInvocation(MethodCall call) async {
    try {
      return await _handleScribeInputInvocation(call);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'services library',
        context: ErrorDescription('during method call ${call.method}'),
        informationCollector: () => <DiagnosticsNode>[
          DiagnosticsProperty<MethodCall>('call', call, style: DiagnosticsTreeStyle.errorProperty),
        ],
      ));
      rethrow;
    }
  }

  Future<dynamic> _handleScribeInputInvocation(MethodCall methodCall) async {
    // TODO(justinmc): Scribe stylus gestures should be supported here.
    // https://github.com/flutter/flutter/issues/156018
    throw MissingPluginException();
  }
}

/// An interface into Android's stylus handwriting text input.
///
/// This is typically mixed into a [State].
///
/// See also:
///
///  * [ScribbleClient], which implements the iOS version of this feature,
///  [Scribble](https://support.apple.com/guide/ipad/enter-text-with-scribble-ipad355ab2a7/ipados).
mixin ScribeClient {
  bool get isActive;

  // TODO(justinmc): Is there a cleaner way to adjust for the device pixel ratio?
  double get devicePixelRatio;

  // TODO(justinmc): Scribe stylus gestures should be supported here.
  // https://github.com/flutter/flutter/issues/156018
}
