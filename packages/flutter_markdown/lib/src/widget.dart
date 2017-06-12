// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:meta/meta.dart';

import 'builder.dart';
import 'style_sheet.dart';

/// Signature for callbacks used by [MarkdownWidget] when the user taps a link.
///
/// Used by [MarkdownWidget.onTapLink].
typedef void MarkdownTapLinkCallback(String href);

/// Creates a format [TextSpan] given a string.
///
/// Used by [MarkdownWidget] to highlight the contents of `pre` elements.
abstract class SyntaxHighlighter { // ignore: one_member_abstracts
  /// Returns the formated [TextSpan] for the given string.
  TextSpan format(String source);
}

/// A base class for widgets that parse and display Markdown.
///
/// Supports all standard Markdown from the original
/// [Markdown specification](https://daringfireball.net/projects/markdown/).
///
/// See also:
///
///  * [Markdown], which is a scrolling container of Markdown.
///  * [MarkdownBody], which is a non-scrolling container of Markdown.
///  * <https://daringfireball.net/projects/markdown/>
abstract class MarkdownWidget extends StatefulWidget {
  /// Creates a widget that parses and displays Markdown.
  ///
  /// The [data] argument must not be null.
  const MarkdownWidget({
    Key key,
    @required this.data,
    this.styleSheet,
    this.syntaxHighlighter,
    this.onTapLink,
  }) : assert(data != null),
       super(key: key);

  /// The Markdown to display.
  final String data;

  /// The styles to use when displaying the Markdown.
  ///
  /// If null, the styles are infered from the current [Theme].
  final MarkdownStyleSheet styleSheet;

  /// The syntax highlighter used to color text in `pre` elements.
  ///
  /// If null, the [MarkdownStyleSheet.code] style is used for `pre` elements.
  final SyntaxHighlighter syntaxHighlighter;

  /// Called when the user taps a link.
  final MarkdownTapLinkCallback onTapLink;

  /// Subclasses should override this function to display the given children,
  /// which are the parsed representation of [data].
  @protected
  Widget build(BuildContext context, List<Widget> children);

  @override
  _MarkdownWidgetState createState() => new _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> implements MarkdownBuilderDelegate {
  List<Widget> _children;
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];

  @override
  void didChangeDependencies() {
    _parseMarkdown();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(MarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data
        || widget.styleSheet != oldWidget.styleSheet)
      _parseMarkdown();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _parseMarkdown() {
    final MarkdownStyleSheet styleSheet = widget.styleSheet ?? new MarkdownStyleSheet.fromTheme(Theme.of(context));

    _disposeRecognizers();

    // TODO: This can be optimized by doing the split and removing \r at the same time
    final List<String> lines = widget.data.replaceAll('\r\n', '\n').split('\n');
    final md.Document document = new md.Document();
    final MarkdownBuilder builder = new MarkdownBuilder(delegate: this, styleSheet: styleSheet);
    _children = builder.build(document.parseLines(lines));
  }

  void _disposeRecognizers() {
    if (_recognizers.isEmpty)
      return;
    final List<GestureRecognizer> localRecognizers = new List<GestureRecognizer>.from(_recognizers);
    _recognizers.clear();
    for (GestureRecognizer recognizer in localRecognizers)
      recognizer.dispose();
  }

  @override
  GestureRecognizer createLink(String href) {
    final TapGestureRecognizer recognizer = new TapGestureRecognizer()
      ..onTap = () {
      if (widget.onTapLink != null)
        widget.onTapLink(href);
    };
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code) {
    if (widget.syntaxHighlighter != null)
      return widget.syntaxHighlighter.format(code);
    return new TextSpan(style: styleSheet.code, text: code);
  }

  @override
  Widget build(BuildContext context) => widget.build(context, _children);
}

/// A non-scrolling widget that parses and displays Markdown.
///
/// Supports all standard Markdown from the original
/// [Markdown specification](https://daringfireball.net/projects/markdown/).
///
/// See also:
///
///  * [Markdown], which is a scrolling container of Markdown.
///  * <https://daringfireball.net/projects/markdown/>
class MarkdownBody extends MarkdownWidget {
  /// Creates a non-scrolling widget that parses and displays Markdown.
  const MarkdownBody({
    Key key,
    String data,
    MarkdownStyleSheet styleSheet,
    SyntaxHighlighter syntaxHighlighter,
    MarkdownTapLinkCallback onTapLink,
  }) : super(
    key: key,
    data: data,
    styleSheet: styleSheet,
    syntaxHighlighter: syntaxHighlighter,
    onTapLink: onTapLink,
  );

  @override
  Widget build(BuildContext context, List<Widget> children) {
    if (children.length == 1)
      return children.single;
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// A scrolling widget that parses and displays Markdown.
///
/// Supports all standard Markdown from the original
/// [Markdown specification](https://daringfireball.net/projects/markdown/).
///
/// See also:
///
///  * [MarkdownBody], which is a non-scrolling container of Markdown.
///  * <https://daringfireball.net/projects/markdown/>
class Markdown extends MarkdownWidget {
  /// Creates a scrolling widget that parses and displays Markdown.
  const Markdown({
    Key key,
    String data,
    MarkdownStyleSheet styleSheet,
    SyntaxHighlighter syntaxHighlighter,
    MarkdownTapLinkCallback onTapLink,
    this.padding: const EdgeInsets.all(16.0),
  }) : super(
    key: key,
    data: data,
    styleSheet: styleSheet,
    syntaxHighlighter: syntaxHighlighter,
    onTapLink: onTapLink,
  );

  /// The amount of space by which to inset the children.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, List<Widget> children) {
    return new ListView(padding: padding, children: children);
  }
}
