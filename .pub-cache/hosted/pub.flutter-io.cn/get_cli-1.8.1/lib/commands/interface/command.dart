import '../../common/utils/logger/log_utils.dart';
import '../../core/generator.dart';
import '../../core/locales.g.dart';
import '../../exception_handler/exceptions/cli_exception.dart';
import '../../extensions.dart';
import '../impl/args_mixin.dart';

abstract class Command with ArgsMixin {
  Command() {
    while (
        ((args.contains(commandName) || args.contains('$commandName:$name'))) &&
            args.isNotEmpty) {
      args.removeAt(0);
    }
    if (args.isNotEmpty && args.first == name) {
      args.removeAt(0);
    }
  }
  int get maxParameters;

  //int get minParameters;

  String? get codeSample;
  String get commandName;

  List<String> get alias => [];

  List<String> get acceptedFlags => [];

  /// hint for command line
  String? get hint;

  /// validate command line arguments
  bool validate() {
    if (GetCli.arguments.contains(commandName) ||
        GetCli.arguments.contains('$commandName:$name')) {
      var flagsNotAceppts = flags;
      flagsNotAceppts.removeWhere((element) => acceptedFlags.contains(element));
      if (flagsNotAceppts.isNotEmpty) {
        LogService.info(LocaleKeys.info_unnecessary_flag.trArgsPlural(
          LocaleKeys.info_unnecessary_flag_prural,
          flagsNotAceppts.length,
          [flagsNotAceppts.toString()],
        )!);
      }

      if (args.length > maxParameters) {
        List pars = args.skip(maxParameters).toList();
        throw CliException(
            LocaleKeys.error_unnecessary_parameter.trArgsPlural(
              LocaleKeys.error_unnecessary_parameter_plural,
              pars.length,
              [pars.toString()],
            ),
            codeSample: codeSample);
      }
    }
    return true;
  }

  /// execute command
  Future<void> execute();

  /// childrens command
  List<Command> get childrens => [];
}
