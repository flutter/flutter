// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [ListenableBuilder].

import 'package:flutter/material.dart';

void main() => runApp(const ListenableBuilderApp());

// This widget listens for changes in the focus state of the subtree defined by
// its child widget, and swaps out the BorderSide of a border around the child
// widget when it has focus.
class FocusListener extends StatefulWidget {
  const FocusListener({
    super.key,
    required this.child,
    this.border,
    this.focusedSide,
  });

  final OutlinedBorder? border;
  final BorderSide? focusedSide;
  final Widget child;

  @override
  State<FocusListener> createState() => _FocusListenerState();
}

class _FocusListenerState extends State<FocusListener> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OutlinedBorder effectiveBorder = widget.border ?? const RoundedRectangleBorder();
    return ListenableBuilder(
      listenable: _focusNode,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        return Focus(
          focusNode: _focusNode,
          skipTraversal: true,
          canRequestFocus: false,
          child: Container(
            decoration: ShapeDecoration(
              shape: effectiveBorder.copyWith(
                side: _focusNode.hasFocus ? widget.focusedSide : null,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class MyField extends StatefulWidget {
  const MyField({super.key, required this.label});

  final String label;

  @override
  State<MyField> createState() => _MyFieldState();
}

class _MyFieldState extends State<MyField> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(widget.label)),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(controller: controller),
            ),
          ),
          ElevatedButton(
              onPressed: () {
                debugPrint('Saving ${widget.label} as ${controller.text}.');
                // Save data here.
              },
              child: const Text('Save')),
        ],
      ),
    );
  }
}

class ListenableBuilderApp extends StatelessWidget {
  const ListenableBuilderApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  MyField(label: 'Title'),
                  FocusListener(
                    border: RoundedRectangleBorder(
                        side: BorderSide(
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                    focusedSide: BorderSide(
                      width: 4,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                    child: MyField(label: 'Name'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
