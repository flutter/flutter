// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'button_bar.dart';
import 'button.dart';
import 'colors.dart';
import 'dialog.dart';
import 'flat_button.dart';
import 'theme.dart';
import 'typography.dart';

const Duration _kDialAnimateDuration = const Duration(milliseconds: 200);
const double _kTwoPi = 2 * math.PI;
const int _kHoursPerDay = 24;
const int _kHoursPerPeriod = 12;
const int _kMinutesPerHour = 60;

/// Whether the [TimeOfDay] is before or after noon.
enum DayPeriod {
  /// Ante meridiem (before noon).
  am,

  /// Post meridiem (after noon).
  pm,
}

/// A value representing a time during the day
class TimeOfDay {
  /// Creates a time of day.
  ///
  /// The [hour] argument must be between 0 and 23, inclusive. The [minute]
  /// argument must be between 0 and 59, inclusive.
  const TimeOfDay({ @required this.hour, @required this.minute });

  /// Creates a time of day based on the given time.
  ///
  /// The [hour] is set to the time's hour and the [minute] is set to the time's
  /// minute in the timezone of the given [DateTime].
  TimeOfDay.fromDateTime(DateTime time) : hour = time.hour, minute = time.minute;

  /// Creates a time of day based on the current time.
  ///
  /// The [hour] is set to the current hour and the [minute] is set to the
  /// current minute in the local time zone.
  factory TimeOfDay.now() { return new TimeOfDay.fromDateTime(new DateTime.now()); }

  /// Returns a new TimeOfDay with the hour and/or minute replaced.
  TimeOfDay replacing({ int hour, int minute }) {
    assert(hour == null || (hour >= 0 && hour < _kHoursPerDay));
    assert(minute == null || (minute >= 0 && minute < _kMinutesPerHour));
    return new TimeOfDay(hour: hour ?? this.hour, minute: minute ?? this.minute);
  }

  /// The selected hour, in 24 hour time from 0..23.
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

  @override
  bool operator ==(dynamic other) {
    if (other is! TimeOfDay)
      return false;
    final TimeOfDay typedOther = other;
    return typedOther.hour == hour
        && typedOther.minute == minute;
  }

  @override
  int get hashCode => hashValues(hour, minute);

  // TODO(ianh): Localize.
  @override
  String toString() => '$hourOfPeriodLabel:$minuteLabel $periodLabel';
}

enum _TimePickerMode { hour, minute }

const double _kTimePickerHeaderPortraitHeight = 96.0;
const double _kTimePickerHeaderLandscapeWidth = 168.0;

const double _kTimePickerWidthPortrait = 328.0;
const double _kTimePickerWidthLanscape = 512.0;

const double _kTimePickerHeightPortrait = 484.0;
const double _kTimePickerHeightLanscape = 304.0;

// TODO(ianh): Localize!
class _TimePickerHeader extends StatelessWidget {
  _TimePickerHeader({
    @required this.selectedTime,
    @required this.mode,
    @required this.orientation,
    @required this.onModeChanged,
    @required this.onChanged,
  }) {
    assert(selectedTime != null);
    assert(mode != null);
    assert(orientation != null);
  }

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final Orientation orientation;
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

