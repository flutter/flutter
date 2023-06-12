import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';

import 'common.dart';

class ValueBuilder extends Mock {
  int? call(BuildContext? context);
}

class Dispose extends Mock {
  void call(BuildContext context, int value);
}

void main() {
  testWidgets('works with MultiProvider', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(
            create: (_) => 42,
          ),
        ],
        child: TextOf<int>(),
      ),
    );

    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('calls create only once', (tester) async {
    final create = ValueBuilder();

    await tester.pumpWidget(Provider<int?>(
      create: create,
      child: TextOf<int?>(),
    ));

    await tester.pumpWidget(Provider<int?>(
      create: create,
      child: TextOf<int?>(),
    ));

    await tester.pumpWidget(Container());

    verify(create(any)).called(1);
  });

  testWidgets('dispose', (tester) async {
    final dispose = Dispose();

    await tester.pumpWidget(
      Provider<int>(
        create: (_) => 42,
        dispose: dispose,
        child: TextOf<int>(),
      ),
    );

    final context = findInheritedContext<int>();

    verifyZeroInteractions(dispose);
    await tester.pumpWidget(Container());
    verify(dispose(context, 42)).called(1);
  });
}
