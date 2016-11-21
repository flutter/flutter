// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'markdown.dart';

/// Style used for rendering markdown formatted text using the [MarkdownBody]
/// widget.
class MarkdownStyleRaw {

  /// Creates a new [MarkdownStyleRaw]
  MarkdownStyleRaw({
    this.a,
    this.p,
    this.code,
    this.h1,
    this.h2,
    this.h3,
    this.h4,
    this.h5,
    this.h6,
    this.em,
    this.strong,
    this.blockquote,
    this.blockSpacing,
    this.listIndent,
    this.blockquotePadding,
    this.blockquoteDecoration,
    this.codeblockPadding,
    this.codeblockDecoration
  }) {
    _init();
  }

  /// Creates a new [MarkdownStyleRaw] based on the current style, with the
  /// provided parameters overridden.
  MarkdownStyleRaw copyWith({
    TextStyle a,
    TextStyle p,
    TextStyle code,
    TextStyle h1,
    TextStyle h2,
    TextStyle h3,
    TextStyle h4,
    TextStyle h5,
    TextStyle h6,
    TextStyle em,
    TextStyle strong,
    TextStyle blockquote,
    double blockSpacing,
    double listIndent,
    double blockquotePadding,
    BoxDecoration blockquoteDecoration,
    double codeblockPadding,
    BoxDecoration codeblockDecoration
  }) {
    return new MarkdownStyleRaw(
      a: a != null ? a : this.a,
      p: p != null ? p : this.p,
      code: code != null ? code : this.code,
      h1: h1 != null ? h1 : this.h1,
      h2: h2 != null ? h2 : this.h2,
      h3: h3 != null ? h3 : this.h3,
      h4: h4 != null ? h4 : this.h4,
      h5: h5 != null ? h5 : this.h5,
      h6: h6 != null ? h6 : this.h6,
      em: em != null ? em : this.em,
      strong: strong != null ? strong : this.strong,
      blockquote: blockquote != null ? blockquote : this.blockquote,
      blockSpacing: blockSpacing != null ? blockSpacing : this.blockSpacing,
      listIndent: listIndent != null ? listIndent : this.listIndent,
      blockquotePadding: blockquotePadding != null ? blockquotePadding : this.blockquotePadding,
      blockquoteDecoration: blockquoteDecoration != null ? blockquoteDecoration : this.blockquoteDecoration,
      codeblockPadding: codeblockPadding != null ? codeblockPadding : this.codeblockPadding,
      codeblockDecoration: codeblockDecoration != null ? codeblockDecoration : this.codeblockDecoration
    );
  }

  final TextStyle a;
  final TextStyle p;
  final TextStyle code;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle h4;
  final TextStyle h5;
  final TextStyle h6;
  final TextStyle em;
  final TextStyle strong;
  final TextStyle blockquote;
  final double blockSpacing;
  final double listIndent;
  final double blockquotePadding;
  final BoxDecoration blockquoteDecoration;
  final double codeblockPadding;
  final BoxDecoration codeblockDecoration;

  Map<String, TextStyle> _styles;

  Map<String, TextStyle> get styles => _styles;

  void _init() {
    _styles = <String, TextStyle>{
      'a': a,
      'p': p,
      'li': p,
      'code': code,
      'pre': p,
      'h1': h1,
      'h2': h2,
      'h3': h3,
      'h4': h4,
      'h5': h5,
      'h6': h6,
      'em': em,
      'strong': strong,
      'blockquote': blockquote
    };
  }
}
