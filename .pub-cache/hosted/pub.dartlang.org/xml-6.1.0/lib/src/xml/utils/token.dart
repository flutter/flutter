/// Shared tokens for XML reading and writing.
class XmlToken {
  static const doubleQuote = '"';
  static const singleQuote = "'";
  static const equals = '=';
  static const namespace = ':';
  static const whitespace = ' ';
  static const openComment = '<!--';
  static const closeComment = '-->';
  static const openCDATA = '<![CDATA[';
  static const closeCDATA = ']]>';
  static const openElement = '<';
  static const closeElement = '>';
  static const openEndElement = '</';
  static const closeEndElement = '/>';
  static const openDeclaration = '<?xml';
  static const closeDeclaration = '?>';
  static const openDoctype = '<!DOCTYPE';
  static const closeDoctype = '>';
  static const openDoctypeIntSubset = '[';
  static const closeDoctypeIntSubset = ']';
  static const doctypeSystemId = 'SYSTEM';
  static const doctypePublicId = 'PUBLIC';
  static const doctypeElementDecl = '<!ELEMENT';
  static const doctypeAttlistDecl = '<!ATTLIST';
  static const doctypeEntityDecl = '<!ENTITY';
  static const doctypeNotationDecl = '<!NOTATION';
  static const doctypeDeclEnd = '>';
  static const doctypeReferenceStart = '%';
  static const doctypeReferenceEnd = ';';
  static const openProcessing = '<?';
  static const closeProcessing = '?>';
  static const entityStart = '&';
  static const entityEnd = ';';

  // https://en.wikipedia.org/wiki/QName
  static const nameStartChars = ':A-Z_a-z'
      '\u00c0-\u00d6'
      '\u00d8-\u00f6'
      '\u00f8-\u02ff'
      '\u0370-\u037d'
      '\u037f-\u1fff'
      '\u200c-\u200d'
      '\u2070-\u218f'
      '\u2c00-\u2fef'
      '\u3001-\ud7ff'
      '\uf900-\ufdcf'
      '\ufdf0-\ufffd';
  static const nameChars = '$nameStartChars'
      '-.0-9'
      '\u00b7'
      '\u0300-\u036f'
      '\u203f-\u2040';
}
