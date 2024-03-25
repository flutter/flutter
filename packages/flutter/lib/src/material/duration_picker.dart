// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'curves.dart';
import 'debug.dart';
import 'dialog.dart';
import 'duration.dart';
import 'feedback.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'input_border.dart';
import 'input_decorator.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'material_state.dart';
import 'text_button.dart';
import 'text_form_field.dart';
import 'text_theme.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'time.dart';
import 'time_picker_theme.dart';

// Examples can assume:
// late BuildContext context;

const Duration _kDialogSizeAnimationDuration = Duration(milliseconds: 200);
const Duration _kDialAnimateDuration = Duration(milliseconds: 200);
const double _kTwoPi = 2 * math.pi;
const Duration _kVibrateCommitDelay = Duration(milliseconds: 100);

const double _kTimePickerHeaderLandscapeWidth = 216;
const double _kTimePickerInnerDialOffset = 28;
const double _kTimePickerDialMinRadius = 50;
const double _kTimePickerDialPadding = 28;

/// Interactive input mode of the time picker dialog.
///
/// In [DurationPickerEntryMode.dial] mode, a clock dial is displayed and the user
/// taps or drags the time they wish to select. In DurationPickerEntryMode.input]
/// mode, [TextField]s are displayed and the user types in the time they wish to
/// select.
///
/// See also:
///
/// * [showDurationPicker], a function that shows a [DurationPickerDialog] and returns
///   the selected time as a [Future].
enum DurationPickerEntryMode {
  /// User picks time from a clock dial.
  ///
  /// Can switch to [input] by activating a mode button in the dialog.
  dial,

  /// User can input the time by typing it into text fields.
  ///
  /// Can switch to [dial] by activating a mode button in the dialog.
  input,

  /// User can only pick time from a clock dial.
  ///
  /// There is no user interface to switch to another mode.
  dialOnly,

  /// User can only input the time by typing it into text fields.
  ///
  /// There is no user interface to switch to another mode.
  inputOnly
}

/// Different modes of [DurationPickerMode].
///
/// See also:
///
///  * [DurationPicker], the class that implements the material duration picker.
/// TODO: should use enum, or a list of enums with {day, hour, minute, second, millisecond, etc., see _DurationMode} ?
enum DurationPickerMode {
  /// Mode that shows the timer duration in hour and minute.
  hm,
  /// Mode that shows the timer duration in minute and second.
  ms,
  /// Mode that shows the timer duration in hour, minute, and second.
  hms,
}

// Whether the dial-mode time picker is currently selecting the hour, the
// minute or the second.
enum _DurationMode { hour, minute, second }

// Aspects of _DurationPickerModel that can be depended upon.
enum _DurationPickerAspect {
  useMaterial3,
  entryMode,
  hourMinuteMode,
  onHourMinuteModeChanged,
  onHourDoubleTapped,
  onMinuteDoubleTapped,
  hourDialType,
  selectedDuration,
  onSelectedDurationChanged,
  orientation,
  theme,
  defaultTheme,
}

class _DurationPickerModel extends InheritedModel<_DurationPickerAspect> {
  const _DurationPickerModel({
    required this.entryMode,
    required this.hourMinuteMode,
    required this.onHourMinuteModeChanged,
    required this.onHourDoubleTapped,
    required this.onMinuteDoubleTapped,
    required this.selectedDuration,
    required this.onSelectedDurationChanged,
    required this.useMaterial3,
    required this.hourDialType,
    required this.orientation,
    required this.theme,
    required this.defaultTheme,
    required super.child,
  });

  final DurationPickerEntryMode entryMode;
  final _DurationMode hourMinuteMode;
  final ValueChanged<_DurationMode> onHourMinuteModeChanged;
  final GestureTapCallback onHourDoubleTapped;
  final GestureTapCallback onMinuteDoubleTapped;
  final Duration selectedDuration;
  final ValueChanged<Duration> onSelectedDurationChanged;
  final bool useMaterial3;
  final _HourDialType hourDialType;
  final Orientation orientation;
  final TimePickerThemeData theme;
  final _TimePickerDefaults defaultTheme;

  static _DurationPickerModel of(BuildContext context, [_DurationPickerAspect? aspect]) => InheritedModel.inheritFrom<_DurationPickerModel>(context, aspect: aspect)!;
  static DurationPickerEntryMode entryModeOf(BuildContext context) => of(context, _DurationPickerAspect.entryMode).entryMode;
  static _DurationMode hourMinuteModeOf(BuildContext context) => of(context, _DurationPickerAspect.hourMinuteMode).hourMinuteMode;
  static Duration selectedDurationOf(BuildContext context) => of(context, _DurationPickerAspect.selectedDuration).selectedDuration;
  static bool useMaterial3Of(BuildContext context) => of(context, _DurationPickerAspect.useMaterial3).useMaterial3;
  static _HourDialType hourDialTypeOf(BuildContext context) => of(context, _DurationPickerAspect.hourDialType).hourDialType;
  static Orientation orientationOf(BuildContext context) => of(context, _DurationPickerAspect.orientation).orientation;
  static TimePickerThemeData themeOf(BuildContext context) => of(context, _DurationPickerAspect.theme).theme;
  static _TimePickerDefaults defaultThemeOf(BuildContext context) => of(context, _DurationPickerAspect.defaultTheme).defaultTheme;

  static void setSelectedTime(BuildContext context, Duration value) => of(context, _DurationPickerAspect.onSelectedDurationChanged).onSelectedDurationChanged(value);
  static void setHourMinuteMode(BuildContext context, _DurationMode value) => of(context, _DurationPickerAspect.onHourMinuteModeChanged).onHourMinuteModeChanged(value);

  @override
  bool updateShouldNotifyDependent(_DurationPickerModel oldWidget, Set<_DurationPickerAspect> dependencies) {
    if (useMaterial3 != oldWidget.useMaterial3 && dependencies.contains(_DurationPickerAspect.useMaterial3)) {
      return true;
    }
    if (entryMode != oldWidget.entryMode && dependencies.contains(_DurationPickerAspect.entryMode)) {
      return true;
    }
    if (hourMinuteMode != oldWidget.hourMinuteMode && dependencies.contains(_DurationPickerAspect.hourMinuteMode)) {
      return true;
    }
    if (onHourMinuteModeChanged != oldWidget.onHourMinuteModeChanged && dependencies.contains(_DurationPickerAspect.onHourMinuteModeChanged)) {
      return true;
    }
    if (onHourMinuteModeChanged != oldWidget.onHourDoubleTapped && dependencies.contains(_DurationPickerAspect.onHourDoubleTapped)) {
      return true;
    }
    if (onHourMinuteModeChanged != oldWidget.onMinuteDoubleTapped && dependencies.contains(_DurationPickerAspect.onMinuteDoubleTapped)) {
      return true;
    }
    if (hourDialType != oldWidget.hourDialType && dependencies.contains(_DurationPickerAspect.hourDialType)) {
      return true;
    }
    if (selectedDuration != oldWidget.selectedDuration && dependencies.contains(_DurationPickerAspect.selectedDuration)) {
      return true;
    }
    if (onSelectedDurationChanged != oldWidget.onSelectedDurationChanged && dependencies.contains(_DurationPickerAspect.onSelectedDurationChanged)) {
      return true;
    }
    if (orientation != oldWidget.orientation && dependencies.contains(_DurationPickerAspect.orientation)) {
      return true;
    }
    if (theme != oldWidget.theme && dependencies.contains(_DurationPickerAspect.theme)) {
      return true;
    }
    if (defaultTheme != oldWidget.defaultTheme && dependencies.contains(_DurationPickerAspect.defaultTheme)) {
      return true;
    }
    return false;
  }

  @override
  bool updateShouldNotify(_DurationPickerModel oldWidget) {
    return useMaterial3 != oldWidget.useMaterial3
        || entryMode != oldWidget.entryMode
        || hourMinuteMode != oldWidget.hourMinuteMode
        || onHourMinuteModeChanged != oldWidget.onHourMinuteModeChanged
        || onHourDoubleTapped != oldWidget.onHourDoubleTapped
        || onMinuteDoubleTapped != oldWidget.onMinuteDoubleTapped
        || hourDialType != oldWidget.hourDialType
        || selectedDuration != oldWidget.selectedDuration
        || onSelectedDurationChanged != oldWidget.onSelectedDurationChanged
        || orientation != oldWidget.orientation
        || theme != oldWidget.theme
        || defaultTheme != oldWidget.defaultTheme;
  }
}

class _TimePickerHeader extends StatelessWidget {
  const _TimePickerHeader({ required this.helpText });

  final String helpText;

