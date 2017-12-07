import 'package:args/args.dart';

void main(List<String> args) {
  ArgParser parser = new ArgParser();

  parser.addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display the tool\'s usage instructions and quit');

  parser.addOption(
      'output',
      abbr: 'o',
      help: 'Target path to write the generated Dart file to');

  parser.addOption(
      'asset_name',
      abbr: 'n',
      help: 'Name to be used ');


  ArgResults argResults = parser.parse(args);

  if (argResults['help']) {
    printUsage(parser);
    return;
  }

  printUsage(parser);
}

void printUsage(ArgParser parser) {
  print('Usage: svg2dart --asset_name=<asset_name> --output=<output_path> <frames_list>');
  print('\nExample: svg2dart --asset_name=_\$menu_arrow --output=lib/data/menu_arrow.g.dart assets/svg/menu_arrow/*.svg\n');
  print(parser.usage);
}
