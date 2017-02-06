// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'markdown_raw.dart';
import 'markdown_style.dart';

/// A [Widget] that renders markdown formatted text. It supports all standard
/// markdowns from the original markdown specification found here:
/// https://daringfireball.net/projects/markdown/ The rendered markdown is
/// placed in a padded scrolling view port. If you do not want the scrolling
/// behaviour, use the [MarkdownBody] class instead.
class Markdown extends MarkdownRaw {

  /// Creates a new Markdown [Widget] that renders the markdown formatted string
  /// passed in as [data]. By default the markdown will be rendered using the
  /// styles from the current theme, but you can optionally pass in a custom
  /// [markdownStyle] that specifies colors and fonts to use. Code blocks are
  /// by default not using syntax highlighting, but it's possible to pass in
  /// a custom [syntaxHighlighter].
  ///
  ///     new Markdown(data: "Hello _world_!");
  Markdown({
    String data,
    SyntaxHighlighter syntaxHighlighter,
    MarkdownStyle markdownStyle,
    MarkdownLinkCallback onTapLink
  }) : super(
    data: data,
    syntaxHighlighter: syntaxHighlighter,
    markdownStyle: markdownStyle,
    onTapLink: onTapLink
  );

  @override
  MarkdownBody createMarkdownBody({
    String data,
    MarkdownStyle markdownStyle,
    SyntaxHighlighter syntaxHighlighter,
    MarkdownLinkCallback onTapLink
  }) {
    return new MarkdownBody(
      data: data,
      markdownStyle: markdownStyle,
      syntaxHighlighter: syntaxHighlighter,
      onTapLink: onTapLink
    );
  }
}

/// A [Widget] that renders markdown formatted text. It supports all standard
/// markdowns from the original markdown specification found here:
/// https://daringfireball.net/projects/markdown/ This class doesn't implement
/// any scrolling behavior, if you want scrolling either wrap the widget in
/// a [ScrollableViewport] or use the [Markdown] widget.
class MarkdownBody extends MarkdownBodyRaw {

  /// Creates a new Markdown [Widget] that renders the markdown formatted string
  /// passed in as [data]. By default the markdown will be rendered using the
  /// styles from the current theme, but you can optionally pass in a custom
  /// [markdownStyle] that specifies colors and fonts to use. Code blocks are
  /// by default not using syntax highlighting, but it's possible to pass in
  /// a custom [syntaxHighlighter].
  ///
  /// Typically, you may want to wrap the [MarkdownBody] widget in a
  /// [SingleChildScrollView], or use the [Markdown] class.
  ///
  /// ```dart
  /// new SingleChildScrollView(
  ///   padding: new EdgeInsets.all(16.0),
  ///   child: new Markdown(data: markdownSource),
  /// ),
  /// ```
  MarkdownBody({
    String data,
    SyntaxHighlighter syntaxHighlighter,
    MarkdownStyle markdownStyle,
    MarkdownLinkCallback onTapLink
  }) : super(
    data: data,
    syntaxHighlighter: syntaxHighlighter,
    markdownStyle: markdownStyle,
    onTapLink: onTapLink
  );

  @override
  MarkdownStyle createDefaultStyle(BuildContext context) {
    return new MarkdownStyle.defaultFromTheme(Theme.of(context));
  }
}
