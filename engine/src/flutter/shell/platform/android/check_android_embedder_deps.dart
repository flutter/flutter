// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Enforces the 3-Layer Dependency Firewall & Monotonic Header Ratchet (RFC 410, ADR-0010).
// Splits file scanning across multiple Dart Isolates (`Isolate.run`).

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

const List<String> _kInternalPrefixes = <String>[
  'flutter/shell/common/',
  'flutter/flow/',
  'flutter/impeller/',
  'flutter/runtime/',
  'flutter/lib/ui/',
  'flutter/common/graphics/',
  'flutter/shell/gpu/',
  'impeller/',
];

class _FileScanResult {
  const _FileScanResult({
    required this.relPath,
    required this.internalHeaders,
    required this.embedderViolations,
    required this.nogncheckViolations,
  });

  final String relPath;
  final List<String> internalHeaders;
  final List<String> embedderViolations;
  final List<String> nogncheckViolations;
}

Future<List<_FileScanResult>> _scanBatchInIsolate(List<String> filePaths, String androidDir) {
  return Isolate.run(() {
    final includeRegex = RegExp(r'^\s*#\s*include\s+"([^"]+)"');
    final results = <_FileScanResult>[];

    for (final fullPath in filePaths) {
      final String relPath = fullPath.substring(androidDir.length + 1).replaceAll(r'\', '/');
      final List<String> lines = File(fullPath).readAsLinesSync();
      final matchedHeaders = <String>{};
      final embedderViolations = <String>[];
      final nogncheckViolations = <String>[];

      for (var i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (line.contains('nogncheck')) {
          nogncheckViolations.add('$relPath:${i + 1}: prohibited nogncheck comment');
        }

        if (fullPath.endsWith('.gn') || fullPath.endsWith('.gni')) {
          continue;
        }

        final Match? match = includeRegex.firstMatch(line);
        if (match != null) {
          final String header = match.group(1)!;
          final bool isInternal = _kInternalPrefixes.any(header.startsWith);
          if (isInternal) {
            matchedHeaders.add(header);
            if (relPath.startsWith('embedder/')) {
              embedderViolations.add(
                '$relPath:${i + 1}: forbidden internal header "$header" in :flutter_embedder_native_src',
              );
            }
          }
        }
      }

      results.add(
        _FileScanResult(
          relPath: relPath,
          internalHeaders: matchedHeaders.toList()..sort(),
          embedderViolations: embedderViolations,
          nogncheckViolations: nogncheckViolations,
        ),
      );
    }

    return results;
  });
}

List<String> _verifyBuildGnFirewall(String androidDir) {
  final buildGnFile = File('$androidDir/BUILD.gn');
  if (!buildGnFile.existsSync()) {
    return <String>['BUILD.gn not found in shell/platform/android/'];
  }
  final String content = buildGnFile.readAsStringSync();
  final errors = <String>[];
  if (!content.contains('source_set("flutter_embedder_native_src")')) {
    errors.add('BUILD.gn is missing source_set("flutter_embedder_native_src")');
  }
  if (!content.contains('"FLUTTER_ENGINE_NO_PROTOTYPES"')) {
    errors.add('BUILD.gn is missing defines = [ "FLUTTER_ENGINE_NO_PROTOTYPES" ]');
  }
  if (!content.contains('check_includes = true')) {
    errors.add('BUILD.gn is missing check_includes = true');
  }
  return errors;
}

Future<void> main(List<String> args) async {
  final bool generateBaseline = args.contains('--generate-baseline');
  final String androidDir = File.fromUri(Platform.script).parent.path;
  final baselinePath = '$androidDir/allowed_internal_headers.yaml';

  final candidateFiles = <String>[];
  for (final FileSystemEntity entity in Directory(androidDir).listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final String path = entity.path;
    if (path.endsWith('.cc') ||
        path.endsWith('.h') ||
        path.endsWith('.cpp') ||
        path.endsWith('.mm') ||
        path.endsWith('.gn') ||
        path.endsWith('.gni')) {
      candidateFiles.add(path);
    }
  }
  candidateFiles.sort();

  // Split work across 4 worker Isolates.
  const workerCount = 4;
  final int batchSize = (candidateFiles.length / workerCount).ceil();
  final futures = <Future<List<_FileScanResult>>>[];
  for (var i = 0; i < candidateFiles.length; i += batchSize) {
    final int end = (i + batchSize < candidateFiles.length) ? i + batchSize : candidateFiles.length;
    futures.add(_scanBatchInIsolate(candidateFiles.sublist(i, end), androidDir));
  }

  final List<List<_FileScanResult>> batches = await Future.wait(futures);
  final fileToHeaders = <String, List<String>>{};
  final uniqueHeaders = <String>{};
  final embedderViolations = <String>[];
  final nogncheckViolations = <String>[];

  for (final batch in batches) {
    for (final result in batch) {
      if (result.internalHeaders.isNotEmpty) {
        fileToHeaders[result.relPath] = result.internalHeaders;
        uniqueHeaders.addAll(result.internalHeaders);
      }
      embedderViolations.addAll(result.embedderViolations);
      nogncheckViolations.addAll(result.nogncheckViolations);
    }
  }

  final List<String> sortedUniqueHeaders = uniqueHeaders.toList()..sort();
  final sortedLegacyFiles = <String, List<String>>{};
  for (final String key in fileToHeaders.keys.toList()..sort()) {
    sortedLegacyFiles[key] = fileToHeaders[key]!;
  }

  if (generateBaseline) {
    final payload = <String, Object>{
      'allowed_legacy_files': sortedLegacyFiles,
      'allowed_unique_headers': sortedUniqueHeaders,
      'governing_adr': 'ADR-0010',
      'rfc': 'RFC-410.0000',
      'total_allowed_internal_headers': sortedUniqueHeaders.length,
    };
    const encoder = JsonEncoder.withIndent('  ');
    const headerComment =
        '# Copyright 2013 The Flutter Authors. All rights reserved.\n'
        '# Use of this source code is governed by a BSD-style license that can be\n'
        '# found in the LICENSE file.\n'
        '#\n'
        '# JSON-compatible YAML baseline for the 3-Layer Dependency Ratchet (ADR-0010).\n';
    File(baselinePath).writeAsStringSync('$headerComment${encoder.convert(payload)}\n');
    stdout.writeln(
      'Generated $baselinePath with ${sortedUniqueHeaders.length} unique internal headers '
      'across ${sortedLegacyFiles.length} legacy files.',
    );
    return;
  }

  final errors = <String>[
    ..._verifyBuildGnFirewall(androidDir),
    ...embedderViolations,
    ...nogncheckViolations,
  ];

  final baselineFile = File(baselinePath);
  if (!baselineFile.existsSync()) {
    errors.add('Baseline file $baselinePath does not exist.');
  } else {
    final String rawJson = baselineFile
        .readAsLinesSync()
        .where((String line) => !line.trimLeft().startsWith('#'))
        .join('\n');
    final baseline = jsonDecode(rawJson) as Map<String, dynamic>;
    final allowedCount = baseline['total_allowed_internal_headers'] as int;
    final Set<String> allowedHeaders = (baseline['allowed_unique_headers'] as List<dynamic>)
        .cast<String>()
        .toSet();
    final Set<String> allowedFiles = (baseline['allowed_legacy_files'] as Map<String, dynamic>).keys
        .toSet();

    if (sortedUniqueHeaders.length > allowedCount) {
      errors.add(
        'Monotonic header ratchet violation: found ${sortedUniqueHeaders.length} unique '
        'internal headers, which exceeds allowed maximum $allowedCount.',
      );
    }

    final List<String> newHeaders = uniqueHeaders.difference(allowedHeaders).toList()..sort();
    if (newHeaders.isNotEmpty) {
      errors.add('Unauthorized new internal headers introduced: $newHeaders');
    }

    final List<String> newFiles = fileToHeaders.keys.toSet().difference(allowedFiles).toList()
      ..sort();
    if (newFiles.isNotEmpty) {
      errors.add('Unauthorized new files including internal headers: $newFiles');
    }
  }

  if (errors.isNotEmpty) {
    for (final err in errors) {
      stderr.writeln('ERROR: $err');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    '[PASS] Android Embedder Dependency Ratchet verified: '
    '${sortedUniqueHeaders.length} unique internal headers in legacy files, '
    '0 internal headers in embedder/ (:flutter_embedder_native_src).',
  );
}
