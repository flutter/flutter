// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// How GN's vocabulary maps onto the Bazel workspace: labels, configs,
/// conditions and the variables of GN's built-in rules.
///
/// These tables are the converter's knowledge of the engine. Everything that
/// is not in them is an error at conversion time; adding to them is how the
/// converter's coverage grows.
library;

import 'gn_ast.dart';
import 'gn_eval.dart';

/// Where the engine's GN root (`//`) lives in the Bazel workspace.
const String bazelRootPackage = '//engine/src';

/// The `size` of a generated `cc_test`. GN has no notion of it; the engine's
/// suites are small unless listed in [testSizes].
const String defaultTestSize = 'small';

/// Test targets (by GN name) that need more than the default size.
const Map<String, String> testSizes = <String, String>{};

/// GN labels with a Bazel home that is not the mechanical translation.
///
/// Keys are GN labels as written (without the implicit `:name` for
/// directory labels); values are Bazel labels.
const Map<String, String> labelOverrides = <String, String>{
  // Synced dependencies with overlay BUILD files.
  '//flutter/third_party/icu': '@icu',
  '//flutter/third_party/icu:icu': '@icu',
  '//flutter/third_party/icu:icuuc': '@icu//:icuuc',
  '//flutter/third_party/icu:icui18n': '@icu//:icui18n',
  '//flutter/third_party/zlib': '@zlib',
  '//flutter/third_party/zlib:zlib': '@zlib',
  '//flutter/third_party/googletest:gtest': '@googletest//:gtest',
  '//flutter/third_party/googletest:gtest_main': '@googletest//:gtest_main',
  '//flutter/third_party/googletest:gmock': '@googletest//:gtest',
  // The secondary tree's forwarders.
  '//third_party/icu': '@icu',
  '//third_party/zlib': '@zlib',
  '//third_party/boringssl': '//engine/src/flutter/third_party/boringssl',
  // The Dart SDK, built by gn_build.
  '//flutter/third_party/dart/runtime:dart_api': '@dart//:dart_api_headers',
  '//flutter/third_party/dart/runtime:libdart_jit':
      '//engine/src/flutter/build/bazel/dart_wrap:libdart_jit',
  '//flutter/third_party/dart/runtime/bin:common_embedder_dart_io':
      '//engine/src/flutter/build/bazel/dart_wrap:common_embedder_dart_io',
  '//flutter/third_party/dart/runtime/bin:elf_loader':
      '//engine/src/flutter/build/bazel/dart_wrap:elf_loader',
  '//flutter/third_party/dart/runtime/bin:native_assets_api':
      '//engine/src/flutter/build/bazel/dart_wrap:native_assets_api',
  '//flutter/third_party/dart/third_party/double-conversion/src:libdouble_conversion':
      '//engine/src/flutter/build/bazel/dart_wrap:libdouble_conversion',
  '//flutter/third_party/dart/third_party/perfetto:libprotozero':
      '//engine/src/flutter/build/bazel/dart_wrap:libprotozero',
  '//third_party/perfetto:libprotozero': '//engine/src/flutter/build/bazel/dart_wrap:libprotozero',
};

/// Label prefixes that map to external repositories: `//third_party/abseil-cpp/absl/x:y`
/// becomes `@abseil-cpp//absl/x:y`.
const Map<String, String> labelRepositoryPrefixes = <String, String>{
  '//third_party/abseil-cpp/': '@abseil-cpp//',
};

/// Translates a GN label to a Bazel label.
///
/// [package] is the GN directory of the file being converted (`//flutter/fml`),
/// for `:local` labels; [location] is where the label was written, for the
/// error when it has no Bazel home.
String bazelLabel(String gnLabel, {required String package, GnLocation? location}) {
  if (gnLabel.startsWith(':')) {
    return gnLabel;
  }
  final String? override = labelOverrides[gnLabel];
  if (override != null) {
    return override;
  }
  for (final MapEntry<String, String> entry in labelRepositoryPrefixes.entries) {
    if (gnLabel.startsWith(entry.key)) {
      return entry.value + gnLabel.substring(entry.key.length);
    }
  }
  if (gnLabel.startsWith('//flutter/') || gnLabel == '//flutter') {
    return '$bazelRootPackage${gnLabel.substring(1)}';
  }
  throw GnError(location ?? GnLocation(package, 0, 0), 'no Bazel home for label $gnLabel');
}

