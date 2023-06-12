import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'common.dart';

void main() {
  group('MultiProvider', () {
    testWidgets('MultiProvider children can only access parent providers',
        (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      final p1 = Provider.value(key: k1, value: 42);
      final p2 = Provider.value(key: k2, value: 'foo');
      final p3 = Provider<double>.value(key: k3, value: 44);

      final keyChild = GlobalKey();
      await tester.pumpWidget(MultiProvider(
        providers: [p1, p2, p3],
        child: Text('Foo', key: keyChild, textDirection: TextDirection.ltr),
      ));

      expect(find.text('Foo'), findsOneWidget);

      // p1 cannot access to p1/p2/p3
      expect(
        () => Provider.of<int>(k1.currentContext!, listen: false),
        throwsProviderNotFound<int>(),
      );
      expect(
        () => Provider.of<String>(k1.currentContext!, listen: false),
        throwsProviderNotFound<String>(),
      );
      expect(
        () => Provider.of<double>(k1.currentContext!, listen: false),
        throwsProviderNotFound<double>(),
      );

      // p2 can access only p1
      expect(Provider.of<int>(k2.currentContext!, listen: false), 42);
      expect(
        () => Provider.of<String>(k2.currentContext!, listen: false),
        throwsProviderNotFound<String>(),
      );
      expect(
        () => Provider.of<double>(k2.currentContext!, listen: false),
        throwsProviderNotFound<double>(),
      );

      // p3 can access both p1 and p2
      expect(Provider.of<int>(k3.currentContext!, listen: false), 42);
      expect(Provider.of<String>(k3.currentContext!, listen: false), 'foo');
      expect(
        () => Provider.of<double>(k3.currentContext!, listen: false),
        throwsProviderNotFound<double>(),
      );

      // the child can access them all
      expect(Provider.of<int>(keyChild.currentContext!, listen: false), 42);
      expect(
        Provider.of<String>(keyChild.currentContext!, listen: false),
        'foo',
      );
      expect(Provider.of<double>(keyChild.currentContext!, listen: false), 44);
    });

    testWidgets('MultiProvider.providers with ignored child', (tester) async {
      final p1 = Provider.value(
        value: 42,
        child: const Text('Bar'),
      );

      await tester.pumpWidget(MultiProvider(
        providers: [p1],
        child: const Text('Foo', textDirection: TextDirection.ltr),
      ));

      expect(find.text('Bar'), findsNothing);
      expect(find.text('Foo'), findsOneWidget);
    });
  });
}
