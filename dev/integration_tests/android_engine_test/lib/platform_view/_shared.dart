// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

final class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.platformView});
  final Widget platformView;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Stack(
        children: <Widget>[
          platformView,
          Center(child: Container(width: 100, height: 100, color: Colors.red)),
        ],
      ),
    );
  }
}
