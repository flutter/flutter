// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../material/material_localizations.dart'
    show MaterialLocalizations;
import '../material/menu_anchor.dart'
    show LocalizedShortcutLabeler,
         MenuAcceleratorCallbackBinding,
         MenuAnchor,
         MenuController,
         MenuDirectionalFocusAction;
import 'app.dart';
import 'colors.dart';
import 'constants.dart';
import 'scrollbar.dart';
import 'theme.dart';

const Duration _kMenuPanReboundDuration = Duration(milliseconds: 600);
const bool _kDebugMenus = false;

// Enable if you want verbose logging about pan region changes.
const bool _kDebugPanRegion = false;

/// Whether [defaultTargetPlatform] is an Apple platform (Mac or iOS).
bool get _isApple {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return false;
  }
}

bool get _platformSupportsAccelerators {
  // On iOS and macOS, pressing the Option key (a.k.a. the Alt key) causes a
  // different set of characters to be generated, and the native menus don't
  // support accelerators anyhow, so we just disable accelerators on these
  // platforms.
  return !_isApple;
}

const Map<ShortcutActivator, Intent> _kMenuTraversalShortcuts =
    <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowUp):
      DirectionalFocusIntent(TraversalDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowDown):
      DirectionalFocusIntent(TraversalDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowLeft):
      DirectionalFocusIntent(TraversalDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight):
      DirectionalFocusIntent(TraversalDirection.right),
};


class _DismissMenuAction extends DismissAction {
  /// Creates a [_DismissMenuAction].
  _DismissMenuAction({required this.controller});

  /// The [MenuController] associated with the menus that should be closed.
  final CupertinoMenuController controller;

  @override
  void invoke(DismissIntent intent) {
    assert(_debugMenuInfo('$runtimeType: Dismissing all open menus.'));
    controller._anchor?._animateClosed();
  }

  @override
  bool isEnabled(DismissIntent intent) {
    return controller.menuStatus != MenuStatus.closed &&
           controller.menuStatus != MenuStatus.closing;
  }
}

/// Mix [CupertinoMenuEntryMixin] in to define how a menu item should be drawn
/// in a menu.
///
/// The [allowLeadingSeparator] and [allowTrailingSeparator] properties control
/// whether a separator can be drawn between menu items. In an adjacent pair of
/// menu items, a separator will only be drawn if the first item has
/// [allowTrailingSeparator] set to true and the second item has
/// [allowLeadingSeparator] set to true.
///
/// The [hasLeading] property describes whether this menu item has a leading
/// widget. If true, the siblings of this menu item that are missing a leading
/// widget will have leading space added. This will align the leading edges of
/// all menu items. Defaults to false.
mixin CupertinoMenuEntryMixin {
  /// Whether a separator can be drawn before this menu item.
  ///
  /// When [allowLeadingSeparator] is true, a separator will be drawn if the
  /// menu item immediately above this item has mixed in
  /// [CupertinoMenuEntryMixin] and has set [allowTrailingSeparator] to true.
  bool get allowLeadingSeparator => true;

  /// Whether a separator can be drawn after this menu item.
  ///
  /// When [allowTrailingSeparator] is true, a separator will be drawn if the
  /// menu item immediately below this item has mixed in
  /// [CupertinoMenuEntryMixin] and has set [allowLeadingSeparator] to true.
  bool get allowTrailingSeparator => true;

  /// Whether this menu item has a leading widget.
  ///
  /// If true, the siblings of this menu item that are missing a leading
  /// widget will have leading space added to align the leading edges of all
  /// menu items.
  bool get hasLeading => false;
}

/// The reveal status of a [CupertinoMenuAnchor].
enum MenuStatus {
  /// The menu is closed, and the menu animation has completed.
  closed,

  /// The menu is opening, and the menu animation is running forward.
  opening,

  /// The menu is open, and the menu animation has completed.
  opened,

  /// The menu is closing, and the menu animation is running in reverse.
  closing,
}

/// A controller to manage a menu created by a [CupertinoMenuAnchor].
///
/// A [CupertinoMenuController] is used to control and interrogate a menu after
/// it has been created, with methods such as [open] and [close], and state
/// accessors like [isOpen].
///
/// See also:
///
/// * [CupertinoMenuAnchor], a widget that displays a Cupertino-style menu when
///   pressed.
// [MenuController] is extended so that menu actions, such as
// [DismissMenuAction], can be used with this controller.
class CupertinoMenuController implements MenuController {
  /// The anchor that this controller controls.
  ///
  /// This is set automatically when a [CupertinoMenuController] is given to the
  /// anchor it controls.
  _CupertinoMenuAnchorState? _anchor;

  /// The [AnimationStatus] of the animation that reveals this controller's menu.
  MenuStatus get menuStatus => _anchor!._menuStatus;

  @override
  bool get isOpen => _anchor!._menuStatus != MenuStatus.closed;

  /// Close the menu that this menu controller is associated with.
  ///
  /// If the menu's anchor point (a [CupertinoMenuAnchor]) is
  /// scrolled by an ancestor, or the view changes size, then any open menu will
  /// automatically close.
  @override
  void close() {
    assert(_anchor != null, 'CupertinoMenuController is not attached to an anchor');
    _anchor!._animateClosed();
  }

  /// Open the menu that this controller is associated with.
  ///
  /// If `position` is given, then the menu will open at the position given, in
  /// the coordinate space of the [CupertinoMenuAnchor] this controller is
  /// attached to.
  ///
  /// The `position` will override the [CupertinoMenuAnchor.alignmentOffset]
  /// given to the [CupertinoMenuAnchor].
  ///
  /// If the menu's anchor point (the [CupertinoMenuAnchor]) is scrolled by an
  /// ancestor, or the view changes size, then any open menu will automatically
  /// close.
  @override
  void open({ui.Offset? position}) {
    assert(_anchor != null, 'CupertinoMenuController is not attached to an anchor');
    _anchor!._animateOpen(position: position);
  }

  // ignore: use_setters_to_change_properties
  void _attach(_CupertinoMenuAnchorState anchor) {
    _anchor = anchor;
  }

  void _detach(_CupertinoMenuAnchorState anchor) {
    if (_anchor == anchor) {
      _anchor = null;
    }
  }
}

class _AnchorScope extends InheritedWidget {
  const _AnchorScope({required this.state, required super.child});
  final _CupertinoMenuAnchorState state;

  @override
  bool updateShouldNotify(_AnchorScope oldWidget) {
    return state != oldWidget.state;
  }
}

/// A builder for the widget that this [CupertinoMenuAnchor] surrounds.
///
/// Typically, this is a button that opens the menu by calling
/// [CupertinoMenuAnchor.open] on the `controller` passed to the builder.
///
/// If a child is not supplied, then the [CupertinoMenuAnchor] will be the size
/// that its parent allocates for it.
typedef CupertinoMenuAnchorChildBuilder = Widget Function(
  BuildContext context,
  CupertinoMenuController controller,
  Widget? child,
);

/// The menu surface builder used by [CupertinoMenuAnchor].
///
/// - The [context] is the build context of the menu overlay.
/// - The [child] is the scrollable containing the [menuChildren].
/// - The [animation] is the animation that runs as the menu is opening or
///   closing.
/// - The [backgroundColor] is the color passed to
///   [CupertinoMenuAnchor.backgroundColor].
/// - The [clipBehavior] is the clip behavior passed to
///   [CupertinoMenuAnchor.clipBehavior].
typedef CupertinoMenuSurfaceBuilder = Widget Function(
  BuildContext context,
  Widget child,
  Animation<double> animation,
  Color backgroundColor,
  Clip clipBehavior,
);

/// A callback that is invoked when the [MenuStatus] changes.
typedef CupertinoMenuStatusChangedCallback = void Function(MenuStatus status);

/// A widget used to mark the "anchor" for a menu, defining the rectangle used
/// to position the menu, which can be done with an explicit location, or
/// with an alignment.
///
/// The [CupertinoMenuAnchor] is typically used to wrap a button that opens a
/// menu when pressed. The menu position is determined by the [alignment] of the
/// anchor attachment point and the [menuAlignment] of the menu attachment
/// point. The [alignmentOffset] can be used to adjust the position of the menu.
///
/// The [menuChildren] are the contents of the menu, and a [surfaceBuilder] can
/// be used to customize the appearance of the menu surface.
///
/// The [controller] can be used to open and close the menu from other widgets.
/// The [onOpen] callback is invoked when the menu popup is mounted and the menu
/// status changes **FROM** [MenuStatus.closed]. The [onClose] callback is
/// invoked when the menu popup is unmounted and the menu status changes **TO**
/// [MenuStatus.closed]. The [onStatusChanged] callback is invoked when the
/// status of the menu changes (see [MenuStatus]).
///
/// ## Usage
/// {@tool snippet}
///
/// This sample code shows a [CupertinoMenuItem] that prints `Item 1 pressed!`
/// when pressed.
///
/// ```dart
///  CupertinoMenuAnchor(
///    menuChildren: <Widget>[
///      CupertinoMenuItem(
///        child: const Text('Item 1'),
///        trailing: const Icon(Icons.add),
///        onPressed: () {
///          print('Item 1 pressed!');
///        },
///      )
///    ],
///    builder: (
///      BuildContext context,
///      CupertinoMenuController controller,
///      Widget? child,
///    ) {
///      return CupertinoButton.filled(
///        child: const Text('Open'),
///        onPressed: () {
///          if (controller.menuStatus
///              case MenuStatus.opening || MenuStatus.opened) {
///            controller.close();
///          } else {
///            controller.open();
///          }
///        },
///      );
///    },
///  );
/// ```
/// {@end-tool}
///
/// {@tool dartpad} This example shows a basic [CupertinoMenuAnchor] that wraps
/// a button.
///
/// ** See code in examples/api/lib/cupertino/menu_anchor/cupertino_menu_anchor.0.dart **
/// {@end-tool}
///
/// {@tool dartpad} This example shows how to use shortcuts with a
/// [CupertinoMenuAnchor] that wraps a button.
///
/// ** See code in examples/api/lib/cupertino/menu_anchor/cupertino_menu_anchor.1.dart **
/// {@end-tool}
///
/// {@tool dartpad} This example shows how to use a [CupertinoMenuAnchor] to
/// create a context menu in a region of the view, positioned where
/// the user clicks the mouse with Ctrl pressed.
///
/// ** See code in examples/api/lib/cupertino/menu_anchor/cupertino_menu_anchor.2.dart **
/// {@end-tool}
class CupertinoMenuAnchor extends StatefulWidget {
  /// Creates a [CupertinoMenuAnchor].
  const CupertinoMenuAnchor({
    super.key,
    required this.menuChildren,
    this.builder,
    this.child,
    this.controller,
    this.childFocusNode,
    this.onOpen,
    this.onClose,
    this.onStatusChanged,
    this.scrollPhysics,
    this.constraints,
    this.menuAlignment,
    this.alignment,
    this.alignmentOffset = Offset.zero,
    this.clipBehavior = Clip.hardEdge,
    this.enablePan = true,
    this.shrinkWrap = true,
    this.consumeOutsideTap = false,
    this.forwardSpring = defaultForwardSpring,
    this.reverseSpring = defaultReverseSpring,
    this.backgroundColor = defaultBackground,
    this.surfaceBuilder = defaultSurfaceBuilder,
    this.screenInsets = defaultScreenInsets,
  });

  /// An optional controller that allows opening and closing of the menu from
  /// other widgets.
  final CupertinoMenuController? controller;

  /// The [childFocusNode] attribute is the optional [FocusNode] also associated
  /// the [child] or [builder] widget that opens the menu.
  ///
  /// The focus node should be attached to the widget that should receive focus
  /// if keyboard focus traversal moves the focus off of the submenu with the
  /// arrow keys.
  ///
  /// If not supplied, then keyboard traversal from the menu back to the
  /// controlling button when the menu is open is disabled.
  final FocusNode? childFocusNode;

  /// The offset of the menu relative to the alignment origin determined by
  /// [alignment] and the ambient [Directionality].
  ///
  /// Use this for adjustments of the menu placement.
  ///
  /// Increasing [Offset.dy] values of [alignmentOffset] move the menu position
  /// down.
  ///
  /// If the [alignment] is not an [AlignmentDirectional], then increasing
  /// [Offset.dx] values of [alignmentOffset] move the menu position to the
  /// right.
  ///
  /// If the [alignment] is an [AlignmentDirectional], then in a
  /// [TextDirection.ltr] [Directionality], increasing [Offset.dx] values of
  /// [alignmentOffset] move the menu position to the right. In a
  /// [TextDirection.rtl] directionality, increasing [Offset.dx] values of
  /// [alignmentOffset] move the menu position to the left.
  ///
  /// Defaults to [Offset.zero].
  final Offset alignmentOffset;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// If [Clip.none] is used, the menu surface will occupy the entire
  /// screen. Using [Clip.antiAliasWithSaveLayer] will prevent the background
  /// blur from being applied to the menu surface.
  final Clip clipBehavior;

  /// Whether or not a tap event that closes the menu will be permitted to
  /// continue on to the gesture arena.
  ///
  /// If false, then tapping outside of a menu when the menu is open will both
  /// close the menu, and allow the tap to participate in the gesture arena. If
  /// true, then it will only close the menu, and the tap event will be
  /// consumed.
  ///
  /// Defaults to false.
  final bool consumeOutsideTap;

  /// A callback invoked when the menu popup is mounted and the menu status
  /// changes **FROM** [MenuStatus.closed].
  ///
  /// To listen for when the menu has finished opening or has changed from
  /// closing to opening, see [onStatusChanged].
  final VoidCallback? onOpen;

  /// A callback invoked when the menu popup is mounted and the menu status
  /// changes **TO** [MenuStatus.closed].
  ///
  /// This callback will only be called after the menu has completely closed.
  ///
  /// To listen for when the menu has begun closing or has changed from opening
  /// to closing, see [onStatusChanged].
  final VoidCallback? onClose;

  /// A callback that is invoked when the status of the menu changes. Unlike
  /// [onOpen] and [onClose], this callback is invoked for all status changes.
  final CupertinoMenuStatusChangedCallback? onStatusChanged;

  /// A list of children containing the menu items that are the contents of the
  /// menu surrounded by this [CupertinoMenuAnchor].
  ///
  /// {@macro flutter.material.MenuBar.shortcuts_note}
  final List<Widget> menuChildren;

