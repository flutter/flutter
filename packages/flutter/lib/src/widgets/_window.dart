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
//    is `false`.
//
// See: https://github.com/flutter/flutter/issues/30701.

import 'dart:ui' show Display, FlutterView;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import '../foundation/_features.dart';
import '_window_io.dart' if (dart.library.js_interop) '_window_web.dart' as window_impl;
import '_window_positioner.dart';
import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'inherited_model.dart';
import 'transitions.dart';
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
///  * [WindowController], the controller for regular top-level windows.
@internal
sealed class BaseWindowController extends ChangeNotifier {
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

  /// Whether or not the underlying native window is destroyed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bool get isDestroyed;
}

/// Delegate class for regular window controller.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowController], the controller that creates and manages regular windows.
///  * [mountToplevelWindow], which renders a window managed by this controller.
@internal
mixin class WindowControllerDelegate {
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
  void onWindowCloseRequested(WindowController controller) {
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
  }
}

/// A controller for a regular window.
///
/// A regular window is a traditional window that can be resized, minimized,
/// maximized, and closed. Upon construction, the window is created for the
/// platform with the provided properties.
///
/// {@template flutter.widgets.windowing.renderContent}
/// This class does not interact with the widget tree. To render content in the
/// window, provide this controller and a content builder in a [WindowEntry].
/// Pass the entry to [WindowManager.initialWindows] when starting the application,
/// to [mountToplevelWindow] to open an additional top-level window, or return it
/// from [NestedWindow.entryBuilder] to render a nested window.
/// {@endtemplate}
///
/// The user of this class is responsible for managing the lifecycle of the window.
/// When the window is no longer needed, the user should call [destroy] on this
/// controller to release the resources associated with the window.
///
/// {@tool snippet}
/// An example usage might look like:
///
/// ```dart
/// // TODO(mattkae): remove invalid_use_of_internal_member ignore comment when this API is stable.
/// // ignore_for_file: invalid_use_of_internal_member
/// import 'package:flutter/material.dart';
/// import 'package:flutter/src/widgets/_window.dart';
///
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   runWidget(
///     WindowManager(
///       initialWindows: <WindowEntry>[
///         WindowEntry(
///           controller: WindowController(
///             size: const Size(800, 600),
///             constraints: const BoxConstraints(minWidth: 640, minHeight: 480),
///             title: 'Example Window',
///           ),
///           builder: (BuildContext context) => const MaterialApp(
///             home: Scaffold(body: Center(child: Text('Hello, World!'))),
///           ),
///         ),
///       ],
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@template flutter.widgets.windowing.controllerScope}
/// When mounted with [mountToplevelWindow] or [NestedWindow], descendants of the
/// window's content can access this controller via [WindowScope.of]. This also
/// applies to windows provided in [WindowManager.initialWindows].
/// {@endtemplate}
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
abstract class WindowController extends BaseWindowController {
  /// Creates a [WindowController] with a specific size.
  ///
  /// Upon construction, the window is created by the platform with the
  /// given [size].
  ///
  /// {@template flutter.widgets.windowing.sizedConstructor}
  ///
  /// The [size] is the preferred content size of the window. The
  /// platform will try to apply this size when the window is created, but it
  /// might not be honored.
  ///
  /// The [constraints] field enforces the minimum and maximum size of
  /// the window. The [size] must satisfy the [constraints].
  /// If the user attempts to resize the window beyond these constraints, the
  /// platform will enforce the constraints according to its own policy. For
  /// example, the platform might clip the content to fit within the resized
  /// window, or it might prevent the window from being resized altogether.
  /// These constraints might not be honored by the platform. If null, the
  /// window will be unconstrained.
  /// {@endtemplate}
  ///
  /// To create a window that is sized to its content instead, use
  /// [WindowController.shrinkWrap].
  ///
  /// {@template flutter.widgets.windowing.shared}
  /// The [title] argument configures the window's title.
  /// If omitted, some platforms might fall back to the app's name.
  ///
  /// The [delegate] argument can be used to listen to the window's
  /// lifecycle. For example, it can be used to save state before
  /// a window is closed.
  /// {@endtemplate}
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  factory WindowController({
    required Size size,
    BoxConstraints? constraints,
    String? title,
    WindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    if (constraints != null) {
      assert(constraints.isSatisfiedBy(size));
    }

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createWindowController(
      delegate: delegate ?? WindowControllerDelegate(),
      size: size,
      constraints: constraints,
      title: title,
      resizable: true,
    );
  }

  /// Creates a [WindowController] that sizes the window to its content.
  ///
  /// {@template flutter.widgets.windowing.shrinkWrapConstructor}
  /// The window is created by the platform and initially
  /// sized to fit its content.
  ///
  /// The [resizable] property determines how the window behaves after that initial sizing:
  ///
  /// * If `false`, the window remains fixed to its content size. If the
  ///   content changes size, the window will automatically resize to match,
  ///   subject to [constraints]. This is the default.
  /// * If `true`, the user can manually resize the window, subject to
  ///   [constraints]. After the initial automatic sizing,
  ///   the window will no longer track the size of its content.
  ///
  /// The [constraints] field enforces the minimum and maximum size of
  /// the window. If the user attempts to resize the window beyond these
  /// constraints, the platform will enforce the constraints according to its
  /// own policy. For example, the platform might clip the content to fit
  /// within the resized window, or it might prevent the window from being
  /// resized altogether. These constraints might not be honored by the
  /// platform. If null, the window will be unconstrained.
  /// {@endtemplate}
  ///
  /// To create a window with a specific size instead, use the default
  /// [WindowController] constructor.
  ///
  /// {@macro flutter.widgets.windowing.shared}
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  factory WindowController.shrinkWrap({
    bool resizable = false,
    BoxConstraints? constraints,
    String? title,
    WindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    WidgetsFlutterBinding.ensureInitialized();

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createWindowController(
      delegate: delegate ?? WindowControllerDelegate(),
      constraints: constraints,
      resizable: resizable,
      title: title,
    );
  }

  /// Creates an empty [WindowController].
  ///
  /// This method is only intended to be used by subclasses of the
  /// [WindowController].
  ///
  /// Users who want to instantiate a new [WindowController] should
  /// always use the factory method to create a controller that is valid
  /// for their particular platform.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @protected
  WindowController.empty();

  /// The current title of the window.
  ///
  /// The title shown in the window is controlled by the platform and may differ
  /// from the `title` set by the constructor or `setTitle`.
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

/// Delegate class for dialog window controller.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [DialogWindowController], the controller that creates and manages dialog windows.
///  * [mountToplevelWindow], which renders a dialog in a separate widget subtree.
///  * [NestedWindow], which renders a dialog in the surrounding widget subtree.
///  * [WindowControllerDelegate], the delegate for regular window controllers.
@internal
mixin class DialogWindowControllerDelegate {
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
  void onWindowCloseRequested(DialogWindowController controller) {
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
  }
}

/// A controller for a dialog window.
///
/// Two types of dialogs are supported:
///  * Modal dialogs: created with a non-null parent. These dialogs are modal
///    to the parent, do not have a system menu, and are not selectable from the
///    window switcher.
///  * Modeless dialogs: created with a null parent. These dialogs can be
///    minimized (but not maximized), and have a disabled close button.
///
/// {@macro flutter.widgets.windowing.renderContent}
///
/// The user of this class is responsible for managing the lifecycle of the window.
/// When the window is no longer needed, the user should call [destroy] on this
/// controller to release the resources associated with the window.
///
/// {@tool snippet}
/// An example usage might look like:
///
/// ```dart
/// // TODO(mattkae): remove invalid_use_of_internal_member ignore comment when this API is stable.
/// // ignore_for_file: invalid_use_of_internal_member
/// import 'package:flutter/material.dart';
/// import 'package:flutter/src/widgets/_window.dart';
///
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   runWidget(
///     WindowManager(
///       initialWindows: <WindowEntry>[
///         WindowEntry(
///           controller: WindowController(
///             size: const Size(800, 600),
///             title: 'Example Window',
///           ),
///           builder: (BuildContext context) => const MaterialApp(home: MyApp()),
///         ),
///       ],
///     ),
///   );
/// }
///
/// class MyApp extends StatelessWidget {
///   const MyApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Center(
///         child: ElevatedButton(
///           onPressed: () {
///             final DialogWindowController controller = DialogWindowController(
///               size: const Size(400, 300),
///               parent: WindowScope.of(context),
///               title: 'Example Dialog',
///             );
///             mountToplevelWindow(
///               context: context,
///               entry: WindowEntry(
///                 controller: controller,
///                 builder: (BuildContext context) => MaterialApp(
///                   home: Scaffold(
///                     body: Center(
///                       child: ElevatedButton(
///                         onPressed: controller.destroy,
///                         child: const Text('Close dialog'),
///                       ),
///                     ),
///                   ),
///                 ),
///               ),
///             );
///           },
///           child: const Text('Open dialog'),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// {@macro flutter.widgets.windowing.controllerScope}
///
/// {@macro flutter.widgets.windowing.experimental}
abstract class DialogWindowController extends BaseWindowController {
  /// Creates a [DialogWindowController] with a specific size.
  ///
  /// Upon construction, the window is created by the platform with
  /// the given [size].
  ///
  /// {@macro flutter.widgets.windowing.sizedConstructor}
  ///
  /// To create a dialog that is sized to its content instead, use
  /// [DialogWindowController.shrinkWrap].
  ///
  /// {@template flutter.widgets.windowing.dialogParent}
  /// The [parent] argument specifies the parent window of this dialog.
  ///
  /// If the [parent] is null, then the dialog is modeless. Such dialogs can
  /// be minimized but not maximized. They also have a disabled close button.
  ///
  /// If the [parent] is non-null, then the dialog is modal to the parent.
  /// Such dialogs do not have a system menu. They are also not selectable
  /// from the window switcher and they are closed when the parent is closed.
  /// {@endtemplate}
  ///
  /// {@macro flutter.widgets.windowing.shared}
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  factory DialogWindowController({
    required Size size,
    BoxConstraints? constraints,
    BaseWindowController? parent,
    String? title,
    DialogWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    WidgetsFlutterBinding.ensureInitialized();

    if (constraints != null) {
      assert(constraints.isSatisfiedBy(size));
    }

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createDialogWindowController(
      delegate: delegate ?? DialogWindowControllerDelegate(),
      size: size,
      constraints: constraints,
      title: title,
      parent: parent,
      resizable: true,
    );
  }

  /// Creates a [DialogWindowController] that sizes the window to its content.
  ///
  /// {@macro flutter.widgets.windowing.shrinkWrapConstructor}
  ///
  /// To create a dialog with a specific size instead, use the default
  /// [DialogWindowController] constructor.
  ///
  /// {@macro flutter.widgets.windowing.dialogParent}
  ///
  /// {@macro flutter.widgets.windowing.shared}
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  factory DialogWindowController.shrinkWrap({
    bool resizable = false,
    BoxConstraints? constraints,
    BaseWindowController? parent,
    String? title,
    DialogWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    WidgetsFlutterBinding.ensureInitialized();
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createDialogWindowController(
      delegate: delegate ?? DialogWindowControllerDelegate(),
      constraints: constraints,
      resizable: resizable,
      title: title,
      parent: parent,
    );
  }

  /// Creates an empty [DialogWindowController].
  ///
  /// This method is only intended to be used by subclasses of the
  /// [DialogWindowController].
  ///
  /// Users who want to instantiate a new [DialogWindowController] should
  /// always use the factory method to create a controller that is valid
  /// for their particular platform.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @protected
  DialogWindowController.empty();

  /// The parent controller of this dialog, if any.
  ///
  /// If null, this dialog is modeless.
  /// If non-null, this dialog is modal to the parent.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  BaseWindowController? get parent;

  /// The current title of the window.
  ///
  /// The title shown in the window is controlled by the platform and may differ
  /// from the `title` set by the constructor or `setTitle`.
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

  /// Whether or not window is currently minimized.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bool get isMinimized;

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

  /// Requests window to be minimized.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void setMinimized(bool minimized);
}

/// Delegate class for tooltip window controller.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
/// * [TooltipWindowController], the controller that creates and manages tooltip windows.
/// * [NestedWindow], which renders a tooltip alongside its anchor widget.
/// * [WindowControllerDelegate], the delegate for regular window controllers.
mixin class TooltipWindowControllerDelegate {
  /// Invoked after the window is closed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void onWindowDestroyed() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }
}

/// A controller for a tooltip window.
///
/// A tooltip window is a small window that displays brief, informative text
/// when a user hovers over or focuses on a UI element. Tooltip windows are
/// typically used to provide additional context or explanations for UI elements
/// without cluttering the main interface. As such, it may not receive input
/// focus from the user. It will however stay open when another window receives
/// input focus.
///
/// {@macro flutter.widgets.windowing.renderContent}
///
/// The user of this class is responsible for managing the lifecycle of the window.
/// When the window is no longer needed, the user should call [destroy] on this
/// controller to release the resources associated with the window.
///
/// If the parent window of the tooltip is destroyed, then the tooltip will
/// be destroyed as well. The user does not need to explicitly call [destroy]
/// in this case.
///
/// {@tool snippet}
/// An example usage of [TooltipWindowController] looks like:
///
/// ** See code in examples/api/lib/widgets/windows/tooltip.0.dart **
/// {@end-tool}
///
/// {@macro flutter.widgets.windowing.controllerScope}
///
/// {@macro flutter.widgets.windowing.experimental}
abstract class TooltipWindowController extends BaseWindowController {
  /// Creates a [TooltipWindowController] with the provided properties.
  ///
  /// Upon construction, the window is created by the platform.
  ///
  /// The [parent] argument specifies the parent window of this tooltip.
  ///
  /// The [anchorRect] argument specifies the rectangle in the parent's coordinate
  /// space to which the tooltip is anchored.
  ///
  /// The [positioner] argument specifies how the tooltip should be positioned
  /// relative to the [anchorRect].
  ///
  /// The [constraints] are the constraints placed upon the size
  /// of the window.
  ///
  /// The [delegate] argument can be used to listen to the window's
  /// lifecycle. For example, it can be used to save state before
  /// a window is closed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  factory TooltipWindowController({
    required BaseWindowController parent,
    required Rect anchorRect,
    required WindowPositioner positioner,
    BoxConstraints constraints = const BoxConstraints(),
    TooltipWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    WidgetsFlutterBinding.ensureInitialized();
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    final TooltipWindowController controller = owner.createTooltipWindowController(
      parent: parent,
      constraints: constraints,
      delegate: delegate ?? TooltipWindowControllerDelegate(),
      anchorRect: anchorRect,
      positioner: positioner,
    );
    return controller;
  }

  /// Creates an empty [TooltipWindowController].
  ///
  /// This method is only intended to be used by subclasses of the
  /// [TooltipWindowController].
  ///
  /// Users who want to instantiate a new [TooltipWindowController] should
  /// always use the factory method to create a controller that is valid
  /// for their particular platform.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @protected
  TooltipWindowController.empty();

  /// The parent controller of this tooltip.
  ///
  /// The tooltip will be destroyed if its parent is destroyed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  BaseWindowController get parent;

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

  /// Updates the position of the tooltip.
  ///
  /// This requests that the tooltip be repositioned according to the new [anchorRect] and/or [positioner].
  ///
  /// On Linux due to a platform limitation this has no effect and only the
  /// positioner passed in the constructor is used. This means that tooltips
  /// that resize on Linux will remain in their original location.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void updatePosition({Rect? anchorRect, WindowPositioner? positioner});
}

/// Delegate class for popup window controller.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
/// * [PopupWindowController], the controller that creates and manages popup windows.
/// * [NestedWindow], which renders a popup alongside its anchor widget.
/// * [WindowControllerDelegate], the delegate for regular window controllers.
mixin class PopupWindowControllerDelegate {
  /// Invoked after the window is closed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void onWindowDestroyed() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }
}

/// A controller for a popup window.
///
/// A popup window is a transient window that is used for menus and context
/// menus. Popups may receive input focus. When another window receives input focus,
/// the popup is closed.
///
/// {@macro flutter.widgets.windowing.renderContent}
///
/// The user of this class is responsible for managing the lifecycle of the window.
/// When the window is no longer needed, the user should call [destroy] on this
/// controller to release the resources associated with the window.
///
/// If the parent window of the popup is destroyed, then the popup will
/// be destroyed as well. The user does not need to explicitly call [destroy]
/// in this case.
///
/// {@tool snippet}
/// An example usage of [PopupWindowController] looks like:
///
/// ** See code in examples/api/lib/widgets/windows/popup.0.dart **
/// {@end-tool}
///
/// {@macro flutter.widgets.windowing.controllerScope}
///
/// {@macro flutter.widgets.windowing.experimental}
abstract class PopupWindowController extends BaseWindowController {
  /// Creates a [PopupWindowController] with the provided properties.
  ///
  /// Upon construction, the window is created by the platform.
  ///
  /// The [parent] argument specifies the parent window of this popup.
  ///
  /// The [anchorRect] argument specifies the rectangle in the parent's coordinate
  /// space to which the popup is anchored.
  ///
  /// The [positioner] argument specifies how the popup should be positioned
  /// relative to the [anchorRect].
  ///
  /// The [constraints] limit the size of the window. If null, the window is
  /// unconstrained.
  ///
  /// The [delegate] argument can be used to listen to the window's
  /// lifecycle. For example, it can be used to save state before
  /// a window is closed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  factory PopupWindowController({
    required BaseWindowController parent,
    required Rect anchorRect,
    required WindowPositioner positioner,
    BoxConstraints? constraints,
    PopupWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    WidgetsFlutterBinding.ensureInitialized();
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createPopupWindowController(
      parent: parent,
      constraints: constraints ?? const BoxConstraints(),
      delegate: delegate ?? PopupWindowControllerDelegate(),
      anchorRect: anchorRect,
      positioner: positioner,
    );
  }

  /// Creates an empty [PopupWindowController].
  ///
  /// This method is only intended to be used by subclasses of the
  /// [PopupWindowController].
  ///
  /// Users who want to instantiate a new [PopupWindowController] should
  /// always use the factory method to create a controller that is valid
  /// for their particular platform.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @protected
  PopupWindowController.empty();

  /// The parent controller of this popup.
  ///
  /// The popup will be destroyed if its parent is destroyed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  BaseWindowController get parent;

  /// Request change to the constraints of the window.
  ///
  /// The [constraints] describes the new constraints that the window should
  /// satisfy. If the constraints disagree with the current size of the window,
  /// the platform might resize the window to satisfy the new constraints.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void setConstraints(BoxConstraints constraints);

  /// Updates the position of the popup.
  ///
  /// This requests that the popup be repositioned according to the new [anchorRect] and/or [positioner].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void updatePosition({Rect? anchorRect, WindowPositioner? positioner});

  /// Returns the offset of the popup's top-left corner in the parent window client area.
  ///
  /// The offset is in logical coordinates.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  Offset get offsetFromParent;

  /// Request activations of the window hierarchy to which this popup belongs.
  ///
  /// The popup window will receive keyboard input when the closest regular
  /// or dialog window is active and a focus node within this popup window
  /// is focused.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void activate() {
    BaseWindowController parent = this.parent;
    while (true) {
      if (parent is WindowController) {
        parent.activate();
        break;
      } else if (parent is DialogWindowController) {
        parent.activate();
        break;
      } else if (parent is PopupWindowController) {
        parent = parent.parent;
      } else {
        throw StateError('Unexpected controller in hierarchy $parent');
      }
    }
  }

  /// Whether the window this popup belongs to is currently activated.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bool get isActivated {
    BaseWindowController parent = this.parent;
    while (true) {
      if (parent is WindowController) {
        return parent.isActivated;
      } else if (parent is DialogWindowController) {
        return parent.isActivated;
      } else if (parent is PopupWindowController) {
        parent = parent.parent;
      } else {
        throw StateError('Unexpected controller in hierarchy $parent');
      }
    }
  }
}

/// Delegate class for satellite window controller.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [SatelliteWindowController], the controller that creates and manages a satellite window.
///  * [mountToplevelWindow], which renders a satellite in a separate widget subtree.
@internal
mixin class SatelliteWindowControllerDelegate {
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
  void onWindowCloseRequested(SatelliteWindowController controller) {
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
  }
}

/// A controller for a satellite window.
///
/// A satellite window is an auxiliary window to a regular or dialog window.
/// Satellite windows are initiially placed using a [WindowPositioner]. Afterwards,
/// the satellite window maintains its position relative to its parent. It is
/// hidden if the application becomes fullscreen or maximized.
///
/// Satellite windows may be resized and moved by the user. After being moved by
/// the user, the satellite window will retain its new position relative to its
/// parent such that when its parent moves, the satellite will be moved by the same
/// offset.
///
/// A satellite may be reparented. For example, if an application has two documents
/// open, the satellite may choose to reparent to the active document such that
/// closing one document will not cause the satellite to close. This behavior
/// may be implemented at the library level, such as in the Material API.
/// Reparenting a satellite will not change the current absolute position of the
/// satellite.
///
/// Upon construction, the window is created for the platform with the provided
/// properties.
///
/// {@macro flutter.widgets.windowing.renderContent}
///
/// The user of this class is responsible for managing the lifecycle of the window.
/// When the window is no longer needed, the user should call [destroy] on this
/// controller to release the resources associated with the window.
///
/// If the parent window of the satellite is destroyed, then the satellite will
/// be destroyed as well. The user does not need to explicitly call [destroy]
/// in this case.
///
/// [SatelliteWindowControllerDelegate.onWindowDestroyed]
/// will be called when the window is destroyed.
///
/// {@tool snippet}
/// An example usage of [SatelliteWindowController] looks like:
///
/// ** See code in examples/api/lib/widgets/windows/satellite.0.dart **
/// {@end-tool}
///
/// {@macro flutter.widgets.windowing.controllerScope}
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
abstract class SatelliteWindowController extends BaseWindowController {
  /// Creates a [SatelliteWindowController] with the provided properties.
  ///
  /// Upon construction, the window is created by the platform with
  /// the given [size].
  ///
  /// {@template flutter.widgets.windowing.satelliteConstructorCommon}
  /// The [parent] argument specifies the parent window of this satellite.
  ///
  /// The [initialPositioner] argument specifies how the satellite should be positioned
  /// relative to the [initialAnchorRect]. The positioner is only applied the first
  /// time that the window is shown. Afterwards, the user may move and resize
  /// the window to their preference. If the [parent] of the satellite moves, the
  /// satellite is moved relative to its parent. The satellite will always retain
  /// its current offset from its parent unless it is moved independently.
  ///
  /// The [initialAnchorRect] argument specifies the rectangle in the parent's coordinate
  /// space to which the tooltip is anchored. If it is `null`, then the satellite
  /// is position relative to the parent window, including its decorations.
  /// {@endtemplate}
  ///
  /// {@macro flutter.widgets.windowing.sizedConstructor}
  ///
  /// The [title] argument configures the window's title.
  /// If omitted, some platforms might fall back to the app's name.
  ///
  /// The [delegate] argument can be used to listen to the window's
  /// lifecycle. For example, it can be used to save state before
  /// a window is closed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  factory SatelliteWindowController({
    required BaseWindowController parent,
    required WindowPositioner initialPositioner,
    Rect? initialAnchorRect,
    Size? size,
    BoxConstraints? constraints,
    String? title,
    SatelliteWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    if (size != null && constraints != null) {
      assert(constraints.isSatisfiedBy(size));
    }

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createSatelliteWindowController(
      delegate: delegate ?? SatelliteWindowControllerDelegate(),
      parent: parent,
      initialAnchorRect: initialAnchorRect,
      initialPositioner: initialPositioner,
      size: size,
      constraints: constraints,
      title: title,
      resizable: true,
    );
  }

  /// Creates a [SatelliteWindowController] that sizes the window to its content.
  ///
  /// {@macro flutter.widgets.windowing.satelliteConstructorCommon}
  ///
  /// {@macro flutter.widgets.windowing.shrinkWrapConstructor}
  ///
  /// To create a satellite window with a specific size instead, use the default
  /// [SatelliteWindowController] constructor.
  ///
  /// {@macro flutter.widgets.windowing.shared}
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  factory SatelliteWindowController.shrinkWrap({
    required BaseWindowController parent,
    required WindowPositioner initialPositioner,
    Rect? initialAnchorRect,
    bool resizable = false,
    BoxConstraints? constraints,
    String? title,
    SatelliteWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    WidgetsFlutterBinding.ensureInitialized();
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createSatelliteWindowController(
      delegate: delegate ?? SatelliteWindowControllerDelegate(),
      parent: parent,
      initialAnchorRect: initialAnchorRect,
      initialPositioner: initialPositioner,
      constraints: constraints,
      resizable: resizable,
      title: title,
    );
  }

  /// Creates an empty [SatelliteWindowController].
  ///
  /// This method is only intended to be used by subclasses of the
  /// [SatelliteWindowController].
  ///
  /// Users who want to instantiate a new [SatelliteWindowController] should
  /// always use the factory method to create a controller that is valid
  /// for their particular platform.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @protected
  SatelliteWindowController.empty();

  /// The parent controller of this satellite.
  ///
  /// The satellite will be destroyed if its parent is destroyed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  BaseWindowController get parent;

  /// The current title of the window.
  ///
  /// The title shown in the window is controlled by the platform and may differ
  /// from the `title` set by the constructor or `setTitle`.
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

  /// Request to change the parent of the window.
  ///
  /// The satellite will maintain its current position after being reparented.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void setParent(BaseWindowController parent);

  /// Request change to the content size of the window.
  ///
  /// The [size] describes the new requested window size. If the size disagrees
  /// with the current constraints placed upon the window, the platform might
  /// clamp the size within the constraints.
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
}

/// [WindowingOwner] is responsible for creating and managing window controllers.
///
/// A custom implementation can be provided by setting [WidgetsBinding.windowingOwner].
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
abstract class WindowingOwner {
  /// Creates a [WindowController] with the provided properties.
  ///
  /// Most app developers should use [WindowController]'s constructor
  /// instead of calling this method directly. This method allows platforms
  /// to inject platform-specific logic.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  WindowController createWindowController({
    required WindowControllerDelegate delegate,
    Size? size,
    BoxConstraints? constraints,
    required bool resizable,
    String? title,
  });

