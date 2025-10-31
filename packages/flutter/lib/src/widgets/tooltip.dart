// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'gesture_detector.dart';
library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'debug.dart';
import 'feedback.dart';
import 'framework.dart';
import 'media_query.dart';
import 'overlay.dart';
import 'selection_container.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

class _TooltipVisibilityScope extends InheritedWidget {
  const _TooltipVisibilityScope({required super.child, required this.visible});

  final bool visible;

  @override
  bool updateShouldNotify(_TooltipVisibilityScope old) {
    return old.visible != visible;
  }
}

/// Signature for computing the position of a tooltip.
///
/// The [TooltipPositionContext] contains all the necessary information for
/// positioning the tooltip, including the target location, sizes, offset, and
/// positioning preference.
///
/// Returns the offset from the top left of the overlay to the top left of the tooltip.
///
/// See also:
///
///  * [TooltipPositionContext], which contains the positioning parameters.
typedef TooltipPositionDelegate = Offset Function(TooltipPositionContext context);

/// Contextual information for positioning a tooltip.
///
/// This immutable data class contains all the necessary information for computing
/// the position of a tooltip relative to its target widget.
///
/// See also:
///
///  * [TooltipPositionDelegate], which uses this context to compute tooltip positions.
@immutable
class TooltipPositionContext {
  /// Creates a tooltip position context.
  const TooltipPositionContext({
    required this.target,
    required this.targetSize,
    required this.tooltipSize,
    required this.verticalOffset,
    required this.preferBelow,
  });

  /// The center point of the target widget in the global coordinate system.
  final Offset target;

  /// The size of the target widget that triggers the tooltip.
  final Size targetSize;

  /// The size of the tooltip itself.
  final Size tooltipSize;

  /// The configured vertical offset.
  final double verticalOffset;

  /// Whether the tooltip prefers to be positioned below the target.
  final bool preferBelow;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TooltipPositionContext &&
        other.target == target &&
        other.targetSize == targetSize &&
        other.tooltipSize == tooltipSize &&
        other.verticalOffset == verticalOffset &&
        other.preferBelow == preferBelow;
  }

  @override
  int get hashCode => Object.hash(target, targetSize, tooltipSize, verticalOffset, preferBelow);
}

/// Overrides the visibility of descendant [RawTooltip] widgets.
///
/// If disabled, the descendant [RawTooltip] widgets will not display a tooltip
/// when tapped, long-pressed, hovered by the mouse, or when
/// `ensureTooltipVisible` is called. This only visually disables tooltips but
/// continues to provide any semantic information that is provided.
class TooltipVisibility extends StatelessWidget {
  /// Creates a widget that configures the visibility of [Tooltip].
  const TooltipVisibility({super.key, required this.visible, required this.child});

  /// The widget below this widget in the tree.
  ///
  /// The entire app can be wrapped in this widget to globally control [Tooltip]
  /// visibility.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Determines the visibility of [Tooltip] widgets that inherit from this widget.
  final bool visible;

  /// The [visible] of the closest instance of this class that encloses the
  /// given context. Defaults to `true` if none are found.
  static bool of(BuildContext context) {
    final _TooltipVisibilityScope? visibility = context
        .dependOnInheritedWidgetOfExactType<_TooltipVisibilityScope>();
    return visibility?.visible ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return _TooltipVisibilityScope(visible: visible, child: child);
  }
}

/// The method of interaction that will trigger a tooltip.
/// Used in [RawTooltip.triggerMode].
///
/// On desktop, a tooltip will be shown as soon as a pointer hovers over
/// the widget, regardless of the value of [RawTooltip.triggerMode].
///
/// See also:
///
///   * [RawTooltip.waitDuration], which defines the length of time that
///     a pointer must hover over a tooltip's widget before the tooltip
///     will be shown.
enum TooltipTriggerMode {
  /// Tooltip will only be shown by calling `ensureTooltipVisible`.
  manual,

  /// Tooltip will be shown after a long press.
  ///
  /// See also:
  ///
  ///   * [GestureDetector.onLongPress], the event that is used for trigger.
  ///   * [Feedback.forLongPress], the feedback method called when feedback is enabled.
  longPress,

