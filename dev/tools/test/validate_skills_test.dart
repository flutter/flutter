// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:dart_skills_lint/dart_skills_lint.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'check_backticks_relative_paths_rule.dart';

const String _configFileName = 'dart_skills_lint.yaml';

Directory _findSkillsDir() {
  Directory dir = Directory.current;
  while (dir.path != dir.parent.path) {
    final skillsDir = Directory(path.join(dir.path, '.agents', 'skills'));
    if (skillsDir.existsSync()) {
      return skillsDir;
    }
    dir = dir.parent;
  }
  throw StateError(
    'Could not find .agents/skills directory starting from ${Directory.current.path}',
  );
}

void main() {
  final Directory skillsDir = _findSkillsDir();
  final String skillsDirectory = skillsDir.path;
  final Directory repoRoot = skillsDir.parent.parent;

  late Level oldLevel;
  StreamSubscription<LogRecord>? subscription;

  setUp(() {
    oldLevel = Logger.root.level;
    Logger.root.level = Level.ALL;
    subscription = Logger.root.onRecord.listen((record) {
      print(record.message);
    });
  });

  tearDown(() async {
    Logger.root.level = oldLevel;
    await subscription?.cancel();
  });

  test('Validate Flutter Skills', () async {
    final Configuration config = await ConfigParser.loadConfig(
      path: path.join(repoRoot.path, 'dev', 'tools', _configFileName),
    );
    final bool isValid = await validateSkills(skillDirPaths: [skillsDirectory], config: config);
    expect(isValid, isTrue, reason: 'Skills validation failed. See above for details.');
  });

  test('Relative to root paths are not in backticks', () async {
    final valid2SegmentPaths = <String>{};

    final List<FileSystemEntity> entities = repoRoot.listSync();
    for (final entity in entities) {
      if (entity is Directory) {
        final String dirName = path.basename(entity.path);
        if (dirName.startsWith('.')) {
          continue;
        }

        final List<FileSystemEntity> subEntities = entity.listSync();
        for (final subEntity in subEntities) {
          if (subEntity is Directory) {
            final String subDirName = path.basename(subEntity.path);
            if (subDirName.startsWith('.')) {
              continue;
            }
            valid2SegmentPaths.add('$dirName/$subDirName');
          }
        }
      }
    }

    final bool isValid = await validateSkills(
      skillDirPaths: [skillsDirectory],
      customRules: [CheckBackticksRelativePathsRule(valid2SegmentPaths, repoRoot.path)],
      resolvedRules: {
        'check-absolute-paths': AnalysisSeverity.disabled,
        'check-relative-paths': AnalysisSeverity.disabled,
        'check-trailing-whitespace': AnalysisSeverity.disabled,
        'description-too-long': AnalysisSeverity.disabled,
        'disallowed-field': AnalysisSeverity.disabled,
        'invalid-skill-name': AnalysisSeverity.disabled,
        'valid-yaml-metadata': AnalysisSeverity.disabled,
      },
    );
    expect(isValid, isTrue, reason: 'Skills validation failed. See above for details.');
  });

  test('CheckBackticksRelativePathsRule handles Windows paths', () async {
    final rule = CheckBackticksRelativePathsRule({'dev/tools'}, '/Users/reidbaker/flutter-work');

    final context = SkillContext(
      directory: Directory('/Users/reidbaker/flutter-work/.agents/skills/test-skill'),
      rawContent: r'Use `dev\tools\test.dart` to test.',
    );

    final List<ValidationError> errors = await rule.validate(context);

    expect(errors, hasLength(1));
    expect(errors.first.message, contains('[test.dart](../../../dev/tools/test.dart)'));
  });
}
