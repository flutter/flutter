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

class Node {
  Node(this.type, this.expectedSymbolCount);

  // Token constructors.
  Node.openBrace(): type = ST.openBrace, value = '{';
  Node.closeBrace(): type = ST.closeBrace, value = '}';
  Node.brace(String this.value) {
    if (value == '{') {
      type = ST.openBrace;
    } else if (value == '}') {
      type = ST.closeBrace;
    } else {
      // We should never arrive here.
      throw Exception('Provided value is not a brace.');
    }
    type = ST.openBrace;
  }
  Node.equalSign(): type = ST.equalSign, value = '=';
  Node.comma(): type = ST.comma, value = ',';
  Node.string(String this.value): type = ST.string;
  Node.number(String this.value): type = ST.number;
  Node.identifier(String this.value): type = ST.identifier;
  Node.pluralKeyword(): type = ST.plural, value = 'plural';
  Node.selectKeyword(): type = ST.select, value = 'select';
  Node.otherKeyword(): type = ST.other, value = 'other';
  Node.empty(): type = ST.empty, value = '';

  String? value;
  late ST type;
  List<Node> children = <Node>[];
  int expectedSymbolCount = 0;

  @override String toString() {
    return 'Node($value, $children)';
  }

  bool get isFull {
    return children.length >= expectedSymbolCount;
  }
}

RegExp specialCharOrWhitespace = RegExp(r'^[^a-zA-Z0-9]');
RegExp whitespace = RegExp(r'^\s');
RegExp validSpecialChar = RegExp(r'^[=,]');

RegExp numeric = RegExp(r'^[0-9]+');
RegExp alphanumeric = RegExp(r'^[a-zA-Z0-9]+');


List<Node> lex(String message) {
  bool isString = true;
  bool isEscaped = false;
  final StringBuffer buffer = StringBuffer();
  final List<Node> tokens = <Node>[];
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
            tokens.add(Node.string(buffer.toString()));
          }
          buffer.clear();
          isString = false;
          tokens.add(Node.brace(char));
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
          tokens.add(Node.pluralKeyword());
        } else if (value == 'select') {
          tokens.add(Node.selectKeyword());
        } else if (value == 'other') {
          tokens.add(Node.otherKeyword());
        } else if (buffer.toString().contains(numeric)) {
          tokens.add(Node.number(buffer.toString()));
        } else if (buffer.toString().contains(alphanumeric)) {
          tokens.add(Node.identifier(buffer.toString()));
        } else {
          throw Exception('lexing error: identifier $buffer tarts with a number');
        }
        buffer.clear();

        if (!char.contains(whitespace)) {
          if (char == '=') {
            tokens.add(Node.equalSign());
          } else if (char == ',') {
            tokens.add(Node.comma());
          } else if (char == '{' || char == '}') {
            tokens.add(Node.brace(char));
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

Node parse(List<Node> tokens) {
  final List<ST> parsingStack = <ST>[ST.message];
  final Node syntaxTree = Node(ST.empty, 1);
  final List<Node> treeTraversalStack = <Node>[syntaxTree];

  // Helper function for parsing and constructing tree.
  void parseAndConstructNode(ST nonterminal, int ruleIndex) {
    final Node parent = treeTraversalStack.last;
    final List<ST> grammarRule = grammar[nonterminal]![ruleIndex];
    final Node node = Node(nonterminal, grammarRule.length);
    parsingStack.addAll(grammarRule.reversed);

    // For tree construction, add nodes to the parent until the parent has all
    // all the children it is expecting.
    parent.children.add(node);
    if (parent.isFull) {
      treeTraversalStack.removeLast();
    }
    treeTraversalStack.add(node);
  }

  while (parsingStack.isNotEmpty) {
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
        final Node parent = treeTraversalStack.last;
        // If we match a terminal symbol, then remove it from tokens and
        // add it to the tree.
        if (symbol == ST.empty) {
          parent.children.add(Node.empty());
        } else if (symbol == tokens[0].type) {
          final Node token = tokens.removeAt(0);
          parent.children.add(token);
        } else {
          throw Exception('syntax error: expected $symbol but got token ${tokens[0]}');
        }

        if (parent.isFull) {
          treeTraversalStack.removeLast();
        }
    }
  }

  return syntaxTree.children[0];
}

// Compress the syntax tree, and check extra syntax rules. Note that after
// parse(lex(message)), the individual parts (ST.string, ST.placeholderExpr, 
// ST.pluralExpr, and ST.selectExpr) are structured as a linked list See diagram
// below. This
// function compresses these parts into a single children array (and does this
// for ST.pluralParts and ST.selectParts as well). Then it checks extra syntax
// rules. Essentially, it converts
//
//            Message
//            /     \
//    PluralExpr  Message
//                /     \
//            String  Message
//                    /     \
//            SelectExpr   ...
//
// to
//
//                Message
//               /   |   \
//     PluralExpr String SelectExpr ...
//
// Keep in mind that this modifies the tree in place and the values of 
// expectedSymbolCount and isFull is no longer useful after this operation.
Node compress(Node syntaxTree) {
  Node node = syntaxTree;
  final List<Node> children = <Node>[];
  switch (syntaxTree.type) {
    case ST.message:
    case ST.pluralParts:
    case ST.selectParts:
      while (node.children.length == 2) {
        children.add(node.children[0]);
        compress(node.children[0]);
        node = node.children[1];
      }
      syntaxTree.children = children;
      break;
    // ignore: no_default_cases
    default:
      node.children.forEach(compress);
  }
  return syntaxTree;
}
