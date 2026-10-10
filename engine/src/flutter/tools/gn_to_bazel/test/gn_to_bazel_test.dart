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
  Set<String> skip = const <String>{},
  String? appendix,
  OutputLayout layout = const OutputLayout.main(),
}) async {
  return emitBuildFile(
    await evaluate(gn, assumptions: assumptions, externalVariables: externalVariables, skip: skip),
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
  sources = [ "$root_gen_dir/a.cc" ]
}
'''),
        throwsGnError(line: 2, message: r'string expansion of $root_gen_dir is not supported'),
      );
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
  sources = [ "$root_gen_dir/a.cc" ]
}
'''),
          throwsGnError(line: 2, message: r'string expansion of $root_gen_dir is not supported'),
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

      test('keeps rebase_path() and exec_script() opaque until they are used', () async {
        final GnFileEvaluation evaluation = await evaluate('''
_unused = rebase_path("//somewhere")
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
  include_dirs = [ rebase_path("//somewhere") ]
}
'''),
          throwsGnError(line: 3, message: 'expected a string, got <rebase_path("//somewhere")>'),
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
    copts = FLUTTER_COPTS + ["-Wno-something"],
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
    copts = FLUTTER_COPTS,
    includes = ["src"],
    linkopts = ["-Wl,--private"],
    local_defines = FLUTTER_LOCAL_DEFINES + ["IMPLEMENTATION=1"] + select({
        "//engine/src/flutter/build/bazel:unoptimized": [
            "DEBUG_ONLY",  # is_debug
        ],
        "//conditions:default": [],
    }),
    deps = [":public_config"],
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
    implementation_deps = [
        "//modules/skcms",
        "//modules/skcms:other",
        "@flutter//engine/src/flutter/fml",
        "@icu",
    ],
    includes = ["."],
    local_defines = FLUTTER_LOCAL_DEFINES + select({
        "@flutter//engine/src/flutter/build/bazel:unoptimized": [
            "DEBUG_ONLY",  # is_debug
        ],
        "//conditions:default": [],
    }),
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
    copts = FLUTTER_COPTS,
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
        final GnBlock tree = await loadGnFile(p.join(directory, 'BUILD.gn'), gnBinary: gnBinary);
        final GnFileEvaluation evaluation = evaluateGnFile(
          tree,
          assumptions: linuxHostAssumptions(),
          templates: templateMappings.keys.toSet(),
          externalVariables: knownExternalVariables,
          skipTargets: file.skip.keys.toSet(),
        );
        final String output = emitBuildFile(
          evaluation,
          gnPackage: file.gnPackage,
          skipTargets: file.skip.keys.toSet(),
          appendix: file.appendix,
        );
        expect(output, File(p.join(directory, 'BUILD.bazel')).readAsStringSync());
        // Every skip in the manifest names a target that exists.
        expect(evaluation.skipped, unorderedEquals(file.skip.keys));
      });
    }
  });
}
