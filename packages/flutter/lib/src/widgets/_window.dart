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
import 'inherited_model.dart';
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

/// Base class for window controllers.
///
/// A [BaseWindowController] is associated with exactly one root [FlutterView].
///
/// When the window is destroyed for any reason (either by the caller or by the
/// platform), the content of the controller will thereafter be invalid.
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
///
/// See also:
///
///  * [RegularWindowController], the controller for regular top-level windows.
@internal
sealed class BaseWindowController {
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
  /// Invoked when the user attempts to close the window.
  ///
  /// The default implementation destroys the window. Subclasses
  /// can override the behavior to delay or prevent the window from closing.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [onWindowDestroyed], which is invoked after the window is closed.
  @internal
  void onWindowCloseRequested(RegularWindowController controller) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    controller.destroy();
  }

  /// Invoked after the window is closed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [onWindowCloseRequested], which is invoked when the user attempts to close the window.
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
/// The user of this class is responsible for managing the lifecycle of the window.
/// When the window is no longer needed, the user should call [destroy] on this
/// controller to release the resources associated with the window.
///
/// {@tool snippet}
/// An example usage might look like:
///
/// ```dart
/// // ignore_for_file: invalid_use_of_internal_member
/// import 'package:flutter/widgets.dart';
/// import 'package:flutter/material.dart';
/// import 'package:flutter/src/widgets/_window.dart';
///
/// void main() {
///   runWidget(
///     RegularWindow(
///       controller: RegularWindowController(
///         preferredSize: const Size(800, 600),
///         preferredConstraints: const BoxConstraints(minWidth: 640, minHeight: 480),
///         title: 'Example Window',
///       ),
///       child: MaterialApp(home: Container()),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// Children of a [RegularWindow] widget can access the [RegularWindowController]
/// via the [WindowControllerScope] inherited widget.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
abstract class RegularWindowController extends BaseWindowController {
  /// Creates a [RegularWindowController] with the provided properties.
  ///
  /// Upon construction, the window is created by the platform.
  ///
  /// The [preferredSize] is the preferred content size of the window.
  /// This might not be honored by the platform. This is the size that
  /// the platform will try to apply to the window when it is created. In contrast,
  /// the [preferredConstraints] field enforces the minimum and maximum size of
  /// the window. If the [preferredSize] does not satisfy the [preferredConstraints]
  /// or the [preferredSize] is null, then the platform will attempt to use an
  /// initial size that does satisfy the [preferredConstraints] instead.
  ///
  /// The [preferredConstraints] are the constraints placed upon the size
  /// of the window. This might not be honored by the platform.
  /// This field enforces a minimum and maximum size on the window. If the
  /// user attempts to resize the window beyond these constraints, the platform
  /// will enforce the constraints according to its own policy. For example, the
  /// platform might clip the content to fit within the resized window, or it might
  /// prevent the window from being resized altogether. If null, the window will
  /// be unconstrained.
  ///
  /// If both [preferredSize] and [preferredConstraints] are null,
  /// then the platform will use its own default size for the window.
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
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
    RegularWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    if (preferredSize != null && preferredConstraints != null) {
      assert(preferredConstraints.isSatisfiedBy(preferredSize));
    }

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createRegularWindowController(
      delegate: delegate ?? RegularWindowControllerDelegate(),
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      title: title,
    );
  }

  /// Creates an empty [RegularWindowController] for testing purposes.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @protected
  @visibleForTesting
  RegularWindowController.empty();

  /// The current title of the window.
  ///
  /// This might differ from the requested title.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  String get title;

  /// Whether the window is currently activated.
  ///
  /// If `true` this means that the window is currently focused and
  /// can receive user input.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bool get isActivated;

  /// Whether or not the window is currently maximized.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bool get isMaximized;

  /// Whether or not window is currently minimized.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bool get isMinimized;

  /// Whether or not the window is currently in fullscreen mode.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bool get isFullscreen;

  /// Request change to the content size of the window.
  ///
  /// The [size] describes the new requested window size. If the size disagrees
  /// with the current constraints placed upon the window, the platform might
  /// clamp the size within the constraints.
  ///
  /// The platform is free to ignore this request.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void setSize(Size size);

  /// Request change to the constraints of the window.
  ///
  /// The [constraints] describes the new constraints that the window should
  /// satisfy. If the constraints disagree with the current size of the window,
  /// the platform might resize the window to satisfy the new constraints.
  ///
  /// The platform is free to ignore this request.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void setConstraints(BoxConstraints constraints);

  /// Request change for the window title.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void setTitle(String title);

  /// Requests that the window be displayed in its current size and position.
  ///
  /// The platform may also give the window input focus and bring it to the
  /// top of the window stack. However, this behavior is platform-dependent.
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

  /// Requests window to be minimized.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void setMinimized(bool minimized);

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
}

