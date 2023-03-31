// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for [GrowthDirection]s.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: MyWidget(),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({ super.key });

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final List<String> alphabet = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
    'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];
  final Widget spacer = const SizedBox.square(dimension: 10);
  final UniqueKey center = UniqueKey();
  Axis axis = Axis.vertical;
  bool reverse = false;

  AxisDirection _getAxisDirection() {
    switch (axis) {
      case Axis.vertical:
        return reverse ? AxisDirection.up : AxisDirection.down;
      case Axis.horizontal:
        return reverse ? AxisDirection.left : AxisDirection.right;
    }
  }

  Widget _getArrows(SliverConstraints constraints) {
    final Widget arrow;
    final AxisDirection adjustedAxisDirection = applyGrowthDirectionToAxisDirection(
      _getAxisDirection(),
      constraints.growthDirection,
    );
    switch(adjustedAxisDirection) {
      case AxisDirection.up:
        arrow = const Icon(Icons.arrow_upward_rounded);
      case AxisDirection.down:
        arrow = const Icon(Icons.arrow_downward_rounded);
      case AxisDirection.left:
        arrow = const Icon(Icons.arrow_back_rounded);
      case AxisDirection.right:
        arrow = const Icon(Icons.arrow_forward_rounded);
    }

    switch(axis) {
      case Axis.vertical:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[ arrow, arrow ]
        );
      case Axis.horizontal:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[ arrow, arrow ]
        );
    }
  }

  void _onAxisDirectionChanged(AxisDirection? axisDirection) {
    if (axisDirection == null) {
      return;
    }
    final bool newReverse;
    final Axis newAxis;
    switch(axisDirection) {
      case AxisDirection.up:
        newReverse = true;
        newAxis = Axis.vertical;
      case AxisDirection.down:
        newReverse = false;
        newAxis = Axis.vertical;
      case AxisDirection.left:
        newReverse = true;
        newAxis = Axis.horizontal;
      case AxisDirection.right:
        newReverse = false;
        newAxis = Axis.horizontal;
    }
    if (newReverse != reverse || newAxis != axis) {
      setState(() {
        // Respond to change in axis direction.
        reverse = newReverse;
        axis = newAxis;
      });
    }
  }

  Widget _getLeading(SliverConstraints constraints, bool isForward) {
    return Container(
      color: isForward ? Colors.orange[300] : Colors.green[400],
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(constraints.axis.toString()),
          spacer,
          Text(constraints.axisDirection.toString()),
          spacer,
          Text(constraints.growthDirection.toString()),
          spacer,
          _getArrows(constraints),
        ],
      ),
    );
  }

  Widget _getRadioRow() {
    return DefaultTextStyle(
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      child: RadioTheme(
        data: RadioThemeData(
          fillColor: MaterialStateProperty.all<Color>(Colors.white),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Radio<AxisDirection>(
                value: AxisDirection.up,
                groupValue: _getAxisDirection(),
                onChanged: _onAxisDirectionChanged,
              ),
              const Text('up'),
              spacer,
              Radio<AxisDirection>(
                value: AxisDirection.down,
                groupValue: _getAxisDirection(),
                onChanged: _onAxisDirectionChanged,
              ),
              const Text('down'),
              spacer,
              Radio<AxisDirection>(
                value: AxisDirection.left,
                groupValue: _getAxisDirection(),
                onChanged: _onAxisDirectionChanged,
              ),
              const Text('left'),
              spacer,
              Radio<AxisDirection>(
                value: AxisDirection.right,
                groupValue: _getAxisDirection(),
                onChanged: _onAxisDirectionChanged,
              ),
              const Text('right'),
              spacer,
            ],
          ),
        ),
      ),
    );
  }

  Widget _getList({ required bool isForward }) {
    // The SliverLayoutBuilder is not necessary, and is here to allow us to see
    // the SliverConstraints & directional information that is provided to the
    // SliverList when laying out.
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        return SliverList.builder(
          itemCount: 27,
          itemBuilder: (BuildContext context, int index) {
            final Widget child;
            if (index == 0) {
              child = _getLeading(constraints, isForward);
            } else {
              child = Container(
                color: isForward
                  ? (index.isEven ? Colors.amber[100] : Colors.amberAccent)
                  : (index.isEven ? Colors.green[100] : Colors.lightGreen),
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text(alphabet[index - 1])),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: child,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GrowthDirections'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _getRadioRow(),
          ),
        ),
      ),
      body: CustomScrollView(
        reverse: reverse,
        scrollDirection: axis,
        // Places the leading edge of the center sliver in the middle of the
        // viewport. Changing this value between 0.0 (the default) and 1.0
        // changes the position of the inflection point between GrowthDirections
        // in the viewport when the slivers are laid out.
        anchor: 0.5,
        center: center,
        slivers: <Widget>[
          _getList(isForward: false),
          SliverToBoxAdapter(
            // This sliver will be located at the anchor. The scroll position
            // will progress in either direction from this point.
            key: center,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: Text('0', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
          ),
          _getList(isForward: true),
        ],
      ),
    );
  }
}
