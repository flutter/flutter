// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// This example shows a set of widgets for changing data fields arranged in a column
/// of rows but, in accessibility mode, are traversed in a custom order.
///
/// This demonstrates how Flutter's accessibility system describes custom traversal
/// orders using sort keys.
///
/// The example app here has three fields that have a title and up/down spinner buttons
/// above and below. The traversal order should allow the user to focus on each
/// title, the input field next, the up spinner next, and the down spinner last before
/// moving to the next input title.
///
/// Users that do not use a screen reader (e.g. TalkBack on Android and VoiceOver on iOS)
/// will just see a regular app with controls.
///
/// The example's [RowColumnTraversal] widget sets up two [Semantics] objects that wrap the
/// given [Widget] child, providing the traversal order they should have in the "row"
/// direction, and then the traversal order they should have in the "column" direction.
///
/// Sort keys, by default, are appended to the sort orders for their parents, but
/// they can also override those of their parents (by setting
/// [SemanticsSortOrder.discardParentOrder] to true), and an entire sort order can be
/// defined with multiple keys, to provide for virtually any ordering.
///
/// Keys at the same position in the sort order are compared with each other, and
/// keys which are of different types, or which have different [SemanticSortKey.name]
/// values compare as "equal" so that two different types of keys can co-exist at the
/// same level and not interfere with each other, allowing for sorting in groups.
/// Keys that evaluate as equal, or when compared with Widgets that don't have
/// [Semantics], are given the default upper-start-to-lower-end geometric
/// ordering.
///
/// Since widgets are globally sorted by their sort key, the order does not have
/// to conform to the widget hierarchy. Indeed, in this example, we traverse vertically
/// first, but the widget hierarchy is a column of rows.
///
/// See also:
///
///  * [Semantics] for an object that annotates widgets with accessibility semantics
///    (including traversal order).
///  * [SemanticSortOrder] for the class that manages the sort order of a semantic node.
///  * [SemanticSortKey] for the base class of all semantic sort keys.
///  * [OrdinalSortKey] for a concrete sort key that sorts based on the given ordinal.
class RowColumnTraversal extends StatelessWidget {
  const RowColumnTraversal({this.rowOrder, this.columnOrder, this.child});

  final int rowOrder;
  final int columnOrder;
  final Widget child;

  /// Builds a widget hierarchy that wraps [child].
  ///
  /// This function expresses the sort keys as a hierarchy, but it could just as
  /// easily have been a flat list:
  ///
  /// ```
  ///  Widget build(BuildContext context) {
  ///    return new Semantics(
  ///      sortOrder: new SemanticsSortOrder(
  ///        keys: <SemanticsSortKey>[
  ///          new OrdinalSortKey(columnOrder.toDouble()),
  ///          new OrdinalSortKey(rowOrder.toDouble())
  ///        ],
  ///      ),
  ///      child: child,
  ///    );
  ///  }
  /// ```
  ///
  /// The resulting order is the same.
  @override
  Widget build(BuildContext context) {
    return Semantics(
      sortKey: OrdinalSortKey(columnOrder.toDouble()),
      child: Semantics(
        sortKey: OrdinalSortKey(rowOrder.toDouble()),
        child: child,
      ),
    );
  }
}

// --------------- Component widgets ---------------------

/// A Button class that wraps an [IconButton] with a [RowColumnTraversal] to
/// set its traversal order.
class SpinnerButton extends StatelessWidget {
  const SpinnerButton(
      {Key key,
      this.onPressed,
      this.icon,
      this.rowOrder,
      this.columnOrder,
      this.field,
      this.increment}) : super(key: key);

  final VoidCallback onPressed;
  final IconData icon;
  final int rowOrder;
  final int columnOrder;
  final Field field;
  final bool increment;

  @override
  Widget build(BuildContext context) {
    final String label = '${increment ? 'Increment' : 'Decrement'} ${_fieldToName(field)}';

    return RowColumnTraversal(
      rowOrder: rowOrder,
      columnOrder: columnOrder,
      child: Center(
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          tooltip: label,
        ),
      ),
    );
  }
}

/// A text entry field that wraps a [TextField] with a [RowColumnTraversal] to
/// set its traversal order.
class FieldWidget extends StatelessWidget {
  const FieldWidget({
    Key key,
    this.rowOrder,
    this.columnOrder,
    this.onIncrease,
    this.onDecrease,
    this.value,
    this.field,
  }) : super(key: key);

  final int rowOrder;
  final int columnOrder;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final int value;
  final Field field;

