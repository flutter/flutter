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

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'gn_ast.dart';
import 'gn_eval.dart';

/// Where the engine's GN root (`//`) lives in the Bazel workspace.
const String bazelRootPackage = '//engine/src';

/// The main repository's apparent name (`module(name = "flutter")` in
/// MODULE.bazel), as it must be written from an external repository that
/// the engine's module extension generates: such repositories see the root
/// module's repository mapping, in which the module's own name is itself.
const String mainRepositoryName = '@flutter';

/// The GN config engine code is compiled with (`-Wunreachable-code`, the
/// engine include roots); what tells engine code from the third-party trees
/// the engine describes with GN (Skia, the codecs), which get
/// `chromium_code` alone.
const String flutterConfigLabel = '//flutter:config';

/// What stands for GN's `//build/config/compiler:default_include_dirs`
/// (`-I//`, the source root), which BUILDCONFIG.gn applies to every target
/// and engine code relies on for its `flutter/...` includes. Every compiled
/// target of the main repository depends on it privately; the third-party
/// trees the engine describes with GN never use it.
const String defaultIncludeDirsLabel = '//engine/src:include_root';

/// The C++ standard library GN's BUILDCONFIG.gn links into every executable
/// and shared library (its default deps). The root `.bazelrc` attaches it to
/// executables through `--@bazel_tools//tools/cpp:link_extra_libs`, which
/// does not reach shared binaries; the converter lists it in their deps.
const String cxxRuntimeLabel = '//engine/src/flutter/build/bazel/toolchains:cxx_runtime';

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
  '//flutter/third_party/googletest:gtest_prod': '@googletest//:gtest_prod',
  // The secondary tree's forwarders.
  '//third_party/icu': '@icu',
  '//third_party/icu:icuuc': '@icu//:icuuc',
  '//third_party/zlib': '@zlib',
  '//third_party/freetype2': '@freetype2',
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
  // Skia, generated into @skia at fetch time from the engine's GN over the
  // synced tree (research/07), and Skia's codec and font dependencies, each
  // generated the same way from its own small GN file.
  '//flutter/skia': '@skia',
  '//flutter/skia:skia': '@skia',
  '//flutter/third_party/expat': '@expat',
  '//flutter/third_party/freetype2': '@freetype2',
  '//flutter/third_party/libjpeg-turbo': '@libjpeg-turbo',
  '//flutter/third_party/libpng': '@libpng',
  '//flutter/third_party/libwebp': '@libwebp',
  '//flutter/third_party/wuffs': '@wuffs',
  '//third_party/libpng': '@libpng',
  // The shader compiler's dependencies (research/08): engine GN in the
  // secondary tree over synced trees (inja, json, SPIRV-Cross, flatbuffers)
  // and SPIRV-Headers' own GN, each a fetch-time repository.
  '//third_party/inja': '@inja',
  '//flutter/third_party/json': '@json',
  '//third_party/spirv_cross_flutter': '@spirv-cross//:spirv_cross_flutter',
  '//flutter/third_party/flatbuffers': '@flatbuffers',
  '//flutter/third_party/vulkan-deps/spirv-headers/src': '@spirv-headers',
  '//flutter/third_party/vulkan-deps/spirv-tools/src': '@spirv-tools',
  '//flutter/third_party/vulkan-deps/glslang/src': '@glslang',
  '//third_party/shaderc_flutter': '@shaderc//:shaderc_flutter',
  '//flutter/third_party/re2': '@re2',
  '//third_party/libtess2': '@libtess2',
  '//flutter/third_party/harfbuzz': '@harfbuzz',
};

