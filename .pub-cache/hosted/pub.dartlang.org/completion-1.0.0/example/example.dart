#!/usr/bin/env dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:completion/completion.dart';

import '../test/completion_tests_args.dart';

void main(List<String> args) {
  final argParser = getHelloSampleParser();

  ArgResults argResult;

  try {
    argResult = tryArgsCompletion(
      args,
      argParser,
      // logFile: '_completion.log',
    );
  } on FormatException catch (ex) {
    // TODO: print color?
    print(ex.message);
    print(argParser.usage);

    /// 64 - C/C++ standard for bad usage.
    exitCode = 64;
    return;
  }

  if (argResult.command != null) {
    final subCommand = argResult.command!;
    final subCommandParser = argParser.commands[subCommand.name]!;

    if (subCommand.name == 'help') {
      // so the help command was run.

      // there are args here, too. Super fun.
      if (subCommand.command != null) {
        // we have a sub-sub command. Fun!
        // let's get the sub-sub command parser

        final subSubCommand = subCommand.command!;
        if (subSubCommand.name == 'assistance') {
          print('Yes, we have help for help...just calling it assistance');
          // let's print sub help. Very crazy.
          print(subCommandParser.usage);
          return;
        } else {
          throw StateError(
              'no clue what that subCammand is: ${subSubCommand.name}');
        }
      }
      // one sub-sub command: help. Really.

      var usage = argParser.usage;

      if (subCommand['yell'] as bool) {
        usage = usage.toUpperCase();
        print("I'm yelling, so the case of the available commands will be off");
      }

      print(usage);
      return;
    }
  }

  final name = argResult.rest.isEmpty ? 'World' : argResult.rest.first;

  final greeting = argResult['friendly'] as bool ? 'Hiya' : 'Hello';

  final salutationVal = argResult['salutation'] as String?;
  final salutation = salutationVal == null ? '' : '$salutationVal ';

  var message = '$greeting, $salutation$name';

  if (argResult['loud'] as bool) {
    message = message.toUpperCase();
  }

  print(message);
}
