import 'package:flutter/material.dart';

@override
void initState() {
super.initState();
_sortedStudents = List.of(students);
}

void _sort<T>(Comparable<T> Function(Student) getField, int columnIndex) {
setState(() {
_isAscending = (_sortColumnIndex == columnIndex) ? !_isAscending : true;
_sortColumnIndex = columnIndex;

_sortedStudents.sort((a, b) {
final aValue = getField(a);
final bValue = getField(b);
return _isAscending
? Comparable.compare(aValue, bValue)
: Comparable.compare(bValue, aValue);
});
});
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Student Table'),
backgroundColor: Colors.deepPurple.shade200,
),
body: SingleChildScrollView(
scrollDirection: Axis.vertical,
child: SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: DataTable(
sortColumnIndex: _sortColumnIndex,
sortAscending: _isAscending,
columns: [
DataColumn(
label: const Text('Nome'),
onSort: (i, _) => _sort((s) => s.name, i),
),
DataColumn(
label: const Text('Idade'),
numeric: true,
onSort: (i, _) => _sort((s) => s.age, i),
),
DataColumn(
label: const Text('Nota'),
numeric: true,
onSort: (i, _) => _sort((s) => s.grade, i),
),
],
rows: _sortedStudents
.map(
(s) => DataRow(cells: [
DataCell(Text(s.name)),
DataCell(Text(s.age.toString())),
DataCell(Text(s.grade.toStringAsFixed(1))),
]),
)
.toList(),
),
),
),
);
}
}