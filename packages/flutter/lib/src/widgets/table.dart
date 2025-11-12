// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'scroll_view.dart';
/// @docImport 'sliver.dart';
library;

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'image.dart';

export 'package:flutter/rendering.dart'
    show
        FixedColumnWidth,
        FlexColumnWidth,
        FractionColumnWidth,
        IntrinsicColumnWidth,
        MaxColumnWidth,
        MinColumnWidth,
        TableBorder,
        TableCellVerticalAlignment,
        TableColumnWidth;

/// A horizontal group of cells in a [Table].
///
/// Every row in a table must have the same number of children.
///
/// The alignment of individual cells in a row can be controlled using a
/// [TableCell].
@immutable
class TableRow {
  /// Creates a row in a [Table].
  const TableRow({this.key, this.decoration, this.children = const <Widget>[]});

  /// An identifier for the row.
  final LocalKey? key;

  /// A decoration to paint behind this row.
  ///
  /// Row decorations fill the horizontal and vertical extent of each row in
  /// the table, unlike decorations for individual cells, which might not fill
  /// either.
  final Decoration? decoration;

  /// The widgets that comprise the cells in this row.
  ///
  /// Children may be wrapped in [TableCell] widgets to provide per-cell
  /// configuration to the [Table], but children are not required to be wrapped
  /// in [TableCell] widgets.
  final List<Widget> children;

  @override
  String toString() {
    final StringBuffer result = StringBuffer();
    result.write('TableRow(');
    if (key != null) {
      result.write('$key, ');
    }
    if (decoration != null) {
      result.write('$decoration, ');
    }
    if (children.isEmpty) {
      result.write('no children');
    } else {
      result.write('$children');
    }
    result.write(')');
    return result.toString();
  }
}

class _TableElementRow {
  const _TableElementRow({this.key, required this.children});
  final LocalKey? key;
  final List<Element> children;
}

