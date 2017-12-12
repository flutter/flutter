import 'dart:io';

import 'package:args/args.dart';
import 'package:svg2dart/svg2dart.dart';

void main(List<String> args) {
  final ArgParser parser = new ArgParser();

  parser.addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display the tool\'s usage instructions and quit.');

  parser.addOption(
      'output',
      abbr: 'o',
      help: 'Target path to write the generated Dart file to.');

  parser.addOption(
      'asset_name',
      abbr: 'n',
      help: 'Name to be used for the the generated const.');


  final ArgResults argResults = parser.parse(args);

  if (argResults['help']) {
    printUsage(parser);
    return;
  }

  final List<FrameData> frames = <FrameData>[];
  for (String filePath in argResults.rest) {
    final FrameData data = interpretSvg(filePath);
    frames.add(data);
  }
  final Animation animation = new Animation.fromFrameData(frames);
  final File outFile = new File(argResults['output']);
  outFile.writeAsStringSync(animation.toDart('_AnimatedIconData', argResults['asset_name']));
}

void printUsage(ArgParser parser) {
  print('Usage: svg2dart --asset_name=<asset_name> --output=<output_path> <frames_list>');
  print('\nExample: svg2dart --asset_name=_\$menu_arrow --output=lib/data/menu_arrow.g.dart assets/svg/menu_arrow/*.svg\n');
  print(parser.usage);
}
