// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'src/rules/avoid_future_catch_error.dart';
import 'src/rules/no_double_clamp.dart';
import 'src/rules/no_runtimetype_in_tostring.dart';
import 'src/rules/no_stopwatches.dart';
import 'src/rules/null_initialized_debug_expensive_fields.dart';
import 'src/rules/protect_public_state_subtypes.dart';
import 'src/rules/render_box_intrinsics.dart';

final FlutterAnalyzerPlugin plugin = FlutterAnalyzerPlugin();

class FlutterAnalyzerPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(AvoidFutureCatchError())
      ..registerWarningRule(NoDoubleClamp())
      ..registerWarningRule(NoRuntimeTypeInToString())
      ..registerWarningRule(NoStopwatches())
      ..registerWarningRule(NullInitializedDebugExpensiveFields())
      ..registerWarningRule(ProtectPublicStateSubtypes())
      ..registerWarningRule(RenderBoxIntrinsicCalculationRule());
  }

  @override
  String get name => 'flutter/flutter analyzer plugin';
}