  /// The widget that this [CupertinoMenuAnchor] surrounds.
  ///
  /// Typically this is a button used to open the menu by calling
  /// [CupertinoMenuController.open] on the `controller` passed to the builder.
  ///
  /// If not supplied, then the [CupertinoMenuAnchor] will be the size that its parent
  /// allocates for it.
  final CupertinoMenuAnchorChildBuilder? builder;

  /// The optional child to be passed to the [builder].
  ///
  /// Supply this child if there is a portion of the widget tree built in
  /// [builder] that doesn't depend on the `controller` or `context` supplied to
  /// the [builder]. It will be more efficient, since Flutter doesn't then need
  /// to rebuild this child when those change.
  final Widget? child;

  /// The [ScrollPhysics] applied to the menu's scrollable.
  ///
  /// If the menu's contents are smaller than its constraints, scrolling
  /// will be disabled regardless of the applied physics.
  /// If null, the physics will be determined by the nearest [ScrollConfiguration].
  /// Defaults to null.
  final ScrollPhysics? scrollPhysics;

  /// The [SpringDescription] used for the opening animation of the menu.
  final SpringDescription forwardSpring;

  /// The [SpringDescription] used for the closing animation of the menu.
  final SpringDescription reverseSpring;

  /// The constraints to apply to the menu scrollable.
  final BoxConstraints? constraints;

  /// The point on the anchor surface that attaches to the menu.
  ///
  /// If null, defaults to [Alignment.topCenter] when the anchor is above
  /// the center of the screen, and [Alignment.bottomCenter] when the anchor is
  /// below the center of the screen.
  final AlignmentGeometry? alignment;

  /// The point on the menu surface that attaches to the anchor.
  ///
  /// Defaults to [Alignment.topCenter] when the anchor is above the center of
  /// the screen, and [Alignment.bottomCenter] (the bottom of the menu surface)
  /// when the anchor is below the center of the screen.
  final AlignmentGeometry? menuAlignment;

  /// Whether or not panning is enabled on the menu.
  ///
  /// When panning is enabled, a [PanGestureRecognizer] is added around the menu
  /// anchor and menu items. The [PanGestureRecognizer] allows for users to
  /// press, move, and activate adjacent menu items in a single gesture. Panning
  /// also scales the menu panel when users drag their pointer away from the
  /// menu.
  ///
  /// Disabling panning can be useful if the menu pan effects interfere with
  /// another pan gesture, such as in the case of dragging a menu anchor around
  /// the screen.
  ///
  /// Defaults to true.
  final bool enablePan;

  /// The background color of the menu.
  ///
  /// If null, the menu will use [defaultBackground]. If the provided color is
  /// not opaque, the menu will apply a [ui.ColorFilter.matrix] and
  /// [ui.ImageFilter.blur] to the contents behind the menu using a
  /// [BackdropFilter] widget.
  final Color backgroundColor;

  /// Whether or not the menu scrollable should shrink-wrap its contents.
  ///
  /// If true, the menu will be sized to fit its contents. Otherwise, the menu
  /// surface will grow to fill either the total available vertical space, or
  /// the value of [constraints.maxHeight], whichever is smaller.
  ///
  /// If you are unsure of the total size of your menu items, keeping
  /// [shrinkWrap] set to true will prevent a menu surface that is larger than
  /// it's contents. However, if you are confident that the total size of your
  /// menu items will always **exceed** the [constraints.maxHeight] you provide,
  /// or the total height of the screen, setting [shrinkWrap] to false can
  /// improve performance by allowing the menu to be laid out in advance.
  ///
  /// Defaults to true.
  final bool shrinkWrap;

  /// The builder responsible for creating and animating the surface
  ///
  /// The default builder animates the size, color, clip behavior, and shadow of
  /// the menu surface.
  ///
  /// Defaults to [defaultSurfaceBuilder].
  final CupertinoMenuSurfaceBuilder surfaceBuilder;

  /// Screen insets to avoid when positioning the menu.
  final EdgeInsetsGeometry screenInsets;

  /// The [SpringDescription] used for the opening animation of a menu layer.
  static const SpringDescription defaultForwardSpring = SpringDescription(
    mass: 1,
    stiffness: 32.7 * math.pi * math.pi,
    damping: 9.25 * math.pi
  );

  /// The [SpringDescription] used for the closing animation of a menu layer.
  static const SpringDescription defaultReverseSpring = SpringDescription(
    mass: 1,
    stiffness: 64 * math.pi * math.pi,
    damping: 28.8 * math.pi
  );

  /// The default background color of the menu surface.
  //
  // Background colors are based on the following:
  //
  // Dark mode on white background => rgb(83, 83, 83)
  // Dark mode on black => rgb(31, 31, 31)
  // Light mode on black background => rgb(197,197,197)
  // Light mode on white => rgb(246, 246, 246)
  static const CupertinoDynamicColor defaultBackground =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(243, 243, 243, 0.775),
    darkColor: Color.fromRGBO(55, 55, 55, 0.735),
  );

  /// The default screen insets to avoid when positioning the menu.
  static const EdgeInsets defaultScreenInsets =  EdgeInsets.all(8);

  static _CupertinoMenuAnchorState? _maybeOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<_AnchorScope>()?.state;
  }

  /// The menu surface builder used by [CupertinoMenuAnchor].
  ///
  /// - The [context] is the build context of the menu overlay.
  /// - The [child] is the scrollable containing the [menuChildren].
  /// - The [animation] is the animation that runs as the menu is opening or
  ///   closing.
  /// - The [backgroundColor] is the color passed to
  ///   [CupertinoMenuAnchor.backgroundColor].
  /// - The [clipBehavior] is the clip behavior passed to
  ///   [CupertinoMenuAnchor.clipBehavior].
  static Widget defaultSurfaceBuilder(
    BuildContext context,
    Widget child,
    Animation<double> animation,
    Color backgroundColor,
    Clip clipBehavior,
  ) {
    return _MenuSurface(
      animation: animation,
      clipBehavior: clipBehavior,
      backgroundColor: backgroundColor,
      child: child,
    );
  }

  @override
  State<CupertinoMenuAnchor> createState() => _CupertinoMenuAnchorState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return menuChildren
        .map<DiagnosticsNode>((Widget child) => child.toDiagnosticsNode())
        .toList();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('consumeOutsideTap',value: consumeOutsideTap, ifTrue: 'AUTO-CLOSE'));
    properties.add(DiagnosticsProperty<FocusNode?>('focusNode', childFocusNode));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior));
    properties.add(DiagnosticsProperty<Offset?>('alignmentOffset', alignmentOffset));
    if (constraints != null) {
      properties.add(DiagnosticsProperty<BoxConstraints?>('constraints', constraints));
    }

    if (child != null) {
      properties.add(DiagnosticsProperty<String?>('child', child.toString()));
    }
  }
}
class _CupertinoMenuAnchorState extends State<CupertinoMenuAnchor>
    with TickerProviderStateMixin {
  static const Tolerance _springTolerance = Tolerance(velocity: 0.1, distance: 0.1);
  final GlobalKey _panelScrollableKey = GlobalKey(debugLabel: '$CupertinoMenuAnchor Scrollable Key');
  late final Animation<double> _scaleAnimation;
  late final AnimationController _panAnimationController;
  late final AnimationController _animationController;

  /// Whether any siblings of this menu item have a leading widget. If a sibling
  /// has a leading widget, this menu item will have leading space added to
  /// align the leading edges of all menu items.
  MenuStatus _menuStatus = MenuStatus.closed;
  ui.Rect _anchorRect = ui.Rect.zero;
  bool _hasLeadingWidget = false;
  final MenuController _innerMenuController = MenuController();
  CupertinoMenuController? _internalMenuController;
  CupertinoMenuController get _menuController => widget.controller
                                                  ?? _internalMenuController!;
  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalMenuController = CupertinoMenuController();
    }

    _menuController._attach(this);
    _animationController = AnimationController.unbounded(vsync: this);
    _panAnimationController = AnimationController.unbounded(value: 1, vsync: this);
    // The scale animation is a combination of the menu opening and pan
    // animations.
    _scaleAnimation = _AnimationProduct(
      first: _animationController,
      next: _panAnimationController,
    );
    _hasLeadingWidget = widget.menuChildren.any((Widget element) {
      if (element case CupertinoMenuEntryMixin(:final bool hasLeading)) {
        return hasLeading;
      } else {
        return false;
      }
    });
  }

  @override
  void didUpdateWidget(CupertinoMenuAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      if (widget.controller != null) {
        _internalMenuController?._detach(this);
        _internalMenuController = null;
      } else {
        assert(_internalMenuController == null);
        _internalMenuController = CupertinoMenuController();
      }
      _menuController._attach(this);
    }

    if (oldWidget.menuChildren != widget.menuChildren) {
      _hasLeadingWidget = widget.menuChildren.any((Widget element) {
        if (element case CupertinoMenuEntryMixin(:final bool hasLeading)) {
          return hasLeading;
        } else {
          return false;
        }
      });
    }

    assert(_menuController._anchor == this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _panAnimationController.dispose();
    _menuController._detach(this);
    _internalMenuController = null;
    super.dispose();
  }

  // Update the menu status and call listeners.
  void _changeMenuStatus(MenuStatus status) {
    if (status == _menuStatus) {
      return;
    }

    final MenuStatus previousStatus = _menuStatus;
    _menuStatus = status;

    // Cannot use postFrameCallback because focus won't return to the previous
    // focus node when the menu is closed.
    if (mounted && SchedulerBinding.instance.schedulerPhase !=
                   SchedulerPhase.persistentCallbacks) {
      setState(() { /* Mark dirty if mounted and not already building. */ });
    }

    if (previousStatus == MenuStatus.closed) {
      widget.onOpen?.call();
    }

    if (status == MenuStatus.closed) {
      widget.onClose?.call();
    }

    widget.onStatusChanged?.call(status);
  }

  // Sets the menu status to closed and sets the menu animation to 0.0. Does not
  // trigger the root menu to close the overlay.
  void _handleClosed() {
    _animationController.stop();
    _animationController.value = 0;
    _changeMenuStatus(MenuStatus.closed);
  }

  // Sets the menu status to opened and sets the menu animation to 1.0. Does not
  // trigger the root menu to open the overlay.
  void _handleOpened() {
    _animationController.stop();
    _animationController.value = 1;
    _changeMenuStatus(MenuStatus.opened);
  }

  // Animate the menu closed, then trigger the root menu to close the overlay.
  void _animateClosed() {
    if (_menuStatus case MenuStatus.closed || MenuStatus.closing) {
      assert(_debugMenuInfo('Blocked $_animateClosed because the menu is already closing'));
      return;
    }

    _animationController
      ..stop()
      ..animateWith(
        ClampedSimulation(
          SpringSimulation(
            widget.reverseSpring,
            _animationController.value,
            0.0,
            5.0,
            tolerance: _springTolerance,
          ),
          xMin: 0.0,
          xMax: 1.0,
        ),
      ).whenComplete(_innerMenuController.close);

    _changeMenuStatus(MenuStatus.closing);
  }

  void _animateOpen({ui.Offset? position}) {
    if (_menuStatus case MenuStatus.opened || MenuStatus.opening) {
      if (position != null) {
        _innerMenuController.open(position: position);
      }
      return;
    }

    if (!_innerMenuController.isOpen) {
      _innerMenuController.open(position: position);
    }

    _animationController
      ..stop()
      ..animateWith(SpringSimulation(
        widget.forwardSpring,
        _animationController.value,
        1.0,
        5.0,
      )).whenComplete(_handleOpened);

    _changeMenuStatus(MenuStatus.opening);

    // When the menu is first opened, set the first focus to the first item in
    // the menu.
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      final BuildContext? panelContext = _panelScrollableKey.currentContext;
      if (mounted && (panelContext?.mounted ?? false)) {
        FocusScope.of(context).setFirstFocus(
          FocusScope.of(panelContext!),
        );
      }
    });
  }

  // Scales the menu panel when the user drags their pointer away from the menu.
  void _handlePanUpdate(DragUpdateDetails update, {bool isInside = false}) {
    final BuildContext? panelContext = _panelScrollableKey.currentContext;
    if (!mounted || panelContext?.mounted != true) {
      return;
    }

    final RenderBox scrollable = panelContext!.findRenderObject()! as RenderBox;
    final RenderBox overlay = Overlay.of(panelContext)
                                .context
                                .findRenderObject()! as RenderBox;

    // Capture the area occupied by the menu panel and the anchor.
    ui.Rect rect = scrollable.localToGlobal(Offset.zero, ancestor: overlay)
                 & scrollable.size;
    rect = rect.expandToInclude(_anchorRect);

    if (_panAnimationController.isAnimating) {
      _panAnimationController.stop();
    }

    final Offset panPosition = update.globalPosition;
    if (rect.contains(panPosition)) {
      _panAnimationController.value = 1.0;
      return;
    }

    final double x = math.max(
      (panPosition.dx - rect.center.dx).abs() - rect.width / 2,
      0.0,
    );
    final double y = math.max(
      (panPosition.dy - rect.center.dy).abs() - rect.height / 2,
      0.0,
    );

    // Find the squared distance from the edge of the menu panel to the pointer.
    final double squaredDistance = x * x + y * y;

    assert(squaredDistance >= 0.0);

    // 60000 is a drag distance of ~245. At this distance, the menu scale
    // will be clamped to 0.7.
    final double value = math.min(squaredDistance / 60000, 1);
    _panAnimationController.value =
        1.0 - Curves.easeOutExpo.transform(value) * 0.3;
  }

  // Rebounds the menu panel scale to 1.0 when the user releases their pointer.
  void _handlePanEnd([DragEndDetails? details]) {
    _panAnimationController
      ..stop()
      ..animateTo(
        1.0,
        duration: _kMenuPanReboundDuration,
        curve: Curves.easeOutQuint,
      );
  }

  Widget _buildOverlay(
    BuildContext overlayContext,
    List<Widget> children,
    FocusScopeNode menuFocusScopeNode,
    Offset? menuPosition,
    Object? tapRegionGroupId,
  ) {
    final RenderBox anchor = context.findRenderObject()! as RenderBox;
    final RenderBox overlay = Overlay.of(overlayContext).context.findRenderObject()! as RenderBox;
    _anchorRect = anchor.localToGlobal(Offset.zero, ancestor: overlay) & anchor.size;
    if (menuPosition != null) {
      _anchorRect = (menuPosition + _anchorRect.topLeft) & Size.zero;
    }

    if (_menuStatus == MenuStatus.closed) {
      return const SizedBox.shrink();
    }

    return ExcludeFocus(
      excluding: _menuStatus == MenuStatus.closing ||
                 _menuStatus == MenuStatus.closed,
      child: _MenuPanel(
        context: overlayContext,
        animation: _animationController.view,
        menuController: _menuController,
        scaleAnimation: _scaleAnimation,
        onPanEnd: _handlePanEnd,
        onPanUpdate: _handlePanUpdate,
        enablePan: widget.enablePan,
        backgroundColor: widget.backgroundColor,
        shrinkWrap: widget.shrinkWrap,
        overlaySize: overlay.paintBounds.size,
        constraints: widget.constraints,
        anchorRect: _anchorRect,
        tapRegionGroupId: tapRegionGroupId,
        panelScrollableKey: _panelScrollableKey,
        consumeOutsideTaps: widget.consumeOutsideTap,
        clipBehavior: widget.clipBehavior,
        scrollPhysics: widget.scrollPhysics,
        menuScopeNode: menuFocusScopeNode,
        alignment: widget.alignment,
        alignmentOffset: widget.alignmentOffset,
        menuAlignment: widget.menuAlignment,
        surfaceBuilder: widget.surfaceBuilder,
        screenInsets: widget.screenInsets,
        children: children,
      ),
    );
  }

  Widget _buildAnchorChild(
    BuildContext context,
    MenuController controller,
    Widget? child,
  ) {
    final Widget anchorChild =
                  widget.builder?.call(context, _menuController, child)
                    ?? child
                    ?? const SizedBox.shrink();
    return widget.enablePan
        ? _PanRegion(
            groupId: _PanRegionRegistry.of(context),
            child: anchorChild,
          )
        : anchorChild;
  }

  @override
  Widget build(BuildContext context) {
    Widget scope = _AnchorScope(
      state: this,
      child: MenuAnchor.withOverlayBuilder(
        menuChildren: widget.menuChildren,
        overlayBuilder: _buildOverlay,
        builder: _buildAnchorChild,
        controller: _innerMenuController,
        childFocusNode: widget.childFocusNode,
        alignmentOffset: widget.alignmentOffset,
        consumeOutsideTap: widget.consumeOutsideTap,
        onClose: _handleClosed,
        onOpen: _animateOpen,
        child: widget.child,
      ),
    );

    if (widget.enablePan && CupertinoMenuAnchor._maybeOf(context) == null) {
      scope = _PanRegionSurface(child: scope);
    }

    return scope;
  }
}