  @override
  Widget build(BuildContext context) {
    final DurationFormat durationFormat = MaterialLocalizations.of(context).durationFormat();

    switch (_DurationPickerModel.orientationOf(context)) {
      case Orientation.portrait:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsetsDirectional.only(bottom: _DurationPickerModel.useMaterial3Of(context) ? 20 : 24),
              child: Text(
                helpText,
                style: _DurationPickerModel.themeOf(context).helpTextStyle ?? _DurationPickerModel.defaultThemeOf(context).helpTextStyle,
              ),
            ),
            Row(
              // Hour/minutes should not change positions in RTL locales.
              textDirection: TextDirection.ltr,
              children: <Widget>[
                const Expanded(child: _HourControl()),
                _TimeSelectorSeparator(durationFormat: durationFormat),
                const Expanded(child: _MinuteControl()),
              ],
            ),
          ],
        );
      case Orientation.landscape:
        return SizedBox(
          width: _kTimePickerHeaderLandscapeWidth,
          child: Stack(
            children: <Widget>[
              Text(
                helpText,
                style: _DurationPickerModel.themeOf(context).helpTextStyle ?? _DurationPickerModel.defaultThemeOf(context).helpTextStyle,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // TODO: may can remove column above
                  Row(
                    // Hour/minutes should not change positions in RTL locales.
                    textDirection: TextDirection.ltr,
                    children: <Widget>[
                      const Expanded(child: _HourControl()),
                      _TimeSelectorSeparator(durationFormat: durationFormat),
                      const Expanded(child: _MinuteControl()),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }
}

class _HourMinuteControl extends StatelessWidget {
  const _HourMinuteControl({
    required this.text,
    required this.onTap,
    required this.onDoubleTap,
    required this.isSelected,
  });

  final String text;
  final GestureTapCallback onTap;
  final GestureTapCallback onDoubleTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final TimePickerThemeData timePickerTheme = _DurationPickerModel.themeOf(context);
    final _TimePickerDefaults defaultTheme = _DurationPickerModel.defaultThemeOf(context);
    final Color backgroundColor = timePickerTheme.hourMinuteColor ?? defaultTheme.hourMinuteColor;
    final ShapeBorder shape = timePickerTheme.hourMinuteShape ?? defaultTheme.hourMinuteShape;

    final Set<MaterialState> states = <MaterialState>{
      if (isSelected) MaterialState.selected,
    };
    final Color effectiveTextColor = MaterialStateProperty.resolveAs<Color>(
      _DurationPickerModel.themeOf(context).hourMinuteTextColor ?? _DurationPickerModel.defaultThemeOf(context).hourMinuteTextColor,
      states,
    );
    final TextStyle effectiveStyle = MaterialStateProperty.resolveAs<TextStyle>(
      timePickerTheme.hourMinuteTextStyle ?? defaultTheme.hourMinuteTextStyle,
      states,
    ).copyWith(color: effectiveTextColor);

    final double height;
    switch (_DurationPickerModel.entryModeOf(context)) {
      case DurationPickerEntryMode.dial:
      case DurationPickerEntryMode.dialOnly:
        height = defaultTheme.hourMinuteSize.height;
      case DurationPickerEntryMode.input:
      case DurationPickerEntryMode.inputOnly:
        height = defaultTheme.hourMinuteInputSize.height;
    }

    return SizedBox(
      height: height,
      child: Material(
        color: MaterialStateProperty.resolveAs(backgroundColor, states),
        clipBehavior: Clip.antiAlias,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          onDoubleTap: isSelected ? onDoubleTap : null,
          child: Center(
            child: Text(
              text,
              style: effectiveStyle,
              textScaler: TextScaler.noScaling,
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays the hour fragment.
///
/// When tapped changes time picker dial mode to [_DurationMode.hour].
class _HourControl extends StatelessWidget {
  const _HourControl();

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final Duration selectedDuration = _DurationPickerModel.selectedDurationOf(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final String formattedHour = localizations.formatDurationHour(selectedDuration);

    Duration hoursFromSelected(int hoursToAdd) {
      switch (_DurationPickerModel.hourDialTypeOf(context)) {
        case _HourDialType.twentyFourHour:
        case _HourDialType.twentyFourHourDoubleRing:
          final int selectedHour = selectedDuration.hour;
          return selectedDuration.replacing(
            hour: (selectedHour + hoursToAdd) % Duration.hoursPerDay,
          );
      }
    }

    final Duration nextHour = hoursFromSelected(1);
    final String formattedNextHour = localizations.formatDurationHour(nextHour);
    final Duration previousHour = hoursFromSelected(-1);
    final String formattedPreviousHour = localizations.formatDurationHour(previousHour);

    return Semantics(
      value: '${localizations.timePickerHourModeAnnouncement} $formattedHour',
      excludeSemantics: true,
      increasedValue: formattedNextHour,
      onIncrease: () {
        _DurationPickerModel.setSelectedTime(context, nextHour);
      },
      decreasedValue: formattedPreviousHour,
      onDecrease: () {
        _DurationPickerModel.setSelectedTime(context, previousHour);
      },
      child: _HourMinuteControl(
        isSelected: _DurationPickerModel.hourMinuteModeOf(context) == _DurationMode.hour,
        text: formattedHour,
        onTap: Feedback.wrapForTap(() => _DurationPickerModel.setHourMinuteMode(context, _DurationMode.hour), context)!,
        onDoubleTap: _DurationPickerModel.of(context, _DurationPickerAspect.onHourDoubleTapped).onHourDoubleTapped,
      ),
    );
  }
}

/// A passive fragment showing a string value.
///
/// Used to display the appropriate separator between the input fields.
class _TimeSelectorSeparator extends StatelessWidget {
  const _TimeSelectorSeparator({ required this.durationFormat });

  final DurationFormat durationFormat;

  String _timeSelectorSeparatorValue(DurationFormat durationFormat) {
    switch (durationFormat) {
      case DurationFormat.H_colon_mm:
      case DurationFormat.HH_colon_mm:
        return ':';
      case DurationFormat.HH_dot_mm:
        return '.';
      case DurationFormat.frenchCanadian:
        return 'h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData timePickerTheme = TimePickerTheme.of(context);
    final _TimePickerDefaults defaultTheme = theme.useMaterial3 ? _TimePickerDefaultsM3(context) : _TimePickerDefaultsM2(context);
    final Set<MaterialState> states = <MaterialState>{};

    final Color effectiveTextColor = MaterialStateProperty.resolveAs<Color>(
      timePickerTheme.timeSelectorSeparatorColor?.resolve(states)
        ?? timePickerTheme.hourMinuteTextColor
        ?? defaultTheme.timeSelectorSeparatorColor?.resolve(states)
        ?? defaultTheme.hourMinuteTextColor,
      states,
    );
    final TextStyle effectiveStyle = MaterialStateProperty.resolveAs<TextStyle>(
      timePickerTheme.timeSelectorSeparatorTextStyle?.resolve(states)
        ?? timePickerTheme.hourMinuteTextStyle
        ?? defaultTheme.timeSelectorSeparatorTextStyle?.resolve(states)
        ?? defaultTheme.hourMinuteTextStyle,
      states,
    ).copyWith(color: effectiveTextColor);

    final double height;
    switch (_DurationPickerModel.entryModeOf(context)) {
      case DurationPickerEntryMode.dial:
      case DurationPickerEntryMode.dialOnly:
        height = defaultTheme.hourMinuteSize.height;
      case DurationPickerEntryMode.input:
      case DurationPickerEntryMode.inputOnly:
        height = defaultTheme.hourMinuteInputSize.height;
    }

    return ExcludeSemantics(
      child: SizedBox(
        width: durationFormat == DurationFormat.frenchCanadian ? 36 : 24,
        height: height,
        child: Text(
          _timeSelectorSeparatorValue(durationFormat),
          style: effectiveStyle,
          textScaler: TextScaler.noScaling,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Displays the minute fragment.
///
/// When tapped changes time picker dial mode to [_DurationMode.minute].
class _MinuteControl extends StatelessWidget {
  const _MinuteControl();

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final Duration selectedDuration = _DurationPickerModel.selectedDurationOf(context);
    final String formattedMinute = localizations.formatDurationMinute(selectedDuration);
    final Duration nextMinute = selectedDuration.replacing(
      minute: (selectedDuration.minute + 1) % Duration.minutesPerHour,
    );
    final String formattedNextMinute = localizations.formatDurationMinute(nextMinute);
    final Duration previousMinute = selectedDuration.replacing(
      minute: (selectedDuration.minute - 1) % Duration.minutesPerHour,
    );
    final String formattedPreviousMinute = localizations.formatDurationMinute(previousMinute);

    return Semantics(
      excludeSemantics: true,
      value: '${localizations.timePickerMinuteModeAnnouncement} $formattedMinute',
      increasedValue: formattedNextMinute,
      onIncrease: () {
        _DurationPickerModel.setSelectedTime(context, nextMinute);
      },
      decreasedValue: formattedPreviousMinute,
      onDecrease: () {
        _DurationPickerModel.setSelectedTime(context, previousMinute);
      },
      child: _HourMinuteControl(
        isSelected: _DurationPickerModel.hourMinuteModeOf(context) == _DurationMode.minute,
        text: formattedMinute,
        onTap: Feedback.wrapForTap(() => _DurationPickerModel.setHourMinuteMode(context, _DurationMode.minute), context)!,
        onDoubleTap: _DurationPickerModel.of(context, _DurationPickerAspect.onMinuteDoubleTapped).onMinuteDoubleTapped,
      ),
    );
  }
}

class _TappableLabel {
  _TappableLabel({
    required this.value,
    required this.inner,
    required this.painter,
    required this.onTap,
  });

  /// The value this label is displaying.
  final int value;

  /// This value is part of the "inner" ring of values on the dial, used for 24
  /// hour input.
  final bool inner;

  /// Paints the text of the label.
  final TextPainter painter;

  /// Called when a tap gesture is detected on the label.
  final VoidCallback onTap;
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.primaryLabels,
    required this.selectedLabels,
    required this.backgroundColor,
    required this.handColor,
    required this.handWidth,
    required this.dotColor,
    required this.dotRadius,
    required this.centerRadius,
    required this.theta,
    required this.radius,
    required this.textDirection,
    required this.selectedValue,
  }) : super(repaint: PaintingBinding.instance.systemFonts) {
    // TODO(polina-c): stop duplicating code across disposables
    // https://github.com/flutter/flutter/issues/137435
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: 'package:flutter/material.dart',
        className: '$_DialPainter',
        object: this,
      );
    }
  }

  final List<_TappableLabel> primaryLabels;
  final List<_TappableLabel> selectedLabels;
  final Color backgroundColor;
  final Color handColor;
  final double handWidth;
  final Color dotColor;
  final double dotRadius;
  final double centerRadius;
  final double theta;
  final double radius;
  final TextDirection textDirection;
  final int selectedValue;

  void dispose() {
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    }
    for (final _TappableLabel label in primaryLabels) {
      label.painter.dispose();
    }
    for (final _TappableLabel label in selectedLabels) {
      label.painter.dispose();
    }
    primaryLabels.clear();
    selectedLabels.clear();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double dialRadius = clampDouble(size.shortestSide / 2, _kTimePickerDialMinRadius + dotRadius, double.infinity);
    final double labelRadius = clampDouble(dialRadius - _kTimePickerDialPadding, _kTimePickerDialMinRadius, double.infinity);
    final double innerLabelRadius = clampDouble(labelRadius - _kTimePickerInnerDialOffset, 0, double.infinity);
    final double handleRadius = clampDouble(labelRadius - (radius < 0.5 ? 1 : 0) * (labelRadius - innerLabelRadius), _kTimePickerDialMinRadius, double.infinity);
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Offset centerPoint = center;
    canvas.drawCircle(centerPoint, dialRadius, Paint()..color = backgroundColor);

    Offset getOffsetForTheta(double theta, double radius) {
      return center + Offset(radius * math.cos(theta), -radius * math.sin(theta));
    }

    void paintLabels(List<_TappableLabel> labels, double radius) {
      if (labels.isEmpty) {
        return;
      }
      final double labelThetaIncrement = -_kTwoPi / labels.length;
      double labelTheta = math.pi / 2;

      for (final _TappableLabel label in labels) {
        final TextPainter labelPainter = label.painter;
        final Offset labelOffset = Offset(-labelPainter.width / 2, -labelPainter.height / 2);
        labelPainter.paint(canvas, getOffsetForTheta(labelTheta, radius) + labelOffset);
        labelTheta += labelThetaIncrement;
      }
    }

    void paintInnerOuterLabels(List<_TappableLabel>? labels) {
      if (labels == null) {
        return;
      }

      paintLabels(labels.where((_TappableLabel label) => !label.inner).toList(), labelRadius);
      paintLabels(labels.where((_TappableLabel label) => label.inner).toList(), innerLabelRadius);
    }

    paintInnerOuterLabels(primaryLabels);

    final Paint selectorPaint = Paint()..color = handColor;
    final Offset focusedPoint = getOffsetForTheta(theta, handleRadius);
    canvas.drawCircle(centerPoint, centerRadius, selectorPaint);
    canvas.drawCircle(focusedPoint, dotRadius, selectorPaint);
    selectorPaint.strokeWidth = handWidth;
    canvas.drawLine(centerPoint, focusedPoint, selectorPaint);

    // Add a dot inside the selector but only when it isn't over the labels.
    // This checks that the selector's theta is between two labels. A remainder
    // between 0.1 and 0.45 indicates that the selector is roughly not above any
    // labels. The values were derived by manually testing the dial.
    final double labelThetaIncrement = -_kTwoPi / primaryLabels.length;
    if (theta % labelThetaIncrement > 0.1 && theta % labelThetaIncrement < 0.45) {
      canvas.drawCircle(focusedPoint, 2, selectorPaint..color = dotColor);
    }

    final Rect focusedRect = Rect.fromCircle(
      center: focusedPoint,
      radius: dotRadius,
    );
    canvas
      ..save()
      ..clipPath(Path()..addOval(focusedRect));
    paintInnerOuterLabels(selectedLabels);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter oldPainter) {
    return oldPainter.primaryLabels != primaryLabels
        || oldPainter.selectedLabels != selectedLabels
        || oldPainter.backgroundColor != backgroundColor
        || oldPainter.handColor != handColor
        || oldPainter.theta != theta;
  }
}

// Which kind of hour dial being presented.
enum _HourDialType {
  twentyFourHour,
  twentyFourHourDoubleRing,
}

class _Dial extends StatefulWidget {
  const _Dial({
    required this.selectedDuration,
    required this.durationMode,
    required this.hourDialType,
    required this.onChanged,
    required this.onHourSelected,
  });

  final Duration selectedDuration;
  final _DurationMode durationMode;
  final _HourDialType hourDialType;
  final ValueChanged<Duration>? onChanged;
  final VoidCallback? onHourSelected;

  @override
  _DialState createState() => _DialState();
}

class _DialState extends State<_Dial> with SingleTickerProviderStateMixin {
  late ThemeData themeData;
  late MaterialLocalizations localizations;
  _DialPainter? painter;
  late AnimationController _animationController;
  late Tween<double> _thetaTween;
  late Animation<double> _theta;
  late Tween<double> _radiusTween;
  late Animation<double> _radius;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: _kDialAnimateDuration,
      vsync: this,
    );
    _thetaTween = Tween<double>(begin: _getThetaForTime(widget.selectedDuration));
    _radiusTween = Tween<double>(begin: _getRadiusForTime(widget.selectedDuration));
    _theta = _animationController
      .drive(CurveTween(curve: standardEasing))
      .drive(_thetaTween)
      ..addListener(() => setState(() { /* _theta.value has changed */ }));
    _radius = _animationController
      .drive(CurveTween(curve: standardEasing))
      .drive(_radiusTween)
      ..addListener(() => setState(() { /* _radius.value has changed */ }));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMediaQuery(context));
    themeData = Theme.of(context);
    localizations = MaterialLocalizations.of(context);
  }

  @override
  void didUpdateWidget(_Dial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.durationMode != oldWidget.durationMode || widget.selectedDuration != oldWidget.selectedDuration) {
      if (!_dragging) {
        _animateTo(_getThetaForTime(widget.selectedDuration), _getRadiusForTime(widget.selectedDuration));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    painter?.dispose();
    super.dispose();
  }

  static double _nearest(double target, double a, double b) {
    return ((target - a).abs() < (target - b).abs()) ? a : b;
  }

  void _animateTo(double targetTheta, double targetRadius) {
    void animateToValue({
      required double target,
      required Animation<double> animation,
      required Tween<double> tween,
      required AnimationController controller,
      required double min,
      required double max,
    }) {
      double beginValue = _nearest(target, animation.value, max);
      beginValue = _nearest(target, beginValue, min);
      tween
        ..begin = beginValue
        ..end = target;
      controller
        ..value = 0
        ..forward();
    }

    animateToValue(
      target: targetTheta,
      animation: _theta,
      tween: _thetaTween,
      controller: _animationController,
      min: _theta.value - _kTwoPi,
      max: _theta.value + _kTwoPi,
    );
    animateToValue(
      target: targetRadius,
      animation: _radius,
      tween: _radiusTween,
      controller: _animationController,
      min: 0,
      max: 1,
    );
  }

  double _getRadiusForTime(Duration time) {
    switch (widget.durationMode) {
      case _DurationMode.hour:
        return switch (widget.hourDialType) {
          _HourDialType.twentyFourHourDoubleRing => time.hour >= 12 ? 0 : 1,
          _HourDialType.twentyFourHour => 1,
        };
      case _DurationMode.minute:
        return 1;
      case _DurationMode.second:
        return 1;
    }
  }

  double _getThetaForTime(Duration duration) {
    final int hoursFactor = switch (widget.hourDialType) {
      _HourDialType.twentyFourHour           => Duration.hoursPerDay,
      _HourDialType.twentyFourHourDoubleRing => DurationExtension.hoursPerPeriod,
    };
    final double fraction = switch (widget.durationMode) {
      _DurationMode.hour   => (duration.hour / hoursFactor) % hoursFactor,
      _DurationMode.minute => (duration.minute / Duration.minutesPerHour) % Duration.minutesPerHour,
      _DurationMode.second => (duration.second / Duration.secondsPerMinute) % Duration.secondsPerMinute,
    };
    return (math.pi / 2 - fraction * _kTwoPi) % _kTwoPi;
  }

  Duration _getTimeForTheta(double theta, {bool roundMinutes = false, bool roundSeconds = false, required double radius}) {
    final double fraction = (0.25 - (theta % _kTwoPi) / _kTwoPi) % 1;
    switch (widget.durationMode) {
      case _DurationMode.hour:
        int newHour;
        switch (widget.hourDialType) {
          case _HourDialType.twentyFourHour:
            newHour = (fraction * Duration.hoursPerDay).round() % Duration.hoursPerDay;
          case _HourDialType.twentyFourHourDoubleRing:
            newHour = (fraction * DurationExtension.hoursPerPeriod).round() % DurationExtension.hoursPerPeriod;
            if (radius < 0.5) {
              newHour = newHour + DurationExtension.hoursPerPeriod;
            }
        }
        return widget.selectedDuration.replacing(hour: newHour);
      case _DurationMode.minute:
        int minute = (fraction * Duration.minutesPerHour).round() % Duration.minutesPerHour;
        if (roundMinutes) {
          // Round the minutes to nearest 5 minute interval.
          minute = ((minute + 2) ~/ 5) * 5 % Duration.minutesPerHour;
        }
        return widget.selectedDuration.replacing(minute: minute);
      case _DurationMode.second:
        int second = (fraction * Duration.secondsPerMinute).round() % Duration.secondsPerMinute;
        if (roundSeconds) {
          // Round the seconds to nearest 5 second interval.
          second = ((second + 2) ~/ 5) * 5 % Duration.secondsPerMinute;
        }
        return widget.selectedDuration.replacing(second: second);
    }
  }

  Duration _notifyOnChangedIfNeeded({ bool roundMinutes = false }) {
    final Duration current = _getTimeForTheta(_theta.value, roundMinutes: roundMinutes, radius: _radius.value);
    if (widget.onChanged == null) {
      return current;
    }
    if (current != widget.selectedDuration) {
      widget.onChanged!(current);
    }
    return current;
  }

  void _updateThetaForPan({ bool roundMinutes = false }) {
    setState(() {
      final Offset offset = _position! - _center!;
      final double labelRadius = _dialSize!.shortestSide / 2 - _kTimePickerDialPadding;
      final double innerRadius = labelRadius - _kTimePickerInnerDialOffset;
      double angle = (math.atan2(offset.dx, offset.dy) - math.pi / 2) % _kTwoPi;
      final double radius = clampDouble((offset.distance - innerRadius) / _kTimePickerInnerDialOffset, 0, 1);
      if (roundMinutes) {
        angle = _getThetaForTime(_getTimeForTheta(angle, roundMinutes: roundMinutes, radius: radius));
      }
      // The controller doesn't animate during the pan gesture.
      _thetaTween
        ..begin = angle
        ..end = angle;
      _radiusTween
        ..begin = radius
        ..end = radius;
    });
  }

  Offset? _position;
  Offset? _center;
  Size? _dialSize;

  void _handlePanStart(DragStartDetails details) {
    assert(!_dragging);
    _dragging = true;
    final RenderBox box = context.findRenderObject()! as RenderBox;
    _position = box.globalToLocal(details.globalPosition);
    _dialSize = box.size;
    _center = _dialSize!.center(Offset.zero);
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _position = _position! + details.delta;
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();
  }

  void _handlePanEnd(DragEndDetails details) {
    assert(_dragging);
    _dragging = false;
    _position = null;
    _center = null;
    _dialSize = null;
    _animateTo(_getThetaForTime(widget.selectedDuration), _getRadiusForTime(widget.selectedDuration));
    if (widget.durationMode == _DurationMode.hour) {
      widget.onHourSelected?.call();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    _position = box.globalToLocal(details.globalPosition);
    _center = box.size.center(Offset.zero);
    _dialSize = box.size;
    _updateThetaForPan(roundMinutes: true);
    final Duration newTime = _notifyOnChangedIfNeeded(roundMinutes: true);
    if (widget.durationMode == _DurationMode.hour) {
      switch (widget.hourDialType) {
        case _HourDialType.twentyFourHour:
        case _HourDialType.twentyFourHourDoubleRing:
          _announceToAccessibility(context, localizations.formatDecimal(newTime.hour));
      }
      widget.onHourSelected?.call();
    } else {
      _announceToAccessibility(context, localizations.formatDecimal(newTime.minute));
    }
    final Duration time = _getTimeForTheta(_theta.value, roundMinutes: true, radius: _radius.value);
    _animateTo(_getThetaForTime(time), _getRadiusForTime(time));
    _dragging = false;
    _position = null;
    _center = null;
    _dialSize = null;
  }

  void _selectHour(int hour) {
    _announceToAccessibility(context, localizations.formatDecimal(hour));
    final Duration duration = widget.selectedDuration.replacing(hour: hour);
    final double angle = _getThetaForTime(duration);
    _thetaTween
      ..begin = angle
      ..end = angle;
    _notifyOnChangedIfNeeded();
  }

  void _selectMinute(int minute) {
    _announceToAccessibility(context, localizations.formatDecimal(minute));
    final Duration duration = widget.selectedDuration.replacing(minute: minute);
    final double angle = _getThetaForTime(duration);
    _thetaTween
      ..begin = angle
      ..end = angle;
    _notifyOnChangedIfNeeded();
  }

  void _selectSecond(int second) {
    _announceToAccessibility(context, localizations.formatDecimal(second));
    final Duration duration = widget.selectedDuration.replacing(second: second);
    final double angle = _getThetaForTime(duration);
    _thetaTween
      ..begin = angle
      ..end = angle;
    _notifyOnChangedIfNeeded();
  }

  static const List<Duration> _amHours = <Duration>[
    Duration(hours: 12),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 3),
    Duration(hours: 4),
    Duration(hours: 5),
    Duration(hours: 6),
    Duration(hours: 7),
    Duration(hours: 8),
    Duration(hours: 9),
    Duration(hours: 10),
    Duration(hours: 11),
  ];

  // On M2, there's no inner ring of numbers.
  static const List<Duration> _twentyFourHoursM2 = <Duration>[
    Duration.zero,
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 6),
    Duration(hours: 8),
    Duration(hours: 10),
    Duration(hours: 12),
    Duration(hours: 14),
    Duration(hours: 16),
    Duration(hours: 18),
    Duration(hours: 20),
    Duration(hours: 22),
  ];

  static const List<Duration> _twentyFourHours = <Duration>[
    Duration.zero,
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 3),
    Duration(hours: 4),
    Duration(hours: 5),
    Duration(hours: 6),
    Duration(hours: 7),
    Duration(hours: 8),
    Duration(hours: 9),
    Duration(hours: 10),
    Duration(hours: 11),
    Duration(hours: 12),
    Duration(hours: 13),
    Duration(hours: 14),
    Duration(hours: 15),
    Duration(hours: 16),
    Duration(hours: 17),
    Duration(hours: 18),
    Duration(hours: 19),
    Duration(hours: 20),
    Duration(hours: 21),
    Duration(hours: 22),
    Duration(hours: 23),
  ];

  _TappableLabel _buildTappableLabel({
    required TextStyle? textStyle,
    required int selectedValue,
    required int value,
    required bool inner,
    required String label,
    required VoidCallback onTap,
  }) {
    return _TappableLabel(
      value: value,
      inner: inner,
      painter: TextPainter(
        text: TextSpan(style: textStyle, text: label),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 2.0),
      )..layout(),
      onTap: onTap,
    );
  }

  List<_TappableLabel> _build24HourRing({
    required TextStyle? textStyle,
    required int selectedValue,
  }) {
    return <_TappableLabel>[
      if (themeData.useMaterial3)
        for (final Duration duration in _twentyFourHours)
          _buildTappableLabel(
            textStyle: textStyle,
            selectedValue: selectedValue,
            inner: duration.hour >= 12,
            value: duration.hour,
            label: duration.hour != 0
                ? '${duration.hour}'
                : localizations.formatDurationHour(duration),
            onTap: () {
              _selectHour(duration.hour);
            },
          ),
      if (!themeData.useMaterial3)
        for (final Duration duration in _twentyFourHoursM2)
          _buildTappableLabel(
            textStyle: textStyle,
            selectedValue: selectedValue,
            inner: false,
            value: duration.hour,
            label: localizations.formatDurationHour(duration),
            onTap: () {
              _selectHour(duration.hour);
            },
          ),
    ];
  }

  List<_TappableLabel> _buildMinutes({
    required TextStyle? textStyle,
    required int selectedValue,
  }) {
    const List<Duration> minuteMarkerValues = <Duration>[
      Duration.zero,
      Duration(minutes: 5),
      Duration(minutes: 10),
      Duration(minutes: 15),
      Duration(minutes: 20),
      Duration(minutes: 25),
      Duration(minutes: 30),
      Duration(minutes: 35),
      Duration(minutes: 40),
      Duration(minutes: 45),
      Duration(minutes: 50),
      Duration(minutes: 55),
    ];

    return <_TappableLabel>[
      for (final Duration duration in minuteMarkerValues)
        _buildTappableLabel(
          textStyle: textStyle,
          selectedValue: selectedValue,
          inner: false,
          value: duration.minute,
          label: localizations.formatDurationMinute(duration),
          onTap: () {
            _selectMinute(duration.minute);
          },
        ),
    ];
  }

  List<_TappableLabel> _buildSeconds({
    required TextStyle? textStyle,
    required int selectedValue,
  }) {
    const List<Duration> secondMarkerValues = <Duration>[
      Duration.zero,
      Duration(seconds: 5),
      Duration(seconds: 10),
      Duration(seconds: 15),
      Duration(seconds: 20),
      Duration(seconds: 25),
      Duration(seconds: 30),
      Duration(seconds: 35),
      Duration(seconds: 40),
      Duration(seconds: 45),
      Duration(seconds: 50),
      Duration(seconds: 55),
    ];

    return <_TappableLabel>[
      for (final Duration duration in secondMarkerValues)
        _buildTappableLabel(
          textStyle: textStyle,
          selectedValue: selectedValue,
          inner: false,
          value: duration.second,
          label: localizations.formatDurationSecond(duration),
          onTap: () {
            _selectSecond(duration.second);
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData timePickerTheme = TimePickerTheme.of(context);
    final _TimePickerDefaults defaultTheme = theme.useMaterial3 ? _TimePickerDefaultsM3(context) : _TimePickerDefaultsM2(context);
    final Color backgroundColor = timePickerTheme.dialBackgroundColor ?? defaultTheme.dialBackgroundColor;
    final Color dialHandColor = timePickerTheme.dialHandColor ?? defaultTheme.dialHandColor;
    final TextStyle labelStyle = timePickerTheme.dialTextStyle ?? defaultTheme.dialTextStyle;
    final Color dialTextUnselectedColor = MaterialStateProperty
      .resolveAs<Color>(timePickerTheme.dialTextColor ?? defaultTheme.dialTextColor, <MaterialState>{ });
    final Color dialTextSelectedColor = MaterialStateProperty
      .resolveAs<Color>(timePickerTheme.dialTextColor ?? defaultTheme.dialTextColor, <MaterialState>{  MaterialState.selected });
    final TextStyle resolvedUnselectedLabelStyle = labelStyle.copyWith(color: dialTextUnselectedColor);
    final TextStyle resolvedSelectedLabelStyle = labelStyle.copyWith(color: dialTextSelectedColor);
    final Color dotColor = dialTextSelectedColor;

    List<_TappableLabel> primaryLabels;
    List<_TappableLabel> selectedLabels;
    final int selectedDialValue;
    final double radiusValue;
    switch (widget.durationMode) {
      case _DurationMode.hour:
        switch (widget.hourDialType) {
          case _HourDialType.twentyFourHour:
          case _HourDialType.twentyFourHourDoubleRing:
            selectedDialValue = widget.selectedDuration.hour;
            primaryLabels = _build24HourRing(
              textStyle: resolvedUnselectedLabelStyle,
              selectedValue: selectedDialValue,
            );
            selectedLabels = _build24HourRing(
              textStyle: resolvedSelectedLabelStyle,
              selectedValue: selectedDialValue,
            );
            radiusValue = theme.useMaterial3 ? _radius.value : 1;
        }
      case _DurationMode.minute:
        selectedDialValue = widget.selectedDuration.minute;
        primaryLabels = _buildMinutes(
          textStyle: resolvedUnselectedLabelStyle,
          selectedValue: selectedDialValue,
        );
        selectedLabels = _buildMinutes(
          textStyle: resolvedSelectedLabelStyle,
          selectedValue: selectedDialValue,
        );
        radiusValue = 1;
      case _DurationMode.second:
        selectedDialValue = widget.selectedDuration.second;
        primaryLabels = _buildSeconds(
          textStyle: resolvedUnselectedLabelStyle,
          selectedValue: selectedDialValue,
        );
        selectedLabels = _buildSeconds(
          textStyle: resolvedSelectedLabelStyle,
          selectedValue: selectedDialValue,
        );
        radiusValue = 1;
    }
    painter?.dispose();
    painter = _DialPainter(
      selectedValue: selectedDialValue,
      primaryLabels: primaryLabels,
      selectedLabels: selectedLabels,
      backgroundColor: backgroundColor,
      handColor: dialHandColor,
      handWidth: defaultTheme.handWidth,
      dotColor: dotColor,
      dotRadius: defaultTheme.dotRadius,
      centerRadius: defaultTheme.centerRadius,
      theta: _theta.value,
      radius: radiusValue,
      textDirection: Directionality.of(context),
    );

    return GestureDetector(
      excludeFromSemantics: true,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTapUp: _handleTapUp,
      child: CustomPaint(
        key: const ValueKey<String>('time-picker-dial'),
        painter: painter,
      ),
    );
  }
}

class _TimePickerInput extends StatefulWidget {
  const _TimePickerInput({
    required this.initialSelectedTime,
    required this.errorInvalidText,
    required this.hourLabelText,
    required this.minuteLabelText,
    required this.helpText,
    required this.autofocusHour,
    required this.autofocusMinute,
    this.restorationId,
  });

  /// The time initially selected when the dialog is shown.
  final Duration initialSelectedTime;

  /// Optionally provide your own validation error text.
  final String? errorInvalidText;

  /// Optionally provide your own hour label text.
  final String? hourLabelText;

  /// Optionally provide your own minute label text.
  final String? minuteLabelText;

  final String helpText;

  final bool? autofocusHour;

  final bool? autofocusMinute;

  /// Restoration ID to save and restore the state of the time picker input
  /// widget.
  ///
  /// If it is non-null, the widget will persist and restore its state
  ///
  /// The state of this widget is persisted in a [RestorationBucket] claimed
  /// from the surrounding [RestorationScope] using the provided restoration ID.
  final String? restorationId;

  @override
  _TimePickerInputState createState() => _TimePickerInputState();
}

class _TimePickerInputState extends State<_TimePickerInput> with RestorationMixin {
  late final RestorableDuration _selectedDuration = RestorableDuration(widget.initialSelectedTime);
  final RestorableBool hourHasError = RestorableBool(false);
  final RestorableBool minuteHasError = RestorableBool(false);

  @override
  void dispose() {
    _selectedDuration.dispose();
    hourHasError.dispose();
    minuteHasError.dispose();
    super.dispose();
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDuration, 'selected_time');
    registerForRestoration(hourHasError, 'hour_has_error');
    registerForRestoration(minuteHasError, 'minute_has_error');
  }

  int? _parseHour(String? value) {
    if (value == null) {
      return null;
    }

    final int? newHour = int.tryParse(value);
    if (newHour == null) {
      return null;
    }

    if (newHour >= 0 && newHour < 24) {
      return newHour;
    }
    return null;
  }

  int? _parseMinute(String? value) {
    if (value == null) {
      return null;
    }

    final int? newMinute = int.tryParse(value);
    if (newMinute == null) {
      return null;
    }

    if (newMinute >= 0 && newMinute < 60) {
      return newMinute;
    }
    return null;
  }

  void _handleHourSavedSubmitted(String? value) {
    final int? newHour = _parseHour(value);
    if (newHour != null) {
      _selectedDuration.value = Duration(hours: newHour, minutes: _selectedDuration.value.minute);
      _DurationPickerModel.setSelectedTime(context, _selectedDuration.value);
      FocusScope.of(context).requestFocus();
    }
  }

  void _handleHourChanged(String value) {
    final int? newHour = _parseHour(value);
    if (newHour != null && value.length == 2) {
      // If a valid hour is typed, move focus to the minute TextField.
      FocusScope.of(context).nextFocus();
    }
  }

  void _handleMinuteSavedSubmitted(String? value) {
    final int? newMinute = _parseMinute(value);
    if (newMinute != null) {
      _selectedDuration.value = Duration(hours: _selectedDuration.value.hour, minutes: int.parse(value!));
      _DurationPickerModel.setSelectedTime(context, _selectedDuration.value);
      FocusScope.of(context).unfocus();
    }
  }

  String? _validateHour(String? value) {
    final int? newHour = _parseHour(value);
    setState(() {
      hourHasError.value = newHour == null;
    });
    // This is used as the validator for the [TextFormField].
    // Returning an empty string allows the field to go into an error state.
    // Returning null means no error in the validation of the entered text.
    return newHour == null ? '' : null;
  }

  String? _validateMinute(String? value) {
    final int? newMinute = _parseMinute(value);
    setState(() {
      minuteHasError.value = newMinute == null;
    });
    // This is used as the validator for the [TextFormField].
    // Returning an empty string allows the field to go into an error state.
    // Returning null means no error in the validation of the entered text.
    return newMinute == null ? '' : null;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final DurationFormat durationFormat = MaterialLocalizations.of(context).durationFormat();
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData timePickerTheme = _DurationPickerModel.themeOf(context);
    final _TimePickerDefaults defaultTheme = _DurationPickerModel.defaultThemeOf(context);
    final TextStyle hourMinuteStyle = timePickerTheme.hourMinuteTextStyle ?? defaultTheme.hourMinuteTextStyle;

    return Padding(
      padding: _DurationPickerModel.useMaterial3Of(context) ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsetsDirectional.only(bottom: _DurationPickerModel.useMaterial3Of(context) ? 20 : 24),
            child: Text(
              widget.helpText,
              style: _DurationPickerModel.themeOf(context).helpTextStyle ?? _DurationPickerModel.defaultThemeOf(context).helpTextStyle,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Hour/minutes should not change positions in RTL locales.
                  textDirection: TextDirection.ltr,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _HourTextField(
                              restorationId: 'hour_text_field',
                              selectedDuration: _selectedDuration.value,
                              style: hourMinuteStyle,
                              autofocus: widget.autofocusHour,
                              inputAction: TextInputAction.next,
                              validator: _validateHour,
                              onSavedSubmitted: _handleHourSavedSubmitted,
                              onChanged: _handleHourChanged,
                              hourLabelText: widget.hourLabelText,
                            ),
                          ),
                          if (!hourHasError.value && !minuteHasError.value)
                            ExcludeSemantics(
                              child: Text(
                                widget.hourLabelText ?? MaterialLocalizations.of(context).timePickerHourLabel,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _TimeSelectorSeparator(durationFormat: durationFormat),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MinuteTextField(
                              restorationId: 'minute_text_field',
                              selectedDuration: _selectedDuration.value,
                              style: hourMinuteStyle,
                              autofocus: widget.autofocusMinute,
                              inputAction: TextInputAction.done,
                              validator: _validateMinute,
                              onSavedSubmitted: _handleMinuteSavedSubmitted,
                              minuteLabelText: widget.minuteLabelText,
                            ),
                          ),
                          if (!hourHasError.value && !minuteHasError.value)
                            ExcludeSemantics(
                              child: Text(
                                widget.minuteLabelText ?? MaterialLocalizations.of(context).timePickerMinuteLabel,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hourHasError.value || minuteHasError.value)
            Text(
              widget.errorInvalidText ?? MaterialLocalizations.of(context).invalidTimeLabel,
              style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.error),
            )
          else
            const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _HourTextField extends StatelessWidget {
  const _HourTextField({
    required this.selectedDuration,
    required this.style,
    required this.autofocus,
    required this.inputAction,
    required this.validator,
    required this.onSavedSubmitted,
    required this.onChanged,
    required this.hourLabelText,
    this.restorationId,
  });

  final Duration selectedDuration;
  final TextStyle style;
  final bool? autofocus;
  final TextInputAction inputAction;
  final FormFieldValidator<String> validator;
  final ValueChanged<String?> onSavedSubmitted;
  final ValueChanged<String> onChanged;
  final String? hourLabelText;
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    return _HourMinuteTextField(
      restorationId: restorationId,
      selectedDuration: selectedDuration,
      isHour: true,
      autofocus: autofocus,
      inputAction: inputAction,
      style: style,
      semanticHintText: hourLabelText ?? MaterialLocalizations.of(context).timePickerHourLabel,
      validator: validator,
      onSavedSubmitted: onSavedSubmitted,
      onChanged: onChanged,
    );
  }
}

class _MinuteTextField extends StatelessWidget {
  const _MinuteTextField({
    required this.selectedDuration,
    required this.style,
    required this.autofocus,
    required this.inputAction,
    required this.validator,
    required this.onSavedSubmitted,
    required this.minuteLabelText,
    this.restorationId,
  });

  final Duration selectedDuration;
  final TextStyle style;
  final bool? autofocus;
  final TextInputAction inputAction;
  final FormFieldValidator<String> validator;
  final ValueChanged<String?> onSavedSubmitted;
  final String? minuteLabelText;
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    return _HourMinuteTextField(
      restorationId: restorationId,
      selectedDuration: selectedDuration,
      isHour: false,
      autofocus: autofocus,
      inputAction: inputAction,
      style: style,
      semanticHintText: minuteLabelText ?? MaterialLocalizations.of(context).timePickerMinuteLabel,
      validator: validator,
      onSavedSubmitted: onSavedSubmitted,
    );
  }
}

class _HourMinuteTextField extends StatefulWidget {
  const _HourMinuteTextField({
    required this.selectedDuration,
    required this.isHour,
    required this.autofocus,
    required this.inputAction,
    required this.style,
    required this.semanticHintText,
    required this.validator,
    required this.onSavedSubmitted,
    this.restorationId,
    this.onChanged,
  });

  final Duration selectedDuration;
  final bool isHour;
  final bool? autofocus;
  final TextInputAction inputAction;
  final TextStyle style;
  final String semanticHintText;
  final FormFieldValidator<String> validator;
  final ValueChanged<String?> onSavedSubmitted;
  final ValueChanged<String>? onChanged;
  final String? restorationId;

  @override
  _HourMinuteTextFieldState createState() => _HourMinuteTextFieldState();
}

class _HourMinuteTextFieldState extends State<_HourMinuteTextField> with RestorationMixin {
  final RestorableTextEditingController controller = RestorableTextEditingController();
  final RestorableBool controllerHasBeenSet = RestorableBool(false);
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode()
      ..addListener(() {
        setState(() {
          // Rebuild when focus changes.
        });
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only set the text value if it has not been populated with a localized
    // version yet.
    if (!controllerHasBeenSet.value) {
      controllerHasBeenSet.value = true;
      controller.value.text = _formattedValue;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    controllerHasBeenSet.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(controller, 'text_editing_controller');
    registerForRestoration(controllerHasBeenSet, 'has_controller_been_set');
  }

  String get _formattedValue {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    return !widget.isHour
        ? localizations.formatDurationMinute(widget.selectedDuration)
        : localizations.formatDurationHour(widget.selectedDuration);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData timePickerTheme = TimePickerTheme.of(context);
    final _TimePickerDefaults defaultTheme = theme.useMaterial3 ? _TimePickerDefaultsM3(context) : _TimePickerDefaultsM2(context);

    final InputDecorationTheme inputDecorationTheme = timePickerTheme.inputDecorationTheme ?? defaultTheme.inputDecorationTheme;
    InputDecoration inputDecoration = const InputDecoration().applyDefaults(inputDecorationTheme);
    // Remove the hint text when focused because the centered cursor
    // appears odd above the hint text.
    final String? hintText = focusNode.hasFocus ? null : _formattedValue;

    // Because the fill color is specified in both the inputDecorationTheme and
    // the TimePickerTheme, if there's one in the user's input decoration theme,
    // use that. If not, but there's one in the user's
    // timePickerTheme.hourMinuteColor, use that, and otherwise use the default.
    // We ignore the value in the fillColor of the input decoration in the
    // default theme here, but it's the same as the hourMinuteColor.
    final Color startingFillColor =
      timePickerTheme.inputDecorationTheme?.fillColor ??
      timePickerTheme.hourMinuteColor ??
      defaultTheme.hourMinuteColor;
    final Color fillColor;
    if (theme.useMaterial3) {
      fillColor = MaterialStateProperty.resolveAs<Color>(
        startingFillColor,
        <MaterialState>{
          if (focusNode.hasFocus) MaterialState.focused,
          if (focusNode.hasFocus) MaterialState.selected,
        },
      );
    } else {
      fillColor = focusNode.hasFocus ? Colors.transparent : startingFillColor;
    }

    inputDecoration = inputDecoration.copyWith(
      hintText: hintText,
      fillColor: fillColor,
    );

    final Set<MaterialState> states = <MaterialState>{
      if (focusNode.hasFocus) MaterialState.focused,
      if (focusNode.hasFocus) MaterialState.selected,
    };
    final Color effectiveTextColor = MaterialStateProperty.resolveAs<Color>(
      timePickerTheme.hourMinuteTextColor ?? defaultTheme.hourMinuteTextColor,
      states,
    );
    final TextStyle effectiveStyle = MaterialStateProperty.resolveAs<TextStyle>(widget.style, states)
      .copyWith(color: effectiveTextColor);

    return SizedBox.fromSize(
      size: defaultTheme.hourMinuteInputSize24Hour,
      child: MediaQuery.withNoTextScaling(
        child: UnmanagedRestorationScope(
          bucket: bucket,
          child: Semantics(
            label: widget.semanticHintText,
            child: TextFormField(
              restorationId: 'hour_minute_text_form_field',
              autofocus: widget.autofocus ?? false,
              expands: true,
              maxLines: null,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(2),
              ],
              focusNode: focusNode,
              textAlign: TextAlign.center,
              textInputAction: widget.inputAction,
              keyboardType: TextInputType.number,
              style: effectiveStyle,
              controller: controller.value,
              decoration: inputDecoration,
              validator: widget.validator,
              onEditingComplete: () => widget.onSavedSubmitted(controller.value.text),
              onSaved: widget.onSavedSubmitted,
              onFieldSubmitted: widget.onSavedSubmitted,
              onChanged: widget.onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

/// Signature for when the time picker entry mode is changed.
typedef DurationEntryModeChangeCallback = void Function(DurationPickerEntryMode mode);

/// A Material Design time picker designed to appear inside a popup dialog.
///
/// Pass this widget to [showDialog]. The value returned by [showDialog] is the
/// selected [Duration] if the user taps the "OK" button, or null if the user
/// taps the "CANCEL" button. The selected time is reported by calling
/// [Navigator.pop].
///
/// Use [showDurationPicker] to show a dialog already containing a [DurationPickerDialog].
class DurationPickerDialog extends StatefulWidget {
  /// Creates a Material Design time picker.
  const DurationPickerDialog({
    super.key,
    this.initialDuration,
    this.cancelText,
    this.confirmText,
    this.helpText,
    this.errorInvalidText,
    this.hourLabelText,
    this.minuteLabelText,
    this.restorationId,
    this.initialEntryMode = DurationPickerEntryMode.dial,
    this.durationPickerMode = DurationPickerMode.hms,
    this.orientation,
    this.onEntryModeChanged,
  });

  /// The time initially selected when the dialog is shown.
  final Duration? initialDuration;

  /// Optionally provide your own text for the cancel button.
  ///
  /// If null, the button uses [MaterialLocalizations.cancelButtonLabel].
  final String? cancelText;

  /// Optionally provide your own text for the confirm button.
  ///
  /// If null, the button uses [MaterialLocalizations.okButtonLabel].
  final String? confirmText;

  /// Optionally provide your own help text to the header of the time picker.
  final String? helpText;

  /// Optionally provide your own validation error text.
  final String? errorInvalidText;

  /// Optionally provide your own hour label text.
  final String? hourLabelText;

  /// Optionally provide your own minute label text.
  final String? minuteLabelText;

  /// Restoration ID to save and restore the state of the [DurationPickerDialog].
  ///
  /// If it is non-null, the time picker will persist and restore the
  /// dialog's state.
  ///
  /// The state of this widget is persisted in a [RestorationBucket] claimed
  /// from the surrounding [RestorationScope] using the provided restoration ID.
  ///
  /// See also:
  ///
  ///  * [RestorationManager], which explains how state restoration works in
  ///    Flutter.
  final String? restorationId;

  /// The entry mode for the picker. Whether it's text input or a dial.
  final DurationPickerEntryMode initialEntryMode;

  /// The duration picker mode. Whether it's hours, minutes, or seconds input.
  final DurationPickerMode durationPickerMode;

  /// The optional [orientation] parameter sets the [Orientation] to use when
  /// displaying the dialog.
  ///
  /// By default, the orientation is derived from the [MediaQueryData.size] of
  /// the ambient [MediaQuery]. If the aspect of the size is tall, then
  /// [Orientation.portrait] is used, if the size is wide, then
  /// [Orientation.landscape] is used.
  ///
  /// Use this parameter to override the default and force the dialog to appear
  /// in either portrait or landscape mode regardless of the aspect of the
  /// [MediaQueryData.size].
  final Orientation? orientation;

  /// Callback called when the selected entry mode is changed.
  final DurationEntryModeChangeCallback? onEntryModeChanged;

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> with RestorationMixin {
  late final RestorableEnum<DurationPickerEntryMode> _entryMode = RestorableEnum<DurationPickerEntryMode>(widget.initialEntryMode, values: DurationPickerEntryMode.values);
  late final RestorableDuration _selectedDuration = RestorableDuration(widget.initialDuration ?? Duration.zero);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RestorableEnum<AutovalidateMode> _autovalidateMode = RestorableEnum<AutovalidateMode>(AutovalidateMode.disabled, values: AutovalidateMode.values);
  late final RestorableEnumN<Orientation> _orientation = RestorableEnumN<Orientation>(widget.orientation, values: Orientation.values);

  // Base sizes
  static const Size _kTimePickerPortraitSize = Size(310, 468);
  static const Size _kTimePickerLandscapeSize = Size(524, 342);
  static const Size _kTimePickerLandscapeSizeM2 = Size(508, 300);
  static const Size _kTimePickerInputSize = Size(312, 216);

  // Absolute minimum dialog sizes, which is the point at which it begins
  // scrolling to fit everything in.
  static const Size _kTimePickerMinPortraitSize = Size(238, 326);
  static const Size _kTimePickerMinLandscapeSize = Size(416, 248);
  static const Size _kTimePickerMinInputSize = Size(312, 196);

  @override
  void dispose() {
    _selectedDuration.dispose();
    _entryMode.dispose();
    _autovalidateMode.dispose();
    _orientation.dispose();
    super.dispose();
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDuration, 'selected_time');
    registerForRestoration(_entryMode, 'entry_mode');
    registerForRestoration(_autovalidateMode, 'autovalidate_mode');
    registerForRestoration(_orientation, 'orientation');
  }

  void _handleTimeChanged(Duration value) {
    if (value != _selectedDuration.value) {
      setState(() {
        _selectedDuration.value = value;
      });
    }
  }

  void _handleEntryModeChanged(DurationPickerEntryMode value) {
    if (value != _entryMode.value) {
      setState(() {
        switch (_entryMode.value) {
          case DurationPickerEntryMode.dial:
            _autovalidateMode.value = AutovalidateMode.disabled;
          case DurationPickerEntryMode.input:
            _formKey.currentState!.save();
          case DurationPickerEntryMode.dialOnly:
            break;
          case DurationPickerEntryMode.inputOnly:
            break;
        }
        _entryMode.value = value;
        widget.onEntryModeChanged?.call(value);
      });
    }
  }

  void _toggleEntryMode() {
    switch (_entryMode.value) {
      case DurationPickerEntryMode.dial:
        _handleEntryModeChanged(DurationPickerEntryMode.input);
      case DurationPickerEntryMode.input:
        _handleEntryModeChanged(DurationPickerEntryMode.dial);
      case DurationPickerEntryMode.dialOnly:
      case DurationPickerEntryMode.inputOnly:
        FlutterError('Can not change entry mode from $_entryMode');
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    if (_entryMode.value == DurationPickerEntryMode.input || _entryMode.value == DurationPickerEntryMode.inputOnly) {
      final FormState form = _formKey.currentState!;
      if (!form.validate()) {
        setState(() {
          _autovalidateMode.value = AutovalidateMode.always;
        });
        return;
      }
      form.save();
    }
    Navigator.pop(context, _selectedDuration.value);
  }

  Size _minDialogSize(BuildContext context, {required bool useMaterial3}) {
    final Orientation orientation = _orientation.value ?? MediaQuery.orientationOf(context);

    switch (_entryMode.value) {
      case DurationPickerEntryMode.dial:
      case DurationPickerEntryMode.dialOnly:
        return switch (orientation) {
          Orientation.portrait  => _kTimePickerMinPortraitSize,
          Orientation.landscape => _kTimePickerMinLandscapeSize,
        };
      case DurationPickerEntryMode.input:
      case DurationPickerEntryMode.inputOnly:
        final MaterialLocalizations localizations = MaterialLocalizations.of(context);
        final DurationFormat durationFormat = localizations.durationFormat();
        final double timePickerWidth;
        switch (durationFormat) {
          case DurationFormat.HH_colon_mm:
          case DurationFormat.HH_dot_mm:
          case DurationFormat.frenchCanadian:
          case DurationFormat.H_colon_mm:
            final _TimePickerDefaults defaultTheme = useMaterial3 ? _TimePickerDefaultsM3(context) : _TimePickerDefaultsM2(context);
            timePickerWidth = _kTimePickerMinInputSize.width - defaultTheme.dayPeriodPortraitSize.width - 12;
        }
        return Size(timePickerWidth, _kTimePickerMinInputSize.height);
    }
  }

  Size _dialogSize(BuildContext context, {required bool useMaterial3}) {
    final Orientation orientation = _orientation.value ?? MediaQuery.orientationOf(context);
    // Constrain the textScaleFactor to prevent layout issues. Since only some
    // parts of the time picker scale up with textScaleFactor, we cap the factor
    // to 1.1 as that provides enough space to reasonably fit all the content.
    //
    // 14 is a common font size used to compute the effective text scale.
    const double fontSizeToScale = 14.0;
    final double textScaleFactor = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1).scale(fontSizeToScale) / fontSizeToScale;

    final Size timePickerSize;
    switch (_entryMode.value) {
      case DurationPickerEntryMode.dial:
      case DurationPickerEntryMode.dialOnly:
        switch (orientation) {
          case Orientation.portrait:
            timePickerSize = _kTimePickerPortraitSize;
          case Orientation.landscape:
            timePickerSize = Size(
              _kTimePickerLandscapeSize.width * textScaleFactor,
              useMaterial3 ? _kTimePickerLandscapeSize.height : _kTimePickerLandscapeSizeM2.height
            );
        }
      case DurationPickerEntryMode.input:
      case DurationPickerEntryMode.inputOnly:
        final MaterialLocalizations localizations = MaterialLocalizations.of(context);
        final DurationFormat durationFormat = localizations.durationFormat();
        final double timePickerWidth;
        switch (durationFormat) {
          case DurationFormat.HH_colon_mm:
          case DurationFormat.HH_dot_mm:
          case DurationFormat.frenchCanadian:
          case DurationFormat.H_colon_mm:
            final _TimePickerDefaults defaultTheme = useMaterial3 ? _TimePickerDefaultsM3(context) : _TimePickerDefaultsM2(context);
            timePickerWidth = _kTimePickerInputSize.width - defaultTheme.dayPeriodPortraitSize.width - 12;
        }
        timePickerSize = Size(timePickerWidth, _kTimePickerInputSize.height);
    }
    return Size(timePickerSize.width, timePickerSize.height * textScaleFactor);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData pickerTheme = TimePickerTheme.of(context);
    final _TimePickerDefaults defaultTheme = theme.useMaterial3 ? _TimePickerDefaultsM3(context) : _TimePickerDefaultsM2(context);
    final ShapeBorder shape = pickerTheme.shape ?? defaultTheme.shape;
    final Color entryModeIconColor = pickerTheme.entryModeIconColor ?? defaultTheme.entryModeIconColor;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);

    final Widget actions = Padding(
      padding: EdgeInsetsDirectional.only(start: theme.useMaterial3 ? 0 : 4),
      child: Row(
        children: <Widget>[
          if (_entryMode.value == DurationPickerEntryMode.dial || _entryMode.value == DurationPickerEntryMode.input)
            IconButton(
              // In material3 mode, we want to use the color as part of the
              // button style which applies its own opacity. In material2 mode,
              // we want to use the color as the color, which already includes
              // the opacity.
              color: theme.useMaterial3 ? null : entryModeIconColor,
              style: theme.useMaterial3 ? IconButton.styleFrom(foregroundColor: entryModeIconColor) : null,
              onPressed: _toggleEntryMode,
              icon: Icon(_entryMode.value == DurationPickerEntryMode.dial ? Icons.keyboard_outlined : Icons.access_time),
              tooltip: _entryMode.value == DurationPickerEntryMode.dial
                  ? MaterialLocalizations.of(context).inputTimeModeButtonLabel
                  : MaterialLocalizations.of(context).dialModeButtonLabel,
            ),
          Expanded(
            child: Container(
              alignment: AlignmentDirectional.centerEnd,
              constraints: const BoxConstraints(minHeight: 36),
              child: OverflowBar(
                spacing: 8,
                overflowAlignment: OverflowBarAlignment.end,
                children: <Widget>[
                  TextButton(
                    style: pickerTheme.cancelButtonStyle ?? defaultTheme.cancelButtonStyle,
                    onPressed: _handleCancel,
                    child: Text(widget.cancelText ??
                        (theme.useMaterial3
                            ? localizations.cancelButtonLabel
                            : localizations.cancelButtonLabel.toUpperCase())),
                  ),
                  TextButton(
                    style: pickerTheme.confirmButtonStyle ?? defaultTheme.confirmButtonStyle,
                    onPressed: _handleOk,
                    child: Text(widget.confirmText ?? localizations.okButtonLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final Offset tapTargetSizeOffset = switch (theme.materialTapTargetSize) {
      MaterialTapTargetSize.padded => Offset.zero,
      // _dialogSize returns "padded" sizes.
      MaterialTapTargetSize.shrinkWrap => const Offset(0, -12),
    };
    final Size dialogSize = _dialogSize(context, useMaterial3: theme.useMaterial3) + tapTargetSizeOffset;
    final Size minDialogSize = _minDialogSize(context, useMaterial3: theme.useMaterial3) + tapTargetSizeOffset;
    return Dialog(
      shape: shape,
      elevation: pickerTheme.elevation ?? defaultTheme.elevation,
      backgroundColor: pickerTheme.backgroundColor ?? defaultTheme.backgroundColor,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: (_entryMode.value == DurationPickerEntryMode.input || _entryMode.value == DurationPickerEntryMode.inputOnly) ? 0 : 24,
      ),
      child: Padding(
        padding: pickerTheme.padding ?? defaultTheme.padding,
        child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
          final Size constrainedSize = constraints.constrain(dialogSize);
          final Size allowedSize = Size(
            constrainedSize.width < minDialogSize.width ? minDialogSize.width : constrainedSize.width,
            constrainedSize.height < minDialogSize.height ? minDialogSize.height : constrainedSize.height,
          );
          return SingleChildScrollView(
            restorationId: 'time_picker_scroll_view_horizontal',
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              restorationId: 'time_picker_scroll_view_vertical',
              child: AnimatedContainer(
                width: allowedSize.width,
                height: allowedSize.height,
                duration: _kDialogSizeAnimationDuration,
                curve: Curves.easeIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autovalidateMode.value,
                        child: _TimePicker(
                          time: widget.initialDuration ?? Duration.zero,
                          onTimeChanged: _handleTimeChanged,
                          helpText: widget.helpText,
                          cancelText: widget.cancelText,
                          confirmText: widget.confirmText,
                          errorInvalidText: widget.errorInvalidText,
                          hourLabelText: widget.hourLabelText,
                          minuteLabelText: widget.minuteLabelText,
                          restorationId: 'time_picker',
                          entryMode: _entryMode.value,
                          orientation: widget.orientation,
                          onEntryModeChanged: _handleEntryModeChanged,
                        ),
                      ),
                    ),
                    actions,
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// The _TimePicker widget is constructed so that in the future we could expose
// this as a public API for embedding time pickers into other non-dialog
// widgets, once we're sure we want to support that.

/// A Time Picker widget that can be embedded into another widget.
class _TimePicker extends StatefulWidget {
  /// Creates a const Material Design time picker.
  const _TimePicker({
    required this.time,
    required this.onTimeChanged,
    this.helpText,
    this.cancelText,
    this.confirmText,
    this.errorInvalidText,
    this.hourLabelText,
    this.minuteLabelText,
    this.restorationId,
    this.entryMode = DurationPickerEntryMode.dial,
    this.orientation,
    this.onEntryModeChanged,
  });

  /// Optionally provide your own text for the help text at the top of the
  /// control.
  ///
  /// If null, the widget uses [MaterialLocalizations.timePickerDialHelpText]
  /// when the [entryMode] is [DurationPickerEntryMode.dial], and
  /// [MaterialLocalizations.timePickerInputHelpText] when the [entryMode] is
  /// [DurationPickerEntryMode.input].
  final String? helpText;

  /// Optionally provide your own text for the cancel button.
  ///
  /// If null, the button uses [MaterialLocalizations.cancelButtonLabel].
  final String? cancelText;

  /// Optionally provide your own text for the confirm button.
  ///
  /// If null, the button uses [MaterialLocalizations.okButtonLabel].
  final String? confirmText;

  /// Optionally provide your own validation error text.
  final String? errorInvalidText;

  /// Optionally provide your own hour label text.
  final String? hourLabelText;

  /// Optionally provide your own minute label text.
  final String? minuteLabelText;

  /// Restoration ID to save and restore the state of the [DurationPickerDialog].
  ///
  /// If it is non-null, the time picker will persist and restore the
  /// dialog's state.
  ///
  /// The state of this widget is persisted in a [RestorationBucket] claimed
  /// from the surrounding [RestorationScope] using the provided restoration ID.
  ///
  /// See also:
  ///
  ///  * [RestorationManager], which explains how state restoration works in
  ///    Flutter.
  final String? restorationId;

  /// The initial entry mode for the picker. Whether it's text input or a dial.
  final DurationPickerEntryMode entryMode;

  /// The currently selected time of day.
  final Duration time;

  final ValueChanged<Duration>? onTimeChanged;

  /// The optional [orientation] parameter sets the [Orientation] to use when
  /// displaying the dialog.
  ///
  /// By default, the orientation is derived from the [MediaQueryData.size] of
  /// the ambient [MediaQuery]. If the aspect of the size is tall, then
  /// [Orientation.portrait] is used, if the size is wide, then
  /// [Orientation.landscape] is used.
  ///
  /// Use this parameter to override the default and force the dialog to appear
  /// in either portrait or landscape mode regardless of the aspect of the
  /// [MediaQueryData.size].
  final Orientation? orientation;

  /// Callback called when the selected entry mode is changed.
  final DurationEntryModeChangeCallback? onEntryModeChanged;

  @override
  State<_TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<_TimePicker> with RestorationMixin {
  Timer? _vibrateTimer;
  late MaterialLocalizations localizations;
  final RestorableEnum<_DurationMode> _hourMinuteMode =
      RestorableEnum<_DurationMode>(_DurationMode.hour, values: _DurationMode.values);
  final RestorableEnumN<_DurationMode> _lastModeAnnounced =
      RestorableEnumN<_DurationMode>(null, values: _DurationMode.values);
  final RestorableBoolN _autofocusHour = RestorableBoolN(null);
  final RestorableBoolN _autofocusMinute = RestorableBoolN(null);
  final RestorableBool _announcedInitialTime = RestorableBool(false);
  late final RestorableEnumN<Orientation> _orientation =
      RestorableEnumN<Orientation>(widget.orientation, values: Orientation.values);
  RestorableDuration get selectedDuration => _selectedDuration;
  late final RestorableDuration _selectedDuration = RestorableDuration(widget.time);

  @override
  void dispose() {
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    _orientation.dispose();
    _selectedDuration.dispose();
    _hourMinuteMode.dispose();
    _lastModeAnnounced.dispose();
    _autofocusHour.dispose();
    _autofocusMinute.dispose();
    _announcedInitialTime.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
    _announceInitialTimeOnce();
    _announceModeOnce();
  }

  @override
  void didUpdateWidget (_TimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orientation != widget.orientation) {
      _orientation.value = widget.orientation;
    }
    if (oldWidget.time != widget.time) {
      _selectedDuration.value = widget.time;
    }
  }

  void _setEntryMode(DurationPickerEntryMode mode){
    widget.onEntryModeChanged?.call(mode);
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_hourMinuteMode, 'hour_minute_mode');
    registerForRestoration(_lastModeAnnounced, 'last_mode_announced');
    registerForRestoration(_autofocusHour, 'autofocus_hour');
    registerForRestoration(_autofocusMinute, 'autofocus_minute');
    registerForRestoration(_announcedInitialTime, 'announced_initial_time');
    registerForRestoration(_selectedDuration, 'selected_time');
    registerForRestoration(_orientation, 'orientation');
  }

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _vibrateTimer?.cancel();
        _vibrateTimer = Timer(_kVibrateCommitDelay, () {
          HapticFeedback.vibrate();
          _vibrateTimer = null;
        });
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
    }
  }

  void _handleHourMinuteModeChanged(_DurationMode mode) {
    _vibrate();
    setState(() {
      _hourMinuteMode.value = mode;
      _announceModeOnce();
    });
  }

  void _handleEntryModeToggle() {
    setState(() {
      DurationPickerEntryMode newMode = widget.entryMode;
      switch (widget.entryMode) {
        case DurationPickerEntryMode.dial:
          newMode = DurationPickerEntryMode.input;
        case DurationPickerEntryMode.input:
          _autofocusHour.value = false;
          _autofocusMinute.value = false;
          newMode = DurationPickerEntryMode.dial;
        case DurationPickerEntryMode.dialOnly:
        case DurationPickerEntryMode.inputOnly:
          FlutterError('Can not change entry mode from ${widget.entryMode}');
      }
      _setEntryMode(newMode);
    });
  }

  void _announceModeOnce() {
    if (_lastModeAnnounced.value == _hourMinuteMode.value) {
      // Already announced it.
      return;
    }

    switch (_hourMinuteMode.value) {
      case _DurationMode.hour:
        _announceToAccessibility(context, localizations.timePickerHourModeAnnouncement);
      case _DurationMode.minute:
        _announceToAccessibility(context, localizations.timePickerMinuteModeAnnouncement);
      case _DurationMode.second:
        _announceToAccessibility(context, localizations.timePickerSecondModeAnnouncement);
    }
    _lastModeAnnounced.value = _hourMinuteMode.value;
  }

  void _announceInitialTimeOnce() {
    if (_announcedInitialTime.value) {
      return;
    }

    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    _announceToAccessibility(
      context,
      localizations.formatDuration(_selectedDuration.value),
    );
    _announcedInitialTime.value = true;
  }

  void _handleTimeChanged(Duration value) {
    _vibrate();
    setState(() {
      _selectedDuration.value = value;
      widget.onTimeChanged?.call(value);
    });
  }

  void _handleHourDoubleTapped() {
    _autofocusHour.value = true;
    _handleEntryModeToggle();
  }

  void _handleMinuteDoubleTapped() {
    _autofocusMinute.value = true;
    _handleEntryModeToggle();
  }

  void _handleHourSelected() {
    setState(() {
      _hourMinuteMode.value = _DurationMode.minute;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final DurationFormat durationFormat = localizations.durationFormat();
    final ThemeData theme = Theme.of(context);
    final _TimePickerDefaults defaultTheme = theme.useMaterial3 ? _TimePickerDefaultsM3(context, entryMode: widget.entryMode) : _TimePickerDefaultsM2(context);
    final Orientation orientation = _orientation.value ?? MediaQuery.orientationOf(context);
    final HourFormat durationHour = hourDurationFormat(of: durationFormat);
    final _HourDialType hourMode = switch (durationHour) {
      HourFormat.HH || HourFormat.H when theme.useMaterial3 => _HourDialType.twentyFourHourDoubleRing,
      HourFormat.HH || HourFormat.H => _HourDialType.twentyFourHour,
      HourFormat.h => throw AssertionError('Duration cannot have an hour format `HourFormat.h`'),
    };

    final String helpText;
    final Widget picker;
    switch (widget.entryMode) {
      case DurationPickerEntryMode.dial:
      case DurationPickerEntryMode.dialOnly:
        helpText = widget.helpText ?? (theme.useMaterial3
          ? localizations.timePickerDialHelpText
          : localizations.timePickerDialHelpText.toUpperCase());

        final EdgeInsetsGeometry dialPadding = switch (orientation) {
          Orientation.portrait  => const EdgeInsets.only(left: 12, right: 12, top: 36),
          Orientation.landscape => const EdgeInsetsDirectional.only(start: 64),
        };
        final Widget dial = Padding(
          padding: dialPadding,
          child: ExcludeSemantics(
            child: SizedBox.fromSize(
              size: defaultTheme.dialSize,
              child: AspectRatio(
                aspectRatio: 1,
                child: _Dial(
                  durationMode: _hourMinuteMode.value,
                  hourDialType: hourMode,
                  selectedDuration: _selectedDuration.value,
                  onChanged: _handleTimeChanged,
                  onHourSelected: _handleHourSelected,
                ),
              ),
            ),
          ),
        );

        switch (orientation) {
          case Orientation.portrait:
            picker = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.useMaterial3 ? 0 : 16),
                  child: _TimePickerHeader(helpText: helpText),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Dial grows and shrinks with the available space.
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: theme.useMaterial3 ? 0 : 16),
                          child: dial,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          case Orientation.landscape:
            picker = Column(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: theme.useMaterial3 ? 0 : 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _TimePickerHeader(helpText: helpText),
                        Expanded(child: dial),
                      ],
                    ),
                  ),
                ),
              ],
            );
        }
      case DurationPickerEntryMode.input:
      case DurationPickerEntryMode.inputOnly:
        final String helpText =  widget.helpText ?? (theme.useMaterial3
          ? localizations.timePickerInputHelpText
          : localizations.timePickerInputHelpText.toUpperCase());

        picker = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _TimePickerInput(
              initialSelectedTime: _selectedDuration.value,
              errorInvalidText: widget.errorInvalidText,
              hourLabelText: widget.hourLabelText,
              minuteLabelText: widget.minuteLabelText,
              helpText: helpText,
              autofocusHour: _autofocusHour.value,
              autofocusMinute: _autofocusMinute.value,
              restorationId: 'time_picker_input',
            ),
          ],
        );
    }
    return _DurationPickerModel(
      entryMode: widget.entryMode,
      selectedDuration: _selectedDuration.value,
      hourMinuteMode: _hourMinuteMode.value,
      orientation: orientation,
      onHourMinuteModeChanged: _handleHourMinuteModeChanged,
      onHourDoubleTapped: _handleHourDoubleTapped,
      onMinuteDoubleTapped: _handleMinuteDoubleTapped,
      hourDialType: hourMode,
      onSelectedDurationChanged: _handleTimeChanged,
      useMaterial3: theme.useMaterial3,
      theme: TimePickerTheme.of(context),
      defaultTheme: defaultTheme,
      child: picker,
    );
  }
}

/// Shows a dialog containing a Material Design time picker.
///
/// The returned Future resolves to the time selected by the user when the user
/// closes the dialog. If the user cancels the dialog, null is returned.
///
/// {@tool snippet} Show a dialog with [initialDuration] equal to the current time.
///
/// ```dart
/// Future<Duration?> selectedDuration = showDurationPicker(
///   initialDuration: Duration.now(),
///   context: context,
/// );
/// ```
/// {@end-tool}
///
/// The [context], [barrierDismissible], [barrierColor], [barrierLabel],
/// [useRootNavigator] and [routeSettings] arguments are passed to [showDialog],
/// the documentation for which discusses how it is used.
///
/// The [builder] parameter can be used to wrap the dialog widget to add
/// inherited widgets like [Localizations.override], [Directionality], or
/// [MediaQuery].
///
/// The `initialEntryMode` parameter can be used to determine the initial time
/// entry selection of the picker (either a clock dial or text input).
///
/// Optional strings for the [helpText], [cancelText], [errorInvalidText],
/// [hourLabelText], [minuteLabelText] and [confirmText] can be provided to
/// override the default values.
///
/// The optional [orientation] parameter sets the [Orientation] to use when
/// displaying the dialog. By default, the orientation is derived from the
/// [MediaQueryData.size] of the ambient [MediaQuery]: wide sizes use the
/// landscape orientation, and tall sizes use the portrait orientation. Use this
/// parameter to override the default and force the dialog to appear in either
/// portrait or landscape mode.
///
/// {@macro flutter.widgets.RawDialogRoute}
///
/// By default, the time picker gets its colors from the overall theme's
/// [ColorScheme]. The time picker can be further customized by providing a
/// [TimePickerThemeData] to the overall theme.
///
/// {@tool snippet} Show a dialog with the text direction overridden to be
/// [TextDirection.rtl].
///
/// ```dart
/// Future<Duration?> selectedDurationRTL = showDurationPicker(
///   context: context,
///   initialDuration: Duration.now(),
///   builder: (BuildContext context, Widget? child) {
///     return Directionality(
///       textDirection: TextDirection.rtl,
///       child: child!,
///     );
///   },
/// );
/// ```
/// {@end-tool}
///
/// {@tool snippet} Show a dialog with time unconditionally displayed in 24 hour
/// format.
///
/// ```dart
/// Future<Duration?> selectedDuration24Hour = showDurationPicker(
///   context: context,
///   initialDuration: const Duration(hours: 10, minutes: 47),
///   builder: (BuildContext context, Widget? child) {
///     return MediaQuery(
///       data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
///       child: child!,
///     );
///   },
/// );
/// ```
/// {@end-tool}
///
/// {@tool dartpad}
/// This example illustrates how to open a time picker, and allows exploring
/// some of the variations in the types of time pickers that may be shown.
///
/// ** See code in examples/api/lib/material/time_picker/show_time_picker.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [showDatePicker], which shows a dialog that contains a Material Design
///   date picker.
/// * [TimePickerThemeData], which allows you to customize the colors,
///   typography, and shape of the time picker.
/// * [DisplayFeatureSubScreen], which documents the specifics of how
///   [DisplayFeature]s can split the screen into sub-screens.
Future<Duration?> showDurationPicker({
  required BuildContext context,
  Duration? initialDuration,
  TransitionBuilder? builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  DurationPickerEntryMode initialEntryMode = DurationPickerEntryMode.dial,
  DurationPickerMode durationPickerMode = DurationPickerMode.hms,
  String? cancelText,
  String? confirmText,
  String? helpText,
  String? errorInvalidText,
  String? hourLabelText,
  String? minuteLabelText,
  RouteSettings? routeSettings,
  DurationEntryModeChangeCallback? onEntryModeChanged,
  Offset? anchorPoint,
  Orientation? orientation,
}) async {
  assert(debugCheckHasMaterialLocalizations(context));

  final Widget dialog = DurationPickerDialog(
    initialDuration: initialDuration,
    initialEntryMode: initialEntryMode,
    cancelText: cancelText,
    confirmText: confirmText,
    helpText: helpText,
    errorInvalidText: errorInvalidText,
    hourLabelText: hourLabelText,
    minuteLabelText: minuteLabelText,
    orientation: orientation,
    onEntryModeChanged: onEntryModeChanged,
  );
  return showDialog<Duration>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useRootNavigator: useRootNavigator,
    builder: (BuildContext context) {
      return builder == null ? dialog : builder(context, dialog);
    },
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
  );
}

void _announceToAccessibility(BuildContext context, String message) {
  SemanticsService.announce(message, Directionality.of(context));
}

// An abstract base class for the M2 and M3 defaults below, so that their return
// types can be non-nullable.
abstract class _TimePickerDefaults extends TimePickerThemeData {
  @override
  Color get backgroundColor;

  @override
  ButtonStyle get cancelButtonStyle;

  @override
  ButtonStyle get confirmButtonStyle;

  @override
  BorderSide get dayPeriodBorderSide;

  @override
  Color get dayPeriodColor;

  @override
  OutlinedBorder get dayPeriodShape;

  Size get dayPeriodInputSize;
  Size get dayPeriodLandscapeSize;
  Size get dayPeriodPortraitSize;

  @override
  Color get dayPeriodTextColor;

  @override
  TextStyle get dayPeriodTextStyle;

  @override
  Color get dialBackgroundColor;

  @override
  Color get dialHandColor;

  // Sizes that are generated from the tokens, but these aren't ones we're ready
  // to expose in the theme.
  Size get dialSize;
  double get handWidth;
  double get dotRadius;
  double get centerRadius;

  @override
  Color get dialTextColor;

  @override
  TextStyle get dialTextStyle;

  @override
  double get elevation;

  @override
  Color get entryModeIconColor;

  @override
  TextStyle get helpTextStyle;

  @override
  Color get hourMinuteColor;

  @override
  ShapeBorder get hourMinuteShape;

  Size get hourMinuteSize;
  Size get hourMinuteSize24Hour;
  Size get hourMinuteInputSize;
  Size get hourMinuteInputSize24Hour;

  @override
  Color get hourMinuteTextColor;

  @override
  TextStyle get hourMinuteTextStyle;

  @override
  InputDecorationTheme get inputDecorationTheme;

  @override
  EdgeInsetsGeometry get padding;

  @override
  ShapeBorder get shape;
}

// These theme defaults are not auto-generated: they match the values for the
// Material 2 spec, which are not expected to change.
class _TimePickerDefaultsM2 extends _TimePickerDefaults {
  _TimePickerDefaultsM2(this.context) : super();

  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;
  static const OutlinedBorder _kDefaultShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)));

  @override
  Color get backgroundColor {
    return _colors.surface;
  }

  @override
  ButtonStyle get cancelButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  ButtonStyle get confirmButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  BorderSide get dayPeriodBorderSide {
    return BorderSide(
      color: Color.alphaBlend(_colors.onSurface.withOpacity(0.38), _colors.surface),
    );
  }

  @override
  Color get dayPeriodColor {
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return _colors.primary.withOpacity(_colors.brightness == Brightness.dark ? 0.24 : 0.12);
      }
      // The unselected day period should match the overall picker dialog color.
      // Making it transparent enables that without being redundant and allows
      // the optional elevation overlay for dark mode to be visible.
      return Colors.transparent;
    });
  }

  @override
  OutlinedBorder get dayPeriodShape {
    return _kDefaultShape;
  }

  @override
  Size get dayPeriodPortraitSize {
    return const Size(52, 80);
  }

  @override
  Size get dayPeriodLandscapeSize {
    return const Size(0, 40);
  }

  @override
  Size get dayPeriodInputSize {
    return const Size(52, 70);
  }

  @override
  Color get dayPeriodTextColor {
    return  MaterialStateColor.resolveWith((Set<MaterialState> states) {
      return states.contains(MaterialState.selected) ? _colors.primary : _colors.onSurface.withOpacity(0.60);
    });
  }

  @override
  TextStyle get dayPeriodTextStyle {
    return _textTheme.titleMedium!.copyWith(color: dayPeriodTextColor);
  }

  @override
  Color get dialBackgroundColor {
    return _colors.onSurface.withOpacity(_colors.brightness == Brightness.dark ? 0.12 : 0.08);
  }

  @override
  Color get dialHandColor {
    return _colors.primary;
  }

  @override
  Size get dialSize {
    return const Size.square(280);
  }

  @override
  double get handWidth {
    return 2;
  }

  @override
  double get dotRadius {
    return 22;
  }

  @override
  double get centerRadius {
    return 4;
  }

  @override
  Color get dialTextColor {
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return _colors.surface;
      }
      return _colors.onSurface;
    });
  }

  @override
  TextStyle get dialTextStyle {
    return _textTheme.bodyLarge!;
  }

  @override
  double get elevation {
    return 6;
  }

  @override
  Color get entryModeIconColor {
    return _colors.onSurface.withOpacity(_colors.brightness == Brightness.dark ? 1.0 : 0.6);
  }

  @override
  TextStyle get helpTextStyle {
    return _textTheme.labelSmall!;
  }

  @override
  Color get hourMinuteColor {
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      return states.contains(MaterialState.selected)
          ? _colors.primary.withOpacity(_colors.brightness == Brightness.dark ? 0.24 : 0.12)
          : _colors.onSurface.withOpacity(0.12);
    });
  }

  @override
  ShapeBorder get hourMinuteShape {
    return _kDefaultShape;
  }

  @override
  Size get hourMinuteSize {
    return const Size(96, 80);
  }

  @override
  Size get hourMinuteSize24Hour {
    return const Size(114, 80);
  }

  @override
  Size get hourMinuteInputSize {
    return const Size(96, 70);
  }

  @override
  Size get hourMinuteInputSize24Hour {
    return const Size(114, 70);
  }

  @override
  Color get hourMinuteTextColor {
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      return states.contains(MaterialState.selected) ? _colors.primary : _colors.onSurface;
    });
  }

  @override
  TextStyle get hourMinuteTextStyle {
    return _textTheme.displayMedium!;
  }

  Color get _hourMinuteInputColor {
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      return states.contains(MaterialState.selected)
          ? Colors.transparent
          : _colors.onSurface.withOpacity(0.12);
    });
  }

  @override
  InputDecorationTheme get inputDecorationTheme {
    return InputDecorationTheme(
      contentPadding: EdgeInsets.zero,
      filled: true,
      fillColor: _hourMinuteInputColor,
      focusColor: Colors.transparent,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.transparent),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _colors.error, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _colors.primary, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _colors.error, width: 2),
      ),
      hintStyle: hourMinuteTextStyle.copyWith(color: _colors.onSurface.withOpacity(0.36)),
      // Prevent the error text from appearing.
      // TODO(rami-a): Remove this workaround once
      // https://github.com/flutter/flutter/issues/54104
      // is fixed.
      errorStyle: const TextStyle(fontSize: 0, height: 0),
    );
  }

  @override
  EdgeInsetsGeometry get padding {
    return const EdgeInsets.fromLTRB(8, 18, 8, 8);
  }

  @override
  ShapeBorder get shape {
    return _kDefaultShape;
  }
}

