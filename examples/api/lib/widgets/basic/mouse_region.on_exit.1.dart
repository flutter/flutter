// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for MouseRegion.onExit

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(
          child: MyStatefulWidget(),
        ),
      ),
    );
  }
}

// A region that hides its content one second after being hovered.
class MyTimedButton extends StatefulWidget {
  const MyTimedButton(
      {super.key, required this.onEnterButton, required this.onExitButton});

  final VoidCallback onEnterButton;
  final VoidCallback onExitButton;

  @override
  State<MyTimedButton> createState() => _MyTimedButton();
}

class _MyTimedButton extends State<MyTimedButton> {
  bool regionIsHidden = false;
  bool hovered = false;

  Future<void> startCountdown() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    hideButton();
  }

  void hideButton() {
    setState(() {
      regionIsHidden = true;
    });
    // This statement is necessary.
    if (hovered) {
      widget.onExitButton();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: MouseRegion(
        child: regionIsHidden
            ? null
            : MouseRegion(
                onEnter: (_) {
                  widget.onEnterButton();
                  setState(() {
                    hovered = true;
                  });
                  startCountdown();
                },
                onExit: (_) {
                  setState(() {
                    hovered = false;
                  });
                  widget.onExitButton();
                },
                child: Container(color: Colors.red),
              ),
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  Key key = UniqueKey();
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ElevatedButton(
          onPressed: () {
            setState(() {
              key = UniqueKey();
            });
          },
          child: const Text('Refresh'),
        ),
        if (hovering) const Text('Hovering'),
        if (!hovering) const Text('Not hovering'),
        MyTimedButton(
          key: key,
          onEnterButton: () {
            setState(() {
              hovering = true;
            });
          },
          onExitButton: () {
            setState(() {
              hovering = false;
            });
          },
        ),
      ],
    );
  }
}