class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.anchorRect,
    required this.context,
    required this.menuController,
    required this.animation,
    required this.menuScopeNode,
    required this.children,
    required this.panelScrollableKey,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.scaleAnimation,
    required this.overlaySize,
    required this.consumeOutsideTaps,
    required this.enablePan,
    required this.backgroundColor,
    required this.clipBehavior,
    required this.alignmentOffset,
    required this.surfaceBuilder,
    required this.shrinkWrap,
    required this.screenInsets,
    this.scrollPhysics,
    this.menuAlignment,
    this.alignment,
    this.constraints,
    this.tapRegionGroupId,
  });

  final Color backgroundColor;
  final bool enablePan;
  final BuildContext context;
  final bool consumeOutsideTaps;
  final CupertinoMenuController menuController;
  final ui.Rect anchorRect;
  final ui.Size overlaySize;
  final FocusScopeNode menuScopeNode;
  final Animation<double> animation;
  final List<Widget> children;
  final GlobalKey panelScrollableKey;
  final _PanRegionUpdateCallback onPanUpdate;
  final void Function([DragEndDetails? details]) onPanEnd;
  final ScrollPhysics? scrollPhysics;
  final BoxConstraints? constraints;
  final Clip clipBehavior;
  final ui.Offset alignmentOffset;
  final AlignmentGeometry? alignment;
  final AlignmentGeometry? menuAlignment;
  final Animation<double> scaleAnimation;
  final Object? tapRegionGroupId;
  final CupertinoMenuSurfaceBuilder surfaceBuilder;
  final bool shrinkWrap;
  final EdgeInsetsGeometry screenInsets;

  @override
  Widget build(BuildContext context) {
    Widget child = TapRegion(
      debugLabel: '$_MenuPanel Tap Region',
      groupId: tapRegionGroupId,
      consumeOutsideTaps: consumeOutsideTaps,
      onTapOutside: (PointerDownEvent event) {
        menuController._anchor!._animateClosed();
      },
      child: MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        child: Actions(
          actions: <Type, Action<Intent>>{
            DirectionalFocusIntent: MenuDirectionalFocusAction(),
            DismissIntent: _DismissMenuAction(controller: menuController),
          },
          child: FocusScope(
            debugLabel: '$_MenuPanel Focus Scope',
            node: menuScopeNode,
            skipTraversal: true,
            child: Shortcuts(
              shortcuts: _kMenuTraversalShortcuts,
              child: _MenuPanelScrollable(
                key: panelScrollableKey,
                shrinkWrap: shrinkWrap,
                physics: scrollPhysics,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );

    child = surfaceBuilder(
      context,
      child,
      animation,
      backgroundColor,
      clipBehavior
    );

    if (enablePan) {
      child = _PanRegion(
        groupId: _PanRegionRegistry.of(context),
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        onPanCancel: onPanEnd,
        child: child,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints.loose(overlaySize),
      child: _MenuPanelLayout(
        constraints: constraints,
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        menuAlignment: menuAlignment,
        anchorAlignment: alignment,
        anchorOffset: alignmentOffset,
        scaleAnimation: scaleAnimation,
        screenInsets: screenInsets.resolve(Directionality.of(context)),
        child: child,
      ),
    );
  }
}

class _MenuPanelLayout extends StatelessWidget {
  const _MenuPanelLayout({
    required this.child,
    required this.constraints,
    required this.menuAlignment,
    required this.overlaySize,
    required this.anchorRect,
    required this.scaleAnimation,
    required this.screenInsets,
    this.anchorAlignment,
    this.anchorOffset,
  });

  /// The menu items to display.
  final Widget child;

  /// The anchor rect relative to the menu overlay.
  final Rect anchorRect;

  /// The animation that drives the scaling.
  final Animation<double> scaleAnimation;

  /// The alignment of the menu attachment point relative to the anchor button.
  final Offset? anchorOffset;

  /// The [BoxConstraints] to apply to the menu.
  final BoxConstraints? constraints;

  /// The insets to avoid when positioning the menu.
  final EdgeInsetsGeometry screenInsets;

  /// The size of the overlay that the menu is displayed in.
  final Size overlaySize;

  /// The point on the anchor surface that should attach to
  /// the menu surface.
  final AlignmentGeometry? anchorAlignment;

  /// The point on the menu surface that should attach to
  /// the anchor surface.
  final AlignmentGeometry? menuAlignment;

  Offset _resolveOffset(TextDirection direction) {
    if (direction == TextDirection.rtl && anchorAlignment is AlignmentDirectional) {
      return Offset(-anchorOffset!.dx, anchorOffset!.dy);
    }

    return anchorOffset!;
  }

  @override
  Widget build(BuildContext context) {
    final ui.TextDirection textDirection = Directionality.of(context);
    final Offset resolvedAnchorOffset = _resolveOffset(textDirection);
    final Rect resolvedAnchorRect = anchorRect.shift(resolvedAnchorOffset);
    Alignment? resolvedAnchorAlignment = anchorAlignment?.resolve(textDirection);
    Alignment? resolvedMenuAlignment = menuAlignment?.resolve(textDirection);

    // The point on the menu surface that should appear to grow from. The growth
    // point will ignore any offset applied (in other words, anchorRect is used
    // instead of resolvedAnchorRect), so offset will not determine the
    // growth direction.
    final ui.Offset growthPoint = anchorRect.topLeft +
        (resolvedAnchorAlignment ?? Alignment.center).alongSize(anchorRect.size);

    // The alignment of the menu growth point relative to the screen. The
    // alignment has already been resolved for the text direction. This value is
    // used to determine the growth direction. If the menu anchor point is above
    // the center of the screen, the menu will grow downwards. Otherwise, it
    // will grow upwards.
    final Alignment menuToScreenAlignment = Alignment(
      (growthPoint.dx / overlaySize.width) * 2 - 1,
      (growthPoint.dy / overlaySize.height) * 2 - 1,
    );

    // The default alignment of the menu relative to the anchor point is 2.5%
    // above or below the anchor.
    resolvedMenuAlignment ??= menuToScreenAlignment.y > 0
                                ? const Alignment(0, 1.025)   // Grows up
                                : const Alignment(0, -1.025); // Grows down

    // The default alignment of the anchor attachment point relative to the menu.
    resolvedAnchorAlignment ??= menuToScreenAlignment.y > 0
                                  ? Alignment.topCenter       // Grows up
                                  : Alignment.bottomCenter;   // Grows down

    // More logic could be moved into the layout delegate, but it's here for now
    // to make menuToScreenAlignment easily accessible for ScaleTransition.
    return ScaleTransition(
      scale: scaleAnimation,
      alignment: menuToScreenAlignment,
      child: Builder(builder: (BuildContext context) {
        final MediaQueryData mediaQuery = MediaQuery.of(context);
        final double textScale = mediaQuery.textScaler.scale(1);
        final double width = textScale > 1.25 ? 350.0 : 250.0;
        final BoxConstraints resolvedConstraints = BoxConstraints(
          minWidth: constraints?.minWidth ?? width,
          maxWidth: constraints?.maxWidth ?? width,
          minHeight: constraints?.minHeight ?? 0.0,
          maxHeight: constraints?.maxHeight ?? double.infinity,
        );

        return CustomSingleChildLayout(
          delegate: _MenuLayout(
            anchorAlignment: resolvedAnchorAlignment!,
            menuAlignment: resolvedMenuAlignment!,
            anchorPosition: RelativeRect.fromSize(
              resolvedAnchorRect,
              overlaySize,
            ),
            edgeInsets: screenInsets.resolve(textDirection),
            avoidBounds: DisplayFeatureSubScreen.avoidBounds(mediaQuery).toSet(),
          ),
          child: ConstrainedBox(
            constraints: resolvedConstraints,
            child: child,
          ),
        );
      }),
    );
  }
}

// The default background of the menu.
class _MenuSurface extends StatelessWidget {
  const _MenuSurface({
    required this.child,
    required this.animation,
    required this.backgroundColor,
    required this.clipBehavior,
  });

  final Widget child;
  final Animation<double> animation;
  final Clip clipBehavior;
  final Color backgroundColor;

  static const BorderRadius defaultBorderRadius = BorderRadius.all(Radius.circular(14));
  static final DecorationTween _decorationTween = DecorationTween(
    begin: const BoxDecoration(
        borderRadius: defaultBorderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0),
          ),
        ]),
    end: const BoxDecoration(
        borderRadius: defaultBorderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            spreadRadius: 30,
            blurRadius: 50,
          ),
        ]),
  );

  //  SizeTransition is not used here because it uses ClipRect rather than
  //  ClipRRect.
  Align _alignTransitionBuilder(BuildContext context, Widget? child) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: animation.value,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBoxTransition(
      decoration: _decorationTween.animate(animation),
      child: ClipRRect(
        clipBehavior: clipBehavior,
        borderRadius: defaultBorderRadius,
        child: AnimatedBuilder(
          animation: animation,
          builder: _alignTransitionBuilder,
          child: _AnimatedSurfaceVibrance(
            surfaceColor: backgroundColor,
            listenable: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// Animates the vibrance, blur, and background of the menu panel.
class _AnimatedSurfaceVibrance extends AnimatedWidget {
  const _AnimatedSurfaceVibrance({
    required Animation<double> listenable,
    required this.surfaceColor,
    required this.child,
  }) : super(listenable: listenable);

  static const Interval _surfaceDelay = Interval(0.55, 1.0);
  final Widget child;
  final Color surfaceColor;
  double get value =>
      ui.clampDouble((super.listenable as Animation<double>).value, 0.0, 1.0);
  static const double darkLumR = 0.45;
  static const double darkLumG = 0.8;
  static const double darkLumB = 0.16;
  static const double lightLumR = 0.26;
  static const double lightLumG = 0.4;
  static const double lightLumB = 0.17;

  /// A [ColorFilter.matrix] that saturates and brightens.
  ///
  /// From https://docs.rainmeter.net/tips/colormatrix-guide/, but tuned
  /// to resemble the iOS 17 menu. Luminance values were altered to emphasize
  /// blues and greens.
  List<double> buildColorFilterMatrix({
    required double strength,
    required Brightness brightness,
  }) {
    double additive, saturation, lumR, lumG, lumB;
    if (brightness == Brightness.light) {
      saturation = strength * 1 + 1;
      additive = 0.0;
      lumR = lightLumR;
      lumG = lightLumG;
      lumB = lightLumB;
    } else {
      saturation = strength * 0.7 + 1;
      additive = 0.3;
      lumR = darkLumR;
      lumG = darkLumG;
      lumB = darkLumB;
    }
    final double sr = (1 - saturation) * lumR;
    final double sg = (1 - saturation) * lumG;
    final double sb = (1 - saturation) * lumB;
    return <double>[
      sr + saturation, sg             , sb             , 0.0, additive,
      sr             , sg + saturation, sb             , 0.0, additive,
      sr             , sg             , sb + saturation, 0.0, additive,
      0.0            , 0.0            , 0.0            , 1.0, 0.0     ,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ui.Color resolved = CupertinoDynamicColor.maybeResolve(surfaceColor, context)
                                ?? surfaceColor;
    final ui.Color color = resolved.withOpacity(resolved.opacity * value);
    final double delayedValue = _surfaceDelay.transform(value);
    Widget surface = CustomPaint(
      willChange: value != 0 && value != 1,
      painter: _UnclippedColorPainter(color: color),
      child: child,
    );

    // If the color is not opaque, apply a blur filter to the surface.
    if (color.alpha != 0xFF) {
      ui.ImageFilter filter = ui.ImageFilter.blur(
        sigmaX: 30 * delayedValue,
        sigmaY: 30 * delayedValue,
      );

      if (!kIsWeb) {
        filter = ui.ImageFilter.compose(
          outer: filter,
          inner: ui.ColorFilter.matrix(
            buildColorFilterMatrix(
              strength: delayedValue,
              brightness: CupertinoTheme.maybeBrightnessOf(context) ?? Brightness.light,
            ),
          ),
        );
      }

      surface = BackdropFilter(
        blendMode: BlendMode.src,
        filter: filter,
        child: surface,
      );
    }

    return surface;
  }
}

// A custom painter that paints a color without clipping.
//
// Used to fill the background color of the menu even when the menu size animation
// surpasses a heightFactor of 1.0.
class _UnclippedColorPainter extends CustomPainter {
  const _UnclippedColorPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(
      color,
      BlendMode.srcOver,
    );
  }

  @override
  bool shouldRepaint(_UnclippedColorPainter oldDelegate) {
    return oldDelegate.color != color;
  }

  @override
  String toString() => '_UnclippedColorPainter($color)';
}

class _MenuPanelScrollable extends StatefulWidget {
  const _MenuPanelScrollable({
    super.key,
    required this.children,
    this.physics,
    this.shrinkWrap = true,
  });

  final List<Widget> children;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  State<_MenuPanelScrollable> createState() => _MenuPanelScrollableState();
}

class _MenuPanelScrollableState extends State<_MenuPanelScrollable> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget? _buildChild(BuildContext context, int index) {
    final Widget child = widget.children[index];
    if (child == widget.children.last) {
      return child;
    }

    if (child case CupertinoMenuEntryMixin(allowTrailingSeparator: false)) {
      return child;
    }

    if (widget.children[index + 1]
        case CupertinoMenuEntryMixin(allowLeadingSeparator: false)) {
      return child;
    }

    return _CupertinoMenuDivider.wrapBottom(child: child);
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _UniversalCupertinoScrollBehavior(),
      child: PrimaryScrollController(
        controller: _controller,
        // A CustomScrollView is used to accommodate a header widget in
        // a future PR.
        child: CustomScrollView(
          clipBehavior: Clip.none,
          controller: _controller,
          physics: widget.physics,
          shrinkWrap: widget.shrinkWrap,
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                _buildChild,
                childCount: widget.children.length,
              ),
            )
          ],
        ),
      ),
    );
  }
}


