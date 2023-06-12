# Changelog

## 5.1.0

- Dart 2.18 requirement.
- Add `seq2`, `seq3`, ... combinator functions returning strongly typed sequences of `Sequence2<R1, R2>`, `Sequence3<R1, R2, R3>`, ...
- Add `Parser.starSeparated`, `Parser.plusSeparated`, `Parser.timesSeparated`, and `Parser.repeatSeparated` returning `SeparatedList` with the strongly typed elements and separators. Deprecate the dynamically typed `Parser.separatedBy`.
- Add `Parser.matchesAll` that creates a lazy iterable over the (overlapping or non-overlapping) successful parse results. Deprecate `matches` and `matchesSkipping`.
- Add a native platform independent `newline` parser.
- Add a section on debugging to the [tutorial](https://github.com/petitparser/dart-petitparser#debugging-your-grammars).
- Remove the deprecated `ref0`, `ref1`, ... instance methods, these methods are globally defined since 4.2.0.
- Make `GrammarDefinition` and `GrammarDefinition.start()` optionally typed.

## 5.0.0

* Dart 2.16 requirement.
* Moved PetitParser examples to a separate Git repository: https://github.com/petitparser/dart-petitparser-examples.
* Add a `skip` helper that silently consumes input before and/or after another parser.
* Make the `ExpressionBuilder<T>` statically typed. This requires existing code to specify the desired result type, and provide all reduction actions.
* Deprecate `hasSideEffect` in `MapParser` by considering all callbacks to have side-effects, the benefit of the added complications is negligible.
* Add `charIgnoringCase`, and provide better standard error messages for character parsers.
* Add initial support for indentation based grammars.

## 4.4.0

* Dart 2.15 requirement.
* Add a `PatternParser` that allows to use any Dart `Pattern` as a parser.
* Greatly improve the test coverage of all code to 98%.

## 4.3.0

* Dart 2.14 requirement.
* Add a `where` parser, that allows to add additional constraints on parse results.
* Add a `labeled` parser, that allows to add a debug label to the parser graph.
* Extract `Predicate<T>` and `Callback<T>` function types to shared file.
* Change debug functions to named arguments, and generate output events with first class objects instead of strings.
* Various improvements to the `Analyzer`:
  * Compute all deeply referenced children.
  * Compute all paths or the shortest path between parsers.
* Fix inaccuracies in character parser documentation and tutorial.
* Add more grammar linter rules that detect common bugs.

## 4.2.0

* Dart 2.13 requirement.
* `ref0`, `ref1`, `ref2`, ... is now also usable outside of `GrammarDefinition`.
  * Use `resolve` to inline all the referenced parsers, which now also works with `SettableParser`.
  * Deprecated `removeSettables`, that is superseded by the more powerful `resolve` operation.
* Add the possibility to join multiple `Token` and transform their values.
* Add `Analyzer` to compute nullability, as well as first-, follow-, and cycle-sets of parsers.
* Add a `linter` that performs a series of checks on grammar graphs.
* Expand the tutorial with a section on testing.

## 4.1.0

* Add the option to select the failure join strategy on `ChoiceParser` parsers:
  * `selectLast` is the default strategy, reporting the failure of the last parser tried.
  * `selectFarthest` reports the parser failure the farthest down in the input string, preferring later failures to earlier ones.
  * `selectFarthestJoined` is the same as above, but joins error messages that happen at the same position.
* Properly type all delegate parsers in choice, sequence, repeat, action, ...
  * Fix typing in `transformParser` and its users (debug tools, optimizers). To fix type your transformation function.
  * Fix typing of `GrammarDefinition` and reference parsers. To take advantage replace uses of `ref` with `ref0`, `ref1`, ...
  * Deprecate `GrammarParser`, a no longer needed wrapper around `GrammarDefinition`. Call `build()` on the definition to get the parser.
* Improve documentation and add a tutorial section on `GrammarDefinition`.

## 4.0.0

* Dart 2.12 requirement and null-safety.
* `Success.message` throws an `UnsupportedError` exception, instead of returning `null`.
* `DelegateParser` has been made abstract to avoid a concrete class in-between abstract classes.
* `Parser.delegate()` has been removed, use `Parser.settable()` as an equivalent replacement.
* `Parser.optional()` is now returning `Parser<T?>`, to provide a non-null default value use `Parser.optionalWith(T value)`.
* `Parser.not()` is now returning the failure `Parser<Failure<T>>` as success value, instead of `null`.
* `epsilon()` is now returning `Parser<void>`, to provide a non-null default value use `epsilonWith(T value)`.
* Removed const constructor from `Parser` hierarchy, as most parsers are inherently mutable and having some constant makes things inconsistent and more complicated than necessary.

## 3.1.0

* Fix missing type information on `eof` and `failure` parser.
* Optimize character predicates by using lookup tables.
* Improvements to documentation and examples.

## 3.0.0

* Dart 2.7 compatibility and requirement (extension methods).
* New features:
    * `String.toParser()` enables creating efficient string and character parsers more easily.
    * `Iterable.toChoiceParser()` and `Iterable.toSequenceParser()` enables creating parsers from collections more easily.
    * `Parser.callCC(Function)` enables capturing a parse continuation more easily.
* Restructure the internal code to be more modular:
    * The `Parser` class now only defines a few core methods, everything else is an extension method.
    * As long as you continue to import `package:petitparser/petitparser.dart` none of the changes should affect existing code.
    * Parser implementations have been moved to `package:petitparser/parser.dart`.
    * Helpers to parse and extract data has been moved to `package:petitparser/matcher.dart`.
    * The expression builder has been moved to `package:petitparser/expression.dart`.
    * The grammar builder has been moved to`package:petitparser/definition.dart`.
* Breaking changes:
    * `Parser` is no longer a `Pattern`, but can be converted to one with `toPattern`.
    * `anyIn` has been removed in favor of the already existing and equivalent `anyOf` parser.
    * `pick` and `permute` are defined on `Parser<List>`, thus they won't be available on the more generic `Parser<dynamic>` any longer. Prefix the operators with a `castList` operator.

## 2.5.0

* Made `ParserError` a `FormatException` to follow typical Dart exception style.

## 2.4.0

* Dart 2.4 compatibility and requirement.
* More tight typing, more strict linter rules.
* Documentation improvements.

## 2.3.0

* Dart 2.3 compatibility and requirement.
* The expression builder supports building expression with parenthesis.
* Improved the documentation on greedy and lazy parsers.
* Add a prolog parser and interpreter example.
* Numerous optimizations and improvements.

## 2.2.0

* Dart 2.2 compatibility and requirement.
* Parser implements the `Pattern` interface.
* Add an example of the expression builder to the tutorial.
* Introduce a fast-parse mode that avoids unnecessary memory allocations during parsing.

## 2.1.0

* Rename ParserError to ParserException, and make it an Exception.
* Simplify the `EndOfInputParser` and the `ListParser`.
* Add a `PositionParser` that produces the current input position.
* Constructor assertions across the stack.

## 2.0.0

* Make parsers fully typed, where it makes sense.
  * In most cases this should have no effect on existing code, but sometimes can point out actual bugs.
  * In rare cases, it might be necessary to insert `cast<R>` or `castList<R>` at the appropriate places.
* Move examples into their own example package.

## 1.8.0

* Drop Dart 1.0 compatibility.

## 1.7.6

* More Dart 2 strong mode fixes.

## 1.7.5

* Dart 2.0 strong mode compatibility.
* Removed deprecated code, and empty beta package.
* Reformatted all code using dartfmt.

## 1.7.0

* Dart 2.0 compatibility.
* Fixed numerous analyzer warnings.
* Generate better default error messages.
* Moved example grammars to examples.

## 1.6.1

* Fix bug with duplicated package name.
* Update documentation.

## 1.6.0

* Migrate to micro libraries.
* Move Smalltalk, Json, Dart and Lisp grammars to examples.

## 1.5.5

* Strict typing fixes.

## 1.5.4

* Fix analyzer warnings.
* Fix package dependencies.

## 1.5.3

* Dev compiler support.

## 1.5.2

* Enable strong mode.

## 1.5.1

* Improve the Dart parser and add more tests.

## 1.5.0

* Update documentation to match the style guide.
* Change library names.
* Add optimizations and tests for the Dart language grammar.
* Improve comments.
* Better error-handling and primitives for Lisp command line app.
* Fix unicode parsing in the JSON parser.
* Add browser back to dev_dependencies.

## 1.4.3

* Restore the CompositeParser class.
* Add more references to open source projects using PetitParser.

## 1.4.2

* Integrate the tutorial into the README.
* Improve formatting of README code blocks.

## 1.4.1

* Improve test coverage.
* Bump minimum SDK to 1.8.0.
* Remove deprecated CompositeParser class.

## 1.4.0

* Migrate from unittest to test.
* Setup Travis.
* Allow for const GrammarDefinitions.
* Fix typo in docs.
* Clean up the JSON grammar.
* Format the benchmarks.

## 1.3.7

* Cleanup dependencies:
  * browser is now `>=0.10.0 <0.11.0`.
  * unittest is now `>=0.11.0 <0.12.0`.
  * Remove explicit dependency on matcher package.
* Make the JSON parser twice as fast.
* Reformat tests.

## 1.3.6

* Add a benchmark for JSON native vs PetitParser.

## 1.3.5

* Change hasEqualProperties to gracefully handle parsers of inconsistent types.

## 1.3.4

* Format source code.
* Add missing documentation.

## 1.3.3

* Performance optimizations
