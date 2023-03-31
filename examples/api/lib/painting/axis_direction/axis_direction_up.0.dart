// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for [AxisDirection.up].

import 'package:flutter/material.dart';

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

class MyWidget extends StatelessWidget {
  const MyWidget({ super.key });

  List<String> get _alphabet => <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
    'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AxisDirection.up')),
      // Also works for ListView.builder, which creates a SliverList for itself.
      // A CustomScrollView allows multiple slivers to be composed together.
      body: CustomScrollView(
        reverse: true,
        slivers: <Widget>[
          SliverList.builder(
            itemCount: 27,
            itemBuilder: (BuildContext context, int index) {
              final Widget child;
              const Widget spacer = SizedBox(height: 10);

              if (index == 0) {
                child = Container(
                  color: Colors.blue[100],
                  padding: const EdgeInsets.all(8.0),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Icon>[
                          Icon(Icons.arrow_upward_rounded),
                          Icon(Icons.arrow_upward_rounded),
                        ],
                      ),
                      spacer,
                      Text('GrowthDirection.forward'),
                      spacer,
                      Text('AxisDirection.up'),
                      spacer,
                      Text('Axis.vertical'),
                    ],
                  ),
                );
              } else {
                child = Container(
                  color: index.isEven ? Colors.amber[100] : Colors.amberAccent,
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: Text(_alphabet[index - 1])),
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
    );
  }
}
