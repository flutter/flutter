// Copyright 2018 the Dart project authors.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

const String title = 'VisibilityDetector Demo';

/// The width of each cell of our pseudo-table of [VisibilityDetector] widgets.
const double cellWidth = 125;

//// The height of each cell of our pseudo-table.
const double cellHeight = 65;

/// The external padding around the primary row/column of the pseudo-table.
const double externalCellPadding = 5;

/// The internal padding for each cell of the pseudo-table.
const double _cellPadding = 10;

/// The external padding around the widgets in the visibility report section.
const double _reportPadding = 5;

/// The height of the visibility report.
const double _reportHeight = 200;

/// The [Key] to the main [ListView] widget.
const mainListKey = Key('MainList');

const scaleButtonKey = Key('scaleButton');

Key secondaryScrollableKey(int primaryIndex) =>
    ValueKey('secondary-$primaryIndex');

/// Returns the [Key] to the [VisibilityDetector] widget in each cell of the
/// pseudo-table.
Key cellKey(int row, int col) => Key('Cell-$row-$col');

/// Returns the [Key] to the content of the cell.
Key cellContentKey(int row, int col) => Key('Content-$row-$col');

/// A callback to be invoked by the [VisibilityDetector.onVisibilityChanged]
/// callback.  We use the extra level of indirection to allow widget tests to
/// reuse this demo app with a different callback.
final visibilityListeners =
    <void Function(RowColumn rc, VisibilityInfo info)>[];

void main() => runApp(const VisibilityDetectorDemo());

/// Axis and growth direction of the table.
class Layout {
  const Layout(this.mainAxis, this.secondaryAxis, {this.reverse = false});

  final Axis mainAxis;
  final Axis secondaryAxis;

  /// Reverse direction of the secondary axis.
  final bool reverse;
}

/// The root widget for the demo app.
class VisibilityDetectorDemo extends StatelessWidget {
  const VisibilityDetectorDemo({Key? key, this.useSlivers = false})
      : super(key: key);

  final bool useSlivers;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: VisibilityDetectorDemoPage(key: key, useSlivers: useSlivers),
    );
  }
}

/// The main page [VisibilityDetectorDemo].
class VisibilityDetectorDemoPage extends StatefulWidget {
  VisibilityDetectorDemoPage({Key? key, this.useSlivers = false})
      : super(key: key);

  final bool useSlivers;

  @override
  VisibilityDetectorDemoPageState createState() =>
      VisibilityDetectorDemoPageState();
}

class VisibilityDetectorDemoPageState
    extends State<VisibilityDetectorDemoPage> {
  VisibilityDetectorDemoPageState();

  var _layoutIndex = 0;

  /// Whether the pseudo-table should be shown.
  bool _tableShown = true;

  /// Whether to use slivers.
  bool _useSlivers = false;

  bool _useScale = false;

  /// The four layouts, that can be changed via pressing the Layout button.
  static const _layouts = [
    Layout(Axis.vertical, Axis.horizontal, reverse: false),
    Layout(Axis.vertical, Axis.horizontal, reverse: true),
    Layout(Axis.horizontal, Axis.vertical, reverse: false),
    Layout(Axis.horizontal, Axis.vertical, reverse: true),
  ];

  Layout get _layout => _layouts[_layoutIndex];

  @override
  void initState() {
    super.initState();
    _useSlivers = widget.useSlivers;
  }

  /// Toggles the visibility of the pseudo-table of [VisibilityDetector]
  /// widgets.
  void _toggleTable() {
    setState(() {
      _tableShown = !_tableShown;
    });
  }

  /// Toggles the visibility of the pseudo-table of [VisibilityDetector]
  /// widgets.
  void _toggleScale() {
    setState(() {
      _useScale = !_useScale;
    });
  }

  /// Toggles between the layouts.
  void _toggleLayout() {
    setState(() {
      _layoutIndex = (_layoutIndex + 1) % _layouts.length;
    });
  }

  /// Toggles between RenderBox and RenderSliver widgets.
  void _toggleSlivers() {
    setState(() {
      _useSlivers = !_useSlivers;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Our pseudo-table of [VisibilityDetector] widgets.  We want to scroll both
    // vertically and horizontally, so we'll implement it as a [ListView] of
    // [ListView]s.
    final table = !_tableShown
        ? null
        : ClipRect(
            child: Container(
              width: _useScale ? 400 : null,
              height: _useScale ? 300 : null,
              child: ListView.builder(
                key: mainListKey,
                scrollDirection: _layout.mainAxis,
                itemExtent: (_layout.mainAxis == Axis.vertical
                        ? cellHeight
                        : cellWidth) +
                    2 * externalCellPadding,
                itemBuilder: (BuildContext context, int primaryIndex) {
                  return _useSlivers
                      ? SliverDemoPageSecondaryAxis(
                          key: secondaryScrollableKey(primaryIndex),
                          primaryIndex: primaryIndex,
                          secondaryAxis: _layout.secondaryAxis,
                          reverse: _layout.reverse,
                          useScale: _useScale,
                        )
                      : DemoPageSecondaryAxis(
                          key: secondaryScrollableKey(primaryIndex),
                          primaryIndex: primaryIndex,
                          secondaryAxis: _layout.secondaryAxis,
                          reverse: _layout.reverse,
                          useScale: _useScale,
                        );
                },
              ),
            ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            shape: const Border(),
            onPressed: _toggleLayout,
            heroTag: null,
            child: Text('Layout'),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            shape: const Border(),
            onPressed: _toggleSlivers,
            heroTag: null,
            child: _useSlivers
                ? const Text('RenderBox')
                : const Text('RenderSliver'),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            shape: const Border(),
            onPressed: _toggleTable,
            heroTag: null,
            child: _tableShown ? const Text('Hide') : const Text('Show'),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            key: scaleButtonKey,
            shape: const Border(),
            onPressed: _toggleScale,
            heroTag: null,
            child: _useScale ? const Text('Scale') : const Text('No scaling'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _tableShown ? Expanded(child: table!) : const Spacer(),
          VisibilityReport(
              title:
                  'Visibility (${_useSlivers ? "RenderSliver" : "RenderBox"})'),
        ],
      ),
    );
  }
}

/// A secondary axis for the pseudo-table of [VisibilityDetector] widgets.
class DemoPageSecondaryAxis extends StatelessWidget {
  const DemoPageSecondaryAxis({
    Key? key,
    required this.primaryIndex,
    required this.secondaryAxis,
    required this.reverse,
    required this.useScale,
  }) : super(key: key);

  final Axis secondaryAxis;
  final int primaryIndex;
  final bool reverse;
  final bool useScale;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: secondaryAxis,
      reverse: reverse,
      padding: const EdgeInsets.all(externalCellPadding),
      itemBuilder: (BuildContext context, int secondaryIndex) {
        return DemoPageCell(
          primaryIndex: primaryIndex,
          secondaryIndex: secondaryIndex,
          useSlivers: false,
          useScale: useScale,
        );
      },
    );
  }
}