/// This class applies [CupertinoScrollbar] to all platforms. Otherwise,
/// [CupertinoScrollBehavior] only applies [CupertinoScrollbar] to desktop
/// platforms.
class _UniversalCupertinoScrollBehavior extends CupertinoScrollBehavior {
  /// Creates a [CupertinoScrollBehavior] that applies [CupertinoScrollbar] to
  /// all platforms.
  const _UniversalCupertinoScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    assert(details.controller != null);
    switch (getPlatform(context)) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        // The native MacOS menu doesn't have a scrollbar, so a thicker iOS
        // scrollbar is used for desktop platforms.
        return CupertinoScrollbar(
          thickness: 6.0,
          radius: const Radius.circular(3.0),
          controller: details.controller,
          thumbVisibility: false,
          child: child,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return CupertinoScrollbar(
          controller: details.controller,
          thumbVisibility: false,
          child: child,
        );
    }
  }
}

/// Multiplies the values of two animations.
///
/// This class is used to animate the scale of the menu when the user drags
/// outside of the menu area.
class _AnimationProduct extends CompoundAnimation<double> {
  _AnimationProduct({
    required super.first,
    required super.next,
  });

  @override
  double get value => super.first.value * super.next.value;
}

// A layout delegate that positions the menu relative to its anchor.
class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout({
    required this.anchorPosition,
    required this.edgeInsets,
    required this.avoidBounds,
    required this.anchorAlignment,
    required this.menuAlignment,
  });

  // The position of underlying anchor that the menu is attached to.
  final RelativeRect anchorPosition;

  // Padding obtained from calling [MediaQuery.paddingOf(context)].
  //
  // Used to prevent the menu from being obstructed by system UI.
  final EdgeInsets edgeInsets;

  // List of rectangles that the menu should not overlap. Unusable screen area.
  final Set<Rect> avoidBounds;

  // The alignment of the menu attachment point relative to the anchor button.
  final Alignment anchorAlignment;

  // The alignment of the menu attachment point relative to the menu surface.
  final Alignment menuAlignment;

  // Finds the closest screen to the anchor position.
  //
  // The closest screen is defined as the screen whose center is closest to the
  // anchor position.
  Rect _findClosestScreen(Size size, Offset point, Set<Rect> avoidBounds) {
    final Iterable<ui.Rect> screens =
        DisplayFeatureSubScreen.subScreensInBounds(
          Offset.zero & size,
          avoidBounds,
        );

    Rect closest = screens.first;
    for (final ui.Rect screen in screens) {
      if ((screen.center - point).distance <
          (closest.center - point).distance) {
        closest = screen;
      }
    }

    return closest;
  }

  // Fits the menu inside the screen, and returns the new position of the menu.
  Offset _fitInsideScreen(
    Rect screen,
    Size childSize,
    Offset wantedPosition,
    EdgeInsets screenPadding,
  ) {
    double x = wantedPosition.dx;
    double y = wantedPosition.dy;
    // Avoid going outside an area defined as the rectangle 8.0 pixels from the
    // edge of the screen in every direction.
    if (x < screen.left + screenPadding.left) {
      // Desired X would overflow left, so we set X to left screen edge
      x = screen.left + screenPadding.left;
    } else if (x + childSize.width > screen.right - screenPadding.right) {
      // Overflows right
      x = screen.right - childSize.width - screenPadding.right;
    }

    if (y < screen.top + screenPadding.top) {
      // Overflows top
      y = screenPadding.top;
    }

    // Overflows bottom
    if (y + childSize.height > screen.bottom - screenPadding.bottom) {
      y = screen.bottom - childSize.height - screenPadding.bottom;

      // If the menu is too tall to fit on the screen, then move it into frame
      if (y < screen.top) {
        y = screen.top + screenPadding.top;
      }
    }

    return Offset(x, y);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay minus totalPadding.
    return BoxConstraints.loose(constraints.biggest).deflate(edgeInsets);
  }

  @override
  Offset getPositionForChild(
    Size size,
    Size childSize,
  ) {
    final Rect anchorRect = anchorPosition.toRect(Offset.zero & size);
    final Offset resolvedOffset =
      anchorAlignment.withinRect(anchorRect) - menuAlignment.alongSize(childSize);

    final Rect screen = _findClosestScreen(
      size,
      anchorRect.center,
      avoidBounds,
    );

    final Offset position = _fitInsideScreen(
      screen,
      childSize,
      resolvedOffset,
      edgeInsets,
    );

    return position;
  }

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) {
    return edgeInsets      != oldDelegate.edgeInsets      ||
           anchorPosition  != oldDelegate.anchorPosition  ||
           anchorAlignment != oldDelegate.anchorAlignment ||
           menuAlignment   != oldDelegate.menuAlignment   ||
           !setEquals(avoidBounds, oldDelegate.avoidBounds);
  }
}

/// A button for use in a [CupertinoMenuAnchor] or on its own, that can be
/// activated by click or keyboard navigation.
///
/// {@tool snippet}
///
/// This sample code shows a [CupertinoMenuItem] that prints `Item 1 pressed!`
/// when pressed.
///
/// ```dart
///  CupertinoMenuAnchor(
///    menuChildren: <Widget>[
///      CupertinoMenuItem(
///        child: const Text('Item 1'),
///        trailing: const Icon(Icons.add),
///        onPressed: () {
///          print('Item 1 pressed!');
///        },
///      )
///    ],
///    builder: (
///      BuildContext context,
///      CupertinoMenuController controller,
///      Widget? child,
///    ) {
///      return CupertinoButton.filled(
///        child: const Text('Open'),
///        onPressed: () {
///          if (controller.menuStatus
///              case MenuStatus.opening || MenuStatus.opened) {
///            controller.close();
///          } else {
///            controller.open();
///          }
///        },
///      );
///    },
///  );
/// ```
/// {@end-tool}
///
/// ## Layout
/// The menu item is unconstrained by default and will grow to fit the size of
/// its container. To constrain the size of a [CupertinoMenuItem], the
/// [constraints] parameter can be set. Constraints are applied **after**
/// [padding]. This means that padding will only affect the size of this menu
/// item if this item's minimum constraints are less than the sum of its
/// [padding] and the size of its contents.
///
/// The [leading] and [trailing] widgets will display before and after the
/// [child] widget, respectively. The [leadingWidth] and [trailingWidth]
/// parameters control the horizontal space that these widgets occupy. The
/// [leadingAlignment] and [trailingAlignment] parameters control the alignment
/// of the leading and trailing widgets within their respective spaces.
///
///
/// ## Input
/// In order to respond to user input, an [onPressed] callback must be provided.
/// If absent, the [enabled] property will be false and user input callbacks
/// ([onFocusChange], [onHover], and [onPressed]) will be ignored. The
/// [behavior] parameter can be used to control whether hit tests can travel
/// behind the menu item, and the [mouseCursor] parameter can be used to change
/// the cursor that appears when the user hovers over the menu.
///
/// The [requestCloseOnActivate] parameter can be set to false to prevent the
/// menu from closing when the item is activated. By default, the menu will
/// close when the item is pressed.
///
/// The [requestFocusOnHover] parameter, when true, focuses the menu item when
/// the item is hovered.
///
/// The [panActivationDelay] parameter can be provided to activate the menu item
/// after a delay when the user pans over the menu item. By default, the menu
/// item will not activate when panned over.
///
///
/// ## Visuals
/// The [hoveredColor], [focusedColor], and [pressedColor] parameters can be
/// used to change the background color of the menu item when hovered, focused,
/// or pressed/panned. If these parameters are not set, the menu item will use
/// the [defaultPressedColor] at `5%`, `7.5%`, and default opacity,
/// respectively.
///
/// The [isDefaultAction] should be set to true if the menu item is the
/// suggested menu item for a given context. If true, this will bold the text of
/// the menu item.
///
/// The [isDestructiveAction] parameter should be set to true if the menu item
/// will perform a destructive action, and will color the text of the menu item
/// [CupertinoColors.systemRed].
///
///
/// ## Shortcuts
/// {@macro flutter.material.MenuBar.shortcuts_note}
///
///
/// ```dart
///
///// Example (Padding ignored)
///
///              Left-to-right Menu Item
///Leading                            Trailing
///Alignment(-0.2, -0.2)              Alignment(0.6, 0.8)
///   ┌────|────────┬───────────────┬────────|────┐
///   │    |        │               │        |    │
///   │    ▼        │    Child      │        |    │
///   │---►Leading  │               │        |    │
///   │             ├───────────────┤        |    │
///   │             │               │        ▼    │
///   │             │   Subtitle    │------►Trail-│
///   │             │               │       ing   │
///   |─────────────|───────────────|─────────────|
///   ▲   Leading   ▲               ▲   Trailing  ▲
///        width                         width
///
///
///
///              Right-to-left Menu Item
///
///    Trailing                      Leading
///    Alignment(0.6, 0.8)           Alignment(-0.4, -0.2)
///   ┌────────|────┬───────────────┬────|────────┐
///   │        |    │               │    |        │
///   │        |    │    Child      │    ▼        │
///   │        |    │               │---►Leading  │
///   │        |    ├───────────────┤             │
///   │        ▼    │               │             │
///   │------►Trail-│   Subtitle    │             │
///   │       ing   │               │             │
///   |─────────────|───────────────|─────────────|
///   ▲   Trailing  ▲               ▲   Leading   ▲
///        width                         width
///```
/// See also:
/// * [CupertinoMenuAnchor], a Cupertino-style widget that shows a menu of
///   actions in a popup
/// * [MenuAnchor], a widget that creates a region with a submenu and shows it
///   when requested.
/// * [MenuItemButton], a menu item with a Material Design style.
/// * [PlatformMenuBar], which creates a menu bar that is rendered by the host
///   platform instead of by Flutter (on macOS, for example).
/// * [ShortcutRegistry], a registry of shortcuts that apply for the entire
///   application.
/// * [VoidCallbackIntent], to define intents that will call a [VoidCallback]
///   and work with the [Actions] and [Shortcuts] system.
/// * [CallbackShortcuts] to define shortcuts that call a callback without
///   involving [Actions].
class CupertinoMenuItem extends StatelessWidget with CupertinoMenuEntryMixin {
  /// Creates a [CupertinoMenuItem]
  ///
  /// The [child] parameter is required and must not be null.
  const CupertinoMenuItem({
    super.key,
    required this.child,
    this.subtitle,
    this.leading,
    this.leadingWidth,
    this.leadingAlignment,
    this.trailing,
    this.trailingWidth,
    this.trailingAlignment,
    this.padding,
    this.constraints,
    this.focusNode,
    this.onHover,
    this.onFocusChange,
    this.onPressed,
    this.hoveredColor,
    this.focusedColor,
    this.pressedColor,
    this.mouseCursor,
    this.panActivationDelay,
    this.shortcut,
    this.behavior = HitTestBehavior.opaque,
    this.applyInsetScaling = true,
    this.requestCloseOnActivate = true,
    this.requestFocusOnHover = false,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
  });

  /// The widget displayed in the center of this button.
  ///
  /// Typically this is the button's label, using a [Text] widget.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The padding applied to this menu item.
  final EdgeInsetsGeometry? padding;

  /// The widget shown before the label; typically a [CupertinoIcon].
  final Widget? leading;

  /// The widget shown after the label; typically a [CupertinoIcon].
  final Widget? trailing;

  /// A widget displayed underneath the [child]; typically a [Text] widget.
  ///
  /// If overriding the default [TextStyle.color] of the [subtitle] widget,
  /// [CupertinoDynamicColor.resolve] should be used to resolve the color
  /// against the ambient [CupertinoTheme] and [TextStyle.inherit] should be set
  /// to false.
  final Widget? subtitle;

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If a callback is not provided, then the button will be disabled.
  final VoidCallback? onPressed;

  /// Called when a pointer enters or exits the button response area.
  ///
  /// The value passed to the callback is true if a pointer has entered the
  /// button area and false if a pointer has exited.
  final ValueChanged<bool>? onHover;

