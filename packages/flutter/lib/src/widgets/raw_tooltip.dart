// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
///
/// @docImport 'gesture_detector.dart';
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
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

const AnimationStyle _kDefaultAnimationStyle = AnimationStyle(
  curve: Curves.fastOutSlowIn,
  duration: Duration(milliseconds: 150),
  reverseDuration: Duration(milliseconds: 75),
);

/// Signature for building the tooltip overlay child.
///
/// The animation property exposes the underlying tooltip overlay child show
/// and hide animation. This can be used to drive animations that sync up with
/// the tooltip overlay child show/hide animation, for example to fade the
/// tooltip in and out.
typedef TooltipComponentBuilder =
    Widget Function(BuildContext context, Animation<double> animation);

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
// TODO(victorsanni): Consider removing preferBelow and verticalOffset since
// they are already available in the context of RawTooltip.
@immutable
class TooltipPositionContext {
  /// Creates a tooltip position context.
  const TooltipPositionContext({
    required this.target,
    required this.targetSize,
    required this.tooltipSize,
    required this.verticalOffset,
    this.preferBelow = true,
    this.overlaySize = Size.infinite,
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

  /// The size of the overlay within which the tooltip is displayed.
  final Size overlaySize;

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
        other.overlaySize == overlaySize &&
        other.verticalOffset == verticalOffset &&
        other.preferBelow == preferBelow;
  }

  @override
  int get hashCode =>
      Object.hash(target, targetSize, tooltipSize, overlaySize, verticalOffset, preferBelow);
}

/// How touch events should trigger a tooltip.
///
/// When using a pointer device like a mouse, a tooltip is shown as soon as
/// a pointer hovers over the widget, regardless of the value of
/// [RawTooltip.triggerMode].
///
/// A tooltip might also be triggered through other means regardless of this
/// option, such as by calling `ensureTooltipVisible`.
///
/// See also:
///
///  * [RawTooltip.triggerMode], which uses this enum.
///
/// See also:
///
///   * [RawTooltip.hoverDelay], which defines the length of time that
///     a pointer must hover over a tooltip's widget before the tooltip
///     will be shown.
enum TooltipTriggerMode {
  /// Tooltip will not be triggered by touch events.
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
typedef TooltipTriggeredCallback = VoidCallback;

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
  const _ExclusiveMouseRegion({super.onEnter, super.onExit, super.child});

  @override
  _RenderExclusiveMouseRegion createRenderObject(BuildContext context) {
    return _RenderExclusiveMouseRegion(onEnter: onEnter, onExit: onExit);
  }
}

class _RenderExclusiveMouseRegion extends RenderMouseRegion {
  _RenderExclusiveMouseRegion({super.onEnter, super.onExit});

  static bool isOutermostMouseRegion = true;
  static bool foundInnermostMouseRegion = false;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    var isHit = false;
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

/// A widget that wraps a child to display an informative overlay in response to
/// user interactions, such as hovering or long-pressing.
///
/// Tooltips provide essential context by displaying text labels or brief
/// descriptions that explain the function of a button or other user interface
/// elements.
///
/// The tooltip can be triggered in several ways:
///
///  * By hovering a mouse pointer over the widget.
///  * By touch interactions, such as a long press or a tap, depending on the
///    configuration of [triggerMode].
///  * Manually, by calling [RawTooltipState.ensureTooltipVisible].
///
/// See also:
///
///   * [Tooltip], a Material-themed [RawTooltip].
// TODO(victorsanni): https://github.com/flutter/flutter/issues/180318
// Add an example of how to call ensureTooltipVisible.
class RawTooltip extends StatefulWidget {
  /// Creates a raw tooltip.
  ///
  /// The [semanticsTooltip], [tooltipBuilder], and [child] arguments are
  /// required.
  const RawTooltip({
    super.key,
    required this.semanticsTooltip,
    required this.tooltipBuilder,
    this.hoverDelay = Duration.zero,
    this.touchDelay = const Duration(milliseconds: 1500),
    this.dismissDelay = const Duration(milliseconds: 100),
    this.enableTapToDismiss = true,
    this.triggerMode = TooltipTriggerMode.longPress,
    this.enableFeedback = true,
    this.onTriggered,
    this.animationStyle = _kDefaultAnimationStyle,
    this.positionDelegate,
    required this.child,
  });

