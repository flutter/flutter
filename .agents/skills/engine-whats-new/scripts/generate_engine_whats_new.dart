// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

class CommitInfo {
  CommitInfo({
    required this.hash,
    required this.shortHash,
    required this.author,
    required this.date,
    required this.title,
    this.prNumber,
  });

  final String hash;
  final String shortHash;
  final String author;
  final String date;
  final String title;
  final String? prNumber;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'hash': hash,
    'shortHash': shortHash,
    'author': author,
    'date': date,
    'title': title,
    'prNumber': prNumber,
  };
}

class ReleaseAnalysis {
  ReleaseAnalysis({
    required this.baseRelease,
    required this.baseRef,
    required this.targetRelease,
    required this.targetRef,
    required this.enginePath,
    required this.diffPath,
    required this.summaryPath,
    required this.totalCommits,
    required this.filesChanged,
    required this.insertions,
    required this.deletions,
    required this.categorizedCommits,
  });

  final String baseRelease;
  final String baseRef;
  final String targetRelease;
  final String targetRef;
  final String enginePath;
  final String diffPath;
  final String summaryPath;
  final int totalCommits;
  final int filesChanged;
  final int insertions;
  final int deletions;
  final Map<String, List<CommitInfo>> categorizedCommits;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'baseRelease': baseRelease,
    'baseRef': baseRef,
    'targetRelease': targetRelease,
    'targetRef': targetRef,
    'enginePath': enginePath,
    'diffPath': diffPath,
    'summaryPath': summaryPath,
    'stats': <String, dynamic>{
      'totalCommits': totalCommits,
      'filesChanged': filesChanged,
      'insertions': insertions,
      'deletions': deletions,
    },
    'categories': categorizedCommits.map(
      (String key, List<CommitInfo> value) =>
          MapEntry<String, dynamic>(key, value.map((CommitInfo c) => c.toJson()).toList()),
    ),
  };
}

Directory findRepoRoot() {
  Directory dir = Directory.current;
  while (dir.path != dir.parent.path) {
    if (Directory('${dir.path}/.git').existsSync()) {
      return dir;
    }
    dir = dir.parent;
  }
  return Directory.current;
}

ProcessResult runGit(List<String> args, {required String workingDirectory}) {
  final ProcessResult result = Process.runSync('git', args, workingDirectory: workingDirectory);
  if (result.exitCode != 0) {
    throw ProcessException('git', args, result.stderr.toString(), result.exitCode);
  }
  return result;
}

String? tryResolveGitRef(String version, String repoRoot) {
  final String cleanVersion = version.trim();
  final candidates = <String>[
    cleanVersion,
    if (!cleanVersion.contains('.')) '3.$cleanVersion.0',
    if (cleanVersion.startsWith('3.') &&
        !cleanVersion.contains('-') &&
        cleanVersion.split('.').length == 2)
      '$cleanVersion.0',
    'origin/flutter-$cleanVersion-candidate.0',
    'flutter-$cleanVersion-candidate.0',
    if (cleanVersion.startsWith('3.'))
      'origin/flutter-${cleanVersion.split('.').take(2).join('.')}-candidate.0',
    if (cleanVersion.startsWith('3.'))
      'flutter-${cleanVersion.split('.').take(2).join('.')}-candidate.0',
    'v$cleanVersion',
    'v$cleanVersion.0',
  ];

  for (final candidate in candidates) {
    try {
      final ProcessResult res = Process.runSync('git', <String>[
        'rev-parse',
        '--verify',
        candidate,
      ], workingDirectory: repoRoot);
      if (res.exitCode == 0) {
        return candidate;
      }
    } catch (_) {}
  }

  try {
    final ProcessResult tagResult = Process.runSync('git', <String>[
      'tag',
      '-l',
      '*$cleanVersion*',
    ], workingDirectory: repoRoot);
    if (tagResult.exitCode == 0) {
      final tagOutput = tagResult.stdout as String;
      final List<String> tags = tagOutput
          .split('\n')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
      if (tags.isNotEmpty) {
        for (final tag in tags) {
          if (tag == cleanVersion || tag == '$cleanVersion.0') {
            return tag;
          }
        }
        return tags.first;
      }
    }
  } catch (_) {}

  return null;
}

