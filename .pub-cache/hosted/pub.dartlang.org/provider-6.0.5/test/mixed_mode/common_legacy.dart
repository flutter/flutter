// @dart=2.11
import 'package:provider/provider.dart';

/// Given `T`, returns a `Provider<T>`.
///
/// For use in legacy tests: they can't instantiate a `Provider<T?>` directly
/// because they can't write `<T?>`. But, they can pass around a `Provider<T?`>.
Provider<T> legacyProviderOfValue<T>(T value, Provider child) =>
    Provider<T>.value(
      value: value,
      child: child,
    );
