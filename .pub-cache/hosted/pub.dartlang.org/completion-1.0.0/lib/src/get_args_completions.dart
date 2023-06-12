import 'package:args/args.dart';

import 'util.dart';

/*
 * TODO: an interesting scenario: if there is only one subcommand,
 *       then tabbing into an app just completes to that one command. Weird?
 */

List<String> getArgsCompletions(
  ArgParser parser,
  List<String> providedArgs,
  String compLine,
  int compPoint,
) {
  // all arg entries: no empty items, no null items, all pre-trimmed
  for (var i = 0; i < providedArgs.length; i++) {
    final arg = providedArgs[i];
    final msg = 'Arg at index $i with value "$arg" ';
    if (arg.trim() != arg) throw StateError('$msg has whitespace');

    if (i < (providedArgs.length - 1)) {
      if (arg.isEmpty) {
        throw StateError('$msg – Only the last arg can be an empty string');
      }
    }
  }

  void sublog(Object obj) {
    log(obj, Tag.getArgsCompletions);
  }

  sublog('provided args: ${helpfulToString(providedArgs)}');
  sublog('COMP_LINE:  "$compLine"');
  sublog('COMP_POINT:  $compPoint');

  if (compPoint < compLine.length) {
    // TODO: ponder smart ways to handle in-line completion
    sublog('cursor is in the middle of the line. NO-OP');
    return const [];
  }

  if (providedArgs.isEmpty) {
    sublog('empty args. Complete with all available commands');
    return parser.commands.keys.toList();
  }

  final alignedArgsOptions =
      providedArgs.map((arg) => _getOptionForArg(parser, arg)).toList();

  /*
   * NOTE: nuanced behavior
   * If the last item provided is a full, real item (command or option)
   * It should be completed with its full name so the user can move on
   * Soooo....we are excluding the last item in [alignedArgsOptions] from
   * optionsDefinedInArgs
   *
   * Keep in mind, if we're already on to the next item to complete, the last
   * item is likely empty string '' or '--', so this isn't a problem
   */

  // a set of options in use (minus, potentially, the last one)
  // all non-null, all unique
  final optionsDefinedInArgs = alignedArgsOptions
      .take(alignedArgsOptions.length - 1)
      .whereType<Option>()
      .toSet();
  sublog('defined options: ${optionsDefinedInArgs.map((o) => o.name).toSet()}');

  final parserOptionCompletions = List<String>.unmodifiable(
      _parserOptionCompletions(parser, optionsDefinedInArgs));

  /*
   * KNOWN: at least one item in providedArgs last and first are now safe
   */

  /*
   * Now we're going to lean on the existing parse functionality to see
   * if the provided args (or a subset of them) parse to valid [ArgsResult]
   * If it does, we can use the result to determine what we should do next
   */

  final subsetTuple = _validSubset(parser, providedArgs);
  final validSubSet = subsetTuple.subset;
  final subsetResult = subsetTuple.result;

  sublog('valid subset: ${helpfulToString(validSubSet)}');

  /*
   * CASE: we have a command
   * get recursive
   */
  if (subsetResult != null && subsetResult.command != null) {
    // get all of the args *after* the command name
    // call in recursively with the sub command parser, right?
    final subCommand = subsetResult.command!;
    final subCommandIndex = providedArgs.indexOf(subCommand.name!);
    assert(subCommandIndex >= 0);
    sublog('so, it seems we have command "${subCommand.name}" at '
        'index $subCommandIndex');

    final subCommandParser = parser.commands[subCommand.name]!;
    final subCommandArgs = providedArgs.sublist(subCommandIndex + 1);

    /*
     * only start rockin' the sub command parser if
     * 1) there's a start on sub args
     * 2) there's whitespace at the end of compLine
     */

    if (subCommandArgs.isNotEmpty || compLine.endsWith(' ')) {
      return getArgsCompletions(
          subCommandParser, subCommandArgs, compLine, compPoint);
    }
  }

  final removedItems = providedArgs.sublist(validSubSet.length);
  assert(removedItems.length + validSubSet.length == providedArgs.length);

  sublog('removed items: ${helpfulToString(removedItems)}');

  final lastArg = providedArgs.last;

  /*
   * CASE: one removed item, that looks like a partial option
   * try to match it against available options
   */
  if (removedItems.length == 1 && removedItems.single.startsWith('--')) {
    final removedItem = removedItems.single;

    if (compLine.endsWith(' ')) {
      // if the removed item maps to an option w/ allowed values
      // we should return those values to complete against
      final option = alignedArgsOptions[providedArgs.length - 1];
      if (option != null &&
          option.allowed != null &&
          option.allowed!.isNotEmpty) {
        assert(!option.isFlag);

        sublog('completing all allowed value for option "${option.name}"');

        return option.allowed!.toList();
      }
    } else {
      sublog('completing the name of options starting with "$removedItem"');

      return parserOptionCompletions
          .where((String option) => option.startsWith(removedItem))
          .toList();
    }
  }

  /*
   * CASE: second-to-last arg is an option+allowed and lastArg is empty
   * then we should complete with the available options, right?
   */
  if (providedArgs.length >= 2) {
    final option = alignedArgsOptions[providedArgs.length - 2];
    if (option != null) {
      if (option.allowed != null && option.allowed!.isNotEmpty) {
        assert(!option.isFlag);
        sublog('completing option "${option.name}"');

        final optionValue = providedArgs[providedArgs.length - 1];

        return option.allowed!.where((v) => v.startsWith(optionValue)).toList();
      } else if (!option.isFlag) {
        sublog('not providing completions. Wating for option value');
        return const [];
      }
    }
  }

  /*
   * CASE: no removed items and compLine ends in a space ->
   * do command completion
   */
  if (removedItems.isEmpty && lastArg == '') {
    sublog('doing command completion');

    return parser.commands.keys.toList();
  }

  /*
   * CASE: If we have '--', then let's naively complete all options
   */
  if (lastArg == '--') {
    sublog('Completing with all available options.');
    return parserOptionCompletions;
  }

  /*
   * CASE: a partial command name?
   * if the last arg doesn't start with a '-'
   */
  if (!lastArg.startsWith('-')) {
    // for now, let's pretend this is partial command

    sublog('completing command names that start with "$lastArg"');

    return parser.commands.keys
        .where((String commandName) => commandName.startsWith(lastArg))
        .toList();
  }

  /*
   * CASE: the last argument is valid, so we should return it
   * if types the last char of a valid option, hitting tab should complete it
   */
  if (lastArg != '' && parserOptionCompletions.contains(lastArg)) {
    sublog('completing final arg');
    return [lastArg];
  }

  sublog('Exhausted options. No suggestions.');

  return const [];
}

