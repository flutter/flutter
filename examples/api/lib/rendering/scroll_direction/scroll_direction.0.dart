// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for [ScrollDirection].

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
  ScrollDirection scrollDirection = ScrollDirection.idle;
  AxisDirection _axisDirection = AxisDirection.down;

  Widget _getArrows() {
    final Widget arrow;
    switch(_axisDirection) {
      case AxisDirection.up:
        arrow = const Icon(Icons.arrow_upward_rounded);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[ arrow, arrow ],
        );
      case AxisDirection.down:
        arrow = const Icon(Icons.arrow_downward_rounded);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[ arrow, arrow ],
        );
      case AxisDirection.left:
        arrow = const Icon(Icons.arrow_back_rounded);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[ arrow, arrow ],
        );
      case AxisDirection.right:
        arrow = const Icon(Icons.arrow_forward_rounded);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[ arrow, arrow ],
        );
    }
  }

  void _onAxisDirectionChanged(AxisDirection? axisDirection) {
    if (axisDirection != null && axisDirection != _axisDirection) {
      setState(() {
        // Respond to change in axis direction.
        _axisDirection = axisDirection;
      });
    }
  }

  Widget _getLeading() {
    return Container(
      color: Colors.blue[100],
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(axisDirectionToAxis(_axisDirection).toString()),
          spacer,
          Text(_axisDirection.toString()),
          spacer,
          const Text('GrowthDirection.forward'),
          spacer,
          Text(scrollDirection.toString()),
          spacer,
          _getArrows(),
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
                groupValue: _axisDirection,
                onChanged: _onAxisDirectionChanged,
              ),
              const Text('up'),
              spacer,
              Radio<AxisDirection>(
                value: AxisDirection.down,
                groupValue: _axisDirection,
                onChanged: _onAxisDirectionChanged,
              ),
              const Text('down'),
              spacer,
              Radio<AxisDirection>(
                value: AxisDirection.left,
                groupValue: _axisDirection,
                onChanged: _onAxisDirectionChanged,
              ),
              const Text('left'),
              spacer,
              Radio<AxisDirection>(
                value: AxisDirection.right,
                groupValue: _axisDirection,
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

  bool _handleNotification(UserScrollNotification notification) {
    if (notification.direction != scrollDirection) {
      setState((){
        scrollDirection = notification.direction;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScrollDirections'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _getRadioRow(),
          ),
        ),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: _handleNotification,
        // Also works for ListView.builder, which creates a SliverList for itself.
        // A CustomScrollView allows multiple slivers to be composed together.
        child: CustomScrollView(
          // This method is available to conveniently determine if an scroll
          // view is reversed by its AxisDirection.
          reverse: axisDirectionIsReversed(_axisDirection),
          // This method is available to conveniently convert an AxisDirection
          // into its Axis.
          scrollDirection: axisDirectionToAxis(_axisDirection),
          slivers: <Widget>[
            SliverList.builder(
              itemCount: 27,
              itemBuilder: (BuildContext context, int index) {
                final Widget child;
                if (index == 0) {
                  child = _getLeading();
                } else {
                  child = Container(
                    color: index.isEven ? Colors.amber[100] : Colors.amberAccent,
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Text(alphabet[index - 1])),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: child,
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}
