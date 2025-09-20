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

import 'colors.dart';
import 'constants.dart';
import 'dialog.dart';
import 'theme.dart';

const Map<ShortcutActivator, Intent> _kMenuTraversalShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.arrowUp): _FocusUpIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): _FocusDownIntent(),
  SingleActivator(LogicalKeyboardKey.home): _FocusFirstIntent(),
  SingleActivator(LogicalKeyboardKey.end): _FocusLastIntent(),
};

bool get _isCupertino {
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

// The font size at which text scales linearly in a CupertinoMenuItem.
const double _kBaseFontSize = 17.0;

// Returns an integer that represents the current text scale factor normalized
// to the base font size.
//
// On iOS, each "unit" of text scaling adds or removes 1/17th of the base font size.
//
// Examples:
// textScaler.scale(17) = 17 → units = 0.0 (default size)
// textScaler.scale(17) = 19 → units = 2.0 (2 units larger)
// textScaler.scale(17) = 15 → units = -2.0 (2 units smaller)
//
// The returned value is positive when the text scale factor is larger than the
// base font size, negative when smaller, and zero when equal.
//
// Normalizing to the base font size simplifies calculations that depend on
// nonlinear text scaling, such as menu layout.
int _normalizeTextScale(BuildContext context) {
  final TextScaler? textScaler = MediaQuery.maybeTextScalerOf(context);
  if (textScaler == null || textScaler == TextScaler.noScaling) {
    return 0;
  }

  return (textScaler.scale(_kBaseFontSize) - _kBaseFontSize).round();
}

// The CupertinoMenuAnchor layout policy changes depending on whether the user is using
// a "regular" font size vs a "large" font size. This is a spectrum. There are
// many "regular" font sizes and many "large" font sizes. But depending on which
// policy is currently being used, a menu is laid out differently.
//
// Empirically, the jump from one policy to the other occurs at the following text
// scale factors:
// Largest regular scale factor:  1.3529411764705883
// Smallest large scale factor:   1.6470588235294117
//
// The following constant represents a division in text scale factor beyond which
// we want to change how the menu is laid out.
//
// This explanation was ported from CupertinoDialog.
const double _kMaxRegularTextScaleFactor = 1.4;

// Accessibility mode on iOS is determined by the text scale factor that the
// user has selected.
bool _isAccessibilityModeEnabled(BuildContext context) {
  final double scaleFactor = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1;
  return scaleFactor > _kMaxRegularTextScaleFactor;
}

/// Mix [CupertinoMenuEntryMixin] in to define how a menu item should be drawn
/// in a menu.
mixin CupertinoMenuEntryMixin {
  /// Whether this menu item has a leading widget.
  ///
  /// If true, siblings of this menu item that are missing a leading
  /// widget will have leading space added to align the leading edges of all
  /// menu items.
  bool get hasLeading;

  /// Whether a separator can be drawn above this menu item.
  ///
  /// When [allowLeadingSeparator] is true, a separator will be drawn if the
  /// menu item immediately above this item has mixed in
  /// [CupertinoMenuEntryMixin] and has set [allowTrailingSeparator] to true.
  bool get allowLeadingSeparator;

  /// Whether a separator can be drawn below this menu item.
  ///
  /// When [allowTrailingSeparator] is true, a separator will be drawn if the
  /// menu item immediately below this item has mixed in
  /// [CupertinoMenuEntryMixin] and has set [allowLeadingSeparator] to true.
  bool get allowTrailingSeparator;
}

class _AnchorScope extends InheritedWidget {
  const _AnchorScope({required this.hasLeading, required super.child});
  final bool hasLeading;

  @override
  bool updateShouldNotify(_AnchorScope oldWidget) {
    return hasLeading != oldWidget.hasLeading;
  }
}

/// Signature for the callback called in response to a [CupertinoMenuAnchor]
/// changing its [AnimationStatus].
typedef CupertinoMenuStatusChangedCallback = void Function(AnimationStatus status);

/// A widget used to mark the "anchor" for a menu, defining the rectangle used
/// to position the menu, which can be done with an explicit location, or
/// with an alignment.
///
/// The [CupertinoMenuAnchor] is typically used to wrap a button that opens a
/// menu when pressed. The menu position is determined by the [alignment] of the
/// anchor attachment point and the [menuAlignment] of the menu attachment
/// point. The [alignmentOffset] can be used to move the menu position relative
/// to the alignment point. If the menu is opened with an explicit position,
/// then the [alignment] and [alignmentOffset] are ignored.
///
/// The [controller] can be used to open and close the menu from other widgets.
/// The [onOpen] callback is invoked when the menu popup is mounted and the menu
/// status changes from [AnimationStatus.dismissed]. The [onClose] callback is
/// invoked when the menu popup is unmounted and the menu status changes to
/// [AnimationStatus.dismissed]. The [onAnimationStatusChange] callback is
/// invoked when the animation status of the menu changes.
///
/// ## Usage
/// {@tool snippet}
///
/// This sample code shows a [CupertinoMenuAnchor] containing one
/// [CupertinoMenuItem]. The menu item prints `Item 1 pressed!` when pressed.
///
/// ```dart
///  CupertinoMenuAnchor(
///    menuChildren: <Widget>[
///      CupertinoMenuItem(
///        trailing: const Icon(Icons.add),
///        onPressed: () {
///          print('Item 1 pressed!');
///        },
///        child: const Text('Item 1'),
///      )
///    ],
///    builder: (
///      BuildContext context,
///      CupertinoMenuController controller,
///      Widget? child,
///    ) {
///      return CupertinoButton.filled(
///        onPressed: () {
///          if (controller,.
///              case MenuStatus.opening || MenuStatus.opened) {
///            controller.close();
///          } else {
///            controller.open();
///          }
///        },
///        child: const Text('Open'),
///      );
///    },
///  );
/// ```
/// {@end-tool}
///
/// {@tool dartpad}
/// This example demonstrates a basic [CupertinoMenuAnchor] that wraps a button.
///
/// ** See code in examples/api/lib/cupertino/menu_anchor/cupertino_menu_anchor.0.dart **
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
    this.onAnimationStatusChange,
    this.constraints,
    this.menuAlignment,
    this.alignment,
    this.alignmentOffset,
    this.constrainCrossAxis = false,
    this.enablePan = true,
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.semanticLabel,
    this.overlayPadding = const EdgeInsets.all(8),
  });

  /// {@macro flutter.widgets.RawMenuAnchor.useRootOverlay}
  final bool useRootOverlay;

  /// An optional controller that allows opening and closing of the menu from
  /// other widgets.
  final MenuController? controller;

  /// A callback that is invoked when the status of the menu changes.
  ///
  /// Unlike [onOpen] and [onClose], this callback is invoked for all
  /// [AnimationStatus] changes.
  final CupertinoMenuStatusChangedCallback? onAnimationStatusChange;

  /// The [childFocusNode] attribute is the optional [FocusNode] also associated
  /// the [child] or [builder] widget that opens the menu.
  ///
  /// The focus node should be attached to the widget that should receive focus
  /// if keyboard focus traversal moves the focus off of the submenu with the
  /// arrow keys.
  ///
  /// If not supplied, then focus will not traverse from the menu to the
  /// controlling button after the menu opens.
  final FocusNode? childFocusNode;

  /// The offset of the menu relative to the alignment origin determined by
  /// [alignment] and the ambient [Directionality].
  ///
  /// Use this for adjustments of the menu placement.
  ///
  /// Increasing [Offset.dy] values of [alignmentOffset] move the menu position
  /// down.
  ///
  /// If the [alignment] is an [AlignmentDirectional] AND the text direction is
  /// [TextDirection.rtl], a larger [Offset.dx] component of [alignmentOffset]
  /// moves the menu position to the left. Otherwise, a larger [Offset.dx] moves
  /// the menu position to the right.
  ///
  /// This value is ignored if the menu is opened with an explicit position.
  final ui.Offset? alignmentOffset;

  /// Whether or not a tap event that closes the menu will be permitted to
  /// continue on to the gesture arena.
  ///
  /// If false, then tapping outside of a menu when the menu is open will both
  /// close the menu, and allow the tap to participate in the gesture arena. If
  /// true, then it will only close the menu, and the tap event will be
  /// consumed.
  ///
  /// Defaults to false.
  final bool consumeOutsideTaps;

  /// A callback invoked when the menu begins opening.
  final VoidCallback? onOpen;

  /// A callback invoked when the menu has completely closed.
  final VoidCallback? onClose;

  /// A list of menu items to display in the menu.
  final List<Widget> menuChildren;

  /// The widget that this [CupertinoMenuAnchor] surrounds.
  ///
  /// Typically, this is a button that calls [MenuController.open] when pressed.
  ///
  /// If not supplied, then the [CupertinoMenuAnchor] will be the size that its parent
  /// allocates for it.
  final RawMenuAnchorChildBuilder? builder;

  /// An optional child to be passed to the [builder].
  ///
  /// Supply this child if there is a portion of the widget tree built in
  /// [builder] that doesn't depend on the `controller` or `context` supplied to
  /// the [builder]. It will be more efficient, since Flutter doesn't then need
  /// to rebuild this child when those change.
  final Widget? child;

  /// The constraints to apply to the menu scrollable.
  final BoxConstraints? constraints;

  /// Whether the menu's cross axis should be constrained by the overlay.
  ///
  /// If true, when the menu is wider than the overlay, the menu width will
  /// shrink to fit the overlay bounds.
  ///
  /// If false, the menu will grow to fit the size of its contents. If the menu
  /// is wider than the overlay, it will be clipped to the overlay's bounds.
  ///
  /// Defaults to false.
  final bool constrainCrossAxis;

  /// The point on the anchor surface that attaches to the menu.
  ///
  /// This value is ignored if the menu is opened with an explicit position.
  final AlignmentGeometry? alignment;

  /// The point on the menu surface that attaches to the anchor.
  final AlignmentGeometry? menuAlignment;

  /// Whether or not panning is enabled on the menu.
  ///
  /// When panning is enabled, an [ImmediateMultiDragGestureRecognizer] is added
  /// around the menu button and menu items. The
  /// [ImmediateMultiDragGestureRecognizer] allows for users to press, move, and
  /// activate adjacent menu items in a single gesture. Panning also scales the
  /// menu panel when users drag their pointer away from the menu.
  ///
  /// Disabling panning can be useful if the menu pan effects interfere with
  /// another pan gesture, such as in the case of dragging a menu anchor around
  /// the screen.
  ///
  /// Defaults to true.
  final bool enablePan;

  /// A label that can be used by screen readers to describe the menu
  ///
  /// This label should clearly describe the purpose of the menu using
  /// alphanumeric characters. For example, "Language Options" could be used as
  /// a semantic label for a menu that users use to select a language.
  ///
  /// Avoid labels that are generic ("Menu"), technical ("Metric unit selection
  /// apparatus"), redundant ("Action Menu Options"), or verbose ( "Click to
  /// display menu list action items for metric unit selection").
  final String? semanticLabel;

  /// The padding to subtract from the overlay when positioning the menu.
  final EdgeInsetsGeometry overlayPadding;

  static _AnchorScope? _maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AnchorScope>();
  }

  static bool? maybeHasLeadingOf(BuildContext context) {
    return _maybeOf(context)?.hasLeading;
  }

  @override
  State<CupertinoMenuAnchor> createState() => _CupertinoMenuAnchorState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return menuChildren.map<DiagnosticsNode>((Widget child) => child.toDiagnosticsNode()).toList();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('consumeOutsideTap', value: consumeOutsideTaps, ifTrue: 'AUTO-CLOSE'),
    );
    properties.add(DiagnosticsProperty<FocusNode?>('focusNode', childFocusNode));
    properties.add(DiagnosticsProperty<Offset?>('alignmentOffset', alignmentOffset));
    if (constraints != null) {
      properties.add(DiagnosticsProperty<BoxConstraints?>('constraints', constraints));
    }
    if (child != null) {
      properties.add(DiagnosticsProperty<String?>('child', child.toString()));
    }
  }
}

