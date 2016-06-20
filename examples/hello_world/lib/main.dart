import 'package:flutter/material.dart';

import 'package:flutter/rendering.dart';  // TBD remove this

class Home extends StatefulWidget {
  @override
  HomeState createState() => new HomeState();
}

class HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return new Container(
      decoration: new BoxDecoration(backgroundColor: Colors.green[300]),
      child: new Center(
        child: new Container(
          decoration: new BoxDecoration(backgroundColor: Colors.purple[300]),
          padding: const EdgeInsets.all(8.0),
          width: 100.0,
          child: new Row(
            mainAxisSpace: MainAxisSpace.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget> [
              new Text('Menu item'),
              new Text('V')
            ]
          )
        )
      )
    );
  }
}

void main() {
  debugPaintSizeEnabled = true;
  runApp(new MaterialApp(home: new Home()));
}
