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
///  * [RegularWindowController], the controller for regular top-level windows.
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
///
/// ```dart
/// // TODO(mattkae): remove invalid_use_of_internal_member ignore comment when this API is stable.
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
/// via the [WindowScope] inherited widget.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
abstract class RegularWindowController extends BaseWindowController {
  /// Creates a [RegularWindowController] with a specific size.
  ///
  /// Upon construction, the window is created by the platform with the
  /// given [preferredSize].
  ///
  /// {@template flutter.widgets.windowing.sizedConstructor}
  ///
  /// The [preferredSize] is the preferred content size of the window. The
  /// platform will try to apply this size when the window is created, but it
  /// might not be honored.
  ///
  /// The [preferredConstraints] field enforces the minimum and maximum size of
  /// the window. The [preferredSize] must satisfy the [preferredConstraints].
  /// If the user attempts to resize the window beyond these constraints, the
  /// platform will enforce the constraints according to its own policy. For
  /// example, the platform might clip the content to fit within the resized
  /// window, or it might prevent the window from being resized altogether.
  /// These constraints might not be honored by the platform. If null, the
  /// window will be unconstrained.
  /// {@endtemplate}
  ///
  /// To create a window that is sized to its content instead, use
  /// [RegularWindowController.sizedToContent].
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
  factory RegularWindowController({
    required Size preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
    RegularWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    if (preferredConstraints != null) {
      assert(preferredConstraints.isSatisfiedBy(preferredSize));
    }

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createRegularWindowController(
      delegate: delegate ?? RegularWindowControllerDelegate(),
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      title: title,
      resizable: true,
    );
  }

  /// Creates a [RegularWindowController] that sizes the window to its content.
  ///
  /// {@template flutter.widgets.windowing.sizedToContentConstructor}
  /// The window is created by the platform and initially
  /// sized to fit its content.
  ///
  /// The [resizable] property determines how the window behaves after that initial sizing:
  ///
  /// * If `false`, the window remains fixed to its content size. If the
  ///   content changes size, the window will automatically resize to match,
  ///   subject to [preferredConstraints]. This is the default.
  /// * If `true`, the user can manually resize the window, subject to
  ///   [preferredConstraints]. After the initial automatic sizing,
  ///   the window will no longer track the size of its content.
  ///
  /// The [preferredConstraints] field enforces the minimum and maximum size of
  /// the window. If the user attempts to resize the window beyond these
  /// constraints, the platform will enforce the constraints according to its
  /// own policy. For example, the platform might clip the content to fit
  /// within the resized window, or it might prevent the window from being
  /// resized altogether. These constraints might not be honored by the
  /// platform. If null, the window will be unconstrained.
  /// {@endtemplate}
  ///
  /// To create a window with a specific size instead, use the default
  /// [RegularWindowController] constructor.
  ///
  /// {@macro flutter.widgets.windowing.shared}
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  factory RegularWindowController.sizedToContent({
    bool resizable = false,
    BoxConstraints? preferredConstraints,
    String? title,
    RegularWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    WidgetsFlutterBinding.ensureInitialized();

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createRegularWindowController(
      delegate: delegate ?? RegularWindowControllerDelegate(),
      preferredConstraints: preferredConstraints,
      resizable: resizable,
      title: title,
    );
  }

  /// Creates an empty [RegularWindowController].
  ///
  /// This method is only intended to be used by subclasses of the
  /// [RegularWindowController].
  ///
  /// Users who want to instantiate a new [RegularWindowController] should
  /// always use the factory method to create a controller that is valid
  /// for their particular platform.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @protected
  RegularWindowController.empty();

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
///  * [DialogWindow], the widget for a dialog window.
///  * [RegularWindowControllerDelegate], the delegate for regular window controllers.
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
/// This class does not interact with the widget tree. Instead, it is typically
/// provided to the [DialogWindow] widget, which renders the content inside the
/// dialog window.
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
///       child: const MyApp()
///     )
///   );
/// }
///
/// class MyApp extends StatelessWidget {
///   const MyApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: DialogWindow(
///         controller: DialogWindowController(
///           preferredSize: const Size(400, 300),
///           parent: WindowScope.of(context),
///           title: 'Example Dialog'
///         ),
///         child: const Text('Hello, World!')
///       )
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// Children of a [DialogWindow] widget can access the [DialogWindowController]
/// via the [WindowScope] inherited widget.
///
/// {@macro flutter.widgets.windowing.experimental}
abstract class DialogWindowController extends BaseWindowController {
  /// Creates a [DialogWindowController] with a specific size.
  ///
  /// Upon construction, the window is created by the platform with
  /// the given [preferredSize].
  ///
  /// {@macro flutter.widgets.windowing.sizedConstructor}
  ///
  /// To create a dialog that is sized to its content instead, use
  /// [DialogWindowController.sizedToContent].
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
    required Size preferredSize,
    BoxConstraints? preferredConstraints,
    BaseWindowController? parent,
    String? title,
    DialogWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    WidgetsFlutterBinding.ensureInitialized();

    if (preferredConstraints != null) {
      assert(preferredConstraints.isSatisfiedBy(preferredSize));
    }

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createDialogWindowController(
      delegate: delegate ?? DialogWindowControllerDelegate(),
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      title: title,
      parent: parent,
      resizable: true,
    );
  }

  /// Creates a [DialogWindowController] that sizes the window to its content.
  ///
  /// {@macro flutter.widgets.windowing.sizedToContentConstructor}
  ///
  /// To create a dialog with a specific size instead, use the default
  /// [DialogWindowController] constructor.
  ///
  /// {@macro flutter.widgets.windowing.dialogParent}
  ///
  /// {@macro flutter.widgets.windowing.shared}
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  factory DialogWindowController.sizedToContent({
    bool resizable = false,
    BoxConstraints? preferredConstraints,
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
      preferredConstraints: preferredConstraints,
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
/// * [TooltipWindow], the widget for a tooltip window.
/// * [RegularWindowControllerDelegate], the delegate for regular window controllers.
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
/// This class does not interact with the widget tree. Instead, it is typically
/// provided to the [TooltipWindow] widget, which renders the content inside the
/// tooltip window.
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
/// Children of a [TooltipWindow] widget can access the [TooltipWindowController]
/// via the [WindowScope] inherited widget.
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
  /// The [preferredConstraints] are the constraints placed upon the size
  /// of the window.
  ///
  /// {@macro flutter.widgets.windowing.constraints}
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
    BoxConstraints preferredConstraints = const BoxConstraints(),
    TooltipWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    WidgetsFlutterBinding.ensureInitialized();
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    final TooltipWindowController controller = owner.createTooltipWindowController(
      parent: parent,
      preferredConstraints: preferredConstraints,
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
/// * [PopupWindow], the widget for a popup window.
/// * [RegularWindowControllerDelegate], the delegate for regular window controllers.
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
/// This class does not interact with the widget tree. Instead, it is typically
/// provided to the [PopupWindow] widget, which renders the content inside the
/// popup window.
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
/// Children of a [PopupWindow] widget can access the [PopupWindowController]
/// via the [WindowScope] [InheritedWidget].
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
  /// {@macro flutter.widgets.windowing.constraints}
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
    BoxConstraints? preferredConstraints,
    PopupWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    WidgetsFlutterBinding.ensureInitialized();
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createPopupWindowController(
      parent: parent,
      preferredConstraints: preferredConstraints ?? const BoxConstraints(),
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
      if (parent is RegularWindowController) {
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
      if (parent is RegularWindowController) {
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
///  * [SatelliteWindow], the widget for a satellite window.
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
/// This class does not interact with the widget tree. Instead, it is typically
/// provided to the [SatelliteWindow] widget, who does the work of rendering the
/// content inside of this window.
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
/// Children of a [SatelliteWindow] widget can access the [SatelliteWindowController]
/// via the [WindowScope] inherited widget.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
abstract class SatelliteWindowController extends BaseWindowController {
  /// Creates a [SatelliteWindowController] with the provided properties.
  ///
  /// Upon construction, the window is created by the platform with
  /// the given [preferredSize].
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
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
    SatelliteWindowControllerDelegate? delegate,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    if (preferredSize != null && preferredConstraints != null) {
      assert(preferredConstraints.isSatisfiedBy(preferredSize));
    }

    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    return owner.createSatelliteWindowController(
      delegate: delegate ?? SatelliteWindowControllerDelegate(),
      parent: parent,
      initialAnchorRect: initialAnchorRect,
      initialPositioner: initialPositioner,
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      title: title,
      resizable: true,
    );
  }

  /// Creates a [SatelliteWindowController] that sizes the window to its content.
  ///
  /// {@macro flutter.widgets.windowing.satelliteConstructorCommon}
  ///
  /// {@macro flutter.widgets.windowing.sizedToContentConstructor}
  ///
  /// To create a dialog with a specific size instead, use the default
  /// [SatelliteWindowController] constructor.
  ///
  /// {@macro flutter.widgets.windowing.shared}
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  factory SatelliteWindowController.sizedToContent({
    required BaseWindowController parent,
    required WindowPositioner initialPositioner,
    Rect? initialAnchorRect,
    bool resizable = false,
    BoxConstraints? preferredConstraints,
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
      preferredConstraints: preferredConstraints,
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
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
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
    required BoxConstraints preferredConstraints,
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
    required BoxConstraints preferredConstraints,
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
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
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
  RegularWindowController createRegularWindowController({
    required RegularWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    bool resizable = true,
    String? title,
  }) {
    throw UnsupportedError(errorMessage);
  }

  @override
  DialogWindowController createDialogWindowController({
    required DialogWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    bool resizable = true,
    BaseWindowController? parent,
    String? title,
  }) {
    throw UnsupportedError(errorMessage);
  }

  @override
  TooltipWindowController createTooltipWindowController({
    required TooltipWindowControllerDelegate delegate,
    required BoxConstraints preferredConstraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) {
    throw UnimplementedError(errorMessage);
  }

  @override
  PopupWindowController createPopupWindowController({
    required PopupWindowControllerDelegate delegate,
    required BoxConstraints preferredConstraints,
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
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    bool resizable = true,
    String? title,
  }) {
    throw UnimplementedError(errorMessage);
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
/// // TODO(mattkae): remove invalid_use_of_internal_member ignore comment when this API is stable.
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
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? widget) => WindowScope(
        controller: controller,
        child: View(view: controller.rootView, child: child),
      ),
    );
  }
}

/// The [DialogWindow] widget provides a way to render a dialog window in the
/// widget tree.
///
/// The provided [controller] creates the native window that backs
/// the widget. The [child] widget is rendered into this newly created window.
///
/// When a [DialogWindow] widget is removed from the tree, the window that was created
/// by the [controller] remains valid until the caller destroys it by calling
/// [DialogWindowController.destroy].
///
/// Widgets in the same tree as the [child] widget will have access to the
/// [DialogWindowController] via the [WindowScope] widget.
///
/// {@tool snippet}
/// An example usage might look like:
///
/// ```dart
/// // TODO(mattkae): remove invalid_use_of_internal_member ignore comment when this API is stable.
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
///       child: const MyApp()
///     )
///   );
/// }
///
/// class MyApp extends StatelessWidget {
///   const MyApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: DialogWindow(
///         controller: DialogWindowController(
///           preferredSize: const Size(400, 300),
///           parent: WindowScope.of(context),
///           title: 'Example Dialog'
///         ),
///         child: const Text('Hello, World!')
///       )
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
class DialogWindow extends StatelessWidget {
  /// Creates a dialog window widget.
  ///
  /// The [controller] creates the native backing window into which the
  /// [child] widget is rendered.
  ///
  /// It is up to the caller to destroy the window by calling
  /// [DialogWindowController.destroy] when the window is no longer needed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  DialogWindow({super.key, required this.controller, required this.child}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  /// Controller for this widget.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final DialogWindowController controller;

  /// The content rendered into this window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final Widget child;

  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? widget) => WindowScope(
        controller: controller,
        child: View(view: controller.rootView, child: child),
      ),
    );
  }
}

@internal
class TooltipWindow extends StatelessWidget {
  /// Creates a tooltip window widget.
  ///
  /// The [controller] creates the native backing window into which the
  /// [child] widget is rendered.
  ///
  /// It is up to the caller to destroy the window by calling
  /// [TooltipWindowController.destroy] when the window is no longer needed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  TooltipWindow({super.key, required this.controller, required this.child}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  /// Controller for this widget.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final TooltipWindowController controller;

  /// The content rendered into this window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final Widget child;

  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? widget) => WindowScope(
        controller: controller,
        child: View(view: controller.rootView, child: child),
      ),
    );
  }
}

/// The [PopupWindow] widget provides a way to render a popup window in the
/// widget tree.
///
/// The provided [controller] creates the native window that backs
/// the widget. The [child] widget is rendered into this newly created window.
///
/// When a [PopupWindow] widget is removed from the tree, the window that was created
/// by the [controller] remains valid until the caller destroys it by calling
/// [PopupWindowController.destroy].
///
/// Widgets in the same tree as the [child] widget will have access to the
/// [PopupWindowController] via the [WindowScope] widget.
///
/// {@tool snippet}
/// An example usage of [PopupWindow] looks like:
///
/// ** See code in examples/api/lib/widgets/windows/popup.0.dart **
/// {@end-tool}
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
/// * [PopupWindowController], the controller that creates and manages popup windows.
@internal
class PopupWindow extends StatelessWidget {
  /// Creates a popup window widget.
  ///
  /// The [controller] creates the native backing window into which the
  /// [child] widget is rendered.
  ///
  /// It is up to the caller to destroy the window by calling
  /// [PopupWindowController.destroy] when the window is no longer needed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  PopupWindow({super.key, required this.controller, required this.child}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  /// Controller for this widget.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  final PopupWindowController controller;

  /// The content rendered into this window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  final Widget child;

  /// {@macro flutter.widgets.windowing.experimental}
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? widget) => WindowScope(
        controller: controller,
        child: View(view: controller.rootView, child: child),
      ),
    );
  }
}

