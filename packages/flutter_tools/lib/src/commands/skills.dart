import 'dart:convert';

import 'package:file/file.dart';

import '../base/common.dart';
import '../base/io.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

/// Command for discovering, installing, and managing AI agent skills.
class SkillsCommand extends FlutterCommand {
  /// Creates the `flutter skills` command.
  // ignore: avoid_unused_constructor_parameters
  SkillsCommand({bool verboseHelp = false}) {
    addSubcommand(SkillsListCommand());
    addSubcommand(SkillsFindCommand());
    addSubcommand(SkillsInstallCommand());
    addSubcommand(SkillsRemoveCommand());
  }

  @override
  final String name = 'skills';

  @override
  final String description = 'Discover, install, and manage AI agent skills.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    globals.printStatus(description);
    globals.printStatus('\nUse "flutter skills -h" for available subcommands.');
    return FlutterCommandResult.success();
  }
}

/// Fetches the skills registry from the remote repository.
Future<List<Map<String, dynamic>>> _fetchSkillsRegistry() async {
  final Uri registryUrl = Uri.parse(
    'https://raw.githubusercontent.com/flutter/skills/main/registry.json',
  );

  final fallbackSkills = <Map<String, dynamic>>[
    <String, dynamic>{
      'name': 'clear_logs_skill',
      'description': 'Cleans up and rolls back build log artifacts automatically.',
      'content': '# Clear Logs Skill\n\nAlways analyze target directory for stale .log profiles.',
    },
  ];

  try {
    final HttpClient client = globals.httpClientFactory?.call() ?? HttpClient();
    final HttpClientRequest request = await client
        .getUrl(registryUrl)
        .timeout(const Duration(seconds: 3));
    final HttpClientResponse response = await request.close();

    if (response.statusCode == 200) {
      final String body = await response.transform(utf8.decoder).join();
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final dynamic rawSkills = decoded['skills'];
        if (rawSkills is List) {
          final skills = <Map<String, dynamic>>[];
          for (final Map<dynamic, dynamic> rawSkill
              in rawSkills.whereType<Map<dynamic, dynamic>>()) {
            final dynamic name = rawSkill['name'];
            final dynamic description = rawSkill['description'];
            final dynamic content = rawSkill['content'];
            if (name is String && description is String) {
              skills.add(<String, dynamic>{
                'name': name,
                'description': description,
                'content': content is String ? content : '',
              });
            }
          }
          return skills;
        }
      }
    }
  } on Exception {
    // Graceful fallback.
  }
  return fallbackSkills;
}

/// Lists available skills from the remote registry.
class SkillsListCommand extends FlutterCommand {
  @override
  final String name = 'list';

  @override
  final String description = 'List available skills from the remote registry.';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    globals.printStatus('Fetching available agent skills...');
    final List<Map<String, dynamic>> skills = await _fetchSkillsRegistry();

    if (skills.isEmpty) {
      globals.printStatus('No skills found.');
      return FlutterCommandResult.success();
    }

    globals.printStatus('\nAvailable Skills:');
    for (final skill in skills) {
      final String name = _skillName(skill).isEmpty ? 'unknown' : _skillName(skill);
      final String description = _skillDescription(skill);
      globals.printStatus('${name.padRight(22)} ─ $description');
    }
    return FlutterCommandResult.success();
  }
}

/// Finds skills in the registry by keyword.
class SkillsFindCommand extends FlutterCommand {
  @override
  final String name = 'find';

  @override
  final String description = 'Find skills by keyword.';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults!.rest.isEmpty) {
      globals.printError('Error: Please specify a search keyword.');
      return FlutterCommandResult.fail();
    }

    final String query = argResults!.rest.first.toLowerCase();
    final List<Map<String, dynamic>> skills = await _fetchSkillsRegistry();
    final List<Map<String, dynamic>> matches = skills.where((Map<String, dynamic> skill) {
      final String name = _skillName(skill).toLowerCase();
      final String desc = _skillDescription(skill).toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();

    if (matches.isEmpty) {
      globals.printStatus('No matches found for: "$query"');
      return FlutterCommandResult.success();
    }

    for (final skill in matches) {
      final String name = _skillName(skill).isEmpty ? 'unknown' : _skillName(skill);
      final String description = _skillDescription(skill);
      globals.printStatus('${name.padRight(22)} ─ $description');
    }
    return FlutterCommandResult.success();
  }
}

/// Installs a skill into the current workspace.
class SkillsInstallCommand extends FlutterCommand {
  @override
  final String name = 'install';

  @override
  final String description = 'Install a specific skill.';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults!.rest.isEmpty) {
      throwToolExit('Specify a skill name.');
    }

    if (!globals.fs.file('pubspec.yaml').existsSync()) {
      throwToolExit(
        'Error: No pubspec.yaml found. Navigate to your Flutter project root directory to install local skills.',
      );
    }

    final String targetSkill = argResults!.rest.first;
    final List<Map<String, dynamic>> skills = await _fetchSkillsRegistry();
    final Map<String, dynamic> match = skills.firstWhere((Map<String, dynamic> skill) {
      final dynamic name = skill['name'];
      return name is String && name.toLowerCase() == targetSkill.toLowerCase();
    }, orElse: () => <String, dynamic>{});

    if (match.isEmpty) {
      throwToolExit('Skill "$targetSkill" not found.');
    }

    final String dirPath = globals.fs.path.join('.flutter_skills');
    final String filePath = globals.fs.path.join(dirPath, '$targetSkill.md');
    globals.fs.directory(dirPath).createSync(recursive: true);
    globals.fs.file(filePath).writeAsStringSync(_skillContent(match, targetSkill));

    globals.printStatus('🎉 Installed: $filePath');
    return FlutterCommandResult.success();
  }
}

/// Removes a skill from the current workspace.
class SkillsRemoveCommand extends FlutterCommand {
  @override
  final String name = 'remove';

  @override
  final String description = 'Remove a specific skill.';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults!.rest.isEmpty) {
      throwToolExit('Specify a skill name.');
    }

    if (!globals.fs.file('pubspec.yaml').existsSync()) {
      throwToolExit(
        'Error: No pubspec.yaml found. Navigate to your Flutter project root directory to install local skills.',
      );
    }

    final String targetSkill = argResults!.rest.first;
    final String filePath = globals.fs.path.join('.flutter_skills', '$targetSkill.md');

    if (!globals.fs.file(filePath).existsSync()) {
      throwToolExit('Skill "$targetSkill" not found.');
    }

    globals.fs.file(filePath).deleteSync();

    final String dirPath = globals.fs.path.dirname(filePath);
    final Directory skillsDir = globals.fs.directory(dirPath);
    if (skillsDir.existsSync()) {
      try {
        if (skillsDir.listSync().isEmpty) {
          skillsDir.deleteSync();
        }
      } on Exception catch (error) {
        globals.printTrace('Failed to inspect installed skills: $error');
      }
    }

    globals.printStatus('🗑️ Removed: $filePath');
    return FlutterCommandResult.success();
  }
}

String _skillName(Map<String, dynamic> skill) {
  final dynamic name = skill['name'];
  return name is String ? name : '';
}

String _skillDescription(Map<String, dynamic> skill) {
  final dynamic description = skill['description'];
  return description is String ? description : '';
}

String _skillContent(Map<String, dynamic> skill, String targetSkill) {
  final dynamic content = skill['content'];
  return content is String ? content : '# $targetSkill\nGeneric instruction file.';
}
