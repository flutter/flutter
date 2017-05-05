// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Defines which [TextStyle] objects to use for which Markdown elements.
class MarkdownStyleSheet {
  /// Creates an explicit mapping of [TextStyle] objects to Markdown elements.
  MarkdownStyleSheet({
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
  }) : _styles = <String, TextStyle>{
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

  /// Creates a [MarkdownStyleSheet] from the [TextStyle]s in the provided [ThemeData].
  factory MarkdownStyleSheet.fromTheme(ThemeData theme) {
    return new MarkdownStyleSheet(
      a: const TextStyle(color: Colors.blue),
      p: theme.textTheme.body1,
      code: new TextStyle(
        color: Colors.grey.shade700,
        fontFamily: "monospace",
        fontSize: theme.textTheme.body1.fontSize * 0.85
      ),
      h1: theme.textTheme.headline,
      h2: theme.textTheme.title,
      h3: theme.textTheme.subhead,
      h4: theme.textTheme.body2,
      h5: theme.textTheme.body2,
      h6: theme.textTheme.body2,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      blockquote: theme.textTheme.body1,
      blockSpacing: 8.0,
      listIndent: 32.0,
      blockquotePadding: 8.0,
      blockquoteDecoration: new BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: new BorderRadius.circular(2.0)
      ),
      codeblockPadding: 8.0,
      codeblockDecoration: new BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: new BorderRadius.circular(2.0)
      )
    );
  }

  /// Creates a [MarkdownStyle] from the [TextStyle]s in the provided [ThemeData].
  ///
  /// This constructor uses larger fonts for the headings than in
  /// [new MarkdownStyle.fromTheme].
  factory MarkdownStyleSheet.largeFromTheme(ThemeData theme) {
    return new MarkdownStyleSheet(
      a: const TextStyle(color: Colors.blue),
      p: theme.textTheme.body1,
      code: new TextStyle(
        color: Colors.grey.shade700,
        fontFamily: "monospace",
        fontSize: theme.textTheme.body1.fontSize * 0.85
      ),
      h1: theme.textTheme.display3,
      h2: theme.textTheme.display2,
      h3: theme.textTheme.display1,
      h4: theme.textTheme.headline,
      h5: theme.textTheme.title,
      h6: theme.textTheme.subhead,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      blockquote: theme.textTheme.body1,
      blockSpacing: 8.0,
      listIndent: 32.0,
      blockquotePadding: 8.0,
      blockquoteDecoration: new BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: new BorderRadius.circular(2.0)
      ),
      codeblockPadding: 8.0,
      codeblockDecoration: new BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: new BorderRadius.circular(2.0)
      )
    );
  }

  /// Creates a new [MarkdownStyleSheet] based on the current style, with the
  /// provided parameters overridden.
  MarkdownStyleSheet copyWith({
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
    Decoration blockquoteDecoration,
    double codeblockPadding,
    Decoration codeblockDecoration
  }) {
    return new MarkdownStyleSheet(
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

  /// The [TextStyle] to use for `a` elements.
  final TextStyle a;

  /// The [TextStyle] to use for `p` elements.
  final TextStyle p;

  /// The [TextStyle] to use for `code` elements.
  final TextStyle code;

  /// The [TextStyle] to use for `h1` elements.
  final TextStyle h1;

  /// The [TextStyle] to use for `h2` elements.
  final TextStyle h2;

  /// The [TextStyle] to use for `h3` elements.
  final TextStyle h3;

  /// The [TextStyle] to use for `h4` elements.
  final TextStyle h4;

  /// The [TextStyle] to use for `h5` elements.
  final TextStyle h5;

  /// The [TextStyle] to use for `h6` elements.
  final TextStyle h6;

  /// The [TextStyle] to use for `em` elements.
  final TextStyle em;

  /// The [TextStyle] to use for `strong` elements.
  final TextStyle strong;

  /// The [TextStyle] to use for `blockquote` elements.
  final TextStyle blockquote;

  /// The amount of vertical space to use between block-level elements.
  final double blockSpacing;

  /// The amount of horizontal space to indent list items.
  final double listIndent;

  /// The padding to use for `blockquote` elements.
  final double blockquotePadding;

  /// The decoration to use behind `blockquote` elements.
  final Decoration blockquoteDecoration;

  /// The padding to use for `pre` elements.
  final double codeblockPadding;

  /// The decoration to use behind for `pre` elements.
  final Decoration codeblockDecoration;

  /// A [Map] from element name to the cooresponding [TextStyle] object.
  Map<String, TextStyle> get styles => _styles;
  Map<String, TextStyle> _styles;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != MarkdownStyleSheet)
      return false;
    final MarkdownStyleSheet typedOther = other;
    return typedOther.a == a
        && typedOther.p == p
        && typedOther.code == code
        && typedOther.h1 == h1
        && typedOther.h2 == h2
        && typedOther.h3 == h3
        && typedOther.h4 == h4
        && typedOther.h5 == h5
        && typedOther.h6 == h6
        && typedOther.em == em
        && typedOther.strong == strong
        && typedOther.blockquote == blockquote
        && typedOther.blockSpacing == blockSpacing
        && typedOther.listIndent == listIndent
        && typedOther.blockquotePadding == blockquotePadding
        && typedOther.blockquoteDecoration == blockquoteDecoration
        && typedOther.codeblockPadding == codeblockPadding
        && typedOther.codeblockDecoration == codeblockDecoration;
  }

  @override
  int get hashCode {
    return hashValues(
      a,
      p,
      code,
      h1,
      h2,
      h3,
      h4,
      h5,
      h6,
      em,
      strong,
      blockquote,
      blockSpacing,
      listIndent,
      blockquotePadding,
      blockquoteDecoration,
      codeblockPadding,
      codeblockDecoration,
    );
  }
}
