// coverage:ignore-file

import '../context/context.dart';
import '../context/result.dart';
import '../parser/combinator/delegate.dart';
import 'grammar.dart';

/// A (now pointless) helper to build a parser from a {@link GrammarDefinition}.
@Deprecated('Directly use the GrammarDefinition to build parsers.')
class GrammarParser<T> extends DelegateParser<T, T> {
  @Deprecated('Directly use the GrammarDefinition to build parsers.')
  GrammarParser(GrammarDefinition definition) : this._(definition.build());

  @Deprecated('Directly use the GrammarDefinition to build parsers.')
  GrammarParser._(super.parser);

  @override
  Result<T> parseOn(Context context) => delegate.parseOn(context);

  @override
  int fastParseOn(String buffer, int position) =>
      delegate.fastParseOn(buffer, position);

  @override
  GrammarParser<T> copy() => GrammarParser<T>._(delegate);
}
