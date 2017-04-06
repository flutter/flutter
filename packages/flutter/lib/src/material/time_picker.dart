// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'button_bar.dart';
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
const Duration _kVibrateCommitDelay = const Duration(milliseconds: 100);

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
const double _kTimePickerWidthLandscape = 512.0;

const double _kTimePickerHeightPortrait = 484.0;
const double _kTimePickerHeightLandscape = 304.0;

const double _kPeriodGap = 8.0;

enum _TimePickerHeaderId {
  hour,
  colon,
  minute,
  period, // AM/PM picker
}

class _TimePickerHeaderLayout extends MultiChildLayoutDelegate {
  _TimePickerHeaderLayout(this.orientation);

  final Orientation orientation;

  @override
  void performLayout(Size size) {
    final BoxConstraints constraints = new BoxConstraints.loose(size);
    final Size hourSize = layoutChild(_TimePickerHeaderId.hour, constraints);
    final Size colonSize = layoutChild(_TimePickerHeaderId.colon, constraints);
    final Size minuteSize = layoutChild(_TimePickerHeaderId.minute, constraints);
    final Size periodSize = layoutChild(_TimePickerHeaderId.period, constraints);

    switch (orientation) {
      // 11:57--period
      //
      // The colon is centered horizontally, the entire layout is centered vertically.
      // The "--" is a _kPeriodGap horizontal gap.
      case Orientation.portrait:
        final double width = colonSize.width / 2.0 + minuteSize.width + _kPeriodGap + periodSize.width;
        final double right = math.max(0.0, size.width / 2.0 - width);

        double x = size.width - right - periodSize.width;
        positionChild(_TimePickerHeaderId.period, new Offset(x, (size.height - periodSize.height) / 2.0));

        x -= minuteSize.width + _kPeriodGap;
        positionChild(_TimePickerHeaderId.minute, new Offset(x, (size.height - minuteSize.height) / 2.0));

        x -= colonSize.width;
        positionChild(_TimePickerHeaderId.colon, new Offset(x, (size.height - colonSize.height) / 2.0));

        x -= hourSize.width;
        positionChild(_TimePickerHeaderId.hour, new Offset(x, (size.height - hourSize.height) / 2.0));
      break;

      // 11:57
      //  --
      // period
      //
      // The colon is centered horizontally, the entire layout is centered vertically.
      // The "--" is a _kPeriodGap vertical gap.
      case Orientation.landscape:
        final double width = colonSize.width / 2.0 + minuteSize.width;
        final double offset = math.max(0.0, size.width / 2.0 - width);
        final double timeHeight = math.max(hourSize.height, colonSize.height);
        final double height = timeHeight + _kPeriodGap + periodSize.height;
        final double timeCenter = (size.height - height) / 2.0 + timeHeight / 2.0;

        double x = size.width - offset - minuteSize.width;
        positionChild(_TimePickerHeaderId.minute, new Offset(x, timeCenter - minuteSize.height / 2.0));

        x -= colonSize.width;
        positionChild(_TimePickerHeaderId.colon, new Offset(x, timeCenter - colonSize.height / 2.0));

        x -= hourSize.width;
        positionChild(_TimePickerHeaderId.hour, new Offset(x, timeCenter - hourSize.height / 2.0));

        x = (size.width - periodSize.width) / 2.0;
        positionChild(_TimePickerHeaderId.period, new Offset(x, timeCenter + timeHeight / 2.0 + _kPeriodGap));
        break;
    }
  }

  @override
  bool shouldRelayout(_TimePickerHeaderLayout oldDelegate) => orientation != oldDelegate.orientation;
}


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
    final int newHour = (selectedTime.hour + _kHoursPerPeriod) % _kHoursPerDay;
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
    final ThemeData themeData = Theme.of(context);
    final TextTheme headerTextTheme = themeData.primaryTextTheme;
    final TextStyle baseHeaderStyle = _getBaseHeaderStyle(headerTextTheme);
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

    final TextStyle activeStyle = baseHeaderStyle.copyWith(color: activeColor);
    final TextStyle inactiveStyle = baseHeaderStyle.copyWith(color: inactiveColor);

    final TextStyle hourStyle = mode == _TimePickerMode.hour ? activeStyle : inactiveStyle;
    final TextStyle minuteStyle = mode == _TimePickerMode.minute ? activeStyle : inactiveStyle;

    final TextStyle amStyle = headerTextTheme.subhead.copyWith(
      color: selectedTime.period == DayPeriod.am ? activeColor: inactiveColor
    );
    final TextStyle pmStyle = headerTextTheme.subhead.copyWith(
      color: selectedTime.period == DayPeriod.pm ? activeColor: inactiveColor
    );

    final Widget dayPeriodPicker = new GestureDetector(
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

    final Widget hour = new GestureDetector(
      onTap: () => _handleChangeMode(_TimePickerMode.hour),
      child: new Text(selectedTime.hourOfPeriodLabel, style: hourStyle),
    );

    final Widget minute = new GestureDetector(
      onTap: () => _handleChangeMode(_TimePickerMode.minute),
      child: new Text(selectedTime.minuteLabel, style: minuteStyle),
    );

    final Widget colon = new Text(':', style: inactiveStyle);

    EdgeInsets padding;
    double height;
    double width;

    assert(orientation != null);
    switch(orientation) {
      case Orientation.portrait:
        height = _kTimePickerHeaderPortraitHeight;
        padding = const EdgeInsets.symmetric(horizontal: 24.0);
        break;
      case Orientation.landscape:
        width = _kTimePickerHeaderLandscapeWidth;
        padding = const EdgeInsets.symmetric(horizontal: 16.0);
        break;
    }

    return new Container(
      width: width,
      height: height,
      padding: padding,
      color: backgroundColor,
      child: new CustomMultiChildLayout(
        delegate: new _TimePickerHeaderLayout(orientation),
        children: <Widget>[
          new LayoutId(id: _TimePickerHeaderId.hour, child: hour),
          new LayoutId(id: _TimePickerHeaderId.colon, child: colon),
          new LayoutId(id: _TimePickerHeaderId.minute, child: minute),
          new LayoutId(id: _TimePickerHeaderId.period, child: dayPeriodPicker),
        ],
      )
    );
  }
}

