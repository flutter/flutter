// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
///
/// @docImport 'app.dart';
/// @docImport 'floating_action_button.dart';
/// @docImport 'icon_button.dart';
/// @docImport 'popup_menu.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'text_theme.dart';
import 'theme.dart';
import 'tooltip_theme.dart';
import 'tooltip_visibility.dart';

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
/// This tooltip will default to showing above the [Text] instead of below
/// because its ambient [TooltipThemeData.preferBelow] is false.
/// (See the use of [MaterialApp.theme].)
/// Setting that piece of theme data is recommended to avoid having a finger or
/// cursor hide the tooltip. For other ways to set that piece of theme data see:
///
/// * [Theme.data], [ThemeData.tooltipTheme]
/// * [TooltipTheme.data]
///
/// or it can be set directly on each tooltip with [Tooltip.preferBelow].
///
/// ** See code in examples/api/lib/material/tooltip/tooltip.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example covers most of the attributes available in Tooltip.
/// `decoration` has been used to give a gradient and borderRadius to Tooltip.
/// `constraints` has been used to set the minimum width of the Tooltip.
/// `preferBelow` is true; the tooltip will prefer showing below [Tooltip]'s child widget.
/// However, it may show the tooltip above if there's not enough space
/// below the widget.
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
    @Deprecated(
      'Use Tooltip.constraints instead. '
      'This feature was deprecated after v3.30.0-0.1.pre.',
    )
    this.height,
    this.constraints,
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
    this.exitDuration,
    this.enableTapToDismiss = true,
    this.triggerMode,
    this.enableFeedback,
    this.onTriggered,
    this.mouseCursor,
    this.ignorePointer,
    this.positionDelegate,
    this.child,
  }) : assert(
         (message == null) != (richMessage == null),
         'Either `message` or `richMessage` must be specified',
       ),
       assert(
         height == null || constraints == null,
         'Only one of `height` and `constraints` may be specified.',
       );

  /// The text to display in the tooltip.
  ///
  /// Only one of [message] and [richMessage] may be non-null.
  final String? message;

  /// The rich text to display in the tooltip.
  ///
  /// Only one of [message] and [richMessage] may be non-null.
  final InlineSpan? richMessage;

  /// The minimum height of the [Tooltip]'s message.
  @Deprecated(
    'Use Tooltip.constraints instead. '
    'This feature was deprecated after v3.30.0-0.1.pre.',
  )
  final double? height;

  /// Constrains the size of the [Tooltip]'s message.
  ///
  /// If null, then the [TooltipThemeData.constraints] of the ambient [ThemeData.tooltipTheme]
  /// will be used. If that is also null, then a default value will be picked based on the current
  /// platform. For desktop platforms, the default value is `BoxConstraints(minHeight: 24.0)`,
  /// while for mobile platforms the default value is `BoxConstraints(minHeight: 32.0)`.
  final BoxConstraints? constraints;

  /// The amount of space by which to inset the [Tooltip]'s message.
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
  ///
  /// See also:
  ///
  ///  * [constraints], which allow setting an explicit size for the tooltip.
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
  /// If there is insufficient space to display the tooltip in
  /// the preferred direction, the tooltip will be displayed in the opposite
  /// direction.
  ///
  /// If this property is null, then [TooltipThemeData.preferBelow] is used.
  /// If that is also null, the default value is true.
  ///
  /// Applying [TooltipThemeData.preferBelow]: `false` for the entire app
  /// is recommended to avoid having a finger or cursor hide a tooltip.
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
  /// [Colors.grey]\[700\] if [ThemeData.brightness] is [Brightness.light], and
  /// [Colors.white] if it is [Brightness.dark].
  final Decoration? decoration;

  /// The style to use for the message of the tooltip.
  ///
  /// If null, the message's [TextStyle] will be determined based on
  /// [ThemeData]. If [ThemeData.brightness] is set to [Brightness.dark],
  /// [TextTheme.bodyMedium] of [ThemeData.textTheme] will be used with
  /// [Colors.white]. Otherwise, if [ThemeData.brightness] is set to
  /// [Brightness.light], [TextTheme.bodyMedium] of [ThemeData.textTheme] will be
  /// used with [Colors.black].
  final TextStyle? textStyle;

  /// How the message of the tooltip is aligned horizontally.
  ///
  /// If this property is null, then [TooltipThemeData.textAlign] is used.
  /// If [TooltipThemeData.textAlign] is also null, the default value is
  /// [TextAlign.start].
  final TextAlign? textAlign;

  /// {@macro flutter.widgets.RawTooltip.hoverDelay}
  final Duration? waitDuration;

  /// {@macro flutter.widgets.RawTooltip.touchDelay}
  ///
  /// See also:
  ///
  ///  * [exitDuration], which allows configuring the time until a pointer
  /// disappears when hovering.
  final Duration? showDuration;

  /// {@macro flutter.widgets.RawTooltip.dismissDelay}
  ///
  /// See also:
  ///
  ///  * [showDuration], which allows configuring the length of time that a
  /// tooltip will be visible after touch events are released.
  final Duration? exitDuration;

  /// {@macro flutter.widgets.RawTooltip.enableTapToDismiss}
  final bool enableTapToDismiss;

  /// {@macro flutter.widgets.RawTooltip.triggerMode}
  ///
  /// If this property is null, then [TooltipThemeData.triggerMode] is used.
  /// If [TooltipThemeData.triggerMode] is also null, the default mode is
  /// [TooltipTriggerMode.longPress].
  final TooltipTriggerMode? triggerMode;

  /// {@macro flutter.widgets.RawTooltip.enableFeedback}
  final bool? enableFeedback;

  /// {@macro flutter.widgets.RawTooltip.onTriggered}
  final TooltipTriggeredCallback? onTriggered;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If this property is null, [MouseCursor.defer] will be used.
  final MouseCursor? mouseCursor;

  /// Whether this tooltip should be invisible to hit testing.
  ///
  /// If no value is passed, pointer events are ignored unless the tooltip has a
  /// [richMessage] instead of a [message].
  ///
  /// See also:
  ///
  /// * [IgnorePointer], for more information about how pointer events are
  /// handled or ignored.
  final bool? ignorePointer;

  /// {@macro flutter.widgets.RawTooltip.positionDelegate}
  final TooltipPositionDelegate? positionDelegate;

  /// {@macro flutter.widgets.RawTooltip.dismissAllToolTips}
  static bool dismissAllToolTips() {
    return RawTooltip.dismissAllToolTips();
  }

  @override
  State<Tooltip> createState() => TooltipState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty(
        'message',
        message,
        showName: message == null,
        defaultValue: message == null ? null : kNoDefaultValue,
      ),
    );
    properties.add(
      StringProperty(
        'richMessage',
        richMessage?.toPlainText(),
        showName: richMessage == null,
        defaultValue: richMessage == null ? null : kNoDefaultValue,
      ),
    );
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(
      DiagnosticsProperty<BoxConstraints>('constraints', constraints, defaultValue: null),
    );
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
    properties.add(DoubleProperty('vertical offset', verticalOffset, defaultValue: null));
    properties.add(
      FlagProperty(
        'position',
        value: preferBelow,
        ifTrue: 'below',
        ifFalse: 'above',
        showName: true,
      ),
    );
    properties.add(
      FlagProperty('semantics', value: excludeFromSemantics, ifTrue: 'excluded', showName: true),
    );
    properties.add(
      DiagnosticsProperty<Duration>('wait duration', waitDuration, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<Duration>('show duration', showDuration, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<Duration>('exit duration', exitDuration, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<TooltipTriggerMode>('triggerMode', triggerMode, defaultValue: null),
    );
    properties.add(
      FlagProperty('enableFeedback', value: enableFeedback, ifTrue: 'true', showName: true),
    );
    properties.add(DiagnosticsProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
    properties.add(
      DiagnosticsProperty<TooltipPositionDelegate>(
        'positionDelegate',
        positionDelegate,
        defaultValue: null,
      ),
    );
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
  static const Duration _defaultShowDuration = Duration(milliseconds: 1500);
  static const Duration _defaultExitDuration = Duration(milliseconds: 100);
  static const Duration _defaultWaitDuration = Duration.zero;
  static const bool _defaultExcludeFromSemantics = false;
  static const TooltipTriggerMode _defaultTriggerMode = TooltipTriggerMode.longPress;
  static const bool _defaultEnableFeedback = true;
  static const TextAlign _defaultTextAlign = TextAlign.start;

  final GlobalKey<RawTooltipState> _tooltipKey = GlobalKey<RawTooltipState>();

  // From InheritedWidgets
  late bool _visible;
  late TooltipThemeData _tooltipTheme;

  /// {@macro flutter.widgets.RawTooltipState.ensureTooltipVisible}
  bool ensureTooltipVisible() {
    return _tooltipKey.currentState?.ensureTooltipVisible() ?? false;
  }

  @protected
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TooltipVisibility.of(context);
    _tooltipTheme = TooltipTheme.of(context);
  }

  // https://material.io/components/tooltips#specs
  double _getDefaultTooltipHeight() {
    return switch (Theme.of(context).platform) {
      TargetPlatform.macOS || TargetPlatform.linux || TargetPlatform.windows => 24.0,
      TargetPlatform.android || TargetPlatform.fuchsia || TargetPlatform.iOS => 32.0,
    };
  }

  EdgeInsets _getDefaultPadding() {
    return switch (Theme.of(context).platform) {
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS => const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    };
  }

  static double _getDefaultFontSize(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.macOS || TargetPlatform.linux || TargetPlatform.windows => 12.0,
      TargetPlatform.android || TargetPlatform.fuchsia || TargetPlatform.iOS => 14.0,
    };
  }

  Offset _getDefaultPositionDelegate(TooltipPositionContext context) {
    final double effectiveVerticalOffset =
        widget.verticalOffset ?? _tooltipTheme.verticalOffset ?? _defaultVerticalOffset;
    final bool effectivePreferBelow =
        widget.preferBelow ?? _tooltipTheme.preferBelow ?? _defaultPreferBelow;
    final resolvedContext = TooltipPositionContext(
      target: context.target,
      targetSize: context.targetSize,
      tooltipSize: context.tooltipSize,
      overlaySize: context.overlaySize,
      verticalOffset: effectiveVerticalOffset,
      preferBelow: effectivePreferBelow,
    );
    return widget.positionDelegate?.call(resolvedContext) ??
        positionDependentBox(
          size: context.overlaySize,
          childSize: context.tooltipSize,
          target: context.target,
          verticalOffset: effectiveVerticalOffset,
          preferBelow: effectivePreferBelow,
        );
  }

  @override
  Widget build(BuildContext context) {
    final (TextStyle defaultTextStyle, BoxDecoration defaultDecoration) = switch (Theme.of(
      context,
    )) {
      ThemeData(
        brightness: Brightness.dark,
        :final TextTheme textTheme,
        :final TargetPlatform platform,
      ) =>
        (
          textTheme.bodyMedium!.copyWith(
            color: Colors.black,
            fontSize: _getDefaultFontSize(platform),
          ),
          BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ThemeData(
        brightness: Brightness.light,
        :final TextTheme textTheme,
        :final TargetPlatform platform,
      ) =>
        (
          textTheme.bodyMedium!.copyWith(
            color: Colors.white,
            fontSize: _getDefaultFontSize(platform),
          ),
          BoxDecoration(
            color: Colors.grey[700]!.withOpacity(0.9),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        ),
    };
    final defaultConstraints = BoxConstraints(
      minHeight: widget.height ?? _tooltipTheme.height ?? _getDefaultTooltipHeight(),
    );

    final Widget tooltipBox = _TooltipBox(
      constraints: widget.constraints ?? _tooltipTheme.constraints ?? defaultConstraints,
      textStyle: widget.textStyle ?? _tooltipTheme.textStyle ?? defaultTextStyle,
      textAlign: widget.textAlign ?? _tooltipTheme.textAlign ?? _defaultTextAlign,
      decoration: widget.decoration ?? _tooltipTheme.decoration ?? defaultDecoration,
      padding: widget.padding ?? _tooltipTheme.padding ?? _getDefaultPadding(),
      margin: widget.margin ?? _tooltipTheme.margin ?? _defaultMargin,
      richMessage: widget.richMessage ?? TextSpan(text: widget.message),
    );

    Widget effectiveChild = MouseRegion(
      cursor: widget.mouseCursor ?? MouseCursor.defer,
      child: widget.child ?? const SizedBox.shrink(),
    );

    final bool excludeFromSemantics =
        widget.excludeFromSemantics ??
        _tooltipTheme.excludeFromSemantics ??
        _defaultExcludeFromSemantics;

    if (_visible) {
      effectiveChild = RawTooltip(
        key: _tooltipKey,
        semanticsTooltip: excludeFromSemantics
            ? null
            : widget.message ?? widget.richMessage?.toPlainText() ?? '',
        tooltipBuilder: (BuildContext context, Animation<double> animation) => IgnorePointer(
          ignoring: widget.ignorePointer ?? widget.message != null,
          child: FadeTransition(opacity: animation, child: tooltipBox),
        ),
        touchDelay: widget.showDuration ?? _tooltipTheme.showDuration ?? _defaultShowDuration,
        triggerMode: widget.triggerMode ?? _tooltipTheme.triggerMode ?? _defaultTriggerMode,
        enableFeedback:
            widget.enableFeedback ?? _tooltipTheme.enableFeedback ?? _defaultEnableFeedback,
        hoverDelay: widget.waitDuration ?? _tooltipTheme.waitDuration ?? _defaultWaitDuration,
        enableTapToDismiss: widget.enableTapToDismiss,
        onTriggered: widget.onTriggered,
        dismissDelay: widget.exitDuration ?? _tooltipTheme.exitDuration ?? _defaultExitDuration,
        positionDelegate: _getDefaultPositionDelegate,
        child: effectiveChild,
      );
    }

    return effectiveChild;
  }
}

class _TooltipBox extends StatelessWidget {
  const _TooltipBox({
    required this.constraints,
    required this.textStyle,
    required this.textAlign,
    required this.decoration,
    required this.padding,
    required this.margin,
    required this.richMessage,
  });

  final BoxConstraints constraints;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final Decoration? decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final InlineSpan richMessage;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: constraints,
      child: DefaultTextStyle(
        style: textStyle,
        textAlign: textAlign,
        child: Container(
          decoration: decoration,
          padding: padding,
          margin: margin,
          child: Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: Text.rich(richMessage, style: textStyle, textAlign: textAlign),
          ),
        ),
      ),
    );
  }
}
