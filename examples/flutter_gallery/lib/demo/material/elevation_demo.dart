import 'package:flutter/material.dart';

class ElevationDemo extends StatelessWidget {
  static const String routeName = '/material/elevation';

  List<Widget> buildCards() {
    final List<Widget> cards = <Widget>[];

    for (double i = 0.0; i <= 5.0; ++i) {
      cards.add(Center(
        child: Card(
          margin: const EdgeInsets.all(20.0),
          elevation: i,
          child: SizedBox(
            height: 100.0,
            width: 100.0,
            child: Center(
              child: Text('${i.toStringAsFixed(0)} pt'),
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
        appBar: new AppBar(title: const Text('Elevation')),
        body: new ListView(
          children: buildCards(),
        ));
  }
}