  TextStyle _getBaseHeaderStyle(TextTheme headerTextTheme) {
    // These font sizes aren't listed in the spec explicitly. I worked them out
    // by measuring the text using a screen ruler and comparing them to the
    // screen shots of the time picker in the spec.
    assert(orientation != null);
    switch (orientation) {
      case Orientation.portrait:
        return headerTextTheme.display3.copyWith(fontSize: 60.0);
      case Orientation.landscape:
        return headerTextTheme.display2.copyWith(fontSize: 50.0);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    TextTheme headerTextTheme = themeData.primaryTextTheme;
    TextStyle baseHeaderStyle = _getBaseHeaderStyle(headerTextTheme);
    Color activeColor;
    Color inactiveColor;
    switch(themeData.primaryColorBrightness) {
      case Brightness.light:
        activeColor = Colors.black87;
        inactiveColor = Colors.black54;
        break;
      case Brightness.dark:
        activeColor = Colors.white;
        inactiveColor = Colors.white70;
        break;
    }

    Color backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = themeData.primaryColor;
        break;
      case Brightness.dark:
        backgroundColor = themeData.backgroundColor;
        break;
    }

    TextStyle activeStyle = baseHeaderStyle.copyWith(color: activeColor);
    TextStyle inactiveStyle = baseHeaderStyle.copyWith(color: inactiveColor);

    TextStyle hourStyle = mode == _TimePickerMode.hour ? activeStyle : inactiveStyle;
    TextStyle minuteStyle = mode == _TimePickerMode.minute ? activeStyle : inactiveStyle;

    TextStyle amStyle = headerTextTheme.subhead.copyWith(
      color: selectedTime.period == DayPeriod.am ? activeColor: inactiveColor
    );
    TextStyle pmStyle = headerTextTheme.subhead.copyWith(
      color: selectedTime.period == DayPeriod.pm ? activeColor: inactiveColor
    );

    Widget dayPeriodPicker = new GestureDetector(
      onTap: _handleChangeDayPeriod,
      behavior: HitTestBehavior.opaque,
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new Text('AM', style: amStyle),
          const SizedBox(width: 0.0, height: 4.0),  // Vertical spacer
          new Text('PM', style: pmStyle),
        ]
      )
    );

    Widget hour = new Align(
      alignment: FractionalOffset.centerRight,
      child: new GestureDetector(
        onTap: () => _handleChangeMode(_TimePickerMode.hour),
        child: new Text(selectedTime.hourOfPeriodLabel, style: hourStyle),
      )
    );

    Widget minute = new GestureDetector(
      onTap: () => _handleChangeMode(_TimePickerMode.minute),
      child: new Text(selectedTime.minuteLabel, style: minuteStyle),
    );

    assert(orientation != null);
    switch (orientation) {
      case Orientation.portrait:
        return new Container(
          height: _kTimePickerHeaderPortraitHeight,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          decoration: new BoxDecoration(backgroundColor: backgroundColor),
          child: new Row(
            children: <Widget>[
              new Flexible(child: hour),
              new Text(':', style: inactiveStyle),
              new Flexible(
                child: new Row(
                  children: <Widget>[
                    minute,
                    const SizedBox(width: 8.0, height: 0.0),  // Horizontal spacer
                    dayPeriodPicker,
                  ]
                )
              )
            ]
          )
        );
      case Orientation.landscape:
        return new Container(
          width: _kTimePickerHeaderLandscapeWidth,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: new BoxDecoration(backgroundColor: backgroundColor),
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Row(
                children: <Widget>[
                  new Flexible(child: hour),
                  new Text(':', style: inactiveStyle),
                  new Flexible(child: minute),
                ],
              ),
              const SizedBox(width: 0.0, height: 8.0),  // Vertical spacer
              dayPeriodPicker,
            ]
          )
        );
    }
    return null;
  }
}

List<TextPainter> _initPainters(TextTheme textTheme, List<String> labels) {
  TextStyle style = textTheme.subhead;
  List<TextPainter> painters = new List<TextPainter>(labels.length);
  for (int i = 0; i < painters.length; ++i) {
    String label = labels[i];
    // TODO(abarth): Handle textScaleFactor.
    // https://github.com/flutter/flutter/issues/5939
    painters[i] = new TextPainter(
      text: new TextSpan(style: style, text: label)
    )..layout();
  }
  return painters;
}

List<TextPainter> _initHours(TextTheme textTheme) {
  return _initPainters(textTheme, <String>[
    '12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'
  ]);
}

