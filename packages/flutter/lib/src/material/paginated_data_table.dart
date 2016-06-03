// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'card.dart';
import 'data_table.dart';
import 'data_table_source.dart';
import 'progress_indicator.dart';

/// A wrapper for [DataTable] that obtains data lazily from a [DataTableSource]
/// and displays it one page at a time. The widget is presented as a [Card].
class PaginatedDataTable extends StatefulWidget {
  /// Creates a widget describing a paginated [DataTable] on a [Card].
  ///
  /// The [columns] argument must be a list of as many [DataColumn] objects as
  /// the table is to have columns, ignoring the leading checkbox column if any.
  /// The [columns] argument must have a length greater than zero and cannot be
  /// null.
  ///
  /// If the table is sorted, the column that provides the current primary key
  /// should be specified by index in [sortColumnIndex], 0 meaning the first
  /// column in [columns], 1 being the next one, and so forth.
  ///
  /// The actual sort order can be specified using [sortAscending]; if the sort
  /// order is ascending, this should be true (the default), otherwise it should
  /// be false.
  ///
  /// The [source] must not be null. The [source] should be a long-lived
  /// [DataTableSource]. The same source should be provided each time a
  /// particular [PaginatedDataTable] widget is created; avoid creating a new
  /// [DataTableSource] with each new instance of the [PaginatedDataTable]
  /// widget unless the data table really is to now show entirely different
  /// data from a new source.
  PaginatedDataTable({
    Key key,
    this.columns,
    this.sortColumnIndex,
    this.sortAscending: true,
    this.onSelectAll,
    this.initialFirstRowIndex: 0,
    this.onPageChanged,
    this.rowsPerPage: 10,
    this.onRowsPerPageChanged,
    this.source
  }) : super(key: key) {
    assert(columns != null);
    assert(columns.length > 0);
    assert(sortColumnIndex == null || (sortColumnIndex >= 0 && sortColumnIndex < columns.length));
    assert(sortAscending != null);
    assert(source != null);
  }

  /// The configuration and labels for the columns in the table.
  final List<DataColumn> columns;

  /// The current primary sort key's column.
  ///
  /// See [DataTable.sortColumnIndex].
  final int sortColumnIndex;

  /// Whether the column mentioned in [sortColumnIndex], if any, is sorted
  /// in ascending order.
  ///
  /// See [DataTable.sortAscending].
  final bool sortAscending;

  /// Invoked when the user selects or unselects every row, using the
  /// checkbox in the heading row.
  ///
  /// See [DataTable.onSelectAll].
  final ValueSetter<bool> onSelectAll;

  /// The index of the first row to display when the widget is first created.
  final int initialFirstRowIndex;

  /// Invoked when the user switches to another page.
  final ValueChanged<int> onPageChanged;

  /// The number of rows to show on each page.
  ///
  /// See also [onRowsPerPageChanged].
  final int rowsPerPage;

  /// Invoked when the user selects a different number of rows per page.
  ///
  /// If this is null, then the value given by [rowsPerPage] will be used
  /// and no affordance will be provided to change the value.
  final ValueChanged<int> onRowsPerPageChanged;

  /// The data source which provides data to show in each row. Must be non-null.
  ///
  /// This object should generally have a lifetime longer than the
  /// [PaginatedDataTable] widget itself; it should be reused each time the
  /// [PaginatedDataTable] constructor is called.
  final DataTableSource source;

  @override
  PaginatedDataTableState createState() => new PaginatedDataTableState();
}

/// Holds the state of a [PaginatedDataTable].
///
/// The table can be programmatically paged using the [pageTo] method.
class PaginatedDataTableState extends State<PaginatedDataTable> {
  int _firstRowIndex;
  int _rowCount;
  bool _rowCountApproximate;
  final Map<int, DataRow> _rows = <int, DataRow>{};

  @override
  void initState() {
    super.initState();
    _firstRowIndex = PageStorage.of(context)?.readState(context) ?? config.initialFirstRowIndex ?? 0;
    config.source.addListener(_handleDataSourceChanged);
    _handleDataSourceChanged();
  }

  @override
  void didUpdateConfig(PaginatedDataTable oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (oldConfig.source != config.source) {
      oldConfig.source.removeListener(_handleDataSourceChanged);
      config.source.addListener(_handleDataSourceChanged);
      _handleDataSourceChanged();
    }
  }

  @override
  void dispose() {
    config.source.removeListener(_handleDataSourceChanged);
    super.dispose();
  }

  void _handleDataSourceChanged() {
    setState(() {
      _rowCount = config.source.rowCount;
      _rowCountApproximate = config.source.isRowCountApproximate;
      _rows.clear();
    });
  }

  /// Ensures that the given row is visible.
  void pageTo(double rowIndex) {
    setState(() {
      final int rowsPerPage = config.rowsPerPage;
      _firstRowIndex = (rowIndex ~/ rowsPerPage) * rowsPerPage;
    });
  }

  DataRow _getBlankRowFor(int index) {
    return new DataRow.byIndex(
      index: index,
      cells: config.columns.map/*<DataCell>*/((DataColumn column) => DataCell.empty).toList()
    );
  }

  DataRow _getProgressIndicatorRowFor(int index) {
    bool haveProgressIndicator = false;
    final List<DataCell> cells = config.columns.map/*<DataCell>*/((DataColumn column) {
      if (!column.numeric) {
        haveProgressIndicator = true;
        return new DataCell(new CircularProgressIndicator());
      }
      return DataCell.empty;
    }).toList();
    if (!haveProgressIndicator) {
      haveProgressIndicator = true;
      cells[0] = new DataCell(new CircularProgressIndicator());
    }
    return new DataRow.byIndex(
      index: index,
      cells: cells
    );
  }

  List<DataRow> _getRows(int firstRowIndex, int rowsPerPage) {
    final List<DataRow> result = <DataRow>[];
    final int nextPageFirstRowIndex = firstRowIndex + rowsPerPage;
    bool haveProgressIndicator = false;
    for (int index = firstRowIndex; index < nextPageFirstRowIndex; index += 1) {
      DataRow row;
      if (index < _rowCount || _rowCountApproximate) {
        row = _rows.putIfAbsent(index, () => config.source.getRow(index));
        if (row == null && !haveProgressIndicator) {
          row ??= _getProgressIndicatorRowFor(index);
          haveProgressIndicator = true;
        }
      }
      row ??= _getBlankRowFor(index);
      result.add(row);
    }
    return result;
  }

  final GlobalKey _tableKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    final List<DataRow> rows = _getRows(_firstRowIndex, config.rowsPerPage);
    Widget table = new DataTable(
      key: _tableKey,
      columns: config.columns,
      sortColumnIndex: config.sortColumnIndex,
      sortAscending: config.sortAscending,
      onSelectAll: config.onSelectAll,
      rows: rows
    );
    return new Card(
      // TODO(ianh): data table card headers
      child: table
      // TODO(ianh): data table card footers: prev/next page, rows per page, etc
    );
  }
}

/*

DataTableCard
 - top: 64px
   - caption, top left
      - 20px Roboto Regular, black87
   - persistent actions, top left
   - header when there's a selection
      - accent 50?
      - show number of selected items
      - different actions
   - actions, top right
      - 24px icons, black54

bottom:
 - 56px
 - handles pagination
    - 12px Roboto Regular, black54

*/
