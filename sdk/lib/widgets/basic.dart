// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:vector_math/vector_math.dart';

import '../rendering/block.dart';
import '../rendering/box.dart';
import '../rendering/flex.dart';
import '../rendering/object.dart';
import '../rendering/paragraph.dart';
import '../rendering/stack.dart';
import 'ui_node.dart';

export '../rendering/box.dart' show BoxConstraints, BoxDecoration, Border, BorderSide, EdgeDims;
export '../rendering/flex.dart' show FlexDirection, FlexJustifyContent, FlexAlignItems;
export '../rendering/object.dart' show Point, Size, Rect, Color, Paint, Path;
export 'ui_node.dart' show UINode, Component, App, EventListenerNode, ParentDataNode;


// PAINTING NODES

class Opacity extends OneChildRenderObjectWrapper {
  Opacity({ String key, this.opacity, UINode child })
    : super(key: key, child: child);

  RenderOpacity get root => super.root;
  final double opacity;

  RenderOpacity createNode() => new RenderOpacity(opacity: opacity);

  void syncRenderObject(Opacity old) {
    super.syncRenderObject(old);
    root.opacity = opacity;
  }
}

class DecoratedBox extends OneChildRenderObjectWrapper {

  DecoratedBox({ String key, this.decoration, UINode child })
    : super(key: key, child: child);

  RenderDecoratedBox get root => super.root;
  final BoxDecoration decoration;

  RenderDecoratedBox createNode() => new RenderDecoratedBox(decoration: decoration);

  void syncRenderObject(DecoratedBox old) {
    super.syncRenderObject(old);
    root.decoration = decoration;
  }

}

class CustomPaint extends OneChildRenderObjectWrapper {

  CustomPaint({ String key, this.callback, this.token, UINode child })
    : super(key: key, child: child);

  RenderCustomPaint get root => super.root;
  final CustomPaintCallback callback;
  final dynamic token;  // set this to be repainted automatically when the token changes

  RenderCustomPaint createNode() => new RenderCustomPaint(callback: callback);

  void syncRenderObject(CustomPaint old) {
    super.syncRenderObject(old);
    if (old != null && old.token != token)
      root.markNeedsPaint();
    root.callback = callback;
  }

  void remove() {
    root.callback = null;
    super.remove();
  }

}

class ClipRect extends OneChildRenderObjectWrapper {
  ClipRect({ String key, UINode child })
    : super(key: key, child: child);

  RenderClipRect get root => super.root;
  RenderClipRect createNode() => new RenderClipRect();
}

class ClipOval extends OneChildRenderObjectWrapper {
  ClipOval({ String key, UINode child })
    : super(key: key, child: child);

  RenderClipOval get root => super.root;
  RenderClipOval createNode() => new RenderClipOval();
}


// POSITIONING AND SIZING NODES

class Transform extends OneChildRenderObjectWrapper {

  Transform({ String key, this.transform, UINode child })
    : super(key: key, child: child);

  RenderTransform get root => super.root;
  final Matrix4 transform;

  RenderTransform createNode() => new RenderTransform(transform: transform);

  void syncRenderObject(Transform old) {
    super.syncRenderObject(old);
    root.transform = transform;
  }

}

class Padding extends OneChildRenderObjectWrapper {

  Padding({ String key, this.padding, UINode child })
    : super(key: key, child: child);

  RenderPadding get root => super.root;
  final EdgeDims padding;

  RenderPadding createNode() => new RenderPadding(padding: padding);

  void syncRenderObject(Padding old) {
    super.syncRenderObject(old);
    root.padding = padding;
  }

}

class Center extends OneChildRenderObjectWrapper {
  Center({ String key, UINode child })
    : super(key: key, child: child);

  RenderPositionedBox get root => super.root;
  RenderPositionedBox createNode() => new RenderPositionedBox();
}

class SizedBox extends OneChildRenderObjectWrapper {

  SizedBox({
    String key,
    this.width,
    this.height,
    UINode child
  }) : super(key: key, child: child);

  RenderConstrainedBox get root => super.root;

  final double width;
  final double height;

  RenderConstrainedBox createNode() => new RenderConstrainedBox(additionalConstraints: _additionalConstraints());

  BoxConstraints _additionalConstraints() {
    var result = const BoxConstraints();
    if (width != null)
      result = result.applyWidth(width);
    if (height != null)
      result = result.applyHeight(height);
    return result;
  }

  void syncRenderObject(SizedBox old) {
    super.syncRenderObject(old);
    root.additionalConstraints = _additionalConstraints();
  }

}

class ConstrainedBox extends OneChildRenderObjectWrapper {

  ConstrainedBox({ String key, this.constraints, UINode child })
    : super(key: key, child: child);

  RenderConstrainedBox get root => super.root;

  final BoxConstraints constraints;

  RenderConstrainedBox createNode() => new RenderConstrainedBox(additionalConstraints: constraints);

  void syncRenderObject(ConstrainedBox old) {
    super.syncRenderObject(old);
    root.additionalConstraints = constraints;
  }

}

class ShrinkWrapWidth extends OneChildRenderObjectWrapper {
  ShrinkWrapWidth({ String key, UINode child })
    : super(key: key, child: child);

  RenderShrinkWrapWidth get root => super.root;
  RenderShrinkWrapWidth createNode() => new RenderShrinkWrapWidth();
}