  @override
  Widget build(BuildContext context) {
    final String stringValue = '${_fieldToName(field)} $value';
    final String increasedValue = '${_fieldToName(field)} ${value + 1}';
    final String decreasedValue = '${_fieldToName(field)} ${value - 1}';

    return RowColumnTraversal(
      rowOrder: rowOrder,
      columnOrder: columnOrder,
      child: Center(
        child: Semantics(
          onDecrease: onDecrease,
          onIncrease: onIncrease,
          value: stringValue,
          increasedValue: increasedValue,
          decreasedValue: decreasedValue,
          child: ExcludeSemantics(child: Text(value.toString())),
        ),
      ),
    );
  }
}

// --------------- Field manipulation functions ---------------------

/// An enum that describes which column we're referring to.
enum Field { DOGS, CATS, FISH }

String _fieldToName(Field field) {
  switch (field) {
    case Field.DOGS:
      return 'Dogs';
    case Field.CATS:
      return 'Cats';
    case Field.FISH:
      return 'Fish';
  }
  return null;
}

// --------------- Main app ---------------------

/// The top-level example widget that serves as the body of the app.
class CustomTraversalExample extends StatefulWidget {
  @override
  CustomTraversalExampleState createState() => CustomTraversalExampleState();
}

/// The state object for the top level example widget.
class CustomTraversalExampleState extends State<CustomTraversalExample> {
  /// The fields that we are manipulating. List indices correspond to
  /// the entries in the [Field] enum.
  List<int> fields = <int>[0, 0, 0];

  void _addToField(Field field, int delta) {
    setState(() {
      fields[field.index] += delta;
    });
  }

  Widget _makeFieldHeader(int rowOrder, int columnOrder, Field field) {
    return RowColumnTraversal(
      rowOrder: rowOrder,
      columnOrder: columnOrder,
      child: Text(_fieldToName(field)),
    );
  }

  Widget _makeSpinnerButton(int rowOrder, int columnOrder, Field field, {bool increment = true}) {
    return SpinnerButton(
      rowOrder: rowOrder,
      columnOrder: columnOrder,
      icon: increment ? Icons.arrow_upward : Icons.arrow_downward,
      onPressed: () => _addToField(field, increment ? 1 : -1),
      field: field,
      increment: increment,
    );
  }

  Widget _makeEntryField(int rowOrder, int columnOrder, Field field) {
    return FieldWidget(
      rowOrder: rowOrder,
      columnOrder: columnOrder,
      onIncrease: () => _addToField(field, 1),
      onDecrease: () => _addToField(field, -1),
      value: fields[field.index],
      field: field,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pet Inventory'),
        ),
        body: Builder(
          builder: (BuildContext context) {
            return DefaultTextStyle(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 21.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Semantics(
                    // Since this is the only sort key that the text has, it
                    // will be compared with the 'column' OrdinalSortKeys of all the
                    // fields, because the column sort keys are first in the other fields.
                    //
                    // An ordinal of "0.0" means that it will be traversed before column 1.
                    sortKey: const OrdinalSortKey(0.0),
                    child: const Text(
                      'How many pets do you own?',
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _makeFieldHeader(1, 0, Field.DOGS),
                      _makeFieldHeader(1, 1, Field.CATS),
                      _makeFieldHeader(1, 2, Field.FISH),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _makeSpinnerButton(3, 0, Field.DOGS, increment: true),
                      _makeSpinnerButton(3, 1, Field.CATS, increment: true),
                      _makeSpinnerButton(3, 2, Field.FISH, increment: true),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _makeEntryField(2, 0, Field.DOGS),
                      _makeEntryField(2, 1, Field.CATS),
                      _makeEntryField(2, 2, Field.FISH),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _makeSpinnerButton(4, 0, Field.DOGS, increment: false),
                      _makeSpinnerButton(4, 1, Field.CATS, increment: false),
                      _makeSpinnerButton(4, 2, Field.FISH, increment: false),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
                  Semantics(
                    // Since this is the only sort key that the reset button has, it
                    // will be compared with the 'column' OrdinalSortKeys of all the
                    // fields, because the column sort keys are first in the other fields.
                    //
                    // an ordinal of "5.0" means that it will be traversed after column 4.
                    sortKey: const OrdinalSortKey(5.0),
                    child: MaterialButton(
                      child: const Text('RESET'),
                      textTheme: ButtonTextTheme.normal,
                      textColor: Colors.blue,
                      onPressed: () {
                        setState(() {
                          fields = <int>[0, 0, 0];
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(CustomTraversalExample());
}

/*
Sample Catalog

Title: CustomTraversalExample

Summary: An app that demonstrates a custom semantics traversal order.

Description:
This app presents a value selection interface where the fields can be
incremented or decremented using spinner arrows. In accessibility mode, the
widgets are traversed in a custom order from one column to the next, starting
with the column title, moving to the input field, then to the "up" increment
button, and lastly to the "down" decrement button.

When not in accessibility mode, the app works as one would expect.

Classes: Semantics

Sample: CustomTraversalExample
*/
