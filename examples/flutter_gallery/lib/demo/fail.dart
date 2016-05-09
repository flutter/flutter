
import 'package:flutter/material.dart';

class LimitDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('LimitedBox test')
      ),
      body: new Block(
        children: <Widget>[
          new LimitedBox(
            maxWidth: 100.0,
            maxHeight: 100.0,
            child: new Container(
              decoration: new BoxDecoration(backgroundColor: const Color(0xFF00FF00))
            )
          )
        ]
      )
    );
  }
}
