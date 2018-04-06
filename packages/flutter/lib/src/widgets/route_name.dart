import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A widget which provides a semantic name route name.
///
/// See also:
///
///   * [SemanticsProperties.route], for a description of how route name
///     semantics work.
class RouteName extends StatelessWidget {

  /// Creates a widget which provides a semantic route name.
  ///
  /// [child] and [name] are required arguments.
  const RouteName({
    Key key,
    @required this.child,
    @required this.name,
  }) : assert(child != null),
       assert(name != null),
       super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// A semantic name for the route.
  final String name;

  @override
  Widget build(BuildContext context) {
    return new Semantics(
      route: true,
      explicitChildNodes: true,
      value: name,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(new StringProperty('name', name, defaultValue: ''));
  }
}