  /// Tooltip will be shown after a single tap.
  ///
  /// See also:
  ///
  ///   * [GestureDetector.onTap], the event that is used for trigger.
  ///   * [Feedback.forTap], the feedback method called when feedback is enabled.
  tap,
}

/// Signature for when a tooltip is triggered.
typedef TooltipTriggeredCallback = void Function();

/// A special [MouseRegion] that when nested, only the first [_ExclusiveMouseRegion]
/// to be hit in hit-testing order will be added to the BoxHitTestResult (i.e.,
/// child over parent, last sibling over first sibling).
///
/// The [onEnter] method will be called when a mouse pointer enters this
/// [MouseRegion], and there is no other [_ExclusiveMouseRegion]s obstructing
/// this [_ExclusiveMouseRegion] from receiving the events. This includes the
/// case where the mouse cursor stays within the paint bounds of an outer
/// [_ExclusiveMouseRegion], but moves outside of the bounds of the inner
/// [_ExclusiveMouseRegion] that was initially blocking the outer widget.
///
/// Likewise, [onExit] is called when the a mouse pointer moves out of the paint
/// bounds of this widget, or moves into another [_ExclusiveMouseRegion] that
/// overlaps this widget in hit-testing order.
///
/// This widget doesn't affect [MouseRegion]s that aren't [_ExclusiveMouseRegion]s,
/// or other [HitTestTarget]s in the tree.
class _ExclusiveMouseRegion extends MouseRegion {
  const _ExclusiveMouseRegion({super.onEnter, super.onExit, super.cursor, super.child});

  @override
  _RenderExclusiveMouseRegion createRenderObject(BuildContext context) {
    return _RenderExclusiveMouseRegion(onEnter: onEnter, onExit: onExit, cursor: cursor);
  }
}

class _RenderExclusiveMouseRegion extends RenderMouseRegion {
  _RenderExclusiveMouseRegion({super.onEnter, super.onExit, super.cursor});

  static bool isOutermostMouseRegion = true;
  static bool foundInnermostMouseRegion = false;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    bool isHit = false;
    final bool outermost = isOutermostMouseRegion;
    isOutermostMouseRegion = false;
    if (size.contains(position)) {
      isHit = hitTestChildren(result, position: position) || hitTestSelf(position);
      if ((isHit || behavior == HitTestBehavior.translucent) && !foundInnermostMouseRegion) {
        foundInnermostMouseRegion = true;
        result.add(BoxHitTestEntry(this, position));
      }
    }

    if (outermost) {
      // The outermost region resets the global states.
      isOutermostMouseRegion = true;
      foundInnermostMouseRegion = false;
    }
    return isHit;
  }
}

///
class RawTooltip extends StatefulWidget {
  ///
  const RawTooltip({
    super.key,
    required this.message,
    required this.tooltipBox,
    this.verticalOffset = 24.0,
    this.preferBelow = true,
    this.excludeFromSemantics = false,
    this.enableTapToDismiss = true,
    this.triggerMode = TooltipTriggerMode.longPress,
    this.enableFeedback = true,
    this.onTriggered,
    this.mouseCursor,
    this.ignorePointer = false,
    this.waitDuration = Duration.zero,
    this.showDuration = const Duration(milliseconds: 1500),
    this.exitDuration = const Duration(milliseconds: 100),
    this.positionDelegate,
    this.child,
  });

  ///
  final String message;

  ///
  final Widget tooltipBox;

  ///
  final double verticalOffset;

  ///
  final bool preferBelow;

  ///
  final bool excludeFromSemantics;

  ///
  final Duration waitDuration;

  ///
  final Duration showDuration;

  ///
  final Duration exitDuration;

  ///
  final bool enableTapToDismiss;

  ///
  final TooltipTriggerMode triggerMode;

  ///
  final bool enableFeedback;

  ///
  final TooltipTriggeredCallback? onTriggered;

  ///
  final MouseCursor? mouseCursor;

  ///
  final bool ignorePointer;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  static final List<RawTooltipState> _openedTooltips = <RawTooltipState>[];

