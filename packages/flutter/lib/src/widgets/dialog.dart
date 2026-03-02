// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;

import 'package:flutter/src/widgets/_window.dart'
    show
        BaseWindowController,
        DialogWindowController,
        DialogWindowControllerDelegate,
        WindowEntry,
        WindowRegistry,
        WindowScope;

typedef RouteBuilder<T> = Route<T> Function(BuildContext context, WidgetBuilder builder);

/// Displays a dialog over the contents of the app.
///
/// When windowing is available, the dialog is a separate window.
///
/// The parameter `routeBuilder` builds the [Route] that will be pushed to the
/// [Navigator]. Defaults to building a [RawDialogRoute]. When windowing is
/// available, this parameter will be silently ignored.
///
/// The parameter `builder` builds the content of the dialog.
Future<T?> showRawDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  RouteBuilder<T>? routeBuilder,
  Color? barrierColor,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool fullscreenDialog = false,
  bool? requestFocus,
}) {
  assert(_debugIsActive(context));
  assert(debugCheckHasWidgetsLocalizations(context));

  final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);

  final WindowRegistry? windowingConfiguration = WindowRegistry.maybeOf(context);
  if (windowingConfiguration != null && isWindowingEnabled) {
    try {
      final Size? parentSize = WindowScope.maybeContentSizeOf(context);
      return navigator.push<T>(
        _DialogWindowRoute<T>(
          builder: builder,
          parentController: WindowScope.maybeOf(context),
          context: context,
          settings: routeSettings,
          preferredSize: fullscreenDialog ? parentSize : null,
        ),
      );
    } on UnsupportedError catch (error, stacktrace) {
      // Fallback to normal dialog route if windowing is not supported
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, library: 'widgets library', stack: stacktrace),
      );
    }
  }

  final Route<T> route =
      routeBuilder?.call(context, builder) ??
      RawDialogRoute<T>(
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => builder(context),
        barrierColor: barrierColor,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        settings: routeSettings,
        anchorPoint: anchorPoint,
        traversalEdgeBehavior: traversalEdgeBehavior ?? TraversalEdgeBehavior.closedLoop,
        requestFocus: requestFocus,
        fullscreenDialog: fullscreenDialog,
      );

  return navigator.push<T>(route);
}

// TODO(justinmc): This was copied from Material, is it needed?
bool _debugIsActive(BuildContext context) {
  if (context is Element && !context.debugIsActive) {
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('This BuildContext is no longer valid.'),
      ErrorDescription(
        'The showDialog function context parameter is a BuildContext that is no longer valid.',
      ),
      ErrorHint(
        'This can commonly occur when the showDialog function is called after awaiting a Future. '
        'In this situation the BuildContext might refer to a widget that has already been disposed during the await. '
        'Consider using a parent context instead.',
      ),
    ]);
  }
  return true;
}

class _DialogWindowDelegate extends DialogWindowControllerDelegate {
  _DialogWindowDelegate(this.route);

  final _DialogWindowRoute<dynamic> route;

  @override
  void onWindowCloseRequested(DialogWindowController controller) {
    route.navigator?.pop();
  }
}

class _DialogWindowRoute<T> extends Route<T> {
  _DialogWindowRoute({
    required this.builder,
    required this.parentController,
    required BuildContext context,
    super.settings,
    Size? preferredSize,
  }) : _registry = WindowRegistry.maybeOf(context) {
    _controller = DialogWindowController(
      parent: parentController,
      title: 'Dialog',
      delegate: _DialogWindowDelegate(this),
      preferredSize: preferredSize,
    );
  }

  final WidgetBuilder builder;
  final BaseWindowController? parentController;
  final WindowRegistry? _registry;
  DialogWindowController? _controller;
  WindowEntry? _entry;
  late final List<OverlayEntry> _overlayEntries;

  @override
  List<OverlayEntry> get overlayEntries => _overlayEntries;

  @override
  void install() {
    super.install();

    // Create a minimal transparent overlay entry to satisfy Navigator requirements.
    // The actual dialog content is rendered through ViewAnchor, not through this overlay.
    _overlayEntries = <OverlayEntry>[
      OverlayEntry(builder: (BuildContext context) => const SizedBox.shrink()),
    ];

    final NavigatorState? nav = navigator;
    final BuildContext? routeContext = nav?.context;
    if (routeContext != null && nav != null) {
      _entry = WindowEntry(controller: _controller!, builder: builder);
      _registry?.register(_entry!);
    }
  }

  @override
  TickerFuture didPush() {
    super.didPush();
    // No animation is needed since the window appears instantly.
    return TickerFuture.complete();
  }

  @override
  bool didPop(T? result) {
    _controller?.destroy();
    return super.didPop(result);
  }

  @override
  void dispose() {
    // Unregister from the registry.
    if (_entry != null) {
      _registry?.unregister(_entry!);
    }
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
