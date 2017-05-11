// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:developer' show Timeline; // to disambiguate reference in dartdocs below

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'media_query.dart';
import 'table.dart';

// Any changes to this file should be reflected in the debugAssertAllWidgetVarsUnset()
// function below.

/// Log the dirty widgets that are built each frame.
///
/// Combined with [debugPrintBuildScope] or [debugPrintBeginFrameBanner], this
/// allows you to distinguish builds triggered by the initial mounting of a
/// widget tree (e.g. in a call to [runApp]) from the regular builds triggered
/// by the pipeline.
///
/// Combined with [debugPrintScheduleBuildForStacks], this lets you watch a
/// widget's dirty/clean lifecycle.
///
/// See also the discussion at [WidgetsBinding.drawFrame].
bool debugPrintRebuildDirtyWidgets = false;

/// Log all calls to [BuildOwner.buildScope].
///
/// Combined with [debugPrintScheduleBuildForStacks], this allows you to track
/// when a [State.setState] call gets serviced.
///
/// Combined with [debugPrintRebuildDirtyWidgets] or
/// [debugPrintBeginFrameBanner], this allows you to distinguish builds
/// triggered by the initial mounting of a widget tree (e.g. in a call to
/// [runApp]) from the regular builds triggered by the pipeline.
///
/// See also the discussion at [WidgetsBinding.drawFrame].
bool debugPrintBuildScope = false;

/// Log the call stacks that mark widgets as needing to be rebuilt.
///
/// This is called whenever [BuildOwner.scheduleBuildFor] adds an element to the
/// dirty list. Typically this is as a result of [Element.markNeedsBuild] being
/// called, which itself is usually a result of [State.setState] being called.
///
/// To see when a widget is rebuilt, see [debugPrintRebuildDirtyWidgets].
///
/// To see when the dirty list is flushed, see [debugPrintBuildScope].
///
/// To see when a frame is scheduled, see [debugPrintScheduleFrameStacks].
bool debugPrintScheduleBuildForStacks = false;

/// Log when widgets with global keys are deactivated and log when they are
/// reactivated (retaken).
///
/// This can help track down framework bugs relating to the [GlobalKey] logic.
bool debugPrintGlobalKeyedWidgetLifecycle = false;

/// Adds [Timeline] events for every Widget built.
///
/// For details on how to use [Timeline] events in the Dart Observatory to
/// optimize your app, see https://fuchsia.googlesource.com/sysui/+/master/docs/performance.md
bool debugProfileBuildsEnabled = false;

/// Show banners for deprecated widgets.
bool debugHighlightDeprecatedWidgets = false;

Key _firstNonUniqueKey(Iterable<Widget> widgets) {
  final Set<Key> keySet = new HashSet<Key>();
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
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasTable(context));
/// ```
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasTable(BuildContext context) {
  assert(() {
    if (context.widget is! Table && context.ancestorWidgetOfExactType(Table) == null) {
      final Element element = context;
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

/// Asserts that the given context has a [MediaQuery] ancestor.
///
/// Used by various widgets to make sure that they are only used in an
/// appropriate context.
///
/// To invoke this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasMediaQuery(context));
/// ```
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasMediaQuery(BuildContext context) {
  assert(() {
    if (context.widget is! MediaQuery && context.ancestorWidgetOfExactType(MediaQuery) == null) {
      final Element element = context;
      throw new FlutterError(
        'No MediaQuery widget found.\n'
        '${context.widget.runtimeType} widgets require a MediaQuery widget ancestor.\n'
        'The specific widget that could not find a MediaQuery ancestor was:\n'
        '  ${context.widget}\n'
        'The ownership chain for the affected widget is:\n'
        '  ${element.debugGetCreatorChain(10)}\n'
        'Typically, the MediaQuery widget is introduced by the MaterialApp or '
        'WidgetsApp widget at the top of your application widget tree.'
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

/// Returns true if none of the widget library debug variables have been changed.
///
/// This function is used by the test framework to ensure that debug variables
/// haven't been inadvertently changed.
///
/// See [https://docs.flutter.io/flutter/widgets/widgets-library.html] for
/// a complete list.
bool debugAssertAllWidgetVarsUnset(String reason) {
  assert(() {
    if (debugPrintRebuildDirtyWidgets ||
        debugPrintBuildScope ||
        debugPrintScheduleBuildForStacks ||
        debugPrintGlobalKeyedWidgetLifecycle ||
        debugProfileBuildsEnabled ||
        debugHighlightDeprecatedWidgets) {
      throw new FlutterError(reason);
    }
    return true;
  });
  return true;
}
