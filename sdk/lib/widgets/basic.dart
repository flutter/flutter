// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import 'package:vector_math/vector_math.dart';

import 'package:sky/mojo/asset_bundle.dart';
import 'package:sky/mojo/net/image_cache.dart' as image_cache;
import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/block.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/paragraph.dart';
import 'package:sky/rendering/stack.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/widget.dart';

export 'package:sky/rendering/box.dart' show BackgroundImage, BoxConstraints, BoxDecoration, Border, BorderSide, EdgeDims;
export 'package:sky/rendering/flex.dart' show FlexDirection, FlexJustifyContent, FlexAlignItems;
export 'package:sky/rendering/object.dart' show Point, Offset, Size, Rect, Color, Paint, Path;
export 'package:sky/widgets/widget.dart' show Widget, Component, StatefulComponent, App, runApp, Listener, ParentDataNode;

// PAINTING NODES

class Opacity extends OneChildRenderObjectWrapper {
  Opacity({ String key, this.opacity, Widget child })
    : super(key: key, child: child);

  RenderOpacity get root => super.root;
  final double opacity;

  RenderOpacity createNode() => new RenderOpacity(opacity: opacity);

  void syncRenderObject(Opacity old) {
    super.syncRenderObject(old);
    root.opacity = opacity;
  }
}

class ColorFilter extends OneChildRenderObjectWrapper {
  ColorFilter({ String key, this.color, this.transferMode, Widget child })
    : super(key: key, child: child);

  RenderColorFilter get root => super.root;
  final Color color;
  final sky.TransferMode transferMode;

  RenderColorFilter createNode() => new RenderColorFilter(color: color, transferMode: transferMode);

  void syncRenderObject(ColorFilter old) {
    super.syncRenderObject(old);
    root.color = color;
    root.transferMode = transferMode;
  }
}

class DecoratedBox extends OneChildRenderObjectWrapper {

  DecoratedBox({ String key, this.decoration, Widget child })
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

  CustomPaint({ String key, this.callback, this.token, Widget child })
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
  ClipRect({ String key, Widget child })
    : super(key: key, child: child);

  RenderClipRect get root => super.root;
  RenderClipRect createNode() => new RenderClipRect();

  // Nothing to sync, so we don't implement syncRenderObject()
}

class ClipRRect extends OneChildRenderObjectWrapper {
  final double xRadius;
  final double yRadius;
  ClipRRect({ String key, Widget child, this.xRadius, this.yRadius })
    : super(key: key, child: child);

  RenderClipRRect get root => super.root;
  RenderClipRRect createNode() => new RenderClipRRect(xRadius: xRadius, yRadius: yRadius);

  void syncRenderObject(ClipRRect old) {
    super.syncRenderObject(old);
    root.xRadius = xRadius;
    root.yRadius = yRadius;
  }
}

class ClipOval extends OneChildRenderObjectWrapper {
  ClipOval({ String key, Widget child })
    : super(key: key, child: child);

  RenderClipOval get root => super.root;
  RenderClipOval createNode() => new RenderClipOval();

  // Nothing to sync, so we don't implement syncRenderObject()
}

// POSITIONING AND SIZING NODES

class Transform extends OneChildRenderObjectWrapper {

  Transform({ String key, this.transform, Widget child })
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

  Padding({ String key, this.padding, Widget child })
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
  Center({ String key, Widget child })
    : super(key: key, child: child);

  RenderPositionedBox get root => super.root;
  RenderPositionedBox createNode() => new RenderPositionedBox();

  // Nothing to sync, so we don't implement syncRenderObject()
}

class SizedBox extends OneChildRenderObjectWrapper {