  /// Called when the menu item gains or loses focus.
  ///
  /// The value parameter is true when the widget's [FocusNode] gains focus, and
  /// false when it loses focus.
  final ValueChanged<bool>? onFocusChange;

  /// Whether hovering should request focus for this widget.
  ///
  /// Defaults to false.
  final bool requestFocusOnHover;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// The delay between a user's pointer entering a menu item during a pan, and
  /// the menu item being tapped.
  ///
  /// Defaults to null, meaning the menu item will not activate when panned
  /// over.
  final Duration? panActivationDelay;

  /// The color of menu item while the menu item is panned or pressed.
  ///
  /// If null, the [pressedColor] will be applied.
  final Color? pressedColor;

  /// The color of menu item while focused.
  ///
  /// If null, [pressedColor] will be applied at 7.5% opacity.
  final Color? focusedColor;

  /// The color of menu item while hovered.
  ///
  /// If null, [pressedColor] will be applied at 5% opacity.
  final Color? hoveredColor;

  /// The mouse cursor to display on hover.
  final MouseCursor? mouseCursor;

  /// How the menu item should respond to hit tests.
  final HitTestBehavior behavior;

  /// Determines if the menu will be closed when a [MenuItemButton] is pressed.
  /// Defaults to true.
  final bool requestCloseOnActivate;

  /// Whether pressing this item will perform a destructive action
  ///
  /// Defaults to false. If true, [CupertinoColors.systemRed] will be
  /// applied to this items label and icon.
  final bool isDestructiveAction;

  /// Whether pressing this item performs the suggested or most commonly used action.
  ///
  /// Defaults to false. If true, [FontWeight.w600] will be
  /// applied to this items label.
  final bool isDefaultAction;

  /// The horizontal space in which the [leading] widget can be placed.
  final double? leadingWidth;

  /// The horizontal space in which the [trailing] widget can be placed.
  final double? trailingWidth;

  /// The alignment of the leading widget within the [leadingWidth] of the menu
  /// item.
  final AlignmentGeometry? leadingAlignment;

  /// The alignment of the trailing widget within the [trailingWidth] of the
  /// menu item.
  final AlignmentGeometry? trailingAlignment;

  /// Whether the insets of the menu item should scale proportional to
  /// [MediaQuery.textScalerOf].
  ///
  /// Defaults to true.
  final bool applyInsetScaling;

  /// The optional shortcut that selects this [CupertinoMenuItem].
  ///
  /// {@macro flutter.material.MenuBar.shortcuts_note}
  final MenuSerializableShortcut? shortcut;

  /// Whether the menu item will respond to user input.
  bool get enabled => onPressed != null;

  @override
  bool get hasLeading => leading != null;

  /// The constraints to apply to the menu item.
  ///
  /// Because padding is applied to the menu item prior to constraints, padding
  /// will only affect the size of the menu item if the height of the padding
  /// plus the height of the menu item's children exceeds the
  /// [BoxConstraints.minHeight].
  final BoxConstraints? constraints;

  /// The default [TextStyle] applied to the [child] widget.
  static const TextStyle defaultTitleStyle = TextStyle(
    height: 1.25,
    fontFamily: 'SF Pro Text',
    fontFamilyFallback: <String>['.AppleSystemUIFont'],
    fontSize: 17,
    letterSpacing: -0.41,
    textBaseline: TextBaseline.ideographic,
    overflow: TextOverflow.ellipsis,
    color: CupertinoDynamicColor.withBrightness(
               color:     Color.fromRGBO(0, 0, 0, 0.96),
               darkColor: Color.fromRGBO(255, 255, 255, 0.96),
             ),
  );

  /// The default [TextStyle] applied to the [subtitle] widget.
  static const TextStyle defaultSubtitleStyle = TextStyle(
    height: 1.25,
    fontFamily: 'SF Pro Text',
    fontFamilyFallback: <String>['.AppleSystemUIFont'],
    fontSize: 15,
    letterSpacing: -0.21,
    textBaseline: TextBaseline.ideographic,
    overflow: TextOverflow.ellipsis,
    color: CupertinoDynamicColor.withBrightnessAndContrast(
      color: Color.fromRGBO(0, 0, 0, 0.4),
      darkColor: Color.fromRGBO(255, 255, 255, 0.4),
      highContrastColor: Color.fromRGBO(0, 0, 0, 0.8),
      darkHighContrastColor: Color.fromRGBO(255, 255, 255, 0.8),
    ),
  );

  /// The color of a [CupertinoMenuItem] when pressed.
  // Pressed colors were sampled from the iOS simulator and are based on the
  // following:
  //
  // Dark mode on white background     rgb(111, 111, 111)
  // Dark mode on black                rgb(61, 61, 61)
  // Light mode on black               rgb(177, 177, 177)
  // Light mode on white               rgb(225, 225, 225)
  static const CupertinoDynamicColor defaultPressedColor =
      CupertinoDynamicColor.withBrightnessAndContrast(
          color: Color.fromRGBO(50, 50, 50, 0.1),
          darkColor: Color.fromRGBO(255, 255, 255, 0.1),
          highContrastColor: Color.fromRGBO(50, 50, 50, 0.2),
          darkHighContrastColor: Color.fromRGBO(255, 255, 255, 0.2),
        );

  /// Resolves the title [TextStyle] in response to [CupertinoThemeData.brightness],
  ///  [isDefaultAction], [isDestructiveAction], and [enabled].
  //
  // Eyeballed from the iOS simulator.
  TextStyle _resolveTitleStyle(BuildContext context) {
    final Color color;
    if (!enabled) {
      color = CupertinoColors.systemGrey;
    } else if (isDestructiveAction) {
      color = CupertinoColors.systemRed;
    } else {
      color = defaultTitleStyle.color!;
    }

    return defaultTitleStyle.copyWith(
      color: CupertinoDynamicColor.maybeResolve(color, context) ?? color,
      fontWeight: isDefaultAction ? FontWeight.w600 : FontWeight.normal,
    );
  }

  /// Handles user selection of the menu item.
  ///
  /// To prevent redundant presses, selection is blocked if the menu has already
  /// started closing.
  ///
  /// If [requestCloseOnActivate] is true, this method is responsible for notifying the
  /// [CupertinoMenuAnchor] that the menu should begin closing.
  void _handleSelect(BuildContext context) {
    final _CupertinoMenuAnchorState? anchor = CupertinoMenuAnchor._maybeOf(context);

    // Block selection if the menu is already closing.
    if (anchor?._menuStatus case MenuStatus.closing) {
      assert(_debugMenuInfo('Blocked $child selection because menu is closing'));
      return;
    }

    assert(_debugMenuInfo('Selected $child menu'));
    if (requestCloseOnActivate) {
      anchor?._animateClosed();
    }

    // Delay the call to onPressed until post-frame so that the focus is
    // restored to what it was before the menu was opened before the action is
    // executed.
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      FocusManager.instance.applyFocusChangesIfNeeded();
      onPressed?.call();
    }, debugLabel: '$CupertinoMenuItem.onPressed');
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle titleTextStyle = _resolveTitleStyle(context);
    final double textScale =
        (MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling).scale(1);
    TextStyle? blendedSubtitleStyle;
    if (subtitle != null || shortcut != null) {
      final bool isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
      blendedSubtitleStyle = defaultSubtitleStyle.copyWith(
        foreground: Paint()
          ..blendMode = isDark ? BlendMode.plus : BlendMode.hardLight
          ..color     = CupertinoDynamicColor.maybeResolve(
                        defaultSubtitleStyle.color,
                          context,
                        )
                        ?? defaultSubtitleStyle.color!,
      );
    }

    Widget label = _CupertinoMenuItemLabel(
      padding: padding,
      constraints: constraints,
      trailing: textScale <= 1.25 ? trailing : null,
      leading: leading,
      leadingAlignment: leadingAlignment,
      trailingAlignment: trailingAlignment,
      leadingWidth: leadingWidth,
      trailingWidth: trailingWidth,
      applyInsetScaling: applyInsetScaling,
      shortcut: shortcut,
      shortcutStyle: blendedSubtitleStyle,
      subtitle: subtitle != null
           ? DefaultTextStyle.merge(
               style: blendedSubtitleStyle,
               child: _AnimatedTitleSwitcher(child: subtitle!)
             )
           : null,
      child: DefaultTextStyle.merge(
               style: titleTextStyle,
               child: _AnimatedTitleSwitcher(child: child),
             ),
    );

    if (leading != null || trailing != null) {
      label = IconTheme.merge(
        data: IconThemeData(
          size: math.sqrt(textScale) * 21,
          color: titleTextStyle.color,
        ),
        child: label,
      );
    }

     if (_platformSupportsAccelerators && enabled) {
      label = MenuAcceleratorCallbackBinding(
        onInvoke: () => _handleSelect(context),
        child: label,
      );
    }

    final Color pressedColor = this.pressedColor ?? defaultPressedColor;
    return MergeSemantics(
      child: Semantics(
        enabled: onPressed != null,
        child: _CupertinoMenuItemGestureHandler(
          mouseCursor: mouseCursor,
          panActivationDelay: panActivationDelay,
          requestFocusOnHover: requestFocusOnHover,
          onPressed: onPressed != null ? () => _handleSelect(context) : null,
          onHover: onHover,
          onFocusChange: onFocusChange,
          focusNode: focusNode,
          focusNodeDebugLabel: child.toString(),
          pressedColor: CupertinoDynamicColor.maybeResolve(pressedColor, context)
                          ?? pressedColor,
          focusedColor: CupertinoDynamicColor.maybeResolve(focusedColor, context)
                          ?? focusedColor,
          hoveredColor: CupertinoDynamicColor.maybeResolve(hoveredColor, context)
                          ?? hoveredColor,
          behavior: behavior,
          child: DefaultTextStyle.merge(
            // The maximum number of lines appears to be infinite on the iOS
            // simulator, so just use a large number. This will apply to all
            // descendents with maxLines = null.
            maxLines: textScale > 1.25 ? 100 : 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: titleTextStyle,
            child: label,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HitTestBehavior>('hitTestBehavior', behavior));
    properties.add(DiagnosticsProperty<Duration>('panActivationDelay', panActivationDelay, defaultValue: Duration.zero));
    properties.add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode, defaultValue: null));
    properties.add(FlagProperty('enabled', value: onPressed != null, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<Widget?>('title', child));
    properties.add(DiagnosticsProperty<Widget?>('subtitle', subtitle));
    if (leading != null) {
      properties.add(DiagnosticsProperty<Widget?>('leading', leading));
    }
    if (trailing != null) {
      properties.add(DiagnosticsProperty<Widget?>('trailing', trailing));
    }
  }
}

class _AnimatedTitleSwitcher extends StatelessWidget {
  const _AnimatedTitleSwitcher({required this.child});
  final Widget child;

  static Widget _layoutBuilder(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: AlignmentDirectional.centerStart,
      children: <Widget>[
        for (final Widget child in previousChildren)
          SizedOverflowBox(
            size: Size.zero,
            alignment: AlignmentDirectional.centerStart,
            child: child,
          ),
        if (currentChild != null)
          AnimatedSize(
            clipBehavior: Clip.none,
            alignment: AlignmentDirectional.centerStart,
            curve: const Cubic(0.33, 0.2, 0.16, 1.04),
            duration: const Duration(milliseconds: 400),
            child: currentChild,
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      reverseDuration: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 200),
      layoutBuilder: _layoutBuilder,
      child: child,
    );
  }
}

