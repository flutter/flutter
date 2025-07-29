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
// 2. Throw an `UnsupportedError` if `isWindowingEnabled`
//    is `false.
//
// See: https://github.com/flutter/flutter/issues/30701.

import 'dart:ui' show Display, FlutterView;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../foundation/_features.dart';
import 'binding.dart';
import 'framework.dart';
import 'view.dart';

const String _kWindowingDisabledErrorMessage = '''
Windowing APIs are not enabled.

Windowing APIs are currently experimental. Do not use windowing APIs in
production applications or plugins published to pub.dev.

To try experimental windowing APIs:
1. Switch to Flutter's main release channel.
2. Turn on the windowing feature flag.

See: https://github.com/flutter/flutter/issues/30701.
''';

/// Defines the possible types for a window.
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
enum WindowType {
  /// Defines a traditional window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  ///  * [RegularWindow], the widget for a regular window.
  ///  * [RegularWindowController], the controller that creates and manages regular windows.
  @internal
  regular,
}

/// Defines sizing request for a window.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
class WindowSizing {
  /// Creates a new [WindowSizing] object.
  ///
  /// Users may pass a [preferredSize] that does not satisfy the
  /// [preferredConstraints]. In this case, the platform will use an initial
  /// size that does satisfy the [preferredConstraints] instead.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  WindowSizing({this.preferredSize, this.preferredConstraints}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  /// Preferred size of the window.
  ///
  /// This might not be honored by the platform.
  ///
  /// This is the size that the platform will try to apply to the window
  /// when it is created. In contrast, the [preferredConstraints] field enforces
  /// the minimum and maximum size of the window. If the [preferredSize]
  /// does not satisfy the [preferredConstraints] or the [preferredSize] is null, then
  /// the platform will use an initial size that does satisfy the [preferredConstraints]
  /// instead.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final Size? preferredSize;

  /// Constraints for the window.
  ///
  /// This might not be honored by the platform.
  ///
  /// This field enforces a minimum and maximum size on the window. If the
  /// user attempts to resize the window beyond these constraints, the platform
  /// will enforce the constraints according to its own policy. For example, the
  /// platform might clip the content to fit within the resized window, or it might
  /// prevent the window from being resized altogether.
  ///
  /// If null, the window will be unconstrained.
  ///
  /// If the [preferredSize] is null, then the platform will use an
  /// initial size that satisfies the [preferredConstraints].
  ///
  /// If the [preferredSize] is not null and it does  not satisfy the
  /// [preferredConstraints], then the platform will use an
  /// initial size that does satisfy the [preferredConstraints] instead.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final BoxConstraints? preferredConstraints;
}

/// Base class for window controllers.
///
/// A [BaseWindowController] is associated with exactly one root [FlutterView].
///
/// When the window is destroyed for any reason (either by the caller or by the
/// platform), the content of the controller will thereafter be invalid.
///
/// This class implements the [Listenable] interface, so callers can listen
/// for changes to the window's properties.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [RegularWindowController], the controller for regular top-level windows.
@internal
abstract class BaseWindowController with ChangeNotifier {
  /// The type of the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  WindowType get type;

  /// The current size of the drawable area of the window.
  ///
  /// This might differ from the requested size.
  ///
  /// This might also differ from the actual size of the window if the window has
  /// decorations such as title bar, borders, etc.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  Size get contentSize;

  /// Destroys this window.
  ///
  /// It is permissible to call this method multiple times.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void destroy();

  /// The root view associated to this window, which is unique to each window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  FlutterView get rootView => _view;
  late final FlutterView _view;

  /// Sets the view associated with this window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @protected
  set rootView(FlutterView view) {
    _view = view;
  }
}

