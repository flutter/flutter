// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:gn_to_bazel/gn_to_bazel.dart';
import 'package:path/path.dart' as p;

/// Checks the converter's reading of GN files against GN's own.
///
///     dart tool/gn_desc_diff.dart --out=out/host_debug_unopt [--assume=x=y]... <BUILD.gn>...
///
/// For every target of each file, what the converter evaluates (sources,
/// public headers, dependencies, and the defines of configs) is compared
/// with `gn desc <out> <label> --format=json`, GN's resolved view of the
/// same target in that out directory. The assumptions default to the Linux
/// host build; pass `--assume` for what distinguishes the out directory
/// (`is_debug=true` for host_debug_unopt). A difference is a converter bug
/// or a GN construct it reads wrongly; the exit code is 1 when there is one.
///
/// This is the oracle for a new conversion: the generated BUILD.bazel is
/// right when this agrees and Bazel builds it.
Future<void> main(List<String> arguments) async {
  exitCode = await run(arguments);
}

Future<int> run(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('root', help: 'The GN source root.', defaultsTo: _defaultRoot())
    ..addOption(
      'out',
      help: 'The GN out directory to compare with (under --root).',
      mandatory: true,
    )
    ..addMultiOption('assume', help: 'GN values beyond the Linux host defaults, as name=value.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    return 64;
  }
  if (options.flag('help') || options.rest.isEmpty) {
    stdout.writeln('Usage: dart tool/gn_desc_diff.dart --out=<dir> [options] <BUILD.gn>...\n');
    stdout.writeln(parser.usage);
    return options.rest.isEmpty ? 64 : 0;
  }
  final String root = p.canonicalize(options.option('root')!);
  final String gn = p.join(root, 'flutter/third_party/gn/gn');
  final String outDir = p.join(root, options.option('out'));
  final Assumptions assumptions = linuxHostAssumptions().withValues(<String, GnValue>{
    for (final String spec in options.multiOption('assume'))
      spec.substring(0, spec.indexOf('=')): Assumptions.parseValue(
        spec.substring(spec.indexOf('=') + 1),
      ),
  });
  final tree = GnSourceTree(root, gnBinary: gn);

  var differences = 0;
  var compared = 0;
  for (final String input in options.rest) {
    final String file = p.canonicalize(input);
    final String gnPackage = tree.gnDirectory(file);
    final Set<String> skip = manifestEntry(gnPackage)?.skip.keys.toSet() ?? const <String>{};
    final GnFileEvaluation evaluation;
    try {
      evaluation = evaluateGnFile(
        tree.load(file),
        assumptions: assumptions,
        templates: templateMappings.keys.toSet(),
        externalVariables: knownExternalVariables,
        skipTargets: skip,
        tree: tree,
        importPolicy: engineImportPolicy,
      );
    } on GnError catch (e) {
      stderr.writeln('error: $e');
      differences++;
      continue;
    }
    // `dir:*` describes the targets; configs are described one by one.
    final Map<String, Object?> described = await _gnDesc(gn, outDir, '$gnPackage:*');
    final seen = <String>{...skip.map((String name) => '$gnPackage:$name')};
    for (final GnTarget target in evaluation.targets) {
      final label = '$gnPackage:${target.name}';
      seen.add(label);
      if (templateMappings.containsKey(target.rule)) {
        // A known template becomes a Bazel macro; what it expands to in GN
        // (a group over `_`-prefixed targets) is the macro's business.
        continue;
      }
      var gnTarget = described[label] as Map<String, Object?>?;
      if (gnTarget == null && target.rule == 'config') {
        final Map<String, Object?> config = await _gnDesc(gn, outDir, label, failIfMissing: false);
        gnTarget = config[label] as Map<String, Object?>?;
      }
      if (gnTarget == null) {
        _report(label, 'is not in the GN build (gn desc knows nothing of it)');
        differences++;
        continue;
      }
      compared++;
      differences += _compare(label, target, gnTarget, gnPackage, evaluation.allDependentConfigs);
    }
    for (final String label in described.keys) {
      // GN's `_`-prefixed targets are the internals of template expansions.
      if (!seen.contains(label) && !label.substring(label.indexOf(':') + 1).startsWith('_')) {
        _report(label, 'is in the GN build but the converter did not evaluate it');
        differences++;
      }
    }
  }
  stdout.writeln(
    '$compared target(s) compared, '
    '${differences == 0 ? 'no differences' : '$differences difference(s)'}',
  );
  return differences == 0 ? 0 : 1;
}

