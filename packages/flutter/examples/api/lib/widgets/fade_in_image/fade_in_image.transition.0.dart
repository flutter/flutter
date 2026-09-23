// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Flutter code sample for [FadeInImage.transition].

void main() => runApp(const FadeInImageTransitionExampleApp());

class FadeInImageTransitionExampleApp extends StatelessWidget {
  const FadeInImageTransitionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      builder: (BuildContext context, Widget? child) {
        return const FadeInImageTransitionExample();
      },
    );
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
  // A solid, opaque placeholder makes the difference between the two
  // transitions visible: with FadeInImageTransition.sequential it fades out
  // before the image appears, while with FadeInImageTransition.fadeInOver it
  // stays put until the image has faded in on top of it.
  static final Uint8List _placeholderBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAEklEQVR42mNIqO3+jw8zjAwFAA9JmcEHBMcCAAAAAElFTkSuQmCC',
  );

  FadeInImageTransition _transition = FadeInImageTransition.sequential;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final FadeInImageTransition transition
                    in FadeInImageTransition.values)
                  _TransitionButton(
                    transition: transition,
                    selected: transition == _transition,
                    onPressed: () {
                      setState(() {
                        _transition = transition;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 250,
              height: 250,
              child: FadeInImage(
                placeholder: MemoryImage(_placeholderBytes),
                image: const NetworkImage(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/puffin.jpg',
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

class _TransitionButton extends StatelessWidget {
  const _TransitionButton({
    required this.transition,
    required this.selected,
    required this.onPressed,
  });

  final FadeInImageTransition transition;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF0175C2)),
          color: selected ? const Color(0xFF0175C2) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          transition.name,
          style: TextStyle(
            color: selected ? const Color(0xFFFFFFFF) : const Color(0xFF0175C2),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
