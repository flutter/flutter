// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'bottom_sheet_theme.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'constants.dart';
import 'curves.dart';
import 'debug.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'material_state.dart';
import 'scaffold.dart';
import 'theme.dart';

const Duration _bottomSheetEnterDuration = Duration(milliseconds: 250);
const Duration _bottomSheetExitDuration = Duration(milliseconds: 200);
const Curve _modalBottomSheetCurve = decelerateEasing;
const double _minFlingVelocity = 700.0;
const double _closeProgressThreshold = 0.5;
const double _defaultScrollControlDisabledMaxHeightRatio = 9.0 / 16.0;

/// A callback for when the user begins dragging the bottom sheet.
///
/// Used by [BottomSheet.onDragStart].
typedef BottomSheetDragStartHandler = void Function(DragStartDetails details);

/// A callback for when the user stops dragging the bottom sheet.
///
/// Used by [BottomSheet.onDragEnd].
typedef BottomSheetDragEndHandler = void Function(
  DragEndDetails details, {
  required bool isClosing,
});

/// A Material Design bottom sheet.
///
/// There are two kinds of bottom sheets in Material Design:
///
///  * _Persistent_. A persistent bottom sheet shows information that
///    supplements the primary content of the app. A persistent bottom sheet
///    remains visible even when the user interacts with other parts of the app.
///    Persistent bottom sheets can be created and displayed with the
///    [ScaffoldState.showBottomSheet] function or by specifying the
///    [Scaffold.bottomSheet] constructor parameter.
///
///  * _Modal_. A modal bottom sheet is an alternative to a menu or a dialog and
///    prevents the user from interacting with the rest of the app. Modal bottom
///    sheets can be created and displayed with the [showModalBottomSheet]
///    function.
///
/// The [BottomSheet] widget itself is rarely used directly. Instead, prefer to
/// create a persistent bottom sheet with [ScaffoldState.showBottomSheet] or
/// [Scaffold.bottomSheet], and a modal bottom sheet with [showModalBottomSheet].
///
/// See also:
///
///  * [showBottomSheet] and [ScaffoldState.showBottomSheet], for showing
///    non-modal "persistent" bottom sheets.
///  * [showModalBottomSheet], which can be used to display a modal bottom
///    sheet.
///  * [BottomSheetThemeData], which can be used to customize the default
///    bottom sheet property values.
///  * The Material 2 spec at <https://m2.material.io/components/sheets-bottom>.
///  * The Material 3 spec at <https://m3.material.io/components/bottom-sheets/overview>.
class BottomSheet extends StatefulWidget {
  /// Creates a bottom sheet.
  ///
  /// Typically, bottom sheets are created implicitly by
  /// [ScaffoldState.showBottomSheet], for persistent bottom sheets, or by
  /// [showModalBottomSheet], for modal bottom sheets.
  const BottomSheet({
    super.key,
    this.animationController,
    this.enableDrag = true,
    this.showDragHandle,
    this.dragHandleColor,
    this.dragHandleSize,
    this.onDragStart,
    this.onDragEnd,
    this.backgroundColor,
    this.shadowColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
    required this.onClosing,
    required this.builder,
  }) : assert(elevation == null || elevation >= 0.0);

  /// The animation controller that controls the bottom sheet's entrance and
  /// exit animations.
  ///
  /// The BottomSheet widget will manipulate the position of this animation, it
  /// is not just a passive observer.
  final AnimationController? animationController;

  /// Called when the bottom sheet begins to close.
  ///
  /// A bottom sheet might be prevented from closing (e.g., by user
  /// interaction) even after this callback is called. For this reason, this
  /// callback might be call multiple times for a given bottom sheet.
  final VoidCallback onClosing;

  /// A builder for the contents of the sheet.
  ///
  /// The bottom sheet will wrap the widget produced by this builder in a
  /// [Material] widget.
  final WidgetBuilder builder;

  /// If true, the bottom sheet can be dragged up and down and dismissed by
  /// swiping downwards.
  ///
  /// If [showDragHandle] is true, this only applies to the content below the drag handle,
  /// because the drag handle is always draggable.
  ///
  /// Default is true.
  ///
  /// If this is true, the [animationController] must not be null.
  /// Use [BottomSheet.createAnimationController] to create one, or provide
  /// another AnimationController.
  final bool enableDrag;

  /// Specifies whether a drag handle is shown.
  ///
  /// The drag handle appears at the top of the bottom sheet. The default color is
  /// [ColorScheme.onSurfaceVariant] with an opacity of 0.4 and can be customized
  /// using [dragHandleColor]. The default size is `Size(32,4)` and can be customized
  /// with [dragHandleSize].
  ///
  /// If null, then the value of  [BottomSheetThemeData.showDragHandle] is used. If
  /// that is also null, defaults to false.
  ///
  /// If this is true, the [animationController] must not be null.
  /// Use [BottomSheet.createAnimationController] to create one, or provide
  /// another AnimationController.
  final bool? showDragHandle;

  /// The bottom sheet drag handle's color.
  ///
  /// Defaults to [BottomSheetThemeData.dragHandleColor].
  /// If that is also null, defaults to [ColorScheme.onSurfaceVariant]
  /// with an opacity of 0.4.
  final Color? dragHandleColor;

  /// Defaults to [BottomSheetThemeData.dragHandleSize].
  /// If that is also null, defaults to Size(32, 4).
  final Size? dragHandleSize;

  /// Called when the user begins dragging the bottom sheet vertically, if
  /// [enableDrag] is true.
  ///
  /// Would typically be used to change the bottom sheet animation curve so
  /// that it tracks the user's finger accurately.
  final BottomSheetDragStartHandler? onDragStart;