String deducePreviousRelease(String targetRelease) {
  final String normalized = targetRelease
      .replaceFirst('flutter-', '')
      .replaceFirst('-candidate.0', '');
  final List<String> parts = normalized.split('.');
  if (parts.length >= 2 && parts[0] == '3') {
    final int? minor = int.tryParse(parts[1]);
    if (minor != null) {
      int prevMinor = minor - 3;
      if (prevMinor == 28) {
        prevMinor = 27;
      }
      if (prevMinor > 0) {
        return '3.$prevMinor';
      }
    }
  }
  return '';
}

String? extractPrNumber(String title) {
  final RegExpMatch? match = RegExp(r'#(\d+)').firstMatch(title);
  return match?.group(1);
}

String categorizeCommit(String title) {
  final String lower = title.toLowerCase();

  if (title.startsWith('Roll Skia') ||
      title.startsWith('Roll Dart SDK') ||
      title.startsWith('Roll ICU') ||
      title.startsWith('Roll HarfBuzz') ||
      title.startsWith('Roll ANGLE') ||
      lower.contains('roll skia') ||
      lower.contains('roll dart sdk') ||
      lower.contains('roll icu')) {
    return '🔄 Dependency Rolls';
  }

  if (lower.contains('impeller') ||
      lower.contains('ubersdf') ||
      lower.contains('flutter gpu') ||
      lower.contains('display_list') ||
      lower.contains('displaylist') ||
      lower.contains('vulkan') ||
      lower.contains('metal') ||
      lower.contains('opengl') ||
      lower.contains('shader') ||
      lower.contains('render') ||
      lower.contains('flow')) {
    return '🚀 Impeller & Graphics Rendering';
  }

  if (lower.contains('[web]') ||
      lower.contains('web_ui') ||
      lower.contains('web_sdk') ||
      lower.contains('wasm') ||
      lower.contains('skwasm') ||
      lower.contains('html') ||
      lower.contains('canvaskit')) {
    return '🌐 Web Engine & Wasm';
  }

  if (lower.contains('[android]') ||
      lower.contains('android') ||
      lower.contains('agp') ||
      lower.contains('gradle') ||
      lower.contains('embedding/engine')) {
    return '📱 Android Embedding';
  }

  if (lower.contains('[ios]') ||
      lower.contains('[macos]') ||
      lower.contains('[darwin]') ||
      lower.contains('darwin') ||
      lower.contains('ios') ||
      lower.contains('macos') ||
      lower.contains('xcode') ||
      lower.contains('metalview')) {
    return '🍎 iOS & macOS Embeddings';
  }

  if (lower.contains('[windows]') ||
      lower.contains('[linux]') ||
      lower.contains('windows') ||
      lower.contains('linux') ||
      lower.contains('win32') ||
      lower.contains('embedder')) {
    return '🪟 Windows & Linux Desktop Embeddings';
  }

  if (lower.contains('[a11y]') ||
      lower.contains('semantics') ||
      lower.contains('accessibility') ||
      lower.contains('typography') ||
      lower.contains('txt') ||
      lower.contains('font') ||
      lower.contains('text input') ||
      lower.contains('autofill')) {
    return '🔤 Text, Typography & Accessibility';
  }

  if (lower.contains('[ci]') ||
      lower.contains('ci:') ||
      lower.contains('build.gn') ||
      lower.contains('tools') ||
      lower.contains('testing') ||
      lower.contains('header_guard') ||
      lower.contains('license') ||
      lower.contains('format')) {
    return '🛠️ Build System, CI & Tooling';
  }

  return '⚙️ Core Runtime & Shell';
}

