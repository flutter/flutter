// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_skills_lint/dart_skills_lint.dart';
import 'package:path/path.dart' as path;

/// A rule that checks that paths inside backticks are relative to the skill file,
/// not relative to the repository root.
class CheckBackticksRelativePathsRule extends SkillRule {
  CheckBackticksRelativePathsRule(this.valid2SegmentPaths, this.repoRootPath);

  final Set<String> valid2SegmentPaths;
  final String repoRootPath;

  @override
  String get name => 'check-backticks-relative-paths';

  @override
  AnalysisSeverity get severity => AnalysisSeverity.error;

  @override
  Future<List<ValidationError>> validate(SkillContext context) async {
    final errors = <ValidationError>[];
    final String content = context.rawContent;

    // Calculate relative path to root
    final String relativePathToRoot = path.relative(repoRootPath, from: context.directory.path);

    final backtickRegex = RegExp(r'`([^`]+)`');
    final Iterable<RegExpMatch> matches = backtickRegex.allMatches(content);

    for (final match in matches) {
      final String textInBackticks = match.group(1)!;
      final String normalizedText = textInBackticks.replaceAll(r'\', '/');

      for (final String validPath in valid2SegmentPaths) {
        if (normalizedText.startsWith('$validPath/')) {
          final fullPath = textInBackticks;
          final String correctedPath = path
              .join(relativePathToRoot, fullPath)
              .replaceAll(r'\', '/');

          errors.add(
            ValidationError(
              ruleId: name,
              file: 'SKILL.md',
              message:
                  'Found root-relative path "$fullPath" in backticks. Suggested fix: [${path.basename(normalizedText)}]($correctedPath)',
              severity: severity,
            ),
          );
        }
      }
    }

    return errors;
  }
}
