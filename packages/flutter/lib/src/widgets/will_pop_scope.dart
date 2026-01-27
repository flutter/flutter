// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'form.dart';
library;

import 'framework.dart';
import 'navigator.dart';
import 'routes.dart';

/// Registers a callback to veto attempts by the user to dismiss the enclosing
/// [ModalRoute].
///
/// {@tool snippet}
/// **Migration example:**
///
/// Instead of:
/// ```dart
/// WillPopScope(
///   onWillPop: () async {
///     if (hasUnsavedChanges) {
///       return await showDialog<bool>(
///         context: context,
///         builder: (context) => AlertDialog(
///           title: const Text('Discard changes?'),
///           actions: [
///             TextButton(
///               onPressed: () => Navigator.pop(context, false),
///               child: const Text('Cancel'),
///             ),
///             TextButton(
///               onPressed: () => Navigator.pop(context, true),
///               child: const Text('Discard'),
///             ),
///           ],
///         ),
///       ) ?? false;
///     }
///     return true;
///   },
///   child: child,
/// )
/// ```
///
/// Use:
/// ```dart
/// PopScope(
///   canPop: !hasUnsavedChanges,
///   onPopInvokedWithResult: (bool didPop, dynamic result) async {
///     if (!didPop && hasUnsavedChanges) {
///       final bool? shouldPop = await showDialog<bool>(
///         context: context,
///         builder: (context) => AlertDialog(
///           title: const Text('Discard changes?'),
///           actions: [
///             TextButton(
///               onPressed: () => Navigator.pop(context, false),
///               child: const Text('Cancel'),
///             ),
///             TextButton(
///               onPressed: () => Navigator.pop(context, true),
///               child: const Text('Discard'),
///             ),
///           ],
///         ),
///       );
///       if (shouldPop == true && context.mounted) {
///         Navigator.of(context).pop();
///       }
///     }
///   },
///   child: child,
/// )
/// ```
///
/// Note: [PopScope] uses [canPop] to prevent the pop in advance, and
/// [onPopInvokedWithResult] is called after the pop attempt. If [canPop] is
/// false, the pop is prevented and `didPop` will be false in the callback.
/// {@end-tool}
///
/// See also:
///
///  * [PopScope], the replacement widget that supports Android predictive back.
///  * [ModalRoute.addScopedWillPopCallback] and [ModalRoute.removeScopedWillPopCallback],
///    which this widget uses to register and unregister [onWillPop].
///  * [Form], which provides an `onWillPop` callback that enables the form
///    to veto a `pop` initiated by the app's back button.
@Deprecated(
  'Use PopScope instead. The Android predictive back feature will not work with WillPopScope. '
  'This feature was deprecated after v3.12.0-1.0.pre.',
)
class WillPopScope extends StatefulWidget {
  /// Creates a widget that registers a callback to veto attempts by the user to
  /// dismiss the enclosing [ModalRoute].
  @Deprecated(
    'Use PopScope instead. The Android predictive back feature will not work with WillPopScope. '
    'This feature was deprecated after v3.12.0-1.0.pre.',
  )
  const WillPopScope({super.key, required this.child, required this.onWillPop});

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Called to veto attempts by the user to dismiss the enclosing [ModalRoute].
  ///
  /// If the callback returns a Future that resolves to false, the enclosing
  /// route will not be popped.
  final WillPopCallback? onWillPop;

  @override
  State<WillPopScope> createState() => _WillPopScopeState();
}

class _WillPopScopeState extends State<WillPopScope> {
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.onWillPop != null) {
      _route?.removeScopedWillPopCallback(widget.onWillPop!);
    }
    _route = ModalRoute.of(context);
    if (widget.onWillPop != null) {
      _route?.addScopedWillPopCallback(widget.onWillPop!);
    }
  }

  @override
  void didUpdateWidget(WillPopScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onWillPop != oldWidget.onWillPop && _route != null) {
      if (oldWidget.onWillPop != null) {
        _route!.removeScopedWillPopCallback(oldWidget.onWillPop!);
      }
      if (widget.onWillPop != null) {
        _route!.addScopedWillPopCallback(widget.onWillPop!);
      }
    }
  }

  @override
  void dispose() {
    if (widget.onWillPop != null) {
      _route?.removeScopedWillPopCallback(widget.onWillPop!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
