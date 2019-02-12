import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// TODO(clocksmith): dartdoc
class FloatingActionButtonTheme extends InheritedWidget {
  /// Applies the given theme [data] to [child].
  ///
  /// The [data] and [child] arguments must not be null.
  FloatingActionButtonTheme({
    Key key,
    @required this.data,
    @required Widget child,
  })  : assert(child != null),
        assert(data != null),
        super(key: key, child: child);

  /// Specifies the color, shape, and text style values for descendant floating
  /// action button widgets.
  final FloatingActionButtonThemeData data;

  /// Returns the data from the closest [FloatingActionButtonTheme] instance
  /// that encloses the given context.
  ///
  /// Defaults to the ambient [ThemeData.floatingActionButtonTheme] if there
  /// is no [FloatingActionButtonTheme] in the given build context.
  ///
  /// {@tool sample}
  ///
  /// ```dart
  /// class Spaceship extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return FloatingActionButtonTheme(
  ///       data: FloatingActionButtonTheme.of(context).copyWith(backgroundColor: Colors.red),
  ///       child: FloatingActionButton(
  ///         child: const Text('Launch'),
  ///         onPressed: () { print('We have liftoff!'); },
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [FloatingActionButtonThemeData], which describes the actual
  ///  configuration of a floating action button theme.
  static FloatingActionButtonThemeData of(BuildContext context) {
    final FloatingActionButtonTheme inheritedTheme = context.inheritFromWidgetOfExactType(FloatingActionButtonTheme);
    return inheritedTheme?.data ?? Theme.of(context).chipTheme;
  }

  @override
  bool updateShouldNotify(FloatingActionButtonTheme oldWidget) => data != oldWidget.data;
}

/// TODO(clocksmith): dartdoc
class FloatingActionButtonThemeData extends Diagnosticable {
  /// TODO(clocksmith): dartdoc
  const FloatingActionButtonThemeData({
    @required this.backgroundColor,
    @required this.foregroundColor,
  })  : assert(backgroundColor != null),
        assert(foregroundColor != null);

  factory FloatingActionButtonThemeData.fromDefaults({
    Brightness brightness,
    Color primaryColor,
    Color onPrimaryColor,
    @required TextStyle textStyle,
  }) {
    return FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
    );
}

  /// Color to be used for the unselected, enabled floating action buttons's
  /// background.
  ///
  /// The default is the primary color.
  final Color backgroundColor;

  /// Color to be used for the unselected, enabled floating action buttons's
  /// foreground.
  ///
  /// The default is the onPrimary color.
  final Color foregroundColor;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  FloatingActionButtonThemeData copyWith({
    Color backgroundColor,
    Color foregroundColor,
  }) {
    return FloatingActionButtonThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
    );
  }

  static FloatingActionButtonThemeData lerp(FloatingActionButtonThemeData a, FloatingActionButtonThemeData b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    return FloatingActionButtonThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
    );
  }
  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      foregroundColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final FloatingActionButtonThemeData otherData = other;
    return otherData.backgroundColor == backgroundColor
        && otherData.foregroundColor == foregroundColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final ThemeData defaultTheme = ThemeData.fallback();
    final FloatingActionButtonThemeData defaultData = FloatingActionButtonThemeData.fromDefaults(
      primaryColor: defaultTheme.primaryColor,
      onPrimaryColor: Colors.white, // This is wrong
      brightness: defaultTheme.brightness,
      textStyle: defaultTheme.textTheme.body2,
    );
    properties.add(DiagnosticsProperty<Color>('backgroundColor', backgroundColor, defaultValue: defaultData.backgroundColor));
    properties.add(DiagnosticsProperty<Color>('foregroundColor', foregroundColor, defaultValue: defaultData.foregroundColor));
  }
}