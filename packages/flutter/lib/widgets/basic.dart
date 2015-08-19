// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:vector_math/vector_math.dart';

import 'package:sky/base/image_resource.dart';
import 'package:sky/mojo/asset_bundle.dart';
import 'package:sky/mojo/net/image_cache.dart' as image_cache;
import 'package:sky/painting/text_style.dart';
import 'package:sky/painting/paragraph_painter.dart';
import 'package:sky/rendering/block.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/rendering/image.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/paragraph.dart';
import 'package:sky/rendering/proxy_box.dart';
import 'package:sky/rendering/shifted_box.dart';
import 'package:sky/rendering/stack.dart';
import 'package:sky/rendering/viewport.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/framework.dart';

export 'package:sky/base/hit_test.dart' show EventDisposition, combineEventDispositions;
export 'package:sky/rendering/block.dart' show BlockDirection;
export 'package:sky/rendering/box.dart' show BoxConstraints;
export 'package:sky/rendering/flex.dart' show FlexDirection, FlexJustifyContent, FlexAlignItems;
export 'package:sky/rendering/object.dart' show Point, Offset, Size, Rect, Color, Paint, Path;
export 'package:sky/rendering/proxy_box.dart' show BackgroundImage, BoxDecoration, BoxShadow, Border, BorderSide, EdgeDims;
export 'package:sky/rendering/toggleable.dart' show ValueChanged;
export 'package:sky/rendering/viewport.dart' show ScrollDirection;
export 'package:sky/widgets/framework.dart' show Key, GlobalKey, Widget, Component, StatefulComponent, App, runApp, Listener, ParentDataNode;

// PAINTING NODES

class Opacity extends OneChildRenderObjectWrapper {
  Opacity({ Key key, this.opacity, Widget child })
    : super(key: key, child: child);

  final double opacity;

  RenderOpacity createNode() => new RenderOpacity(opacity: opacity);
  RenderOpacity get renderObject => super.renderObject;

  void syncRenderObject(Opacity old) {
    super.syncRenderObject(old);
    renderObject.opacity = opacity;
  }
}

class ColorFilter extends OneChildRenderObjectWrapper {
  ColorFilter({ Key key, this.color, this.transferMode, Widget child })
    : super(key: key, child: child);

  final Color color;
  final sky.TransferMode transferMode;

  RenderColorFilter createNode() => new RenderColorFilter(color: color, transferMode: transferMode);
  RenderColorFilter get renderObject => super.renderObject;

  void syncRenderObject(ColorFilter old) {
    super.syncRenderObject(old);
    renderObject.color = color;
    renderObject.transferMode = transferMode;
  }
}

class DecoratedBox extends OneChildRenderObjectWrapper {
  DecoratedBox({ Key key, this.decoration, Widget child })
    : super(key: key, child: child);

  final BoxDecoration decoration;

  RenderDecoratedBox createNode() => new RenderDecoratedBox(decoration: decoration);
  RenderDecoratedBox get renderObject => super.renderObject;

  void syncRenderObject(DecoratedBox old) {
    super.syncRenderObject(old);
    renderObject.decoration = decoration;
  }
}

class CustomPaint extends OneChildRenderObjectWrapper {
  CustomPaint({ Key key, this.callback, this.token, Widget child })
    : super(key: key, child: child);

  final CustomPaintCallback callback;
  final dynamic token; // set this to be repainted automatically when the token changes

  RenderCustomPaint createNode() => new RenderCustomPaint(callback: callback);
  RenderCustomPaint get renderObject => super.renderObject;

  void syncRenderObject(CustomPaint old) {
    super.syncRenderObject(old);
    if (old != null && old.token != token)
      renderObject.markNeedsPaint();
    renderObject.callback = callback;
  }

  void remove() {
    renderObject.callback = null;
    super.remove();
  }
}

class ClipRect extends OneChildRenderObjectWrapper {
  ClipRect({ Key key, Widget child })
    : super(key: key, child: child);

  RenderClipRect createNode() => new RenderClipRect();
  RenderClipRect get renderObject => super.renderObject;

  // Nothing to sync, so we don't implement syncRenderObject()
}

class ClipRRect extends OneChildRenderObjectWrapper {
  ClipRRect({ Key key, this.xRadius, this.yRadius, Widget child })
    : super(key: key, child: child);

  final double xRadius;
  final double yRadius;

  RenderClipRRect createNode() => new RenderClipRRect(xRadius: xRadius, yRadius: yRadius);
  RenderClipRRect get renderObject => super.renderObject;

  void syncRenderObject(ClipRRect old) {
    super.syncRenderObject(old);
    renderObject.xRadius = xRadius;
    renderObject.yRadius = yRadius;
  }
}

class ClipOval extends OneChildRenderObjectWrapper {
  ClipOval({ Key key, Widget child })
    : super(key: key, child: child);

