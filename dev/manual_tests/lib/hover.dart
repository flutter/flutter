// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Hover Demo',
    home: HoverDemo(),
  ));
}

class DemoButton extends StatelessWidget {
  const DemoButton({this.name});

  final String name;

  void _handleOnPressed() {
    print('Button $name pressed.');
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: () => _handleOnPressed(),
      child: Text(name),
    );
  }
}

class HoverDemo extends StatefulWidget {
  const HoverDemo({Key key}) : super(key: key);

  @override
  _HoverDemoState createState() => _HoverDemoState();
}

class _HoverDemoState extends State<HoverDemo> {
  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DefaultTextStyle(
      style: textTheme.display1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hover Demo'),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Text('+'),
          onPressed: () {},
        ),
        body: Center(
          child: Builder(builder: (BuildContext context) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    RaisedButton(
                      onPressed: () => print('Button pressed.'),
                      child: const Text('Button'),
                      focusColor: Colors.deepOrangeAccent,
                    ),
                    FlatButton(
                      onPressed: () => print('Button pressed.'),
                      child: const Text('Button'),
                      focusColor: Colors.deepOrangeAccent,
                    ),
                    IconButton(
                      onPressed: () => print('Button pressed'),
                      icon: const Icon(Icons.access_alarm),
                      focusColor: Colors.deepOrangeAccent,
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Enter Text', filled: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    autofocus: false,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter Text',
                      filled: false,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
