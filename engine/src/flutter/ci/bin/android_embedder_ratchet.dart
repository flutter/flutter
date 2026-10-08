// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Ratchet for moving the Android embedder onto the embedder C API in place.
//
// Counts how `shell/platform/android` couples to engine internals and compares
// the counts with the ones recorded in [ratchetFilePath].
//
//  * `check` fails if a count differs from the recorded one. A higher count is
//    a regression. A lower count must be recorded with `update` in the same
//    change, so it can never silently rise again.
//  * `update` records the current counts. It refuses to record a higher count
//    for a ratcheted metric unless the metric is named with --allow-increase
//    and a --reason is given. The reason is kept in the file's history, so
//    every increase shows up in review.
//
// Metrics whose enforcement is `zero` must be zero. The last change of the
// migration switches the end-state metrics to `zero`.
//
// Run with --help for usage.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// The recorded counts, relative to `engine/src/flutter`.
const String ratchetFilePath = 'shell/platform/android/embedder_convergence_ratchet.json';

/// The directory that is measured, relative to `engine/src/flutter`.
const String androidDir = 'shell/platform/android';

/// The JNI glue whose direct `PlatformViewAndroid` calls are counted.
const String jniImplFile = '$androidDir/platform_view_android_jni_impl.cc';

/// The header whose `PlatformView` overrides are counted.
const String platformViewAndroidHeader = '$androidDir/platform_view_android.h';

/// The build file and target whose engine dependencies are counted.
const String androidBuildFile = '$androidDir/BUILD.gn';

/// The GN target that owns the Android shell sources.
const String androidShellTarget = 'flutter_shell_native_src';

/// Exit code for a failed check or a refused update.
const int exitFailure = 1;

/// Exit code for bad command line usage (EX_USAGE from sysexits.h).
const int exitUsage = 64;

/// Include prefixes (relative to `flutter/`) that the Android shell may use
/// in the end state. `common/graphics/` is a separate GN target with
/// rendering dependencies, so it is not part of `common/`.
const List<String> allowedIncludePrefixes = <String>[
  'fml/',
  'common/',
  'assets/',
  '$androidDir/',
  'shell/platform/embedder/embedder.h',
];

/// Include prefixes that are not allowed even though a prefix in
/// [allowedIncludePrefixes] matches them.
const List<String> disallowedIncludePrefixes = <String>['common/graphics/'];

/// Top-level directories of `engine/src/flutter`. A quoted include that does
/// not start with `flutter/` is resolved against these, because the engine
/// puts `//flutter` on the include path (for example `"common/settings.h"`).
const List<String> engineTopLevelDirs = <String>[
  'assets',
  'common',
  'display_list',
  'flow',
  'fml',
  'impeller',
  'lib',
  'runtime',
  'shell',
  'skia',
  'third_party',
  'txt',
  'vulkan',
];

/// GN labels :flutter_shell_native_src may depend on in the end state.
const Set<String> allowedGnLabels = <String>{
  '//flutter/assets',
  '//flutter/common',
  '//flutter/fml',
  '//flutter/shell/platform/embedder:embedder_as_internal_library',
  '//flutter/shell/platform/embedder:embedder_headers',
};

/// How `check` treats a metric.
enum Enforcement {
  /// The count may only go down, and every change must be recorded.
  ratchet,

  /// The count must be zero.
  zero,

  /// The count is recorded for review. `check` reports a change but does not
  /// fail.
  report,
}

/// Thrown when the ratchet file is malformed or an update is refused.
class RatchetException implements Exception {
  RatchetException(this.message);

  final String message;

  @override
  String toString() => 'RatchetException: $message';
}

/// The non-test C++ sources of the Android shell, plus the two files that
/// per-file metrics read.
@immutable
class AndroidSources {
  const AndroidSources({required this.files, required this.buildGn});

