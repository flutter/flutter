// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Flutter code sample for [AbsorbPointer].

void main() => runApp(const AbsorbPointerApp());

class AbsorbPointerApp extends StatelessWidget {
  const AbsorbPointerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      builder: (BuildContext context, Widget? child) {
        return const AbsorbPointerExample();
      },
    );
  }
}

class AbsorbPointerExample extends StatefulWidget {
  const AbsorbPointerExample({super.key});

  @override
  State<AbsorbPointerExample> createState() => _AbsorbPointerExampleState();
}

class _AbsorbPointerExampleState extends State<AbsorbPointerExample> {
  int _absorbTapCount = 0;
  int _ignoreTapCount = 0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: <Widget>[
          Column(
            mainAxisAlignment: .center,
            children: <Widget>[
              const Text('AbsorbPointer'),
              const SizedBox(height: 16.0),
              Stack(
                alignment: .center,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _absorbTapCount += 1;
                      });
                    },
                    child: Container(
                      width: 200.0,
                      height: 100.0,
                      color: const Color(0xFF2196F3),
                      alignment: .center,
                      child: const Text(
                        'Tap me',
                        style: TextStyle(color: Color(0xFFFFFFFF)),
                      ),
                    ),
                  ),
                  // The AbsorbPointer absorbs the pointer events itself: over
                  // the overlapping region, neither its child nor the target
                  // behind it in the stack receives the tap, so the counter
                  // does not change.
                  AbsorbPointer(
                    child: Container(
                      width: 100.0,
                      height: 200.0,
                      color: const Color(0x88BBDEFB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text('Taps received: $_absorbTapCount'),
            ],
          ),
          Column(
            mainAxisAlignment: .center,
            children: <Widget>[
              const Text('IgnorePointer'),
              const SizedBox(height: 16.0),
              Stack(
                alignment: .center,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _ignoreTapCount += 1;
                      });
                    },
                    child: Container(
                      width: 200.0,
                      height: 100.0,
                      color: const Color(0xFF4CAF50),
                      alignment: .center,
                      child: const Text(
                        'Tap me',
                        style: TextStyle(color: Color(0xFFFFFFFF)),
                      ),
                    ),
                  ),
                  // The IgnorePointer is invisible to hit testing: over the
                  // overlapping region, its child does not receive the tap,
                  // but the target behind it in the stack does, so the
                  // counter increases.
                  IgnorePointer(
                    child: Container(
                      width: 100.0,
                      height: 200.0,
                      color: const Color(0x88C8E6C9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text('Taps received: $_ignoreTapCount'),
            ],
          ),
        ],
      ),
    );
  }
}
