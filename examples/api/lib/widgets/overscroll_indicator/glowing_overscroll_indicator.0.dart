// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [GlowingOverscrollIndicator].

void main() => runApp(const GlowingOverscrollIndicatorExampleApp());

class GlowingOverscrollIndicatorExampleApp extends StatelessWidget {
  const GlowingOverscrollIndicatorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GlowingOverscrollIndicator Sample')),
        body: const GlowingOverscrollIndicatorExample(),
      ),
    );
  }
}

class GlowingOverscrollIndicatorExample extends StatelessWidget {
  const GlowingOverscrollIndicatorExample({super.key});

  @override
  Widget build(BuildContext context) {
    final double leadingPaintOffset = MediaQuery.of(context).padding.top + AppBar().preferredSize.height;
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (OverscrollIndicatorNotification notification) {
        if (notification.leading) {
          notification.paintOffset = leadingPaintOffset;
        }
        return false;
      },
      child: CustomScrollView(
        slivers: <Widget>[
          const SliverAppBar(title: Text('Custom PaintOffset')),
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
