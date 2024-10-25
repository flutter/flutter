// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [SelectionArea].

void main() => runApp(const SelectionAreaSelectionListenerExampleApp());

class SelectionAreaSelectionListenerExampleApp extends StatelessWidget {
  const SelectionAreaSelectionListenerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SelectionListenerNotifier _selectionNotifier = SelectionListenerNotifier();
  SelectedContentRange? _currentRange;
  SelectionStatus? _currentSelectionStatus;
  SelectionListenerStatus? _selectionListenerStatus;

  @override
  void initState() {
    super.initState();
    _selectionNotifier.addStatusListener(_handleOnSelectionStateChanged);
  }

  @override
  void dispose() {
    _selectionNotifier.removeStatusListener(_handleOnSelectionStateChanged);
    _selectionNotifier.dispose();
    _currentRange = null;
    _currentSelectionStatus = null;
    super.dispose();
  }

  void _handleOnSelectionStateChanged(SelectionListenerStatus status) {
    setState(() {
      _currentRange = _selectionNotifier.range;
      _currentSelectionStatus = _selectionNotifier.status;
      _selectionListenerStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Selection StartOffset: ${_currentRange?.startOffset}'),
                Text('Selection EndOffset: ${_currentRange?.endOffset}'),
                Text('Selection Status: $_currentSelectionStatus'),
                Text('Selection Listener Status: $_selectionListenerStatus'),
              ],
            ),
            const SizedBox(height: 15.0,),
            SelectionArea(
              child: SelectionListener(
                selectionNotifier: _selectionNotifier,
                child: const Text('This is some text under a SelectionArea that can be selected.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
