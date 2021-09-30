// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateless_widget_scaffold.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for InteractiveViewer.constrained
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// This example shows how to create a pannable table. Because the table is
// larger than the entire screen, setting `constrained` to false is necessary
// to allow it to be drawn to its full size. The parts of the table that
// exceed the screen size can then be panned into view.

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
        body: const MyStatelessWidget(),
      ),
    );
  }
}

/// This is the stateless widget that the main application instantiates.
class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

  Widget build(BuildContext context) {
    const int _rowCount = 48;
    const int _columnCount = 6;

    return InteractiveViewer(
      alignPanAxis: true,
      constrained: false,
      scaleEnabled: false,
      child: Table(
        columnWidths: <int, TableColumnWidth>{
          for (int column = 0; column < _columnCount; column += 1)
            column: const FixedColumnWidth(200.0),
        },
        children: <TableRow>[
          for (int row = 0; row < _rowCount; row += 1)
            TableRow(
              children: <Widget>[
                for (int column = 0; column < _columnCount; column += 1)
                  Container(
                    height: 26,
                    color: row % 2 + column % 2 == 1
                        ? Colors.white
                        : Colors.grey.withOpacity(0.1),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('$row x $column'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}