/// A Secondary axis using sliver cell widgets.
class SliverDemoPageSecondaryAxis extends StatelessWidget {
  const SliverDemoPageSecondaryAxis({
    Key? key,
    required this.primaryIndex,
    required this.secondaryAxis,
    required this.reverse,
    required this.useScale,
  }) : super(key: key);

  final Axis secondaryAxis;
  final int primaryIndex;
  final bool reverse;
  final bool useScale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: secondaryAxis == Axis.horizontal
          ? const EdgeInsets.symmetric(vertical: externalCellPadding)
          : const EdgeInsets.symmetric(horizontal: externalCellPadding),
      child: CustomScrollView(
        scrollDirection: secondaryAxis,
        reverse: reverse,
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              width: externalCellPadding,
              height: externalCellPadding,
            ),
          ),
          // Sliver version renders up to 20 columns.
          for (var secondaryIndex = 0; secondaryIndex < 20; secondaryIndex++)
            DemoPageCell(
              primaryIndex: primaryIndex,
              secondaryIndex: secondaryIndex,
              useSlivers: true,
              useScale: useScale,
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              width: externalCellPadding,
              height: externalCellPadding,
            ),
          ),
        ],
      ),
    );
  }
}

/// An individual cell for the pseudo-table of [VisibilityDetector] widgets.
class DemoPageCell extends StatelessWidget {
  DemoPageCell({
    Key? key,
    required this.primaryIndex,
    required this.secondaryIndex,
    required this.useSlivers,
    required this.useScale,
  })  : _cellName = 'Item $primaryIndex-$secondaryIndex',
        _backgroundColor = ((primaryIndex + secondaryIndex) % 2 == 0)
            ? Colors.pink[200]
            : Colors.yellow[200],
        super(key: key);

  final int primaryIndex;
  final int secondaryIndex;
  final bool useSlivers;
  final bool useScale;

  /// The text to show for the cell.
  final String _cellName;

  final Color? _backgroundColor;

  /// [VisibilityDetector] callback for when the visibility of the widget
  /// changes.  Triggers the [visibilityListeners] callbacks.
  void _handleVisibilityChanged(VisibilityInfo info) {
    for (final listener in visibilityListeners) {
      listener(RowColumn(primaryIndex, secondaryIndex), info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cell = Container(
      key: cellContentKey(primaryIndex, secondaryIndex),
      width: cellWidth,
      decoration: BoxDecoration(color: _backgroundColor),
      padding: const EdgeInsets.all(_cellPadding),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(_cellName, style: Theme.of(context).textTheme.headline4),
      ),
    );

    if (useSlivers) {
      return SliverVisibilityDetector(
        key: cellKey(primaryIndex, secondaryIndex),
        onVisibilityChanged: _handleVisibilityChanged,
        sliver: SliverToBoxAdapter(child: cell),
      );
    }

    var visibilityDetector = VisibilityDetector(
      key: cellKey(primaryIndex, secondaryIndex),
      onVisibilityChanged: _handleVisibilityChanged,
      child: cell,
    );

    if (useScale) {
      return Transform.scale(
        scale: 0.25,
        child: Padding(
          padding: const EdgeInsets.only(left: 100),
          child: visibilityDetector,
        ),
      );
    } else {
      return visibilityDetector;
    }
  }
}

/// A widget that lists the reported visibility percentages of the
/// [VisibilityDetector] widgets on the page.
class VisibilityReport extends StatelessWidget {
  const VisibilityReport({Key? key, required this.title}) : super(key: key);