List<TextPainter> _initPainters(TextTheme textTheme, List<String> labels) {
  final TextStyle style = textTheme.subhead;
  final List<TextPainter> painters = new List<TextPainter>(labels.length);
  for (int i = 0; i < painters.length; ++i) {
    final String label = labels[i];
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
    final double radius = size.shortestSide / 2.0;
    final Offset center = new Offset(size.width / 2.0, size.height / 2.0);
    final Point centerPoint = center.toPoint();
    canvas.drawCircle(centerPoint, radius, new Paint()..color = backgroundColor);

    const double labelPadding = 24.0;
    final double labelRadius = radius - labelPadding;
    Offset getOffsetForTheta(double theta) {
      return center + new Offset(labelRadius * math.cos(theta),
                                 -labelRadius * math.sin(theta));
    }

    void paintLabels(List<TextPainter> labels) {
      final double labelThetaIncrement = -_kTwoPi / labels.length;
      double labelTheta = math.PI / 2.0;

      for (TextPainter label in labels) {
        final Offset labelOffset = new Offset(-label.width / 2.0, -label.height / 2.0);
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
    final double currentTheta = _theta.value;
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
    final double fraction = (config.mode == _TimePickerMode.hour) ?
        (time.hour / _kHoursPerPeriod) % _kHoursPerPeriod :
        (time.minute / _kMinutesPerHour) % _kMinutesPerHour;
    return (math.PI / 2.0 - fraction * _kTwoPi) % _kTwoPi;
  }

  TimeOfDay _getTimeForTheta(double theta) {
    final double fraction = (0.25 - (theta % _kTwoPi) / _kTwoPi) % 1.0;
    if (config.mode == _TimePickerMode.hour) {
      final int hourOfPeriod = (fraction * _kHoursPerPeriod).round() % _kHoursPerPeriod;
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
    final TimeOfDay current = _getTimeForTheta(_theta.value);
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
    final RenderBox box = context.findRenderObject();
    _position = box.globalToLocal(details.globalPosition);
    _center = box.size.center(Point.origin);
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

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    Color backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = Colors.grey[200];
        break;
      case Brightness.dark:
        backgroundColor = themeData.backgroundColor;
        break;
    }

    final ThemeData theme = Theme.of(context);
    List<TextPainter> primaryLabels;
    List<TextPainter> secondaryLabels;
    switch (config.mode) {
      case _TimePickerMode.hour:
        primaryLabels = _initHours(theme.textTheme);
        secondaryLabels = _initHours(theme.accentTextTheme);
        break;
      case _TimePickerMode.minute:
        primaryLabels = _initMinutes(theme.textTheme);
        secondaryLabels = _initMinutes(theme.accentTextTheme);
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
    @required this.initialTime
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
  Timer _vibrateTimer;

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        _vibrateTimer?.cancel();
        _vibrateTimer = new Timer(_kVibrateCommitDelay, () {
          HapticFeedback.vibrate();
          _vibrateTimer = null;
        });
        break;
      case TargetPlatform.iOS:
        break;
    }
  }

  void _handleModeChanged(_TimePickerMode mode) {
    _vibrate();
    setState(() {
      _mode = mode;
    });
  }

  void _handleTimeChanged(TimeOfDay value) {
    _vibrate();
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
    final Widget picker = new Padding(
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

    final Widget actions = new ButtonTheme.bar(
      child: new ButtonBar(
        children: <Widget>[
          new FlatButton(
            child: const Text('CANCEL'),
            onPressed: _handleCancel
          ),
          new FlatButton(
            child: const Text('OK'),
            onPressed: _handleOk
          ),
        ]
      )
    );

    return new Dialog(
      child: new OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          final Widget header = new _TimePickerHeader(
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
                    new Expanded(child: picker),
                    actions,
                  ]
                )
              );
            case Orientation.landscape:
              return new SizedBox(
                width: _kTimePickerWidthLandscape,
                height: _kTimePickerHeightLandscape,
                child: new Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    new Flexible(
                      child: new Column(
                        children: <Widget>[
                          new Expanded(child: picker),
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

  @override
  void dispose() {
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    super.dispose();
  }
}

/// Shows a dialog containing a material design time picker.
///
/// The returned Future resolves to the time selected by the user when the user
/// closes the dialog. If the user cancels the dialog, null is returned.
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
///  * <https://material.google.com/components/pickers.html#pickers-time-pickers>
Future<TimeOfDay> showTimePicker({
  @required BuildContext context,
  @required TimeOfDay initialTime
}) async {
  assert(context != null);
  assert(initialTime != null);
  return await showDialog(
    context: context,
    child: new _TimePickerDialog(initialTime: initialTime)
  );
}
