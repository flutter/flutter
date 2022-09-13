// Symbol Types
enum ST {
  // Terminal Types
  openBrace,
  closeBrace,
  comma,
  equalSign,
  other,
  plural,
  select,
  string,
  number,
  identifier,
  empty,
  // Nonterminal Types
  message,

  placeholderExpr,

  pluralExpr,
  pluralParts,
  pluralPart,

  selectExpr,
  selectParts,
  selectPart,
}

final List<ST> nonterminals = <ST>[
  ST.message,
  ST.placeholderExpr,
  ST.pluralExpr,
  ST.selectExpr,
  ST.pluralParts,
  ST.pluralPart,
  ST.selectExpr,
  ST.selectParts,
  ST.selectPart,
];

// The grammar of the syntax.
Map<ST, List<List<ST>>> grammar = <ST, List<List<ST>>>{
  ST.message: <List<ST>>[
    [ST.string, ST.message],
    [ST.placeholderExpr, ST.message],
    [ST.pluralExpr, ST.message],
    [ST.selectExpr, ST.message],
    [ST.empty]
  ],
  ST.placeholderExpr: <List<ST>>[
    [ST.openBrace, ST.identifier, ST.closeBrace],
  ],
  ST.pluralExpr: <List<ST>>[
    [ST.openBrace, ST.identifier, ST.comma, ST.plural, ST.comma, ST.pluralParts, ST.closeBrace],
  ],
  ST.pluralParts: <List<ST>>[
    [ST.pluralPart, ST.pluralParts],
    [ST.empty],
  ],
  ST.pluralPart: <List<ST>>[
    [ST.identifier, ST.openBrace, ST.message, ST.closeBrace],
    [ST.equalSign, ST.number, ST.openBrace, ST.message, ST.closeBrace],
    [ST.other, ST.openBrace, ST.message, ST.closeBrace],
  ],
  ST.selectExpr: <List<ST>>[
    [ST.openBrace, ST.identifier, ST.comma, ST.select, ST.comma, ST.selectParts, ST.closeBrace],
    [ST.other, ST.openBrace, ST.message, ST.closeBrace],
  ],
  ST.selectParts: <List<ST>>[
    [ST.selectPart, ST.selectParts],
    [ST.empty],
  ],
  ST.selectPart: <List<ST>>[
    [ST.identifier, ST.openBrace, ST.message, ST.closeBrace],
    [ST.other, ST.openBrace, ST.message, ST.closeBrace],
  ]
};

abstract class Node {
  Node(this.type);
  ST type;
}

class TokenNode extends Node {
  TokenNode(super.type, this.value);

  String value;

  @override String toString() {
    return 'Token($value)';
  }

  static TokenNode openBrace() {
    return TokenNode(ST.openBrace, '{');
  }

  static TokenNode closeBrace() {
    return TokenNode(ST.closeBrace, '}');
  }

  static TokenNode brace(String value) {
    if (value == '{') {
      return TokenNode(ST.openBrace, '{');
    } else if (value == '}') {
      return TokenNode(ST.closeBrace, '}');
    } else {
      // we should never arrive here.
      throw Exception('value is not a brace');
    }
  }

  static TokenNode equalSign() {
    return TokenNode(ST.equalSign, '=');
  }

  static TokenNode comma() {
    return TokenNode(ST.comma, ',');
  }

  static TokenNode string(String value) {
    return TokenNode(ST.string, value);
  }

  static TokenNode number(String value) {
    return TokenNode(ST.number, value);
  }

  static TokenNode identifier(String value) {
    return TokenNode(ST.identifier, value);
  }

  static TokenNode plural() {
    return TokenNode(ST.plural, 'plural');
  }

  static TokenNode select() {
    return TokenNode(ST.select, 'select');
  }

  static TokenNode other() {
    return TokenNode(ST.other, 'other');
  }

  static TokenNode empty() {
    return TokenNode(ST.empty, '');
  }
}

class NonterminalNode extends Node {
  NonterminalNode(super.type, this.totalSymbols): children = <Node>[];

  List<Node> children;

  @override
  String toString() {
    return 'Node($type, $children)';
  }

  // Total number of symbols to add.
  // This is dependent on the production rule.
  int totalSymbols;

  void addChild(Node childNode) {
    children.add(childNode);
  }
}

