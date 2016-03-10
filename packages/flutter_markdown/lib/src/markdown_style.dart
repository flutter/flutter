// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'markdown_style_raw.dart';

/// Style used for rendering markdown formatted text using the [MarkdownBody]
/// widget.
class MarkdownStyle extends MarkdownStyleRaw{

  /// Creates a [MarkdownStyle] from the [TextStyle]s in the provided [theme].
  MarkdownStyle.defaultFromTheme(ThemeData theme) : super(
    a: new TextStyle(color: Colors.blue[500]),
    p: theme.text.body1,
    code: new TextStyle(
      color: Colors.grey[700],
      fontFamily: "monospace",
      fontSize: theme.text.body1.fontSize * 0.85
    ),
    h1: theme.text.headline,
    h2: theme.text.title,
    h3: theme.text.subhead,
    h4: theme.text.body2,
    h5: theme.text.body2,
    h6: theme.text.body2,
    em: new TextStyle(fontStyle: FontStyle.italic),
    strong: new TextStyle(fontWeight: FontWeight.bold),
    blockquote: theme.text.body1,
    blockSpacing: 8.0,
    listIndent: 32.0,
    blockquotePadding: 8.0,
    blockquoteDecoration: new BoxDecoration(
      backgroundColor: Colors.blue[100],
      borderRadius: 2.0
    ),
    codeblockPadding: 8.0,
    codeblockDecoration: new BoxDecoration(
      backgroundColor: Colors.grey[100],
      borderRadius: 2.0
    )
  );

  /// Creates a [MarkdownStyle] from the [TextStyle]s in the provided [theme].
  /// This style uses larger fonts for the headings than in
  /// [MarkdownStyle.defaultFromTheme].
  MarkdownStyle.largeFromTheme(ThemeData theme) : super (
    a: new TextStyle(color: Colors.blue[500]),
    p: theme.text.body1,
    code: new TextStyle(
      color: Colors.grey[700],
      fontFamily: "monospace",
      fontSize: theme.text.body1.fontSize * 0.85
    ),
    h1: theme.text.display3,
    h2: theme.text.display2,
    h3: theme.text.display1,
    h4: theme.text.headline,
    h5: theme.text.title,
    h6: theme.text.subhead,
    em: new TextStyle(fontStyle: FontStyle.italic),
    strong: new TextStyle(fontWeight: FontWeight.bold),
    blockquote: theme.text.body1,
    blockSpacing: 8.0,
    listIndent: 32.0,
    blockquotePadding: 8.0,
    blockquoteDecoration: new BoxDecoration(
      backgroundColor: Colors.blue[100],
      borderRadius: 2.0
    ),
    codeblockPadding: 8.0,
    codeblockDecoration: new BoxDecoration(
      backgroundColor: Colors.grey[100],
      borderRadius: 2.0
    )
  );
}