  /// Called when the user stops dragging the bottom sheet, if [enableDrag]
  /// is true.
  ///
  /// Would typically be used to reset the bottom sheet animation curve, so
  /// that it animates non-linearly. Called before [onClosing] if the bottom
  /// sheet is closing.
  final BottomSheetDragEndHandler? onDragEnd;

  /// The bottom sheet's background color.
  ///
  /// Defines the bottom sheet's [Material.color].
  ///
  /// Defaults to null and falls back to [Material]'s default.
  final Color? backgroundColor;

  /// The color of the shadow below the sheet.
  ///
  /// If this property is null, then [BottomSheetThemeData.shadowColor] of
  /// [ThemeData.bottomSheetTheme] is used. If that is also null, the default value
  /// is transparent.
  ///
  /// See also:
  ///
  ///  * [elevation], which defines the size of the shadow below the sheet.
  ///  * [shape], which defines the shape of the sheet and its shadow.
  final Color? shadowColor;

  /// The z-coordinate at which to place this material relative to its parent.
  ///
  /// This controls the size of the shadow below the material.
  ///
  /// Defaults to 0. The value is non-negative.
  final double? elevation;

  /// The shape of the bottom sheet.
  ///
  /// Defines the bottom sheet's [Material.shape].
  ///
  /// Defaults to null and falls back to [Material]'s default.
  final ShapeBorder? shape;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defines the bottom sheet's [Material.clipBehavior].
  ///
  /// Use this property to enable clipping of content when the bottom sheet has
  /// a custom [shape] and the content can extend past this shape. For example,
  /// a bottom sheet with rounded corners and an edge-to-edge [Image] at the
  /// top.
  ///
  /// If this property is null then [BottomSheetThemeData.clipBehavior] of
  /// [ThemeData.bottomSheetTheme] is used. If that's null then the behavior
  /// will be [Clip.none].
  final Clip? clipBehavior;

  /// Defines minimum and maximum sizes for a [BottomSheet].
  ///
  /// If null, then the ambient [ThemeData.bottomSheetTheme]'s
  /// [BottomSheetThemeData.constraints] will be used. If that
  /// is null and [ThemeData.useMaterial3] is true, then the bottom sheet
  /// will have a max width of 640dp. If [ThemeData.useMaterial3] is false, then
  /// the bottom sheet's size will be constrained by its parent
  /// (usually a [Scaffold]). In this case, consider limiting the width by
  /// setting smaller constraints for large screens.
  ///
  /// If constraints are specified (either in this property or in the
  /// theme), the bottom sheet will be aligned to the bottom-center of
  /// the available space. Otherwise, no alignment is applied.
  final BoxConstraints? constraints;

  @override
  State<BottomSheet> createState() => _BottomSheetState();

  /// Creates an [AnimationController] suitable for a
  /// [BottomSheet.animationController].
  ///
  /// This API available as a convenience for a Material compliant bottom sheet
  /// animation. If alternative animation durations are required, a different
  /// animation controller could be provided.
  static AnimationController createAnimationController(TickerProvider vsync) {
    return AnimationController(
      duration: _bottomSheetEnterDuration,
      reverseDuration: _bottomSheetExitDuration,
      debugLabel: 'BottomSheet',
      vsync: vsync,
    );
  }
}

class _BottomSheetState extends State<BottomSheet> {

  final GlobalKey _childKey = GlobalKey(debugLabel: 'BottomSheet child');

  double get _childHeight {
    final RenderBox renderBox = _childKey.currentContext!.findRenderObject()! as RenderBox;
    return renderBox.size.height;
  }

  bool get _dismissUnderway => widget.animationController!.status == AnimationStatus.reverse;

