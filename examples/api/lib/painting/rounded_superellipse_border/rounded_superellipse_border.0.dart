// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for [RoundedSuperellipseBorder].

void main() {
  runApp(const RoundedSuperellipseBorderExample());
}

class RoundedSuperellipseBorderExample extends StatefulWidget {
  const RoundedSuperellipseBorderExample({super.key});

  static final GlobalKey kBorderBoxKey = GlobalKey();
  static final GlobalKey kThicknessSliderKey = GlobalKey();
  static final GlobalKey kRadiusSliderKey = GlobalKey();

  @override
  State<RoundedSuperellipseBorderExample> createState() =>
      RoundedSuperellipseBorderExampleState();
}

class RoundedSuperellipseBorderExampleState
    extends State<RoundedSuperellipseBorderExample> {
  bool _toggle = true;
  double _borderThickness = 4;
  double _borderRadius = 69;

  @override
  Widget build(BuildContext context) {
    final BorderRadiusGeometry radius = BorderRadiusGeometry.circular(
      _borderRadius,
    );
    final BorderSide side = BorderSide(
      width: _borderThickness,
      color: const Color(0xFF111111),
    );
    final ShapeBorder shape = _toggle
        ? RoundedSuperellipseBorder(side: side, borderRadius: radius)
        : RoundedRectangleBorder(side: side, borderRadius: radius);

    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
          child: Container(
            padding: const EdgeInsetsGeometry.all(10),
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: <Widget>[
                // The border is drawn by this DecoratedBox.
                DecoratedBox(
                  key: RoundedSuperellipseBorderExample.kBorderBoxKey,
                  decoration: ShapeDecoration(
                    shape: shape,
                    color: const Color(0xFFFFC107),
                  ),
                  child: const SizedBox(width: 400, height: 200),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text('Shape: '),
                    CupertinoSwitch(
                      value: _toggle,
                      onChanged: (bool value) {
                        setState(() {
                          _toggle = value;
                        });
                      },
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 200),
                      child: Text(
                        _toggle ? 'Rounded Superellipse' : 'Rounded Rect',
                      ),
                    ),
                  ],
                ),
                SliderRow(
                  label: 'Thickness',
                  slider: CupertinoSlider(
                    value: _borderThickness,
                    max: 14,
                    min: 0.0000001,
                    onChanged: (double value) {
                      setState(() {
                        _borderThickness = value;
                      });
                    },
                  ),
                  valueString: _borderThickness.toStringAsFixed(1),
                  key: RoundedSuperellipseBorderExample.kThicknessSliderKey,
                ),
                SliderRow(
                  label: 'Radius',
                  slider: CupertinoSlider(
                    value: _borderRadius,
                    max: 100,
                    onChanged: (double value) {
                      setState(() {
                        _borderRadius = value;
                      });
                    },
                  ),
                  valueString: _borderRadius.toStringAsFixed(1),
                  key: RoundedSuperellipseBorderExample.kRadiusSliderKey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SliderRow extends StatelessWidget {
  const SliderRow({
    super.key,
    required this.label,
    required this.slider,
    required this.valueString,
  });

  final String label;
  final Widget slider;
  final String valueString;

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 50),
          child: Text(label),
        ),
        Expanded(child: slider),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 50),
          child: Text(valueString),
        ),
      ],
    );
  }
}
