// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'framework.dart';
import 'table.dart';

/// Log the dirty widgets that are built each frame.
bool debugPrintRebuildDirtyWidgets = false;

/// Log when widgets with global keys are deactivated and log when they are
/// reactivated (retaken).
///
/// This can help track down framework bugs relating to the [GlobalKey] logic.
bool debugPrintGlobalKeyedWidgetLifecycle = false;

Key _firstNonUniqueKey(Iterable<Widget> widgets) {
  Set<Key> keySet = new HashSet<Key>();
  for (Widget widget in widgets) {
    assert(widget != null);
    if (widget.key == null)
      continue;
    if (!keySet.add(widget.key))
      return widget.key;
  }
  return null;
}

/// Asserts if the given child list contains any duplicate non-null keys.
///
/// To invoke this function, use the following pattern, typically in the
/// relevant Widget's constructor:
///
/// ```dart
/// assert(!debugChildrenHaveDuplicateKeys(this, children));
/// ```
///
/// For a version of this function that can be used in contexts where
/// the list of items does not have a particular parent, see
/// [debugItemsHaveDuplicateKeys].
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugChildrenHaveDuplicateKeys(Widget parent, Iterable<Widget> children) {
  assert(() {
    final Key nonUniqueKey = _firstNonUniqueKey(children);
    if (nonUniqueKey != null) {
      throw new FlutterError(
        'Duplicate keys found.\n'
        'If multiple keyed nodes exist as children of another node, they must have unique keys.\n'
        '$parent has multiple children with key $nonUniqueKey.'
      );
    }
    return true;
  });
  return false;
}

/// Asserts if the given list of items contains any duplicate non-null keys.
///
/// To invoke this function, use the following pattern:
///
/// ```dart
/// assert(!debugItemsHaveDuplicateKeys(items));
/// ```
///
/// For a version of this function specifically intended for parents
/// checking their children lists, see [debugChildrenHaveDuplicateKeys].
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugItemsHaveDuplicateKeys(Iterable<Widget> items) {
  assert(() {
    final Key nonUniqueKey = _firstNonUniqueKey(items);
    if (nonUniqueKey != null)
      throw new FlutterError('Duplicate key found: $nonUniqueKey.');
    return true;
  });
  return false;
}

/// Asserts that the given context has a [Table] ancestor.
///
/// Used by [TableRowInkWell] to make sure that it is only used in an appropriate context.
///
/// To invoke this function, use the following pattern, typically in the
/// relevant Widget's [build] method:
///
/// ```dart
/// assert(debugCheckHasTable(context));
/// ```
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasTable(BuildContext context) {
  assert(() {
    if (context.widget is! Table && context.ancestorWidgetOfExactType(Table) == null) {
      Element element = context;
      throw new FlutterError(
        'No Table widget found.\n'
        '${context.widget.runtimeType} widgets require a Table widget ancestor.\n'
        'The specific widget that could not find a Table ancestor was:\n'
        '  ${context.widget}\n'
        'The ownership chain for the affected widget is:\n'
        '  ${element.debugGetCreatorChain(10)}'
      );
    }
    return true;
  });
  return true;
}

/// Asserts that the `built` widget is not null.
///
/// Used when the given `widget` calls a builder function to check that the
/// function returned a non-null value, as typically required.
///
/// Does nothing when asserts are disabled.
void debugWidgetBuilderValue(Widget widget, Widget built) {
  assert(() {
    if (built == null) {
      throw new FlutterError(
        'A build function returned null.\n'
        'The offending widget is: $widget\n'
        'Build functions must never return null. '
        'To return an empty space that causes the building widget to fill available room, return "new Container()". '
        'To return an empty space that takes as little room as possible, return "new Container(width: 0.0, height: 0.0)".'
      );
    }
    return true;
  });
}
