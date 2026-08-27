// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/avoid_future_catch_error.dart';
import 'src/rules/deprecation_syntax.dart';
import 'src/rules/golden_test_tags.dart';
import 'src/rules/integration_test_timeouts.dart';
import 'src/rules/issue_link_syntax.dart';
import 'src/rules/no_bad_imports_in_flutter.dart';
import 'src/rules/no_double_clamp.dart';
import 'src/rules/no_globals_in_flutter_tools.dart';
import 'src/rules/no_runtimetype_in_tostring.dart';
import 'src/rules/no_stopwatches.dart';
import 'src/rules/no_sync_async_star.dart';
import 'src/rules/no_test_imports.dart';
import 'src/rules/null_initialized_debug_expensive_fields.dart';
import 'src/rules/protect_public_state_subtypes.dart';
import 'src/rules/render_box_intrinsics.dart';
import 'src/rules/repository_link_syntax.dart';
import 'src/rules/skip_test_comments.dart';
import 'src/rules/taboo_documentation.dart';

final FlutterAnalyzerPlugin plugin = FlutterAnalyzerPlugin();

class FlutterAnalyzerPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(AvoidFutureCatchError())
      ..registerWarningRule(DeprecationSyntax())
      ..registerWarningRule(GoldenTestTags())
      ..registerWarningRule(IntegrationTestTimeouts())
      ..registerWarningRule(IssueLinkSyntax())
      ..registerWarningRule(NoBadImportsInFlutter())
      ..registerWarningRule(NoDoubleClamp())
      ..registerWarningRule(NoGlobalsInFlutterTools())
      ..registerWarningRule(NoRuntimeTypeInToString())
      ..registerWarningRule(NoStopwatches())
      ..registerWarningRule(NoSyncAsyncStar())
      ..registerWarningRule(NoTestImports())
      ..registerWarningRule(NullInitializedDebugExpensiveFields())
      ..registerWarningRule(ProtectPublicStateSubtypes())
      ..registerWarningRule(RenderBoxIntrinsicCalculationRule())
      ..registerWarningRule(RepositoryLinkSyntax())
      ..registerWarningRule(SkipTestComments())
      ..registerWarningRule(TabooDocumentation());
  }

  @override
  String get name => 'flutter/flutter analyzer plugin';
}
