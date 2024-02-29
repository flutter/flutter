// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../build_info.dart' show BuildMode;
import '../convert.dart';
import 'compile.dart';

enum CompileTarget {
  js,
  wasm,
}

sealed class WebCompilerConfig {
  const WebCompilerConfig({required this.renderer, required this.optimizationLevel});

  /// The default optimization level for dart2js/dart2wasm.
  static const int kDefaultOptimizationLevel = 4;

  /// Build environment flag for [optimizationLevel].
  static const String kOptimizationLevel = 'OptimizationLevel';

  /// The compiler optimization level.
  ///
  /// Valid values are O1 (lowest, profile default) to O4 (highest, release default).
  final int optimizationLevel;

  /// Returns which target this compiler outputs (js or wasm)
  CompileTarget get compileTarget;
  final WebRendererMode renderer;

  String get buildKey;

  Map<String, Object> get buildEventAnalyticsValues => <String, Object>{
    'optimizationLevel': optimizationLevel,
  };


  Map<String, dynamic> get _buildKeyMap => <String, dynamic>{
    'optimizationLevel': optimizationLevel,
  };
}

/// Configuration for the Dart-to-Javascript compiler (dart2js).
class JsCompilerConfig extends WebCompilerConfig {
  const JsCompilerConfig({
    this.csp = false,
    this.dumpInfo = false,
    this.nativeNullAssertions = false,
    super.optimizationLevel = WebCompilerConfig.kDefaultOptimizationLevel,
    this.noFrequencyBasedMinification = false,
    this.sourceMaps = true,
    super.renderer = WebRendererMode.auto,
  });

  /// Instantiates [JsCompilerConfig] suitable for the `flutter run` command.
  const JsCompilerConfig.run({
    required bool nativeNullAssertions,
    required WebRendererMode renderer,
  }) : this(
          nativeNullAssertions: nativeNullAssertions,
          optimizationLevel: WebCompilerConfig.kDefaultOptimizationLevel ,
          renderer: renderer,
        );

  /// Build environment flag for [dumpInfo].
  static const String kDart2jsDumpInfo = 'Dart2jsDumpInfo';

  /// Build environment flag for [noFrequencyBasedMinification].
  static const String kDart2jsNoFrequencyBasedMinification =
      'Dart2jsNoFrequencyBasedMinification';

  /// Build environment flag for [csp].
  static const String kCspMode = 'cspMode';

  /// Build environment flag for [sourceMaps].
  static const String kSourceMapsEnabled = 'SourceMaps';

  /// Build environment flag for [nativeNullAssertions].
  static const String kNativeNullAssertions = 'NativeNullAssertions';

  /// Whether to disable dynamic generation code to satisfy CSP policies.
  final bool csp;

  /// If `--dump-info` should be passed to the compiler.
  final bool dumpInfo;

  /// Whether native null assertions are enabled.
  final bool nativeNullAssertions;

  // If `--no-frequency-based-minification` should be passed to dart2js
  // TODO(kevmoo): consider renaming this to be "positive". Double negatives are confusing.
  final bool noFrequencyBasedMinification;

  /// `true` if the JavaScript compiler build should output source maps.
  final bool sourceMaps;

  @override
  CompileTarget get compileTarget => CompileTarget.js;

  /// Arguments to use in both phases: full JS compile and CFE-only.
  List<String> toSharedCommandOptions() => <String>[
        if (nativeNullAssertions) '--native-null-assertions',
        if (!sourceMaps) '--no-source-maps',
      ];

  /// Arguments to use in the full JS compile, but not CFE-only.
  ///
  /// Includes the contents of [toSharedCommandOptions].
  List<String> toCommandOptions(BuildMode buildMode) => <String>[
        if (buildMode == BuildMode.profile) '--no-minify',
        ...toSharedCommandOptions(),
        '-O$optimizationLevel',
        if (dumpInfo) '--dump-info',
        if (noFrequencyBasedMinification) '--no-frequency-based-minification',
        if (csp) '--csp',
      ];

  @override
  String get buildKey {
    final Map<String, dynamic> settings = <String, dynamic>{
      ...super._buildKeyMap,
      'csp': csp,
      'dumpInfo': dumpInfo,
      'nativeNullAssertions': nativeNullAssertions,
      'noFrequencyBasedMinification': noFrequencyBasedMinification,
      'sourceMaps': sourceMaps,
    };
    return jsonEncode(settings);
  }
}

/// Configuration for the Wasm compiler.
class WasmCompilerConfig extends WebCompilerConfig {
  const WasmCompilerConfig({
    super.optimizationLevel = WebCompilerConfig.kDefaultOptimizationLevel,
    this.stripWasm = true,
    super.renderer = WebRendererMode.auto,
  });

  /// Build environment for [stripWasm].
  static const String kStripWasm = 'StripWasm';

  /// Whether to strip the wasm file of static symbols.
  final bool stripWasm;

  @override
  CompileTarget get compileTarget => CompileTarget.wasm;

  List<String> toCommandOptions(BuildMode buildMode) {
    final bool stripSymbols = buildMode == BuildMode.release && stripWasm;
    return <String>[
      '-O$optimizationLevel',
      '--${stripSymbols ? 'no-' : ''}name-section',
    ];
  }

  @override
  String get buildKey {
    final Map<String, dynamic> settings = <String, dynamic>{
      ...super._buildKeyMap,
      'stripWasm': stripWasm,
    };
    return jsonEncode(settings);
  }
}