  /// Creates a [DialogWindowController] with the provided properties.
  ///
  /// Most app developers should use [DialogWindowController]'s constructor
  /// instead of calling this method directly. This method allows platforms
  /// to inject platform-specific logic.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  DialogWindowController createDialogWindowController({
    required DialogWindowControllerDelegate delegate,
    Size? size,
    BoxConstraints? constraints,
    required bool resizable,
    BaseWindowController? parent,
    String? title,
  });

  /// Creates a [TooltipWindowController] with the provided properties.
  ///
  /// Most app developers should use [TooltipWindowController]'s constructor
  /// instead of calling this method directly. This method allows platforms
  /// to inject platform-specific logic.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  TooltipWindowController createTooltipWindowController({
    required TooltipWindowControllerDelegate delegate,
    required BoxConstraints constraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  });

  /// Creates a [PopupWindowController] with the provided properties.
  ///
  /// Most app developers should use [PopupWindowController]'s constructor
  /// instead of calling this method directly. This method allows platforms
  /// to inject platform-specific logic.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  PopupWindowController createPopupWindowController({
    required PopupWindowControllerDelegate delegate,
    required BoxConstraints constraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  });

  /// Creates a [SatelliteWindowController] with the provided properties.
  ///
  /// Most app developers should use [SatelliteWindowController]'s constructor
  /// instead of calling this method directly. This method allows platforms
  /// to inject platform-specific logic.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  SatelliteWindowController createSatelliteWindowController({
    required SatelliteWindowControllerDelegate delegate,
    required BaseWindowController parent,
    required WindowPositioner initialPositioner,
    Rect? initialAnchorRect,
    Size? size,
    BoxConstraints? constraints,
    required bool resizable,
    String? title,
  });
}