/// Label prefixes that map to external repositories: `//third_party/abseil-cpp/absl/x:y`
/// becomes `@abseil-cpp//absl/x:y`.
const Map<String, String> labelRepositoryPrefixes = <String, String>{
  '//third_party/abseil-cpp/': '@abseil-cpp//',
  // The engine's GN for Skia (`//flutter/skia/...`) and Skia's own tree
  // (`//flutter/third_party/skia/...`) both land in @skia.
  '//flutter/skia/': '@skia//',
  '//flutter/third_party/skia/': '@skia//',
  '//flutter/third_party/expat/': '@expat//',
  '//flutter/third_party/freetype2/': '@freetype2//',
  '//flutter/third_party/libjpeg-turbo/': '@libjpeg-turbo//',
  '//flutter/third_party/libpng/': '@libpng//',
  '//flutter/third_party/libwebp/': '@libwebp//',
  '//flutter/third_party/wuffs/': '@wuffs//',
  '//flutter/third_party/inja/': '@inja//',
  '//flutter/third_party/json/': '@json//',
  '//flutter/third_party/vulkan-deps/spirv-cross/src/': '@spirv-cross//',
  '//flutter/third_party/flatbuffers/': '@flatbuffers//',
  '//flutter/third_party/vulkan-deps/spirv-headers/src/': '@spirv-headers//',
  '//flutter/third_party/vulkan-deps/spirv-tools/src/': '@spirv-tools//',
  '//flutter/third_party/vulkan-deps/glslang/src/': '@glslang//',
  '//flutter/third_party/shaderc/': '@shaderc//',
  '//flutter/third_party/re2/': '@re2//',
  '//flutter/third_party/libtess2/': '@libtess2//',
  '//flutter/third_party/harfbuzz/': '@harfbuzz//',
};

/// Generated include directories (`$root_gen_dir/flutter`) that are an
/// ancestor package's: Bazel's `includes` is package-relative, and the
/// target whose `includes` names that package's directory already covers
/// its twin in the output tree, so the directory is a dependency on it.
const Map<String, String> genDirIncludeTargets = <String, String>{
  '//': defaultIncludeDirsLabel,
  '//flutter': '//engine/src/flutter:config',
};

/// Compiler flags that GN hands to the dependents of a target through one
/// of its public configs (`wuffs_public` turns warnings off for whoever
/// includes wuffs), which Bazel has no way to carry along a dependency.
/// The converter adds them to the `copts` of every target that lists the
/// dependency, and when it converts the dependency's own file it requires
/// the public config to carry exactly these, so that the two sides cannot
/// drift apart. Keys are GN labels as `//dir:name`.
const Map<String, List<String>> propagatedCopts = <String, List<String>>{
  '//flutter/third_party/freetype2:freetype2': <String>[
    '-Wno-unused-function',
    '-Wno-unused-variable',
  ],
  // The secondary tree's forwarder to the same target (harfbuzz names it).
  '//third_party/freetype2:freetype2': <String>['-Wno-unused-function', '-Wno-unused-variable'],
  '//flutter/third_party/wuffs:wuffs': <String>['-Wno-unused-function', '-Wno-c++11-narrowing'],
  '//third_party/inja:inja': <String>['-Wno-unused-variable', '-Wno-newline-eof'],
  '//flutter/third_party/vulkan-deps/glslang/src:glslang_lib_sources': <String>['-Wno-conversion'],
  '//flutter/third_party/vulkan-deps/glslang/src:glslang_sources': <String>['-Wno-conversion'],
  '//flutter/third_party/vulkan-deps/glslang/src:glslang_default_resource_limits_sources': <String>[
    '-Wno-conversion',
  ],
};

/// A Bazel label taken apart: `@repo//package:name`.
@immutable
final class BazelLabel {
  const BazelLabel(this.repository, this.package, this.name);

