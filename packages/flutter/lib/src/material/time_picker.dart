// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';
import 'typography.dart';
import 'constants.dart';

const Duration _kDialAnimateDuration = const Duration(milliseconds: 200);
const double _kTwoPi = 2 * math.PI;
const int _kHoursPerDay = 24;
const int _kHoursPerPeriod = 12;
const int _kMinutesPerHour = 60;

enum DayPeriod {
  am,
  pm,
}

/// A value representing a time during the day
class TimeOfDay {
  const TimeOfDay({ this.hour, this.minute });

  /// Returns a new TimeOfDay with the hour and/or minute replaced.
  TimeOfDay replacing({ int hour, int minute }) {
    assert(hour == null || (hour >= 0 && hour < _kHoursPerDay));
    assert(minute == null || (minute >= 0 && minute < _kMinutesPerHour));
    return new TimeOfDay(hour: hour ?? this.hour, minute: minute ?? this.minute);
  }

  /// The selected hour, in 24 hour time from 0..23
  final int hour;

  /// The selected minute.
  final int minute;

  /// Whether this time of day is before or after noon.
  DayPeriod get period => hour < _kHoursPerPeriod ? DayPeriod.am : DayPeriod.pm;

  /// Which hour of the current period (e.g., am or pm) this time is.
  int get hourOfPeriod => hour - periodOffset;

  String _addLeadingZeroIfNeeded(int value) {
    if (value < 10)
      return '0$value';
    return value.toString();
  }

  /// A string representing the hour, in 24 hour time (e.g., '04' or '18').
  String get hourLabel => _addLeadingZeroIfNeeded(hour);

  /// A string representing the minute (e.g., '07').
  String get minuteLabel => _addLeadingZeroIfNeeded(minute);

  /// A string representing the hour of the current period (e.g., '4' or '6').
  String get hourOfPeriodLabel {
    // TODO(ianh): Localize.
    final int hourOfPeriod = this.hourOfPeriod;
    if (hourOfPeriod == 0)
      return '12';
    return hourOfPeriod.toString();
  }

  /// A string representing the current period (e.g., 'a.m.').
  String get periodLabel => period == DayPeriod.am ? 'a.m.' : 'p.m.'; // TODO(ianh): Localize.

  /// The hour at which the current period starts.
  int get periodOffset => period == DayPeriod.am ? 0 : _kHoursPerPeriod;

  bool operator ==(dynamic other) {
    if (other is! TimeOfDay)
      return false;
    final TimeOfDay typedOther = other;
    return typedOther.hour == hour
        && typedOther.minute == minute;
  }

  int get hashCode => hashValues(hour, minute);

  // TODO(ianh): Localize.
  String toString() => '$hourOfPeriodLabel:$minuteLabel $periodLabel';
}

enum _TimePickerMode { hour, minute }

class TimePicker extends StatefulComponent {
  TimePicker({
    this.selectedTime,
    this.onChanged
  }) {
    assert(selectedTime != null);
  }

  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onChanged;

  _TimePickerState createState() => new _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  _TimePickerMode _mode = _TimePickerMode.hour;

  void _handleModeChanged(_TimePickerMode mode) {
    userFeedback.performHapticFeedback(HapticFeedbackType.VIRTUAL_KEY);
    setState(() {
      _mode = mode;
    });
  }

  Widget build(BuildContext context) {
    Widget header = new _TimePickerHeader(
      selectedTime: config.selectedTime,
      mode: _mode,
      onModeChanged: _handleModeChanged,
      onChanged: config.onChanged
    );
    return new Column(<Widget>[
      header,
      new AspectRatio(
        aspectRatio: 1.0,
        child: new Container(
          margin: const EdgeDims.all(12.0),
          child: new _Dial(
            mode: _mode,
            selectedTime: config.selectedTime,
            onChanged: config.onChanged
          )
        )
      )
    ], alignItems: FlexAlignItems.stretch);
  }
}

// TODO(ianh): Localize!
class _TimePickerHeader extends StatelessComponent {
  _TimePickerHeader({
    this.selectedTime,
    this.mode,
    this.onModeChanged,
    this.onChanged
  }) {
    assert(selectedTime != null);
    assert(mode != null);
  }

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final ValueChanged<_TimePickerMode> onModeChanged;
  final ValueChanged<TimeOfDay> onChanged;

  void _handleChangeMode(_TimePickerMode value) {
    if (value != mode)
      onModeChanged(value);
  }