// Convert CST to AST
// class MessageNode extends Node {
//   MessageNode(Node node) {
//     assert(node.type == ST.message);
//     NonterminalNode n = node as NonterminalNode;
//     while (node.children.length == 2) {
//       switch (node.children[0].type) {
//         case ST.string:
//           messageParts.add(StringNode(node.children[0]));
//           break;
//         case ST.placeholderExpr:
//           messageParts.add(PlaceholderNode(node.children[0]));
//           break;
//         case ST.pluralExpr:
//           messageParts.add(PluralExpr(node.children[0]));
//       }
//       node = node.children[1];
//     }
//   }

//   List<MessagePartNode> messageParts = <MessagePartNode>[];
// }

// abstract class MessagePartNode extends Node {

// }

// class StringNode extends MessagePartNode {
//   StringNode(Node node) {
//     string = node.
//   }

//   String string;
// }

// class PlaceholderNode extends MessagePartNode {
//   String identifier;
// }

// enum PluralId {
//   zero,
//   one,
//   two,
//   many,
//   few,
//   other
// }

// class PluralNode extends MessagePartNode {
//   String identifier;
//   List<PluralPartNode> pluralParts;
// }

// class PluralPartNode extends Node {
//   String identifier;
//   MessageNode message;
// }

RegExp specialCharOrWhitespace = RegExp(r'^[^a-zA-Z0-9]');
RegExp whitespace = RegExp(r'^\s');
RegExp validSpecialChar = RegExp(r'^[=,]');

RegExp numeric = RegExp(r'^[0-9]+');
RegExp alphanumeric = RegExp(r'^[a-zA-Z0-9]+');


List<TokenNode> lex(String message) {
  bool isString = true;
  bool isEscaped = false;
  final StringBuffer buffer = StringBuffer();
  final List<TokenNode> tokens = <TokenNode>[];
  String? prevChar;
  for (final int rune in message.runes) {
    final String char = String.fromCharCode(rune);   
    if (isString) {
      // If we see '' then add ' to the buffer regardless of isEscape.
      if (char == "'" && prevChar == "'") {
        buffer.write(char);
      } else if (isEscaped) {
        if (char == "'") {
          isEscaped = false;
        } else {
          buffer.write(char);
        }
      } else {
        if (char == "'") {
          isEscaped = true;
        } else if (char == '{' || char == '}') { // Here we have an unescaped open brace.
          if(buffer.isNotEmpty) {
            tokens.add(TokenNode.string(buffer.toString()));
          }
          buffer.clear();
          isString = false;
          tokens.add(TokenNode.brace(char));
        } else {
          buffer.write(char);
        }
      }
    } else {
      // If !isString, delimit by whitespace and special characters.
      // If a token starts with a number, it is a number.
      // Otherwise it is an identifier.
      if (char.contains(specialCharOrWhitespace)) {
        final String value = buffer.toString();
        if (value.isEmpty) {
          // skip
        } else if (value == 'plural') {
          tokens.add(TokenNode.plural());
        } else if (value == 'select') {
          tokens.add(TokenNode.select());
        } else if (value == 'other') {
          tokens.add(TokenNode.other());
        } else if (buffer.toString().contains(numeric)) {
          tokens.add(TokenNode.number(buffer.toString()));
        } else if (buffer.toString().contains(alphanumeric)) {
          tokens.add(TokenNode.identifier(buffer.toString()));
        } else {
          throw Exception('lexing error: identifier $buffer tarts with a number');
        }
        buffer.clear();

        if (!char.contains(whitespace)) {
          if (char == '=') {
            tokens.add(TokenNode.equalSign());
          } else if (char == ',') {
            tokens.add(TokenNode.comma());
          } else if (char == '{' || char == '}') {
            tokens.add(TokenNode.brace(char));
            isString = true;
          } else {
            throw Exception('lexing error: unrecognized token $char');
          }
        }
      } else {
        buffer.write(char);
      }
    }
  }
  return tokens;
}