/// Creates default windowing owner for standard desktop embedders.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
WindowingOwner createDefaultWindowingOwner() {
  if (!isWindowingEnabled) {
    return _WindowingOwnerUnsupported(errorMessage: _kWindowingDisabledErrorMessage);
  }

  final WindowingOwner? owner = window_impl.createDefaultOwner();
  if (owner != null) {
    return owner;
  }

  return _WindowingOwnerUnsupported(errorMessage: 'Windowing is unsupported on this platform.');
}

/// Windowing delegate used on platforms that do not support windowing.
class _WindowingOwnerUnsupported extends WindowingOwner {
  _WindowingOwnerUnsupported({required this.errorMessage});

  final String errorMessage;

  @override
  WindowController createWindowController({
    required WindowControllerDelegate delegate,
    Size? size,
    BoxConstraints? constraints,
    bool resizable = true,
    String? title,
  }) {
    throw UnsupportedError(errorMessage);
  }

  @override
  DialogWindowController createDialogWindowController({
    required DialogWindowControllerDelegate delegate,
    Size? size,
    BoxConstraints? constraints,
    bool resizable = true,
    BaseWindowController? parent,
    String? title,
  }) {
    throw UnsupportedError(errorMessage);
  }

  @override
  TooltipWindowController createTooltipWindowController({
    required TooltipWindowControllerDelegate delegate,
    required BoxConstraints constraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) {
    throw UnimplementedError(errorMessage);
  }

  @override
  PopupWindowController createPopupWindowController({
    required PopupWindowControllerDelegate delegate,
    required BoxConstraints constraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) {
    throw UnimplementedError(errorMessage);
  }

  @override
  SatelliteWindowController createSatelliteWindowController({
    required SatelliteWindowControllerDelegate delegate,
    required BaseWindowController parent,
    required WindowPositioner initialPositioner,
    Rect? initialAnchorRect,
    Size? size,
    BoxConstraints? constraints,
    bool resizable = true,
    String? title,
  }) {
    throw UnimplementedError(errorMessage);
  }
}

enum _WindowControllerAspect {
  contentSize,
  title,
  activated,
  maximized,
  minimized,
  fullscreen,
  destroyed,
}

/// Provides descendants with access to the [BaseWindowController] associated with
/// the window that is being rendered.
///
/// [WindowManager] and [NestedWindow] provide a scope for each window's content,
/// allowing descendants to access that window's controller via [WindowScope.of].
///
/// Windows created using native APIs do not have a [WindowScope].
/// This includes the initial window created by the native entrypoint
/// that [runApp] attaches to.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowManager], which provides a scope for each top-level window.
///  * [NestedWindow], which provides a scope for a nested window.
///  * [mountToplevelWindow], which adds a window to the nearest manager.
@internal
class WindowScope extends InheritedModel<_WindowControllerAspect> {
  /// Creates a new [WindowScope].
  ///
  /// This widget is used by [WindowManager] and [NestedWindow] to provide
  /// widgets in a window's subtree with access to information about
  /// the window.
  ///
  /// The [controller] is the controller associated with this window,
  /// and the [child] is the widget tree that will have access
  /// to this context.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  WindowScope({super.key, required this.controller, required super.child})
    : _isDestroyed = controller.isDestroyed,
      // A destroyed controller throws from its other getters (e.g.
      // [BaseWindowController.contentSize]), so only the destroyed flag is read
      // once the window is gone. The remaining aspects are moot at that point
      // and fall back to defaults.
      _contentSize = controller.isDestroyed ? Size.zero : controller.contentSize,
      _title = controller.isDestroyed ? '' : _titleValue(controller),
      _isActivated = !controller.isDestroyed && _isActivatedValue(controller),
      _isMaximized = !controller.isDestroyed && _isMaximizedValue(controller),
      _isMinimized = !controller.isDestroyed && _isMinimizedValue(controller),
      _isFullscreen = !controller.isDestroyed && _isFullscreenValue(controller) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  // A snapshot of the aspect values captured from [controller] at construction
  // time.
  //
  // The window manager rebuilds this [WindowScope] with the same [controller]
  // instance whenever the controller notifies its listeners. Because the
  // controller is the same object across rebuilds, comparing the live
  // controller against itself in [updateShouldNotify] and
  // [updateShouldNotifyDependent] would never detect a change. Capturing the
  // values here means the old and new widgets hold independent snapshots that
  // can be compared to detect which aspects changed.
  final Size _contentSize;
  final String _title;
  final bool _isActivated;
  final bool _isMaximized;
  final bool _isMinimized;
  final bool _isFullscreen;
  final bool _isDestroyed;

  /// The controller associated with this window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final BaseWindowController controller;

  /// Returns the [BaseWindowController] for the window that hosts the given context.
  ///
  /// {@template flutter.widgets.windowing.windowScope.of}
  /// If there is no [WindowScope] in scope, this method
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
  /// * [WindowController], the controller for regular top-level windows.
  /// * [DialogWindowController], the controller for dialog windows.
  /// * [WindowManager], which provides a scope for each top-level window.
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
  /// * [WindowController], the controller for regular top-level windows.
  /// * [DialogWindowController], the controller for dialog windows.
  /// * [WindowManager], which provides a scope for each top-level window.
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
  /// * [WindowController.title], which returns the current title of the window.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static String titleOf(BuildContext context) {
    return _titleValue(_of(context, _WindowControllerAspect.title));
  }

  /// Returns title of the nearest [WindowScope], or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [WindowController.title], which returns the current title of the window.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static String? maybeTitleOf(BuildContext context) {
    final BaseWindowController? controller = _maybeOf(context, _WindowControllerAspect.title);
    if (controller == null) {
      return null;
    }

    return _titleValue(controller);
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
  /// * [WindowController.isActivated], which returns the current activation status of the window.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static bool isActivatedOf(BuildContext context) {
    return _isActivatedValue(_of(context, _WindowControllerAspect.activated));
  }

