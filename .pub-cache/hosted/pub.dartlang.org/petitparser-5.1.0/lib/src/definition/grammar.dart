import 'package:meta/meta.dart';

import '../core/parser.dart';
import 'reference.dart';
import 'resolve.dart';

/// Helper to conveniently define and build complex, recursive grammars using
/// plain Dart code.
///
/// To create a new grammar definition subclass [GrammarDefinition]. For every
/// production create a new method returning the primitive parser defining it.
/// The method called [start] is supposed to return the start production of the
/// grammar (that can be customized when building the parsers). To refer to
/// another production use [ref0] with the function reference as the argument.
///
/// Consider the following example to parse a list of numbers:
///
///     class ListGrammarDefinition extends GrammarDefinition {
///       Parser start()   => ref0(list).end();
///       Parser list()    => ref0(element) & char(',') & ref0(list)
///                         | ref0(element);
///       Parser element() => digit().plus().flatten();
///     }
///
/// Since this is plain Dart code, common refactorings such as renaming a
/// production updates all references correctly. Also code navigation and code
/// completion works as expected.
///
/// To attach custom production actions you might want to further subclass your
/// grammar definition and override overriding the necessary productions defined
/// in the superclass:
///
///     class ListParserDefinition extends ListGrammarDefinition {
///       Parser element() => super.element().map((value) => int.parse(value));
///     }
///
/// Note that productions can be parametrized. Define such productions with
/// positional arguments, and refer to them using [ref1], [ref2], ... where
/// the number corresponds to the argument count.
///
/// Consider extending the above grammar with a parametrized token production:
///
///     class TokenizedListGrammarDefinition extends GrammarDefinition {
///       Parser start() => ref0(list).end();
///       Parser list() => ref0(element) & ref1(token, char(',')) & ref0(list)
///                      | ref0(element);
///       Parser element() => ref1(token, digit().plus());
///       Parser token(Parser parser)  => parser.token().trim();
///     }
///
/// To get a runnable parser call the [build] method on the definition. It
/// resolves recursive references and returns an efficient parser that can be
/// further composed. The optional `start` reference specifies a different
/// starting production within the grammar. The optional `arguments`
/// parametrize the start production.
///
///     final parser = new ListParserDefinition().build();
///
///     parser.parse('1');          // [1]
///     parser.parse('1,2,3');      // [1, 2, 3]
///
@optionalTypeArgs
abstract class GrammarDefinition<R> {
  const GrammarDefinition();

  /// The starting production of this definition.
  Parser<R> start();

  /// Builds a composite parser from this definition.
  ///
  /// The optional [start] reference specifies a different starting production
  /// into the grammar. The optional [arguments] list parametrizes the called
  /// production.
  Parser<T> build<T>({Function? start, List<Object> arguments = const []}) {
    if (start != null) {
      return resolve(Function.apply(start, arguments));
    } else if (arguments.isEmpty) {
      return resolve(this.start() as Parser<T>);
    } else {
      throw StateError('Invalid arguments passed.');
    }
  }
}
