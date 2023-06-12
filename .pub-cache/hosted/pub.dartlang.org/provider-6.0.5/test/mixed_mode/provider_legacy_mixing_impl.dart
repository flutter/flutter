/////// Mixed mode: test is legacy, runtime is legacy, package:provider is null safe.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'common_legacy.dart';

void main() {
  // See `provider_test.dart` for corresponding sound mode test.
  testWidgets('unsound provide T* inject T', (tester) async {
    late double value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double>.
        value = Provider.of<double>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double*>.
      legacyProviderOfValue<double>(
        24,
        Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(24.0));
  });

  testWidgets('unsound provide T* inject T?', (tester) async {
    late double? value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double?>.
        value = Provider.of<double?>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double>.
      legacyProviderOfValue<double>(
        24,
        Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(24.0));
  });

  testWidgets('unsound provide T inject T', (tester) async {
    late double value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double>.
        value = Provider.of<double>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double>.
      Provider<double>.value(
        value: 24,
        child: Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(24.0));
  });

  testWidgets('unsound provide T inject T?', (tester) async {
    late double? value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double>.
        value = Provider.of<double?>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double>.
      Provider<double>.value(
        value: 24,
        child: Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(24.0));
  });

  testWidgets('unsound provide T inject T', (tester) async {
    late double? value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double>.
        value = Provider.of<double>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double>.
      Provider<double>.value(
        value: 24,
        child: Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(24.0));
  });

  testWidgets('unsound provide T? inject T', (tester) async {
    late double? value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double>.
        value = Provider.of<double>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double?>.
      Provider<double?>.value(
        value: 24,
        child: Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(24.0));
  });

  testWidgets('unsound provide T? inject T?', (tester) async {
    late double? value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double>.
        value = Provider.of<double?>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double?>.
      Provider<double?>.value(
        value: 24,
        child: Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(24.0));
  });

  // See `provider_test.dart` for corresponding sound mode test.
  testWidgets('unsound provide null T* inject T', (tester) async {
    late double value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double>.
        value = Provider.of<double>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double*>.
      legacyProviderOfValue<double>(
        null,
        Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(null));
  });

  testWidgets('unsound provide null T* inject T?', (tester) async {
    late double? value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double?>.
        value = Provider.of<double?>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double>.
      legacyProviderOfValue<double>(
        null,
        Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(null));
  });

  testWidgets('unsound provide null T? inject T', (tester) async {
    late double value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double>.
        value = Provider.of<double>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double?>.
      Provider<double?>.value(
        value: null,
        child: Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(null));
  });

  testWidgets('unsound provide null T? inject T?', (tester) async {
    late double? value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double>.
        value = Provider.of<double?>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double?>.
      Provider<double?>.value(
        value: null,
        child: Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(null));
  });
}
