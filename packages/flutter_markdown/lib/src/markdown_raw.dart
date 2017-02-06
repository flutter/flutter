// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:markdown/markdown.dart' as md;
import 'package:meta/meta.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

import 'markdown_style_raw.dart';

typedef void MarkdownLinkCallback(String href);


/// A [Widget] that renders markdown formatted text. It supports all standard
/// markdowns from the original markdown specification found here:
/// https://daringfireball.net/projects/markdown/ The rendered markdown is
/// placed in a padded scrolling view port. If you do not want the scrolling
/// behaviour, use the [MarkdownBodyRaw] class instead.
class MarkdownRaw extends StatelessWidget {

  /// Creates a new Markdown [Widget] that renders the markdown formatted string
  /// passed in as [data]. By default the markdown will be rendered using the
  /// styles from the current theme, but you can optionally pass in a custom
  /// [markdownStyle] that specifies colors and fonts to use. Code blocks are
  /// by default not using syntax highlighting, but it's possible to pass in
  /// a custom [syntaxHighlighter].
  ///
  ///     new MarkdownRaw(data: "Hello _world_!", markdownStyle: myStyle);
  MarkdownRaw({
    this.data,
    this.markdownStyle,
    this.syntaxHighlighter,
    this.padding: const EdgeInsets.all(16.0),
    this.onTapLink
  });

  /// Markdown styled text
  final String data;

  /// Style used for rendering the markdown
  final MarkdownStyleRaw markdownStyle;

  /// The syntax highlighter used to color text in code blocks
  final SyntaxHighlighter syntaxHighlighter;

  /// Padding used
  final EdgeInsets padding;

  /// Callback when a link is tapped
  final MarkdownLinkCallback onTapLink;

  @override
  Widget build(BuildContext context) {
    // TODO(abarth): We should use a ListView here and lazily build the widgets
    // from the markdown.
    return new SingleChildScrollView(
      padding: padding,
      child: createMarkdownBody(
        data: data,
        markdownStyle: markdownStyle,
        syntaxHighlighter: syntaxHighlighter,
        onTapLink: onTapLink,
      ),
    );
  }

