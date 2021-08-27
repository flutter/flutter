// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateful_widget_material_ticker.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for InheritedNotifier
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// This example shows three spinning squares that use the value of the notifier
// on an ancestor [InheritedNotifier] (`SpinModel`) to give them their
// rotation. The [InheritedNotifier] doesn't need to know about the children,
// and the `notifier` argument doesn't need to be an animation controller, it
// can be anything that implements [Listenable] (like a [ChangeNotifier]).
//
// The `SpinModel` class could just as easily listen to another object (say, a
// separate object that keeps the value of an input or data model value) that
// is a [Listenable], and get the value from that. The descendants also don't
// need to have an instance of the [InheritedNotifier] in order to use it, they
// just need to know that there is one in their ancestry. This can help with
// decoupling widgets from their models.

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

//********************************************************************************
//* ▼▼▼▼▼▼▼▼ code-dartImports ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

import 'dart:math' as math;

//* ▲▲▲▲▲▲▲▲ code-dartImports ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************************

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

class SpinModel extends InheritedNotifier<AnimationController> {
  const SpinModel({
    Key? key,
    AnimationController? notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);

  static double of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SpinModel>()!
        .notifier!
        .value;
  }
}

class Spinner extends StatelessWidget {
  const Spinner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: SpinModel.of(context) * 2.0 * math.pi,
      child: Container(
        width: 100,
        height: 100,
        color: Colors.green,
        child: const Center(
          child: Text('Whee!'),
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
/// AnimationControllers can be created with `vsync: this` because of TickerProviderStateMixin.
class _MyStatefulWidgetState extends State<MyStatefulWidget>
    with TickerProviderStateMixin {
//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpinModel(
      notifier: _controller,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const <Widget>[
          Spinner(),
          Spinner(),
          Spinner(),
        ],
      ),
    );
  }

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}
