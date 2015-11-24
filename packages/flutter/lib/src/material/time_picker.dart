// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';
import 'typography.dart';

class TimeOfDay {
  const TimeOfDay({ this.hour, this.minute });

  TimeOfDay replacing({ int hour, int minute }) {
    return new TimeOfDay(hour: hour ?? this.hour, minute: minute ?? this.minute);
  }

  /// The selected hour, in 24 hour time from 0..23
  final int hour;

  /// The selected minute.
  final int minute;

  bool operator ==(dynamic other) {
    if (other is! TimeOfDay)
      return false;
    final TimeOfDay typedOther = other;
    return typedOther.hour == hour
        && typedOther.minute == minute;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value + hour.hashCode;
    value = 37 * value + minute.hashCode;
    return value;
  }

  String toString() => 'TimeOfDay(hour: $hour, minute: $minute)';
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
      onModeChanged: _handleModeChanged
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

// Shows the selected date in large font and toggles between year and day mode
class _TimePickerHeader extends StatelessComponent {
  _TimePickerHeader({ this.selectedTime, this.mode, this.onModeChanged }) {
    assert(selectedTime != null);
    assert(mode != null);
  }

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final ValueChanged<_TimePickerMode> onModeChanged;

  void _handleChangeMode(_TimePickerMode value) {
    if (value != mode)
      onModeChanged(value);
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

    return new Container(
      padding: new EdgeDims.all(10.0),
      decoration: new BoxDecoration(backgroundColor: theme.primaryColor),
      child: new Row(<Widget>[
        new GestureDetector(
          onTap: () => _handleChangeMode(_TimePickerMode.hour),
          child: new Text(selectedTime.hour.toString(), style: hourStyle)
        ),
        new Text(':', style: inactiveStyle),
        new GestureDetector(
          onTap: () => _handleChangeMode(_TimePickerMode.minute),
          child: new Text(selectedTime.minute.toString(), style: minuteStyle)
        ),
      ], justifyContent: FlexJustifyContent.end)
    );
  }
}

final List<TextPainter> _kHours = _initHours();
final List<TextPainter> _kMinutes = _initMinutes();

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

    double labelThetaIncrement = -2 * math.PI / _kHours.length;
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
  double _theta;

  void initState() {
    super.initState();
    _theta = _getThetaForTime(config.selectedTime);
  }

  void didUpdateConfig(_Dial oldConfig) {
    if (config.mode != oldConfig.mode)
      _theta = _getThetaForTime(config.selectedTime);
  }

  double _getThetaForTime(TimeOfDay time) {
    double fraction = (config.mode == _TimePickerMode.hour) ?
        (time.hour / 12) % 12 : (time.minute / 60) % 60;
    return math.PI / 2.0 - fraction * 2 * math.PI;
  }

  TimeOfDay _getTimeForTheta(double theta) {
    double fraction = (0.25 - (theta % (2 * math.PI)) / (2 * math.PI)) % 1.0;
    if (config.mode == _TimePickerMode.hour) {
      return config.selectedTime.replacing(
        hour: (fraction * 12).round()
      );
    } else {
      return config.selectedTime.replacing(
        minute: (fraction * 60).round()
      );
    }
  }

  void _notifyOnChangedIfNeeded() {
    if (config.onChanged == null)
      return;
    TimeOfDay current = _getTimeForTheta(_theta);
    if (current != config.selectedTime)
      config.onChanged(current);
  }

  void _updateThetaForPan() {
    setState(() {
      Offset offset = _position - _center;
      _theta = (math.atan2(offset.dx, offset.dy) - math.PI / 2.0) % (2 * math.PI);
    });
  }

  Point _position;
  Point _center;

  void _handlePanStart(Point globalPosition) {
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
    _position = null;
    _center = null;
    setState(() {
      // TODO(abarth): Animate to the final value.
      _theta = _getThetaForTime(config.selectedTime);
    });
  }

  Widget build(BuildContext context) {
    return new GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: new CustomPaint(
        painter: new _DialPainter(
          labels: config.mode == _TimePickerMode.hour ? _kHours : _kMinutes,
          primaryColor: Theme.of(context).primaryColor,
          theta: _theta
        )
      )
    );
  }
}
