import 'package:flutter/widgets.dart';

/// An inherited widget that provides windowing configuration to its descendants.
///
/// This widget allows you to enable or disable windowing features across the
/// widget tree. When [enableWindowing] is set to `true`, widgets that support
/// windowing will create separate windows where applicable, such as for dialogs
/// or popups.
///
/// If windowing is not supported on the current platform, this configuration
/// will have no effect.
class WindowingConfiguration extends InheritedWidget {
  /// Creates a [WindowingConfiguration] widget.
  ///
  /// The [enableWindowing] parameter determines whether windowing features are
  /// enabled.
  /// The [child] parameter is the widget below this widget in the tree.
  const WindowingConfiguration({super.key, required this.enableWindowing, required super.child});

  /// Whether windowing features are enabled.
  ///
  /// When `true`, widgets that support windowing will create separate windows
  /// where applicable.
  final bool enableWindowing;

  /// Retrieves the nearest [WindowingConfiguration] instance from the given
  /// [BuildContext].
  ///
  /// Returns `null` if no [WindowingConfiguration] is found in the widget tree.
  static WindowingConfiguration? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WindowingConfiguration>();
  }

  @override
  bool updateShouldNotify(covariant WindowingConfiguration oldWidget) {
    return enableWindowing != oldWidget.enableWindowing;
  }
}
