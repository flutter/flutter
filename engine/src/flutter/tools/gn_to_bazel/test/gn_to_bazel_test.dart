// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:gn_to_bazel/gn_to_bazel.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The engine checkout's `gn`, found relative to this package
/// (`engine/src/flutter/tools/gn_to_bazel`) or named by `$GN`.
final String gnBinary = () {
  final String? fromEnvironment = Platform.environment['GN'];
  if (fromEnvironment != null) {
    return fromEnvironment;
  }
  return p.join(Directory.current.path, '..', '..', 'third_party', 'gn', 'gn');
}();

/// Parses [gn] (the text of a BUILD.gn) with the real GN parser.
Future<GnBlock> parse(String gn) async {
  final Directory temp = Directory.systemTemp.createTempSync('gn_to_bazel_test');
  addTearDown(() => temp.deleteSync(recursive: true));
  final file = File(p.join(temp.path, 'BUILD.gn'))..writeAsStringSync(gn);
  return loadGnFile(file.path, gnBinary: gnBinary);
}

Future<GnFileEvaluation> evaluate(
  String gn, {
  Assumptions? assumptions,
  Set<String> externalVariables = knownExternalVariables,
  Set<String> templates = const <String>{'test_fixtures'},
  Set<String> skip = const <String>{},
  Map<String, Condition> targetConditions = const <String, Condition>{},
}) async {
  return evaluateGnFile(
    await parse(gn),
    assumptions: assumptions ?? linuxHostAssumptions(),
    templates: templates,
    externalVariables: externalVariables,
    booleanVariables: knownBooleanVariables,
    skipTargets: skip,
    targetConditions: targetConditions,
  );
}

Future<String> convert(
  String gn, {
  Assumptions? assumptions,
  String gnPackage = '//flutter/example',
  Set<String> externalVariables = knownExternalVariables,
  Set<String> templates = const <String>{'test_fixtures'},
  Set<String> skip = const <String>{},
  String? appendix,
  OutputLayout layout = const OutputLayout.main(),
  Map<String, Condition> targetConditions = const <String, Condition>{},
}) async {
  return emitBuildFile(
    await evaluate(
      gn,
      assumptions: assumptions,
      externalVariables: externalVariables,
      templates: templates,
      skip: skip,
      targetConditions: targetConditions,
    ),
    gnPackage: gnPackage,
    skipTargets: skip,
    appendix: appendix,
    layout: layout,
  );
}

/// A GN source tree in a temporary directory holding [files] (paths relative
/// to the root, contents), for tests of imports and templates.
GnSourceTree sourceTree(Map<String, String> files) {
  final Directory root = Directory.systemTemp.createTempSync('gn_to_bazel_tree');
  addTearDown(() => root.deleteSync(recursive: true));
  File(p.join(root.path, '.gn')).writeAsStringSync('buildconfig = "//BUILDCONFIG.gn"\n');
  for (final MapEntry<String, String> file in files.entries) {
    File(p.join(root.path, file.key))
      ..createSync(recursive: true)
      ..writeAsStringSync(file.value);
  }
  return GnSourceTree(root.path, gnBinary: gnBinary);
}

/// Evaluates [file] of [tree] with imports under `//lib/` evaluated and
/// `//known/config.gni` taken as known, like the engine's policy.
GnFileEvaluation evaluateIn(
  GnSourceTree tree,
  String file, {
  Assumptions? assumptions,
  Set<String> templates = const <String>{},
  ImportPolicy importPolicy = const ImportPolicy(
    evaluatedPrefixes: <String>{'//lib/'},
    known: <String>{'//known/config.gni', '//flutter/build/zip_bundle.gni'},
  ),
}) {
  return evaluateGnFile(
    tree.load(tree.resolve(file)),
    assumptions: assumptions ?? linuxHostAssumptions(),
    templates: templates,
    externalVariables: knownExternalVariables,
    booleanVariables: knownBooleanVariables,
    tree: tree,
    importPolicy: importPolicy,
  );
}

/// The unconditional string items of [variable] of [target].
List<String> strings(GnTarget target, String variable) {
  return <String>[
    for (final GnValue value in target.variables[variable]!.unconditionalItems!)
      (value as GnStringValue).value,
  ];
}

/// Matches a [GnError] whose message mentions [line] of the input and
/// contains [message].
Matcher throwsGnError({required int line, required String message}) {
  return throwsA(
    isA<GnError>()
        .having((GnError e) => e.location.line, 'line', line)
        .having((GnError e) => e.message, 'message', contains(message)),
  );
}