/// The [SatelliteWindow] widget provides a way to render a satellite window in the
/// widget tree.
///
/// The provided [controller] creates the native window that backs
/// the widget. The [child] widget is rendered into this newly created window.
///
/// When a [SatelliteWindow] widget is removed from the tree, the window that was created
/// by the [controller] remains valid until the caller destroys it by calling
/// [SatelliteWindowController.destroy].
///
/// Widgets in the same tree as the [child] widget will have access to the
/// [SatelliteWindowController] via the [WindowScope] widget.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
/// * [SatelliteWindowController], the controller that creates and manages satellite windows.
@internal
class SatelliteWindow extends StatelessWidget {
  /// Creates a satellite window widget.
  ///
  /// The [controller] creates the native backing window into which the
  /// [child] widget is rendered.
  ///
  /// It is up to the caller to destroy the window by calling
  /// [SatelliteWindowController.destroy] when the window is no longer needed.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  SatelliteWindow({super.key, required this.controller, required this.child}) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  /// Controller for this widget.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final SatelliteWindowController controller;

  /// The content rendered into this window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final Widget child;

  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? widget) => WindowScope(
        controller: controller,
        child: View(view: controller.rootView, child: child),
      ),
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
///  * [DialogWindow], the widget to create a dialog window.
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
  /// {@template flutter.widgets.windowing.WindowScope.of}
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
  /// * [RegularWindowController], the controller for regular top-level windows.
  /// * [DialogWindowController], the controller for dialog windows.
  /// * [RegularWindow], the widget for a regular window.
  /// * [DialogWindow], the widget for a dialog window.
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
  /// * [DialogWindowController], the controller for dialog windows.
  /// * [RegularWindow], the widget for a regular window.
  /// * [DialogWindow], the widget for a dialog window.
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
      DialogWindowController() => controller.title,
      TooltipWindowController() => '',
      PopupWindowController() => '',
      SatelliteWindowController() => controller.title,
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
      DialogWindowController() => controller.title,
      TooltipWindowController() => '',
      PopupWindowController() => '',
      SatelliteWindowController() => controller.title,
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
      DialogWindowController() => controller.isActivated,
      TooltipWindowController() => false,
      PopupWindowController() => controller.isActivated,
      SatelliteWindowController() => controller.isActivated,
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
      DialogWindowController() => controller.isActivated,
      TooltipWindowController() => false,
      PopupWindowController() => controller.isActivated,
      SatelliteWindowController() => controller.isActivated,
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
      DialogWindowController() => controller.isMinimized,
      TooltipWindowController() => false,
      PopupWindowController() => false,
      SatelliteWindowController() => false,
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
      DialogWindowController() => controller.isMinimized,
      TooltipWindowController() => false,
      PopupWindowController() => false,
      SatelliteWindowController() => false,
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
      DialogWindowController() => false,
      TooltipWindowController() => false,
      PopupWindowController() => false,
      SatelliteWindowController() => false,
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
      DialogWindowController() => false,
      TooltipWindowController() => false,
      PopupWindowController() => false,
      SatelliteWindowController() => false,
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
      DialogWindowController() => false,
      TooltipWindowController() => false,
      PopupWindowController() => false,
      SatelliteWindowController() => false,
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
      DialogWindowController() => false,
      TooltipWindowController() => false,
      PopupWindowController() => false,
      SatelliteWindowController() => false,
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
              final DialogWindowController dialog =>
                dialog.title != (oldWidget.controller as DialogWindowController).title,
              TooltipWindowController() => false,
              PopupWindowController() => false,
              final SatelliteWindowController satellite =>
                satellite.title != (oldWidget.controller as SatelliteWindowController).title,
            },
            _WindowControllerAspect.activated => switch (controller) {
              final RegularWindowController regular =>
                regular.isActivated !=
                    (oldWidget.controller as RegularWindowController).isActivated,
              final DialogWindowController dialog =>
                dialog.isActivated != (oldWidget.controller as DialogWindowController).isActivated,
              TooltipWindowController() => false,
              final PopupWindowController popup =>
                popup.isActivated != (oldWidget.controller as PopupWindowController).isActivated,
              final SatelliteWindowController satellite =>
                satellite.isActivated !=
                    (oldWidget.controller as SatelliteWindowController).isActivated,
            },
            _WindowControllerAspect.maximized => switch (controller) {
              final RegularWindowController regular =>
                regular.isMaximized !=
                    (oldWidget.controller as RegularWindowController).isMaximized,
              DialogWindowController() => false,
              TooltipWindowController() => false,
              PopupWindowController() => false,
              SatelliteWindowController() => false,
            },
            _WindowControllerAspect.minimized => switch (controller) {
              final RegularWindowController regular =>
                regular.isMinimized !=
                    (oldWidget.controller as RegularWindowController).isMinimized,
              final DialogWindowController dialog =>
                dialog.isMinimized != (oldWidget.controller as DialogWindowController).isMinimized,
              TooltipWindowController() => false,
              PopupWindowController() => false,
              SatelliteWindowController() => false,
            },
            _WindowControllerAspect.fullscreen => switch (controller) {
              final RegularWindowController regular =>
                regular.isFullscreen !=
                    (oldWidget.controller as RegularWindowController).isFullscreen,
              DialogWindowController() => false,
              TooltipWindowController() => false,
              PopupWindowController() => false,
              SatelliteWindowController() => false,
            },
          },
    );
  }
}

