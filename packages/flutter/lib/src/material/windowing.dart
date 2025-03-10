import 'package:flutter/widgets.dart';

/// Allows descendent widgets of the MaterialApp to query whether or not
/// they should prioritize using the windowing API over [Overlay]s when it is
/// appropriate to do so.
///
/// Descendent widgets obtain the current suggestion to use the windowing api
/// using [Windowing.of]. When a widget uses [Windowing.of], it is automatically
/// rebuilt if the flag later changes.
///
/// This flag can be specified when constructing a [MaterialApp] using the
/// [MaterialApp.useWindowingApi] property.
class Windowing extends InheritedWidget {
  /// Constructs a [Windowing] inherited widget which allows all descendents
  /// to query for [Windowing.useWindowingApi].
  const Windowing({super.key, required this.useWindowingApi, required super.child});

  /// When true, widgets that normally use an [Overlay] to float on top of the
  /// the application content will instead opt to use a true native window.
  /// This includes widgets such as [PopupMenuButton] and [DropdownButton], as
  /// well as constructs like [showMenu] and [showDialog].
  ///
  /// This flag only affects platforms that implement the windowing API.
  ///
  /// Defaults to false.
  final bool useWindowingApi;

  @override
  bool updateShouldNotify(Windowing oldWindowing) {
    return useWindowingApi != oldWindowing.useWindowingApi;
  }

  /// Returns the state of [Windowing.useWindowingApi]. If true, the consuming
  /// descendent should attempt to use the windowing API wherever applicable.
  ///
  /// Typical usage is as follows:
  /// ```dart
  /// bool useWindowingApi = Windowing.of(context);
  /// ```
  static bool of(BuildContext context) {
    final Windowing? windowing = context.dependOnInheritedWidgetOfExactType<Windowing>();
    return windowing?.useWindowingApi ?? false;
  }
}