  RenderClipOval createNode() => new RenderClipOval();
  RenderClipOval get renderObject => super.renderObject;

  // Nothing to sync, so we don't implement syncRenderObject()
}


// POSITIONING AND SIZING NODES

class Transform extends OneChildRenderObjectWrapper {
  Transform({ Key key, this.transform, Widget child })
    : super(key: key, child: child);

  final Matrix4 transform;

  RenderTransform createNode() => new RenderTransform(transform: transform);
  RenderTransform get renderObject => super.renderObject;

  void syncRenderObject(Transform old) {
    super.syncRenderObject(old);
    renderObject.transform = transform;
  }
}

class Padding extends OneChildRenderObjectWrapper {
  Padding({ Key key, this.padding, Widget child })
    : super(key: key, child: child);

  final EdgeDims padding;

  RenderPadding createNode() => new RenderPadding(padding: padding);
  RenderPadding get renderObject => super.renderObject;

  void syncRenderObject(Padding old) {
    super.syncRenderObject(old);
    renderObject.padding = padding;
  }
}

class Center extends OneChildRenderObjectWrapper {
  Center({ Key key, Widget child })
    : super(key: key, child: child);

  RenderPositionedBox createNode() => new RenderPositionedBox();
  RenderPositionedBox get renderObject => super.renderObject;

  // Nothing to sync, so we don't implement syncRenderObject()
}

class SizedBox extends OneChildRenderObjectWrapper {
  SizedBox({ Key key, this.width, this.height, Widget child })
    : super(key: key, child: child);

  final double width;
  final double height;

  RenderConstrainedBox createNode() => new RenderConstrainedBox(additionalConstraints: _additionalConstraints());
  RenderConstrainedBox get renderObject => super.renderObject;

  BoxConstraints _additionalConstraints() {
    BoxConstraints result = const BoxConstraints();
    if (width != null)
      result = result.applyWidth(width);
    if (height != null)
      result = result.applyHeight(height);
    return result;
  }

  void syncRenderObject(SizedBox old) {
    super.syncRenderObject(old);
    renderObject.additionalConstraints = _additionalConstraints();
  }
}

class ConstrainedBox extends OneChildRenderObjectWrapper {
  ConstrainedBox({ Key key, this.constraints, Widget child })
    : super(key: key, child: child);

  final BoxConstraints constraints;

  RenderConstrainedBox createNode() => new RenderConstrainedBox(additionalConstraints: constraints);
  RenderConstrainedBox get renderObject => super.renderObject;

  void syncRenderObject(ConstrainedBox old) {
    super.syncRenderObject(old);
    renderObject.additionalConstraints = constraints;
  }
}

class AspectRatio extends OneChildRenderObjectWrapper {
  AspectRatio({ Key key, this.aspectRatio, Widget child })
    : super(key: key, child: child);

  final double aspectRatio;

  RenderAspectRatio createNode() => new RenderAspectRatio(aspectRatio: aspectRatio);
  RenderAspectRatio get renderObject => super.renderObject;

  void syncRenderObject(AspectRatio old) {
    super.syncRenderObject(old);
    renderObject.aspectRatio = aspectRatio;
  }
}

class ShrinkWrapWidth extends OneChildRenderObjectWrapper {
  ShrinkWrapWidth({ Key key, this.stepWidth, this.stepHeight, Widget child })
    : super(key: key, child: child);

  final double stepWidth;
  final double stepHeight;

  RenderShrinkWrapWidth createNode() => new RenderShrinkWrapWidth();
  RenderShrinkWrapWidth get renderObject => super.renderObject;

  void syncRenderObject(ShrinkWrapWidth old) {
    super.syncRenderObject(old);
    renderObject.stepWidth = stepWidth;
    renderObject.stepHeight = stepHeight;
  }
}

class Baseline extends OneChildRenderObjectWrapper {
  Baseline({ Key key, this.baseline, this.baselineType: TextBaseline.alphabetic, Widget child })
    : super(key: key, child: child);

  final double baseline; // in pixels
  final TextBaseline baselineType;

  RenderBaseline createNode() => new RenderBaseline(baseline: baseline, baselineType: baselineType);
  RenderBaseline get renderObject => super.renderObject;

  void syncRenderObject(Baseline old) {
    super.syncRenderObject(old);
    renderObject.baseline = baseline;
    renderObject.baselineType = baselineType;
  }
}

class Viewport extends OneChildRenderObjectWrapper {
  Viewport({
    Key key,
    this.scrollOffset: Offset.zero,
    this.scrollDirection: ScrollDirection.vertical,
    Widget child
  }) : super(key: key, child: child);

  final Offset scrollOffset;
  final ScrollDirection scrollDirection;

