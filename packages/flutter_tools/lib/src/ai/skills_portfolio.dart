import 'package:file/file.dart';
import '../globals.dart' as globals;

class SkillsPortfolio {
  /// Reads all installed skills from the local workspace directory
  /// and aggregates them into a structured prompt block.
  static String compileActiveSkills() {
    final Directory skillsDir = globals.fs.directory('.flutter_skills');
    if (!skillsDir.existsSync()) {
      return '';
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('\n=== ACTIVE DEVELOPER AGENT SKILLS ===');

    for (final FileSystemEntity entity in skillsDir.listSync()) {
      if (entity is File && entity.path.endsWith('.md')) {
        try {
          final String content = entity.readAsStringSync();
          buffer.writeln(content);
          buffer.writeln('---');
        } catch (e) {
          globals.printTrace('Failed to parse skill asset ${entity.path}: $e');
        }
      }
    }

    return buffer.toString();
  }
}
