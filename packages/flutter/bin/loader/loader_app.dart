import 'package:flutter/material.dart';

void main() {
  runApp(new MaterialApp(
      title: 'Flutter Initial Load',
      home: new Scaffold(
        body: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Text('Loading application onto device...',
                       style: new TextStyle(fontSize: 24.0)),
              new CircularProgressIndicator(value: null)
            ]
        )
      )
    )
  );
}

