// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [Wrap] with [Wrapped] children.

void main() => runApp(const WrapExampleApp());

class WrapExampleApp extends StatelessWidget {
  const WrapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WrapExample(),
    );
  }
}

class WrapExample extends StatefulWidget {
  const WrapExample({super.key});

  @override
  State<WrapExample> createState() => _WrapExampleState();
}

class _WrapExampleState extends State<WrapExample> {
  static final List<WrapFit?> fits = <WrapFit?>[null, ...WrapFit.values];
  List<(WrapFit?, String)> items = <(WrapFit?, String)>[(null, 'Item 0'), (null, 'Item 1')];

  Widget buildItem(int index, WrapFit? fit, String content) {
    final Widget button = FilledButton.icon(
        onPressed: () {
          setState(() {
            items[index] = (fits[((fit?.index ?? - 1) + 2) % fits.length], content);
          });
        },
        onLongPress: () {
          setState(() {
            items.removeAt(index);
          });
        },
        icon: const Icon(Icons.switch_access_shortcut),
        iconAlignment: IconAlignment.end,
        label: Text(content),
        style: TextButton.styleFrom(
          backgroundColor: switch (fit) {
            WrapFit.runTight => const Color.fromARGB(255, 243, 33, 33),
            WrapFit.runLoose => const Color.fromARGB(255, 255, 146, 146),
            WrapFit.runMaybeTight => const Color.fromARGB(255, 41, 182, 62),
            WrapFit.tight => const Color.fromARGB(255, 3, 43, 244),
            null => const Color.fromARGB(255, 34, 196, 255),
          },
          foregroundColor: fit?.isTight ?? false ? Colors.white : Colors.black,
      ),
    );

    if (fit == null) {
      return button;
    } else {
      return Wrapped(
        fit: fit,
        child: Tooltip(
          message: fit.name,
          child: button,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wrap Example')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          runSpacing: 8,
          spacing: 8,
          children: <Widget>[
            for (final (int index, (WrapFit? fit, String content)) in items.indexed)
              buildItem(index, fit, content),
            Wrapped(
              // If the child fits in the current run,
              // its max width is set to the remaining space.
              // Otherwise it may be as wide as the Wrap
              fit: WrapFit.runLoose,
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'some text',
                  counterText: 'press ENTER to add'
                ),
                onSubmitted: (String value) {
                  setState(() {
                    items.add((null, value));
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
