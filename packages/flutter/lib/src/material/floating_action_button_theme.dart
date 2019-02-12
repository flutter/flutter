import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class FloatingActionButtonTheme extends InheritedWidget {
  /// Creates a FloatingActionButton theme.
  FloatingActionButtonTheme({
    Key key,
    @required this.data,
    @required Widget child,
  })  : assert(child != null),
        assert(data != null),
        super(key: key, child: child);

  final FloatingActionButtonThemeData data;

  @override
  bool updateShouldNotify(FloatingActionButtonTheme oldWidget) => data != oldWidget.data;
}

class FloatingActionButtonThemeData extends Diagnosticable {

}