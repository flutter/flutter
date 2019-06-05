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

class _SliderDemoState extends State<SliderDemo> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sliders'),
          actions: <Widget>[MaterialDemoDocumentationButton(SliderDemo.routeName)],
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'SLIDERS'),
              Tab(text: 'RANGE SLIDERS'),
            ],
          ),
        ),
//        body: Padding(
//          padding: const EdgeInsets.symmetric(horizontal: 40.0),
//          child: TabBarView(
//            children: <Widget>[
//              _SingleSliderTabView(),
//              _RangeSliderTabView(),
//            ],
//          )
//        ),
//        body: _SingleSliderTabView(),
        body: _RangeSliderTabView(),
      ),
    );
  }
}

class _SingleSliderTabView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SingleSliderTabViewState();
}

class _SingleSliderTabViewState extends State<_SingleSliderTabView> {
  double _value = 25.0;
  double _discreteValue = 20.0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Slider(
              value: _value,
              min: 0.0,
              max: 100.0,
              onChanged: (double value) {
                setState(() {
                  _value = value;
                });
              },
            ),
            const Text('Continuous'),
          ],
        ),
//        Column(
//          mainAxisSize: MainAxisSize.min,
//          children: <Widget>[
//            Row(
//              children: <Widget>[
//                Expanded(
//                  child: Slider(
//                    value: _value,
//                    min: 0.0,
//                    max: 100.0,
//                    onChanged: (double value) {
//                      setState(() {
//                        _value = value;
//                      });
//                    },
//                  ),
//                ),
//                Semantics(
//                  label: 'Editable numerical value',
//                  child: Container(
//                    width: 48,
//                    height: 48,
//                    child: TextField(
//                      onSubmitted: (String value) {
//                        final double newValue = double.tryParse(value);
//                        if (newValue != null && newValue != _value) {
//                          setState(() {
//                            _value = newValue.clamp(0, 100);
//                          });
//                        }
//                      },
//                      keyboardType: TextInputType.number,
//                      controller: TextEditingController(
//                        text: _value.toStringAsFixed(0),
//                      ),
//                    ),
//                  ),
//                ),
//              ],
//            ),
//            const Text('Continuous with Editable Numerical Value'),
//          ],
//        ),
//        Column(
//          mainAxisSize: MainAxisSize.min,
//          children: const <Widget>[
//            Slider(value: 0.25, onChanged: null),
//            Text('Disabled'),
//          ],
//        ),
//        Column(
//          mainAxisSize: MainAxisSize.min,
//          children: <Widget>[
//            Slider(
//              value: _discreteValue,
//              min: 0.0,
//              max: 200.0,
//              divisions: 5,
//              label: '${_discreteValue.round()}',
//              onChanged: (double value) {
//                setState(() {
//                  _discreteValue = value;
//                });
//              },
//            ),
//            const Text('Discrete'),
//          ],
//        ),
//        Column(
//          mainAxisSize: MainAxisSize.min,
//          children: <Widget>[
//            SliderTheme(
//              data: theme.sliderTheme.copyWith(
//                activeTrackColor: Colors.deepPurple,
//                inactiveTrackColor: Colors.black26,
//                activeTickMarkColor: Colors.white70,
//                inactiveTickMarkColor: Colors.black,
//                overlayColor: Colors.black12,
//                thumbColor: Colors.deepPurple,
//                valueIndicatorColor: Colors.deepPurpleAccent,
//                thumbShape: _CustomThumbShape(),
//                valueIndicatorShape: _CustomValueIndicatorShape(),
//                valueIndicatorTextStyle: theme.accentTextTheme.body2.copyWith(color: Colors.black87),
//              ),
//              child: Slider(
//                value: _discreteValue,
//                min: 0.0,
//                max: 200.0,
//                divisions: 5,
//                semanticFormatterCallback: (double value) => value.round().toString(),
//                label: '${_discreteValue.round()}',
//                onChanged: (double value) {
//                  setState(() {
//                    _discreteValue = value;
//                  });
//                },
//              ),
//            ),
//            const Text('Discrete with Custom Theme'),
//          ],
//        ),
      ],
    );
  }
}

class _RangeSliderTabView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RangeSliderTabViewState();
}

class _RangeSliderTabViewState extends State<_RangeSliderTabView> {
  RangeValues _rangeValues = const RangeValues(25, 50);
  RangeValues _rangeValuesWithLabels = const RangeValues(25, 75);
  RangeValues _discreteRangeValues = const RangeValues(40, 120);
  double _discreteValue = 20;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return  Container(
//      color: Colors.greenAccent,
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SliderTheme(
                    data: theme.sliderTheme.copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      showValueIndicator: ShowValueIndicator.always,
                    ),
                    child: RangeSlider(
                      values: _rangeValues,
                      min: 0.0,
                      max: 100.0,
                      semanticFormatterCallback: (RangeValues values) => '$values',
                      labels: RangeLabels('${_rangeValues.start.round()}', '${_rangeValues.end.round()}'),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _rangeValues = values;
                        });
                      },
//                    onChanged: null,
                    ),
                  ),
                ),
                const Text('Continuous'),
              ],
            ),
//        Column(
//            mainAxisSize: MainAxisSize.min,
//            children: <Widget>[
//              Slider(
//                value: _discreteValue,
//                min: 0.0,
//                max: 200.0,
//                divisions: 5,
//                label: '${_discreteValue.round()}',
//                onChanged: (double value) {
//                  setState(() {
//                    _discreteValue = value;
//                  });
//                },
//              ),
//              const Text('Discrete'),
//            ],
//          ),
//        Column(
//          mainAxisSize: MainAxisSize.min,
//          children: <Widget>[
//            SliderTheme(
//              data: theme.sliderTheme.copyWith(
//                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
//                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
//                showValueIndicator: ShowValueIndicator.always,
//              ),
//              child: RangeSlider(
//                values: _rangeValuesWithLabels,
//                min: 0.0,
//                max: 100.0,
//                semanticFormatterCallback: (RangeValues values) => '$values',
//                labels: RangeLabels('${_rangeValuesWithLabels.start.round()}', '${_rangeValuesWithLabels.end.round()}'),
//                onChanged: (RangeValues values) {
//                  setState(() {
//                    _rangeValuesWithLabels = values;
//                  });
//                },
//              ),
//            ),
//            const Text('Range'),
//          ],
//        ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SliderTheme(
                    data: theme.sliderTheme.copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      showValueIndicator: ShowValueIndicator.always,
                    ),
                    child: RangeSlider(
                      values: _discreteRangeValues,
                      min: 0.0,
                      max: 200.0,
                      divisions: 5,
                      semanticFormatterCallback: (RangeValues values) => '$values',
                      labels: RangeLabels('${_discreteRangeValues.start.round()}', '${_discreteRangeValues.end.round()}'),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _discreteRangeValues = values;
                        });
                      },
//                    onChanged: null,
                    ),
                  ),
                ),
                const Text('Discrete'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