Node parse(List<TokenNode> tokens) {
  final List<ST> parsingStack = <ST>[ST.message];
  final NonterminalNode syntaxTree = NonterminalNode(ST.empty, 1);
  final List<NonterminalNode> treeTraversalStack = <NonterminalNode>[syntaxTree];

  // Helper function for parsing and constructing tree.
  void parseAndConstructNode(ST nonterminal, int ruleIndex) {
    print(nonterminal);
    final NonterminalNode parent = treeTraversalStack.last;
    final List<ST> grammarRule = grammar[nonterminal]![ruleIndex];
    final NonterminalNode node = NonterminalNode(nonterminal, grammarRule.length);
    parsingStack.addAll(grammarRule.reversed);

    // For tree construction, add nodes to the parent until the parent has all
    // all the children it is expecting.
    parent.children.add(node);
    if (parent.children.length >= parent.totalSymbols) {
      treeTraversalStack.removeLast();
    }
    treeTraversalStack.add(node);
  }

  while (parsingStack.isNotEmpty) {
    print(parsingStack);
    print(tokens);
    final ST symbol = parsingStack.removeLast();

    // Figure out which production rule to use.
    switch(symbol) {
      case ST.message:
        if (tokens.isNotEmpty && tokens[0].type == ST.closeBrace) {
          parseAndConstructNode(ST.message, 4);
        } else if (tokens.isNotEmpty && tokens[0].type == ST.string) {
          parseAndConstructNode(ST.message, 0);
        } else if (2 < tokens.length && tokens[2].type == ST.closeBrace) {
          parseAndConstructNode(ST.message, 1);
        } else if (3 < tokens.length && tokens[3].type == ST.plural) {
          parseAndConstructNode(ST.message, 2);
        } else if (3 < tokens.length && tokens[3].type == ST.select) {
          parseAndConstructNode(ST.message, 3);
        } else {
          parseAndConstructNode(ST.message, 4);
        }
        break;
      case ST.placeholderExpr:
        parseAndConstructNode(ST.placeholderExpr, 0);
        break;
      case ST.pluralExpr:
        parseAndConstructNode(ST.pluralExpr, 0);
        break;
      case ST.pluralParts:
        if (tokens.isNotEmpty && (
            tokens[0].type == ST.identifier ||
            tokens[0].type == ST.other ||
            tokens[0].type == ST.equalSign
          )
        ) {
          parseAndConstructNode(ST.pluralParts, 0);
        } else {
          parseAndConstructNode(ST.pluralParts, 1);
        }
        break;
      case ST.pluralPart:
        if (tokens.isNotEmpty && tokens[0].type == ST.identifier) {
          parseAndConstructNode(ST.pluralPart, 0);
        } else if (tokens.isNotEmpty && tokens[0].type == ST.equalSign) {
          parseAndConstructNode(ST.pluralPart, 1);
        } else if (tokens.isNotEmpty && tokens[0].type == ST.other) {
          parseAndConstructNode(ST.pluralPart, 2);
        } else {
          throw Exception('syntax error: expected plural part of form identifier { message }.');
        }
        break;
      case ST.selectExpr:
        parseAndConstructNode(ST.selectExpr, 0);
        break;
      case ST.selectParts:
        if (tokens.isNotEmpty && (
          tokens[0].type == ST.identifier ||
          tokens[0].type == ST.other
        )) {
          parseAndConstructNode(ST.selectParts, 0);
        } else {
          parseAndConstructNode(ST.selectParts, 1);
        }
        break;
      case ST.selectPart:
        if (tokens.isNotEmpty && tokens[0].type == ST.identifier) {
          parseAndConstructNode(ST.selectPart, 0);
        } else if (tokens.isNotEmpty && tokens[0].type == ST.other) {
          parseAndConstructNode(ST.selectPart, 1);
        } else {
          throw Exception('syntax error: expected select part of form identifier { message }.');
        }
        break;
      // At this point, we are only handling terminal symbols.
      // ignore: no_default_cases
      default:
        final NonterminalNode parent = treeTraversalStack.last;
        // If we match a terminal symbol, then remove it from tokens and
        // add it to the tree.
        if (symbol == ST.empty) {
          parent.children.add(TokenNode.empty());
        } else if (symbol == tokens[0].type) {
          final Node token = tokens.removeAt(0);
          parent.children.add(token);
        } else {
          throw Exception('syntax error: expected $symbol but got token ${tokens[0]}');
        }

        if (parent.children.length >= parent.totalSymbols) {
          treeTraversalStack.removeLast();
        }
    }
  }

  return syntaxTree.children[0];
}