  Set<MaterialState> dragHandleMaterialState = <MaterialState>{};

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      dragHandleMaterialState.add(MaterialState.dragged);
    });
    widget.onDragStart?.call(details);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(
      (widget.enableDrag || (widget.showDragHandle?? false)) && widget.animationController != null,
      "'BottomSheet.animationController' cannot be null when 'BottomSheet.enableDrag' or 'BottomSheet.showDragHandle' is true. "
      "Use 'BottomSheet.createAnimationController' to create one, or provide another AnimationController.",
    );
    if (_dismissUnderway) {
      return;
    }
    widget.animationController!.value -= details.primaryDelta! / _childHeight;
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(
      (widget.enableDrag || (widget.showDragHandle?? false)) && widget.animationController != null,
      "'BottomSheet.animationController' cannot be null when 'BottomSheet.enableDrag' or 'BottomSheet.showDragHandle' is true. "
      "Use 'BottomSheet.createAnimationController' to create one, or provide another AnimationController.",
    );
    if (_dismissUnderway) {
      return;
    }
    setState(() {
      dragHandleMaterialState.remove(MaterialState.dragged);
    });
    bool isClosing = false;
    if (details.velocity.pixelsPerSecond.dy > _minFlingVelocity) {
      final double flingVelocity = -details.velocity.pixelsPerSecond.dy / _childHeight;
      if (widget.animationController!.value > 0.0) {
        widget.animationController!.fling(velocity: flingVelocity);
      }
      if (flingVelocity < 0.0) {
        isClosing = true;
      }
    } else if (widget.animationController!.value < _closeProgressThreshold) {
      if (widget.animationController!.value > 0.0) {
        widget.animationController!.fling(velocity: -1.0);
      }
      isClosing = true;
    } else {
      widget.animationController!.forward();
    }

    widget.onDragEnd?.call(
      details,
      isClosing: isClosing,
    );

    if (isClosing) {
      widget.onClosing();
    }
  }

  bool extentChanged(DraggableScrollableNotification notification) {
    if (notification.extent == notification.minExtent && notification.shouldCloseOnMinExtent) {
      widget.onClosing();
    }
    return false;
  }

  void _handleDragHandleHover(bool hovering) {
    if (hovering != dragHandleMaterialState.contains(MaterialState.hovered)) {
      setState(() {
        if (hovering){
          dragHandleMaterialState.add(MaterialState.hovered);
        }
        else{
          dragHandleMaterialState.remove(MaterialState.hovered);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final BottomSheetThemeData bottomSheetTheme = Theme.of(context).bottomSheetTheme;
    final bool useMaterial3 = Theme.of(context).useMaterial3;
    final BottomSheetThemeData defaults = useMaterial3 ? _BottomSheetDefaultsM3(context) : const BottomSheetThemeData();
    final BoxConstraints? constraints = widget.constraints ?? bottomSheetTheme.constraints ?? defaults.constraints;
    final Color? color = widget.backgroundColor ?? bottomSheetTheme.backgroundColor ?? defaults.backgroundColor;
    final Color? surfaceTintColor = bottomSheetTheme.surfaceTintColor ?? defaults.surfaceTintColor;
    final Color? shadowColor = widget.shadowColor ?? bottomSheetTheme.shadowColor ?? defaults.shadowColor;
    final double elevation = widget.elevation ?? bottomSheetTheme.elevation ?? defaults.elevation ?? 0;
    final ShapeBorder? shape = widget.shape ?? bottomSheetTheme.shape ?? defaults.shape;
    final Clip clipBehavior = widget.clipBehavior ?? bottomSheetTheme.clipBehavior ?? Clip.none;
    final bool showDragHandle = widget.showDragHandle ?? (widget.enableDrag && (bottomSheetTheme.showDragHandle ?? false));

    Widget? dragHandle;
    if (showDragHandle){
      dragHandle = _DragHandle(
        onSemanticsTap: widget.onClosing,
        handleHover: _handleDragHandleHover,
        materialState: dragHandleMaterialState,
        dragHandleColor: widget.dragHandleColor,
        dragHandleSize: widget.dragHandleSize,
      );
      // Only add [_BottomSheetGestureDetector] to the drag handle when the rest of the
      // bottom sheet is not draggable. If the whole bottom sheet is draggable,
      // no need to add it.
      if (!widget.enableDrag) {
        dragHandle = _BottomSheetGestureDetector(
          onVerticalDragStart: _handleDragStart,
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          child: dragHandle,
        );
      }
    }

    Widget bottomSheet = Material(
      key: _childKey,
      color: color,
      elevation: elevation,
      surfaceTintColor: surfaceTintColor,
      shadowColor: shadowColor,
      shape: shape,
      clipBehavior: clipBehavior,
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: extentChanged,
        child: !showDragHandle
          ? widget.builder(context)
          : Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                dragHandle!,
                Padding(
                  padding: const EdgeInsets.only(top: kMinInteractiveDimension),
                  child: widget.builder(context),
                ),
              ],
            ),
      ),
    );

    if (constraints != null) {
      bottomSheet = Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: constraints,
          child: bottomSheet,
        ),
      );
    }

    return !widget.enableDrag ? bottomSheet : _BottomSheetGestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: bottomSheet,
    );
  }
}

// PERSISTENT BOTTOM SHEETS

// See scaffold.dart

typedef _SizeChangeCallback<Size> = void Function(Size);