/// Delegate class for regular window controller.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [RegularWindowController], the controller that creates and manages regular windows.
///  * [RegularWindow], the widget for a regular window.
@internal
mixin class RegularWindowControllerDelegate {
  /// Invoked when user attempts to close the window.
  ///
  /// The default implementation destroys the window. Subclasses
  /// can override the behavior to delay or prevent the window from closing.
  ///
  /// See also:
  /// * [onWindowDestroyed], which is invoked after the window is closed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void onWindowCloseRequested(RegularWindowController controller) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    controller.destroy();
  }

  /// Invoked after the window is closed.
  ///
  /// See also:
  ///
  /// * [onWindowCloseRequested], which is invoked when the user attempts to close the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void onWindowDestroyed() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    if (!owner.hasTopLevelWindows()) {
      // TODO(mattkae): close the application if this is the last window
      // via ServicesBinding.instance.exitApplication(AppExitType.cancelable);
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
///     preferredSize: Size(800, 600),
///     preferredConstraints: BoxConstraints(minWidth: 640, minHeight: 480),
///   ),
///   title: "Example Window",
/// );
/// runWidget(
///   RegularWindow(
///     controller: controller,
///     child: MaterialApp(home: Container()),
///   ),
/// );
/// ```
///
/// When provided to a [RegularWindow] widget, widgets inside of the [child]
/// parameter will have access to the [RegularWindowController] via the
/// [WindowControllerContext] widget.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
abstract class RegularWindowController extends BaseWindowController {
  /// Creates a [RegularWindowController] with the provided properties.
  ///
  /// Upon construction, the window is created by the platform.
  ///
  /// The [preferredContentSize] argument sets the window's initial size preference.
  /// This might not be honored by the platform.
  ///
  /// The [title] argument configures the window's initial title.
  /// If omitted, some platforms might fall back to the app's name.
  ///
  /// The [delegate] argument can be used to listen to the window's
  /// lifecycle. For example, it can be used to save state before
  /// a window is closed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  factory RegularWindowController({
    required WindowSizing preferredContentSize,
    String? title,
    RegularWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    final RegularWindowController controller = owner.createRegularWindowController(
      preferredContentSize: preferredContentSize,
      delegate: delegate ?? RegularWindowControllerDelegate(),
    );
    if (title != null) {
      controller.setTitle(title);
    }
    return controller;
  }

  /// Creates an empty [RegularWindowController].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  // TODO(mattkae): Replace @internal with @visibleForTesting when this API is non-experimental
  @internal
  @protected
  RegularWindowController.empty();

  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @override
  WindowType get type => WindowType.regular;

  /// Request change to the content sizing of the window.
  ///
  /// [sizing] describes the new requested window size. The properties
  /// of this object are applied independently of each other. For example,
  /// setting [WindowSizing.preferredSize] does not affect the
  /// [WindowSizing.preferredConstraints] set previously.
  ///
  /// The platform is free to ignore the request.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void updateContentSizing(WindowSizing sizing);

  /// Request change for the window title.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void setTitle(String title);

  /// Requests that the window be displayed in its current size and position.
  ///
  /// If the window is minimized, the window returns to the size and position
  /// that it had before that state was applied. The window will also be
  /// brought to the top of the window stack.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void activate();

  /// Requests the window to be maximized.
  ///
  /// This has no effect if the window is currently full screen or minimized,
  /// but might affect the window size upon restoring it from minimized or
  /// full screen state.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void setMaximized(bool maximized);

  /// Returns whether window is currently maximized.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bool isMaximized();

  /// Requests window to be minimized.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void setMinimized(bool minimized);

  /// Returns whether window is currently minimized.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bool isMinimized();

  /// Request change for the window to enter or exit fullscreen state.
  ///
  /// If [fullscreen] is set to true, the platform will attempt to change
  /// the state of the window to fullscreen. If false, the window will
  /// return to a previous non-hidden state. Both cases might not be
  /// honored by the platform.
  ///
  /// The [display] specifies an optional [Display] on which the window
  /// would like to be fullscreened. This might not be honored by the
  /// platform. The [display] argument is ignored if [fullscreen] is `false`.
  ///
  /// When [fullscreen] is set to false, it is up to the platform as to
  /// which display the window will be restored to. The platform might
  /// restore the window to the display on which it was previously fullscreened,
  /// or it might restore the window to the display on which it was last
  /// active.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void setFullscreen(bool fullscreen, {Display? display});

  /// Returns whether window is currently in fullscreen mode.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bool isFullscreen();
}

