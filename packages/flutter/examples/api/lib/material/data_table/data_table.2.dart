// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [DataTable].

void main() => runApp(const DataTableExampleApp());

/// An example app that shows a [DataTable] sorted by a single column.
class DataTableExampleApp extends StatelessWidget {
  const DataTableExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('DataTable Sample')),
        body: const DataTableExample(),
      ),
    );
  }
}

/// A simple representation of a person with a name, age, and role.
class Person {
  const Person({required this.name, required this.age, required this.role});

  final String name;
  final int age;
  final String role;
}

/// A widget that displays a [DataTable] of people and allows sorting them.
class DataTableExample extends StatefulWidget {
  const DataTableExample({super.key});

  @override
  State<DataTableExample> createState() => _DataTableExampleState();
}

class _DataTableExampleState extends State<DataTableExample> {
  final List<Person> _people = <Person>[
    const Person(name: 'Sarah', age: 19, role: 'Student'),
    const Person(name: 'Janine', age: 43, role: 'Professor'),
    const Person(name: 'William', age: 27, role: 'Associate Professor'),
    const Person(name: 'Emma', age: 31, role: 'Teaching Assistant'),
    const Person(name: 'Liam', age: 52, role: 'Dean'),
    const Person(name: 'Olivia', age: 24, role: 'Researcher'),
  ];

  /// The column the rows are currently sorted by, or null if not sorted.
  int? _sortColumnIndex;

  /// Whether the rows are sorted in ascending order.
  bool _sortAscending = true;

  /// Sorts the rows with [compare] and records the sort column and direction.
  ///
  /// [DataTable] only draws the sort arrow; reordering the rows is up to the app.
  void _sort(int columnIndex, bool ascending, Comparator<Person> compare) {
    setState(() {
      _people.sort(
        (Person a, Person b) => ascending ? compare(a, b) : compare(b, a),
      );
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DataTable(
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      columns: <DataColumn>[
        DataColumn(
          label: const Text('Name'),
          onSort: (int columnIndex, bool ascending) => _sort(
            columnIndex,
            ascending,
            (Person a, Person b) => a.name.compareTo(b.name),
          ),
        ),
        DataColumn(
          label: const Text('Age'),
          numeric: true,
          onSort: (int columnIndex, bool ascending) => _sort(
            columnIndex,
            ascending,
            (Person a, Person b) => a.age.compareTo(b.age),
          ),
        ),
        const DataColumn(label: Text('Role')),
      ],
      rows: <DataRow>[
        for (final Person person in _people)
          DataRow(
            cells: <DataCell>[
              DataCell(Text(person.name)),
              DataCell(Text('${person.age}')),
              DataCell(Text(person.role)),
            ],
          ),
      ],
    );
  }
}