class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.onSemanticsTap,
    required this.handleHover,
    required this.materialState,
    this.dragHandleColor,
    this.dragHandleSize,
  });

  final VoidCallback? onSemanticsTap;
  final ValueChanged<bool> handleHover;
  final Set<MaterialState> materialState;
  final Color? dragHandleColor;
  final Size? dragHandleSize;

  @override
  Widget build(BuildContext context) {
    final BottomSheetThemeData bottomSheetTheme = Theme.of(context).bottomSheetTheme;
    final BottomSheetThemeData m3Defaults = _BottomSheetDefaultsM3(context);
    final Size handleSize = dragHandleSize ?? bottomSheetTheme.dragHandleSize ?? m3Defaults.dragHandleSize!;

    return MouseRegion(
      onEnter: (PointerEnterEvent event) => handleHover(true),
      onExit: (PointerExitEvent event) => handleHover(false),
      child: Semantics(
        label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        container: true,
        onTap: onSemanticsTap,
        child: SizedBox(
          height: kMinInteractiveDimension,
          width: kMinInteractiveDimension,
          child: Center(
            child: Container(
              height: handleSize.height,
              width: handleSize.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(handleSize.height/2),
                color: MaterialStateProperty.resolveAs<Color?>(dragHandleColor, materialState)
                  ?? MaterialStateProperty.resolveAs<Color?>(bottomSheetTheme.dragHandleColor, materialState)
                  ?? m3Defaults.dragHandleColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetLayoutWithSizeListener extends SingleChildRenderObjectWidget {
  const _BottomSheetLayoutWithSizeListener({
    required this.onChildSizeChanged,
    required this.animationValue,
    required this.isScrollControlled,
    required this.scrollControlDisabledMaxHeightRatio,
    super.child,
  });

  final _SizeChangeCallback<Size> onChildSizeChanged;
  final double animationValue;
  final bool isScrollControlled;
  final double scrollControlDisabledMaxHeightRatio;

  @override
  _RenderBottomSheetLayoutWithSizeListener createRenderObject(BuildContext context) {
    return _RenderBottomSheetLayoutWithSizeListener(
      onChildSizeChanged: onChildSizeChanged,
      animationValue: animationValue,
      isScrollControlled: isScrollControlled,
      scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderBottomSheetLayoutWithSizeListener renderObject) {
    renderObject.onChildSizeChanged = onChildSizeChanged;
    renderObject.animationValue = animationValue;
    renderObject.isScrollControlled = isScrollControlled;
    renderObject.scrollControlDisabledMaxHeightRatio = scrollControlDisabledMaxHeightRatio;
  }
}

class _RenderBottomSheetLayoutWithSizeListener extends RenderShiftedBox {
  _RenderBottomSheetLayoutWithSizeListener({
    RenderBox? child,
    required _SizeChangeCallback<Size> onChildSizeChanged,
    required double animationValue,
    required bool isScrollControlled,
    required double scrollControlDisabledMaxHeightRatio,
  }) : _onChildSizeChanged = onChildSizeChanged,
       _animationValue = animationValue,
       _isScrollControlled = isScrollControlled,
       _scrollControlDisabledMaxHeightRatio = scrollControlDisabledMaxHeightRatio,
       super(child);

  Size _lastSize = Size.zero;

  _SizeChangeCallback<Size> get onChildSizeChanged => _onChildSizeChanged;
  _SizeChangeCallback<Size> _onChildSizeChanged;
    set onChildSizeChanged(_SizeChangeCallback<Size> newCallback) {
    if (_onChildSizeChanged == newCallback) {
      return;
    }

    _onChildSizeChanged = newCallback;
    markNeedsLayout();
  }

  double get animationValue => _animationValue;
  double _animationValue;
  set animationValue(double newValue) {
    if (_animationValue == newValue) {
      return;
    }

    _animationValue = newValue;
    markNeedsLayout();
  }

  bool get isScrollControlled => _isScrollControlled;
  bool _isScrollControlled;
  set isScrollControlled(bool newValue) {
    if (_isScrollControlled == newValue) {
      return;
    }

    _isScrollControlled = newValue;
    markNeedsLayout();
  }

  double get scrollControlDisabledMaxHeightRatio => _scrollControlDisabledMaxHeightRatio;
  double _scrollControlDisabledMaxHeightRatio;
  set scrollControlDisabledMaxHeightRatio(double newValue) {
    if (_scrollControlDisabledMaxHeightRatio == newValue) {
      return;
    }

    _scrollControlDisabledMaxHeightRatio = newValue;
    markNeedsLayout();
  }

  Size _getSize(BoxConstraints constraints) {
    return constraints.constrain(constraints.biggest);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final double width = _getSize(BoxConstraints.tightForFinite(height: height)).width;
    if (width.isFinite) {
      return width;
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double width = _getSize(BoxConstraints.tightForFinite(height: height)).width;
    if (width.isFinite) {
      return width;
    }
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double height = _getSize(BoxConstraints.tightForFinite(width: width)).height;
    if (height.isFinite) {
      return height;
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double height = _getSize(BoxConstraints.tightForFinite(width: width)).height;
    if (height.isFinite) {
      return height;
    }
    return 0.0;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _getSize(constraints);
  }

  BoxConstraints _getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      maxHeight: isScrollControlled
          ? constraints.maxHeight
          : constraints.maxHeight * scrollControlDisabledMaxHeightRatio,
    );
  }

  Offset _getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, size.height - childSize.height * animationValue);
  }

  @override
  void performLayout() {
    size = _getSize(constraints);
    if (child != null) {
      final BoxConstraints childConstraints = _getConstraintsForChild(constraints);
      assert(childConstraints.debugAssertIsValid(isAppliedConstraint: true));
      child!.layout(childConstraints, parentUsesSize: !childConstraints.isTight);
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      childParentData.offset = _getPositionForChild(size, childConstraints.isTight ? childConstraints.smallest : child!.size);
      final Size childSize = childConstraints.isTight ? childConstraints.smallest : child!.size;

      if (_lastSize != childSize) {
        _lastSize = childSize;
        _onChildSizeChanged.call(_lastSize);
      }
    }
  }
}

class _ModalBottomSheet<T> extends StatefulWidget {
  const _ModalBottomSheet({
    super.key,
    required this.route,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
    this.isScrollControlled = false,
    this.scrollControlDisabledMaxHeightRatio = _defaultScrollControlDisabledMaxHeightRatio,
    this.enableDrag = true,
    this.showDragHandle = false,
  });

  final ModalBottomSheetRoute<T> route;
  final bool isScrollControlled;
  final double scrollControlDisabledMaxHeightRatio;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final BoxConstraints? constraints;
  final bool enableDrag;
  final bool showDragHandle;

  @override
  _ModalBottomSheetState<T> createState() => _ModalBottomSheetState<T>();
}

class _ModalBottomSheetState<T> extends State<_ModalBottomSheet<T>> {
  ParametricCurve<double> animationCurve = _modalBottomSheetCurve;

  String _getRouteLabel(MaterialLocalizations localizations) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return '';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return localizations.dialogLabel;
    }
  }

  EdgeInsets _getNewClipDetails(Size topLayerSize) {
    return EdgeInsets.fromLTRB(0, 0, 0, topLayerSize.height);
  }

  void handleDragStart(DragStartDetails details) {
    // Allow the bottom sheet to track the user's finger accurately.
    animationCurve = Curves.linear;
  }

  void handleDragEnd(DragEndDetails details, {bool? isClosing}) {
    // Allow the bottom sheet to animate smoothly from its current position.
    animationCurve = _BottomSheetSuspendedCurve(
      widget.route.animation!.value,
      curve: _modalBottomSheetCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final String routeLabel = _getRouteLabel(localizations);

    return AnimatedBuilder(
      animation: widget.route.animation!,
      child: BottomSheet(
        animationController: widget.route._animationController,
        onClosing: () {
          if (widget.route.isCurrent) {
            Navigator.pop(context);
          }
        },
        builder: widget.route.builder,
        backgroundColor: widget.backgroundColor,
        elevation: widget.elevation,
        shape: widget.shape,
        clipBehavior: widget.clipBehavior,
        constraints: widget.constraints,
        enableDrag: widget.enableDrag,
        showDragHandle: widget.showDragHandle,
        onDragStart: handleDragStart,
        onDragEnd: handleDragEnd,
      ),
      builder: (BuildContext context, Widget? child) {
        final double animationValue = animationCurve.transform(
            widget.route.animation!.value,
        );
        return Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: routeLabel,
          explicitChildNodes: true,
          child: ClipRect(
            child: _BottomSheetLayoutWithSizeListener(
              onChildSizeChanged: (Size size) {
                widget.route._didChangeBarrierSemanticsClip(
                  _getNewClipDetails(size),
                );
              },
              animationValue: animationValue,
              isScrollControlled: widget.isScrollControlled,
              scrollControlDisabledMaxHeightRatio: widget.scrollControlDisabledMaxHeightRatio,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// A route that represents a Material Design modal bottom sheet.
///
/// {@template flutter.material.ModalBottomSheetRoute}
/// A modal bottom sheet is an alternative to a menu or a dialog and prevents
/// the user from interacting with the rest of the app.
///
/// A closely related widget is a persistent bottom sheet, which shows
/// information that supplements the primary content of the app without
/// preventing the user from interacting with the app. Persistent bottom sheets
/// can be created and displayed with the [showBottomSheet] function or the
/// [ScaffoldState.showBottomSheet] method.
///
/// The [isScrollControlled] parameter specifies whether this is a route for
/// a bottom sheet that will utilize [DraggableScrollableSheet]. Consider
/// setting this parameter to true if this bottom sheet has
/// a scrollable child, such as a [ListView] or a [GridView],
/// to have the bottom sheet be draggable.
///
/// The [isDismissible] parameter specifies whether the bottom sheet will be
/// dismissed when user taps on the scrim.
///
/// The [enableDrag] parameter specifies whether the bottom sheet can be
/// dragged up and down and dismissed by swiping downwards.
///
/// The [useSafeArea] parameter specifies whether the sheet will avoid system
/// intrusions on the top, left, and right. If false, no SafeArea is added
/// and the top padding is consumed using [MediaQuery.removePadding].
/// Defaults to false.
///
/// The optional [backgroundColor], [elevation], [shape], [clipBehavior],
/// [constraints] and [transitionAnimationController]
/// parameters can be passed in to customize the appearance and behavior of
/// modal bottom sheets (see the documentation for these on [BottomSheet]
/// for more details).
///
/// The [transitionAnimationController] controls the bottom sheet's entrance and
/// exit animations. It's up to the owner of the controller to call
/// [AnimationController.dispose] when the controller is no longer needed.
///
/// The optional `settings` parameter sets the [RouteSettings] of the modal bottom sheet
/// sheet. This is particularly useful in the case that a user wants to observe
/// [PopupRoute]s within a [NavigatorObserver].
/// {@endtemplate}
///
/// {@macro flutter.widgets.RawDialogRoute}
///
/// See also:
///
///  * [showModalBottomSheet], which is a way to display a ModalBottomSheetRoute.
///  * [BottomSheet], which becomes the parent of the widget returned by the
///    function passed as the `builder` argument to [showModalBottomSheet].
///  * [showBottomSheet] and [ScaffoldState.showBottomSheet], for showing
///    non-modal bottom sheets.
///  * [DraggableScrollableSheet], creates a bottom sheet that grows
///    and then becomes scrollable once it reaches its maximum size.
///  * [DisplayFeatureSubScreen], which documents the specifics of how
///    [DisplayFeature]s can split the screen into sub-screens.
///  * The Material 2 spec at <https://m2.material.io/components/sheets-bottom>.
///  * The Material 3 spec at <https://m3.material.io/components/bottom-sheets/overview>.
class ModalBottomSheetRoute<T> extends PopupRoute<T> {
  /// A modal bottom sheet route.
  ModalBottomSheetRoute({
    required this.builder,
    this.capturedThemes,
    this.barrierLabel,
    this.barrierOnTapHint,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
    this.modalBarrierColor,
    this.isDismissible = true,
    this.enableDrag = true,
    this.showDragHandle,
    required this.isScrollControlled,
    this.scrollControlDisabledMaxHeightRatio = _defaultScrollControlDisabledMaxHeightRatio,
    super.settings,
    this.transitionAnimationController,
    this.anchorPoint,
    this.useSafeArea = false,
  });

  /// A builder for the contents of the sheet.
  ///
  /// The bottom sheet will wrap the widget produced by this builder in a
  /// [Material] widget.
  final WidgetBuilder builder;

  /// Stores a list of captured [InheritedTheme]s that are wrapped around the
  /// bottom sheet.
  ///
  /// Consider setting this attribute when the [ModalBottomSheetRoute]
  /// is created through [Navigator.push] and its friends.
  final CapturedThemes? capturedThemes;

  /// Specifies whether this is a route for a bottom sheet that will utilize
  /// [DraggableScrollableSheet].
  ///
  /// Consider setting this parameter to true if this bottom sheet has
  /// a scrollable child, such as a [ListView] or a [GridView],
  /// to have the bottom sheet be draggable.
  final bool isScrollControlled;

  /// The max height constraint ratio for the bottom sheet
  /// when [isScrollControlled] set to false,
  /// no ratio will be applied when [isScrollControlled] set to true.
  ///
  /// Defaults to 9 / 16.
  final double scrollControlDisabledMaxHeightRatio;

  /// The bottom sheet's background color.
  ///
  /// Defines the bottom sheet's [Material.color].
  ///
  /// If this property is not provided, it falls back to [Material]'s default.
  final Color? backgroundColor;

  /// The z-coordinate at which to place this material relative to its parent.
  ///
  /// This controls the size of the shadow below the material.
  ///
  /// Defaults to 0, must not be negative.
  final double? elevation;

  /// The shape of the bottom sheet.
  ///
  /// Defines the bottom sheet's [Material.shape].
  ///
  /// If this property is not provided, it falls back to [Material]'s default.
  final ShapeBorder? shape;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defines the bottom sheet's [Material.clipBehavior].
  ///
  /// Use this property to enable clipping of content when the bottom sheet has
  /// a custom [shape] and the content can extend past this shape. For example,
  /// a bottom sheet with rounded corners and an edge-to-edge [Image] at the
  /// top.
  ///
  /// If this property is null, the [BottomSheetThemeData.clipBehavior] of
  /// [ThemeData.bottomSheetTheme] is used. If that's null, the behavior defaults to [Clip.none]
  /// will be [Clip.none].
  final Clip? clipBehavior;

  /// Defines minimum and maximum sizes for a [BottomSheet].
  ///
  /// If null, the ambient [ThemeData.bottomSheetTheme]'s
  /// [BottomSheetThemeData.constraints] will be used. If that
  /// is null and [ThemeData.useMaterial3] is true, then the bottom sheet
  /// will have a max width of 640dp. If [ThemeData.useMaterial3] is false, then
  /// the bottom sheet's size will be constrained by its parent
  /// (usually a [Scaffold]). In this case, consider limiting the width by
  /// setting smaller constraints for large screens.
  ///
  /// If constraints are specified (either in this property or in the
  /// theme), the bottom sheet will be aligned to the bottom-center of
  /// the available space. Otherwise, no alignment is applied.
  final BoxConstraints? constraints;

  /// Specifies the color of the modal barrier that darkens everything below the
  /// bottom sheet.
  ///
  /// Defaults to `Colors.black54` if not provided.
  final Color? modalBarrierColor;

  /// Specifies whether the bottom sheet will be dismissed
  /// when user taps on the scrim.
  ///
  /// If true, the bottom sheet will be dismissed when user taps on the scrim.
  ///
  /// Defaults to true.
  final bool isDismissible;

  /// Specifies whether the bottom sheet can be dragged up and down
  /// and dismissed by swiping downwards.
  ///
  /// If true, the bottom sheet can be dragged up and down and dismissed by
  /// swiping downwards.
  ///
  /// This applies to the content below the drag handle, if showDragHandle is true.
  ///
  /// Defaults is true.
  final bool enableDrag;

  /// Specifies whether a drag handle is shown.
  ///
  /// The drag handle appears at the top of the bottom sheet. The default color is
  /// [ColorScheme.onSurfaceVariant] with an opacity of 0.4 and can be customized
  /// using dragHandleColor. The default size is `Size(32,4)` and can be customized
  /// with dragHandleSize.
  ///
  /// If null, then the value of  [BottomSheetThemeData.showDragHandle] is used. If
  /// that is also null, defaults to false.
  final bool? showDragHandle;

  /// The animation controller that controls the bottom sheet's entrance and
  /// exit animations.
  ///
  /// The BottomSheet widget will manipulate the position of this animation, it
  /// is not just a passive observer.
  final AnimationController? transitionAnimationController;

  /// {@macro flutter.widgets.DisplayFeatureSubScreen.anchorPoint}
  final Offset? anchorPoint;

  /// Whether to avoid system intrusions on the top, left, and right.
  ///
  /// If true, a [SafeArea] is inserted to keep the bottom sheet away from
  /// system intrusions at the top, left, and right sides of the screen.
  ///
  /// If false, the bottom sheet isn't exposed to the top padding of the
  /// MediaQuery.
  ///
  /// In either case, the bottom sheet extends all the way to the bottom of
  /// the screen, including any system intrusions.
  ///
  /// The default is false.
  final bool useSafeArea;

  /// {@template flutter.material.ModalBottomSheetRoute.barrierOnTapHint}
  /// The semantic hint text that informs users what will happen if they
  /// tap on the widget. Announced in the format of 'Double tap to ...'.
  ///
  /// If the field is null, the default hint will be used, which results in
  /// announcement of 'Double tap to activate'.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [barrierDismissible], which controls the behavior of the barrier when
  ///    tapped.
  ///  * [ModalBarrier], which uses this field as onTapHint when it has an onTap action.
  final String? barrierOnTapHint;

  final ValueNotifier<EdgeInsets> _clipDetailsNotifier = ValueNotifier<EdgeInsets>(EdgeInsets.zero);

  @override
  void dispose() {
    _clipDetailsNotifier.dispose();
    super.dispose();
  }

  /// Updates the details regarding how the [SemanticsNode.rect] (focus) of
  /// the barrier for this [ModalBottomSheetRoute] should be clipped.
  ///
  /// returns true if the clipDetails did change and false otherwise.
  bool _didChangeBarrierSemanticsClip(EdgeInsets newClipDetails) {
    if (_clipDetailsNotifier.value == newClipDetails) {
      return false;
    }
    _clipDetailsNotifier.value = newClipDetails;
    return true;
  }

  @override
  Duration get transitionDuration => _bottomSheetEnterDuration;

  @override
  Duration get reverseTransitionDuration => _bottomSheetExitDuration;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  final String? barrierLabel;

  @override
  Color get barrierColor => modalBarrierColor ?? Colors.black54;

  AnimationController? _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    if (transitionAnimationController != null) {
      _animationController = transitionAnimationController;
      willDisposeAnimationController = false;
    } else {
      _animationController = BottomSheet.createAnimationController(navigator!);
    }
    return _animationController!;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final Widget content = DisplayFeatureSubScreen(
      anchorPoint: anchorPoint,
      child: Builder(
        builder: (BuildContext context) {
          final BottomSheetThemeData sheetTheme = Theme.of(context).bottomSheetTheme;
          final BottomSheetThemeData defaults = Theme.of(context).useMaterial3 ? _BottomSheetDefaultsM3(context) : const BottomSheetThemeData();
          return _ModalBottomSheet<T>(
            route: this,
            backgroundColor: backgroundColor ?? sheetTheme.modalBackgroundColor ?? sheetTheme.backgroundColor ?? defaults.backgroundColor,
            elevation: elevation ?? sheetTheme.modalElevation ?? defaults.modalElevation ?? sheetTheme.elevation,
            shape: shape,
            clipBehavior: clipBehavior,
            constraints: constraints,
            isScrollControlled: isScrollControlled,
            scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
            enableDrag: enableDrag,
            showDragHandle: showDragHandle ?? (enableDrag && (sheetTheme.showDragHandle ?? false)),
          );
        },
      ),
    );

    final Widget bottomSheet = useSafeArea
      ? SafeArea(bottom: false, child: content)
      : MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: content,
        );

    return capturedThemes?.wrap(bottomSheet) ?? bottomSheet;
  }

  @override
  Widget buildModalBarrier() {
    if (barrierColor.alpha != 0 && !offstage) { // changedInternalState is called if barrierColor or offstage updates
      assert(barrierColor != barrierColor.withOpacity(0.0));
      final Animation<Color?> color = animation!.drive(
        ColorTween(
          begin: barrierColor.withOpacity(0.0),
          end: barrierColor, // changedInternalState is called if barrierColor updates
        ).chain(CurveTween(curve: barrierCurve)), // changedInternalState is called if barrierCurve updates
      );
      return AnimatedModalBarrier(
        color: color,
        dismissible: barrierDismissible, // changedInternalState is called if barrierDismissible updates
        semanticsLabel: barrierLabel, // changedInternalState is called if barrierLabel updates
        barrierSemanticsDismissible: semanticsDismissible,
        clipDetailsNotifier: _clipDetailsNotifier,
        semanticsOnTapHint: barrierOnTapHint,
      );
    } else {
      return ModalBarrier(
        dismissible: barrierDismissible, // changedInternalState is called if barrierDismissible updates
        semanticsLabel: barrierLabel, // changedInternalState is called if barrierLabel updates
        barrierSemanticsDismissible: semanticsDismissible,
        clipDetailsNotifier: _clipDetailsNotifier,
        semanticsOnTapHint: barrierOnTapHint,
      );
    }
  }
}

// TODO(guidezpl): Look into making this public. A copy of this class is in
//  scaffold.dart, for now, https://github.com/flutter/flutter/issues/51627
/// A curve that progresses linearly until a specified [startingPoint], at which
/// point [curve] will begin. Unlike [Interval], [curve] will not start at zero,
/// but will use [startingPoint] as the Y position.
///
/// For example, if [startingPoint] is set to `0.5`, and [curve] is set to
/// [Curves.easeOut], then the bottom-left quarter of the curve will be a
/// straight line, and the top-right quarter will contain the entire contents of
/// [Curves.easeOut].
///
/// This is useful in situations where a widget must track the user's finger
/// (which requires a linear animation), and afterwards can be flung using a
/// curve specified with the [curve] argument, after the finger is released. In
/// such a case, the value of [startingPoint] would be the progress of the
/// animation at the time when the finger was released.
class _BottomSheetSuspendedCurve extends ParametricCurve<double> {
  /// Creates a suspended curve.
  const _BottomSheetSuspendedCurve(
    this.startingPoint, {
    this.curve = Curves.easeOutCubic,
  });

  /// The progress value at which [curve] should begin.
  final double startingPoint;

  /// The curve to use when [startingPoint] is reached.
  ///
  /// This defaults to [Curves.easeOutCubic].
  final Curve curve;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    assert(startingPoint >= 0.0 && startingPoint <= 1.0);

    if (t < startingPoint) {
      return t;
    }

    if (t == 1.0) {
      return t;
    }

    final double curveProgress = (t - startingPoint) / (1 - startingPoint);
    final double transformed = curve.transform(curveProgress);
    return lerpDouble(startingPoint, 1, transformed)!;
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($startingPoint, $curve)';
  }
}

/// Shows a modal Material Design bottom sheet.
///
/// {@macro flutter.material.ModalBottomSheetRoute}
///
/// {@macro flutter.widgets.RawDialogRoute}
///
/// The `context` argument is used to look up the [Navigator] and [Theme] for
/// the bottom sheet. It is only used when the method is called. Its
/// corresponding widget can be safely removed from the tree before the bottom
/// sheet is closed.
///
/// The `useRootNavigator` parameter ensures that the root navigator is used to
/// display the [BottomSheet] when set to `true`. This is useful in the case
/// that a modal [BottomSheet] needs to be displayed above all other content
/// but the caller is inside another [Navigator].
///
/// Returns a `Future` that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the modal bottom sheet was closed.
///
/// The 'barrierLabel' parameter can be used to set a custom barrierlabel.
/// Will default to modalBarrierDismissLabel of context if not set.
///
/// {@tool dartpad}
/// This example demonstrates how to use [showModalBottomSheet] to display a
/// bottom sheet that obscures the content behind it when a user taps a button.
/// It also demonstrates how to close the bottom sheet using the [Navigator]
/// when a user taps on a button inside the bottom sheet.
///
/// ** See code in examples/api/lib/material/bottom_sheet/show_modal_bottom_sheet.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This sample shows the creation of [showModalBottomSheet], as described in:
/// https://m3.material.io/components/bottom-sheets/overview
///
/// ** See code in examples/api/lib/material/bottom_sheet/show_modal_bottom_sheet.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [BottomSheet], which becomes the parent of the widget returned by the
///    function passed as the `builder` argument to [showModalBottomSheet].
///  * [showBottomSheet] and [ScaffoldState.showBottomSheet], for showing
///    non-modal bottom sheets.
///  * [DraggableScrollableSheet], creates a bottom sheet that grows
///    and then becomes scrollable once it reaches its maximum size.
///  * [DisplayFeatureSubScreen], which documents the specifics of how
///    [DisplayFeature]s can split the screen into sub-screens.
///  * The Material 2 spec at <https://m2.material.io/components/sheets-bottom>.
///  * The Material 3 spec at <https://m3.material.io/components/bottom-sheets/overview>.
Future<T?> showModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  double scrollControlDisabledMaxHeightRatio = _defaultScrollControlDisabledMaxHeightRatio,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
}) {
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));

  final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);
  return navigator.push(ModalBottomSheetRoute<T>(
    builder: builder,
    capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
    isScrollControlled: isScrollControlled,
    scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
    barrierLabel: barrierLabel ?? localizations.scrimLabel,
    barrierOnTapHint: localizations.scrimOnTapHint(localizations.bottomSheetLabel),
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    isDismissible: isDismissible,
    modalBarrierColor: barrierColor ?? Theme.of(context).bottomSheetTheme.modalBarrierColor,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    settings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
    useSafeArea: useSafeArea,
  ));
}

/// Shows a Material Design bottom sheet in the nearest [Scaffold] ancestor. To
/// show a persistent bottom sheet, use the [Scaffold.bottomSheet].
///
/// Returns a controller that can be used to close and otherwise manipulate the
/// bottom sheet.
///
/// The optional [backgroundColor], [elevation], [shape], [clipBehavior],
/// [constraints] and [transitionAnimationController]
/// parameters can be passed in to customize the appearance and behavior of
/// persistent bottom sheets (see the documentation for these on [BottomSheet]
/// for more details).
///
/// The [enableDrag] parameter specifies whether the bottom sheet can be
/// dragged up and down and dismissed by swiping downwards.
///
/// To rebuild the bottom sheet (e.g. if it is stateful), call
/// [PersistentBottomSheetController.setState] on the controller returned by
/// this method.
///
/// The new bottom sheet becomes a [LocalHistoryEntry] for the enclosing
/// [ModalRoute] and a back button is added to the app bar of the [Scaffold]
/// that closes the bottom sheet.
///
/// To create a persistent bottom sheet that is not a [LocalHistoryEntry] and
/// does not add a back button to the enclosing Scaffold's app bar, use the
/// [Scaffold.bottomSheet] constructor parameter.
///
/// A closely related widget is a modal bottom sheet, which is an alternative
/// to a menu or a dialog and prevents the user from interacting with the rest
/// of the app. Modal bottom sheets can be created and displayed with the
/// [showModalBottomSheet] function.
///
/// The `context` argument is used to look up the [Scaffold] for the bottom
/// sheet. It is only used when the method is called. Its corresponding widget
/// can be safely removed from the tree before the bottom sheet is closed.
///
/// See also:
///
///  * [BottomSheet], which becomes the parent of the widget returned by the
///    `builder`.
///  * [showModalBottomSheet], which can be used to display a modal bottom
///    sheet.
///  * [Scaffold.of], for information about how to obtain the [BuildContext].
///  * The Material 2 spec at <https://m2.material.io/components/sheets-bottom>.
///  * The Material 3 spec at <https://m3.material.io/components/bottom-sheets/overview>.
PersistentBottomSheetController<T> showBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  bool? enableDrag,
  AnimationController? transitionAnimationController,
}) {
  assert(debugCheckHasScaffold(context));

  return Scaffold.of(context).showBottomSheet<T>(
    builder,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    enableDrag: enableDrag,
    transitionAnimationController: transitionAnimationController,
  );
}

