// Copyright 2015, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  runApp(
    new MaterialApp(
      title: "HTTP POST Example",
      routes: {
        '/': (RouteArguments args) => const PostDemo()
      }
    )
  );
}

class PostDemo extends StatefulComponent {
  const PostDemo();
  PostDemoState createState() => new PostDemoState();
}

class PostDemoState extends State<PostDemo> {

  String _response = null;

  void initState() {
    _refresh();
    super.initState();
  }

  Future _refresh() async {
    setState(() {
      _response = null;
    });
    http.Response response = await http.post(
      "http://httpbin.org/post",
      body: "asdf=42",
      headers: { "foo": "bar" }
    );
    setState(() {
      _response = response.body;
    });
  }

  Widget build(BuildContext context)  {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text("HTTP POST example")
      ),
      body: new Material(
        child: new Block(
          [new Text(
            "${_response ?? 'Loading...'}",
            style: Typography.black.body1
          )]
        )
      ),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(
          icon: 'navigation/refresh'
        ),
        onPressed: _refresh
      )
    );
  }
}
