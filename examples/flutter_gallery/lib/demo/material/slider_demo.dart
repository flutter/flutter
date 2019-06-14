// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../gallery/demo.dart';

class SliderDemo extends StatefulWidget {
  static const String routeName = '/material/slider';

  @override
  _SliderDemoState createState() => _SliderDemoState();
}

Path _triangle(double size, Offset thumbCenter, {bool invert = false}) {
  final Path thumbPath = Path();
  final double height = math.sqrt(3.0) / 2.0;
  final double halfSide = size / 2.0;
  final double centerHeight = size * height / 3.0;
  final double sign = invert ? -1.0 : 1.0;
  thumbPath.moveTo(thumbCenter.dx - halfSide, thumbCenter.dy + sign * centerHeight);
  thumbPath.lineTo(thumbCenter.dx, thumbCenter.dy - 2.0 * sign * centerHeight);
  thumbPath.lineTo(thumbCenter.dx + halfSide, thumbCenter.dy + sign * centerHeight);
  thumbPath.close();
  return thumbPath;
}

Path _leftTriangle(double size, Offset thumbCenter, {bool invert = false}) {
  final Path thumbPath = Path();
  final double halfSide = size / 2.0;
  final double sign = invert ? -1.0 : 1.0;
  thumbPath.moveTo(thumbCenter.dx - halfSide, thumbCenter.dy);
  thumbPath.lineTo(thumbCenter.dx + halfSide, thumbCenter.dy - halfSide * sign);
  thumbPath.lineTo(thumbCenter.dx + halfSide, thumbCenter.dy + halfSide * sign);
  thumbPath.close();
  return thumbPath;
}

Path _rightTriangle(double size, Offset thumbCenter, {bool invert = false}) {
  final Path thumbPath = Path();
  final double halfSide = size / 2.0;
  final double sign = invert ? -1.0 : 1.0;
  thumbPath.moveTo(thumbCenter.dx + halfSide, thumbCenter.dy);
  thumbPath.lineTo(thumbCenter.dx - halfSide, thumbCenter.dy - halfSide * sign);
  thumbPath.lineTo(thumbCenter.dx - halfSide, thumbCenter.dy + halfSide * sign);
  thumbPath.close();
  return thumbPath;
}

class _CustomRangeThumbShape extends RangeSliderThumbShape {
  static const double _thumbSize = 4.0;
  static const double _disabledThumbSize = 3.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return isEnabled ? const Size.fromRadius(_thumbSize) : const Size.fromRadius(_disabledThumbSize);
  }

  static final Animatable<double> sizeTween = Tween<double>(
    begin: _disabledThumbSize,
    end: _thumbSize,
  );

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    @required Animation<double> activationAnimation,
    @required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop,
    @required SliderThemeData sliderTheme,
    TextDirection textDirection,
    Thumb thumb,
  }) {
    assert(thumb != null);
    final Canvas canvas = context.canvas;
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );

    final double size = _thumbSize * sizeTween.evaluate(enableAnimation);
    Path thumbPath;
    switch (textDirection) {
      case TextDirection.rtl:
        switch (thumb) {
          case Thumb.start:
            thumbPath = _rightTriangle(size, center);
            break;
          case Thumb.end:
            thumbPath = _leftTriangle(size, center);
            break;
        }
        break;
      case TextDirection.ltr:
        switch (thumb) {
          case Thumb.start:
            thumbPath = _leftTriangle(size, center);
            break;
          case Thumb.end:
            thumbPath = _rightTriangle(size, center);
            break;
        }
        break;
    }
    if (thumbPath != null) {
      canvas.drawPath(thumbPath, Paint()
        ..color = colorTween.evaluate(enableAnimation));
    }
  }
}

class _CustomThumbShape extends SliderComponentShape {
  static const double _thumbSize = 4.0;
  static const double _disabledThumbSize = 3.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return isEnabled ? const Size.fromRadius(_thumbSize) : const Size.fromRadius(_disabledThumbSize);
  }

  static final Animatable<double> sizeTween = Tween<double>(
    begin: _disabledThumbSize,
    end: _thumbSize,
  );

  @override
  void paint(
    PaintingContext context,
    Offset thumbCenter, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    final Canvas canvas = context.canvas;
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );
    final double size = _thumbSize * sizeTween.evaluate(enableAnimation);
    final Path thumbPath = _triangle(size, thumbCenter);
    canvas.drawPath(thumbPath, Paint()..color = colorTween.evaluate(enableAnimation));
  }
}

