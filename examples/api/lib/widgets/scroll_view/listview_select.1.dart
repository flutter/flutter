// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for ListTile selection in a ListView or GridView
// Long press any ListTile to enable selection mode.

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: ListTileSelectExample(),
    );
  }
}

class ListTileSelectExample extends StatefulWidget {
  const ListTileSelectExample({Key? key}) : super(key: key);

  @override
  ListTileSelectExampleState createState() => ListTileSelectExampleState();
}

class ListTileSelectExampleState extends State<ListTileSelectExample> {
  bool isEditMode = false;
  final int listLength = 30;
  late List<bool> _selected;
  bool _selectAll = false;
  bool _isGridMode = false;

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.generate(listLength, (_) => false);
  }

  @override
  void dispose() {
    _selected.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'ListTile select example',
          ),
          leading: isEditMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      isEditMode = false;
                    });
                  },
                )
              : const BackButton(),
          actions: <Widget>[
            if (_isGridMode)
              IconButton(
                icon: const Icon(Icons.grid_on),
                onPressed: () {
                  setState(() {
                    _isGridMode = false;
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  setState(() {
                    _isGridMode = true;
                  });
                },
              ),
            if (isEditMode)
              TextButton(
                  child: !_selectAll
                      ? const Text('select all')
                      : const Text('unselect all'),
                  onPressed: () {
                    _selectAll = !_selectAll;
                    setState(() {
                      _selected =
                          List<bool>.generate(listLength, (_) => _selectAll);
                    });
                  }),
          ],
        ),
        body: _isGridMode
            ? GridBuilder(
                isEditMode: isEditMode,
                selectedList: _selected,
                onEditChange: (bool x) {
                  setState(() {
                    isEditMode = x;
                  });
                },
              )
            : ListBuilder(
                isEditMode: isEditMode,
                selectedList: _selected,
                onEditChange: (bool x) {
                  setState(() {
                    isEditMode = x;
                  });
                },
              ));
  }
}

// ignore: must_be_immutable
class GridBuilder extends StatefulWidget {
  GridBuilder(
      {Key? key,
      required this.selectedList,
      required this.isEditMode,
      this.onEditChange})
      : super(key: key);

  bool isEditMode;
  final Function(bool)? onEditChange;
  final List<bool> selectedList;

  @override
  GridBuilderState createState() => GridBuilderState();
}

class GridBuilderState extends State<GridBuilder> {
  void _toggle(int index) {
    if (widget.isEditMode) {
      setState(() {
        widget.selectedList[index] = !widget.selectedList[index];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        itemCount: widget.selectedList.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemBuilder: (_, int index) {
          return InkWell(
            onTap: () => _toggle(index),
            onLongPress: () {
              if (!widget.isEditMode) {
                setState(() {
                  widget.isEditMode = true;
                  widget.selectedList[index] = true;
                });
                widget.onEditChange!(true);
              }
            },
            child: GridTile(
                child: Container(
              child: widget.isEditMode
                  ? Checkbox(
                      onChanged: (bool? x) => _toggle(index),
                      value: widget.selectedList[index])
                  : const Icon(Icons.image),
            )),
          );
        });
  }
}

// ignore: must_be_immutable
class ListBuilder extends StatefulWidget {
  ListBuilder(
      {Key? key,
      required this.selectedList,
      required this.isEditMode,
      this.onEditChange})
      : super(key: key);

  bool isEditMode;
  final List<bool> selectedList;
  final Function(bool)? onEditChange;

  @override
  State<ListBuilder> createState() => _ListBuilderState();
}

class _ListBuilderState extends State<ListBuilder> {
  void _toggle(int index) {
    if (widget.isEditMode) {
      setState(() {
        widget.selectedList[index] = !widget.selectedList[index];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.selectedList.length,
        itemBuilder: (_, int index) {
          return ListTile(
              onTap: () => _toggle(index),
              onLongPress: () {
                if (!widget.isEditMode) {
                  setState(() {
                    widget.isEditMode = true;
                    widget.selectedList[index] = true;
                  });
                  widget.onEditChange!(true);
                }
              },
              trailing: widget.isEditMode
                  ? Checkbox(
                      value: widget.selectedList[index],
                      onChanged: (bool? x) => _toggle(index),
                    )
                  : const SizedBox.shrink(),
              title: Text('item $index'));
        });
  }
}