  MarkdownBodyRaw createMarkdownBody({
    String data,
    @checked MarkdownStyleRaw markdownStyle,
    SyntaxHighlighter syntaxHighlighter,
    MarkdownLinkCallback onTapLink
  }) {
    return new MarkdownBodyRaw(
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
/// a [ScrollableViewport] or use the [MarkdownRaw] widget.
class MarkdownBodyRaw extends StatefulWidget {

  /// Creates a new Markdown [Widget] that renders the markdown formatted string
  /// passed in as [data]. You need to pass in a [markdownStyle] that defines
  /// how the code is rendered. Code blocks are by default not using syntax
  /// highlighting, but it's possible to pass in a custom [syntaxHighlighter].
  ///
  /// Typically, you may want to wrap the [MarkdownBodyRaw] widget in a
  /// a [ScrollableViewport], or use the [Markdown class].
  ///
  /// ```dart
  /// new SingleChildScrollView(
  ///   padding: new EdgeInsets.all(16.0),
  ///   child: new MarkdownBodyRaw(
  ///     data: markdownSource,
  ///     markdownStyle: myStyle,
  ///   ),
  /// ),
  /// ```
  MarkdownBodyRaw({
    this.data,
    this.markdownStyle,
    this.syntaxHighlighter,
    this.onTapLink
  });

  /// Markdown styled text
  final String data;

  /// Style used for rendering the markdown
  final MarkdownStyleRaw markdownStyle;

  /// The syntax highlighter used to color text in code blocks
  final SyntaxHighlighter syntaxHighlighter;

  /// Callback when a link is tapped
  final MarkdownLinkCallback onTapLink;

  @override
  _MarkdownBodyRawState createState() => new _MarkdownBodyRawState();

  MarkdownStyleRaw createDefaultStyle(BuildContext context) => null;
}

class _MarkdownBodyRawState extends State<MarkdownBodyRaw> {

  @override
  void dependenciesChanged() {
    _buildMarkdownCache();
    super.dependenciesChanged();
  }

  @override
  void dispose() {
    _linkHandler.dispose();
    super.dispose();
  }

  @override
  void didUpdateConfig(MarkdownBodyRaw oldConfig) {
    super.didUpdateConfig(oldConfig);

    if (oldConfig.data != config.data ||
        oldConfig.markdownStyle != config.markdownStyle ||
        oldConfig.syntaxHighlighter != config.syntaxHighlighter ||
        oldConfig.onTapLink != config.onTapLink)
      _buildMarkdownCache();
  }

  void _buildMarkdownCache() {
    MarkdownStyleRaw markdownStyle = config.markdownStyle ?? config.createDefaultStyle(context);
    SyntaxHighlighter syntaxHighlighter = config.syntaxHighlighter ?? new _DefaultSyntaxHighlighter(markdownStyle.code);

    _linkHandler?.dispose();
    _linkHandler = new _LinkHandler(config.onTapLink);

    // TODO: This can be optimized by doing the split and removing \r at the same time
    List<String> lines = config.data.replaceAll('\r\n', '\n').split('\n');
    md.Document document = new md.Document();

    _Renderer renderer = new _Renderer();
    _cachedBlocks = renderer.render(document.parseLines(lines), markdownStyle, syntaxHighlighter, _linkHandler);
  }

  List<_Block> _cachedBlocks;
  _LinkHandler _linkHandler;

  @override
  Widget build(BuildContext context) {
    List<Widget> blocks = <Widget>[];
    for (_Block block in _cachedBlocks) {
      blocks.add(block.build(context));
    }

    return new Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('cached blocks identity: ${_cachedBlocks.hashCode}');
  }
}

class _Renderer implements md.NodeVisitor {
  List<_Block> render(List<md.Node> nodes, MarkdownStyleRaw markdownStyle, SyntaxHighlighter syntaxHighlighter, _LinkHandler linkHandler) {
    assert(markdownStyle != null);

    _blocks = <_Block>[];
    _listIndents = <String>[];
    _markdownStyle = markdownStyle;
    _syntaxHighlighter = syntaxHighlighter;
    _linkHandler = linkHandler;

    for (final md.Node node in nodes) {
      node.accept(this);
    }

    return _blocks;
  }

  List<_Block> _blocks;
  List<String> _listIndents;
  MarkdownStyleRaw _markdownStyle;
  SyntaxHighlighter _syntaxHighlighter;
  _LinkHandler _linkHandler;

  @override
  void visitText(md.Text text) {
    _MarkdownNodeList topList = _currentBlock.stack.last;
    List<_MarkdownNode> top = topList.list;

    if (_currentBlock.tag == 'pre')
      top.add(new _MarkdownNodeTextSpan(_syntaxHighlighter.format(text.text)));
    else
      top.add(new _MarkdownNodeString(text.text));
  }

  @override
  bool visitElementBefore(md.Element element) {
    if (_isListTag(element.tag))
      _listIndents.add(element.tag);

    if (_isBlockTag(element.tag)) {
      List<_Block> blockList;
      if (_currentBlock == null)
        blockList = _blocks;
      else
        blockList = _currentBlock.subBlocks;

      _Block newBlock = new _Block(element.tag, element.attributes, _markdownStyle, new List<String>.from(_listIndents), blockList.length);
      blockList.add(newBlock);
    } else {
      _LinkInfo linkInfo;
      if (element.tag == 'a') {
        linkInfo = _linkHandler.createLinkInfo(element.attributes['href']);
      }

      TextStyle style = _markdownStyle.styles[element.tag] ?? new TextStyle();
      List<_MarkdownNode> styleElement = <_MarkdownNode>[new _MarkdownNodeTextStyle(style, linkInfo)];
      _currentBlock.stack.add(new _MarkdownNodeList(styleElement));
    }
    return true;
  }

  @override
  void visitElementAfter(md.Element element) {
    if (_isListTag(element.tag))
      _listIndents.removeLast();

    if (_isBlockTag(element.tag)) {
      if (_currentBlock.stack.length > 0) {
        _MarkdownNodeList stackList = _currentBlock.stack.first;
        _currentBlock.stack = stackList.list;
        _currentBlock.open = false;
      } else {
        _currentBlock.stack = <_MarkdownNode>[new _MarkdownNodeString('')];
      }
    } else {
      if (_currentBlock.stack.length > 1) {
        _MarkdownNodeList poppedList = _currentBlock.stack.last;
        List<_MarkdownNode> popped = poppedList.list;
        _currentBlock.stack.removeLast();

        _MarkdownNodeList topList = _currentBlock.stack.last;
        List<_MarkdownNode> top = topList.list;
        top.add(new _MarkdownNodeList(popped));
      }
    }
  }

  static const List<String> _kBlockTags = const <String>['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'blockquote', 'img', 'pre', 'ol', 'ul'];
  static const List<String> _kListTags = const <String>['ul', 'ol'];

  bool _isBlockTag(String tag) {
    return _kBlockTags.contains(tag);
  }

  bool _isListTag(String tag) {
    return _kListTags.contains(tag);
  }

  _Block get _currentBlock => _currentBlockInList(_blocks);

  _Block _currentBlockInList(List<_Block> blocks) {
    if (blocks.isEmpty)
      return null;

    if (!blocks.last.open)
      return null;

    _Block childBlock = _currentBlockInList(blocks.last.subBlocks);
    if (childBlock != null)
      return childBlock;

    return blocks.last;
  }
}

abstract class _MarkdownNode {
}

class _MarkdownNodeList extends _MarkdownNode {
  _MarkdownNodeList(this.list);
  List<_MarkdownNode> list;
}

class _MarkdownNodeTextStyle extends _MarkdownNode {
  _MarkdownNodeTextStyle(this.style, [this.linkInfo = null]);
  TextStyle style;
  _LinkInfo linkInfo;
}

class _MarkdownNodeString extends _MarkdownNode {
  _MarkdownNodeString(this.string);
  String string;
}

class _MarkdownNodeTextSpan extends _MarkdownNode {
  _MarkdownNodeTextSpan(this.textSpan);
  TextSpan textSpan;
}

class _Block {
  _Block(this.tag, this.attributes, this.markdownStyle, this.listIndents, this.blockPosition) {
    TextStyle style = markdownStyle.styles[tag];
    if (style == null)
      style = new TextStyle(color: const Color(0xffff0000));

    stack = <_MarkdownNode>[new _MarkdownNodeList(<_MarkdownNode>[new _MarkdownNodeTextStyle(style)])];
    subBlocks = <_Block>[];
  }

  final String tag;
  final Map<String, String> attributes;
  final MarkdownStyleRaw markdownStyle;
  final List<String> listIndents;
  final int blockPosition;

  List<_MarkdownNode> stack;
  List<_Block> subBlocks;

  bool get open => _open;
  set open(bool open) {
    _open = open;
    if (!open && subBlocks.length > 0)
      subBlocks.last.isLast = true;
  }

  bool _open = true;
  bool isLast = false;

  Widget build(BuildContext context) {

    if (tag == 'img') {
      return _buildImage(context, attributes['src']);
    }

    double spacing = markdownStyle.blockSpacing;
    if (isLast) spacing = 0.0;

    Widget contents;

    if (subBlocks.length > 0) {
      List<Widget> subWidgets = <Widget>[];
      for (_Block subBlock in subBlocks) {
        subWidgets.add(subBlock.build(context));
      }

      contents = new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: subWidgets
      );
    } else {
      TextSpan span = _stackToTextSpan(new _MarkdownNodeList(stack));
      contents = new RichText(text: span);

      if (listIndents.length > 0) {
        Widget bullet;
        if (listIndents.last == 'ul') {
          bullet = new Text(
            '•',
            textAlign: TextAlign.center
          );
        }
        else {
          bullet = new Padding(
            padding: new EdgeInsets.only(right: 5.0),
            child: new Text(
              "${blockPosition + 1}.",
              textAlign: TextAlign.right
            )
          );
        }

        contents = new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new SizedBox(
              width: listIndents.length * markdownStyle.listIndent,
              child: bullet
            ),
            new Expanded(child: contents)
          ]
        );
      }
    }

    BoxDecoration decoration;
    EdgeInsets padding;

    if (tag == 'blockquote') {
      decoration = markdownStyle.blockquoteDecoration;
      padding = new EdgeInsets.all(markdownStyle.blockquotePadding);
    } else if (tag == 'pre') {
      decoration = markdownStyle.codeblockDecoration;
      padding = new EdgeInsets.all(markdownStyle.codeblockPadding);
    }

    return new Container(
      padding: padding,
      margin: new EdgeInsets.only(bottom: spacing),
      child: contents,
      decoration: decoration
    );
  }

  TextSpan _stackToTextSpan(_MarkdownNode stack) {
    if (stack is _MarkdownNodeTextSpan)
      return stack.textSpan;

    if (stack is _MarkdownNodeList) {
      List<_MarkdownNode> list = stack.list;
      _MarkdownNodeTextStyle styleNode = list[0];
      _LinkInfo linkInfo = styleNode.linkInfo;
      TextStyle style = styleNode.style;

      List<TextSpan> children = <TextSpan>[];
      for (int i = 1; i < list.length; i++) {
        children.add(_stackToTextSpan(list[i]));
      }

      String text;
      if (children.length == 1 && _isPlainText(children[0])) {
        text = children[0].text;
        children = null;
      }

      TapGestureRecognizer recognizer = linkInfo?.recognizer;

      return new TextSpan(style: style, children: children, recognizer: recognizer, text: text);
    }

    if (stack is _MarkdownNodeString) {
      return new TextSpan(text: stack.string);
    }

    return null;
  }

  bool _isPlainText(TextSpan span) {
    return (span.text != null && span.style == null && span.recognizer == null && span.children == null);
  }

  Widget _buildImage(BuildContext context, String src) {
    List<String> parts = src.split('#');
    if (parts.length == 0) return new Container();

    String path = parts.first;
    double width;
    double height;
    if (parts.length == 2) {
      List<String> dimensions = parts.last.split('x');
      if (dimensions.length == 2) {
        width = double.parse(dimensions[0]);
        height = double.parse(dimensions[1]);
      }
    }

    return new Image.network(path, width: width, height: height);
  }
}

class _LinkInfo {
  _LinkInfo(this.href, this.recognizer);

  final String href;
  final TapGestureRecognizer recognizer;
}

class _LinkHandler {
  _LinkHandler(this.onTapLink);

  List<_LinkInfo> links = <_LinkInfo>[];
  MarkdownLinkCallback onTapLink;

  _LinkInfo createLinkInfo(String href) {
    TapGestureRecognizer recognizer = new TapGestureRecognizer();
    recognizer.onTap = () {
      if (onTapLink != null)
        onTapLink(href);
    };

    _LinkInfo linkInfo = new _LinkInfo(href, recognizer);
    links.add(linkInfo);

    return linkInfo;
  }

  void dispose() {
    for (_LinkInfo linkInfo in links) {
      linkInfo.recognizer.dispose();
    }
  }
}

abstract class SyntaxHighlighter { // ignore: one_member_abstracts
  TextSpan format(String source);
}

class _DefaultSyntaxHighlighter extends SyntaxHighlighter{
  _DefaultSyntaxHighlighter(this.style);

  final TextStyle style;

  @override
  TextSpan format(String source) {
    return new TextSpan(style: style, children: <TextSpan>[new TextSpan(text: source)]);
  }
}
