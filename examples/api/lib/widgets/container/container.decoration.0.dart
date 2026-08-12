// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Container.decoration].

void main() => runApp(const ContainerDecorationExampleApp());

/// The color of the border painted by every sample below.
const Color borderColor = Color(0xFF3F51B5); // Colors.indigo

/// The color of the opaque child placed inside every [Container] below.
const Color fillColor = Color(0xFFFFC107); // Colors.amber

/// The page background, which shows through the gaps in the first pitfall.
const Color backgroundColor = Color(0xFFFFFFFF);

class ContainerDecorationExampleApp extends StatelessWidget {
  const ContainerDecorationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ContainerDecorationExample());
  }
}

class ContainerDecorationExample extends StatelessWidget {
  const ContainerDecorationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: const Text('Container borders and clipping')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'A child clipped to the outer corner radius',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'The border insets the child, so clipping the child to the '
              'outer corner radius pulls its corners away from the inside '
              'of the border and shows the background through the gaps. '
              'Clipping to the corner radius minus the border width aligns '
              'the curves.',
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: <Widget>[
                _Sample(
                  label: 'Pitfall',
                  child: Container(
                    key: const Key('gap-pitfall'),
                    width: 140.0,
                    height: 140.0,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 20.0),
                      borderRadius: BorderRadius.circular(56.0),
                    ),
                    // The child is inset by the 20-pixel border (see
                    // Decoration.padding), so a 56-pixel corner radius no
                    // longer matches the border's inner edge, whose radius is
                    // 56.0 - 20.0 = 36.0 pixels: the corners pull away from
                    // the border, leaving background-colored gaps.
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(56.0),
                      child: const ColoredBox(color: fillColor),
                    ),
                  ),
                ),
                _Sample(
                  label: 'Recommended',
                  child: Container(
                    key: const Key('gap-recommended'),
                    width: 140.0,
                    height: 140.0,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 20.0),
                      borderRadius: BorderRadius.circular(56.0),
                    ),
                    // Reducing the clip radius by the border width aligns the
                    // child's corners with the inside of the border.
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36.0),
                      child: const ColoredBox(color: fillColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Text(
              'An opaque child under clipBehavior',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'The clip follows the outer edge of the decoration, and the '
              'decoration (including its border) paints behind the child, so '
              'an opaque child covers the border near the corners. Moving '
              'the border to an otherwise identical foregroundDecoration '
              'paints it on top of the child, while the border-free '
              'decoration still defines the clip path.',
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: <Widget>[
                _Sample(
                  label: 'Pitfall',
                  child: Container(
                    key: const Key('covered-pitfall'),
                    width: 140.0,
                    height: 140.0,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 8.0),
                      borderRadius: BorderRadius.circular(56.0),
                    ),
                    // The child's sharp corners cover the border ring near
                    // the corners; the clip only trims what sticks out past
                    // the decoration's outer edge.
                    child: const ColoredBox(color: fillColor),
                  ),
                ),
                _Sample(
                  label: 'Recommended',
                  child: Container(
                    key: const Key('covered-recommended'),
                    width: 140.0,
                    height: 140.0,
                    clipBehavior: Clip.antiAlias,
                    // Without a border, the decoration no longer insets the
                    // child, but it still defines the rounded clip path.
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(56.0),
                    ),
                    // An identical border in the foreground decoration paints
                    // on top of the child, so it stays fully visible.
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 8.0),
                      borderRadius: BorderRadius.circular(56.0),
                    ),
                    child: const ColoredBox(color: fillColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Sample extends StatelessWidget {
  const _Sample({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[child, const SizedBox(height: 4.0), Text(label)],
    );
  }
}
