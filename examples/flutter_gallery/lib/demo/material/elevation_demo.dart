import 'package:flutter/material.dart';

class ElevationDemo extends StatefulWidget {
  static const String routeName = '/material/elevation';

  @override
  State<StatefulWidget> createState() => _ElevationDemoState();
}

class _ElevationDemoState extends State<ElevationDemo> {
  bool _shouldShowElevation = true;

  List<Widget> buildCards() {
    final List<Widget> cards = <Widget>[];
    const List<double> elevations = <double>[
      0.0,
      1.0,
      2.0,
      3.0,
      4.0,
      5.0,
      8.0,
      16.0,
      24.0,
    ];

    for (double i in elevations) {
      cards.add(new Center(
        child: new Card(
          margin: const EdgeInsets.all(20.0),
          elevation: _shouldShowElevation ? i : 0.0,
          child: new SizedBox(
            height: 100.0,
            width: 100.0,
            child: new Center(
              child: new Text('${i.toStringAsFixed(0)} pt'),
            ),
          ),
        ),
      ));
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: const Text('Elevation'),
          actions: <Widget>[
            new IconButton(
                icon: const Icon(Icons.sentiment_very_satisfied),
                onPressed: () {
                  setState(() => _shouldShowElevation = !_shouldShowElevation);
                })
          ],
        ),
        body: new ListView(
          children: buildCards(),
        ));
  }
}
