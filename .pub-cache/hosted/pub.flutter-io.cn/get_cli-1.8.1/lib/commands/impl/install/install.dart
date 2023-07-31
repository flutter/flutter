import '../../../common/utils/logger/log_utils.dart';
import '../../../common/utils/pubspec/pubspec_utils.dart';
import '../../../common/utils/shell/shel.utils.dart';
import '../../../core/internationalization.dart';
import '../../../core/locales.g.dart';
import '../../../exception_handler/exceptions/cli_exception.dart';
import '../../interface/command.dart';

class InstallCommand extends Command {
  @override
  String get commandName => 'install';
  @override
  List<String> get alias => ['-i'];
  @override
  Future<void> execute() async {
    var isDev = containsArg('--dev') || containsArg('-dev');
    var runPubGet = false;

    for (var element in args) {
      var packageInfo = element.split(':');
      LogService.info('Installing package "${packageInfo.first}" …');
      if (packageInfo.length == 1) {
        runPubGet = await PubspecUtils.addDependencies(packageInfo.first,
                isDev: isDev, runPubGet: false)
            ? true
            : runPubGet;
      } else {
        runPubGet = await PubspecUtils.addDependencies(packageInfo.first,
                version: packageInfo[1], isDev: isDev, runPubGet: false)
            ? true
            : runPubGet;
      }
    }

    if (runPubGet) await ShellUtils.pubGet();
  }

  @override
  String? get hint => Translation(LocaleKeys.hint_install).tr;

  @override
  bool validate() {
    super.validate();

    if (args.isEmpty) {
      throw CliException(
          'Please, enter the name of a package you wanna install',
          codeSample: codeSample);
    }
    return true;
  }

  final String? codeSample1 = LogService.code('get install get:3.4.6');
  final String? codeSample2 = LogService.code('get install get');

  @override
  String get codeSample => '''
  $codeSample1
  if you wanna install the latest version:
  $codeSample2
''';

  @override
  int get maxParameters => 999;
}
