// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../scanner/token.dart';
import 'literal_entry_info.dart';
import 'parser_impl.dart';
import 'util.dart';

/// [ifCondition] is the first step for parsing a literal entry
/// starting with `if` control flow.
const LiteralEntryInfo ifCondition = const IfCondition();

/// [spreadOperator] is the first step for parsing a literal entry
/// preceded by a '...' spread operator.
const LiteralEntryInfo spreadOperator = const SpreadOperator();

/// The first step when processing a `for` control flow collection entry.
class ForCondition extends LiteralEntryInfo {
  bool _inStyle = false;

  ForCondition() : super(false, 0);

  @override
  Token parse(Token token, Parser parser) {
    Token next = token.next!;
    Token? awaitToken;
    if (optional('await', next)) {
      awaitToken = token = next;
      next = token.next!;
    }
    final Token forToken = next;
    assert(optional('for', forToken));
    parser.listener.beginForControlFlow(awaitToken, forToken);

    token = parser.parseForLoopPartsStart(awaitToken, forToken);
    Token identifier = token.next!;
    token = parser.parseForLoopPartsMid(token, awaitToken, forToken);

    if (optional('in', token.next!) || optional(':', token.next!)) {
      // Process `for ( ... in ... )`
      _inStyle = true;
      token = parser.parseForInLoopPartsRest(
          token, awaitToken, forToken, identifier);
    } else {
      // Process `for ( ... ; ... ; ... )`
      _inStyle = false;
      token = parser.parseForLoopPartsRest(token, forToken, awaitToken);
    }
    return token;
  }

  @override
  LiteralEntryInfo computeNext(Token token) {
    Token next = token.next!;
    if (optional('for', next) ||
        (optional('await', next) && optional('for', next.next!))) {
      return new Nested(
        new ForCondition(),
        _inStyle ? const ForInComplete() : const ForComplete(),
      );
    } else if (optional('if', next)) {
      return new Nested(
        ifCondition,
        _inStyle ? const ForInComplete() : const ForComplete(),
      );
    } else if (optional('...', next) || optional('...?', next)) {
      return _inStyle ? const ForInSpread() : const ForSpread();
    }
    return _inStyle ? const ForInEntry() : const ForEntry();
  }
}

/// A step for parsing a spread collection
/// as the "for" control flow's expression.
class ForSpread extends SpreadOperator {
  const ForSpread();

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const ForComplete();
  }
}

/// A step for parsing a spread collection
/// as the "for-in" control flow's expression.
class ForInSpread extends SpreadOperator {
  const ForInSpread();

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const ForInComplete();
  }
}

/// A step for parsing a literal list, set, or map entry
/// as the "for" control flow's expression.
class ForEntry extends LiteralEntryInfo {
  const ForEntry() : super(true, 0);

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const ForComplete();
  }
}

/// A step for parsing a literal list, set, or map entry
/// as the "for-in" control flow's expression.
class ForInEntry extends LiteralEntryInfo {
  const ForInEntry() : super(true, 0);

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const ForInComplete();
  }
}

class ForComplete extends LiteralEntryInfo {
  const ForComplete() : super(false, 0);

  @override
  Token parse(Token token, Parser parser) {
    parser.listener.endForControlFlow(token);
    return token;
  }
}

class ForInComplete extends LiteralEntryInfo {
  const ForInComplete() : super(false, 0);

  @override
  Token parse(Token token, Parser parser) {
    parser.listener.endForInControlFlow(token);
    return token;
  }
}

/// The first step when processing an `if` control flow collection entry.
class IfCondition extends LiteralEntryInfo {
  const IfCondition() : super(false, 1);

  @override
  Token parse(Token token, Parser parser) {
    final Token ifToken = token.next!;
    assert(optional('if', ifToken));
    parser.listener.beginIfControlFlow(ifToken);
    Token result = parser.ensureParenthesizedCondition(ifToken);
    parser.listener.handleThenControlFlow(result);
    return result;
  }

  @override
  LiteralEntryInfo computeNext(Token token) {
    Token next = token.next!;
    if (optional('for', next) ||
        (optional('await', next) && optional('for', next.next!))) {
      return new Nested(new ForCondition(), const IfComplete());
    } else if (optional('if', next)) {
      return new Nested(ifCondition, const IfComplete());
    } else if (optional('...', next) || optional('...?', next)) {
      return const IfSpread();
    }
    return const IfEntry();
  }
}

/// A step for parsing a spread collection
/// as the `if` control flow's then-expression.
class IfSpread extends SpreadOperator {
  const IfSpread();

  @override
  LiteralEntryInfo computeNext(Token token) => const IfComplete();
}

/// A step for parsing a literal list, set, or map entry
/// as the `if` control flow's then-expression.
class IfEntry extends LiteralEntryInfo {
  const IfEntry() : super(true, 0);

  @override
  LiteralEntryInfo computeNext(Token token) => const IfComplete();
}

class IfComplete extends LiteralEntryInfo {
  const IfComplete() : super(false, 0);

  @override
  Token parse(Token token, Parser parser) {
    if (!optional('else', token.next!)) {
      parser.listener.endIfControlFlow(token);
    }
    return token;
  }

  @override
  LiteralEntryInfo? computeNext(Token token) {
    return optional('else', token.next!) ? const IfElse() : null;
  }
}

/// A step for parsing the `else` portion of an `if` control flow.
class IfElse extends LiteralEntryInfo {
  const IfElse() : super(false, -1);

  @override
  Token parse(Token token, Parser parser) {
    Token elseToken = token.next!;
    assert(optional('else', elseToken));
    parser.listener.handleElseControlFlow(elseToken);
    return elseToken;
  }

  @override
  LiteralEntryInfo computeNext(Token token) {
    assert(optional('else', token));
    Token next = token.next!;
    if (optional('for', next) ||
        (optional('await', next) && optional('for', next.next!))) {
      return new Nested(new ForCondition(), const IfElseComplete());
    } else if (optional('if', next)) {
      return new Nested(ifCondition, const IfElseComplete());
    } else if (optional('...', next) || optional('...?', next)) {
      return const ElseSpread();
    }
    return const ElseEntry();
  }
}

class ElseSpread extends SpreadOperator {
  const ElseSpread();

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const IfElseComplete();
  }
}

class ElseEntry extends LiteralEntryInfo {
  const ElseEntry() : super(true, 0);

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const IfElseComplete();
  }
}

class IfElseComplete extends LiteralEntryInfo {
  const IfElseComplete() : super(false, 0);

  @override
  Token parse(Token token, Parser parser) {
    parser.listener.endIfElseControlFlow(token);
    return token;
  }
}

/// The first step when processing a spread entry.
class SpreadOperator extends LiteralEntryInfo {
  const SpreadOperator() : super(false, 0);

  @override
  Token parse(Token token, Parser parser) {
    final Token operator = token.next!;
    assert(optional('...', operator) || optional('...?', operator));
    token = parser.parseExpression(operator);
    parser.listener.handleSpreadExpression(operator);
    return token;
  }
}

class Nested extends LiteralEntryInfo {
  LiteralEntryInfo? nestedStep;
  final LiteralEntryInfo lastStep;

  Nested(this.nestedStep, this.lastStep) : super(false, 0);

  @override
  bool get hasEntry => nestedStep!.hasEntry;

  @override
  Token parse(Token token, Parser parser) => nestedStep!.parse(token, parser);

  @override
  LiteralEntryInfo computeNext(Token token) {
    nestedStep = nestedStep!.computeNext(token);
    return nestedStep != null ? this : lastStep;
  }
}
