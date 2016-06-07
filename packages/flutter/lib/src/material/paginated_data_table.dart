// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'card.dart';
import 'data_table.dart';
import 'data_table_source.dart';
import 'drop_down.dart';
import 'icon_button.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'icons.dart';
import 'progress_indicator.dart';
import 'theme.dart';

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
  ///
  /// The [rowsPerPage] and [availableRowsPerPage] must not be null (though they
  /// both have defaults, so don't have to be specified).
  PaginatedDataTable({
    Key key,
    this.columns,
    this.sortColumnIndex,
    this.sortAscending: true,
    this.onSelectAll,
    this.initialFirstRowIndex: 0,
    this.onPageChanged,
    this.rowsPerPage: defaultRowsPerPage,
    this.availableRowsPerPage: const <int>[defaultRowsPerPage, defaultRowsPerPage * 2, defaultRowsPerPage * 5, defaultRowsPerPage * 10],
    this.onRowsPerPageChanged,
    this.source
  }) : super(key: key) {
    assert(columns != null);
    assert(columns.length > 0);
    assert(sortColumnIndex == null || (sortColumnIndex >= 0 && sortColumnIndex < columns.length));
    assert(sortAscending != null);
    assert(rowsPerPage != null);
    assert(rowsPerPage > 0);
    assert(availableRowsPerPage != null);
    assert(availableRowsPerPage.contains(rowsPerPage));
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
  ///
  /// The value is the index of the first row on the currently displayed page.
  final ValueChanged<int> onPageChanged;

  /// The number of rows to show on each page.
  ///
  /// See also:
  ///
  /// * [onRowsPerPageChanged]
  /// * [defaultRowsPerPage]
  final int rowsPerPage;

  /// The default value for [rowsPerPage].
  ///
  /// Useful when initializing the field that will hold the current
  /// [rowsPerPage], when implemented [onRowsPerPageChanged].
  static const int defaultRowsPerPage = 10;

  /// The options to offer for the rowsPerPage.
  ///
  /// The current [rowsPerPage] must be a value in this list.
  ///
  /// The values in this list should be sorted in ascending order.
  final List<int> availableRowsPerPage;

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
  void pageTo(int rowIndex) {
    final int oldFirstRowIndex = _firstRowIndex;
    setState(() {
      final int rowsPerPage = config.rowsPerPage;
      _firstRowIndex = (rowIndex ~/ rowsPerPage) * rowsPerPage;
    });
    if ((config.onPageChanged != null) &&
        (oldFirstRowIndex != _firstRowIndex))
      config.onPageChanged(_firstRowIndex);
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
    final TextStyle textStyle = Theme.of(context).textTheme.caption;
    final List<Widget> footerWidgets = <Widget>[];
    if (config.onRowsPerPageChanged != null) {
      List<Widget> availableRowsPerPage = config.availableRowsPerPage
        .where((int value) => value <= _rowCount)
        .map/*<DropDownMenuItem<int>>*/((int value) {
          return new DropDownMenuItem<int>(
            value: value,
            child: new Text('$value')
          );
        })
        .toList();
      footerWidgets.addAll(<Widget>[
        new Text('Rows per page:'),
        new DropDownButtonHideUnderline(
          child: new DropDownButton<int>(
            items: availableRowsPerPage,
            value: config.rowsPerPage,
            onChanged: config.onRowsPerPageChanged,
            style: textStyle,
            iconSize: 24.0
          )
        ),
      ]);
    }
    footerWidgets.addAll(<Widget>[
      new Container(width: 32.0),
      new Text(
        '${_firstRowIndex + 1}\u2013${_firstRowIndex + config.rowsPerPage} ${ _rowCountApproximate ? "of about" : "of" } $_rowCount'
      ),
      new Container(width: 32.0),
      new IconButton(
        padding: EdgeInsets.zero,
        icon: Icons.chevron_left,
        onPressed: _firstRowIndex <= 0 ? null : () {
          pageTo(math.max(_firstRowIndex - config.rowsPerPage, 0));
        }
      ),
      new Container(width: 24.0),
      new IconButton(
        padding: EdgeInsets.zero,
        icon: Icons.chevron_right,
        onPressed: (!_rowCountApproximate && (_firstRowIndex + config.rowsPerPage >= _rowCount)) ? null : () {
          pageTo(_firstRowIndex + config.rowsPerPage);
        }
      ),
      new Container(width: 14.0),
    ]);
    return new Card(
      // TODO(ianh): data table card headers
      /*
         - title, top left
            - 20px Roboto Regular, black87
         - persistent actions, top left
         - header when there's a selection
            - accent 50?
            - show number of selected items
            - different actions
         - actions, top right
            - 24px icons, black54
      */
      child: new BlockBody(
        children: <Widget>[
          new ScrollableViewport(
            scrollDirection: Axis.horizontal,
            child: new DataTable(
              key: _tableKey,
              columns: config.columns,
              sortColumnIndex: config.sortColumnIndex,
              sortAscending: config.sortAscending,
              onSelectAll: config.onSelectAll,
              rows: _getRows(_firstRowIndex, config.rowsPerPage)
            )
          ),
          new DefaultTextStyle(
            style: textStyle,
            child: new IconTheme(
              data: new IconThemeData(
                opacity: 0.54
              ),
              child: new Container(
                height: 56.0,
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: footerWidgets
                )
              )
            )
          )
        ]
      )
    );
  }
}
