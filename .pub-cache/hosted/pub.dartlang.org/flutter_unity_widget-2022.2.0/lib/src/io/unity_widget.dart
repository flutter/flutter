import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../facade_controller.dart';
import '../helpers/misc.dart';
import 'device_method.dart';
import 'mobile_unity_widget_controller.dart';
import 'unity_widget_platform.dart';

int _nextUnityCreationId = 0;

/// Android specific settings for [UnityWidget].
class AndroidUnityWidgetFlutter {
  /// Whether to render [UnityWidget] with a [AndroidViewSurface] to build the Flutter Unity widget.
  ///
  /// This implementation uses hybrid composition to render the Flutter Unity
  /// Widget on Android. This comes at the cost of some performance on Android
  /// versions below 10. See
  /// https://flutter.dev/docs/development/platform-integration/platform-views#performance for more
  /// information.
  ///
  /// Defaults to true.
  static bool get useAndroidViewSurface {
    final UnityWidgetPlatform platform = UnityWidgetPlatform.instance;
    if (platform is MethodChannelUnityWidget) {
      return platform.useAndroidViewSurface;
    }
    return false;
  }

  /// Set whether to render [UnityWidget] with a [AndroidViewSurface] to build the Flutter Unity widget.
  ///
  /// This implementation uses hybrid composition to render the Unity Widget
  /// Widget on Android. This comes at the cost of some performance on Android
  /// versions below 10. See
  /// https://flutter.dev/docs/development/platform-integration/platform-views#performance for more
  /// information.
  ///
  /// Defaults to true.
  static set useAndroidViewSurface(bool useAndroidViewSurface) {
    final UnityWidgetPlatform platform = UnityWidgetPlatform.instance;
    if (platform is MethodChannelUnityWidget) {
      platform.useAndroidViewSurface = useAndroidViewSurface;
    }
  }
}

typedef MobileUnityWidgetState = _UnityWidgetState;

class UnityWidget extends StatefulWidget {
  UnityWidget({
    Key? key,
    required this.onUnityCreated,
    this.onUnityMessage,
    this.fullscreen = false,
    this.enablePlaceholder = false,
    this.runImmediately = false,
    this.unloadOnDispose = false,
    this.printSetupLog = true,
    this.onUnityUnloaded,
    this.gestureRecognizers,
    this.placeholder,
    this.useAndroidViewSurface = false,
    this.onUnitySceneLoaded,
    this.uiLevel = 1,
    this.borderRadius = BorderRadius.zero,
    this.layoutDirection,
    this.hideStatus = false,
    this.webUrl,
  });

  ///Event fires when the unity player is created.
  final UnityCreatedCallback onUnityCreated;

  /// WebGL url source.
  final String? webUrl;

  ///Event fires when the [UnityWidget] gets a message from unity.
  final UnityMessageCallback? onUnityMessage;

  ///Event fires when the [UnityWidget] gets a scene loaded from unity.
  final UnitySceneChangeCallback? onUnitySceneLoaded;

  ///Event fires when the [UnityWidget] unity player gets unloaded.
  final UnityUnloadCallback? onUnityUnloaded;

  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// Set to true to force unity to fullscreen
  final bool fullscreen;

  /// Set to true to force unity to fullscreen
  final bool hideStatus;

  /// Controls the layer in which unity widget is rendered in flutter (defaults to 1)
  final int uiLevel;

  /// This flag tells android to load unity as the flutter app starts (Android only)
  final bool runImmediately;

  /// This flag tells android to unload unity whenever widget is disposed
  final bool unloadOnDispose;

  /// This flag enables placeholder widget
  final bool enablePlaceholder;

  /// This flag enables placeholder widget
  final bool printSetupLog;

  /// This flag allows you use AndroidView instead of PlatformViewLink for android
  final bool? useAndroidViewSurface;

  /// This is just a helper to render a placeholder widget
  final Widget? placeholder;

  /// Border radius
  final BorderRadius borderRadius;

  /// The layout direction to use for the embedded view.
  ///
  /// If this is null, the ambient [Directionality] is used instead. If there is
  /// no ambient [Directionality], [TextDirection.ltr] is used.
  final TextDirection? layoutDirection;

  @override
  _UnityWidgetState createState() => _UnityWidgetState();
}

class _UnityWidgetState extends State<UnityWidget> {
  late int _unityId;

  UnityWidgetController? _controller;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _unityId = _nextUnityCreationId++;
    } else {
      _unityId = 0;
    }
  }

  @override
  Future<void> dispose() async {
    if (!kIsWeb) {
      if (_nextUnityCreationId > 0) --_nextUnityCreationId;
    }
    try {
      _controller?.dispose();
      _controller = null;
    } catch (e) {
      // todo: implement
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> unityOptions = <String, dynamic>{
      'fullscreen': widget.fullscreen,
      'uiLevel': widget.uiLevel,
      'hideStatus': widget.hideStatus,
      'unloadOnDispose': widget.unloadOnDispose,
      'runImmediately': widget.runImmediately,
    };

    if (widget.enablePlaceholder) {
      return widget.placeholder ??
          Text('Placeholder mode enabled, no native code will be called');
    }

    return UnityWidgetPlatform.instance.buildViewWithTextDirection(
      _unityId,
      _onPlatformViewCreated,
      unityOptions: unityOptions,
      textDirection: widget.layoutDirection ??
          Directionality.maybeOf(context) ??
          TextDirection.ltr,
      gestureRecognizers: widget.gestureRecognizers,
      useAndroidViewSurf: widget.useAndroidViewSurface,
      unitySrcUrl: widget.webUrl,
    );
  }

  Future<void> _onPlatformViewCreated(int id) async {
    final controller = await MobileUnityWidgetController.init(id, this);
    _controller = controller;
    widget.onUnityCreated(controller);

    if (widget.printSetupLog) {
      log('*********************************************');
      log('** flutter unity controller setup complete **');
      log('*********************************************');
    }
  }
}
