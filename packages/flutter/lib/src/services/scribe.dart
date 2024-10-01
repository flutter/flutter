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

  final Set<ScribeClient> _scribeClients = <ScribeClient>{};

  /// Tell Android to begin receiving stylus handwriting input.
  ///
  /// This is typically called after detecting the start of stylus input.
  ///
  /// Supported on Android API 33 and above.
  static Future<void> startStylusHandwriting() {
    return _instance._channel.invokeMethod<void>(
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

  static void registerScribeClient(ScribeClient scribeClient) {
    _instance._scribeClients.add(scribeClient);
    // TODO(justinmc): Support Scribe hover icon by sending the Rect of each
    // ScribeClient currently on screen to the engine.
    // https://github.com/flutter/flutter/issues/155948
  }

  static void unregisterScribeClient(ScribeClient scribeClient) {
    _instance._scribeClients.remove(scribeClient);
  }

  ScribeClient? get activeScribeClient {
    final Iterable<ScribeClient> activeClients = _scribeClients.where((ScribeClient client) {
      return client.isActive;
    });
    assert(activeClients.length <= 1);
    return activeClients.firstOrNull;
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
    switch (methodCall.method) {
      case 'ScribeClient.performHandwritingGesture':
        assert(activeScribeClient != null);
        print('Justin ScribeClient.performHandwritingGesture with args ${methodCall.arguments}');
        // TODO(justinmc): Create enums and stuff to parse the argument.
        return activeScribeClient!.performHandwritingGesture();
      case 'ScribeClient.performSelectionGesture':
        assert(activeScribeClient != null);
        final List<dynamic> args = methodCall.arguments as List<dynamic>;
        assert(args.length == 1, 'ScribeClient.performSelectionGesture should send a single Rect as its args');
        final Rect selectionArea = _getSelectionArea(args, activeScribeClient!.devicePixelRatio);
        return activeScribeClient!.performSelectionGesture(selectionArea);
    }
  }
}

/// An interface into Android's stylus handwriting text input.

/// A mixin that to receive focus from the engine.
///
/// This is currently only used to handle UIIndirectScribbleInteraction.
mixin ScribeClient {
  bool get isActive;

  // TODO(justinmc): Double check about providing an implementation and breaking
  // changes. If you add a new method, will users break?
  /// Called when Android receives a handwriting gesture.
  ///
  /// See also:
  ///
  ///  * Android's
  ///    [InputConnection.performHandwritingGesture](https://developer.android.com/reference/android/view/inputmethod/InputConnection#performHandwritingGesture(android.view.inputmethod.HandwritingGesture,%20java.util.concurrent.Executor,%20java.util.function.IntConsumer))
  ///    method, from which the engine calls through to this method.
  Future<bool> performHandwritingGesture() {
    throw UnimplementedError();
  }

  // TODO(justinmc): Is there a cleaner way to adjust for the device pixel ratio?
  double get devicePixelRatio;
}