  /// The text to display in the tooltip's semantics announcement.
  ///
  /// This string is used by assistive technologies, most notably screen readers
  /// like TalkBack and VoiceOver, to describe the tooltip's purpose.
  ///
  /// Providing a non-empty string adds a [Semantics] tooltip string for
  /// assistive technologies. If the tooltip should not have a semantic
  /// description, this property must be explicitly set to null.
  final String? semanticsTooltip;

  /// Builds the widget that will be displayed in the tooltip's overlay.
  ///
  /// The `animation` parameter is an [Animation] that maps to the tooltip's
  /// show and hide animation. Its value goes from 0.0 to 1.0 when the tooltip
  /// is shown, and from 1.0 to 0.0 when it is hidden.
  ///
  /// This animation can be used to create custom transitions for the tooltip,
  /// such as fading or scaling, by wrapping the tooltip's content in a
  /// [FadeTransition] or [ScaleTransition] and using the provided `animation`.
  ///
  /// The characteristics of the animation, such as its duration and curve, can
  /// be customized using the [RawTooltip.animationStyle] property.
  ///
  /// {@tool snippet}
  /// A common use case is to fade the tooltip's content in and out.
  ///
  /// ```dart
  /// RawTooltip(
  ///   semanticsTooltip: 'An example tooltip',
  ///   tooltipBuilder: (BuildContext context, Animation<double> animation) {
  ///     return FadeTransition(
  ///       opacity: animation,
  ///       child: Container(
  ///         padding: const EdgeInsets.all(8.0),
  ///         color: Colors.grey,
  ///         child: const Text('I am a tooltip!'),
  ///       ),
  ///     );
  ///   },
  ///   child: const Icon(Icons.info),
  /// )
  /// ```
  /// {@end-tool}
  final TooltipComponentBuilder tooltipBuilder;

  /// {@template flutter.widgets.RawTooltip.hoverDelay}
  /// The length of time that a pointer must hover over a tooltip's widget
  /// before the tooltip will be shown.
  ///
  /// Defaults to 0 milliseconds (the tooltip is shown immediately upon hover).
  /// {@endtemplate}
  final Duration hoverDelay;

  /// {@template flutter.widgets.RawTooltip.touchDelay}
  /// The length of time that the tooltip will be shown after a long press is
  /// released (if triggerMode is [TooltipTriggerMode.longPress]) or a tap is
  /// released (if triggerMode is [TooltipTriggerMode.tap]).
  ///
  /// This property does not affect mouse pointer devices.
  ///
  /// Defaults to 1.5 seconds (the tooltip is shown 1.5 seconds after a tap or
  /// long press is released).
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [dismissDelay], which allows configuring the time until a pointer
  /// disappears when hovering.
  final Duration touchDelay;

  /// {@template flutter.widgets.RawTooltip.dismissDelay}
  /// The length of time that a pointer must have stopped hovering over a
  /// tooltip's widget before the tooltip will be hidden.
  ///
  /// Defaults to 100 milliseconds.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [touchDelay], which allows configuring the length of time that a
  /// tooltip will be visible after touch events are released.
  final Duration dismissDelay;

  /// {@template flutter.widgets.RawTooltip.enableTapToDismiss}
  /// Whether the tooltip can be dismissed by tap.
  ///
  /// The default value is true.
  /// {@endtemplate}
  final bool enableTapToDismiss;

  /// {@template flutter.widgets.RawTooltip.triggerMode}
  /// The [TooltipTriggerMode] that will show the tooltip.
  ///
  /// This property does not affect mouse devices. Setting [triggerMode] to
  /// [TooltipTriggerMode.manual] will not prevent the tooltip from showing when
  /// the mouse cursor hovers over it.
  /// {@endtemplate}
  final TooltipTriggerMode triggerMode;

  /// {@template flutter.widgets.RawTooltip.enableFeedback}
  /// Whether the tooltip should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// When null, the default value is true.
  ///
  /// See also:
  ///
  ///  * [Feedback], for providing platform-specific feedback to certain
  ///  actions.
  /// {@endtemplate}
  final bool enableFeedback;