/// A structured label for a [CupertinoMenuItem].
///
/// It not only shows the [CupertinoMenuItem.child], but if there is a shortcut
/// associated with the [CupertinoMenuItem], it will display a mnemonic for the
/// shortcut.
class _CupertinoMenuItemLabel extends StatelessWidget
    with CupertinoMenuEntryMixin {
  /// Creates a [_CupertinoMenuItemLabel]
  const _CupertinoMenuItemLabel({
    required this.child,
    this.leading,
    this.trailing,
    this.subtitle,
    this.shortcut,
    this.shortcutStyle,
    this.applyInsetScaling = true,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? padding,
    AlignmentGeometry? leadingAlignment,
    AlignmentGeometry? trailingAlignment,
    double? leadingWidth,
    double? trailingWidth,
  })  : _padding = padding,
        _leadingAlignment = leadingAlignment ?? defaultLeadingAlignment,
        _trailingAlignment = trailingAlignment ?? defaultTrailingAlignment,
        _trailingWidth = trailingWidth,
        _leadingWidth = leadingWidth,
        _constraints = constraints;

  static const double defaultHorizontalWidth = 16.0;
  static const double leadingWidgetWidth = 32.0;
  static const double trailingWidgetWidth = 44.0;
  static const EdgeInsetsDirectional defaultPadding =
                  EdgeInsetsDirectional.symmetric(vertical: 11.5);
  static const AlignmentDirectional defaultLeadingAlignment = AlignmentDirectional(1 / 6, 0.0);
  static const AlignmentDirectional defaultTrailingAlignment = AlignmentDirectional(-3 / 11, 0.0);
  static const BoxConstraints defaultConstraints = BoxConstraints(
    minHeight: kMinInteractiveDimensionCupertino,
  );

  // The padding for the contents of the menu item.
  //
  // If null, defaults to [defaultPadding].
  final EdgeInsetsGeometry? _padding;

  // The widget shown before the title. Typically a [CupertinoIcon].
  final Widget? leading;

  // The widget shown after the title. Typically a [CupertinoIcon].
  final Widget? trailing;

  // The width of the leading portion of the menu item.
  //
  // If null, [leadingWidgetWidth] is used when this menu item or a sibling menu
  // item has a leading widget, and [defaultHorizontalWidth] is used otherwise.
  final double? _leadingWidth;

  // The width of the trailing portion of the menu item.
  //
  // Defaults to [trailingWidgetWidth] when this menu item has a trailing
  // widget, and [defaultHorizontalWidth] otherwise.
  final double? _trailingWidth;

  // The alignment of the leading widget within the leading portion of the menu
  // item.
  //
  // Defaults to [defaultLeadingAlignment] when null.
  final AlignmentGeometry _leadingAlignment;

  // The alignment of the trailing widget within the trailing portion of the
  // menu item.
  //
  // Defaults to [defaultTrailingAlignment].
  final AlignmentGeometry _trailingAlignment;

  // The constraints applied to this menu item.
  //
  // If null, [defaultConstraints] is used.
  final BoxConstraints? _constraints;

  // The top center content of the menu item. Typically a [Text] widget.
  final Widget child;

  // The bottom center content of the menu item. Typically a [Text] widget.
  final Widget? subtitle;

  // Whether the insets of the menu item should scale with the
  // [MediaQuery.textScalerOf].
  final bool applyInsetScaling;

  /// The shortcut for this label, so that it can generate a string describing
  /// the shortcut.
  final MenuSerializableShortcut? shortcut;

  /// The [TextStyle] to apply when displaying this shortcut.
  final TextStyle? shortcutStyle;

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1.0;
    final double pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final double physicalPixel = 1 / pixelRatio;
    final bool showLeadingWidget = leading != null || (CupertinoMenuAnchor
                                                        ._maybeOf(context)
                                                        ?._hasLeadingWidget ?? false);
    double trailingWidth = _trailingWidth
                            ?? (trailing != null
                                  ? trailingWidgetWidth
                                  : defaultHorizontalWidth);
    double leadingWidth = _leadingWidth
                            ?? (showLeadingWidget
                                  ? leadingWidgetWidth
                                  : defaultHorizontalWidth);

    // Subtract a physical pixel from the default padding if no padding is
    // specified by the user. (iOS 17.2 simulator debug view)
    EdgeInsetsGeometry padding = _padding
            ?? defaultPadding.copyWith(
                 top:    math.max(defaultPadding.top - physicalPixel / 2, 0),
                 bottom: math.max(defaultPadding.bottom - physicalPixel / 2, 0),
               );

    BoxConstraints constraints = _constraints
                    ?? defaultConstraints.copyWith(
                        minHeight: defaultConstraints.minHeight - physicalPixel
                      );

    if (applyInsetScaling && textScale != 1.0) {
      // Padding scales with textScale, but at a slower rate than text. Square
      // root is used to estimate the padding scaling factor.
      final double paddingScaler = math.sqrt(textScale);
      padding       *= paddingScaler;
      constraints   *= paddingScaler;
      leadingWidth  *= paddingScaler;
      trailingWidth *= paddingScaler;
    }

    return ConstrainedBox(
      constraints: constraints,
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            // The leading and trailing widgets are wrapped in SizedBoxes and
            // then aligned, rather than just padded, because the alignment
            // behavior of the SizedBoxes appears to be more consistent with
            // AutoLayout (iOS).
            SizedBox(
              width: leadingWidth,
              child: showLeadingWidget
                  ? Align(alignment: _leadingAlignment, child: leading)
                  : null,
            ),
            Expanded(
              child: subtitle == null
                  ? child
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        child,
                        const SizedBox(height: 1),
                        subtitle!,
                      ],
                    ),
            ),
            if (shortcut != null)
              Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Text(
                    // Should CupertinoLocalizations be used here?
                    LocalizedShortcutLabeler.instance.getShortcutLabel(
                      shortcut!,
                      MaterialLocalizations.of(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: shortcutStyle
                            ?? TextStyle(
                                 color: CupertinoColors
                                            .secondaryLabel
                                            .resolveFrom(context)
                               )
                  )
              ),
            SizedBox(
              width: trailingWidth,
              child: trailing != null
                  ? Align(alignment: _trailingAlignment, child: trailing)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// A large horizontal divider that is used to separate [CupertinoMenuItem]s in
/// a [CupertinoMenuAnchor].
///
/// The divider has a height of 8 logical pixels. The [color] parameter can be
/// provided to customize the color of the divider.
///
/// See also:
///
/// * [CupertinoMenuItem], a Cupertino-style menu item.
/// * [CupertinoMenuAnchor], a widget that creates a Cupertino-style popup menu.
/// * [CupertinoMenuEntryMixin], a mixin that can be used to specify the
///   dividers that should flank a custom menu item.
class CupertinoLargeMenuDivider extends StatelessWidget
    with CupertinoMenuEntryMixin {
  /// Creates a large horizontal divider for a [CupertinoMenuAnchor].
  const CupertinoLargeMenuDivider({
    super.key,
    this.color = defaultColor,
  });

  /// Color for a transparent [CupertinoLargeMenuDivider].
  // The following colors were measured from debug mode on the iOS simulator,
  static const CupertinoDynamicColor defaultColor =
      CupertinoDynamicColor.withBrightness(
          color:     Color.fromRGBO(0, 0, 0, 0.08),
          darkColor: Color.fromRGBO(0, 0, 0, 0.16),
        );

  /// The color of the divider.
  ///
  /// If this property is null, [CupertinoLargeMenuDivider.defaultColor] is
  /// used.
  final Color color;

  @override
  bool get allowTrailingSeparator => false;

  @override
  bool get allowLeadingSeparator => false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      color: CupertinoDynamicColor.resolve(color, context),
    );
  }
}

/// A horizontal divider used to separate [CupertinoMenuItem]s
///
/// The default width of the divider is 1 physical pixel, Unlike a [Border],
/// the [thickness] of the divider does occupy layout space.
///
// This is class will be made public in the future, but is currently private to
// avoid API churn.
class _CupertinoMenuDivider extends StatelessWidget {
  /// Draws a [_CupertinoMenuDivider] below a [child].
  const _CupertinoMenuDivider.wrapBottom({
    required Widget child,
  })  : _child = child;

  /// The default color applied to the [_CupertinoMenuDivider] with
  /// [BlendMode.overlay].
  ///
  /// This color is applied to the divider before the [underlayColor] is
  /// applied, and is used to give the appearance of the divider "cutting" into
  /// the background.
  // The following colors were measured from the iOS simulator, and opacity was
  // extrapolated:
  // Dark mode on black       Color.fromRGBO(97, 97, 97)
  // Dark mode on white       Color.fromRGBO(132, 132, 132)
  // Light mode on black      Color.fromRGBO(147, 147, 147)
  // Light mode on white      Color.fromRGBO(187, 187, 187)
  //
  // Colors were also compared atop a red, green, and blue backgrounds on the
  // iOS simulator.
  static const CupertinoDynamicColor underlayColor =
    CupertinoDynamicColor.withBrightness(
        color: Color.fromRGBO(140, 140, 140, 0.5),
        darkColor: Color.fromRGBO(255, 255, 255, 0.25),
      );

  /// The default color applied to the [_CupertinoMenuDivider], atop the
  /// [underlayColor], with [BlendMode.srcOver].
  ///
  /// This color is used to make the divider more opaque.
  static const CupertinoDynamicColor color =
    CupertinoDynamicColor.withBrightness(
        color: Color.fromRGBO(0, 0, 0, 0.24),
        darkColor: Color.fromRGBO(255, 255, 255, 0.23),
      );

  /// The widget below this widget in the tree.
  final Widget? _child;

  @override
  Widget build(BuildContext context) {
    final double pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final double displacement = 1 / pixelRatio;
    final TextDirection textDirection = Directionality.of(context);
    final Alignment begin = AlignmentDirectional.bottomStart.resolve(textDirection);
    final Alignment end = AlignmentDirectional.bottomEnd.resolve(textDirection);
    assert(
      begin.y == end.y && begin.y.roundToDouble() == begin.y,
      'CupertinoMenuDivider must either inhabit the top, bottom, or center of its parent.',
    );
    return CustomPaint(
      painter: _AliasedBorderPainter(
        begin: begin,
        end: end,
        color: CupertinoDynamicColor.resolve(color, context),
        underlayColor: CupertinoDynamicColor.resolve(underlayColor, context),
        offset: Offset(0, -displacement / 2),
        border: const BorderSide(width: 0.0),
        // Only anti-alias the border if the thickness is less than one physical
        // pixel.
        antiAlias: pixelRatio < 1.0,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: displacement),
        child: _child,
      ),
    );
  }
}

// A custom painter that draws a border without antialiasing.
class _AliasedBorderPainter extends CustomPainter {
  const _AliasedBorderPainter({
    required this.border,
    required this.color,
    required this.underlayColor,
    required this.begin,
    required this.end,
    this.offset = Offset.zero,
    this.antiAlias = false,
  });

  final BorderSide border;
  final Color color;
  final Color underlayColor;
  final Alignment begin;
  final Alignment end;
  final Offset offset;
  final bool antiAlias;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset p1 = begin.alongSize(size) + offset;
    final Offset p2 = end.alongSize(size) + offset;
    if (!kIsWeb) {
      final Paint basePainter = border.toPaint()
        ..color = underlayColor
        ..isAntiAlias = antiAlias
        ..blendMode = BlendMode.overlay;
      canvas.drawLine(p1, p2, basePainter);
    }

    final Paint tintPainter = border.toPaint()
      ..color = color
      ..isAntiAlias = antiAlias;
    canvas.drawLine(p1, p2, tintPainter);
  }

  @override
  bool shouldRepaint(_AliasedBorderPainter oldDelegate) {
    return color         != oldDelegate.color          ||
           underlayColor != oldDelegate.underlayColor  ||
           end           != oldDelegate.end            ||
           begin         != oldDelegate.begin          ||
           border        != oldDelegate.border         ||
           offset        != oldDelegate.offset         ||
           antiAlias     != oldDelegate.antiAlias;
  }
}

/// A gesture handler for [CupertinoMenuItem]s that responds to  taps, pans, and
/// long presses.
///
/// The [onPressed] callback is called when the user taps the menu item, pans over
/// the menu item and lifts their finger, or when the user long-presses a menu
/// item that has a non-null [panActivationDelay]. If provided, the [pressedColor]
/// will highlight the menu item whenever a pointer is in contact with the menu
/// item. If [onPressed] is null, the menu item will be disabled and will not
/// respond to user input.
///
/// A [mouseCursor] can be provided to change the cursor that appears when a
/// mouse hovers over the menu item. If [mouseCursor] is null, the
/// [SystemMouseCursors.click] cursor is used. A [hoveredColor] can be provided
/// to change the color of the menu item when a mouse hovers over the menu item.
///
/// If [focusNode] is provided, the menu item will be focusable. When the menu
/// item is focused, the [focusedColor] will be used to highlight the menu item.
class _CupertinoMenuItemGestureHandler extends StatefulWidget {
  /// Creates a [_CupertinoMenuItemGestureHandler].
  ///
  /// The [child] and [pressedColor] arguments are required and must not be null.
  const _CupertinoMenuItemGestureHandler({
    required this.child,
    required this.pressedColor,
    this.mouseCursor,
    this.focusedColor,
    this.focusNode,
    this.hoveredColor,
    this.panActivationDelay,
    this.onPressed,
    this.onHover,
    this.onFocusChange,
    this.focusNodeDebugLabel,
    this.requestFocusOnHover = false,
    this.behavior = HitTestBehavior.opaque,
  });

  /// The widget displayed in the center of this button.
  ///
  /// Typically this is the button's label, using a [Text] widget.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this callback is null, then the button will be disabled.
  ///
  /// See also:
  ///
  ///  * [enabled], which is true if the button is enabled.
  final VoidCallback? onPressed;

  /// Called when a pointer enters or exits the button response area.
  ///
  /// The value passed to the callback is true if a pointer has entered button
  /// area and false if a pointer has exited.
  final ValueChanged<bool>? onHover;

  /// Whether hovering can request focus.
  ///
  /// Defaults to false.
  final bool requestFocusOnHover;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's node gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool>? onFocusChange;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// Delay between a user's pointer entering a menu item during a pan, and
  /// the menu item being tapped.
  ///
  /// If null, the menu item will not be pressed when panned over.
  final Duration? panActivationDelay;

  /// The color of menu item when focused.
  final Color? focusedColor;

  /// The color of menu item when hovered by the user's pointer.
  final Color? hoveredColor;

  /// The color of menu item while the menu item is swiped or pressed down.
  final Color? pressedColor;

  /// The mouse cursor to display on hover.
  final MouseCursor? mouseCursor;

  /// How the menu item should respond to hit tests.
  ///
  /// Defaults to [HitTestBehavior.opaque].
  final HitTestBehavior behavior;

  /// A debug label that is used to identify the focus node.
  final String? focusNodeDebugLabel;

  /// Whether the menu item will respond to user input.
  bool get enabled => onPressed != null;

  @override
  State<_CupertinoMenuItemGestureHandler> createState() =>
      _CupertinoMenuItemGestureHandlerState();
}

