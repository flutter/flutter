// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Do not import this file in production applications or packages published
// to pub.dev. Flutter will make breaking changes to this file, even in patch
// versions.
//
// All APIs in this file must be private or must:
//
// 1. Have the `@internal` attribute.
// 2. Throw an  `UnsupportedError` if `isWindowingEnabled`
//    is `false.
//
// See: https://github.com/flutter/flutter/issues/30701.

import 'dart:ui' show AppExitType, Display, FlutterView;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../foundation/_features.dart';
import 'binding.dart';
import 'framework.dart';
import 'view.dart';

const String _windowingDisabledErrorMessage = '''
Windowing APIs are not enabled.
Windowing APIs are currently experimental. Do not use windowing APIs in
production applications or plugins published to pub.dev.

To try experimental windowing APIs:
1. Switch to Flutter's main release channel.
2. Turn on the windowing feature flag.

See: https://github.com/flutter/flutter/issues/30701.
''';

/// Defines the possible archetypes for a window.
///
/// {@template flutter.widgets.windowing.experimental}
/// Do not use this API in production applications or packages published to
/// pub.dev. Flutter will make breaking changes to this API, even in patch
/// versions.
///
/// This API throws an [UnsupportedError] error unless Flutter’s windowing
/// feature is enabled by [isWindowingEnabled].
///
/// See: https://github.com/flutter/flutter/issues/30701.
/// {@endtemplate}
@internal
enum WindowArchetype {
  /// Defines a traditional window
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  regular,
}

/// Defines sizing request for a window.
///
/// {@template flutter.widgets.windowing.experimental}
/// Do not use this API in production applications or packages published to
/// pub.dev. Flutter will make breaking changes to this API, even in patch
/// versions.
///
/// This API throws an [UnsupportedError] error unless Flutter’s windowing
/// feature is enabled by [isWindowingEnabled].
///
/// See: https://github.com/flutter/flutter/issues/30701.
/// {@endtemplate}
@internal
class WindowSizing {
  /// Creates a new [WindowSizing] object.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  WindowSizing({this.preferredSize, this.constraints}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_windowingDisabledErrorMessage);
    }
  }

  /// Preferred size of the window. This may not be honored by the platform.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  final Size? preferredSize;

  /// Constraints for the window. This may not be honored by the platform.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  final BoxConstraints? constraints;
}

/// Base class for window controllers.
///
/// A window controller must provide a [future] that resolves to a
/// a [WindowCreationResult] object. This object contains the view
/// associated with the window, the archetype of the window, the size
/// of the window, and the state of the window.
///
/// The caller may also provide a callback to be called when the window
/// is destroyed, and a callback to be called when an error is encountered
/// during the creation of the window.
///
/// Each [WindowController] is associated with exactly one root [FlutterView].
///
/// When the window is destroyed for any reason (either by the caller or by the
/// platform), the content of the controller will thereafter be invalid. Callers
/// may check if this content is invalid via the [isReady] property.
///
/// This class implements the [Listenable] interface, so callers can listen
/// for changes to the window's properties.
///
/// {@template flutter.widgets.windowing.experimental}
/// Do not use this API in production applications or packages published to
/// pub.dev. Flutter will make breaking changes to this API, even in patch
/// versions.
///
/// This API throws an [UnsupportedError] error unless Flutter’s windowing
/// feature is enabled by [isWindowingEnabled].
///
/// See: https://github.com/flutter/flutter/issues/30701.
/// {@endtemplate}
@internal
abstract class WindowController with ChangeNotifier {
  @protected
  /// Sets the view associated with this window.
  // ignore: use_setters_to_change_properties
  void setView(FlutterView view) {
    _view = view;
  }

  /// The archetype of the window.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  WindowArchetype get type;

  /// The current size of the window. This may differ from the requested size.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  Size get contentSize;

  /// Destroys this window. It is permissible to call this method multiple times.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  void destroy();

  /// The root view associated to this window, which is unique to each window.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  FlutterView get rootView => _view;
  late final FlutterView _view;
}

/// Delegate class for regular window controller.
///
/// {@template flutter.widgets.windowing.experimental}
/// Do not use this API in production applications or packages published to
/// pub.dev. Flutter will make breaking changes to this API, even in patch
/// versions.
///
/// This API throws an [UnsupportedError] error unless Flutter’s windowing
/// feature is enabled by [isWindowingEnabled].
///
/// See: https://github.com/flutter/flutter/issues/30701.
/// {@endtemplate}
@internal
mixin class RegularWindowControllerDelegate {
  /// Invoked when user attempts to close the window. Default implementation
  /// destroys the window. Subclass can override the behavior to delay
  /// or prevent the window from closing.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  void onWindowCloseRequested(RegularWindowController controller) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_windowingDisabledErrorMessage);
    }

    controller.destroy();
  }

  /// Invoked when the window is closed. Default implementation exits the
  /// application if this was the last top-level window.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  void onWindowDestroyed() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_windowingDisabledErrorMessage);
    }

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    if (!owner.hasTopLevelWindows()) {
      // No more top-level windows, exit the application.
      ServicesBinding.instance.exitApplication(AppExitType.cancelable);
    }
  }
}

