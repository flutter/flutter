// ignore_for_file: constant_identifier_names

/// Enum of the different XML node types.
enum XmlNodeType {
  /// An attribute, e.g. `id="123"`.
  ATTRIBUTE,

  /// A character data, e.g.  `<![CDATA[escaped text]]>`.
  CDATA,

  /// A comment, e.g. `<!-- comment -->`.
  COMMENT,

  /// A xml declaration, e.g. `<?xml version='1.0'?>`.
  DECLARATION,

  /// A document type declaration, e.g. `<!DOCTYPE html>`.
  DOCUMENT_TYPE,

  /// A document object.
  DOCUMENT,

  /// A document fragment, e.g. `#document-fragment`.
  DOCUMENT_FRAGMENT,

  /// An element, e.g. `<item>` or `<item />`.
  ELEMENT,

  /// A processing instruction, e.g. `<?pi test?>`.
  PROCESSING,

  /// A text, e.g. `Hello World`.
  TEXT,
}
