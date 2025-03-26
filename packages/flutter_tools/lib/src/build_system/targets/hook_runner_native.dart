// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../asset.dart';
import '../../build_info.dart';
import '../../globals.dart' as globals;
import '../../hook_runner.dart' show FlutterHookRunner;
import '../../isolated/native_assets/dart_hook_result.dart' show DartHookResult;
import '../build_system.dart' show BuildResult, Environment, ExceptionMeasurement;
import 'native_assets.dart' show DartBuild;

class FlutterHookRunnerNative extends FlutterHookRunner {
  FlutterHookRunnerNative();

  @override
  Future<FlutterHookResult> runHooks({
    required TargetPlatform targetPlatform,
    required Environment environment,
  }) async {
    globals.printTrace('runDartBuild() with ${environment.defines} and $targetPlatform');
    if (dartDataHookResult?.isUpToDate(globals.fs) ?? false) {
      globals.printTrace('runDartBuild() - up-to-date already');
      return dartDataHookResult!;
    }
    globals.printTrace('runDartBuild() - will perform dart build');

    final BuildResult lastBuild = await globals.buildSystem.build(
      DartBuild(specifiedTargetPlatform: targetPlatform),
      environment,
    );
    if (!lastBuild.success) {
      for (final ExceptionMeasurement exceptionMeasurement in lastBuild.exceptions.values) {
        globals.printError(
          exceptionMeasurement.exception.toString(),
          stackTrace: globals.logger.isVerbose ? exceptionMeasurement.stackTrace : null,
        );
      }
    }

    dartDataHookResult = await DartBuild.loadHookResult(
      environment,
    ).then((DartHookResult hookResult) => hookResult.asFlutterResult);
    globals.printTrace('runDartBuild() - done');
    return dartDataHookResult!;
  }
}