/// [WindowingOwner] is responsible for creating and managing window controllers.
///
/// Custom subclass can be provided by subclassing [WidgetsBinding] and
/// overriding the [createWindowingOwner] method.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
abstract class WindowingOwner {
  /// Creates a [RegularWindowController] with the provided properties.
  ///
  /// Most app developers should use [RegularWindowController]'s constructor
  /// instead of calling this method directly. This method allows platforms
  /// to inject platform-specific logic.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  RegularWindowController createRegularWindowController({
    required WindowSizing preferredContentSize,
    required RegularWindowControllerDelegate delegate,
  });

  /// Returns whether application has any top level windows created by this
  /// windowing owner.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bool hasTopLevelWindows();

  /// Creates default windowing owner for standard desktop embedders.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  static WindowingOwner createDefaultOwner() {
    if (!isWindowingEnabled) {
      return _WindowingOwnerUnsupported(errorMessaage: _kWindowingDisabledErrorMessage);
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
    required WindowSizing preferredContentSize,
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
/// widget tree.
///
/// The provided [controller] creates the native window that backs
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
/// runApp(
///   RegularWindow(
///     controller: controller,
///     child: MaterialApp(home: Container()),
///   ),
/// );
/// ```
///
/// When a [RegularWindow] widget is removed from the tree, the window that was created
/// by the [controller] is automatically destroyed if it has not yet been destroyed.
///
/// Widgets in the same tree as the [child] widget will have access to the
/// [RegularWindowController] via the [WindowControllerContext] widget.
///
/// {@macro flutter.widgets.windowing.experimental}
class RegularWindow extends StatefulWidget {
  /// Creates a regular window widget.
  ///
  /// The [controller] creates the native backing window into which the
  /// [child] widget is rendered.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  RegularWindow({super.key, required this.controller, required this.child}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  /// Controller for this widget.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final RegularWindowController controller;

  /// The content rendered into this window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final Widget child;

  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @override
  State<RegularWindow> createState() => _RegularWindowState();
}

class _RegularWindowState extends State<RegularWindow> {
  @override
  void dispose() {
    widget.controller.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return View(
      view: widget.controller.rootView,
      child: WindowControllerContext(controller: widget.controller, child: widget.child),
    );
  }
}

/// Provides descendants with access to the [BaseWindowController] associated with
/// the window that is being rendered.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [RegularWindow], the widget to create a regular window.
@internal
class WindowControllerContext extends InheritedWidget {
  /// Creates a new [WindowControllerContext].
  ///
  /// This widget is used by the window widgets to provide
  /// widgets in a window's subtree with access to information about
  /// the window.
  ///
  /// The [controller] is the controller associated with this window,
  /// and the [child] is the widget tree that will have access
  /// to this context.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  WindowControllerContext({super.key, required this.controller, required super.child}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  /// The controller associated with this window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final BaseWindowController controller;

  /// Returns the [WindowControllerContext].
  ///
  /// If [isWindowingEnabled] is `false`, this method will throw an
  /// [UnsupportedError].
  ///
  /// If there is no [WindowControllerContext] in scope, this method
  /// will throw a [TypeError] exception in release builds, and thrown
  /// a descriptive [FlutterError] in debug builds.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  /// * [RegularWindowController], the controller for regular top-level windows.
  /// * [RegularWindow], the widget for a regular window.
  /// * [maybeOf], which doesn't throw or assert if it doesn't find a
  ///   [WindowControllerContext] ancestor. It returns null instead.
  @internal
  static BaseWindowController of(BuildContext context) {
    assert(_debugCheckHasWindowController(context));
    return context.dependOnInheritedWidgetOfExactType<WindowControllerContext>()!.controller;
  }

  /// Returns the [WindowControllerContext] if one exists, otherwise null.
  ///
  /// If [isWindowingEnabled] is `false`, this method will throw an
  /// [UnsupportedError].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  /// * [RegularWindowController], the controller for regular top-level windows.
  /// * [RegularWindow], the widget for a regular window.
  /// * [of], which will throw if it doesn't find a [WindowControllerContext] ancestor,
  ///   instead of returning null.
  @internal
  static BaseWindowController? maybeOf(BuildContext context) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
    return context.dependOnInheritedWidgetOfExactType<WindowControllerContext>()?.controller;
  }

  static bool _debugCheckHasWindowController(BuildContext context) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    assert(() {
      if (context.dependOnInheritedWidgetOfExactType<WindowControllerContext>() == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('No WindowControllerContext found in context.'),
          ErrorDescription(
            '${context.widget.runtimeType} widgets require a WindowControllerContext widget ancestor.',
          ),
          context.describeWidget(
            'The specific widget that could not find a WindowControllerContext ancestor was',
          ),
          context.describeOwnershipChain('The ownership chain for the affected widget is'),
          ErrorHint(
            'No WindowControllerContext ancestor could be found starting from the context '
            'that was passed to WindowControllerContext.of(). This can happen because the '
            'context used is not a descendant of a RegularWindow widget, which introduces '
            'a WindowControllerContext.',
          ),
        ]);
      }
      return true;
    }());
    return true;
  }

  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @override
  bool updateShouldNotify(WindowControllerContext oldWidget) {
    return controller != oldWidget.controller;
  }
}
