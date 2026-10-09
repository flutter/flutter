// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Container.clipBehavior].

void main() => runApp(const ContainerClipBehaviorExampleApp());

/// The color of the border painted by both samples below.
const Color borderColor = Color(0xFF3F51B5); // Colors.indigo

/// The color of the opaque child placed inside both [Container]s below.
const Color fillColor = Color(0xFFFFC107); // Colors.amber

/// The width and height of both sample [Container]s below.
const double sampleSize = 140.0;

/// The corner radius of both samples' [BoxDecoration.borderRadius].
const double outerRadius = 56.0;

/// The border width of both samples.
const double borderWidth = 8.0;

class ContainerClipBehaviorExampleApp extends StatelessWidget {
  const ContainerClipBehaviorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ContainerClipBehaviorExample());
  }
}

class ContainerClipBehaviorExample extends StatelessWidget {
  const ContainerClipBehaviorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Container clipBehavior and a border')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
                  label: 'Border in the decoration',
                  child: Container(
                    key: const Key('covered-pitfall'),
                    width: sampleSize,
                    height: sampleSize,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                      borderRadius: BorderRadius.circular(outerRadius),
                    ),
                    // The child's sharp corners cover the border ring near
                    // the corners; the clip only trims what sticks out past
                    // the decoration's outer edge.
                    child: const ColoredBox(color: fillColor),
                  ),
                ),
                _Sample(
                  label: 'Border in the foregroundDecoration',
                  child: Container(
                    key: const Key('covered-recommended'),
                    width: sampleSize,
                    height: sampleSize,
                    clipBehavior: Clip.antiAlias,
                    // Without a border, the decoration no longer insets the
                    // child, but it still defines the rounded clip path.
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(outerRadius),
                    ),
                    // An identical border in the foreground decoration paints
                    // on top of the child, so it stays fully visible.
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                      borderRadius: BorderRadius.circular(outerRadius),
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
