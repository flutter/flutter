// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'feedback.dart';
import 'theme.dart';
import 'tooltip_theme.dart';
import 'tooltip_visibility.dart';

/// Signature for when a tooltip is triggered.
typedef TooltipTriggeredCallback = void Function();

/// A Material Design tooltip.
///
/// Tooltips provide text labels which help explain the function of a button or
/// other user interface action. Wrap the button in a [Tooltip] widget and provide
/// a message which will be shown when the widget is long pressed.
///
/// Many widgets, such as [IconButton], [FloatingActionButton], and
/// [PopupMenuButton] have a `tooltip` property that, when non-null, causes the
/// widget to include a [Tooltip] in its build.
///
/// Tooltips improve the accessibility of visual widgets by proving a textual
/// representation of the widget, which, for example, can be vocalized by a
/// screen reader.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=EeEfD5fI-5Q}
///
/// {@tool dartpad}
/// This example show a basic [Tooltip] which has a [Text] as child.
/// [message] contains your label to be shown by the tooltip when
/// the child that Tooltip wraps is hovered over on web or desktop. On mobile,
/// the tooltip is shown when the widget is long pressed.
///
/// ** See code in examples/api/lib/material/tooltip/tooltip.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example covers most of the attributes available in Tooltip.
/// `decoration` has been used to give a gradient and borderRadius to Tooltip.
/// `height` has been used to set a specific height of the Tooltip.
/// `preferBelow` is false, the tooltip will prefer showing above [Tooltip]'s child widget.
/// However, it may show the tooltip below if there's not enough space
/// above the widget.
/// `textStyle` has been used to set the font size of the 'message'.
/// `showDuration` accepts a Duration to continue showing the message after the long
/// press has been released or the mouse pointer exits the child widget.
/// `waitDuration` accepts a Duration for which a mouse pointer has to hover over the child
/// widget before the tooltip is shown.
///
/// ** See code in examples/api/lib/material/tooltip/tooltip.1.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows a rich [Tooltip] that specifies the [richMessage]
/// parameter instead of the [message] parameter (only one of these may be
/// non-null. Any [InlineSpan] can be specified for the [richMessage] attribute,
/// including [WidgetSpan].
///
/// ** See code in examples/api/lib/material/tooltip/tooltip.2.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows how [Tooltip] can be shown manually with [TooltipTriggerMode.manual]
/// by calling the [TooltipState.ensureTooltipVisible] function.
///
/// ** See code in examples/api/lib/material/tooltip/tooltip.3.dart **
/// {@end-tool}
///
/// See also:
///
///  * <https://material.io/design/components/tooltips.html>
///  * [TooltipTheme] or [ThemeData.tooltipTheme]
///  * [TooltipVisibility]
class Tooltip extends StatefulWidget {
  /// Creates a tooltip.
  ///
  /// By default, tooltips should adhere to the
  /// [Material specification](https://material.io/design/components/tooltips.html#spec).
  /// If the optional constructor parameters are not defined, the values
  /// provided by [TooltipTheme.of] will be used if a [TooltipTheme] is present
  /// or specified in [ThemeData].
  ///
  /// All parameters that are defined in the constructor will
  /// override the default values _and_ the values in [TooltipTheme.of].
  ///
  /// Only one of [message] and [richMessage] may be non-null.
  const Tooltip({
    super.key,
    this.message,
    this.richMessage,
    this.height,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.preferBelow,
    this.excludeFromSemantics,
    this.decoration,
    this.textStyle,
    this.textAlign,
    this.waitDuration,
    this.showDuration,
    this.triggerMode,
    this.enableFeedback,
    this.onTriggered,
    this.child,
  }) :  assert((message == null) != (richMessage == null), 'Either `message` or `richMessage` must be specified'),
        assert(
          richMessage == null || textStyle == null,
          'If `richMessage` is specified, `textStyle` will have no effect. '
          'If you wish to provide a `textStyle` for a rich tooltip, add the '
          '`textStyle` directly to the `richMessage` InlineSpan.',
        );

