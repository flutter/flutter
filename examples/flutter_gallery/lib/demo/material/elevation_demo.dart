import 'package:flutter/material.dart';

import '../../gallery/demo.dart';

class ElevationDemo extends StatefulWidget {
  static const String routeName = '/material/elevation';

  @override
  State<StatefulWidget> createState() => _ElevationDemoState();
}

class _ElevationDemoState extends State<ElevationDemo> {
  bool _showElevation = true;

  List<Widget> buildCards() {
    const List<double> elevations = <double>[
      0,
      1,
      2,
      3,
      4,
      5,
      8,
      16,
      24,
    ];

    return elevations.map<Widget>((double elevation) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          elevation: _showElevation ? elevation : 0.0,
          child: SizedBox(
            height: 100,
            width: 100,
            child: Center(
              child: Text('${elevation.toStringAsFixed(0)} pt'),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elevation'),
        actions: <Widget>[
          MaterialDemoDocumentationButton(ElevationDemo.routeName),
          IconButton(
            icon: const Icon(Icons.sentiment_very_satisfied),
            onPressed: () {
              setState(() => _showElevation = !_showElevation);
            },
          )
        ],
      ),
      body: ListView(
        children: buildCards(),
      ),
    );
  }
}