void main() {
  group('gn_ast', () {
    test('keeps node types, locations and comments', () async {
      final GnBlock tree = await parse('''
import("//flutter/common/config.gni")

# A leading comment.
source_set("x") {
  sources = [
    "a.cc",
    # About b.
    "b.cc",  # Trailing.
  ]
  if (is_win) {
    sources += [ "c.cc" ]
  } else if (is_mac) {
    sources -= [ "a.cc" ]
  } else {
    defines = [ "D=1" ]
  }
}
''');
      expect(tree.statements, hasLength(2));
      final call = tree.statements[1] as GnFunctionCall;
      expect(call.name, 'source_set');
      expect(call.beforeComments, <String>['# A leading comment.']);
      expect(call.location.line, 4);
      expect((call.args.single as GnLiteral).stringValue, 'x');

      final List<GnNode> body = call.block!.statements;
      final sources = body[0] as GnBinary;
      expect(sources.op, '=');
      expect((sources.left as GnIdentifier).name, 'sources');
      final list = sources.right as GnList;
      expect(list.items, hasLength(2));
      expect(list.items[1].beforeComments, <String>['# About b.']);
      expect(list.items[1].suffixComments, <String>['# Trailing.']);
      expect(list.items[1].location.line, 8);

      final condition = body[1] as GnCondition;
      expect((condition.condition as GnIdentifier).name, 'is_win');
      expect(condition.orElse, isA<GnCondition>());
      final elseIf = condition.orElse! as GnCondition;
      expect(elseIf.orElse, isA<GnBlock>());
      expect((elseIf.thenBlock.statements.single as GnBinary).op, '-=');
    });

    test('resolves string escapes', () async {
      final GnBlock tree = await parse(r'''
x = "a\"b\$c"
''');
      final assignment = tree.statements.single as GnBinary;
      final literal = assignment.right as GnLiteral;
      expect(literal.stringValue, r'a"b$c');
      expect(literal.hasExpansion, isFalse);
      expect(GnLiteral(literal.location, r'"$x/y"').hasExpansion, isTrue);
    });
  });

  group('gn_eval', () {
    test('folds conditions the assumptions decide and keeps the rest', () async {
      final GnFileEvaluation evaluation = await evaluate('''
source_set("x") {
  sources = [ "a.cc" ]
  if (is_linux) {
    sources += [ "linux.cc" ]
  }
  if (is_win) {
    sources += [ "win.cc" ]
  }
  if (enable_backtrace && !is_wasm) {
    sources += [ "backtrace.cc" ]
  }
  if (slimpeller) {
    sources += [ "slim.cc" ]
  } else {
    sources += [ "full.cc" ]
  }
}
''');
      final GnTarget target = evaluation.targets.single;
      expect(target.rule, 'source_set');
      expect(target.name, 'x');
      expect(target.condition, Condition.always);
      final List<GnAssignment> assignments = target.variables['sources']!.assignments;
      expect(assignments.map((GnAssignment a) => a.items.single.toString()), <String>[
        '"a.cc"',
        '"linux.cc"',
        '"backtrace.cc"',
        '"slim.cc"',
        '"full.cc"',
      ]);
      expect(assignments[1].condition, Condition.always);
      expect(assignments[1].sourceConditions, <String>['is_linux']);
      expect(assignments[2].condition, Condition.always);
      expect(assignments[2].sourceConditions, <String>['enable_backtrace && !is_wasm']);
      expect(assignments[3].condition, const ConditionVariable('slimpeller'));
      expect(assignments[4].condition, const ConditionNot(ConditionVariable('slimpeller')));
      expect(assignments[4].sourceConditions, <String>['!(slimpeller)']);
    });

    test('keeps get_target_outputs() as a value naming the target, filtered', () async {
      final GnFileEvaluation evaluation = await evaluate('''
group("x") {
  testonly = true
  fixtures = [ "a.png" ] + filter_include(get_target_outputs("//flutter/test:stages"), [ "*.iplr" ])
  fixtures += get_target_outputs("//flutter/other:bundle")
  names = filter_include([ "a.iplr", "b.txt", "c.iplr" ], [ "*.iplr" ])
}
''');
      final GnTarget target = evaluation.targets.single;
      expect(
        target.variables['fixtures']!.assignments.expand((GnAssignment a) => a.items),
        <GnValue>[
          const GnStringValue('a.png'),
          const GnTargetOutputsValue('//flutter/test:stages', <String>['*.iplr']),
          const GnTargetOutputsValue('//flutter/other:bundle', <String>[]),
        ],
      );
      expect(target.variables['names']!.assignments.single.items, <GnValue>[
        const GnStringValue('a.iplr'),
        const GnStringValue('c.iplr'),
      ]);
    });

    test('applies assumptions to a condition built outside evaluation', () {
      final Assumptions assumptions = linuxHostAssumptions();
      const Condition debug = ConditionVariable('is_debug');
      expect(assumptions.apply(const ConditionVariable('is_win')), Condition.never);
      expect(assumptions.apply(const ConditionNot(ConditionVariable('is_win'))), Condition.always);
      expect(assumptions.apply(debug), debug);
      expect(
        assumptions.apply(
          const ConditionAnd(<Condition>[
            ConditionNot(ConditionVariable('is_win')),
            ConditionNot(debug),
          ]),
        ),
        const ConditionNot(debug),
      );
      expect(
        assumptions.apply(const ConditionAnd(<Condition>[ConditionVariable('is_win'), debug])),
        Condition.never,
      );
    });

    test('evaluates string comparisons and else-if chains', () async {
      final GnFileEvaluation evaluation = await evaluate('''
source_set("x") {
  if (target_os == "wasm") {
    sources = [ "wasm.cc" ]
  } else if (target_os != "fuchsia") {
    sources = [ "other.cc" ]
  } else {
    sources = [ "fuchsia.cc" ]
  }
  if (flutter_runtime_mode == "release") {
    defines = [ "RELEASE" ]
  }
}
''');
      final GnTarget target = evaluation.targets.single;
      expect(target.variables['sources']!.unconditionalItems, <GnValue>[
        const GnStringValue('other.cc'),
      ]);
      final GnAssignment defines = target.variables['defines']!.assignments.single;
      expect(defines.condition, const ConditionComparison('flutter_runtime_mode', true, 'release'));
      expect(defines.condition.gnSource, 'flutter_runtime_mode == "release"');
    });

    test('applies -= and the += on configs that set_defaults allows', () async {
      final GnFileEvaluation evaluation = await evaluate('''
source_set("x") {
  sources = [
    "a.cc",
    "b.cc",
  ]
  sources -= [ "a.cc" ]
  configs += [ "//build/config/compiler:no_chromium_code" ]
  configs -= [ "//build/config/compiler:chromium_code" ]
}
''');
      final GnTarget target = evaluation.targets.single;
      expect(target.variables['sources']!.unconditionalItems, <GnValue>[
        const GnStringValue('b.cc'),
      ]);
      expect(target.variables['configs']!.assignments.map((GnAssignment a) => a.op), <String>[
        '+=',
        '-=',
      ]);
    });

    test('follows local variables and string concatenation', () async {
      final GnFileEvaluation evaluation = await evaluate('''
common_sources = [ "common.cc" ]
source_set("x") {
  sources = common_sources + [ "x.cc" ]
  defines = [ "PREFIX_" + "SUFFIX" ]
}
''');
      final GnTarget target = evaluation.targets.single;
      expect(target.variables['sources']!.unconditionalItems, <GnValue>[
        const GnStringValue('common.cc'),
        const GnStringValue('x.cc'),
      ]);
      expect(target.variables['defines']!.unconditionalItems, <GnValue>[
        const GnStringValue('PREFIX_SUFFIX'),
      ]);
      await expectLater(
        evaluate('''
source_set("x") {
  sources = [ "a.cc" ]
  sources += "b.cc"
}
'''),
        throwsGnError(line: 3, message: '+= of a scalar to the list sources'),
      );
    });

    test('expands known strings and leaves the rest alone', () async {
      final GnFileEvaluation evaluation = await evaluate(r'''
source_set("x") {
  sources = [ "a.cc" ]
  deps = [ "$dart_src/runtime/bin:elf_loader" ]
}
''');
      expect(evaluation.targets.single.variables['deps']!.unconditionalItems, <GnValue>[
        const GnStringValue('//flutter/third_party/dart/runtime/bin:elf_loader'),
      ]);
      await expectLater(
        evaluate(r'''
source_set("x") {
  sources = [ "$mystery_dir/a.cc" ]
}
'''),
        throwsGnError(line: 2, message: r'string expansion of $mystery_dir is not supported'),
      );
    });

    test('keeps an external variable inside a string as a reference', () async {
      final GnFileEvaluation evaluation = await evaluate(r'''
source_set("version") {
  sources = [ "version.cc" ]
  defines = [
    "FLUTTER_ENGINE_VERSION=\"$engine_version\"",
    "BOTH=${engine_version}$content_hash",
  ]
}
''');
      expect(evaluation.targets.single.variables['defines']!.unconditionalItems, <GnValue>[
        const GnExpandedString(<GnValue>[
          GnStringValue('FLUTTER_ENGINE_VERSION="'),
          GnReference('engine_version'),
          GnStringValue('"'),
        ]),
        const GnExpandedString(<GnValue>[
          GnStringValue('BOTH='),
          GnReference('engine_version'),
          GnReference('content_hash'),
        ]),
      ]);
    });

    test('follows boolean variables, decided or not', () async {
      final GnFileEvaluation evaluation = await evaluate('''
use_swiftshader = enable_unittests && shell_enable_gl
use_slim = slimpeller && !is_fuchsia
if (use_swiftshader) {
  source_set("gl") {
    sources = [ "gl.cc" ]
  }
}
source_set("x") {
  sources = [ "x.cc" ]
  if (use_slim) {
    sources += [ "slim.cc" ]
  }
}
''');
      expect(evaluation.targets.map((GnTarget t) => t.name), <String>['gl', 'x']);
      expect(evaluation.targets[0].condition, Condition.always);
      final GnAssignment slim = evaluation.targets[1].variables['sources']!.assignments[1];
      expect(slim.condition, const ConditionVariable('slimpeller'));
    });

    test('compares two known strings', () async {
      final GnFileEvaluation evaluation = await evaluate('''
if (current_toolchain == host_toolchain) {
  source_set("host_only") {
    sources = [ "a.cc" ]
  }
}
''');
      expect(evaluation.targets.single.condition, Condition.always);
      await expectLater(
        evaluate('''
if (current_toolchain == unknown_toolchain) {
  source_set("x") {
    sources = [ "a.cc" ]
  }
}
'''),
        throwsGnError(line: 1, message: 'needs both values to be known'),
      );
    });

    test(
      r'`current_toolchain == default_toolchain` holds; `($default_toolchain)` is dropped',
      () async {
        // glslang's shape: an action defined in the default toolchain alone
        // and named with the suffix. A Bazel package is loaded once per
        // configuration, so the test holds and the suffix says nothing --
        // with the toolchains open (the generation scope) as with them known.
        for (final assumptions in <Assumptions>[generationAssumptions(), linuxHostAssumptions()]) {
          final GnFileEvaluation evaluation = await evaluate(r'''
if (current_toolchain == default_toolchain) {
  source_set("build_info") {
    sources = [ "info.cc" ]
  }
}
if (default_toolchain != current_toolchain) {
  source_set("elsewhere") {
    sources = [ "e.cc" ]
  }
}
source_set("lib") {
  sources = [ "lib.cc" ]
  public_deps = [ ":build_info($default_toolchain)" ]
  deps = [ "//flutter/other:thing(${default_toolchain})" ]
}
''', assumptions: assumptions);
          expect(evaluation.targets.map((GnTarget t) => '${t.name} [${t.condition}]'), <String>[
            'build_info [true]',
            'lib [true]',
          ]);
          expect(strings(evaluation.targets[1], 'public_deps'), <String>[':build_info']);
          expect(strings(evaluation.targets[1], 'deps'), <String>['//flutter/other:thing']);
        }
      },
    );

    test('compares a string written under conditions case by case', () async {
      // skia.gni's skia_gl_standard: "webgl" where is_wasm, "" otherwise.
      // `== "webgl"` is the wasm case's condition, `== "gles"` no case at
      // all, `!= "gles"` every case.
      final GnFileEvaluation evaluation = await evaluate('''
if (is_wasm) {
  gl_standard = "webgl"
} else {
  gl_standard = ""
}
source_set("x") {
  sources = [ "x.cc" ]
  if (gl_standard == "webgl") {
    defines = [ "WEBGL" ]
  }
  if (gl_standard == "gles") {
    sources += [ "gles.cc" ]
  }
  if (gl_standard != "gles") {
    sources += [ "not_gles.cc" ]
  }
}
''', assumptions: generationAssumptions());
      final GnTarget target = evaluation.targets.single;
      expect(
        target.variables['defines']!.assignments.map((GnAssignment a) => a.toString()),
        <String>['[is_wasm] = ["WEBGL"]'],
      );
      expect(
        target.variables['sources']!.assignments.map((GnAssignment a) => a.toString()),
        <String>['[true] = ["x.cc"]', '[true] += ["not_gles.cc"]'],
      );
    });

    test("an OS name's comparison the assumptions deny is decided", () async {
      // `target_os != "win"` where is_win is false (the generation scope),
      // `full_target_platform_name == "ios-arm64"` where is_ios is;
      // `target_os == "wasm"` stays open there, as `target_os != "android"`
      // does since the Android platform (skcms's condition).
      final GnFileEvaluation evaluation = await evaluate('''
source_set("x") {
  sources = [ "x.cc" ]
  if (target_os != "win") {
    sources += [ "not_win.cc" ]
  }
  if (full_target_platform_name == "ios-arm64") {
    sources += [ "ios.cc" ]
  }
  if (target_os == "wasm") {
    sources += [ "wasm.cc" ]
  }
}
''', assumptions: generationAssumptions());
      expect(
        evaluation.targets.single.variables['sources']!.assignments.map(
          (GnAssignment a) => a.toString(),
        ),
        <String>[
          '[true] = ["x.cc"]',
          '[true] += ["not_win.cc"]',
          '[target_os == "wasm"] += ["wasm.cc"]',
        ],
      );
    });

    test('the generation scope is the host scope less what GN derives from the target', () {
      // Every value generationAssumptions fixes is the host's; what it
      // leaves open is exactly the target (its OS, CPU, toolchains and
      // names) and the arguments GN derives from it, each with a
      // config_setting. An argument added to linuxHostAssumptions lands
      // here, to be classified: derived (and given a setting) or an input
      // of tools/gn's (and kept, as Skia's are).
      final Assumptions host = linuxHostAssumptions();
      final Assumptions generation = generationAssumptions();
      for (final String name in generation.names) {
        final GnValue? value = generation[name];
        if (value is GnConditionValue) {
          // An argument the web build passes differently: a formula over
          // the OS that comes out as the host's value on the host.
          final GnValue? expected = host[name];
          expect(expected, isA<GnBoolValue>(), reason: name);
          expect(
            host.apply(value.condition),
            ConditionConstant((expected! as GnBoolValue).value),
            reason: name,
          );
          continue;
        }
        if (value is GnCasedValue && value.variable == 'target_os') {
          // An argument tools/gn passes per target OS (skia_gl_standard):
          // the host's value is its linux case.
          expect(host[name], GnStringValue(value.values['linux']!), reason: name);
          continue;
        }
        expect(value, host[name], reason: name);
      }
      expect(
        generation.names.where((String n) => generation[n] is GnConditionValue).toList()..sort(),
        // ... and is_apple, BUILDCONFIG.gn's `is_ios || is_mac`.
        <String>[...perTargetOsArguments.keys, 'is_apple']..sort(),
      );
      expect(host.names.where((String name) => generation[name] == null).toList()..sort(), <String>[
        'build_engine_artifacts',
        'current_cpu',
        'current_os',
        'current_toolchain',
        'default_toolchain',
        'disable_vma_stl_shared_mutex',
        // A setting (build/bazel:embedder_for_target); off on the host.
        'embedder_for_target',
        'enable_backtrace',
        'enable_unittests',
        'full_target_platform_name',
        'host_toolchain',
        'impeller_enable_metal',
        'impeller_enable_opengles',
        'impeller_enable_vulkan',
        'is_android',
        // The macOS port (research/20): is_mac is the macOS platform's
        // (iOS is not built yet; is_apple is its formula, above).
        'is_linux',
        'is_mac',
        'is_wasm',
        'shell_enable_gl',
        'shell_enable_metal',
        'shell_enable_software',
        'shell_enable_vulkan',
        // skia.gni's default gives both builds' values: a derivation.
        'skia_use_gl',
        // The wasm toolchains set these per variant: the web build's
        // settings (webVariantArguments).
        'skia_use_icu',
        'skia_use_libpng_decode',
        'skia_use_libpng_encode',
        'skia_use_rust_png_decode',
        'skia_use_rust_png_encode',
        'skia_use_wuffs',
        'target_cpu',
        'target_os',
        'target_platform_name',
        'test_enable_gl',
        'test_enable_metal',
        'test_enable_software',
        'test_enable_vulkan',
        'use_flutter_cxx',
      ]);
    });

    test('a disjunction of a conjunction and its denied terms always holds', () {
      // The condition a name defined in both branches of an `if` on a
      // conjunction is defined under (skcms's arch() template); and the
      // duals of the conjunction's simplifications.
      const a = ConditionVariable('a');
      const b = ConditionVariable('b');
      final Condition both = Condition.conjunction(const <Condition>[a, b]);
      expect(Condition.disjunction(<Condition>[both, both.negated]), Condition.always);
      expect(Condition.disjunction(<Condition>[both, a.negated, b.negated]), Condition.always);
      expect(
        Condition.disjunction(<Condition>[
          a,
          Condition.conjunction(<Condition>[a.negated, b]),
        ]),
        Condition.disjunction(const <Condition>[a, b]),
      );
      expect(Condition.disjunction(<Condition>[a, both]), a);
    });

    test(
      '`current_toolchain == host_toolchain` with neither assumed is the host predicate',
      () async {
        // The web scope: the toolchains open (a wasm build has the host's
        // toolchain beside its own), the comparison GN's "the host's own build".
        final open = Assumptions(const <String, GnValue>{});
        final GnFileEvaluation evaluation = await evaluate('''
if (current_toolchain == host_toolchain) {
  source_set("host_only") {
    sources = [ "a.cc" ]
  }
}
if (host_toolchain != current_toolchain) {
  source_set("target_only") {
    sources = [ "b.cc" ]
  }
}
''', assumptions: open);
        expect(evaluation.targets[0].condition, const ConditionVariable(hostToolchainPredicate));
        expect(
          evaluation.targets[1].condition,
          const ConditionVariable(hostToolchainPredicate).negated,
        );
        // Emitted: the host group of build/bazel, and its complement in a
        // conjunction.
        final String output = await convert('''
source_set("x") {
  sources = [ "x.cc" ]
  if (current_toolchain == host_toolchain) {
    sources += [ "host.cc" ]
  }
  if (is_wasm && current_toolchain != host_toolchain) {
    sources += [ "wasm_target.cc" ]
  }
}
''', assumptions: open);
        expect(output, contains('load("@bazel_skylib//lib:selects.bzl", "selects")'));
        expect(
          output,
          contains(
            '        "//engine/src/flutter/build/bazel:host_toolchain": [\n'
            '            "host.cc",  # current_toolchain == host_toolchain\n'
            '        ],\n',
          ),
        );
        expect(
          output,
          contains(
            'selects.config_setting_group(\n'
            '    name = "when_is_wasm_and_not_is_host_toolchain",\n'
            '    match_all = [\n'
            '        "@platforms//os:emscripten",\n'
            '        "//engine/src/flutter/build/bazel:not_host_toolchain",\n'
            '    ],\n'
            ')\n',
          ),
        );
      },
    );

    test('knows the OS predicates and the values of one variable exclude each other', () {
      const Condition mac = ConditionVariable('is_mac');
      const Condition ios = ConditionVariable('is_ios');
      const Condition slim = ConditionVariable('slimpeller');
      const Condition wasm = ConditionComparison('target_os', true, 'wasm');
      const Condition fuchsia = ConditionComparison('target_os', true, 'fuchsia');
      // The path of `else if (is_mac)` after `if (is_ios)`.
      expect(ios.negated.and(mac), mac);
      expect(mac.and(ios), Condition.never);
      expect(mac.and(mac), mac);
      expect(mac.and(mac.negated), Condition.never);
      expect(mac.or(mac.negated), Condition.always);
      expect(mac.negated.or(ios.negated), Condition.always);
      expect(mac.negated.or(ios), mac.negated);
      expect(wasm.and(fuchsia), Condition.never);
      // An OS name or a platform name compared asserts the OS predicate it
      // names (and the platform name its CPU): `is_linux` beside
      // `target_os == "wasm"` or `full_target_platform_name == "wasm-wasm"`
      // never holds, and `wasm-wasm` beside `target_cpu == "x64"` neither.
      const Condition linux = ConditionVariable('is_linux');
      const Condition wasmWasm = ConditionComparison(
        'full_target_platform_name',
        true,
        'wasm-wasm',
      );
      const Condition linuxX64 = ConditionComparison(
        'full_target_platform_name',
        true,
        'linux-x64',
      );
      const Condition x64 = ConditionComparison('target_cpu', true, 'x64');
      expect(linux.and(wasm), Condition.never);
      expect(linux.and(wasmWasm), Condition.never);
      expect(wasmWasm.and(x64), Condition.never);
      expect(linux.and(linuxX64), const ConditionAnd(<Condition>[linux, linuxX64]));
      expect(linuxX64.and(x64), const ConditionAnd(<Condition>[linuxX64, x64]));
      expect(targetPlatformParts('darwin-arm64'), (osPredicate: 'is_mac', cpu: 'arm64'));
      expect(targetPlatformParts('windows-x64'), (osPredicate: 'is_win', cpu: 'x64'));
      expect(targetPlatformParts('nonsense'), isNull);
      expect(wasm.and(fuchsia.negated), wasm);
      expect(wasm.negated.or(fuchsia.negated), Condition.always);
      // Unrelated predicates are left alone, in order; so is anything that
      // would take more than one look (no resolution). A disjunction beside
      // the negation of one of its terms is absorbed, though: `!(slim &&
      // mac) && slim` is `!mac && slim` -- the shape of a scalar's earlier
      // case once a later write under a second condition overrides it.
      expect(slim.and(mac), const ConditionAnd(<Condition>[slim, mac]));
      expect(
        mac.or(ios).negated,
        const ConditionAnd(<Condition>[ConditionNot(mac), ConditionNot(ios)]),
      );
      expect(
        slim.and(mac).negated.and(slim),
        const ConditionAnd(<Condition>[ConditionNot(mac), slim]),
      );
    });

    test('reads a scalar reassigned under conditions by its cases', () async {
      final GnFileEvaluation evaluation = await evaluate('''
include_gl = !is_fuchsia && !is_win
if (slimpeller) {
  include_gl = false
}
if (is_win) {
  flavor = "win"
} else if (is_mac) {
  flavor = "mac"
} else {
  flavor = "posix"
}
if (is_mac) {
  verbose = true
} else {
  verbose = false
}
source_set("x") {
  sources = [ "x.cc" ]
  if (include_gl) {
    sources += [ "gl.cc" ]
  }
  if (verbose) {
    sources += [ "verbose.cc" ]
  }
  output_name = flavor
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      final GnTarget target = evaluation.targets.single;
      final List<GnAssignment> sources = target.variables['sources']!.assignments;
      expect(
        sources[1].condition,
        const ConditionAnd(<Condition>[
          ConditionNot(ConditionVariable('is_fuchsia')),
          ConditionNot(ConditionVariable('is_win')),
          ConditionNot(ConditionVariable('slimpeller')),
        ]),
      );
      expect(sources[2].condition, const ConditionVariable('is_mac'));
      final List<GnScalarCase> flavors = target.variables['output_name']!.cases(target.location);
      expect(flavors.map((GnScalarCase c) => '$c'), <String>[
        '[is_win] "win"',
        '[is_mac] "mac"',
        '[!is_win && !is_mac] "posix"',
      ]);
    });

    test('simplifies the cases of a scalar overridden under a second condition', () async {
      // build/archives' prefix: a value per runtime mode, then `-ddm` added
      // under dart_dynamic_modules. Each earlier case stands where the
      // later write does not happen, `a && !(b && a)`, which is `a && !b`.
      final GnFileEvaluation evaluation = await evaluate(r'''
source_set("x") {
  if (flutter_runtime_mode != "debug") {
    prefix = "linux-x64-$flutter_runtime_mode"
  } else {
    prefix = "linux-x64"
  }
  if (dart_dynamic_modules) {
    prefix = "$prefix-ddm"
  }
  output_name = prefix
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      final GnTarget target = evaluation.targets.single;
      expect(
        target.variables['output_name']!
            .cases(target.location)
            .map((GnScalarCase c) => '${c.condition}'),
        <String>[
          'flutter_runtime_mode != "debug" && !dart_dynamic_modules',
          'flutter_runtime_mode == "debug" && !dart_dynamic_modules',
          'dart_dynamic_modules && flutter_runtime_mode != "debug"',
          'dart_dynamic_modules && flutter_runtime_mode == "debug"',
        ],
      );
      expect(
        Condition.conjunction(const <Condition>[
          ConditionVariable('a'),
          ConditionVariable('b'),
          ConditionOr(<Condition>[
            ConditionNot(ConditionVariable('a')),
            ConditionNot(ConditionVariable('b')),
          ]),
        ]),
        Condition.never,
      );
      expect(
        Condition.conjunction(const <Condition>[
          ConditionVariable('a'),
          ConditionOr(<Condition>[ConditionVariable('a'), ConditionVariable('b')]),
        ]),
        const ConditionVariable('a'),
      );
    });

    test('takes is_clang as given under any assumptions', () async {
      final GnFileEvaluation evaluation = await evaluate('''
source_set("x") {
  sources = [ "x.cc" ]
  if (is_clang) {
    cflags = [ "-Wno-shadow" ]
  }
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(
        evaluation.targets.single.variables['cflags']!.assignments.single.condition,
        Condition.always,
      );
    });

    test('leaves skipped targets alone', () async {
      final GnFileEvaluation evaluation = await evaluate(
        '''
mystery_template("snapshot") {
  dart_main = "//flutter/x/main.dart"
  deps = [ exec_script("nope.py") ]
}
source_set("x") {
  sources = [ "x.cc" ]
}
''',
        skip: <String>{'snapshot'},
      );
      expect(evaluation.skipped, <String>['snapshot']);
      expect(evaluation.targets.map((GnTarget t) => t.name), <String>['x']);
    });

    test('answers defined() from the scope', () async {
      final GnFileEvaluation evaluation = await evaluate('''
source_set("x") {
  sources = [ "x.cc" ]
  if (!defined(defines)) {
    defines = []
  }
  defines += [ "X=1" ]
  if (defined(enable_unittests) && !defined(never_declared)) {
    defines += [ "Y=1" ]
  }
}
''');
      expect(evaluation.targets.single.variables['defines']!.unconditionalItems, <GnValue>[
        const GnStringValue('X=1'),
        const GnStringValue('Y=1'),
      ]);
    });

    test('records imports and comments', () async {
      final GnFileEvaluation evaluation = await evaluate('''
import("//flutter/common/config.gni")

# Says what x is for.
source_set("x") {
  # Why these sources.
  sources = [
    "a.cc",
    # Why b.
    "b.cc",
  ]
}
''');
      expect(evaluation.imports, <String>['//flutter/common/config.gni']);
      final GnTarget target = evaluation.targets.single;
      expect(target.comments, <String>['# Says what x is for.']);
      final GnAssignment sources = target.variables['sources']!.assignments.single;
      expect(sources.comments, <String>['# Why these sources.']);
      expect(sources.commentsOf(0).isEmpty, isTrue);
      expect(sources.commentsOf(1).before, <String>['# Why b.']);
    });

    test('foreach runs its body per element, in the enclosing scope', () async {
      // GN's foreach opens no scope: the body writes the enclosing
      // variables, the loop variable shadows a variable of the same name
      // only for the loop, and an element a condition adds to the list runs
      // the body under that condition (never under this host: not at all).
      final GnFileEvaluation evaluation = await evaluate('''
source_set("x") {
  f = "kept"
  names = [ "a", "b" ]
  if (is_mac) {
    names += [ "mac" ]
  }
  if (flutter_runtime_mode == "release") {
    names += [ "release" ]
  }
  sources = []
  foreach(f, names) {
    sources += [ f + ".cc" ]
  }
  output_name = f
}
''');
      final GnTarget target = evaluation.targets.single;
      expect(
        target.variables['sources']!.liveItems.map((GnListItem i) => '[${i.condition}] ${i.value}'),
        <String>[
          '[true] "a.cc"',
          '[true] "b.cc"',
          '[flutter_runtime_mode == "release"] "release.cc"',
        ],
      );
      expect(target.variables['output_name']!.unconditionalItems, <GnValue>[
        const GnStringValue('kept'),
      ]);
      // The loop variable is gone afterwards when it was not there before.
      await expectLater(
        evaluate('''
source_set("x") {
  sources = []
  foreach(f, [ "a" ]) {
    sources += [ f + ".cc" ]
  }
  output_name = f
}
'''),
        throwsGnError(line: 6, message: 'unknown variable f'),
      );
      await expectLater(
        evaluate('''
source_set("x") {
  foreach(f, "a") {
    sources = [ f ]
  }
}
'''),
        throwsGnError(line: 2, message: 'foreach() over something other than a list'),
      );
    });

    group('is strict about', () {
      test('exec_script and other calls in expressions', () async {
        // exec_script() as a statement does nothing the converter can use.
        await expectLater(
          evaluate('''
exec_script("check.py", [])
'''),
          throwsGnError(line: 1, message: 'exec_script() is not supported'),
        );
        await expectLater(
          evaluate('''
source_set("x") {
  sources = read_file("list.txt", "list lines")
}
'''),
          throwsGnError(line: 2, message: 'read_file() in an expression is not supported'),
        );
      });

      test('forward_variables_from outside a template', () async {
        await expectLater(
          evaluate('''
source_set("x") {
  forward_variables_from(invoker, [ "sources" ])
}
'''),
          throwsGnError(line: 2, message: 'invoker is not a scope'),
        );
      });

      test('unknown variables, functions and templates', () async {
        await expectLater(
          evaluate('''
source_set("x") {
  sources = extra_sources
}
'''),
          throwsGnError(line: 2, message: 'unknown variable extra_sources'),
        );
        await expectLater(
          evaluate('''
source_set("x") {
  if (use_thing) {
    sources = [ "a.cc" ]
  }
}
'''),
          throwsGnError(line: 2, message: 'unknown variable use_thing in condition'),
        );
        await expectLater(
          evaluate('''
my_template("x") {
  sources = [ "a.cc" ]
}
'''),
          throwsGnError(line: 1, message: 'unknown function or template my_template()'),
        );
      });

      test('string expansions', () async {
        await expectLater(
          evaluate(r'''
source_set("x") {
  sources = [ "$mystery_dir/a.cc" ]
}
'''),
          throwsGnError(line: 2, message: r'string expansion of $mystery_dir is not supported'),
        );
      });

      test('reassignment under a condition', () async {
        await expectLater(
          evaluate('''
source_set("x") {
  sources = [ "a.cc" ]
  if (slimpeller) {
    sources = [ "b.cc" ]
  }
}
'''),
          throwsGnError(line: 4, message: 'conditional reassignment of sources'),
        );
      });

      test('targets nested in conditions the assumptions cannot decide', () async {
        final GnFileEvaluation evaluation = await evaluate('''
if (enable_unittests) {
  source_set("linux_only") {
    sources = [ "a.cc" ]
  }
}
if (slimpeller) {
  source_set("maybe") {
    sources = [ "b.cc" ]
  }
} else {
  source_set("otherwise") {
    sources = [ "c.cc" ]
  }
}
''');
        expect(evaluation.targets[0].condition, Condition.always);
        expect(evaluation.targets[1].condition, const ConditionVariable('slimpeller'));
        // The target exists in Bazel but is incompatible where GN would not
        // define it.
        final String output = emitBuildFile(evaluation, gnPackage: '//flutter/example');
        expect(
          output,
          contains('''
cc_library(
    name = "maybe",
    srcs = ["b.cc"],
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    target_compatible_with = select({
        "//engine/src/flutter/common:slimpeller_enabled": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
'''),
        );
        expect(
          output,
          contains('''
    target_compatible_with = select({
        "//engine/src/flutter/common:slimpeller_enabled": ["@platforms//:incompatible"],
        "//conditions:default": [],
    }),
'''),
        );
        // Under --assume=none, enable_unittests is the testing package's
        // setting; a conjunction of mixed settings has no select().
        final String open = await convert('''
if (enable_unittests) {
  source_set("tests_only") {
    sources = [ "a.cc" ]
  }
}
''', assumptions: Assumptions(const <String, GnValue>{}));
        expect(
          open,
          contains('''
    target_compatible_with = select({
        "//engine/src/flutter/testing:unittests_enabled": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
'''),
        );
        // A conjunction of mixed settings keys a config_setting_group of
        // the file; a denied OS predicate is its complement group. A denied
        // flag has no complement and stays an error.
        final String mixed = await convert(
          '''
if (enable_unittests && !is_wasm) {
  source_set("x") {
    sources = [ "a.cc" ]
  }
}
impeller_shaders("entity_shaders") {
  name = "entity"
  if (impeller_enable_opengles && !is_wasm) {
    gles_language_version = 460
  }
  shaders = [ "shaders/solid_fill.vert" ]
}
''',
          templates: <String>{'impeller_shaders'},
          assumptions: Assumptions(const <String, GnValue>{}),
        );
        expect(
          mixed,
          contains('''
load("@bazel_skylib//lib:selects.bzl", "selects")
'''),
        );
        expect(
          mixed,
          contains('''
# `enable_unittests && !is_wasm`, for the select()s of this file.
selects.config_setting_group(
    name = "when_enable_unittests_and_not_is_wasm",
    match_all = [
        "//engine/src/flutter/testing:unittests_enabled",
        "//engine/src/flutter/build/bazel:not_wasm",
    ],
)
'''),
        );
        expect(
          mixed,
          contains('''
    target_compatible_with = select({
        ":when_enable_unittests_and_not_is_wasm": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
'''),
        );
        expect(
          mixed,
          contains('''
    gles_language_version = select({
        ":when_impeller_enable_opengles_and_not_is_wasm": 460,
        "//conditions:default": None,
    }),
'''),
        );
        await expectLater(
          convert('''
if (enable_unittests && !slimpeller) {
  source_set("x") {
    sources = [ "a.cc" ]
  }
}
''', assumptions: Assumptions(const <String, GnValue>{})),
          throwsGnError(
            line: 2,
            message: 'no config_setting holds exactly when `!slimpeller` does',
          ),
        );
      });
    });

    group('imports, arguments and templates', () {
      test('evaluates imports the policy names and records the known ones', () {
        final GnSourceTree tree = sourceTree(<String, String>{
          'lib/lists.gni': '''
_private = [ "hidden.cc" ]
example_sources = [
  "a.cc",
  "b.cc",
]
example_sources += _private
''',
          'flutter/example/BUILD.gn': '''
import("//known/config.gni")
import("../../lib/lists.gni")

source_set("x") {
  sources = example_sources
}
''',
        });
        final GnFileEvaluation evaluation = evaluateIn(tree, '//flutter/example/BUILD.gn');
        expect(evaluation.imports, <String>['//known/config.gni', '//lib/lists.gni']);
        expect(strings(evaluation.targets.single, 'sources'), <String>[
          'a.cc',
          'b.cc',
          'hidden.cc',
        ]);
        // The depfile names what was read.
        expect(tree.loadedFiles.map((String f) => tree.gnPath(f)), <String>[
          '//flutter/example/BUILD.gn',
          '//lib/lists.gni',
        ]);
      });

      test('get_path_info() of a list gives the list of absolute paths', () {
        // The client wrapper's core_wrapper_files.gni: file lists made
        // absolute where the .gni lives, read by the BUILD.gn beside it.
        final GnSourceTree tree = sourceTree(<String, String>{
          'flutter/lib/files.gni': '''
lib_sources = get_path_info([
                              "a.cc",
                              "sub/b.cc",
                            ],
                            "abspath")
lib_headers = get_path_info([ "include/x.h" ], "abspath")
''',
          'flutter/lib/BUILD.gn': '''
import("files.gni")

source_set("x") {
  sources = lib_sources
  public = lib_headers
}
''',
        });
        final GnFileEvaluation evaluation = evaluateIn(
          tree,
          '//flutter/lib/BUILD.gn',
          importPolicy: const ImportPolicy(evaluatedPrefixes: <String>{'//flutter/lib/'}),
        );
        expect(strings(evaluation.targets.single, 'sources'), <String>[
          '//flutter/lib/a.cc',
          '//flutter/lib/sub/b.cc',
        ]);
        expect(strings(evaluation.targets.single, 'public'), <String>['//flutter/lib/include/x.h']);
        final String output = emitBuildFile(evaluation, gnPackage: '//flutter/lib', tree: tree);
        expect(output, contains('    srcs = [\n        "a.cc",\n        "sub/b.cc",\n    ],\n'));
        expect(output, contains('    hdrs = ["include/x.h"],\n'));
      });

      test('keeps underscore names private and rejects unknown imports', () {
        final GnSourceTree tree = sourceTree(<String, String>{
          'lib/lists.gni': '_private = [ "hidden.cc" ]\n',
          'a/BUILD.gn': '''
import("//lib/lists.gni")
source_set("x") {
  sources = _private
}
''',
          'b/BUILD.gn': '''
import("//elsewhere/other.gni")
''',
        });
        expect(
          () => evaluateIn(tree, '//a/BUILD.gn'),
          throwsGnError(line: 3, message: 'unknown variable _private'),
        );
        expect(
          () => evaluateIn(tree, '//b/BUILD.gn'),
          throwsGnError(
            line: 1,
            message: 'import of //elsewhere/other.gni is neither evaluated nor known',
          ),
        );
      });

      test('declare_args() defaults yield to the assumptions', () {
        final GnSourceTree tree = sourceTree(<String, String>{
          'lib/args.gni': '''
declare_args() {
  enable_x = true
  x_level = 2
  x_name = "default"
}
''',
          'a/BUILD.gn': '''
import("//lib/args.gni")
source_set("x") {
  sources = [ "a.cc" ]
  defines = [ "NAME=" + x_name ]
  if (enable_x) {
    sources += [ "x.cc" ]
  }
  if (x_level >= 2) {
    defines += [ "LEVEL2" ]
  }
}
''',
        });
        final GnTarget defaults = evaluateIn(tree, '//a/BUILD.gn').targets.single;
        expect(strings(defaults, 'sources'), <String>['a.cc', 'x.cc']);
        expect(strings(defaults, 'defines'), <String>['NAME=default', 'LEVEL2']);

        final GnTarget overridden = evaluateIn(
          tree,
          '//a/BUILD.gn',
          assumptions: Assumptions(const <String, GnValue>{
            'enable_x': GnBoolValue(false),
            'x_level': GnIntValue(1),
            'x_name': GnStringValue('custom'),
          }),
        ).targets.single;
        expect(strings(overridden, 'sources'), <String>['a.cc']);
        expect(strings(overridden, 'defines'), <String>['NAME=custom']);
      });

      test('an argument the Bazel side defines keeps its name', () async {
        // impeller/tools/args.gni's shape: backend arguments with
        // per-platform defaults, and arguments derived from them.
        final GnSourceTree tree = sourceTree(<String, String>{
          'lib/args.gni': '''
declare_args() {
  impeller_enable_metal = is_mac || is_ios
  impeller_enable_vulkan = is_linux || is_win || enable_unittests
}
declare_args() {
  impeller_enable_compute = impeller_enable_vulkan || impeller_enable_metal
}
''',
          'flutter/a/BUILD.gn': '''
import("//lib/args.gni")
source_set("x") {
  sources = [ "a.cc" ]
  if (impeller_enable_vulkan) {
    sources += [ "vk.cc" ]
  }
  if (impeller_enable_compute) {
    sources += [ "compute.cc" ]
  }
}
''',
        });
        // Under --assume=none the arguments are their Bazel settings; the
        // derived one is the formula over them.
        final GnTarget open = evaluateIn(
          tree,
          '//flutter/a/BUILD.gn',
          assumptions: Assumptions(const <String, GnValue>{}),
        ).targets.single;
        final List<GnAssignment> sources = open.variables['sources']!.assignments;
        expect(sources[1].condition, const ConditionVariable('impeller_enable_vulkan'));
        expect(
          sources[2].condition,
          const ConditionOr(<Condition>[
            ConditionVariable('impeller_enable_vulkan'),
            ConditionVariable('impeller_enable_metal'),
          ]),
        );
        expect(
          emitBuildFile(
            evaluateIn(
              tree,
              '//flutter/a/BUILD.gn',
              assumptions: Assumptions(const <String, GnValue>{}),
            ),
            gnPackage: '//flutter/a',
          ),
          contains('''
    }) + select({
        "//engine/src/flutter/impeller/tools:vulkan": [
            "compute.cc",  # impeller_enable_compute
        ],
        "//engine/src/flutter/impeller/tools:metal": [
            "compute.cc",  # impeller_enable_compute
        ],
        "//conditions:default": [],
    }),
'''),
        );
        // The host assumptions decide them, as before.
        final GnTarget host = evaluateIn(tree, '//flutter/a/BUILD.gn').targets.single;
        expect(strings(host, 'sources'), <String>['a.cc', 'vk.cc', 'compute.cc']);
      });

      test('a placeholder group yields to the real target of its name', () async {
        // impeller_component's shape: an empty group stands in for a
        // testonly component when unit tests are off; the real target's
        // type is a variable written once in the branch that uses it.
        final GnSourceTree tree = sourceTree(<String, String>{
          'lib/component.gni': '''
template("component") {
  if (defined(invoker.testonly) && invoker.testonly && !enable_unittests) {
    group(target_name) {
      not_needed(invoker, "*")
    }
  } else {
    target_type = "source_set"
    if (defined(invoker.target_type)) {
      target_type = invoker.target_type
    }
    target(target_type, target_name) {
      forward_variables_from(invoker, "*")
    }
  }
}
''',
          'flutter/a/BUILD.gn': '''
import("//lib/component.gni")
component("x_unittests") {
  testonly = true
  sources = [ "x_unittests.cc" ]
}
component("x") {
  sources = [ "x.cc" ]
}
''',
          'flutter/b/BUILD.gn': '''
if (slimpeller) {
  source_set("twice") {
    sources = [ "a.cc" ]
  }
}
if (is_debug) {
  source_set("twice") {
    sources = [ "b.cc" ]
  }
}
''',
        });
        final GnFileEvaluation open = evaluateIn(
          tree,
          '//flutter/a/BUILD.gn',
          assumptions: Assumptions(const <String, GnValue>{}),
        );
        // The placeholder group is resolved away in the evaluation: one
        // target per name, the real one under its condition.
        expect(open.targets.map((GnTarget t) => '${t.rule} ${t.name} [${t.condition}]'), <String>[
          'source_set x_unittests [enable_unittests]',
          'source_set x [true]',
        ]);
        final String output = emitBuildFile(open, gnPackage: '//flutter/a');
        expect('cc_library('.allMatches(output).length, 2);
        expect(
          output,
          contains('''
cc_library(
    name = "x_unittests",
    testonly = True,
    srcs = ["x_unittests.cc"],
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    target_compatible_with = select({
        "//engine/src/flutter/testing:unittests_enabled": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
'''),
        );
        expect(
          () => emitBuildFile(
            evaluateIn(
              tree,
              '//flutter/b/BUILD.gn',
              assumptions: Assumptions(const <String, GnValue>{}),
            ),
            gnPackage: '//flutter/b',
          ),
          throwsGnError(line: 7, message: 'target twice is defined more than once'),
        );
      });

      test('two definitions of a name in branches that cannot both run become one target', () {
        // Skia's optional() shape: the feature's sources and public config
        // when it is enabled, an empty source set otherwise, under an
        // argument the host assumptions leave open (skia_use_fontconfig is
        // the fontconfig flag). One cc_library, each branch's variables
        // under its condition, the public config inherited by dependents
        // under the same condition; what both branches set the same way
        // stays unconditional.
        final GnSourceTree tree = sourceTree(<String, String>{
          'lib/optional.gni': '''
declare_args() {
  skia_use_fontconfig = is_linux
}
declare_args() {
  skia_enable_fontmgr_fontconfig = skia_use_fontconfig
}
template("optional") {
  if (invoker.enabled) {
    config(target_name + "_public") {
      defines = invoker.public_defines
    }
    source_set(target_name) {
      visibility = [ ":*" ]
      configs = [ ":lib_config" ]
      forward_variables_from(invoker, "*", [ "configs", "public_defines" ])
      all_dependent_configs = [ ":" + target_name + "_public" ]
    }
  } else {
    source_set(target_name) {
      visibility = [ ":*" ]
      configs = [ ":lib_config" ]
      forward_variables_from(invoker, "*", [ "configs", "public_defines", "public_deps", "deps", "sources", "public" ])
    }
  }
}
''',
          'flutter/a/BUILD.gn': '''
import("//lib/optional.gni")
config("lib_config") {
  defines = [ "LIB" ]
}
optional("fontmgr_fontconfig") {
  enabled = skia_enable_fontmgr_fontconfig
  public_defines = [ "SK_FONTMGR_FONTCONFIG_AVAILABLE" ]
  public = [ "fontmgr_fontconfig.h" ]
  sources = [ "fontmgr_fontconfig.cc" ]
  deps = [ ":typeface" ]
}
source_set("typeface") {
  sources = [ "typeface.cc" ]
}
source_set("skia") {
  sources = [ "skia.cc" ]
  deps = [ ":fontmgr_fontconfig" ]
}
''',
        });
        final GnFileEvaluation evaluation = evaluateIn(tree, '//flutter/a/BUILD.gn');
        expect(
          evaluation.targets.map((GnTarget t) => '${t.rule} ${t.name} [${t.condition}]'),
          <String>[
            'config lib_config [true]',
            'config fontmgr_fontconfig_public [skia_use_fontconfig]',
            'source_set fontmgr_fontconfig [true]',
            'source_set typeface [true]',
            'source_set skia [true]',
          ],
        );
        final GnTarget merged = evaluation.targets[2];
        expect(strings(merged, 'configs'), <String>[':lib_config']);
        expect(merged.variables['sources']!.unconditionalItems, isNull);
        expect(
          merged.variables['sources']!.assignments.map((GnAssignment a) => a.toString()),
          <String>['[skia_use_fontconfig] += ["fontmgr_fontconfig.cc"]'],
        );
        expect(
          evaluation.inheritedConfigs['skia']!.map(
            (String config, Condition when) => MapEntry<String, String>(config, '$when'),
          ),
          <String, String>{':fontmgr_fontconfig_public': 'skia_use_fontconfig'},
        );
        final String output = emitBuildFile(evaluation, gnPackage: '//flutter/a', tree: tree);
        expect(
          output,
          contains('''
cc_library(
    name = "fontmgr_fontconfig_public",
    defines = ["SK_FONTMGR_FONTCONFIG_AVAILABLE"],
    target_compatible_with = select({
        "//engine/src/flutter/txt:fontconfig": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
)

cc_library(
    name = "fontmgr_fontconfig",
    srcs = select({
        "//engine/src/flutter/txt:fontconfig": [
            "fontmgr_fontconfig.cc",  # skia_use_fontconfig
        ],
        "//conditions:default": [],
    }),
    hdrs = select({
        "//engine/src/flutter/txt:fontconfig": [
            "fontmgr_fontconfig.h",  # skia_use_fontconfig
        ],
        "//conditions:default": [],
    }),
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES + ["LIB"],
    deps = ["//engine/src:include_root"] + select({
        "//engine/src/flutter/txt:fontconfig": [
            ":fontmgr_fontconfig_public",  # skia_use_fontconfig
            ":typeface",  # skia_use_fontconfig
        ],
        "//conditions:default": [],
    }),
    alwayslink = True,
)
'''),
        );
        expect(
          output,
          contains('''
cc_library(
    name = "skia",
    srcs = ["skia.cc"],
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        ":fontmgr_fontconfig",
        "//engine/src:include_root",
    ] + select({
        "//engine/src/flutter/txt:fontconfig": [":fontmgr_fontconfig_public"],
        "//conditions:default": [],
    }),
    alwayslink = True,
)
'''),
        );
        // Decided either way, the file is the one branch, as before.
        final GnFileEvaluation off = evaluateIn(
          tree,
          '//flutter/a/BUILD.gn',
          assumptions: linuxHostAssumptions().withValues(const <String, GnValue>{
            'skia_use_fontconfig': GnBoolValue(false),
          }),
        );
        expect(off.targets.map((GnTarget t) => t.name), <String>[
          'lib_config',
          'fontmgr_fontconfig',
          'typeface',
          'skia',
        ]);
        expect(off.targets[1].variables.containsKey('sources'), isFalse);
        expect(off.inheritedConfigs['skia'], isEmpty);
      });

      test('an item both definitions of a name append is in the list under either', () {
        // skcms's arch() under the generation scope: a source set in both
        // branches of an `if` on a conjunction (`current_cpu == "x64" &&
        // target_os != "android"`, the latter decided). The target exists
        // under either branch, so unconditionally; a dependency both
        // branches add (skia_source_set's raw_ptr) is unconditional too,
        // not listed once under each branch -- the denied branch has no
        // config_setting of its own.
        final GnSourceTree tree = sourceTree(<String, String>{
          'flutter/a/BUILD.gn': '''
template("arch") {
  if (invoker.enabled) {
    source_set(target_name) {
      forward_variables_from(invoker, "*")
      deps += [ ":common" ]
    }
  } else {
    source_set(target_name) {
      forward_variables_from(invoker, "*", [ "sources", "cflags", "deps" ])
      deps = [ ":common" ]
    }
  }
}
arch("hsw") {
  enabled = current_cpu == "x64" && target_os != "android"
  sources = [ "hsw.cc" ]
  cflags = [ "-mavx2" ]
  deps = [ ":extra" ]
}
source_set("common") {
  sources = [ "common.cc" ]
}
source_set("extra") {
  sources = [ "extra.cc" ]
}
''',
        });
        final GnFileEvaluation evaluation = evaluateIn(
          tree,
          '//flutter/a/BUILD.gn',
          assumptions: generationAssumptions(),
        );
        final GnTarget merged = evaluation.targets.first;
        expect(merged.name, 'hsw');
        expect(merged.condition, Condition.always);
        expect(
          merged.variables['deps']!.assignments.map((GnAssignment a) => a.toString()),
          <String>[
            '[current_cpu == "x64" && target_os != "android"] += [":extra"]',
            '[true] += [":common"]',
          ],
        );
        final String output = emitBuildFile(evaluation, gnPackage: '//flutter/a', tree: tree);
        expect(
          output,
          contains('''
cc_library(
    name = "hsw",
    srcs = select({
        ":when_current_cpu_x64_and_target_os_not_android": [
            "hsw.cc",  # current_cpu == "x64" && target_os != "android"
        ],
        "//conditions:default": [],
    }),
    copts = CHROMIUM_CODE_COPTS + select({
        ":when_current_cpu_x64_and_target_os_not_android": [
            "-mavx2",  # current_cpu == "x64" && target_os != "android"
        ],
        "//conditions:default": [],
    }),
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        ":common",
        "//engine/src:include_root",
    ] + select({
        ":when_current_cpu_x64_and_target_os_not_android": [
            ":extra",  # current_cpu == "x64" && target_os != "android"
        ],
        "//conditions:default": [],
    }),
    alwayslink = True,
)
'''),
        );
      });

      test('runs templates as closures with invoker and target_name', () {
        final GnSourceTree tree = sourceTree(<String, String>{
          'lib/templates.gni': '''
_extra_deps = [ "//lib:extra" ]

template("my_lib") {
  source_set(target_name) {
    forward_variables_from(invoker, "*", [ "deps" ])
    deps = _extra_deps
    if (defined(invoker.deps)) {
      deps += invoker.deps
    }
    if (defined(invoker.flavour)) {
      defines = [ "FLAVOUR_" + invoker.flavour ]
    }
  }
  _invocation = target_name
  group(target_name + "_group") {
    deps = [ ":" + _invocation, ":" + target_name ]
  }
}

template("my_other_lib") {
  static_library(target_name) {
    forward_variables_from(invoker, [ "sources", "missing" ])
  }
}
''',
          'a/BUILD.gn': '''
import("//lib/templates.gni")

# About x.
my_lib("x") {
  sources = [ "a.cc" ]
  deps = [ "//lib:dep" ]
  flavour = "vanilla"
}

my_other_lib("y") {
  sources = [ "b.cc" ]
}
''',
        });
        final GnFileEvaluation evaluation = evaluateIn(tree, '//a/BUILD.gn');
        expect(evaluation.targets.map((GnTarget t) => t.name), <String>['x', 'x_group', 'y']);
        final GnTarget x = evaluation.targets[0];
        expect(x.rule, 'source_set');
        expect(x.comments, <String>['# About x.']);
        expect(strings(x, 'sources'), <String>['a.cc']);
        expect(strings(x, 'deps'), <String>['//lib:extra', '//lib:dep']);
        expect(strings(x, 'defines'), <String>['FLAVOUR_vanilla']);
        // Forwarded variables are marked, so that bookkeeping like `flavour`
        // can be told from what the template wrote.
        expect(x.variables['flavour']!.forwarded, isTrue);
        expect(x.variables['deps']!.forwarded, isFalse);
        final GnTarget group = evaluation.targets[1];
        expect(group.rule, 'group');
        expect(group.comments, isEmpty);
        // target_name reflects the innermost scope (GN's reference): inside
        // the group's block it is the group's own name, and the template's
        // invocation name is what it saved outside.
        expect(strings(group, 'deps'), <String>[':x', ':x_group']);
        final GnTarget y = evaluation.targets[2];
        expect(y.rule, 'static_library');
        expect(strings(y, 'sources'), <String>['b.cc']);
        expect(y.variables.containsKey('missing'), isFalse);
      });

      test('defines target_name in the invocation block, as GN does', () {
        // impeller/display_list's local templates read invoker.target_name
        // (GN's FillTargetBlockScope sets it in the block's scope); the
        // forwarded "*" leaves it out, the body having its own.
        final GnSourceTree tree = sourceTree(<String, String>{
          'a/BUILD.gn': '''
template("suite") {
  target_name = invoker.target_name
  source_set(target_name) {
    forward_variables_from(invoker, "*")
    sources += [ "common.cc" ]
  }
}

suite("x") {
  sources = [ "x.cc" ]
}
''',
        });
        final GnFileEvaluation evaluation = evaluateIn(tree, '//a/BUILD.gn');
        final GnTarget x = evaluation.targets.single;
        expect(x.name, 'x');
        expect(strings(x, 'sources'), <String>['x.cc', 'common.cc']);
        expect(x.variables.containsKey('target_name'), isFalse);
      });

      test('a template invokes another, forwarding into its own scope', () {
        // publish.gni's shape: publish_client_wrapper_extension invokes
        // publish_client_wrapper_core, which invokes publish_client_wrapper;
        // each forwards an optional invoker variable into template scope,
        // tests it with defined() and derives the copies' destination from
        // it, and the inner template names a file of its own directory.
        final GnSourceTree tree = sourceTree(<String, String>{
          'lib/publish.gni': r'''
_readme = get_path_info("README", "abspath")

template("publish") {
  forward_variables_from(invoker, [ "suffix" ])
  if (defined(suffix)) {
    dir = "$root_out_dir/wrapper_$suffix"
  } else {
    dir = "$root_out_dir/wrapper"
  }
  group(target_name) {
    forward_variables_from(invoker, [ "public_deps" ])
    deps = [ ":${target_name}_sources" ]
  }
  copy("${target_name}_sources") {
    sources = invoker.sources + [ _readme ]
    outputs = [ "$dir/{{source_file_part}}" ]
  }
}

template("publish_extension") {
  publish("${target_name}_core") {
    forward_variables_from(invoker, [ "suffix" ])
    sources = [ "//lib/core.cc" ]
  }
  publish(target_name) {
    forward_variables_from(invoker, [ "sources", "suffix" ])
    public_deps = [ ":${target_name}_core" ]
  }
}
''',
          'a/BUILD.gn': '''
import("//lib/publish.gni")

publish_extension("wrapper_a") {
  sources = [ "a.cc" ]
  suffix = "a"
}

publish("plain") {
  sources = [ "p.cc" ]
}
''',
        });
        final GnFileEvaluation evaluation = evaluateIn(tree, '//a/BUILD.gn');
        expect(evaluation.targets.map((GnTarget t) => t.name), <String>[
          'wrapper_a_core',
          'wrapper_a_core_sources',
          'wrapper_a',
          'wrapper_a_sources',
          'plain',
          'plain_sources',
        ]);
        final GnTarget core = evaluation.targets[1];
        expect(core.rule, 'copy');
        expect(strings(core, 'sources'), <String>['//lib/core.cc', '//lib/README']);
        expect(strings(core, 'outputs'), <String>['$buildDirRoot/wrapper_a/{{source_file_part}}']);
        final GnTarget wrapper = evaluation.targets[2];
        expect(wrapper.rule, 'group');
        expect(strings(wrapper, 'public_deps'), <String>[':wrapper_a_core']);
        expect(strings(wrapper, 'deps'), <String>[':wrapper_a_sources']);
        expect(strings(evaluation.targets[3], 'sources'), <String>['a.cc', '//lib/README']);
        // Without a suffix, defined() is false and the plain destination is
        // used; the template-scope variable of one invocation does not leak
        // into the next.
        final GnTarget plain = evaluation.targets[5];
        expect(strings(plain, 'outputs'), <String>['$buildDirRoot/wrapper/{{source_file_part}}']);
        expect(evaluation.targets[4].variables.containsKey('public_deps'), isFalse);
      });

      test("+= on an enclosing scope's variable modifies a copy, as GN does", () {
        // The embedder's embedder_source_set forwards public_configs into
        // template scope and the target block appends to it
        // (Scope::GetValueForcedToCurrentScope); the template-scope value
        // stays as it was for a second target.
        final GnSourceTree tree = sourceTree(<String, String>{
          'a/BUILD.gn': '''
config("a_config") {
  defines = [ "A" ]
}

config("b_config") {
  defines = [ "B" ]
}

template("twice") {
  forward_variables_from(invoker, "*")
  source_set(target_name) {
    sources = [ "x.cc" ]
    public_configs += [ ":a_config" ]
  }
  source_set(target_name + "_plain") {
    sources = [ "y.cc" ]
  }
}

twice("x") {
  public_configs = [ ":b_config" ]
}
''',
        });
        final GnFileEvaluation evaluation = evaluateIn(tree, '//a/BUILD.gn');
        final GnTarget x = evaluation.targets.singleWhere((GnTarget t) => t.name == 'x');
        expect(strings(x, 'public_configs'), <String>[':b_config', ':a_config']);
        final GnTarget plain = evaluation.targets.singleWhere((GnTarget t) => t.name == 'x_plain');
        expect(plain.variables.containsKey('public_configs'), isFalse);
      });

      test('is strict about templates too', () {
        final GnSourceTree tree = sourceTree(<String, String>{
          'lib/templates.gni': '''
template("clobbering") {
  source_set(target_name) {
    sources = [ "own.cc" ]
    forward_variables_from(invoker, [ "sources" ])
  }
}
''',
          'a/BUILD.gn': '''
import("//lib/templates.gni")
clobbering("x") {
  sources = [ "a.cc" ]
}
''',
          'lib/targets.gni': '''
source_set("in_gni") {
  sources = [ "a.cc" ]
}
''',
          'b/BUILD.gn': 'import("//lib/targets.gni")\n',
        });
        expect(
          () => evaluateIn(tree, '//a/BUILD.gn'),
          throwsGnError(line: 4, message: 'forward_variables_from() would clobber sources'),
        );
        expect(
          () => evaluateIn(tree, '//b/BUILD.gn'),
          throwsGnError(line: 1, message: 'target defined in an imported file'),
        );
      });

      test('short-circuits && and || and compares integers', () async {
        final GnFileEvaluation evaluation = await evaluate('''
source_set("x") {
  sources = [ "a.cc" ]
  if (is_android && defined(ndk_api) && ndk_api >= 30) {
    sources += [ "android.cc" ]
  }
  if (is_linux || never_declared) {
    sources += [ "linux.cc" ]
  }
}
''');
        expect(strings(evaluation.targets.single, 'sources'), <String>['a.cc', 'linux.cc']);
      });

      test('reads a variable with conditional appends as conditional items', () async {
        final GnFileEvaluation evaluation = await evaluate('''
source_set("x") {
  _sources = [ "a.cc" ]
  if (is_win) {
    _sources += [ "win.cc" ]
  }
  if (slimpeller) {
    _sources += [ "slim.cc" ]
  }
  sources = _sources
}
''');
        final List<GnAssignment> sources =
            evaluation.targets.single.variables['sources']!.assignments;
        expect(sources, hasLength(2));
        expect(sources[0].op, '=');
        expect(sources[0].condition, Condition.always);
        expect(sources[0].items, <GnValue>[const GnStringValue('a.cc')]);
        expect(sources[1].op, '+=');
        expect(sources[1].condition, const ConditionVariable('slimpeller'));
        expect(sources[1].items, <GnValue>[const GnStringValue('slim.cc')]);
      });

      test('converts action() with rebased paths and generated outputs', () async {
        final GnSourceTree tree = sourceTree(<String, String>{
          'flutter/example/gen.py': '',
          'flutter/example/CHANGES': '',
          'flutter/example/grammars/core.json': '',
          'flutter/example/BUILD.gn': r'''
action("tables") {
  script = "gen.py"
  grammar_dir = "grammars"
  out_file = "${target_gen_dir}/tables.inc"
  sources = [ "$grammar_dir/core.json" ]
  outputs = [ out_file ]
  args = [
    "--grammar=" + rebase_path("$grammar_dir/core.json", root_build_dir),
    "--grammar-dir",
    rebase_path(grammar_dir, root_build_dir),
    rebase_path("CHANGES", root_build_dir),
    "--out",
    rebase_path(out_file, root_build_dir),
  ]
}

config("gen_dirs") {
  include_dirs = [ get_label_info(":tables", "target_gen_dir") + "/include" ]
}

source_set("lib") {
  sources = [ "lib.cc" ]
  deps = [ ":tables" ]
  configs += [ ":gen_dirs" ]
}
''',
        });
        final String output = emitBuildFile(
          evaluateIn(tree, '//flutter/example/BUILD.gn'),
          gnPackage: '//flutter/example',
          tree: tree,
        );
        expect(
          output,
          contains(r'''
gn_action(
    name = "tables",
    srcs = ["grammars/core.json"],
    args = [
        "--grammar=$(execpath :grammars/core.json)",
        "--grammar-dir",
        "$(src engine/src/flutter/example/grammars)",
        "$(execpath :CHANGES)",
        "--out",
        "$(gen engine/src/flutter/example/tables.inc)",
    ],
    inputs = ["CHANGES"],
    outputs = ["tables.inc"],
    script = "gen.py",
)
'''),
        );
        // The action's outputs are sources of its dependent; the generated
        // include directory is the package's (Bazel's `includes` spans the
        // output tree).
        expect(output, contains('srcs = [\n        "lib.cc",\n        ":tables",\n    ],'));
        expect(output, contains('includes = ["include"]'));
        expect(output, contains('load("//build_defs/gn:gn_action.bzl", "gn_action")'));
      });

      test("names a test after its output_name, with GN's name as an alias", () async {
        // The Android suites run_tests.py pushes by file name
        // (impeller_toolkit_android_unittests for toolkit/android's
        // `unittests`), as a binary with an output_name is named.
        final String output = await convert('''
source_set("unittests_lib") {
  testonly = true
  sources = [ "x_unittests.cc" ]
}
executable("unittests") {
  testonly = true
  output_name = "impeller_toolkit_android_unittests"
  deps = [ ":unittests_lib" ]
}
''');
        expect(output, contains('cc_test(\n    name = "impeller_toolkit_android_unittests",'));
        expect(
          output,
          contains(
            'alias(\n    name = "unittests",\n    actual = ":impeller_toolkit_android_unittests",',
          ),
        );
      });

      test('converts action() outputs and inputs in the build directory', () async {
        // The Android embedding's Java actions: outputs at the build root
        // named by the runtime mode, an input another action puts there, a
        // bare enumerated variable as an argument, a program run by its
        // absolute path (the JDK's), and a target's outputs among the
        // sources and arguments.
        final GnSourceTree tree = sourceTree(<String, String>{
          'flutter/example/gen.py': '',
          'flutter/example/pack.py': '',
          'flutter/example/a.java': '',
          'flutter/example/BUILD.gn': r'''
action("config") {
  script = "gen.py"
  outputs = [ "$target_gen_dir/Config.java" ]
  args = [ "--mode", flutter_runtime_mode ]
}

action("jar") {
  script = "pack.py"
  sources = [ "a.java" ]
  sources += get_target_outputs(":config")
  jar_path = "$root_out_dir/embedding_$flutter_runtime_mode.jar"
  outputs = [ jar_path, "$target_gen_dir/jar.d" ]
  _jarbin = rebase_path("//flutter/third_party/java/openjdk/bin/jar")
  args = [
    "--jar-bin=$_jarbin",
    "--jar-path=" + rebase_path(jar_path, root_build_dir),
    "--depfile=" + rebase_path("$target_gen_dir/jar.d", root_build_dir),
  ] + rebase_path(sources, root_build_dir)
  deps = [ ":config" ]
}

action("bundle") {
  script = "pack.py"
  inputs = [ "$root_build_dir/embedding_$flutter_runtime_mode.jar", "$root_build_dir/libflutter.so" ]
  outputs = [ "$root_build_dir/flutter.jar" ]
  args = [
    "--output",
    rebase_path("$root_build_dir/flutter.jar", root_build_dir),
    "--native",
    rebase_path("$root_build_dir/libflutter.so", root_build_dir),
  ]
  deps = [ ":jar" ]
}
''',
        });
        final String output = emitBuildFile(
          evaluateIn(tree, '//flutter/example/BUILD.gn'),
          gnPackage: '//flutter/example',
          tree: tree,
        );
        // The bare variable: one argument per mode, under the mode.
        expect(
          output,
          contains(r'''
    args = ["--mode"] + select({
        "//engine/src/flutter/common:runtime_mode_debug": ["debug"],
        "//conditions:default": [],
    }) + select({
        "//engine/src/flutter/common:runtime_mode_profile": ["profile"],
'''),
        );
        // The jar: a tool with its runtime, a build output per mode named
        // by its path under the build directory, the depfile a plain
        // output, and the generated source as its target's file.
        expect(output, contains(r'"--jar-bin=$(execpath @openjdk//:bin/jar)"'));
        expect(
          output,
          contains(r'''
    tools = [
        "@openjdk//:bin/jar",
        "@openjdk//:runtime",
    ],
'''),
        );
        expect(
          output,
          contains(r'''
    build_outputs = select({
        "//engine/src/flutter/common:runtime_mode_debug": ["embedding_debug.jar"],
        "//conditions:default": [],
    }) + select({
'''),
        );
        expect(
          output,
          contains(
            r'"//engine/src/flutter/common:runtime_mode_debug": ["--jar-path=$(built embedding_debug.jar)"]',
          ),
        );
        expect(output, contains(r'"--depfile=$(gen engine/src/flutter/example/jar.d)"'));
        expect(output, contains('outputs = ["jar.d"]'));
        expect(output, contains(r'"$(execpath :config)"'));
        expect(output, contains('srcs = [\n        "a.java",\n        ":config",\n    ],'));
        // The bundle: its inputs of the build directory are build_inputs,
        // its own output a build output, both named by their paths there.
        expect(
          output,
          contains(r'''
    build_inputs = select({
        "//engine/src/flutter/common:runtime_mode_debug": ["embedding_debug.jar"],
        "//conditions:default": [],
    }) + select({
'''),
        );
        expect(
          output,
          contains('    }) + ["libflutter.so"],\n    build_outputs = ["flutter.jar"],'),
        );
        expect(output, contains(r'"$(built flutter.jar)"'));
        expect(output, contains(r'"$(built libflutter.so)"'));
      });

      test('keeps rebase_path() and exec_script() opaque until they are used', () async {
        final GnFileEvaluation evaluation = await evaluate('''
_unused = rebase_path("//somewhere", "//elsewhere")
_also_unused = exec_script("list.py", [], "list lines")
source_set("x") {
  sources = [ "a.cc" ]
}
''');
        expect(strings(evaluation.targets.single, 'sources'), <String>['a.cc']);
        await expectLater(
          convert('''
source_set("x") {
  sources = [ "a.cc" ]
  include_dirs = [ rebase_path("//somewhere", "//elsewhere") ]
}
'''),
          throwsGnError(
            line: 3,
            message: 'expected a string, got <rebase_path("//somewhere", "//elsewhere")>',
          ),
        );
        // A path rebased to the build directory is for an action's args.
        await expectLater(
          convert('''
source_set("x") {
  sources = [ "a.cc" ]
  include_dirs = [ rebase_path("//somewhere", root_build_dir) ]
}
'''),
          throwsGnError(line: 3, message: 'only usable in the args of an action()'),
        );
      });

      test(
        'evaluates string_replace(), cased assumptions and paths relative to the build directory',
        () async {
          // The Android embedding's jar names: the ABI (config.gni's table
          // by current_cpu, a cased assumption) with its dashes replaced,
          // joined to the runtime mode (a bare reference), as a path under
          // the build directory (the three-argument rebase_path).
          final GnFileEvaluation evaluation = await evaluate(r'''
action("jar") {
  script = "pack.py"
  artifact_id = string_replace(android_app_abi, "-", "_") + "_" + flutter_runtime_mode
  jar_filename = "$artifact_id.jar"
  outputs = [ "$root_build_dir/$jar_filename" ]
  args = [
    "--output",
    rebase_path("flutter.jar", root_build_dir, root_build_dir),
    "--native",
    rebase_path(jar_filename, root_build_dir, root_build_dir),
    "--abi",
    android_app_abi,
  ]
}
''');
          final GnTarget jar = evaluation.targets.single;
          final List<GnScalarCase> id = jar.variables['artifact_id']!.cases(jar.location);
          expect(id.map((GnScalarCase c) => c.condition.toString()), <String>[
            'current_cpu == "x86"',
            'current_cpu == "arm"',
            'current_cpu == "x64"',
            'current_cpu == "arm64"',
            'current_cpu == "riscv64"',
          ]);
          expect(id[1].value.toString(), r'"armeabi_v7a_$flutter_runtime_mode"');
          final List<GnValue> args = jar.variables['args']!.liveItems
              .map((GnListItem i) => i.value)
              .toList();
          expect(args[1], const GnStringValue('\u0001//@out/flutter.jar\u0001'));
          final List<GnListItem> natives = jar.variables['args']!.liveItems
              .where((GnListItem i) => i.value.toString().contains('v8a_'))
              .toList();
          expect(
            natives.single.value.toString(),
            '"\u0001//@out/arm64_v8a_\$flutter_runtime_mode.jar\u0001"',
          );
          expect(natives.single.condition.toString(), 'current_cpu == "arm64"');
          // The bare ABI: its five cases, the last riscv64's.
          expect(args.last, const GnStringValue('riscv64'));
          expect(
            jar.variables['args']!.liveItems.last.condition.toString(),
            'current_cpu == "riscv64"',
          );
        },
      );

      test(
        "evaluates nested lists by index, as the validation layers' foreach reads them",
        () async {
          final GnFileEvaluation evaluation = await evaluate(r'''
layer_sources = [ "a.cpp", "b.cpp" ]
layers = [ [ "khronos", layer_sources, [ ":glslang" ], [] ] ]
foreach(layer_info, layers) {
  name = layer_info[0]
  shared_library("VkLayer_$name") {
    sources = layer_info[1]
    deps = [ ":utils" ]
    if (layer_info[2] != "") {
      deps += layer_info[2]
    }
    defines = layer_info[3]
  }
}
''');
          final GnTarget layer = evaluation.targets.single;
          expect(layer.name, 'VkLayer_khronos');
          expect(strings(layer, 'sources'), <String>['a.cpp', 'b.cpp']);
          expect(strings(layer, 'deps'), <String>[':utils', ':glslang']);
          expect(strings(layer, 'defines'), <String>[]);
        },
      );

      test('keeps the order of arguments around a cased string', () async {
        // `[ "--platform", _platform, dir ]` with _platform cased by OS:
        // the select() sits where the element is, not after the list.
        final String output = await convert(r'''
action("json") {
  script = "gen.py"
  outputs = [ "$root_out_dir/data/layer.json" ]
  if (flutter_runtime_mode == "debug") {
    _platform = "Debug"
  } else {
    _platform = "Other"
  }
  args = [ "--platform", _platform, rebase_path("$root_out_dir/data", root_build_dir), rebase_path(root_build_dir, root_build_dir) ]
  data = outputs
}
''');
        expect(
          output,
          contains(r'''
    args = ["--platform"] + select({
        "//engine/src/flutter/common:runtime_mode_debug": [
            "Debug",  # flutter_runtime_mode == "debug"
        ],
        "//conditions:default": [],
    }) + select({
        "//engine/src/flutter/common:runtime_mode_debug": [],
        "//conditions:default": [
            "Other",  # !(flutter_runtime_mode == "debug")
        ],
    }) + [
        "$(built data)",
        "$(built .)",
    ],
    build_outputs = ["data/layer.json"],
'''),
        );
      });

      test('builds a dependency with a toolchain for its platform, and archives one of several build outputs', () async {
        final GnSourceTree tree = sourceTree(<String, String>{
          'flutter/example/pack.py': '',
          'flutter/example/javac.py': '',
          'flutter/example/BUILD.gn': r'''
import("//flutter/build/zip_bundle.gni")

action("jar") {
  script = "pack.py"
  outputs = [ "$root_build_dir/flutter.jar", "$root_build_dir/engine.jar" ]
  args = [
    "--output", rebase_path("flutter.jar", root_build_dir, root_build_dir),
    "--version", engine_version,
  ]
  deps = [ ":java" ]
  apilevel26_toolchain = "//build/toolchain/android:clang_arm64_apilevel26"
  validation_layer_target = "//third_party/vulkan_validation_layers($apilevel26_toolchain)"
  deps += [ validation_layer_target ]
  validation_layer_out_dir = get_label_info(validation_layer_target, "root_out_dir")
  args += [ "--native_lib", rebase_path("$validation_layer_out_dir/libVkLayer_khronos_validation.so") ]
}

action("java") {
  script = "javac.py"
  outputs = [ "$target_gen_dir/java.d" ]
}

zip_bundle("jar_zip") {
  output = "android-arm64/artifacts.zip"
  files = [
    {
      source = "$root_build_dir/flutter.jar"
      destination = "flutter.jar"
    },
  ]
  deps = [ ":jar" ]
}
''',
        });
        final String output = emitBuildFile(
          evaluateIn(tree, '//flutter/example/BUILD.gn', templates: <String>{'zip_bundle'}),
          gnPackage: '//flutter/example',
          tree: tree,
        );
        expect(
          output,
          contains(r'''
    args = [
        "--output",
        "$(built flutter.jar)",
        "--version",
        ENGINE_VERSION,
        "--native_lib",
        "$(built clang_arm64_apilevel26/libVkLayer_khronos_validation.so)",
    ],
    build_outputs = [
        "flutter.jar",
        "engine.jar",
    ],
    platform = "//engine/src/flutter/build/bazel/toolchains:android_arm64_api26",
    platform_build_dir = "clang_arm64_apilevel26",
    platform_deps = ["@vulkan_validation_layers"],
    script = "pack.py",
    deps = [":java"],
'''),
        );
        expect(output, contains('load("@engine_version//:version.bzl", "ENGINE_VERSION")'));
        expect(output, contains('files = {"flutter.jar": ":jar"}'));
        expect(output, contains('sources = {"flutter.jar": "flutter.jar"}'));
      });

      test(
        'lays a Maven tree out: foreach passes, get_path_info parts, constants in paths',
        () async {
          // The Android embedding's embedding_jars: a foreach over sources
          // named by the runtime mode, each pass reading the name and
          // extension of its own source, into outputs and arguments whose
          // paths carry the engine version (a constant on the Bazel side).
          final GnSourceTree tree = sourceTree(<String, String>{
            'flutter/example/android_artifacts.py': '',
            'flutter/example/BUILD.gn': r'''
action("embedding_jars") {
  script = "android_artifacts.py"
  base_sources = [
    "$root_out_dir/flutter_embedding_$flutter_runtime_mode.jar",
    "$root_out_dir/flutter_embedding_$flutter_runtime_mode.pom",
  ]
  sources = base_sources
  outputs = []
  args = []
  base_name = "$root_out_dir/zip_archives/download.flutter.io/io/flutter/" +
              "flutter_embedding_$flutter_runtime_mode/1.0.0-$engine_version/" +
              "flutter_embedding_$flutter_runtime_mode-1.0.0-${engine_version}"
  foreach(source, base_sources) {
    extension = get_path_info(source, "extension")
    name = get_path_info(source, "name")
    if (extension == "jar") {
      outputs += [ "${base_name}.jar" ]
      args += [
        "-i",
        rebase_path("$root_out_dir/${name}.jar", root_build_dir),
        rebase_path("${base_name}.jar", root_build_dir),
      ]
    } else {
      outputs += [ "${base_name}.${extension}" ]
      args += [
        "-i",
        rebase_path(source, root_build_dir),
        rebase_path("${base_name}.${extension}", root_build_dir),
      ]
    }
  }
}
''',
          });
          final String output = emitBuildFile(
            evaluateIn(tree, '//flutter/example/BUILD.gn'),
            gnPackage: '//flutter/example',
            tree: tree,
          );
          // The jar pass: the source by its name, the destination an
          // expression around the version, under the mode.
          expect(
            output,
            contains(r'''
    args = [
        "-i",  # extension == "jar"
    ] + select({
        "//engine/src/flutter/common:runtime_mode_debug": [
            "$(built flutter_embedding_debug.jar)",  # extension == "jar"
        ],
        "//conditions:default": [],
    }) + select({'''),
          );
          expect(
            output,
            contains(
              r'"$(built zip_archives/download.flutter.io/io/flutter/flutter_embedding_debug/1.0.0-" + ENGINE_VERSION + "/flutter_embedding_debug-1.0.0-" + ENGINE_VERSION + ".jar)",  # extension == "jar"',
            ),
          );
          // The pom pass: GN's else branch, the extension spelled out.
          expect(
            output,
            contains(r'"$(built flutter_embedding_debug.pom)",  # !(extension == "jar")'),
          );
          expect(
            output,
            contains(
              r'"zip_archives/download.flutter.io/io/flutter/flutter_embedding_debug/1.0.0-" + ENGINE_VERSION + "/flutter_embedding_debug-1.0.0-" + ENGINE_VERSION + ".pom",  # !(extension == "jar")',
            ),
          );
          expect(output, contains('build_inputs = select({'));
          expect(
            output,
            contains(
              '"//engine/src/flutter/common:runtime_mode_debug": ["flutter_embedding_debug.jar"],',
            ),
          );
        },
      );

      test('declares a directory output and archives it at the root', () async {
        // The Android javadoc: an action whose output is a directory (the
        // mapping says which), zipped by a bundle whose entry is the
        // target's one output at "/".
        final GnSourceTree tree = sourceTree(<String, String>{
          'flutter/shell/platform/android/gen_javadoc.py': '',
          'flutter/third_party/android_embedding_dependencies/lib/a.jar': '',
          'flutter/shell/platform/android/BUILD.gn': r'''
import("//flutter/build/zip_bundle.gni")

action("gen_android_javadoc") {
  script = "gen_javadoc.py"
  outputs = [ "$target_gen_dir/javadocs" ]
  args = [
    "--out-dir",
    rebase_path(outputs[0], root_build_dir),
    "--dependencies",
    rebase_path("//flutter/third_party/android_embedding_dependencies/lib", root_build_dir),
  ]
}

zip_bundle("android_javadoc") {
  output = "android-javadoc.zip"
  javadoc_dir = get_target_outputs(":gen_android_javadoc")
  files = [
    {
      source = javadoc_dir[0]
      destination = "/"
    },
  ]
  deps = [ ":gen_android_javadoc" ]
}
''',
        });
        final String output = emitBuildFile(
          evaluateIn(
            tree,
            '//flutter/shell/platform/android/BUILD.gn',
            templates: <String>{'zip_bundle'},
          ),
          gnPackage: '//flutter/shell/platform/android',
          tree: tree,
        );
        expect(output, contains('output_dirs = ["javadocs"]'));
        expect(output, isNot(contains('outputs = ["javadocs"]')));
        // A directory of another repository: its label, for the rule to
        // place.
        expect(output, contains(r'"$(src @android_embedding_dependencies//:lib)"'));
        expect(output, contains('files = {"/": ":gen_android_javadoc"}'));
        expect(output, contains('sources = {"/": "gen/flutter/shell/platform/android/javadocs"}'));
      });

      test('rebases paths to absolute ones and to the current directory', () async {
        // sky_engine's way of naming the Dart SDK's sources: a base rebased
        // to an absolute path, a directory under it, a list under that; and
        // a script named relative to the current directory, which the
        // source-absolute path serves as.
        final GnFileEvaluation evaluation = await evaluate(r'''
lib_root = rebase_path("//third_party/dart/sdk/lib")
copy("async") {
  lib_path = rebase_path("async", "", lib_root)
  sources = rebase_path([ "async.dart", "sub/timer.dart" ], "", lib_path)
  outputs = [ "$root_gen_dir/pkg/lib/async/{{source_file_part}}" ]
}
action("x") {
  script = rebase_path("//flutter/build/tools/x.py", ".", "//")
  sources = [ "//flutter/a.txt" ]
  outputs = [ "$root_gen_dir/x.out" ]
  args = rebase_path(sources, root_build_dir) + [ "--absolute" ] + rebase_path([ "//flutter/b.txt" ], "", "//")
}
''');
        final GnTarget copy = evaluation.targets[0];
        expect(strings(copy, 'sources'), <String>[
          '\u0001//third_party/dart/sdk/lib/async/async.dart\u0001',
          '\u0001//third_party/dart/sdk/lib/async/sub/timer.dart\u0001',
        ]);
        final GnTarget action = evaluation.targets[1];
        expect(strings(action, 'script'), <String>['//flutter/build/tools/x.py']);
        expect(strings(action, 'args'), <String>[
          '\u0001//flutter/a.txt\u0001',
          '--absolute',
          '\u0001//flutter/b.txt\u0001',
        ]);
        await expectLater(
          evaluate('''
x = rebase_path("a", "", "relative/base")
'''),
          throwsGnError(line: 1, message: 'is not a path rebase_path() can rebase from'),
        );
      });
    });
  });

  group('sky_engine', () {
    // The shapes of sky/packages/sky_engine/BUILD.gn: copies of files of
    // other packages and of the Dart tree into the gen directory, a
    // generated_file with contents, an action converted by its script, the
    // web SDK's rewriter template.
    String convertSkyEngine() {
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/third_party/dart/sdk/lib/async/async_sources.gni': '''
async_sdk_sources = [
  "async.dart",
  "timer.dart",
]
''',
        'flutter/lib/ui/dart_ui.gni': '''
dart_ui_files = [
  "//flutter/lib/ui/ui.dart",
]
dart_ui_fix_data_file = "//flutter/lib/ui/fix_dart_ui.yaml"
''',
        'flutter/lib/ui/BUILD.gn': '',
        'flutter/build/dart/rules.gni': '',
        'flutter/web_sdk/web_sdk.gni': '',
        'flutter/sky/packages/sky_engine/BUILD.gn': r'''
import("//flutter/build/dart/rules.gni")
import("//flutter/lib/ui/dart_ui.gni")
import("//flutter/web_sdk/web_sdk.gni")
import("$dart_src/sdk/lib/async/async_sources.gni")

copy("copy_sky_engine_authors") {
  sources = [ "//AUTHORS" ]
  outputs = [ "$root_gen_dir/dart-pkg/sky_engine/{{source_file_part}}" ]
}

dart_sdk_lib_path = rebase_path("$dart_src/sdk/lib")

copy("async") {
  lib_path = rebase_path("async", "", dart_sdk_lib_path)
  sources = rebase_path(async_sdk_sources, "", lib_path)
  outputs = [ "$root_gen_dir/dart-pkg/sky_engine/lib/async/{{source_file_part}}" ]
}

copy("copy_dart_ui") {
  sources = dart_ui_files
  outputs = [ "$root_gen_dir/dart-pkg/sky_engine/lib/ui/{{source_file_part}}" ]
}

copy("copy_dart_ui_fix_data") {
  sources = [ dart_ui_fix_data_file ]
  outputs = [ "$root_gen_dir/dart-pkg/sky_engine/lib/fix_data/fix_dart_ui.yaml" ]
}

copy("renamed") {
  sources = [ "//flutter/lib/ui/fix_dart_ui.yaml" ]
  outputs = [ "$root_gen_dir/dart-pkg/sky_engine/lib/fix_data/renamed.yaml" ]
}

web_ui_ui_web_with_output("copy_dart_ui_web") {
  output_dir = "$root_gen_dir/dart-pkg/sky_engine/lib/ui_web/"
}

group("copy_dart_sdk") {
  deps = [ ":async" ]
}

generated_file("_embedder_yaml") {
  outputs = [ "$root_gen_dir/dart-pkg/sky_engine/lib/_embedder.yaml" ]
  contents = [
    "# Generated.",
    "",
    "embedded_libs:",
    "  \"dart:async\": \"async/async.dart\"",
  ]
}

action("sky_engine") {
  package_name = "sky_engine"
  pkg_directory = rebase_path("$root_gen_dir/dart-pkg", root_build_dir)
  stamp_file = "$root_gen_dir/dart-pkg/${package_name}.stamp"
  sources = [
    "LICENSE",
    "pubspec.yaml",
  ]
  deps = [
    ":_embedder_yaml",
    ":copy_dart_sdk",
    ":copy_dart_ui",
    ":copy_dart_ui_web",
  ]
  if (!is_fuchsia) {
    deps += [ ":copy_sky_engine_authors" ]
  }
  service_isolate_dir = "$dart_src/sdk/lib/_internal/vm/bin/"
  sdk_ext_directory = [ "$root_gen_dir/sky/bindings" ]
  sdk_ext_files = [ "$service_isolate_dir/vmservice_io.dart" ]
  outputs = [ stamp_file ]
  script = rebase_path("//flutter/build/dart/tools/dart_pkg.py", ".", "//")
  inputs = [ script ] + sources
  args = [
    "--package-name",
    package_name,
    "--pkg-directory",
    pkg_directory,
    "--stamp-file",
    rebase_path(stamp_file, root_build_dir),
    "--package-sources",
  ] + rebase_path(sources, root_build_dir) + [ "--sdk-ext-directories" ] +
      rebase_path(sdk_ext_directory, root_build_dir) + [ "--sdk-ext-files" ] +
      rebase_path(sdk_ext_files, root_build_dir)
}
''',
      });
      return emitBuildFile(
        evaluateIn(
          tree,
          '//flutter/sky/packages/sky_engine/BUILD.gn',
          templates: <String>{'web_ui_ui_web_with_output'},
          importPolicy: engineImportPolicy,
        ),
        gnPackage: '//flutter/sky/packages/sky_engine',
        tree: tree,
        layout: mainRepositoryLayout,
        forwardedFlags: DependencyResolver(tree: tree, assumptions: linuxHostAssumptions()),
      );
    }

    test('copies files of the root, of another package and of the Dart tree', () {
      final String output = convertSkyEngine();
      expect(
        output,
        contains(r'''
gn_copy(
    name = "copy_sky_engine_authors",
    srcs = ["//engine/src:AUTHORS"],
    outputs = ["$root_gen_dir/dart-pkg/sky_engine/{{source_file_part}}"],
)
'''),
      );
      expect(
        output,
        contains(r'''
gn_copy(
    name = "async",
    srcs = [
        "@dart//:sdk/lib/async/async.dart",
        "@dart//:sdk/lib/async/timer.dart",
    ],
    outputs = ["$root_gen_dir/dart-pkg/sky_engine/lib/async/{{source_file_part}}"],
)
'''),
      );
      expect(output, contains('srcs = ["//engine/src/flutter/lib/ui:ui.dart"],'));
      // A copy into the gen directory keeping the name travels as it is; one
      // renaming its file is produced under GN's path in the build directory.
      expect(
        output,
        contains(r'''
gn_copy(
    name = "copy_dart_ui_fix_data",
    srcs = ["//engine/src/flutter/lib/ui:fix_dart_ui.yaml"],
    outputs = ["$root_gen_dir/dart-pkg/sky_engine/lib/fix_data/fix_dart_ui.yaml"],
)
'''),
      );
      expect(
        output,
        contains(r'''
gn_copy(
    name = "renamed",
    srcs = ["//engine/src/flutter/lib/ui:fix_dart_ui.yaml"],
    outs = ["gen/dart-pkg/sky_engine/lib/fix_data/renamed.yaml"],
    outputs = ["$root_gen_dir/dart-pkg/sky_engine/lib/fix_data/renamed.yaml"],
)
'''),
      );
    });

    test('generated_file with contents, the rewriter template, the action by its script', () {
      final String output = convertSkyEngine();
      expect(
        output,
        contains(r'''
gn_generated_file(
    name = "_embedder_yaml",
    out = "gen/dart-pkg/sky_engine/lib/_embedder.yaml",
    content = [
        "# Generated.",
        "",
        "embedded_libs:",
        "  \"dart:async\": \"async/async.dart\"",
    ],
    outputs = ["$root_gen_dir/dart-pkg/sky_engine/lib/_embedder.yaml"],
)
'''),
      );
      expect(
        output,
        contains(r'''
web_ui_ui_web_with_output(
    name = "copy_dart_ui_web",
    output_dir = "$root_gen_dir/dart-pkg/sky_engine/lib/ui_web/",
)
'''),
      );
      expect(
        output,
        contains(r'''
dart_pkg(
    name = "sky_engine",
    srcs = [
        "LICENSE",
        "pubspec.yaml",
    ],
    package = "sky_engine",
    sdk_ext = ["@dart//:sdk/lib/_internal/vm/bin/vmservice_io.dart"],
    deps = [
        ":_embedder_yaml",
        ":copy_dart_sdk",
        ":copy_dart_ui",
        ":copy_dart_ui_web",
        ":copy_sky_engine_authors",  # !is_fuchsia
    ],
)
'''),
      );
      expect(output, contains('load("//build_defs/dart:dart_pkg.bzl", "dart_pkg")'));
      expect(output, isNot(contains('gn_action(')));
    });

    test('generated_file over metadata walks the deps at conversion time', () async {
      // The macOS archives' entitlements lists: GN collects `data_keys` from
      // the metadata of the deps and of theirs, depth-first, each target
      // once. The walk is done here -- this file's targets directly, other
      // files' through the resolver -- each line under the conditions on
      // its path, in GN's order; the file's `deps` stay the rule's.
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/x/BUILD.gn': r'''
executable("tool") {
  sources = [ "a.cc" ]
  deps = [ ":lib", "//flutter/y:helper" ]
  metadata = {
    entitlement_file_path = [ "tool" ]
  }
}
source_set("lib") {
  sources = [ "l.cc" ]
  if (is_android) {
    metadata = {
      entitlement_file_path = [ "lib-android" ]
    }
  }
}
generated_file("entitlements") {
  outputs = [ "$target_gen_dir/entitlements.txt" ]
  data_keys = [ "entitlement_file_path" ]
  deps = [ ":tool" ]
}
''',
        'flutter/y/BUILD.gn': r'''
executable("helper") {
  sources = [ "h.cc" ]
  metadata = {
    entitlement_file_path = [ "helper" ]
    without_entitlement_file_path = [ "other" ]
  }
}
''',
      });
      final String output = emitBuildFile(
        evaluateIn(tree, '//flutter/x/BUILD.gn', assumptions: generationAssumptions()),
        gnPackage: '//flutter/x',
        tree: tree,
      );
      expect(
        output,
        contains(
          'gn_generated_file(\n'
          '    name = "entitlements",\n'
          '    out = "entitlements.txt",\n'
          '    content = ["tool"] + select({\n'
          '        "@platforms//os:android": ["lib-android"],\n'
          '        "//conditions:default": [],\n'
          '    }) + ["helper"],\n'
          '    outputs = ["\$root_gen_dir/flutter/x/entitlements.txt"],\n'
          '    deps = [":tool"],\n'
          ')\n',
        ),
      );
      expect(output, isNot(contains('"other"')));
    });
  });

  group('starlark_emitter', () {
    test('converts libraries, configs and tests', () async {
      final String output = await convert('''
config("example_config") {
  defines = [ "EXAMPLE=1" ]
  include_dirs = [ "include" ]
}

# The library.
source_set("example") {
  sources = [
    "example.cc",
    "example.h",
    "detail/impl.cc",
  ]
  public_configs = [
    ":example_config",
    "//flutter:config",
  ]
  deps = [ "//flutter/fml" ]
  public_deps = [ "//flutter/third_party/icu" ]
  if (is_linux) {
    libs = [ "pthread" ]
  }
}

config("dynamic_symbols") {
  if (is_clang && is_linux) {
    ldflags = [ "-rdynamic" ]
  }
}

executable("example_unittests") {
  testonly = true
  sources = [ "example_unittests.cc" ]
  deps = [
    ":example",
    "//flutter/testing",
  ]
  public_configs = [ ":dynamic_symbols" ]
}
''');
      expect(output, '''
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Generated from //flutter/example/BUILD.gn by gn_to_bazel; do not edit.

load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test")
load("//build_defs/cc:copts.bzl", "FLUTTER_COPTS", "FLUTTER_LOCAL_DEFINES")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "example_config",
    defines = ["EXAMPLE=1"],
    includes = ["include"],
)

# The library.
cc_library(
    name = "example",
    srcs = [
        "detail/impl.cc",
        "example.cc",
    ],
    hdrs = ["example.h"],
    copts = FLUTTER_COPTS,
    linkopts = [
        "-lpthread",  # is_linux
    ],
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        ":example_config",
        "//engine/src:include_root",
        "//engine/src/flutter:config",
        "//engine/src/flutter/fml",
        "@icu",
    ],
    alwayslink = True,
)

cc_library(
    name = "dynamic_symbols",
    linkopts = [
        "-rdynamic",  # is_clang && is_linux
    ],
)

cc_test(
    name = "example_unittests",
    size = "small",
    srcs = ["example_unittests.cc"],
    copts = FLUTTER_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        ":dynamic_symbols",
        ":example",
        "//engine/src:include_root",
        "//engine/src/flutter/testing",
    ],
)
''');
    });

    test('static libraries are not alwayslink; tests may have no sources', () async {
      final String output = await convert('''
static_library("archive") {
  sources = [ "a.cc" ]
}

executable("archive_unittests") {
  testonly = true
  sources = []
  deps = [
    ":archive",
    "//flutter/third_party/googletest:gtest",
    "//flutter/third_party/googletest:gmock",
    "//flutter/third_party/googletest:gtest_main",
  ]
}
''');
      expect(output, isNot(contains('alwayslink = True')));
      // An archive with no headers of its own: buildifier would have it
      // alwayslink, which a static_library is not.
      expect(
        output,
        contains('# buildifier: disable=no-hdrs-no-alwayslink\ncc_library(\n    name = "archive",'),
      );
      // gmock and gtest are one Bazel target; the duplicate is dropped.
      expect(
        output,
        contains('''
cc_test(
    name = "archive_unittests",
    size = "small",
    deps = [
        ":archive",
        "@googletest//:gtest",
        "@googletest//:gtest_main",
        "@googletest_tree//:root_includes",
        "@googletest_tree//:third_party_dir_includes",
    ],
)
'''),
      );
      final String kinds = await convert('''
executable("x_rendertests") {
  testonly = true
  sources = [ "a.cc" ]
}
executable("x_benchmarks") {
  testonly = true
  sources = [ "b.cc" ]
}
executable("x_tool") {
  sources = [ "c.cc" ]
}
''');
      expect(kinds, contains('cc_test(\n    name = "x_rendertests",'));
      expect(kinds, contains('cc_binary(\n    name = "x_benchmarks",\n    testonly = True,'));
      expect(kinds, contains('cc_binary(\n    name = "x_tool",\n    srcs'));
    });

    test('renders the runtime mode and slimpeller as select()', () async {
      final String output = await convert('''
source_set("x") {
  sources = [ "a.cc" ]
  if (flutter_runtime_mode == "profile") {
    sources += [ "profile.cc" ]
  }
  if (flutter_runtime_mode != "debug") {
    sources += [ "optimized.cc" ]
  }
  if (!slimpeller) {
    sources += [ "skia.cc" ]
  }
}
''');
      expect(
        output,
        contains('''
    srcs = ["a.cc"] + select({
        "//engine/src/flutter/common:runtime_mode_profile": [
            "profile.cc",  # flutter_runtime_mode == "profile"
        ],
        "//conditions:default": [],
    }) + select({
        "//engine/src/flutter/common:runtime_mode_debug": [],
        "//conditions:default": [
            "optimized.cc",  # flutter_runtime_mode != "debug"
        ],
    }) + select({
        "//engine/src/flutter/common:slimpeller_enabled": [],
        "//conditions:default": [
            "skia.cc",  # !slimpeller
        ],
    }),
'''),
      );
    });

    test('appends the manifest appendix and lists skipped targets', () async {
      final String output = await convert(
        '''
source_set("x") {
  sources = [ "x.cc" ]
}
source_set("later") {
  sources = [ "later.cc" ]
  deps = [ "//flutter/not_yet" ]
}
''',
        skip: <String>{'later'},
        appendix: 'exports_files(["fixtures_location.cc"])\n',
      );
      expect(output, contains('# Not converted: later.\n'));
      expect(output, isNot(contains('not_yet')));
      expect(
        output,
        endsWith('''
    alwayslink = True,
)

# What GN has no words for; maintained in the converter's manifest
# (tools/gn_to_bazel/lib/src/manifest.dart).

exports_files(["fixtures_location.cc"])
'''),
      );
    });

    test("an appendix's load() statements join the file's", () async {
      final String output = await convert(
        '''
source_set("x") {
  sources = [ "x.cc" ]
}
''',
        appendix: '''
load("@rules_cc//cc:defs.bzl", "cc_test")
load("//build_defs/testing:testing.bzl", "flutter_test_fixtures")

flutter_test_fixtures(name = "x_fixtures")

cc_test(
    name = "x_unittests",
    deps = [":x"],
)
''',
      );
      expect(
        output,
        contains('''
load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test")
load("//build_defs/cc:copts.bzl", "CHROMIUM_CODE_COPTS", "FLUTTER_LOCAL_DEFINES")
load("//build_defs/testing:testing.bzl", "flutter_test_fixtures")
'''),
      );
      expect(
        output,
        endsWith('''
# (tools/gn_to_bazel/lib/src/manifest.dart).

flutter_test_fixtures(name = "x_fixtures")

cc_test(
    name = "x_unittests",
    deps = [":x"],
)
'''),
      );
    });

    test('renders undecided conditions as select()', () async {
      final String output = await convert('''
source_set("x") {
  sources = [ "a.cc" ]
  if (is_win) {
    sources += [ "win.cc" ]
  } else {
    sources += [ "posix.cc" ]
  }
  if (is_mac || is_ios) {
    sources += [ "apple.cc" ]
  }
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(
        output,
        contains('''
    srcs = ["a.cc"] + select({
        "@platforms//os:windows": [
            "win.cc",  # is_win
        ],
        "//conditions:default": [],
    }) + select({
        "@platforms//os:windows": [],
        "//conditions:default": [
            "posix.cc",  # !(is_win)
        ],
    }) + select({
        "@platforms//os:macos": [
            "apple.cc",  # is_mac || is_ios
        ],
        "@platforms//os:ios": [
            "apple.cc",  # is_mac || is_ios
        ],
        "//conditions:default": [],
    }),
'''),
      );
    });

    test('rejects conditions without a config_setting', () async {
      // is_component_build (BUILDCONFIG.gn) has none: the engine never sets it.
      await expectLater(
        convert('''
source_set("x") {
  sources = [ "a.cc" ]
  if (is_component_build) {
    sources += [ "component.cc" ]
  }
}
''', assumptions: Assumptions(const <String, GnValue>{})),
        throwsA(
          isA<GnError>().having(
            (GnError e) => e.message,
            'message',
            contains('no config_setting for `is_component_build`'),
          ),
        ),
      );
      // shell/config.gni's arguments have theirs (//flutter/shell's appendix).
      final String output = await convert('''
source_set("x") {
  sources = [ "a.cc" ]
  if (shell_enable_metal) {
    sources += [ "metal.cc" ]
  }
  if (test_enable_vulkan && !is_wasm) {
    sources += [ "vulkan_test.cc" ]
  }
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(output, contains('"//engine/src/flutter/shell:enable_metal": ['));
      // A denied variable in a disjunction, and an OS name compared,
      // asserted and denied (fml's backtrace and wasm branches).
      final String fml = await convert('''
source_set("x") {
  sources = [ "a.cc" ]
  if (enable_backtrace && !is_wasm) {
    sources += [ "backtrace.cc" ]
  } else {
    sources += [ "backtrace_stub.cc" ]
  }
  if (target_os == "wasm") {
    sources += [ "wasm.cc" ]
  }
  if (target_os != "wasm" && is_linux) {
    sources += [ "linux_not_wasm.cc" ]
  }
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(
        fml,
        contains(
          '        "//engine/src/flutter/common:backtrace_disabled": [\n'
          '            "backtrace_stub.cc",  # !(enable_backtrace && !is_wasm)\n'
          '        ],\n'
          '        "@platforms//os:emscripten": [\n'
          '            "backtrace_stub.cc",  # !(enable_backtrace && !is_wasm)\n'
          '        ],\n',
        ),
      );
      expect(
        fml,
        contains(
          '        "@platforms//os:emscripten": [\n            "wasm.cc",  # target_os == "wasm"\n',
        ),
      );
      expect(
        fml,
        contains(
          '    match_all = [\n'
          '        "//engine/src/flutter/build/bazel:not_wasm",\n'
          '        "@platforms//os:linux",\n'
          '    ],\n',
        ),
      );
      expect(
        output,
        contains(
          '    match_all = [\n'
          '        "//engine/src/flutter/shell:test_enable_vulkan",\n'
          '        "//engine/src/flutter/build/bazel:not_wasm",\n'
          '    ],\n',
        ),
      );
    });

    test('spells a platform name out per pair the assumptions allow', () async {
      // font_subset's archive path with the OS open: one case per
      // full_target_platform_name the OS predicates and target_cpu leave
      // possible -- the Linux pairs and wasm under `is_linux || is_wasm`,
      // and under target_cpu x64 only linux-x64.
      const gn = r'''
import("//flutter/build/zip_bundle.gni")
zip_bundle("font_subset") {
  output = "${full_target_platform_name}/font-subset.zip"
  files = [
    {
      source = "$root_out_dir/font-subset"
      destination = "font-subset"
    },
  ]
  deps = [ ":font_subset_bin" ]
}
executable("font_subset_bin") {
  output_name = "font-subset"
  sources = [ "main.cc" ]
}
''';
      final open = Assumptions(const <String, GnValue>{
        'is_android': GnBoolValue(false),
        'is_fuchsia': GnBoolValue(false),
        'is_ios': GnBoolValue(false),
        'is_mac': GnBoolValue(false),
        'is_qnx': GnBoolValue(false),
        'is_win': GnBoolValue(false),
      });
      final String output = await convert(gn, assumptions: open, templates: <String>{'zip_bundle'});
      expect(
        output,
        contains(
          '    output = select({\n'
          '        "//engine/src/flutter/common:platform_linux_arm64": "linux-arm64/font-subset.zip",\n'
          '        "//engine/src/flutter/common:platform_linux_x64": "linux-x64/font-subset.zip",\n'
          '        "//engine/src/flutter/common:platform_wasm_wasm": "wasm-wasm/font-subset.zip",\n'
          '        "//conditions:default": None,\n'
          '    }),\n',
        ),
      );
      final String x64 = await convert(
        gn,
        assumptions: open.withValues(const <String, GnValue>{'target_cpu': GnStringValue('x64')}),
        templates: <String>{'zip_bundle'},
      );
      expect(
        x64,
        contains(
          '    output = select({\n'
          '        "//engine/src/flutter/common:platform_linux_x64": "linux-x64/font-subset.zip",\n'
          '        "//conditions:default": None,\n'
          '    }),\n',
        ),
      );
      // Under the host assumptions the name is a string.
      expect(
        await convert(gn, templates: <String>{'zip_bundle'}),
        contains('    output = "linux-x64/font-subset.zip",\n'),
      );
    });

    test('a disjunction inside a conjunction is a match_any group inside the match_all', () async {
      // impeller/tools/component.gni: `impeller_supports_rendering &&
      // enable_unittests`, the former the disjunction of the three backends.
      final String output = await convert('''
source_set("x") {
  sources = [ "a.cc" ]
  if ((impeller_enable_metal || impeller_enable_opengles || impeller_enable_vulkan) && enable_unittests) {
    sources += [ "rendering_tests.cc" ]
  }
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(
        output,
        contains(
          'selects.config_setting_group(\n'
          '    name = "when_impeller_enable_metal_or_impeller_enable_opengles_or_impeller_enable_vulkan_and_enable_unittests",\n'
          '    match_all = [\n'
          '        ":when_impeller_enable_metal_or_impeller_enable_opengles_or_impeller_enable_vulkan",\n'
          '        "//engine/src/flutter/testing:unittests_enabled",\n'
          '    ],\n'
          ')\n',
        ),
      );
      expect(
        output,
        contains(
          'selects.config_setting_group(\n'
          '    name = "when_impeller_enable_metal_or_impeller_enable_opengles_or_impeller_enable_vulkan",\n'
          '    match_any = [\n'
          '        "//engine/src/flutter/impeller/tools:metal",\n'
          '        "//engine/src/flutter/impeller/tools:opengles",\n'
          '        "//engine/src/flutter/impeller/tools:vulkan",\n'
          '    ],\n'
          ')\n',
        ),
      );
    });

    test('a predicate read as a value is the predicate', () async {
      // gpu.gni's invocations: the test_enable_* arguments assigned to the
      // invoker's members, tested in the template.
      final String output = await convert('''
template("configuration") {
  group(target_name) {
    public_deps = []
    if (invoker.enable_software) {
      public_deps += [ "//flutter/shell/gpu:gpu_surface_software" ]
    }
  }
}
configuration("gpu") {
  enable_software = test_enable_software
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(
        output,
        contains(
          '    deps = select({\n'
          '        "//engine/src/flutter/shell:test_enable_software": [\n'
          '            "//engine/src/flutter/shell/gpu:gpu_surface_software",  # invoker.enable_software\n'
          '        ],\n'
          '        "//conditions:default": [],\n'
          '    }),\n',
        ),
      );
    });

    test("a conditional target's conjunction group takes no compatibility", () async {
      // A target under a condition is incompatible elsewhere; the
      // config_setting_group its select() adds to the file is a setting, not
      // a target, and selects.config_setting_group has no such attribute.
      final String output = await convert('''
if (is_linux) {
  source_set("x") {
    sources = [ "a.cc" ]
    if (shell_enable_vulkan && !is_wasm) {
      sources += [ "vulkan.cc" ]
    }
  }
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(
        output,
        contains('    target_compatible_with = select({\n        "@platforms//os:linux": [],\n'),
      );
      expect(
        output,
        contains(
          'selects.config_setting_group(\n'
          '    name = "when_shell_enable_vulkan_and_not_is_wasm",\n'
          '    match_all = [\n'
          '        "//engine/src/flutter/shell:enable_vulkan",\n'
          '        "//engine/src/flutter/build/bazel:not_wasm",\n'
          '    ],\n'
          ')\n',
        ),
      );
    });

    test("items under a condition the target's own implies are unconditional", () async {
      // lib/ui/fixtures/shaders: a file-level list defined in the same
      // `if (enable_unittests)` block as the target that reads it. The
      // target is incompatible elsewhere; within it the items always hold,
      // and a macro that inspects the list gets a list, not a select().
      final String output = await convert('''
if (enable_unittests) {
  test_sources = [ "a_test.cc", "b_test.cc" ]
  source_set("x") {
    sources = test_sources
    if (is_wasm) {
      sources += [ "wasm.cc" ]
    }
  }
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(
        output,
        contains(
          '    srcs = [\n'
          '        "a_test.cc",  # enable_unittests\n'
          '        "b_test.cc",  # enable_unittests\n'
          '    ] + select({\n'
          '        "@platforms//os:emscripten": [\n'
          '            "wasm.cc",  # is_wasm\n'
          '        ],\n'
          '        "//conditions:default": [],\n'
          '    }),\n',
        ),
      );
      expect(output, contains('"//engine/src/flutter/testing:unittests_enabled": [],'));
    });

    test('list constants in a select() branch stand as themselves', () async {
      // testing's suites: cflags_objc = flutter_cflags_objc under
      // test_enable_metal -- a list, joined to the branch with `+`. The
      // Objective-C flags go to the target's Objective-C library (its .mm
      // sources), once for GN's two lists, which are one, and split by the
      // platform: config.gni's macOS list on a Mac (test_enable_metal says
      // nothing of the OS), the generic one elsewhere; the C++ library keeps
      // the C++ flags and links the Objective-C library in.
      final String output = await convert('''
source_set("x") {
  sources = [ "a.cc", "b.mm" ]
  if (test_enable_metal) {
    cflags_objc = flutter_cflags_objc
    cflags_objcc = flutter_cflags_objcc
    cflags = [ "-fobjc-weak" ]
  }
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(
        output,
        contains(
          'flutter_objc_library(\n'
          '    name = "x_objc",\n'
          '    srcs = ["b.mm"],\n'
          '    copts = CHROMIUM_CODE_COPTS + select({\n'
          '        "//engine/src/flutter/shell:test_enable_metal": [\n'
          '            "-fobjc-weak",  # test_enable_metal\n'
          '        ],\n'
          '        "//conditions:default": [],\n'
          '    }) + select({\n'
          '        ":when_test_enable_metal_and_is_mac": MACOS_CFLAGS_OBJC,\n'
          '        "//conditions:default": [],\n'
          '    }) + select({\n'
          '        ":when_test_enable_metal_and_not_is_mac": FLUTTER_CFLAGS_OBJC,\n'
          '        "//conditions:default": [],\n'
          '    }),\n',
        ),
      );
      expect(output, isNot(contains('FLUTTER_CFLAGS_OBJCC')));
      expect(
        output,
        contains(
          'cc_library(\n'
          '    name = "x",\n'
          '    srcs = ["a.cc"],\n'
          '    copts = CHROMIUM_CODE_COPTS + select({\n'
          '        "//engine/src/flutter/shell:test_enable_metal": [\n'
          '            "-fobjc-weak",  # test_enable_metal\n'
          '        ],\n'
          '        "//conditions:default": [],\n'
          '    }),\n',
        ),
      );
      expect(output, contains('        ":x_objc",\n'));
    });

    test('the Objective-C flags of a target without Objective-C sources go nowhere', () async {
      // GN applies cflags_objc to no compile of such a target; neither the
      // flags nor their constant's load reach the file.
      final String output = await convert('''
source_set("x") {
  sources = [ "a.cc" ]
  cflags_objc = flutter_cflags_objc
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(output, isNot(contains('FLUTTER_CFLAGS_OBJC')));
      expect(output, isNot(contains('flutter_objc_library')));
    });

    test('a source_set of Swift sources is a flutter_swift_library', () async {
      // darwin/common's InternalFlutterSwiftCommon: Swift sources behind a
      // bridging header, `public` headers, a local config with the Swift
      // flags (-enable-testing under the unit tests) and darwin_sdk.gni's
      // Swift library directories as lib_dirs -- which the rule carries, so
      // the listing goes; the config's cc_library form drops both too. A
      // C++ target listing the config takes neither.
      final String output = await convert('''
config("config") {
  lib_dirs = mac_swift_lib_paths
  swiftflags = []
  if (enable_unittests) {
    swiftflags += [ "-enable-testing" ]
  }
}
source_set("bindings") {
  sources = [ "bindings.h", "bindings.mm" ]
  configs += [ ":config" ]
}
source_set("Module") {
  configs += [ ":config" ]
  bridge_header = "Module-Bridging-Header.h"
  sources = [ "a.swift", "b.swift" ]
  public = [ "public.h" ]
  deps = [ ":bindings" ]
}
''', assumptions: generationAssumptions());
      expect(
        output,
        contains(
          'flutter_swift_library(\n'
          '    name = "Module",\n'
          '    srcs = [\n'
          '        "a.swift",\n'
          '        "b.swift",\n'
          '    ],\n'
          '    hdrs = ["public.h"],\n'
          '    bridge_header = "Module-Bridging-Header.h",\n'
          '    swiftflags = select({\n'
          '        "//engine/src/flutter/testing:unittests_enabled": [\n'
          '            "-enable-testing",  # enable_unittests\n'
          '        ],\n'
          '        "//conditions:default": [],\n'
          '    }),\n'
          '    deps = [\n'
          '        ":bindings",\n'
          '        "//engine/src:include_root",\n'
          '    ],\n'
          ')\n',
        ),
      );
      expect(
        output,
        contains('load("//build_defs/cc:swift_library.bzl", "flutter_swift_library")'),
      );
      expect(output, contains('cc_library(\n    name = "config",\n)\n'));
      expect(output, isNot(contains('mac_swift_lib_paths')));
      expect(output, isNot(contains('MACOS_SWIFT_LIBRARY_DIRS')));
      // The Swift target's alone: the config's cc_library form and the
      // Objective-C target listing the config carry none.
      expect('swiftflags'.allMatches(output).length, 1);
      await expectLater(
        convert('''
config("config") {
  lib_dirs = [ "/usr/local/lib" ]
}
'''),
        throwsGnError(line: 2, message: 'lib_dirs holds'),
      );
    });

    test('Objective-C sources under is_mac make a macOS library', () async {
      // fml: .mm under is_mac || is_ios (is_ios a constant), with
      // config.gni's macOS flags; the library is compatible on macOS alone
      // and the C++ library links it there.
      final String output = await convert('''
source_set("x") {
  sources = [ "a.cc" ]
  if (is_mac) {
    sources += [ "b.mm" ]
    cflags_objcc = flutter_cflags_objcc
  }
}
''', assumptions: generationAssumptions());
      expect(
        output,
        contains(
          'flutter_objc_library(\n'
          '    name = "x_objc",\n'
          '    srcs = select({\n'
          '        "@platforms//os:macos": [\n'
          '            "b.mm",  # is_mac\n'
          '        ],\n'
          '        "//conditions:default": [],\n'
          '    }),\n'
          '    copts = CHROMIUM_CODE_COPTS + select({\n'
          '        "@platforms//os:macos": MACOS_CFLAGS_OBJC,\n'
          '        "//conditions:default": [],\n'
          '    }),\n',
        ),
      );
      expect(
        output,
        contains(
          '    target_compatible_with = select({\n'
          '        "@platforms//os:macos": [],\n'
          '        "//conditions:default": ["@platforms//:incompatible"],\n'
          '    }),\n',
        ),
      );
      expect(
        output,
        contains(
          '    deps = ["//engine/src:include_root"] + select({\n'
          '        "@platforms//os:macos": [":x_objc"],\n'
          '        "//conditions:default": [],\n'
          '    }),\n',
        ),
      );
    });

    test("a target's own Objective-C flags reach its library, the macOS list on a Mac", () {
      // shell/gpu's gpu_surface_metal: under shell_enable_metal (macOS or
      // iOS) with config.gni's flags unconditionally -- a target's own
      // flags, which the emitter keeps apart from the conditional ones
      // (ownFlags) and the companion lost (found on the Mac, 10-27: no
      // -fobjc-arc). The constant is the macOS list under is_mac and the
      // other elsewhere, since the target's condition names no platform.
      final GnSourceTree tree = sourceTree(<String, String>{
        'known/config.gni': '',
        'flutter/x/BUILD.gn': '''
import("//known/config.gni")
if (shell_enable_metal) {
  source_set("gpu_surface_metal") {
    cflags_objc = flutter_cflags_objc
    cflags_objcc = flutter_cflags_objcc
    sources = [ "a.cc", "b.mm" ]
  }
}
''',
      });
      final String output = emitBuildFile(
        evaluateIn(tree, '//flutter/x/BUILD.gn', assumptions: generationAssumptions()),
        gnPackage: '//flutter/x',
      );
      expect(
        output,
        contains(
          'flutter_objc_library(\n'
          '    name = "gpu_surface_metal_objc",\n'
          '    srcs = ["b.mm"],\n'
          '    copts = CHROMIUM_CODE_COPTS + select({\n'
          '        "@platforms//os:macos": MACOS_CFLAGS_OBJC,\n'
          '        "//conditions:default": [],\n'
          '    }) + select({\n'
          '        "@platforms//os:macos": [],\n'
          '        "//conditions:default": FLUTTER_CFLAGS_OBJC,\n'
          '    }),\n',
        ),
      );
    });

    test("a test's Objective-C sources make a testonly, alwayslink library", () async {
      // fml_unittests: its .mm hold gtest registrations nothing refers to
      // (GN links the executable's objects whole) and depend on testonly
      // fixtures, which Bazel's test rule may and a plain library may not
      // (found on the Mac, 10-27).
      final String output = await convert('''
import("//flutter/testing/testing.gni")
executable("x_unittests") {
  testonly = true
  sources = [ "a_unittests.cc" ]
  if (is_mac) {
    sources += [ "b_unittests.mm" ]
  }
  deps = [ "//flutter/testing" ]
}
''', assumptions: generationAssumptions());
      expect(
        output,
        contains(
          'flutter_objc_library(\n'
          '    name = "x_unittests_objc",\n'
          '    testonly = True,\n'
          '    srcs = select({\n'
          '        "@platforms//os:macos": [\n'
          '            "b_unittests.mm",  # is_mac\n'
          '        ],\n'
          '        "//conditions:default": [],\n'
          '    }),\n',
        ),
      );
      expect(
        output,
        contains('    alwayslink = True,\n)\n\ncc_test(\n    name = "x_unittests",\n'),
      );
    });

    test('an argument the macro applies under a predicate loses that condition', () async {
      // impeller/fixtures: gles_exclusions under impeller_enable_opengles,
      // which impeller_shaders asks `in` of, and applies to the GLES backend
      // alone -- a list, not a select().
      final String output = await convert(
        '''
import("//flutter/impeller/tools/impeller.gni")
impeller_shaders("fixtures") {
  name = "fixtures"
  shaders = [ "a.frag", "b.comp" ]
  if (impeller_enable_opengles) {
    gles_exclusions = [ "b.comp" ]
  }
}
''',
        gnPackage: '//flutter/impeller/fixtures',
        assumptions: Assumptions(const <String, GnValue>{}),
        templates: <String>{'impeller_shaders'},
      );
      expect(
        output,
        contains(
          '    gles_exclusions = [\n        "b.comp",  # impeller_enable_opengles\n    ],\n',
        ),
      );
      expect(output, isNot(contains('gles_exclusions = select')));
    });

    test('a dependency listed outright is not listed again under a condition', () async {
      // impeller_unittests: geometry_unittests in deps and again under
      // impeller_supports_rendering; GN's deps are a set, Bazel rejects the
      // duplicate the select() would make.
      final String output = await convert('''
source_set("x") {
  sources = [ "a.cc" ]
  deps = [ "//flutter/fml" ]
  if (is_wasm) {
    deps += [ "//flutter/fml", "//flutter/testing" ]
  }
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(
        output,
        contains(
          '    deps = [\n'
          '        "//engine/src:include_root",\n'
          '        "//engine/src/flutter/fml",\n'
          '    ] + select({\n'
          '        "@platforms//os:emscripten": [\n'
          '            "//engine/src/flutter/testing",  # is_wasm\n'
          '        ],\n'
          '        "//conditions:default": [],\n'
          '    }),\n',
        ),
      );
    });

    test("an ordered attribute keeps GN's interleaving of conditional appends", () async {
      // impeller_public_config's defines: IMPELLER_DEBUG under the runtime
      // mode first, the rest after -- the compiler reads defines, copts and
      // include directories in order, so the select() sits where GN's append
      // was. deps, which buildifier sorts, keep the two-part layout.
      final String output = await convert('''
config("x") {
  defines = []
  if (flutter_runtime_mode == "debug") {
    defines += [ "A_DEBUG=1" ]
  }
  defines += [ "B=1" ]
  if (is_wasm) {
    defines += [ "C_WASM=1" ]
  }
  defines += [ "D=1" ]
}
''', assumptions: Assumptions(const <String, GnValue>{}));
      expect(
        output,
        contains(
          '    defines = select({\n'
          '        "//engine/src/flutter/common:runtime_mode_debug": [\n'
          '            "A_DEBUG=1",  # flutter_runtime_mode == "debug"\n'
          '        ],\n'
          '        "//conditions:default": [],\n'
          '    }) + ["B=1"] + select({\n'
          '        "@platforms//os:emscripten": [\n'
          '            "C_WASM=1",  # is_wasm\n'
          '        ],\n'
          '        "//conditions:default": [],\n'
          '    }) + ["D=1"],\n',
        ),
      );
    });

    test('renders a scalar with several cases as select()', () async {
      // metal_version as impeller/renderer writes it (an else-if chain over
      // the OS predicates, undefined elsewhere); vulkan_language_version
      // written once under a condition; testonly with a default.
      final String output = await convert(
        '''
impeller_shaders("entity_shaders") {
  name = "entity"
  testonly = true
  if (is_win) {
    testonly = false
  }
  if (is_ios) {
    metal_version = "2.4"
  } else if (is_mac) {
    metal_version = "2.1"
  }
  if (slimpeller) {
    vulkan_language_version = 130
  }
  shaders = [ "shaders/solid_fill.vert" ]
}
source_set("x") {
  sources = [ "x.cc" ]
  if (is_win) {
    sources += [ "win.cc" ]
  } else if (is_mac) {
    sources += [ "mac.cc" ]
  } else {
    sources += [ "posix.cc" ]
  }
}
''',
        templates: <String>{'impeller_shaders'},
        assumptions: Assumptions(const <String, GnValue>{}),
      );
      expect(
        output,
        contains('''
impeller_shaders(
    name = "entity_shaders",
    testonly = select({
        "@platforms//os:windows": False,
        "//conditions:default": True,
    }),
    library_name = "entity",
    metal_version = select({
        "@platforms//os:ios": "2.4",
        "@platforms//os:macos": "2.1",
        "//conditions:default": None,
    }),
    shaders = ["shaders/solid_fill.vert"],
    vulkan_language_version = select({
        "//engine/src/flutter/common:slimpeller_enabled": 130,
        "//conditions:default": None,
    }),
)
'''),
      );
      // The else-if chain's branches key on their own OS; the final else
      // (neither) empties both keys and keeps the branch as the default.
      expect(
        output,
        contains('''
    srcs = ["x.cc"] + select({
        "@platforms//os:windows": [
            "win.cc",  # is_win
        ],
        "//conditions:default": [],
    }) + select({
        "@platforms//os:macos": [
            "mac.cc",  # !(is_win) && is_mac
        ],
        "//conditions:default": [],
    }) + select({
        "@platforms//os:windows": [],
        "@platforms//os:macos": [],
        "//conditions:default": [
            "posix.cc",  # !(is_win) && !(is_mac)
        ],
    }),
'''),
      );
    });

    test('rejects scalar cases a select() cannot hold', () async {
      // A value under a conjunction keys a config_setting_group when every
      // term has a setting (`!is_win && slimpeller`). Two shapes have no
      // select(): a negated case whose complement overlaps another case
      // (`!is_win` then `!slimpeller`: unset where slimpeller holds and
      // is_win does, which no key can say beside the group's value), and a
      // denied flag inside a conjunction (no complement setting). A name
      // that varies no target can have.
      final String grouped = await convert(
        '''
impeller_shaders("entity_shaders") {
  name = "entity"
  if (!is_win && slimpeller) {
    metal_version = "2.1"
  }
  shaders = [ "shaders/solid_fill.vert" ]
}
''',
        templates: <String>{'impeller_shaders'},
        assumptions: Assumptions(const <String, GnValue>{}),
      );
      expect(
        grouped,
        contains('''
    metal_version = select({
        ":when_not_is_win_and_slimpeller": "2.1",
        "//conditions:default": None,
    }),
'''),
      );
      expect(
        grouped,
        contains('''
selects.config_setting_group(
    name = "when_not_is_win_and_slimpeller",
    match_all = [
        "//engine/src/flutter/build/bazel:not_win",
        "//engine/src/flutter/common:slimpeller_enabled",
    ],
)
'''),
      );
      await expectLater(
        convert(
          '''
impeller_shaders("entity_shaders") {
  name = "entity"
  if (!is_win) {
    metal_version = "2.1"
  }
  if (!slimpeller) {
    metal_version = "2.4"
  }
  shaders = [ "shaders/solid_fill.vert" ]
}
''',
          templates: <String>{'impeller_shaders'},
          assumptions: Assumptions(const <String, GnValue>{}),
        ),
        throwsGnError(line: 7, message: 'metal_version is unset where `slimpeller` holds without'),
      );
      await expectLater(
        convert(
          '''
impeller_shaders("entity_shaders") {
  name = "entity"
  if (!slimpeller) {
    metal_version = "2.1"
  }
  if (!is_win) {
    metal_version = "2.4"
  }
  shaders = [ "shaders/solid_fill.vert" ]
}
''',
          templates: <String>{'impeller_shaders'},
          assumptions: Assumptions(const <String, GnValue>{}),
        ),
        throwsGnError(line: 4, message: 'no config_setting holds exactly when `!slimpeller` does'),
      );
      await expectLater(
        convert('''
shared_library("tessellator_shared") {
  if (is_win) {
    output_name = "libtessellator"
  } else {
    output_name = "tessellator"
  }
  sources = [ "a.cc" ]
}
''', assumptions: Assumptions(const <String, GnValue>{})),
        throwsGnError(line: 3, message: 'output_name must be a single unconditional string'),
      );
    });

    test("an executable's output_name names the rule, with an alias under the target's", () async {
      // flutter_tester's template forwards output_name = target_name: the
      // file Bazel produces anyway.
      final String output = await convert('''
executable("tester") {
  output_name = "tester"
  sources = [ "a.cc" ]
}
''');
      expect(output, contains('cc_binary(\n    name = "tester",\n'));
      expect(output, isNot(contains('output_name')));
      expect(output, isNot(contains('alias(')));
      // font-subset: the target `_font-subset` produces `font-subset`, and a
      // cc_binary's file is its name.
      final String renamed = await convert('''
executable("_font-subset") {
  output_name = "font-subset"
  sources = [ "a.cc" ]
}
''');
      expect(renamed, contains('cc_binary(\n    name = "font-subset",\n'));
      expect(
        renamed,
        contains('alias(\n    name = "_font-subset",\n    actual = ":font-subset",\n)'),
      );
      expect(renamed, isNot(contains('output_name')));
      // A test the same way: the file name is what a runner pushes to a
      // device (the Android suites), GN's name the alias.
      final String test = await convert('''
executable("a_unittests") {
  testonly = true
  output_name = "a_tests"
  sources = [ "a.cc" ]
}
''');
      expect(test, contains('cc_test(\n    name = "a_tests",'));
      expect(test, contains('alias(\n    name = "a_unittests",\n    actual = ":a_tests",'));
    });

    test('keeps comments and shortens labels into the package', () async {
      final String output = await convert('''
source_set("x") {
  sources = [ "x.cc" ]

  # Why these.
  deps = [
    "//flutter/example:y",
    # The library itself.
    "//flutter/example",
    "//flutter/fml",
  ]
  if (is_linux) {
    # Linux needs this one.
    deps += [ "//flutter/example:linux" ]
  }
}
''');
      expect(
        output,
        contains('''
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    # Why these.
    deps = [
        # The library itself.
        ":example",
        # Linux needs this one.
        ":linux",  # is_linux
        ":y",
        "//engine/src:include_root",
        "//engine/src/flutter/fml",
    ],
'''),
      );
    });

    test('drops the warning set for no_chromium_code', () async {
      final String output = await convert('''
source_set("x") {
  sources = [ "x.cc" ]
  configs -= [ "//build/config/compiler:chromium_code" ]
  configs += [ "//build/config/compiler:no_chromium_code" ]
}
''');
      expect(output, contains('copts = FLUTTER_THIRD_PARTY_COPTS,'));
      expect(output, isNot(contains('FLUTTER_LOCAL_DEFINES')));
    });

    test('keeps language-specific flags apart, drops -std= and repeated files', () async {
      final String output = await convert('''
source_set("x") {
  sources = [
    "a.c",
    "b.cc",
    "shared.h",
    "shared.h",
  ]
  cflags = [
    "-std=c11",
    "-Wno-something",
  ]
  cflags_c = [ "-Wno-c-only" ]
  cflags_cc = [
    "-std=c++17",
    "-fno-rtti",
  ]
}
''');
      expect(
        output,
        contains('''
cc_library(
    name = "x",
    srcs = [
        "a.c",
        "b.cc",
    ],
    hdrs = ["shared.h"],
    conlyopts = ["-Wno-c-only"],
    copts = ["-Wno-something"] + CHROMIUM_CODE_COPTS,
    cxxopts = ["-fno-rtti"],
'''),
      );
      expect(output, isNot(contains('-std=')));
    });

    test('an explicit public list becomes hdrs; private configs are inlined', () async {
      final String output = await convert('''
config("private_config") {
  defines = [ "IMPLEMENTATION=1" ]
  include_dirs = [ "src" ]
  ldflags = [ "-Wl,--private" ]
}

config("public_config") {
  defines = [ "PUBLIC=1" ]
}

static_library("lib") {
  public = [ "include/lib.h" ]
  sources = [
    "src/lib.cc",
    "src/lib_priv.h",
  ]
  configs += [ ":private_config" ]
  public_configs = [ ":public_config" ]
  if (is_debug) {
    defines = [ "DEBUG_ONLY" ]
  }
}

static_library("headers_only_private_config") {
  sources = [ "src/other.h" ]
  configs += [ ":private_config" ]
}
''');
      expect(
        output,
        contains('''
cc_library(
    name = "lib",
    srcs = [
        "src/lib.cc",
        "src/lib_priv.h",
    ],
    hdrs = ["include/lib.h"],
    copts = CHROMIUM_CODE_COPTS,
    includes = ["src"],
    linkopts = ["-Wl,--private"],
    local_defines = FLUTTER_LOCAL_DEFINES + ["IMPLEMENTATION=1"] + select({
        "//engine/src/flutter/build/bazel:unoptimized": [
            "DEBUG_ONLY",  # is_debug
        ],
        "//conditions:default": [],
    }),
    deps = [
        ":public_config",
        "//engine/src:include_root",
    ],
)
'''),
      );
      // A headers-only target has nothing to compile the private defines
      // into; what remains of the config still applies.
      expect(
        output,
        contains('''
cc_library(
    name = "headers_only_private_config",
    hdrs = ["src/other.h"],
    includes = ["src"],
    linkopts = ["-Wl,--private"],
)
'''),
      );
      // The private config is still a target of its own, for anyone who
      // lists it publicly.
      expect(
        output,
        contains('cc_library(\n    name = "private_config",\n    defines = ["IMPLEMENTATION=1"],'),
      );
    });

    test('lays files out by package in an external repository', () async {
      // The Skia layout: the engine's //flutter/skia/BUILD.gn generates the
      // root of @skia, whose files are Skia's synced tree.
      const layout = OutputLayout.repository(
        '@skia',
        repositoryGnRoot: '//flutter/third_party/skia',
        packages: <String>{'', 'modules/skcms'},
      );
      final String output = await convert(
        r'''
_skia_root = "//flutter/third_party/skia"

source_set("example") {
  include_dirs = [ _skia_root ]
  sources = [
    "$_skia_root/src/a.cc",
    "//flutter/third_party/skia/src/b.cc",
    "//flutter/third_party/skia/modules/skcms/c.cc",
  ]
  public = [ "$_skia_root/include/a.h" ]
  deps = [
    "modules/skcms",
    "//flutter/third_party/skia/modules/skcms:other",
    "//flutter/fml",
    "//flutter/third_party/icu",
  ]
  if (is_debug) {
    defines = [ "DEBUG_ONLY" ]
  }
}
''',
        gnPackage: '//flutter/skia',
        layout: layout,
      );
      expect(output, contains('# Generated from //flutter/skia/BUILD.gn by gn_to_bazel'));
      // The engine's own files and settings are reached through the main
      // repository's name.
      expect(
        output,
        contains(
          'load("@flutter//build_defs/cc:copts.bzl", '
          '"CHROMIUM_CODE_COPTS", "FLUTTER_LOCAL_DEFINES")',
        ),
      );
      expect(
        output,
        contains('''
cc_library(
    name = "example",
    srcs = [
        "src/a.cc",
        "src/b.cc",
        "//modules/skcms:c.cc",
    ],
    hdrs = ["include/a.h"],
    copts = CHROMIUM_CODE_COPTS,
    includes = ["."],
    local_defines = FLUTTER_LOCAL_DEFINES + select({
        "@flutter//engine/src/flutter/build/bazel:unoptimized": [
            "DEBUG_ONLY",  # is_debug
        ],
        "//conditions:default": [],
    }),
    deps = [
        "//modules/skcms",
        "//modules/skcms:other",
        "@flutter//engine/src/flutter/fml",
        "@icu",
    ],
'''),
      );
      await expectLater(
        convert(
          '''
source_set("x") {
  sources = [ "//flutter/elsewhere/a.cc" ]
}
''',
          gnPackage: '//flutter/skia',
          layout: layout,
        ),
        throwsGnError(line: 2, message: 'is outside the output repository @skia'),
      );
    });

    test('implicit deps reach every target that compiles', () async {
      const layout = OutputLayout.repository(
        '@skia',
        repositoryGnRoot: '//flutter/third_party/skia',
        packages: <String>{'', 'modules/skcms'},
      );
      final GnFileEvaluation evaluation = await evaluate('''
config("headers_only") {
  defines = [ "X" ]
}
source_set("compiled") {
  sources = [ "//flutter/third_party/skia/modules/skcms/a.cc" ]
}
''');
      final String output = emitBuildFile(
        evaluation,
        gnPackage: '//flutter/skia/modules/skcms',
        layout: layout,
        implicitDeps: const <String>['@skia//:skia_headers'],
      );
      expect(
        output,
        contains('''
cc_library(
    name = "compiled",
    srcs = ["a.cc"],
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = ["//:skia_headers"],
    alwayslink = True,
)
'''),
      );
      expect(
        output,
        contains('cc_library(\n    name = "headers_only",\n    defines = ["X"],\n)\n'),
      );
    });

    test('a .gni list read by reference in defines is its copts.bzl constant', () async {
      final String output = await convert('''
config("flutter_config") {
  defines = feature_defines_list
}
''');
      expect(output, contains('load("//build_defs/cc:copts.bzl", "FLUTTER_FEATURE_DEFINES")\n'));
      expect(
        output,
        contains(
          'cc_library(\n    name = "flutter_config",\n    defines = FLUTTER_FEATURE_DEFINES,\n)\n',
        ),
      );
    });

    test('a string around an external reference is a concatenation; defines are escaped '
        "for Bazel's tokenizer", () async {
      final String output = await convert(r'''
source_set("version") {
  sources = [ "version.cc" ]
  defines = [
    "FLUTTER_ENGINE_VERSION=\"$engine_version\"",
    "SKIA_VERSION=\"$skia_version\"",
  ]
  public_configs = [ "//flutter:config" ]
}

config("quoted") {
  defines = [ "GREETING=\"hello world\"" ]
}
''');
      expect(
        output,
        contains('load("@engine_version//:version.bzl", "ENGINE_VERSION", "SKIA_VERSION")\n'),
      );
      // Bazel tokenizes `defines` like a shell, so the quotes GN hands the
      // compiler verbatim are escaped (`\"` in the attribute value).
      expect(
        output,
        contains(r'''
    local_defines = FLUTTER_LOCAL_DEFINES + [
        "FLUTTER_ENGINE_VERSION=\\\"" + ENGINE_VERSION + "\\\"",
        "SKIA_VERSION=\\\"" + SKIA_VERSION + "\\\"",
    ],
'''),
      );
      expect(
        output,
        contains(r'''
cc_library(
    name = "quoted",
    defines = ["GREETING=\\\"hello\\ world\\\""],
)
'''),
      );
    });

    test('an include directory of another repository is a dependency on its library', () async {
      final String output = await convert('''
config("gles_config") {
  include_dirs = [ "//flutter/third_party/angle/include" ]
}

source_set("gles") {
  sources = [
    "gles.cc",
    "//flutter/third_party/angle/include/GLES3/gl3.h",
  ]
  public_configs = [ ":gles_config" ]
}
''');
      expect(
        output,
        contains('cc_library(\n    name = "gles_config",\n    deps = ["@angle//:headers"],\n)\n'),
      );
      expect(output, contains('"@angle//:include/GLES3/gl3.h"'));

      // A directory of another package of this repository (the core client
      // wrapper's include/flutter, which the GLFW wrapper's config names):
      // a dependency on the library its package's appendix adds -- and, in
      // that package itself, a plain `includes`, as the library is there.
      const gn = '''
config("relative_core_wrapper_headers") {
  include_dirs = [ "//flutter/shell/platform/common/client_wrapper/include/flutter" ]
}
''';
      expect(
        await convert(gn, gnPackage: '//flutter/shell/platform/glfw/client_wrapper'),
        contains(
          'cc_library(\n    name = "relative_core_wrapper_headers",\n'
          '    deps = ["//engine/src/flutter/shell/platform/common/client_wrapper:relative_core_wrapper_headers"],\n)\n',
        ),
      );
      expect(
        await convert(gn, gnPackage: '//flutter/shell/platform/common/client_wrapper'),
        contains(
          'cc_library(\n    name = "relative_core_wrapper_headers",\n'
          '    includes = ["include/flutter"],\n)\n',
        ),
      );
    });

    test('a suite run_tests.py runs with arguments gets them as args and data', () async {
      final GnFileEvaluation evaluation = await evaluate('''
executable("flow_unittests") {
  testonly = true
  sources = [ "flow_run_all_unittests.cc" ]
  deps = [ "//flutter/testing:testing_lib" ]
}
''');
      final String output = emitBuildFile(evaluation, gnPackage: '//flutter/flow');
      expect(
        output,
        contains('''
    args = [
        "--golden-dir=engine/src/flutter/testing/resources",
        "--font-file=engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf",
    ],
'''),
      );
      expect(
        output,
        contains('''
    data = [
        "//engine/src/flutter/testing:resources",
        "//engine/src/flutter/txt:third_party/fonts/Roboto-Regular.ttf",
    ],
'''),
      );
      expect(output, contains('size = "medium"'));
    });

    test('a suite that opens a window becomes a flutter_display_test', () async {
      // impeller_dart_unittests (displayTests): cc_test's attributes, the GPU
      // backends beside the binary and run_tests.py's arguments, on the
      // macro that runs the binary under a display.
      final GnFileEvaluation evaluation = await evaluate('''
executable("impeller_dart_unittests") {
  testonly = true
  deps = [
    "renderer:renderer_dart_unittests",
    "//flutter/testing",
  ]
}
''');
      final String output = emitBuildFile(evaluation, gnPackage: '//flutter/impeller');
      expect(
        output,
        contains(
          'load("//build_defs/testing:testing.bzl", "flutter_display_test", "flutter_gpu_test_backends")',
        ),
      );
      expect(
        output,
        contains('''
flutter_display_test(
    name = "impeller_dart_unittests",
    size = "small",
    args = [
        "--enable_vulkan_validation",
        "--gtest_filter=*Metal",
    ],
    data = [":gpu_test_backends"],
    deps = [
        "//engine/src/flutter/impeller/renderer:renderer_dart_unittests",
        "//engine/src/flutter/testing",
    ],
)
'''),
      );
      expect(output, isNot(contains('cc_test')));
    });

    test("a sharded suite gets shard_count; run_tests.py's Linux run has no arguments", () async {
      // impeller_unittests (testShardCounts): the whole suite as Linux CI runs
      // it, split into shards the display test's wrapper hands to gtest.
      final GnFileEvaluation evaluation = await evaluate('''
executable("impeller_unittests") {
  testonly = true
  deps = [
    "base:base_unittests",
    "//flutter/testing",
  ]
}
''');
      final String output = emitBuildFile(evaluation, gnPackage: '//flutter/impeller');
      expect(
        output,
        contains('''
flutter_display_test(
    name = "impeller_unittests",
    size = "large",
    data = [":gpu_test_backends"],
    shard_count = 16,
    deps = [
        "//engine/src/flutter/impeller/base:base_unittests",
        "//engine/src/flutter/testing",
    ],
)
'''),
      );
      expect(output, isNot(contains('args')));
    });

    test(r"wasm_lib becomes a wasm_module; a rebase_path() among its ldflags is the file's $(execpath)", () {
      // skwasm's shape: a module over the engine's and Skia's libraries, a
      // JavaScript library named on the link line by its rebased path and
      // listed among the inputs, flags under is_debug.
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/skw/BUILD.gn': '''
template("variant") {
  wasm_lib(target_name) {
    public_configs = [ "//flutter:config" ]
    sources = [
      "canvas.cc",
      "helpers.h",
    ]
    cflags = [ "-mreference-types" ]
    ldflags = [
      "-lGL",
      "--js-library",
      rebase_path("library_support.js"),
    ]
    inputs = [ rebase_path("library_support.js") ]
    if (invoker.is_heavy) {
      sources += [ "animated_image.cc" ]
    }
    if (is_debug) {
      ldflags += [ "-sASSERTIONS=1" ]
    } else {
      ldflags += [ "--closure=1" ]
    }
    deps = [ "//flutter/display_list" ]
  }
}
variant("m") {
  is_heavy = true
}
''',
      });
      final String output = emitBuildFile(
        evaluateIn(tree, '//flutter/skw/BUILD.gn', templates: <String>{'wasm_lib'}),
        gnPackage: '//flutter/skw',
        tree: tree,
      );
      expect(output, contains('load("//build_defs/web:wasm.bzl", "wasm_module")'));
      expect(
        output,
        contains(r'''
wasm_module(
    name = "m",
    srcs = [
        "animated_image.cc",  # invoker.is_heavy
        "canvas.cc",
        "helpers.h",
    ],
    copts = ["-mreference-types"] + FLUTTER_COPTS,
    link_inputs = ["library_support.js"],
    linkopts = [
        "-lGL",
        "--js-library",
        "$(execpath library_support.js)",
    ] + select({
        "//engine/src/flutter/build/bazel:unoptimized": [
            "-sASSERTIONS=1",  # is_debug
        ],
        "//conditions:default": [],
    }) + select({
        "//engine/src/flutter/build/bazel:unoptimized": [],
        "//conditions:default": [
            "--closure=1",  # !(is_debug)
        ],
    }),
    deps = [
        "//engine/src/flutter:config",
        "//engine/src/flutter/display_list",
    ],
)
'''),
      );
    });

    test("a copy naming a module in a wasm toolchain is the module's files under the toolchain's platform", () {
      // The web SDK's copies (third_party/canvaskit): the module's outputs
      // under the toolchain's directory of the build directory, the
      // toolchain named on the dependency edge; the files GN names, by
      // name, with the unoptimized build's source map under its condition
      // (a copy may name fewer files than the module writes).
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/ck/BUILD.gn': r'''
template("skw_toolchain") {
  wasm_toolchain(target_name) {
    extra_toolchain_args = {
      skia_use_icu = invoker.heavy
      wasm_use_workers = true
    }
  }
}
skw_toolchain("skw") {
  heavy = false
}
copy("skw_group") {
  visibility = [ "//flutter/web_sdk:*" ]
  public_deps = [ "//flutter/skwasm(:skw)" ]
  sources = [
    "$root_out_dir/skw/skwasm.js",
    "$root_out_dir/skw/skwasm.js.symbols",
    "$root_out_dir/skw/skwasm.wasm",
  ]
  if (is_debug) {
    if (!wasm_use_dwarf) {
      sources += [ "$root_out_dir/skw/skwasm.wasm.map" ]
    }
  }
  outputs = [ "$root_out_dir/flutter_web_sdk/canvaskit/{{source_file_part}}" ]
}
''',
      });
      final String output = emitBuildFile(
        evaluateIn(
          tree,
          '//flutter/ck/BUILD.gn',
          templates: <String>{'wasm_lib', 'wasm_toolchain'},
        ),
        gnPackage: '//flutter/ck',
        tree: tree,
      );
      expect(
        output,
        contains(r'''
gn_copy(
    name = "skw_group",
    srcs = ["//engine/src/flutter/skwasm"],
    files = [
        "skwasm.js",
        "skwasm.js.symbols",
        "skwasm.wasm",
    ] + select({
        "//engine/src/flutter/build/bazel:unoptimized": ["skwasm.wasm.map"],
        "//conditions:default": [],
    }),
    outputs = ["$root_out_dir/flutter_web_sdk/canvaskit/{{source_file_part}}"],
    platform = ":skw",
)
'''),
      );
    });

    test("a wasm link compiles with the engine's copts: the constant and the flags its "
        'dependencies hand it, after its own cflags', () {
      // wimp's shape: a wasm_lib over impeller, whose public config turns
      // warnings off for whoever includes it; and CanvasKit's executable,
      // which lists no //flutter:config and depends on nothing that does.
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/quiet/BUILD.gn': '''
config("quiet_public") {
  cflags = [ "-Wno-shadow" ]
}

source_set("quiet") {
  sources = [ "q.cc" ]
  public_configs = [ ":quiet_public" ]
}
''',
        'flutter/mod/BUILD.gn': '''
wasm_lib("mod") {
  sources = [ "m.cc" ]
  cflags = [ "-mreference-types" ]
  public_configs = [ "//flutter:config" ]
  deps = [ "//flutter/quiet" ]
}

executable("ck_js") {
  output_extension = "js"
  output_name = "ck"
  sources = [ "ck.cpp" ]
  deps = [ "//flutter/quiet" ]
}
''',
      });
      final String output = emitBuildFile(
        evaluateIn(tree, '//flutter/mod/BUILD.gn', templates: <String>{'wasm_lib'}),
        gnPackage: '//flutter/mod',
        tree: tree,
        forwardedFlags: DependencyResolver(tree: tree, assumptions: linuxHostAssumptions()),
      );
      expect(
        output,
        contains('''
wasm_module(
    name = "mod",
    srcs = ["m.cc"],
    copts = ["-mreference-types"] + FLUTTER_COPTS + [
        "-Wno-shadow",  # from //flutter/quiet
    ],
'''),
      );
      expect(
        output,
        contains('''
wasm_executable(
    name = "ck_js",
    srcs = ["ck.cpp"],
    copts = CHROMIUM_CODE_COPTS + [
        "-Wno-shadow",  # from //flutter/quiet
    ],
'''),
      );
    });

    test(
      'an executable with output_extension "js" is a wasm_executable; its group is a filegroup',
      () {
        // CanvasKit's shape (flutter/skia/modules/canvaskit): a template over
        // executable() in the wasm toolchain, a rebased path inside a flag,
        // and the group the web SDK's copies name.
        final GnSourceTree tree = sourceTree(<String, String>{
          'flutter/ckm/BUILD.gn': r'''
template("ck_lib") {
  _lib_name = target_name
  executable("${_lib_name}_js") {
    forward_variables_from(invoker, [ "sources", "ldflags", "deps", "check_includes" ])
    output_extension = "js"
    output_name = "${_lib_name}"
  }
  group("$_lib_name") {
    public_deps = [ ":${_lib_name}_js" ]
  }
}
ck_lib("canvaskit") {
  check_includes = false
  deps = [ "//flutter/display_list" ]
  sources = [ "bindings.cpp" ]
  externs_path = rebase_path("externs.js")
  ldflags = [
    "--pre-js",
    rebase_path("release.js"),
    "--closure-args=--externs=$externs_path",
    "-sEXPORT_NAME=CanvasKitInit",
  ]
}
''',
        });
        final String output = emitBuildFile(
          evaluateIn(tree, '//flutter/ckm/BUILD.gn', templates: <String>{'wasm_lib'}),
          gnPackage: '//flutter/ckm',
          tree: tree,
        );
        expect(
          output,
          contains(r'''
wasm_executable(
    name = "canvaskit_js",
    srcs = ["bindings.cpp"],
    copts = CHROMIUM_CODE_COPTS,
    link_inputs = [
        "release.js",
        "externs.js",
    ],
    linkopts = [
        "--pre-js",
        "$(execpath release.js)",
        "--closure-args=--externs=$(execpath externs.js)",
        "-sEXPORT_NAME=CanvasKitInit",
    ],
    output_name = "canvaskit",
    deps = ["//engine/src/flutter/display_list"],
)

filegroup(
    name = "canvaskit",
    srcs = [":canvaskit_js"],
)
'''),
        );
      },
    );

    test('sdk_rewriter takes its directory as a filegroup; a mapped template defined in the file is the rule', () {
      // web_sdk/BUILD.gn's shape: sdk_rewriter over a directory of another
      // package (directorySources), its exclusion a rebased path, and the
      // file's own _compile_platform template, whose mapping stands for
      // its body.
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/wsdk/BUILD.gn': r'''
template("_compile_platform") {
  action(target_name) {
    script = "//build/gn_run_binary.py"
    outputs = [ invoker.output_dill ]
    args = [ invoker.kernel_target ]
  }
}
sdk_rewriter("web_engine_library") {
  library_name = "engine"
  api_file = "engine.dart"
  input_dir = "//flutter/lib/web_ui/lib/src/engine/"
  output_dir = "$root_out_dir/flutter_web_sdk/lib/_engine/"
  exclude_pattern = rebase_path("//flutter/lib/web_ui/lib/src/engine/skwasm")
}
_compile_platform("dart2js_full") {
  kernel_target = "dart2js"
  summary_only = false
  output_dill = "$root_out_dir/flutter_web_sdk/kernel/dart2js_platform.dill"
  null_environment = true
}
''',
        'flutter/wsdk/engine.dart': '',
      });
      final String output = emitBuildFile(
        evaluateIn(
          tree,
          '//flutter/wsdk/BUILD.gn',
          templates: <String>{'sdk_rewriter', '_compile_platform'},
        ),
        gnPackage: '//flutter/wsdk',
        tree: tree,
      );
      expect(
        output,
        contains(r'''
sdk_rewriter(
    name = "web_engine_library",
    srcs = ["//engine/src/flutter/lib/web_ui:web_engine_sources"],
    api_file = "engine.dart",
    exclude = "engine/src/flutter/lib/web_ui/lib/src/engine/skwasm",
    input_dir = "engine/src/flutter/lib/web_ui/lib/src/engine",
    library_name = "engine",
    output_dir = "$root_out_dir/flutter_web_sdk/lib/_engine/",
)

web_platform_dill(
    name = "dart2js_full",
    kernel_target = "dart2js",
    null_environment = True,
    output_dill = "$root_out_dir/flutter_web_sdk/kernel/dart2js_platform.dill",
    summary_only = False,
)
'''),
      );
    });

    test('a copy in a wasm toolchain whose source is not an output of its module is an error', () {
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/ck/BUILD.gn': r'''
template("skw_toolchain") {
  wasm_toolchain(target_name) {
    extra_toolchain_args = {
      wasm_use_workers = true
    }
  }
}
skw_toolchain("skw") {
}
copy("skw_group") {
  public_deps = [ "//flutter/skwasm(:skw)" ]
  sources = [ "$root_out_dir/skw/other.js" ]
  outputs = [ "$root_out_dir/flutter_web_sdk/canvaskit/{{source_file_part}}" ]
}
''',
      });
      expect(
        () => emitBuildFile(
          evaluateIn(
            tree,
            '//flutter/ck/BUILD.gn',
            templates: <String>{'wasm_lib', 'wasm_toolchain'},
          ),
          gnPackage: '//flutter/ck',
          tree: tree,
        ),
        throwsA(
          isA<GnError>().having(
            (GnError e) => e.message,
            'message',
            contains('is not an output of //flutter/skwasm in toolchain :skw'),
          ),
        ),
      );
    });

    test('a suite run_tests.py puts through gtest-parallel becomes a flutter_cc_test', () async {
      // ui_unittests (gtestParallelSuites, with testRuns' runnerArgs): the
      // macro that runs the binary through the runner, with run_tests.py's
      // --timeout=90 for the runner and the GPU backends beside the binary.
      final GnFileEvaluation evaluation = await evaluate('''
executable("ui_unittests") {
  testonly = true
  sources = [ "ui_unittests.cc" ]
  deps = [ "//flutter/testing" ]
}
''');
      final String output = emitBuildFile(evaluation, gnPackage: '//flutter/lib/ui');
      expect(
        output,
        contains(
          'load("//build_defs/testing:testing.bzl", "flutter_cc_test", "flutter_gpu_test_backends")',
        ),
      );
      expect(
        output,
        contains('''
flutter_cc_test(
    name = "ui_unittests",
    size = "medium",
    srcs = ["ui_unittests.cc"],
    copts = CHROMIUM_CODE_COPTS,
    data = [":gpu_test_backends"],
    local_defines = FLUTTER_LOCAL_DEFINES,
    runner_args = ["--timeout=90"],
    deps = [
        "//engine/src:include_root",
        "//engine/src/flutter/testing",
    ],
)
'''),
      );
      expect(output, isNot(contains('\ncc_test(')));
      // The GTK shell's suite: a display test, under the runner.
      final GnFileEvaluation gtk = await evaluate('''
executable("flutter_linux_unittests") {
  testonly = true
  sources = [ "test.cc" ]
}
''');
      final String gtkOutput = emitBuildFile(gtk, gnPackage: '//flutter/shell/platform/linux');
      expect(gtkOutput, contains('flutter_display_test(\n    name = "flutter_linux_unittests",'));
      expect(gtkOutput, contains('    gtest_parallel = True,\n'));
      expect(gtkOutput, contains('    session_bus = True,\n'));
      expect(gtkOutput, contains('    env = {"G_DEBUG": "fatal-criticals"},\n'));
    });

    test('a benchmark run_tests.py runs is a manual cc_test; the others stay binaries', () async {
      // fml_benchmarks (benchmarkRuns): run_engine_benchmarks' ICU argument
      // and its file, tagged out of wildcard runs.
      final GnFileEvaluation evaluation = await evaluate('''
executable("fml_benchmarks") {
  testonly = true
  sources = [ "message_loop_task_queues_benchmark.cc" ]
  deps = [ "//flutter/benchmarking" ]
}
''');
      final String output = emitBuildFile(evaluation, gnPackage: '//flutter/fml');
      expect(
        output,
        contains('''
cc_test(
    name = "fml_benchmarks",
    size = "medium",
    srcs = ["message_loop_task_queues_benchmark.cc"],
    args = ["--icu-data-file-path=../+synced_deps+icu/common/icudtl.dat"],
    copts = CHROMIUM_CODE_COPTS,
    data = ["@icu//:icudata"],
    local_defines = FLUTTER_LOCAL_DEFINES,
    tags = [
        "benchmark",
        "manual",
    ],
    deps = [
        "//engine/src:include_root",
        "//engine/src/flutter/benchmarking",
    ],
)
'''),
      );
      // A testonly executable named neither *tests nor in benchmarkRuns.
      final GnFileEvaluation binary = await evaluate('''
executable("display_list_region_benchmarks") {
  testonly = true
  sources = [ "benchmarking/dl_region_benchmarks.cc" ]
}
''');
      final String binaryOutput = emitBuildFile(binary, gnPackage: '//flutter/display_list');
      expect(binaryOutput, contains('cc_binary(\n    name = "display_list_region_benchmarks",'));
      expect(binaryOutput, isNot(contains('tags')));
    });

    test('a testonly executable named *testrunner is a cc_test', () async {
      // licenses_cpp_testrunner: the gtest executable a builder runs from the
      // build directory rather than through run_tests.py.
      final GnFileEvaluation evaluation = await evaluate('''
executable("licenses_cpp_testrunner") {
  testonly = true
  sources = [ "src/catalog_unittests.cc" ]
  deps = [ "//flutter/third_party/googletest:gtest_main" ]
}

executable("runner") {
  sources = [ "src/main.cc" ]
}
''');
      final String output = emitBuildFile(evaluation, gnPackage: '//flutter/tools/licenses_cpp');
      expect(
        output,
        contains('cc_test(\n    name = "licenses_cpp_testrunner",\n    size = "medium",'),
      );
      expect(output, contains('cc_binary(\n    name = "runner",'));
    });

    test('all_dependent_configs cross private deps; engine code gets FLUTTER_COPTS', () async {
      final String output = await convert('''
config("vulkan_public") {
  defines = [ "SK_VULKAN" ]
}

source_set("vulkan") {
  sources = [ "vk.cc" ]
  all_dependent_configs = [ ":vulkan_public" ]
}

source_set("gpu") {
  sources = [ "gpu.cc" ]
  deps = [ ":vulkan" ]
}

source_set("skia") {
  sources = [ "skia.cc" ]
  deps = [ ":gpu" ]
}

source_set("engine") {
  sources = [ "engine.cc" ]
  deps = [ "//flutter/fml" ]
}

source_set("engine_too") {
  sources = [ "engine_too.cc" ]
  public_configs = [ "//flutter:config" ]
}
''');
      // GN applies vulkan_public to gpu and skia although they reach vulkan
      // through private deps.
      expect(
        output,
        contains('''
cc_library(
    name = "gpu",
    srcs = ["gpu.cc"],
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        ":vulkan",
        ":vulkan_public",
        "//engine/src:include_root",
    ],
    alwayslink = True,
)
'''),
      );
      expect(
        output,
        contains('''
cc_library(
    name = "skia",
    srcs = ["skia.cc"],
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        ":gpu",
        ":vulkan_public",
        "//engine/src:include_root",
    ],
    alwayslink = True,
)
'''),
      );
      // //flutter:config listed; a dependency on a file the converter cannot
      // read (no tree here) hands nothing.
      expect(
        output,
        contains('name = "engine",\n    srcs = ["engine.cc"],\n    copts = CHROMIUM_CODE_COPTS,'),
      );
      expect(
        output,
        contains('name = "engine_too",\n    srcs = ["engine_too.cc"],\n    copts = FLUTTER_COPTS,'),
      );
    });

    test("//flutter:config reaches a target as GN applies it: a dependency's public config, "
        'forwarded along public_deps only', () {
      // fml exports the config; impeller/geometry lists it privately (dl_path
      // depends on it and GN compiles dl_path without -Wunreachable-code);
      // compiler_lib hands fml's on through its public_deps (impellerc gets
      // it over a plain deps edge); a private deps edge forwards nothing.
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/fml/BUILD.gn': '''
source_set("fml") {
  sources = [ "fml.cc" ]
  public_configs = [ "//flutter:config" ]
}
''',
        'flutter/impeller/geometry/BUILD.gn': '''
source_set("geometry") {
  sources = [ "geometry.cc" ]
  configs += [ "//flutter:config" ]
}
''',
        'flutter/impeller/compiler/BUILD.gn': '''
source_set("compiler_lib") {
  sources = [ "compiler.cc" ]
  public_deps = [ "//flutter/fml" ]
}
''',
        'flutter/example/BUILD.gn': '''
source_set("through_public") {
  sources = [ "through_public.cc" ]
  public_deps = [ "//flutter/fml" ]
}

source_set("through_private") {
  sources = [ "through_private.cc" ]
  deps = [ "//flutter/fml" ]
}

source_set("on_fml") {
  sources = [ "on_fml.cc" ]
  deps = [ "//flutter/fml" ]
}

source_set("on_geometry") {
  sources = [ "on_geometry.cc" ]
  deps = [ "//flutter/impeller/geometry" ]
}

source_set("on_compiler_lib") {
  sources = [ "on_compiler_lib.cc" ]
  deps = [ "//flutter/impeller/compiler:compiler_lib" ]
}

source_set("on_through_public") {
  sources = [ "on_through_public.cc" ]
  deps = [ ":through_public" ]
}

source_set("on_through_private") {
  sources = [ "on_through_private.cc" ]
  deps = [ ":through_private" ]
}
''',
      });
      final String output = emitBuildFile(
        evaluateIn(tree, '//flutter/example/BUILD.gn'),
        gnPackage: '//flutter/example',
        tree: tree,
        forwardedFlags: DependencyResolver(tree: tree, assumptions: linuxHostAssumptions()),
      );
      String coptsOf(String name) {
        final RegExpMatch? match = RegExp(
          'name = "$name",\\n    srcs = \\["$name.cc"\\],\\n    copts = ([A-Z_]+),',
        ).firstMatch(output);
        return match?.group(1) ?? 'not found';
      }

      expect(coptsOf('on_fml'), 'FLUTTER_COPTS');
      expect(coptsOf('through_public'), 'FLUTTER_COPTS');
      expect(coptsOf('through_private'), 'FLUTTER_COPTS');
      expect(coptsOf('on_compiler_lib'), 'FLUTTER_COPTS');
      expect(coptsOf('on_through_public'), 'FLUTTER_COPTS');
      expect(coptsOf('on_geometry'), 'CHROMIUM_CODE_COPTS');
      expect(coptsOf('on_through_private'), 'CHROMIUM_CODE_COPTS');
    });

    test('hands the flags of a public config to the owner and its dependents', () async {
      // wuffs: the engine's GN turns warnings off for whoever includes it.
      const layout = OutputLayout.repository(
        '@wuffs',
        repositoryGnRoot: '//flutter/third_party/wuffs',
      );
      const wuffsGn = '''
config("wuffs_public") {
  include_dirs = [ "release/c" ]
  cflags = []
  if (is_clang) {
    cflags += [
      "-Wno-unused-function",
      "-Wno-c++11-narrowing",
    ]
  }
}

config("quiet") {
  cflags = [ "-w" ]
  cflags_c = [ "-std=c99" ]
}

source_set("wuffs") {
  public_configs = [ ":wuffs_public" ]
  configs += [ ":quiet" ]
  sources = [ "release/c/wuffs-v0.3.c" ]
}
''';
      final String wuffs = await convert(
        wuffsGn,
        gnPackage: '//flutter/third_party/wuffs',
        layout: layout,
      );
      // The owner compiles with the flags of both configs (-std= aside); the
      // public config is still a dependency for its include directory.
      expect(
        wuffs,
        contains('''
cc_library(
    name = "wuffs",
    srcs = ["release/c/wuffs-v0.3.c"],
    copts = CHROMIUM_CODE_COPTS + [
        "-Wno-unused-function",  # is_clang
        "-Wno-c++11-narrowing",  # is_clang
        "-w",
    ],
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [":wuffs_public"],
    alwayslink = True,
)
'''),
      );
      expect(
        wuffs,
        contains('cc_library(\n    name = "wuffs_public",\n    includes = ["release/c"],\n)'),
      );
      expect(wuffs, contains('cc_library(\n    name = "quiet",\n)'));

      // A dependent gets them from wuffs's own GN file, read from the tree
      // (dependency_resolver.dart).
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/third_party/wuffs/BUILD.gn': wuffsGn,
        'flutter/example/BUILD.gn': '''
source_set("gif_codec") {
  sources = [ "gif.cc" ]
  deps = [ "//flutter/third_party/wuffs" ]
}
''',
      });
      final String user = emitBuildFile(
        evaluateIn(tree, '//flutter/example/BUILD.gn'),
        gnPackage: '//flutter/example',
        tree: tree,
      );
      expect(
        user,
        contains('''
    copts = CHROMIUM_CODE_COPTS + [
        "-Wno-unused-function",  # from //flutter/third_party/wuffs
        "-Wno-c++11-narrowing",  # from //flutter/third_party/wuffs
    ],
'''),
      );
      expect(user, contains('        "@wuffs",\n    ],'));
      // Without a tree to read wuffs's file from, nothing says what it
      // hands on.
      expect(
        await convert('''
source_set("gif_codec") {
  sources = [ "gif.cc" ]
  deps = [ "//flutter/third_party/wuffs" ]
}
'''),
        contains('copts = CHROMIUM_CODE_COPTS,'),
      );

      // A config with flags that nothing in the file lists is an error.
      await expectLater(
        convert('''
config("unused") {
  cflags = [ "-Wall" ]
}
'''),
        throwsGnError(line: 2, message: 'cannot be propagated by Bazel'),
      );
    });

    test('hands the flags on along public_deps chains, under their conditions', () async {
      // flutter_vma: GN applies the Vulkan headers' and the allocator's
      // suppressions to whoever depends on flutter_vma, since it lists both
      // in public_deps, and so on down the chain; each hop is read from the
      // dependency's file.
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/third_party/vulkan-deps/vulkan-headers/src/BUILD.gn': '''
config("vulkan_headers_config") {
  include_dirs = [ "include" ]
  if (is_clang) {
    cflags = [ "-Wno-redundant-parens" ]
  }
}

source_set("vulkan_headers") {
  public_configs = [ ":vulkan_headers_config" ]
}
''',
        'flutter/third_party/vulkan_memory_allocator/BUILD.gn': '''
config("vulkan_memory_allocator_config") {
  include_dirs = [ "include" ]
  cflags_cc = [ "-Wno-unused-private-field" ]
}

source_set("vulkan_memory_allocator") {
  public_configs = [ ":vulkan_memory_allocator_config" ]
}
''',
        'flutter/flutter_vma/BUILD.gn': '''
source_set("flutter_vma") {
  sources = [ "flutter_vma.cc" ]
  public_deps = [
    "//flutter/third_party/vulkan-deps/vulkan-headers/src:vulkan_headers",
    "//flutter/third_party/vulkan_memory_allocator",
  ]
  public_configs = [ "//flutter:config" ]
}
''',
        'flutter/vulkan/BUILD.gn': '''
source_set("vulkan") {
  sources = [ "vulkan.cc" ]
  deps = [ "//flutter/flutter_vma" ]
}

group("forwarding") {
  public_deps = [ "//flutter/flutter_vma" ]
}

group("private") {
  deps = [ "//flutter/flutter_vma" ]
}

source_set("in_release") {
  sources = [ "r.cc" ]
  public_deps = []
  if (flutter_runtime_mode == "release") {
    public_deps += [ "//flutter/flutter_vma" ]
  }
}
''',
        'flutter/shell/BUILD.gn': '''
source_set("through_group") {
  sources = [ "g.cc" ]
  deps = [ "//flutter/vulkan:forwarding" ]
}

source_set("stopped") {
  sources = [ "s.cc" ]
  deps = [ "//flutter/vulkan:private" ]
}

source_set("maybe") {
  sources = [ "m.cc" ]
  deps = [ "//flutter/vulkan:in_release" ]
}
''',
      });
      String convertIn(String package) {
        return emitBuildFile(evaluateIn(tree, '$package/BUILD.gn'), gnPackage: package, tree: tree);
      }

      // The owner compiles with what its public_deps hand it (the headers'
      // flag, under is_clang, which the host assumptions settle).
      expect(
        convertIn('//flutter/flutter_vma'),
        contains('''
    copts = FLUTTER_COPTS + [
        "-Wno-redundant-parens",  # from //flutter/third_party/vulkan-deps/vulkan-headers/src:vulkan_headers
        "-Wno-unused-private-field",  # from //flutter/third_party/vulkan_memory_allocator
    ],
'''),
      );
      // A dependent, two hops down.
      final String vulkan = convertIn('//flutter/vulkan');
      expect(
        vulkan,
        contains('''
    name = "vulkan",
    srcs = ["vulkan.cc"],
    copts = FLUTTER_COPTS + [
        "-Wno-redundant-parens",  # from //flutter/flutter_vma
        "-Wno-unused-private-field",  # from //flutter/flutter_vma
    ],
'''),
      );
      // A group hands on what its public_deps hand it, and keeps what its
      // private deps hand it to itself; a conditional public dependency
      // hands on under its condition, which the dependent's copts take as
      // a select().
      final String shell = convertIn('//flutter/shell');
      expect(
        shell,
        contains('''
    name = "through_group",
    srcs = ["g.cc"],
    copts = FLUTTER_COPTS + [
        "-Wno-redundant-parens",  # from //flutter/vulkan:forwarding
        "-Wno-unused-private-field",  # from //flutter/vulkan:forwarding
    ],
'''),
      );
      expect(
        shell,
        contains('    name = "stopped",\n    srcs = ["s.cc"],\n    copts = CHROMIUM_CODE_COPTS,\n'),
      );
      expect(
        shell,
        contains('''
    name = "maybe",
    srcs = ["m.cc"],
    copts = FLUTTER_COPTS + select({
        "//engine/src/flutter/common:runtime_mode_release": [
            "-Wno-redundant-parens",  # from //flutter/vulkan:in_release
            "-Wno-unused-private-field",  # from //flutter/vulkan:in_release
        ],
        "//conditions:default": [],
    }),
'''),
      );
      // The owner of a conditional public dependency takes it under the
      // condition too.
      expect(
        vulkan,
        contains('''
    name = "in_release",
    srcs = ["r.cc"],
    copts = FLUTTER_COPTS + select({
        "//engine/src/flutter/common:runtime_mode_release": [
            "-Wno-redundant-parens",  # from //flutter/flutter_vma
            "-Wno-unused-private-field",  # from //flutter/flutter_vma
        ],
        "//conditions:default": [],
    }),
'''),
      );
    });

    test('derives the flags once per dependency file and reads the placeholder idiom', () async {
      // One resolver serves a run; a dependency whose file is absent, or
      // which GN defines twice (the real target under a condition, an empty
      // group otherwise), hands what the real target does.
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/third_party/quiet/BUILD.gn': '''
config("quiet_public") {
  cflags = [ "-Wno-shadow" ]
}

if (is_linux) {
  source_set("quiet") {
    sources = [ "q.cc" ]
    public_configs = [ ":quiet_public" ]
  }
} else {
  group("quiet") {
  }
}
''',
        'flutter/a/BUILD.gn': '''
source_set("a") {
  sources = [ "a.cc" ]
  deps = [
    "//flutter/third_party/quiet",
    "//flutter/nowhere:nothing",
  ]
}
''',
        'flutter/b/BUILD.gn': '''
source_set("b") {
  sources = [ "b.cc" ]
  deps = [ "//flutter/third_party/quiet" ]
}
''',
      });
      final resolver = DependencyResolver(tree: tree, assumptions: linuxHostAssumptions());
      for (final package in <String>['//flutter/a', '//flutter/b']) {
        expect(
          emitBuildFile(
            evaluateIn(tree, '$package/BUILD.gn'),
            gnPackage: package,
            tree: tree,
            forwardedFlags: resolver,
          ),
          contains('"-Wno-shadow",  # from //flutter/third_party/quiet'),
        );
      }
      expect(resolver.flagsOf('//flutter/third_party/quiet:quiet'), <ForwardedFlag>[
        (condition: Condition.always, flag: '-Wno-shadow'),
      ]);
      expect(resolver.flagsOf('//flutter/nowhere:nothing'), isEmpty);
      expect(DependencyResolver.none().flagsOf('//flutter/third_party/quiet:quiet'), isEmpty);
    });

    test('a dependency file outside the import policy says nothing; one the converter '
        'cannot evaluate is an error', () {
      // The Dart runtime's and abseil's files import outside the policy:
      // they hand nothing, as far as the converter can tell. A file within
      // the policy that fails to evaluate is the converter's own failure,
      // which must not pass as "no flags" (glslang's -Wno-conversion once
      // went missing that way).
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/third_party/foreign/BUILD.gn': '''
import("//somewhere/else.gni")
source_set("foreign") {
  sources = [ "f.cc" ]
}
''',
        'flutter/third_party/broken/BUILD.gn': '''
if (current_toolchain == unknown_toolchain) {
  source_set("broken") {
    sources = [ "b.cc" ]
  }
}
''',
      });
      final resolver = DependencyResolver(tree: tree, assumptions: linuxHostAssumptions());
      expect(resolver.flagsOf('//flutter/third_party/foreign:foreign'), isEmpty);
      expect(
        () => resolver.flagsOf('//flutter/third_party/broken:broken'),
        throwsGnError(line: 1, message: 'needs both values to be known'),
      );
    });

    test('zip_bundle: entries by destination, sources resolved to their producers', () async {
      // font_subset's shape: the executable's output_name, a copy into the
      // build root, a shared library, a source file, an entry under the
      // runtime mode, and the block's helpers.
      final String output = await convert(
        r'''
import("//flutter/build/zip_bundle.gni")

executable("_tool") {
  output_name = "tool"
  sources = [ "a.cc" ]
}

shared_library("engine_library") {
  output_name = "engine"
  sources = [ "b.cc" ]
}

copy("copy_headers") {
  sources = [ "embedder.h" ]
  outputs = [ "$root_out_dir/flutter_embedder.h" ]
}

zip_bundle("bundle") {
  if (is_mac) {
    output = "darwin-${target_cpu}/tool.zip"
  } else {
    output = "${full_target_platform_name}/tool.zip"
  }
  tool_bin = "tool"
  if (is_win) {
    tool_bin = "${tool_bin}.exe"
  }
  deps = [ ":_tool", ":engine_library", ":copy_headers" ]
  files = [
    {
      source = "$root_build_dir/$tool_bin"
      destination = tool_bin
    },
    {
      source = "README.md"
      destination = "docs/README.md"
    },
    {
      source = "$root_out_dir/flutter_embedder.h"
      destination = "flutter_embedder.h"
    },
  ]
  if (host_os == "linux") {
    files += [
      {
        source = "$root_out_dir/libengine.so"
        destination = "libengine.so"
      },
    ]
  }
  if (flutter_runtime_mode == "release") {
    files += [
      {
        source = "$root_build_dir/tool"
        destination = "extra/tool"
      },
    ]
  }
}
''',
        templates: <String>{'zip_bundle'},
      );
      expect(
        output,
        contains('''
zip_bundle(
    name = "bundle",
    files = {
        "tool": ":_tool",
        "docs/README.md": "README.md",
        "flutter_embedder.h": ":copy_headers",
        "libengine.so": ":engine_library",
    } | select({
        "//engine/src/flutter/common:runtime_mode_release": {"extra/tool": ":_tool"},
        "//conditions:default": {},
    }),
    output = "linux-x64/tool.zip",
    sources = {
        "tool": "tool",
        "flutter_embedder.h": "flutter_embedder.h",
        "libengine.so": "libengine.so",
    } | select({
        "//engine/src/flutter/common:runtime_mode_release": {"extra/tool": "tool"},
        "//conditions:default": {},
    }),
    deps = [
        ":_tool",
        ":copy_headers",
        ":engine_library",
    ],
)
'''),
      );
      // The copy into the build root converts; as it renames its file, the
      // Bazel file bears the layout's name.
      expect(
        output,
        contains(
          'gn_copy(\n    name = "copy_headers",\n    srcs = ["embedder.h"],\n'
          '    outs = ["flutter_embedder.h"],\n    outputs = ["\$root_out_dir/flutter_embedder.h"],\n)\n',
        ),
      );
      expect(output, isNot(contains('tool_bin')));
      // A copy into the build root that keeps its file's name lets the file
      // travel as it is.
      expect(
        await convert(r'''
copy("copy_icu") {
  sources = [ "data/icudtl.dat" ]
  outputs = [ "$root_out_dir/icudtl.dat" ]
}
'''),
        contains(
          'gn_copy(\n    name = "copy_icu",\n    srcs = ["data/icudtl.dat"],\n'
          '    outputs = ["\$root_out_dir/icudtl.dat"],\n)\n',
        ),
      );
      // An entry nothing produces.
      await expectLater(
        convert(
          r'''
import("//flutter/build/zip_bundle.gni")

zip_bundle("bundle") {
  output = "x.zip"
  files = [
    {
      source = "$root_build_dir/nothing"
      destination = "nothing"
    },
  ]
}
''',
          templates: <String>{'zip_bundle'},
        ),
        throwsGnError(
          line: 5,
          message:
              r'no target of this file or of the deps of bundle produces $root_out_dir/nothing',
        ),
      );
      // An argument the mapping lacks, as opposed to a helper the block reads.
      await expectLater(
        convert(
          '''
import("//flutter/build/zip_bundle.gni")

zip_bundle("bundle") {
  output = "x.zip"
  files = []
  strip = true
}
''',
          templates: <String>{'zip_bundle'},
        ),
        throwsGnError(
          line: 6,
          message: 'argument strip is not handled by the zip_bundle macro mapping',
        ),
      );
    });

    test(
      'a framework bundle: the copies into it, package_framework.py, the archive over it',
      () async {
        // The embedder's FlutterEmbedder.framework: the shared library copied
        // under Versions/A (its build-directory path resolving to the target
        // that links it), the symlinks made by package_framework.py -- the
        // action known by its script, the rule declaring the links from its
        // arguments -- and the archive whose entries are the bundle directory
        // (every file placed under it) and the top-level links.
        final String output = await convert(
          r'''
import("//flutter/build/zip_bundle.gni")

shared_library("engine_library") {
  output_name = "engine"
  sources = [ "b.cc" ]
}

_framework_dir = "$root_out_dir/Engine.framework"

copy("copy_dylib") {
  sources = [ "$root_out_dir/libengine.dylib" ]
  outputs = [ "$_framework_dir/Versions/A/Engine" ]
  deps = [ ":engine_library" ]
}

copy("copy_headers") {
  sources = [ "embedder.h" ]
  outputs = [ "$_framework_dir/Versions/A/Headers/Engine.h" ]
}

action("generate_symlinks") {
  script = "//build/config/mac/package_framework.py"
  outputs = [
    "$root_build_dir/Engine.stamp",
    _framework_dir,
    "$_framework_dir/Headers",
  ]
  args = [
    "--framework",
    "Engine.framework",
    "--version",
    "A",
    "--contents",
    "Engine",
    "Headers",
    "--stamp",
    "Engine.stamp",
  ]
  deps = [ ":copy_dylib", ":copy_headers" ]
}

zip_bundle("framework_archive") {
  deps = [ ":generate_symlinks" ]
  output = "darwin-x64/Engine.framework.zip"
  files = [
    {
      source = _framework_dir
      destination = "Engine.framework"
    },
    {
      source = "$_framework_dir/Headers"
      destination = "Engine.framework/Headers"
    },
  ]
}

action("engine_xcframework") {
  script = "//flutter/sky/tools/create_xcframework.py"
  outputs = [ "$root_out_dir/Engine.xcframework" ]
  args = [
    "--frameworks",
    rebase_path(_framework_dir),
    "--name",
    "Engine",
    "--location",
    rebase_path(root_out_dir),
  ]
  deps = [ ":generate_symlinks" ]
}
''',
          templates: <String>{'zip_bundle'},
        );
        expect(
          output,
          contains('load("//build_defs/dist:framework.bzl", "framework_symlinks", "xcframework")'),
        );
        expect(
          output,
          contains('''
framework_symlinks(
    name = "generate_symlinks",
    args = [
        "--framework",
        "Engine.framework",
        "--version",
        "A",
        "--contents",
        "Engine",
        "Headers",
        "--stamp",
        "Engine.stamp",
    ],
    deps = [
        ":copy_dylib",
        ":copy_headers",
    ],
)
'''),
        );
        expect(
          output,
          contains(r'''
gn_copy(
    name = "copy_dylib",
    srcs = [":engine_library"],
    outs = ["Engine.framework/Versions/A/Engine"],
    outputs = ["$root_out_dir/Engine.framework/Versions/A/Engine"],
    deps = [":engine_library"],
)
'''),
        );
        expect(
          output,
          contains('''
zip_bundle(
    name = "framework_archive",
    files = {
        "Engine.framework": ":generate_symlinks",
        "Engine.framework/Headers": ":generate_symlinks",
    },
    output = "darwin-x64/Engine.framework.zip",
    sources = {
        "Engine.framework": "Engine.framework",
        "Engine.framework/Headers": "Engine.framework/Headers",
    },
    deps = [":generate_symlinks"],
)
'''),
        );
        expect(output, isNot(contains('package_framework.py')));
        // The xcframework over the bundle: the rule reads GN's arguments
        // with the bundle and the location as path tokens.
        expect(
          output,
          contains(r'''
xcframework(
    name = "engine_xcframework",
    args = [
        "--frameworks",
        "$(built Engine.framework)",
        "--name",
        "Engine",
        "--location",
        "$(built .)",
    ],
    deps = [":generate_symlinks"],
)
'''),
        );
      },
    );

    test("a target reached on one platform alone: the manifest's targetConditions", () async {
      // shell/platform/common's accessibility bridge: defined outright, but
      // only the macOS and Windows shells name it and only they compile it.
      // Evaluated as if inside `if (is_mac)`: incompatible elsewhere, and
      // what its block lists under is_mac is unconditional within it.
      final String output = await convert(
        r'''
source_set("bridge") {
  sources = [ "bridge.cc" ]
  if (is_mac) {
    sources += [ "bridge_mac.cc" ]
  }
  if (is_linux) {
    sources += [ "bridge_linux.cc" ]
  }
}

source_set("plain") {
  sources = [ "plain.cc" ]
}
''',
        assumptions: generationAssumptions(),
        targetConditions: <String, Condition>{'bridge': const ConditionVariable('is_mac')},
      );
      expect(
        output,
        contains('''
cc_library(
    name = "bridge",
    srcs = [
        "bridge.cc",
        "bridge_mac.cc",  # is_mac
    ],
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    target_compatible_with = select({
        "@platforms//os:macos": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
    deps = ["//engine/src:include_root"],
    alwayslink = True,
)
'''),
      );
      expect(output, isNot(contains('bridge_linux.cc')));
      expect(
        output,
        contains('''
cc_library(
    name = "plain",
    srcs = ["plain.cc"],
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = ["//engine/src:include_root"],
    alwayslink = True,
)
'''),
      );
    });

    test(
      'zip_bundle_from_file over a directory of the build directory is a build_directory_tree',
      () async {
        // The web SDK's archive (web_sdk/BUILD.gn): every entry is a source
        // under one directory of the build directory at its path below it,
        // `rebase_path(source, "$root_build_dir/<dir>")` -- a target's outputs
        // and literal paths alike -- so the archive is one tree over the
        // bundle's deps, which place their files there (BuildDirectoryInfo).
        final GnSourceTree tree = sourceTree(<String, String>{
          'flutter/wsdk/BUILD.gn': r'''
import("//flutter/build/zip_bundle.gni")

copy("lib") {
  sources = [ "ui.dart" ]
  outputs = [ "$root_out_dir/flutter_web_sdk/lib/{{source_file_part}}" ]
}

copy("kernel") {
  sources = [ "platform.dill" ]
  outputs = [ "$root_out_dir/flutter_web_sdk/kernel/{{source_file_part}}" ]
}

zip_bundle_from_file("sdk_archive") {
  output = "flutter-web-sdk.zip"
  deps = [ ":kernel", ":lib" ]
  sources = get_target_outputs(":kernel")
  sources += [ "$root_out_dir/flutter_web_sdk/lib/ui.dart" ]
  if (is_wasm) {
    sources += [ "$root_out_dir/flutter_web_sdk/canvaskit/skwasm.wasm" ]
  }
  tmp_files = []
  foreach(source, sources) {
    tmp_files += [
      {
        source = rebase_path(source)
        destination = rebase_path(source, "$root_build_dir/flutter_web_sdk")
      },
    ]
  }
  files = tmp_files
}
''',
        });
        final String output = emitBuildFile(
          evaluateIn(tree, '//flutter/wsdk/BUILD.gn', templates: <String>{'zip_bundle_from_file'}),
          gnPackage: '//flutter/wsdk',
          tree: tree,
        );
        expect(
          output,
          contains('''
build_directory_tree(
    name = "sdk_archive_tree",
    srcs = [
        ":kernel",
        ":lib",
    ],
    under = "flutter_web_sdk",
)

zip_bundle_from_file(
    name = "sdk_archive",
    output = "flutter-web-sdk.zip",
    trees = [":sdk_archive_tree"],
    deps = [
        ":kernel",
        ":lib",
    ],
)
'''),
        );
        // An entry at the build directory's root is not under a directory:
        // the plain bundle shape, entry by entry (a `rebase_path()` around
        // a source is the path itself).
        final String mixed = await convert(
          r'''
import("//flutter/build/zip_bundle.gni")

copy("lib") {
  sources = [ "ui.dart" ]
  outputs = [ "$root_out_dir/flutter_web_sdk/lib/ui.dart" ]
}

copy("version") {
  sources = [ "version" ]
  outputs = [ "$root_out_dir/version" ]
}

zip_bundle_from_file("mixed") {
  output = "mixed.zip"
  deps = [
    ":lib",
    ":version",
  ]
  files = [
    {
      source = rebase_path("$root_build_dir/flutter_web_sdk/lib/ui.dart")
      destination = "lib/ui.dart"
    },
    {
      source = rebase_path("$root_build_dir/version")
      destination = "version"
    },
  ]
}
''',
          templates: <String>{'zip_bundle_from_file'},
        );
        expect(mixed, isNot(contains('build_directory_tree')));
        expect(
          mixed,
          contains('''
    files = {
        "lib/ui.dart": ":lib",
        "version": ":version",
    },
'''),
        );
      },
    );

    test("zip_bundle: an entry produced by another file's target, through the resolver", () {
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/build/zip_bundle.gni': '',
        'flutter/compiler/BUILD.gn': '''
executable("impellerc") {
  sources = [ "c.cc" ]
}
''',
        'flutter/sdk/BUILD.gn': r'''
import("//flutter/build/zip_bundle.gni")

zip_bundle("sdk") {
  output = "sdk.zip"
  deps = [ "//flutter/compiler:impellerc" ]
  files = [
    {
      source = "$root_build_dir/impellerc"
      destination = "bin/impellerc"
    },
  ]
}
''',
      });
      final resolver = DependencyResolver(tree: tree, assumptions: linuxHostAssumptions());
      expect(
        emitBuildFile(
          evaluateIn(tree, '//flutter/sdk/BUILD.gn', templates: <String>{'zip_bundle'}),
          gnPackage: '//flutter/sdk',
          tree: tree,
          forwardedFlags: resolver,
        ),
        contains('files = {"bin/impellerc": "//engine/src/flutter/compiler:impellerc"}'),
      );
      expect(resolver.targetOf('//flutter/compiler:impellerc')?.rule, 'executable');
      expect(resolver.targetOf('//flutter/compiler:nothing'), isNull);
      expect(resolver.targetOf('//flutter/nowhere:nothing'), isNull);
    });

    test('zip_bundle: conditional destinations and names, a directory, a group', () {
      // build/archives' shapes: the patched SDK's layout by mode, the
      // artifacts' prefix with the mode's name, a directory source, a
      // source produced behind a group, an output of a hand-written tree.
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/build/zip_bundle.gni': '',
        'flutter/shell/testing/BUILD.gn': '''
group("testing") {
  public_deps = [ ":flutter_tester" ]
}

executable("flutter_tester") {
  sources = [ "t.cc" ]
}
''',
        'flutter/build/archives/BUILD.gn': r'''
import("//flutter/build/zip_bundle.gni")

zip_bundle("flutter_patched_sdk") {
  file_suffix = ""
  path_prefix = "flutter_patched_sdk/"
  if (flutter_runtime_mode == "release") {
    file_suffix = "_product"
    path_prefix = "flutter_patched_sdk_product/"
  }
  output = "flutter_patched_sdk${file_suffix}.zip"
  files = [
    {
      source = "$root_out_dir/flutter_patched_sdk/platform_strong.dill"
      destination = "${path_prefix}platform_strong.dill"
    },
  ]
}

zip_bundle("artifacts") {
  deps = [ "//flutter/shell/testing" ]
  if (flutter_runtime_mode != "debug") {
    prefix = "$full_target_platform_name-$flutter_runtime_mode"
  } else {
    prefix = "$full_target_platform_name"
  }
  output = "$prefix/artifacts.zip"
  files = [
    {
      source = "$root_out_dir/flutter_tester"
      destination = "flutter_tester"
    },
  ]
  if (flutter_runtime_mode == "debug") {
    files += [
      {
        source = "//flutter/impeller/compiler/shader_lib"
        destination = "shader_lib"
      },
    ]
  }
}
''',
      });
      final String output = emitBuildFile(
        evaluateIn(tree, '//flutter/build/archives/BUILD.gn', templates: <String>{'zip_bundle'}),
        gnPackage: '//flutter/build/archives',
        tree: tree,
        forwardedFlags: DependencyResolver(tree: tree, assumptions: linuxHostAssumptions()),
      );
      expect(
        output,
        contains('''
zip_bundle(
    name = "flutter_patched_sdk",
    files = select({
        "//engine/src/flutter/common:runtime_mode_release": {"flutter_patched_sdk_product/platform_strong.dill": "//engine/src/flutter/lib/snapshot:flutter_patched_sdk/platform_strong.dill"},
        "//conditions:default": {"flutter_patched_sdk/platform_strong.dill": "//engine/src/flutter/lib/snapshot:flutter_patched_sdk/platform_strong.dill"},
    }),
    output = select({
        "//engine/src/flutter/common:runtime_mode_release": "flutter_patched_sdk_product.zip",
        "//conditions:default": "flutter_patched_sdk.zip",
    }),
    sources = select({
        "//engine/src/flutter/common:runtime_mode_release": {"flutter_patched_sdk_product/platform_strong.dill": "flutter_patched_sdk/platform_strong.dill"},
        "//conditions:default": {"flutter_patched_sdk/platform_strong.dill": "flutter_patched_sdk/platform_strong.dill"},
    }),
)
'''),
      );
      expect(
        output,
        contains('''
zip_tree(
    name = "artifacts_shader_lib",
    srcs = ["//engine/src/flutter/impeller/compiler/shader_lib:all_files"],
    destination = "shader_lib",
    root = "engine/src/flutter/impeller/compiler/shader_lib",
)

zip_bundle(
    name = "artifacts",
    files = {"flutter_tester": "//engine/src/flutter/shell/testing:flutter_tester"},
    output = select({
        "//engine/src/flutter/common:runtime_mode_profile": "linux-x64-profile/artifacts.zip",
        "//engine/src/flutter/common:runtime_mode_release": "linux-x64-release/artifacts.zip",
        "//engine/src/flutter/common:runtime_mode_jit_release": "linux-x64-jit_release/artifacts.zip",
        "//engine/src/flutter/common:runtime_mode_debug": "linux-x64/artifacts.zip",
        "//conditions:default": None,
    }),
    sources = {"flutter_tester": "flutter_tester"},
    trees = select({
        "//engine/src/flutter/common:runtime_mode_debug": [":artifacts_shader_lib"],
        "//conditions:default": [],
    }),
    deps = ["//engine/src/flutter/shell/testing"],
)
'''),
      );
    });

    test('zip_bundle: every output of a copy at its build-directory path is a tree', () {
      // The GTK bundle's idiom: foreach over get_target_outputs() of the
      // headers' copy, each at rebase_path(source, root_build_dir), ahead of
      // the library and gen_snapshot; the loop variable is a helper.
      const gtk = r'''
import("//flutter/build/zip_bundle.gni")

_public_headers = [
  "public/flutter_linux/fl_view.h",
  "public/flutter_linux/flutter_linux.h",
]

shared_library("flutter_linux_gtk") {
  sources = [ "fl_view.cc" ]
}

copy("publish_headers_linux") {
  sources = _public_headers
  outputs = [ "$root_out_dir/flutter_linux/{{source_file_part}}" ]
}

zip_bundle("flutter_gtk") {
  prefix = "$full_target_platform_name-$flutter_runtime_mode/"
  output = "${prefix}${full_target_platform_name}-flutter-gtk.zip"
  deps = [
    ":flutter_linux_gtk",
    ":publish_headers_linux",
    "$dart_src/runtime/bin:gen_snapshot",
  ]
  sources = get_target_outputs(":publish_headers_linux")
  tmp_files = []
  foreach(source, sources) {
    tmp_files += [
      {
        source = source
        destination = rebase_path(source, "$root_build_dir")
      },
    ]
  }
  tmp_files += [
    {
      source = "$root_build_dir/libflutter_${host_os}_gtk.so"
      destination = "libflutter_${host_os}_gtk.so"
    },
    {
      source = "$root_build_dir/gen_snapshot"
      destination = "gen_snapshot"
    },
  ]
  files = tmp_files
}
''';
      // get_target_outputs() reads the copy through the source tree.
      String convertGtk(String gn) {
        final GnSourceTree tree = sourceTree(<String, String>{
          'flutter/build/zip_bundle.gni': '',
          'flutter/shell/platform/linux/BUILD.gn': gn,
        });
        return emitBuildFile(
          evaluateIn(
            tree,
            '//flutter/shell/platform/linux/BUILD.gn',
            templates: <String>{'zip_bundle'},
          ),
          gnPackage: '//flutter/shell/platform/linux',
          tree: tree,
          forwardedFlags: DependencyResolver(tree: tree, assumptions: linuxHostAssumptions()),
        );
      }

      final String output = convertGtk(gtk);
      expect(
        output,
        contains('''
zip_tree(
    name = "flutter_gtk_publish_headers_linux",
    srcs = [":publish_headers_linux"],
    destination = "",
    root = "engine/src/flutter/shell/platform/linux/public",
)

zip_bundle(
    name = "flutter_gtk",
    files = {
        "libflutter_linux_gtk.so": ":flutter_linux_gtk",
        "gen_snapshot": "//engine/src/flutter/build/bazel/dart_wrap:gen_snapshot",
    },
    output = select({
        "//engine/src/flutter/common:runtime_mode_debug": "linux-x64-debug/linux-x64-flutter-gtk.zip",
        "//engine/src/flutter/common:runtime_mode_profile": "linux-x64-profile/linux-x64-flutter-gtk.zip",
        "//engine/src/flutter/common:runtime_mode_release": "linux-x64-release/linux-x64-flutter-gtk.zip",
        "//engine/src/flutter/common:runtime_mode_jit_release": "linux-x64-jit_release/linux-x64-flutter-gtk.zip",
        "//conditions:default": None,
    }),
    sources = {
        "libflutter_linux_gtk.so": "libflutter_linux_gtk.so",
        "gen_snapshot": "gen_snapshot",
    },
    trees = [":flutter_gtk_publish_headers_linux"],
    deps = [
        ":flutter_linux_gtk",
        ":publish_headers_linux",
        "//engine/src/flutter/build/bazel/dart_wrap:gen_snapshot",
    ],
)
'''),
      );
      expect(output, isNot(contains('tmp_files')));
      // The shapes a tree cannot say: a destination other than the
      // build-directory path, a copy whose outputs are not
      // `$root_out_dir/<dir>/{{source_file_part}}`, a source outside `<dir>`,
      // sources under different roots.
      void Function() variant(String from, String to) {
        expect(gtk, contains(from));
        return () => convertGtk(gtk.replaceFirst(from, to));
      }

      expect(
        variant(r'destination = rebase_path(source, "$root_build_dir")', 'destination = "x.h"'),
        throwsGnError(
          line: 45,
          message: "an entry over a target's outputs must place each at its build-directory path",
        ),
      );
      expect(
        variant(
          r'outputs = [ "$root_out_dir/flutter_linux/{{source_file_part}}" ]',
          r'outputs = [ "$root_out_dir/{{source_file_part}}" ]',
        ),
        throwsGnError(
          line: 45,
          message:
              r'the outputs of //flutter/shell/platform/linux:publish_headers_linux are not '
              r'`$root_out_dir/<dir>/{{source_file_part}}` over its sources',
        ),
      );
      expect(
        variant('"public/flutter_linux/fl_view.h"', '"fl_view.h"'),
        throwsGnError(
          line: 45,
          message:
              'fl_view.h of //flutter/shell/platform/linux:publish_headers_linux does not lie '
              'under a `flutter_linux` directory, as its output does',
        ),
      );
      expect(
        variant('"public/flutter_linux/fl_view.h"', '"other/flutter_linux/fl_view.h"'),
        throwsGnError(
          line: 45,
          message:
              'the sources of //flutter/shell/platform/linux:publish_headers_linux lie under '
              'different roots: engine/src/flutter/shell/platform/linux/other, '
              'engine/src/flutter/shell/platform/linux/public',
        ),
      );
    });

    test('a string expanding a conditional variable has a value per case', () async {
      final GnFileEvaluation evaluation = await evaluate(r'''
executable("tool") {
  suffix = ""
  if (flutter_runtime_mode == "release") {
    suffix = "_product"
  }
  output_name = "tool${suffix}"
  sources = [ "a.cc" ]
}
''');
      final GnTarget target = evaluation.targets.single;
      expect(
        target.variables['output_name']!.cases(target.location).map((GnScalarCase c) => '$c'),
        <String>[
          '[flutter_runtime_mode != "release"] "tool"',
          '[flutter_runtime_mode == "release"] "tool_product"',
        ],
      );
      await expectLater(
        evaluate(r'''
executable("tool") {
  a = ""
  b = ""
  if (flutter_runtime_mode == "release") {
    a = "x"
    b = "y"
  }
  output_name = "tool$a$b"
  sources = [ "a.cc" ]
}
'''),
        throwsGnError(
          line: 8,
          message: 'more than one variable with conditional values in one string',
        ),
      );
    });

    test('a helper variable of a target block is ignored', () async {
      // The embedder's flutter_engine group.
      final String output = await convert('''
group("flutter_engine") {
  deps = []
  build_embedder_api = current_toolchain == host_toolchain || is_win
  if (build_embedder_api) {
    deps += [ ":a" ]
  }
}
''');
      expect(output, contains('deps = [\n        ":a",  # build_embedder_api\n    ],'));
      expect(output, isNot(contains('build_embedder_api =')));
    });

    test('secondary source root: a BUILD.gn stands in for another directory', () {
      // wuffs: its BUILD.gn lives in //flutter/build/secondary.
      final GnSourceTree tree = sourceTree(<String, String>{
        '.gn':
            'buildconfig = "//BUILDCONFIG.gn"\nsecondary_source = "//flutter/build/secondary/"\n',
        'lib/lists.gni': 'lib_sources = [ "a.c" ]\n',
        'flutter/build/secondary/flutter/third_party/wuffs/BUILD.gn': '''
import("//lib/lists.gni")
import("//flutter/build/secondary/flutter/third_party/wuffs/more.gni")

config("wuffs_config") {
  include_dirs = [
    "release/c",
    "//flutter/build/secondary/flutter/third_party/wuffs/config",
  ]
  cflags = [
    "-Wno-unused-function",
    "-Wno-c++11-narrowing",
  ]
}

source_set("wuffs") {
  sources = lib_sources + more_sources
  public_configs = [ ":wuffs_config" ]
}
''',
        'flutter/build/secondary/flutter/third_party/wuffs/more.gni': 'more_sources = [ "b.c" ]\n',
      });
      expect(tree.secondarySource, '//flutter/build/secondary');
      final String file = tree.resolve('//flutter/third_party/wuffs/BUILD.gn');
      expect(file, endsWith('flutter/build/secondary/flutter/third_party/wuffs/BUILD.gn'));
      expect(tree.gnDirectory(file), '//flutter/third_party/wuffs');
      final GnFileEvaluation evaluation = evaluateIn(
        tree,
        '//flutter/third_party/wuffs/BUILD.gn',
        importPolicy: const ImportPolicy(
          evaluatedPrefixes: <String>{'//lib/', '//flutter/build/secondary/'},
        ),
      );
      expect(strings(evaluation.targets[1], 'sources'), <String>['a.c', 'b.c']);
      // Files beside the secondary BUILD.gn are mirrored into the repository.
      final String output = emitBuildFile(
        evaluation,
        gnPackage: '//flutter/third_party/wuffs',
        layout: OutputLayout.repository(
          '@wuffs',
          repositoryGnRoot: '//flutter/third_party/wuffs',
          secondarySource: tree.secondarySource,
        ),
      );
      // In GN's order -- the compiler's search order -- which buildifier
      // would reverse, so the list says not to.
      expect(
        output,
        contains(
          'includes = [\n        # do not sort\n        "release/c",\n        "config",\n    ],',
        ),
      );
    });

    test(
      "include_dirs keep GN's order, marked for buildifier when it is not buildifier's",
      () async {
        // freetype2: the directory with Flutter's public-macros.h (which hides
        // the API) ahead of the stock headers; sorted, the stock file wins.
        final String overriding = await convert('''
config("freetype_config") {
  include_dirs = [
    "include/freetype-flutter-config",
    "include",
  ]
}
''');
        expect(
          overriding,
          contains(
            'includes = [\n        # do not sort\n        "include/freetype-flutter-config",\n        "include",\n    ],',
          ),
        );
        // Already in buildifier's order: no mark.
        final String sorted = await convert('''
config("c") {
  include_dirs = [
    "include",
    "include/private",
  ]
}
''');
        expect(
          sorted,
          contains('includes = [\n        "include",\n        "include/private",\n    ],'),
        );
        expect(sorted, isNot(contains('do not sort')));
      },
    );

    test("an executable's include_dirs ride a helper library", () async {
      final String output = await convert('''
executable("tool") {
  sources = [ "tool.cc" ]
  include_dirs = [ "grpc" ]
}
''');
      expect(
        output,
        contains('''
cc_library(
    name = "tool_include_dirs",
    includes = ["grpc"],
)

cc_binary(
    name = "tool",
    srcs = ["tool.cc"],
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        ":tool_include_dirs",
        "//engine/src:include_root",
    ],
)
'''),
      );
    });

    test('copy() becomes a gn_copy that records the destination', () async {
      expect(
        await convert(r'''
copy("shaders") {
  sources = [
    "a.glsl",
    "b.glsl",
  ]
  outputs = [ "$root_out_dir/shader_lib/{{source_file_part}}" ]
}
'''),
        contains(r'''
load("//build_defs/gn:gn_action.bzl", "gn_copy")

package(default_visibility = ["//visibility:public"])

gn_copy(
    name = "shaders",
    srcs = [
        "a.glsl",
        "b.glsl",
    ],
    outputs = ["$root_out_dir/shader_lib/{{source_file_part}}"],
)
'''),
      );
    });

    test('a copy relocating its sources under the gen dir produces them; a test reads them '
        'as data; a config local; a header-only library keeps its link flags', () async {
      // The GTK shell: the compiled GSettings schemas are copied to
      // assets/<name>/gschemas.compiled (GN's {{source_name_part}}), the
      // suite depends on the copy and reads the file at run time, the
      // disable_warnings config computes its flags in a local that GN's
      // unused-variable rule accepts because the block reads it, and
      // flutter_linux (no sources) lists the epoxy config, whose -lepoxy
      // the shared library's link needs.
      final String output = await convert(r'''
config("epoxy") {
  libs = [ "epoxy" ]
}

config("disable_warnings") {
  warning_flags = [ "-Wno-deprecated-volatile" ]
  cflags = warning_flags
  cflags_cc = warning_flags
}

source_set("sources") {
  sources = [ "a.cc" ]
  configs += [ ":disable_warnings" ]
}

source_set("shell") {
  configs += [ ":epoxy" ]
  public_deps = [ ":sources" ]
}

copy("gschemas") {
  testonly = true
  sources = [ "testing/gschemas/ubuntu-20.04.compiled" ]
  outputs = [ "$root_gen_dir/flutter/example/assets/{{source_name_part}}/gschemas.compiled" ]
}

executable("shell_unittests") {
  testonly = true
  sources = [ "a_test.cc" ]
  deps = [
    ":gschemas",
    ":sources",
  ]
}
''');
      expect(
        output,
        contains(
          'gn_copy(\n    name = "gschemas",\n    testonly = True,\n'
          '    srcs = ["testing/gschemas/ubuntu-20.04.compiled"],\n'
          '    outs = ["assets/ubuntu-20.04/gschemas.compiled"],\n'
          '    outputs = ["\$root_gen_dir/flutter/example/assets/{{source_name_part}}/gschemas.compiled"],\n)\n',
        ),
      );
      expect(output, contains('    data = [":gschemas"],\n'));
      expect(
        output,
        contains('    deps = [\n        ":sources",\n        "//engine/src:include_root",\n'),
      );
      // The local is nothing of the config's own; the flags are inlined in
      // the target that lists it.
      expect(output, contains('cc_library(\n    name = "disable_warnings",\n)\n'));
      expect(output, contains('    cxxopts = ["-Wno-deprecated-volatile"],\n'));
      // The header-only shell keeps the epoxy config's library (inlined, as
      // a private config of this file is) for the links that reach it.
      expect(
        output,
        contains(
          'cc_library(\n    name = "shell",\n    linkopts = ["-lepoxy"],\n'
          '    deps = [":sources"],\n)\n',
        ),
      );
    });

    test('a dependency on a snapshot template of the same file is data', () async {
      // //flutter/testing's fixture_test: in the profile mode its public_deps
      // name the VM service's AOT snapshot, whose ELF the fixtures load at
      // run time; the macro's target is files, not a library. (GN's
      // $target_gen_dir spelled out: the harness has no source tree.)
      final String output = await convert(
        r'''
dart_snapshot_kernel("vmservice_kernel") {
  dart_main = "fixtures/empty.dart"
  dart_kernel = "$root_gen_dir/flutter/example/assets/vmservice_kernel.bin"
}

dart_snapshot_aot("vmservice_snapshot") {
  dart_kernel = "$root_gen_dir/flutter/example/assets/vmservice_kernel.bin"
  dart_elf_filename = "libvmservice_snapshot.so"
  deps = [ ":vmservice_kernel" ]
}

source_set("fixture_test") {
  testonly = true
  sources = [ "fixture_test.cc" ]
  public_deps = [ "//flutter/common" ]
  if (flutter_runtime_mode == "profile") {
    public_deps += [ ":vmservice_snapshot" ]
  }
}
''',
        templates: <String>{'dart_snapshot_kernel', 'dart_snapshot_aot'},
      );
      expect(
        output,
        contains(
          'flutter_dart_snapshot_aot(\n    name = "vmservice_snapshot",\n'
          '    dart_elf_filename = "libvmservice_snapshot.so",\n'
          '    dart_kernel = "assets/vmservice_kernel.bin",\n'
          '    deps = [":vmservice_kernel"],\n)\n',
        ),
      );
      expect(
        output,
        contains(
          '    data = select({\n'
          '        "//engine/src/flutter/common:runtime_mode_profile": [\n'
          '            ":vmservice_snapshot",  # flutter_runtime_mode == "profile"\n'
          '        ],\n'
          '        "//conditions:default": [],\n'
          '    }),\n',
        ),
      );
      expect(
        output,
        contains(
          '    deps = [\n        "//engine/src:include_root",\n        "//engine/src/flutter/common",\n    ],\n',
        ),
      );
    });

    test('a template invocation maps its files, labels, configs and scalars', () async {
      // The flatbuffers template's public config carries two generated
      // include directories: the package's own (the `includes` of the
      // config's library span the output tree too) and //flutter's, which
      // is the target whose `includes` already name that directory.
      final String output = await convert(
        r'''
config("schema_config") {
  include_dirs = [
    "$root_gen_dir/flutter",
    "$root_gen_dir/flutter/example",
    "include",
  ]
}

source_set("other") {
  sources = [ "other.cc" ]
}

flatbuffers("schema") {
  testonly = true
  flatbuffers = [ "schema.fbs" ]
  public_configs = [ ":schema_config" ]
  public_deps = [ "//flutter/third_party/flatbuffers" ]
  deps = [ ":other" ]
}
''',
        templates: <String>{'flatbuffers'},
      );
      expect(
        output,
        contains('''
load("@rules_cc//cc:defs.bzl", "cc_library")
load("//build_defs/cc:copts.bzl", "CHROMIUM_CODE_COPTS", "FLUTTER_LOCAL_DEFINES")
load("//build_defs/flatbuffers:flatbuffers.bzl", "flatbuffers")
'''),
      );
      expect(
        output,
        contains('''
cc_library(
    name = "schema_config",
    includes = [
        ".",
        "include",
    ],
    deps = ["//engine/src/flutter:config"],
)
'''),
      );
      expect(
        output,
        contains('''
flatbuffers(
    name = "schema",
    testonly = True,
    flatbuffers = ["schema.fbs"],
    deps = [
        ":other",
        ":schema_config",
        "@flatbuffers",
    ],
)
'''),
      );
      await expectLater(
        convert(
          '''
flatbuffers("schema") {
  flatbuffers = [ "schema.fbs" ]
  public_configs = [ "//build/config:mystery" ]
}
''',
          templates: <String>{'flatbuffers'},
        ),
        throwsGnError(line: 3, message: 'no Bazel dependency mapping for a flatbuffers macro'),
      );
    });

    test('an impeller_shaders invocation becomes the macro call', () async {
      // GN's `name` is the library name; a condition the assumptions decide
      // folds (is_linux), one they refute vanishes (metal_version under
      // is_mac).
      final String output = await convert(
        '''
impeller_shaders("entity_shaders") {
  name = "entity"
  if (is_linux) {
    vulkan_language_version = 130
  }
  if (is_mac && !is_ios) {
    metal_version = "2.3"
  }
  use_half_textures = true
  shaders = [
    "shaders/solid_fill.vert",
    "shaders/blending/advanced_blend.frag",
  ]
}
''',
        templates: <String>{'impeller_shaders'},
      );
      expect(
        output,
        contains('''
load("//build_defs/impeller:shaders.bzl", "impeller_shaders")

package(default_visibility = ["//visibility:public"])

impeller_shaders(
    name = "entity_shaders",
    library_name = "entity",
    shaders = [
        "shaders/solid_fill.vert",
        "shaders/blending/advanced_blend.frag",
    ],
    use_half_textures = True,
    vulkan_language_version = 130,
)
'''),
      );
      expect(
        templateMappings['impeller_shaders']!.innerTargetsOf('entity_shaders'),
        containsAll(<String>[
          'vk_entity_shaders',
          'impellerc_gles3_entity_shaders',
          'reflect_reflect_gles_entity_shaders',
        ]),
      );
    });

    test('a file of another package is labelled through it', () async {
      // The layout knows the main repository's packages; a fixture under
      // //flutter/txt is //engine/src/flutter/txt's file.
      const layout = OutputLayout.main(
        packages: <String>{'engine/src/flutter/txt', 'engine/src/flutter/example'},
      );
      expect(
        await convert('''
test_fixtures("fixtures") {
  fixtures = [
    "//flutter/txt/third_party/fonts/Roboto-Regular.ttf",
    "data/local.txt",
  ]
}
''', layout: layout),
        contains('''
flutter_test_fixtures(
    name = "fixtures",
    fixtures = [
        "data/local.txt",
        "//engine/src/flutter/txt:third_party/fonts/Roboto-Regular.ttf",
    ],
)
'''),
      );
      await expectLater(
        convert('''
test_fixtures("fixtures") {
  fixtures = [ "//flutter/elsewhere/font.ttf" ]
}
''', layout: layout),
        throwsGnError(line: 2, message: 'outside the package of the generated file'),
      );
    });

    test(
      "a file of the machine under host_os == \"mac\" is a host file under the host's setting",
      () async {
        // txt's and impeller/fixtures' test_fixtures copy a Mac's emoji font
        // by its absolute path under `host_os == "mac"`. With host_os a cased
        // value (the manifest's hostOsCases for those files), the comparison
        // is the host's setting and the file is @host_files' (a repository
        // of the machine's files GN names, present where they exist); any
        // other absolute path is an error. In the generation's own scope
        // host_os is a string and the branch folds away.
        const gn = '''
test_fixtures("fixtures") {
  fixtures = [ "data/local.txt" ]
  if (host_os == "mac") {
    fixtures += [ "/System/Library/Fonts/Apple Color Emoji.ttc" ]
  }
}
''';
        expect(
          await convert(gn, assumptions: Assumptions(hostOsCases)),
          contains('''
flutter_test_fixtures(
    name = "fixtures",
    fixtures = ["data/local.txt"] + select({
        "//engine/src/flutter/build/bazel:host_os_is_mac": [
            "@host_files//:System/Library/Fonts/Apple Color Emoji.ttc",  # host_os == "mac"
        ],
        "//conditions:default": [],
    }),
)
'''),
        );
        expect(
          await convert(
            gn,
            assumptions: Assumptions(const <String, GnValue>{'host_os': GnStringValue('linux')}),
          ),
          contains('''
flutter_test_fixtures(
    name = "fixtures",
    fixtures = ["data/local.txt"],
)
'''),
        );
        await expectLater(
          convert('''
test_fixtures("fixtures") {
  fixtures = [ "/Library/Fonts/Other.ttf" ]
}
'''),
          throwsGnError(line: 2, message: 'not among the host files'),
        );
      },
    );

    test('a relative path with .. resolves as GN resolves it', () async {
      // tonic's suite lists ../file_loader/file_loader_unittests.cc, a file
      // of the parent package; a Dart entry point is a single file.
      const layout = OutputLayout.main(
        packages: <String>{'engine/src/flutter', 'engine/src/flutter/example'},
      );
      final String output = await convert('''
test_fixtures("fixtures") {
  dart_main = "fixtures/main.dart"
  use_target_as_artifact_prefix = true
}
executable("example_unittests") {
  testonly = true
  sources = [
    "../file_loader/file_loader_unittests.cc",
    "sub/../local_unittest.cc",
  ]
}
''', layout: layout);
      expect(
        output,
        contains('''
flutter_test_fixtures(
    name = "fixtures",
    dart_main = "fixtures/main.dart",
    use_target_as_artifact_prefix = True,
)
'''),
      );
      expect(
        output,
        contains('''
    srcs = [
        "local_unittest.cc",
        "//engine/src/flutter:file_loader/file_loader_unittests.cc",
    ],
'''),
      );
      await expectLater(
        convert('''
source_set("x") {
  sources = [ "../../../../escape.cc" ]
}
'''),
        throwsGnError(line: 2, message: 'leaves the source root'),
      );
    });

    test("test_fixtures' dest names the package whose assets receive the files", () async {
      // lib/ui's shader fixtures: `dest = "$root_gen_dir/flutter/lib/ui"`,
      // the generated twin of a package the layout knows.
      const layout = OutputLayout.main(
        packages: <String>{'engine/src/flutter/lib/ui', 'engine/src/flutter/lib/ui/shaders'},
      );
      expect(
        await convert(
          r'''
impellerc("stages") {
  shaders = [ "a.frag" ]
  shader_target_flags = [ "--sksl" ]
  intermediates_subdir = "iplr"
  sl_file_extension = "iplr"
  iplr = true
}
test_fixtures("fixtures") {
  deps = [ ":stages" ]
  fixtures = get_target_outputs("//flutter/lib/ui/shaders:stages")
  dest = "$root_gen_dir/flutter/lib/ui"
}
''',
          gnPackage: '//flutter/lib/ui/shaders',
          layout: layout,
          templates: <String>{'test_fixtures', 'impellerc'},
        ),
        contains('''
flutter_test_fixtures(
    name = "fixtures",
    dest = "//engine/src/flutter/lib/ui",
    fixtures_targets = {":stages": []},
    deps = [":stages"],
)
'''),
      );
      await expectLater(
        convert(
          r'''
test_fixtures("fixtures") {
  fixtures = [ "a.png" ]
  dest = "$root_gen_dir/flutter/lib/ui/nowhere"
}
''',
          gnPackage: '//flutter/lib/ui/shaders',
          layout: layout,
        ),
        throwsGnError(line: 3, message: 'not a package the layout knows'),
      );
    });

    test('a copy() that renames its file produces the copy under the new name', () async {
      // general_shaders' no_uniforms_alt: a literal output (no {{source...}}
      // expansion) under the target_gen_dir is the point of the copy.
      expect(
        await convert(r'''
copy("alt") {
  sources = [ "$root_gen_dir/flutter/example/iplr/a.frag.iplr" ]
  outputs = [ "$root_gen_dir/flutter/example/iplr/alt.frag.iplr" ]
  deps = [ ":compile" ]
}
'''),
        contains(r'''
gn_copy(
    name = "alt",
    srcs = ["iplr/a.frag.iplr"],
    outs = ["iplr/alt.frag.iplr"],
    outputs = ["$root_gen_dir/flutter/example/iplr/alt.frag.iplr"],
    deps = [":compile"],
)
'''),
      );
    });

    test('a private config of another file is an implementation dependency', () async {
      // `../skia:skia_private` names a sibling directory's config; as a
      // private config its library applies to this target's compiles only.
      // The implicit name of a directory label is the directory's.
      expect(absoluteGnLabel('../../:x', package: '//a/b/c'), '//a:x');
      expect(absoluteGnLabel('../base', package: '//a/b', implicitName: true), '//a/base:base');
      expect(absoluteGnLabel(':x', package: '//a/b'), '//a/b:x');
      final String output = await convert('''
source_set("x") {
  sources = [ "a.cc" ]
  configs += [ "../skia:skia_private" ]
  public_configs = [ "//flutter/impeller:impeller_public_config" ]
}

source_set("headers") {
  sources = [ "b.h" ]
  configs += [ "../skia:skia_private" ]
}
''');
      expect(
        output,
        contains('''
    implementation_deps = ["@skia//:skia_private"],
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        "//engine/src:include_root",
        "//engine/src/flutter/impeller:impeller_public_config",
    ],
    alwayslink = True,
)
'''),
      );
      // A header-only library compiles nothing for the config's defines to
      // apply to; the config stays for its link flags (implementation_deps
      // carries those on to the binaries), which reach dependents' links
      // in GN whether or not the target compiles.
      expect(
        output,
        contains(
          'cc_library(\n    name = "headers",\n    hdrs = ["b.h"],\n'
          '    implementation_deps = ["@skia//:skia_private"],\n)\n',
        ),
      );
    });

    test('output_name on a source_set is ignored; an import inside a target', () async {
      expect(
        await convert('''
source_set("x") {
  output_name = "libx"
  sources = [ "a.cc" ]
}
'''),
        contains('name = "x"'),
      );
      // GN brings a .gni's variables into the block's scope; a file already
      // imported at file level changes nothing, any other is refused.
      final GnSourceTree tree = sourceTree(<String, String>{
        'lib/lists.gni': 'example_sources = [ "a.cc" ]\n',
        'lib/other.gni': 'other_sources = [ "b.cc" ]\n',
        'pkg/BUILD.gn': '''
import("//lib/lists.gni")

source_set("x") {
  import("//lib/lists.gni")
  sources = example_sources
}
''',
        'bad/BUILD.gn': '''
source_set("x") {
  import("//lib/other.gni")
  sources = other_sources
}
''',
      });
      final GnFileEvaluation evaluation = evaluateIn(tree, '//pkg/BUILD.gn');
      expect(strings(evaluation.targets.single, 'sources'), <String>['a.cc']);
      expect(
        () => evaluateIn(tree, '//bad/BUILD.gn'),
        throwsGnError(line: 2, message: 'import of //lib/other.gni inside a target'),
      );
    });

    test('generated and foreign include directories', () async {
      // The root of the generated tree is the engine's include root; a
      // directory of another repository comes with the dependency on it.
      expect(
        await convert(r'''
source_set("x") {
  sources = [ "a.cc" ]
  include_dirs = [
    "$root_gen_dir",
    "//flutter/third_party/vulkan-deps/spirv-cross/src/",
  ]
  deps = [ "//third_party/spirv_cross_flutter" ]
}
'''),
        contains('''
# include_dirs: @spirv-cross// comes with the dependency on @spirv-cross.
cc_library(
    name = "x",
    srcs = ["a.cc"],
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        "//engine/src:include_root",
        "@spirv-cross//:spirv_cross_flutter",
    ],
    alwayslink = True,
)
'''),
      );
      // Another package's generated directory has no target to stand for
      // it.
      await expectLater(
        convert(r'''
source_set("x") {
  sources = [ "a.cc" ]
  include_dirs = [ "$root_gen_dir/flutter/elsewhere" ]
}
'''),
        throwsGnError(line: 3, message: 'outside the package of the generated file'),
      );
    });

    test('rejects what it cannot express', () async {
      // Flags and defines on a header-only target apply to nothing, in GN as
      // here.
      expect(
        await convert('''
source_set("headers") {
  sources = [ "a.h" ]
  defines = [ "UNUSED" ]
  cflags = [ "-Wall" ]
}
'''),
        contains('cc_library(\n    name = "headers",\n    hdrs = ["a.h"],\n)\n'),
      );
      await expectLater(
        convert('''
source_set("x") {
  sources = [ "a.cc" ]
  deps = [ "//third_party/somewhere:else" ]
}
'''),
        throwsGnError(line: 3, message: 'no Bazel home for label //third_party/somewhere:else'),
      );
      await expectLater(
        convert('''
source_set("x") {
  sources = [ "a.cc" ]
  configs += [ "//build/config:mystery" ]
}
'''),
        throwsGnError(line: 3, message: 'config //build/config:mystery has no Bazel mapping'),
      );
      await expectLater(
        convert('''
action_foreach("x") {
  script = "x.py"
  sources = [ "a.txt" ]
  outputs = [ "x.h" ]
}
'''),
        throwsGnError(line: 1, message: 'action_foreach() is not converted yet'),
      );
    });

    test(
      "a shared_library is a flutter_shared_library under GN's name, named by its output",
      () async {
        // The macro (build_defs/cc/shared_library.bzl) declares the
        // platform's file -- lib<output_name>.so off the Apple platforms,
        // lib<output_name>.dylib on them -- and GN's name as an alias.
        final String output = await convert('''
shared_library("x_shared") {
  output_name = "x"
  sources = [ "a.cc" ]
  deps = [ ":y" ]
}
source_set("y") {
  sources = [ "y.cc" ]
}
''');
        expect(
          output,
          contains('''
flutter_shared_library(
    name = "x_shared",
    srcs = ["a.cc"],
    copts = CHROMIUM_CODE_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    output_name = "x",
    deps = [
        ":y",
        "//engine/src:include_root",
        "//engine/src/flutter/build/bazel/toolchains:cxx_runtime",
    ],
)
'''),
        );
        expect(
          output,
          contains('load("//build_defs/cc:shared_library.bzl", "flutter_shared_library")'),
        );
        expect(output, isNot(contains('alias(')));
        // Without output_name the target's own name is the library's.
        expect(
          await convert('''
shared_library("z") {
  sources = [ "a.cc" ]
}
'''),
          contains(
            '    name = "z",\n    srcs = ["a.cc"],\n    copts = CHROMIUM_CODE_COPTS,\n    local_defines = FLUTTER_LOCAL_DEFINES,\n    output_name = "z",\n',
          ),
        );
        // A library named like the shared library's output would declare the
        // same libw.so; it gives the implicit output up.
        final String clash = await convert('''
source_set("w") {
  sources = [ "w.cc" ]
}
shared_library("w_shared") {
  output_name = "w"
  sources = [ "a.cc" ]
  deps = [ ":w" ]
}
''');
        expect(clash, contains('    name = "w",\n    srcs = ["w.cc"],\n'));
        expect(clash, contains('    linkstatic = True,\n'));
        expect(clash, contains('    name = "w_shared",\n'));
      },
    );

    test(
      r'an ldflags entry naming a source file becomes $(execpath) with a linker input',
      () async {
        // The embedder's shared library and its version script.
        final GnSourceTree tree = sourceTree(<String, String>{
          'flutter/example/exports.lst': '',
          'flutter/example/BUILD.gn': r'''
shared_library("x") {
  sources = [ "a.cc" ]
  ldflags = [ "-Wl,--version-script=" + rebase_path("exports.lst", root_build_dir) ]
}
''',
        });
        final String output = emitBuildFile(
          evaluateIn(tree, '//flutter/example/BUILD.gn'),
          gnPackage: '//flutter/example',
          tree: tree,
        );
        expect(output, contains('    additional_linker_inputs = [":exports.lst"],\n'));
        expect(
          output,
          contains('    linkopts = ["-Wl,--version-script=\$(execpath :exports.lst)"],\n'),
        );
      },
    );

    test(
      "a config's locals carry nothing; a define names a generated file by its run-time path",
      () async {
        // The embedder's embedder_jit_snapshot_setup: four paths computed in
        // `_`-prefixed locals from get_label_info(..., "target_gen_dir"), which
        // the test joins with GetSourcePath() (Bazel's: engine/src/).
        final GnSourceTree tree = sourceTree(<String, String>{
          'flutter/example/BUILD.gn': r'''
config("jit") {
  _label = "//flutter/lib/snapshot:vm_isolate_snapshot.bin"
  _dir = get_label_info(_label, "target_gen_dir")
  _data = "${_dir}/isolate_snapshot.bin"
  defines = [ "TEST_DATA=\"${_data}\"" ]
}

executable("x_unittests") {
  testonly = true
  sources = [ "a.cc" ]
  configs += [ ":jit" ]
}
''',
        });
        final String output = emitBuildFile(
          evaluateIn(tree, '//flutter/example/BUILD.gn'),
          gnPackage: '//flutter/example',
          tree: tree,
        );
        expect(
          output,
          contains(r'''
cc_library(
    name = "jit",
    defines = ["TEST_DATA=\\\"flutter/lib/snapshot/isolate_snapshot.bin\\\""],
)
'''),
        );
        expect(
          output,
          contains(
            r'    local_defines = FLUTTER_LOCAL_DEFINES + ["TEST_DATA=\\\"flutter/lib/snapshot/isolate_snapshot.bin\\\""],'
            '\n',
          ),
        );
        expect(output, isNot(contains('_dir')));
      },
    );
  });

  group('builders', () {
    // Builder files of the shapes ci/builders/linux_*.json has: a build
    // whose flags all map, one with a flag the Bazel build cannot express,
    // one of another platform, and ninja targets in each of GN's spellings.
    Map<String, BuilderConfig> configs(Map<String, String> files) {
      final Directory root = Directory.systemTemp.createTempSync('gn_to_bazel_builders');
      addTearDown(() => root.deleteSync(recursive: true));
      for (final MapEntry<String, String> file in files.entries) {
        File(p.join(root.path, file.key)).writeAsStringSync(file.value);
      }
      final loader = BuildConfigLoader(buildConfigsDir: root);
      final Map<String, BuilderConfig> loaded = loader.configs;
      expect(loader.errors, isEmpty);
      return loaded;
    }

    String build(
      String name,
      String gn,
      List<String> ninja, {
      List<String> archives = const <String>[],
      String tests = '',
    }) {
      return '''
{
  "name": "$name",
  "gn": [${gn.split(' ').where((String s) => s.isNotEmpty).map((String s) => '"$s"').join(', ')}],
  "ninja": {"config": "$name", "targets": [${ninja.map((String s) => '"$s"').join(', ')}]},
  "archives": [${archives.isEmpty ? '' : '{"name": "$name", "base_path": "out/$name/zip_archives/", "type": "gcs", "include_paths": [${archives.map((String s) => '"$s"').join(', ')}], "realm": "production"}'}],
  "tests": [$tests],
  "drone_dimensions": ["os=Linux"],
  "gclient_variables": {}
}''';
    }

    String runTests(String name, String types) {
      return '{"name": "$name", "language": "python3", "script": "flutter/testing/run_tests.py", '
          '"parameters": ["--variant", "x", "--type", "$types"], "contexts": []}';
    }

    test('maps flags to configurations and ninja targets to install targets', () {
      final Map<String, BuilderConfig> loaded = configs(<String, String>{
        'linux_host_engine.json':
            '''
{"builds": [
  ${build('ci/host_debug', '--target-dir ci/host_debug --runtime-mode debug --prebuilt-dart-sdk --no-lto --rbe --no-goma', <String>['flutter/build/archives:artifacts', 'flutter/tools/font_subset', 'sky_engine', 'flutter', 'flutter:unittests'], archives: <String>['out/ci/host_debug/zip_archives/linux-x64/artifacts.zip'])},
  ${build('ci/host_release', '--target-dir ci/host_release --runtime-mode=release --prebuilt-dart-sdk --no-lto', <String>['flutter/build/archives:flutter_patched_sdk'])},
  ${build('ci/host_debug_test', '--target-dir ci/host_debug_test --runtime-mode debug --prebuilt-dart-sdk --no-lto', <String>['flutter:unittests'], tests: '${runTests('Host Tests', 'dart,dart-host,engine,impeller-golden')}, {"name": "Lint", "language": "bash", "script": "flutter/ci/lint.sh", "parameters": [], "contexts": []}, {"name": "Tests of tools/gn", "language": "python3", "script": "flutter/tools/gn_test.py", "parameters": [], "contexts": []}')},
  ${build('ci/host_debug_unopt', '--runtime-mode debug --unoptimized --asan --dart-debug', <String>['flutter/tools/font_subset', 'flutter/fml:fml_unittests'])},
  ${build('ci/host_profile_lto', '--runtime-mode profile --prebuilt-dart-sdk', <String>['flutter/tools/font_subset'])},
  ${build('ci/android_debug', '--android --no-lto', <String>['flutter'])},
  ${build('ci/android_debug_x86', '--android --android-cpu=x86 --no-lto', <String>['flutter'])},
  ${build('ci/android_debug_arm64', '--target-dir ci/android_debug_arm64 --android --android-cpu=arm64 --no-lto --rbe --no-goma', <String>['flutter', 'flutter/shell/platform/android:abi_jars', 'flutter/shell/platform/embedder:embedder-archive'], archives: <String>['out/ci/android_debug_arm64/zip_archives/android-arm64/symbols.zip'])},
  ${build('ci/host_release_licenses', '--target-dir ci/host_release_licenses --runtime-mode release --no-lto --rbe --no-goma', <String>['flutter/tools/licenses_cpp', 'flutter/tools/licenses_cpp:licenses_cpp_testrunner'], tests: '{"name": "Run license_cpp unittests", "script": "out/ci/host_release_licenses/licenses_cpp_testrunner"}, {"name": "Run another runner", "script": "out/ci/host_release_licenses/other_testrunner"}')}
]}''',
        'mac_host_engine.json':
            '{"builds": [${build('ci/mac_host', '--runtime-mode debug --no-lto', <String>['flutter'])}]}',
        // Linux arm64: --target-os=linux --linux-cpu=arm64 is the arm64
        // platform (a Linux toolchain: --no-lto as the host's); another
        // --target-os is out of scope.
        'linux_arm_host_engine.json':
            '''
{"builds": [
  ${build('ci/linux_debug_arm64', '--target-dir ci/linux_debug_arm64 --runtime-mode debug --target-os=linux --linux-cpu=arm64 --prebuilt-dart-sdk --no-lto --rbe --no-goma', <String>['flutter/build/archives:artifacts'], archives: <String>['out/ci/linux_debug_arm64/zip_archives/linux-arm64/artifacts.zip'])},
  ${build('ci/fuchsia_debug_x64', '--target-os=fuchsia --fuchsia-cpu=x64 --runtime-mode debug --no-lto', <String>['flutter/shell/platform/fuchsia:fuchsia'])}
]}''',
        // The web: --web is the wasm platform, whose optimized build links
        // with LTO as GN's does (so --no-lto is what it cannot express).
        'linux_web_engine_build.json':
            '''
{"builds": [
  ${build('ci/wasm_release', '--web --runtime-mode=release --no-rbe --no-goma', <String>['flutter/web_sdk:flutter_web_sdk_archive'], archives: <String>['out/wasm_release/zip_archives/flutter-web-sdk.zip'])},
  ${build('ci/wasm_profile', '--web --runtime-mode=profile --no-lto', <String>['flutter/web_sdk:flutter_web_sdk_archive'])}
]}''',
        // The developer's configurations: linux/wasm_release sets what
        // ci/wasm_release sets (one configuration); linux/host_debug's
        // --no-stripped (the stripped setting off) parts it from
        // ci/host_debug's; macos/host_debug is the Mac's, after the Linux
        // builds, and keeps its OS beside Linux's host_debug.
        'local_engine.json':
            '''
{"builds": [
  ${build('linux/host_debug', '--runtime-mode debug --no-stripped --no-lto --rbe --no-goma', <String>[])},
  ${build('linux/host_debug_unopt', '--runtime-mode debug --unopt --no-stripped --no-lto', <String>[])},
  ${build('linux/wasm_release', '--web --runtime-mode=release --no-rbe --no-goma', <String>['flutter/web_sdk:flutter_web_sdk_archive'])},
  ${build('linux/wasm_debug_unopt', '--web --runtime-mode=debug --unoptimized --no-rbe --no-goma', <String>['flutter/web_sdk:flutter_web_sdk_archive'])},
  ${build('linux/android_debug_arm64', '--runtime-mode debug --android --android-cpu=arm64 --no-stripped --no-lto --rbe --no-goma', <String>[])},
  ${build('macos/host_debug', '--runtime-mode debug --no-stripped --no-lto --xcode-symlinks', <String>[])}
]}''',
      });
      final List<BuilderBuild> builds = builderBuilds(loaded);
      // CI's host_debug_unopt sets flags the developer's does not (asan, a
      // Debug VM): the developer's keeps the bare name, CI's its prefix.
      expect(builds.map((BuilderBuild b) => b.configName), <String>[
        'linux_debug_arm64',
        'ci_host_debug',
        'host_release',
        'host_debug_test',
        'ci_host_debug_unopt',
        'host_profile_lto',
        'android_debug',
        'android_debug_x86',
        'android_debug_arm64',
        'host_release_licenses',
        'wasm_release',
        'wasm_profile',
        'host_debug',
        'host_debug_unopt',
        'wasm_release',
        'wasm_debug_unopt',
        'android_debug_arm64',
        'mac_host',
        'mac_host_debug',
      ]);
      expect(
        configsBazelrc(builds),
        contains('''
# linux_arm_host_engine.json: ci/linux_debug_arm64
#   --target-dir ci/linux_debug_arm64 --runtime-mode debug --target-os=linux --linux-cpu=arm64 --prebuilt-dart-sdk --no-lto --rbe --no-goma
build:linux_debug_arm64 --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug --platforms=//engine/src/flutter/build/bazel/toolchains:linux_arm64

# linux_host_engine.json: ci/host_debug
#   --target-dir ci/host_debug --runtime-mode debug --prebuilt-dart-sdk --no-lto --rbe --no-goma
build:ci_host_debug --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug

# linux_host_engine.json: ci/host_release
#   --target-dir ci/host_release --runtime-mode=release --prebuilt-dart-sdk --no-lto
build:host_release --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=release

# linux_host_engine.json: ci/host_debug_test
#   --target-dir ci/host_debug_test --runtime-mode debug --prebuilt-dart-sdk --no-lto
build:host_debug_test --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug

# linux_host_engine.json: ci/host_debug_unopt
#   --runtime-mode debug --unoptimized --asan --dart-debug
build:ci_host_debug_unopt --compilation_mode=dbg --//engine/src/flutter/common:runtime_mode=debug --//engine/src/flutter/build/bazel:asan --test_timeout=240,1200,3600,14400 --//engine/src/flutter/build/bazel/dart_wrap:dart_debug

# linux_host_engine.json: ci/host_profile_lto
#   --runtime-mode profile --prebuilt-dart-sdk
build:host_profile_lto --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=profile --//engine/src/flutter/build/bazel:lto

# linux_host_engine.json: ci/android_debug
#   --android --no-lto
build:android_debug --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug --platforms=//engine/src/flutter/build/bazel/toolchains:android_arm --//engine/src/flutter/build/bazel:stripped=false

# linux_host_engine.json: ci/android_debug_x86
#   --android --android-cpu=x86 --no-lto
# No configuration: the Bazel build cannot express
#   --android-cpu=x86 (the Bazel build has Android arm and arm64 and riscv64 and x64 platforms only)

# linux_host_engine.json: ci/android_debug_arm64
#   --target-dir ci/android_debug_arm64 --android --android-cpu=arm64 --no-lto --rbe --no-goma
build:android_debug_arm64 --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug --platforms=//engine/src/flutter/build/bazel/toolchains:android_arm64 --//engine/src/flutter/build/bazel:stripped=false

# linux_host_engine.json: ci/host_release_licenses
#   --target-dir ci/host_release_licenses --runtime-mode release --no-lto --rbe --no-goma
build:host_release_licenses --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=release

# linux_web_engine_build.json: ci/wasm_release
#   --web --runtime-mode=release --no-rbe --no-goma
build:wasm_release --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=release --platforms=//engine/src/flutter/build/bazel/toolchains/emscripten:wasm32_emscripten

# linux_web_engine_build.json: ci/wasm_profile
#   --web --runtime-mode=profile --no-lto
# No configuration: the Bazel build cannot express
#   --no-lto (the wasm platform links the optimized build with LTO)

# local_engine.json: linux/host_debug
#   --runtime-mode debug --no-stripped --no-lto --rbe --no-goma
build:host_debug --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug --//engine/src/flutter/build/bazel:stripped=false

# local_engine.json: linux/host_debug_unopt
#   --runtime-mode debug --unopt --no-stripped --no-lto
build:host_debug_unopt --compilation_mode=dbg --//engine/src/flutter/common:runtime_mode=debug --//engine/src/flutter/build/bazel:stripped=false

# local_engine.json: linux/wasm_release
#   --web --runtime-mode=release --no-rbe --no-goma
# The same configuration as linux_web_engine_build.json's ci/wasm_release, above.

# local_engine.json: linux/wasm_debug_unopt
#   --web --runtime-mode=debug --unoptimized --no-rbe --no-goma
build:wasm_debug_unopt --compilation_mode=dbg --//engine/src/flutter/common:runtime_mode=debug --platforms=//engine/src/flutter/build/bazel/toolchains/emscripten:wasm32_emscripten

# local_engine.json: linux/android_debug_arm64
#   --runtime-mode debug --android --android-cpu=arm64 --no-stripped --no-lto --rbe --no-goma
# The same configuration as linux_host_engine.json's ci/android_debug_arm64, above.

# mac_host_engine.json: ci/mac_host
#   --runtime-mode debug --no-lto
build:mac_host --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug --platforms=//engine/src/flutter/build/bazel/toolchains:macos_x64

# local_engine.json: macos/host_debug
#   --runtime-mode debug --no-stripped --no-lto --xcode-symlinks
build:mac_host_debug --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug --platforms=//engine/src/flutter/build/bazel/toolchains:macos_x64 --//engine/src/flutter/build/bazel:stripped=false
'''),
      );
      // Two builds of one name with different flags cannot share it.
      expect(
        () => configsBazelrc(
          builderBuilds(
            configs(<String, String>{
              'linux_a.json':
                  '{"builds": [${build('ci/host_x', '--runtime-mode debug --no-lto', <String>[])}]}',
              'linux_b.json':
                  '{"builds": [${build('ci/host_x', '--runtime-mode release --no-lto', <String>[])}]}',
            }),
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('would both be --config=host_x with different flags'),
          ),
        ),
      );
      // What builderBuilds leaves out is named, with its reason, so that the
      // generated file accounts for every build of the Linux files: the
      // fixture's Fuchsia build, and a test-only build with no gn step.
      final Map<String, BuilderConfig> withTestOnly = configs(<String, String>{
        'linux_arm_host_engine.json':
            '{"builds": [${build('ci/fuchsia_debug_x64', '--target-os=fuchsia --fuchsia-cpu=x64 --runtime-mode debug --no-lto', <String>['flutter/shell/platform/fuchsia:fuchsia'])}]}',
        // linux_web_engine_test.json's bundles: a generator task, no gn step.
        'linux_web_engine_test.json':
            '{"builds": [{"name": "web_tests/test_bundles/fallbacks", '
            '"drone_dimensions": ["os=Linux"], "generators": {"tasks": [{"name": "compile bundle", '
            '"parameters": ["test", "--compile", "--bundle=fallbacks"], '
            '"scripts": ["flutter/lib/web_ui/dev/felt"]}]}, "tests": []}]}',
      });
      final List<LeftOutBuild> leftOut = leftOutBuilds(withTestOnly);
      expect(leftOut, <LeftOutBuild>[
        (
          file: 'linux_arm_host_engine.json',
          name: 'ci/fuchsia_debug_x64',
          reason: 'a platform the Bazel build has none for yet (--target-os=fuchsia)',
        ),
        (
          file: 'linux_web_engine_test.json',
          name: 'web_tests/test_bundles/fallbacks',
          reason: 'no tools/gn step: not a build',
        ),
      ]);
      expect(
        configsBazelrc(builderBuilds(withTestOnly), leftOut: leftOut),
        endsWith('''
# Not configurations: the builds of these files that are not builds of this
# scope -- another platform's, or a test-only build with no tools/gn step.
# Every other build of the Linux and Mac builder files is above.
#   linux_arm_host_engine.json: ci/fuchsia_debug_x64 -- a platform the Bazel build has none for yet (--target-os=fuchsia)
#   linux_web_engine_test.json: web_tests/test_bundles/fallbacks -- no tools/gn step: not a build
'''),
      );
      expect(configsBazelrc(builds), isNot(contains('Not configurations')));
      final String buildFile = buildersBuildFile(
        builds,
        <String, Set<String>>{
          '//flutter/build/archives': <String>{'artifacts', 'flutter_patched_sdk'},
          '//flutter/tools/font_subset': <String>{'font_subset'},
          '//flutter/sky/packages/sky_engine': <String>{'sky_engine'},
          // sky/dist's action of the same bare name, in a file GN reads
          // under is_android: a host build's `sky_engine` is still the
          // package's, unique among the targets that exist for it.
          '//flutter/sky/dist': <String>{'sky_engine', 'zip'},
          '//flutter/impeller/compiler/shader_lib/flutter': <String>{'flutter'},
          '//flutter/tools/licenses_cpp': <String>{'licenses_cpp', 'license_file_compare'},
          '//flutter/web_sdk': <String>{'flutter_web_sdk_archive'},
          '//flutter/shell/platform/embedder': <String>{'embedder-archive'},
        },
        convertedTests: <String, Set<String>>{
          '//flutter/fml': <String>{'fml_unittests'},
          '//flutter/txt': <String>{'txt_unittests'},
          '//flutter/tools/licenses_cpp': <String>{'licenses_cpp_testrunner'},
        },
        packageConditions: <String, String?>{'//flutter/sky/dist': 'is_android'},
      );
      // `flutter` is the directory //flutter (not converted), not the
      // shader_lib target of that name; `flutter:unittests` is not converted.
      expect(
        buildFile,
        contains('''
# linux_host_engine.json: ci/host_debug
#   bazel run --config=ci_host_debug :ci_host_debug
# Not built, no Bazel counterpart yet: flutter, flutter:unittests.
install(
    name = "ci_host_debug",
    testonly = True,
    contents = [
        "//engine/src/flutter/build/archives:artifacts",
        "//engine/src/flutter/sky/packages/sky_engine:sky_engine",
        "//engine/src/flutter/tools/font_subset:font_subset",
    ],
    directory = "ci/host_debug",
    target_compatible_with = select({
        "//engine/src/flutter/build/bazel:host_os_is_linux": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
)
'''),
      );
      // fileHolds: a file read under is_android exists for the Android
      // builds and no other; an unconditional file for every build.
      final BuilderBuild androidBuild = builds.firstWhere(
        (BuilderBuild b) => b.name == 'ci/android_debug_arm64',
      );
      final BuilderBuild hostBuild = builds.firstWhere(
        (BuilderBuild b) => b.name == 'ci/host_debug',
      );
      expect(fileHolds('is_android', androidBuild), isTrue);
      expect(fileHolds('is_android', hostBuild), isFalse);
      expect(fileHolds(null, hostBuild), isTrue);
      expect(fileHolds('is_linux', hostBuild), isTrue);
      expect(fileHolds('is_linux', androidBuild), isFalse);
      // The Android build: the root group and the Java half's targets have
      // no counterpart yet; the embedder archive installs.
      expect(
        buildFile,
        contains('''
# linux_host_engine.json: ci/android_debug_arm64
#   bazel run --config=android_debug_arm64 :android_debug_arm64
# Not built, no Bazel counterpart yet: flutter, flutter/shell/platform/android:abi_jars.
install(
    name = "android_debug_arm64",
    testonly = True,
    contents = ["//engine/src/flutter/shell/platform/embedder:embedder-archive"],
    directory = "ci/android_debug_arm64",
    target_compatible_with = select({
        "//engine/src/flutter/build/bazel:host_os_is_linux": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
)
'''),
      );
      // The web build installs into the directory tools/gn names for its
      // flags (out/wasm_release: the install rule's variant under the wasm
      // platform), having no --target-dir.
      expect(
        buildFile,
        contains('''
# linux_web_engine_build.json: ci/wasm_release
#   bazel run --config=wasm_release :wasm_release
install(
    name = "wasm_release",
    testonly = True,
    contents = ["//engine/src/flutter/web_sdk:flutter_web_sdk_archive"],
    target_compatible_with = select({
        "//engine/src/flutter/build/bazel:host_os_is_linux": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
)

# linux_web_engine_build.json: ci/wasm_profile
#   no configuration (configs.bazelrc); the flags would be:
#   --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=profile --platforms=//engine/src/flutter/build/bazel/toolchains/emscripten:wasm32_emscripten
install(
    name = "wasm_profile",
'''),
      );
      // The developer's linux/wasm_release builds what CI's ci/wasm_release
      // builds under the same name: one install.
      expect(
        buildFile,
        contains('''
# local_engine.json: linux/wasm_release
#   bazel run --config=wasm_release :wasm_release
# The same install as linux_web_engine_build.json's ci/wasm_release, above.
'''),
      );
      expect(
        buildFile,
        contains('''
# linux_host_engine.json: ci/host_debug_unopt
#   bazel run --config=ci_host_debug_unopt :ci_host_debug_unopt
# Tests, run by `bazel test` rather than installed: flutter/fml:fml_unittests.
install(
    name = "ci_host_debug_unopt",
    testonly = True,
    contents = ["//engine/src/flutter/tools/font_subset:font_subset"],
    target_compatible_with = select({
        "//engine/src/flutter/build/bazel:host_os_is_linux": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
)
'''),
      );
      // An Android build without a platform keeps its install (built with the
      // flags of the nearest configuration, as any build without one).
      expect(
        buildFile,
        contains('''
# linux_host_engine.json: ci/android_debug_x86
#   no configuration (configs.bazelrc); the flags would be:
#   --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug --//engine/src/flutter/build/bazel:stripped=false
# Not built, no Bazel counterpart yet: flutter.
# Nothing to install.
'''),
      );
      // The Mac's build is an install of its own (the macOS platform); the
      // Fuchsia build is out of scope.
      expect(
        buildFile,
        contains('''
# mac_host_engine.json: ci/mac_host
#   bazel run --config=mac_host :mac_host
# Not built, no Bazel counterpart yet: flutter.
# Nothing to install.
'''),
      );
      expect(buildFile, isNot(contains('fuchsia_debug_x64')));
      expect(
        buildFile,
        contains('''
# linux_arm_host_engine.json: ci/linux_debug_arm64
#   bazel run --config=linux_debug_arm64 :linux_debug_arm64
install(
    name = "linux_debug_arm64",
    testonly = True,
    contents = ["//engine/src/flutter/build/archives:artifacts"],
    directory = "ci/linux_debug_arm64",
    target_compatible_with = select({
        "//engine/src/flutter/build/bazel:host_os_is_linux": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
)
'''),
      );
      expect(
        buildFile,
        contains(
          '# local_engine.json: linux/host_debug\n'
          "#   ninja's default target, everything: "
          'bazel build --config=host_debug //engine/src/flutter:local_engine\n',
        ),
      );
      // The tests: the suites of the run_tests.py types, the `engine` type's
      // executables among the converted tests, the rest on record.
      expect(
        buildFile,
        contains(
          '''
# linux_host_engine.json: ci/host_debug_test
#   bazel run --config=host_debug_test :host_debug_test
# Not built, no Bazel counterpart yet: flutter:unittests.
# Nothing to install.

# ci/host_debug_test's tests: run_tests.py --type dart,dart-host,engine,impeller-golden.
# Not run, no Bazel test yet: assets_unittests (engine), client_wrapper_glfw_unittests (engine), ''',
        ),
      );
      // A step that runs a script of the checkout with a Bazel test of its
      // own (checkoutScriptTests) joins the suite; one without is on record.
      expect(
        buildFile,
        contains(
          'the impeller-golden type.\n'
          "# ci/host_debug_test's steps that run a script of the checkout, as Bazel tests: "
          '//engine/src/flutter:gn_test.\n'
          '# Other steps, scripts of the checkout: Lint.\n',
        ),
      );
      expect(
        buildFile,
        contains('''
test_suite(
    name = "host_debug_test_tests",
    tags = ["manual"],
    tests = [
        "//engine/src/flutter:dart_host_tests",
        "//engine/src/flutter:gn_test",
        "//engine/src/flutter/fml:fml_unittests",
        "//engine/src/flutter/testing/dart:dart",
        "//engine/src/flutter/testing/dart/vm_service:vm_service",
        "//engine/src/flutter/testing/smoke_test_failure:smoke_test_failure",
        "//engine/src/flutter/txt:txt_unittests",
    ],
)
'''),
      );
      // A step that runs a test executable from the build directory
      // (out/<dir>/<name>) is that executable's Bazel test in the suite; one
      // with no Bazel test is on record. The directory spelling of the ninja
      // target is the target of the directory's name.
      expect(
        buildFile,
        contains('''
# linux_host_engine.json: ci/host_release_licenses
#   bazel run --config=host_release_licenses :host_release_licenses
# Tests, run by `bazel test` rather than installed: flutter/tools/licenses_cpp:licenses_cpp_testrunner.
install(
    name = "host_release_licenses",
    testonly = True,
    contents = ["//engine/src/flutter/tools/licenses_cpp:licenses_cpp"],
    directory = "ci/host_release_licenses",
    target_compatible_with = select({
        "//engine/src/flutter/build/bazel:host_os_is_linux": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
)

# ci/host_release_licenses's tests run from the build directory: licenses_cpp_testrunner, other_testrunner.
# Not run, no Bazel test yet: other_testrunner (run from the build directory).
test_suite(
    name = "host_release_licenses_tests",
    tags = ["manual"],
    tests = ["//engine/src/flutter/tools/licenses_cpp:licenses_cpp_testrunner"],
)
'''),
      );
    });

    test('the engine type names executables run_tests.py runs', () {
      // One-directional: every name of the tables is one the script runs
      // (the script's platform branches keep the other direction manual).
      final String script = File(
        p.join(Directory.current.path, '..', '..', 'testing', 'run_tests.py'),
      ).readAsStringSync();
      for (final String name in runTestsEngineSuites) {
        expect(script, contains("make_test('$name'"), reason: name);
      }
      for (final String name in runTestsEngineSuitesMac) {
        expect(script, contains("'$name'"), reason: name);
      }
      // The Mac's list has the Objective-C and Darwin suites and not the
      // Linux ones.
      expect(runTestsEngineSuitesMac, contains('flutter_desktop_darwin_unittests'));
      expect(runTestsEngineSuitesMac, isNot(contains('flutter_linux_unittests')));
      expect(runTestsEngineSuitesMac, isNot(contains('txt_unittests')));
    });

    test("the Mac's builds: a platform each, their names kept or prefixed", () {
      final Map<String, BuilderConfig> loaded = configs(<String, String>{
        'linux_host_engine.json':
            '''
{"builds": [
  ${build('ci/host_debug', '--target-dir ci/host_debug --runtime-mode debug --no-lto', <String>['flutter/build/archives:artifacts'])},
  ${build('ci/android_profile', '--target-dir ci/android_profile --runtime-mode profile --android', <String>['default'])}
]}''',
        'linux_web_engine_build.json':
            '{"builds": [${build('ci/wasm_release', '--web --runtime-mode=release --no-rbe --no-goma', <String>['flutter/web_sdk:flutter_web_sdk_archive'])}]}',
        // The Mac's: its host_debug is an x64 build (tools/gn's --mac-cpu
        // default) and builds other targets than Linux's, so it keeps its
        // OS; --mac --mac-cpu arm64 and a host build with --mac-cpu arm64
        // are the arm64 platform; the Android AOT build from a Mac makes
        // the Mac's gen_snapshot, so it keeps its OS too, though its flags
        // are Linux's.
        'mac_host_engine.json':
            '''
{"builds": [
  ${build('ci/host_debug', '--target-dir ci/host_debug --runtime-mode debug --no-lto --xcode-symlinks', <String>['flutter/build/archives:artifacts', 'flutter/shell/platform/darwin/macos:zip_macos_flutter_framework'])},
  ${build('ci/mac_debug_arm64', '--target-dir ci/mac_debug_arm64 --mac --mac-cpu arm64 --runtime-mode debug --no-lto --xcode-symlinks', <String>['flutter/build/archives:artifacts'])},
  ${build('ci/host_debug_unopt_arm64', '--target-dir ci/host_debug_unopt_arm64 --runtime-mode debug --unoptimized --no-lto --mac-cpu arm64 --xcode-symlinks', <String>[], tests: runTests('Host Tests', 'dart,engine'))}
]}''',
        'mac_android_aot_engine.json':
            '{"builds": [${build('ci/android_profile', '--target-dir ci/android_profile --runtime-mode profile --android --xcode-symlinks', <String>['flutter/lib/snapshot', 'flutter/shell/platform/android:gen_snapshot'])}]}',
        // iOS is out of scope, --simulator and --darwin-extension-safe with it.
        'mac_ios_engine.json':
            '{"builds": [${build('ci/ios_debug_sim_extension_safe', '--ios --runtime-mode debug --simulator --simulator-cpu=arm64 --no-lto --darwin-extension-safe', <String>[])}]}',
        // The developer's: the web build from either host is one build;
        // macos/host_debug (--no-stripped) is the Mac's developer build,
        // from which CI's mac_host_debug differs, so CI's keeps its ci/.
        'local_engine.json':
            '''
{"builds": [
  ${build('linux/wasm_release', '--web --runtime-mode=release --no-rbe --no-goma', <String>['flutter/web_sdk:flutter_web_sdk_archive'])},
  ${build('macos/wasm_release', '--web --runtime-mode=release --no-rbe --no-goma', <String>['flutter/web_sdk:flutter_web_sdk_archive'])},
  ${build('macos/host_debug', '--runtime-mode debug --no-stripped --no-lto --xcode-symlinks', <String>[])}
]}''',
      });
      final List<BuilderBuild> builds = builderBuilds(loaded);
      expect(builds.map((BuilderBuild b) => '${b.name} ${b.configName}'), <String>[
        'ci/host_debug host_debug',
        'ci/android_profile android_profile',
        'ci/wasm_release wasm_release',
        'linux/wasm_release wasm_release',
        'ci/android_profile mac_android_profile',
        'ci/host_debug ci_mac_host_debug',
        'ci/mac_debug_arm64 mac_debug_arm64',
        'ci/host_debug_unopt_arm64 host_debug_unopt_arm64',
        'macos/wasm_release wasm_release',
        'macos/host_debug mac_host_debug',
      ]);
      final String bazelrc = configsBazelrc(builds, leftOut: leftOutBuilds(loaded));
      expect(
        bazelrc,
        contains('''
# mac_android_aot_engine.json: ci/android_profile
#   --target-dir ci/android_profile --runtime-mode profile --android --xcode-symlinks
build:mac_android_profile --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=profile --platforms=//engine/src/flutter/build/bazel/toolchains:android_arm --//engine/src/flutter/build/bazel:lto --//engine/src/flutter/build/bazel:stripped=false

# mac_host_engine.json: ci/host_debug
#   --target-dir ci/host_debug --runtime-mode debug --no-lto --xcode-symlinks
build:ci_mac_host_debug --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug --platforms=//engine/src/flutter/build/bazel/toolchains:macos_x64

# mac_host_engine.json: ci/mac_debug_arm64
#   --target-dir ci/mac_debug_arm64 --mac --mac-cpu arm64 --runtime-mode debug --no-lto --xcode-symlinks
build:mac_debug_arm64 --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug --platforms=//engine/src/flutter/build/bazel/toolchains:macos_arm64

# mac_host_engine.json: ci/host_debug_unopt_arm64
#   --target-dir ci/host_debug_unopt_arm64 --runtime-mode debug --unoptimized --no-lto --mac-cpu arm64 --xcode-symlinks
build:host_debug_unopt_arm64 --compilation_mode=dbg --//engine/src/flutter/common:runtime_mode=debug --platforms=//engine/src/flutter/build/bazel/toolchains:macos_arm64

# local_engine.json: macos/wasm_release
#   --web --runtime-mode=release --no-rbe --no-goma
# The same configuration as linux_web_engine_build.json's ci/wasm_release, above.

# local_engine.json: macos/host_debug
#   --runtime-mode debug --no-stripped --no-lto --xcode-symlinks
build:mac_host_debug --compilation_mode=opt --//engine/src/flutter/common:runtime_mode=debug --platforms=//engine/src/flutter/build/bazel/toolchains:macos_x64 --//engine/src/flutter/build/bazel:stripped=false
'''),
      );
      expect(
        bazelrc,
        contains(
          '#   mac_ios_engine.json: ci/ios_debug_sim_extension_safe -- a platform the Bazel '
          'build has none for yet (--ios)',
        ),
      );
      // fileHolds: a file read under is_mac exists for the Mac's builds, a
      // Linux one not.
      final BuilderBuild macBuild = builds.firstWhere(
        (BuilderBuild b) => b.configName == 'mac_debug_arm64',
      );
      final BuilderBuild linuxBuild = builds.firstWhere(
        (BuilderBuild b) => b.configName == 'host_debug',
      );
      expect(fileHolds('is_mac', macBuild), isTrue);
      expect(fileHolds('is_linux', macBuild), isFalse);
      expect(fileHolds('is_mac', linuxBuild), isFalse);
      expect(fileHolds('is_linux', linuxBuild), isTrue);
      // The installs: the Mac's host_debug under its own name, the darwin
      // framework listed until it converts; the suite of the arm64 host
      // build runs the Mac's engine list (the Darwin suites among them,
      // txt_unittests not).
      final String buildFile = buildersBuildFile(
        builds,
        <String, Set<String>>{
          '//flutter/build/archives': <String>{'artifacts'},
          '//flutter/web_sdk': <String>{'flutter_web_sdk_archive'},
        },
        convertedTests: <String, Set<String>>{
          '//flutter/fml': <String>{'fml_unittests'},
          '//flutter/txt': <String>{'txt_unittests'},
          '//flutter/shell/platform/darwin/macos': <String>{'flutter_desktop_darwin_unittests'},
        },
      );
      expect(
        buildFile,
        contains('''
# mac_host_engine.json: ci/host_debug
#   bazel run --config=ci_mac_host_debug :ci_mac_host_debug
# Not built, no Bazel counterpart yet: flutter/shell/platform/darwin/macos:zip_macos_flutter_framework.
install(
    name = "ci_mac_host_debug",
    testonly = True,
    contents = ["//engine/src/flutter/build/archives:artifacts"],
    directory = "ci/host_debug",
    target_compatible_with = select({
        "//engine/src/flutter/build/bazel:host_os_is_mac": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
)
'''),
      );
      expect(
        buildFile,
        contains('''
# ci/host_debug_unopt_arm64's tests: run_tests.py --type dart,engine.
# Not run, no Bazel test yet: assets_unittests (engine), '''),
      );
      expect(
        buildFile,
        contains('''
test_suite(
    name = "host_debug_unopt_arm64_tests",
    tags = ["manual"],
    tests = [
        "//engine/src/flutter/fml:fml_unittests",
        "//engine/src/flutter/shell/platform/darwin/macos:flutter_desktop_darwin_unittests",
        "//engine/src/flutter/testing/dart:dart",
        "//engine/src/flutter/testing/dart/vm_service:vm_service",
        "//engine/src/flutter/testing/smoke_test_failure:smoke_test_failure",
    ],
)
'''),
      );
      expect(buildFile, isNot(contains('txt_unittests (engine)')));
    });
  });

  group('mirrored lists', () {
    test('agreeing lists pass; a test added to GN alone is reported', () {
      final GnSourceTree tree = sourceTree(<String, String>{
        'flutter/testing/dart/BUILD.gn': r'''
tests = [
  "a_test.dart",
  "b_test.dart",
]
foreach(test, tests) {
  flutter_frontend_server("compile_$test") {
    main_dart = test
  }
}
''',
        'flutter/testing/dart/BUILD.bazel': '''
flutter_dart_tests(
    name = "dart",
    tests = [
        "a_test.dart",  # a comment
        "b_test.dart",
    ],
    vm_service = False,
)
''',
      });
      const lists = <String, MirroredList>{'//flutter/testing/dart': MirroredList('tests')};
      expect(mirroredListMismatches(tree, lists), isEmpty);
      File(
        p.join(tree.root, 'flutter/testing/dart/BUILD.gn'),
      ).writeAsStringSync('tests = [\n  "a_test.dart",\n  "b_test.dart",\n  "c_test.dart",\n]\n');
      final reloaded = GnSourceTree(tree.root, gnBinary: gnBinary);
      final List<String> messages = mirroredListMismatches(reloaded, lists);
      expect(messages, hasLength(1));
      expect(messages.single, contains('missing c_test.dart'));
      expect(messages.single, contains('hand-written'));
    });

    test('the Starlark list is read strictly', () {
      expect(bazelListAttribute('x(\n    tests = ["a.dart", "b.dart"],\n)\n', 'tests'), <String>[
        'a.dart',
        'b.dart',
      ]);
      expect(
        bazelListAttribute('tests = [\n    "a.dart",\n]\ntests = ["b.dart"]\n', 'tests'),
        isNull,
      );
      expect(bazelListAttribute('tests = ["a.dart"] + more\n', 'tests'), <String>['a.dart']);
      expect(bazelListAttribute('tests = [name + ".dart"]\n', 'tests'), isNull);
      expect(bazelListAttribute('srcs = ["a.dart"]\n', 'tests'), isNull);
    });
  });

  group('round trip', () {
    // The checked-in files the converter generates (see the manifest); a
    // difference means the GN file changed without regenerating, or the
    // converter did.
    for (final ConvertedFile file in convertedFiles) {
      test(file.gnPackage, () async {
        // The package lives at engine/src/flutter/tools/gn_to_bazel.
        final String directory = p.join(
          Directory.current.path,
          '..',
          '..',
          '..',
          file.gnPackage.substring(2),
        );
        final tree = GnSourceTree(
          p.join(Directory.current.path, '..', '..', '..'),
          gnBinary: gnBinary,
        );
        final GnFileEvaluation evaluation = evaluateGnFile(
          tree.load(p.join(directory, 'BUILD.gn')),
          assumptions: generationAssumptions().withValues(file.assume),
          templates: templateMappings.keys.toSet(),
          externalVariables: knownExternalVariables,
          booleanVariables: knownBooleanVariables,
          skipTargets: file.skip.keys.toSet(),
          tree: tree,
          importPolicy: engineImportPolicy,
          condition: file.condition == null ? Condition.always : ConditionVariable(file.condition!),
          targetConditions: <String, Condition>{
            for (final MapEntry<String, String> entry in file.targetConditions.entries)
              entry.key: ConditionVariable(entry.value),
          },
        );
        final String output = emitBuildFile(
          evaluation,
          gnPackage: file.gnPackage,
          skipTargets: file.skip.keys.toSet(),
          appendix: file.appendix,
          layout: mainRepositoryLayout,
          implicitDeps: file.implicitDeps,
          tree: tree,
          unconvertedDeps: file.unconvertedDeps,
          filesGroups: file.filesGroups,
        );
        expect(output, File(p.join(directory, 'BUILD.bazel')).readAsStringSync());
        // Every skip in the manifest names a target that exists.
        expect(evaluation.skipped, unorderedEquals(file.skip.keys));
      });
    }
  });
}
