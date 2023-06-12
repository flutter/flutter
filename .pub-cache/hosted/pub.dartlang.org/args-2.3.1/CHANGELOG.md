## 2.3.1

* Switch to using package:lints.
* Address an issue with the readme API documentation (#211).
* Populate the pubspec `repository` field.

## 2.3.0

* Add the ability to group commands by category in usage text.

## 2.2.0

* Suggest similar commands if an unknown command is encountered, when using the
  `CommandRunner`.
  * The max edit distance for suggestions defaults to 2, but can be configured
    using the `suggestionDistanceLimit` parameter on the constructor. You can
    set it to `0` to disable the feature.

## 2.1.1

* Fix a bug with `mandatory` options which caused a null assertion failure when
  used within a command.

## 2.1.0

* Add a `mandatory` argument to require the presence of an option.
* Add `aliases` named argument to `addFlag`, `addOption`, and `addMultiOption`,
  as well as a public `findByNameOrAlias` method on `ArgParser`. This allows
  you to provide aliases for an argument name, which eases the transition from
  one argument name to another.

## 2.0.0

* Stable null safety release.

## 2.0.0-nullsafety.0

* Migrate to null safety.
* **BREAKING** Remove APIs that had been marked as deprecated:

  * Instead of the `allowMulti` and `splitCommas` arguments to
    `ArgParser.addOption()`, use `ArgParser.addMultiOption()`.
  * Instead of `ArgParser.getUsage()`, use `ArgParser.usage`.
  * Instead of `Option.abbreviation`, use `Option.abbr`.
  * Instead of `Option.defaultValue`, use `Option.defaultsTo`.
  * Instead of `OptionType.FLAG/SINGLE/MULTIPLE`, use
    `OptionType.flag/single/multiple`.
* Add a more specific function type to the `callback` argument of `addOption`.

## 1.6.0

* Remove `help` from the list of commands in usage.
* Remove the blank lines in usage which separated the help for options that
  happened to span multiple lines.

## 1.5.4

* Fix a bug with option names containing underscores.
* Point towards `CommandRunner` in the docs for `ArgParser.addCommand` since it
  is what most authors will want to use instead.

## 1.5.3

* Improve arg parsing performance: use queues instead of lists internally to
  get linear instead of quadratic performance, which is important for large
  numbers of args (>1000). And, use simple string manipulation instead of
  regular expressions for a 1.5x improvement everywhere.
* No longer automatically add a 'help' option to commands that don't validate
  their arguments (fix #123).

## 1.5.2

* Added support for `usageLineLength` in `CommandRunner`

## 1.5.1

* Added more comprehensive word wrapping when `usageLineLength` is set.

## 1.5.0

* Add `usageLineLength` to control word wrapping usage text.

## 1.4.4

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 1.4.3

* Display the default values for options with `allowedHelp` specified.

## 1.4.2

* Narrow the SDK constraint to only allow SDK versions that support `FutureOr`.

## 1.4.1

* Fix the way default values for multi-valued options are printed in argument
  usage.

## 1.4.0

* Deprecated `OptionType.FLAG`, `OptionType.SINGLE`, and `OptionType.MULTIPLE`
  in favor of `OptionType.flag`, `OptionType.single`, and `OptionType.multiple`
  which follow the style guide.

* Deprecated `Option.abbreviation` and `Option.defaultValue` in favor of
  `Option.abbr` and `Option.defaultsTo`. This makes all of `Option`'s fields
  match the corresponding parameters to `ArgParser.addOption()`.

* Deprecated the `allowMultiple` and `splitCommas` arguments to
  `ArgParser.addOption()` in favor of a separate `ArgParser.addMultiOption()`
  method. This allows us to provide more accurate type information, and to avoid
  adding flags that only make sense for multi-options in places where they might
  be usable for single-value options.

## 1.3.0

* Type `Command.run()`'s return value as `FutureOr<T>`.

## 1.2.0

* Type the `callback` parameter to `ArgParser.addOption()` as `Function` rather
  than `void Function(value)`. This allows strong-mode users to write `callback:
  (String value) { ... }` rather than having to manually cast `value` to a
  `String` (or a `List<String>` with `allowMultiple: true`).

## 1.1.0

* `ArgParser.parse()` now takes an `Iterable<String>` rather than a
  `List<String>`.

* `ArgParser.addOption()`'s `allowed` option now takes an `Iterable<String>`
  rather than a `List<String>`.

## 1.0.2

* Fix analyzer warning

## 1.0.1

* Fix a fuzzy arrow type warning.

## 1.0.0

* **Breaking change**: The `allowTrailingOptions` argument to `new
  ArgumentParser()` defaults to `true` instead of `false`.

* Add `new ArgParser.allowAnything()`. This allows any input, without parsing
  any options.

## 0.13.7

* Add explicit support for forwarding the value returned by `Command.run()` to
  `CommandRunner.run()`. This worked unintentionally prior to 0.13.6+1.

* Add type arguments to `CommandRunner` and `Command` to indicate the return
  values of the `run()` functions.

## 0.13.6+1

* When a `CommandRunner` is passed `--help` before any commands, it now prints
  the usage of the chosen command.

## 0.13.6

* `ArgParser.parse()` now throws an `ArgParserException`, which implements
  `FormatException` and has a field that lists the commands that were parsed.

* If `CommandRunner.run()` encounters a parse error for a subcommand, it now
  prints the subcommand's usage rather than the global usage.

## 0.13.5

* Allow `CommandRunner.argParser` and `Command.argParser` to be overridden in
  strong mode.

## 0.13.4+2

* Fix a minor documentation error.

## 0.13.4+1

* Ensure that multiple-value arguments produce reified `List<String>`s.

## 0.13.4

* By default, only the first line of a command's description is included in its
  parent runner's usage string. This returns to the default behavior from
  before 0.13.3+1.

* A `Command.summary` getter has been added to explicitly control the summary
  that appears in the parent runner's usage string. This getter defaults to the
  first line of the description, but can be overridden if the user wants a
  multi-line summary.

## 0.13.3+6

* README fixes.

## 0.13.3+5

* Make strong mode clean.

## 0.13.3+4

* Use the proper `usage` getter in the README.

## 0.13.3+3

* Add an explicit default value for the `allowTrailingOptions` parameter to `new
  ArgParser()`. This doesn't change the behavior at all; the option already
  defaulted to `false`, and passing in `null` still works.

## 0.13.3+2

* Documentation fixes.

## 0.13.3+1

* Print all lines of multi-line command descriptions.

## 0.13.2

* Allow option values that look like options. This more closely matches the
  behavior of [`getopt`][getopt], the *de facto* standard for option parsing.

[getopt]: https://man7.org/linux/man-pages/man3/getopt.3.html

## 0.13.1

* Add `ArgParser.addSeparator()`. Separators allow users to group their options
  in the usage text.

## 0.13.0

* **Breaking change**: An option that allows multiple values will now
  automatically split apart comma-separated values. This can be controlled with
  the `splitCommas` option.

## 0.12.2+6

* Remove the dependency on the `collection` package.

## 0.12.2+5

* Add syntax highlighting to the README.

## 0.12.2+4

* Add an example of using command-line arguments to the README.

## 0.12.2+3

* Fixed implementation of ArgResults.options to really use Iterable<String>
  instead of Iterable<dynamic> cast to Iterable<String>.

## 0.12.2+2

* Updated dependency constraint on `unittest`.

* Formatted source code.

* Fixed use of deprecated API in example.

## 0.12.2+1

* Fix the built-in `help` command for `CommandRunner`.

## 0.12.2

* Add `CommandRunner` and `Command` classes which make it easy to build a
  command-based command-line application.

* Add an `ArgResults.arguments` field, which contains the original argument list.

## 0.12.1

* Replace `ArgParser.getUsage()` with `ArgParser.usage`, a getter.
  `ArgParser.getUsage()` is now deprecated, to be removed in args version 1.0.0.

## 0.12.0+2

* Widen the version constraint on the `collection` package.

## 0.12.0+1

* Remove the documentation link from the pubspec so this is linked to
  pub.dev by default.

## 0.12.0

* Removed public constructors for `ArgResults` and `Option`.

* `ArgResults.wasParsed()` can be used to determine if an option was actually
  parsed or the default value is being returned.

* Replaced `isFlag` and `allowMultiple` fields in the `Option` class with a
  three-value `OptionType` enum.

* Options may define `valueHelp` which will then be shown in the usage.

## 0.11.0

* Move handling trailing options from `ArgParser.parse()` into `ArgParser`
  itself. This lets subcommands have different behavior for how they handle
  trailing options.

## 0.10.0+2

* Usage ignores hidden options when determining column widths.
