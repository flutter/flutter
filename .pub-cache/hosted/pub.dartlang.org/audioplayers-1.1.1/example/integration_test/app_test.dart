import 'package:audioplayers_example/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'platform_features.dart';
import 'source_test_data.dart';
import 'tabs/context_tab.dart';
import 'tabs/controls_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/source_tab.dart';
import 'tabs/stream_tab.dart';

void main() {
  final features = PlatformFeatures.instance();

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify app is launched', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(
        find.text('Remote URL WAV 1 - coins.wav'),
        findsOneWidget,
      );
    });
  });

  group('test functionality of sources', () {
    final audioTestDataList = [
      if (features.hasUrlSource)
        SourceTestData(
          sourceKey: 'url-remote-wav-1',
          duration: const Duration(milliseconds: 451),
        ),
      if (features.hasUrlSource)
        SourceTestData(
          sourceKey: 'url-remote-wav-2',
          duration: const Duration(seconds: 1, milliseconds: 068),
        ),
      if (features.hasUrlSource)
        SourceTestData(
          sourceKey: 'url-remote-mp3-1',
          duration: const Duration(minutes: 3, seconds: 30, milliseconds: 77),
        ),
      if (features.hasUrlSource)
        SourceTestData(
          sourceKey: 'url-remote-mp3-2',
          duration: const Duration(minutes: 1, seconds: 34, milliseconds: 119),
        ),
      if (features.hasUrlSource && features.hasPlaylistSourceType)
        SourceTestData(
          sourceKey: 'url-remote-m3u8',
          duration: Duration.zero,
          isLiveStream: true,
        ),
      if (features.hasUrlSource)
        SourceTestData(
          sourceKey: 'url-remote-mpga',
          duration: Duration.zero,
          isLiveStream: true,
        ),
      if (features.hasAssetSource)
        SourceTestData(
          sourceKey: 'asset-wav',
          duration: const Duration(seconds: 1, milliseconds: 068),
        ),
      if (features.hasAssetSource)
        SourceTestData(
          sourceKey: 'asset-mp3',
          duration: const Duration(minutes: 1, seconds: 34, milliseconds: 119),
        ),
      if (features.hasBytesSource)
        SourceTestData(
          sourceKey: 'bytes-local',
          duration: const Duration(seconds: 1, milliseconds: 068),
        ),
      if (features.hasBytesSource)
        SourceTestData(
          sourceKey: 'bytes-remote',
          duration: const Duration(minutes: 3, seconds: 30, milliseconds: 76),
        ),
    ];

    for (final audioSourceTestData in audioTestDataList) {
      testWidgets('test source $audioSourceTestData',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await testSourcesTab(tester, audioSourceTestData, features);
        await testControlsTab(tester, audioSourceTestData, features);
        await testStreamsTab(tester, audioSourceTestData, features);
        await testContextTab(tester, audioSourceTestData, features);
        await testLogsTab(tester, audioSourceTestData, features);
      });
    }
  });

  group('play multiple sources', () {
    // TODO(Gustl22): play sources simultaneously
    // TODO(Gustl22): play one source after another
  });
}