  /// Reads the sources below [flutterRoot] (`engine/src/flutter`).
  factory AndroidSources.load(Directory flutterRoot) {
    final root = Directory(path.join(flutterRoot.path, androidDir));
    if (!root.existsSync()) {
      throw RatchetException('${root.path} does not exist.');
    }
    final files = <String, String>{};
    for (final FileSystemEntity entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final String relative = path.posix.joinAll(
        path.split(path.relative(entity.path, from: flutterRoot.path)),
      );
      if (!isCppSource(relative) || isTestSource(relative)) {
        continue;
      }
      files[relative] = entity.readAsStringSync();
    }
    final buildGn = File(path.join(flutterRoot.path, androidBuildFile));
    if (!buildGn.existsSync()) {
      throw RatchetException('${buildGn.path} does not exist.');
    }
    return AndroidSources(files: files, buildGn: buildGn.readAsStringSync());
  }

  /// Contents of each non-test C++ source, keyed by its path relative to
  /// `engine/src/flutter`, using `/` separators.
  final Map<String, String> files;

  /// Contents of [androidBuildFile].
  final String buildGn;

  /// Counts [pattern] in the code of every file, ignoring comments and the
  /// contents of string and character literals.
  int countInCode(RegExp pattern, {String? onlyFile}) {
    var total = 0;
    for (final MapEntry<String, String> entry in files.entries) {
      if (onlyFile != null && entry.key != onlyFile) {
        continue;
      }
      total += pattern.allMatches(stripCommentsAndLiterals(entry.value)).length;
    }
    return total;
  }

  /// Counts quoted includes, resolved relative to `flutter/`, for which
  /// [test] returns true.
  int countIncludes(bool Function(String flutterRelativePath) test) {
    var total = 0;
    for (final String source in files.values) {
      for (final String include in quotedIncludes(source)) {
        final String? resolved = resolveEngineInclude(include);
        if (resolved != null && test(resolved)) {
          total++;
        }
      }
    }
    return total;
  }
}

/// A coupling count.
@immutable
class Metric {
  const Metric({
    required this.name,
    required this.description,
    required this.defaultEnforcement,
    required this.measure,
  });

  final String name;
  final String description;

  /// The enforcement used when the metric is first recorded.
  final Enforcement defaultEnforcement;

  final int Function(AndroidSources sources) measure;
}

/// Every metric, in the order they are reported and recorded.
final List<Metric> allMetrics = <Metric>[
  Metric(
    name: 'shell_refs',
    description: 'Code references to flutter::Shell.',
    defaultEnforcement: Enforcement.ratchet,
    measure: (AndroidSources s) => s.countInCode(RegExp(r'\bShell\b')),
  ),
  Metric(
    name: 'get_shell_calls',
    description: 'Calls to GetShell(), GetShellPointer() or GetShellForTesting().',
    defaultEnforcement: Enforcement.ratchet,
    measure: (AndroidSources s) => s.countInCode(RegExp(r'\bGetShell(?:Pointer|ForTesting)?\s*\(')),
  ),
  Metric(
    name: 'embedder_engine_refs',
    description: 'References to flutter::EmbedderEngine, the type behind the C API handle.',
    defaultEnforcement: Enforcement.ratchet,
    measure: (AndroidSources s) => s.countInCode(RegExp(r'\bEmbedderEngine\b')),
  ),
  Metric(
    name: 'embedder_internal_includes',
    description: 'Includes of shell/platform/embedder headers other than embedder.h.',
    defaultEnforcement: Enforcement.ratchet,
    measure: (AndroidSources s) => s.countIncludes(isEmbedderInternalInclude),
  ),
  Metric(
    name: 'engine_internal_includes',
    description:
        'Includes of engine headers outside fml, common, assets, embedder.h '
        'and the Android shell.',
    defaultEnforcement: Enforcement.ratchet,
    measure: (AndroidSources s) => s.countIncludes(isEngineInternalInclude),
  ),
  Metric(
    name: 'jni_platform_view_calls',
    description: 'JNI entry points that call PlatformViewAndroid instead of the C API.',
    defaultEnforcement: Enforcement.ratchet,
    measure: (AndroidSources s) => s.countInCode(
      RegExp(r'\bANDROID_SHELL_HOLDER\s*->\s*GetPlatformView\s*\('),
      onlyFile: jniImplFile,
    ),
  ),
  Metric(
    name: 'platform_view_android_overrides',
    description: 'PlatformView overrides declared by PlatformViewAndroid (destructor excluded).',
    defaultEnforcement: Enforcement.ratchet,
    measure: (AndroidSources s) {
      final String? header = s.files[platformViewAndroidHeader];
      return header == null ? 0 : countClassOverrides(header, 'PlatformViewAndroid');
    },
  ),
  Metric(
    name: 'gn_internal_deps',
    description: 'Direct //flutter deps of :$androidShellTarget outside the allowed set.',
    defaultEnforcement: Enforcement.report,
    measure: (AndroidSources s) =>
        gnDepLabels(s.buildGn, androidShellTarget).where(isDisallowedGnLabel).length,
  ),
];

