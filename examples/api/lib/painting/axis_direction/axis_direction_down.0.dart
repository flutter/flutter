// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for [AxisDirection.down].

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

  static const List<String> alphabet = <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scrolling Directions')),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverList.builder(
            itemCount: 27,
            itemBuilder: (BuildContext context, int index) {
              late Widget child;
              const Widget spacer = SizedBox(height: 10);

              if (index == 0) {
                child = Container(
                  color: Colors.blue[100],
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Axis.vertical'),
                        spacer,
                        Text('AxisDirection.down'),
                        spacer,
                        Text('GrowthDirection.forward'),
                        spacer,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Icon>[
                            Icon(Icons.arrow_downward_rounded),
                            Icon(Icons.arrow_downward_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                child = Container(
                  color: index.isEven ? Colors.amber[100] : Colors.amberAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Text(alphabet[index - 1])),
                  ),
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
