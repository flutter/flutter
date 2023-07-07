import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_unity_widget/src/facade_controller.dart';

import 'helpers/misc.dart';

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
  });

  ///Event fires when the unity player is created.
  final UnityCreatedCallback onUnityCreated;

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
  @override
  Widget build(BuildContext context) {
    return Text(
        '$defaultTargetPlatform is not yet supported by the unity player plugin');
  }
}
