// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

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
}) async {
  return evaluateGnFile(
    await parse(gn),
    assumptions: assumptions ?? linuxHostAssumptions(),
    templates: templates,
    externalVariables: externalVariables,
    skipTargets: skip,
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
}) async {
  return emitBuildFile(
    await evaluate(
      gn,
      assumptions: assumptions,
      externalVariables: externalVariables,
      templates: templates,
      skip: skip,
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
  ImportPolicy importPolicy = const ImportPolicy(
    evaluatedPrefixes: <String>{'//lib/'},
    known: <String>{'//known/config.gni'},
  ),
}) {
  return evaluateGnFile(
    tree.load(tree.resolve(file)),
    assumptions: assumptions ?? linuxHostAssumptions(),
    externalVariables: knownExternalVariables,
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
      expect(wasm.and(fuchsia.negated), wasm);
      expect(wasm.negated.or(fuchsia.negated), Condition.always);
      // Unrelated predicates are left alone, in order; so is anything that
      // would take more than one look (no resolution, no absorption).
      expect(slim.and(mac), const ConditionAnd(<Condition>[slim, mac]));
      expect(
        mac.or(ios).negated,
        const ConditionAnd(<Condition>[ConditionNot(mac), ConditionNot(ios)]),
      );
      expect(
        slim.and(mac).negated.and(slim),
        const ConditionAnd(<Condition>[
          ConditionOr(<Condition>[ConditionNot(slim), ConditionNot(mac)]),
          slim,
        ]),
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

    group('is strict about', () {
      test('foreach', () async {
        await expectLater(
          evaluate('''
source_set("x") {
  sources = []
  foreach(f, [ "a", "b" ]) {
    sources += [ f + ".cc" ]
  }
}
'''),
          throwsGnError(line: 3, message: 'foreach() is not supported'),
        );
      });

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
        expect(open.targets.map((GnTarget t) => '${t.rule} ${t.name} [${t.condition}]'), <String>[
          'group x_unittests [!enable_unittests]',
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
    copts = CHROMIUM_CODE_COPTS + FLUTTER_TESTONLY_COPTS,
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
  group(target_name + "_group") {
    deps = [ ":" + target_name ]
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
        expect(strings(group, 'deps'), <String>[':x']);
        final GnTarget y = evaluation.targets[2];
        expect(y.rule, 'static_library');
        expect(strings(y, 'sources'), <String>['b.cc']);
        expect(y.variables.containsKey('missing'), isFalse);
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
        expect(
          output,
          contains('load("//engine/src/flutter/build/bazel/gn_action:gn_action.bzl", "gn_action")'),
        );
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
load("//engine/src/flutter/build/bazel:copts.bzl", "FLUTTER_COPTS", "FLUTTER_LOCAL_DEFINES", "FLUTTER_TESTONLY_COPTS")

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
    copts = FLUTTER_COPTS + FLUTTER_TESTONLY_COPTS,
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
      expect(output, isNot(contains('alwayslink')));
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
load("//engine/src/flutter/testing:testing.bzl", "flutter_test_fixtures")

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
load("//engine/src/flutter/build/bazel:copts.bzl", "CHROMIUM_CODE_COPTS", "FLUTTER_LOCAL_DEFINES")
load("//engine/src/flutter/testing:testing.bzl", "flutter_test_fixtures")
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
      await expectLater(
        convert('''
source_set("x") {
  sources = [ "a.cc" ]
  if (shell_enable_metal) {
    sources += [ "metal.cc" ]
  }
}
''', assumptions: Assumptions(const <String, GnValue>{})),
        throwsA(
          isA<GnError>().having(
            (GnError e) => e.message,
            'message',
            contains('no config_setting for `shell_enable_metal`'),
          ),
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
    copts = FLUTTER_COPTS,
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
    copts = CHROMIUM_CODE_COPTS + ["-Wno-something"],
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
          'load("@flutter//engine/src/flutter/build/bazel:copts.bzl", '
          '"FLUTTER_COPTS", "FLUTTER_LOCAL_DEFINES")',
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
    copts = FLUTTER_COPTS,
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
      expect(
        output,
        contains('load("//engine/src/flutter/build/bazel:copts.bzl", "FLUTTER_FEATURE_DEFINES")\n'),
      );
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
      // //flutter:config, listed or implied by a dependency on engine code.
      expect(
        output,
        contains('name = "engine",\n    srcs = ["engine.cc"],\n    copts = FLUTTER_COPTS,'),
      );
      expect(
        output,
        contains('name = "engine_too",\n    srcs = ["engine_too.cc"],\n    copts = FLUTTER_COPTS,'),
      );
    });

    test('hands the flags of a public config to the owner and its dependents', () async {
      // wuffs: the engine's GN turns warnings off for whoever includes it.
      const layout = OutputLayout.repository(
        '@wuffs',
        repositoryGnRoot: '//flutter/third_party/wuffs',
      );
      final String wuffs = await convert(
        '''
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
''',
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

      // A dependent gets them from the table.
      final String user = await convert('''
source_set("gif_codec") {
  sources = [ "gif.cc" ]
  deps = [ "//flutter/third_party/wuffs" ]
}
''');
      expect(
        user,
        contains('''
    copts = CHROMIUM_CODE_COPTS + [
        "-Wno-unused-function",  # from //flutter/third_party/wuffs
        "-Wno-c++11-narrowing",  # from //flutter/third_party/wuffs
    ],
'''),
      );

      // A public config with flags that the table does not know is an error,
      // as is a config with flags that nothing in the file lists.
      await expectLater(
        convert('''
config("loud_public") {
  cflags = [ "-Wall" ]
}
source_set("x") {
  sources = [ "x.cc" ]
  public_configs = [ ":loud_public" ]
}
'''),
        throwsGnError(line: 4, message: 'list them under //flutter/example:x in propagatedCopts'),
      );
      await expectLater(
        convert('''
config("unused") {
  cflags = [ "-Wall" ]
}
'''),
        throwsGnError(line: 2, message: 'cannot be propagated by Bazel'),
      );
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
      expect(output, contains('includes = [\n        "release/c",\n        "config",\n    ],'));
    });

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
load("//engine/src/flutter/build/bazel/gn_action:gn_action.bzl", "gn_copy")

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
load("//engine/src/flutter/build/bazel:copts.bzl", "CHROMIUM_CODE_COPTS", "FLUTTER_LOCAL_DEFINES")
load("//engine/src/flutter/build/bazel/flatbuffers:flatbuffers.bzl", "flatbuffers")
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
load("//engine/src/flutter/build/bazel/impeller:shaders.bzl", "impeller_shaders")

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
    deps = [
        "//engine/src:include_root",
        "//engine/src/flutter/impeller:impeller_public_config",
    ],
    implementation_deps = ["@skia//:skia_private"],
    alwayslink = True,
)
'''),
      );
      // A header-only library compiles nothing for the config to apply to.
      expect(output, contains('cc_library(\n    name = "headers",\n    hdrs = ["b.h"],\n)\n'));
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

    test('a shared_library is a shared cc_binary named after its output, with an alias', () async {
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
cc_binary(
    name = "libx.so",
    srcs = ["a.cc"],
    copts = CHROMIUM_CODE_COPTS,
    linkshared = True,
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        ":y",
        "//engine/src:include_root",
        "//engine/src/flutter/build/bazel/toolchains:cxx_runtime",
    ],
)

alias(
    name = "x_shared",
    actual = ":libx.so",
)
'''),
      );
      // Without output_name the target's own name is the library's.
      expect(
        await convert('''
shared_library("z") {
  sources = [ "a.cc" ]
}
'''),
        contains('    name = "libz.so",\n'),
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
      expect(clash, contains('    name = "libw.so",\n'));
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
          assumptions: linuxHostAssumptions(),
          templates: templateMappings.keys.toSet(),
          externalVariables: knownExternalVariables,
          skipTargets: file.skip.keys.toSet(),
          tree: tree,
          importPolicy: engineImportPolicy,
        );
        final String output = emitBuildFile(
          evaluation,
          gnPackage: file.gnPackage,
          skipTargets: file.skip.keys.toSet(),
          appendix: file.appendix,
          layout: mainRepositoryLayout,
        );
        expect(output, File(p.join(directory, 'BUILD.bazel')).readAsStringSync());
        // Every skip in the manifest names a target that exists.
        expect(evaluation.skipped, unorderedEquals(file.skip.keys));
      });
    }
  });
}