  ///
  final TooltipPositionDelegate? positionDelegate;

  /// Dismiss all of the tooltips that are currently shown on the screen,
  /// including those with mouse cursors currently hovering over them.
  ///
  /// This method returns true if it successfully dismisses the tooltips. It
  /// returns false if there is no tooltip shown on the screen.
  static bool dismissAllToolTips() {
    if (_openedTooltips.isNotEmpty) {
      // Avoid concurrent modification.
      final List<RawTooltipState> openedTooltips = _openedTooltips.toList();
      for (final RawTooltipState state in openedTooltips) {
        assert(state.mounted);
        state._scheduleDismissTooltip(withDelay: Duration.zero);
      }
      return true;
    }
    return false;
  }

  @override
  State<RawTooltip> createState() => RawTooltipState();
}

///
class RawTooltipState extends State<RawTooltip> with SingleTickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();

  // From InheritedWidgets
  late bool _visible;

  Timer? _timer;
  AnimationController? _backingController;
  AnimationController get _controller {
    return _backingController ??= AnimationController(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 75),
      vsync: this,
    )..addStatusListener(_handleStatusChanged);
  }

  CurvedAnimation? _backingOverlayAnimation;
  CurvedAnimation get _overlayAnimation {
    return _backingOverlayAnimation ??= CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  LongPressGestureRecognizer? _longPressRecognizer;
  TapGestureRecognizer? _tapRecognizer;

  // The ids of mouse devices that are keeping the tooltip from being dismissed.
  //
  // Device ids are added to this set in _handleMouseEnter, and removed in
  // _handleMouseExit. The set is cleared in _handleTapToDismiss, typically when
  // a PointerDown event interacts with some other UI component.
  final Set<int> _activeHoveringPointerDevices = <int>{};

  AnimationStatus _animationStatus = AnimationStatus.dismissed;
  void _handleStatusChanged(AnimationStatus status) {
    assert(mounted);
    switch ((_animationStatus.isDismissed, status.isDismissed)) {
      case (false, true):
        RawTooltip._openedTooltips.remove(this);
        _overlayController.hide();
      case (true, false):
        _overlayController.show();
        RawTooltip._openedTooltips.add(this);
        SemanticsService.tooltip(widget.message);
      case (true, true) || (false, false):
        break;
    }
    _animationStatus = status;
  }

  void _scheduleShowTooltip({required Duration withDelay, Duration? showDuration}) {
    assert(mounted);
    void show() {
      assert(mounted);
      if (!_visible) {
        return;
      }

      _controller.forward();
      _timer?.cancel();
      _timer = showDuration == null ? null : Timer(showDuration, _controller.reverse);
    }

    assert(
      !(_timer?.isActive ?? false) || _controller.status != AnimationStatus.reverse,
      'timer must not be active when the tooltip is fading out',
    );
    if (_controller.isDismissed && withDelay.inMicroseconds > 0) {
      _timer?.cancel();
      _timer = Timer(withDelay, show);
    } else {
      show(); // If the tooltip is already fading in or fully visible, skip the
      // animation and show the tooltip immediately.
    }
  }

  void _scheduleDismissTooltip({required Duration withDelay}) {
    assert(mounted);
    assert(
      !(_timer?.isActive ?? false) || _backingController?.status != AnimationStatus.reverse,
      'timer must not be active when the tooltip is fading out',
    );

    _timer?.cancel();
    _timer = null;
    // Use _backingController instead of _controller to prevent the lazy getter
    // from instantiating an AnimationController unnecessarily.
    if (_backingController?.isForwardOrCompleted ?? false) {
      // Dismiss when the tooltip is fading in: if there's a dismiss delay we'll
      // allow the fade in animation to continue until the delay timer fires.
      if (withDelay.inMicroseconds > 0) {
        _timer = Timer(withDelay, _controller.reverse);
      } else {
        _controller.reverse();
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    // PointerDeviceKinds that don't support hovering.
    const Set<PointerDeviceKind> triggerModeDeviceKinds = <PointerDeviceKind>{
      PointerDeviceKind.invertedStylus,
      PointerDeviceKind.stylus,
      PointerDeviceKind.touch,
      PointerDeviceKind.unknown,
      // MouseRegion only tracks PointerDeviceKind == mouse.
      PointerDeviceKind.trackpad,
    };
    switch (widget.triggerMode) {
      case TooltipTriggerMode.longPress:
        final LongPressGestureRecognizer recognizer = _longPressRecognizer ??=
            LongPressGestureRecognizer(debugOwner: this, supportedDevices: triggerModeDeviceKinds);
        recognizer
          ..onLongPressCancel = _handleTapToDismiss
          ..onLongPress = _handleLongPress
          ..onLongPressUp = _handlePressUp
          ..addPointer(event);
      case TooltipTriggerMode.tap:
        final TapGestureRecognizer recognizer = _tapRecognizer ??= TapGestureRecognizer(
          debugOwner: this,
          supportedDevices: triggerModeDeviceKinds,
        );
        recognizer
          ..onTapCancel = _handleTapToDismiss
          ..onTap = _handleTap
          ..addPointer(event);
      case TooltipTriggerMode.manual:
        break;
    }
  }

  // For PointerDownEvents, this method will be called after _handlePointerDown.
  void _handleGlobalPointerEvent(PointerEvent event) {
    assert(mounted);
    if (_tapRecognizer?.primaryPointer == event.pointer ||
        _longPressRecognizer?.primaryPointer == event.pointer) {
      // This is a pointer of interest specified by the trigger mode, since it's
      // picked up by the recognizer.
      //
      // The recognizer will later determine if this is indeed a "trigger"
      // gesture and dismiss the tooltip if that's not the case. However there's
      // still a chance that the PointerEvent was cancelled before the gesture
      // recognizer gets to emit a tap/longPress down, in which case the onCancel
      // callback (_handleTapToDismiss) will not be called.
      return;
    }
    if ((_timer == null && _controller.isDismissed) || event is! PointerDownEvent) {
      return;
    }
    _handleTapToDismiss();
  }

  // The primary pointer is not part of a "trigger" gesture so the tooltip
  // should be dismissed.
  void _handleTapToDismiss() {
    if (!widget.enableTapToDismiss) {
      return;
    }
    _scheduleDismissTooltip(withDelay: Duration.zero);
    _activeHoveringPointerDevices.clear();
  }

  void _handleTap() {
    if (!_visible) {
      return;
    }
    final bool tooltipCreated = _controller.isDismissed;
    if (tooltipCreated && widget.enableFeedback) {
      assert(widget.triggerMode == TooltipTriggerMode.tap);
      Feedback.forTap(context);
    }
    widget.onTriggered?.call();
    _scheduleShowTooltip(
      withDelay: Duration.zero,
      // _activeHoveringPointerDevices keep the tooltip visible.
      showDuration: _activeHoveringPointerDevices.isEmpty ? widget.showDuration : null,
    );
  }

  // When a "trigger" gesture is recognized and the pointer down even is a part
  // of it.
  void _handleLongPress() {
    if (!_visible) {
      return;
    }
    final bool tooltipCreated = _visible && _controller.isDismissed;
    if (tooltipCreated && widget.enableFeedback) {
      assert(widget.triggerMode == TooltipTriggerMode.longPress);
      Feedback.forLongPress(context);
    }
    widget.onTriggered?.call();
    _scheduleShowTooltip(withDelay: Duration.zero);
  }

  void _handlePressUp() {
    if (_activeHoveringPointerDevices.isNotEmpty) {
      return;
    }
    _scheduleDismissTooltip(withDelay: widget.showDuration);
  }

  // # Current Hovering Behavior:
  // 1. Hovered tooltips don't show more than one at a time, for each mouse
  //    device. For example, a chip with a delete icon typically shouldn't show
  //    both the delete icon tooltip and the chip tooltip at the same time.
  // 2. Hovered tooltips are dismissed when:
  //    i. [dismissAllToolTips] is called, even these tooltips are still hovered
  //    ii. a unrecognized PointerDownEvent occurred within the application
  //    (even these tooltips are still hovered),
  //    iii. The last hovering device leaves the tooltip.
  void _handleMouseEnter(PointerEnterEvent event) {
    // _handleMouseEnter is only called when the mouse starts to hover over this
    // tooltip (including the actual tooltip it shows on the overlay), and this
    // tooltip is the first to be hit in the widget tree's hit testing order.
    // See also _ExclusiveMouseRegion for the exact behavior.
    _activeHoveringPointerDevices.add(event.device);
    // Dismiss other open tooltips unless they're kept visible by other mice.
    // The mouse tracker implementation always dispatches all `onExit` events
    // before dispatching any `onEnter` events, so `event.device` must have
    // already been removed from _activeHoveringPointerDevices of the tooltips
    // that are no longer being hovered over.
    final List<RawTooltipState> tooltipsToDismiss = RawTooltip._openedTooltips
        .where((RawTooltipState tooltip) => tooltip._activeHoveringPointerDevices.isEmpty)
        .toList();
    for (final RawTooltipState tooltip in tooltipsToDismiss) {
      assert(tooltip.mounted);
      tooltip._scheduleDismissTooltip(withDelay: Duration.zero);
    }
    _scheduleShowTooltip(
      withDelay: tooltipsToDismiss.isNotEmpty ? Duration.zero : widget.waitDuration,
    );
  }

  void _handleMouseExit(PointerExitEvent event) {
    if (_activeHoveringPointerDevices.isEmpty) {
      return;
    }
    _activeHoveringPointerDevices.remove(event.device);
    if (_activeHoveringPointerDevices.isEmpty) {
      _scheduleDismissTooltip(withDelay: widget.exitDuration);
    }
  }

  /// Shows the tooltip if it is not already visible.
  ///
  /// After made visible by this method, The tooltip does not automatically
  /// dismiss after `waitDuration`, until the user dismisses/re-triggers it, or
  /// [RawTooltip.dismissAllToolTips] is called.
  ///
  /// Returns `false` when the tooltip shouldn't be shown or when the tooltip
  /// was already visible.
  bool ensureTooltipVisible() {
    if (!_visible) {
      return false;
    }

    _timer?.cancel();
    _timer = null;
    if (_controller.isForwardOrCompleted) {
      return false;
    }
    _scheduleShowTooltip(withDelay: Duration.zero);
    return true;
  }

  @protected
  @override
  void initState() {
    super.initState();
    // Listen to global pointer events so that we can hide a tooltip immediately
    // if some other control is clicked on. Pointer events are dispatched to
    // global routes **after** other routes.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handleGlobalPointerEvent);
  }

  @protected
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TooltipVisibility.of(context);
  }

  Widget _buildTooltipOverlay(BuildContext context, OverlayChildLayoutInfo layoutInfo) {
    if (layoutInfo.childPaintTransform.determinant() == 0.0) {
      // The child is not visible.
      return const SizedBox.shrink();
    }
    final Offset target = MatrixUtils.transformPoint(
      layoutInfo.childPaintTransform,
      layoutInfo.childSize.center(Offset.zero),
    );
    final Size tooltipSize = layoutInfo.childSize;

    final _TooltipOverlay overlayChild = _TooltipOverlay(
      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,
      animation: _overlayAnimation,
      target: target,
      targetSize: tooltipSize,
      verticalOffset: widget.verticalOffset,
      preferBelow: widget.preferBelow,
      positionDelegate: widget.positionDelegate,
      ignorePointer: widget.ignorePointer,
      tooltipBox: widget.tooltipBox,
    );

    return SelectionContainer.maybeOf(context) == null
        ? overlayChild
        : SelectionContainer.disabled(child: overlayChild);
  }

  @protected
  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handleGlobalPointerEvent);
    RawTooltip._openedTooltips.remove(this);
    // _longPressRecognizer.dispose() and _tapRecognizer.dispose() may call
    // their registered onCancel callbacks if there's a gesture in progress.
    // Remove the onCancel callbacks to prevent the registered callbacks from
    // triggering unnecessary side effects (such as animations).
    _longPressRecognizer?.onLongPressCancel = null;
    _longPressRecognizer?.dispose();
    _tapRecognizer?.onTapCancel = null;
    _tapRecognizer?.dispose();
    _timer?.cancel();
    _backingController?.dispose();
    _backingOverlayAnimation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If message is empty then no need to create a tooltip overlay to show
    // the empty black container so just return the wrapped child as is or
    // empty container if child is not specified.
    if (widget.message.isEmpty) {
      return widget.child ?? const SizedBox.shrink();
    }
    assert(debugCheckHasOverlay(context));
    final bool excludeFromSemantics = widget.excludeFromSemantics;
    Widget result = Semantics(
      tooltip: excludeFromSemantics ? null : widget.message,
      child: widget.child,
    );

    // Only check for gestures if tooltip should be visible.
    if (_visible) {
      result = _ExclusiveMouseRegion(
        onEnter: _handleMouseEnter,
        onExit: _handleMouseExit,
        cursor: widget.mouseCursor ?? MouseCursor.defer,
        child: Listener(
          onPointerDown: _handlePointerDown,
          behavior: HitTestBehavior.opaque,
          child: result,
        ),
      );
    }
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlayController,
      overlayChildBuilder: _buildTooltipOverlay,
      child: result,
    );
  }
}

