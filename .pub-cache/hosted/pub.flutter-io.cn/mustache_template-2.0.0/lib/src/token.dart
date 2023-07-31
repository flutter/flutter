class TokenType {
  const TokenType(this.name);

  final String name;

  @override
  String toString() => '(TokenType $name)';

  static const TokenType text = TokenType('text');
  static const TokenType openDelimiter = TokenType('openDelimiter');
  static const TokenType closeDelimiter = TokenType('closeDelimiter');

  // A sigil is the word commonly used to describe the special character at the
  // start of mustache tag i.e. #, ^ or /.
  static const TokenType sigil = TokenType('sigil');
  static const TokenType identifier = TokenType('identifier');
  static const TokenType dot = TokenType('dot');

  static const TokenType changeDelimiter = TokenType('changeDelimiter');
  static const TokenType whitespace = TokenType('whitespace');
  static const TokenType lineEnd = TokenType('lineEnd');
}

class Token {
  Token(this.type, this.value, this.start, this.end);

  final TokenType type;
  final String value;

  final int start;
  final int end;

  @override
  String toString() => '(Token ${type.name} \"$value\" $start $end)';
}