/// A widget that uses the table layout algorithm for its children.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=_lbE0wsVZSw}
///
/// {@tool dartpad}
/// This sample shows a [Table] with borders, multiple types of column widths
/// and different vertical cell alignments.
///
/// ** See code in examples/api/lib/widgets/table/table.0.dart **
/// {@end-tool}
///
/// If you only have one row, the [Row] widget is more appropriate. If you only
/// have one column, the [SliverList] or [Column] widgets will be more
/// appropriate.
///
/// Rows size vertically based on their contents. To control the individual
/// column widths, use the [columnWidths] property to specify a
/// [TableColumnWidth] for each column. If [columnWidths] is null, or there is a
/// null entry for a given column in [columnWidths], the table uses the
/// [defaultColumnWidth] instead.
///
/// By default, [defaultColumnWidth] is a [FlexColumnWidth]. This
/// [TableColumnWidth] divides up the remaining space in the horizontal axis to
/// determine the column width. If wrapping a [Table] in a horizontal
/// [ScrollView], choose a different [TableColumnWidth], such as
/// [FixedColumnWidth].
///
/// For more details about the table layout algorithm, see [RenderTable].
/// To control the alignment of children, see [TableCell].
///
/// See also:
///
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Table extends RenderObjectWidget {
  /// Creates a table.
  Table({
    super.key,
    this.children = const <TableRow>[],
    this.columnWidths,
    this.defaultColumnWidth = const FlexColumnWidth(),
    this.textDirection,
    this.border,
    this.defaultVerticalAlignment = TableCellVerticalAlignment.top,
    this.textBaseline, // NO DEFAULT: we don't know what the text's baseline should be
  }) : assert(
         defaultVerticalAlignment != TableCellVerticalAlignment.baseline || textBaseline != null,
         'textBaseline is required if you specify the defaultVerticalAlignment with TableCellVerticalAlignment.baseline',
       ),
       assert(() {
         if (children.any(
           (TableRow row1) =>
               row1.key != null &&
               children.any((TableRow row2) => row1 != row2 && row1.key == row2.key),
         )) {
           throw FlutterError(
             'Two or more TableRow children of this Table had the same key.\n'
             'All the keyed TableRow children of a Table must have different Keys.',
           );
         }
         return true;
       }()),
       assert(() {
         if (children.isNotEmpty) {
           final int expectedColumnCount = children.first.children.length;

           // Check if the first row has cells before using it as a reference
           if (expectedColumnCount == 0) {
             throw FlutterError.fromParts(<DiagnosticsNode>[
               ErrorSummary('Empty first TableRow.'),
               ErrorDescription(
                 'The first TableRow in the table has no cells. '
                 'It must contain at least one child widget to define the '
                 "table's column count.",
               ),
             ]);
           }

           for (int y = 0; y < children.length; y++) {
             final TableRow row = children[y];
             final List<Widget> cellList = row.children;
             final int cellCount = cellList.length;

             // Check if this row has the correct number of cells
             if (cellCount != expectedColumnCount) {
               throw FlutterError.fromParts(<DiagnosticsNode>[
                 ErrorSummary('Inconsistent number of table cells.'),
                 ErrorDescription(
                   'Row $y contains $cellCount cells, but each row in this table '
                   'must contain exactly $expectedColumnCount, like the first row.',
                 ),
                 ErrorHint(
                   'When using colSpan or rowSpan, every TableRow must still '
                   'define the same total number of cells (including placeholder '
                   'cells such as TableCell.none) to ensure a consistent table grid.',
                 ),
                 ErrorDescription(
                   'For example, if one cell spans 3 columns, you must still include '
                   'two TableCell.none placeholders to fill the remaining column slots in that row.',
                 ),
               ]);
             }
           }
         }
         return true;
       }()),
       _rowDecorations = children.any((TableRow row) => row.decoration != null)
           ? children.map<Decoration?>((TableRow row) => row.decoration).toList(growable: false)
           : null {
    assert(() {
      final List<Widget> flatChildren = children
          .expand<Widget>((TableRow row) => row.children)
          .toList(growable: false);
      return !debugChildrenHaveDuplicateKeys(
        this,
        flatChildren,
        message:
            'Two or more cells in this Table contain widgets with the same key.\n'
            'Every widget child of every TableRow in a Table must have different keys. The cells of a Table are '
            'flattened out for processing, so separate cells cannot have duplicate keys even if they are in '
            'different rows.',
      );
    }());
  }

  /// The rows of the table.
  ///
  /// Every row in a table must have the same number of children.
  final List<TableRow> children;

  /// How the horizontal extents of the columns of this table should be determined.
  ///
  /// If the [Map] has a null entry for a given column, the table uses the
  /// [defaultColumnWidth] instead. By default, that uses flex sizing to
  /// distribute free space equally among the columns.
  ///
  /// The [FixedColumnWidth] class can be used to specify a specific width in
  /// pixels. That is the cheapest way to size a table's columns.
  ///
  /// The layout performance of the table depends critically on which column
  /// sizing algorithms are used here. In particular, [IntrinsicColumnWidth] is
  /// quite expensive because it needs to measure each cell in the column to
  /// determine the intrinsic size of the column.
  ///
  /// The keys of this map (column indexes) are zero-based.
  ///
  /// If this is set to null, then an empty map is assumed.
  final Map<int, TableColumnWidth>? columnWidths;

  /// How to determine with widths of columns that don't have an explicit sizing
  /// algorithm.
  ///
  /// Specifically, the [defaultColumnWidth] is used for column `i` if
  /// `columnWidths[i]` is null. Defaults to [FlexColumnWidth], which will
  /// divide the remaining horizontal space up evenly between columns of the
  /// same type [TableColumnWidth].
  ///
  /// A [Table] in a horizontal [ScrollView] must use a [FixedColumnWidth], or
  /// an [IntrinsicColumnWidth] as the horizontal space is infinite.
  final TableColumnWidth defaultColumnWidth;

  /// The direction in which the columns are ordered.
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// The style to use when painting the boundary and interior divisions of the table.
  final TableBorder? border;

  /// How cells that do not explicitly specify a vertical alignment are aligned vertically.
  ///
  /// Cells may specify a vertical alignment by wrapping their contents in a
  /// [TableCell] widget.
  final TableCellVerticalAlignment defaultVerticalAlignment;

  /// The text baseline to use when aligning rows using [TableCellVerticalAlignment.baseline].
  ///
  /// This must be set if using baseline alignment. There is no default because there is no
  /// way for the framework to know the correct baseline _a priori_.
  final TextBaseline? textBaseline;

  final List<Decoration?>? _rowDecorations;

  @override
  RenderObjectElement createElement() => _TableElement(this);

  @override
  RenderTable createRenderObject(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return RenderTable(
      columns: children.isNotEmpty ? children[0].children.length : 0,
      rows: children.length,
      columnWidths: columnWidths,
      defaultColumnWidth: defaultColumnWidth,
      textDirection: textDirection ?? Directionality.of(context),
      border: border,
      rowDecorations: _rowDecorations,
      configuration: createLocalImageConfiguration(context),
      defaultVerticalAlignment: defaultVerticalAlignment,
      textBaseline: textBaseline,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTable renderObject) {
    assert(debugCheckHasDirectionality(context));
    assert(renderObject.columns == (children.isNotEmpty ? children[0].children.length : 0));
    assert(renderObject.rows == children.length);
    renderObject
      ..columnWidths = columnWidths
      ..defaultColumnWidth = defaultColumnWidth
      ..textDirection = textDirection ?? Directionality.of(context)
      ..border = border
      ..rowDecorations = _rowDecorations
      ..configuration = createLocalImageConfiguration(context)
      ..defaultVerticalAlignment = defaultVerticalAlignment
      ..textBaseline = textBaseline;
  }
}

class _TableElement extends RenderObjectElement {
  _TableElement(Table super.widget);

  @override
  RenderTable get renderObject => super.renderObject as RenderTable;

  List<_TableElementRow> _children = const <_TableElementRow>[];

  bool _doingMountOrUpdate = false;

  @override
  void mount(Element? parent, Object? newSlot) {
    assert(!_doingMountOrUpdate);
    _doingMountOrUpdate = true;
    super.mount(parent, newSlot);
    int rowIndex = -1;
    _children = (widget as Table).children
        .map<_TableElementRow>((TableRow row) {
          int columnIndex = 0;
          rowIndex += 1;
          return _TableElementRow(
            key: row.key,
            children: row.children
                .map<Element>((Widget child) {
                  return inflateWidget(child, _TableSlot(columnIndex++, rowIndex));
                })
                .toList(growable: false),
          );
        })
        .toList(growable: false);
    _updateRenderObjectChildren();
    assert(_doingMountOrUpdate);
    _doingMountOrUpdate = false;
  }

  @override
  void insertRenderObjectChild(RenderBox child, _TableSlot slot) {
    renderObject.setupParentData(child);
    // Once [mount]/[update] are done, the children are getting set all at once
    // in [_updateRenderObjectChildren].
    if (!_doingMountOrUpdate) {
      renderObject.setChild(slot.column, slot.row, child);
    }
  }

  @override
  void moveRenderObjectChild(RenderBox child, _TableSlot oldSlot, _TableSlot newSlot) {
    assert(_doingMountOrUpdate);
    // Child gets moved at the end of [update] in [_updateRenderObjectChildren].
  }

  @override
  void removeRenderObjectChild(RenderBox child, _TableSlot slot) {
    renderObject.setChild(slot.column, slot.row, null);
  }

  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void update(Table newWidget) {
    assert(!_doingMountOrUpdate);
    _doingMountOrUpdate = true;
    final Map<LocalKey, List<Element>> oldKeyedRows = <LocalKey, List<Element>>{};
    for (final _TableElementRow row in _children) {
      if (row.key != null) {
        oldKeyedRows[row.key!] = row.children;
      }
    }
    final Iterator<_TableElementRow> oldUnkeyedRows = _children
        .where((_TableElementRow row) => row.key == null)
        .iterator;
    final List<_TableElementRow> newChildren = <_TableElementRow>[];
    final Set<List<Element>> taken = <List<Element>>{};
    for (int rowIndex = 0; rowIndex < newWidget.children.length; rowIndex++) {
      final TableRow row = newWidget.children[rowIndex];
      List<Element> oldChildren;
      if (row.key != null && oldKeyedRows.containsKey(row.key)) {
        oldChildren = oldKeyedRows[row.key]!;
        taken.add(oldChildren);
      } else if (row.key == null && oldUnkeyedRows.moveNext()) {
        oldChildren = oldUnkeyedRows.current.children;
      } else {
        oldChildren = const <Element>[];
      }
      final List<_TableSlot> slots = List<_TableSlot>.generate(
        row.children.length,
        (int columnIndex) => _TableSlot(columnIndex, rowIndex),
      );
      newChildren.add(
        _TableElementRow(
          key: row.key,
          children: updateChildren(
            oldChildren,
            row.children,
            forgottenChildren: _forgottenChildren,
            slots: slots,
          ),
        ),
      );
    }
    while (oldUnkeyedRows.moveNext()) {
      updateChildren(
        oldUnkeyedRows.current.children,
        const <Widget>[],
        forgottenChildren: _forgottenChildren,
      );
    }
    for (final List<Element> oldChildren in oldKeyedRows.values.where(
      (List<Element> list) => !taken.contains(list),
    )) {
      updateChildren(oldChildren, const <Widget>[], forgottenChildren: _forgottenChildren);
    }

    _children = newChildren;
    _updateRenderObjectChildren();
    _forgottenChildren.clear();
    super.update(newWidget);
    assert(widget == newWidget);
    assert(_doingMountOrUpdate);
    _doingMountOrUpdate = false;
  }

  void _updateRenderObjectChildren() {
    renderObject.setFlatChildren(
      _children.isNotEmpty ? _children[0].children.length : 0,
      _children.expand<RenderBox>((_TableElementRow row) {
        return row.children.map<RenderBox>((Element child) {
          final RenderBox box = child.renderObject! as RenderBox;
          return box;
        });
      }).toList(),
    );
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final Element child in _children.expand<Element>((_TableElementRow row) => row.children)) {
      if (!_forgottenChildren.contains(child)) {
        visitor(child);
      }
    }
  }

  @override
  bool forgetChild(Element child) {
    _forgottenChildren.add(child);
    super.forgetChild(child);
    return true;
  }
}