class _CustomValueIndicatorShape extends SliderComponentShape {
  static const double _indicatorSize = 4.0;
  static const double _disabledIndicatorSize = 3.0;
  static const double _slideUpHeight = 40.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(isEnabled ? _indicatorSize : _disabledIndicatorSize);
  }

  static final Animatable<double> sizeTween = Tween<double>(
    begin: _disabledIndicatorSize,
    end: _indicatorSize,
  );

  @override
  void paint(
    PaintingContext context,
    Offset thumbCenter, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    final Canvas canvas = context.canvas;
    final ColorTween enableColor = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.valueIndicatorColor,
    );
    final Tween<double> slideUpTween = Tween<double>(
      begin: 0.0,
      end: _slideUpHeight,
    );
    final double size = _indicatorSize * sizeTween.evaluate(enableAnimation);
    final Offset slideUpOffset = Offset(0.0, -slideUpTween.evaluate(activationAnimation));
    final Path thumbPath = _triangle(
      size,
      thumbCenter + slideUpOffset,
      invert: true,
    );
    final Color paintColor = enableColor.evaluate(enableAnimation).withAlpha((255.0 * activationAnimation.value).round());
    canvas.drawPath(
      thumbPath,
      Paint()..color = paintColor,
    );
    canvas.drawLine(
        thumbCenter,
        thumbCenter + slideUpOffset,
        Paint()
          ..color = paintColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
    labelPainter.paint(canvas, thumbCenter + slideUpOffset + Offset(-labelPainter.width / 2.0, -labelPainter.height - 4.0));
  }
}

class _CustomRangeValueIndicatorShape extends RangeSliderValueIndicatorShape {
  _CustomRangeValueIndicatorShape() : _customValueIndicatorShape = _CustomValueIndicatorShape();

  final SliderComponentShape _customValueIndicatorShape;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete, {TextPainter labelPainter}) {
    return _customValueIndicatorShape.getPreferredSize(isEnabled, isDiscrete);
  }

  @override
  void paint(
      PaintingContext context,
      Offset center, {
      Animation<double> activationAnimation,
      Animation<double> enableAnimation,
      bool isDiscrete,
      bool isOnTop,
      TextPainter labelPainter,
      RenderBox parentBox,
      SliderThemeData sliderTheme,
      TextDirection textDirection,
      double value,
      Thumb thumb,
    }) {
    _customValueIndicatorShape.paint(
      context,
      center.translate(-5, 0),
      activationAnimation: activationAnimation,
      enableAnimation: enableAnimation,
      isDiscrete: isDiscrete,
      labelPainter: labelPainter,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      textDirection: textDirection,
      value: value,
    );
  }

}

class _SliderDemoState extends State<SliderDemo> {
  double _value = 25.0;
  double _discreteValue = 20.0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final List<ComponentDemoTabData> demos = <ComponentDemoTabData>[
      ComponentDemoTabData(
        tabName: 'SINGLE SLIDER',
        description: 'Sliders containing 1 thumb',
        demoWidget: _Sliders(),
        documentationUrl: 'https://docs.flutter.io/flutter/material/Slider-class.html',
      ),
      ComponentDemoTabData(
        tabName: 'RANGE SLIDER',
        description: 'Sliders containing 2 thumbs',
        demoWidget: _RangeSliders(),
        documentationUrl: 'https://docs.flutter.io/flutter/material/Slider-class.html',
      ),
    ];

    return TabbedComponentDemoScaffold(
      title: 'Sliders',
      demos: demos,
    );
  }
}

class _Sliders extends StatefulWidget {
  @override
  _SlidersState createState() => _SlidersState();
}

