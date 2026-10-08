// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// The font family that `hook/build.dart` provides.
const String kHookFontFamily = 'RobotoFromHook';

void main() {
  runApp(const FontAssetsApp());
}

class FontAssetsApp extends StatelessWidget {
  const FontAssetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Font Assets',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Regular from hook', style: TextStyle(fontFamily: kHookFontFamily)),
              Text(
                'Bold from hook',
                style: TextStyle(fontFamily: kHookFontFamily, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
