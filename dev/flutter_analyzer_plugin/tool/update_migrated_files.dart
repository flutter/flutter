// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

final RegExp _globalsImportPattern = RegExp(r'''^\s*import\s+['"](?:.*\/)?globals\.dart['"]''');

/// Scans [flutterToolsDir] and returns relative POSIX paths (e.g. `'lib/src/commands/clean.dart'`)
/// of all `.dart` files that do not import `globals.dart`.
///
/// Excludes `lib/src/globals.dart` itself.
Set<String> findMigratedFiles(Directory flutterToolsDir) {
  final cleanFiles = <String>{};
  final libDir = Directory('${flutterToolsDir.path}/lib');
  final testDir = Directory('${flutterToolsDir.path}/test');

  for (final dir in <Directory>[libDir, testDir]) {
    if (!dir.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String relativePath = entity.path
          .replaceAll(r'\', '/')
          .substring('${flutterToolsDir.path.replaceAll(r'\', '/')}/'.length);

      // Exclude globals.dart itself since it defines ambient globals.
      if (relativePath == 'lib/src/globals.dart') {
        continue;
      }

      if (!importsGlobals(entity)) {
        cleanFiles.add(relativePath);
      }
    }
  }

  return cleanFiles;
}

/// Checks whether [file] imports `globals.dart` via relative import or `package:flutter_tools/src/globals.dart`.
bool importsGlobals(File file) {
  final List<String> lines = file.readAsLinesSync();
  for (final line in lines) {
    final String trimmed = line.trim();
    if (trimmed.startsWith('//') || trimmed.startsWith('/*')) {
      continue;
    }
    if (_globalsImportPattern.hasMatch(trimmed)) {
      return true;
    }
  }
  return false;
}

/// Generates Dart source content for `no_globals_in_flutter_tools_restricted_paths.dart`.
String generateRestrictedPathsContent(Set<String> files) {
  final List<String> sortedFiles = files.toList()..sort();
  final buffer = StringBuffer();
  buffer.writeln('// Copyright 2014 The Flutter Authors. All rights reserved.');
  buffer.writeln('// Use of this source code is governed by a BSD-style license that can be');
  buffer.writeln('// found in the LICENSE file.');
  buffer.writeln();
  buffer.writeln('// AUTO-GENERATED FILE. DO NOT MODIFY MANUALLY.');
  buffer.writeln('// To update, run:');
  buffer.writeln('//   dart dev/flutter_analyzer_plugin/tool/update_migrated_files.dart');
  buffer.writeln();
  buffer.writeln('/// Default set of file paths relative to `packages/flutter_tools/` that must');
  buffer.writeln('/// not import `globals.dart`.');
  buffer.writeln('const Set<String> defaultRestrictedPaths = <String>{');
  for (final file in sortedFiles) {
    buffer.writeln("  '$file',");
  }
  buffer.writeln('};');
  return buffer.toString();
}

/// Locates `packages/flutter_tools` starting from the current directory or script location.
Directory findFlutterToolsDirectory() {
  Directory current = Directory.current;
  while (current.path != current.parent.path) {
    final candidate = Directory('${current.path}/packages/flutter_tools');
    if (candidate.existsSync()) {
      return candidate;
    }
    current = current.parent;
  }
  // Fallback to relative navigation from script location
  final String scriptDir = File(Platform.script.toFilePath()).parent.path;
  final candidate = Directory('$scriptDir/../../../packages/flutter_tools');
  if (candidate.existsSync()) {
    return candidate;
  }
  throw StateError('Could not find packages/flutter_tools directory');
}

/// Locates `dev/flutter_analyzer_plugin` starting from the current directory or script location.
Directory findAnalyzerPluginDirectory() {
  Directory current = Directory.current;
  while (current.path != current.parent.path) {
    final candidate = Directory('${current.path}/dev/flutter_analyzer_plugin');
    if (candidate.existsSync()) {
      return candidate;
    }
    current = current.parent;
  }
  final String scriptDir = File(Platform.script.toFilePath()).parent.path;
  final candidate = Directory('$scriptDir/..');
  if (candidate.existsSync()) {
    return candidate;
  }
  throw StateError('Could not find dev/flutter_analyzer_plugin directory');
}

void main(List<String> args) {
  final Directory toolsDir = findFlutterToolsDirectory();
  final Directory pluginDir = findAnalyzerPluginDirectory();
  final targetFile = File(
    '${pluginDir.path}/lib/src/rules/no_globals_in_flutter_tools_restricted_paths.dart',
  );

  final Set<String> migratedFiles = findMigratedFiles(toolsDir);

  if (args.contains('--verify')) {
    if (!targetFile.existsSync()) {
      stderr.writeln('Error: ${targetFile.path} does not exist. Run without --verify to generate.');
      exitCode = 1;
      return;
    }
    // Read the current file content and extract paths
    final String content = targetFile.readAsStringSync();
    final pathRegex = RegExp(r"'([^']+)'");
    final Set<String> existingPaths =
        pathRegex.allMatches(content).map((Match m) => m.group(1)!).toSet();

    final Set<String> missing = migratedFiles.difference(existingPaths);
    final Set<String> extra = existingPaths.difference(migratedFiles);

    if (missing.isNotEmpty || extra.isNotEmpty) {
      if (missing.isNotEmpty) {
        stderr.writeln(
          'Error: The following ${missing.length} migrated files are missing from defaultRestrictedPaths:\n'
          '  ${missing.take(10).join('\n  ')}${missing.length > 10 ? '\n  ...and ${missing.length - 10} more' : ''}',
        );
      }
      if (extra.isNotEmpty) {
        stderr.writeln(
          'Error: The following ${extra.length} files in defaultRestrictedPaths import globals.dart:\n'
          '  ${extra.take(10).join('\n  ')}${extra.length > 10 ? '\n  ...and ${extra.length - 10} more' : ''}',
        );
      }
      stderr.writeln(
        '\nRun `dart dev/flutter_analyzer_plugin/tool/update_migrated_files.dart` to update.',
      );
      exitCode = 1;
      return;
    }

    stdout.writeln(
      'Verified: all ${migratedFiles.length} migrated files are included in defaultRestrictedPaths.',
    );
    return;
  }

  final String content = generateRestrictedPathsContent(migratedFiles);
  targetFile.writeAsStringSync(content);
  stdout.writeln(
    'Successfully updated ${targetFile.path} with ${migratedFiles.length} migrated files.',
  );
}
