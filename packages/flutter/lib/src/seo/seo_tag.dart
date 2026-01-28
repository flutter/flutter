// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Enumeration of supported HTML semantic tags for SEO.
///
/// These tags represent the subset of HTML elements that are meaningful
/// for search engine optimization and document structure.
///
/// {@category SEO}
enum SeoTag {
  // Headings
  /// `<h1>` - Main page heading (use only once per page).
  h1,

  /// `<h2>` - Section heading
  h2,

  /// `<h3>` - Subsection heading
  h3,

  /// `<h4>` - Sub-subsection heading
  h4,

  /// `<h5>` - Minor heading
  h5,

  /// `<h6>` - Smallest heading
  h6,

  // Text content
  /// `<p>` - Paragraph
  p,

  /// `<span>` - Inline text container
  span,

  /// `<div>` - Generic block container
  div,

  // Document sections
  /// `<article>` - Self-contained content (blog post, news article, etc.)
  article,

  /// `<section>` - Thematic grouping of content
  section,

  /// `<aside>` - Tangentially related content (sidebar, callout)
  aside,

  /// `<nav>` - Navigation links
  nav,

  /// `<header>` - Introductory content or navigational aids
  header,

  /// `<footer>` - Footer for section or page
  footer,

  /// `<main>` - Main content of the document
  main,

  // Lists
  /// `<ul>` - Unordered list
  ul,

  /// `<ol>` - Ordered list
  ol,

  /// `<li>` - List item
  li,

  // Links and media
  /// `<a>` - Hyperlink
  a,

  /// `<img>` - Image
  img,

  /// `<figure>` - Self-contained content with optional caption
  figure,

  /// `<figcaption>` - Caption for a figure
  figcaption,

  // Quotations
  /// `<blockquote>` - Block quotation
  blockquote,

  /// `<cite>` - Citation or reference
  cite,

  /// `<q>` - Inline quotation
  q,

  // Time and data
  /// `<time>` - Date/time (machine-readable)
  time,

  /// `<data>` - Machine-readable equivalent
  data,

  /// `<address>` - Contact information
  address,

  // Emphasis
  /// `<strong>` - Strong importance
  strong,

  /// `<em>` - Stress emphasis
  em,

  /// `<mark>` - Highlighted/marked text
  mark,

  // Code
  /// `<code>` - Code fragment.
  code,

  /// `<pre>` - Preformatted text.
  pre,

  // Tables (basic support)
  /// `<table>` - Table.
  table,

  /// `<thead>` - Table head.
  thead,

  /// `<tbody>` - Table body.
  tbody,

  /// `<tr>` - Table row.
  tr,

  /// `<th>` - Table header cell.
  th,

  /// `<td>` - Table data cell.
  td,

  // Void elements
  /// `<br>` - Line break.
  br,

  /// `<hr>` - Horizontal rule.
  hr,
}

/// Extension methods for [SeoTag].
extension SeoTagExtension on SeoTag {
  /// Returns the HTML tag name as a string.
  ///
  /// This is an alias for [tagName] for convenience.
  String get htmlTag => tagName;

  /// Returns the HTML tag name as a string.
  String get tagName {
    switch (this) {
      case SeoTag.h1:
        return 'h1';
      case SeoTag.h2:
        return 'h2';
      case SeoTag.h3:
        return 'h3';
      case SeoTag.h4:
        return 'h4';
      case SeoTag.h5:
        return 'h5';
      case SeoTag.h6:
        return 'h6';
      case SeoTag.p:
        return 'p';
      case SeoTag.span:
        return 'span';
      case SeoTag.div:
        return 'div';
      case SeoTag.article:
        return 'article';
      case SeoTag.section:
        return 'section';
      case SeoTag.aside:
        return 'aside';
      case SeoTag.nav:
        return 'nav';
      case SeoTag.header:
        return 'header';
      case SeoTag.footer:
        return 'footer';
      case SeoTag.main:
        return 'main';
      case SeoTag.ul:
        return 'ul';
      case SeoTag.ol:
        return 'ol';
      case SeoTag.li:
        return 'li';
      case SeoTag.a:
        return 'a';
      case SeoTag.img:
        return 'img';
      case SeoTag.figure:
        return 'figure';
      case SeoTag.figcaption:
        return 'figcaption';
      case SeoTag.blockquote:
        return 'blockquote';
      case SeoTag.cite:
        return 'cite';
      case SeoTag.q:
        return 'q';
      case SeoTag.time:
        return 'time';
      case SeoTag.data:
        return 'data';
      case SeoTag.address:
        return 'address';
      case SeoTag.strong:
        return 'strong';
      case SeoTag.em:
        return 'em';
      case SeoTag.mark:
        return 'mark';
      case SeoTag.code:
        return 'code';
      case SeoTag.pre:
        return 'pre';
      case SeoTag.table:
        return 'table';
      case SeoTag.thead:
        return 'thead';
      case SeoTag.tbody:
        return 'tbody';
      case SeoTag.tr:
        return 'tr';
      case SeoTag.th:
        return 'th';
      case SeoTag.td:
        return 'td';
      case SeoTag.br:
        return 'br';
      case SeoTag.hr:
        return 'hr';
    }
  }

  /// Whether this tag is a void element (self-closing, no children).
  ///
  /// This is an alias for [isVoidElement].
  bool get isVoid => isVoidElement;

