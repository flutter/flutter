import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template sample_command}
///
/// `shorebird_tools sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class SampleCommand extends Command<int> {
  /// {@macro sample_command}
  SampleCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser.addFlag(
      'cyan',
      abbr: 'c',
      help: 'Prints the same joke, but in cyan',
      negatable: false,
    );
  }

  @override
  String get description => 'A sample sub command that just prints one joke';

  @override
  String get name => 'sample';

  final Logger _logger;

  @override
  Future<int> run() async {
    var output = 'Which unicorn has a cold? The Achoo-nicorn!';
    if (argResults?['cyan'] == true) {
      output = lightCyan.wrap(output)!;
    }
    _logger.info(output);
    return ExitCode.success.code;
  }
}