/// What a GN config contributes to the target that lists it.
sealed class ConfigEffect {
  const ConfigEffect();
}

/// The config is a dependency on a Bazel target carrying its defines and
/// include directories.
final class ConfigDependency extends ConfigEffect {
  const ConfigDependency(this.label);

  final String label;
}

/// The config is implied by something else (a dependency that already
/// carries it) and needs nothing.
final class ConfigImplied extends ConfigEffect {
  const ConfigImplied();
}

/// The config selects the warning set: `chromium_code` or not.
final class ConfigWarningSet extends ConfigEffect {
  const ConfigWarningSet({required this.chromiumCode});

  final bool chromiumCode;
}

/// The configs the engine's build files mention, outside their own package.
const Map<String, ConfigEffect> configEffects = <String, ConfigEffect>{
  '//flutter:config': ConfigDependency('//engine/src/flutter:config'),
  '//flutter/common:flutter_config': ConfigDependency('//engine/src/flutter/common:flutter_config'),
  '//flutter/third_party/icu:icu_config': ConfigImplied(),
  '//build/config/compiler:chromium_code': ConfigWarningSet(chromiumCode: true),
  '//build/config/compiler:no_chromium_code': ConfigWarningSet(chromiumCode: false),
};

/// The Bazel config_setting (or constraint) for a GN platform predicate.
const Map<String, String> conditionSettings = <String, String>{
  'is_android': '@platforms//os:android',
  'is_fuchsia': '@platforms//os:fuchsia',
  'is_ios': '@platforms//os:ios',
  'is_linux': '@platforms//os:linux',
  'is_mac': '@platforms//os:macos',
  'is_qnx': '@platforms//os:qnx',
  'is_win': '@platforms//os:windows',
};

/// GN variables an imported `.gni` defines and that build files may read or
/// test. Reads become references that [referenceConstants] resolve.
const Set<String> knownExternalVariables = <String>{
  // //build/config/BUILDCONFIG.gn
  'current_cpu',
  'current_os',
  'host_os',
  'is_android',
  'is_apple',
  'is_debug',
  'is_fuchsia',
  'is_ios',
  'is_linux',
  'is_mac',
  'is_qnx',
  'is_wasm',
  'is_win',
  'target_cpu',
  'target_os',
  // //flutter/common/config.gni
  'enable_backtrace',
  'enable_unittests',
  'flutter_cflags_objc',
  'flutter_cflags_objcc',
  'flutter_runtime_mode',
  'slimpeller',
  // //flutter/tools/fuchsia/gn-sdk/src/gn_configs.gni
  'fuchsia_arch_root',
  'fuchsia_sdk',
};

/// Starlark expressions for GN references that have a Bazel-side constant.
const Map<String, String> referenceConstants = <String, String>{
  'flutter_cflags_objc': 'FLUTTER_CFLAGS_OBJC',
  'flutter_cflags_objcc': 'FLUTTER_CFLAGS_OBJCC',
};

/// The `.gni` templates the converter knows, with the Bazel macro for each
/// (`load` label and symbol).
final class TemplateMapping {
  const TemplateMapping(this.bzl, this.symbol);

  final String bzl;
  final String symbol;
}

const Map<String, TemplateMapping> templateMappings = <String, TemplateMapping>{
  'test_fixtures': TemplateMapping(
    '//engine/src/flutter/testing:testing.bzl',
    'flutter_test_fixtures',
  ),
};

/// Which assumptions describe the Linux x64 host build. Everything not fixed
/// here stays a select().
Assumptions linuxHostAssumptions() {
  return Assumptions(const <String, GnValue>{
    'current_cpu': GnStringValue('x64'),
    'current_os': GnStringValue('linux'),
    'host_os': GnStringValue('linux'),
    'target_cpu': GnStringValue('x64'),
    'target_os': GnStringValue('linux'),
    'is_android': GnBoolValue(false),
    'is_apple': GnBoolValue(false),
    'is_fuchsia': GnBoolValue(false),
    'is_ios': GnBoolValue(false),
    'is_linux': GnBoolValue(true),
    'is_mac': GnBoolValue(false),
    'is_qnx': GnBoolValue(false),
    'is_wasm': GnBoolValue(false),
    'is_win': GnBoolValue(false),
    'enable_backtrace': GnBoolValue(true),
    'enable_unittests': GnBoolValue(true),
  });
}
