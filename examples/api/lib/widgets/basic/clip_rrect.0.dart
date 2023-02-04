// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for [ClipRRect].

import 'package:flutter/material.dart';

void main() => runApp(const ClipRRectApp());

class ClipRRectApp extends StatelessWidget {
  const ClipRRectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ClipRRect Sample')),
        body: const ClipRRectExample(),
      ),
    );
  }
}

class ClipRRectExample extends StatelessWidget {
  const ClipRRectExample({super.key});

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(color: Colors.white);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          const Container(
            alignment: Alignment.center,
            constraints: BoxConstraints(
              maxWidth: 300,
              maxHeight: 100,
            ),
            color: Colors.blue,
            child: Text('No ClipRRect', style: style),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(30.0),
            child: const Container(
              alignment: Alignment.center,
              constraints: BoxConstraints(
                maxWidth: 300,
                maxHeight: 100,
              ),
              color: Colors.green,
              child: Text('ClipRRect', style: style),
            ),
          ),
          const ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(20.0),
              bottomRight: Radius.circular(30.0),
              bottomLeft: Radius.circular(40.0),
            ),
            child: Container(
              alignment: Alignment.center,
              constraints: BoxConstraints(
                maxWidth: 300,
                maxHeight: 100,
              ),
              color: Colors.purple,
              child: Text('ClipRRect', style: style),
            ),
          ),
        ],
      ),
    );
  }
}