List<TextPainter> _initMinutes(TextTheme textTheme) {
  return _initPainters(textTheme, <String>[
    '00', '05', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55'
  ]);
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    this.primaryLabels,
    this.secondaryLabels,
    this.backgroundColor,
    this.accentColor,
    this.theta
  });

  final List<TextPainter> primaryLabels;
  final List<TextPainter> secondaryLabels;
  final Color backgroundColor;
  final Color accentColor;
  final double theta;

  @override
  void paint(Canvas canvas, Size size) {
    double radius = size.shortestSide / 2.0;
    Offset center = new Offset(size.width / 2.0, size.height / 2.0);
    Point centerPoint = center.toPoint();
    canvas.drawCircle(centerPoint, radius, new Paint()..color = backgroundColor);

    const double labelPadding = 24.0;
    double labelRadius = radius - labelPadding;
    Offset getOffsetForTheta(double theta) {
      return center + new Offset(labelRadius * math.cos(theta),
                                 -labelRadius * math.sin(theta));
    }

    void paintLabels(List<TextPainter> labels) {
      double labelThetaIncrement = -_kTwoPi / labels.length;
      double labelTheta = math.PI / 2.0;

      for (TextPainter label in labels) {
        Offset labelOffset = new Offset(-label.width / 2.0, -label.height / 2.0);
        label.paint(canvas, getOffsetForTheta(labelTheta) + labelOffset);
        labelTheta += labelThetaIncrement;
      }
    }

    paintLabels(primaryLabels);

    final Paint selectorPaint = new Paint()
      ..color = accentColor;
    final Point focusedPoint = getOffsetForTheta(theta).toPoint();
    final double focusedRadius = labelPadding - 4.0;
    canvas.drawCircle(centerPoint, 4.0, selectorPaint);
    canvas.drawCircle(focusedPoint, focusedRadius, selectorPaint);
    selectorPaint.strokeWidth = 2.0;
    canvas.drawLine(centerPoint, focusedPoint, selectorPaint);

    final Rect focusedRect = new Rect.fromCircle(
      center: focusedPoint, radius: focusedRadius
    );
    canvas
      ..saveLayer(focusedRect, new Paint())
      ..clipPath(new Path()..addOval(focusedRect));
    paintLabels(secondaryLabels);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter oldPainter) {
    return oldPainter.primaryLabels != primaryLabels
        || oldPainter.secondaryLabels != secondaryLabels
        || oldPainter.backgroundColor != backgroundColor
        || oldPainter.accentColor != accentColor
        || oldPainter.theta != theta;
  }
}

class _Dial extends StatefulWidget {
  _Dial({
    @required this.selectedTime,
    @required this.mode,
    @required this.onChanged
  }) {
    assert(selectedTime != null);
  }

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  _DialState createState() => new _DialState();
}

class _DialState extends State<_Dial> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _thetaController = new AnimationController(
      duration: _kDialAnimateDuration,
      vsync: this,
    );
    _thetaTween = new Tween<double>(begin: _getThetaForTime(config.selectedTime));
    _theta = _thetaTween.animate(new CurvedAnimation(
      parent: _thetaController,
      curve: Curves.fastOutSlowIn
    ))..addListener(() => setState(() { }));
  }

  @override
  void didUpdateConfig(_Dial oldConfig) {
    if (config.mode != oldConfig.mode && !_dragging)
      _animateTo(_getThetaForTime(config.selectedTime));
  }

  @override
  void dispose() {
    _thetaController.dispose();
    super.dispose();
  }

  Tween<double> _thetaTween;
  Animation<double> _theta;
  AnimationController _thetaController;
  bool _dragging = false;

  static double _nearest(double target, double a, double b) {
    return ((target - a).abs() < (target - b).abs()) ? a : b;
  }

  void _animateTo(double targetTheta) {
    double currentTheta = _theta.value;
    double beginTheta = _nearest(targetTheta, currentTheta, currentTheta + _kTwoPi);
    beginTheta = _nearest(targetTheta, beginTheta, currentTheta - _kTwoPi);
    _thetaTween
      ..begin = beginTheta
      ..end = targetTheta;
    _thetaController
      ..value = 0.0
      ..forward();
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
      final Offset offset = _position - _center;
      final double angle = (math.atan2(offset.dx, offset.dy) - math.PI / 2.0) % _kTwoPi;
      _thetaTween
        ..begin = angle
        ..end = angle; // The controller doesn't animate during the pan gesture.
    });
  }

  Point _position;
  Point _center;

  void _handlePanStart(DragStartDetails details) {
    assert(!_dragging);
    _dragging = true;
    RenderBox box = context.findRenderObject();
    _position = box.globalToLocal(details.globalPosition);
    double radius = box.size.shortestSide / 2.0;
    _center = new Point(radius, radius);
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _position += details.delta;
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();
  }

  void _handlePanEnd(DragEndDetails details) {
    assert(_dragging);
    _dragging = false;
    _position = null;
    _center = null;
    _animateTo(_getThetaForTime(config.selectedTime));
  }

  final List<TextPainter> _hoursWhite = _initHours(Typography.white);
  final List<TextPainter> _hoursBlack = _initHours(Typography.black);
  final List<TextPainter> _minutesWhite = _initMinutes(Typography.white);
  final List<TextPainter> _minutesBlack = _initMinutes(Typography.black);

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);

    Color backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = Colors.grey[200];
        break;
      case Brightness.dark:
        backgroundColor = themeData.backgroundColor;
        break;
    }

    List<TextPainter> primaryLabels;
    List<TextPainter> secondaryLabels;
    switch (config.mode) {
      case _TimePickerMode.hour:
        switch (themeData.brightness) {
          case Brightness.light:
            primaryLabels = _hoursBlack;
            secondaryLabels = _hoursWhite;
            break;
          case Brightness.dark:
            primaryLabels = _hoursWhite;
            secondaryLabels = _hoursBlack;
            break;
        }
        break;
      case _TimePickerMode.minute:
        switch (themeData.brightness) {
          case Brightness.light:
            primaryLabels = _minutesBlack;
            secondaryLabels = _minutesWhite;
            break;
          case Brightness.dark:
            primaryLabels = _minutesWhite;
            secondaryLabels = _minutesBlack;
            break;
        }
        break;
    }

    return new GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: new CustomPaint(
        key: const ValueKey<String>('time-picker-dial'), // used for testing.
        painter: new _DialPainter(
          primaryLabels: primaryLabels,
          secondaryLabels: secondaryLabels,
          backgroundColor: backgroundColor,
          accentColor: themeData.accentColor,
          theta: _theta.value
        )
      )
    );
  }
}