// BEGIN GENERATED TOKEN PROPERTIES - TimePicker

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _TimePickerDefaultsM3 extends _TimePickerDefaults {
  _TimePickerDefaultsM3(this.context, { this.entryMode = DurationPickerEntryMode.dial });

  final BuildContext context;
  final DurationPickerEntryMode entryMode;

  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color get backgroundColor {
    return _colors.surfaceContainerHigh;
  }

  @override
  ButtonStyle get cancelButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  ButtonStyle get confirmButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  BorderSide get dayPeriodBorderSide {
    return BorderSide(color: _colors.outline);
  }

  @override
  Color get dayPeriodColor {
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return _colors.tertiaryContainer;
      }
      // The unselected day period should match the overall picker dialog color.
      // Making it transparent enables that without being redundant and allows
      // the optional elevation overlay for dark mode to be visible.
      return Colors.transparent;
    });
  }

  @override
  OutlinedBorder get dayPeriodShape {
    return const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))).copyWith(side: dayPeriodBorderSide);
  }

  @override
  Size get dayPeriodPortraitSize {
    return const Size(52, 80);
  }

  @override
  Size get dayPeriodLandscapeSize {
    return const Size(216, 38);
  }

  @override
  Size get dayPeriodInputSize {
    // Input size is eight pixels smaller than the portrait size in the spec,
    // but there's not token for it yet.
    return Size(dayPeriodPortraitSize.width, dayPeriodPortraitSize.height - 8);
  }

  @override
  Color get dayPeriodTextColor {
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.focused)) {
          return _colors.onTertiaryContainer;
        }
        if (states.contains(MaterialState.hovered)) {
          return _colors.onTertiaryContainer;
        }
        if (states.contains(MaterialState.pressed)) {
          return _colors.onTertiaryContainer;
        }
        return _colors.onTertiaryContainer;
      }
      if (states.contains(MaterialState.focused)) {
        return _colors.onSurfaceVariant;
      }
      if (states.contains(MaterialState.hovered)) {
        return _colors.onSurfaceVariant;
      }
      if (states.contains(MaterialState.pressed)) {
        return _colors.onSurfaceVariant;
      }
      return _colors.onSurfaceVariant;
    });
  }

  @override
  TextStyle get dayPeriodTextStyle {
    return _textTheme.titleMedium!.copyWith(color: dayPeriodTextColor);
  }

  @override
  Color get dialBackgroundColor {
    return _colors.surfaceContainerHighest;
  }

  @override
  Color get dialHandColor {
    return _colors.primary;
  }

  @override
  Size get dialSize {
    return const Size.square(256.0);
  }

  @override
  double get handWidth {
    return const Size(2, double.infinity).width;
  }

  @override
  double get dotRadius {
    return const Size.square(48.0).width / 2;
  }

  @override
  double get centerRadius {
    return const Size.square(8.0).width / 2;
  }

  @override
  Color get dialTextColor {
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return _colors.onPrimary;
      }
      return _colors.onSurface;
    });
  }

  @override
  TextStyle get dialTextStyle {
    return _textTheme.bodyLarge!;
  }

  @override
  double get elevation {
    return 6.0;
  }

  @override
  Color get entryModeIconColor {
    return _colors.onSurface;
  }

  @override
  TextStyle get helpTextStyle {
    return MaterialStateTextStyle.resolveWith((Set<MaterialState> states) {
      final TextStyle textStyle = _textTheme.labelMedium!;
      return textStyle.copyWith(color: _colors.onSurfaceVariant);
    });
  }

  @override
  EdgeInsetsGeometry get padding {
    return const EdgeInsets.all(24);
  }

  @override
  Color get hourMinuteColor {
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        Color overlayColor = _colors.primaryContainer;
        if (states.contains(MaterialState.pressed)) {
          overlayColor = _colors.onPrimaryContainer;
        } else if (states.contains(MaterialState.hovered)) {
          const double hoverOpacity = 0.08;
          overlayColor = _colors.onPrimaryContainer.withOpacity(hoverOpacity);
        } else if (states.contains(MaterialState.focused)) {
          const double focusOpacity = 0.1;
          overlayColor = _colors.onPrimaryContainer.withOpacity(focusOpacity);
        }
        return Color.alphaBlend(overlayColor, _colors.primaryContainer);
      } else {
        Color overlayColor = _colors.surfaceContainerHighest;
        if (states.contains(MaterialState.pressed)) {
          overlayColor = _colors.onSurface;
        } else if (states.contains(MaterialState.hovered)) {
          const double hoverOpacity = 0.08;
          overlayColor = _colors.onSurface.withOpacity(hoverOpacity);
        } else if (states.contains(MaterialState.focused)) {
          const double focusOpacity = 0.1;
          overlayColor = _colors.onSurface.withOpacity(focusOpacity);
        }
        return Color.alphaBlend(overlayColor, _colors.surfaceContainerHighest);
      }
    });
  }

  @override
  ShapeBorder get hourMinuteShape {
    return const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)));
  }

  @override
  Size get hourMinuteSize {
    return const Size(96, 80);
  }

  @override
  Size get hourMinuteSize24Hour {
    return Size(const Size(114, double.infinity).width, hourMinuteSize.height);
  }

  @override
  Size get hourMinuteInputSize {
    // Input size is eight pixels smaller than the regular size in the spec, but
    // there's not token for it yet.
    return Size(hourMinuteSize.width, hourMinuteSize.height - 8);
  }

  @override
  Size get hourMinuteInputSize24Hour {
    // Input size is eight pixels smaller than the regular size in the spec, but
    // there's not token for it yet.
    return Size(hourMinuteSize24Hour.width, hourMinuteSize24Hour.height - 8);
  }

  @override
  Color get hourMinuteTextColor {
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      return _hourMinuteTextColor.resolve(states);
    });
  }

  MaterialStateProperty<Color> get _hourMinuteTextColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.pressed)) {
          return _colors.onPrimaryContainer;
        }
        if (states.contains(MaterialState.hovered)) {
          return _colors.onPrimaryContainer;
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.onPrimaryContainer;
        }
        return _colors.onPrimaryContainer;
      } else {
        // unselected
        if (states.contains(MaterialState.pressed)) {
          return _colors.onSurface;
        }
        if (states.contains(MaterialState.hovered)) {
          return _colors.onSurface;
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.onSurface;
        }
        return _colors.onSurface;
      }
    });
  }

  @override
  TextStyle get hourMinuteTextStyle {
    return MaterialStateTextStyle.resolveWith((Set<MaterialState> states) {
      // TODO(tahatesser): Update this when https://github.com/flutter/flutter/issues/131247 is fixed.
      // This is using the correct text style from Material 3 spec.
      // https://m3.material.io/components/time-pickers/specs#fd0b6939-edab-4058-82e1-93d163945215
      return switch (entryMode) {
        DurationPickerEntryMode.dial || DurationPickerEntryMode.dialOnly
          => _textTheme.displayLarge!.copyWith(color: _hourMinuteTextColor.resolve(states)),
        DurationPickerEntryMode.input || DurationPickerEntryMode.inputOnly
          => _textTheme.displayMedium!.copyWith(color: _hourMinuteTextColor.resolve(states)),
      };
    });
  }

  @override
  InputDecorationTheme get inputDecorationTheme {
    // This is NOT correct, but there's no token for
    // 'time-input.container.shape', so this is using the radius from the shape
    // for the hour/minute selector. It's a BorderRadiusGeometry, so we have to
    // resolve it before we can use it.
    final BorderRadius selectorRadius = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)))
      .borderRadius
      .resolve(Directionality.of(context));
    return InputDecorationTheme(
      contentPadding: EdgeInsets.zero,
      filled: true,
      // This should be derived from a token, but there isn't one for 'time-input'.
      fillColor: hourMinuteColor,
      // This should be derived from a token, but there isn't one for 'time-input'.
      focusColor: _colors.primaryContainer,
      enabledBorder: OutlineInputBorder(
        borderRadius: selectorRadius,
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: selectorRadius,
        borderSide: BorderSide(color: _colors.error, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: selectorRadius,
        borderSide: BorderSide(color: _colors.primary, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: selectorRadius,
        borderSide: BorderSide(color: _colors.error, width: 2),
      ),
      hintStyle: hourMinuteTextStyle.copyWith(color: _colors.onSurface.withOpacity(0.36)),
      // Prevent the error text from appearing.
      // TODO(rami-a): Remove this workaround once
      // https://github.com/flutter/flutter/issues/54104
      // is fixed.
      errorStyle: const TextStyle(fontSize: 0, height: 0),
    );
  }

  @override
  ShapeBorder get shape {
    return const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0)));
  }

  @override
  MaterialStateProperty<Color?>? get timeSelectorSeparatorColor {
    // TODO(tahatesser): Update this when tokens are available.
    // This is taken from https://m3.material.io/components/time-pickers/specs.
    return MaterialStatePropertyAll<Color>(_colors.onSurface);
  }

  @override
  MaterialStateProperty<TextStyle?>? get timeSelectorSeparatorTextStyle {
    // TODO(tahatesser): Update this when tokens are available.
    // This is taken from https://m3.material.io/components/time-pickers/specs.
    return MaterialStatePropertyAll<TextStyle?>(_textTheme.displayLarge);
  }
}

// END GENERATED TOKEN PROPERTIES - TimePicker
