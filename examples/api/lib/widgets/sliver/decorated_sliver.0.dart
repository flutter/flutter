// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() => runApp(const SliverDecorationExampleApp());

class SliverDecorationExampleApp extends StatelessWidget {
  const SliverDecorationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('SliverDecoration Sample')),
        body: const SliverDecorationExample(),
      ),
    );
  }
}

class SliverDecorationExample extends StatelessWidget {
  const SliverDecorationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        DecoratedSliver(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.5, -0.6),
              radius: 0.15,
              colors: <Color>[
                Color(0xFFEEEEEE),
                Color(0xFF111133),
              ],
              stops: <double>[0.9, 1.0],
            ),
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
               const Text('Goodnight Moon'),
            ]),
          ),
        ),
        const DecoratedSliver(
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.all(Radius.circular(50))
          ),
          sliver: SliverToBoxAdapter(child: SizedBox(height: 300)),
        ),
      ],
    );
  }
}
