// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateful_widget_material.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for PointerSignalResolver
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// Here is an example that demonstrates the effect of not using the resolver
// versus using it.
//
// When this example is set to _not_ use the resolver, then triggering the
// mouse wheel over the outer box will cause only the outer box to change
// color, but triggering the mouse wheel over the inner box will cause _both_
// the outer and the inner boxes to change color (because they're both
// receiving the event).
//
// When this example is set to _use_ the resolver, then only the box located
// directly under the cursor will change color when the mouse wheel is
// triggered.

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

//****************************************************************************
//* ▼▼▼▼▼▼▼▼ code-imports ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

import 'package:flutter/gestures.dart';

//* ▲▲▲▲▲▲▲▲ code-imports ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//****************************************************************************

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// This is the main application widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: MyStatefulWidget(),
    );
  }
}

//*****************************************************************************
//* ▼▼▼▼▼▼▼▼ code-preamble ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

class ColorChanger extends StatefulWidget {
  const ColorChanger({
    Key? key,
    required this.initialColor,
    required this.useResolver,
    this.child,
  }) : super(key: key);

  final HSVColor initialColor;
  final bool useResolver;
  final Widget? child;

  @override
  State<ColorChanger> createState() => _ColorChangerState();
}

class _ColorChangerState extends State<ColorChanger> {
  late HSVColor color;

  void rotateColor() {
    setState(() {
      color = color.withHue((color.hue + 3) % 360.0);
    });
  }

  @override
  void initState() {
    super.initState();
    color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: const Border.fromBorderSide(BorderSide()),
        color: color.toColor(),
      ),
      child: Listener(
        onPointerSignal: (PointerSignalEvent event) {
          if (widget.useResolver) {
            GestureBinding.instance!.pointerSignalResolver.register(event,
                (PointerSignalEvent event) {
              rotateColor();
            });
          } else {
            rotateColor();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const AbsorbPointer(),
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

//* ▲▲▲▲▲▲▲▲ code-preamble ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//*****************************************************************************

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

  bool useResolver = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColorChanger(
            initialColor: const HSVColor.fromAHSV(0.2, 120.0, 1, 1),
            useResolver: useResolver,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 0.5,
              child: ColorChanger(
                initialColor: const HSVColor.fromAHSV(1, 60.0, 1, 1),
                useResolver: useResolver,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Switch(
                  value: useResolver,
                  onChanged: (bool value) {
                    setState(() {
                      useResolver = value;
                    });
                  },
                ),
                const Text(
                  'Use the PointerSignalResolver?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}