/// [WindowingOwner] is responsible for creating and managing window controllers.
///
/// A custom implementation can be provided by setting [WidgetsBinding.windowingOwner].
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
    required RegularWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
  });

  /// Returns whether the application has any top level windows created by this
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
      return _WindowingOwnerUnsupported(errorMessage: _kWindowingDisabledErrorMessage);
    }

    // TODO(mattkae): Implement windowing owners for desktop platforms.
    return _WindowingOwnerUnsupported(errorMessage: 'Windowing is unsupported on this platform.');
  }
}

/// Windowing delegate used on platforms that do not support windowing.
class _WindowingOwnerUnsupported extends WindowingOwner {
  _WindowingOwnerUnsupported({required this.errorMessage});

  final String errorMessage;

  @override
  RegularWindowController createRegularWindowController({
    required RegularWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
  }) {
    throw UnsupportedError(errorMessage);
  }

  @override
  bool hasTopLevelWindows() {
    throw UnsupportedError(errorMessage);
  }
}

/// The [RegularWindow] widget provides a way to render a regular window in the
/// widget tree.
///
/// The provided [controller] creates the native window that backs
/// the widget. The [child] widget is rendered into this newly created window.
///
/// When a [RegularWindow] widget is removed from the tree, the window that was created
/// by the [controller] remains valid until the caller destroys it by calling
/// [RegularWindowController.destroy].
///
/// Widgets in the same tree as the [child] widget will have access to the
/// [RegularWindowController] via the [WindowScope] widget.
///
/// {@tool snippet}
/// An example usage might look like:
///
/// ```dart
/// // ignore_for_file: invalid_use_of_internal_member
/// import 'package:flutter/widgets.dart';
/// import 'package:flutter/material.dart';
/// import 'package:flutter/src/widgets/_window.dart';
///
/// void main() {
///   runWidget(
///     RegularWindow(
///       controller: RegularWindowController(
///         preferredSize: const Size(800, 600),
///         preferredConstraints: const BoxConstraints(minWidth: 640, minHeight: 480),
///         title: 'Example Window',
///       ),
///       child: MaterialApp(home: Container()),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
class RegularWindow extends StatelessWidget {
  /// Creates a regular window widget.
  ///
  /// The [controller] creates the native backing window into which the
  /// [child] widget is rendered.
  ///
  /// It is up to the caller to destroy the window by calling
  /// [RegularWindowController.destroy] when the window is no longer needed.
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
  Widget build(BuildContext context) {
    return WindowScope(
      controller: controller,
      child: View(view: controller.rootView, child: child),
    );
  }
}

enum _WindowControllerAspect { contentSize, title, activated, maximized, minimized, fullscreen }

/// Provides descendants with access to the [BaseWindowController] associated with
/// the window that is being rendered.
///
/// Windows created using native APIs do not have a [WindowScope].
/// This includes the initial window created by the native entrypoint
/// that [runApp] attaches to.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [RegularWindow], the widget to create a regular window.
@internal
class WindowScope extends InheritedModel<_WindowControllerAspect> {
  /// Creates a new [WindowScope].
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
  WindowScope({super.key, required this.controller, required super.child}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  /// The controller associated with this window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final BaseWindowController controller;

  /// Returns the [BaseWindowController] for the window that hosts the given context.
  ///
  /// {@template flutter.widgets.windowing.windowControllerScope.of}
  /// If there is no [WindowControllerScope] in scope, this method
  /// will throw a [TypeError] exception in release builds, and throws
  /// a descriptive [FlutterError] in debug builds.
  ///
  /// Windows creating using native APIs do not have a [WindowScope].
  /// This includes the initial window created by the native entrypoint
  /// that [runApp] attaches to.
  /// {@endtemplate}
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController], the controller for regular top-level windows.
  /// * [RegularWindow], the widget for a regular window.
  /// * [maybeOf], which doesn't throw or assert if it doesn't find a
  ///   [WindowScope] ancestor. It returns null instead.
  @internal
  static BaseWindowController of(BuildContext context) {
    return _of(context);
  }