  /// Returns the activation status of the nearest [WindowScope],
  /// or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [WindowController.isActivated], which returns the current activation status of the window.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static bool? maybeIsActivatedOf(BuildContext context) {
    final BaseWindowController? controller = _maybeOf(context, _WindowControllerAspect.activated);
    if (controller == null) {
      return null;
    }

    return _isActivatedValue(controller);
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
  /// * [WindowController.isMinimized], which returns the current minimized status of the window.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static bool isMinimizedOf(BuildContext context) {
    return _isMinimizedValue(_of(context, _WindowControllerAspect.minimized));
  }

  /// Returns the minimization status of the nearest [WindowScope],
  /// or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [WindowController.isMinimized], which returns the current minimized status of the window.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static bool? maybeIsMinimizedOf(BuildContext context) {
    final BaseWindowController? controller = _maybeOf(context, _WindowControllerAspect.minimized);
    if (controller == null) {
      return null;
    }

    return _isMinimizedValue(controller);
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
  /// * [WindowController.isMaximized], which returns the current maximized status of the window.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static bool isMaximizedOf(BuildContext context) {
    return _isMaximizedValue(_of(context, _WindowControllerAspect.maximized));
  }

  /// Returns the maximization status of the nearest [WindowScope],
  /// or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [WindowController.isMaximized], which returns the current maximized status of the window.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static bool? maybeIsMaximizedOf(BuildContext context) {
    final BaseWindowController? controller = _maybeOf(context, _WindowControllerAspect.maximized);
    if (controller == null) {
      return null;
    }

    return _isMaximizedValue(controller);
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
  /// * [WindowController.isFullscreen], which returns the current fullscreen status of the window.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static bool isFullscreenOf(BuildContext context) {
    return _isFullscreenValue(_of(context, _WindowControllerAspect.fullscreen));
  }

  /// Returns the fullscreen status of the nearest [WindowScope],
  /// or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [WindowController.isFullscreen], which returns the current fullscreen status of the window.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static bool? maybeIsFullscreenOf(BuildContext context) {
    final BaseWindowController? controller = _maybeOf(context, _WindowControllerAspect.fullscreen);
    if (controller == null) {
      return null;
    }

    return _isFullscreenValue(controller);
  }

  /// Returns whether the nearest [WindowScope]'s window is destroyed.
  ///
  /// {@macro flutter.widgets.windowing.windowScope.of}
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [BaseWindowController.isDestroyed], which returns whether the underlying
  ///   native window is destroyed.
  /// * [of], which returns the [BaseWindowController] associated with the window.
  @internal
  static bool isDestroyedOf(BuildContext context) {
    return _of(context, _WindowControllerAspect.destroyed).isDestroyed;
  }

  /// Returns whether the nearest [WindowScope]'s window is destroyed,
  /// or null if not found.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  /// * [BaseWindowController.isDestroyed], which returns whether the underlying
  ///   native window is destroyed.
  /// * [maybeOf], which returns the [BaseWindowController] associated with the window, or null if not found.
  @internal
  static bool? maybeIsDestroyedOf(BuildContext context) {
    return _maybeOf(context, _WindowControllerAspect.destroyed)?.isDestroyed;
  }

  /// Computes the value of the [_WindowControllerAspect.title] aspect for the
  /// given [controller]. Controllers that do not support titles report an empty
  /// string.
  static String _titleValue(BaseWindowController controller) => switch (controller) {
    WindowController() => controller.title,
    DialogWindowController() => controller.title,
    TooltipWindowController() => '',
    PopupWindowController() => '',
    SatelliteWindowController() => controller.title,
  };

  // Computes the value of the [_WindowControllerAspect.activated] aspect for the
  // given [controller]. Controllers that do not support activation report false.
  static bool _isActivatedValue(BaseWindowController controller) => switch (controller) {
    WindowController() => controller.isActivated,
    DialogWindowController() => controller.isActivated,
    TooltipWindowController() => false,
    PopupWindowController() => controller.isActivated,
    SatelliteWindowController() => controller.isActivated,
  };

  /// Computes the value of the [_WindowControllerAspect.maximized] aspect for the
  /// given [controller]. Controllers that do not support maximization report
  /// false.
  static bool _isMaximizedValue(BaseWindowController controller) => switch (controller) {
    WindowController() => controller.isMaximized,
    DialogWindowController() => false,
    TooltipWindowController() => false,
    PopupWindowController() => false,
    SatelliteWindowController() => false,
  };

  /// Computes the value of the [_WindowControllerAspect.minimized] aspect for the
  /// given [controller]. Controllers that do not support minimization report
  /// false.
  static bool _isMinimizedValue(BaseWindowController controller) => switch (controller) {
    WindowController() => controller.isMinimized,
    DialogWindowController() => controller.isMinimized,
    TooltipWindowController() => false,
    PopupWindowController() => false,
    SatelliteWindowController() => false,
  };

  /// Computes the value of the [_WindowControllerAspect.fullscreen] aspect for
  /// the given [controller]. Controllers that do not support fullscreen report
  /// false.
  static bool _isFullscreenValue(BaseWindowController controller) => switch (controller) {
    WindowController() => controller.isFullscreen,
    DialogWindowController() => false,
    TooltipWindowController() => false,
    PopupWindowController() => false,
    SatelliteWindowController() => false,
  };

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
            'context used is not within the content of a window rendered by '
            'WindowManager, which introduces a WindowScope for each window.',
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
  bool updateShouldNotify(WindowScope oldWidget) {
    return controller != oldWidget.controller ||
        _contentSize != oldWidget._contentSize ||
        _title != oldWidget._title ||
        _isActivated != oldWidget._isActivated ||
        _isMaximized != oldWidget._isMaximized ||
        _isMinimized != oldWidget._isMinimized ||
        _isFullscreen != oldWidget._isFullscreen ||
        _isDestroyed != oldWidget._isDestroyed;
  }

  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @override
  bool updateShouldNotifyDependent(WindowScope oldWidget, Set<Object> dependencies) {
    return dependencies.any(
      (Object dependency) =>
          dependency is _WindowControllerAspect &&
          switch (dependency) {
            _WindowControllerAspect.contentSize => _contentSize != oldWidget._contentSize,
            _WindowControllerAspect.title => _title != oldWidget._title,
            _WindowControllerAspect.activated => _isActivated != oldWidget._isActivated,
            _WindowControllerAspect.maximized => _isMaximized != oldWidget._isMaximized,
            _WindowControllerAspect.minimized => _isMinimized != oldWidget._isMinimized,
            _WindowControllerAspect.fullscreen => _isFullscreen != oldWidget._isFullscreen,
            _WindowControllerAspect.destroyed => _isDestroyed != oldWidget._isDestroyed,
          },
    );
  }
}

