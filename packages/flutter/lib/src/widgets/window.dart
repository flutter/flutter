// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show AppExitType, FlutterView, Display;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '_window_ffi.dart' if (dart.library.js_util) '_window_web.dart' as window_impl;
import 'binding.dart';
import 'framework.dart';
import 'view.dart';

/// Defines the possible archetypes for a window.
enum WindowArchetype {
  /// Defines a traditional window
  regular,
}

/// Defines sizing request for a window.
class WindowSizing {
  /// Creates a new [WindowSizing] object.
  WindowSizing({this.preferredSize, this.constraints});

  /// Preferred size of the window. This may not be honored by the platform.
  final Size? preferredSize;

  /// Constraints for the window. This may not be honored by the platform.
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
abstract class WindowController with ChangeNotifier {
  @protected
  /// Sets the view associated with this window.
  // ignore: use_setters_to_change_properties
  void setView(FlutterView view) {
    _view = view;
  }

  /// The archetype of the window.
  WindowArchetype get type;

  /// The current size of the window. This may differ from the requested size.
  Size get contentSize;

  /// Destroys this window. It is permissible to call this method multiple times.
  void destroy();

  /// The root view associated to this window, which is unique to each window.
  FlutterView get rootView => _view;
  late final FlutterView _view;
}

/// Delegate class for regular window controller.
mixin class RegularWindowControllerDelegate {
  /// Invoked when user attempts to close the window. Default implementation
  /// destroys the window. Subclass can override the behavior to delay
  /// or prevent the window from closing.
  void onWindowCloseRequested(RegularWindowController controller) {
    controller.destroy();
  }

  /// Invoked when the window is closed. Default implementation exits the
  /// application if this was the last top-level window.
  void onWindowDestroyed() {
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
abstract class RegularWindowController extends WindowController {
  /// Creates a [RegularWindowController] with the provided properties.
  /// Upon construction, the window is created for the platform.
  ///
  /// [contentSize] sizing requests for the window. This may not be honored by the platform
  /// [title] the title of the window
  /// [state] the initial state of the window
  /// [delegate] optional delegate for the controller controller.
  factory RegularWindowController({
    required WindowSizing contentSize,
    String? title,
    RegularWindowControllerDelegate? delegate,
  }) {
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

  @protected
  /// Creates an empty [RegularWindowController].
  RegularWindowController.empty();

  @override
  WindowArchetype get type => WindowArchetype.regular;

  /// Request change for the window content size.
  ///
  /// [contentSize] describes the new requested window size. The properties
  /// of this object are applied independently of each other. For example,
  /// setting [WindowSizing.preferredSize] does not affect the [WindowSizing.constraints]
  /// set previously.
  ///
  /// System compositor is free to ignore the request.
  void updateContentSize(WindowSizing sizing);

  /// Request change for the window title.
  /// [title] new title of the window.
  void setTitle(String title);

  /// Requests that the window be displayed in its current size and position.
  /// If the window is minimized or maximized, the window returns to the size
  /// and position that it had before that state was applied.
  void activate();

  /// Requests the window to be maximized. This has no effect
  /// if the window is currently full screen or minimized, but may
  /// affect the window size upon restoring it from minimized or
  /// full screen state.
  void setMaximized(bool maximized);

  /// Returns whether window is currently maximized.
  bool isMaximized();

  /// Requests window to be minimized.
  void setMinimized(bool minimized);

  /// Returns whether window is currently minimized.
  bool isMinimized();

  /// Request change for the window to enter or exit fullscreen state.
  /// [fullscreen] whether to enter or exit fullscreen state.
  /// [displayId] optional [Display] identifier to use for fullscreen mode.
  /// Specifying the [displayId] might not be supported on all platforms.
  void setFullscreen(bool fullscreen, {int? displayId});

  /// Returns whether window is currently in fullscreen mode.
  bool isFullscreen();
}

/// [WindowingOwner] is responsible for creating and managing window controllers.
///
/// Custom subclass can be provided by subclassing [WidgetsBinding] and
/// overriding the [createWindowingOwner] method.
abstract class WindowingOwner {
  /// Creates a [RegularWindowController] with the provided properties.
  RegularWindowController createRegularWindowController({
    required WindowSizing contentSize,
    required RegularWindowControllerDelegate delegate,
  });

  /// Returns whether application has any top level windows created by this
  /// windowing owner.
  bool hasTopLevelWindows();

  /// Creates default windowing owner for standard desktop embedders.
  static WindowingOwner createDefaultOwner() {
    return window_impl.createDefaultOwner() ?? _FallbackWindowingOwner();
  }
}

/// Windowing delegate used on platforms that do not support windowing.
class _FallbackWindowingOwner extends WindowingOwner {
  @override
  RegularWindowController createRegularWindowController({
    required WindowSizing contentSize,
    required RegularWindowControllerDelegate delegate,
  }) {
    throw UnsupportedError(
      'Current platform does not support windowing.\n'
      'Implement a WindowingDelegate for this platform.',
    );
  }

  @override
  bool hasTopLevelWindows() {
    return false;
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
class RegularWindow extends StatefulWidget {
  /// Creates a regular window widget.
  /// [controller] the controller for this window
  /// [child] the content to render into this window
  /// [key] the key for this widget
  const RegularWindow({super.key, required this.controller, required this.child});

  /// Controller for this widget.
  final RegularWindowController controller;

  /// The content rendered into this window.
  final Widget child;

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
class WindowControllerContext extends InheritedWidget {
  /// Creates a new [WindowControllerContext]
  /// [controller] the controller associated with this window
  /// [child] the child widget
  const WindowControllerContext({super.key, required this.controller, required super.child});

  /// The controller associated with this window.
  final WindowController controller;

  /// Returns the [WindowContext] if any
  static WindowController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WindowControllerContext>()?.controller;
  }

  @override
  bool updateShouldNotify(WindowControllerContext oldWidget) {
    return controller != oldWidget.controller;
  }
}