class _CupertinoMenuItemGestureHandlerState
    extends State<_CupertinoMenuItemGestureHandler>
    with _PanTarget<_CupertinoMenuItemGestureHandler> {
  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _simulateTap),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: _simulateTap),
  };

  Timer? _longPanPressTimer;
  bool _isFocused = false;
  bool _isSwiped = false;
  bool _isPressed = false;
  bool _isHovered = false;

  // If a focus node isn't given to the widget, then we have to manage our own.
  FocusNode? _internalFocusNode;
  FocusNode? get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _createInternalFocusNode();
    }
    _focusNode?.addListener(_handleFocusChange);
  }

  @override
  bool didPanEnter() {
    assert(widget.enabled, 'Disabled items should not call didPanEnter.');

    if (widget.panActivationDelay != null && _longPanPressTimer == null) {
      _longPanPressTimer = Timer(widget.panActivationDelay!, () {
        _longPanPressTimer = null;
        if (mounted) {
          _handleTap();
        }
      });
    }

    if (!_isSwiped) {
      setState(() {
        _isSwiped = true;
      });
    }
    return true;
  }

  @override
  void didPanLeave({required bool pointerUp}) {
    _longPanPressTimer?.cancel();
    _longPanPressTimer = null;
    if (mounted) {
      if (pointerUp) {
        _simulateTap();
      } else if (_isSwiped || _isPressed) {
        setState(() {
          _isSwiped = false;
          _isPressed = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(_CupertinoMenuItemGestureHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)
          ?.removeListener(_handleFocusChange);
      if (widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      } else {
        _createInternalFocusNode();
      }
      _focusNode!.addListener(_handleFocusChange);
    }

    if (oldWidget.enabled && !widget.enabled) {
      _isHovered = false;
      _isPressed = false;
      _isSwiped = false;
      _handleFocusChange(false);
    }
  }

  @override
  void dispose() {
    _longPanPressTimer?.cancel();
    _focusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  void _handleFocusChange([bool? focused]) {
    if (_focusNode?.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode?.hasFocus ?? focused ?? false;
      });

      widget.onFocusChange?.call(_isFocused);
    }
  }

  void _handleHover(PointerEvent event) {
    final bool hovered = event is PointerEnterEvent;
    if (!widget.enabled) {
      if (_isHovered) {
        setState(() {
          _isHovered = false;
        });
      }
      return;
    }

    if (hovered != _isHovered) {
      widget.onHover?.call(hovered);
      if (hovered && widget.requestFocusOnHover) {
        assert(_debugMenuInfo('Requesting focus for $_focusNode from hover'));
        _focusNode?.requestFocus();
      }

      setState(() {
        _isHovered = hovered;
      });
    }
  }

  void _simulateTap([Intent? intent]) {
    if (widget.enabled) {
      _handleTap();
    }
  }

  void _handleTap() {
    if (widget.enabled) {
      widget.onPressed?.call();
      setState(() {
        _isPressed = false;
        _isSwiped = false;
      });
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && !_isPressed) {
      setState(() {
        _isPressed = true;
        _isSwiped = true;
      });
    }
  }

  void _handleTapCancel() {
    if (_isPressed || _isSwiped) {
      setState(() {
        _isPressed = false;
        _isSwiped = false;
      });
    }
  }

  void _createInternalFocusNode() {
    _internalFocusNode = FocusNode();
    assert(() {
      _internalFocusNode!.debugLabel =
          '$CupertinoMenuItem(${widget.focusNodeDebugLabel})';
      return true;
    }());
  }

  Color? get backgroundColor {
    if (widget.enabled) {
      if (_isPressed || _isSwiped) {
        return widget.pressedColor;
      }

      if (_isFocused) {
        return widget.focusedColor ?? widget.pressedColor?.withOpacity(0.075);
      }

      if (_isHovered) {
        return widget.hoveredColor ?? widget.pressedColor?.withOpacity(0.05);
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget? child = widget.child;
    final Color? backgroundColor = this.backgroundColor;
    if (backgroundColor != null) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          backgroundBlendMode:
              CupertinoTheme.maybeBrightnessOf(context) == Brightness.light
                  ? BlendMode.multiply
                  : BlendMode.plus,
          color: backgroundColor,
        ),
        child: child,
      );
    }

    child = MouseRegion(
        onEnter: _handleHover,
        onExit: _handleHover,
        hitTestBehavior: HitTestBehavior.deferToChild,
        cursor: widget.enabled
            ? widget.mouseCursor ?? SystemMouseCursors.click
            : MouseCursor.defer,
        child: Actions(
          actions: _actionMap,
          child: Focus(
            focusNode: _focusNode,
            canRequestFocus: widget.enabled,
            skipTraversal: !widget.enabled,
            onFocusChange: _handleFocusChange,
            child: GestureDetector(
              behavior: widget.behavior,
              onTap: _handleTap,
              onTapDown: _handleTapDown,
              onTapCancel: _handleTapCancel,
              child: child,
            ),
          ),
        ),
      );

    if (widget.enabled) {
      child = MetaData(
        metaData: this,
        child: child,
      );
    }

    return child;
  }
}

/// Can be mixed into a [State] to receive callbacks when a pointer enters or
/// leaves a [_PanTarget]. The [_PanTarget] should be an ancestor of a
/// [_PanRegion].
@optionalTypeArgs
mixin _PanTarget<T extends StatefulWidget> on State<T> {
  /// Called when a pointer enters the [_PanTarget].
  ///
  /// Return true if the pointer should be considered "on" the [_PanTarget], and
  /// false otherwise (for example, when the [_PanTarget] is disabled).
  bool didPanEnter();

  /// Called when the pointer leaves the [_PanTarget]. If [pointerUp] is true,
  /// then the pointer left the screen while over this menu item.
  void didPanLeave({required bool pointerUp});
}


/// An interface for registering and unregistering a [_RenderPanRegion]
/// (typically created with a [_PanRegion] widget) with a
/// [_RenderPanRegionSurface] (typically created with a [_PanRegionSurface]
/// widget).
abstract class _PanRegionRegistry {
  /// Register the given [_RenderPanRegion] with the registry.
  void registerPanRegion(_RenderPanRegion region);

  /// Unregister the given [_RenderPanRegion] with the registry.
  void unregisterPanRegion(_RenderPanRegion region);

  /// Forwards a [PointerDownEvent] from a hit [_PanRegion] to the nearest
  /// [_RenderPanRegionSurface].
  ///
  /// The `result` parameter is the result of a box hit test that hit a
  /// [_PanRegion].
  void beginPan(PointerDownEvent event, BoxHitTestResult result);

