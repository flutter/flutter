// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// This example demonstrates how to use the [AutomaticKeepAliveClientMixin]
// to keep the state of a widget alive even when it is scrolled out of view.

// The widget includes a button to toggle the keep-alive state. When `wantKeepAlive`
// is `true`, the widget is kept alive. When it is `false`, the widget can be disposed
// when scrolled out of view.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AutomaticKeepAliveClientMixin Example')),
        body: const MyWidget(),
      ),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with AutomaticKeepAliveClientMixin<MyWidget> {
  bool _keepAlive = false;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important to call super.build to manage the keep-alive state
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Keep me alive: $_keepAlive'),
        ElevatedButton(
          child: const Text('Toggle'),
          onPressed: () {
            setState(() {
              _keepAlive = !_keepAlive;
              updateKeepAlive(); // Important to call to update the keep-alive status
            });
          },
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => _keepAlive;
}