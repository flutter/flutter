import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlatformUnityWidget {
  FakePlatformUnityWidget(int id, Map<dynamic, dynamic> params)
      : channel = MethodChannel(
            'plugin.xraph.com/unity_view_$id', const StandardMethodCodec()) {
    channel.setMockMethodCallHandler(onMethodCall);
  }

  MethodChannel channel;

  bool playerCreated = false;
  bool playerUnloaded = false;
  bool unityReady = false;
  bool? unityPaused = null;
  bool? unityInBackground = null;
  List<Map<String, dynamic>> _sentMessages = [];

  Future<dynamic> onMethodCall(MethodCall call) {
    switch (call.method) {
      case 'unity#waitForUnity':
        return Future<bool?>.sync(() => unityReady);
      case 'unity#isPaused':
        return Future<bool?>.sync(() => unityPaused);
      case 'unity#isReady':
        return Future<bool>.sync(() => unityReady);
      case 'unity#isLoaded':
        return Future<bool>.sync(() => playerUnloaded);
      case 'unity#inBackground':
        final res = inBackground();
        return Future<void>.sync(() => res);
      case 'unity#createPlayer':
        final res = create();
        return Future<bool?>.sync(() => res);
      default:
        return Future<void>.sync(() {});
    }
  }

  bool isReady() {
    return unityReady;
  }

  bool? isPaused() {
    return unityPaused;
  }

  bool isLoaded() {
    return playerUnloaded;
  }

  bool? inBackground() {
    return unityInBackground;
  }

  Future<bool?>? create() {
    playerCreated = true;
    unityPaused = false;
    playerUnloaded = false;
    unityReady = true;
    return null;
  }

  Future<void>? postMessage(String gameObject, methodName, message) {
    _sentMessages.add(<String, dynamic>{
      'gameObject': gameObject,
      'methodName': methodName,
      'message': message,
    });
    return null;
  }

  Future<void>? postJsonMessage(
      String gameObject, String methodName, Map<String, dynamic> message) {
    _sentMessages.add(<String, dynamic>{
      'gameObject': gameObject,
      'methodName': methodName,
      'message': message,
    });
    return null;
  }

  Future<void>? pause() {
    unityPaused = true;
    return null;
  }

  Future<void>? resume() {
    unityPaused = false;
    return null;
  }

  Future<void>? openInNativeProcess() {
    return null;
  }

  Future<void>? unload() {
    playerUnloaded = true;
    return null;
  }

  Future<void>? quit() {
    return null;
  }
}

class FakePlatformViewsController {
  FakePlatformUnityWidget? lastCreatedView;

  Future<dynamic> fakePlatformViewsMethodHandler(MethodCall call) {
    switch (call.method) {
      case 'create':
        final Map<dynamic, dynamic> args = call.arguments;
        final Map<dynamic, dynamic> params = _decodeParams(args['params'])!;
        lastCreatedView = FakePlatformUnityWidget(
          args['id'],
          params,
        );
        lastCreatedView?.create();
        return Future<int>.sync(() => 1);
      default:
        return Future<void>.sync(() {});
    }
  }

  void reset() {
    lastCreatedView = null;
  }
}

Map<dynamic, dynamic>? _decodeParams(Uint8List paramsMessage) {
  final ByteBuffer buffer = paramsMessage.buffer;
  final ByteData messageBytes = buffer.asByteData(
    paramsMessage.offsetInBytes,
    paramsMessage.lengthInBytes,
  );
  return const StandardMessageCodec().decodeMessage(messageBytes);
}
