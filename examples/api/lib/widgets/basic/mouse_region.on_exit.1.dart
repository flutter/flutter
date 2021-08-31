// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateful_widget_scaffold_center.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for MouseRegion.onExit
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// The following example shows a widget that hides its content one second
// after being hovered, and also exposes the enter and exit callbacks.
// Because the widget conditionally creates the `MouseRegion`, and leaks the
// hover state, it needs to take the restriction into consideration. In this
// case, since it has access to the event that triggers the disappearance of
// the `MouseRegion`, it simply trigger the exit callback during that event
// as well.

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// This is the main application widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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

//*****************************************************************************
//* ▼▼▼▼▼▼▼▼ code-preamble ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// A region that hides its content one second after being hovered.
class MyTimedButton extends StatefulWidget {
  const MyTimedButton(
      {Key? key, required this.onEnterButton, required this.onExitButton})
      : super(key: key);

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

//* ▲▲▲▲▲▲▲▲ code-preamble ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//*****************************************************************************

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

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

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}
