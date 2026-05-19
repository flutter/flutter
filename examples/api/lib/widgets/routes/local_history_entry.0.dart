// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [LocalHistoryEntry].

void main() {
  runApp(PanelDemo());
}

class PanelDemo extends StatefulWidget {
  const PanelDemo({super.key});
  @override
  State<PanelDemo> createState() => _PanelDemoState();
}

class _PanelDemoState extends State<PanelDemo> {
  bool _isPanelOpen = false;
  LocalHistoryEntry? _entry;
  void _openPanel() {
    if (_isPanelOpen) {
      return;
    }
    _entry = LocalHistoryEntry(
      onRemove: () {
        setState(() {
          _isPanelOpen = false;
          _entry = null;
        });
      },
    );
    ModalRoute.of(context)?.addLocalHistoryEntry(_entry!);
    setState(() {
      _isPanelOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('LocalHistoryEntry Example')),
        body: Stack(
          children: <Widget>[
            Center(
              child: ElevatedButton(
                onPressed: _openPanel,
                child: const Text('Open Panel'),
              ),
            ),
            if (_isPanelOpen)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 200,
                  color: Colors.blueAccent,
                  child: const Center(
                    child: Text(
                      'Press back to close this panel',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