  RenderViewport createNode() => new RenderViewport(scrollOffset: scrollOffset, scrollDirection: scrollDirection);
  RenderViewport get renderObject => super.renderObject;

  void syncRenderObject(Viewport old) {
    super.syncRenderObject(old);
    renderObject.scrollOffset = scrollOffset;
    renderObject.scrollDirection = scrollDirection;
  }
}

class SizeObserver extends OneChildRenderObjectWrapper {
  SizeObserver({ Key key, this.callback, Widget child })
    : super(key: key, child: child);

  final SizeChangedCallback callback;

  RenderSizeObserver createNode() => new RenderSizeObserver(callback: callback);
  RenderSizeObserver get renderObject => super.renderObject;

  void syncRenderObject(SizeObserver old) {
    super.syncRenderObject(old);
    renderObject.callback = callback;
  }

  void remove() {
    renderObject.callback = null;
    super.remove();
  }
}


// CONVENIENCE CLASS TO COMBINE COMMON PAINTING, POSITIONING, AND SIZING NODES

class Container extends Component {

  Container({
    Key key,
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

  EdgeDims get _paddingIncludingBorder {
    if (decoration == null || decoration.border == null)
      return padding;
    EdgeDims borderPadding = decoration.border.dimensions;
    if (padding == null)
      return borderPadding;
    return padding + borderPadding;
  }

  Widget build() {
    Widget current = child;

    if (child == null && (width == null || height == null))
      current = new ConstrainedBox(constraints: BoxConstraints.expand);

    EdgeDims effectivePadding = _paddingIncludingBorder;
    if (effectivePadding != null)
      current = new Padding(padding: effectivePadding, child: current);

    if (decoration != null)
      current = new DecoratedBox(decoration: decoration, child: current);

    if (width != null || height != null) {
      current = new SizedBox(
        width: width,
        height: height,
        child: current
      );
    }

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
  Block(List<Widget> children, {
    Key key,
    this.direction: BlockDirection.vertical
  }) : super(key: key, children: children);

  final BlockDirection direction;

  RenderBlock createNode() => new RenderBlock(direction: direction);
  RenderBlock get renderObject => super.renderObject;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    renderObject.direction = direction;
  }
}

class Stack extends MultiChildRenderObjectWrapper {
  Stack(List<Widget> children, { Key key })
    : super(key: key, children: children);

  RenderStack createNode() => new RenderStack();
  RenderStack get renderObject => super.renderObject;
}

class Positioned extends ParentDataNode {
  Positioned({
    Key key,
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
    Key key,
    this.direction: FlexDirection.horizontal,
    this.justifyContent: FlexJustifyContent.start,
    this.alignItems: FlexAlignItems.center,
    this.textBaseline
  }) : super(key: key, children: children);

  final FlexDirection direction;
  final FlexJustifyContent justifyContent;
  final FlexAlignItems alignItems;
  final TextBaseline textBaseline;

  RenderFlex createNode() => new RenderFlex(direction: direction);
  RenderFlex get renderObject => super.renderObject;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    renderObject.direction = direction;
    renderObject.justifyContent = justifyContent;
    renderObject.alignItems = alignItems;
    renderObject.textBaseline = textBaseline;
  }

}

class Flexible extends ParentDataNode {
  Flexible({ Key key, int flex: 1, Widget child })
    : super(child, new FlexBoxParentData()..flex = flex, key: key);
}

class Paragraph extends LeafRenderObjectWrapper {
  Paragraph({ Key key, this.text }) : super(key: key);

  final TextSpan text;

  RenderParagraph createNode() => new RenderParagraph(text);
  RenderParagraph get renderObject => super.renderObject;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    renderObject.text = text;
  }
}

class StyledText extends Component {
  // elements ::= "string" | [<text-style> <elements>*]
  // Where "string" is text to display and text-style is an instance of
  // TextStyle. The text-style applies to all of the elements that follow.
  StyledText({ this.elements, Key key }) : super(key: key) {
    assert(_toSpan(elements) != null);
  }

  final dynamic elements;

  TextSpan _toSpan(dynamic element) {
    if (element is String)
      return new PlainTextSpan(element);
    if (element is Iterable) {
      dynamic first = element.first;
      if (first is! TextStyle)
        throw new ArgumentError("First element of Iterable is a ${first.runtimeType} not a TextStyle");
      return new StyledTextSpan(first, element.skip(1).map(_toSpan).toList());
    }
    throw new ArgumentError("Element is ${element.runtimeType} not a String or an Iterable");
  }

  Widget build() {
    return new Paragraph(text: _toSpan(elements));
  }
}

class Text extends Component {
  Text(this.data, { Key key, TextStyle this.style }) : super(key: key);

  final String data;
  final TextStyle style;

  Widget build() {
    TextSpan text = new PlainTextSpan(data);
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
      text = new StyledTextSpan(combinedStyle, [text]);
    return new Paragraph(text: text);
  }
}