/// Whether [relativePath] is a C++ source or header.
bool isCppSource(String relativePath) {
  final String extension = path.posix.extension(relativePath);
  return extension == '.cc' || extension == '.h';
}

/// Whether [relativePath] is a test, mock or test-support file.
bool isTestSource(String relativePath) {
  final List<String> segments = path.posix.split(relativePath);
  if (segments.contains('test') || segments.contains('testing')) {
    return true;
  }
  final String name = segments.last;
  return name.contains('unittest') || name.contains('_mock') || name.startsWith('mock_');
}

/// Removes comments and the contents of string and character literals from
/// C++ [source]. Newlines are kept so the line structure is preserved.
String stripCommentsAndLiterals(String source) {
  final out = StringBuffer();
  var i = 0;
  while (i < source.length) {
    final String c = source[i];
    final String next = i + 1 < source.length ? source[i + 1] : '';
    if (c == '/' && next == '/') {
      final int end = source.indexOf('\n', i);
      if (end == -1) {
        break;
      }
      i = end;
      continue;
    }
    if (c == '/' && next == '*') {
      final int end = source.indexOf('*/', i + 2);
      final String comment = end == -1 ? source.substring(i) : source.substring(i, end + 2);
      out.write('\n' * '\n'.allMatches(comment).length);
      if (end == -1) {
        break;
      }
      i = end + 2;
      continue;
    }
    if (c == '"' && i > 0 && source[i - 1] == 'R') {
      // Raw string literal: R"delimiter( ... )delimiter".
      final int open = source.indexOf('(', i);
      if (open != -1) {
        final String delimiter = source.substring(i + 1, open);
        final int close = source.indexOf(')$delimiter"', open);
        if (close != -1) {
          final String body = source.substring(i, close + delimiter.length + 2);
          out.write('""');
          out.write('\n' * '\n'.allMatches(body).length);
          i = close + delimiter.length + 2;
          continue;
        }
      }
    }
    final bool startsCharLiteral =
        c == "'" && (i == 0 || !RegExp(r'[0-9A-Za-z_]').hasMatch(source[i - 1]));
    if (c == '"' || startsCharLiteral) {
      out.write(c);
      i++;
      while (i < source.length && source[i] != c && source[i] != '\n') {
        i += source[i] == r'\' ? 2 : 1;
      }
      if (i < source.length && source[i] == c) {
        out.write(c);
        i++;
      }
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

/// Counts the `override` declarations in the body of [className] in C++
/// [source], not counting the destructor. Returns 0 if the class is absent.
int countClassOverrides(String source, String className) {
  final String code = stripCommentsAndLiterals(source);
  final Match? header = RegExp(r'\bclass\s+' + RegExp.escape(className) + r'\b[^;{]*\{')
      .firstMatch(code);
  if (header == null) {
    return 0;
  }
  final String body = code.substring(header.end, _matchingBrace(code, header.end - 1));
  final int overrides = RegExp(r'\boverride\b').allMatches(body).length;
  final int destructors = RegExp(
    '~${RegExp.escape(className)}'
    r'\s*\(\s*\)\s*override\b',
  ).allMatches(body).length;
  return overrides - destructors;
}

/// The paths of the quoted `#include` directives in [source], in order.
List<String> quotedIncludes(String source) {
  return RegExp(
    r'^\s*#\s*include\s*"([^"]+)"',
    multiLine: true,
  ).allMatches(source).map((RegExpMatch m) => m.group(1)!).toList();
}

/// Resolves a quoted include to a path relative to `engine/src/flutter`, or
/// returns null if it does not name an engine header.
String? resolveEngineInclude(String include) {
  if (include.startsWith('flutter/')) {
    return include.substring('flutter/'.length);
  }
  final String first = include.split('/').first;
  if (include.contains('/') && engineTopLevelDirs.contains(first)) {
    return include;
  }
  return null;
}

/// Whether a resolved include names an embedder header other than the public
/// API.
bool isEmbedderInternalInclude(String flutterRelativePath) {
  return flutterRelativePath.startsWith('shell/platform/embedder/') &&
      flutterRelativePath != 'shell/platform/embedder/embedder.h';
}

/// Whether a resolved include names an engine header that the Android shell
/// may not use in the end state. Embedder headers are counted separately by
/// [isEmbedderInternalInclude].
bool isEngineInternalInclude(String flutterRelativePath) {
  if (flutterRelativePath.startsWith('shell/platform/embedder/')) {
    return false;
  }
  if (disallowedIncludePrefixes.any(flutterRelativePath.startsWith)) {
    return true;
  }
  return !allowedIncludePrefixes.any(flutterRelativePath.startsWith);
}

/// Whether a GN dependency label counts towards `gn_internal_deps`. Targets
/// of the Android shell itself are excluded.
bool isDisallowedGnLabel(String label) {
  if (!label.startsWith('//flutter/')) {
    return false;
  }
  if (label == '//flutter/$androidDir' ||
      label.startsWith('//flutter/$androidDir/') ||
      label.startsWith('//flutter/$androidDir:')) {
    return false;
  }
  final String canonical = _canonicalGnLabel(label);
  return !allowedGnLabels.contains(canonical);
}

/// `//a/b:b` and `//a/b` name the same target.
String _canonicalGnLabel(String label) {
  final int colon = label.indexOf(':');
  if (colon == -1) {
    return label;
  }
  final String dir = label.substring(0, colon);
  final String name = label.substring(colon + 1);
  return path.posix.basename(dir) == name ? dir : label;
}

/// The labels listed in `deps` and `public_deps` of [target] in [buildGn],
/// including conditional `+=` additions.
List<String> gnDepLabels(String buildGn, String target) {
  final Match? header = RegExp(r'\b\w+\(\s*"' + RegExp.escape(target) + r'"\s*\)\s*\{')
      .firstMatch(buildGn);
  if (header == null) {
    throw RatchetException('GN target "$target" not found.');
  }
  final int bodyStart = header.end;
  final int bodyEnd = _matchingBrace(buildGn, bodyStart - 1);
  final String body = buildGn.substring(bodyStart, bodyEnd);
  final labels = <String>[];
  for (final RegExpMatch list in RegExp(
    r'\b(?:public_deps|deps)\s*\+?=\s*\[([^\]]*)\]',
  ).allMatches(body)) {
    for (final RegExpMatch label in RegExp(r'"([^"]+)"').allMatches(list.group(1)!)) {
      labels.add(label.group(1)!);
    }
  }
  return labels;
}

int _matchingBrace(String text, int openIndex) {
  var depth = 0;
  var inString = false;
  for (var i = openIndex; i < text.length; i++) {
    final String c = text[i];
    if (inString) {
      if (c == r'\') {
        i++;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '#') {
      final int end = text.indexOf('\n', i);
      if (end == -1) {
        break;
      }
      i = end;
      continue;
    }
    if (c == '"') {
      inString = true;
    } else if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  throw RatchetException('Unbalanced braces in GN file.');
}

/// Measures every metric in [sources].
Map<String, int> measure(AndroidSources sources) {
  return <String, int>{
    for (final Metric metric in allMetrics) metric.name: metric.measure(sources),
  };
}

/// One recorded metric.
@immutable
class RecordedMetric {
  const RecordedMetric({required this.count, required this.enforcement});

  final int count;
  final Enforcement enforcement;
}

/// A recorded increase of a ratcheted metric.
@immutable
class Increase {
  const Increase({
    required this.metric,
    required this.from,
    required this.to,
    required this.reason,
  });

  final String metric;
  final int from;
  final int to;
  final String reason;
}

/// The contents of [ratchetFilePath].
@immutable
class RatchetFile {
  const RatchetFile({required this.metrics, required this.history});

  factory RatchetFile.parse(String json) {
    final Object? decoded = jsonDecode(json);
    if (decoded is! Map<String, Object?>) {
      throw RatchetException('The ratchet file must contain a JSON object.');
    }
    final Object? rawMetrics = decoded['metrics'];
    if (rawMetrics is! Map<String, Object?>) {
      throw RatchetException('"metrics" must be an object.');
    }
    final recorded = <String, RecordedMetric>{};
    rawMetrics.forEach((String name, Object? value) {
      if (value is! Map<String, Object?> || value['count'] is! int || value['enforce'] is! String) {
        throw RatchetException('Metric "$name" must have an int "count" and a string "enforce".');
      }
      recorded[name] = RecordedMetric(
        count: value['count']! as int,
        enforcement: _parseEnforcement(value['enforce']! as String),
      );
    });
    final Object rawHistory = decoded['history'] ?? <Object?>[];
    if (rawHistory is! List<Object?>) {
      throw RatchetException('"history" must be a list.');
    }
    final history = <Increase>[];
    for (final Object? entry in rawHistory) {
      if (entry is! Map<String, Object?> ||
          entry['metric'] is! String ||
          entry['from'] is! int ||
          entry['to'] is! int ||
          entry['reason'] is! String) {
        throw RatchetException('Malformed history entry: $entry');
      }
      history.add(
        Increase(
          metric: entry['metric']! as String,
          from: entry['from']! as int,
          to: entry['to']! as int,
          reason: entry['reason']! as String,
        ),
      );
    }
    return RatchetFile(metrics: recorded, history: history);
  }

  final Map<String, RecordedMetric> metrics;
  final List<Increase> history;

  String toJson() {
    final Object json = <String, Object?>{
      'comment':
          'Coupling counts for shell/platform/android. Maintained by '
          'ci/bin/android_embedder_ratchet.dart; run its "update" command '
          'instead of editing counts by hand.',
      'metrics': <String, Object?>{
        for (final MapEntry<String, RecordedMetric> e in metrics.entries)
          e.key: <String, Object?>{'count': e.value.count, 'enforce': e.value.enforcement.name},
      },
      'history': <Object?>[
        for (final Increase i in history)
          <String, Object?>{'metric': i.metric, 'from': i.from, 'to': i.to, 'reason': i.reason},
      ],
    };
    return '${const JsonEncoder.withIndent('  ').convert(json)}\n';
  }
}

Enforcement _parseEnforcement(String name) {
  for (final Enforcement value in Enforcement.values) {
    if (value.name == name) {
      return value;
    }
  }
  throw RatchetException('Unknown enforcement "$name".');
}

/// The outcome of comparing measured counts with recorded ones.
@immutable
class CheckResult {
  const CheckResult({required this.errors, required this.notes});

  /// Problems that fail the check.
  final List<String> errors;

  /// Changes to report-only metrics.
  final List<String> notes;

  bool get passed => errors.isEmpty;
}

/// Compares [current] with [recorded].
CheckResult check(RatchetFile recorded, Map<String, int> current) {
  final errors = <String>[];
  final notes = <String>[];
  for (final MapEntry<String, int> entry in current.entries) {
    final String name = entry.key;
    final int now = entry.value;
    final RecordedMetric? was = recorded.metrics[name];
    if (was == null) {
      errors.add('$name is not recorded. Run "update" to record it.');
      continue;
    }
    switch (was.enforcement) {
      case Enforcement.zero:
        if (now != 0) {
          errors.add('$name must be 0 but is $now.');
        }
      case Enforcement.ratchet:
        if (now > was.count) {
          errors.add('$name rose from ${was.count} to $now.');
        } else if (now < was.count) {
          errors.add(
            '$name dropped from ${was.count} to $now. Run "update" to record '
            'the lower count so it cannot rise again.',
          );
        }
      case Enforcement.report:
        if (now != was.count) {
          notes.add('$name changed from ${was.count} to $now (report only).');
        }
    }
  }
  for (final String name in recorded.metrics.keys) {
    if (!current.containsKey(name)) {
      errors.add('$name is recorded but no longer measured. Remove it with "update".');
    }
  }
  return CheckResult(errors: errors, notes: notes);
}

/// Returns [recorded] with the counts replaced by [current].
///
/// A ratcheted metric may only rise if it is in [allowIncrease], in which
/// case [reason] is required and recorded. [enforce] changes the enforcement
/// of the named metrics; switching to [Enforcement.zero] requires a count of
/// zero.
RatchetFile update(
  RatchetFile recorded,
  Map<String, int> current, {
  Set<String> allowIncrease = const <String>{},
  String? reason,
  Map<String, Enforcement> enforce = const <String, Enforcement>{},
}) {
  for (final name in <String>{...allowIncrease, ...enforce.keys}) {
    if (!current.containsKey(name)) {
      throw RatchetException('Unknown metric "$name".');
    }
  }
  if (allowIncrease.isNotEmpty && (reason == null || reason.trim().isEmpty)) {
    throw RatchetException('--allow-increase requires --reason.');
  }
  final defaults = <String, Enforcement>{
    for (final Metric metric in allMetrics) metric.name: metric.defaultEnforcement,
  };
  final updated = <String, RecordedMetric>{};
  final history = <Increase>[...recorded.history];
  final refused = <String>[];
  for (final MapEntry<String, int> entry in current.entries) {
    final String name = entry.key;
    final int now = entry.value;
    final RecordedMetric? was = recorded.metrics[name];
    final Enforcement enforcement =
        enforce[name] ?? was?.enforcement ?? defaults[name] ?? Enforcement.ratchet;
    if (enforcement == Enforcement.zero && now != 0) {
      refused.add('$name must be 0 to be enforced as zero, but is $now.');
      continue;
    }
    if (was != null && was.enforcement == Enforcement.ratchet && now > was.count) {
      if (!allowIncrease.contains(name)) {
        refused.add(
          '$name rose from ${was.count} to $now. Pass --allow-increase=$name '
          'with a --reason if the increase is intended.',
        );
        continue;
      }
      history.add(Increase(metric: name, from: was.count, to: now, reason: reason!.trim()));
    }
    updated[name] = RecordedMetric(count: now, enforcement: enforcement);
  }
  if (refused.isNotEmpty) {
    throw RatchetException(refused.join('\n'));
  }
  return RatchetFile(metrics: updated, history: history);
}

/// The `engine/src/flutter` directory that contains this script.
Directory _defaultFlutterRoot() {
  return Directory(
    path.normalize(path.join(path.dirname(Platform.script.toFilePath()), '..', '..')),
  );
}

ArgParser _buildParser() {
  return ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage information.')
    ..addOption(
      'flutter-root',
      help: 'The engine/src/flutter directory to measure.',
      defaultsTo: _defaultFlutterRoot().path,
    )
    ..addMultiOption(
      'allow-increase',
      help: '(update) Metrics that may rise. Requires --reason.',
      valueHelp: 'metric',
    )
    ..addOption('reason', help: '(update) Why the --allow-increase metrics rose.')
    ..addMultiOption(
      'enforce',
      help: '(update) Change how a metric is enforced: ratchet, zero or report.',
      valueHelp: 'metric=enforcement',
    );
}

String _usage(ArgParser parser) {
  return 'Usage: dart ci/bin/android_embedder_ratchet.dart <check|update> [options]\n\n'
      '  check   Fail if a count differs from $ratchetFilePath.\n'
      '  update  Record the current counts.\n\n'
      '${parser.usage}\n\n'
      'Metrics:\n'
      '${allMetrics.map((Metric m) => '  ${m.name}: ${m.description}').join('\n')}';
}

String _table(RatchetFile recorded, Map<String, int> current) {
  final rows = <String>[
    '${'metric'.padRight(32)}${'recorded'.padLeft(9)}${'current'.padLeft(9)}  enforce',
  ];
  for (final Metric metric in allMetrics) {
    final RecordedMetric? was = recorded.metrics[metric.name];
    rows.add(
      '${metric.name.padRight(32)}'
      '${(was?.count.toString() ?? '-').padLeft(9)}'
      '${current[metric.name].toString().padLeft(9)}'
      '  ${was?.enforcement.name ?? '-'}',
    );
  }
  return rows.join('\n');
}

Future<void> main(List<String> args) async {
  final ArgParser parser = _buildParser();
  final ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n${_usage(parser)}');
    exitCode = exitUsage;
    return;
  }
  if (options['help'] as bool) {
    stdout.writeln(_usage(parser));
    return;
  }
  if (options.rest.length != 1 || !<String>{'check', 'update'}.contains(options.rest.single)) {
    stderr.writeln(_usage(parser));
    exitCode = exitUsage;
    return;
  }
  final flutterRoot = Directory(options['flutter-root'] as String);
  final ratchetFile = File(path.join(flutterRoot.path, ratchetFilePath));
  try {
    final Map<String, int> current = measure(AndroidSources.load(flutterRoot));
    final recorded = ratchetFile.existsSync()
        ? RatchetFile.parse(ratchetFile.readAsStringSync())
        : const RatchetFile(metrics: <String, RecordedMetric>{}, history: <Increase>[]);
    stdout.writeln(_table(recorded, current));
    if (options.rest.single == 'check') {
      final CheckResult result = check(recorded, current);
      for (final String note in result.notes) {
        stdout.writeln('NOTE: $note');
      }
      for (final String error in result.errors) {
        stderr.writeln('ERROR: $error');
      }
      if (!result.passed) {
        exitCode = exitFailure;
      }
      return;
    }
    final enforce = <String, Enforcement>{};
    for (final spec in options['enforce'] as List<String>) {
      final int equals = spec.indexOf('=');
      if (equals == -1) {
        throw RatchetException('--enforce expects metric=enforcement, got "$spec".');
      }
      enforce[spec.substring(0, equals)] = _parseEnforcement(spec.substring(equals + 1));
    }
    final RatchetFile updated = update(
      recorded,
      current,
      allowIncrease: (options['allow-increase'] as List<String>).toSet(),
      reason: options['reason'] as String?,
      enforce: enforce,
    );
    ratchetFile.writeAsStringSync(updated.toJson());
    stdout.writeln('Wrote ${ratchetFile.path}');
  } on RatchetException catch (e) {
    stderr.writeln('ERROR: ${e.message}');
    exitCode = exitFailure;
  }
}