/// A registry providing access to the top-level windows rendered by a manager.
///
/// The [WindowManager] provides a [WindowRegistry] to its descendants.
///
/// Descendants of the manager can use [WindowRegistry.maybeOf] to access the
/// registry and inspect [windows]. To add a window, use [mountToplevelWindow].
/// When a registered window's controller reports that it has been destroyed,
/// the manager removes its entry from the registry.
///
/// Windows rendered by [NestedWindow] are not registered here.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowManager], responsible for listening for new windows and rendering them.
@internal
class WindowRegistry extends ChangeNotifier {
  /// Creates a window registry.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  WindowRegistry() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  final List<WindowEntry> _windows = <WindowEntry>[];

  /// The list of registered windows.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  List<WindowEntry> get windows => List<WindowEntry>.unmodifiable(_windows);

  void _register(WindowEntry entry) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _windows.add(entry);
    notifyListeners();
  }

  void _unregister(WindowEntry entry) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _windows.remove(entry);
    notifyListeners();
  }

  /// Retrieves the [WindowRegistry] from the given [context].
  ///
  /// Returns null if no registry is found in the widget tree.
  ///
  /// This does not throw when used in a non-windowing environment, as this
  /// may be a signal to the owner that windowing itself is unavailable.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  static WindowRegistry? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_WindowRegistryScope>()?._registry;
  }

  /// Retrieves the [WindowRegistry] from the given [context].
  ///
  /// If there is no [WindowRegistry] in scope, this method
  /// will throw a [TypeError] exception in release builds, and throws
  /// a descriptive [FlutterError] in debug builds.
  ///
  /// This method can still be called when windowing is not enabled, as it
  /// may be a signal to the owner that windowing itself is unavailable.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  static WindowRegistry of(BuildContext context) {
    final WindowRegistry? registry = maybeOf(context);
    assert(() {
      if (registry == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('No WindowRegistry found in context.'),
          ErrorDescription(
            '${context.widget.runtimeType} widgets require a WindowRegistry widget ancestor.',
          ),
          context.describeWidget(
            'The specific widget that could not find a WindowRegistry ancestor was',
          ),
          context.describeOwnershipChain('The ownership chain for the affected widget is'),
          ErrorHint(
            'No WindowRegistry ancestor could be found starting from the context '
            'that was passed to WindowRegistry.of(). This can happen because the '
            'context used is not a descendant of a WindowManager widget, which introduces '
            'a WindowRegistry.',
          ),
        ]);
      }
      return true;
    }());
    return registry!;
  }
}

