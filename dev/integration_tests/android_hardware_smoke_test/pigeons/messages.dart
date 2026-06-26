// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/app/src/main/kotlin/com/example/android_hardware_smoke_test/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.example.android_hardware_smoke_test'),
    dartPackageName: 'android_hardware_smoke_test',
  ),
)
enum TestScenario {
  blueRectangle,
  trianglePath,
  text,
  image,
  advancedBlend,
  backdropFilterBlur,
  platformViewTextureLayer,
  platformViewHybridComposition,
  platformViewHybridCompositionPlusPlus,
}

class RenderRequest {
  const RenderRequest({
    required this.scenario,
    required this.performAppSideGoldenCompare,
    required this.captureScreenshot,
  });
  final TestScenario scenario;
  final bool performAppSideGoldenCompare;
  final bool captureScreenshot;
}

class RenderReply {
  const RenderReply({
    required this.message,
    this.reason,
    this.x,
    this.y,
    this.width,
    this.height,
    this.imageBytes,
  });
  final String message;
  final String? reason;
  final int? x;
  final int? y;
  final int? width;
  final int? height;
  final Uint8List? imageBytes;
}

class CompareGoldenRequest {
  const CompareGoldenRequest({required this.scenario, required this.imageBytes});
  final TestScenario scenario;
  final Uint8List imageBytes;
}

class CompareGoldenReply {
  const CompareGoldenReply({required this.message});
  final String message;
}

@HostApi()
abstract class NativeSupportApi {
  String? getImpellerBackend();
}

@FlutterApi()
abstract class SmokeTestFlutterApi {
  @async
  RenderReply renderTest(RenderRequest request);

  @async
  CompareGoldenReply compareGolden(CompareGoldenRequest request);
}