class Image extends LeafRenderObjectWrapper {
  Image({
    Key key,
    this.image,
    this.width,
    this.height,
    this.colorFilter,
    this.fit: ImageFit.scaleDown,
    this.repeat: ImageRepeat.noRepeat
  }) : super(key: key);

  final sky.Image image;
  final double width;
  final double height;
  final sky.ColorFilter colorFilter;
  final ImageFit fit;
  final ImageRepeat repeat;

  RenderImage createNode() => new RenderImage(
    image: image,
    width: width,
    height: height,
    colorFilter: colorFilter,
    fit: fit,
    repeat: repeat);
  RenderImage get renderObject => super.renderObject;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    renderObject.image = image;
    renderObject.width = width;
    renderObject.height = height;
    renderObject.colorFilter = colorFilter;
    renderObject.fit = fit;
    renderObject.repeat = repeat;
  }
}

class ImageListener extends StatefulComponent {
  ImageListener({
    Key key,
    this.image,
    this.width,
    this.height,
    this.colorFilter,
    this.fit: ImageFit.scaleDown,
    this.repeat: ImageRepeat.noRepeat
  }) : super(key: key);

  ImageResource image;
  double width;
  double height;
  sky.ColorFilter colorFilter;
  ImageFit fit;
  ImageRepeat repeat;

  sky.Image _resolvedImage;

  void _handleImageChanged(sky.Image resolvedImage) {
    if (!mounted)
      return;
    setState(() {
      _resolvedImage = resolvedImage;
    });
  }

  void didMount() {
    super.didMount();
    image.addListener(_handleImageChanged);
  }

  void didUnmount() {
    super.didUnmount();
    image.removeListener(_handleImageChanged);
  }

  void syncFields(ImageListener source) {
    final bool needToUpdateListeners = (image != source.image) && mounted;
    if (needToUpdateListeners)
      image.removeListener(_handleImageChanged);
    image = source.image;
    width = source.width;
    height = source.height;
    colorFilter = source.colorFilter;
    fit = source.fit;
    repeat = source.repeat;
    if (needToUpdateListeners)
      image.addListener(_handleImageChanged);
  }

  Widget build() {
    return new Image(
      image: _resolvedImage,
      width: width,
      height: height,
      colorFilter: colorFilter,
      fit: fit,
      repeat: repeat
    );
  }
}

class NetworkImage extends Component {
  NetworkImage({
    Key key,
    this.src,
    this.width,
    this.height,
    this.colorFilter,
    this.fit: ImageFit.scaleDown,
    this.repeat: ImageRepeat.noRepeat
  }) : super(key: key);

  final String src;
  final double width;
  final double height;
  final sky.ColorFilter colorFilter;
  final ImageFit fit;
  final ImageRepeat repeat;

  Widget build() {
    return new ImageListener(
      image: image_cache.load(src),
      width: width,
      height: height,
      colorFilter: colorFilter,
      fit: fit,
      repeat: repeat
    );
  }
}

class AssetImage extends Component {
  AssetImage({
    Key key,
    this.name,
    this.bundle,
    this.width,
    this.height,
    this.colorFilter,
    this.fit: ImageFit.scaleDown,
    this.repeat: ImageRepeat.noRepeat
  }) : super(key: key);

  final String name;
  final AssetBundle bundle;
  final double width;
  final double height;
  final sky.ColorFilter colorFilter;
  final ImageFit fit;
  final ImageRepeat repeat;

  Widget build() {
    return new ImageListener(
      image: bundle.loadImage(name),
      width: width,
      height: height,
      colorFilter: colorFilter,
      fit: fit,
      repeat: repeat
    );
  }
}

class WidgetToRenderBoxAdapter extends LeafRenderObjectWrapper {
  WidgetToRenderBoxAdapter(RenderBox renderBox)
    : renderBox = renderBox,
      super(key: new Key.fromObjectIdentity(renderBox));

  final RenderBox renderBox;

  RenderBox createNode() => this.renderBox;
  RenderBox get renderObject => super.renderObject;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    if (old != null) {
      assert(old is WidgetToRenderBoxAdapter);
      assert(renderObject == old.renderObject);
    }
  }

  void remove() {
    RenderObjectWrapper ancestor = findAncestorRenderObjectWrapper();
    assert(ancestor is RenderObjectWrapper);
    assert(ancestor.renderObject == renderObject.parent);
    ancestor.detachChildRoot(this);
    super.remove();
  }
}


// EVENT HANDLING

class IgnorePointer extends OneChildRenderObjectWrapper {
  IgnorePointer({ Key key, Widget child })
    : super(key: key, child: child);
  RenderIgnorePointer createNode() => new RenderIgnorePointer();
  RenderIgnorePointer get renderObject => super.renderObject;
}