  /// The text to display in the tooltip.
  ///
  /// Only one of [message] and [richMessage] may be non-null.
  final String? message;

  /// The rich text to display in the tooltip.
  ///
  /// Only one of [message] and [richMessage] may be non-null.
  final InlineSpan? richMessage;

  /// The height of the tooltip's [child].
  ///
  /// If the [child] is null, then this is the tooltip's intrinsic height.
  final double? height;

  /// The amount of space by which to inset the tooltip's [child].
  ///
  /// On mobile, defaults to 16.0 logical pixels horizontally and 4.0 vertically.
  /// On desktop, defaults to 8.0 logical pixels horizontally and 4.0 vertically.
  final EdgeInsetsGeometry? padding;

  /// The empty space that surrounds the tooltip.
  ///
  /// Defines the tooltip's outer [Container.margin]. By default, a
  /// long tooltip will span the width of its window. If long enough,
  /// a tooltip might also span the window's height. This property allows
  /// one to define how much space the tooltip must be inset from the edges
  /// of their display window.
  ///
  /// If this property is null, then [TooltipThemeData.margin] is used.
  /// If [TooltipThemeData.margin] is also null, the default margin is
  /// 0.0 logical pixels on all sides.
  final EdgeInsetsGeometry? margin;

  /// The vertical gap between the widget and the displayed tooltip.
  ///
  /// When [preferBelow] is set to true and tooltips have sufficient space to
  /// display themselves, this property defines how much vertical space
  /// tooltips will position themselves under their corresponding widgets.
  /// Otherwise, tooltips will position themselves above their corresponding
  /// widgets with the given offset.
  final double? verticalOffset;

  /// Whether the tooltip defaults to being displayed below the widget.
  ///
  /// Defaults to true. If there is insufficient space to display the tooltip in
  /// the preferred direction, the tooltip will be displayed in the opposite
  /// direction.
  final bool? preferBelow;

  /// Whether the tooltip's [message] or [richMessage] should be excluded from
  /// the semantics tree.
  ///
  /// Defaults to false. A tooltip will add a [Semantics] label that is set to
  /// [Tooltip.message] if non-null, or the plain text value of
  /// [Tooltip.richMessage] otherwise. Set this property to true if the app is
  /// going to provide its own custom semantics label.
  final bool? excludeFromSemantics;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// Specifies the tooltip's shape and background color.
  ///
  /// The tooltip shape defaults to a rounded rectangle with a border radius of
  /// 4.0. Tooltips will also default to an opacity of 90% and with the color
  /// [Colors.grey]\[700\] if [ThemeData.brightness] is [Brightness.dark], and
  /// [Colors.white] if it is [Brightness.light].
  final Decoration? decoration;

  /// The style to use for the message of the tooltip.
  ///
  /// If null, the message's [TextStyle] will be determined based on
  /// [ThemeData]. If [ThemeData.brightness] is set to [Brightness.dark],
  /// [TextTheme.bodyText2] of [ThemeData.textTheme] will be used with
  /// [Colors.white]. Otherwise, if [ThemeData.brightness] is set to
  /// [Brightness.light], [TextTheme.bodyText2] of [ThemeData.textTheme] will be
  /// used with [Colors.black].
  final TextStyle? textStyle;

  /// How the message of the tooltip is aligned horizontally.
  ///
  /// If this property is null, then [TooltipThemeData.textAlign] is used.
  /// If [TooltipThemeData.textAlign] is also null, the default value is
  /// [TextAlign.start].
  final TextAlign? textAlign;

  /// The length of time that a pointer must hover over a tooltip's widget
  /// before the tooltip will be shown.
  ///
  /// Defaults to 0 milliseconds (tooltips are shown immediately upon hover).
  final Duration? waitDuration;

