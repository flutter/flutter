// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Flutter code sample for [FadeInImage.transition].

void main() => runApp(const FadeInImageTransitionExampleApp());

class FadeInImageTransitionExampleApp extends StatelessWidget {
  const FadeInImageTransitionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: FadeInImageTransitionExample());
  }
}

class FadeInImageTransitionExample extends StatefulWidget {
  const FadeInImageTransitionExample({super.key});

  @override
  State<FadeInImageTransitionExample> createState() =>
      _FadeInImageTransitionExampleState();
}

class _FadeInImageTransitionExampleState
    extends State<FadeInImageTransitionExample> {
  // A solid, opaque placeholder so the difference between the two transitions
  // is visible: in sequential mode it fades out before the image appears, while
  // in fadeInOver mode it stays put until the image has faded in on top.
  static final Uint8List _placeholderBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAEklEQVR42mNIqO3+jw8zjAwFAA9JmcEHBMcCAAAAAElFTkSuQmCC',
  );

  FadeInImageTransition _transition = FadeInImageTransition.sequential;
  int _reloadCount = 0;

  void _selectTransition(FadeInImageTransition transition) {
    setState(() {
      _transition = transition;
      // Change the image's cache key so the fade-in animation plays again each
      // time a transition is selected.
      _reloadCount += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FadeInImage.transition')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SegmentedButton<FadeInImageTransition>(
              segments: const <ButtonSegment<FadeInImageTransition>>[
                ButtonSegment<FadeInImageTransition>(
                  value: FadeInImageTransition.sequential,
                  label: Text('sequential'),
                ),
                ButtonSegment<FadeInImageTransition>(
                  value: FadeInImageTransition.fadeInOver,
                  label: Text('fadeInOver'),
                ),
              ],
              selected: <FadeInImageTransition>{_transition},
              onSelectionChanged: (Set<FadeInImageTransition> selection) {
                _selectTransition(selection.first);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 250,
              height: 250,
              child: FadeInImage(
                // Rebuild the widget from scratch on each selection so the fade
                // animation replays and both transitions can be compared.
                key: ValueKey<int>(_reloadCount),
                placeholder: MemoryImage(_placeholderBytes),
                image: NetworkImage(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/puffin.jpg?reload=$_reloadCount',
                ),
                fit: BoxFit.cover,
                transition: _transition,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
