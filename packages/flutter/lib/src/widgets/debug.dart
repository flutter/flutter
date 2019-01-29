// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:developer' show Timeline; // to disambiguate reference in dartdocs below

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/rendering.dart' show RenderErrorBuilder;

import 'basic.dart';
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
/// To get similar information but showing it on the timeline available from the
/// Observatory rather than getting it in the console (where it can be
/// overwhelming), consider [debugProfileBuildsEnabled].
///
/// See also the discussion at [WidgetsBinding.drawFrame].
bool debugPrintRebuildDirtyWidgets = false;

/// Signature for [debugOnRebuildDirtyWidget] implementations.
typedef RebuildDirtyWidgetCallback = void Function(Element e, bool builtOnce);

/// Callback invoked for every dirty widget built each frame.
///
/// This callback is only invoked in debug builds.
///
/// See also:
///
///  * [debugPrintRebuildDirtyWidgets], which does something similar but logs
///    to the console instead of invoking a callback.
///  * [debugOnProfilePaint], which does something similar for [RenderObject]
///    painting.
///  * [WidgetInspectorService], which uses the [debugOnRebuildDirtyWidget]
///    callback to generate aggregate profile statistics describing which widget
///    rebuilds occurred when the
///    `ext.flutter.inspector.trackRebuildDirtyWidgets` service extension is
///    enabled.
RebuildDirtyWidgetCallback debugOnRebuildDirtyWidget;

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
///
/// See also [debugProfilePaintsEnabled], which does something similar but for
/// painting, and [debugPrintRebuildDirtyWidgets], which does something similar
/// but reporting the builds to the console.
bool debugProfileBuildsEnabled = false;

/// Show banners for deprecated widgets.
bool debugHighlightDeprecatedWidgets = false;

Key _firstNonUniqueKey(Iterable<Widget> widgets) {
  final Set<Key> keySet = HashSet<Key>();
  for (Widget widget in widgets) {
    assert(widget != null);
    if (widget.key == null)
      continue;
    if (!keySet.add(widget.key))
      return widget.key;
  }
  return null;
}

/// Variant of [FlutterErrorBuilder] with extra methods for describing widget
/// errors.
///
/// It is important to add basic parts to the error report using base class
/// methods such as addError, addDescription, addHint, etc.
///
/// If the error you want to report is from the rendering layer, consider using
/// [RenderErrorBuilder] instead.
/// See also:
///
///  * [RenderErrorBuilder], which should be used instead if the error you want
///    to report only deals with the rendering layer.
class WidgetErrorBuilder extends RenderErrorBuilder {
  /// Creates a [WidgetErrorBuilder]
  WidgetErrorBuilder();

  /// Creates a [RenderErrorBuilder] with its details computed only when needed.
  /// Use if computing the error details may throw an exception or is expensive.
  WidgetErrorBuilder.lazy(ErrorBuilderCallback<WidgetErrorBuilder> callback) : super.lazy(callback);

  /// Adds a description of a specific type of widget missing from the current
  /// build context's ancestry tree.
  ///
  /// You can find an example of using this method in [debugCheckHasMaterial].
  void describeMissingAncestor(
    BuildContext context, {
    @required Type expectedAncestorType,
  }) {
    final List<Element> ancestors = <Element>[];
    context.visitAncestorElements((Element element) {
      ancestors.add(element);
      return true;
    });

    // TODO(jacobr): indicate this is the context on the error.
    addDiagnostic(DiagnosticsProperty<Element>(
      'The specific widget that could not find a $expectedAncestorType ancestor was',
      context,
      style: DiagnosticsTreeStyle.indentedSingleLine,
    ));

    if (ancestors.isNotEmpty) {
      describeElements('The ancestors of this widget were', ancestors);
    } else {
      addDiagnostic(DiagnosticsNode.message(
          'This widget is the root of the tree, so it has no '
              'ancestors, let alone a "$expectedAncestorType" ancestor.'
      ));
    }
  }

  /// Adds a description of the specific widget the error is originated from
  /// to the error report.
  ///
  /// The description will include the widget's type and its properties.
  /// Technically this method logs the [Element] rather than just the [Widget]
  /// so that GUI tools can jump to the exact location in the Element tree where
  /// the widget was created.
  ///
  /// {@tool sample}
  /// ```dart
  /// WidgetErrorBuilder()
  ///   ..addWidgetContext('The specific widget that could not find a Table ancestor was', context)
  /// ```
  /// {@end-tool}
  /// {@tool sample}
  void addWidgetContext(String name, BuildContext context) {
    addDiagnostic(DiagnosticsProperty<Element>(name, context, style: DiagnosticsTreeStyle.indentedSingleLine));
  }
  
  /// Adds a description of an [Element] from the current build context
  /// to the error report.
  void describeElement(String name, Element element, {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.indentedSingleLine}) {
    addDiagnostic(DiagnosticsProperty<Element>(name, element, style: style));
  }

