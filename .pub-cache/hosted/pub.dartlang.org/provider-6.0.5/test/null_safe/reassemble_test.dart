import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ReassembleHandler extends ReassembleHandler {
  bool hasReassemble = false;

  @override
  void reassemble() {
    hasReassemble = true;
  }
}

void main() {
  testWidgets('ReassembleHandler', (tester) async {
    final provider = _ReassembleHandler();

    await tester.pumpWidget(
      Provider.value(
        value: provider,
        child: const SizedBox(),
      ),
    );

    // ignore: unawaited_futures
    tester.binding.reassembleApplication();
    await tester.pump();

    expect(provider.hasReassemble, equals(true));
  });

  testWidgets('unevaluated create', (tester) async {
    final provider = _ReassembleHandler();

    await tester.pumpWidget(
      Provider(
        create: (_) => provider,
        child: const SizedBox(),
      ),
    );

    // ignore: unawaited_futures
    tester.binding.reassembleApplication();
    await tester.pump();

    expect(provider.hasReassemble, equals(false));
  });

  testWidgets('unevaluated create', (tester) async {
    final provider = _ReassembleHandler();

    await tester.pumpWidget(
      Provider(
        create: (_) => provider,
        builder: (context, _) {
          context.watch<_ReassembleHandler>();
          return Container();
        },
      ),
    );

    // ignore: unawaited_futures
    tester.binding.reassembleApplication();
    await tester.pump();

    expect(provider.hasReassemble, equals(true));
  });
}
