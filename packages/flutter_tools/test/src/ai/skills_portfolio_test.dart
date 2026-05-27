import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/ai/skills_portfolio.dart';

import '../context.dart';
import '../test_flutter_command_runner.dart';

void main() {
  group('SkillsPortfolio', () {
    late MemoryFileSystem memoryFileSystem;

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
    });

    testUsingContext(
      'compiles markdown files into an active skills block',
      () {
        memoryFileSystem.directory('.flutter_skills').createSync(recursive: true);
        memoryFileSystem
            .file('.flutter_skills/clear_logs_skill.md')
            .writeAsStringSync('# Clear Logs Skill\nDo not leave stale logs behind.');
        memoryFileSystem.file('.flutter_skills/ignore.txt').writeAsStringSync('ignore me');

        final String compiled = SkillsPortfolio.compileActiveSkills();

        expect(compiled, contains('=== ACTIVE DEVELOPER AGENT SKILLS ==='));
        expect(compiled, contains('Clear Logs Skill'));
        expect(compiled, isNot(contains('ignore me')));
      },
      overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'returns empty when the skill directory cannot be listed',
      () {
        memoryFileSystem.file('.flutter_skills').writeAsStringSync('not a directory');

        final String compiled = SkillsPortfolio.compileActiveSkills();

        expect(compiled, isEmpty);
      },
      overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });
}
