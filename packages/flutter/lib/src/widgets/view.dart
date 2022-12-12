// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show FlutterView;

import 'framework.dart';
import 'lookup_boundary.dart';

/// Injects a [FlutterView] into the tree and makes it available to descendants
/// within the same [LookupBoundary] via [View.of] and [View.maybeOf].
///
/// In a future version of Flutter, the functionality of this widget will be
/// extended to actually bootstrap the render tree that is going to be rendered
/// into the provided [view]. This will enable rendering content into multiple
/// [FlutterView]s from a single widget tree.
///
/// Each [FlutterView] can be associated with at most one [View] widget in the
/// widget tree. Two or more [View] widgets configured with the same
/// [FlutterView] must never exist within the same widget tree at the same time.
/// Internally, this limitation is enforced by a [GlobalObjectKey] that derives
/// its identity from the [view] provided to this widget.
class View extends InheritedWidget {
  /// Injects the provided [view] into the widget tree.
  View({required this.view, required super.child}) : super(key: GlobalObjectKey(view));

  /// The [FlutterView] to be injected into the tree.
  final FlutterView view;

  @override
  bool updateShouldNotify(View oldWidget) => view != oldWidget.view;

  /// The [FlutterView] associated with the provided `context`.
  ///
  /// The [FlutterView] returned by this method is the one into which the
  /// content defined by the provided [BuildContext] will render into.
  ///
  /// Returns null if the `context` is not associated with a [FlutterView].
  ///
  /// The method creates a dependency on the context, which will be informed
  /// when the identity of the [FlutterView] changes. However, the context will
  /// not be informed when the property values exposed by the [FlutterView]
  /// instance change. Consider using [MediaQuery.maybeOf] to query those
  /// properties if the context must be informed when their values change.
  ///
  /// See also:
  ///
  ///  * [View.of], which throws instead of returning null if no [FlutterView]
  ///    is found.
  static FlutterView? maybeOf(BuildContext context) {
    return LookupBoundary.dependOnInheritedWidgetOfExactType<View>(context)?.view;
  }

  /// The [FlutterView] associated with the provided `context`.
  ///
  /// The [FlutterView] returned by this method is the one into which the
  /// content defined by the provided [BuildContext] will render into.
  ///
  /// Throws if the `context` is not associated with a [FlutterView].
  ///
  /// The method creates a dependency on the context, which will be informed
  /// when the identity of the [FlutterView] changes. However, the context will
  /// not be informed when the property values exposed by the [FlutterView]
  /// instance change. Consider using [MediaQuery.of] to query those
  /// properties if the context must be informed when their values change.
  ///
  /// See also:
  ///
  ///  * [View.maybeOf], which throws instead of returning null if no
  ///    [FlutterView] is found.
  static FlutterView of(BuildContext context) {
    final FlutterView? result = maybeOf(context);
    assert(() {
      if (result == null) {
        final bool hiddenByBoundary = LookupBoundary.debugIsHidingAncestorWidgetOfExactType<View>(context);
        final List<DiagnosticsNode> information = <DiagnosticsNode>[
          if (hiddenByBoundary) ...<DiagnosticsNode>[
            ErrorSummary('View.of() was called with a context that does not have access to a View widget.'),
            ErrorDescription('The context provided to View.of() does have a View widget ancestor, but it is hidden by a LookupBoundary.'),
          ] else ...<DiagnosticsNode>[
            ErrorSummary('View.of() was called with a context that does not contain a View widget.'),
            ErrorDescription('No View widget ancestor could be found starting from the context that was passed to View.of().'),
          ],
          ErrorDescription(
            'The context used was:\n'
            '  $context',
          ),
          ErrorHint('This usually means that the provided context is not associated with a View.'),
        ];
        throw FlutterError.fromParts(information);
      }
      return true;
    }());
    return result!;
  }
}