/// A controller for a regular window.
///
/// A regular window is a traditional window that can be resized, minimized,
/// maximized, and closed. Upon construction, the window is created for the
/// platform with the provided properties.
///
/// This class does not interact with the widget tree. Instead, it is typically
/// provided to the [RegularWindow] widget, who does the work of rendering the
/// content inside of this window.
///
/// An example usage might look like:
/// ```dart
/// final RegularWindowController controller = RegularWindowController(
///   contentSize: const WindowSizing(
///     size: Size(800, 600),
///     constraints: BoxConstraints(minWidth: 640, minHeight: 480),
///   ),
///   title: "Example Window",
/// );
/// runWidget(RegularWindow(
///   controller: controller,
///   child: MaterialApp(home: Container())));
/// ```
///
/// When provided to a [RegularWindow] widget, widgets inside of the [child]
/// parameter will have access to the [RegularWindowController] via the
/// [WindowControllerContext] widget.
///
/// {@template flutter.widgets.windowing.experimental}
/// Do not use this API in production applications or packages published to
/// pub.dev. Flutter will make breaking changes to this API, even in patch
/// versions.
///
/// This API throws an [UnsupportedError] error unless Flutter’s windowing
/// feature is enabled by [isWindowingEnabled].
///
/// See: https://github.com/flutter/flutter/issues/30701.
/// {@endtemplate}
@internal
abstract class RegularWindowController extends WindowController {
  /// Creates a [RegularWindowController] with the provided properties.
  /// Upon construction, the window is created for the platform.
  ///
  /// [contentSize] sizing requests for the window. This may not be honored by the platform
  /// [title] the title of the window
  /// [state] the initial state of the window
  /// [delegate] optional delegate for the controller controller.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  factory RegularWindowController({
    required WindowSizing contentSize,
    String? title,
    RegularWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_windowingDisabledErrorMessage);
    }

    WidgetsFlutterBinding.ensureInitialized();
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    final RegularWindowController controller = owner.createRegularWindowController(
      contentSize: contentSize,
      delegate: delegate ?? RegularWindowControllerDelegate(),
    );
    if (title != null) {
      controller.setTitle(title);
    }
    return controller;
  }

  /// Creates an empty [RegularWindowController].
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  @protected
  RegularWindowController.empty();

  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  @override
  WindowArchetype get type => WindowArchetype.regular;

  /// Request change for the window content size.
  ///
  /// [contentSize] describes the new requested window size. The properties
  /// of this object are applied independently of each other. For example,
  /// setting [WindowSizing.preferredSize] does not affect the [WindowSizing.constraints]
  /// set previously.
  ///
  /// The platform is free to ignore the request.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  void updateContentSize(WindowSizing sizing);

  /// Request change for the window title.
  /// [title] new title of the window.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  void setTitle(String title);

  /// Requests that the window be displayed in its current size and position.
  /// If the window is minimized or maximized, the window returns to the size
  /// and position that it had before that state was applied.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  void activate();

  /// Requests the window to be maximized. This has no effect
  /// if the window is currently full screen or minimized, but may
  /// affect the window size upon restoring it from minimized or
  /// full screen state.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  void setMaximized(bool maximized);

  /// Returns whether window is currently maximized.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  bool isMaximized();

  /// Requests window to be minimized.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  void setMinimized(bool minimized);

  /// Returns whether window is currently minimized.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  bool isMinimized();

  /// Request change for the window to enter or exit fullscreen state.
  /// [fullscreen] whether to enter or exit fullscreen state.
  /// [displayId] optional [Display] identifier to use for fullscreen mode.
  /// Specifying the [displayId] might not be supported on all platforms.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  void setFullscreen(bool fullscreen, {int? displayId});

  /// Returns whether window is currently in fullscreen mode.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  bool isFullscreen();
}

/// [WindowingOwner] is responsible for creating and managing window controllers.
///
/// Custom subclass can be provided by subclassing [WidgetsBinding] and
/// overriding the [createWindowingOwner] method.
///
/// {@template flutter.widgets.windowing.experimental}
/// Do not use this API in production applications or packages published to
/// pub.dev. Flutter will make breaking changes to this API, even in patch
/// versions.
///
/// This API throws an [UnsupportedError] error unless Flutter’s windowing
/// feature is enabled by [isWindowingEnabled].
///
/// See: https://github.com/flutter/flutter/issues/30701.
/// {@endtemplate}
@internal
abstract class WindowingOwner {
  /// Creates a [RegularWindowController] with the provided properties.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  RegularWindowController createRegularWindowController({
    required WindowSizing contentSize,
    required RegularWindowControllerDelegate delegate,
  });

  /// Returns whether application has any top level windows created by this
  /// windowing owner.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  bool hasTopLevelWindows();

  /// Creates default windowing owner for standard desktop embedders.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  static WindowingOwner createDefaultOwner() {
    if (!isWindowingEnabled) {
      return _WindowingOwnerUnsupported(errorMessaage: _windowingDisabledErrorMessage);
    }

    // TODO(mattkae): Implement windowing owners for desktop platforms.
    return _WindowingOwnerUnsupported(errorMessaage: 'Windowing is unsupported on this platform.');
  }
}