/// A registry used to render top-level windows.
///
/// The registry is often used to render top-level windows
/// that are logically nested under a widget deep in the tree.
///
/// The [WindowManager] provides a [WindowRegistry] to its descendents.
///
/// Descendents of the manager can use [WindowRegistry.maybeOf] to access the
/// registry. With the registry, they can call [WindowRegistry.register] to
/// add a new window to the registry and [WindowRegistry.unregister] to remove
/// a window from the registry.
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

  /// Registers a window.
  ///
  /// The [entry] parameter specifies the window to register.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void register(WindowEntry entry) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _windows.add(entry);
    notifyListeners();
  }

  /// Unregisters a window.
  ///
  /// The window must be unregistered before it is destroyed. Call
  /// [BaseWindowController.destroy] to destroy the window or listen
  /// to the onWindowCloseRequested method of the window's delegate.
  ///
  /// The [entry] parameter specifies the window to unregister.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void unregister(WindowEntry entry) {
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
  _WindowRegistryScope({required WindowRegistry registry, required super.child})
    : _registry = registry {
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

/// Represents an entry for a window such as a dialog.
///
/// This class holds the necessary information to build and manage
/// a window within the application.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowRegistry], where window entries can be registered.
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
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final WidgetBuilder builder;
}

/// The window manager provides a convenient way to render windows
/// at the root of an application.
///
/// Descendents of the [WindowManager] may access the [WindowRegistry] via
/// [WindowRegistry.maybeOf] in order to register new windows. [WindowManager]
/// listens on the [WindowRegistry] and renders the new windows using the
/// appropriate window widget as they are added or removed.
///
/// If windowing is not enabled, this widgets renders [child] directly
/// and does not provide the [WindowRegistry].
///
/// {@tool dartpad}
/// An example usage might look like this, where the window manager wraps
/// the root of the widget tree so that dialogs can be rendered at the same level
/// as a [RegularWindow].
///
/// ** See code in examples/api/lib/widgets/windows/window_manager.0.dart **
/// {@end-tool}
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowRegistry], where window entries can be registered.
@internal
class WindowManager extends StatefulWidget {
  /// Creates a window manager.
  ///
  /// The [child] is the content inside of the window manager.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  const WindowManager({super.key, required this.child});

