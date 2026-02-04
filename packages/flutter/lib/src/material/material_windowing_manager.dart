// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/widgets.dart';
import '../widgets/_window.dart' show BaseWindowController;
import 'theme.dart';

const String _kWindowingDisabledErrorMessage = '''
Windowing APIs are not enabled.

Windowing APIs are currently experimental. Do not use windowing APIs in
production applications or plugins published to pub.dev.

To try experimental windowing APIs:
1. Switch to Flutter's main release channel.
2. Turn on the windowing feature flag.

See: https://github.com/flutter/flutter/issues/30701.
''';

/// Registry for managing windows in a Material application.
///
/// This registry allows registering and unregistering windows such as dialogs,
/// and notifies listeners when the list of registered windows changes.
///
/// It also indicates whether windowing features are enabled via [enableWindowing].
///
/// {@template flutter.material.windowing.experimental}
/// Do not use this API in production applications or packages published to
/// pub.dev. Flutter will make breaking changes to this API, even in patch
/// versions.
///
/// This API throws an [UnsupportedError] error unless Flutter’s windowing
/// feature is enabled by [isWindowingEnabled].
///
/// See: https://github.com/flutter/flutter/issues/30701.
/// {@endtemplate}
@internal
class MaterialWindowRegistry extends ChangeNotifier {
  /// Creates a Material window registry.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  MaterialWindowRegistry() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  /// Whether windowing features are enabled.
  @internal
  bool get enableWindowing => isWindowingEnabled;
  final List<MaterialWindowEntry> _windows = <MaterialWindowEntry>[];

  /// The list of registered windows.
  List<MaterialWindowEntry> get windows => List<MaterialWindowEntry>.unmodifiable(_windows);

  /// Registers a window.
  ///
  /// The [entry] parameter specifies the window to register.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void register(MaterialWindowEntry entry) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _windows.add(entry);
    notifyListeners();
  }

  /// Unregisters a window.
  ///
  /// The [entry] parameter specifies the window to unregister.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void unregister(MaterialWindowEntry entry) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _windows.remove(entry);
    notifyListeners();
  }

  /// Retrieves the [MaterialWindowRegistry] from the given [context].
  ///
  /// Returns null if no registry is found in the widget tree.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  static MaterialWindowRegistry? maybeOf(BuildContext context) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    return context.dependOnInheritedWidgetOfExactType<MaterialWindowRegistryScope>()?._registry;
  }
}

/// An inherited widget that provides access to the [MaterialWindowRegistry].
////
/// {@macro flutter.widgets.windowing.experimental}
@internal
class MaterialWindowRegistryScope extends InheritedWidget {
  /// Creates a Material window registry scope.
  ///
  /// The [registry] parameter specifies the window registry to provide.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  MaterialWindowRegistryScope({
    super.key,
    required MaterialWindowRegistry registry,
    required super.child,
  }) : _registry = registry {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  final MaterialWindowRegistry _registry;

  @override
  bool updateShouldNotify(MaterialWindowRegistryScope oldWidget) {
    return _registry != oldWidget._registry;
  }
}

/// Represents an entry for a Material window such as a dialog.
///
/// This class holds the necessary information to build and manage
/// a window within the Material application.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
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
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  MaterialWindowEntry({
    required this.controller,
    required this.builder,
    required this.textDirection,
    required this.themeData,
    required this.mediaQueryData,
    this.onPop,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }
  }

  /// The controller that manages the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final BaseWindowController controller;

  /// The builder function that builds the content of the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final WidgetBuilder builder;

  /// The text direction for the window's content.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final TextDirection textDirection;

  /// The theme data for the window's content.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final ThemeData themeData;

  /// The media query data for the window's content.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final MediaQueryData mediaQueryData;

  /// Callback invoked when the window is popped from the navigation stack.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final VoidCallback? onPop;
}