Option? _getOptionForArg(ArgParser parser, String arg) {
  // could be a full arg name
  if (arg.startsWith('--')) {
    final nameOption = arg.substring(2);
    final option = parser.options[nameOption];
    if (option != null) {
      return option;
    }
  }

  // could be a 'not' arg name
  if (arg.startsWith('--no-')) {
    final nameOption = arg.substring(5);
    final option = parser.options[nameOption];
    if (option != null && option.negatable!) {
      return option;
    }
  }

  if (arg.startsWith('-') && arg.length == 2) {
    // all abbreviations are single-character
    final abbr = arg.substring(1);
    assert(abbr.length == 1);
    return parser.findByAbbreviation(abbr);
  }

  // no matching option
  return null;
}

Iterable<String> _parserOptionCompletions(
    ArgParser parser, Set<Option> existingOptions) {
  assert(
      existingOptions.every((option) => parser.options.containsValue(option)));

  return parser.options.values
      .where((opt) =>
          !existingOptions.contains(opt) || opt.type == OptionType.multiple)
      .expand(_argsOptionCompletions);
}

_Tuple _validSubset(ArgParser parser, List<String> providedArgs) {
  /* start with all of the args, loop through parsing them,
   * removing one every time
   *
   * Util:
   * 1) we have a valid ArgsResult
   * 2) we have no more args
   */
  final validSubSet = providedArgs.toList();
  ArgResults? subsetResult;
  while (validSubSet.isNotEmpty) {
    try {
      subsetResult = parser.parse(validSubSet);
      break;
    } on FormatException catch (_) {
      //_log('tried to parse subset $validSubSet');
      //_log('error:\t$ex');
      // I guess that won't parse
    }

    // TODO: other ways this could fail? Hmm...

    validSubSet.removeLast();
  }

  return _Tuple(validSubSet, subsetResult);
}

List<String> _argsOptionCompletions(Option option) => <String>[
      '--${option.name}',
      if (option.negatable!) '--no-${option.name}',
    ]..sort();

class _Tuple {
  final List<String> subset;
  final ArgResults? result;

  const _Tuple(this.subset, this.result);
}
