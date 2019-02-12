import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// TODO(clockismith): this
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

class FloatingActionButtonThemeData extends Diagnosticable {

}