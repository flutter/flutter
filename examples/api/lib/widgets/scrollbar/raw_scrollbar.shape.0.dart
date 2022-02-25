// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for RawScrollbar.shape

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: MyStatelessWidget(),
    );
  }
}

class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawScrollbar(
        shape: const StadiumBorder(
            side: BorderSide(color: Colors.brown, width: 3.0)),
        thickness: 15.0,
        thumbColor: Colors.blue,
        thumbVisibility: true,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: List<Text>.generate(
              100, (int index) => Text((index * index).toString())),
        ),
      ),
    );
  }
}