ReleaseAnalysis analyzeEngineDiff({
  required String repoRoot,
  required String baseRelease,
  required String targetRelease,
  String enginePath = 'engine/src/flutter',
  String? outputDiffPath,
  String? outputSummaryPath,
}) {
  final String? baseRef = tryResolveGitRef(baseRelease, repoRoot);
  if (baseRef == null) {
    throw ArgumentError('Could not resolve git reference for base release "$baseRelease".');
  }

  final String? targetRef = tryResolveGitRef(targetRelease, repoRoot);
  if (targetRef == null) {
    throw ArgumentError('Could not resolve git reference for target release "$targetRelease".');
  }

  final String resolvedDiffPath =
      outputDiffPath ??
      'engine_diff_${baseRelease.replaceAll('/', '_')}_to_${targetRelease.replaceAll('/', '_')}.diff';
  final String resolvedSummaryPath =
      outputSummaryPath ?? 'engine_whats_new_${targetRelease.replaceAll('/', '_')}.md';

  final ProcessResult diffResult = runGit(<String>[
    'diff',
    '$baseRef..$targetRef',
    '--',
    enginePath,
  ], workingDirectory: repoRoot);
  File('$repoRoot/$resolvedDiffPath').writeAsStringSync(diffResult.stdout as String);

  var filesChanged = 0;
  var insertions = 0;
  var deletions = 0;

  final ProcessResult statResult = runGit(<String>[
    'diff',
    '--shortstat',
    '$baseRef..$targetRef',
    '--',
    enginePath,
  ], workingDirectory: repoRoot);
  final String statStr = (statResult.stdout as String).trim();
  if (statStr.isNotEmpty) {
    final RegExpMatch? filesMatch = RegExp(r'(\d+)\s+files? changed').firstMatch(statStr);
    final RegExpMatch? insMatch = RegExp(r'(\d+)\s+insertions?\(\+\)').firstMatch(statStr);
    final RegExpMatch? delMatch = RegExp(r'(\d+)\s+deletions?\(-\)').firstMatch(statStr);

    if (filesMatch != null) {
      filesChanged = int.parse(filesMatch.group(1)!);
    }
    if (insMatch != null) {
      insertions = int.parse(insMatch.group(1)!);
    }
    if (delMatch != null) {
      deletions = int.parse(delMatch.group(1)!);
    }
  }

  final ProcessResult logResult = runGit(<String>[
    'log',
    '--pretty=format:%H%x09%h%x09%an%x09%ad%x09%s',
    '--date=short',
    '$baseRef..$targetRef',
    '--',
    enginePath,
  ], workingDirectory: repoRoot);

  final List<String> lines = (logResult.stdout as String)
      .split('\n')
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toList();

  final categorized = <String, List<CommitInfo>>{
    '🚀 Impeller & Graphics Rendering': <CommitInfo>[],
    '🌐 Web Engine & Wasm': <CommitInfo>[],
    '📱 Android Embedding': <CommitInfo>[],
    '🍎 iOS & macOS Embeddings': <CommitInfo>[],
    '🪟 Windows & Linux Desktop Embeddings': <CommitInfo>[],
    '🔤 Text, Typography & Accessibility': <CommitInfo>[],
    '🔄 Dependency Rolls': <CommitInfo>[],
    '🛠️ Build System, CI & Tooling': <CommitInfo>[],
    '⚙️ Core Runtime & Shell': <CommitInfo>[],
  };

  for (final line in lines) {
    final List<String> parts = line.split('\t');
    if (parts.length >= 5) {
      final String hash = parts[0];
      final String shortHash = parts[1];
      final String author = parts[2];
      final String date = parts[3];
      final String title = parts.sublist(4).join('\t');
      final String? pr = extractPrNumber(title);

      final commit = CommitInfo(
        hash: hash,
        shortHash: shortHash,
        author: author,
        date: date,
        title: title,
        prNumber: pr,
      );

      final String cat = categorizeCommit(title);
      categorized.putIfAbsent(cat, () => <CommitInfo>[]).add(commit);
    }
  }

  final analysis = ReleaseAnalysis(
    baseRelease: baseRelease,
    baseRef: baseRef,
    targetRelease: targetRelease,
    targetRef: targetRef,
    enginePath: enginePath,
    diffPath: resolvedDiffPath,
    summaryPath: resolvedSummaryPath,
    totalCommits: lines.length,
    filesChanged: filesChanged,
    insertions: insertions,
    deletions: deletions,
    categorizedCommits: categorized,
  );

  final String summaryContent = generateMarkdownSummary(analysis);
  File('$repoRoot/$resolvedSummaryPath').writeAsStringSync(summaryContent);

  return analysis;
}

String generateMarkdownSummary(ReleaseAnalysis analysis) {
  final buffer = StringBuffer();

  buffer.writeln("# What's New in Flutter Engine (Release ${analysis.targetRelease})");
  buffer.writeln();
  buffer.writeln(
    'Comparing changes in `//${analysis.enginePath}` from **${analysis.baseRelease}** (`${analysis.baseRef}`) to **${analysis.targetRelease}** (`${analysis.targetRef}`).',
  );
  buffer.writeln();
  buffer.writeln('## 📊 Overview & Statistics');
  buffer.writeln();
  buffer.writeln('- **Diff File Generated:** [${analysis.diffPath}](${analysis.diffPath})');
  buffer.writeln('- **Total Engine Commits:** ${analysis.totalCommits}');
  buffer.writeln('- **Files Changed:** ${analysis.filesChanged}');
  buffer.writeln('- **Lines Added:** +${analysis.insertions}');
  buffer.writeln('- **Lines Removed:** -${analysis.deletions}');
  buffer.writeln();

  buffer.writeln('## 🌟 Subsystem Breakdown');
  buffer.writeln();

  for (final MapEntry<String, List<CommitInfo>> entry in analysis.categorizedCommits.entries) {
    if (entry.value.isEmpty) {
      continue;
    }
    buffer.writeln('### ${entry.key} (${entry.value.length} commits)');
    buffer.writeln();
    for (final CommitInfo c in entry.value) {
      final String prLink = c.prNumber != null
          ? '[#${c.prNumber}](https://github.com/flutter/flutter/pull/${c.prNumber})'
          : c.shortHash;
      buffer.writeln('- ${c.title} ($prLink by *${c.author}*)');
    }
    buffer.writeln();
  }

  return buffer.toString();
}