  SizedBox({
    String key,
    this.width,
    this.height,
    Widget child
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

  ConstrainedBox({ String key, this.constraints, Widget child })
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

  ShrinkWrapWidth({
    String key,
    this.stepWidth,
    this.stepHeight,
    Widget child
  }): super(key: key, child: child);

  RenderShrinkWrapWidth get root => super.root;

  final double stepWidth;
  final double stepHeight;

  RenderShrinkWrapWidth createNode() => new RenderShrinkWrapWidth();

  void syncRenderObject(ShrinkWrapWidth old) {
    super.syncRenderObject(old);
    root.stepWidth = stepWidth;
    root.stepHeight = stepHeight;
  }

}

class Baseline extends OneChildRenderObjectWrapper {

  Baseline({
    String key,
    this.baseline, // in pixels
    this.baselineType: TextBaseline.alphabetic,
    Widget child
  }): super(key: key, child: child);

  RenderBaseline get root => super.root;

  final double baseline;
  final TextBaseline baselineType;

  RenderBaseline createNode() => new RenderBaseline(baseline: baseline, baselineType: baselineType);

  void syncRenderObject(Baseline old) {
    super.syncRenderObject(old);
    root.baseline = baseline;
    root.baselineType = baselineType;
  }

}

class Viewport extends OneChildRenderObjectWrapper {

  Viewport({
    String key,
    this.offset: 0.0,
    Widget child
  }) : super(key: key, child: child);

  final double offset;

  RenderViewport get root => super.root;
  RenderViewport createNode() => new RenderViewport(scrollOffset: new Offset(0.0, offset));

  void syncRenderObject(Viewport old) {
    super.syncRenderObject(old);
    root.scrollOffset = new Offset(0.0, offset);
  }

}

class SizeObserver extends OneChildRenderObjectWrapper {

  SizeObserver({ String key, this.callback, Widget child })
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

  final Widget child;
  final BoxConstraints constraints;
  final BoxDecoration decoration;
  final EdgeDims margin;
  final EdgeDims padding;
  final Matrix4 transform;
  final double width;
  final double height;

  Widget build() {
    Widget current = child;

    if (child == null && width == null && height == null)
      current = new ConstrainedBox(constraints: BoxConstraints.expand);

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
  Block(List<Widget> children, { String key })
    : super(key: key, children: children);

  RenderBlock get root => super.root;
  RenderBlock createNode() => new RenderBlock();
}

class Stack extends MultiChildRenderObjectWrapper {
  Stack(List<Widget> children, { String key })
    : super(key: key, children: children);

  RenderStack get root => super.root;
  RenderStack createNode() => new RenderStack();
}

class Positioned extends ParentDataNode {
  Positioned({
    String key,
    Widget child,
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

  Flex(List<Widget> children, {
    String key,
    this.direction: FlexDirection.horizontal,
    this.justifyContent: FlexJustifyContent.start,
    this.alignItems: FlexAlignItems.center
  }) : super(key: key, children: children);

  RenderFlex get root => super.root;
  RenderFlex createNode() => new RenderFlex(direction: this.direction);

  final FlexDirection direction;
  final FlexJustifyContent justifyContent;
  final FlexAlignItems alignItems;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    root.direction = direction;
    root.justifyContent = justifyContent;
    root.alignItems = alignItems;
  }

}

class Flexible extends ParentDataNode {
  Flexible({ String key, Widget child, int flex: 1 })
    : super(child, new FlexBoxParentData()..flex = flex, key: key);
}

class Inline extends LeafRenderObjectWrapper {
  Inline({ String key, this.text }) : super(key: key);

  RenderParagraph get root => super.root;
  RenderParagraph createNode() => new RenderParagraph(text);

  final InlineBase text;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    root.inline = text;
  }

}

class StyledText extends Component {
  // elements ::= "string" | [<text-style> <elements>*]
  // Where "string" is text to display and text-style is an instance of
  // TextStyle. The text-style applies to all of the elements that follow.
  StyledText({ this.elements, String key }) : super(key: key);

  final dynamic elements;

  InlineBase _toInline(dynamic element) {
    if (element is String) {
      return new InlineText(element);
    }
    if (element is Iterable && element.first is TextStyle) {
      return new InlineStyle(element.first, element.skip(1).map(_toInline).toList());
    }
    throw new ArgumentError("invalid elements");
  }

  Widget build() {
    return new Inline(text: _toInline(elements));
  }
}

class Text extends Component {
  Text(this.data, { String key, TextStyle this.style }) : super(key: key);
  final String data;
  final TextStyle style;
  bool get interchangeable => true;
  Widget build() {
    InlineBase text = new InlineText(data);
    TextStyle defaultStyle = DefaultTextStyle.of(this);
    TextStyle combinedStyle;
    if (defaultStyle != null) {
      if (style != null)
        combinedStyle = defaultStyle.merge(style);
      else
        combinedStyle = defaultStyle;
    } else {
      combinedStyle = style;
    }
    if (combinedStyle != null)
      text = new InlineStyle(combinedStyle, [text]);
    return new Inline(text: text);
  }
}

class Image extends LeafRenderObjectWrapper {
  Image({ sky.Image image, this.size })
    : image = image, super(key: image.hashCode.toString());

  RenderImage get root => super.root;
  RenderImage createNode() => new RenderImage(image, size);

  final sky.Image image;
  final Size size;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    root.image = image;
    root.requestedSize = size;
  }
}

class FutureImage extends StatefulComponent {
  FutureImage({ this.image, this.size });

  Future<sky.Image> image;
  Size size;
  sky.Image _resolvedImage;

  void didMount() {
    super.didMount();
    _resolveImage();
  }

  void _resolveImage() {
    image.then((sky.Image resolvedImage) {
      if (!mounted)
        return;
      setState(() {
        _resolvedImage = resolvedImage;
      });
    });
  }

  void syncFields(FutureImage source) {
    bool needToResolveImage = (image != source.image);
    image = source.image;
    size = source.size;
    if (needToResolveImage)
      _resolveImage();
  }

  Widget build() {
    return new Image(image: _resolvedImage, size: size);
  }
}

class NetworkImage extends Component {
  NetworkImage({ String src, this.size }) : src = src, super(key: src);

  final String src;
  final Size size;

  Widget build() {
    return new FutureImage(image: image_cache.load(src), size: size);
  }
}

class AssetImage extends Component {
  AssetImage({ this.bundle, String name, this.size })
    : name = name, super(key: name);

  final AssetBundle bundle;
  final String name;
  final Size size;

  Widget build() {
    return new FutureImage(image: bundle.loadImage(name), size: size);
  }
}

class WidgetToRenderBoxAdapter extends LeafRenderObjectWrapper {

  WidgetToRenderBoxAdapter(RenderBox renderBox)
    : renderBox = renderBox,
      super(key: renderBox.hashCode.toString());

  RenderBox get root => super.root;
  RenderBox createNode() => this.renderBox;

  final RenderBox renderBox;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    if (old != null) {
      assert(old is WidgetToRenderBoxAdapter);
      assert(root == old.root);
    }
  }

  void remove() {
    RenderObjectWrapper ancestor = findAncestorRenderObjectWrapper();
    assert(ancestor is RenderObjectWrapper);
    ancestor.detachChildRoot(this);
    super.remove();
  }

}
