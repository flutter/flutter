// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [PaginatedDataTable].

class MyDataSource extends DataTableSource {
  @override
  int get rowCount => 3;

  @override
  DataRow? getRow(int index) {
    final List<String>? info = switch (index) {
      0 => const <String>['Sarah', '19', 'Student'],
      1 => const <String>['Janine', '43', 'Professor'],
      2 => const <String>['William', '27', 'Associate Professor'],
      _ => null,
    };
    if (info == null) {
      return null;
    }
    return DataRow(cells: <DataCell>[for (final item in info) DataCell(Text(item))]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

final DataTableSource dataSource = MyDataSource();

void main() => runApp(const DataTableExampleApp());

class DataTableExampleApp extends StatelessWidget {
  const DataTableExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SingleChildScrollView(
        padding: EdgeInsets.all(12.0),
        child: DataTableExample(),
      ),
    );
  }
}

class DataTableExample extends StatelessWidget {
  const DataTableExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PaginatedDataTable(
      columns: const <DataColumn>[
        DataColumn(
          label: Text('Name'),
        ),
        DataColumn(
          label: Text('Age'),
        ),
        DataColumn(
          label: Text('Role'),
        ),
      ],
      source: dataSource,
    );
  }
}
