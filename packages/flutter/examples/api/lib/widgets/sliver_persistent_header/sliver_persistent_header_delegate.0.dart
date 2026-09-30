// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [SliverPersistentHeaderDelegate].

void main() => runApp(const SliverPersistentHeaderDelegateExampleApp());

class SliverPersistentHeaderDelegateExampleApp extends StatelessWidget {
  const SliverPersistentHeaderDelegateExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SliverPersistentHeaderDelegateExample());
  }
}

class SliverPersistentHeaderDelegateExample extends StatelessWidget {
  const SliverPersistentHeaderDelegateExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          const SliverPersistentHeader(
            pinned: true,
            delegate: _TitleHeaderDelegate(minExtent: 60.0, maxExtent: 160.0),
          ),
          SliverList.builder(
            itemCount: 30,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(title: Text('Item $index'));
            },
          ),
        ],
      ),
    );
  }
}

class _TitleHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TitleHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
  });

  // The extents are supplied through the constructor and never change for a
  // given delegate instance, as the contract of the base class requires.
  @override
  final double minExtent;

  @override
  final double maxExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // `shrinkOffset` runs from 0.0, when the header is at its maxExtent, up to
    // maxExtent - minExtent, when it has collapsed to its minExtent. Scaling it
    // to the 0.0-1.0 range makes it convenient to interpolate on.
    final double t = shrinkOffset / (maxExtent - minExtent);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: Color.lerp(colors.primaryContainer, colors.primary, t),
      // `overlapsContent` is true once the list is scrolling underneath the
      // header, which is the usual cue to raise it above the content.
      elevation: overlapsContent ? 4.0 : 0.0,
      child: Center(
        child: Text(
          'Header',
          style: TextStyle(
            fontSize: 32.0 - 14.0 * t,
            color: Color.lerp(colors.onPrimaryContainer, colors.onPrimary, t),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TitleHeaderDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent;
  }
}