class _CupertinoMenuAnchorState extends State<CupertinoMenuAnchor> with TickerProviderStateMixin {
  /// Approximated using settling duration calculation (see
  /// https://github.com/flutter/flutter/pull/164411#issuecomment-2691969477)
  /// with a settling duration of 500 ms, an initialVelocity of 0.5, and a bounce of 0.2,
  /// then tweaked to match iOS
  static const SpringDescription forwardSpring = SpringDescription(
    mass: 1.0,
    stiffness: 349.1,
    damping: 29.9,
  );

  /// Approximated using settling duration calculation (see
  /// https://github.com/flutter/flutter/pull/164411#issuecomment-2691969477)
  /// with a duration of 500 ms and bounce of 0, then tweaked to match iOS
  static const SpringDescription reverseSpring = SpringDescription(
    mass: 1.0,
    stiffness: 235.1,
    damping: 30.7,
  );
  static const Tolerance springTolerance = Tolerance(velocity: 0.1, distance: 0.1);
  late final AnimationController _animationController;
  final FocusScopeNode menuScopeNode = FocusScopeNode(debugLabel: 'Menu Scope');
  final ValueNotifier<double> _panDistanceNotifier = ValueNotifier<double>(0);
  AnimationStatus _status = AnimationStatus.dismissed;
  bool _hasLeadingWidget = false;
  MenuController get _menuController => widget.controller ?? _internalMenuController!;
  MenuController? _internalMenuController;
  bool get excludeInteraction => !_status.isForwardOrCompleted;
  bool get enablePan =>
      widget.enablePan &&
      switch (_status) {
        AnimationStatus.forward || AnimationStatus.completed || AnimationStatus.dismissed => true,
        AnimationStatus.reverse => false,
      };

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalMenuController = MenuController();
    }

    _animationController = AnimationController.unbounded(vsync: this);
    _animationController.addStatusListener(_handleAnimationStatusChange);
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
      if (widget.controller != null) {
        _internalMenuController = null;
      } else {
        assert(_internalMenuController == null);
        _internalMenuController = MenuController();
      }
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
  }

  @override
  void dispose() {
    _animationController
      ..stop()
      ..dispose();
    _internalMenuController = null;
    _panDistanceNotifier.dispose();
    super.dispose();
  }

  void _handleCloseRequested(VoidCallback hideMenu) {
    if (_status case AnimationStatus.reverse || AnimationStatus.dismissed) {
      return;
    }

    _animationController
        .animateBackWith(
          ClampedSimulation(
            SpringSimulation(
              reverseSpring,
              _animationController.value,
              0.0,
              0.0,
              tolerance: springTolerance,
            ),
            xMin: 0.0,
            xMax: 1.0,
          ),
        )
        .whenComplete(hideMenu);

    widget.childFocusNode?.requestFocus();
  }

  void _handleOpenRequested(ui.Offset? position, VoidCallback showOverlay) {
    showOverlay();
    if (_status case AnimationStatus.completed || AnimationStatus.forward) {
      return;
    }

    _animationController.animateWith(
      SpringSimulation(forwardSpring, _animationController.value, 1, 0.5),
    );
    FocusScope.of(context).setFirstFocus(menuScopeNode);
  }

  void _handleAnimationStatusChange(AnimationStatus status) {
    setState(() {
      _status = status;
    });
    widget.onAnimationStatusChange?.call(status);
  }

  void _handleFocusChange(bool focus) {
    if (focus || menuScopeNode.hasFocus) {
      return;
    }

    _menuController.close();
  }

  void _handlePanChange(double distance) {
    if (!_menuController.isOpen) {
      _menuController.open();
      return;
    }
    // Because we are triggering a nested ticker, it's easiest to pass a
    // listenable down the tree. Otherwise, it would be more idiomatic to use
    // an inherited widget.
    _panDistanceNotifier.value = distance;
  }

  Widget _buildMenuOverlay(BuildContext childContext, RawMenuOverlayInfo info) {
    return IgnorePointer(
      ignoring: excludeInteraction,
      child: BlockSemantics(
        blocking: !excludeInteraction,
        child: _MenuOverlay(
          constrainCrossAxis: widget.constrainCrossAxis,
          visibilityAnimation: _animationController.view,
          panDistanceListenable: _panDistanceNotifier,
          alignmentOffset: widget.alignmentOffset ?? Offset.zero,
          status: _status,
          constraints: widget.constraints,
          consumeOutsideTaps: widget.consumeOutsideTaps,
          alignment: widget.alignment,
          menuAlignment: widget.menuAlignment,
          overlaySize: info.overlaySize,
          anchorRect: info.anchorRect,
          anchorPosition: info.position,
          tapRegionGroupId: info.tapRegionGroupId,
          semanticLabel: widget.semanticLabel,
          focusScopeNode: menuScopeNode,
          overlayInsets: widget.overlayPadding,
          children: widget.menuChildren,
        ),
      ),
    );
  }

  Widget _buildChild(BuildContext context, MenuController controller, Widget? child) {
    // The anchor can initiate a pan gesture, but should not be included in the
    // pan area.
    return _PanSurface(
      includeInPanArea: false,
      child:
          widget.builder?.call(context, _menuController, widget.child) ??
          widget.child ??
          const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PanRegion(
      onPanDistanceChanged: _handlePanChange,
      enabled: enablePan,
      child: Focus(
        includeSemantics: false,
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: _handleFocusChange,
        child: _AnchorScope(
          hasLeading: _hasLeadingWidget,
          child: RawMenuAnchor(
            useRootOverlay: widget.useRootOverlay,
            onCloseRequested: _handleCloseRequested,
            onOpenRequested: _handleOpenRequested,
            overlayBuilder: _buildMenuOverlay,
            builder: _buildChild,
            controller: _menuController,
            childFocusNode: widget.childFocusNode,
            consumeOutsideTaps: widget.consumeOutsideTaps,
            onClose: widget.onClose,
            onOpen: widget.onOpen,
          ),
        ),
      ),
    );
  }
}

// TODO(davidhicks980): Remove _resolveMotion() when AnimationBehavior accommodates reduced motion.
// (https://github.com/flutter/flutter/issues/173461)
enum _CompatAnimationBehavior {
  /// All animations are played as normal, with no reduction in motion.
  normal,

  /// Corresponds to ui.AccessibilityFeatures.reduceMotion
  reduced,

  /// Corresponds to ui.AccessibilityFeatures.disableAnimations
  none,
}

class _MenuOverlay extends StatefulWidget {
  const _MenuOverlay({
    required this.children,
    required this.focusScopeNode,
    required this.semanticLabel,
    required this.consumeOutsideTaps,
    required this.constrainCrossAxis,
    required this.constraints,
    required this.overlaySize,
    required this.overlayInsets,
    required this.anchorRect,
    required this.anchorPosition,
    required this.tapRegionGroupId,
    required this.alignmentOffset,
    required this.alignment,
    required this.menuAlignment,
    required this.status,
    required this.visibilityAnimation,
    required this.panDistanceListenable,
  });

  final List<Widget> children;
  final FocusScopeNode focusScopeNode;
  final String? semanticLabel;
  final bool consumeOutsideTaps;
  final bool constrainCrossAxis;
  final BoxConstraints? constraints;
  final Size overlaySize;
  final EdgeInsetsGeometry overlayInsets;
  final Rect anchorRect;
  final Offset? anchorPosition;
  final Object tapRegionGroupId;
  final Offset alignmentOffset;
  final AlignmentGeometry? alignment;
  final AlignmentGeometry? menuAlignment;
  final AnimationStatus status;
  final Animation<double> visibilityAnimation;
  final ValueListenable<double> panDistanceListenable;

  @override
  State<_MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<_MenuOverlay>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const double _defaultMenuWidth = 250;
  static const double _accessibleMenuWidth = 343;