class _BottomSheetGestureDetector extends StatelessWidget {
  const _BottomSheetGestureDetector({
    required this.child,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
  });

  final Widget child;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      excludeFromSemantics: true,
      gestures: <Type, GestureRecognizerFactory<GestureRecognizer>>{
        VerticalDragGestureRecognizer : GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(debugOwner: this),
          (VerticalDragGestureRecognizer instance) {
            instance
              ..onStart = onVerticalDragStart
              ..onUpdate = onVerticalDragUpdate
              ..onEnd = onVerticalDragEnd
              ..onlyAcceptDragOnThreshold = true;
          },
        ),
      },
      child: child,
    );
  }
}

// BEGIN GENERATED TOKEN PROPERTIES - BottomSheet

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _BottomSheetDefaultsM3 extends BottomSheetThemeData {
  _BottomSheetDefaultsM3(this.context)
    : super(
      elevation: 1.0,
      modalElevation: 1.0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28.0))),
      constraints: const BoxConstraints(maxWidth: 640),
    );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color? get backgroundColor => _colors.surface;

  @override
  Color? get surfaceTintColor => _colors.surfaceTint;

  @override
  Color? get shadowColor => Colors.transparent;

  @override
  Color? get dragHandleColor => _colors.onSurfaceVariant.withOpacity(0.4);

  @override
  Size? get dragHandleSize => const Size(32, 4);

  @override
  BoxConstraints? get constraints => const BoxConstraints(maxWidth: 640.0);
}

// END GENERATED TOKEN PROPERTIES - BottomSheet