  /// Parses `@repo//pkg:name`, `//pkg:name`, `//pkg` (name = last segment),
  /// `@repo` (`@repo//:repo`) and `:name` (in [package] of [repository]).
  factory BazelLabel.parse(String label, {String repository = '', String package = ''}) {
    var rest = label;
    var repo = repository;
    if (rest.startsWith('@')) {
      final int slashes = rest.indexOf('//');
      if (slashes < 0) {
        return BazelLabel(rest, '', rest.substring(1));
      }
      repo = rest.substring(0, slashes);
      rest = rest.substring(slashes);
    }
    if (rest.startsWith('//')) {
      rest = rest.substring(2);
      final int colon = rest.indexOf(':');
      if (colon < 0) {
        return BazelLabel(repo, rest, rest.substring(rest.lastIndexOf('/') + 1));
      }
      return BazelLabel(repo, rest.substring(0, colon), rest.substring(colon + 1));
    }
    if (rest.startsWith(':')) {
      return BazelLabel(repo, package, rest.substring(1));
    }
    throw ArgumentError.value(label, 'label', 'not a label');
  }

  /// `@skia` or the empty string for the main repository.
  final String repository;
  final String package;
  final String name;

  /// How to write this label from [package] of [repository]: `:name` within
  /// the package, `//pkg:name` within the repository, the full form
  /// elsewhere; the name is dropped when it repeats the package's last
  /// segment (`@icu` for `@icu//:icu`). From an external repository, the
  /// main repository is [mainRepositoryName].
  String relativeTo({required String repository, required String package}) {
    if (this.repository == repository && this.package == package) {
      return ':$name';
    }
    final String last = this.package.substring(this.package.lastIndexOf('/') + 1);
    if (this.repository == repository) {
      return '//${this.package}${name == last && this.package.isNotEmpty ? '' : ':$name'}';
    }
    final String repo = this.repository.isEmpty ? mainRepositoryName : this.repository;
    if (this.package.isEmpty) {
      return name == repo.substring(1) ? repo : '$repo//:$name';
    }
    return '$repo//${this.package}${name == last ? '' : ':$name'}';
  }

  @override
  bool operator ==(Object other) =>
      other is BazelLabel &&
      other.repository == repository &&
      other.package == package &&
      other.name == name;

  @override
  int get hashCode => Object.hash(repository, package, name);

  @override
  String toString() => '$repository//$package:$name';
}

/// Where a generated file lives: in the main repository (an engine package
/// such as `//engine/src/flutter/fml`), or in an external repository made
/// from a synced tree at fetch time (`@skia`, whose root is the GN directory
/// `//flutter/third_party/skia`).
@immutable
final class OutputLayout {
  /// The main repository; [packages] are the Bazel packages that exist in
  /// it (`engine/src/flutter/fml`), for files of another package.
  const OutputLayout.main({this.packages = const <String>{}})
    : repository = '',
      repositoryGnRoot = '//',
      pathPrefix = 'engine/src/',
      secondarySource = null;

  const OutputLayout.repository(
    this.repository, {
    required this.repositoryGnRoot,
    this.packages = const <String>{''},
    this.secondarySource,
  }) : pathPrefix = '';

  /// `@skia`, or the empty string for the main repository.
  final String repository;

  /// The GN directory that is the repository's root: files under it are
  /// repository-relative.
  final String repositoryGnRoot;

  /// What precedes a GN-root-relative path in the repository: the GN root
  /// is `engine/src` of the main repository.
  final String pathPrefix;

  /// The Bazel packages that exist in the repository (repository-relative
  /// directories; `''` is the root), so that a file in a subpackage is
  /// labelled through its own package.
  final Set<String> packages;

  /// GN's secondary source root (`//flutter/build/secondary`), when the
  /// repository's build files live there: files beside them (`expat`'s
  /// `expat_config` directory) are mirrored into the repository by the
  /// repository rule, so their GN paths map into it too.
  final String? secondarySource;

  bool get isMain => repository.isEmpty;

