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
}) async {
  return evaluateGnFile(
    await parse(gn),
    assumptions: assumptions ?? linuxHostAssumptions(),
    templates: templates,
    externalVariables: externalVariables,
  );
}

Future<String> convert(
  String gn, {
  Assumptions? assumptions,
  String gnPackage = '//flutter/example',
  Set<String> externalVariables = knownExternalVariables,
}) async {
  return emitBuildFile(
    await evaluate(gn, assumptions: assumptions, externalVariables: externalVariables),
    gnPackage: gnPackage,
  );
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

      test('exec_script', () async {
        await expectLater(
          evaluate('''
files = exec_script("list.py", [], "list lines")
'''),
          throwsGnError(line: 1, message: 'exec_script() in an expression is not supported'),
        );
      });

      test('templates and forward_variables_from', () async {
        await expectLater(
          evaluate('''
template("my_lib") {
  source_set(target_name) {
    forward_variables_from(invoker, "*")
  }
}
'''),
          throwsGnError(line: 1, message: 'template() is not supported'),
        );
        await expectLater(
          evaluate('''
source_set("x") {
  forward_variables_from(invoker, [ "sources" ])
}
'''),
          throwsGnError(line: 2, message: 'forward_variables_from() is not supported'),
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
  sources = [ "$root_gen_dir/a.cc" ]
}
'''),
          throwsGnError(line: 2, message: 'string expansion is not supported'),
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
}
''');
        expect(evaluation.targets[0].condition, Condition.always);
        expect(evaluation.targets[1].condition, const ConditionVariable('slimpeller'));
        expect(
          () => emitBuildFile(evaluation, gnPackage: '//flutter/example'),
          throwsGnError(line: 7, message: 'defined under `slimpeller`'),
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

executable("example_unittests") {
  testonly = true
  sources = [ "example_unittests.cc" ]
  deps = [
    ":example",
    "//flutter/testing",
  ]
}
''');
      expect(output, '''
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Generated from //flutter/example/BUILD.gn by gn_to_bazel; do not edit.

load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test")
load("//engine/src/flutter/build/bazel:copts.bzl", "FLUTTER_COPTS", "FLUTTER_LOCAL_DEFINES")

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
    implementation_deps = ["//engine/src/flutter/fml"],
    linkopts = [
        "-lpthread",  # is_linux
    ],
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        ":example_config",
        "//engine/src/flutter:config",
        "@icu",
    ],
)

cc_test(
    name = "example_unittests",
    size = "small",
    srcs = ["example_unittests.cc"],
    copts = FLUTTER_COPTS,
    local_defines = FLUTTER_LOCAL_DEFINES,
    deps = [
        ":example",
        "//engine/src/flutter/testing",
    ],
)
''');
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
  if (slimpeller) {
    sources += [ "slim.cc" ]
  }
}
'''),
        throwsA(
          isA<GnError>().having(
            (GnError e) => e.message,
            'message',
            contains('no config_setting for `slimpeller`'),
          ),
        ),
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
    # Why these.
    implementation_deps = [
        # The library itself.
        ":example",
        # Linux needs this one.
        ":linux",  # is_linux
        ":y",
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

    test('rejects what it cannot express', () async {
      await expectLater(
        convert('''
source_set("headers") {
  sources = [ "a.h" ]
  defines = [ "UNUSED" ]
}
'''),
        throwsGnError(line: 1, message: 'has flags or defines but no sources'),
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
shared_library("x") {
  sources = [ "a.cc" ]
}
'''),
        throwsGnError(line: 1, message: 'shared_library() is not converted yet'),
      );
    });
  });

  group('round trip', () {
    /// The checked-in files the converter generates; a difference means the
    /// GN file changed without regenerating, or the converter did.
    const generated = <String, List<String>>{
      '//flutter/fml': <String>['fml_benchmarks'],
    };

    for (final MapEntry<String, List<String>> entry in generated.entries) {
      test(entry.key, () async {
        // The package lives at engine/src/flutter/tools/gn_to_bazel.
        final String directory = p.join(
          Directory.current.path,
          '..',
          '..',
          '..',
          entry.key.substring(2),
        );
        final GnBlock tree = await loadGnFile(p.join(directory, 'BUILD.gn'), gnBinary: gnBinary);
        final GnFileEvaluation evaluation = evaluateGnFile(
          tree,
          assumptions: linuxHostAssumptions(),
          templates: templateMappings.keys.toSet(),
          externalVariables: knownExternalVariables,
        );
        final String output = emitBuildFile(
          evaluation,
          gnPackage: entry.key,
          skipTargets: entry.value.toSet(),
        );
        expect(output, File(p.join(directory, 'BUILD.bazel')).readAsStringSync());
      });
    }
  });
}
