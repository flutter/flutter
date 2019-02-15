// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(MaterialApp(
    title: 'Focusable Demo',
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Focusable Demo'),
      ),
      body: const Center(
        child: FocusableDemo(),
      ),
    ),
  ));
}

class FocusableButton extends StatefulWidget {
  const FocusableButton({
    Key key,
    @required this.title,
    this.autofocus = false,
  }) : super(key: key);

  final String title;
  final bool autofocus;

  @override
  _FocusableButtonState createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<FocusableButton> {
  bool _handleKeyEvent(FocusableNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _handleButtonPress();
      }
    }
    print('Button ${widget.title} got key event $event');
    return true;
  }

  void _handleButtonPress() {
    print('Button ${widget.title} pressed.');
  }

  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    print('Focusable Button ${widget.title} ${_hasFocus ? 'has focus' : 'does not have focus'}');
    print(context.owner.focusManager.rootScope.toStringDeep());
    return Focusable(
      autofocus: widget.autofocus,
      debugLabel: widget.title,
      showDecorations: true,
      onKey: _handleKeyEvent,
      onFocusChange: (bool hasFocus) {
        setState(() {
          _hasFocus = hasFocus;
        });
      },
      child: Builder(builder: (BuildContext context) {
        return FlatButton(
          onPressed: () {
            Focusable.of(context).requestFocus();
            _handleButtonPress();
          },
          child: Text(widget.title),
        );
      }),
    );
  }
}

class FocusableDemo extends StatefulWidget {
  const FocusableDemo({Key key}) : super(key: key);

  @override
  _FocusableDemoState createState() => _FocusableDemoState();
}

class _FocusableDemoState extends State<FocusableDemo> {
  @override
  Widget build(BuildContext context) {
    print('Built main widget: ${context.owner.focusManager.rootScope.toStringDeep()}');

    final TextTheme textTheme = Theme.of(context).textTheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultFocusTraversal(
        policy: const ReadingOrderTraversalPolicy(),
        child: Focusable(
          debugLabel: 'Scope',
          isScope: true,
          onKey: (FocusableNode node, RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              print('Scope got key event: ${event.logicalKey}, $node');
              print('Keys down: ${RawKeyboard.instance.keysPressed}');
              if (event.logicalKey == LogicalKeyboardKey.tab) {
                print(context.owner.focusManager.rootFocusable.toStringDeep());
                if (event.isShiftPressed) {
                  print('Moving to previous.');
                  setState(() {
                    node.previousFocus();
                  });
                } else {
                  print('Moving to next.');
                  setState(() {
                    node.nextFocus();
                  });
                }
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                setState(() {
                  node.focusInDirection(AxisDirection.left);
                });
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                setState(() {
                  node.focusInDirection(AxisDirection.right);
                });
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                setState(() {
                  node.focusInDirection(AxisDirection.up);
                });
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                setState(() {
                  node.focusInDirection(AxisDirection.down);
                });
              }
            }
          },
          child: DefaultTextStyle(
            style: textTheme.display1,
            child: Builder(builder: (BuildContext context) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      FocusableButton(
                        title: 'One',
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      FocusableButton(
                        title: 'Two',
                      ),
                      FocusableButton(title: 'Three'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      FocusableButton(
                        title: 'Four',
                      ),
                      FocusableButton(title: 'Five'),
                      FocusableButton(title: 'Six'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      FocusableButton(
                        title: 'Seven',
                        autofocus: true,
                      ),
                      FocusableButton(title: 'Eight'),
                      FocusableButton(title: 'Nine'),
                      FocusableButton(title: 'Ten'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Focusable(
                        debugLabel: 'Next',
                        child: MaterialButton(
                          onPressed: () {
                            return Focusable.of(context).nextFocus();
                          },
                          child: const Text('NEXT'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