  /// The repository-relative path of a GN directory or file under the root,
  /// or null when it is outside.
  String? relativePath(String gnPath) {
    final String? secondary = secondarySource;
    if (secondary != null && gnPath.startsWith(secondary + repositoryGnRoot.substring(1))) {
      return relativePath('/${gnPath.substring(secondary.length)}');
    }
    final root = repositoryGnRoot == '//' ? '//' : '$repositoryGnRoot/';
    if (gnPath == repositoryGnRoot) {
      return pathPrefix.isEmpty ? '' : pathPrefix.substring(0, pathPrefix.length - 1);
    }
    if (!gnPath.startsWith(root)) {
      return null;
    }
    return '$pathPrefix${gnPath.substring(root.length)}';
  }

  /// The package (from [packages]) that owns a repository-relative path, or
  /// null when none does (in an external repository the root always does).
  String? owningPackage(String relativePath) {
    String? best;
    for (final String package in packages) {
      if (package.isEmpty || relativePath == package || relativePath.startsWith('$package/')) {
        if (best == null || package.length > best.length) {
          best = package;
        }
      }
    }
    return best;
  }
}

/// A GN label as written (`//a/b:c`, `//a/b`, `:c`, `modules/skcms`,
/// `../base`, `../../:skia_private`) made absolute, [package] being the GN
/// directory of the file it was written in. A relative label is a
/// directory, possibly with a name after the colon, relative to that
/// directory; the two parts are resolved apart so that `../../:x` is
/// `//grandparent:x`. With [implicitName], `//a/b` is `//a/b:b`.
String absoluteGnLabel(String gnLabel, {required String package, bool implicitName = false}) {
  String label;
  if (gnLabel.startsWith(':')) {
    label = '$package$gnLabel';
  } else if (gnLabel.startsWith('//')) {
    label = gnLabel;
  } else {
    final int colon = gnLabel.indexOf(':');
    final String directory = colon < 0 ? gnLabel : gnLabel.substring(0, colon);
    final String name = colon < 0 ? '' : gnLabel.substring(colon);
    final String normalized = p.posix.normalize('${package.substring(2)}/$directory');
    label = '//${normalized == '.' ? '' : normalized}$name';
  }
  if (implicitName && !label.contains(':')) {
    label = '$label:${label.substring(label.lastIndexOf('/') + 1)}';
  }
  return label;
}

