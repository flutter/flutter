import 'package:args/args.dart';
import 'package:conductor_core/conductor_core.dart';

const String kTokenOption = 'token';

Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser.addOption(
    kTokenOption,
    help: 'GitHub access token.',
    mandatory: true,
  );
  final ArgResults results = parser.parse(args);
  await PackageAutoroller(
    token: results[kTokenOption] as String,
  ).roll();
}