/// A widget that controls how a child of a [Table] is aligned.
///
/// A [TableCell] widget must be a descendant of a [Table], and the path from
/// the [TableCell] widget to its enclosing [Table] must contain only
/// [TableRow]s, [StatelessWidget]s, or [StatefulWidget]s (not
/// other kinds of widgets, like [RenderObjectWidget]s).
///
/// To create an empty [TableCell], provide a [SizedBox.shrink]
/// as the [child].
class TableCell extends StatelessWidget {
  /// Creates a widget that controls how a child of a [Table] is aligned.
  const TableCell({
    super.key,
    this.colSpan = 1,
    this.rowSpan = 1,
    this.verticalAlignment,
    required this.child,
  }) : assert(colSpan >= 1, 'The colSpan of a TableCell must be at least 1.'),
       assert(rowSpan >= 1, 'The rowSpan of a TableCell must be at least 1.');

  /// Internal constructor used for [TableCell.none].
  const TableCell._none()
    : colSpan = 0,
      rowSpan = 0,
      verticalAlignment = null,
      child = const SizedBox.shrink();

  /// {@template flutter.widgets.table.none}
  /// A table cell that acts as a structural placeholder to preserve the
  /// table’s grid alignment.
  ///
  /// This cell must be used in positions covered by another cell’s [colSpan]
  /// or [rowSpan] to make the table’s structure explicit and maintain a
  /// consistent layout across all rows and columns.
  /// {@endtemplate}
  static const TableCell none = TableCell._none();