  /// The length of time that the tooltip will be shown after a long press is
  /// released (if triggerMode is [TooltipTriggerMode.longPress]) or a tap is
  /// released (if triggerMode is [TooltipTriggerMode.tap]) or mouse pointer
  /// exits the widget.
  ///
  /// Defaults to 1.5 seconds for long press and tap released or 0.1 seconds
  /// for mouse pointer exits the widget.
  final Duration? showDuration;

  /// The [TooltipTriggerMode] that will show the tooltip.
  ///
  /// If this property is null, then [TooltipThemeData.triggerMode] is used.
  /// If [TooltipThemeData.triggerMode] is also null, the default mode is
  /// [TooltipTriggerMode.longPress].
  final TooltipTriggerMode? triggerMode;

  /// Whether the tooltip should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// When null, the default value is true.
  ///
  /// See also:
  ///
  ///  * [Feedback], for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  /// Called when the Tooltip is triggered.
  ///
  /// The tooltip is triggered after a tap when [triggerMode] is [TooltipTriggerMode.tap]
  /// or after a long press when [triggerMode] is [TooltipTriggerMode.longPress].
  final TooltipTriggeredCallback? onTriggered;

  static final List<TooltipState> _openedTooltips = <TooltipState>[];

  // Causes any current tooltips to be concealed. Only called for mouse hover enter
  // detections. Won't conceal the supplied tooltip.
  static void _concealOtherTooltips(TooltipState current) {
    if (_openedTooltips.isNotEmpty) {
      // Avoid concurrent modification.
      final List<TooltipState> openedTooltips = _openedTooltips.toList();
      for (final TooltipState state in openedTooltips) {
        if (state == current) {
          continue;
        }
        state._concealTooltip();
      }
    }
  }

  // Causes the most recently concealed tooltip to be revealed. Only called for mouse
  // hover exit detections.
  static void _revealLastTooltip() {
    if (_openedTooltips.isNotEmpty) {
      _openedTooltips.last._revealTooltip();
    }
  }

  /// Dismiss all of the tooltips that are currently shown on the screen.
  ///
  /// This method returns true if it successfully dismisses the tooltips. It
  /// returns false if there is no tooltip shown on the screen.
  static bool dismissAllToolTips() {
    if (_openedTooltips.isNotEmpty) {
      // Avoid concurrent modification.
      final List<TooltipState> openedTooltips = _openedTooltips.toList();
      for (final TooltipState state in openedTooltips) {
        state._dismissTooltip(immediately: true);
      }
      return true;
    }
    return false;
  }

  @override
  State<Tooltip> createState() => TooltipState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty(
      'message',
      message,
      showName: message == null,
      defaultValue: message == null ? null : kNoDefaultValue,
    ));
    properties.add(StringProperty(
      'richMessage',
      richMessage?.toPlainText(),
      showName: richMessage == null,
      defaultValue: richMessage == null ? null : kNoDefaultValue,
    ));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
    properties.add(DoubleProperty('vertical offset', verticalOffset, defaultValue: null));
    properties.add(FlagProperty('position', value: preferBelow, ifTrue: 'below', ifFalse: 'above', showName: true));
    properties.add(FlagProperty('semantics', value: excludeFromSemantics, ifTrue: 'excluded', showName: true));
    properties.add(DiagnosticsProperty<Duration>('wait duration', waitDuration, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('show duration', showDuration, defaultValue: null));
    properties.add(DiagnosticsProperty<TooltipTriggerMode>('triggerMode', triggerMode, defaultValue: null));
    properties.add(FlagProperty('enableFeedback', value: enableFeedback, ifTrue: 'true', showName: true));
    properties.add(DiagnosticsProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
  }
}

