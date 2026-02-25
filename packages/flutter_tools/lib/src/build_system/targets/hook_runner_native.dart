// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../asset.dart';
import '../../base/logger.dart' show Logger;
import '../../build_info.dart';
import '../../hook_runner.dart' show FlutterHookRunner;
import '../../isolated/native_assets/dart_hook_result.dart' show DartHooksResult;
import '../../isolated/native_assets/native_assets.dart';
import '../build_system.dart' show Environment;
import 'native_assets.dart' show createFlutterNativeAssetsBuildRunner;

class FlutterHookRunnerNative implements FlutterHookRunner {
  FlutterHookResult? _flutterHookResult;

  @visibleForTesting
  static const kHooksOutputDirectory = 'native_hooks';

  @override
  Future<FlutterHookResult> runHooks({
    required TargetPlatform targetPlatform,
    required Environment environment,
    Logger? logger,
  }) async {
    logger?.printTrace('runHooks() with ${environment.defines} and $targetPlatform');
    if (_flutterHookResult != null &&
        !_flutterHookResult!.hasAnyModifiedFiles(environment.fileSystem)) {
      logger?.printTrace('runHooks() - up-to-date already');
      return _flutterHookResult!;
    }
    logger?.printTrace('runHooks() - will perform dart build');

    final FlutterNativeAssetsBuildRunner buildRunner = await createFlutterNativeAssetsBuildRunner(
      environment,
    );

    final DartHooksResult dartHooksResult = await runFlutterSpecificHooks(
      environmentDefines: environment.defines,
      buildRunner: buildRunner,
      targetPlatform: targetPlatform,
      projectUri: environment.projectDir.uri,
      fileSystem: environment.fileSystem,
      buildCodeAssets: false,
      buildDataAssets: true,
    );

    final FlutterHookResult flutterHookResult = dartHooksResult.asFlutterResult;
    _flutterHookResult = flutterHookResult;
    logger?.printTrace('runHooks() - done');
    return flutterHookResult;
  }
}