/// Translates a GN label to a Bazel label.
///
/// [package] is the GN directory of the file being converted (`//flutter/fml`),
/// for `:local` labels; [location] is where the label was written, for the
/// error when it has no Bazel home.
String bazelLabel(String gnLabel, {required String package, GnLocation? location}) {
  // `:x($default_toolchain)` is `:x` here: a Bazel build has one
  // configuration of each target.
  final int paren = gnLabel.indexOf('(');
  if (paren > 0 && gnLabel.endsWith(')')) {
    gnLabel = gnLabel.substring(0, paren);
  }
  if (gnLabel.startsWith(':')) {
    return gnLabel;
  }
  final String absolute = absoluteGnLabel(gnLabel, package: package);
  final String? override = labelOverrides[absolute];
  if (override != null) {
    return override;
  }
  // `//dir:name` where `//dir` is the root of an external repository.
  final int colon = absolute.indexOf(':');
  if (colon > 0) {
    final String? directory = labelOverrides[absolute.substring(0, colon)];
    if (directory != null && directory.startsWith('@') && !directory.contains('//')) {
      return '$directory//${absolute.substring(colon)}';
    }
  }
  for (final MapEntry<String, String> entry in labelRepositoryPrefixes.entries) {
    if (absolute.startsWith(entry.key)) {
      return entry.value + absolute.substring(entry.key.length);
    }
  }
  if (absolute.startsWith('//flutter/') || absolute == '//flutter') {
    return '$bazelRootPackage${absolute.substring(1)}';
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
  '//flutter/impeller:impeller_public_config': ConfigDependency(
    '//engine/src/flutter/impeller:impeller_public_config',
  ),
  '//flutter/third_party/icu:icu_config': ConfigImplied(),
  // Skia's text modules list //flutter/skia's private config from their own
  // files (`configs += [ "../../:skia_private" ]`); its library carries
  // SK_GAMMA_APPLY_TO_A8, which the dependency makes public where GN's
  // private config kept it to the module (decision 14's kind of delta;
  // nothing outside Skia reads it).
  '//flutter/skia:skia_private': ConfigDependency('@skia//:skia_private'),
  // skunicode hides ICU's C++ API with Skia's own config (private, so an
  // implementation dependency: txt, downstream, uses that API).
  '//flutter/third_party/skia/third_party/icu/config:no_cxx': ConfigDependency(
    '@skia//third_party/icu/config:no_cxx',
  ),
  // shaderc lists SPIRV-Tools' public config itself (`configs +=`).
  '//flutter/third_party/vulkan-deps/spirv-tools/src:spvtools_public_config': ConfigDependency(
    '@spirv-tools//:spvtools_public_config',
  ),
  '//build/config/compiler:chromium_code': ConfigWarningSet(chromiumCode: true),
  '//build/config/compiler:no_chromium_code': ConfigWarningSet(chromiumCode: false),
};

/// The Bazel config_setting (or constraint) for a GN boolean predicate.
const Map<String, String> conditionSettings = <String, String>{
  'is_android': '@platforms//os:android',
  'is_fuchsia': '@platforms//os:fuchsia',
  'is_ios': '@platforms//os:ios',
  'is_linux': '@platforms//os:linux',
  'is_mac': '@platforms//os:macos',
  'is_qnx': '@platforms//os:qnx',
  'is_win': '@platforms//os:windows',
  'is_debug': '//engine/src/flutter/build/bazel:unoptimized',
  'slimpeller': '//engine/src/flutter/common:slimpeller_enabled',
  // testing.gni's default, `current_toolchain == host_toolchain || is_fuchsia
  // || is_mac`, read in Bazel terms (the group in //flutter/testing's
  // appendix).
  'enable_unittests': '//engine/src/flutter/testing:unittests_enabled',
  // impeller/tools/args.gni's backend arguments: flags whose defaults GN
  // derives from the platform (impeller/tools/BUILD.bazel).
  'impeller_enable_metal': '//engine/src/flutter/impeller/tools:metal',
  'impeller_enable_opengles': '//engine/src/flutter/impeller/tools:opengles',
  'impeller_enable_vulkan': '//engine/src/flutter/impeller/tools:vulkan',
};

/// The Bazel config_setting for `variable == "value"`, by variable and value.
const Map<String, Map<String, String>> comparisonSettings = <String, Map<String, String>>{
  'flutter_runtime_mode': <String, String>{
    'debug': '//engine/src/flutter/common:runtime_mode_debug',
    'profile': '//engine/src/flutter/common:runtime_mode_profile',
    'release': '//engine/src/flutter/common:runtime_mode_release',
    'jit_release': '//engine/src/flutter/common:runtime_mode_jit_release',
  },
};

/// GN variables an imported `.gni` defines and that build files may read or
/// test. Reads become references that [referenceConstants] resolve.
const Set<String> knownExternalVariables = <String>{
  // //build/config/BUILDCONFIG.gn
  'current_cpu',
  'current_os',
  'current_toolchain',
  'default_library_type',
  'default_toolchain',
  'host_cpu',
  'host_os',
  'host_toolchain',
  'is_android',
  'is_apple',
  'is_clang',
  'is_component_build',
  'is_debug',
  'is_fuchsia',
  'is_ios',
  'is_linux',
  'is_mac',
  'is_official_build',
  'is_qnx',
  'is_wasm',
  'is_win',
  'target_cpu',
  'target_os',
  // //flutter/build/dart/dart.gni
  'dart_src',
  // //flutter/common/config.gni
  'enable_backtrace',
  'enable_unittests',
  'flutter_cflags_objc',
  'flutter_cflags_objcc',
  'flutter_runtime_mode',
  'slimpeller',
  // //flutter/shell/config.gni
  'shell_enable_gl',
  'shell_enable_metal',
  'shell_enable_software',
  'shell_enable_vulkan',
  'test_enable_gl',
  'test_enable_metal',
  'test_enable_software',
  'test_enable_vulkan',
  // //flutter/tools/fuchsia/gn-sdk/src/gn_configs.gni
  'fuchsia_arch_root',
  'fuchsia_sdk',
  // //flutter/impeller/tools/args.gni (evaluated): the backend arguments are
  // Bazel flags, so declare_args() keeps their names rather than GN's
  // per-platform default formulas.
  'impeller_enable_metal',
  'impeller_enable_opengles',
  'impeller_enable_vulkan',
};

/// Starlark expressions for GN references that have a Bazel-side constant.
const Map<String, String> referenceConstants = <String, String>{
  'flutter_cflags_objc': 'FLUTTER_CFLAGS_OBJC',
  'flutter_cflags_objcc': 'FLUTTER_CFLAGS_OBJCC',
};

/// How a template argument translates to a macro attribute.
enum TemplateArgumentKind {
  /// Files of the package (`fixtures`, `flatbuffers`).
  files,

  /// Labels (`deps`).
  labels,

  /// Configs, which become labels of their config libraries.
  configs,

  /// A scalar (`testonly`).
  scalar,
}

/// One argument of a known template: the macro attribute it becomes and how.
final class TemplateArgument {
  const TemplateArgument(this.attribute, this.kind);

  final String attribute;
  final TemplateArgumentKind kind;
}

/// The `.gni` templates the converter knows, with the Bazel macro for each
/// (`load` label and symbol) and the arguments it accepts.
final class TemplateMapping {
  const TemplateMapping(
    this.bzl,
    this.symbol,
    this.arguments, {
    this.innerTargets = const <String>[],
  });

  final String bzl;
  final String symbol;
  final Map<String, TemplateArgument> arguments;

  /// The other targets an invocation expands to in GN, as patterns over the
  /// invocation's name (`flatc_{name}`) and, for the shader templates, the
  /// backend (`impellerc_{backend}_{name}` over [impellerShaderBackends]),
  /// besides those GN's convention prefixes with `_`. The macro's business;
  /// the oracle expects them.
  final List<String> innerTargets;

  /// [innerTargets] expanded for [name].
  Iterable<String> innerTargetsOf(String name) sync* {
    for (final String pattern in innerTargets) {
      final String named = pattern.replaceAll('{name}', name);
      if (named.contains('{backend}')) {
        yield* impellerShaderBackends.map((String b) => named.replaceAll('{backend}', b));
      } else {
        yield named;
      }
    }
  }
}

/// The backends impeller/tools/shaders.gni expands to on a Linux host
/// (GLES 2, GLES 3, Vulkan; no Metal), as the shader rules in
/// build/bazel/impeller mirror them.
const List<String> impellerShaderBackends = <String>['gles', 'gles3', 'vk'];

const Map<String, TemplateMapping> templateMappings = <String, TemplateMapping>{
  'test_fixtures': TemplateMapping(
    '//engine/src/flutter/testing:testing.bzl',
    'flutter_test_fixtures',
    <String, TemplateArgument>{
      'fixtures': TemplateArgument('fixtures', TemplateArgumentKind.files),
      'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
    },
  ),
  // build/secondary/flutter/third_party/flatbuffers/flatbuffers.gni: flatc
  // over the schemas, the generated headers as a library.
  'flatbuffers': TemplateMapping(
    '//engine/src/flutter/build/bazel/flatbuffers:flatbuffers.bzl',
    'flatbuffers',
    <String, TemplateArgument>{
      'flatbuffers': TemplateArgument('flatbuffers', TemplateArgumentKind.files),
      'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
      'public_deps': TemplateArgument('deps', TemplateArgumentKind.labels),
      'public_configs': TemplateArgument('deps', TemplateArgumentKind.configs),
      'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
    },
    innerTargets: <String>['flatc_{name}'],
  ),
  // impeller/tools/shaders.gni: impellerc per shader per backend, the
  // archives, the embedded blobs and the reflection libraries. GN's `name`
  // is the library name (`entity` in `entity_shaders_vk`); Bazel's is the
  // target's.
  'impeller_shaders': TemplateMapping(
    '//engine/src/flutter/build/bazel/impeller:shaders.bzl',
    'impeller_shaders',
    <String, TemplateArgument>{
      'name': TemplateArgument('library_name', TemplateArgumentKind.scalar),
      'shaders': TemplateArgument('shaders', TemplateArgumentKind.files),
      'analyze': TemplateArgument('analyze', TemplateArgumentKind.scalar),
      'enable_opengles': TemplateArgument('enable_opengles', TemplateArgumentKind.scalar),
      'gles_language_version': TemplateArgument(
        'gles_language_version',
        TemplateArgumentKind.scalar,
      ),
      'vulkan_language_version': TemplateArgument(
        'vulkan_language_version',
        TemplateArgumentKind.scalar,
      ),
      'metal_version': TemplateArgument('metal_version', TemplateArgumentKind.scalar),
      'use_half_textures': TemplateArgument('use_half_textures', TemplateArgumentKind.scalar),
      'require_framebuffer_fetch': TemplateArgument(
        'require_framebuffer_fetch',
        TemplateArgumentKind.scalar,
      ),
      'gles_exclusions': TemplateArgument('gles_exclusions', TemplateArgumentKind.files),
      'vulkan_exclusions': TemplateArgument('vulkan_exclusions', TemplateArgumentKind.files),
      'entry_point_prefix': TemplateArgument('entry_point_prefix', TemplateArgumentKind.scalar),
      'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
    },
    innerTargets: <String>[
      '{backend}_{name}',
      'impellerc_{backend}_{name}',
      'genlib_{backend}_{name}',
      'gen_blob_embed_{backend}_{name}',
      'embed_{backend}_{name}',
      'embed_embed_{backend}_{name}',
      'reflect_{backend}_{name}',
      'reflect_reflect_{backend}_{name}',
      'analyze_{backend}_{name}',
    ],
  ),
};

/// Which imported `.gni` files the converter evaluates (Skia's lists,
/// arguments and templates; the engine's Skia wrapper files; Impeller's
/// arguments and its `impeller_component` template) and which it takes as
/// known through the tables above (the engine's own configuration files,
/// whose variables are [knownExternalVariables] and whose templates are
/// [templateMappings]; Impeller's shader templates, until something
/// converted invokes them).
const ImportPolicy engineImportPolicy = ImportPolicy(
  evaluatedPrefixes: <String>{
    '//flutter/third_party/skia/',
    '//flutter/skia/',
    '//flutter/impeller/tools/impeller.gni',
    '//flutter/impeller/tools/args.gni',
    '//flutter/impeller/tools/component.gni',
    '//flutter/third_party/glfw/glfw_args.gni',
    // The engine's answers to the Khronos trees' build_overrides (where
    // SPIRV-Headers and SPIRV-Tools are, build_with_chromium = false) and
    // their own argument files.
    '//build_overrides/build.gni',
    '//build_overrides/spirv_tools.gni',
    '//build_overrides/glslang.gni',
    '//flutter/third_party/vulkan-deps/',
  },
  known: <String>{
    '//flutter/build/dart/dart.gni',
    '//flutter/common/config.gni',
    '//flutter/impeller/tools/shaders.gni',
    '//flutter/shell/config.gni',
    // Declares the version arguments and asserts they are set; nothing
    // converted reads them (impeller/compiler imports it without use).
    '//flutter/shell/version/version.gni',
    '//flutter/testing/testing.gni',
    '//flutter/third_party/flatbuffers/flatbuffers.gni',
    '//flutter/tools/fuchsia/gn-sdk/src/gn_configs.gni',
  },
);

/// Which assumptions describe the Linux x64 host build (the values
/// `tools/gn` gives these arguments for it, as in `out/host_debug*/args.gn`).
/// Everything not fixed here stays a select(): `is_debug`, the runtime mode
/// and slimpeller in particular, which are Bazel flags.
Assumptions linuxHostAssumptions() {
  return Assumptions(const <String, GnValue>{
    // //build/config/BUILDCONFIG.gn
    'current_cpu': GnStringValue('x64'),
    'current_os': GnStringValue('linux'),
    'current_toolchain': GnStringValue('//build/toolchain/linux:clang_x64'),
    'default_library_type': GnStringValue('static_library'),
    'default_toolchain': GnStringValue('//build/toolchain/linux:clang_x64'),
    'host_cpu': GnStringValue('x64'),
    'host_os': GnStringValue('linux'),
    'host_toolchain': GnStringValue('//build/toolchain/linux:clang_x64'),
    'target_cpu': GnStringValue('x64'),
    'target_os': GnStringValue('linux'),
    'is_android': GnBoolValue(false),
    'is_apple': GnBoolValue(false),
    // is_clang: a toolchain invariant (gn_eval's toolchainInvariants).
    'is_component_build': GnBoolValue(false),
    'is_fuchsia': GnBoolValue(false),
    'is_ios': GnBoolValue(false),
    'is_linux': GnBoolValue(true),
    'is_mac': GnBoolValue(false),
    'is_official_build': GnBoolValue(true),
    'is_qnx': GnBoolValue(false),
    'is_wasm': GnBoolValue(false),
    'is_win': GnBoolValue(false),
    // //flutter/build/dart/dart.gni
    'dart_src': GnStringValue('//flutter/third_party/dart'),
    // //flutter/common/config.gni
    'enable_backtrace': GnBoolValue(true),
    'enable_unittests': GnBoolValue(true),
    // //flutter/shell/config.gni
    'shell_enable_gl': GnBoolValue(true),
    'shell_enable_metal': GnBoolValue(false),
    'shell_enable_software': GnBoolValue(true),
    'shell_enable_vulkan': GnBoolValue(true),
    'test_enable_gl': GnBoolValue(true),
    'test_enable_metal': GnBoolValue(false),
    'test_enable_software': GnBoolValue(true),
    'test_enable_vulkan': GnBoolValue(true),
    // //flutter/impeller/tools/args.gni, as its defaults come out on Linux.
    'impeller_enable_metal': GnBoolValue(false),
    'impeller_enable_opengles': GnBoolValue(true),
    'impeller_enable_vulkan': GnBoolValue(true),
    // Skia's arguments as tools/gn sets them for a Linux host; the rest take
    // the defaults of //flutter/third_party/skia/gn/skia.gni.
    'skia_enable_pdf': GnBoolValue(false),
    'skia_gl_standard': GnStringValue(''),
    'skia_use_dng_sdk': GnBoolValue(false),
    'skia_use_expat': GnBoolValue(true),
    'skia_use_fontconfig': GnBoolValue(false),
    'skia_use_gl': GnBoolValue(true),
    'skia_use_icu': GnBoolValue(true),
    'skia_use_libpng_decode': GnBoolValue(true),
    'skia_use_libpng_encode': GnBoolValue(true),
    'skia_use_rust_png_decode': GnBoolValue(false),
    'skia_use_rust_png_encode': GnBoolValue(false),
    'skia_use_vma': GnBoolValue(false),
    'skia_use_vulkan': GnBoolValue(true),
    'skia_use_wuffs': GnBoolValue(true),
    'skia_use_x11': GnBoolValue(false),
    'skia_use_xps': GnBoolValue(false),
  });
}