  void _handleChangeDayPeriod() {
    int newHour = (selectedTime.hour + _kHoursPerPeriod) % _kHoursPerDay;
    onChanged(selectedTime.replacing(hour: newHour));
  }

  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextTheme headerTheme = theme.primaryTextTheme;

    Color activeColor;
    Color inactiveColor;
    switch(theme.primaryColorBrightness) {
      case ThemeBrightness.light:
        activeColor = Colors.black87;
        inactiveColor = Colors.black54;
        break;
      case ThemeBrightness.dark:
        activeColor = Colors.white;
        inactiveColor = Colors.white70;
        break;
    }
    TextStyle activeStyle = headerTheme.display3.copyWith(color: activeColor);
    TextStyle inactiveStyle = headerTheme.display3.copyWith(color: inactiveColor);

    TextStyle hourStyle = mode == _TimePickerMode.hour ? activeStyle : inactiveStyle;
    TextStyle minuteStyle = mode == _TimePickerMode.minute ? activeStyle : inactiveStyle;

    TextStyle amStyle = headerTheme.subhead.copyWith(
      color: selectedTime.period == DayPeriod.am ? activeColor: inactiveColor
    );
    TextStyle pmStyle = headerTheme.subhead.copyWith(
      color: selectedTime.period == DayPeriod.pm ? activeColor: inactiveColor
    );

    return new Container(
      padding: kDialogHeadingPadding,
      decoration: new BoxDecoration(backgroundColor: theme.primaryColor),
      child: new Row(<Widget>[
        new GestureDetector(
          onTap: () => _handleChangeMode(_TimePickerMode.hour),
          child: new Text(selectedTime.hourOfPeriodLabel, style: hourStyle)
        ),
        new Text(':', style: inactiveStyle),
        new GestureDetector(
          onTap: () => _handleChangeMode(_TimePickerMode.minute),
          child: new Text(selectedTime.minuteLabel, style: minuteStyle)
        ),
        new GestureDetector(
          onTap: _handleChangeDayPeriod,
          behavior: HitTestBehavior.opaque,
          child: new Container(
            padding: const EdgeDims.only(left: 16.0, right: 24.0),
            child: new Column([
              new Text('AM', style: amStyle),
              new Container(
                padding: const EdgeDims.only(top: 4.0),
                child: new Text('PM', style: pmStyle)
              ),
            ], justifyContent: FlexJustifyContent.end)
          )
        )
      ], justifyContent: FlexJustifyContent.end)
    );
  }
}

List<TextPainter> _initPainters(List<String> labels) {
  TextStyle style = Typography.black.subhead.copyWith(height: 1.0);
  List<TextPainter> painters = new List<TextPainter>(labels.length);
  for (int i = 0; i < painters.length; ++i) {
    String label = labels[i];
    TextPainter painter = new TextPainter(
      new StyledTextSpan(style, [
        new PlainTextSpan(label)
      ])
    );
    painter
      ..maxWidth = double.INFINITY
      ..maxHeight = double.INFINITY
      ..layout()
      ..maxWidth = painter.maxIntrinsicWidth
      ..layout();
    painters[i] = painter;
  }
  return painters;
}

List<TextPainter> _initHours() {
  return _initPainters(['12', '1', '2', '3', '4', '5',
                        '6', '7', '8', '9', '10', '11']);
}

List<TextPainter> _initMinutes() {
  return _initPainters(['00', '05', '10', '15', '20', '25',
                        '30', '35', '40', '45', '50', '55']);
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    this.labels,
    this.primaryColor,
    this.theta
  });

  final List<TextPainter> labels;
  final Color primaryColor;
  final double theta;

  void paint(Canvas canvas, Size size) {
    double radius = size.shortestSide / 2.0;
    Offset center = new Offset(size.width / 2.0, size.height / 2.0);
    Point centerPoint = center.toPoint();
    canvas.drawCircle(centerPoint, radius, new Paint()..color = Colors.grey[200]);

    const double labelPadding = 24.0;
    double labelRadius = radius - labelPadding;
    Offset getOffsetForTheta(double theta) {
      return center + new Offset(labelRadius * math.cos(theta),
                                 -labelRadius * math.sin(theta));
    }

    Paint primaryPaint = new Paint()
      ..color = primaryColor;
    Point currentPoint = getOffsetForTheta(theta).toPoint();
    canvas.drawCircle(centerPoint, 4.0, primaryPaint);
    canvas.drawCircle(currentPoint, labelPadding - 4.0, primaryPaint);
    primaryPaint.strokeWidth = 2.0;
    canvas.drawLine(centerPoint, currentPoint, primaryPaint);

    double labelThetaIncrement = -_kTwoPi / labels.length;
    double labelTheta = math.PI / 2.0;

    for (TextPainter label in labels) {
      Offset labelOffset = new Offset(-label.width / 2.0, -label.height / 2.0);
      label.paint(canvas, getOffsetForTheta(labelTheta) + labelOffset);
      labelTheta += labelThetaIncrement;
    }
  }

  bool shouldRepaint(_DialPainter oldPainter) {
    return oldPainter.labels != labels
        || oldPainter.primaryColor != primaryColor
        || oldPainter.theta != theta;
  }
}