  /// {@template flutter.widgets.RawTooltip.onTriggered}
  /// Called when the [RawTooltip] is triggered programmatically, on tap, or on
  /// long press.
  ///
  /// The tooltip is triggered after a tap when [triggerMode] is
  /// [TooltipTriggerMode.tap] or after a long press when [triggerMode] is
  /// [TooltipTriggerMode.longPress].
  ///
  /// Hovering over the tooltip with a mouse pointer does not trigger this
  /// callback.
  ///
  /// See also:
  ///
  /// * [TooltipTriggerMode], which defines the different ways a tooltip can be
  ///   triggered.
  /// {@endtemplate}
  final TooltipTriggeredCallback? onTriggered;

  /// Used to override the curve and duration of the animation that shows and
  /// hides the tooltip.
  ///
  /// If [AnimationStyle.duration] is provided, it will be used to override
  /// the show tooltip animation duration. If it is null, defaults to 150ms.
  ///
  /// If [AnimationStyle.curve] is provided, it will be used to override
  /// the show tooltip animation curve. If it is null, defaults to
  /// [Curves.fastOutSlowIn].
  ///
  /// If [AnimationStyle.reverseDuration] is provided, it will be used to
  /// override the hide tooltip animation duration. If it is null, defaults to
  /// 75ms.
  ///
  /// If [AnimationStyle.reverseCurve] is provided, it will be used to override
  /// the hide tooltip animation curve. If it is null, the same curve will be
  /// used as for the show tooltip animation.
  ///
  /// To disable the tooltip show/hide animation, use
  /// [AnimationStyle.noAnimation].
  // TODO(victorsanni): Add an example of chaining a physics-based animation to
  // the tooltip's underlying animation.
  final AnimationStyle animationStyle;

  /// {@template flutter.widgets.RawTooltip.positionDelegate}
  /// A custom position delegate function for computing where the tooltip should
  /// be positioned.
  ///
  /// If provided, this function will be called with a [TooltipPositionContext]
  /// containing all the necessary information for positioning the tooltip. The
  /// function should return an [Offset] indicating where to place the tooltip
  /// in the closest [Overlay].
  ///
  /// This allows for custom positioning such as left/right positioning, or any
  /// other arbitrary positioning logic.
  ///
  /// For example, if the [Overlay] takes up the entire screen, returning
  /// [Offset.zero] will position the tooltip at the top-left corner of the
  /// screen.
  ///
  /// The [TooltipPositionContext] provides information that can be used to
  /// position the tooltip relative to the target/child.
  ///
  /// For example:
  /// ```dart
  /// positionDelegate: (TooltipPositionContext context) {
  ///   // Use the context information to position the tooltip to the right of
  ///   // the target.
  ///   return Offset(
  ///     context.target.dx + context.targetSize.width / 2,
  ///     context.target.dy - context.tooltipSize.height / 2,
  ///   );
  /// }
  /// ```
  ///
  /// If null, defaults to positioning the tooltip center-aligned and below the
  /// target using [positionDependentBox].
  ///
  /// See also:
  ///
  ///  * [TooltipPositionContext], which contains the positioning parameters.
  ///  * [TooltipPositionDelegate], the function signature for custom
  ///  positioning.
  /// {@endtemplate}
  final TooltipPositionDelegate? positionDelegate;

  /// The widget below this widget in the tree.
  ///
  /// The widget returned in [tooltipBuilder] will be shown when the user hovers
  /// over this child widget.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  static final List<RawTooltipState> _openedTooltips = <RawTooltipState>[];

  /// {@template flutter.widgets.RawTooltip.dismissAllToolTips}
  /// Dismiss all of the tooltips that are currently shown on the screen,
  /// including those with mouse cursors currently hovering over them.
  ///
  /// This method returns true if it successfully dismisses at least one tooltip
  /// and returns false if there is no tooltip currently displayed.
  /// {@endtemplate}
  static bool dismissAllToolTips() {
    if (_openedTooltips.isEmpty) {
      return false;
    }
    // Avoid concurrent modification.
    final List<RawTooltipState> openedTooltips = _openedTooltips.toList();
    for (final state in openedTooltips) {
      assert(state.mounted);
      state._scheduleDismissTooltip();
    }
    return true;
  }

