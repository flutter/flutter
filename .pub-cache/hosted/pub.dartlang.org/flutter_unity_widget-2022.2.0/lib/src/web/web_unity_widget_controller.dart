import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:stream_transform/stream_transform.dart';

import '../facade_controller.dart';
import '../helpers/events.dart';
import '../helpers/misc.dart';
import '../helpers/types.dart';
import 'unity_widget.dart';

class UnityWebEvent {
  UnityWebEvent({
    required this.name,
    this.data,
  });
  final String name;
  final dynamic data;
}

class WebUnityWidgetController extends UnityWidgetController {
  final WebUnityWidgetState _unityWidgetState;

  static Registrar? webRegistrar;

  late html.MessageEvent _unityFlutterBiding;
  late html.MessageEvent _unityFlutterBidingFn;

  bool unityReady = false;
  bool unityPause = true;

  MethodChannel? _channel;

  /// used for cancel the subscription
  StreamSubscription? _onUnityMessageSub,
      _onUnitySceneLoadedSub,
      _onUnityUnloadedSub;

  // The controller we need to broadcast the different events coming
  // from handleMethodCall.
  //
  // It is a `broadcast` because multiple controllers will connect to
  // different stream views of this Controller.
  final StreamController<UnityEvent> _unityStreamController =
      StreamController<UnityEvent>.broadcast();

  // Returns a filtered view of the events in the _controller, by unityId.
  Stream<UnityEvent> get _events => _unityStreamController.stream;

  WebUnityWidgetController._(this._unityWidgetState) {
    _channel = ensureChannelInitialized();
    _connectStreams();
    _registerEvents();
  }

  /// Accesses the MethodChannel associated to the passed unityId.
  MethodChannel get channel {
    MethodChannel? channel = _channel;
    if (channel == null) {
      throw UnknownUnityIDError(0);
    }
    return channel;
  }

  // /// Initialize [UnityWidgetController] with [id]
  // /// Mainly for internal use when instantiating a [UnityWidgetController] passed
  // /// in [UnityWidget.onUnityCreated] callback.
  static Future<WebUnityWidgetController> init(
      int id, WebUnityWidgetState unityWidgetState) async {
    return WebUnityWidgetController._(
      unityWidgetState,
    );
  }

  /// Method required for web initialization
  static void registerWith(Registrar registrar) {
    webRegistrar = registrar;
  }

  MethodChannel ensureChannelInitialized() {
    MethodChannel? channel = _channel;
    if (channel == null) {
      channel = MethodChannel(
        'plugin.xraph.com/unity_view',
        const StandardMethodCodec(),
        webRegistrar,
      );

      channel.setMethodCallHandler(_handleMessages);
      _channel = channel;
    }
    return channel;
  }

  _registerEvents() {
    if (kIsWeb) {
      html.window.addEventListener('message', (event) {
        final raw = (event as html.MessageEvent).data.toString();
        // ignore: unnecessary_null_comparison
        if (raw == '' || raw == null) return;
        if (raw == 'unityReady') {
          unityReady = true;
          unityPause = false;

          _unityStreamController.add(UnityCreatedEvent(0, {}));
          return;
        }

        _processEvents(UnityWebEvent(
          name: event.data['name'],
          data: event.data['data'],
        ));
      });
    }
  }

  void _connectStreams() {
    if (_unityWidgetState.widget.onUnityMessage != null) {
      _onUnityMessageSub = _events.whereType<UnityMessageEvent>().listen(
          (UnityMessageEvent e) =>
              _unityWidgetState.widget.onUnityMessage!(e.value));
    }

    if (_unityWidgetState.widget.onUnitySceneLoaded != null) {
      _onUnitySceneLoadedSub = _events
          .whereType<UnitySceneLoadedEvent>()
          .listen((UnitySceneLoadedEvent e) =>
              _unityWidgetState.widget.onUnitySceneLoaded!(e.value));
    }

    if (_unityWidgetState.widget.onUnityUnloaded != null) {
      _onUnityUnloadedSub = _events
          .whereType<UnityLoadedEvent>()
          .listen((_) => _unityWidgetState.widget.onUnityUnloaded!());
    }
  }

