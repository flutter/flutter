// ignore_for_file: constant_identifier_names

/// Enum of the attribute quote types.
enum XmlAttributeType {
  SINGLE_QUOTE("'"),
  DOUBLE_QUOTE('"');

  const XmlAttributeType(this.token);

  factory XmlAttributeType.fromToken(String token) {
    assert(SINGLE_QUOTE.token == token || DOUBLE_QUOTE.token == token,
        'Unexpected attribute type token: $token');
    return SINGLE_QUOTE.token == token ? SINGLE_QUOTE : DOUBLE_QUOTE;
  }

  final String token;
}
