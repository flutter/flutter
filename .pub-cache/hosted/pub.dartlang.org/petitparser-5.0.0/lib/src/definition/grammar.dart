import 'package:meta/meta.dart';

import '../core/parser.dart';
import 'internal/undefined.dart';
import 'reference.dart' as reference;
import 'resolve.dart';

/// Helper to conveniently define and build complex, recursive grammars using
/// plain Dart code.
///
/// To create a new grammar definition subclass [GrammarDefinition]. For every
/// production create a new method returning the primitive parser defining it.
/// The method called [start] is supposed to return the start production of the
/// grammar (that can be customized when building the parsers). To refer to a
/// production defined in the same definition use [ref0] with the function
/// reference as the argument.
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
abstract class GrammarDefinition {
  const GrammarDefinition();

  /// The starting production of this definition.
  Parser start();

  /// Reference to a production [callback] optionally parametrized with
  /// [arg1], [arg2], [arg3], [arg4], and [arg5].
  ///
  /// This function is deprecated because it doesn't work well in strong mode.
  /// Use [ref0], [ref1], [ref2], [ref3], [ref4], or [ref5] instead.
  @Deprecated('Use [ref0], [ref1], [ref2], ... instead.')
  Parser<T> ref<T>(Function callback,
          [dynamic arg1 = undefined,
          dynamic arg2 = undefined,
          dynamic arg3 = undefined,
          dynamic arg4 = undefined,
          dynamic arg5 = undefined]) =>
      reference.ref(callback, arg1, arg2, arg3, arg4, arg5);

  /// Reference to a production [callback] without any parameters.
  Parser<T> ref0<T>(Parser<T> Function() callback) =>
      reference.ref0<T>(callback);

  /// Reference to a production [callback] parametrized with a single argument
  /// [arg1].
  Parser<T> ref1<T, A1>(Parser<T> Function(A1) callback, A1 arg1) =>
      reference.ref1<T, A1>(callback, arg1);

  /// Reference to a production [callback] parametrized with two arguments
  /// [arg1] and [arg2].
  Parser<T> ref2<T, A1, A2>(
          Parser<T> Function(A1, A2) callback, A1 arg1, A2 arg2) =>
      reference.ref2<T, A1, A2>(callback, arg1, arg2);

  /// Reference to a production [callback] parametrized with tree arguments
  /// [arg1], [arg2], and [arg3].
  Parser<T> ref3<T, A1, A2, A3>(
          Parser<T> Function(A1, A2, A3) callback, A1 arg1, A2 arg2, A3 arg3) =>
      reference.ref3<T, A1, A2, A3>(callback, arg1, arg2, arg3);

  /// Reference to a production [callback] parametrized with four arguments
  /// [arg1], [arg2], [arg3], and [arg4].
  Parser<T> ref4<T, A1, A2, A3, A4>(Parser<T> Function(A1, A2, A3, A4) callback,
          A1 arg1, A2 arg2, A3 arg3, A4 arg4) =>
      reference.ref4<T, A1, A2, A3, A4>(callback, arg1, arg2, arg3, arg4);

  /// Reference to a production [callback] parametrized with five arguments
  /// [arg1], [arg2], [arg3], [arg4], and [arg5].
  Parser<T> ref5<T, A1, A2, A3, A4, A5>(
          Parser<T> Function(A1, A2, A3, A4, A5) callback,
          A1 arg1,
          A2 arg2,
          A3 arg3,
          A4 arg4,
          A5 arg5) =>
      reference.ref5<T, A1, A2, A3, A4, A5>(
          callback, arg1, arg2, arg3, arg4, arg5);

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
