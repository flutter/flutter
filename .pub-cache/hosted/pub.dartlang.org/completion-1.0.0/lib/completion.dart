import 'package:args/args.dart';

import 'src/get_args_completions.dart';
import 'src/try_completion.dart';

export 'src/generate.dart';
export 'src/try_completion.dart';

ArgResults tryArgsCompletion(
  List<String> mainArgs,
  ArgParser parser, {
  @Deprecated('Useful for testing, but do not released with this set.')
      bool? logFile,
}) {
  tryCompletion(
    mainArgs,
    (List<String> args, String compLine, int compPoint) =>
        getArgsCompletions(parser, args, compLine, compPoint),
    // ignore: deprecated_member_use_from_same_package,deprecated_member_use
    logFile: logFile,
  );
  return parser.parse(mainArgs);
}
