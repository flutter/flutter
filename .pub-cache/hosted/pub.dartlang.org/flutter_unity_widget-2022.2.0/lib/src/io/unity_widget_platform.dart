import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../helpers/events.dart';
import 'device_method.dart';

abstract class UnityWidgetPlatform extends PlatformInterface {
  /// Constructs a UnityViewFlutterPlatform.
  UnityWidgetPlatform() : super(token: _token);

  static final Object _token = Object();

  static UnityWidgetPlatform _instance = MethodChannelUnityWidget();

  /// The default instance of [UnityWidgetPlatform] to use.
  ///
  /// Defaults to [MethodChannelUnityWidgetFlutter].
  static UnityWidgetPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [UnityWidgetPlatform] when they register themselves.
  static set instance(UnityWidgetPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// /// Initializes the platform interface with [id].
  ///
  /// This method is called when the plugin is first initialized.
  Future<void> init(int unityId) {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<bool?> isReady({required int unityId}) async {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<bool?> isPaused({required int unityId}) async {
    throw UnimplementedError('isPaused() has not been implemented.');
  }

  Future<bool?> isLoaded({required int unityId}) async {
    throw UnimplementedError('isLoaded() has not been implemented.');
  }

  Future<bool?> inBackground({required int unityId}) async {
    throw UnimplementedError('inBackground() has not been implemented.');
  }

  Future<bool?> createUnityPlayer({required int unityId}) async {
    throw UnimplementedError('createUnityPlayer() has not been implemented.');
  }

  Future<void> postMessage(
      {required int unityId,
      required String gameObject,
      required String methodName,
      required String message}) {
    throw UnimplementedError('postMessage() has not been implemented.');
  }

  Future<void> postJsonMessage(
      {required int unityId,
      required String gameObject,
      required String methodName,
      required Map message}) {
    throw UnimplementedError('postJsonMessage() has not been implemented.');
  }

  Future<void> pausePlayer({required int unityId}) async {
    throw UnimplementedError('pausePlayer() has not been implemented.');
  }

  Future<void> resumePlayer({required int unityId}) async {
    throw UnimplementedError('resumePlayer() has not been implemented.');
  }

  /// Opens unity in it's own activity. Android only.
  Future<void> openInNativeProcess({required int unityId}) async {
    throw UnimplementedError('openInNativeProcess() has not been implemented.');
  }

  Future<void> unloadPlayer({required int unityId}) async {
    throw UnimplementedError('unloadPlayer() has not been implemented.');
  }

  Future<void> quitPlayer({required int unityId}) async {
    throw UnimplementedError('quitPlayer() has not been implemented.');
  }

  Stream<UnityMessageEvent> onUnityMessage({required int unityId}) {
    throw UnimplementedError('onUnityMessage() has not been implemented.');
  }

  Stream<UnityLoadedEvent> onUnityUnloaded({required int unityId}) {
    throw UnimplementedError('onUnityUnloaded() has not been implemented.');
  }

  Stream<UnityCreatedEvent> onUnityCreated({required int unityId}) {
    throw UnimplementedError('onUnityUnloaded() has not been implemented.');
  }

  Stream<UnitySceneLoadedEvent> onUnitySceneLoaded({required int unityId}) {
    throw UnimplementedError('onUnitySceneLoaded() has not been implemented.');
  }

  /// Dispose of whatever resources the `unityId` is holding on to.
  void dispose({required int unityId}) {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  /// Returns a widget displaying the unity view
  Widget buildView(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    Map<String, dynamic> unityOptions = const {},
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    bool? useAndroidViewSurf,
    String? unitySrcUrl,
  }) {
    throw UnimplementedError('buildView() has not been implemented.');
  }

  /// Returns a widget displaying the unity view.
  ///
  /// This method is similar to [buildView], but contains a parameter for
  /// platforms that require a text direction.
  ///
  /// Default behavior passes all parameters except `textDirection` to
  /// [buildView]. This is for backward compatibility with existing
  /// implementations. Platforms that use the text direction should override
  /// this as the primary implementation, and delegate to it from buildView.
  Widget buildViewWithTextDirection(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required TextDirection textDirection,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    Map<String, dynamic> unityOptions = const <String, dynamic>{},
    bool? useAndroidViewSurf,
    String? unitySrcUrl,
  }) {
    return buildView(
      creationId,
      onPlatformViewCreated,
      gestureRecognizers: gestureRecognizers,
      unityOptions: unityOptions,
      useAndroidViewSurf: useAndroidViewSurf,
      unitySrcUrl: unitySrcUrl,
    );
  }
}
