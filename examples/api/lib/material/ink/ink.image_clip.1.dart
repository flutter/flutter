// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for Image.frameBuilder

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(
          child: MyStatelessWidget(),
        ),
      ),
    );
  }
}

class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: Material( // We can deliberately wrap in a Material
        child: Ink.image(
          fit: BoxFit.fill,
          width: 300,
          height: 300,
          image: const NetworkImage(
            'https://flutter.github.io/assets-for-api-docs/assets/widgets/puffin.jpg',
          ),
          child: InkWell(
              onTap: () { /* ... */ },
              child: const Align(
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    'PUFFIN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
          ),
        ),
      ),
    );
  }
}