/// Windowing delegate used on platforms that do not support windowing.
class _WindowingOwnerUnsupported extends WindowingOwner {
  _WindowingOwnerUnsupported({required this.errorMessaage});

  final String errorMessaage;

  @override
  RegularWindowController createRegularWindowController({
    required WindowSizing contentSize,
    required RegularWindowControllerDelegate delegate,
  }) {
    throw UnsupportedError(errorMessaage);
  }

  @override
  bool hasTopLevelWindows() {
    throw UnsupportedError(errorMessaage);
  }
}

/// The [RegularWindow] widget provides a way to render a regular window in the
/// widget tree. The provided [controller] creates the native window that backs
/// the widget. The [child] widget is rendered into this newly created window.
///
/// While the window is being created, the [RegularWindow] widget will render
/// an empty [ViewCollection] widget. Once the window is created, the [child]
/// widget will be rendered into the window inside of a [View].
///
/// An example usage might look like:
/// ```dart
/// final RegularWindowController controller = RegularWindowController(
///   contentSize: const WindowSizing(
///     size: Size(800, 600),
///     constraints: BoxConstraints(minWidth: 640, minHeight: 480),
///   ),
///   title: "Example Window",
/// );
/// runApp(RegularWindow(
///   controller: controller,
///   child: MaterialApp(home: Container())));
/// ```
///
/// When a [RegularWindow] widget is removed from the tree, the window that was created
/// by the [controller] is automatically destroyed if it has not yet been destroyed.
///
/// Widgets in the same tree as the [child] widget will have access to the
/// [RegularWindowController] via the [WindowControllerContext] widget.
///
/// {@template flutter.widgets.windowing.experimental}
/// Do not use this API in production applications or packages published to
/// pub.dev. Flutter will make breaking changes to this API, even in patch
/// versions.
///
/// This API throws an [UnsupportedError] error unless Flutter’s windowing
/// feature is enabled by [isWindowingEnabled].
///
/// See: https://github.com/flutter/flutter/issues/30701.
/// {@endtemplate}
class RegularWindow extends StatefulWidget {
  /// Creates a regular window widget.
  /// [controller] the controller for this window
  /// [child] the content to render into this window
  /// [key] the key for this widget
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  RegularWindow({super.key, required this.controller, required this.child}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_windowingDisabledErrorMessage);
    }
  }

  /// Controller for this widget.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  final RegularWindowController controller;

  /// The content rendered into this window.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  final Widget child;

  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  @override
  State<RegularWindow> createState() => _RegularWindowState();
}

class _RegularWindowState extends State<RegularWindow> {
  @override
  void dispose() {
    super.dispose();
    widget.controller.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return View(
      view: widget.controller.rootView,
      child: WindowControllerContext(controller: widget.controller, child: widget.child),
    );
  }
}

/// Provides descendants with access to the [WindowController] associated with
/// the window that is being rendered.
///
/// {@template flutter.widgets.windowing.experimental}
/// Do not use this API in production applications or packages published to
/// pub.dev. Flutter will make breaking changes to this API, even in patch
/// versions.
///
/// This API throws an [UnsupportedError] error unless Flutter’s windowing
/// feature is enabled by [isWindowingEnabled].
///
/// See: https://github.com/flutter/flutter/issues/30701.
/// {@endtemplate}
@internal
class WindowControllerContext extends InheritedWidget {
  /// Creates a new [WindowControllerContext]
  /// [controller] the controller associated with this window
  /// [child] the child widget
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  WindowControllerContext({super.key, required this.controller, required super.child}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_windowingDisabledErrorMessage);
    }
  }

  /// The controller associated with this window.
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  final WindowController controller;

  /// Returns the [WindowContext] if any
  ///
  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  static WindowController? of(BuildContext context) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_windowingDisabledErrorMessage);
    }

    return context.dependOnInheritedWidgetOfExactType<WindowControllerContext>()?.controller;
  }

  /// {@template flutter.widgets.windowing.experimental}
  /// Do not use this API in production applications or packages published to
  /// pub.dev. Flutter will make breaking changes to this API, even in patch
  /// versions.
  ///
  /// This API throws an [UnsupportedError] error unless Flutter’s windowing
  /// feature is enabled by [isWindowingEnabled].
  ///
  /// See: https://github.com/flutter/flutter/issues/30701.
  /// {@endtemplate}
  @internal
  @override
  bool updateShouldNotify(WindowControllerContext oldWidget) {
    return controller != oldWidget.controller;
  }
}
