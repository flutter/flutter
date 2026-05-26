import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:android_driver_extensions/native_driver.dart';
// ignore: unused_import
import 'package:android_driver_extensions/skia_gold.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

/// Whether the current environment is LUCI.
bool get isLuci => io.Platform.environment["LUCI_CI"] == "True";

/// What golden suffix this test should use for different engine configurations.
String get goldenVariant {
  final String? variant =
      io.Platform.environment["ANDROID_HARDWARE_SMOKE_TEST_GOLDEN_VARIANT"];
  if (variant == null || variant.isEmpty) {
    return "";
  }
  return ".$variant";
}

void main() async {
  late final FlutterDriver flutterDriver;

  setUpAll(() async {
    if (isLuci) {
      await enableSkiaGoldComparator(
        namePrefix: "android_hardware_smoke_test$goldenVariant",
      );
    }
    flutterDriver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await flutterDriver.close();
  });

  Future<void> templateTest(String testName) async {
    // Ask the app to render the test and return the rendered image bytes
    final String response = await flutterDriver.requestData(
      json.encode(<String, Object?>{
        "testName": testName,
        "performAppSideGoldenCompare": false,
      }),
    );

    // Expect a successful reply
    final Map<String, Object?> reply =
        (json.decode(response) as Map<Object?, Object?>)
            .cast<String, Object?>();
    expect(reply["message"], equals("Rendered $testName"));

    // Compare the bytes to a golden file on the host filesystem
    final String imageBase64 = reply["imageBytes"]! as String;
    final Uint8List imageBytes = base64.decode(imageBase64);
    await expectLater(
      imageBytes,
      matchesGoldenFile("goldens/$testName$goldenVariant.png"),
    );
  }

  test("should render and match blueRectangleTest golden", () async {
    await templateTest("blueRectangleTest");
  }, timeout: Timeout.none);

  test("should render and match trianglePathTest golden", () async {
    await templateTest("trianglePathTest");
  }, timeout: Timeout.none);
}
