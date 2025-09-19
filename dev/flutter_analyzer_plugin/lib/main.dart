// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'src/rules/avoid_future_catch_error.dart';
import 'src/rules/no_double_clamp.dart';
import 'src/rules/no_stopwatches.dart';
import 'src/rules/protect_public_state_subtypes.dart';
import 'src/rules/render_box_intrinsics.dart';

final FlutterAnalyzerPlugin plugin = FlutterAnalyzerPlugin();

class FlutterAnalyzerPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(AvoidFutureCatchError())
      ..registerWarningRule(NoDoubleClamp())
      ..registerWarningRule(NoStopwatches())
      ..registerWarningRule(ProtectPublicStateSubtypes())
      ..registerWarningRule(RenderBoxIntrinsicCalculationRule());
  }
}
