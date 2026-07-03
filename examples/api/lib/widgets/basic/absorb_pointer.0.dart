// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [AbsorbPointer].

void main() => runApp(const AbsorbPointerApp());

class AbsorbPointerApp extends StatelessWidget {
  const AbsorbPointerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AbsorbPointer Sample')),
        body: const Center(child: AbsorbPointerExample()),
      ),
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
    return Row(
      mainAxisAlignment: .spaceEvenly,
      children: <Widget>[
        Column(
          mainAxisSize: .min,
          children: <Widget>[
            const Text('AbsorbPointer'),
            const SizedBox(height: 16.0),
            Stack(
              alignment: .center,
              children: <Widget>[
                SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _absorbTapCount += 1;
                      });
                    },
                    child: null,
                  ),
                ),
                // The AbsorbPointer absorbs the pointer events itself: over
                // the overlapping region, neither its child button nor the
                // button behind it in the stack receives the tap, so the
                // counter does not change.
                SizedBox(
                  width: 100.0,
                  height: 200.0,
                  child: AbsorbPointer(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade200,
                      ),
                      onPressed: () {},
                      child: null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text('Taps received: $_absorbTapCount'),
          ],
        ),
        Column(
          mainAxisSize: .min,
          children: <Widget>[
            const Text('IgnorePointer'),
            const SizedBox(height: 16.0),
            Stack(
              alignment: .center,
              children: <Widget>[
                SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _ignoreTapCount += 1;
                      });
                    },
                    child: null,
                  ),
                ),
                // The IgnorePointer is invisible to hit testing: over the
                // overlapping region, its child button does not receive the
                // tap, but the button behind it in the stack does, so the
                // counter increases.
                SizedBox(
                  width: 100.0,
                  height: 200.0,
                  child: IgnorePointer(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade200,
                      ),
                      onPressed: () {},
                      child: null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text('Taps received: $_ignoreTapCount'),
          ],
        ),
      ],
    );
  }
}