/// Contains the state for a [Tooltip].
///
/// This class can be used to programmatically show the Tooltip, see the
/// [ensureTooltipVisible] method.
class TooltipState extends State<Tooltip> with SingleTickerProviderStateMixin {
  static const double _defaultVerticalOffset = 24.0;
  static const bool _defaultPreferBelow = true;
  static const EdgeInsetsGeometry _defaultMargin = EdgeInsets.zero;
  static const Duration _fadeInDuration = Duration(milliseconds: 150);
  static const Duration _fadeOutDuration = Duration(milliseconds: 75);
  static const Duration _defaultShowDuration = Duration(milliseconds: 1500);
  static const Duration _defaultHoverShowDuration = Duration(milliseconds: 100);
  static const Duration _defaultWaitDuration = Duration.zero;
  static const bool _defaultExcludeFromSemantics = false;
  static const TooltipTriggerMode _defaultTriggerMode = TooltipTriggerMode.longPress;
  static const bool _defaultEnableFeedback = true;
  static const TextAlign _defaultTextAlign = TextAlign.start;

  late double _height;
  late EdgeInsetsGeometry _padding;
  late EdgeInsetsGeometry _margin;
  late Decoration _decoration;
  late TextStyle _textStyle;
  late TextAlign _textAlign;
  late double _verticalOffset;
  late bool _preferBelow;
  late bool _excludeFromSemantics;
  late AnimationController _controller;
  OverlayEntry? _entry;
  Timer? _dismissTimer;
  Timer? _showTimer;
  late Duration _showDuration;
  late Duration _hoverShowDuration;
  late Duration _waitDuration;
  late bool _mouseIsConnected;
  bool _pressActivated = false;
  late TooltipTriggerMode _triggerMode;
  late bool _enableFeedback;
  late bool _isConcealed;
  late bool _forceRemoval;
  late bool _visible;

  /// The plain text message for this tooltip.
  ///
  /// This value will either come from [widget.message] or [widget.richMessage].
  String get _tooltipMessage => widget.message ?? widget.richMessage!.toPlainText();

  @override
  void initState() {
    super.initState();
    _isConcealed = false;
    _forceRemoval = false;
    _mouseIsConnected = RendererBinding.instance.mouseTracker.mouseIsConnected;
    _controller = AnimationController(
      duration: _fadeInDuration,
      reverseDuration: _fadeOutDuration,
      vsync: this,
    )
      ..addStatusListener(_handleStatusChanged);
    // Listen to see when a mouse is added.
    RendererBinding.instance.mouseTracker.addListener(_handleMouseTrackerChange);
    // Listen to global pointer events so that we can hide a tooltip immediately
    // if some other control is clicked on.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TooltipVisibility.of(context);
  }