class _TimePickerDialog extends StatefulWidget {
  _TimePickerDialog({
    Key key,
    this.initialTime
  }) : super(key: key) {
    assert(initialTime != null);
  }

  final TimeOfDay initialTime;

  @override
  _TimePickerDialogState createState() => new _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  @override
  void initState() {
    super.initState();
    _selectedTime = config.initialTime;
  }

  _TimePickerMode _mode = _TimePickerMode.hour;
  TimeOfDay _selectedTime;

  void _handleModeChanged(_TimePickerMode mode) {
    HapticFeedback.vibrate();
    setState(() {
      _mode = mode;
    });
  }

  void _handleTimeChanged(TimeOfDay value) {
    setState(() {
      _selectedTime = value;
    });
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    Navigator.pop(context, _selectedTime);
  }

  @override
  Widget build(BuildContext context) {
    Widget picker = new Padding(
      padding: const EdgeInsets.all(16.0),
      child: new AspectRatio(
        aspectRatio: 1.0,
        child: new _Dial(
          mode: _mode,
          selectedTime: _selectedTime,
          onChanged: _handleTimeChanged,
        )
      )
    );

    Widget actions = new ButtonTheme.bar(
      child: new ButtonBar(
        children: <Widget>[
          new FlatButton(
            child: new Text('CANCEL'),
            onPressed: _handleCancel
          ),
          new FlatButton(
            child: new Text('OK'),
            onPressed: _handleOk
          ),
        ]
      )
    );

    return new Dialog(
      child: new OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          Widget header = new _TimePickerHeader(
            selectedTime: _selectedTime,
            mode: _mode,
            orientation: orientation,
            onModeChanged: _handleModeChanged,
            onChanged: _handleTimeChanged,
          );

          assert(orientation != null);
          switch (orientation) {
            case Orientation.portrait:
              return new SizedBox(
                width: _kTimePickerWidthPortrait,
                height: _kTimePickerHeightPortrait,
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    new Flexible(child: picker),
                    actions,
                  ]
                )
              );
            case Orientation.landscape:
              return new SizedBox(
                width: _kTimePickerWidthLanscape,
                height: _kTimePickerHeightLanscape,
                child: new Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    new Flexible(
                      fit: FlexFit.loose,
                      child: new Column(
                        children: <Widget>[
                          new Flexible(child: picker),
                          actions,
                        ]
                      )
                    ),
                  ]
                )
              );
          }
          return null;
        }
      )
    );
  }
}

/// Shows a dialog containing a material design time picker.
///
/// The returned Future resolves to the time selected by the user when the user
/// closes the dialog. If the user cancels the dialog, the Future resolves to
/// the [initialTime].
///
/// To show a dialog with [initialTime] equal to the current time:
/// ```dart
/// showTimePicker(
///   initialTime: new TimeOfDay.now(),
///   context: context
/// );
/// ```
///
/// See also:
///
///  * [showDatePicker]
///  * <https://www.google.com/design/spec/components/pickers.html#pickers-time-pickers>
Future<TimeOfDay> showTimePicker({
  BuildContext context,
  TimeOfDay initialTime
}) async {
  assert(initialTime != null);
  return await showDialog(
    context: context,
    child: new _TimePickerDialog(initialTime: initialTime)
  ) ?? initialTime;
}