/// Compares one target; returns the number of differences.
int _compare(
  String label,
  GnTarget target,
  Map<String, Object?> gnTarget,
  String gnPackage,
  Map<String, Set<String>> inherited,
) {
  var differences = 0;
  void check(String what, Set<String> ours, Set<String> theirs, {bool subset = false}) {
    final Set<String> missing = subset ? const <String>{} : theirs.difference(ours);
    final Set<String> extra = ours.difference(theirs);
    if (missing.isEmpty && extra.isEmpty) {
      return;
    }
    differences++;
    _report(label, '$what differ');
    for (final String m in missing.toList()..sort()) {
      stdout.writeln('    GN has, converter lacks: $m');
    }
    for (final String e in extra.toList()..sort()) {
      stdout.writeln('    converter has, GN lacks: $e');
    }
  }

  // A config's description has no type.
  final String type = gnTarget['type'] as String? ?? 'config';
  if (type != target.rule) {
    _report(label, 'is a ${target.rule} to the converter, a $type to GN');
    differences++;
  }
  // Items under conditions the assumptions did not decide cannot be
  // compared with one out directory; they are reported, not counted.
  final undecided = <String>[];
  Set<String> items(String variable, String Function(String) normalize) {
    final GnVariable? v = target.variables[variable];
    if (v == null) {
      return const <String>{};
    }
    final result = <String>{};
    for (final GnAssignment a in v.assignments) {
      if (!a.isUnconditional) {
        undecided.add('$variable under ${a.condition}');
        continue;
      }
      for (final GnValue item in a.items) {
        if (item is GnStringValue) {
          switch (a.op) {
            case '-=':
              result.remove(normalize(item.value));
            case '=' || '+=':
              result.add(normalize(item.value));
          }
        }
      }
      if (a.op == '=' && a.items.isEmpty) {
        result.clear();
      }
    }
    return result;
  }

  String path(String value) => _absolutePath(value, gnPackage);
  String labelOf(String value) => _absoluteLabel(value, gnPackage);

  check('sources', items('sources', path), _strings(gnTarget['sources']).map(path).toSet());
  final Object? public = gnTarget['public'];
  if (public is List<Object?>) {
    check('public', items('public', path), _strings(public).map(path).toSet());
  } else if (target.variables.containsKey('public')) {
    _report(label, 'has a public list to the converter, all headers public to GN');
    differences++;
  }
  // gn desc's deps are deps and public_deps together, plus what
  // BUILDCONFIG.gn's executable template adds (the C++ runtime, which the
  // Bazel toolchain provides).
  check(
    'deps',
    items('deps', labelOf).union(items('public_deps', labelOf)),
    _strings(gnTarget['deps']).map(_stripToolchain).map(labelOf).toSet()..removeAll(_toolchainDeps),
  );
  // gn desc lists public_configs after propagation from public_deps, so the
  // target's own are a subset; all_dependent_configs are compared after
  // propagation on both sides (the converter follows deps within the file).
  check(
    'public_configs',
    items('public_configs', labelOf),
    _strings(gnTarget['public_configs']).map(labelOf).toSet(),
    subset: true,
  );
  check(
    'all_dependent_configs',
    (inherited[target.name] ?? const <String>{}).map(labelOf).toSet(),
    _strings(gnTarget['all_dependent_configs']).map(labelOf).toSet(),
  );
  if (type == 'config') {
    check('defines', items('defines', (String s) => s), _strings(gnTarget['defines']).toSet());
    check(
      'include_dirs',
      items('include_dirs', path),
      _strings(gnTarget['include_dirs']).map(path).toSet(),
    );
  }
  for (final u in undecided) {
    stdout.writeln('  $label: $u (undecided; not compared)');
  }
  return differences;
}

void _report(String label, String message) => stdout.writeln('$label $message');

/// Dependencies BUILDCONFIG.gn adds to every executable and shared library:
/// the C++ runtime, which is the Bazel toolchain's.
const Set<String> _toolchainDeps = <String>{
  '//flutter/third_party/libcxx:libcxx',
  '//flutter/third_party/libcxxabi:libcxxabi',
};

Future<Map<String, Object?>> _gnDesc(
  String gn,
  String outDir,
  String pattern, {
  bool failIfMissing = true,
}) async {
  final ProcessResult result = await Process.run(gn, <String>[
    'desc',
    outDir,
    pattern,
    '--format=json',
  ]);
  if (result.exitCode != 0) {
    if (!failIfMissing) {
      return const <String, Object?>{};
    }
    throw StateError('gn desc $pattern failed: ${result.stderr}');
  }
  // gn prints warnings about args.gn ahead of the JSON.
  final stdout = result.stdout as String;
  return jsonDecode(stdout.substring(stdout.indexOf('{'))) as Map<String, Object?>;
}

List<String> _strings(Object? json) =>
    json is List<Object?> ? json.cast<String>() : const <String>[];

/// `//flutter/skia`, `:x`, `modules/skcms` and `//a/b:c` as `//dir:name`.
String _absoluteLabel(String value, String gnPackage) {
  var label = value.startsWith(':')
      ? '$gnPackage$value'
      : value.startsWith('//')
      ? value
      : '$gnPackage/$value';
  if (!label.contains(':')) {
    label = '$label:${label.substring(label.lastIndexOf('/') + 1)}';
  }
  return label;
}

String _stripToolchain(String label) {
  final int paren = label.indexOf('(');
  return paren < 0 ? label : label.substring(0, paren);
}

/// A GN path as `//dir/file`, without a trailing slash (gn desc lists
/// include directories with one).
String _absolutePath(String value, String gnPackage) {
  final absolute = value.startsWith('//') ? value : '$gnPackage/$value';
  return p.posix.normalize(absolute);
}

String _defaultRoot() {
  // tool/gn_desc_diff.dart lives at engine/src/flutter/tools/gn_to_bazel/tool.
  return p.normalize(p.join(p.dirname(p.fromUri(Platform.script)), '../../../..'));
}
