import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/options/common_options.dart';
import 'package:test/test.dart';

class DummyCommand extends FlutterCommand {
  DummyCommand() {
    registerOptionBundles(<OptionBundle>[const BuildInfoOptionsBundle()]);
  }

  @override
  final String name = 'dummy';

  @override
  final String description = 'A dummy command';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}

void main() {
  test('BuildInfoOptionsBundle registers all descriptors successfully', () {
    final DummyCommand command = DummyCommand();
    final CommandRunner<void> runner = CommandRunner<void>('test', 'test');
    runner.addCommand(command);

    // Verify all keys are present in the argParser
    expect(command.argParser.options.containsKey('track-widget-creation'), isTrue);
    expect(command.argParser.options.containsKey('analyze-size'), isTrue);
    expect(command.argParser.options.containsKey('code-size-directory'), isTrue);
    expect(command.argParser.options.containsKey('obfuscate'), isTrue);
    expect(command.argParser.options.containsKey('split-debug-info'), isTrue);
    expect(command.argParser.options.containsKey('android-gradle-daemon'), isTrue);
    expect(command.argParser.options.containsKey('android-project-arg'), isTrue);
    expect(command.argParser.options.containsKey('android-project-cache-dir'), isTrue);
    expect(
      command.argParser.options.containsKey('android-skip-build-dependency-validation'),
      isTrue,
    );
    expect(command.argParser.options.containsKey('performance-measurement-file'), isTrue);
    expect(command.argParser.options.containsKey('flavor'), isTrue);
    expect(command.argParser.options.containsKey('codesign'), isTrue);
    expect(command.argParser.options.containsKey('frontend-server-starter-path'), isTrue);
    expect(command.argParser.options.containsKey('initialize-from-dill'), isTrue);
    expect(command.argParser.options.containsKey('assume-initialize-from-dill-up-to-date'), isTrue);
  });
}
