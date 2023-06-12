import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';

import 'provider.dart';

/// {@macro provider.valuelistenableprovider}
class ValueListenableProvider<T> extends SingleChildStatelessWidget {
  /// {@template provider.valuelistenableprovider}
  /// Listens to a [ValueListenable] and exposes its current value.
  ///
  /// This is useful for testing purposes, to easily simular a provider update:
  ///
  /// ```dart
  /// testWidgets('example', (tester) async {
  ///   // Create a ValueNotifier that tests will use to drive the application
  ///   final counter = ValueNotifier(0);
  ///
  ///   // Mount the application using ValueListenableProvider
  ///   await tester.pumpWidget(
  ///     ValueListenableProvider<int>.value(
  ///       value: counter,
  ///       child: MyApp(),
  ///     ),
  ///   );
  ///
  ///   // Tests can now simulate a provider update by updating the notifier
  ///   // then calling tester.pump()
  ///   counter.value++;
  ///   await tester.pump();
  /// });
  /// ```
  /// {@endtemplate}
  ValueListenableProvider.value({
    Key? key,
    required ValueListenable<T> value,
    UpdateShouldNotify<T>? updateShouldNotify,
    Widget? child,
  })  : _valueListenable = value,
        _updateShouldNotify = updateShouldNotify,
        super(key: key, child: child);

  final ValueListenable<T> _valueListenable;
  final UpdateShouldNotify<T>? _updateShouldNotify;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return ValueListenableBuilder<T>(
      valueListenable: _valueListenable,
      builder: (context, value, _) {
        return Provider<T>.value(
          value: value,
          updateShouldNotify: _updateShouldNotify,
          child: child,
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('value', _valueListenable.value));
  }
}
