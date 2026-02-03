// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import '../widgets/_window.dart' show BaseWindowController, DialogWindow, DialogWindowController;
import 'dialog_theme.dart';
import 'theme.dart';

/// Manages windows for the Material application and provides the [MaterialWindowRegistry]
/// to descendant widgets.
///
/// This widget is rendered by [MaterialApp] at the root of its tree.
///
/// Descendents may access the [MaterialWindowRegistry] via
/// [MaterialWindowRegistry.maybeOf]. This registry can be used to
/// register and unregister windows such as dialogs. The registered windows
/// are rendered alongside the main application using [ViewAnchor].
class MaterialWindowingManager extends StatefulWidget {
  /// Creates a Material windowing manager.
  ///
  /// The [enableWindowing] and [child] parameters are required.
  MaterialWindowingManager({super.key, required bool enableWindowing, required this.child})
    : _registry = MaterialWindowRegistry(enableWindowing: enableWindowing);

  /// The child widget.
  final Widget child;

  final MaterialWindowRegistry _registry;

  @override
  State<MaterialWindowingManager> createState() => _MaterialWindowingManagerState();
}

class _MaterialWindowingManagerState extends State<MaterialWindowingManager> {
  @override
  Widget build(BuildContext context) {
    return _MaterialWindowRegistryScope(
      registry: widget._registry,
      child: ListenableBuilder(
        listenable: widget._registry,
        builder: (BuildContext context, Widget? child) {
          final List<Widget> subViews = widget._registry.windows.map((MaterialWindowEntry entry) {
            switch (entry.controller.runtimeType) {
              case final DialogWindowController dialog:
                return _buildDialog(entry, dialog);
              default:
                throw UnimplementedError(
                  'Unsupported window controller type: ${entry.controller.runtimeType}',
                );
            }
          }).toList();

          return ViewAnchor(
            view: subViews.isNotEmpty ? ViewCollection(views: subViews) : null,
            child: child!,
          );
        },
        child: widget.child,
      ),
    );
  }

  Widget _buildDialog(MaterialWindowEntry entry, DialogWindowController controller) {
    final Widget dialogContent = _DialogPopScope(
      onPop: entry.onPop,
      child: Builder(
        builder: (BuildContext innerContext) {
          return _FullWindowDialogWrapper(child: entry.builder(innerContext));
        },
      ),
    );

    return DialogWindow(
      controller: controller,
      child: Directionality(
        textDirection: entry.textDirection,
        child: Theme(
          data: entry.themeData,
          child: MediaQuery(data: entry.mediaQueryData, child: dialogContent),
        ),
      ),
    );
  }
}

/// Registry for managing windows in a Material application.
///
/// This registry allows registering and unregistering windows such as dialogs,
/// and notifies listeners when the list of registered windows changes.
///
/// It also indicates whether windowing features are enabled via [enableWindowing].
class MaterialWindowRegistry extends ChangeNotifier {
  /// Creates a Material window registry.
  MaterialWindowRegistry({required this.enableWindowing});

  /// Whether windowing features are enabled.
  final bool enableWindowing;
  final List<MaterialWindowEntry> _windows = <MaterialWindowEntry>[];

  /// The list of registered windows.
  List<MaterialWindowEntry> get windows => List<MaterialWindowEntry>.unmodifiable(_windows);

  /// Registers a window.
  ///
  /// The [entry] parameter specifies the window to register.
  void register(MaterialWindowEntry entry) {
    _windows.add(entry);
    notifyListeners();
  }

  /// Unregisters a window.
  ///
  /// The [entry] parameter specifies the window to unregister.
  void unregister(MaterialWindowEntry entry) {
    _windows.remove(entry);
    notifyListeners();
  }

  /// Retrieves the [MaterialWindowRegistry] from the given [context].
  ///
  /// Returns null if no registry is found in the widget tree.
  static MaterialWindowRegistry? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_MaterialWindowRegistryScope>()?._registry;
  }
}

class _MaterialWindowRegistryScope extends InheritedWidget {
  const _MaterialWindowRegistryScope({
    required MaterialWindowRegistry registry,
    required super.child,
  }) : _registry = registry;

