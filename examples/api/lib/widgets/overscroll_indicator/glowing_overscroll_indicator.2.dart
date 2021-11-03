// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for GlowingOverscrollIndicator

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Override the [default drag behavior](https://flutter.dev/docs/release/breaking-changes/default-scroll-behavior-drag).
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
   Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
     PointerDeviceKind.touch,
     PointerDeviceKind.mouse,
  };
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
        // Set [TargetPlatform](https://api.flutter.dev/flutter/foundation/TargetPlatform-class.html)
        // to Android, this type of scroll behavior is common on Android.
        platform: TargetPlatform.android,
      ),
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const MyStatelessWidget(),
      ),
    );
  }
}

class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return const <Widget>[
          SliverAppBar(title: Text('Custom NestedScrollViews')),
        ];
      },
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Container(
              color: Colors.amberAccent,
              height: 100,
              child: const Center(child: Text('Glow all day!')),
            ),
          ),
          const SliverFillRemaining(child: FlutterLogo()),
        ],
      ),
    );
  }
}