  // https://material.io/components/tooltips#specs
  double _getDefaultTooltipHeight() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 24.0;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return 32.0;
    }
  }

  EdgeInsets _getDefaultPadding() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0);
    }
  }

  double _getDefaultFontSize() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 12.0;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return 14.0;
    }
  }

  // Forces a rebuild if a mouse has been added or removed.
  void _handleMouseTrackerChange() {
    if (!mounted) {
      return;
    }
    final bool mouseIsConnected = RendererBinding.instance.mouseTracker.mouseIsConnected;
    if (mouseIsConnected != _mouseIsConnected) {
      setState(() {
        _mouseIsConnected = mouseIsConnected;
      });
    }
  }

  void _handleStatusChanged(AnimationStatus status) {
    // If this tip is concealed, don't remove it, even if it is dismissed, so that we can
    // reveal it later, unless it has explicitly been hidden with _dismissTooltip.
    if (status == AnimationStatus.dismissed && (_forceRemoval || !_isConcealed)) {
      _removeEntry();
    }
  }

  void _dismissTooltip({ bool immediately = false }) {
    _showTimer?.cancel();
    _showTimer = null;
    if (immediately) {
      _removeEntry();
      return;
    }
    // So it will be removed when it's done reversing, regardless of whether it is
    // still concealed or not.
    _forceRemoval = true;
    if (_pressActivated) {
      _dismissTimer ??= Timer(_showDuration, _controller.reverse);
    } else {
      _dismissTimer ??= Timer(_hoverShowDuration, _controller.reverse);
    }
    _pressActivated = false;
  }

  void _showTooltip({ bool immediately = false }) {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (immediately) {
      ensureTooltipVisible();
      return;
    }
    _showTimer ??= Timer(_waitDuration, ensureTooltipVisible);
  }

  void _concealTooltip() {
    if (_isConcealed || _forceRemoval) {
      // Already concealed, or it's being removed.
      return;
    }
    _isConcealed = true;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _showTimer?.cancel();
    _showTimer = null;
    if (_entry != null) {
      _entry!.remove();
    }
    _controller.reverse();
  }

  void _revealTooltip() {
    if (!_isConcealed) {
      // Already uncovered.
      return;
    }
    _isConcealed = false;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _showTimer?.cancel();
    _showTimer = null;
    if (!_entry!.mounted) {
      final OverlayState overlayState = Overlay.of(
        context,
        debugRequiredFor: widget,
      )!;
      overlayState.insert(_entry!);
    }
    SemanticsService.tooltip(_tooltipMessage);
    _controller.forward();
  }

  /// Shows the tooltip if it is not already visible.
  ///
  /// Returns `false` when the tooltip shouldn't be shown or when the tooltip
  /// was already visible.
  bool ensureTooltipVisible() {
    if (!_visible || !mounted) {
      return false;
    }
    _showTimer?.cancel();
    _showTimer = null;
    _forceRemoval = false;
    if (_isConcealed) {
      if (_mouseIsConnected) {
        Tooltip._concealOtherTooltips(this);
      }
      _revealTooltip();
      return true;
    }
    if (_entry != null) {
      // Stop trying to hide, if we were.
      _dismissTimer?.cancel();
      _dismissTimer = null;
      _controller.forward();
      return false; // Already visible.
    }
    _createNewEntry();
    _controller.forward();
    return true;
  }

  static final Set<TooltipState> _mouseIn = <TooltipState>{};

  void _handleMouseEnter() {
    if (mounted) {
      _showTooltip();
    }
  }

  void _handleMouseExit({bool immediately = false}) {
    if (mounted) {
      // If the tip is currently covered, we can just remove it without waiting.
      _dismissTooltip(immediately: _isConcealed || immediately);
    }
  }

  void _createNewEntry() {
    final OverlayState overlayState = Overlay.of(
      context,
      debugRequiredFor: widget,
    )!;

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset target = box.localToGlobal(
      box.size.center(Offset.zero),
      ancestor: overlayState.context.findRenderObject(),
    );

    // We create this widget outside of the overlay entry's builder to prevent
    // updated values from happening to leak into the overlay when the overlay
    // rebuilds.
    final Widget overlay = Directionality(
      textDirection: Directionality.of(context),
      child: _TooltipOverlay(
        richMessage: widget.richMessage ?? TextSpan(text: widget.message),
        height: _height,
        padding: _padding,
        margin: _margin,
        onEnter: _mouseIsConnected ? (_) => _handleMouseEnter() : null,
        onExit: _mouseIsConnected ? (_) => _handleMouseExit() : null,
        decoration: _decoration,
        textStyle: _textStyle,
        textAlign: _textAlign,
        animation: CurvedAnimation(
          parent: _controller,
          curve: Curves.fastOutSlowIn,
        ),
        target: target,
        verticalOffset: _verticalOffset,
        preferBelow: _preferBelow,
      ),
    );
    _entry = OverlayEntry(builder: (BuildContext context) => overlay);
    _isConcealed = false;
    overlayState.insert(_entry!);
    SemanticsService.tooltip(_tooltipMessage);
    if (_mouseIsConnected) {
      // Hovered tooltips shouldn't show more than one at once. For example, a chip with
      // a delete icon shouldn't show both the delete icon tooltip and the chip tooltip
      // at the same time.
      Tooltip._concealOtherTooltips(this);
    }
    assert(!Tooltip._openedTooltips.contains(this));
    Tooltip._openedTooltips.add(this);
  }

  void _removeEntry() {
    Tooltip._openedTooltips.remove(this);
    _mouseIn.remove(this);
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _showTimer?.cancel();
    _showTimer = null;
    if (!_isConcealed) {
      _entry?.remove();
    }
    _isConcealed = false;
    _entry = null;
    if (_mouseIsConnected) {
      Tooltip._revealLastTooltip();
    }
  }

  void _handlePointerEvent(PointerEvent event) {
    if (_entry == null) {
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _handleMouseExit();
    } else if (event is PointerDownEvent) {
      _handleMouseExit(immediately: true);
    }
  }

  @override
  void deactivate() {
    if (_entry != null) {
      _dismissTooltip(immediately: true);
    }
    _showTimer?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    RendererBinding.instance.mouseTracker.removeListener(_handleMouseTrackerChange);
    _removeEntry();
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    _pressActivated = true;
    final bool tooltipCreated = ensureTooltipVisible();
    if (tooltipCreated && _enableFeedback) {
      if (_triggerMode == TooltipTriggerMode.longPress) {
        Feedback.forLongPress(context);
      } else {
        Feedback.forTap(context);
      }
    }
    widget.onTriggered?.call();
  }

  void _handleTap() {
    _handlePress();
    // When triggerMode is not [TooltipTriggerMode.tap] the tooltip is dismissed
    // by _handlePointerEvent, which listens to the global pointer events.
    // When triggerMode is [TooltipTriggerMode.tap] and the Tooltip GestureDetector
    // competes with other GestureDetectors, the disambiguation process will complete
    // after the global pointer event is received. As we can't rely on the global
    // pointer events to dismiss the Tooltip, we have to call _handleMouseExit
    // to dismiss the tooltip after _showDuration expired.
    _handleMouseExit();
  }

  @override
  Widget build(BuildContext context) {
    // If message is empty then no need to create a tooltip overlay to show
    // the empty black container so just return the wrapped child as is or
    // empty container if child is not specified.
    if (_tooltipMessage.isEmpty) {
      return widget.child ?? const SizedBox();
    }
    assert(Overlay.of(context, debugRequiredFor: widget) != null);
    final ThemeData theme = Theme.of(context);
    final TooltipThemeData tooltipTheme = TooltipTheme.of(context);
    final TextStyle defaultTextStyle;
    final BoxDecoration defaultDecoration;
    if (theme.brightness == Brightness.dark) {
      defaultTextStyle = theme.textTheme.bodyText2!.copyWith(
        color: Colors.black,
        fontSize: _getDefaultFontSize(),
      );
      defaultDecoration = BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      );
    } else {
      defaultTextStyle = theme.textTheme.bodyText2!.copyWith(
        color: Colors.white,
        fontSize: _getDefaultFontSize(),
      );
      defaultDecoration = BoxDecoration(
        color: Colors.grey[700]!.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      );
    }

    _height = widget.height ?? tooltipTheme.height ?? _getDefaultTooltipHeight();
    _padding = widget.padding ?? tooltipTheme.padding ?? _getDefaultPadding();
    _margin = widget.margin ?? tooltipTheme.margin ?? _defaultMargin;
    _verticalOffset = widget.verticalOffset ?? tooltipTheme.verticalOffset ?? _defaultVerticalOffset;
    _preferBelow = widget.preferBelow ?? tooltipTheme.preferBelow ?? _defaultPreferBelow;
    _excludeFromSemantics = widget.excludeFromSemantics ?? tooltipTheme.excludeFromSemantics ?? _defaultExcludeFromSemantics;
    _decoration = widget.decoration ?? tooltipTheme.decoration ?? defaultDecoration;
    _textStyle = widget.textStyle ?? tooltipTheme.textStyle ?? defaultTextStyle;
    _textAlign = widget.textAlign ?? tooltipTheme.textAlign ?? _defaultTextAlign;
    _waitDuration = widget.waitDuration ?? tooltipTheme.waitDuration ?? _defaultWaitDuration;
    _showDuration = widget.showDuration ?? tooltipTheme.showDuration ?? _defaultShowDuration;
    _hoverShowDuration = widget.showDuration ?? tooltipTheme.showDuration ?? _defaultHoverShowDuration;
    _triggerMode = widget.triggerMode ?? tooltipTheme.triggerMode ?? _defaultTriggerMode;
    _enableFeedback = widget.enableFeedback ?? tooltipTheme.enableFeedback ?? _defaultEnableFeedback;

    Widget result = Semantics(
      tooltip: _excludeFromSemantics
          ? null
          : _tooltipMessage,
      child: widget.child,
    );

    // Only check for gestures if tooltip should be visible.
    if (_visible) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: (_triggerMode == TooltipTriggerMode.longPress) ? _handlePress : null,
        onTap: (_triggerMode == TooltipTriggerMode.tap) ? _handleTap : null,
        excludeFromSemantics: true,
        child: result,
      );
      // Only check for hovering if there is a mouse connected.
      if (_mouseIsConnected) {
        result = MouseRegion(
          onEnter: (_) => _handleMouseEnter(),
          onExit: (_) => _handleMouseExit(),
          child: result,
        );
      }
    }

    return result;
  }
}

