import 'equatable.dart';
import 'equatable_config.dart';
import 'equatable_utils.dart';

/// A mixin that helps implement equality
/// without needing to explicitly override [operator ==] and [hashCode].
///
/// Like with extending [Equatable], the [EquatableMixin] overrides the
/// [operator ==] as well as the [hashCode] based on the provided [props].
mixin EquatableMixin {
  /// {@macro equatable_props}
  List<Object?> get props;

  /// {@macro equatable_stringify}
  // ignore: avoid_returning_null
  bool? get stringify => null;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EquatableMixin &&
            runtimeType == other.runtimeType &&
            equals(props, other.props);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode(props);

  @override
  String toString() {
    switch (stringify) {
      case true:
        return mapPropsToString(runtimeType, props);
      case false:
        return '$runtimeType';
      default:
        return EquatableConfig.stringify == true
            ? mapPropsToString(runtimeType, props)
            : '$runtimeType';
    }
  }
}