  /// Allows finding of the nearest [_PanRegionRegistry], such as a
  /// [_RenderPanRegionSurface].
  ///
  /// Will throw if a [_PanRegionRegistry] isn't found.
  static _PanRegionRegistry of(BuildContext context) {
    final _PanRegionRegistry? registry = maybeOf(context);
    assert(() {
      if (registry == null) {
        throw FlutterError(
          'PanRegionRegistry.of() was called with a context that does not contain a PanRegionSurface widget.\n'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return registry!;
  }

  /// Allows finding of the nearest [_PanRegionRegistry], such as a
  /// [_RenderPanRegionSurface].
  static _PanRegionRegistry? maybeOf(BuildContext context) {
    return context.findAncestorRenderObjectOfType<_RenderPanRegionSurface>();
  }
}

/// A widget that notifies registered [_PanRegion]s of pan events that occur
/// inside or outside of their bounds.
///
/// The regions are defined by adding [_PanRegion] widgets to the widget tree
/// around the regions of interest, and they will register with this
/// [_PanRegionSurface]. Each of the tap regions can optionally belong to a group
/// by assigning a [_PanRegion.groupId], where all the regions with the same
/// groupId act as if they were all one region.
///
/// Pan events are defined as a sequence of [PointerEvent]s that start **after**
/// a [PointerDownEvent] and end with a [PointerUpEvent] or
/// [PointerCancelEvent]. Pan callbacks, such as [_PanRegion.onPanUpdate],
/// will only be called by a [_PanRegion] if that region, or a group member
/// of that region, is hit by the [PointerDownEvent] that initiates the pan.
///
/// Once a pan is initiated, pan events that occur within the bounds of a
/// [_PanRegion] will make that region and it's group members call
/// [_PanRegion.onPanUpdate] with the `isInside` parameter set to true. If
/// the pan occurred outside all members of a group, `isInside` is set to false.
///
/// The [_PanRegionSurface] should be defined at the highest level needed to
/// encompass the entire area where taps should be monitored. This is typically
/// around the entire app. If the entire app isn't covered, then taps outside of
/// the [_PanRegionSurface] will be ignored and no [_PanRegion.onTapOutside] calls
/// will be made for those events.
///
/// [_PanRegion]s register only with the nearest ancestor [_PanRegionSurface].
///
/// See also:
///
///  * [_RenderPanRegionSurface], the render object that is inserted into the
///    render tree by this widget.
///  * <https://flutter.dev/gestures/#gesture-disambiguation> for more
///    information about the gesture system and how it disambiguates inputs.
class _PanRegionSurface extends SingleChildRenderObjectWidget {
  /// Creates a const [_RenderPanRegionSurface].
  ///
  /// The [child] attribute is required.
  const _PanRegionSurface({
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPanRegionSurface();
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderProxyBox renderObject,
  ) {}
}

/// A render object that notifies registered [_RenderPanRegion]s of pan events
/// that occur inside or outside of their bounds.
///
/// Regions are defined by adding [_RenderPanRegion] render objects in the render
/// tree around the regions of interest, and they will register with this
/// [_RenderPanRegionSurface]. Each of the [_RenderPanRegion]s can optionally
/// belong to a group by assigning a [_RenderPanRegion.groupId], where all the
/// regions sharing a groupId act as if they were all one region.
///
/// Pan events are defined as a sequence of [PointerEvent]s that start **after**
/// a [PointerDownEvent] and end with a [PointerUpEvent] or
/// [PointerCancelEvent]. Pan callbacks, such as [_RenderPanRegion.onPanUpdate],
/// will only be called by a [_RenderPanRegion] if that region, or a group member
/// of that region, is hit by the [PointerDownEvent] that initiates the pan.
///
/// Once a pan is initiated, pan events that occur within the bounds of a
/// [_RenderPanRegion] will make that region and it's group members call
/// [_RenderPanRegion.onPanUpdate] with the `isInside` parameter set to true. If
/// the pan occurred outside all members of a group, `isInside` is set to false.
///
/// The [_RenderPanRegionSurface] should be defined at the highest level needed
/// to encompass the entire area where pans should be monitored. This is
/// typically around the entire app. If the entire app isn't covered, then taps
/// outside of the [_RenderPanRegionSurface] will be ignored and no
/// [_RenderPanRegion.onPanUpdate] calls will be made for those events.
///
///
/// [_RenderPanRegion]s register only with the nearest ancestor
/// [_RenderPanRegionSurface].
///
/// See also:
///
/// * [_PanRegionSurface], a widget that inserts a [_RenderPanRegionSurface] into
///   the render tree.
/// * [_PanRegionRegistry.of], which can find the nearest ancestor
///   [_RenderPanRegionSurface], which is a [_PanRegionRegistry].
class _RenderPanRegionSurface extends RenderProxyBox implements _PanRegionRegistry {
  /// Regions grouped by their [_PanRegion.groupId]s.
  final Map<Object?, Set<_RenderPanRegion>> _groupIdToRegions = <Object?, Set<_RenderPanRegion>>{};

  /// [_PanRegion]s that are participating in the current pan gesture.
  final Set<_RenderPanRegion> _pannedRegions = <_RenderPanRegion>{};

  /// [_PanRegion]s that have been registered with this surface.
  final Set<_RenderPanRegion> _registeredRegions = <_RenderPanRegion>{};

  /// The most recently panned [_PanTarget]s, in the order they were panned.
  final List<_PanTarget> _enteredTargets = <_PanTarget>[];

  late final PanGestureRecognizer _pan = PanGestureRecognizer()
    ..onUpdate = _handlePanUpdate
    ..onEnd = _handlePanEnd
    ..onCancel = _handlePanCancel;

  Offset? _panPosition;
  BoxHitTestResult? _pannedHitTestResults;
  Set<_RenderPanRegion> _hitRegions = <_RenderPanRegion>{};

  @override
  void registerPanRegion(_RenderPanRegion region) {
    assert(_debugPanRegion('Region $region registered.'));
    assert(!_registeredRegions.contains(region));
    _registeredRegions.add(region);
    if (region.groupId != null) {
      _groupIdToRegions[region.groupId] ??= <_RenderPanRegion>{};
      _groupIdToRegions[region.groupId]!.add(region);
    }
    _updatePannedRegions();
  }

  @override
  void unregisterPanRegion(_RenderPanRegion region) {
    assert(_debugPanRegion('Region $region unregistered.'));
    assert(_registeredRegions.contains(region));
    _registeredRegions.remove(region);
    if (region.groupId != null) {
      assert(_groupIdToRegions.containsKey(region.groupId));
      _groupIdToRegions[region.groupId]!.remove(region);
      if (_groupIdToRegions[region.groupId]!.isEmpty) {
        _groupIdToRegions.remove(region.groupId);
      }
    }
    _updatePannedRegions();
  }

  @override
  void beginPan(PointerDownEvent event, BoxHitTestResult result) {
    // Block multiple pan initiations (overlapping regions that were hit).
     if (_pannedHitTestResults?.path == result.path) {
      assert(_debugPanRegion('Pan is already initiated: $_pannedRegions'));
      return;
    }

    assert(
      _registeredRegions.every((_RenderPanRegion element) => element.enabled),
      'A disabled RenderPanRegion was registered.',
    );

    if (_registeredRegions.isEmpty) {
      assert(_debugPanRegion('Ignored pan event because no regions were registered.'));
      return;
    }

    // Collect the regions that were hit.
    _hitRegions = _filterHitRegions(result.path).cast<_RenderPanRegion>().toSet();

    assert(_debugPanRegion('PointerDown event hit ${_hitRegions.length} regions.'));

    _updatePannedRegions();

    assert(_pannedRegions.isNotEmpty);

    _panPosition = event.position;
    _pan.addPointer(event);
  }

  @override
  void dispose() {
    _pan.dispose();
    super.dispose();
  }

  void _updatePannedRegions() {
    final Set<_RenderPanRegion> registeredHitRegions =
        _hitRegions.intersection(_registeredRegions);
    _pannedRegions.clear();
    for (final _RenderPanRegion region in registeredHitRegions) {
      if (region.groupId == null) {
        _pannedRegions.add(region);
        continue;
      }

      // Add all grouped regions to the insideRegions so that groups act as a
      // single region.
      _pannedRegions.addAll(_groupIdToRegions[region.groupId]!);
    }
  }

  // Returns the registered regions that are in the hit path.
  Iterable<HitTestTarget> _filterHitRegions(Iterable<HitTestEntry> hitTestPath) {
    final Set<HitTestTarget> hitRegions = <HitTestTarget>{};
    for (final HitTestEntry<HitTestTarget> entry in hitTestPath) {
      final HitTestTarget target = entry.target;
      if (_registeredRegions.contains(target)) {
        hitRegions.add(target);
      }
    }
    return hitRegions;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _panPosition = details.globalPosition;
    _updatePan(details);
  }

  void _handlePanEnd(DragEndDetails details) {
    _leaveAllEntered(pointerUp: true);
    for (final _RenderPanRegion region in _pannedRegions) {
      region.onPanEnd?.call(details);
    }
    assert(_debugPanRegion('Pan ended at ${details.globalPosition}.'));
    _panPosition = null;
    _pannedRegions.clear();
  }

  void _handlePanCancel() {
    _leaveAllEntered();
    for (final _RenderPanRegion region in _pannedRegions) {
      region.onPanCancel?.call();
    }
    assert(_debugPanRegion('Pan canceled at $_panPosition.'));
    _panPosition = null;
    _pannedRegions.clear();
  }

  void _updatePan(DragUpdateDetails details) {
    final Set<_RenderPanRegion> hitRegions = <_RenderPanRegion>{};
    final BoxHitTestResult result = BoxHitTestResult();

    // Hit test and collect each [RenderPanRegion] and it's children. If a
    // region is hit, regions in the same group are marked as hit.
    for (final _RenderPanRegion region in _pannedRegions) {
      final ui.Offset localPosition = region.globalToLocal(_panPosition!);
      if (region.hitTest(result, position: localPosition)) {
        if (region.groupId == null) {
          hitRegions.add(region);
          continue;
        }

        hitRegions.addAll(_groupIdToRegions[region.groupId]!);
      }
    }

    // Notify the regions that were hit, and the regions that were not.
    for (final _RenderPanRegion region in _pannedRegions) {
      region.onPanUpdate?.call(details, isInside: hitRegions.contains(region));
    }

    // Collect RenderMetaData children that were hit.
    final Iterator<HitTestEntry<HitTestTarget>> hitPath = result.path.iterator;
    final List<_PanTarget> targets = <_PanTarget>[];
    while (hitPath.moveNext()) {
      final HitTestTarget target = hitPath.current.target;

      // If the [MetaData] that is hit contains a [_PanTarget] in the same group,
      // then add it to the list of targets.
      if (target case RenderMetaData(:final _PanTarget metaData)) {
        targets.add(metaData);
      }
    }

    bool listsMatch = false;

    // Check if the panned targets are the same as the last pan event
    // (_enteredTargets contains the previous targets).
    if (
      targets.length >= _enteredTargets.length &&
      _enteredTargets.isNotEmpty
    ) {
      listsMatch = true;
      for (int i = 0; i < _enteredTargets.length; i++) {
        if (targets[i] != _enteredTargets[i]) {
          listsMatch = false;
          break;
        }
      }
    }

    // If everything is the same, bail early.
    if (listsMatch) {
      return;
    }

    // Leave old targets.
    _leaveAllEntered();

    // Enter new targets.
    final Iterator<_PanTarget> iterator = targets.iterator;
    while (iterator.moveNext()) {
      final _PanTarget target = iterator.current;
      _enteredTargets.add(target);
      if (target.didPanEnter()) {
        HapticFeedback.selectionClick();
        return;
      }
    }
  }

  void _leaveAllEntered({bool pointerUp = false}) {
    for (final _PanTarget target in _enteredTargets) {
      target.didPanLeave(pointerUp: pointerUp);
    }

    _enteredTargets.clear();
  }
}

/// A handler for pan events that occur inside or outside of a [_PanRegion].
///
/// Pan events are defined as a sequence of [PointerEvent]s that start **after**
/// a [PointerDownEvent] and end with a [PointerUpEvent] or
/// [PointerCancelEvent].
///
/// Once a pan is initiated, pan events that occur within the bounds of a
/// [_RenderPanRegion] will make that region and it's group members call
/// [_RenderPanRegion.onPanUpdate] with the `isInside` parameter set to true. If
/// the pan occurred outside all members of a group, `isInside` is set to false.
typedef _PanRegionUpdateCallback = void Function(DragUpdateDetails details, {bool isInside});

/// A widget that defines a region that will begin tracking pan events upon
/// receiving a [PointerDownEvent] with the bounds of itself or a group member.
///
/// Pan events are defined as a sequence of [PointerEvent]s that start **after**
/// a [PointerDownEvent] and end with a [PointerUpEvent] or
/// [PointerCancelEvent].
///
/// This widget indicates to the nearest ancestor [_PanRegionSurface] that the
/// region occupied by its child will participate in the pan detection for that
/// surface.
///
/// If this region belongs to a group (by virtue of its [groupId]), all the
/// regions in the group will call their [_PanRegion.onPanUpdate] callbacks when
/// a pan is detected by any member of the group.
///
/// If there is no [_PanRegionSurface] ancestor, [_PanRegion] will do nothing.
class _PanRegion extends SingleChildRenderObjectWidget {
  /// Creates a const [_PanRegion].
  ///
  /// The [child] argument is required.
  const _PanRegion({
    required super.child,
    // ignore: unused_element
    this.enabled = true,
    // ignore: unused_element
    this.behavior = HitTestBehavior.deferToChild,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.groupId,
    String? debugLabel,
  }) : debugLabel = kReleaseMode ? null : debugLabel;

  /// Whether or not this [_PanRegion] is enabled as part of the composite region.
  final bool enabled;

  /// How to behave during hit testing when deciding how the hit test propagates
  /// to children and whether to consider targets behind this [_PanRegion].
  ///
  /// Defaults to [HitTestBehavior.deferToChild].
  ///
  /// See [HitTestBehavior] for the allowed values and their meanings.
  final HitTestBehavior behavior;

  /// A callback to be invoked when a pan is detected by this [_PanRegion], or
  /// any other pan region with the same [groupId], if any.
  ///
  /// The [DragUpdateDetails] passed to the function is the event that was
  /// emitted by the [PanGestureRecognizer].
  ///
  /// Pan events are defined as a sequence of [PointerEvent]s that start
  /// **after** a [PointerDownEvent] and end with a [PointerUpEvent] or
  /// [PointerCancelEvent]. If this region and it's group members do not
  /// receive the [PointerDownEvent] that initiates a pan, then this callback
  /// will not be called.
  ///
  /// Once a pan is initiated, pan events that occur within the bounds of a
  /// [_RenderPanRegion] will make that region and it's group members call
  /// [_RenderPanRegion.onPanUpdate] with the `isInside` parameter set to true.
  /// If the pan occurred outside all members of a group, `isInside` is set to
  /// false.
  final _PanRegionUpdateCallback? onPanUpdate;

  /// A callback invoked when the pointer that initiated a pan leaves the
  /// screen.
  ///
  /// Pan events are defined as a sequence of [PointerEvent]s that start
  /// **after** a [PointerDownEvent] and end with a [PointerUpEvent] or
  /// [PointerCancelEvent]. If neither this region nor it's group members
  /// receive the [PointerDownEvent] that initiates the pan, then this callback
  /// will not be called.
  final GestureDragEndCallback? onPanEnd;

  /// A callback invoked when the pan is interrupted (for example, by a system modal
  /// appearing).
  ///
  /// Pan events are defined as a sequence of [PointerEvent]s that start
  /// **after** a [PointerDownEvent] and end with a [PointerUpEvent] or
  /// [PointerCancelEvent]. If neither this region nor it's group members
  /// receive the [PointerDownEvent] that initiates the pan, then this callback
  /// will not be called.
  final GestureDragCancelCallback? onPanCancel;

  /// An optional group ID that groups [_PanRegion]s together so that they
  /// operate as one region. If any member of a group is hit by the
  /// [PointerDownEvent] that initiates a pan, then all members will be notified
  /// of subsequent pan events.
  ///
  /// If the group id is null, then only this region is hit tested.
  final Object? groupId;

  /// An optional debug label to help with debugging in debug mode.
  ///
  /// Will be null in release mode.
  final String? debugLabel;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPanRegion(
      registry: _PanRegionRegistry.maybeOf(context),
      enabled: enabled,
      behavior: behavior,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      groupId: groupId,
      debugLabel: debugLabel,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderPanRegion renderObject) {
    renderObject
      ..registry = _PanRegionRegistry.maybeOf(context)
      ..enabled = enabled
      ..behavior = behavior
      ..groupId = groupId
      ..onPanUpdate = onPanUpdate
      ..onPanEnd = onPanEnd
      ..onPanCancel = onPanCancel;
    assert((){
      renderObject.debugLabel = debugLabel;
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'DISABLED', defaultValue: true));
    properties.add(DiagnosticsProperty<HitTestBehavior>('behavior', behavior, defaultValue: HitTestBehavior.deferToChild));
    properties.add(DiagnosticsProperty<Object?>('debugLabel', debugLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<Object?>('groupId', groupId, defaultValue: null));
  }
}

/// A render object that defines a region that begins tracking pan events upon
/// receiving a [PointerDownEvent] within it's own bounds or the bounds of a
/// group member.
///
/// This render object indicates to the nearest ancestor [_PanRegionSurface]
/// that the region occupied by this render object's child (or the render object
/// itself, if [behavior] is [HitTestBehavior.opaque]) will participate in the
/// pan detection.
///
/// Panning in this context is defined as a sequence of [PointerEvent]s that
/// start **after** a [PointerDownEvent] and end with a [PointerUpEvent] or
/// [PointerCancelEvent].
///
/// If this region belongs to a group (by virtue of its [groupId]), all the
/// regions in the group will call their [_PanRegion.onPanUpdate] callbacks when
/// a pan is detected by any member of the group.
///
/// If there is no [_PanRegionSurface] ancestor, [_PanRegion] will do nothing.
///
/// See also:
///
///  * [_PanRegion], a widget that inserts a [_RenderPanRegion] into the render
///    tree.
class _RenderPanRegion extends RenderProxyBoxWithHitTestBehavior {
  /// Creates a [_RenderPanRegion].
  _RenderPanRegion({
    // ignore: library_private_types_in_public_api
    _PanRegionRegistry? registry,
    bool enabled = true,
    this.onPanUpdate,
    this.onPanCancel,
    this.onPanEnd,
    super.behavior = HitTestBehavior.deferToChild,
    Object? groupId,
    String? debugLabel,
  })  : _registry = registry,
        _enabled = enabled,
        _groupId = groupId,
        debugLabel = kReleaseMode ? null : debugLabel;

  /// A callback to be invoked when a tap is detected outside of this
  /// [_RenderPanRegion] and any other region with the same [groupId], if any.
  ///
  /// The [PointerDownEvent] passed to the function is the event that caused the
  /// notification. If this region is part of a group (i.e. [groupId] is set),
  /// then it's possible that the event may be outside of this immediate region,
  /// although it will be within the region of one of the group members.
  _PanRegionUpdateCallback? onPanUpdate;

  /// Called when the pointer leaves the region encompassed by all [_PanRegion]s
  /// in this group.
  GestureDragEndCallback? onPanEnd;

  /// Called when the pan is interrupted (for example, by a system modal
  /// appearing).
  GestureDragCancelCallback? onPanCancel;

  /// A label used in debug builds. Will be null in release builds.
  String? debugLabel;

  /// The most recent [BoxHitTestResult] that hit this region.
  // ignore: use_late_for_private_fields_and_variables
  BoxHitTestResult? _cachedHit;

  bool _isRegistered = false;

  /// Whether or not this region should participate in the composite region.
  bool get enabled => _enabled;
  bool _enabled;
  set enabled(bool value) {
    if (_enabled != value) {
      _enabled = value;
      markNeedsLayout();
    }
  }

  /// An optional group ID that groups [_RenderPanRegion]s together so that they
  /// operate as one region. If any member of a group is hit by a particular
  /// pan, then the [onPanUpdate] will not be called for any members of the
  /// group. If any member of the group is panned, then all members will have their
  /// [onPanUpdate] called.
  ///
  /// If the group id is null, then only this region is hit tested.
  Object? get groupId => _groupId;
  Object? _groupId;
  set groupId(Object? value) {
    if (_groupId != value) {
      // If the group changes, we need to unregister and re-register under the
      // new group. The re-registration happens automatically in layout().
      if (_isRegistered) {
        _registry!.unregisterPanRegion(this);
        _isRegistered = false;
      }
      _groupId = value;
      markNeedsLayout();
    }
  }

  /// The registry that this [_RenderPanRegion] should register with.
  ///
  /// If the [registry] is null, then this region will not be registered
  /// anywhere, and will not do any pan detection.
  ///
  /// A [_RenderPanRegionSurface] is a [_PanRegionRegistry].
  // ignore: library_private_types_in_public_api
  _PanRegionRegistry? get registry => _registry;
  _PanRegionRegistry? _registry;
  // ignore: library_private_types_in_public_api
  set registry(_PanRegionRegistry? value) {
    if (_registry != value) {
      if (_isRegistered) {
        _registry!.unregisterPanRegion(this);
        _isRegistered = false;
      }
      _registry = value;
      markNeedsLayout();
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required ui.Offset position}) {
    final bool hit = super.hitTest(result, position: position);
    if (hit) {
      _cachedHit = result;
    }
    return hit;
  }


  @override
  void handleEvent(PointerEvent event, HitTestEntry<HitTestTarget> entry) {
    // Forward [PointerDownEvent]s to the nearest ancestor
    // [RenderPanRegionSurface].
    if (event is PointerDownEvent && _isRegistered) {
      registry!.beginPan(event, _cachedHit!);
    }
  }

  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    super.layout(constraints, parentUsesSize: parentUsesSize);
    if (_registry == null) {
      return;
    }

    // This region should be registered when enabled, and unregistered when
    // disabled.
    //
    // NOTE: The logic for [RenderTapRegion] unregisters/registers every time
    // layout occurs, whereas [RenderPanRegion] only registers when the enabled
    // and _isRegistered states change. It's not clear why [RenderTapRegion]
    // behaves this way.
    if (_isRegistered == _enabled) {
      return;
    }

    if (_enabled) {
      _registry!.registerPanRegion(this);
    } else {
      _registry!.unregisterPanRegion(this);
    }

    _isRegistered = _enabled;
  }

  @override
  void dispose() {
    if (_isRegistered) {
      _registry!.unregisterPanRegion(this);
    }

    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String?>('debugLabel', debugLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<Object?>('groupId', groupId, defaultValue: null));
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'DISABLED', defaultValue: true));
  }
}



/// A debug print function, which should only be called within an assert, like
/// so:
///
///   assert(_debugMenuInfo('Debug Message'));
///
/// so that the call is entirely removed in release builds.
///
/// Enable debug printing by setting [_kDebugMenus] to true at the top of the
/// file.
bool _debugMenuInfo(String message, [Iterable<String>? details]) {
  assert(() {
    if (_kDebugMenus) {
      debugPrint('MENU: $message');
      if (details != null && details.isNotEmpty) {
        for (final String detail in details) {
          debugPrint('    $detail');
        }
      }
    }
    return true;
  }());
  // Return true so that it can be easily used inside of an assert.
  return true;
}

bool _debugPanRegion(String message, [Iterable<String>? details]) {
  if (_kDebugPanRegion) {
    debugPrint('PAN REGION: $message');
    if (details != null && details.isNotEmpty) {
      for (final String detail in details) {
        debugPrint('    $detail');
      }
    }
  }
  // Return true so that it can be easily used inside of an assert.
  return true;
}
