import 'package:args/args.dart';

ArgParser getHelloSampleParser() {
  final parser = ArgParser()

    // not negatable
    ..addFlag('friendly',
        abbr: 'f', negatable: false, help: 'should I be friendly?')

    // negatable
    ..addFlag('loud', help: 'should I be loud in how I say hello?')

    // option with a fixed set of options
    ..addOption('salutation',
        abbr: 's',
        help: 'What salutation should I use?',
        allowed: ['Mr', 'Mrs', 'Dr', 'Ms'])

    // allow multiple
    ..addMultiOption('middle-name',
        abbr: 'm', help: 'Do you have one or more middle names?');

  parser.addCommand('help')
    ..addFlag('yell', abbr: 'h', help: 'Happy to yell at you :-)')
    ..addCommand('assistance');

  return parser;
}
