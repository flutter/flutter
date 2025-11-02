// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

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
import 'dialog.dart';
import 'theme.dart';

// Dismiss is handled by RawMenuAnchor
const Map<ShortcutActivator, Intent> _kMenuTraversalShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
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

// The font size at which text scales linearly on the iOS 18.5 simulator.
const double _kCupertinoMobileBaseFontSize = 17.0;

/// The CupertinoMenuAnchor layout policy changes depending on whether the user is using
/// a "regular" font size vs a "large" font size. This is a spectrum. There are
/// many "regular" font sizes and many "large" font sizes. But depending on which
/// policy is currently being used, a menu is laid out differently.
///
/// Empirically, the jump from one policy to the other occurs at the following text
/// scale factors:
/// * Max "regular" scale factor ≈ 23/17 ≈ 1.352... (6 units)
/// * Min "accessible" scale factor   ≈ 28/17 ≈ 1.647... (11 units)
///
/// The following constant represents a division in text scale factor beyond which
/// we want to change how the menu is laid out.
///
/// This explanation was ported from CupertinoDialog.
const double _kMinimumAccessibleNormalizedTextScale = 11;

/// The minimum normalized text scale factor supported on iOS.
const double _kMinimumTextScaleFactor = 1 - 3 / _kCupertinoMobileBaseFontSize;

/// The minimum normalized text scale factor supported on iOS.
const double _kMaximumTextScaleFactor = 1 + 36 / _kCupertinoMobileBaseFontSize;

/// The font family for menu items at smaller text scales.
const String _kBodyFont = 'CupertinoSystemText';

/// The font family for menu items at larger text scales.
const String _kDisplayFont = 'CupertinoSystemDisplay';

/// Returns an integer that represents the current text scale factor normalized
/// to the base font size.
///
/// Normalizing to the base font size simplifies storage of nonlinear layout
/// spacing that depends on the text scale factor.
///
/// On iOS, the base text scale is 17.0 pt, meaning each "unit" represents an
/// increase or decrease of 1/17th (≈5.88%) of the base font size.
///
/// The equation to calculate the normalized text scale is:
///
/// ```dart
/// final normalizedScale = MediaQuery.of(context).scale(baseFontSize) - baseFontSize
/// ```
///
/// The returned value is positive when the text scale factor is larger than the
/// base font size, negative when smaller, and zero when equal.
double _normalizeTextScale(TextScaler textScaler) {
  if (textScaler == TextScaler.noScaling) {
    return 0;
  }

  return textScaler.scale(_kCupertinoMobileBaseFontSize) - _kCupertinoMobileBaseFontSize;
}

// Accessibility mode on iOS is determined by the text scale factor that the
// user has selected.
bool _isAccessibilityModeEnabled(BuildContext context) {
  final TextScaler? textScaler = MediaQuery.maybeTextScalerOf(context);
  if (textScaler == null) {
    return false;
  }

  return _normalizeTextScale(textScaler) >= _kMinimumAccessibleNormalizedTextScale;
}

/// The width of a Cupertino menu
// Measured on:
//  - iPadOS 18.5 Simulator
//    - iPad Pro 11-inch
//    - iPad Pro 13-inch
//  - iOS 18.5 Simulator
//   - iPhone 16 Pro
enum _CupertinoMenuWidth {
  iPadOS(points: 262),
  iPadOSAccessible(points: 343),
  iOS(points: 250),
  iOSAccessible(points: 370);

  const _CupertinoMenuWidth({required this.points});

  // Determines the appropriate menu width based on screen width and
  // accessibility mode.
  //
  // A screen width threshold of 768 points is used to differentiate
  // between mobile and tablet devices.
  factory _CupertinoMenuWidth.fromScreenWidth({
    required double screenWidth,
    required bool isAccessibilityModeEnabled,
  }) {
    final bool isMobile = screenWidth < _kMenuWidthMobileWidthThreshold;
    return switch ((isMobile, isAccessibilityModeEnabled)) {
      (false, false) => _CupertinoMenuWidth.iPadOS,
      (false, true) => _CupertinoMenuWidth.iPadOSAccessible,
      (true, false) => _CupertinoMenuWidth.iOS,
      (true, true) => _CupertinoMenuWidth.iOSAccessible,
    };
  }

  static const double _kMenuWidthMobileWidthThreshold = 768;
  final double points;
}

