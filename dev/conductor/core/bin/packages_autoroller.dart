import 'package:args/args.dart';
import 'package:conductor_core/conductor_core.dart';

const String kTokenOption = 'token';
const String kGithubClient = 'github-client';

Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser.addOption(
    kTokenOption,
    help: 'GitHub access token.',
    mandatory: true,
  );
  parser.addOption(
    kGithubClient,
    help: 'Path to GitHub CLI client.',
    mandatory: true,
  );
  final ArgResults results = parser.parse(args);
  await PackageAutoroller(
    githubClient: results[kGithubClient] as String,
    token: results[kTokenOption] as String,
  ).roll();
}
