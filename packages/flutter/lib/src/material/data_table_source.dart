// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'paginated_data_table.dart';
library;

import 'package:flutter/foundation.dart';
import 'data_table.dart';

/// A data source for obtaining row data for [PaginatedDataTable] objects.
///
/// A data table source provides two main pieces of information:
///
/// * The number of rows in the data table ([rowCount]).
/// * The data for each row (indexed from `0` to `rowCount - 1`).
///
/// It also provides a listener API ([addListener]/[removeListener]) so that
/// consumers of the data can be notified when it changes. When the data
/// changes, call [notifyListeners] to send the notifications.
///
/// DataTableSource objects are expected to be long-lived, not recreated with
/// each build.
///
/// If a [DataTableSource] is used with a [PaginatedDataTable] that supports
/// sortable columns (see [DataColumn.onSort] and
/// [PaginatedDataTable.sortColumnIndex]), the rows reported by the data source
/// must be reported in the sorted order.
abstract class DataTableSource extends ChangeNotifier {
  /// Called to obtain the data about a particular row.
  ///
  /// Rows should be keyed so that state can be maintained when the data source
  /// is sorted (e.g. in response to [DataColumn.onSort]). Keys should be
  /// consistent for a given [DataRow] regardless of the sort order (i.e. the
  /// key represents the data's identity, not the row position).
  ///
  /// The [DataRow.byIndex] constructor provides a convenient way to construct
  /// [DataRow] objects for this method's purposes without having to worry about
  /// independently keying each row. The index passed to that constructor is the
  /// index of the underlying data, which is different than the `index`
  /// parameter for [getRow], which represents the _sorted_ position.
  ///
  /// If the given index does not correspond to a row, or if no data is yet
  /// available for a row, then return null. The row will be left blank and a
  /// loading indicator will be displayed over the table. Once data is available
  /// or once it is firmly established that the row index in question is beyond
  /// the end of the table, call [notifyListeners]. (See [rowCount].)
  ///
  /// If the underlying data changes, call [notifyListeners].
  DataRow? getRow(int index);

  /// Called to obtain the number of rows to tell the user are available.
  ///
  /// If [isRowCountApproximate] is false, then this must be an accurate number,
  /// and [getRow] must return a non-null value for all indices in the range 0
  /// to one less than the row count.
  ///
  /// If [isRowCountApproximate] is true, then the user will be allowed to
  /// attempt to display rows up to this [rowCount], and the display will
  /// indicate that the count is approximate. The row count should therefore be
  /// greater than the actual number of rows if at all possible.
  ///
  /// If the row count changes, call [notifyListeners].
  int get rowCount;

  /// Called to establish if [rowCount] is a precise number or might be an
  /// over-estimate. If this returns true (i.e. the count is approximate), and
  /// then later the exact number becomes available, then call
  /// [notifyListeners].
  bool get isRowCountApproximate;

  /// Called to obtain the number of rows that are currently selected.
  ///
  /// If the selected row count changes, call [notifyListeners].
  ///
  /// Selected rows are those whose [DataRow.selected] property is set to true.
  int get selectedRowCount;
}