  static final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    _FocusDownIntent: _FocusDownAction(),
    _FocusUpIntent: _FocusUpAction(),
    _FocusFirstIntent: _FocusFirstAction(),
    _FocusLastIntent: _FocusLastAction(),
  };
  late final AnimationController _panAnimationController;
  late final ProxyAnimation _scaleAnimation = ProxyAnimation(kAlwaysCompleteAnimation);
  final ProxyAnimation _fadeAnimation = ProxyAnimation(kAlwaysCompleteAnimation);
  final ProxyAnimation _sizeAnimation = ProxyAnimation(kAlwaysCompleteAnimation);
  late Alignment _attachmentPointAlignment;
  late ui.Offset _attachmentPoint;
  late Alignment _menuAlignment;
  List<Widget> _children = <Widget>[];
  _CompatAnimationBehavior? _animationBehavior;
  ui.TextDirection? _textDirection;

  // The actual distance the user has panned away from the menu.
  double _panTargetDistance = 0;

  // The effective distance the user has panned away from the menu, after
  // applying velocity and deceleration.
  double _panCurrentDistance = 0;

  // The accumulated velocity of the pan gesture, used to determine how fast
  // the menu scales to _panTargetDistance
  double _panVelocity = 0;

  // A ticker used to drive the pan animation.
  Ticker? _panTicker;

  bool get _excludeInteraction => !widget.status.isForwardOrCompleted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _panAnimationController = AnimationController.unbounded(value: 1, vsync: this);
    widget.panDistanceListenable.addListener(_handlePanDistanceChanged);
    _resolveChildren();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ui.TextDirection newTextDirection = Directionality.of(context);
    if (_textDirection != newTextDirection) {
      _textDirection = newTextDirection;
      _resolveLayout();
    }

    _resolveMotion();
  }

  @override
  void didUpdateWidget(covariant _MenuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.panDistanceListenable != widget.panDistanceListenable) {
      oldWidget.panDistanceListenable.removeListener(_handlePanDistanceChanged);
      widget.panDistanceListenable.addListener(_handlePanDistanceChanged);
    }

    if (oldWidget.visibilityAnimation != widget.visibilityAnimation) {
      _resolveMotion();
    }

    if (oldWidget.anchorRect != widget.anchorRect ||
        oldWidget.anchorPosition != widget.anchorPosition ||
        oldWidget.alignmentOffset != widget.alignmentOffset ||
        oldWidget.alignment != widget.alignment ||
        oldWidget.menuAlignment != widget.menuAlignment ||
        oldWidget.overlaySize != widget.overlaySize) {
      _resolveLayout();
    }

    if (oldWidget.children != widget.children) {
      _resolveChildren();
    }
  }

  @override
  void didChangeAccessibilityFeatures() {
    super.didChangeAccessibilityFeatures();
    _resolveMotion();
  }

  @override
  void dispose() {
    widget.panDistanceListenable.removeListener(_handlePanDistanceChanged);
    _panTicker
      ?..stop()
      ..dispose();
    _panAnimationController
      ..stop()
      ..dispose();
    _scaleAnimation.parent = null;
    _fadeAnimation.parent = null;
    _sizeAnimation.parent = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _resolveChildren() {
    _children = <Widget>[];
    Widget child = widget.children.first;
    for (int i = 0; i < widget.children.length; i++) {
      _children.add(child);
      if (child == widget.children.last) {
        break;
      }

      if (child case CupertinoMenuEntryMixin(allowLeadingSeparator: false)) {
        continue;
      }

      child = widget.children[i + 1];
      if (child case CupertinoMenuEntryMixin(allowTrailingSeparator: false)) {
        continue;
      }

      _children.add(const _CupertinoMenuDivider());
    }
  }

  void _resolveMotion() {
    // Behavior of reduce motion is based on iOS 18.5 simulator. Behavior of
    // disable animations could not be determined, so all animations are disabled.
    final ui.AccessibilityFeatures accessibilityFeatures =
        View.of(context).platformDispatcher.accessibilityFeatures;

    final _CompatAnimationBehavior newAnimationBehavior = switch (accessibilityFeatures) {
      ui.AccessibilityFeatures(disableAnimations: true) => _CompatAnimationBehavior.none,
      ui.AccessibilityFeatures(reduceMotion: true) => _CompatAnimationBehavior.reduced,
      _ => _CompatAnimationBehavior.normal,
    };

    if (_animationBehavior == newAnimationBehavior) {
      return;
    }

    _animationBehavior = newAnimationBehavior;
    switch (_animationBehavior!) {
      case _CompatAnimationBehavior.normal:
        _scaleAnimation.parent = _AnimationProduct(
          first: widget.visibilityAnimation,
          next: _panAnimationController.view.drive(Tween<double>(begin: 0.8, end: 1)),
        );
        _sizeAnimation.parent = widget.visibilityAnimation.drive(Tween<double>(begin: 0.8, end: 1));
        _fadeAnimation.parent = widget.visibilityAnimation.drive(
          CurveTween(curve: Curves.easeIn).chain(const _ClampTween(begin: 0, end: 1)),
        );

      case _CompatAnimationBehavior.reduced:
        // Pan scaling works with reduced motion.
        _scaleAnimation.parent = _panAnimationController.view.drive(
          Tween<double>(begin: 0.8, end: 1),
        );
        _sizeAnimation.parent = kAlwaysCompleteAnimation;
        _fadeAnimation.parent = widget.visibilityAnimation.drive(
          CurveTween(curve: Curves.easeIn).chain(const _ClampTween(begin: 0, end: 1)),
        );

      case _CompatAnimationBehavior.none:
        _scaleAnimation.parent = kAlwaysCompleteAnimation;
        _fadeAnimation.parent = kAlwaysCompleteAnimation;
        _sizeAnimation.parent = kAlwaysCompleteAnimation;
    }
  }

  // Position was determined using iOS 18.5 simulator (phone + tablet).
  //
  // Layout needs to be resolved outside of the layout delegate because the
  // ScaleTransition widget is dependent on the attachment point alignment.
  void _resolveLayout() {
    final ui.Offset anchorMidpoint;
    if (widget.anchorPosition != null) {
      anchorMidpoint = widget.anchorRect.topLeft + widget.anchorPosition!;
    } else {
      anchorMidpoint = widget.anchorRect.center;
    }

    final double xMidpointRatio = anchorMidpoint.dx / widget.overlaySize.width;
    final double yMidpointRatio = anchorMidpoint.dy / widget.overlaySize.height;
    final double defaultVerticalAlignment = yMidpointRatio < 0.5 ? 1 : -1;
    final double defaultHorizontalAlignment = switch (xMidpointRatio) {
      < 0.4 => -1.0, // Left
      > 0.6 => 1.0, // Right
      _ => 0.0, // Center
    };

    _menuAlignment =
        widget.menuAlignment?.resolve(_textDirection) ??
        Alignment(defaultHorizontalAlignment, -defaultVerticalAlignment);

    _attachmentPoint = widget.anchorRect.topLeft;
    if (widget.anchorPosition != null) {
      // If an anchorPosition is provided, then the alignment and the
      // alignmentOffset are ignored. The anchorPosition already provides the
      // exact point on the anchor surface that attaches to the menu, so no
      // further adjustment is needed.
      _attachmentPoint += widget.anchorPosition!;
    } else {
      final Alignment anchorAlignment =
          widget.alignment?.resolve(_textDirection) ??
          Alignment(defaultHorizontalAlignment, defaultVerticalAlignment);

      _attachmentPoint += anchorAlignment.alongSize(widget.anchorRect.size);
      if (widget.alignment is AlignmentDirectional) {
        _attachmentPoint += switch (_textDirection!) {
          ui.TextDirection.ltr => widget.alignmentOffset,
          ui.TextDirection.rtl => Offset(-widget.alignmentOffset.dx, widget.alignmentOffset.dy),
        };
      } else {
        _attachmentPoint += widget.alignmentOffset;
      }
    }

    final double yAttachmentPointRatio = _attachmentPoint.dy / widget.overlaySize.height;
    // The alignment of the menu growth point relative to the screen.
    _attachmentPointAlignment = Alignment(xMidpointRatio * 2 - 1, yAttachmentPointRatio * 2 - 1);
  }

  void _handleOutsideTap(PointerDownEvent event) {
    MenuController.maybeOf(context)!.close();
  }

  void _handlePanDistanceChanged() {
    _panTargetDistance = ui.clampDouble(widget.panDistanceListenable.value, 0, 150);
    if (_panCurrentDistance == _panTargetDistance) {
      return;
    }

    _panTicker ??= createTicker(_updatePanScale);
    if (!_panTicker!.isActive) {
      _panTicker!.start();
    }
  }

  // The menu will scale between 80% and 100% of its size based on the distance
  // the user has dragged their pointer away from the menu edges.
  void _updatePanScale(Duration elapsed) {
    const double maxVelocity = 20.0;
    const double minVelocity = 8;
    const double maxPanDistance = 150;
    const double accelerationRate = 0.12;

    // The distance below which velocity begins to decelerate.
    //
    // When the pan distance to target is less than this value, the animation
    // velocity reduces proportionally to create smooth arrival at the target.
    // Higher values mean the animation begins to decelerate sooner, resulting to
    // a smoother animation curve.
    const double decelerationDistanceThreshold = 40;

    // The distance at which the animation will snap to the target distance without
    // any animation.
    const double remainingDistanceSnapThreshold = 1.0;

    // When the user's pointer is within this distance of the menu edges, the
    // pan animation will terminate.
    const double terminationDistanceThreshold = 5.0;

    final double distance = _panTargetDistance - _panCurrentDistance;
    final double absoluteDistance = distance.abs();

    // As the distance between the current position and the target position increases,
    // the proximity factor approaches 1.0, which increases acceleration.
    //
    // Conversely, as the current position nears the target within the deceleration
    // zone, the proximity factor approaches 0.0, which decreases acceleration
    // and smoothes the end of the animation.
    final double proximityFactor = math.min(absoluteDistance / decelerationDistanceThreshold, 1.0);

    _panVelocity += accelerationRate * proximityFactor;
    _panVelocity = ui.clampDouble(_panVelocity, minVelocity, maxVelocity);

    final double finalVelocity = _panVelocity * proximityFactor;
    final double distanceReduction = distance.sign * finalVelocity;
    _panCurrentDistance += distanceReduction;

    if (absoluteDistance < remainingDistanceSnapThreshold) {
      _panCurrentDistance = _panTargetDistance;
      _panVelocity = 0;
      if (_panTargetDistance < terminationDistanceThreshold) {
        _panTicker!.stop();
      }
    }

    _panAnimationController.value = 1 - _panCurrentDistance / maxPanDistance;
  }

  // Avoid using a SizeTransition since CupertinoPopupSurface already clips its child.
  Widget _buildAlignTransition(BuildContext context, Widget? child) {
    return Align(
      heightFactor: _sizeAnimation.value,
      widthFactor: 1,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final BoxConstraints constraints =
        widget.constraints ??
        (_isAccessibilityModeEnabled(context)
            ? const BoxConstraints.tightFor(width: _accessibleMenuWidth)
            : const BoxConstraints.tightFor(width: _defaultMenuWidth));
    Widget child = ConstrainedBox(
      constraints: constraints,
      child: _PanSurface(
        includeInPanArea: true,
        child: Actions(
          actions: _actions,
          child: Shortcuts(
            shortcuts: _kMenuTraversalShortcuts,
            child: FocusScope(
              node: widget.focusScopeNode,
              descendantsAreFocusable: true,
              descendantsAreTraversable: true,
              canRequestFocus: true,
              child: TapRegion(
                groupId: widget.tapRegionGroupId,
                consumeOutsideTaps: widget.consumeOutsideTaps,
                onTapOutside: _handleOutsideTap,
                // A custom shadow painter is used to make the underlying colors
                // appear more vibrant. This is achieved by removing the shadow
                // underlying the popup surface using a save layer combined with a
                // clear blend mode.
                //
                // From my (davidhicks980) understanding and testing, it is
                // impossible to achieve the appearance of an iOS backdrop using
                // only guassian blur, linear color filter, and shadows, because the
                // iOS popup surface does not linearly transform underlying colors.
                // A custom shader would need to be used to achieve the same effect.
                // Please correct me if I am wrong.
                child: CustomPaint(
                  painter: _ShadowPainter(
                    radius: const Radius.circular(13),
                    brightness: CupertinoTheme.brightnessOf(context),
                    repaint: _fadeAnimation,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: CupertinoPopupSurface(
                      // The FadeTransition widget needs to wrap Semantics so that
                      // the semantics widget senses that the menu is the same
                      // opacity as the menu items. Otherwise, "a menu cannot be
                      // empty" is thrown due to the menu items being transparent
                      // while the menu semantics are still present.
                      child: Semantics.fromProperties(
                        explicitChildNodes: true,
                        excludeSemantics: _excludeInteraction,
                        properties: SemanticsProperties(
                          role: _excludeInteraction ? null : SemanticsRole.menu,
                          scopesRoute: true,
                          namesRoute: true,
                          label: widget.semanticLabel,
                        ),
                        child: AnimatedBuilder(
                          animation: _sizeAnimation,
                          builder: _buildAlignTransition,
                          child: SingleChildScrollView(
                            clipBehavior: Clip.none,
                            child: Column(children: _children),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // The menu content can grow beyond the size of the overlay, but will be
    // clipped by the overlay's bounds.
    if (!widget.constrainCrossAxis) {
      child = UnconstrainedBox(
        clipBehavior: Clip.hardEdge,
        alignment: AlignmentDirectional.centerStart,
        constrainedAxis: Axis.vertical,
        child: child,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints.loose(widget.overlaySize),
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: _attachmentPointAlignment,
        child: Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQuery = MediaQuery.of(context);
            return CustomSingleChildLayout(
              delegate: _MenuLayoutDelegate(
                isPositioned: widget.anchorPosition != null,
                constrainCrossAxis: widget.constrainCrossAxis,
                padding: mediaQuery.padding + widget.overlayInsets.resolve(_textDirection),
                avoidBounds: DisplayFeatureSubScreen.avoidBounds(mediaQuery).toSet(),
                anchorRect: widget.anchorRect,
                attachmentPoint: _attachmentPoint,
                menuAlignment: _menuAlignment,
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter({required this.radius, required this.brightness, required this.repaint})
    : super(repaint: repaint);

  double get shadowOpacity => ui.clampDouble(repaint.value, 0, 1);
  final Animation<double> repaint;
  final Radius radius;
  final ui.Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    assert(shadowOpacity >= 0 && shadowOpacity <= 1);
    final Offset center = Offset(size.width / 2, size.height / 2);
    final ui.RSuperellipse menuRect = RSuperellipse.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width, height: size.height),
      radius,
    );
    final Paint shadowPaint =
        Paint()
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowOpacity * 50)
          ..color = ui.Color.fromRGBO(0, 0, 10, shadowOpacity * shadowOpacity * 0.24);
    final ui.Paint clearPaint = Paint()..blendMode = BlendMode.clear;

    canvas
      ..saveLayer(Rect.largest, Paint())
      ..drawRSuperellipse(menuRect.inflate(50), shadowPaint)
      ..drawRSuperellipse(menuRect, clearPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.brightness != brightness ||
      oldDelegate.repaint != repaint;

  @override
  bool shouldRebuildSemantics(_ShadowPainter oldDelegate) => false;
}

class _MenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _MenuLayoutDelegate({
    required this.anchorRect,
    required this.attachmentPoint,
    required this.avoidBounds,
    required this.padding,
    required this.menuAlignment,
    required this.constrainCrossAxis,
    required this.isPositioned,
  });

  // Rectangle anchoring the menu
  final ui.Rect anchorRect;

  // The offset of the menu from the top-left corner of the overlay.
  final ui.Offset attachmentPoint;

  // List of rectangles that the menu should not overlap. Unusable screen area.
  final Set<Rect> avoidBounds;

  // Whether an explicit position was provided when opening the menu.
  final bool isPositioned;

  // Whether to constrain the menu surface to the cross axis.
  final bool constrainCrossAxis;

  // The resolved alignment of the menu attachment point relative to the menu surface.
  final Alignment menuAlignment;

  // Unsafe bounds used when constraining and positioning the menu.
  //
  // Used to prevent the menu from being obstructed by system UI.
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay minus padding.
    return BoxConstraints.loose(constraints.biggest).deflate(padding);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final ui.Offset position = attachmentPoint - menuAlignment.alongSize(childSize);
    final ui.Rect anchor = isPositioned ? attachmentPoint & Size.zero : anchorRect;
    final Rect screen = _findClosestScreen(size, anchor.center, avoidBounds);
    return _fitInsideScreen(padding.deflateRect(screen), childSize, position, anchor);
  }

  // Finds the closest screen to the anchor point.
  Rect _findClosestScreen(Size parentSize, Offset point, Set<Rect> avoidBounds) {
    final Iterable<ui.Rect> screens = DisplayFeatureSubScreen.subScreensInBounds(
      Offset.zero & parentSize,
      avoidBounds,
    );

    Rect closest = screens.first;
    for (final ui.Rect screen in screens.skip(1)) {
      if ((screen.center - point).distanceSquared < (closest.center - point).distanceSquared) {
        closest = screen;
      }
    }

    return closest;
  }

  Offset _fitInsideScreen(Rect screen, Size childSize, Offset position, ui.Rect anchor) {
    double x = position.dx;
    double y = position.dy;

    bool overLeftEdge(double x) => x < screen.left;
    bool overRightEdge(double x) => x > screen.right - childSize.width;
    bool overTopEdge(double y) => y < screen.top;
    bool overBottomEdge(double y) => y > screen.bottom - childSize.height;

    // Layout horizontally first to determine if the menu can be placed on
    // either side of the anchor without overlapping.
    final bool hasHorizontalAnchorOverlap = childSize.width >= screen.width;
    if (hasHorizontalAnchorOverlap || overLeftEdge(x)) {
      x = screen.left;
    } else if (overRightEdge(x)) {
      x = screen.right - childSize.width;
    }

    if (childSize.height >= screen.height) {
      // Menu is too big to fit on screen. Fit as much as possible.
      return Offset(x, screen.top);
    }

    // Behavior in this scenario could not be determined on iOS 18.5
    // simulator, so this logic is based on what seems most reasonable.
    if (hasHorizontalAnchorOverlap && !anchor.isEmpty) {
      // If both horizontal screen edges overlap, shift the menu upwards or
      // downwards by the minimum amount needed to avoid overlapping the anchor.
      //
      // NOTE: Menus that are deliberately overlapping the anchor will stop
      // overlapping the anchor, but only when the screen's width is smaller
      // than the menu's width.
      final double below = anchor.bottom - y;
      final double above = y + childSize.height - anchor.top;
      if (below > 0 && above > 0) {
        if (below > above) {
          y = anchor.top - childSize.height;
        } else {
          y = anchor.bottom;
        }
      }
    }

    if (overTopEdge(y)) {
      // Flip the Y position across the vertical midpoint of the anchor so that the menu is below the anchor.
      final double flipY = anchor.center.dy * 2 - position.dy - childSize.height;
      if (overTopEdge(flipY) || overBottomEdge(flipY)) {
        y = screen.top;
      } else {
        y = flipY;
      }
    } else if (overBottomEdge(y)) {
      // Flip the Y position across the vertical midpoint of the anchor so that
      // the menu is above the anchor.
      final double flipY = anchor.center.dy * 2 - position.dy - childSize.height;
      if (overTopEdge(flipY) || overBottomEdge(flipY)) {
        y = screen.bottom - childSize.height;
      } else {
        y = flipY;
      }
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayoutDelegate oldDelegate) {
    return menuAlignment != oldDelegate.menuAlignment ||
        isPositioned != oldDelegate.isPositioned ||
        attachmentPoint != oldDelegate.attachmentPoint ||
        anchorRect != oldDelegate.anchorRect ||
        constrainCrossAxis != oldDelegate.constrainCrossAxis ||
        padding != oldDelegate.padding ||
        anchorRect != oldDelegate.anchorRect ||
        !setEquals(avoidBounds, oldDelegate.avoidBounds);
  }
}

class _FocusUpIntent extends DirectionalFocusIntent {
  const _FocusUpIntent() : super(TraversalDirection.up);
}

class _FocusDownIntent extends DirectionalFocusIntent {
  const _FocusDownIntent() : super(TraversalDirection.down);
}

class _FocusUpAction extends ContextAction<DirectionalFocusIntent> {
  _FocusUpAction();

  @override
  void invoke(DirectionalFocusIntent intent, [BuildContext? context]) {
    final FocusTraversalPolicy policy =
        FocusTraversalGroup.maybeOf(context!) ?? ReadingOrderTraversalPolicy();
    if (_isCupertino && !kIsWeb) {
      // Don't wrap on iOS or MacOS.
      policy.inDirection(primaryFocus!, intent.direction);
      return;
    }

    final FocusNode? firstFocus = policy.findFirstFocus(primaryFocus!, ignoreCurrentFocus: true);
    final FocusNode lastFocus = policy.findLastFocus(primaryFocus!, ignoreCurrentFocus: true);
    if (lastFocus.context != null) {
      if (primaryFocus == lastFocus.enclosingScope || primaryFocus == firstFocus) {
        policy.requestFocusCallback(lastFocus);
        return;
      }
    }

    policy.inDirection(primaryFocus!, intent.direction);
  }
}

class _FocusDownAction extends ContextAction<DirectionalFocusIntent> {
  _FocusDownAction();

  @override
  void invoke(DirectionalFocusIntent intent, [BuildContext? context]) {
    final FocusTraversalPolicy policy =
        FocusTraversalGroup.maybeOf(context!) ?? ReadingOrderTraversalPolicy();
    if (_isCupertino && !kIsWeb) {
      // Don't wrap on iOS or MacOS.
      policy.inDirection(primaryFocus!, intent.direction);
      return;
    }

    final FocusNode? firstFocus = policy.findFirstFocus(primaryFocus!, ignoreCurrentFocus: true);
    final FocusNode lastFocus = policy.findLastFocus(primaryFocus!, ignoreCurrentFocus: true);
    if (firstFocus?.context != null) {
      if (primaryFocus == firstFocus!.enclosingScope || primaryFocus == lastFocus) {
        policy.requestFocusCallback(firstFocus);
        return;
      }
    }

    policy.inDirection(primaryFocus!, intent.direction);
  }
}

class _FocusFirstIntent extends Intent {
  const _FocusFirstIntent();
}

class _FocusFirstAction extends ContextAction<_FocusFirstIntent> {
  _FocusFirstAction();

  @override
  void invoke(_FocusFirstIntent intent, [BuildContext? context]) {
    final FocusTraversalPolicy policy =
        FocusTraversalGroup.maybeOf(context!) ?? ReadingOrderTraversalPolicy();
    final FocusNode? firstFocus = policy.findFirstFocus(primaryFocus!, ignoreCurrentFocus: true);
    if (firstFocus == null || firstFocus.context == null) {
      return;
    }
    policy.requestFocusCallback(firstFocus);
  }
}

class _FocusLastIntent extends Intent {
  const _FocusLastIntent();
}

class _FocusLastAction extends ContextAction<_FocusLastIntent> {
  _FocusLastAction();

  @override
  void invoke(_FocusLastIntent intent, [BuildContext? context]) {
    final FocusTraversalPolicy policy =
        FocusTraversalGroup.maybeOf(context!) ?? ReadingOrderTraversalPolicy();
    final FocusNode lastFocus = policy.findLastFocus(primaryFocus!, ignoreCurrentFocus: true);
    if (lastFocus.context == null) {
      return;
    }
    policy.requestFocusCallback(lastFocus);
  }
}

/// A horizontal divider used to separate [CupertinoMenuItem]s
///
/// The default thickess of the divider is 1 physical pixel.
///
// This is class may be made public in the future, but is currently private to
// avoid API churn.
class _CupertinoMenuDivider extends StatelessWidget {
  /// Draws a [_CupertinoMenuDivider] below a [child].
  const _CupertinoMenuDivider();

  /// The default color applied to the [_CupertinoMenuDivider] with
  /// [ui.BlendMode.overlay].
  ///
  /// On all platforms except web, this color is applied to the divider before
  /// the [color] is applied, and is used to give the appearance of the divider
  /// cutting into the background.
  // The following colors were measured from the iOS 17.2 simulator, and opacity was
  // extrapolated:
  // Dark mode on black       Color.fromRGBO(97, 97, 97)
  // Dark mode on white       Color.fromRGBO(132, 132, 132)
  // Light mode on black      Color.fromRGBO(147, 147, 147)
  // Light mode on white      Color.fromRGBO(187, 187, 187)
  //
  // Colors were also compared atop a red, green, and blue backgrounds.
  static const CupertinoDynamicColor overlayColor = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(140, 140, 140, 0.5),
    darkColor: Color.fromRGBO(255, 255, 255, 0.25),
  );

  /// The default color applied to the [_CupertinoMenuDivider], atop the
  /// [overlayColor], with [BlendMode.srcOver].
  ///
  /// This color is used to make the divider more opaque.
  static const CupertinoDynamicColor color = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0.24),
    darkColor: Color.fromRGBO(255, 255, 255, 0.10),
  );

  @override
  Widget build(BuildContext context) {
    final double pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final double displacement = 1 / pixelRatio;
    return CustomPaint(
      size: Size(double.infinity, displacement),
      painter: _AliasedLinePainter(
        overlayColor: CupertinoDynamicColor.resolve(overlayColor, context),
        border: BorderSide(width: 0.0, color: CupertinoDynamicColor.resolve(color, context)),
        // Only anti-alias on devices with a low pixel density.
        antiAlias: pixelRatio < 1.0,
      ),
    );
  }
}

// Draws an aliased line that approximates the appearance of an iOS 18.5 menu
// divider using blend modes.
class _AliasedLinePainter extends CustomPainter {
  const _AliasedLinePainter({
    required this.border,
    required this.overlayColor,
    this.antiAlias = false,
  });

  final BorderSide border;
  final Color overlayColor;
  final bool antiAlias;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset p1 = size.bottomLeft(Offset.zero);
    final Offset p2 = size.bottomRight(Offset.zero);

    // BlendMode.overlay is not supported on the web.
    if (!kIsWeb) {
      final Paint overlayPainter =
          border.toPaint()
            ..color = overlayColor
            ..isAntiAlias = antiAlias
            ..blendMode = BlendMode.overlay;
      canvas.drawLine(p1, p2, overlayPainter);
    }

    final Paint colorPainter = border.toPaint()..isAntiAlias = antiAlias;
    canvas.drawLine(p1, p2, colorPainter);
  }

  @override
  bool shouldRepaint(_AliasedLinePainter oldDelegate) {
    return border != oldDelegate.border ||
        antiAlias != oldDelegate.antiAlias ||
        overlayColor != oldDelegate.overlayColor;
  }
}

/// A menu item for use in a [CupertinoMenuAnchor].
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
///        trailing: const Icon(Icons.add),
///        onPressed: () {
///          print('Item 1 pressed!');
///        },
///        child: const Text('Item 1'),
///      )
///    ],
///    builder: (
///      BuildContext context,
///      CupertinoMenuController controller,
///      Widget? child,
///    ) {
///      return CupertinoButton.filled(
///        onPressed: () {
///          if (controller.menuStatus
///              case MenuStatus.opening || MenuStatus.opened) {
///            controller.close();
///          } else {
///            controller.open();
///          }
///        },
///        child: const Text('Open'),
///      );
///    },
///  );
/// ```
/// {@end-tool}
///
/// ## Layout
/// The menu item is unconstrained by default and will grow to fit the size of
/// its container. To constrain the size of a [CupertinoMenuItem], the
/// [constraints] parameter can be set. When set, the [constraints] are applied
/// **above** [padding]. This means that [padding] will only affect the size of
/// this menu item if this item's minimum constraints are less than the sum of
/// its [padding] and the size of its contents.
///
/// The [leading] and [trailing] widgets display before and after the [child]
/// widget, respectively. The [leadingWidth] and [trailingWidth] parameters
/// control the horizontal space that these widgets occupy. The
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
/// close when an item is pressed.
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
/// The [decoration] parameter can be used to change the background color of the
/// menu item when hovered, focused, pressed, or panned. If these parameters are
/// not set, the menu item will use [CupertinoMenuItem.defaultDecoration].
///
/// The [isDestructiveAction] parameter should be set to true if the menu item
/// will perform a destructive action, and will color the text of the menu item
/// [CupertinoColors.systemRed].
///
/// {@tool dartpad}
/// This example shows basic usage of a [CupertinoMenuItem] that wraps a button.
///
/// ** See code in examples/api/lib/cupertino/menu_anchor/cupertino_menu_anchor.0.dart **
/// {@end-tool}
///
/// See also:
/// * [CupertinoMenuAnchor], a Cupertino-style widget that shows a menu of
///   actions in a popup
/// * [RawMenuAnchor], a lower-level widget that creates a region with a submenu
///   that is the basis for [CupertinoMenuAnchor].
/// * [PlatformMenuBar], which creates a menu bar that is rendered by the host
///   platform instead of by Flutter (on macOS, for example).
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
    this.decoration,
    this.mouseCursor,
    this.panActivationDelay,
    this.statesController,
    this.behavior = HitTestBehavior.opaque,
    this.applyInsetScaling = true,
    this.requestCloseOnActivate = true,
    this.requestFocusOnHover = true,
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

  /// The widget shown before the label; typically a [CupertinoIcons].
  final Widget? leading;

  /// The widget shown after the label; typically a [CupertinoIcons].
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
  /// Defaults to true.
  final bool requestFocusOnHover;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// The delay between a user's pointer entering a menu item during a pan and
  /// the menu item being tapped.
  ///
  /// Defaults to null, meaning the menu item will not activate when panned
  /// over.
  final Duration? panActivationDelay;

  /// The decoration to paint behind the menu item.
  ///
  /// If null, defaults to [CupertinoMenuItem.defaultDecoration].
  final WidgetStateProperty<BoxDecoration>? decoration;

  /// The mouse cursor to display on hover.
  final WidgetStateProperty<MouseCursor>? mouseCursor;

  /// The [WidgetStatesController] that controls the state of this menu item.
  final WidgetStatesController? statesController;

  /// How the menu item should respond to hit tests.
  final HitTestBehavior behavior;

  /// Determines if the menu will be closed when a [CupertinoMenuItem] is pressed.
  /// Defaults to true.
  final bool requestCloseOnActivate;

  /// Whether pressing this item will perform a destructive action
  ///
  /// Defaults to false. If true, the default color of this item's label and
  /// icon will be [CupertinoColors.systemRed].
  final bool isDestructiveAction;

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

  /// Whether the insets of the menu item should scale with
  /// [MediaQuery.textScalerOf].
  ///
  /// Defaults to true.
  final bool applyInsetScaling;

  /// Whether the menu item will respond to user input.
  bool get enabled => onPressed != null;

  @override
  bool get hasLeading => leading != null;

  @override
  bool get allowLeadingSeparator => true;

  @override
  bool get allowTrailingSeparator => true;

  /// The [BoxConstraints] to apply to the menu item.
  ///
  /// Because [padding] is applied to the menu item prior to [constraints], [padding]
  /// will only affect the size of the menu item if the vertical [padding]
  /// plus the height of the menu item's children exceeds the
  /// [BoxConstraints.minHeight].
  final BoxConstraints? constraints;

  /// The default [MouseCursor] for a [CupertinoMenuItem].
  // Obtained from
  static final WidgetStateProperty<MouseCursor> defaultCursor =
      WidgetStateProperty.resolveWith<MouseCursor>((Set<WidgetState> states) {
        return !states.contains(WidgetState.disabled) && kIsWeb
            ? SystemMouseCursors.click
            : MouseCursor.defer;
      });

  /// The default [TextStyle] applied to the [child] widget.
  // Color and size were obtained from the iOS 18.5 simulator.
  static const TextStyle defaultTitleStyle = TextStyle(
    fontSize: 17,
    letterSpacing: -0.41,
    color: CupertinoDynamicColor.withBrightness(
      color: Color.from(alpha: 0.96, red: 0, green: 0, blue: 0),
      darkColor: Color.from(alpha: 0.96, red: 255, green: 255, blue: 255),
    ),
  );

  // Obtained from the iOS 18.5 simulator.
  static const double _defaultSubtitleFontSize = 15.0;

  /// The default [TextStyle] applied to the [subtitle] widget.
  // A custom blend mode is applied to the subtitle to mimick the visual effect of
  // the iOS menu subtitle. As a result, the defaultSubtitleStyle color does not match the
  // reported color on the iOS 18.5 simulator.
  static const TextStyle defaultSubtitleStyle = TextStyle(
    fontSize: _defaultSubtitleFontSize,
    letterSpacing: -0.21,
    color: CupertinoDynamicColor.withBrightnessAndContrast(
      color: Color.from(alpha: 0.4, red: 0, green: 0, blue: 0),
      darkColor: Color.from(alpha: 0.4, red: 1, green: 1, blue: 1),
      highContrastColor: Color.from(alpha: 0.8, red: 0, green: 0, blue: 0),
      darkHighContrastColor: Color.from(alpha: 0.8, red: 1, green: 1, blue: 1),
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
  //
  // Blend mode is used to mimick the visual effect of the iOS
  // menu item. As a result, the default pressed color does not match the
  // reported colors on the iOS 18.5 simulator.
  static const WidgetStateProperty<BoxDecoration> defaultDecoration =
      WidgetStateProperty<BoxDecoration>.fromMap(<WidgetStatesConstraint, BoxDecoration>{
        WidgetState.dragged: BoxDecoration(
          color: CupertinoDynamicColor.withBrightnessAndContrast(
            color: Color.fromRGBO(50, 50, 50, 0.1),
            darkColor: Color.fromRGBO(255, 255, 255, 0.1),
            highContrastColor: Color.fromRGBO(50, 50, 50, 0.2),
            darkHighContrastColor: Color.fromRGBO(255, 255, 255, 0.2),
          ),
        ),
        WidgetState.pressed: BoxDecoration(
          color: CupertinoDynamicColor.withBrightnessAndContrast(
            color: Color.fromRGBO(50, 50, 50, 0.1),
            darkColor: Color.fromRGBO(255, 255, 255, 0.1),
            highContrastColor: Color.fromRGBO(50, 50, 50, 0.2),
            darkHighContrastColor: Color.fromRGBO(255, 255, 255, 0.2),
          ),
        ),
        WidgetState.focused: BoxDecoration(
          color: CupertinoDynamicColor.withBrightnessAndContrast(
            color: Color.fromRGBO(50, 50, 50, 0.075),
            darkColor: Color.fromRGBO(255, 255, 255, 0.075),
            highContrastColor: Color.fromRGBO(50, 50, 50, 0.15),
            darkHighContrastColor: Color.fromRGBO(255, 255, 255, 0.15),
          ),
        ),
        WidgetState.hovered: BoxDecoration(
          color: CupertinoDynamicColor.withBrightnessAndContrast(
            color: Color.fromRGBO(50, 50, 50, 0.05),
            darkColor: Color.fromRGBO(255, 255, 255, 0.05),
            highContrastColor: Color.fromRGBO(50, 50, 50, 0.1),
            darkHighContrastColor: Color.fromRGBO(255, 255, 255, 0.1),
          ),
        ),
        WidgetState.any: BoxDecoration(),
      });

  /// The maximum number of lines for the [child] widget when
  /// [MediaQuery.textScalerOf] returns a [TextScaler] that is less than or
  /// equal to 1.25.
  // Observed to be 2 on the iOS 17.2 simulator.
  static const int defaultMaxLines = 2;

  /// The maximum number of lines for the [child] widget when
  /// [MediaQuery.textScalerOf] returns a [TextScaler] that is greater than
  /// 1.25.
  ///
  // Observed to be infinite on the iOS 17.2 simulator.
  static const int defaultAccessibilityModeMaxLines = 100;

  /// Resolves the title [TextStyle] in response to
  /// [CupertinoThemeData.brightness], [isDestructiveAction], and [enabled].
  //
  // Approximated from the iOS 17.2 simulator.
  TextStyle _resolveChildStyle(BuildContext context) {
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
      fontWeight: FontWeight.normal,
      fontFamily: CupertinoTheme.of(context).textTheme.textStyle.fontFamily,
    );
  }

  // The font sizes observed on the iOS 18.5 simulator differ from the HIG
  // guidelines for fonts, so a correction factor is applied to the subtitle
  // font size to match the observed sizes.
  //
  // iOS font sizes:
  //  Units    | -3 | -2 | -1 |  0 |  2 |  4 |  6 | 11 | 16 | 23 | 30 | 36
  //  Subtitle | 12 | 13 | 14 | 15 | 17 | 19 | 21 | 25 | 30 | 36 | 42 | 49
  double _calculateSubtitleCorrectionFactor(BuildContext context) {
    final int units = _normalizeTextScale(context);
    if (units == 0) {
      return 1.0;
    }

    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final double higFontSize = textScaler.scale(_defaultSubtitleFontSize);
    final double linearTextSize = units + _defaultSubtitleFontSize;

    // correctedTextSize is the font size observed on iOS 18.5, and the font
    // size we want to match.
    final double correctedTextSize =
        linearTextSize +
        switch (units) {
          < 16 => 0,
          < 23 => -1,
          == 30 => -3,
          _ => -2,
        };

    // Return the factor to convert the HIG font size to the desired font size.
    return correctedTextSize / higFontSize;
  }

  TextStyle _resolveSubtitleStyle(BuildContext context) {
    TextStyle subtitleStyle = defaultSubtitleStyle;
    final double correctionFactor = _calculateSubtitleCorrectionFactor(context);
    if (correctionFactor != 1.0) {
      final double fontSize = defaultSubtitleStyle.fontSize!;
      subtitleStyle = subtitleStyle.copyWith(fontSize: correctionFactor * fontSize);
    }

    final bool isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    subtitleStyle = subtitleStyle.copyWith(
      fontFamily: CupertinoTheme.of(context).textTheme.textStyle.fontFamily,
      foreground:
          Paint()
            ..blendMode = isDark ? BlendMode.plus : BlendMode.hardLight
            ..color =
                CupertinoDynamicColor.maybeResolve(defaultSubtitleStyle.color, context) ??
                defaultSubtitleStyle.color!,
    );

    return subtitleStyle;
  }

  void _handleSelect(BuildContext context) {
    if (requestCloseOnActivate) {
      MenuController.maybeOf(context)?.close();
    }

    onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle childTextStyle = _resolveChildStyle(context);
    final bool isAccessibilityModeEnabled = _isAccessibilityModeEnabled(context);

    Widget label = _CupertinoMenuItemLabel(
      padding: padding,
      constraints: constraints,
      trailing: isAccessibilityModeEnabled ? trailing : null,
      leading: leading,
      leadingAlignment: leadingAlignment,
      trailingAlignment: trailingAlignment,
      leadingWidth: leadingWidth,
      trailingWidth: trailingWidth,
      applyInsetScaling: applyInsetScaling,
      subtitle:
          subtitle != null
              ? DefaultTextStyle.merge(style: _resolveSubtitleStyle(context), child: subtitle!)
              : null,
      child: DefaultTextStyle.merge(style: childTextStyle, child: child),
    );

    if (leading != null || trailing != null) {
      label = IconTheme.merge(
        data: IconThemeData(size: 21, color: childTextStyle.color, applyTextScaling: true),
        child: label,
      );
    }

    return _CupertinoMenuItemInteractionHandler(
      mouseCursor: mouseCursor ?? defaultCursor,
      panActivationDelay: panActivationDelay,
      requestFocusOnHover: requestFocusOnHover,
      onPressed: onPressed != null ? () => _handleSelect(context) : null,
      onHover: onHover,
      onFocusChange: onFocusChange,
      focusNode: focusNode,
      focusNodeDebugLabel: child.toString(),
      decoration: decoration ?? defaultDecoration,
      statesController: statesController,
      behavior: behavior,
      child: DefaultTextStyle.merge(
        maxLines: isAccessibilityModeEnabled ? defaultAccessibilityModeMaxLines : defaultMaxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        style: const TextStyle(height: 1.25, textBaseline: TextBaseline.ideographic),
        child: label,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HitTestBehavior>('hitTestBehavior', behavior));
    properties.add(
      DiagnosticsProperty<Duration>(
        'panActivationDelay',
        panActivationDelay,
        defaultValue: Duration.zero,
      ),
    );
    properties.add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode, defaultValue: null));
    properties.add(FlagProperty('enabled', value: onPressed != null, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<Widget?>('child', child));
    properties.add(DiagnosticsProperty<Widget?>('subtitle', subtitle));
    if (leading != null) {
      properties.add(DiagnosticsProperty<Widget?>('leading', leading));
    }
    if (trailing != null) {
      properties.add(DiagnosticsProperty<Widget?>('trailing', trailing));
    }
  }
}

// TODO(davidhicks980): Update layout when Flutter adds support for last
// baseline (https://github.com/flutter/flutter/issues/4614)
class _CupertinoMenuItemLabel extends StatelessWidget {
  const _CupertinoMenuItemLabel({
    required this.child,
    this.leading,
    this.leadingWidth,
    AlignmentGeometry? leadingAlignment,
    this.trailing,
    this.trailingWidth,
    AlignmentGeometry? trailingAlignment,
    this.subtitle,
    this.applyInsetScaling = true,
    BoxConstraints? constraints,
    this.padding,
  }) : _leadingAlignment = leadingAlignment ?? defaultLeadingAlignment,
       _trailingAlignment = trailingAlignment ?? defaultTrailingAlignment,
       _constraints = constraints;

  // Values were obtained from the iOS 17.2 simulator. Values were measured
  // with a TextScaler of 1.0.
  static const double defaultHorizontalWidth = 16.0;
  static const double leadingWidgetWidth = 32.0;
  static const double trailingWidgetWidth = 44.0;

  // Because iOS uses last baseline alignment to position the child and subtitle
  // and Flutter does not yet support last baseline alignment, padding is used
  // to approximate the vertical alignment of the text.
  static const EdgeInsetsDirectional defaultPadding = EdgeInsetsDirectional.symmetric(
    vertical: 11.5,
  );

  /// Approximate position of the leading widget within the leading width.
  static const AlignmentDirectional defaultLeadingAlignment = AlignmentDirectional(1 / 6, 0.0);

  /// Approximate position of the trailing widget within the trailing width.
  static const AlignmentDirectional defaultTrailingAlignment = AlignmentDirectional(-3 / 11, 0.0);

  // Minimum default constraints of a menu item before one physical pixel is
  // subtracted from the height. If the pixel ratio is 2, then the final
  // vertical minHeight will be 43.5. Height retrieved from the iOS 17.2 simulator
  // debug view.
  static const double defaultHeightWithDivider = kMinInteractiveDimensionCupertino;

  /// The padding for the contents of the menu item.
  ///
  /// If null, the [defaultPadding] minus one physical pixel is used for the
  /// total vertical padding.
  final EdgeInsetsGeometry? padding;

  /// The widget shown before the title. Typically an [Icon].
  ///
  /// Defaults to null.
  final Widget? leading;

  /// The widget shown after the title. Typically an [Icon].
  ///
  /// Defaults to null.
  final Widget? trailing;

  /// The width of the leading portion of the label.
  ///
  /// If null, [leadingWidgetWidth] is used when this menu item or a sibling
  /// menu item has a leading widget, and [defaultHorizontalWidth] is used
  /// otherwise.
  final double? leadingWidth;

  /// The width of the trailing portion of the label.
  ///
  /// Defaults to [trailingWidgetWidth] when this menu item has a trailing
  /// widget, and [defaultHorizontalWidth] otherwise.
  final double? trailingWidth;

  /// The alignment of the leading widget within the leading portion of the menu
  /// item.
  ///
  /// Defaults to [defaultLeadingAlignment] when null.
  final AlignmentGeometry _leadingAlignment;

  /// The alignment of the trailing widget within the trailing portion of the
  /// menu item.
  ///
  /// Defaults to [defaultTrailingAlignment].
  final AlignmentGeometry _trailingAlignment;

  /// The constraints applied to this menu item.
  ///
  /// If null, [defaultConstraints] is used.
  final BoxConstraints? _constraints;

  /// The top center content of the menu item. Typically a [Text] widget.
  final Widget child;

  /// The bottom center content of the menu item. Typically a [Text] widget.
  final Widget? subtitle;

  /// Whether the insets of the menu item should scale with the
  /// [MediaQuery.textScalerOf].
  final bool applyInsetScaling;

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1.0;
    final double pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final double physicalPixel = 1 / pixelRatio;

    final bool showLeadingWidget =
        leading != null || (CupertinoMenuAnchor.maybeHasLeadingOf(context) ?? false);

    double resolvedLeadingWidth =
        leadingWidth ??
        (showLeadingWidget
            ? leadingWidgetWidth //
            : defaultHorizontalWidth);

    double resolvedTrailingWidth =
        trailingWidth ??
        (trailing != null
            ? trailingWidgetWidth //
            : defaultHorizontalWidth);

    // Subtract a physical pixel from the default padding if no padding is
    // specified by the user. Padding retrieved from the iOS 17.2 simulator
    // debug view.
    EdgeInsetsGeometry padding =
        this.padding ?? (defaultPadding - EdgeInsetsDirectional.symmetric(vertical: physicalPixel));

    BoxConstraints constraints =
        _constraints ?? BoxConstraints(minHeight: defaultHeightWithDivider - physicalPixel);

    if (applyInsetScaling && textScale != 1.0) {
      // Padding scales with textScale, but at a slower rate than text. Square
      // root is a (very) rough estimate the padding scaling factor.
      final double paddingScaler = math.sqrt(textScale);
      padding *= paddingScaler;
      constraints *= paddingScaler;
      resolvedLeadingWidth *= paddingScaler;
      resolvedTrailingWidth *= paddingScaler;
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
            // the iOS simulator.
            SizedBox(
              width: resolvedLeadingWidth,
              child: showLeadingWidget ? Align(alignment: _leadingAlignment, child: leading) : null,
            ),
            // Ideally, we would align text with a first-baseline of 28 a
            // last-baseline of 15.667 (iOS 17.4 simulator), but we have to
            // accommodate multiple text styles for their menu implementation.
            // Instead, padding is used to approximate the vertical alignment of
            // the text.
            Expanded(
              child:
                  subtitle == null
                      ? child
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[child, const SizedBox(height: 1), subtitle!],
                      ),
            ),
            SizedBox(
              width: resolvedTrailingWidth,
              child:
                  trailing != null
                      ? Align(
                        alignment: _trailingAlignment,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 20 * textScale),
                          child: trailing,
                        ),
                      )
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
class CupertinoLargeMenuDivider extends StatelessWidget with CupertinoMenuEntryMixin {
  /// Creates a large horizontal divider for a [CupertinoMenuAnchor].
  const CupertinoLargeMenuDivider({super.key, this.color = defaultColor});

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
  bool get hasLeading => false;

  /// Color for a transparent [CupertinoLargeMenuDivider].
  // The following colors were measured from debug mode on the iOS 18.5 simulator,
  static const CupertinoDynamicColor defaultColor = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    darkColor: Color.fromRGBO(0, 0, 0, 0.16),
  );

  static const double _height = 8.0;

  @override
  Widget build(BuildContext context) {
    return Container(height: _height, color: CupertinoDynamicColor.resolve(color, context));
  }
}

/// A gesture and focus handler for [CupertinoMenuItem].
///
/// The [onPressed] callback is called when the user taps the menu item, pans over
/// the menu item and lifts their finger, or when the user long-presses a menu
/// item that has a non-null [panActivationDelay].
///
/// A [mouseCursor] can be provided to change the cursor that appears when a
/// mouse hovers over the menu item. If [mouseCursor] is null, the
/// [SystemMouseCursors.click] cursor is used.
///
/// If [focusNode] is provided, the menu item will be focusable. When the menu
/// item is focused, the [focusedColor] will be used to highlight the menu item.
class _CupertinoMenuItemInteractionHandler extends StatefulWidget {
  /// Creates a [_CupertinoMenuItemInteractionHandler].
  ///
  /// The [child] and [pressedColor] arguments are required and must not be null.
  const _CupertinoMenuItemInteractionHandler({
    required this.child,
    required this.decoration,
    required this.mouseCursor,
    required this.focusNode,
    required this.panActivationDelay,
    required this.onPressed,
    required this.onHover,
    required this.onFocusChange,
    required this.focusNodeDebugLabel,
    required this.requestFocusOnHover,
    required this.behavior,
    required this.statesController,
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

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's node gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool>? onFocusChange;

  /// Whether hovering can request focus.
  ///
  /// Defaults to false.
  final bool requestFocusOnHover;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// Delay between a user's pointer entering a menu item during a pan, and
  /// the menu item being tapped.
  ///
  /// If null, the menu item will not be pressed when panned over.
  final Duration? panActivationDelay;

  /// How the menu item should respond to hit tests.
  final HitTestBehavior behavior;

  /// A debug label that is used to identify the focus node.
  final String? focusNodeDebugLabel;

  /// The mouse cursor to display on hover.
  final WidgetStateProperty<MouseCursor> mouseCursor;

  /// The decoration to show around the menu item based on its state.
  final WidgetStateProperty<BoxDecoration> decoration;

  /// Represents the interactive "state" of this widget in terms of a set of
  /// [WidgetState]s, like [WidgetState.pressed] and [WidgetState.focused].
  ///
  /// Using [WidgetStatesController.addListener], listeners can be added to
  /// observe state changes in this widget. To add or remove states to this widget,
  /// [WidgetStatesController.update] can be used. Note that added states are
  /// only visually represented. In other words, adding [WidgetState.focused] to
  /// this widget will make the widget look like it has focus, but it will not
  /// actually receive focus.
  final WidgetStatesController? statesController;

  bool get enabled => onPressed != null;

  @override
  State<_CupertinoMenuItemInteractionHandler> createState() =>
      _CupertinoMenuItemInteractionHandlerState();
}

class _CupertinoMenuItemInteractionHandlerState extends State<_CupertinoMenuItemInteractionHandler>
    implements _PanTarget {
  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _simulateTap),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: _simulateTap),
  };

  // If a focus node isn't given to the widget, then we have to manage our own.
  FocusNode get _focusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  FocusNode? _internalFocusNode;

  Set<WidgetState> _states = <WidgetState>{};
  WidgetStatesController get _statesController {
    return widget.statesController ?? (_internalStatesController ??= WidgetStatesController());
  }

  WidgetStatesController? _internalStatesController;
  bool get isHovered => _statesController.value.contains(WidgetState.hovered);
  bool get isPressed => _statesController.value.contains(WidgetState.pressed);
  bool get isFocused => _statesController.value.contains(WidgetState.focused);
  bool get isDragged => _statesController.value.contains(WidgetState.dragged);
  bool get isEnabled => !_statesController.value.contains(WidgetState.disabled);

  Timer? _longPanPressTimer;

  void _storeStates() {
    _states = _statesController.value;
  }

  @override
  void initState() {
    super.initState();
    _statesController.addListener(_storeStates);
  }

  @override
  void didUpdateWidget(_CupertinoMenuItemInteractionHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      } else {
        assert(_internalFocusNode == null);
        _internalFocusNode = FocusNode(debugLabel: widget.focusNodeDebugLabel);
      }
    }

    if (widget.statesController != oldWidget.statesController) {
      _statesController.removeListener(_storeStates);
      // States are currently being stored on WidgetStatesController and not on
      // the widget, so states should be transferred if a widget's controller is
      // replaced.
      if (widget.statesController != null) {
        _internalStatesController?.dispose();
        _internalStatesController = null;
      }
      _statesController.addListener(_storeStates);
      // Synchronize the states of this widget with the new controller.
      for (final WidgetState state in _states) {
        _statesController.update(state, true);
      }
    }

    if (!widget.enabled && oldWidget.enabled) {
      if (isEnabled) {
        _statesController
          ..update(WidgetState.disabled, true)
          ..update(WidgetState.pressed, false)
          ..update(WidgetState.focused, false)
          ..update(WidgetState.hovered, false)
          ..update(WidgetState.dragged, false);
      }
      _longPanPressTimer?.cancel();
      _longPanPressTimer = null;
    }
  }

  @override
  void dispose() {
    _statesController.removeListener(_storeStates);

    _internalStatesController?.dispose();
    _internalStatesController = null;

    _longPanPressTimer?.cancel();
    _longPanPressTimer = null;

    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  @override
  bool didPanEnter() {
    if (!widget.enabled) {
      return false;
    }

    if (widget.panActivationDelay != null && _longPanPressTimer == null) {
      _longPanPressTimer = Timer(widget.panActivationDelay!, () {
        _longPanPressTimer?.cancel();
        _longPanPressTimer = null;
        _simulateTap();
      });
    }

    _statesController.update(WidgetState.dragged, true);
    return true;
  }

  @override
  void didPanLeave({bool pointerUp = false}) {
    _longPanPressTimer?.cancel();
    _longPanPressTimer = null;
    if (pointerUp && widget.enabled && mounted) {
      _simulateTap();
    }

    _statesController.update(WidgetState.dragged, false);
  }

  void _handleFocusChange([bool? focused]) {
    final bool hasPrimaryFocus = focused ?? _focusNode.hasPrimaryFocus;
    if (hasPrimaryFocus != isFocused) {
      _statesController.update(WidgetState.focused, hasPrimaryFocus);
      widget.onFocusChange?.call(isFocused);
    }
  }

  void _simulateTap([Intent? intent]) {
    widget.onPressed?.call();
  }

  void _handleTapDown(TapDownDetails details) {
    _statesController.update(WidgetState.pressed, true);
  }

  void _handleTapUp(TapUpDetails? details) {
    _statesController.update(WidgetState.pressed, false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    _statesController.update(WidgetState.pressed, false);
  }

  void _handlePointerExit(PointerExitEvent event) {
    if (isHovered) {
      _statesController
        ..update(WidgetState.hovered, false)
        ..update(WidgetState.focused, false);
      widget.onHover?.call(false);
    }
  }

  // TextButton.onHover and MouseRegion.onHover can't be used without triggering
  // focus on scroll.
  void _handlePointerHover(PointerHoverEvent event) {
    if (!isHovered) {
      widget.onHover?.call(true);
      _statesController.update(WidgetState.hovered, true);
      if (widget.requestFocusOnHover) {
        _focusNode.requestFocus();

        // Without invalidating the focus policy, switching to directional focus
        // may not originate at this node.
        FocusTraversalGroup.of(context).invalidateScopeData(FocusScope.of(context));
      }
    }
  }

  void _dismissMenu() {
    Actions.invoke(context, const DismissIntent());
  }

  Widget _buildStatefulWrapper(BuildContext context, Set<WidgetState> value, Widget? child) {
    final MouseCursor cursor = widget.mouseCursor.resolve(value);
    BoxDecoration decoration = widget.decoration.resolve(value);
    if (decoration.color != null) {
      decoration = decoration.copyWith(
        color: CupertinoDynamicColor.maybeResolve(decoration.color, context),
      );

      // Don't apply a blend mode if the user has specified one.
      if (!kIsWeb && decoration.backgroundBlendMode == null) {
        decoration = decoration.copyWith(
          backgroundBlendMode:
              CupertinoTheme.maybeBrightnessOf(context) == Brightness.light
                  ? BlendMode.multiply
                  : BlendMode.plus,
        );
      }
    }

    return MouseRegion(
      onHover: widget.enabled ? _handlePointerHover : null,
      onExit: widget.enabled ? _handlePointerExit : null,
      hitTestBehavior: HitTestBehavior.deferToChild,
      cursor: cursor,
      child: DecoratedBox(decoration: decoration, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DeviceGestureSettings? gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    return MetaData(
      metaData: this,
      child: Actions(
        actions: widget.enabled ? _actionMap : <Type, Action<Intent>>{},
        child: Focus(
          focusNode: _focusNode,
          canRequestFocus: widget.enabled,
          skipTraversal: !widget.enabled,
          onFocusChange: _handleFocusChange,
          child: Semantics.fromProperties(
            properties: SemanticsProperties(
              role: SemanticsRole.menuItem,
              enabled: widget.enabled,
              focused: isFocused,
              onDismiss: _dismissMenu,
            ),
            child: ValueListenableBuilder<Set<WidgetState>>(
              valueListenable: _statesController,
              builder: _buildStatefulWrapper,
              child: RawGestureDetector(
                behavior: widget.behavior,
                gestures: <Type, GestureRecognizerFactory>{
                  TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                    () => TapGestureRecognizer(),
                    (TapGestureRecognizer instance) {
                      instance
                        ..onTapDown = widget.enabled ? _handleTapDown : null
                        ..onTapUp = widget.enabled ? _handleTapUp : null
                        ..onTapCancel = widget.enabled ? _handleTapCancel : null
                        ..gestureSettings = gestureSettings;
                    },
                  ),
                },
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Called when a [_PanTarget] is entered or exited.
///
/// The `position` describes the global position of the pointer.
///
/// The `onTarget` parameter is true when the pointer is on a [_PanTarget].
typedef _CupertinoPanUpdateCallback = void Function(DragUpdateDetails position, {bool onTarget});

class _PanRegionScope extends InheritedWidget {
  const _PanRegionScope({required super.child, required this.state});
  final _PanRegionState? state;

  @override
  bool updateShouldNotify(_PanRegionScope oldWidget) {
    return state != oldWidget.state;
  }
}

class _PanRegion extends StatefulWidget {
  const _PanRegion({this.enabled = true, required this.onPanDistanceChanged, required this.child});

  final bool enabled;
  final ValueChanged<double> onPanDistanceChanged;
  final Widget child;

  static _PanRegionState _of(BuildContext context) {
    final _PanRegionState? result =
        context.dependOnInheritedWidgetOfExactType<_PanRegionScope>()?.state;
    assert(result != null, 'No PanRegion found in context');
    return result!;
  }

  /// Creates a [ImmediateMultiDragGestureRecognizer] to recognize the start of
  /// a pan gesture.
  ImmediateMultiDragGestureRecognizer createRecognizer(GestureMultiDragStartCallback onStart) {
    return ImmediateMultiDragGestureRecognizer(
      allowedButtonsFilter: (int button) => button == kPrimaryButton,
    )..onStart = onStart;
  }

  @override
  State<_PanRegion> createState() => _PanRegionState();
}

class _PanRegionState extends State<_PanRegion> {
  final Set<_RenderPanSurface> _surfaces = <_RenderPanSurface>{};
  ImmediateMultiDragGestureRecognizer? _recognizer;
  bool get isPanning => _position != null;
  ui.Offset? _position;

  void attachChild(_RenderPanSurface surface) {
    _surfaces.add(surface);
  }

  void detachChild(_RenderPanSurface surface) {
    _surfaces.remove(surface);
  }

  ui.Rect get panArea {
    ui.Rect? combined;
    if (_surfaces.isEmpty) {
      return Rect.zero;
    }

    for (final _RenderPanSurface surface in _surfaces) {
      if (combined == null) {
        combined = surface.rect;
      } else {
        combined = combined.expandToInclude(surface.rect);
      }
    }
    return combined!;
  }

  double calculateSquaredDistance(Rect rect, Offset position) {
    if (rect.contains(position)) {
      return 0;
    }

    final double x = math.max((position.dx - rect.center.dx).abs() - rect.width / 2, 0.0);
    final double y = math.max((position.dy - rect.center.dy).abs() - rect.height / 2, 0.0);

    // Find the squared distance from the edge of the menu panel to the pointer.
    final double squaredDistance = x * x + y * y;
    return squaredDistance;
  }

  void routePointer(PointerDownEvent event) {
    assert(!isPanning);
    assert(_recognizer != null || !widget.enabled);
    _recognizer?.addPointer(event);
  }

  @override
  void initState() {
    super.initState();
    _recognizer = widget.createRecognizer(_beginPan);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recognizer!.gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
  }

  @override
  void didUpdateWidget(_PanRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _recognizer = widget.createRecognizer(_beginPan);
      } else {
        if (isPanning) {
          _completePan();
        }
        _recognizer?.dispose();
        _recognizer = null;
      }
    }
  }

  @override
  void dispose() {
    assert(_surfaces.isEmpty);
    _disposeInactiveRecognizer();
    super.dispose();
  }

  void _disposeInactiveRecognizer() {
    if (!isPanning && _recognizer != null) {
      _recognizer!.dispose();
      _recognizer = null;
    }
  }

  void _completePan() {
    _position = null;
    widget.onPanDistanceChanged(0);
    if (mounted) {
      setState(() {
        // Rebuild to notify that the pan has ended.
      });
    } else {
      // If the widget is not mounted, safely dispose of the recognizer.
      _disposeInactiveRecognizer();
    }
  }

  void _handlePanEnd(DragEndDetails position) {
    _completePan();
  }

  void _handlePanCancel() {
    _completePan();
  }

  void _handlePanUpdate(DragUpdateDetails updateDetails, {bool onTarget = false}) {
    _position = _position! + updateDetails.delta;
    if (onTarget) {
      // If the pointer is on a target, reset the distance to 0.
      widget.onPanDistanceChanged(0);
      return;
    }

    // We can't merge rects because the root menu anchor may not be contiguous.
    double minSquaredDistance = double.infinity;
    for (final _RenderPanSurface surface in _surfaces) {
      final double squaredDistance = calculateSquaredDistance(surface.rect, _position!);
      minSquaredDistance = math.min(squaredDistance, minSquaredDistance);
    }

    final double distance = math.sqrt(minSquaredDistance);
    widget.onPanDistanceChanged(distance);
  }

  Drag? _beginPan(ui.Offset position) {
    assert(!isPanning, 'A new pan should not begin while a pan is active.');
    _position = position;
    return _PanHandler(
      router: this,
      viewId: View.of(context).viewId,
      initialPosition: position,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onPanCanceled: _handlePanCancel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PanRegionScope(state: this, child: widget.child);
  }
}

/// An area that can initiate panning.
///
/// This widget registers with the nearest [_PanRegion] and exposes its position
/// as a [ui.Rect]. This [_PanSurface] will route [PointerDownEvent]s to its
/// [_PanRegion]. If a routed [PointerDownEvent] results in a pan gesture, the
/// [_PanRegion] will use the combined [ui.Rect] of all registered [_PanSurface]s
/// to calculate the panning distance.
class _PanSurface extends SingleChildRenderObjectWidget {
  /// Creates a pan surface that registers with a parent [_PanRegion].
  const _PanSurface({required super.child, required this.includeInPanArea});
  final bool includeInPanArea;

  @override
  _RenderPanSurface createRenderObject(BuildContext context) {
    return _RenderPanSurface(region: _PanRegion._of(context), includeInPanArea: includeInPanArea);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderPanSurface renderObject) {
    renderObject
      ..region = _PanRegion._of(context)
      ..includeInPanArea = includeInPanArea;
  }
}

class _RenderPanSurface extends RenderMetaData {
  _RenderPanSurface({required _PanRegionState region, required bool includeInPanArea})
    : _region = region,
      _includeInPanArea = includeInPanArea;

  _PanRegionState get region => _region;
  _PanRegionState _region;
  set region(_PanRegionState value) {
    if (_region != value) {
      _region.detachChild(this);
      _region = value;
      _region.attachChild(this);
      markNeedsPaint();
    }
  }

  bool get includeInPanArea => _includeInPanArea;
  bool _includeInPanArea = true;
  set includeInPanArea(bool value) {
    if (_includeInPanArea != value) {
      _includeInPanArea = value;
      markNeedsPaint();
    }
  }

  ui.Rect get rect => _panRect;
  ui.Rect _panRect = Rect.zero;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _region.attachChild(this);
  }

  @override
  void detach() {
    _region.detachChild(this);
    super.detach();
  }

  @override
  void dispose() {
    _region.detachChild(this);
    super.dispose();
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      _region.routePointer(event);
    }
  }

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    super.paint(context, offset);
    if (!includeInPanArea) {
      return;
    }

    // Calculate the rect of this surface in the global coordinate system.
    _panRect = localToGlobal(Offset.zero) & size;
  }
}

/// Mix into [State] to receive callbacks when a pointer enters or leaves while
/// down. The [StatefulWidget] this class is mixed into must be a descendant of
/// a [_PanRegion].
@optionalTypeArgs
abstract class _PanTarget {
  /// Called when a pointer enters the [_PanTarget]. Return true if the pointer
  /// should be considered "on" the [_PanTarget], and false otherwise (for
  /// example, when the [_PanTarget] is disabled).
  bool didPanEnter();

  /// Called when the pan is ended or canceled. If `pointerUp` is true,
  /// then the pointer was removed from the screen while over this [_PanTarget].
  void didPanLeave({required bool pointerUp});
}

/// Handles panning events for a [_PanRegion].
// This class was adapted from _DragAvatar.
class _PanHandler extends Drag {
  /// Creates a [_PanHandler] that handles panning events for a [_PanRegion].
  _PanHandler({
    required Offset initialPosition,
    required this.viewId,
    required this.router,
    required this.onPanEnd,
    required this.onPanUpdate,
    required this.onPanCanceled,
  }) : _position = initialPosition {
    _updatePan();
  }

  final int viewId;
  final List<_PanTarget> _enteredTargets = <_PanTarget>[];
  final _CupertinoPanUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final GestureDragCancelCallback onPanCanceled;
  final _PanRegionState router;
  Offset _position;

  @override
  void update(DragUpdateDetails details) {
    final Offset oldPosition = _position;
    _position += details.delta;
    if (_position != oldPosition) {
      _updatePan();
      onPanUpdate.call(details, onTarget: _enteredTargets.isNotEmpty);
    }
  }

  @override
  void end(DragEndDetails details) {
    _leaveAllEntered(pointerUp: true);
    onPanEnd.call(details);
  }

  @override
  void cancel() {
    _leaveAllEntered();
    onPanCanceled();
  }

  void _updatePan() {
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, _position, viewId);
    // Look for the RenderBoxes that corresponds to the hit target
    final List<_PanTarget> targets = <_PanTarget>[];
    for (final HitTestEntry entry in result.path) {
      if (entry.target case RenderMetaData(:final _PanTarget metaData)) {
        targets.add(metaData);
      }
    }

    bool listsMatch = false;
    if (targets.length >= _enteredTargets.length && _enteredTargets.isNotEmpty) {
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
    for (final _PanTarget? target in targets) {
      if (target != null) {
        _enteredTargets.add(target);
        if (target.didPanEnter()) {
          HapticFeedback.selectionClick();
          return;
        }
      }
    }
  }

  void _leaveAllEntered({bool pointerUp = false}) {
    for (int i = 0; i < _enteredTargets.length; i += 1) {
      _enteredTargets[i].didPanLeave(pointerUp: pointerUp);
    }
    _enteredTargets.clear();
  }
}

/// Multiplies the values of two animations.
///
/// This class is used to animate the scale of the menu when the user drags
/// outside of the menu area.
class _AnimationProduct extends CompoundAnimation<double> {
  _AnimationProduct({required super.first, required super.next});

  @override
  double get value => super.first.value * super.next.value;
}

class _ClampTween extends Animatable<double> {
  const _ClampTween({required this.begin, required this.end});
  final double begin;
  final double end;

  @override
  double transform(double t) {
    if (t < begin) {
      return begin;
    }

    if (t > end) {
      return end;
    }

    return t;
  }
}
