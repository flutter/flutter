// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: TestAssetDisplay(),
        ),
      ),
    );
  }
}

class TestAssetDisplay extends StatelessWidget {
  const TestAssetDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/test_asset.txt'),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error!;
        }
        if (snapshot.hasData) {
          return Text(snapshot.data!);
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