  @override
  State<RawTooltip> createState() => RawTooltipState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty(
        'semantics',
        semanticsTooltip,
        showName: semanticsTooltip == null || semanticsTooltip!.isEmpty,
        defaultValue: semanticsTooltip == null || semanticsTooltip!.isEmpty
            ? null
            : kNoDefaultValue,
      ),
    );
    properties.add(DiagnosticsProperty<Duration>('hover delay', hoverDelay, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('touch delay', touchDelay, defaultValue: null));
    properties.add(
      DiagnosticsProperty<Duration>('dismiss delay', dismissDelay, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<TooltipTriggerMode>('triggerMode', triggerMode, defaultValue: null),
    );
    properties.add(
      FlagProperty('enableFeedback', value: enableFeedback, ifTrue: 'true', showName: true),
    );
    properties.add(
      DiagnosticsProperty<TooltipPositionDelegate>(
        'positionDelegate',
        positionDelegate,
        defaultValue: null,
      ),
    );
  }
}

/// Contains the state for a [RawTooltip].
///
/// This class can be used to programmatically show the [RawTooltip]. See the
/// [ensureTooltipVisible] method.
class RawTooltipState extends State<RawTooltip> with SingleTickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();

  Timer? _timer;
  AnimationController? _backingController;
  AnimationController get _controller {
    return _backingController ??= AnimationController(
      duration: widget.animationStyle.duration,
      reverseDuration: widget.animationStyle.reverseDuration,
      vsync: this,
    )..addStatusListener(_handleStatusChanged);
  }

  CurvedAnimation? _backingOverlayAnimation;
  CurvedAnimation get _overlayAnimation {
    return _backingOverlayAnimation ??= CurvedAnimation(
      parent: _controller,
      curve: widget.animationStyle.curve ?? _kDefaultAnimationStyle.curve!,
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
        SemanticsService.tooltip(widget.semanticsTooltip ?? '');
      case (true, true) || (false, false):
        break;
    }
    _animationStatus = status;
  }

  void _scheduleShowTooltip({required Duration withDelay, Duration? touchDelay}) {
    assert(mounted);
    void show() {
      assert(mounted);

      _controller.forward();
      _timer?.cancel();
      _timer = touchDelay == null ? null : Timer(touchDelay, _controller.reverse);
    }

    assert(
      !(_timer?.isActive ?? false) || _controller.status != AnimationStatus.reverse,
      'timer must not be active when the tooltip is animating out',
    );
    if (_controller.isDismissed && withDelay.inMicroseconds > 0) {
      _timer?.cancel();
      _timer = Timer(withDelay, show);
    } else {
      // If the tooltip is already animating in or fully visible, skip
      // the animation and show the tooltip immediately.
      show();
    }
  }

