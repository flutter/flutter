import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unity_widget/src/io/device_method.dart';
import 'package:flutter_unity_widget/src/io/io.dart';
import 'package:flutter_unity_widget/src/io/unity_widget.dart';
import 'package:flutter_unity_widget/src/io/unity_widget_platform.dart';

import 'fake_unity_widget_controllers.dart';

Future<void> main() async {
  const MethodChannel channel = MethodChannel('plugin.xraph.com/unity_view');
  final FakePlatformViewsController fakePlatformViewsController =
      FakePlatformViewsController();

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SystemChannels.platform_views.setMockMethodCallHandler(
        fakePlatformViewsController.fakePlatformViewsMethodHandler);
  });

  setUp(() {
    fakePlatformViewsController.reset();
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  testWidgets('Unity widget ready', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: UnityWidget(
          onUnityCreated: (UnityWidgetController controller) {},
          printSetupLog: false,
        ),
      ),
    );

    final FakePlatformUnityWidget platformUnityWidget =
        fakePlatformViewsController.lastCreatedView!;

    expect(platformUnityWidget.unityReady, true);
    expect(find.byType(UnityWidget), findsOneWidget);
  });

  testWidgets('Unity widget pause called successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: UnityWidget(
          onUnityCreated: (UnityWidgetController controller) {},
          printSetupLog: false,
        ),
      ),
    );

    final FakePlatformUnityWidget platformUnityWidget =
        fakePlatformViewsController.lastCreatedView!;

    platformUnityWidget.pause();
    expect(platformUnityWidget.unityPaused, true);
    expect(find.byType(UnityWidget), findsOneWidget);
  });

  testWidgets(
    'Default Android widget is AndroidView',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: UnityWidget(
            onUnityCreated: (UnityWidgetController controller) {},
            printSetupLog: false,
          ),
        ),
      );

      expect(find.byType(AndroidView), findsOneWidget);
      expect(find.byType(UnityWidget), findsOneWidget);
    },
  );

  testWidgets('Use PlatformViewLink on Android', (WidgetTester tester) async {
    final MethodChannelUnityWidget platform =
        UnityWidgetPlatform.instance as MethodChannelUnityWidget;
    platform.useAndroidViewSurface = true;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: UnityWidget(
          onUnityCreated: (UnityWidgetController controller) {},
          printSetupLog: false,
          useAndroidViewSurface: true,
        ),
      ),
    );

    expect(find.byType(PlatformViewLink), findsOneWidget);
    platform.useAndroidViewSurface = true;
    expect(find.byType(UnityWidget), findsOneWidget);
  });
}