  /// Returns the [BaseWindowController] if one exists, otherwise null.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController], the controller for regular top-level windows.
  /// * [RegularWindow], the widget for a regular window.
  /// * [of], which will throw if it doesn't find a [WindowScope] ancestor,
  ///   instead of returning null.
  @internal
  static BaseWindowController? maybeOf(BuildContext context) {
    return _maybeOf(context);
  }

  /// Returns [BaseWindowController.contentSize] of the nearest [WindowScope].
  ///
  /// {@macro flutter.widgets.windowing.windowScope.of}
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [BaseWindowController.contentSize], which returns the current content size of the window.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static Size contentSizeOf(BuildContext context) =>
      _of(context, _WindowControllerAspect.contentSize).contentSize;

  /// Returns [BaseWindowController.contentSize] of the nearest [WindowScope],
  /// or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [BaseWindowController.contentSize], which returns the current content size of the window.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static Size? maybeContentSizeOf(BuildContext context) =>
      _maybeOf(context, _WindowControllerAspect.contentSize)?.contentSize;

  /// Returns the title of the controller in the nearest [WindowScope].
  ///
  /// {@macro flutter.widgets.windowing.windowScope.of}
  ///
  /// If the window associated with the controller does not support titles,
  /// this method will throw an [UnsupportedError].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController.title], which returns the current title of the window.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static String titleOf(BuildContext context) {
    final BaseWindowController controller = _of(context, _WindowControllerAspect.title);
    return switch (controller) {
      RegularWindowController() => controller.title,
    };
  }

  /// Returns title of the nearest [WindowScope], or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController.title], which returns the current title of the window.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static String? maybeTitleOf(BuildContext context) {
    final BaseWindowController? controller = _maybeOf(context, _WindowControllerAspect.title);
    if (controller == null) {
      return null;
    }

    return switch (controller) {
      RegularWindowController() => controller.title,
    };
  }

  /// Returns the activation status of the nearest [WindowScope].
  ///
  /// {@macro flutter.widgets.windowing.windowScope.of}
  ///
  /// If the window associated with the controller does not support activation,
  /// this method will throw an [UnsupportedError].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController.isActivated], which returns the current activation status of the window.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static bool isActivatedOf(BuildContext context) {
    final BaseWindowController controller = _of(context, _WindowControllerAspect.activated);
    return switch (controller) {
      RegularWindowController() => controller.isActivated,
    };
  }

  /// Returns the activation status of the nearest [WindowScope],
  /// or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController.isActivated], which returns the current activation status of the window.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static bool? maybeIsActivatedOf(BuildContext context) {
    final BaseWindowController? controller = _maybeOf(context, _WindowControllerAspect.activated);
    if (controller == null) {
      return null;
    }

    return switch (controller) {
      RegularWindowController() => controller.isActivated,
    };
  }

  /// Returns the minimization status of the nearest [WindowScope].
  ///
  /// {@macro flutter.widgets.windowing.windowScope.of}
  ///
  /// If the window associated with the controller does not support minimization,
  /// this method will throw an [UnsupportedError].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController.isMinimized], which returns the current minimized status of the window.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static bool isMinimizedOf(BuildContext context) {
    final BaseWindowController controller = _of(context, _WindowControllerAspect.minimized);
    return switch (controller) {
      RegularWindowController() => controller.isMinimized,
    };
  }

  /// Returns the minimization status of the nearest [WindowScope],
  /// or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController.isMinimized], which returns the current minimized status of the window.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static bool? maybeIsMinimizedOf(BuildContext context) {
    final BaseWindowController? controller = _maybeOf(context, _WindowControllerAspect.minimized);
    if (controller == null) {
      return null;
    }

    return switch (controller) {
      RegularWindowController() => controller.isMinimized,
    };
  }

  /// Returns the maximization status of the nearest [WindowScope].
  ///
  /// {@macro flutter.widgets.windowing.windowScope.of}
  ///
  /// If the window associated with the controller does not support maximization,
  /// this method will throw an [UnsupportedError].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController.isMaximized], which returns the current maximized status of the window.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static bool isMaximizedOf(BuildContext context) {
    final BaseWindowController controller = _of(context, _WindowControllerAspect.maximized);
    return switch (controller) {
      RegularWindowController() => controller.isMaximized,
    };
  }

  /// Returns the maximization status of the nearest [WindowScope],
  /// or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController.isMaximized], which returns the current maximized status of the window.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static bool? maybeIsMaximizedOf(BuildContext context) {
    final BaseWindowController? controller = _maybeOf(context, _WindowControllerAspect.maximized);
    if (controller == null) {
      return null;
    }

    return switch (controller) {
      RegularWindowController() => controller.isMaximized,
    };
  }

  /// Returns the fullscreen status of the nearest [WindowScope].
  ///
  /// {@macro flutter.widgets.windowing.windowScope.of}
  ///
  /// If the window associated with the controller does not support fullscreen,
  /// this method will throw an [UnsupportedError].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController.isFullscreen], which returns the current fullscreen status of the window.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static bool isFullscreenOf(BuildContext context) {
    final BaseWindowController controller = _of(context, _WindowControllerAspect.fullscreen);

    return switch (controller) {
      RegularWindowController() => controller.isFullscreen,
    };
  }

  /// Returns the fullscreen status of the nearest [WindowScope],
  /// or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [RegularWindowController.isFullscreen], which returns the current fullscreen status of the window.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static bool? maybeIsFullscreenOf(BuildContext context) {
    final BaseWindowController? controller = _maybeOf(context, _WindowControllerAspect.fullscreen);
    if (controller == null) {
      return null;
    }

    return switch (controller) {
      RegularWindowController() => controller.isFullscreen,
    };
  }

  static BaseWindowController _of(BuildContext context, [_WindowControllerAspect? aspect]) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
    assert(_debugCheckHasWindowController(context));
    return InheritedModel.inheritFrom<WindowScope>(context, aspect: aspect)!.controller;
  }

  static BaseWindowController? _maybeOf(BuildContext context, [_WindowControllerAspect? aspect]) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
    return InheritedModel.inheritFrom<WindowScope>(context, aspect: aspect)?.controller;
  }

  static bool _debugCheckHasWindowController(BuildContext context) {
    assert(() {
      if (context.dependOnInheritedWidgetOfExactType<WindowScope>() == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('No WindowScope found in context.'),
          ErrorDescription(
            '${context.widget.runtimeType} widgets require a WindowScope widget ancestor.',
          ),
          context.describeWidget(
            'The specific widget that could not find a WindowScope ancestor was',
          ),
          context.describeOwnershipChain('The ownership chain for the affected widget is'),
          ErrorHint(
            'No WindowScope ancestor could be found starting from the context '
            'that was passed to WindowScope.of(). This can happen because the '
            'context used is not a descendant of a RegularWindow widget, which introduces '
            'a WindowScope.',
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
  bool updateShouldNotify(WindowScope oldWidget) => controller != oldWidget.controller;

  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @override
  bool updateShouldNotifyDependent(WindowScope oldWidget, Set<Object> dependencies) {
    return dependencies.any(
      (Object dependency) =>
          dependency is _WindowControllerAspect &&
          switch (dependency) {
            _WindowControllerAspect.contentSize =>
              controller.contentSize != oldWidget.controller.contentSize,
            _WindowControllerAspect.title => switch (controller) {
              final RegularWindowController regular =>
                regular.title != (oldWidget.controller as RegularWindowController).title,
            },
            _WindowControllerAspect.activated => switch (controller) {
              final RegularWindowController regular =>
                regular.isActivated !=
                    (oldWidget.controller as RegularWindowController).isActivated,
            },
            _WindowControllerAspect.maximized => switch (controller) {
              final RegularWindowController regular =>
                regular.isMaximized !=
                    (oldWidget.controller as RegularWindowController).isMaximized,
            },
            _WindowControllerAspect.minimized => switch (controller) {
              final RegularWindowController regular =>
                regular.isMinimized !=
                    (oldWidget.controller as RegularWindowController).isMinimized,
            },
            _WindowControllerAspect.fullscreen => switch (controller) {
              final RegularWindowController regular =>
                regular.isFullscreen !=
                    (oldWidget.controller as RegularWindowController).isFullscreen,
            },
          },
    );
  }
}