  /// How this cell is aligned vertically.
  final TableCellVerticalAlignment? verticalAlignment;

  /// The number of columns this cell should span.
  ///
  /// The value represents the number of columns the cell will extend to cover,
  /// defaults to 1.
  ///
  /// When a cell spans multiple columns, you must follow with
  /// the corresponding number of [TableCell.none] in the same row to fill the
  /// remaining covered columns and maintain the table’s grid structure.
  final int colSpan;

  /// The number of rows this cell should span.
  ///
  /// The value represents the number of rows the cell will extend to cover,
  /// defaults to 1.
  ///
  /// When a cell spans multiple rows, you must follow with
  /// the corresponding number of [TableCell.none] in the following [TableRow]s
  /// to preserve consistent table alignment.
  final int rowSpan;

  /// The child of this cell.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _TableCell(
      colSpan: colSpan,
      rowSpan: rowSpan,
      verticalAlignment: verticalAlignment,
      child: Semantics(role: SemanticsRole.cell, child: child),
    );
  }
}

class _TableCell extends ParentDataWidget<TableCellParentData> {
  const _TableCell({
    this.verticalAlignment,
    required this.colSpan,
    required this.rowSpan,
    required super.child,
  });
  final TableCellVerticalAlignment? verticalAlignment;

  final int colSpan;
  final int rowSpan;

  @override
  void applyParentData(RenderObject renderObject) {
    final TableCellParentData parentData = renderObject.parentData! as TableCellParentData;
    bool needsLayout = false;

    if (parentData.verticalAlignment != verticalAlignment) {
      parentData.verticalAlignment = verticalAlignment;
      needsLayout = true;
    }
    if (parentData.colSpan != colSpan) {
      parentData.colSpan = colSpan;
      needsLayout = true;
    }
    if (parentData.rowSpan != rowSpan) {
      parentData.rowSpan = rowSpan;
      needsLayout = true;
    }

    if (needsLayout) {
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => Table;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<TableCellVerticalAlignment>('verticalAlignment', verticalAlignment))
      ..add(IntProperty('colSpan', colSpan))
      ..add(IntProperty('rowSpan', rowSpan));
  }
}

@immutable
class _TableSlot with Diagnosticable {
  const _TableSlot(this.column, this.row);

  final int column;
  final int row;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _TableSlot && column == other.column && row == other.row;
  }

  @override
  int get hashCode => Object.hash(column, row);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('x', column));
    properties.add(IntProperty('y', row));
  }
}