  final MaterialWindowRegistry _registry;

  @override
  bool updateShouldNotify(_MaterialWindowRegistryScope oldWidget) {
    return _registry != oldWidget._registry;
  }
}

// Wrapper that makes dialogs fill the entire window without insets or rounded corners
class _FullWindowDialogWrapper extends StatelessWidget {
  const _FullWindowDialogWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final DialogThemeData windowDialogTheme = DialogTheme.of(context).copyWith(
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(), // No rounded corners
      alignment: Alignment.topLeft, // Align to top-left so it fills from corner
      constraints:
          const BoxConstraints.expand(), // Remove default constraints so dialog can expand to fill available space
    );

    return DialogTheme(
      data: windowDialogTheme,
      child: MediaQuery.removeViewInsets(
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        context: context,
        child: MediaQuery.removeViewPadding(
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          context: context,
          child: child,
        ),
      ),
    );
  }
}

// Provides a pop callback that dialog content can use
// Wraps content to provide a Navigator-like interface for popping
class _DialogPopScope extends StatelessWidget {
  const _DialogPopScope({required this.child, this.onPop});

  final Widget child;
  final VoidCallback? onPop;

  @override
  Widget build(BuildContext context) {
    // Wrap with WillPopScope to handle back button and provide popNavigator function
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          onPop?.call();
        }
      },
      child: Builder(
        builder: (BuildContext context) {
          // Provide a way for child widgets to pop using Navigator.maybePop(context)
          // by wrapping in a minimal Navigator
          return _NavigatorShim(onPop: onPop, child: child);
        },
      ),
    );
  }
}

// Creates a minimal Navigator that intercepts pop calls
class _NavigatorShim extends StatefulWidget {
  const _NavigatorShim({required this.child, this.onPop});

  final VoidCallback? onPop;
  final Widget child;

  @override
  State<_NavigatorShim> createState() => _NavigatorShimState();
}

class _NavigatorShimState extends State<_NavigatorShim> {
  @override
  Widget build(BuildContext context) {
    // Create a Navigator with a single page that contains the child
    // This allows Navigator.pop(context) calls from within the dialog to work
    return Navigator(
      pages: <Page<void>>[_DialogContentPage(child: widget.child)],
      onPopPage: (Route<dynamic> route, dynamic result) {
        // When the page is popped, call our onPop callback
        widget.onPop?.call();
        // Return false to prevent the route from being removed from the Navigator
        // (since we're handling the pop externally by closing the dialog window)
        return false;
      },
    );
  }
}

// A simple page for the dialog content
class _DialogContentPage extends Page<void> {
  const _DialogContentPage({required this.child});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return child;
          },
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

/// Represents an entry for a Material window such as a dialog.
///
/// This class holds the necessary information to build and manage
/// a window within the Material application.
class MaterialWindowEntry {
  /// Creates a Material window entry.
  ///
  /// The [controller] parameter is the controller that manages the window.
  ///
  /// The [builder] parameter is a function that builds the content of the window.
  ///
  /// The [textDirection] parameter specifies the text direction for the window's content.
  ///
  /// The [themeData] parameter provides the theme data for the window's content.
  ///
  /// The [mediaQueryData] parameter provides the media query data for the window's content.
  ///
  /// The [onPop] parameter is a callback that is invoked when the window is
  /// popped from the navigation stack.
  MaterialWindowEntry({
    required this.controller,
    required this.builder,
    required this.textDirection,
    required this.themeData,
    required this.mediaQueryData,
    this.onPop,
  });

  /// The controller that manages the window.
  final BaseWindowController controller;

  /// The builder function that builds the content of the window.
  final WidgetBuilder builder;

  /// The text direction for the window's content.
  final TextDirection textDirection;

  /// The theme data for the window's content.
  final ThemeData themeData;

  /// The media query data for the window's content.
  final MediaQueryData mediaQueryData;

  /// Callback invoked when the window is popped from the navigation stack.
  final VoidCallback? onPop;
}
