// ignore_for_file: unused_import
import 'dart:convert';
import 'dart:typed_data';
import 'package:android_driver_extensions/native_driver.dart';
import 'package:android_driver_extensions/skia_gold.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() async {
  late final FlutterDriver flutterDriver;

  setUpAll(() async {
    // If running on CI, this will seamlessly initialize Skia Gold comparisons
    // await enableSkiaGoldComparator(namePrefix: 'android_hardware_smoke_test');
    flutterDriver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await flutterDriver.close();
  });

  test('should render and match fooTest golden', () async {
    // 1. Command the app to render fooTest and return its screenshot bytes
    final String response = await flutterDriver.requestData(
      json.encode(<String, dynamic>{
        'testName': 'fooTest',
        'performAppSideGoldenCompare': false,
      }),
    );

    // 2. Assert on status message
    final dynamic reply = json.decode(response);
    expect(reply['message'], equals('Rendered fooTest'));

    // 3. Extract and decode the base64 screenshot bytes
    final String imageBase64 = reply['imageBytes'] as String;
    final Uint8List imageBytes = base64.decode(imageBase64);

    // 4. Compare on the host filesystem relative to integration_test/goldens/
    await expectLater(imageBytes, matchesGoldenFile('goldens/fooTest.png'));
  }, timeout: Timeout.none);

  test('should render and match barTest golden', () async {
    // 1. Command the app to render barTest and return its screenshot bytes
    final String response = await flutterDriver.requestData(
      json.encode(<String, dynamic>{
        'testName': 'barTest',
        'performAppSideGoldenCompare': false,
      }),
    );

    // 2. Assert on status message
    final dynamic reply = json.decode(response);
    expect(reply['message'], equals('Rendered barTest'));

    // 3. Extract and decode the base64 screenshot bytes
    final String imageBase64 = reply['imageBytes'] as String;
    final Uint8List imageBytes = base64.decode(imageBase64);

    // 4. Compare on the host filesystem relative to integration_test/goldens/
    await expectLater(imageBytes, matchesGoldenFile('goldens/barTest.png'));
  }, timeout: Timeout.none);
}