class _Dial extends StatefulComponent {
  _Dial({
    this.selectedTime,
    this.mode,
    this.onChanged
  }) {
    assert(selectedTime != null);
  }

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final ValueChanged<TimeOfDay> onChanged;

  _DialState createState() => new _DialState();
}

class _DialState extends State<_Dial> {
  void initState() {
    super.initState();
    _theta = new ValuePerformance(
      variable: new AnimatedValue<double>(_getThetaForTime(config.selectedTime), curve: Curves.ease),
      duration: _kDialAnimateDuration
    )..addListener(() => setState(() { }));
  }

  void didUpdateConfig(_Dial oldConfig) {
    if (config.mode != oldConfig.mode && !_dragging)
      _animateTo(_getThetaForTime(config.selectedTime));
  }

  ValuePerformance<double> _theta;
  bool _dragging = false;

  static double _nearest(double target, double a, double b) {
    return ((target - a).abs() < (target - b).abs()) ? a : b;
  }

  void _animateTo(double targetTheta) {
    double currentTheta = _theta.value;
    double beginTheta = _nearest(targetTheta, currentTheta, currentTheta + _kTwoPi);
    beginTheta = _nearest(targetTheta, beginTheta, currentTheta - _kTwoPi);
    _theta
      ..variable.begin = beginTheta
      ..variable.end = targetTheta
      ..progress = 0.0
      ..play();
  }

  double _getThetaForTime(TimeOfDay time) {
    double fraction = (config.mode == _TimePickerMode.hour) ?
        (time.hour / _kHoursPerPeriod) % _kHoursPerPeriod :
        (time.minute / _kMinutesPerHour) % _kMinutesPerHour;
    return (math.PI / 2.0 - fraction * _kTwoPi) % _kTwoPi;
  }

  TimeOfDay _getTimeForTheta(double theta) {
    double fraction = (0.25 - (theta % _kTwoPi) / _kTwoPi) % 1.0;
    if (config.mode == _TimePickerMode.hour) {
      int hourOfPeriod = (fraction * _kHoursPerPeriod).round() % _kHoursPerPeriod;
      return config.selectedTime.replacing(
        hour: hourOfPeriod + config.selectedTime.periodOffset
      );
    } else {
      return config.selectedTime.replacing(
        minute: (fraction * _kMinutesPerHour).round() % _kMinutesPerHour
      );
    }
  }

  void _notifyOnChangedIfNeeded() {
    if (config.onChanged == null)
      return;
    TimeOfDay current = _getTimeForTheta(_theta.value);
    if (current != config.selectedTime)
      config.onChanged(current);
  }

  void _updateThetaForPan() {
    setState(() {
      Offset offset = _position - _center;
      _theta.variable.value = (math.atan2(offset.dx, offset.dy) - math.PI / 2.0) % _kTwoPi;
    });
  }

  Point _position;
  Point _center;

  void _handlePanStart(Point globalPosition) {
    assert(!_dragging);
    _dragging = true;
    RenderBox box = context.findRenderObject();
    _position = box.globalToLocal(globalPosition);
    double radius = box.size.shortestSide / 2.0;
    _center = new Point(radius, radius);
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();
  }

  void _handlePanUpdate(Offset delta) {
    _position += delta;
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();
  }

  void _handlePanEnd(Offset velocity) {
    assert(_dragging);
    _dragging = false;
    _position = null;
    _center = null;
    _animateTo(_getThetaForTime(config.selectedTime));
  }

  final List<TextPainter> _hours = _initHours();
  final List<TextPainter> _minutes = _initMinutes();

  Widget build(BuildContext context) {
    return new GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: new CustomPaint(
        painter: new _DialPainter(
          labels: config.mode == _TimePickerMode.hour ? _hours : _minutes,
          primaryColor: Theme.of(context).primaryColor,
          theta: _theta.value
        )
      )
    );
  }
}
