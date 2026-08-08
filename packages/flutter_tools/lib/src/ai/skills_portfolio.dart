import 'package:file/file.dart';

import '../globals.dart' as globals;

/// Compiles the set of installed skills into a prompt fragment.
class SkillsPortfolio {
  /// Reads all installed skills from the local workspace directory
  /// and aggregates them into a structured prompt block.
  static String compileActiveSkills() {
    final Directory skillsDir = globals.fs.directory('.flutter_skills');
    if (!skillsDir.existsSync()) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n=== ACTIVE DEVELOPER AGENT SKILLS ===');

    try {
      for (final FileSystemEntity entity in skillsDir.listSync()) {
        if (entity is File && entity.path.endsWith('.md')) {
          try {
            final String content = entity.readAsStringSync();
            buffer.writeln(content);
            buffer.writeln('---');
          } on Exception catch (error) {
            globals.printTrace('Failed to parse skill asset ${entity.path}: $error');
          }
        }
      }
    } on Exception catch (error) {
      globals.printTrace('Failed to inspect installed skill directory ${skillsDir.path}: $error');
      return '';
    }

    return buffer.toString();
  }
}