class _TooltipOverlay extends StatelessWidget {
  const _TooltipOverlay({
    required this.animation,
    required this.target,
    required this.targetSize,
    required this.verticalOffset,
    required this.preferBelow,
    required this.ignorePointer,
    required this.tooltipBox,
    this.positionDelegate,
    this.onEnter,
    this.onExit,
  });

  final Animation<double> animation;
  final Offset target;
  final Size targetSize;
  final double verticalOffset;
  final bool preferBelow;
  final TooltipPositionDelegate? positionDelegate;
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final bool ignorePointer;
  final Widget tooltipBox;

  @override
  Widget build(BuildContext context) {
    Widget result = FadeTransition(opacity: animation, child: tooltipBox);
    if (onEnter != null || onExit != null) {
      result = _ExclusiveMouseRegion(onEnter: onEnter, onExit: onExit, child: result);
    }
    return Positioned.fill(
      bottom: MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0.0,
      child: CustomSingleChildLayout(
        delegate: _TooltipPositionDelegate(
          target: target,
          targetSize: targetSize,
          verticalOffset: verticalOffset,
          preferBelow: preferBelow,
          positionDelegate: positionDelegate,
        ),
        child: IgnorePointer(ignoring: ignorePointer, child: result),
      ),
    );
  }
}