  void _processEvents(UnityWebEvent e) {
    switch (e.name) {
      case 'onUnityMessage':
        _unityStreamController.add(UnityMessageEvent(0, e.data));
        break;
      case 'onUnitySceneLoaded':
        _unityStreamController
            .add(UnitySceneLoadedEvent(0, SceneLoaded.fromMap(e.data)));
        break;
    }
  }

  Future<dynamic> _handleMessages(MethodCall call) {
    switch (call.method) {
      case "unity#waitForUnity":
        return Future.value(null);
      case "unity#dispose":
        dispose();
        return Future.value(null);
      case "unity#postMessage":
        messageUnity(
          gameObject: call.arguments['gameObject'],
          methodName: call.arguments['methodName'],
          message: call.arguments['message'],
        );
        return Future.value(null);
      case "unity#resumePlayer":
        callUnityFn(fnName: 'resume');
        return Future.value(null);
      case "unity#pausePlayer":
        callUnityFn(fnName: 'pause');
        return Future.value(null);
      case "unity#unloadPlayer":
        callUnityFn(fnName: 'unload');
        return Future.value(null);
      case "unity#quitPlayer":
        callUnityFn(fnName: 'quit');
        return Future.value(null);
      default:
        throw UnimplementedError("Unimplemented ${call.method} method");
    }
  }

  void callUnityFn({required String fnName}) {
    if (kIsWeb) {
      _unityFlutterBidingFn = html.MessageEvent(
        'unityFlutterBidingFnCal',
        data: fnName,
      );
      html.window.dispatchEvent(_unityFlutterBidingFn);
    }
  }

  void messageUnity({
    required String gameObject,
    required String methodName,
    required String message,
  }) {
    if (kIsWeb) {
      _unityFlutterBiding = html.MessageEvent(
        'unityFlutterBiding',
        data: json.encode({
          "gameObject": gameObject,
          "methodName": methodName,
          "message": message,
        }),
      );
      html.window.dispatchEvent(_unityFlutterBiding);
      postProcess();
    }
  }

  /// This method makes sure Unity has been refreshed and is ready to receive further messages.
  void postProcess() {
    html.Element? frame = html.document
        .querySelector('flt-platform-view')
        ?.querySelector('iframe');

    if (frame != null) {
      (frame as html.IFrameElement).focus();
    }
  }

  @override
  Future<void>? postMessage(
    String gameObject,
    dynamic methodName,
    dynamic message,
  ) async {
    messageUnity(
      gameObject: gameObject,
      methodName: methodName,
      message: message,
    );
  }

  @override
  Future<void> postJsonMessage(
    String gameObject,
    String methodName,
    Map<String, dynamic> message,
  ) async {
    messageUnity(
      gameObject: gameObject,
      methodName: methodName,
      message: json.encode(message),
    );
  }

  @override
  Future<void> pause() async {
    callUnityFn(fnName: 'pause');
  }

  @override
  Future<void> resume() async {
    callUnityFn(fnName: 'resume');
  }

  @override
  Future<void> openInNativeProcess() async {
    await channel.invokeMethod('unity#openInNativeProcess');
  }

  @override
  Future<void> unload() async {
    callUnityFn(fnName: 'unload');
  }

  @override
  Future<void> quit() async {
    callUnityFn(fnName: 'quit');
  }

  /// cancel the subscriptions when dispose called
  void _cancelSubscriptions() {
    _onUnityMessageSub?.cancel();
    _onUnitySceneLoadedSub?.cancel();
    _onUnityUnloadedSub?.cancel();

    _onUnityMessageSub = null;
    _onUnitySceneLoadedSub = null;
    _onUnityUnloadedSub = null;
  }

  void dispose() {
    _cancelSubscriptions();
    if (kIsWeb) {
      html.window.removeEventListener('message', (_) {});
      html.window.removeEventListener('unityFlutterBiding', (event) {});
      html.window.removeEventListener('unityFlutterBidingFnCal', (event) {});
    }
  }
}
