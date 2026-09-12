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
      if (entity case File(:final String path) when path.endsWith('.dart')) {
        final String relativePath = path
            .replaceAll(r'\', '/')
            .substring('${flutterToolsDir.path.replaceAll(r'\', '/')}/'.length);

        // Exclude globals.dart itself since it defines ambient globals.
        if (relativePath != 'lib/src/globals.dart' && !importsGlobals(entity)) {
          cleanFiles.add(relativePath);
        }
      }
    }
  }

  return cleanFiles;
}

/// Checks whether [file] imports `globals.dart` via relative import or `package:flutter_tools/src/globals.dart`.
bool importsGlobals(File file) {
  return file.readAsLinesSync().any((String line) {
    final String trimmed = line.trim();
    return !trimmed.startsWith('//') &&
        !trimmed.startsWith('/*') &&
        _globalsImportPattern.hasMatch(trimmed);
  });
}

/// Generates Dart source content for `no_globals_in_flutter_tools_restricted_paths.dart`.
String generateRestrictedPathsContent(Set<String> files) {
  final List<String> sortedFiles = files.toList()..sort();
  final String pathsContent = sortedFiles.map((String file) => "  '$file',").join('\n');
  return '''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// AUTO-GENERATED FILE. DO NOT MODIFY MANUALLY.
// To update, run:
//   dart dev/flutter_analyzer_plugin/tool/update_migrated_files.dart

/// Default set of file paths relative to `packages/flutter_tools/` that must
/// not import `globals.dart`.
///
/// Part of the flutter_tools dependency injection migration effort
/// (https://github.com/flutter/flutter/issues/47161).
const Set<String> defaultRestrictedPaths = <String>{
$pathsContent
};
''';
}

/// Locates the Flutter repository root directory starting from the current directory
/// or script location.
Directory findFlutterRepoRoot() {
  Directory current = Directory.current;
  while (current.path != current.parent.path) {
    if (Directory('${current.path}/packages/flutter_tools').existsSync() &&
        Directory('${current.path}/dev/flutter_analyzer_plugin').existsSync()) {
      return current;
    }
    current = current.parent;
  }
  // Fallback to relative navigation from script location
  final Directory scriptDir = File(Platform.script.toFilePath()).parent;
  final Directory candidate = scriptDir.parent.parent;
  if (Directory('${candidate.path}/packages/flutter_tools').existsSync()) {
    return candidate;
  }
  throw StateError('Could not find Flutter repository root directory');
}

/// Locates `packages/flutter_tools` starting from the current directory or script location.
Directory findFlutterToolsDirectory() =>
    Directory('${findFlutterRepoRoot().path}/packages/flutter_tools');

/// Locates `dev/flutter_analyzer_plugin` starting from the current directory or script location.
Directory findAnalyzerPluginDirectory() =>
    Directory('${findFlutterRepoRoot().path}/dev/flutter_analyzer_plugin');

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