/// A delegate for computing the layout of a tooltip to be displayed above or
/// below a target specified in the global coordinate system.
class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate for computing the layout of a tooltip.
  _TooltipPositionDelegate({
    required this.target,
    required this.targetSize,
    required this.verticalOffset,
    required this.preferBelow,
    this.positionDelegate,
  });

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  /// The size of the target widget that triggers the tooltip.
  final Size targetSize;

  /// The amount of vertical distance between the target and the displayed
  /// tooltip.
  final double verticalOffset;

  /// Whether the tooltip is displayed below its widget by default.
  ///
  /// If there is insufficient space to display the tooltip in the preferred
  /// direction, the tooltip will be displayed in the opposite direction.
  final bool preferBelow;

  /// A custom position delegate function for computing where the tooltip should be positioned.
  ///
  /// If provided, this function will be called with a [TooltipPositionContext] instead
  /// of the default positioning logic.
  final TooltipPositionDelegate? positionDelegate;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    if (positionDelegate != null) {
      return positionDelegate!(
        TooltipPositionContext(
          target: target,
          targetSize: targetSize,
          tooltipSize: childSize,
          verticalOffset: verticalOffset,
          preferBelow: preferBelow,
        ),
      );
    }
    return positionDependentBox(
      size: size,
      childSize: childSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: preferBelow,
    );
  }

  @override
  bool shouldRelayout(_TooltipPositionDelegate oldDelegate) {
    return target != oldDelegate.target ||
        targetSize != oldDelegate.targetSize ||
        verticalOffset != oldDelegate.verticalOffset ||
        preferBelow != oldDelegate.preferBelow ||
        positionDelegate != oldDelegate.positionDelegate;
  }
}
