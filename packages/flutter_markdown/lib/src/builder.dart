// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;

import 'style_sheet.dart';

final Set<String> _kBlockTags = new Set<String>.from(<String>[
  'p',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'li',
  'blockquote',
  'img',
  'pre',
  'ol',
  'ul',
]);

const List<String> _kListTags = const <String>['ul', 'ol'];

bool _isBlockTag(String tag) => _kBlockTags.contains(tag);
bool _isListTag(String tag) => _kListTags.contains(tag);

class _BlockElement {
  _BlockElement(this.tag);

  final String tag;
  final List<Widget> children = <Widget>[];

  int nextListIndex = 0;
}

class _InlineElement {
  final List<TextSpan> children = <TextSpan>[];
}

/// A delegate used by [MarkdownBuilder] to control the widgets it creates.
abstract class MarkdownBuilderDelegate {
  /// Returns a gesture recognizer to use for an `a` element with the given
  /// `href` attribute.
  GestureRecognizer createLink(String href);

  /// Returns formatted text to use to display the given contents of a `pre`
  /// element.
  ///
  /// The `styleSheet` is the value of [MarkdownBuilder.styleSheet].
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code);
}

/// Builds a [Widget] tree from parsed Markdown.
///
/// See also:
///
///  * [Markdown], which is a widget that parses and displays Markdown.
class MarkdownBuilder implements md.NodeVisitor {
  /// Creates an object that builds a [Widget] tree from parsed Markdown.
  MarkdownBuilder({ this.delegate, this.styleSheet });

  /// A delegate that controls how link and `pre` elements behave.
  final MarkdownBuilderDelegate delegate;

  /// Defines which [TextStyle] objects to use for each type of element.
  final MarkdownStyleSheet styleSheet;

  final List<String> _listIndents = <String>[];
  final List<_BlockElement> _blocks = <_BlockElement>[];
  final List<_InlineElement> _inlines = <_InlineElement>[];

  /// Returns widgets that display the given Markdown nodes.
  ///
  /// The returned widgets are typically used as children in a [ListView].
  List<Widget> build(List<md.Node> nodes) {
    _listIndents.clear();
    _blocks.clear();
    _inlines.clear();

    _blocks.add(new _BlockElement(null));
    _inlines.add(new _InlineElement());

    for (md.Node node in nodes) {
      assert(_blocks.length == 1);
      node.accept(this);
    }

    assert(_inlines.single.children.isEmpty);
    return _blocks.single.children;
  }

  @override
  void visitText(md.Text text) {
    if (_blocks.last.tag == null) // Don't allow text directly under the root.
      return;
    final TextSpan span = _blocks.last.tag == 'pre' ?
      delegate.formatText(styleSheet, text.text) : new TextSpan(text: text.text);
    _inlines.last.children.add(span);
  }

  @override
  bool visitElementBefore(md.Element element) {
    final String tag = element.tag;
    if (_isBlockTag(tag)) {
      _addAnonymousBlockIfNeeded(styleSheet.styles[tag]);
      if (_isListTag(tag))
        _listIndents.add(tag);
      _blocks.add(new _BlockElement(tag));
    } else {
      _inlines.add(new _InlineElement());
    }
    return true;
  }

  @override
  void visitElementAfter(md.Element element) {
    final String tag = element.tag;

    if (_isBlockTag(tag)) {
      _addAnonymousBlockIfNeeded(styleSheet.styles[tag]);

      final _BlockElement current = _blocks.removeLast();
      Widget child;
      if (tag == 'img') {
        child = _buildImage(element.attributes['src']);
      } else {
        if (current.children.isNotEmpty) {
          child = new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: current.children,
          );
        } else {
          child = const SizedBox();
        }

        if (_isListTag(tag)) {
          assert(_listIndents.isNotEmpty);
          _listIndents.removeLast();
        } else if (tag == 'li') {
          if (_listIndents.isNotEmpty) {
            child = new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new SizedBox(
                  width: styleSheet.listIndent,
                  child: _buildBullet(_listIndents.last),
                ),
                new Expanded(child: child)
              ],
            );
          }
        } else if (tag == 'blockquote') {
          child = new DecoratedBox(
            decoration: styleSheet.blockquoteDecoration,
            child: new Padding(
              padding: new EdgeInsets.all(styleSheet.blockquotePadding),
              child: child,
            ),
          );
        } else if (tag == 'pre') {
          child = new DecoratedBox(
            decoration: styleSheet.codeblockDecoration,
            child: new Padding(
              padding: new EdgeInsets.all(styleSheet.codeblockPadding),
              child: child,
            ),
          );
        }
      }

      _addBlockChild(child);
    } else {
      final _InlineElement current = _inlines.removeLast();
      final _InlineElement parent = _inlines.last;

      if (current.children.isNotEmpty) {
        GestureRecognizer recognizer;

        if (tag == 'a')
          recognizer = delegate.createLink(element.attributes['href']);

        parent.children.add(new TextSpan(
          style: styleSheet.styles[tag],
          recognizer: recognizer,
          children: current.children,
        ));
      }
    }
  }

  Widget _buildImage(String src) {
    final List<String> parts = src.split('#');
    if (parts.isEmpty)
      return const SizedBox();

    final String path = parts.first;
    double width;
    double height;
    if (parts.length == 2) {
      final List<String> dimensions = parts.last.split('x');
      if (dimensions.length == 2) {
        width = double.parse(dimensions[0]);
        height = double.parse(dimensions[1]);
      }
    }

    return new Image.network(path, width: width, height: height);
  }

  Widget _buildBullet(String listTag) {
    if (listTag == 'ul')
      return const Text('•', textAlign: TextAlign.center);

    final int index = _blocks.last.nextListIndex;
    return new Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: new Text('${index + 1}.', textAlign: TextAlign.right),
    );
  }

  void _addBlockChild(Widget child) {
    final _BlockElement parent = _blocks.last;
    if (parent.children.isNotEmpty)
      parent.children.add(new SizedBox(height: styleSheet.blockSpacing));
    parent.children.add(child);
    parent.nextListIndex += 1;
  }

  void _addAnonymousBlockIfNeeded(TextStyle style) {
    final _InlineElement inline = _inlines.single;
    if (inline.children.isNotEmpty) {
      final TextSpan span = new TextSpan(style: style, children: inline.children);
      _addBlockChild(new RichText(text: span));
      _inlines.clear();
      _inlines.add(new _InlineElement());
    }
  }
}
