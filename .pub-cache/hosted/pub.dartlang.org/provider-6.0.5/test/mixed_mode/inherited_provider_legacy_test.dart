// Mixed mode: test is legacy, runtime is legacy, package:provider is null safe.
// @dart=2.11
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../null_safe/common.dart';

BuildContext get context => find.byType(Context).evaluate().single;

class Context extends StatelessWidget {
  const Context({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

void main() {
  testWidgets('allows nulls in mixed mode', (tester) async {
    // ignore: avoid_returning_null
    int initialValueBuilder(BuildContext _) => null;

    await tester.pumpWidget(
      InheritedProvider<int>(
        create: initialValueBuilder,
        child: const Context(),
      ),
    );

    expect(Provider.of<int>(context, listen: false), equals(null));
    expect(Provider.of<int>(context, listen: false), equals(null));
  });

  testWidgets(
      'throw ProviderNotFoundException in mixed mode if no provider exists',
      (tester) async {
    await tester.pumpWidget(const Context());

    expect(
      () => context.read<int>(),
      throwsProviderNotFound<int>(),
    );
  });
}
