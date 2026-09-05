// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Container.decoration].

void main() => runApp(const ContainerDecorationExampleApp());

/// The color of the border painted by both samples below.
const Color borderColor = Color(0xFF3F51B5); // Colors.indigo

/// The color of the opaque child placed inside both [Container]s below.
const Color fillColor = Color(0xFFFFC107); // Colors.amber

/// The page background, which shows through the corner gaps when the child
/// is clipped to the outer radius.
const Color backgroundColor = Color(0xFFFFFFFF);

/// The width and height of both sample [Container]s below.
const double sampleSize = 160.0;

/// The corner radius of both samples' [BoxDecoration.borderRadius].
const double outerRadius = 56.0;

/// The border width of both samples.
const double borderWidth = 20.0;

/// The child's corner radius that matches the inside of a [borderWidth]-wide
/// border around [outerRadius].
const double innerRadius = outerRadius - borderWidth;

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
      appBar: AppBar(
        title: const Text('Container decoration and a clipped child'),
      ),
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
                  label: 'Clipped to the outer radius',
                  child: Container(
                    key: const Key('gap-pitfall'),
                    width: sampleSize,
                    height: sampleSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                      borderRadius: BorderRadius.circular(outerRadius),
                    ),
                    // The child is inset by the border (see
                    // Decoration.padding), so outerRadius no longer matches
                    // the border's inner edge, whose radius is innerRadius
                    // (outerRadius minus the border width): the corners pull
                    // away from the border, leaving background-colored gaps.
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(outerRadius),
                      child: const ColoredBox(color: fillColor),
                    ),
                  ),
                ),
                _Sample(
                  label: 'Clipped to the outer radius minus the border width',
                  child: Container(
                    key: const Key('gap-recommended'),
                    width: sampleSize,
                    height: sampleSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                      borderRadius: BorderRadius.circular(outerRadius),
                    ),
                    // Reducing the clip radius to innerRadius aligns the
                    // child's corners with the inside of the border.
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(innerRadius),
                      child: const ColoredBox(color: fillColor),
                    ),
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