class _WindowRegistryScope extends InheritedWidget {
  _WindowRegistryScope({required this._registry, required super.child}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  final WindowRegistry _registry;

  @override
  bool updateShouldNotify(_WindowRegistryScope oldWidget) {
    return _registry != oldWidget._registry;
  }
}

/// Pairs a native window controller with a builder for its widget content.
///
/// Creating an entry does not mount its content. Pass it to
/// [WindowManager.initialWindows] or [mountToplevelWindow] to render it in a
/// separate subtree, or return it from [NestedWindow.entryBuilder] to render it
/// in the surrounding subtree.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [mountToplevelWindow], which adds an entry to the nearest window manager.
///  * [NestedWindow], which renders an entry without registering it with a manager.
@internal
class WindowEntry {
  /// Creates a window entry.
  ///
  /// The [controller] parameter is the controller that manages the window.
  ///
  /// The [builder] parameter is a function that builds the content of the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  WindowEntry({required this.controller, required this.builder}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  /// The controller that manages the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final BaseWindowController controller;

  /// The builder function that builds the content of the window.
  ///
  /// The returned widget is rendered in [BaseWindowController.rootView].
  /// This callback may be invoked more than once and should not create the
  /// native window; use [controller] for that window.
  ///
  /// When rendered by [WindowManager] or [NestedWindow], the supplied context
  /// is below the window's [View] and [WindowScope], so it can be used to look
  /// up that view or controller.
  ///
  /// When rendered by [NestedWindow], the context also inherits from the widgets
  /// surrounding [NestedWindow].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final WidgetBuilder builder;
}

/// Renders and manages a collection of top-level windows.
///
/// Pass a [WindowManager] to [runWidget] to render [initialWindows]. Initialize
/// the binding with [WidgetsFlutterBinding.ensureInitialized] before creating
/// the windows' controllers.
///
/// Descendants may use [mountToplevelWindow] to add windows. Each entry is
/// rendered in its own [View] and [WindowScope], as a sibling of the other
/// entries. The manager provides a [WindowRegistry] for inspecting these entries
/// and removes an entry when its controller reports that the window is destroyed.
///
/// This widget does not render into the implicit view used by [runApp].
/// Windowing must be enabled; it does not provide a fallback for platforms
/// without windowing support.
///
/// {@tool sample}
/// This example starts with one window and uses [mountToplevelWindow] to add a
/// dialog as a sibling subtree.
///
/// ** See code in examples/api/lib/widgets/windows/window_manager.0.dart **
/// {@end-tool}
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [mountToplevelWindow], a global function to render a window into the tree.
@internal
class WindowManager extends StatefulWidget {
  /// Creates a window manager.
  ///
  /// The [initialWindows] are registered when this widget's state is initialized.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  const WindowManager({super.key, required this.initialWindows});

