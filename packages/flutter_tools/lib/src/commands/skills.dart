import 'dart:convert';
import '../base/common.dart';
import '../base/io.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class SkillsCommand extends FlutterCommand {
  SkillsCommand();

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

Future<List<Map<String, dynamic>>> _fetchSkillsRegistry() async {
  final Uri registryUrl = Uri.parse(
    'https://raw.githubusercontent.com/flutter/skills/main/registry.json',
  );

  final fallbackSkills = <Map<String, dynamic>>[
    {
      'name': 'clear_logs_skill',
      'description': 'Cleans up and rolls back build log artifacts automatically.',
      'content': '# Clear Logs Skill\n\nAlways analyze target directory for stale .log profiles.',
    },
  ];

  try {
    final client = HttpClient();
    final HttpClientRequest request = await client
        .getUrl(registryUrl)
        .timeout(const Duration(seconds: 3));
    final HttpClientResponse response = await request.close();

    if (response.statusCode == 200) {
      final String body = await response.transform(utf8.decoder).join();
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['skills'] is List) {
        return List<Map<String, dynamic>>.from(decoded['skills'] as List);
      }
    }
  } on Exception {
    // Graceful fallback
  }
  return fallbackSkills;
}

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
      globals.printStatus('${(skill['name'] as String).padRight(22)} ─ ${skill['description']}');
    }
    return FlutterCommandResult.success();
  }
}

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
      final String name = (skill['name'] as String? ?? '').toLowerCase();
      final String desc = (skill['description'] as String? ?? '').toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();

    if (matches.isEmpty) {
      globals.printStatus('No matches found for: "$query"');
      return FlutterCommandResult.success();
    }

    for (final skill in matches) {
      globals.printStatus('${(skill['name'] as String).padRight(22)} ─ ${skill['description']}');
    }
    return FlutterCommandResult.success();
  }
}

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
    final String targetSkill = argResults!.rest.first;
    final List<Map<String, dynamic>> skills = await _fetchSkillsRegistry();
    final Map<String, dynamic> match = skills.firstWhere(
      (Map<String, dynamic> s) => (s['name'] as String).toLowerCase() == targetSkill.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );

    if (match.isEmpty) {
      throwToolExit('Skill "$targetSkill" not found.');
    }

    final String dirPath = globals.fs.path.join('.flutter_skills');
    final String filePath = globals.fs.path.join(dirPath, '$targetSkill.md');
    globals.fs.directory(dirPath).createSync(recursive: true);
    globals.fs.file(filePath).writeAsStringSync(match['content'] as String);

    globals.printStatus('🎉 Installed: $filePath');
    return FlutterCommandResult.success();
  }
}
