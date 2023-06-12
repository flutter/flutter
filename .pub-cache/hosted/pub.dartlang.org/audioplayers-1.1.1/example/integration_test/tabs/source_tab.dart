import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../platform_features.dart';
import '../source_test_data.dart';
import '../test_utils.dart';

Future<void> testSourcesTab(
  WidgetTester tester,
  SourceTestData audioSourceTestData,
  PlatformFeatures features,
) async {
  printOnFailure('Test Sources Tab');
  await tester.tap(find.byKey(const Key('sourcesTab')));
  await tester.pumpAndSettle();

  await tester.testSource(audioSourceTestData.sourceKey);
}

extension ControlsWidgetTester on WidgetTester {
  Future<void> testSource(String sourceKey) async {
    printOnFailure('Test setting source: $sourceKey');
    final st = StackTrace.current.toString();
    final sourceWidgetKey = Key('setSource-$sourceKey');
    await scrollTo(sourceWidgetKey);
    await tap(find.byKey(sourceWidgetKey));

    // Wait for toast appearance and disappearance
    await waitFor(
      () async => expect(
        find.byKey(const Key('toast-source-set')),
        findsOneWidget,
      ),
      timeout: const Duration(seconds: 180),
      stackTrace: st,
    );
    await waitFor(
      () async => expect(
        find.byKey(const Key('toast-source-set')),
        findsNothing,
      ),
      stackTrace: st,
    );
  }
}