  /// The initial windows to be registered and managed by this window manager.
  ///
  /// This list is read only when the state is initialized. Updating it during a
  /// rebuild does not add or remove windows. To open another window, use
  /// [mountToplevelWindow]; to close one, call [BaseWindowController.destroy].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  final List<WindowEntry> initialWindows;

  @override
  State<WindowManager> createState() => _WindowManagerState();
}

class _WindowManagerState extends State<WindowManager> {
  final WindowRegistry _registry = WindowRegistry();

  @override
  void initState() {
    super.initState();
    widget.initialWindows.forEach(_registry._register);
  }

  @override
  Widget build(BuildContext context) {
    return _WindowRegistryScope(
      registry: _registry,
      child: ListenableBuilder(
        listenable: _registry,
        builder: (BuildContext context, Widget? child) {
          final List<Widget> subViews = _registry.windows.map((WindowEntry entry) {
            return _WindowEntryRender(entry: entry, removeFromRegistry: true);
          }).toList();

          return ViewCollection(views: subViews);
        },
      ),
    );
  }
}

class _WindowEntryRender extends StatefulWidget {
  const _WindowEntryRender({required this.entry, required this.removeFromRegistry});

  final WindowEntry entry;
  final bool removeFromRegistry;

  @override
  State<_WindowEntryRender> createState() => _WindowEntryRenderState();
}

class _WindowEntryRenderState extends State<_WindowEntryRender> {
  @override
  void initState() {
    super.initState();
    widget.entry.controller.addListener(_handleWindowDestroyed);
  }

  @override
  void dispose() {
    super.dispose();
    widget.entry.controller.removeListener(_handleWindowDestroyed);
  }

  void _handleWindowDestroyed() {
    if (!widget.removeFromRegistry) {
      return;
    }

    if (widget.entry.controller.isDestroyed) {
      final WindowRegistry windowRegistry = WindowRegistry.of(context);
      windowRegistry._unregister(widget.entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final WindowEntry entry = widget.entry;
    return ListenableBuilder(
      listenable: entry.controller,
      builder: (BuildContext context, Widget? widget) => WindowScope(
        controller: entry.controller,
        child: View(
          view: entry.controller.rootView,
          child: Builder(builder: entry.builder),
        ),
      ),
    );
  }
}

/// Mounts a window as a new entry in the nearest [WindowManager].
///
/// The [entry] pairs an existing native window controller with a builder for its
/// content. The manager registers the entry and renders its content in the
/// controller's [BaseWindowController.rootView] on a subsequent build.
/// A native window must not be mounted more than once.
///
/// The new window's subtree is a sibling of the manager's other windows, not a
/// descendant of the calling [context]. Inherited widgets below the manager in
/// the caller's subtree are therefore not available to the new window.
/// Inherited widgets above the manager remain available to all its windows.
/// Typically, each entry builds its own `WidgetsApp` or `MaterialApp`.
///
/// The [context] must be a descendant of a [WindowManager]. Throws a [StateError]
/// if no manager's [WindowRegistry] is available from that context.
///
/// The manager provides a [WindowScope] around the new window's content. Close
/// the window by calling [BaseWindowController.destroy] on [WindowEntry.controller].
/// Its entry is removed when the controller reports that it is destroyed.
/// Removing the caller from the widget tree does not close the mounted window.
///
/// "Top-level" describes placement in the widget tree, not the native window
/// type. An entry can use any [BaseWindowController], including a dialog with a
/// native parent. To share the caller's inherited widgets instead, use
/// [NestedWindow].
///
/// {@tool sample}
/// This example adds a dialog to the manager from an existing window.
///
/// ** See code in examples/api/lib/widgets/windows/window_manager.0.dart **
/// {@end-tool}
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowManager.initialWindows], which supplies windows at startup.
///  * [NestedWindow], which renders a window in the surrounding widget subtree.
@internal
void mountToplevelWindow({required BuildContext context, required WindowEntry entry}) {
  if (!isWindowingEnabled) {
    throw UnsupportedError(_kWindowingDisabledErrorMessage);
  }

  final WindowRegistry? windowRegistry = WindowRegistry.maybeOf(context);
  if (windowRegistry == null) {
    throw StateError(
      'To use `mountToplevelWindow`, a `WindowManager` widget must be rendered in your hierarchy and accessible in via the context.',
    );
  }

  windowRegistry._register(entry);
}

/// Creates a window entry when a [NestedWindow] is shown.
///
/// Called by [NestedWindow.entryBuilder] on each transition from hidden to
/// showing. The callback should create a new native window controller and return
/// it with a content builder in a [WindowEntry], since hiding the nested window
/// destroys the previous controller's native window.
///
/// This callback receives the potential anchor rectangle of the window as a
/// parameter, if one is available.
///
/// {@macro flutter.widgets.windowing.nestedExperimental}
@internal
typedef WindowEntryBuilder = WindowEntry Function(Rect?);

/// Controls whether a [NestedWindow] renders its window content.
///
/// This controller controls the widget's visibility, not the native window's
/// properties. The [BaseWindowController] returned by
/// [NestedWindow.entryBuilder] manages the native window.
///
/// Keep this controller for the lifetime of one [NestedWindow] and call [show],
/// [hide], or [toggle] only while that widget is mounted. Listeners are notified
/// when [showing] changes. The owner is responsible for disposing this controller
/// when it is no longer needed; disposing it does not close the native window.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
class NestedWindowController extends ChangeNotifier {
  /// Creates a controller for an initially hidden [NestedWindow].
  NestedWindowController();
  late final _NestedWindowState _anchor;
  bool _showing = false;

  /// Whether the associated [NestedWindow] is showing its window content.
  ///
  /// This tracks calls to [show] and [hide], not native visibility or activation.
  bool get showing => _showing;

  void _setShowing(bool showing) {
    _showing = showing;
    notifyListeners();
  }

  /// Creates and shows the associated [NestedWindow]'s native window.
  ///
  /// Calls [NestedWindow.entryBuilder] to obtain a fresh entry. Does nothing if
  /// the nested window is already showing.
  ///
  /// The associated [NestedWindow] must be mounted.
  void show() {
    _anchor._show();
  }

  /// Destroys the native window and removes its content from [NestedWindow].
  ///
  /// Does nothing if the nested window is already hidden. A subsequent [show]
  /// creates a new entry rather than reusing the destroyed window.
  ///
  /// The associated [NestedWindow] must be mounted.
  void hide() {
    _anchor._hide();
  }