  void _scheduleDismissTooltip({Duration withDelay = Duration.zero}) {
    assert(mounted);
    assert(
      !(_timer?.isActive ?? false) || _backingController?.status != AnimationStatus.reverse,
      'timer must not be active when the tooltip is animating out',
    );

    _timer?.cancel();
    _timer = null;
    // Use _backingController instead of _controller to prevent the lazy getter
    // from instantiating an AnimationController unnecessarily.
    if (_backingController?.isForwardOrCompleted ?? false) {
      // Dismiss when the tooltip is animating in: if there's a dismiss delay
      // we'll allow the animation to continue until the delay timer fires.
      if (withDelay.inMicroseconds > 0) {
        _timer = Timer(withDelay, _controller.reverse);
      } else {
        _controller.reverse();
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    // PointerDeviceKinds that don't support hovering.
    const triggerModeDeviceKinds = <PointerDeviceKind>{
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
    _scheduleDismissTooltip();
    _activeHoveringPointerDevices.clear();
  }

  void _handleTap() {
    final bool tooltipCreated = _controller.isDismissed;
    if (tooltipCreated && widget.enableFeedback) {
      assert(widget.triggerMode == TooltipTriggerMode.tap);
      Feedback.forTap(context);
    }
    widget.onTriggered?.call();
    _scheduleShowTooltip(
      withDelay: Duration.zero,
      // _activeHoveringPointerDevices keep the tooltip visible.
      touchDelay: _activeHoveringPointerDevices.isEmpty ? widget.touchDelay : null,
    );
  }

  // When a "trigger" gesture is recognized and the pointer down even is a part
  // of it.
  void _handleLongPress() {
    final bool tooltipCreated = _controller.isDismissed;
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
    _scheduleDismissTooltip(withDelay: widget.touchDelay);
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
    for (final tooltip in tooltipsToDismiss) {
      assert(tooltip.mounted);
      tooltip._scheduleDismissTooltip();
    }
    _scheduleShowTooltip(
      withDelay: tooltipsToDismiss.isNotEmpty ? Duration.zero : widget.hoverDelay,
    );
  }

  void _handleMouseExit(PointerExitEvent event) {
    if (_activeHoveringPointerDevices.isEmpty) {
      return;
    }
    _activeHoveringPointerDevices.remove(event.device);
    if (_activeHoveringPointerDevices.isEmpty) {
      _scheduleDismissTooltip(withDelay: widget.dismissDelay);
    }
  }

  /// {@template flutter.widgets.RawTooltipState.ensureTooltipVisible}
  /// Shows the tooltip if it is not already visible.
  ///
  /// After made visible by this method, the tooltip does not automatically
  /// dismiss after [RawTooltip.hoverDelay] until the user dismisses/re-triggers it, or
  /// [RawTooltip.dismissAllToolTips] is called.
  ///
  /// Returns `false` when the tooltip shouldn't be shown or when the tooltip
  /// was already visible.
  /// {@endtemplate}
  bool ensureTooltipVisible() {
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

  Widget _buildTooltipOverlay(BuildContext context, OverlayChildLayoutInfo layoutInfo) {
    if (layoutInfo.childPaintTransform.determinant() == 0.0) {
      // The child is not visible.
      return const SizedBox.shrink();
    }
    final Offset target = MatrixUtils.transformPoint(
      layoutInfo.childPaintTransform,
      layoutInfo.childSize.center(Offset.zero),
    );

    // Keep the tooltip visible while the overlay child is hovered.
    final Widget tooltip = _ExclusiveMouseRegion(
      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,
      child: widget.tooltipBuilder(context, _overlayAnimation),
    );

    final Widget overlayChild = Positioned.fill(
      bottom: MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0.0,
      child: CustomSingleChildLayout(
        delegate: _TooltipPositionDelegate(
          target: target,
          targetSize: layoutInfo.childSize,
          positionDelegate: widget.positionDelegate,
        ),
        child: tooltip,
      ),
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
    if (widget.semanticsTooltip?.isEmpty ?? false) {
      return widget.child;
    }
    assert(debugCheckHasOverlay(context));
    final bool excludeFromSemantics =
        widget.semanticsTooltip == null || widget.semanticsTooltip!.isEmpty;
    // TODO(victorsanni): https://github.com/flutter/flutter/issues/180320
    // Add SemanticsRole.tooltip.
    Widget result = Semantics(
      tooltip: excludeFromSemantics ? null : widget.semanticsTooltip,
      child: widget.child,
    );

    // Only check for gestures if tooltip should be visible.
    result = _ExclusiveMouseRegion(
      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,
      child: Listener(
        onPointerDown: _handlePointerDown,
        behavior: HitTestBehavior.opaque,
        child: result,
      ),
    );

    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlayController,
      overlayChildBuilder: _buildTooltipOverlay,
      child: result,
    );
  }
}

/// A delegate for computing the layout of a tooltip to be displayed above or
/// below a target specified in the global coordinate system.
class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate for computing the layout of a tooltip.
  _TooltipPositionDelegate({required this.target, required this.targetSize, this.positionDelegate});

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  /// The size of the target widget that triggers the tooltip.
  final Size targetSize;

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
          overlaySize: size,
          verticalOffset: 0.0,
        ),
      );
    }
    return positionDependentBox(
      size: size,
      childSize: childSize,
      target: target,
      preferBelow: true,
    );
  }

  @override
  bool shouldRelayout(_TooltipPositionDelegate oldDelegate) {
    return target != oldDelegate.target ||
        targetSize != oldDelegate.targetSize ||
        positionDelegate != oldDelegate.positionDelegate;
  }
}
