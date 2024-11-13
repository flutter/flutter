// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
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
  SelectableRegionSelectionStatus? _selectableRegionStatus;

  @override
  void dispose() {
    _selectionNotifier.dispose();
    _currentRange = null;
    _currentSelectionStatus = null;
    _selectableRegionStatus = null;
    super.dispose();
  }

  void _handleOnSelectionStateChanged(SelectableRegionSelectionStatus status) {
    setState(() {
      _currentRange = _selectionNotifier.range;
      _currentSelectionStatus = _selectionNotifier.status;
      _selectableRegionStatus = status;
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
                Text('Selectable Region Status: $_selectableRegionStatus'),
              ],
            ),
            const SizedBox(height: 15.0,),
            SelectionArea(
              child: MySelectableText(
                selectionNotifier: _selectionNotifier,
                onChanged: _handleOnSelectionStateChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MySelectableText extends StatefulWidget {
  const MySelectableText({
    super.key,
    required this.selectionNotifier,
    required this.onChanged,
  });

  final SelectionListenerNotifier selectionNotifier;
  final ValueChanged<SelectableRegionSelectionStatus> onChanged;

  @override
  State<MySelectableText> createState() => _MySelectableTextState();
}

class _MySelectableTextState extends State<MySelectableText> {
  ValueListenable<SelectableRegionSelectionStatus>? _selectableRegionScope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectableRegionScope?.removeListener(_handleOnSelectableRegionChanged);
    _selectableRegionScope = SelectableRegionScope.maybeOf(context);
    _selectableRegionScope?.addListener(_handleOnSelectableRegionChanged);
  }

  @override
  void dispose() {
    _selectableRegionScope?.removeListener(_handleOnSelectableRegionChanged);
    _selectableRegionScope = null;
    super.dispose();
  }

  void _handleOnSelectableRegionChanged() {
    if (_selectableRegionScope == null) {
      return;
    }
    widget.onChanged.call(_selectableRegionScope!.value);
  }

  @override
  Widget build(BuildContext context) {
    return SelectionListener(
      selectionNotifier: widget.selectionNotifier,
      child: const Text('This is some text under a SelectionArea that can be selected.'),
    );
  }
}
