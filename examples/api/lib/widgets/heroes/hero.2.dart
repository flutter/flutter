// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for Hero

import 'package:flutter/material.dart';

void main() => runApp(const HeroApp());

class HeroApp extends StatelessWidget {
  const HeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HeroExample(),
    );
  }
}

class HeroExample extends StatelessWidget {
  const HeroExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hero Sample')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 20.0),
          ListTile(
            leading: const Hero(
              tag: 'hero-rectangle',
              child: BoxWidget(size: Size(50.0, 50.0)),
            ),
            onTap: () => _gotoDetailsPage(context),
            title: const Text(
              'Tap on the icon to view hero animation transition.',
            ),
          ),
        ],
      ),
    );
  }

  void _gotoDetailsPage(BuildContext context) {
    Navigator.of(context).push(CustomRoute());
  }
}

class BoxWidget extends StatelessWidget {
  const BoxWidget({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.blue,
    );
  }
}

class CustomRoute extends PageRoute<void> with MaterialRouteTransitionMixin<void> {
  final LayerLink _link = LayerLink();
  late final OverlayEntry overlayEntry;

  @override
  Widget buildContent(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Second Page'),
        ),
        body: Center(
          child: Hero(
            key: const Key('hero'),
            tag: 'hero-rectangle',
            insertOverlayBelow: overlayEntry,
            child: const BoxWidget(size: Size(200.0, 200.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return CompositedTransformFollower(
      showWhenUnlinked: false,
      link: _link,
      child: IgnorePointer(
        child: FractionallySizedBox(
          heightFactor: 0.5,
          widthFactor: 0.5,
          child: ColoredBox(color: Colors.green.withOpacity(0.5)),
        ),
      ),
    );
  }

  @override
  bool get maintainState => false;

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return <OverlayEntry>[
      ...super.createOverlayEntries(),
      overlayEntry = OverlayEntry(builder: _buildOverlay),
    ];
  }
}