  /// The child widget of the window manager.
  final Widget child;

  @override
  State<WindowManager> createState() => _WindowManagerState();
}

class _WindowManagerState extends State<WindowManager> {
  final WindowRegistry _registry = WindowRegistry();

  @override
  Widget build(BuildContext context) {
    if (!isWindowingEnabled) {
      return widget.child;
    }

    return _WindowRegistryScope(
      registry: _registry,
      child: ListenableBuilder(
        listenable: _registry,
        builder: (BuildContext context, Widget? child) {
          final List<Widget> subViews = _registry.windows.map((WindowEntry entry) {
            return switch (entry.controller) {
              final DialogWindowController dialog => DialogWindow(
                controller: dialog,
                child: entry.builder(context),
              ),
              final RegularWindowController regular => RegularWindow(
                controller: regular,
                child: entry.builder(context),
              ),
              final TooltipWindowController tooltip => TooltipWindow(
                controller: tooltip,
                child: entry.builder(context),
              ),
              final PopupWindowController popup => PopupWindow(
                controller: popup,
                child: entry.builder(context),
              ),
              final SatelliteWindowController satellite => SatelliteWindow(
                controller: satellite,
                child: entry.builder(context),
              ),
            };
          }).toList();

          final FlutterView? view = View.maybeOf(context);
          if (view == null) {
            return ViewCollection(views: subViews);
          }

          return ViewAnchor(
            view: subViews.isNotEmpty ? ViewCollection(views: subViews) : null,
            child: child!,
          );
        },
        child: widget.child,
      ),
    );
  }
}
