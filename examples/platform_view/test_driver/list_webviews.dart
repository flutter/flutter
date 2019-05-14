// Copyright 2019, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

const int _kNumWebViews = 10;

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    final List<Widget> list = <Widget>[
      TextField(
        style: const TextStyle(
          fontSize: 18.0,
        ),
      )
    ];

    for (int i = 0; i < _kNumWebViews; i++) {
      list.add(buildWebView(i));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: ListView(
          key: const ValueKey<String>('long_list'),
          children: list,
        ),
      ),
    );
  }

  Container buildWebView(int index) {
    return Container(
      key: ValueKey<int>(index),
      height: 500,
      width: 300,
      child: WebView(
        initialUrl: 'https://flutter.dev',
      ),
    );
  }
}