  /// Adds a list of [Element]s from the current build context to the error report.
  void describeElements(String name, Iterable<Element> elements) {
    addDiagnostic(DiagnosticsBlock(
      name: name,
      children: elements.map<DiagnosticsNode>((Element element) => DiagnosticsProperty<Element>('', element)).toList(),
      allowTruncate: true,
    ));
  }

  /// Adds a description of a specific [Ticker] to the error report. 
  void describeTicker(String name, Ticker ticker) {
    // TODO(jacobr): this toString includes a StackTrace. create a TickerProperty DiagnosticsNode.
    addDiagnostic(DiagnosticsProperty<Ticker>('The offending ticker was', ticker, description: ticker.toString(debugIncludeStack: true)));
  }

  /// Adds a description of the ownership chain from a specific [Element]
  /// to the error report. It's useful for debugging the source of an element.
  void describeOwnershipChain(String name, Element element) {
    // XXX make this structured so clients can allow clicks on individual entries.
    // For example, is this an iterable with arrows as the separators?
    addDiagnostic(StringProperty(name, element.debugGetCreatorChain(10)));
  }
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
      throw FlutterError.from(FlutterErrorBuilder()
        ..addError('Duplicate keys found.')
        ..addContract('If multiple keyed nodes exist as children of another node, they must have unique keys.')
        // TODO(jacobr): expose both the parent and key as structured objects.
        ..addViolation('$parent has multiple children with key $nonUniqueKey.')
      );
    }
    return true;
  }());
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
      throw FlutterError.from(FlutterErrorBuilder()..addErrorProperty('Duplicate key found', nonUniqueKey, style: DiagnosticsTreeStyle.singleLine));
    return true;
  }());
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
      throw FlutterError.from(WidgetErrorBuilder()
        ..addError('No Table widget found.')
        ..addContract('${context.widget.runtimeType} widgets require a Table widget ancestor.')
        ..addWidgetContext('The specific widget that could not find a Table ancestor was', context)
        ..describeOwnershipChain('The ownership chain for the affected widget is', element)
      );
    }
    return true;
  }());
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
      throw FlutterError.from(WidgetErrorBuilder()
        ..addError('No MediaQuery widget found.')
        ..addViolation('${context.widget.runtimeType} widgets require a MediaQuery widget ancestor.')
        ..addWidgetContext('The specific widget that could not find a MediaQuery ancestor was', context)
        ..describeOwnershipChain('The ownership chain for the affected widget is', element)
        ..addHint(
          'Typically, the MediaQuery widget is introduced by the MaterialApp or '
          'WidgetsApp widget at the top of your application widget tree.'
        )
      );
    }
    return true;
  }());
  return true;
}

/// Asserts that the given context has a [Directionality] ancestor.
///
/// Used by various widgets to make sure that they are only used in an
/// appropriate context.
///
/// To invoke this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasDirectionality(context));
/// ```
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasDirectionality(BuildContext context) {
  assert(() {
    if (context.widget is! Directionality && context.ancestorWidgetOfExactType(Directionality) == null) {
      final Element element = context;
      throw FlutterError.from(WidgetErrorBuilder()
        ..addError('No Directionality widget found.')
        ..addContract('${context.widget.runtimeType} widgets require a Directionality widget ancestor.\n')
        ..addWidgetContext('The specific widget that could not find a Directionality ancestor was', context)
        ..describeOwnershipChain('The ownership chain for the affected widget is', element)
        ..addHint(
          'Typically, the Directionality widget is introduced by the MaterialApp '
          'or WidgetsApp widget at the top of your application widget tree. It '
          'determines the ambient reading direction and is used, for example, to '
          'determine how to lay out text, how to interpret "start" and "end" '
          'values, and to resolve EdgeInsetsDirectional, '
          'AlignmentDirectional, and other *Directional objects.'
        )
      );
    }
    return true;
  }());
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
      // XXX review how this message looks.
      throw FlutterError.from(WidgetErrorBuilder()
        ..addError('A build function returned null.')
        ..addProperty('The offending widget is', widget)
        ..addContract('Build functions must never return null.')
        ..addHint('To return an empty space that causes the building widget to fill available room, return "new Container()".')
        ..addHint('To return an empty space that takes as little room as possible, return "new Container(width: 0.0, height: 0.0)".')
      );
    }
    if (widget == built) {
      throw FlutterError.from(WidgetErrorBuilder()
        ..addError('A build function returned context.widget.')
        ..addProperty('The offending widget is', widget)
        ..addContract(
          'Build functions must never return their BuildContext parameter\'s widget or a child that contains "context.widget". '
          'Doing so introduces a loop in the widget tree that can cause the app to crash.'
        )
      );
    }
    return true;
  }());
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
      throw FlutterError(reason);
    }
    return true;
  }());
  return true;
}