class SizeObserver extends OneChildRenderObjectWrapper {

  SizeObserver({ String key, this.callback, UINode child })
    : super(key: key, child: child);

  RenderSizeObserver get root => super.root;
  final SizeChangedCallback callback;

  RenderSizeObserver createNode() => new RenderSizeObserver(callback: callback);

  void syncRenderObject(SizeObserver old) {
    super.syncRenderObject(old);
    root.callback = callback;
  }

  void remove() {
    root.callback = null;
    super.remove();
  }

}


// CONVENIENCE CLASS TO COMBINE COMMON PAINTING, POSITIONING, AND SIZING NODES

class Container extends Component {

  Container({
    String key,
    this.child,
    this.constraints,
    this.decoration,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.transform
  }) : super(key: key);

  final UINode child;
  final BoxConstraints constraints;
  final BoxDecoration decoration;
  final EdgeDims margin;
  final EdgeDims padding;
  final Matrix4 transform;
  final double width;
  final double height;

  UINode build() {
    UINode current = child;

    if (child == null && width == null && height == null)
      current = new SizedBox(
        width: double.INFINITY,
        height: double.INFINITY
      );

    if (padding != null)
      current = new Padding(padding: padding, child: current);

    if (decoration != null)
      current = new DecoratedBox(decoration: decoration, child: current);

    if (width != null || height != null)
      current = new SizedBox(
        width: width,
        height: height,
        child: current
      );

    if (constraints != null)
      current = new ConstrainedBox(constraints: constraints, child: current);

    if (margin != null)
      current = new Padding(padding: margin, child: current);

    if (transform != null)
      current = new Transform(transform: transform, child: current);

    return current;
  }

}


// LAYOUT NODES

class Block extends MultiChildRenderObjectWrapper {
  Block(List<UINode> children, { String key })
    : super(key: key, children: children);

  RenderBlock get root => super.root;
  RenderBlock createNode() => new RenderBlock();
}

class Stack extends MultiChildRenderObjectWrapper {
  Stack(List<UINode> children, { String key })
    : super(key: key, children: children);

  RenderStack get root => super.root;
  RenderStack createNode() => new RenderStack();
}

class Positioned extends ParentDataNode {
  Positioned({
    String key,
    UINode child,
    double top,
    double right,
    double bottom,
    double left
  }) : super(child,
             new StackParentData()..top = top
                                  ..right = right
                                  ..bottom = bottom
                                  ..left = left,
             key: key);
}

class Flex extends MultiChildRenderObjectWrapper {

  Flex(List<UINode> children, {
    String key,
    this.direction: FlexDirection.horizontal,
    this.justifyContent: FlexJustifyContent.flexStart,
    this.alignItems: FlexAlignItems.center
  }) : super(key: key, children: children);

  RenderFlex get root => super.root;
  RenderFlex createNode() => new RenderFlex(direction: this.direction);

  final FlexDirection direction;
  final FlexJustifyContent justifyContent;
  final FlexAlignItems alignItems;

  void syncRenderObject(UINode old) {
    super.syncRenderObject(old);
    root.direction = direction;
    root.justifyContent = justifyContent;
    root.alignItems = alignItems;
  }

}

class Flexible extends ParentDataNode {
  Flexible({ String key, UINode child, int flex: 1 })
    : super(child, new FlexBoxParentData()..flex = flex, key: key);
}

class Paragraph extends RenderObjectWrapper {

  Paragraph({ String key, this.text, this.style }) : super(key: key);

  RenderParagraph get root => super.root;
  RenderParagraph createNode() => new RenderParagraph(text: text, style: style);

  final String text;
  final TextStyle style;

  void syncRenderObject(UINode old) {
    super.syncRenderObject(old);
    root.text = text;
    root.style = style;
  }

  void insert(RenderObjectWrapper child, dynamic slot) {
    assert(false);
    // Paragraph does not support having children currently
  }

}

class Text extends Component {
  Text(this.data, { TextStyle this.style }) : super(key: '*text*');
  final String data;
  final TextStyle style;
  bool get interchangeable => true;
  UINode build() => new Paragraph(text: data, style: style);
}

class Image extends RenderObjectWrapper {

  Image({
    String key,
    this.src,
    this.size
  }) : super(key: key);

  RenderImage get root => super.root;
  RenderImage createNode() => new RenderImage(this.src, this.size);

  final String src;
  final Size size;

  void syncRenderObject(UINode old) {
    super.syncRenderObject(old);
    root.src = src;
    root.requestedSize = size;
  }

  void insert(RenderObjectWrapper child, dynamic slot) {
    assert(false);
    // Image does not support having children currently
  }

}

class UINodeToRenderBoxAdapter extends RenderObjectWrapper {

  UINodeToRenderBoxAdapter(RenderBox renderBox)
    : this.renderBox = renderBox,
      super(key: renderBox.hashCode.toString());

  RenderBox get root => super.root;
  RenderBox createNode() => this.renderBox;

  final RenderBox renderBox;

  void syncRenderObject(UINode old) {
    super.syncRenderObject(old);
    if (old != null) {
      assert(old is UINodeToRenderBoxAdapter);
      assert(root == old.renderBox);
    }
  }

  void insert(RenderObjectWrapper child, dynamic slot) {
    assert(false);
    // UINodeToRenderBoxAdapter cannot have UINode children; by
    // definition, it is the transition out of the UINode world.
  }

}