  /// The text to use for the heading of the report.
  final String title;

  @override
  Widget build(BuildContext context) {
    final headingTextStyle =
        Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white);

    final heading = Container(
      padding: const EdgeInsets.all(_reportPadding),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(color: Colors.black),
      child: Text(title, style: headingTextStyle),
    );

    final grid = Container(
      padding: const EdgeInsets.all(_reportPadding),
      decoration: BoxDecoration(color: Colors.grey[300]),
      child: const SizedBox(
        height: _reportHeight,
        child: VisibilityReportGrid(),
      ),
    );

    return Column(children: <Widget>[heading, grid]);
  }
}

/// The portion of [VisibilityReport] that shows data.
class VisibilityReportGrid extends StatefulWidget {
  const VisibilityReportGrid({Key? key}) : super(key: key);

  @override
  VisibilityReportGridState createState() => VisibilityReportGridState();
}

class VisibilityReportGridState extends State<VisibilityReportGrid> {
  /// Maps [row, column] indices to the visibility percentage of the
  /// corresponding [VisibilityDetector] widget.
  final _visibilities = SplayTreeMap<RowColumn, double>();

  /// The [Text] widgets used to fill our [GridView].
  List<Text>? _reportItems;

  /// See [State.initState].  Adds a callback to [visibilityListeners] to update
  /// the visibility report with the widget's visibility.
  @override
  void initState() {
    super.initState();

    visibilityListeners.add(_update);
    assert(visibilityListeners.contains(_update));
  }

  @override
  void dispose() {
    visibilityListeners.remove(_update);

    super.dispose();
  }

  /// Callback added to [visibilityListeners] to update the state.
  void _update(RowColumn rc, VisibilityInfo info) {
    setState(() {
      if (info.visibleFraction == 0) {
        _visibilities.remove(rc);
      } else {
        _visibilities[rc] = info.visibleFraction;
      }

      // Invalidate `_reportItems` so that we regenerate it lazily.
      _reportItems = null;
    });
  }

  /// Populates [_reportItems].
  List<Text> _generateReportItems() {
    final entries = _visibilities.entries;
    final items = <Text>[];

    for (final i in entries) {
      final visiblePercentage = (i.value * 100).toStringAsFixed(1);
      items.add(Text('${i.key}: $visiblePercentage%'));
    }

    // It's easier to read cells down than across, so sort by columns instead of
    // by rows.
    final tailIndex = items.length - items.length ~/ 3;
    final midIndex = tailIndex - tailIndex ~/ 2;
    final head = items.getRange(0, midIndex);
    final mid = items.getRange(midIndex, tailIndex);
    final tail = items.getRange(tailIndex, items.length);
    return collate([head, mid, tail]).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    _reportItems ??= _generateReportItems();

    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 8,
      padding: const EdgeInsets.all(5),
      children: _reportItems!,
    );
  }
}

/// A class for storing a [row, column] pair.
class RowColumn extends Comparable<RowColumn> {
  RowColumn(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(dynamic other) {
    if (other is RowColumn) {
      return row == other.row && column == other.column;
    }
    return false;
  }

  @override
  int get hashCode => hashValues(row, column);

  /// See [Comparable.compareTo].  Sorts [RowColumn] objects in row-major order.
  @override
  int compareTo(RowColumn other) {
    if (row < other.row) {
      return -1;
    } else if (row > other.row) {
      return 1;
    }

    if (column < other.column) {
      return -1;
    } else if (column > other.column) {
      return 1;
    }

    return 0;
  }

  @override
  String toString() {
    return '[$row, $column]';
  }
}

/// Returns an [Iterable] containing the nth element (if it exists) of every
/// [Iterable] in `iterables` in sequence.
///
/// Unlike [zip](https://pub.dev/documentation/quiver/latest/quiver.iterables/zip.html),
/// returns a single sequence and continues until *all* [Iterable]s are
/// exhausted.
///
/// For example, `collate([[1, 4, 7], [2, 5, 8, 9], [3, 6]])` would return a
/// sequence `1, 2, 3, 4, 5, 6, 7, 8, 9`.
@visibleForTesting
Iterable<T> collate<T>(Iterable<Iterable<T>> iterables) sync* {
  final iterators = [for (final iterable in iterables) iterable.iterator];
  if (iterators.isEmpty) {
    return;
  }

  while (true) {
    var exhaustedCount = 0;
    for (final i in iterators) {
      if (i.moveNext()) {
        yield i.current;
        continue;
      }

      exhaustedCount += 1;
      if (exhaustedCount == iterators.length) {
        // All iterators are at their ends.
        return;
      }
    }
  }
}