void printHelp() {
  stdout.writeln("Flutter Engine What's New & Diff Generator");
  stdout.writeln();
  stdout.writeln('Usage:');
  stdout.writeln(
    '  dart generate_engine_whats_new.dart --release <TARGET_RELEASE> [--from <BASE_RELEASE>]',
  );
  stdout.writeln();
  stdout.writeln('Options:');
  stdout.writeln(
    '  --release, --to, --target <version>   Target Flutter release version (e.g. 3.47)',
  );
  stdout.writeln(
    '  --from, --base <version>              Base Flutter release version (e.g. 3.44). If omitted, automatically determined.',
  );
  stdout.writeln(
    '  --engine-path <path>                  Engine directory relative to repo root (default: engine/src/flutter)',
  );
  stdout.writeln(
    '  --output-diff <file>                  Output diff file path (default: engine_diff_<base>_to_<target>.diff)',
  );
  stdout.writeln(
    '  --output-summary <file>               Output summary markdown file path (default: engine_whats_new_<target>.md)',
  );
  stdout.writeln(
    '  --format <markdown|json|text>         Stdout output format (default: markdown)',
  );
  stdout.writeln('  -h, --help                            Show this help message');
}

void main(List<String> args) {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    printHelp();
    exit(args.isEmpty ? 1 : 0);
  }

  String? targetRelease;
  String? baseRelease;
  var enginePath = 'engine/src/flutter';
  String? outputDiff;
  String? outputSummary;
  var format = 'markdown';

  for (var i = 0; i < args.length; i++) {
    final String arg = args[i];
    if ((arg == '--release' || arg == '--to' || arg == '--target') && i + 1 < args.length) {
      targetRelease = args[++i];
    } else if ((arg == '--from' || arg == '--base') && i + 1 < args.length) {
      baseRelease = args[++i];
    } else if (arg == '--engine-path' && i + 1 < args.length) {
      enginePath = args[++i];
    } else if (arg == '--output-diff' && i + 1 < args.length) {
      outputDiff = args[++i];
    } else if (arg == '--output-summary' && i + 1 < args.length) {
      outputSummary = args[++i];
    } else if (arg == '--format' && i + 1 < args.length) {
      format = args[++i].toLowerCase();
    } else if (!arg.startsWith('-') && targetRelease == null) {
      targetRelease = arg;
    }
  }

  if (targetRelease == null) {
    stderr.writeln('Error: Target release version is required (e.g. --release 3.47).');
    printHelp();
    exit(1);
  }

  final String repoRoot = findRepoRoot().path;

  if (baseRelease == null || baseRelease.isEmpty) {
    baseRelease = deducePreviousRelease(targetRelease);
    if (baseRelease.isEmpty) {
      stderr.writeln(
        'Error: Could not automatically deduce previous release for "$targetRelease". Please specify --from <version>.',
      );
      exit(1);
    }
  }

  try {
    final ReleaseAnalysis analysis = analyzeEngineDiff(
      repoRoot: repoRoot,
      baseRelease: baseRelease,
      targetRelease: targetRelease,
      enginePath: enginePath,
      outputDiffPath: outputDiff,
      outputSummaryPath: outputSummary,
    );

    if (format == 'json') {
      stdout.writeln(jsonEncode(analysis.toJson()));
    } else {
      stdout.writeln('Generated Engine Diff: ${analysis.diffPath}');
      stdout.writeln("Generated What's New Summary: ${analysis.summaryPath}");
      stdout.writeln(
        'Total Commits: ${analysis.totalCommits} | Files Changed: ${analysis.filesChanged} (+${analysis.insertions} / -${analysis.deletions})',
      );
    }
  } catch (e) {
    stderr.writeln("Error generating engine what's new: $e");
    exit(1);
  }
}
