enum ASN1EncodingRule {
  /// Normal DER encoding rules
  ENCODING_DER,

  /// BER encoding where the length is described in a long form
  ENCODING_BER_LONG_LENGTH_FORM,

  /// BER Constructed encoding with definite length
  ENCODING_BER_CONSTRUCTED,

  /// BER encoding with padded bits to make the length of the value bytes a multiple of eight. Only used for ASN1BitString
  ENCODING_BER_PADDED,

  /// BER Constructed encoding with indefinite length
  ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH
}