// TODO(davidhicks980): DynamicType should be moved to the Cupertino theming library when available.
// Obtained from https://developer.apple.com/design/human-interface-guidelines/typography#Specifications
enum _DynamicTypeStyle {
  body(
    xSmall: TextStyle(fontSize: 14, height: 19 / 14, letterSpacing: -0.41, fontFamily: _kBodyFont),
    small: TextStyle(fontSize: 15, height: 20 / 15, letterSpacing: -0.41, fontFamily: _kBodyFont),
    medium: TextStyle(fontSize: 16, height: 21 / 16, letterSpacing: -0.41, fontFamily: _kBodyFont),
    large: TextStyle(fontSize: 17, height: 22 / 17, letterSpacing: -0.41, fontFamily: _kBodyFont),
    xLarge: TextStyle(fontSize: 19, height: 24 / 19, letterSpacing: -0.41, fontFamily: _kBodyFont),
    xxLarge: TextStyle(fontSize: 21, height: 26 / 21, letterSpacing: -0.8, fontFamily: _kBodyFont),
    xxxLarge: TextStyle(
      fontSize: 23,
      height: 29 / 23,
      letterSpacing: 0.38,
      fontFamily: _kDisplayFont,
    ),
    ax1: TextStyle(fontSize: 28, height: 34 / 28, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax2: TextStyle(fontSize: 33, height: 40 / 33, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax3: TextStyle(fontSize: 40, height: 48 / 40, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax4: TextStyle(fontSize: 47, height: 56 / 47, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax5: TextStyle(fontSize: 53, height: 62 / 53, letterSpacing: 0.38, fontFamily: _kDisplayFont),
  ),
  subhead(
    xSmall: TextStyle(fontSize: 12, height: 16 / 12, letterSpacing: -0.025, fontFamily: _kBodyFont),
    small: TextStyle(fontSize: 13, height: 18 / 13, letterSpacing: -0.025, fontFamily: _kBodyFont),
    medium: TextStyle(fontSize: 14, height: 19 / 14, letterSpacing: -0.025, fontFamily: _kBodyFont),
    large: TextStyle(fontSize: 15, height: 20 / 15, letterSpacing: -0.2, fontFamily: _kBodyFont),
    xLarge: TextStyle(fontSize: 17, height: 22 / 17, letterSpacing: -0.41, fontFamily: _kBodyFont),
    xxLarge: TextStyle(fontSize: 19, height: 24 / 19, letterSpacing: -0.68, fontFamily: _kBodyFont),
    xxxLarge: TextStyle(
      fontSize: 21,
      height: 28 / 21,
      letterSpacing: -0.68,
      fontFamily: _kBodyFont,
    ),
    ax1: TextStyle(fontSize: 25, height: 31 / 25, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax2: TextStyle(fontSize: 30, height: 37 / 30, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax3: TextStyle(fontSize: 36, height: 43 / 36, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax4: TextStyle(fontSize: 42, height: 50 / 42, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax5: TextStyle(fontSize: 49, height: 58 / 49, letterSpacing: 0.38, fontFamily: _kDisplayFont),
  );

  const _DynamicTypeStyle({
    required this.xSmall,
    required this.small,
    required this.medium,
    required this.large,
    required this.xLarge,
    required this.xxLarge,
    required this.xxxLarge,
    required this.ax1,
    required this.ax2,
    required this.ax3,
    required this.ax4,
    required this.ax5,
  });

  final TextStyle xSmall;
  final TextStyle small;
  final TextStyle medium;
  final TextStyle large;
  final TextStyle xLarge;
  final TextStyle xxLarge;
  final TextStyle xxxLarge;
  final TextStyle ax1;
  final TextStyle ax2;
  final TextStyle ax3;
  final TextStyle ax4;
  final TextStyle ax5;

  double _interpolateUnits(double units, int minimum, int maximum) {
    final double t = (units - minimum) / (maximum - minimum);
    return ui.lerpDouble(0, 1, t)!;
  }

  // The following units were measured from the iOS 18.5 simulator in points.
  TextStyle resolveTextStyle(TextScaler textScaler) {
    final double units =
        textScaler.scale(_kCupertinoMobileBaseFontSize) - _kCupertinoMobileBaseFontSize;
    return switch (units) {
      <= -3 => xSmall,
      < -2 => TextStyle.lerp(xSmall, small, _interpolateUnits(units, -3, -2))!,
      < -1 => TextStyle.lerp(small, medium, _interpolateUnits(units, -2, -1))!,
      < 0 => TextStyle.lerp(medium, large, _interpolateUnits(units, -1, 0))!,
      < 2 => TextStyle.lerp(large, xLarge, _interpolateUnits(units, 0, 2))!,
      < 4 => TextStyle.lerp(xLarge, xxLarge, _interpolateUnits(units, 2, 4))!,
      < 6 => TextStyle.lerp(xxLarge, xxxLarge, _interpolateUnits(units, 4, 6))!,
      < 11 => TextStyle.lerp(xxxLarge, ax1, _interpolateUnits(units, 6, 11))!,
      < 16 => TextStyle.lerp(ax1, ax2, _interpolateUnits(units, 11, 16))!,
      < 23 => TextStyle.lerp(ax2, ax3, _interpolateUnits(units, 16, 23))!,
      < 30 => TextStyle.lerp(ax3, ax4, _interpolateUnits(units, 23, 30))!,
      < 36 => TextStyle.lerp(ax4, ax5, _interpolateUnits(units, 30, 36))!,
      _ => ax5,
    };
  }
}

double _computeSquaredDistanceToRect(Offset point, Rect rect) {
  final double dx = point.dx - ui.clampDouble(point.dx, rect.left, rect.right);
  final double dy = point.dy - ui.clampDouble(point.dy, rect.top, rect.bottom);
  return dx * dx + dy * dy;
}

/// Returns the nearest multiple of [to] to [value].
/// ```dart
/// print(quantize(3.15, to: 0));    // 3.15
/// print(quantize(3.15, to: 1));    // 3
/// print(quantize(3.15, to: 0.1));  // 3.2
/// print(quantize(3.15, to: 0.01)); // 3.15
/// print(quantize(3.15, to: 0.25)); // 3.25
/// print(quantize(3.15, to: 0.5));  // 3.0
/// print(quantize(-3.15, to: 0.5)); // -3.0
/// print(quantize(-3.15, to: 0.1)); // -3.2
/// ```
double _quantize(double value, {required double to}) {
  if (to == 0) {
    return value;
  }
  return (value / to).round() * to;
}

/// Mix [CupertinoMenuEntryMixin] in to define how a menu item should be drawn
/// in a menu.
mixin CupertinoMenuEntryMixin {
  /// Whether this menu item has a leading widget.
  ///
  /// If [hasLeading] returns true, siblings of this menu item that are missing
  /// a leading widget will have leading space added to align the leading edges
  /// of all menu items.
  bool hasLeading(BuildContext context);

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
typedef CupertinoMenuAnimationStatusChangedCallback = void Function(AnimationStatus status);

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
/// invoked every time the [AnimationStatus] of the menu animation changes.
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
///    builder: (BuildContext context, MenuController controller, Widget? child) {
///      return CupertinoButton.filled(
///        onPressed: () {
///          if (controller.isOpen) {
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
    this.controller,
    this.onOpen,
    this.onClose,
    this.onAnimationStatusChange,
    this.alignment,
    this.alignmentOffset,
    this.menuAlignment,
    this.constraints,
    this.constrainCrossAxis = false,
    this.consumeOutsideTaps = false,
    this.enableSwipe = true,
    this.longPressToOpenDuration = Duration.zero,
    this.useRootOverlay = false,
    this.overlayPadding = const EdgeInsets.all(8),
    required this.menuChildren,
    this.builder,
    this.child,
    this.childFocusNode,
  });

  /// An optional controller that allows opening and closing of the menu from
  /// other widgets.
  final MenuController? controller;

  /// A callback invoked when the menu is opened while having an
  /// [AnimationStatus] of [AnimationStatus.dismissed] or [AnimationStatus.reverse].
  final VoidCallback? onOpen;

  /// A callback invoked when the menu is closed while having an
  /// [AnimationStatus] of [AnimationStatus.complete] or [AnimationStatus.forward].
  final VoidCallback? onClose;

  /// A callback that is invoked when the status of the menu changes.
  ///
  /// Unlike [onOpen] and [onClose], this callback is invoked for all
  /// [AnimationStatus] changes.
  final CupertinoMenuAnimationStatusChangedCallback? onAnimationStatusChange;

  /// The point on the anchor surface that attaches to the menu.
  ///
  /// This value is ignored if the menu is opened with an explicit position.
  final AlignmentGeometry? alignment;

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

  /// The point on the menu surface that attaches to the anchor.
  final AlignmentGeometry? menuAlignment;

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

  /// Whether or not swiping is enabled on the menu.
  ///
  /// When swiping is enabled, a [MultiDragGestureRecognizer] is added around
  /// the menu button and menu items. The [MultiDragGestureRecognizer] allows
  /// for users to press, move, and activate adjacent menu items in a single
  /// gesture. Swiping also scales the menu panel when users drag their
  /// pointer away from the menu.
  ///
  /// Disabling swiping can be useful if the menu swipe effects interfere with
  /// another swipe gesture, such as in the case of dragging a menu anchor
  /// around the screen.
  ///
  /// Defaults to true.
  final bool enableSwipe;

  /// The duration after which a long-press on the anchor button will open the
  /// menu.
  ///
  /// When a menu is opened via long-press, the menu can be swiped in the same
  /// gesture to select and activate menu items.
  ///
  /// When the inner menu button is disabled, [longPressToOpenDuration] should
  /// be set to [Duration.zero] to prevent the menu from opening on long-press.
  ///
  /// Defaults to [Duration.zero], which disables the behavior.
  final Duration longPressToOpenDuration;

  /// {@macro flutter.widgets.RawMenuAnchor.useRootOverlay}
  final bool useRootOverlay;

  /// The padding to subtract from the overlay when positioning the menu.
  final EdgeInsetsGeometry overlayPadding;

  /// A list of menu items to display in the menu.
  final List<Widget> menuChildren;

  /// The widget that this [CupertinoMenuAnchor] surrounds.
  ///
  /// Typically, this is a button that calls [MenuController.open] when pressed.
  ///
  /// If null, the [CupertinoMenuAnchor] will be the size that its parent
  /// allocates for it.
  final RawMenuAnchorChildBuilder? builder;

  /// An optional child to be passed to the [builder].
  ///
  /// Supply this child if there is a portion of the widget tree built in
  /// [builder] that doesn't depend on the `controller` or `context` supplied to
  /// the [builder]. It will be more efficient, since Flutter doesn't then need
  /// to rebuild this child when those change.
  final Widget? child;

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

  /// Returns whether any ancestor [CupertinoMenuAnchor] has menu items with
  /// leading widgets.
  ///
  /// This can be used by menu items to determine whether they need to
  /// allocate space for a leading widget to align with sibling menu items.
  static bool? maybeHasLeadingOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AnchorScope>()?.hasLeading;
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
    properties.add(DiagnosticsProperty<FocusNode?>('childFocusNode', childFocusNode));
    properties.add(DiagnosticsProperty<BoxConstraints?>('constraints', constraints));
    properties.add(DiagnosticsProperty<AlignmentGeometry?>('menuAlignment', menuAlignment));
    properties.add(DiagnosticsProperty<AlignmentGeometry?>('alignment', alignment));
    properties.add(DiagnosticsProperty<Offset?>('alignmentOffset', alignmentOffset));
    properties.add(
      FlagProperty(
        'constrainCrossAxis',
        value: constrainCrossAxis,
        ifTrue: 'constrains cross axis',
      ),
    );
    properties.add(
      FlagProperty(
        'enableSwipe',
        value: enableSwipe,
        ifTrue: 'swipe enabled',
        ifFalse: 'swipe disabled',
      ),
    );
    properties.add(
      FlagProperty(
        'consumeOutsideTaps',
        value: consumeOutsideTaps,
        ifTrue: 'consumes outside taps',
      ),
    );
    properties.add(
      FlagProperty('useRootOverlay', value: useRootOverlay, ifTrue: 'uses root overlay'),
    );
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('overlayPadding', overlayPadding));
  }
}

class _CupertinoMenuAnchorState extends State<CupertinoMenuAnchor> with TickerProviderStateMixin {
  static const Tolerance springTolerance = Tolerance(velocity: 0.1, distance: 0.1);

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

  late final AnimationController _animationController;
  final FocusScopeNode _menuScopeNode = FocusScopeNode(debugLabel: 'Menu Scope');
  final ValueNotifier<double> _swipeDistanceNotifier = ValueNotifier<double>(0);

  bool? _hasLeadingWidget;
  MenuController get _menuController => widget.controller ?? _internalMenuController!;
  MenuController? _internalMenuController;
  bool get isOpening => _animationStatus.isForwardOrCompleted;
  bool get enableSwipe =>
      widget.enableSwipe &&
      switch (_animationStatus) {
        AnimationStatus.forward || AnimationStatus.completed || AnimationStatus.dismissed => true,
        AnimationStatus.reverse => false,
      };
  AnimationStatus _animationStatus = AnimationStatus.dismissed;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalMenuController = MenuController();
    }

    _animationController = AnimationController.unbounded(vsync: this);
    _animationController.addStatusListener(_handleAnimationStatusChange);
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
      _hasLeadingWidget = _resolveHasLeading();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hasLeadingWidget ??= _resolveHasLeading();
  }

  @override
  void dispose() {
    _menuScopeNode.dispose();
    _animationController
      ..stop()
      ..dispose();
    _internalMenuController = null;
    _swipeDistanceNotifier.dispose();
    super.dispose();
  }

  bool _resolveHasLeading() {
    return widget.menuChildren.any((Widget element) {
      return switch (element) {
        final CupertinoMenuEntryMixin entry => entry.hasLeading(context),
        _ => false,
      };
    });
  }

  void _handleAnimationStatusChange(AnimationStatus status) {
    setState(() {
      _animationStatus = status;
    });

    widget.onAnimationStatusChange?.call(status);
  }

  void _handleSwipeDistanceChange(double distance) {
    if (!_menuController.isOpen) {
      return;
    }

    // Because we are triggering a nested ticker, it's easiest to pass a
    // listenable down the tree. Otherwise, it would be more idiomatic to use
    // an inherited widget.
    _swipeDistanceNotifier.value = distance;
  }

  void _handleAnchorSwipeStart() {
    // If widget.anchorPressActivationDuration becomes zero while a press is
    // active, do not open the menu.
    if (isOpening || widget.longPressToOpenDuration == Duration.zero) {
      return;
    }
    _menuController.open();
  }

  void _handleCloseRequested(VoidCallback hideMenu) {
    if (_animationStatus case AnimationStatus.reverse || AnimationStatus.dismissed) {
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
  }

  void _handleOpenRequested(ui.Offset? position, VoidCallback showOverlay) {
    showOverlay();

    if (_animationStatus case AnimationStatus.completed || AnimationStatus.forward) {
      return;
    }

    _animationController.animateWith(
      SpringSimulation(forwardSpring, _animationController.value, 1, 0.5),
    );

    FocusScope.of(context).setFirstFocus(_menuScopeNode);
  }

  Widget _buildMenuOverlay(BuildContext childContext, RawMenuOverlayInfo info) {
    return ExcludeSemantics(
      excluding: !isOpening,
      child: IgnorePointer(
        ignoring: !isOpening,
        child: ExcludeFocus(
          excluding: !isOpening,
          child: _MenuOverlay(
            constrainCrossAxis: widget.constrainCrossAxis,
            visibilityAnimation: _animationController.view,
            swipeDistanceListenable: _swipeDistanceNotifier,
            alignmentOffset: widget.alignmentOffset ?? Offset.zero,
            constraints: widget.constraints,
            consumeOutsideTaps: widget.consumeOutsideTaps,
            alignment: widget.alignment,
            menuAlignment: widget.menuAlignment,
            overlaySize: info.overlaySize,
            anchorRect: info.anchorRect,
            anchorPosition: info.position,
            tapRegionGroupId: info.tapRegionGroupId,
            focusScopeNode: _menuScopeNode,
            overlayInsets: widget.overlayPadding,
            children: widget.menuChildren,
          ),
        ),
      ),
    );
  }

  Widget _buildChild(BuildContext context, MenuController controller, Widget? child) {
    final Widget anchor =
        widget.builder?.call(context, _menuController, widget.child) ??
        widget.child ??
        const SizedBox.shrink();

    if (widget.longPressToOpenDuration == Duration.zero || !enableSwipe) {
      return anchor;
    }

    return _SwipeSurface(
      onStart: _handleAnchorSwipeStart,
      delay: widget.longPressToOpenDuration,
      child: anchor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SwipeRegion(
      onDistanceChanged: _handleSwipeDistanceChange,
      enabled: enableSwipe,
      child: _AnchorScope(
        hasLeading: _hasLeadingWidget!,
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
    required this.visibilityAnimation,
    required this.swipeDistanceListenable,
  });

  final List<Widget> children;
  final FocusScopeNode focusScopeNode;
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
  final Animation<double> visibilityAnimation;
  final ValueListenable<double> swipeDistanceListenable;

  @override
  State<_MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<_MenuOverlay>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    _FocusDownIntent: _FocusDownAction(),
    _FocusUpIntent: _FocusUpAction(),
    _FocusFirstIntent: _FocusFirstAction(),
    _FocusLastIntent: _FocusLastAction(),
  };
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _swipeAnimationController;
  late final ProxyAnimation _scaleAnimation = ProxyAnimation(kAlwaysCompleteAnimation);
  final ProxyAnimation _fadeAnimation = ProxyAnimation(kAlwaysCompleteAnimation);
  final ProxyAnimation _sizeAnimation = ProxyAnimation(kAlwaysCompleteAnimation);
  late Alignment _attachmentPointAlignment;
  late ui.Offset _attachmentPoint;
  late Alignment _menuAlignment;
  List<Widget> _children = <Widget>[];
  _CompatAnimationBehavior? _animationBehavior;
  ui.TextDirection? _textDirection;

  // The actual distance the user has swiped away from the menu.
  double _swipeTargetDistance = 0;

  // The effective distance the user has swiped away from the menu, after
  // applying velocity and deceleration.
  double _swipeCurrentDistance = 0;

  // The accumulated velocity of the swipe gesture, used to determine how fast
  // the menu scales to _swipeTargetDistance
  double _swipeVelocity = 0;

  // A ticker used to drive the swipe animation.
  Ticker? _swipeTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _swipeAnimationController = AnimationController.unbounded(value: 1, vsync: this);
    widget.swipeDistanceListenable.addListener(_handleSwipeDistanceChanged);
    _resolveChildren();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ui.TextDirection newTextDirection = Directionality.of(context);
    if (_textDirection != newTextDirection) {
      _textDirection = newTextDirection;
      _resolvePosition();
    }

    _resolveMotion();
  }

  @override
  void didUpdateWidget(_MenuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.swipeDistanceListenable != widget.swipeDistanceListenable) {
      oldWidget.swipeDistanceListenable.removeListener(_handleSwipeDistanceChanged);
      widget.swipeDistanceListenable.addListener(_handleSwipeDistanceChanged);
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
      _resolvePosition();
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
    _scrollController.dispose();
    widget.swipeDistanceListenable.removeListener(_handleSwipeDistanceChanged);
    _swipeTicker
      ?..stop()
      ..dispose();
    _swipeAnimationController
      ..stop()
      ..dispose();
    _scaleAnimation.parent = null;
    _fadeAnimation.parent = null;
    _sizeAnimation.parent = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _resolveChildren() {
    if (widget.children.isEmpty) {
      _children = <Widget>[];
      return;
    }

    final List<Widget> children = <Widget>[];
    Widget child = widget.children.first;
    for (int i = 0; i < widget.children.length; i++) {
      children.add(child);
      if (child == widget.children.last) {
        break;
      }

      if (child case CupertinoMenuEntryMixin(allowTrailingSeparator: false)) {
        child = widget.children[i + 1];
        continue;
      }

      child = widget.children[i + 1];
      if (child case CupertinoMenuEntryMixin(allowLeadingSeparator: false)) {
        continue;
      }

      children.add(const _CupertinoMenuDivider());
    }
    _children = children;
  }

  void _resolveMotion() {
    // Behavior of reduce motion is based on iOS 18.5 simulator. Behavior of
    // disable animations could not be determined, so all animations are disabled.
    final ui.AccessibilityFeatures accessibilityFeatures = View.of(
      context,
    ).platformDispatcher.accessibilityFeatures;

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
          next: _swipeAnimationController.view.drive(Tween<double>(begin: 0.8, end: 1)),
        );
        _sizeAnimation.parent = widget.visibilityAnimation.drive(Tween<double>(begin: 0.8, end: 1));
        _fadeAnimation.parent = widget.visibilityAnimation.drive(
          CurveTween(curve: Curves.easeIn).chain(const _ClampTween(begin: 0, end: 1)),
        );

      case _CompatAnimationBehavior.reduced:
        // Swipe scaling works with reduced motion.
        _scaleAnimation.parent = _swipeAnimationController.view.drive(
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
  void _resolvePosition() {
    final ui.Offset anchorMidpoint;
    if (widget.anchorPosition != null) {
      anchorMidpoint = widget.anchorRect.topLeft + widget.anchorPosition!;
    } else {
      anchorMidpoint = widget.anchorRect.center;
    }

    final double xMidpointRatio = anchorMidpoint.dx / widget.overlaySize.width;
    final double yMidpointRatio = anchorMidpoint.dy / widget.overlaySize.height;

    // Slightly favor placing the menu below the anchor when it is near the vertical
    // center of the screen.
    final double defaultVerticalAlignment = yMidpointRatio < 0.55 ? 1 : -1;
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
    final double xAttachmentPointRatio = _attachmentPoint.dx / widget.overlaySize.width;
    // The alignment of the menu growth point relative to the screen.
    _attachmentPointAlignment = Alignment(
      xAttachmentPointRatio * 2 - 1,
      yAttachmentPointRatio * 2 - 1,
    );
  }

  void _handleOutsideTap(PointerDownEvent event) {
    MenuController.maybeOf(context)!.close();
  }

  void _handleSwipeDistanceChanged() {
    _swipeTargetDistance = ui.clampDouble(widget.swipeDistanceListenable.value, 0, 150);
    if (_swipeCurrentDistance == _swipeTargetDistance) {
      return;
    }

    _swipeTicker ??= createTicker(_updateSwipeScale);
    if (!_swipeTicker!.isActive) {
      _swipeTicker!.start();
    }
  }

  // The menu will scale between 80% and 100% of its size based on the distance
  // the user has dragged their pointer away from the menu edges.
  void _updateSwipeScale(Duration elapsed) {
    const double maxVelocity = 20.0;
    const double minVelocity = 8;
    const double maxSwipeDistance = 150;
    const double accelerationRate = 0.12;

    // The distance below which velocity begins to decelerate.
    //
    // When the swipe distance to target is less than this value, the animation
    // velocity reduces proportionally to create smooth arrival at the target.
    // Higher values mean the animation begins to decelerate sooner, resulting to
    // a smoother animation curve.
    const double decelerationDistanceThreshold = 80;

    // The distance at which the animation will snap to the target distance without
    // any animation.
    const double remainingDistanceSnapThreshold = 1.0;

    // When the user's pointer is within this distance of the menu edges, the
    // swipe animation will terminate.
    const double terminationDistanceThreshold = 5.0;

    final double distance = _swipeTargetDistance - _swipeCurrentDistance;
    final double absoluteDistance = distance.abs();

    // As the distance between the current position and the target position increases,
    // the proximity factor approaches 1.0, which increases acceleration.
    //
    // Conversely, as the current position nears the target within the deceleration
    // zone, the proximity factor approaches 0.0, which decreases acceleration
    // and smoothes the end of the animation.
    final double proximityFactor = math.min(absoluteDistance / decelerationDistanceThreshold, 1.0);

    _swipeVelocity += accelerationRate * proximityFactor;
    _swipeVelocity = ui.clampDouble(_swipeVelocity, minVelocity, maxVelocity);

    final double finalVelocity = _swipeVelocity * proximityFactor;
    final double distanceReduction = distance.sign * finalVelocity;
    _swipeCurrentDistance += distanceReduction;

    if (absoluteDistance < remainingDistanceSnapThreshold) {
      _swipeCurrentDistance = _swipeTargetDistance;
      _swipeVelocity = 0;
      if (_swipeTargetDistance < terminationDistanceThreshold) {
        _swipeTicker!.stop();
      }
    }

    _swipeAnimationController.value = 1 - _swipeCurrentDistance / maxSwipeDistance;
  }

  @override
  Widget build(BuildContext context) {
    final BoxConstraints constraints;
    if (widget.constraints != null) {
      constraints = widget.constraints!;
    } else {
      final bool isAccessibilityModeEnabled = _isAccessibilityModeEnabled(context);
      final double screenWidth = MediaQuery.widthOf(context);
      final _CupertinoMenuWidth menuWidth = _CupertinoMenuWidth.fromScreenWidth(
        isAccessibilityModeEnabled: isAccessibilityModeEnabled,
        screenWidth: screenWidth,
      );
      constraints = BoxConstraints.tightFor(width: menuWidth.points);
    }
    Widget child = _SwipeSurface(
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
        // only Gaussian blur, linear color filter, and shadows, because the
        // iOS popup surface does not linearly transform underlying colors.
        // A custom shader would need to be used to achieve the same effect.
        child: Actions(
          actions: _actions,
          child: Shortcuts(
            shortcuts: _kMenuTraversalShortcuts,
            child: FocusScope(
              node: widget.focusScopeNode,
              descendantsAreFocusable: true,
              descendantsAreTraversable: true,
              canRequestFocus: true,
              child: CustomPaint(
                painter: _ShadowPainter(
                  brightness: CupertinoTheme.maybeBrightnessOf(context) ?? ui.Brightness.light,
                  repaint: _fadeAnimation,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  alwaysIncludeSemantics: true,
                  child: CupertinoPopupSurface(
                    // The FadeTransition widget needs to wrap Semantics so
                    // that the semantics widget senses that the menu is the
                    // same opacity as the menu items. Otherwise, "a menu
                    // cannot be empty" error is thrown due to the menu items
                    // being transparent while the menu semantics are still
                    // present.
                    child: AnimatedBuilder(
                      animation: _sizeAnimation,
                      child: Semantics(
                        explicitChildNodes: true,
                        scopesRoute: true,
                        namesRoute: true,
                        child: ConstrainedBox(
                          constraints: constraints,
                          child: SingleChildScrollView(
                            clipBehavior: Clip.none,
                            primary: true,
                            child: Column(mainAxisSize: MainAxisSize.min, children: _children),
                          ),
                        ),
                      ),
                      builder: (BuildContext context, Widget? child) {
                        return Align(
                          heightFactor: _sizeAnimation.value,
                          widthFactor: 1.0,
                          alignment: Alignment.topCenter,
                          child: child,
                        );
                      },
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
        child: ValueListenableBuilder<double>(
          valueListenable: _sizeAnimation,
          child: child,
          builder: (BuildContext context, double value, Widget? child) {
            final ui.Rect anchorRect = widget.anchorPosition != null
                ? _attachmentPoint & Size.zero
                : widget.anchorRect;
            final List<ui.DisplayFeature>? displayFeatures = MediaQuery.maybeDisplayFeaturesOf(
              context,
            );
            return CustomSingleChildLayout(
              delegate: _MenuLayoutDelegate(
                anchorRect: anchorRect,
                attachmentPoint: _attachmentPoint,
                menuAlignment: _menuAlignment,
                padding: widget.overlayInsets.resolve(_textDirection),
                heightFactor: value,
                avoidBounds: displayFeatures != null ? avoidBounds(displayFeatures) : <Rect>{},
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }

  static Set<ui.Rect> avoidBounds(List<ui.DisplayFeature> displayFeatures) {
    final Set<ui.Rect> bounds = <ui.Rect>{};
    for (final ui.DisplayFeature feature in displayFeatures) {
      if (feature.bounds.shortestSide > 0 ||
          feature.state == ui.DisplayFeatureState.postureHalfOpened) {
        bounds.add(feature.bounds);
      }
    }
    return bounds;
  }
}

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter({required this.brightness, required this.repaint}) : super(repaint: repaint);

  static const Radius radius = Radius.circular(13);
  static const double lightShadowOpacity = 0.12;
  static const double darkShadowOpacity = 0.24;
  double get shadowOpacity => ui.clampDouble(repaint.value, 0, 1);
  final Animation<double> repaint;
  final ui.Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    assert(shadowOpacity >= 0 && shadowOpacity <= 1);
    final Offset center = Offset(size.width / 2, size.height / 2);
    final ui.RSuperellipse menuRect = RSuperellipse.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width, height: size.height),
      radius,
    );
    final double opacityMultiplier = switch (brightness) {
      ui.Brightness.light => lightShadowOpacity,
      ui.Brightness.dark => darkShadowOpacity,
    };
    final Paint shadowPaint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowOpacity * 50)
      ..color = ui.Color.fromRGBO(0, 0, 10, shadowOpacity * shadowOpacity * opacityMultiplier);
    final ui.Paint clearPaint = Paint()..blendMode = BlendMode.clear;

    canvas
      ..saveLayer(Rect.largest, Paint())
      ..drawRSuperellipse(menuRect.inflate(50), shadowPaint)
      ..drawRSuperellipse(menuRect, clearPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter oldDelegate) =>
      oldDelegate.brightness != brightness || oldDelegate.repaint != repaint;

  @override
  bool shouldRebuildSemantics(_ShadowPainter oldDelegate) => false;
}

class _MenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _MenuLayoutDelegate({
    required this.anchorRect,
    required this.menuAlignment,
    required this.padding,
    required this.attachmentPoint,
    required this.heightFactor,
    required this.avoidBounds,
  });

  // Rectangle anchoring the menu
  final ui.Rect anchorRect;

  // The offset of the menu from the top-left corner of the overlay.
  final ui.Offset attachmentPoint;

  // The resolved alignment of the menu attachment point relative to the menu surface.
  final Alignment menuAlignment;

  // Unsafe bounds used when constraining and positioning the menu.
  //
  // Used to prevent the menu from being obstructed by system UI.
  final EdgeInsets padding;

  // The factor by which to multiply the height of the child.
  final double heightFactor;

  // List of rectangles that the menu should not overlap. Unusable screen area.
  final Set<Rect> avoidBounds;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay.
    return BoxConstraints.loose(constraints.biggest);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double inverseHeightFactor = heightFactor > 0.01 ? 1 / heightFactor : 0;
    final Size finalSize = Size(childSize.width, childSize.height * inverseHeightFactor);
    final ui.Offset desiredPosition = attachmentPoint - menuAlignment.alongSize(childSize);
    final ui.Rect screen = _findClosestScreen(size, anchorRect.center, avoidBounds);
    final ui.Offset finalPosition = _positionChild(
      padding.deflateRect(screen),
      finalSize,
      desiredPosition,
      anchorRect,
    );
    final double fullHeight = finalSize.height;
    // If the menu sits above the anchor when fully open, grow upward:
    // keep the bottom (attachment) fixed by shifting the top-left during animation.
    final bool growsUp = finalPosition.dy + finalSize.height <= anchorRect.center.dy;
    if (growsUp) {
      final double dy = fullHeight - childSize.height;
      return Offset(finalPosition.dx, finalPosition.dy + dy);
    }

    final Offset initialPosition = Offset(finalPosition.dx, anchorRect.bottom);
    return Offset.lerp(initialPosition, finalPosition, heightFactor)!;
  }

  Offset _positionChild(Rect screen, Size childSize, Offset position, ui.Rect anchor) {
    double x = position.dx;
    double y = position.dy;

    bool overLeftEdge(double x) => x < screen.left;
    bool overRightEdge(double x) => x > screen.right - childSize.width;
    bool overTopEdge(double y) => y < screen.top;
    bool overBottomEdge(double y) => y > screen.bottom - childSize.height;

    // Layout horizontally first to determine if the menu can be placed on
    // either side of the anchor without overlapping.
    bool hasHorizontalAnchorOverlap = childSize.width >= screen.width;
    if (hasHorizontalAnchorOverlap) {
      x = screen.left;
    } else {
      if (overLeftEdge(x)) {
        // Flip the X position across the horizontal midpoint of the anchor so that the menu is to the right of the anchor.
        final double flipX = anchor.center.dx * 2 - position.dx - childSize.width;
        hasHorizontalAnchorOverlap = overRightEdge(flipX);
        if (hasHorizontalAnchorOverlap || overLeftEdge(flipX)) {
          x = screen.left;
        } else {
          x = flipX;
        }
      } else if (overRightEdge(x)) {
        // Flip the X position across the horizontal midpoint of the anchor so that the menu is to the left of the anchor.
        final double flipX = anchor.center.dx * 2 - position.dx - childSize.width;
        hasHorizontalAnchorOverlap = overLeftEdge(flipX);
        if (hasHorizontalAnchorOverlap || overRightEdge(flipX)) {
          x = screen.right - childSize.width;
        } else {
          x = flipX;
        }
      }
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

  // Finds the closest screen to the anchor point.
  //
  // This algorithm is different than the algorithms for PopupMenuButton and MenuAnchor,
  // since those widgets calculate the closest screen based on the center of the
  // overlay.
  Rect _findClosestScreen(Size parentSize, Offset point, Set<Rect> avoidBounds) {
    final Iterable<ui.Rect> screens = DisplayFeatureSubScreen.subScreensInBounds(
      Offset.zero & parentSize,
      avoidBounds,
    );

    Rect? closest;
    double closestSquaredDistance = 0;
    for (final ui.Rect screen in screens) {
      if (screen.contains(point)) {
        return screen;
      }

      if (closest == null) {
        closest = screen;
        closestSquaredDistance = _computeSquaredDistanceToRect(point, closest);
        continue;
      }

      final double squaredDistance = _computeSquaredDistanceToRect(point, screen);
      if (squaredDistance < closestSquaredDistance) {
        closest = screen;
        closestSquaredDistance = squaredDistance;
      }
    }

    return closest!;
  }

  @override
  bool shouldRelayout(_MenuLayoutDelegate oldDelegate) {
    return menuAlignment != oldDelegate.menuAlignment ||
        attachmentPoint != oldDelegate.attachmentPoint ||
        anchorRect != oldDelegate.anchorRect ||
        padding != oldDelegate.padding ||
        heightFactor != oldDelegate.heightFactor ||
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
      // Don't wrap on iOS or macOS.
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
      // Don't wrap on iOS or macOS.
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
/// The default thickness of the divider is 1 physical pixel.
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
    color: Color.fromRGBO(140, 140, 140, 0.3),
    darkColor: Color.fromRGBO(255, 255, 255, 0.25),
  );

  /// The default color applied to the [_CupertinoMenuDivider], atop the
  /// [overlayColor], with [BlendMode.srcOver].
  ///
  /// This color is used to make the divider more opaque.
  static const CupertinoDynamicColor color = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0.25),
    darkColor: Color.fromRGBO(255, 255, 255, 0.25),
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
      final Paint overlayPainter = border.toPaint()
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
///      MenuController controller,
///      Widget? child,
///    ) {
///      return CupertinoButton.filled(
///        onPressed: () {
///          if (controller.isOpen) {
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
/// [leadingMidpointAlignment] and [trailingMidpointAlignment] parameters control the alignment
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
/// ## Visuals
/// The [decoration] parameter can be used to change the background color of the
/// menu item when hovered, focused, pressed, or swiped. If these parameters are
/// not set, the menu item will use [CupertinoMenuItem._defaultDecoration].
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
    this.leadingMidpointAlignment,
    this.trailing,
    this.trailingWidth,
    this.trailingMidpointAlignment,
    this.padding,
    this.constraints,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
    this.onHover,
    this.onPressed,
    this.decoration,
    this.mouseCursor,
    this.statesController,
    this.behavior = HitTestBehavior.opaque,
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

  /// The widget shown before the label. Typically an [Icon].
  final Widget? leading;

  /// The widget shown after the label. Typically an [Icon].
  final Widget? trailing;

  /// A widget displayed underneath the [child]. Typically a [Text] widget.
  final Widget? subtitle;

  /// Called when this menu is tapped or otherwise activated.
  ///
  /// If a callback is not provided, then the button will be disabled.
  final VoidCallback? onPressed;

  /// Triggered when a pointer moves into a position within this widget without
  /// buttons pressed.
  ///
  /// Usually this is only fired for pointers which report their location when
  /// not down (e.g. mouse pointers). Certain devices also fire this event on
  /// single taps in accessibility mode.
  ///
  /// This callback is not triggered by the movement of the widget.
  ///
  /// The time that this callback is triggered is during the callback of a
  /// pointer event, which is always between frames.
  final ValueChanged<bool>? onHover;

  /// {@macro flutter.material.inkwell.onFocusChange}
  final ValueChanged<bool>? onFocusChange;

  /// Whether hovering should request focus for this widget.
  ///
  /// Defaults to true.
  final bool requestFocusOnHover;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// The decoration to paint behind the menu item.
  ///
  /// If null, defaults to [CupertinoMenuItem._defaultDecoration].
  final WidgetStateProperty<BoxDecoration>? decoration;

  /// The mouse cursor to display on hover.
  final WidgetStateProperty<MouseCursor>? mouseCursor;

  /// {@macro flutter.material.inkwell.statesController}
  final WidgetStatesController? statesController;

  /// How the menu item should respond to hit tests.
  final HitTestBehavior behavior;

  /// Determines if the menu will be closed when a [CupertinoMenuItem] is pressed.
  ///
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

  /// The alignment of the center point of the leading widget within the
  /// [leadingWidth] of the menu item.
  final AlignmentGeometry? leadingMidpointAlignment;

  /// The alignment of the center point of the trailing widget within the
  /// [trailingWidth] of the menu item.
  final AlignmentGeometry? trailingMidpointAlignment;

  /// The [BoxConstraints] to apply to the menu item.
  ///
  /// Because [padding] is applied to the menu item prior to [constraints], the [padding]
  /// will only affect the size of the menu item if the vertical [padding]
  /// plus the height of the menu item's children exceeds the
  /// [BoxConstraints.minHeight].
  final BoxConstraints? constraints;

  @override
  bool hasLeading(BuildContext context) => leading != null;

  @override
  bool get allowLeadingSeparator => true;

  @override
  bool get allowTrailingSeparator => true;

  /// The default mouse cursor for a [CupertinoMenuItem].
  static final WidgetStateProperty<MouseCursor> _defaultCursor =
      WidgetStateProperty.resolveWith<MouseCursor>((Set<WidgetState> states) {
        return !states.contains(WidgetState.disabled) && kIsWeb
            ? SystemMouseCursors.click
            : MouseCursor.defer;
      });

  // Obtained from the iOS 18.5 simulator debug view.
  static const Color _defaultTextColor = CupertinoDynamicColor.withBrightness(
    color: Color.from(alpha: 0.96, red: 0, green: 0, blue: 0),
    darkColor: Color.from(alpha: 0.96, red: 1, green: 1, blue: 1),
  );

  /// The default [Color] applied to a [CupertinoMenuItem]'s [subtitle]
  /// widget, if a subtitle is provided.
  // A custom blend mode is applied to the subtitle to mimic the visual effect
  // of the iOS menu subtitle. As a result, the defaultSubtitleStyle color does
  // not match the reported color on the iOS 18.5 simulator.
  static const Color _defaultSubtitleTextColor = CupertinoDynamicColor.withBrightness(
    color: Color.from(alpha: 0.55, red: 0, green: 0, blue: 0),
    darkColor: Color.from(alpha: 0.4, red: 1, green: 1, blue: 1),
  );

  /// The decoration of a [CupertinoMenuItem] when pressed.
  // Pressed colors were sampled from the iOS simulator and are based on the
  // following:
  //
  // Dark mode on white background     rgb(111, 111, 111)
  // Dark mode on black                rgb(61, 61, 61)
  // Light mode on black               rgb(177, 177, 177)
  // Light mode on white               rgb(225, 225, 225)
  //
  // Blend mode is used to mimic the visual effect of the iOS
  // menu item. As a result, the default pressed color does not match the
  // reported colors on the iOS 18.5 simulator.
  static const WidgetStateProperty<BoxDecoration> _defaultDecoration =
      WidgetStateProperty<BoxDecoration>.fromMap(<WidgetStatesConstraint, BoxDecoration>{
        WidgetState.dragged: BoxDecoration(
          color: CupertinoDynamicColor.withBrightness(
            color: Color.fromRGBO(50, 50, 50, 0.1),
            darkColor: Color.fromRGBO(255, 255, 255, 0.1),
          ),
        ),
        WidgetState.pressed: BoxDecoration(
          color: CupertinoDynamicColor.withBrightness(
            color: Color.fromRGBO(50, 50, 50, 0.1),
            darkColor: Color.fromRGBO(255, 255, 255, 0.1),
          ),
        ),
        WidgetState.focused: BoxDecoration(
          color: CupertinoDynamicColor.withBrightness(
            color: Color.fromRGBO(50, 50, 50, 0.075),
            darkColor: Color.fromRGBO(255, 255, 255, 0.075),
          ),
        ),
        WidgetState.hovered: BoxDecoration(
          color: CupertinoDynamicColor.withBrightness(
            color: Color.fromRGBO(50, 50, 50, 0.05),
            darkColor: Color.fromRGBO(255, 255, 255, 0.05),
          ),
        ),
        WidgetState.any: BoxDecoration(),
      });

  /// The maximum number of lines for the [child] widget when
  /// [MediaQuery.textScalerOf] returns a [TextScaler] that is less than or
  /// equal to 1.25.
  // Observed on the iOS and iPadOS 18.5 simulators.
  static const int defaultMaxLines = 2;

  /// The maximum number of lines for the [child] widget when
  /// [MediaQuery.textScalerOf] returns a [TextScaler] that is greater than
  /// 1.25.
  ///
  // Observed on the iOS and iPadOS 18.5 simulators.
  static const int defaultAccessibilityModeMaxLines = 100;

  /// The base font size multiplier for the [trailing] widget when
  /// [MediaQuery.textScalerOf] returns a [TextScaler] that is less than or
  /// equal to 1.25.
  static const double _trailingIconFontSizeMultiplier = 1.24;

  /// Resolves the title [TextStyle] in response to
  /// [CupertinoThemeData.brightness], [isDestructiveAction], and [enabled].
  //
  // Approximated from the iOS and iPadOS 18.5 simulators.
  TextStyle _resolveDefaultTextStyle(BuildContext context, TextScaler textScaler) {
    Color color;
    if (onPressed == null) {
      color = CupertinoColors.systemGrey;
    } else if (isDestructiveAction) {
      color = CupertinoColors.systemRed;
    } else {
      color = _defaultTextColor;
    }

    return _DynamicTypeStyle.body
        .resolveTextStyle(textScaler)
        .copyWith(
          // Font size will be scaled by TextScaler.
          fontSize: 17,
          color: CupertinoDynamicColor.resolve(color, context),
        );
  }

  TextStyle _resolveDefaultSubtitleStyle(BuildContext context, TextScaler textScaler) {
    final bool isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;
    return _DynamicTypeStyle.subhead
        .resolveTextStyle(textScaler)
        .copyWith(
          // Font size will be scaled by TextScaler.
          fontSize: 15,
          textBaseline: TextBaseline.alphabetic,
          foreground: Paint()
            // Per iOS 18.5 simulator:
            // Dark mode: linearDodge is used on iOS to achieve a lighter color.
            // This is approximated with BlendMode.plus.
            // For light mode: plusDarker is used on iOS to achieve a darker color.
            // HardLight is used as an approximation.
            ..blendMode = isDark ? BlendMode.plus : BlendMode.hardLight
            ..color = CupertinoDynamicColor.resolve(_defaultSubtitleTextColor, context),
        );
  }

  void _handleSelect(BuildContext context) {
    if (requestCloseOnActivate) {
      MenuController.maybeOf(context)?.close();
    }

    onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final TextScaler textScaler =
        MediaQuery.maybeTextScalerOf(context) ??
        TextScaler.linear(MediaQuery.maybeTextScaleFactorOf(context) ?? 1);
    final TextStyle defaultTextStyle = _resolveDefaultTextStyle(context, textScaler);
    final bool isAccessibilityModeEnabled = _isAccessibilityModeEnabled(context);
    Widget? leadingWidget;
    Widget? trailingWidget;

    if (leading != null) {
      leadingWidget = DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        child: IconTheme.merge(
          data: const IconThemeData(size: 15, weight: 600, applyTextScaling: true),
          child: leading!,
        ),
      );
    }

    if (trailing != null && !isAccessibilityModeEnabled) {
      final Widget child = DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 17),
        child: IconTheme.merge(
          data: const IconThemeData(size: 17, applyTextScaling: true),
          child: trailing!,
        ),
      );
      trailingWidget = Builder(
        builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScaler.scale(_trailingIconFontSizeMultiplier)),
            ),
            child: child,
          );
        },
      );
    }

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: _kMinimumTextScaleFactor,
      maxScaleFactor: _kMaximumTextScaleFactor,
      child: _CupertinoMenuItemInteractionHandler(
        mouseCursor: mouseCursor ?? _defaultCursor,
        requestFocusOnHover: requestFocusOnHover,
        onPressed: onPressed != null ? () => _handleSelect(context) : null,
        onHover: onHover,
        onFocusChange: onFocusChange,
        autofocus: autofocus,
        focusNode: focusNode,
        decoration: decoration ?? _defaultDecoration,
        statesController: statesController,
        behavior: behavior,
        child: DefaultTextStyle.merge(
          maxLines: isAccessibilityModeEnabled ? defaultAccessibilityModeMaxLines : defaultMaxLines,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          style: TextStyle(color: defaultTextStyle.color),
          child: IconTheme.merge(
            data: IconThemeData(color: defaultTextStyle.color),
            child: _CupertinoMenuItemLabel(
              padding: padding,
              constraints: constraints,
              trailing: trailingWidget,
              leading: leadingWidget,
              leadingMidpointAlignment: leadingMidpointAlignment,
              trailingMidpointAlignment: trailingMidpointAlignment,
              leadingWidth: leadingWidth,
              trailingWidth: trailingWidth,
              subtitle: subtitle != null
                  ? DefaultTextStyle.merge(
                      style: _resolveDefaultSubtitleStyle(context, textScaler),
                      child: subtitle!,
                    )
                  : null,
              child: DefaultTextStyle.merge(style: defaultTextStyle, child: child),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget?>('child', child));
    properties.add(
      FlagProperty(
        'requestCloseOnActivate',
        value: requestCloseOnActivate,
        ifTrue: 'closes on press',
        ifFalse: 'does not close on press',
        defaultValue: true,
      ),
    );

    properties.add(
      FlagProperty(
        'requestFocusOnHover',
        value: requestFocusOnHover,
        ifFalse: 'does not request focus on hover',
        ifTrue: 'requests focus on hover',
        defaultValue: true,
      ),
    );

    properties.add(EnumProperty<HitTestBehavior>('hitTestBehavior', behavior));
    properties.add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode, defaultValue: null));
    properties.add(FlagProperty('enabled', value: onPressed != null, ifFalse: 'DISABLED'));

    if (subtitle != null) {
      properties.add(DiagnosticsProperty<Widget?>('subtitle', subtitle));
    }
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
    this.subtitle,
    this.leading,
    this.leadingWidth,
    AlignmentGeometry? leadingMidpointAlignment,
    this.trailing,
    this.trailingWidth,
    AlignmentGeometry? trailingMidpointAlignment,
    BoxConstraints? constraints,
    this.padding,
  }) : _leadingAlignment = leadingMidpointAlignment,
       _trailingAlignment = trailingMidpointAlignment,
       _constraints = constraints;

  // Values were obtained from the iOS 18.5 simulator.
  static const double _defaultHorizontalWidth = 16;

  static const double _leadingWidthSlope = -311 / 1000;
  static const double _leadingWidthYIntercept = 10;

  static const double _leadingMidpointSlope = 118 / 1000000;
  static const double _leadingMidpointYIntercept = 73 / 125;

  static const double _trailingWidthSlope = 1 / 10;
  static const double _trailingWidthYIntercept = 22;

  static const double _firstBaselineToTopSlope = 14 / 11;
  static const double _lastBaselineToBottomSlope = 71 / 100;

  final Widget? leading;
  final double? leadingWidth;
  final AlignmentGeometry? _leadingAlignment;

  final Widget? trailing;
  final double? trailingWidth;
  final AlignmentGeometry? _trailingAlignment;

  final Widget child;
  final Widget? subtitle;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? _constraints;

  // Tested across all iOS dynamic type sizes on iOS and iPadOS 18.5 simulators.
  // Expected values deviate by no more than 1 physical pixel.
  double _resolveLeadingWidth(TextScaler textScaler, double pixelRatio, double lineHeight) {
    final double units = _normalizeTextScale(textScaler);
    final double value = _leadingWidthSlope * units + _leadingWidthYIntercept;
    return _quantize(value + lineHeight, to: 1 / pixelRatio);
  }

  // Tested across all iOS dynamic type sizes on iOS and iPadOS 18.5 simulators.
  // Expected values deviate by no more than 1 physical pixel.
  double _resolveTrailingWidth(TextScaler textScaler, double pixelRatio, double lineHeight) {
    final double units = _normalizeTextScale(textScaler);
    final double value = _trailingWidthSlope * units + _trailingWidthYIntercept;
    return _quantize(value + lineHeight, to: 1 / pixelRatio);
  }

  AlignmentGeometry _resolveTrailingAlignment(double trailingWidth) {
    final double horizontalOffset = trailingWidth / 2 + 6;
    final double horizontalRatio = (trailingWidth - horizontalOffset) / trailingWidth;
    final double horizontalAlignment = (horizontalRatio * 2) - 1;
    return AlignmentDirectional(horizontalAlignment, 0.0);
  }

  AlignmentGeometry _resolveLeadingAlignment(double leadingWidth, TextScaler textScaler) {
    final double units = _normalizeTextScale(textScaler);
    final double horizontalRatio = _leadingMidpointSlope * units + _leadingMidpointYIntercept;
    final double horizontalAlignment = (horizontalRatio * 2) - 1;
    return AlignmentDirectional(horizontalAlignment, 0.0);
  }

  double _resolveFirstBaselineToTop(double lineHeight, double pixelRatio) {
    return _quantize(lineHeight * _firstBaselineToTopSlope, to: 1 / pixelRatio);
  }

  double _resolveLastBaselineToBottom(double lineHeight, double pixelRatio) {
    return _quantize(lineHeight * _lastBaselineToBottomSlope, to: 1 / pixelRatio);
  }

  EdgeInsets _resolvePadding(double minimumHeight, double lineHeight) {
    final double padding = math.max(0, minimumHeight - lineHeight);
    return EdgeInsets.symmetric(vertical: padding / 2);
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final TextScaler textScaler = MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    final double pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final TextStyle dynamicBodyText = _DynamicTypeStyle.body.resolveTextStyle(textScaler);
    assert(dynamicBodyText.fontSize != null && dynamicBodyText.height != null);
    final double lineHeight = dynamicBodyText.fontSize! * dynamicBodyText.height!;
    final bool showLeadingWidget =
        leading != null || (CupertinoMenuAnchor.maybeHasLeadingOf(context) ?? false);

    // TODO(davidhicks980): Use last baseline layout when supported.
    // (https://github.com/flutter/flutter/issues/4614)

    // The actual menu item layout uses first and last baselines to position the
    // text, but Flutter does not support last baseline alignment.
    //
    // To approximate the padding, subtract the default height of a single line
    // of text from the height of a single-line menu item, and divide the result
    // in half to get an estimated top and bottom padding. The downside to this
    // approach is that child and subtitle text with different line heights may
    // appear to have uneven padding.
    final double minimumHeight =
        _resolveFirstBaselineToTop(lineHeight, pixelRatio) +
        _resolveLastBaselineToBottom(lineHeight, pixelRatio);
    final BoxConstraints constraints = _constraints ?? BoxConstraints(minHeight: minimumHeight);

    final EdgeInsetsGeometry resolvedPadding =
        padding ?? _resolvePadding(minimumHeight, lineHeight);

    final double resolvedLeadingWidth =
        leadingWidth ??
        (showLeadingWidget
            ? _resolveLeadingWidth(textScaler, pixelRatio, lineHeight)
            : _defaultHorizontalWidth);

    final double resolvedTrailingWidth =
        trailingWidth ??
        (trailing != null
            ? _resolveTrailingWidth(textScaler, pixelRatio, lineHeight)
            : _defaultHorizontalWidth);

    return ConstrainedBox(
      constraints: constraints,
      child: Padding(
        padding: resolvedPadding,
        child: Stack(
          children: <Widget>[
            if (showLeadingWidget)
              Positioned.directional(
                textDirection: textDirection,
                start: 0,
                top: 0,
                bottom: 0,
                width: resolvedLeadingWidth,
                child: _AlignMidpoint(
                  alignment:
                      _leadingAlignment ??
                      _resolveLeadingAlignment(resolvedLeadingWidth, textScaler),
                  child: leading,
                ),
              ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: resolvedLeadingWidth,
                end: resolvedTrailingWidth,
              ),
              child: subtitle == null
                  ? Align(alignment: AlignmentDirectional.centerStart, child: child)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[child, const SizedBox(height: 1), subtitle!],
                    ),
            ),
            if (trailing != null)
              // On iOS, the trailing widget is constrained to a maximum height
              // of minimumHeight - 12 and a maximum width of
              // resolvedTrailingWidth - 20. These constraints were omitted for
              // more flexibility.
              Positioned.directional(
                textDirection: textDirection,
                end: 0,
                top: 0,
                bottom: 0,
                width: resolvedTrailingWidth,
                child: _AlignMidpoint(
                  alignment: _trailingAlignment ?? _resolveTrailingAlignment(resolvedTrailingWidth),
                  child: trailing,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A widget that positions the midpoint of its child at an alignment within
/// itself.
///
/// Almost identical to [Align], but aligns the midpoint of the child rather
/// than the top-left corner.
class _AlignMidpoint extends SingleChildRenderObjectWidget {
  /// Creates a widget that positions its child's center point at a specific
  /// [alignment].
  ///
  /// The [alignment] parameter is required and must not
  /// be null.
  const _AlignMidpoint({required this.alignment, required super.child});

  /// The alignment for positioning the child's horizontal midpoint.
  final AlignmentGeometry alignment;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAlignMidpoint(
      alignment: alignment,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderAlignMidpoint renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = Directionality.maybeOf(context);
  }
}

class _RenderAlignMidpoint extends RenderPositionedBox {
  _RenderAlignMidpoint({super.alignment, super.textDirection});

  @override
  void alignChild() {
    assert(child != null);
    assert(!child!.debugNeedsLayout);
    assert(child!.hasSize);
    assert(hasSize);
    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    final ui.Offset offset = resolvedAlignment.alongSize(size) - child!.size.center(Offset.zero);
    final double dx = offset.dx.clamp(0.0, size.width - child!.size.width);
    final double dy = offset.dy.clamp(0.0, size.height - child!.size.height);

    childParentData.offset = Offset(dx, dy);
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      final Paint paint;
      if (child != null && !child!.size.isEmpty) {
        paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFFFFFF00);
        final BoxParentData childParentData = child!.parentData! as BoxParentData;
        // vertical alignment arrows
        final double headSize = math.min(childParentData.offset.dy * 0.2, 10.0);
        final ui.Size childSize = child!.size;
        final double horizontalMidpoint =
            offset.dx + childParentData.offset.dx + childSize.width / 2;
        final double verticalMidpoint =
            offset.dy + childParentData.offset.dy + childSize.height / 2;

        final ui.Path path = Path()
          // Top arrow
          ..moveTo(horizontalMidpoint, offset.dy)
          ..relativeLineTo(0.0, childParentData.offset.dy - headSize)
          ..relativeLineTo(headSize, 0.0)
          ..relativeLineTo(-headSize, headSize)
          ..relativeLineTo(-headSize, -headSize)
          ..relativeLineTo(headSize, 0.0)
          // Bottom arrow
          ..moveTo(horizontalMidpoint, offset.dy + size.height + headSize)
          ..relativeLineTo(0.0, -size.height + childSize.height + childParentData.offset.dy)
          ..relativeLineTo(headSize, 0)
          ..relativeLineTo(-headSize, -headSize)
          ..relativeLineTo(-headSize, headSize)
          ..relativeLineTo(headSize, 0)
          // Left arrow
          ..moveTo(offset.dx, verticalMidpoint)
          ..relativeLineTo(childParentData.offset.dx - headSize, 0.0)
          ..relativeLineTo(0.0, headSize)
          ..relativeLineTo(headSize, -headSize)
          ..relativeLineTo(-headSize, -headSize)
          ..relativeLineTo(0.0, headSize)
          // Right arrow
          ..moveTo(offset.dx + size.width, verticalMidpoint)
          ..relativeLineTo(
            -size.width + childSize.width + childParentData.offset.dx + headSize,
            0.0,
          )
          ..relativeLineTo(0.0, headSize)
          ..relativeLineTo(-headSize, -headSize)
          ..relativeLineTo(headSize, -headSize)
          ..relativeLineTo(0.0, headSize);
        context.canvas.drawPath(path, paint);
      } else {
        paint = Paint()..color = const Color(0x90909090);
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    }());
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
/// * [CupertinoMenuEntryMixin], a mixin that can be used to control whether
///   dividers are shown before or after a menu item.
class CupertinoLargeMenuDivider extends StatelessWidget with CupertinoMenuEntryMixin {
  /// Creates a large horizontal divider for a [CupertinoMenuAnchor].
  const CupertinoLargeMenuDivider({super.key, this.color = defaultColor});

  /// The color of the divider.
  ///
  /// Defaults to [CupertinoLargeMenuDivider.defaultColor].
  final Color color;

  @override
  bool get allowTrailingSeparator => false;

  @override
  bool get allowLeadingSeparator => false;

  @override
  bool hasLeading(BuildContext context) => false;

  /// Default color for a [CupertinoLargeMenuDivider].
  // The following colors were measured from debug mode on the iOS 18.5 simulator,
  static const CupertinoDynamicColor defaultColor = CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    darkColor: Color.fromRGBO(0, 0, 0, 0.16),
  );

  static const double _height = 8.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CupertinoDynamicColor.resolve(color, context),
      child: const SizedBox(height: _height, width: double.infinity),
    );
  }
}

class _CupertinoMenuItemInteractionHandler extends StatefulWidget {
  const _CupertinoMenuItemInteractionHandler({
    required this.onHover,
    required this.onPressed,
    required this.onFocusChange,
    required this.focusNode,
    required this.autofocus,
    required this.requestFocusOnHover,
    required this.behavior,
    required this.statesController,
    required this.mouseCursor,
    required this.decoration,
    required this.child,
  });

  final ValueChanged<bool>? onHover;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool requestFocusOnHover;
  final HitTestBehavior behavior;
  final WidgetStatesController? statesController;
  final WidgetStateProperty<MouseCursor> mouseCursor;
  final WidgetStateProperty<BoxDecoration> decoration;
  final Widget child;

  @override
  State<_CupertinoMenuItemInteractionHandler> createState() =>
      _CupertinoMenuItemInteractionHandlerState();
}

class _CupertinoMenuItemInteractionHandlerState extends State<_CupertinoMenuItemInteractionHandler>
    implements _SwipeTarget {
  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _handleActivation),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: _handleActivation),
  };

  // If a focus node isn't given to the widget, then we have to manage our own.
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  FocusNode? _internalFocusNode;

  WidgetStatesController? _internalStatesController;
  WidgetStatesController get _statesController {
    return widget.statesController ?? _internalStatesController!;
  }

  Map<Type, GestureRecognizerFactory>? gestures;

  bool get isHovered => _isHovered;
  bool _isHovered = false;
  set isHovered(bool value) {
    if (_isHovered != value) {
      _isHovered = value;
      _statesController.update(WidgetState.hovered, value);
    }
  }

  bool get isPressed => _isPressed;
  bool _isPressed = false;
  set isPressed(bool value) {
    if (_isPressed != value) {
      _isPressed = value;
      _statesController.update(WidgetState.pressed, value);
    }
  }

  bool get isSwiped => _isSwiped;
  bool _isSwiped = false;
  set isSwiped(bool value) {
    if (_isSwiped != value) {
      _isSwiped = value;
      _statesController.update(WidgetState.dragged, value);
    }
  }

  bool get isFocused => _isFocused;
  bool _isFocused = false;
  set isFocused(bool value) {
    if (_isFocused != value) {
      _isFocused = value;
      _statesController.update(WidgetState.focused, value);
    }
  }

  bool get isEnabled => _isEnabled;
  bool _isEnabled = false;
  set isEnabled(bool value) {
    if (_isEnabled != value) {
      _isEnabled = value;
      _statesController.update(WidgetState.disabled, !value);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }

    if (widget.statesController == null) {
      _internalStatesController = WidgetStatesController();
    }

    isEnabled = widget.onPressed != null;
    isFocused = _focusNode.hasPrimaryFocus;
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
        _internalFocusNode = FocusNode();
      }

      isFocused = _focusNode.hasPrimaryFocus;
    }

    if (widget.statesController != oldWidget.statesController) {
      if (widget.statesController != null) {
        _internalStatesController?.dispose();
        _internalStatesController = null;
      } else {
        assert(_internalStatesController == null);
        _internalStatesController = WidgetStatesController();
      }
    }

    if (widget.onPressed != oldWidget.onPressed) {
      if (widget.onPressed == null) {
        isEnabled = isHovered = isPressed = isSwiped = isFocused = false;
      } else {
        isEnabled = true;
      }
    }
  }

  @override
  bool didSwipeEnter() {
    if (!isEnabled) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
        HapticFeedback.selectionClick();
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        break;
    }

    isSwiped = true;
    return true;
  }

  @override
  void didSwipeLeave({bool pointerUp = false}) {
    if (isEnabled && pointerUp) {
      _handleActivation();
    }

    isSwiped = false;
  }

  @override
  void dispose() {
    _internalStatesController?.dispose();
    _internalStatesController = null;
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  void _handleFocusChange([bool? focused]) {
    isFocused = _focusNode.hasPrimaryFocus;
    widget.onFocusChange?.call(isFocused);
  }

  void _handleActivation([Intent? intent]) {
    isSwiped = isPressed = false;
    widget.onPressed?.call();
  }

  void _handleTapDown(TapDownDetails details) {
    isPressed = true;
  }

  void _handleTapUp(TapUpDetails? details) {
    isPressed = false;
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    isPressed = false;
  }

  void _handlePointerExit(PointerExitEvent event) {
    if (isHovered) {
      isHovered = isFocused = false;
      widget.onHover?.call(false);
    }
  }

  // TextButton.onHover and MouseRegion.onHover can't be used without triggering
  // focus on scroll.
  void _handlePointerHover(PointerHoverEvent event) {
    if (!isHovered) {
      isHovered = true;
      widget.onHover?.call(true);
      if (widget.requestFocusOnHover) {
        _focusNode.requestFocus();

        // Without invalidating the focus policy, switching to directional focus
        // may not originate at this node.
        FocusTraversalGroup.of(context).invalidateScopeData(FocusScope.of(context));
      }
    }
  }

  void _handleDismissMenu() {
    Actions.invoke(context, const DismissIntent());
  }

  Widget _buildStatefulWrapper(BuildContext context, Set<WidgetState> value, Widget? child) {
    final MouseCursor cursor = widget.mouseCursor.resolve(value);
    final BoxDecoration decoration = widget.decoration.resolve(value);
    final bool hasBackground = decoration.color != null || decoration.gradient != null;
    return MouseRegion(
      onHover: isEnabled ? _handlePointerHover : null,
      onExit: isEnabled ? _handlePointerExit : null,
      hitTestBehavior: HitTestBehavior.deferToChild,
      cursor: cursor,
      child: DecoratedBox(
        decoration: decoration.copyWith(
          color: CupertinoDynamicColor.maybeResolve(decoration.color, context),
          backgroundBlendMode: kIsWeb || !hasBackground || decoration.backgroundBlendMode != null
              ? decoration.backgroundBlendMode
              : CupertinoTheme.maybeBrightnessOf(context) == Brightness.light
              ? BlendMode.multiply
              : BlendMode.plus,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isEnabled) {
      final DeviceGestureSettings? gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
      gestures ??= <Type, GestureRecognizerFactory>{
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (TapGestureRecognizer instance) {
            instance
              ..onTapDown = _handleTapDown
              ..onTapUp = _handleTapUp
              ..onTapCancel = _handleTapCancel
              ..gestureSettings = gestureSettings;
          },
        ),
      };
    } else {
      gestures = null;
    }

    return MergeSemantics(
      child: Semantics.fromProperties(
        properties: SemanticsProperties(
          enabled: isEnabled,
          onDismiss: isEnabled ? _handleDismissMenu : null,
        ),
        child: MetaData(
          metaData: this,
          child: Actions(
            actions: isEnabled ? _actionMap : <Type, Action<Intent>>{},
            child: Focus(
              autofocus: isEnabled && widget.autofocus,
              focusNode: _focusNode,
              canRequestFocus: isEnabled,
              skipTraversal: !isEnabled,
              onFocusChange: _handleFocusChange,
              child: ValueListenableBuilder<Set<WidgetState>>(
                valueListenable: _statesController,
                builder: _buildStatefulWrapper,
                child: RawGestureDetector(
                  behavior: widget.behavior,
                  gestures: gestures ?? const <Type, GestureRecognizerFactory>{},
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mix into [State] to receive callbacks when a pointer enters or leaves while
/// down. The [StatefulWidget] this class is mixed into must be a descendant of
/// a [_SwipeRegion].
@optionalTypeArgs
abstract class _SwipeTarget {
  /// Called when a pointer enters the [_SwipeTarget]. Return true if the pointer
  /// should be considered "on" the [_SwipeTarget], and false otherwise (for
  /// example, when the [_SwipeTarget] is disabled).
  bool didSwipeEnter();

  /// Called when the swipe is ended or canceled. If `pointerUp` is true,
  /// then the pointer was removed from the screen while over this [_SwipeTarget].
  void didSwipeLeave({required bool pointerUp});
}

abstract class _SwipeSurfaceData {
  ui.Rect computeRect();
}

abstract class _SwipeRegionProvider {
  void attachSurface(_SwipeSurfaceData surface);
  void detachSurface(_SwipeSurfaceData surface);
  void beginSwipe(PointerDownEvent event, {Duration delay = Duration.zero, VoidCallback? onStart});
}

class _SwipeScope extends InheritedWidget {
  const _SwipeScope({required super.child, required this.state});
  final _SwipeRegionProvider state;

  @override
  bool updateShouldNotify(_SwipeScope oldWidget) {
    return state != oldWidget.state;
  }
}

class _SwipeRegion extends StatefulWidget {
  const _SwipeRegion({this.enabled = true, required this.onDistanceChanged, required this.child});

  final bool enabled;
  final ValueChanged<double> onDistanceChanged;
  final Widget child;

  static _SwipeRegionProvider of(BuildContext context) {
    final _SwipeScope? scope = context.dependOnInheritedWidgetOfExactType<_SwipeScope>();
    assert(scope != null, 'No SwipeRegion found in context');
    return scope!.state;
  }

  @override
  State<_SwipeRegion> createState() => _SwipeRegionState();
}

class _SwipeRegionState extends State<_SwipeRegion> implements _SwipeRegionProvider {
  final Set<_SwipeSurfaceData> _surfaces = <_SwipeSurfaceData>{};
  MultiDragGestureRecognizer? _recognizer;
  bool get _isSwiping => _position != null;
  ui.Offset? _position;

  @override
  void attachSurface(_SwipeSurfaceData surface) {
    _surfaces.add(surface);
  }

  @override
  void detachSurface(_SwipeSurfaceData surface) {
    _surfaces.remove(surface);
  }

  @override
  void beginSwipe(PointerDownEvent event, {Duration delay = Duration.zero, VoidCallback? onStart}) {
    if (!widget.enabled) {
      return;
    }

    if (_isSwiping) {
      assert(_recognizer != null);
      return;
    }

    if (_recognizer != null && _recognizer!.onStart == onStart) {
      bool delayMatches = true;
      if (_recognizer case final DelayedMultiDragGestureRecognizer recognizer) {
        delayMatches = recognizer.delay == delay;
      }
      if (delayMatches) {
        _recognizer!.addPointer(event);
        return;
      }
    }

    _recognizer?.dispose();
    _recognizer = null;

    Drag handleStart(Offset position) {
      onStart?.call();
      return _createSwipeHandle(position);
    }

    // Use a MultiDragGestureRecognizer instead of a SwipeGestureRecognizer
    // since the latter does not support delayed recognition.
    if (delay == Duration.zero) {
      _recognizer = ImmediateMultiDragGestureRecognizer(
        allowedButtonsFilter: (int button) => button == kPrimaryButton,
      )..onStart = handleStart;
    } else {
      _recognizer = DelayedMultiDragGestureRecognizer(
        delay: delay,
        allowedButtonsFilter: (int button) => button == kPrimaryButton,
      )..onStart = handleStart;
    }

    _recognizer!.gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    _recognizer!.addPointer(event);
  }

  @override
  void didUpdateWidget(_SwipeRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (!widget.enabled) {
        if (_isSwiping) {
          _position = null;
          widget.onDistanceChanged(0);
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

  void _handleSwipeEnd(DragEndDetails position) {
    _completeSwipe();
  }

  void _handleSwipeCancel() {
    _completeSwipe();
  }

  void _handleSwipeUpdate(DragUpdateDetails updateDetails, {bool onTarget = false}) {
    _position = _position! + updateDetails.delta;

    // We can't merge rects because the root menu anchor may not be contiguous.
    double minimumSquaredDistance = double.maxFinite;
    for (final _SwipeSurfaceData surface in _surfaces) {
      final double squaredDistance = _computeSquaredDistanceToRect(
        _position!,
        surface.computeRect(),
      );

      if (squaredDistance.floor() == 0) {
        widget.onDistanceChanged(0);
        return;
      }

      minimumSquaredDistance = math.min(squaredDistance, minimumSquaredDistance);
    }

    final double distance = minimumSquaredDistance == 0 ? 0 : math.sqrt(minimumSquaredDistance);
    widget.onDistanceChanged(distance);
  }

  Drag _createSwipeHandle(ui.Offset position) {
    assert(!_isSwiping, 'A new swipe should not begin while a swipe is active.');
    _position = position;
    return _SwipeHandle(
      router: this,
      viewId: View.of(context).viewId,
      initialPosition: position,
      onSwipeUpdate: _handleSwipeUpdate,
      onSwipeEnd: _handleSwipeEnd,
      onSwipeCanceled: _handleSwipeCancel,
    );
  }

  void _disposeInactiveRecognizer() {
    if (!_isSwiping && _recognizer != null) {
      _recognizer!.dispose();
      _recognizer = null;
    }
  }

  void _completeSwipe() {
    _position = null;
    widget.onDistanceChanged(0);
    if (!mounted) {
      // If the widget is not mounted, safely dispose of the recognizer.
      _disposeInactiveRecognizer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SwipeScope(state: this, child: widget.child);
  }
}

/// An area that can initiate swiping.
///
/// This widget registers with the nearest [_SwipeRegion] and exposes its position
/// as a [ui.Rect]. This [_SwipeSurface] will route [PointerDownEvent]s to its
/// [_SwipeRegion]. If a routed [PointerDownEvent] results in a swipe gesture, the
/// [_SwipeRegion] will use the combined [ui.Rect] of all registered [_SwipeSurface]s
/// to calculate the swiping distance.
class _SwipeSurface extends SingleChildRenderObjectWidget {
  /// Creates a swipe surface that registers with a parent [_SwipeRegion].
  const _SwipeSurface({required super.child, this.delay = Duration.zero, this.onStart});

  /// The delay before recognizing a swipe gesture.
  final Duration delay;
  final VoidCallback? onStart;

  @override
  _RenderSwipeableSurface createRenderObject(BuildContext context) {
    return _RenderSwipeableSurface(
      region: _SwipeRegion.of(context),
      delay: delay,
      onStart: onStart,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSwipeableSurface renderObject) {
    renderObject
      ..region = _SwipeRegion.of(context)
      ..delay = delay
      ..onStart = onStart;
  }
}

class _RenderSwipeableSurface extends RenderProxyBox implements _SwipeSurfaceData {
  _RenderSwipeableSurface({
    required _SwipeRegionProvider region,
    required this.delay,
    required this.onStart,
  }) : _region = region;

  _SwipeRegionProvider get region => _region;
  _SwipeRegionProvider _region;
  set region(_SwipeRegionProvider value) {
    if (_region != value) {
      _region.detachSurface(this);
      _region = value;
      _region.attachSurface(this);
    }
  }

  Duration delay;
  VoidCallback? onStart;

  @override
  ui.Rect computeRect() => localToGlobal(Offset.zero) & size;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _region.attachSurface(this);
  }

  @override
  void detach() {
    _region.detachSurface(this);
    super.detach();
  }

  @override
  void dispose() {
    _region.detachSurface(this);
    super.dispose();
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      _region.beginSwipe(event, delay: delay, onStart: onStart);
    }
  }
}

/// Handles swiping events for a [_SwipeRegion].
// This class was adapted from _DragAvatar.
class _SwipeHandle extends Drag {
  /// Creates a [_SwipeHandle] that handles swiping events for a [_SwipeRegion].
  _SwipeHandle({
    required Offset initialPosition,
    required this.viewId,
    required this.router,
    required this.onSwipeEnd,
    required this.onSwipeUpdate,
    required this.onSwipeCanceled,
  }) : _position = initialPosition {
    _updateSwipe();
  }

  final int viewId;
  final List<_SwipeTarget> _enteredTargets = <_SwipeTarget>[];
  final GestureDragUpdateCallback onSwipeUpdate;
  final GestureDragEndCallback onSwipeEnd;
  final GestureDragCancelCallback onSwipeCanceled;
  final _SwipeRegionState router;
  Offset _position;

  @override
  void update(DragUpdateDetails details) {
    final Offset oldPosition = _position;
    _position += details.delta;
    if (_position != oldPosition) {
      _updateSwipe();
      onSwipeUpdate.call(details);
    }
  }

  @override
  void end(DragEndDetails details) {
    _leaveAllEntered(pointerUp: true);
    onSwipeEnd.call(details);
  }

  @override
  void cancel() {
    _leaveAllEntered();
    onSwipeCanceled();
  }

  void _updateSwipe() {
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, _position, viewId);
    // Look for the RenderBoxes that corresponds to the hit target
    final List<_SwipeTarget> targets = <_SwipeTarget>[];
    for (final HitTestEntry entry in result.path) {
      if (entry.target case RenderMetaData(:final _SwipeTarget metaData)) {
        targets.add(metaData);
      }
    }

    if (_enteredTargets.isNotEmpty && targets.length >= _enteredTargets.length) {
      bool listsMatch = true;
      for (int i = 0; i < _enteredTargets.length; i++) {
        if (targets[i] != _enteredTargets[i]) {
          listsMatch = false;
          break;
        }
      }

      if (listsMatch) {
        return;
      }
    }

    // Leave old targets.
    _leaveAllEntered();

    // Enter new targets.
    for (final _SwipeTarget target in targets) {
      _enteredTargets.add(target);
      if (target.didSwipeEnter()) {
        return;
      }
    }
  }

  void _leaveAllEntered({bool pointerUp = false}) {
    for (int i = 0; i < _enteredTargets.length; i += 1) {
      _enteredTargets[i].didSwipeLeave(pointerUp: pointerUp);
    }
    _enteredTargets.clear();
  }
}

// Multiplies the values of two animations.
//
// This class is used to animate the scale of the menu when the user drags
// outside of the menu area.
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
