// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

class Desert {
  Desert(this.name, this.calories, this.fat, this.carbs, this.protein, this.sodium, this.calcium, this.iron);
  final String name;
  final int calories;
  final double fat;
  final int carbs;
  final double protein;
  final int sodium;
  final int calcium;
  final int iron;

  bool selected = false;
}

class DataTableDemo extends StatefulWidget {
  static const String routeName = '/data-table';

  @override
  _DataTableDemoState createState() => new _DataTableDemoState();
}

class _DataTableDemoState extends State<DataTableDemo> {

  int _sortColumnIndex;
  bool _sortAscending = true;

  final List<Desert> _deserts = [
    new Desert('Frozen yogurt',      159,  6.0, 24, 4.0,  87, 14,  1),
    new Desert('Ice cream sandwich', 237,  9.0, 37, 4.3, 129,  8,  1),
    new Desert('Eclair',             262, 16.0, 24, 6.0, 337,  6,  7),
    new Desert('Cupcake',            305,  3.7, 67, 4.3, 413,  3,  8),
    new Desert('Gingerbread',        356, 16.0, 49, 3.9, 327,  7, 16),
    new Desert('Jelly bean',         375,  0.0, 94, 0.0,  50,  0,  0),
    new Desert('Lollipop',           392,  0.2, 98, 0.0,  38,  0,  2),
    new Desert('Honeycomb',          408,  3.2, 87, 6.5, 562,  0, 45),
    new Desert('Donut',              452, 25.0, 51, 4.9, 326,  2, 22),
    new Desert('KitKat',             518, 26.0, 65, 7.0,  54, 12,  6),
  ];

  void _sort/*<T>*/(Comparable<dynamic/*=T*/> getField(Desert d), int columnIndex, bool ascending) {
    setState(() {
      _deserts.sort((Desert a, Desert b) {
        if (!ascending) {
          final Desert c = a;
          a = b;
          b = c;
        }
        final Comparable<dynamic/*=T*/> aValue = getField(a);
        final Comparable<dynamic/*=T*/> bValue = getField(b);
        return Comparable.compare(aValue, bValue);
      });
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Data tables')),
      body: new Block(
        children: <Widget>[
          new Material(
            child: new IntrinsicHeight(
              child: new Block(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  new DataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: <DataColumn>[
                      new DataColumn(
                        label: new Text('Dessert (100g serving)'),
                        onSort: (int columnIndex, bool ascending) => _sort/*<String>*/((Desert d) => d.name, columnIndex, ascending)
                      ),
                      new DataColumn(
                        label: new Text('Calories'),
                        tooltip: 'The total amount of food energy in the given serving size.',
                        numeric: true,
                        onSort: (int columnIndex, bool ascending) => _sort/*<num>*/((Desert d) => d.calories, columnIndex, ascending)
                      ),
                      new DataColumn(
                        label: new Text('Fat (g)'),
                        numeric: true,
                        onSort: (int columnIndex, bool ascending) => _sort/*<num>*/((Desert d) => d.fat, columnIndex, ascending)
                      ),
                      new DataColumn(
                        label: new Text('Carbs (g)'),
                        numeric: true,
                        onSort: (int columnIndex, bool ascending) => _sort/*<num>*/((Desert d) => d.carbs, columnIndex, ascending)
                      ),
                      new DataColumn(
                        label: new Text('Protein (g)'),
                        numeric: true,
                        onSort: (int columnIndex, bool ascending) => _sort/*<num>*/((Desert d) => d.protein, columnIndex, ascending)
                      ),
                      new DataColumn(
                        label: new Text('Sodium (mg)'),
                        numeric: true,
                        onSort: (int columnIndex, bool ascending) => _sort/*<num>*/((Desert d) => d.sodium, columnIndex, ascending)
                      ),
                      new DataColumn(
                        label: new Text('Calcium (%)'),
                        tooltip: 'The amount of calcium as a percentage of the recommended daily amount.',
                        numeric: true,
                        onSort: (int columnIndex, bool ascending) => _sort/*<num>*/((Desert d) => d.calcium, columnIndex, ascending)
                      ),
                      new DataColumn(
                        label: new Text('Iron (%)'),
                        numeric: true,
                        onSort: (int columnIndex, bool ascending) => _sort/*<num>*/((Desert d) => d.iron, columnIndex, ascending)
                      ),
                    ],
                    rows: _deserts.map/*<DataRow>*/((Desert desert) {
                      return new DataRow(
                        key: new ValueKey<Desert>(desert),
                        selected: desert.selected,
                        onSelectChanged: (bool selected) { setState(() { desert.selected = selected; }); },
                        cells: <DataCell>[
                          new DataCell(new Text('${desert.name}')),
                          new DataCell(new Text('${desert.calories}')),
                          new DataCell(new Text('${desert.fat.toStringAsFixed(1)}')),
                          new DataCell(new Text('${desert.carbs}')),
                          new DataCell(new Text('${desert.protein.toStringAsFixed(1)}')),
                          new DataCell(new Text('${desert.sodium}')),
                          new DataCell(new Text('${desert.calcium}%')),
                          new DataCell(new Text('${desert.iron}%')),
                        ]
                      );
                    }).toList(growable: false)
                  )
                ]
              )
            )
          )
        ]
      )
    );
  }
}
