import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TableDemo extends StatefulWidget {
  const TableDemo({ Key key }) : super(key: key);

  static const String routeName = '/table';

  @override _TableDemoState createState() => _TableDemoState();
}

class _TableDemoState extends State<TableDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scrollable Table'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.help),
            tooltip: 'Help',
            onPressed: () {
              showDialog<Column>(
                context: context,
                builder: (BuildContext context) => instructionDialog,
              );
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        disableRotation: true,
        disableScale: true,
        child: _getTable(10, 2),
      ),
    );
  }

  Table _getTable(int rowCount, int columnCount) {
    return Table(
      // ignore: prefer_const_literals_to_create_immutables
      columnWidths: <int, TableColumnWidth>{
        for (int column = 0; column < columnCount; column++)
          column: const FixedColumnWidth(300.0),
      },
      // ignore: prefer_const_literals_to_create_immutables
      children: <TableRow>[
        for (int row = 0; row < rowCount; row++)
          // ignore: prefer_const_constructors
          TableRow(
            // ignore: prefer_const_literals_to_create_immutables
            children: <Widget>[
              for (int column = 0; column < columnCount; column++)
                Container(
                  height: 100,
                  color: row % 2 + column % 2 == 1 ? Colors.red : Colors.green,
                ),
            ],
          ),
      ],
    );
  }

  Widget get instructionDialog {
    return AlertDialog(
      title: const Text('Bidirectional Scrolling'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          Text('Tap to edit hex tiles, and use gestures to move around the scene:\n'),
          Text('- Drag to pan.'),
          Text('- Pinch to zoom.'),
          Text('- Rotate with two fingers.'),
          Text('\nYou can always press the home button to return to the starting orientation!'),
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