/// A delegate for computing the layout of a tooltip to be displayed above or
/// below a target specified in the global coordinate system.
class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate for computing the layout of a tooltip.
  ///
  /// The arguments must not be null.
  _TooltipPositionDelegate({
    required this.target,
    required this.verticalOffset,
    required this.preferBelow,
  }) : assert(target != null),
       assert(verticalOffset != null),
       assert(preferBelow != null);

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  /// The amount of vertical distance between the target and the displayed
  /// tooltip.
  final double verticalOffset;

  /// Whether the tooltip is displayed below its widget by default.
  ///
  /// If there is insufficient space to display the tooltip in the preferred
  /// direction, the tooltip will be displayed in the opposite direction.
  final bool preferBelow;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
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
    return target != oldDelegate.target
        || verticalOffset != oldDelegate.verticalOffset
        || preferBelow != oldDelegate.preferBelow;
  }
}

class _TooltipOverlay extends StatelessWidget {
  const _TooltipOverlay({
    required this.height,
    required this.richMessage,
    this.padding,
    this.margin,
    this.decoration,
    this.textStyle,
    this.textAlign,
    required this.animation,
    required this.target,
    required this.verticalOffset,
    required this.preferBelow,
    this.onEnter,
    this.onExit,
  });

  final InlineSpan richMessage;
  final double height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final Animation<double> animation;
  final Offset target;
  final double verticalOffset;
  final bool preferBelow;
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;

  @override
  Widget build(BuildContext context) {
    Widget result = IgnorePointer(
      child: FadeTransition(
        opacity: animation,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyText2!,
            child: Container(
              decoration: decoration,
              padding: padding,
              margin: margin,
              child: Center(
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: Text.rich(
                  richMessage,
                  style: textStyle,
                  textAlign: textAlign,
                ),
              ),
            ),
          ),
        ),
      )
    );
    if (onEnter != null || onExit != null) {
      result = MouseRegion(
        onEnter: onEnter,
        onExit: onExit,
        child: result,
      );
    }
    return Positioned.fill(
      bottom: MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0.0,
      child: CustomSingleChildLayout(
        delegate: _TooltipPositionDelegate(
          target: target,
          verticalOffset: verticalOffset,
          preferBelow: preferBelow,
        ),
        child: result,
      ),
    );
  }
}