  /// Hides the window if it is showing, or shows it if it is hidden.
  ///
  /// The associated [NestedWindow] must be mounted.
  void toggle() {
    _anchor._toggle();
  }
}

/// Renders a window alongside [child] in the surrounding widget subtree.
///
/// The [child] remains in its current view. When [controller] shows the window,
/// [entryBuilder] creates a [WindowEntry] whose content is rendered in a separate
/// [View], attached with a [ViewAnchor]. The window's content inherits from
/// ancestors of this widget, but not from [child] or its descendants.
/// This widget must have a [View] ancestor for [child] to render into.
///
/// Unlike [mountToplevelWindow], this widget does not require a [WindowManager]
/// or add an entry to a [WindowRegistry]. It is useful for popups, tooltips, and
/// other windows that need access to the surrounding inherited widgets.
///
/// Nesting in the widget tree does not set a native parent. Supply the appropriate
/// parent when creating the native controller in [entryBuilder]. This widget
/// provides a [WindowScope] for that controller, so descendants of the window's
/// content can access it via [WindowScope.of].
///
/// For [PopupWindowController] and [TooltipWindowController], this widget tracks
/// [child]'s bounds in the containing view and requests position updates when
/// those bounds change. The entry builder must still supply an initial anchor
/// rectangle and a [WindowPositioner]. Native platform positioning restrictions
/// still apply.
///
/// The window is initially hidden. Use [NestedWindowController.show],
/// [NestedWindowController.hide], or [NestedWindowController.toggle] to change
/// its visibility. Hiding destroys the native window; showing it again calls
/// [entryBuilder] for a new entry. Close the window before removing this widget,
/// since removing it does not itself destroy the native window.
///
/// {@tool snippet}
/// This helper builds a button and a nested dialog in an existing window's
/// `MaterialApp`. The dialog shares the surrounding app's inherited widgets.
/// The caller keeps the controller in its state and disposes it when no longer
/// needed, after closing the dialog.
///
/// ```dart
/// // ignore_for_file: invalid_use_of_internal_member
/// import 'package:flutter/material.dart';
/// import 'package:flutter/src/widgets/_window.dart';
///
/// Widget buildNestedDialog(
///   BuildContext context,
///   NestedWindowController controller,
/// ) {
///   return NestedWindow(
///     controller: controller,
///     entryBuilder: (Rect? anchorRect) {
///       final DialogWindowController dialog = DialogWindowController(
///         parent: WindowScope.of(context),
///         size: const Size(400, 300),
///         title: 'Nested dialog',
///       );
///       return WindowEntry(
///         controller: dialog,
///         builder: (BuildContext context) => Material(
///           child: Center(
///             child: ElevatedButton(
///               onPressed: controller.hide,
///               child: const Text('Close dialog'),
///             ),
///           ),
///         ),
///       );
///     },
///     child: ElevatedButton(
///       onPressed: controller.show,
///       child: const Text('Open dialog'),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@macro flutter.widgets.windowing.nestedExperimental}
///
/// See also:
///
///  * [mountToplevelWindow], which renders content in a separate subtree under a
///    window manager.
///  * [ViewAnchor], which attaches a view alongside a widget in another view.
@internal
class NestedWindow extends StatefulWidget {
  /// Creates a widget that can show a nested window alongside [child].
  ///
  /// The [entryBuilder] is called lazily when [controller] shows the window,
  /// rather than when this widget is built.
  const NestedWindow({
    super.key,
    required this.controller,
    required this.entryBuilder,
    required this.child,
  });

  /// Controls whether the nested window is shown.
  ///
  /// Keep the same controller while this widget is mounted. The caller owns the
  /// controller and is responsible for disposing it.
  final NestedWindowController controller;

  /// Creates the native window controller and content builder each time the
  /// window is shown after being hidden.
  ///
  /// Return a fresh [WindowEntry] with a new controller on each call. Updating
  /// this callback while the window is showing does not replace the current
  /// entry.
  final WindowEntryBuilder entryBuilder;

  /// The widget that remains in the containing view whether the window is shown
  /// or hidden.
  ///
  /// Its bounds are used to update the anchor rectangle for popup and tooltip
  /// windows.
  final Widget child;

  @override
  State<NestedWindow> createState() => _NestedWindowState();
}

class _NestedWindowState extends State<NestedWindow> {
  WindowEntry? _entry;
  _ElementPositionTracker? _tracker;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller._anchor = this;
  }

  @override
  void dispose() {
    _tracker?.dispose();
    super.dispose();
  }

  void _show() {
    if (_entry != null) {
      return;
    }
    final tracker = _ElementPositionTracker(element: _key.currentContext!);
    final WindowEntry entry = widget.entryBuilder(tracker.getGlobalRect());
    tracker.onGlobalRectChange = (rect) {
      switch (entry.controller) {
        case final PopupWindowController popup:
          popup.updatePosition(anchorRect: rect);
        case final TooltipWindowController tooltip:
          tooltip.updatePosition(anchorRect: rect);
        default:
          break;
      }
    };
    widget.controller._setShowing(true);
    entry.controller.addListener(_onDestroyed);
    setState(() {
      _entry = entry;
      _tracker = tracker;
    });
  }

  void _onDestroyed() {
    if (_entry == null || !_entry!.controller.isDestroyed) {
      return;
    }

    _tracker?.dispose();
    widget.controller._setShowing(false);
    _entry?.controller.removeListener(_onDestroyed);
    setState(() {
      _entry = null;
      _tracker = null;
    });
  }

  void _hide() {
    if (_entry == null) {
      return;
    }

    _entry!.controller.destroy();
  }

  void _toggle() {
    if (_entry == null) {
      _show();
    } else {
      _hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewAnchor(
      view: _entry != null ? _WindowEntryRender(entry: _entry!, removeFromRegistry: false) : null,
      child: KeyedSubtree(key: _key, child: widget.child),
    );
  }
}

/// Tracks the global rect of an [Element].
class _ElementPositionTracker {
  _ElementPositionTracker({required this.element}) {
    _ElementPositionTrackerManager.instance.add(this);
  }

  void dispose() {
    _ElementPositionTrackerManager.instance.remove(this);
  }

  /// Returns current global rect for the tracked element, or `null` if not available.
  Rect? getGlobalRect() {
    final Rect? rect = _getGlobalRect();
    _lastReportedRect = rect;
    return rect;
  }

  /// Callback invoked every time the global position of the tracked element changes
  /// compared to last result of [getGlobalRect].
  void Function(Rect rect)? onGlobalRectChange;

  final BuildContext element;
  Rect? _lastReportedRect;

  Rect? _getGlobalRect() {
    if (!element.mounted) {
      return null;
    }
    final RenderObject? renderBox = element.findRenderObject();
    if (renderBox is! RenderBox) {
      return null;
    }

    final Matrix4 transform = renderBox.getTransformTo(null);
    final Rect rect = Offset.zero & renderBox.size;
    final Rect globalRect = MatrixUtils.transformRect(transform, rect);
    return globalRect;
  }

  void _updateSelf() {
    final Rect? rect = _getGlobalRect();
    if (rect == null) {
      _ElementPositionTrackerManager.instance.remove(this);
      return;
    }
    if (_lastReportedRect != rect) {
      _lastReportedRect = rect;
      onGlobalRectChange?.call(rect);
    }
  }
}

class _ElementPositionTrackerManager {
  _ElementPositionTrackerManager._() {
    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      final trackersCopy = List<_ElementPositionTracker>.from(_trackers, growable: false);
      for (final tracker in trackersCopy) {
        tracker._updateSelf();
      }
    });
  }

  static final _instance = _ElementPositionTrackerManager._();
  static _ElementPositionTrackerManager get instance => _instance;
  final List<_ElementPositionTracker> _trackers = <_ElementPositionTracker>[];

  void add(_ElementPositionTracker tracker) {
    _trackers.add(tracker);
  }

  void remove(_ElementPositionTracker tracker) {
    _trackers.remove(tracker);
  }
}