  /// Whether this tag is a void element (self-closing, no children).
  bool get isVoidElement {
    switch (this) {
      case SeoTag.img:
      case SeoTag.br:
      case SeoTag.hr:
        return true;
      case SeoTag.h1:
      case SeoTag.h2:
      case SeoTag.h3:
      case SeoTag.h4:
      case SeoTag.h5:
      case SeoTag.h6:
      case SeoTag.p:
      case SeoTag.span:
      case SeoTag.div:
      case SeoTag.article:
      case SeoTag.section:
      case SeoTag.aside:
      case SeoTag.nav:
      case SeoTag.header:
      case SeoTag.footer:
      case SeoTag.main:
      case SeoTag.ul:
      case SeoTag.ol:
      case SeoTag.li:
      case SeoTag.a:
      case SeoTag.figure:
      case SeoTag.figcaption:
      case SeoTag.blockquote:
      case SeoTag.cite:
      case SeoTag.q:
      case SeoTag.time:
      case SeoTag.data:
      case SeoTag.address:
      case SeoTag.strong:
      case SeoTag.em:
      case SeoTag.mark:
      case SeoTag.code:
      case SeoTag.pre:
      case SeoTag.table:
      case SeoTag.thead:
      case SeoTag.tbody:
      case SeoTag.tr:
      case SeoTag.th:
      case SeoTag.td:
        return false;
    }
  }

  /// Whether this tag is a block-level element.
  ///
  /// This is an alias for [isBlockElement].
  bool get isBlock => isBlockElement;

  /// Whether this tag is a block-level element.
  bool get isBlockElement {
    switch (this) {
      case SeoTag.h1:
      case SeoTag.h2:
      case SeoTag.h3:
      case SeoTag.h4:
      case SeoTag.h5:
      case SeoTag.h6:
      case SeoTag.p:
      case SeoTag.div:
      case SeoTag.article:
      case SeoTag.section:
      case SeoTag.aside:
      case SeoTag.nav:
      case SeoTag.header:
      case SeoTag.footer:
      case SeoTag.main:
      case SeoTag.ul:
      case SeoTag.ol:
      case SeoTag.li:
      case SeoTag.figure:
      case SeoTag.blockquote:
      case SeoTag.address:
      case SeoTag.pre:
      case SeoTag.table:
      case SeoTag.thead:
      case SeoTag.tbody:
      case SeoTag.tr:
      case SeoTag.hr:
        return true;
      case SeoTag.span:
      case SeoTag.a:
      case SeoTag.img:
      case SeoTag.figcaption:
      case SeoTag.cite:
      case SeoTag.q:
      case SeoTag.time:
      case SeoTag.data:
      case SeoTag.strong:
      case SeoTag.em:
      case SeoTag.mark:
      case SeoTag.code:
      case SeoTag.th:
      case SeoTag.td:
      case SeoTag.br:
        return false;
    }
  }

  /// Whether this tag represents a heading element.
  bool get isHeading {
    switch (this) {
      case SeoTag.h1:
      case SeoTag.h2:
      case SeoTag.h3:
      case SeoTag.h4:
      case SeoTag.h5:
      case SeoTag.h6:
        return true;
      case SeoTag.p:
      case SeoTag.span:
      case SeoTag.div:
      case SeoTag.article:
      case SeoTag.section:
      case SeoTag.aside:
      case SeoTag.nav:
      case SeoTag.header:
      case SeoTag.footer:
      case SeoTag.main:
      case SeoTag.ul:
      case SeoTag.ol:
      case SeoTag.li:
      case SeoTag.a:
      case SeoTag.img:
      case SeoTag.figure:
      case SeoTag.figcaption:
      case SeoTag.blockquote:
      case SeoTag.cite:
      case SeoTag.q:
      case SeoTag.time:
      case SeoTag.data:
      case SeoTag.address:
      case SeoTag.strong:
      case SeoTag.em:
      case SeoTag.mark:
      case SeoTag.code:
      case SeoTag.pre:
      case SeoTag.table:
      case SeoTag.thead:
      case SeoTag.tbody:
      case SeoTag.tr:
      case SeoTag.th:
      case SeoTag.td:
      case SeoTag.br:
      case SeoTag.hr:
        return false;
    }
  }

  /// Returns the heading level (1-6) or null if not a heading.
  int? get headingLevel {
    switch (this) {
      case SeoTag.h1:
        return 1;
      case SeoTag.h2:
        return 2;
      case SeoTag.h3:
        return 3;
      case SeoTag.h4:
        return 4;
      case SeoTag.h5:
        return 5;
      case SeoTag.h6:
        return 6;
      case SeoTag.p:
      case SeoTag.span:
      case SeoTag.div:
      case SeoTag.article:
      case SeoTag.section:
      case SeoTag.aside:
      case SeoTag.nav:
      case SeoTag.header:
      case SeoTag.footer:
      case SeoTag.main:
      case SeoTag.ul:
      case SeoTag.ol:
      case SeoTag.li:
      case SeoTag.a:
      case SeoTag.img:
      case SeoTag.figure:
      case SeoTag.figcaption:
      case SeoTag.blockquote:
      case SeoTag.cite:
      case SeoTag.q:
      case SeoTag.time:
      case SeoTag.data:
      case SeoTag.address:
      case SeoTag.strong:
      case SeoTag.em:
      case SeoTag.mark:
      case SeoTag.code:
      case SeoTag.pre:
      case SeoTag.table:
      case SeoTag.thead:
      case SeoTag.tbody:
      case SeoTag.tr:
      case SeoTag.th:
      case SeoTag.td:
      case SeoTag.br:
      case SeoTag.hr:
        return null;
    }
  }
}