class _SlidersState extends State<_Sliders> {
  double _continuousValue = 25.0;
  double _discreteValue = 20.0;
  double _discreteCustomValue = 25.0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                label: 'Editable numerical value',
                child: Container(
                  width: 48,
                  height: 48,
                  child: TextField(
                    textAlign: TextAlign.center,
                    onSubmitted: (String value) {
                      final double newValue = double.tryParse(value);
                      if (newValue != null && newValue != _continuousValue) {
                        setState(() {
                          _continuousValue = newValue.clamp(0, 100);
                        });
                      }
                    },
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: _continuousValue.toStringAsFixed(0),
                    ),
                  ),
                ),
              ),
              Slider.adaptive(
                value: _continuousValue,
                min: 0.0,
                max: 100.0,
                onChanged: (double value) {
                  setState(() {
                    _continuousValue = value;
                  });
                },
              ),
              const Text('Continuous with Editable Numerical Value'),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Slider.adaptive(value: 0.25, onChanged: null),
              Text('Disabled'),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Slider.adaptive(
                value: _discreteValue,
                min: 0.0,
                max: 200.0,
                divisions: 5,
                label: '${_discreteValue.round()}',
                onChanged: (double value) {
                  setState(() {
                    _discreteValue = value;
                  });
                },
              ),
              const Text('Discrete'),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SliderTheme(
                data: theme.sliderTheme.copyWith(
                  activeTrackColor: Colors.deepPurple,
                  inactiveTrackColor: Colors.black26,
                  activeTickMarkColor: Colors.white70,
                  inactiveTickMarkColor: Colors.black,
                  overlayColor: Colors.black12,
                  thumbColor: Colors.deepPurple,
                  valueIndicatorColor: Colors.deepPurpleAccent,
                  thumbShape: _CustomThumbShape(),
                  valueIndicatorShape: _CustomValueIndicatorShape(),
                  valueIndicatorTextStyle: theme.accentTextTheme.body2.copyWith(color: Colors.black87),
                ),
                child: Slider(
                  value: _discreteCustomValue,
                  min: 0.0,
                  max: 200.0,
                  divisions: 5,
                  semanticFormatterCallback: (double value) => value.round().toString(),
                  label: '${_discreteCustomValue.round()}',
                  onChanged: (double value) {
                    setState(() {
                      _discreteCustomValue = value;
                    });
                  },
                ),
              ),
              const Text('Discrete with Custom Theme'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeSliders extends StatefulWidget {
  @override
  _RangeSlidersState createState() => _RangeSlidersState();
}

class _RangeSlidersState extends State<_RangeSliders> {
  RangeValues _continuousValues = RangeValues(25.0, 75.0);
  RangeValues _discreteValues = RangeValues(20.0, 120.0);
  RangeValues _discreteCustomValues = RangeValues(25.0, 75.0);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RangeSlider(
                values: _continuousValues,
                min: 0.0,
                max: 100.0,
                onChanged: (RangeValues values) {
                  setState(() {
                    _continuousValues = values;
                  });
                },
              ),
              const Text('Continuous'),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RangeSlider(values: const RangeValues(0.25, 0.75), onChanged: null),
              const Text('Disabled'),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RangeSlider(
                values: _discreteValues,
                min: 0.0,
                max: 200.0,
                divisions: 5,
                labels: RangeLabels('${_discreteValues.start.round()}', '${_discreteValues.end.round()}'),
                onChanged: (RangeValues values) {
                  setState(() {
                    _discreteValues = values;
                  });
                },
              ),
              const Text('Discrete'),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.deepPurple,
                  inactiveTrackColor: Colors.black26,
                  activeTickMarkColor: Colors.white70,
                  inactiveTickMarkColor: Colors.black,
                  overlayColor: Colors.black12,
                  thumbColor: Colors.deepPurple,
                  valueIndicatorColor: Colors.deepPurpleAccent,
                  rangeThumbShape: _CustomRangeThumbShape(),
                  rangeValueIndicatorShape: _CustomRangeValueIndicatorShape(),
                  valueIndicatorTextStyle: theme.accentTextTheme.body2.copyWith(color: Colors.black87),
                ),
                child: RangeSlider(
                  values: _discreteCustomValues,
                  min: 0.0,
                  max: 200.0,
                  divisions: 5,
                  labels: RangeLabels('${_discreteCustomValues.start.round()}', '${_discreteCustomValues.end.round()}'),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _discreteCustomValues = values;
                    });
                  },
                ),
              ),
              const Text('Discrete with Custom Theme'),
            ],
          ),
        ],
      ),
    );
  }
}

