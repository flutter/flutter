// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/rendering.dart';
import 'package:sky/services.dart';
import 'package:sky/src/fn3/framework.dart';

export 'package:sky/rendering.dart' show
    BackgroundImage,
    BlockDirection,
    Border,
    BorderSide,
    BoxConstraints,
    BoxDecoration,
    BoxDecorationPosition,
    BoxShadow,
    Color,
    EdgeDims,
    FlexAlignItems,
    FlexDirection,
    FlexJustifyContent,
    Offset,
    Paint,
    Path,
    Point,
    Rect,
    ScrollDirection,
    Shape,
    ShrinkWrap,
    Size,
    ValueChanged;


// PAINTING NODES

class Opacity extends OneChildRenderObjectWidget {
  Opacity({ Key key, this.opacity, Widget child })
    : super(key: key, child: child) {
    assert(opacity >= 0.0 && opacity <= 1.0);
  }

  final double opacity;

  RenderOpacity createRenderObject() => new RenderOpacity(opacity: opacity);

  void updateRenderObject(RenderOpacity renderObject, Opacity oldWidget) {
    renderObject.opacity = opacity;
  }
}

class ColorFilter extends OneChildRenderObjectWidget {
  ColorFilter({ Key key, this.color, this.transferMode, Widget child })
    : super(key: key, child: child) {
    assert(color != null);
    assert(transferMode != null);
  }

  final Color color;
  final sky.TransferMode transferMode;

  RenderColorFilter createRenderObject() => new RenderColorFilter(color: color, transferMode: transferMode);

  void updateRenderObject(RenderColorFilter renderObject, ColorFilter oldWidget) {
    renderObject.color = color;
    renderObject.transferMode = transferMode;
  }
}

class DecoratedBox extends OneChildRenderObjectWidget {
  DecoratedBox({
    Key key,
    this.decoration,
    this.position: BoxDecorationPosition.background,
    Widget child
  }) : super(key: key, child: child) {
    assert(decoration != null);
    assert(position != null);
  }

  final BoxDecoration decoration;
  final BoxDecorationPosition position;

  RenderObject createRenderObject() => new RenderDecoratedBox(decoration: decoration, position: position);

  void updateRenderObject(RenderDecoratedBox renderObject, DecoratedBox oldWidget) {
    renderObject.decoration = decoration;
    renderObject.position = position;
  }
}

class CustomPaint extends OneChildRenderObjectWidget {
  CustomPaint({ Key key, this.callback, this.token, Widget child })
    : super(key: key, child: child) {
    assert(callback != null);
  }

  final CustomPaintCallback callback;
  final Object token; // set this to be repainted automatically when the token changes

  RenderCustomPaint createRenderObject() => new RenderCustomPaint(callback: callback);

  void updateRenderObject(RenderCustomPaint renderObject, CustomPaint oldWidget) {
    if (oldWidget != null && oldWidget.token != token)
      renderObject.markNeedsPaint();
    renderObject.callback = callback;
  }

  void didUnmountRenderObject(RenderCustomPaint renderObject) {
    renderObject.callback = null;
  }
}

class ClipRect extends OneChildRenderObjectWidget {
  ClipRect({ Key key, Widget child })
    : super(key: key, child: child);

  RenderClipRect createRenderObject() => new RenderClipRect();

  void updateRenderObject(RenderClipRect renderObject, ClipRect oldWidget) {
    // Nothing to update
  }
}

class ClipRRect extends OneChildRenderObjectWidget {
  ClipRRect({ Key key, this.xRadius, this.yRadius, Widget child })
    : super(key: key, child: child);

  final double xRadius;
  final double yRadius;

  RenderClipRRect createRenderObject() => new RenderClipRRect(xRadius: xRadius, yRadius: yRadius);

  void updateRenderObject(RenderClipRRect renderObject, ClipRRect oldWidget) {
    renderObject.xRadius = xRadius;
    renderObject.yRadius = yRadius;
  }
}

class ClipOval extends OneChildRenderObjectWidget {
  ClipOval({ Key key, Widget child })
    : super(key: key, child: child);

  RenderClipOval createRenderObject() => new RenderClipOval();

  void updateRenderObject(RenderClipOval renderObject, ClipOval oldWidget) {
    // Nothing to update
  }
}


// POSITIONING AND SIZING NODES

class Transform extends OneChildRenderObjectWidget {
  Transform({ Key key, this.transform, this.origin, Widget child })
    : super(key: key, child: child) {
    assert(transform != null);
  }

  final Matrix4 transform;
  final Offset origin;

  RenderTransform createRenderObject() => new RenderTransform(transform: transform, origin: origin);

  void updateRenderObject(RenderTransform renderObject, Transform oldWidget) {
    renderObject.transform = transform;
    renderObject.origin = origin;
  }
}

class Padding extends OneChildRenderObjectWidget {
  Padding({ Key key, this.padding, Widget child })
    : super(key: key, child: child) {
    assert(padding != null);
  }

  final EdgeDims padding;

  RenderPadding createRenderObject() => new RenderPadding(padding: padding);

  void updateRenderObject(RenderPadding renderObject, Padding oldWidget) {
    renderObject.padding = padding;
  }
}

class Align extends OneChildRenderObjectWidget {
  Align({
    Key key,
    this.horizontal: 0.5,
    this.vertical: 0.5,
    this.shrinkWrap: ShrinkWrap.none,
    Widget child
  }) : super(key: key, child: child) {
    assert(horizontal != null);
    assert(vertical != null);
    assert(shrinkWrap != null);
  }

  final double horizontal;
  final double vertical;
  final ShrinkWrap shrinkWrap;

  RenderPositionedBox createRenderObject() => new RenderPositionedBox(horizontal: horizontal, vertical: vertical, shrinkWrap: shrinkWrap);

  void updateRenderObject(RenderPositionedBox renderObject, Align oldWidget) {
    renderObject.horizontal = horizontal;
    renderObject.vertical = vertical;
    renderObject.shrinkWrap = shrinkWrap;
  }
}

class Center extends Align {
  Center({ Key key, ShrinkWrap shrinkWrap: ShrinkWrap.none, Widget child })
    : super(key: key, shrinkWrap: shrinkWrap, child: child);
}

class SizedBox extends OneChildRenderObjectWidget {
  SizedBox({ Key key, this.width, this.height, Widget child })
    : super(key: key, child: child);

  final double width;
  final double height;

  RenderConstrainedBox createRenderObject() => new RenderConstrainedBox(additionalConstraints: _additionalConstraints);

  BoxConstraints get _additionalConstraints {
    BoxConstraints result = const BoxConstraints();
    if (width != null)
      result = result.tightenWidth(width);
    if (height != null)
      result = result.tightenHeight(height);
    return result;
  }

  void updateRenderObject(RenderConstrainedBox renderObject, SizedBox oldWidget) {
    renderObject.additionalConstraints = _additionalConstraints;
  }
}

class ConstrainedBox extends OneChildRenderObjectWidget {
  ConstrainedBox({ Key key, this.constraints, Widget child })
    : super(key: key, child: child) {
    assert(constraints != null);
  }

  final BoxConstraints constraints;

  RenderConstrainedBox createRenderObject() => new RenderConstrainedBox(additionalConstraints: constraints);

  void updateRenderObject(RenderConstrainedBox renderObject, ConstrainedBox oldWidget) {
    renderObject.additionalConstraints = constraints;
  }
}

class AspectRatio extends OneChildRenderObjectWidget {
  AspectRatio({ Key key, this.aspectRatio, Widget child })
    : super(key: key, child: child) {
    assert(aspectRatio != null);
  }

  final double aspectRatio;

  RenderAspectRatio createRenderObject() => new RenderAspectRatio(aspectRatio: aspectRatio);

  void updateRenderObject(RenderAspectRatio renderObject, AspectRatio oldWidget) {
    renderObject.aspectRatio = aspectRatio;
  }
}

class IntrinsicWidth extends OneChildRenderObjectWidget {
  IntrinsicWidth({ Key key, this.stepWidth, this.stepHeight, Widget child })
    : super(key: key, child: child);

  final double stepWidth;
  final double stepHeight;

  RenderIntrinsicWidth createRenderObject() => new RenderIntrinsicWidth(stepWidth: stepWidth, stepHeight: stepHeight);

  void updateRenderObject(RenderIntrinsicWidth renderObject, IntrinsicWidth oldWidget) {
    renderObject.stepWidth = stepWidth;
    renderObject.stepHeight = stepHeight;
  }
}

class IntrinsicHeight extends OneChildRenderObjectWidget {
  IntrinsicHeight({ Key key, Widget child })
    : super(key: key, child: child);

  RenderIntrinsicHeight createRenderObject() => new RenderIntrinsicHeight();

  void updateRenderObject(RenderIntrinsicHeight renderObject, IntrinsicHeight oldWidget) {
    // Nothing to update
  }
}

class Baseline extends OneChildRenderObjectWidget {
  Baseline({ Key key, this.baseline, this.baselineType: TextBaseline.alphabetic, Widget child })
    : super(key: key, child: child) {
    assert(baseline != null);
    assert(baselineType != null);
  }

  final double baseline; // in pixels
  final TextBaseline baselineType;

  RenderBaseline createRenderObject() => new RenderBaseline(baseline: baseline, baselineType: baselineType);

  void updateRenderObject(RenderBaseline renderObject, Baseline oldWidget) {
    renderObject.baseline = baseline;
    renderObject.baselineType = baselineType;
  }
}

class Viewport extends OneChildRenderObjectWidget {
  Viewport({
    Key key,
    this.scrollDirection: ScrollDirection.vertical,
    this.scrollOffset: Offset.zero,
    Widget child
  }) : super(key: key, child: child) {
    assert(scrollDirection != null);
    assert(scrollOffset != null);
  }

  final ScrollDirection scrollDirection;
  final Offset scrollOffset;

  RenderViewport createRenderObject() => new RenderViewport(scrollDirection: scrollDirection, scrollOffset: scrollOffset);

  void updateRenderObject(RenderViewport renderObject, Viewport oldWidget) {
    // Order dependency: RenderViewport validates scrollOffset based on scrollDirection.
    renderObject.scrollDirection = scrollDirection;
    renderObject.scrollOffset = scrollOffset;
  }
}

class SizeObserver extends OneChildRenderObjectWidget {
  SizeObserver({ Key key, this.callback, Widget child })
    : super(key: key, child: child) {
    assert(callback != null);
  }

  final SizeChangedCallback callback;

  RenderSizeObserver createRenderObject() => new RenderSizeObserver(callback: callback);

  void updateRenderObject(RenderSizeObserver renderObject, SizeObserver oldWidget) {
    renderObject.callback = callback;
  }

  void didUnmountRenderObject(RenderSizeObserver renderObject) {
    renderObject.callback = null;
  }
}


// CONVENIENCE CLASS TO COMBINE COMMON PAINTING, POSITIONING, AND SIZING NODES

class Container extends StatelessComponent {

  Container({
    Key key,
    this.child,
    this.constraints,
    this.decoration,
    this.foregroundDecoration,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.transform
  }) : super(key: key) {
    assert(margin == null || margin.isNonNegative);
    assert(padding == null || padding.isNonNegative);
  }

  final Widget child;
  final BoxConstraints constraints;
  final BoxDecoration decoration;
  final BoxDecoration foregroundDecoration;
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

  Widget build(BuildContext context) {
    Widget current = child;

    if (child == null && (width == null || height == null))
      current = new ConstrainedBox(constraints: const BoxConstraints.expand());

    EdgeDims effectivePadding = _paddingIncludingBorder;
    if (effectivePadding != null)
      current = new Padding(padding: effectivePadding, child: current);

    if (decoration != null)
      current = new DecoratedBox(decoration: decoration, child: current);

    if (foregroundDecoration != null) {
      current = new DecoratedBox(
        decoration: foregroundDecoration,
        position: BoxDecorationPosition.foreground,
        child: current
      );
    }

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

class BlockBody extends MultiChildRenderObjectWidget {
  BlockBody(List<Widget> children, {
    Key key,
    this.direction: BlockDirection.vertical
  }) : super(key: key, children: children) {
    assert(direction != null);
  }

  final BlockDirection direction;

  RenderBlock createRenderObject() => new RenderBlock(direction: direction);

  void updateRenderObject(RenderBlock renderObject, BlockBody oldWidget) {
    renderObject.direction = direction;
  }
}

class Stack extends MultiChildRenderObjectWidget {
  Stack(List<Widget> children, { Key key })
    : super(key: key, children: children);

  RenderStack createRenderObject() => new RenderStack();

  void updateRenderObject(RenderStack renderObject, Stack oldWidget) {
    // Nothing to update
  }
}

class Positioned extends ParentDataWidget {
  Positioned({
    Key key,
    Widget child,
    this.top,
    this.right,
    this.bottom,
    this.left
  }) : super(key: key, child: child);

  final double top;
  final double right;
  final double bottom;
  final double left;

  void debugValidateAncestor(Widget ancestor) {
    assert(() {
      'Positioned must placed inside a Stack';
      return ancestor is Stack;
    });
  }

  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StackParentData);
    final StackParentData parentData = renderObject.parentData;
    bool needsLayout = false;

    if (parentData.top != top) {
      parentData.top = top;
      needsLayout = true;
    }

    if (parentData.right != right) {
      parentData.right = right;
      needsLayout = true;
    }

    if (parentData.bottom != bottom) {
      parentData.bottom = bottom;
      needsLayout = true;
    }

    if (parentData.left != left) {
      parentData.left = left;
      needsLayout = true;
    }

    if (needsLayout)
      renderObject.markNeedsLayout();
  }
}

class Grid extends MultiChildRenderObjectWidget {
  Grid(List<Widget> children, { Key key, this.maxChildExtent })
    : super(key: key, children: children) {
    assert(maxChildExtent != null);
  }

  final double maxChildExtent;

  RenderGrid createRenderObject() => new RenderGrid(maxChildExtent: maxChildExtent);

  void updateRenderObject(RenderGrid renderObject, Grid oldWidget) {
    renderObject.maxChildExtent = maxChildExtent;
  }
}

class Flex extends MultiChildRenderObjectWidget {
  Flex(List<Widget> children, {
    Key key,
    this.direction: FlexDirection.horizontal,
    this.justifyContent: FlexJustifyContent.start,
    this.alignItems: FlexAlignItems.center,
    this.textBaseline
  }) : super(key: key, children: children) {
    assert(direction != null);
    assert(justifyContent != null);
    assert(alignItems != null);
  }

  final FlexDirection direction;
  final FlexJustifyContent justifyContent;
  final FlexAlignItems alignItems;
  final TextBaseline textBaseline;

  RenderFlex createRenderObject() => new RenderFlex(direction: direction);

  void updateRenderObject(RenderFlex renderObject, Flex oldWidget) {
    renderObject.direction = direction;
    renderObject.justifyContent = justifyContent;
    renderObject.alignItems = alignItems;
    renderObject.textBaseline = textBaseline;
  }
}

class Row extends Flex {
  Row(List<Widget> children, {
    Key key,
    justifyContent: FlexJustifyContent.start,
    alignItems: FlexAlignItems.center,
    textBaseline
  }) : super(children, key: key, direction: FlexDirection.horizontal, justifyContent: justifyContent, alignItems: alignItems, textBaseline: textBaseline);
}

class Column extends Flex {
  Column(List<Widget> children, {
    Key key,
    justifyContent: FlexJustifyContent.start,
    alignItems: FlexAlignItems.center,
    textBaseline
  }) : super(children, key: key, direction: FlexDirection.vertical, justifyContent: justifyContent, alignItems: alignItems, textBaseline: textBaseline);
}

class Flexible extends ParentDataWidget {
  Flexible({ Key key, this.flex: 1, Widget child })
    : super(key: key, child: child);

  final int flex;

  void debugValidateAncestor(Widget ancestor) {
    assert(() {
      'Flexible must placed inside a Flex';
      return ancestor is Flex;
    });
  }

  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is FlexParentData);
    final FlexParentData parentData = renderObject.parentData;
    if (parentData.flex != flex) {
      parentData.flex = flex;
      renderObject.markNeedsLayout();
    }
  }
}

class Paragraph extends LeafRenderObjectWidget {
  Paragraph({ Key key, this.text }) : super(key: key) {
    assert(text != null);
  }

  final TextSpan text;

  RenderParagraph createRenderObject() => new RenderParagraph(text);

  void updateRenderObject(RenderParagraph renderObject, Paragraph oldWidget) {
    renderObject.text = text;
  }
}

class StyledText extends StatelessComponent {
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

  Widget build(BuildContext context) {
    return new Paragraph(text: _toSpan(elements));
  }
}

class DefaultTextStyle extends InheritedWidget {
  DefaultTextStyle({
    Key key,
    this.style,
    Widget child
  }) : super(key: key, child: child) {
    assert(style != null);
    assert(child != null);
  }

  final TextStyle style;

  static TextStyle of(BuildContext context) {
    DefaultTextStyle result = context.inheritedWidgetOfType(DefaultTextStyle);
    return result?.style;
  }

  bool updateShouldNotify(DefaultTextStyle old) => style != old.style;
}

class Text extends StatelessComponent {
  Text(this.data, { Key key, TextStyle this.style }) : super(key: key) {
    assert(data != null);
  }

  final String data;
  final TextStyle style;

  Widget build(BuildContext context) {
    TextSpan text = new PlainTextSpan(data);
    TextStyle defaultStyle = DefaultTextStyle.of(context);
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

class Image extends LeafRenderObjectWidget {
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

  RenderImage createRenderObject() => new RenderImage(
    image: image,
    width: width,
    height: height,
    colorFilter: colorFilter,
    fit: fit,
    repeat: repeat);

  void updateRenderObject(RenderImage renderObject, Image oldWidget) {
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
  }) : super(key: key) {
    assert(image != null);
  }

  final ImageResource image;
  final double width;
  final double height;
  final sky.ColorFilter colorFilter;
  final ImageFit fit;
  final ImageRepeat repeat;

  ImageListenerState createState() => new ImageListenerState(this);
}

class ImageListenerState extends ComponentState<ImageListener> {
  ImageListenerState(ImageListener config) : super(config) {
    config.image.addListener(_handleImageChanged);
  }

  sky.Image _resolvedImage;

  void _handleImageChanged(sky.Image resolvedImage) {
    setState(() {
      _resolvedImage = resolvedImage;
    });
  }

  void dispose() {
    config.image.removeListener(_handleImageChanged);
  }

  void didUpdateConfig(ImageListener oldConfig) {
    if (config.image != oldConfig.image) {
      oldConfig.image.removeListener(_handleImageChanged);
      config.image.addListener(_handleImageChanged);
    }
  }

  Widget build(BuildContext context) {
    return new Image(
      image: _resolvedImage,
      width: config.width,
      height: config.height,
      colorFilter: config.colorFilter,
      fit: config.fit,
      repeat: config.repeat
    );
  }
}

class NetworkImage extends StatelessComponent {
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

  Widget build(BuildContext context) {
    return new ImageListener(
      image: imageCache.load(src),
      width: width,
      height: height,
      colorFilter: colorFilter,
      fit: fit,
      repeat: repeat
    );
  }
}

class AssetImage extends StatelessComponent {
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

  Widget build(BuildContext context) {
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


// EVENT HANDLING

class Listener extends OneChildRenderObjectWidget {
  Listener({
    Key key,
    Widget child,    
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel
  }): super(key: key, child: child);

  final PointerEventListener onPointerDown;
  final PointerEventListener onPointerMove;
  final PointerEventListener onPointerUp;
  final PointerEventListener onPointerCancel;

  RenderPointerListener createRenderObject() => new RenderPointerListener(
    onPointerDown: onPointerDown,
    onPointerMove: onPointerMove,
    onPointerUp: onPointerUp,
    onPointerCancel: onPointerCancel
  );

  void updateRenderObject(RenderPointerListener renderObject, Listener oldWidget) {
    renderObject.onPointerDown = onPointerDown;
    renderObject.onPointerMove = onPointerMove;
    renderObject.onPointerUp = onPointerUp;
    renderObject.onPointerCancel = onPointerCancel;
  }
}

class IgnorePointer extends OneChildRenderObjectWidget {
  IgnorePointer({ Key key, Widget child, this.ignoring: true })
    : super(key: key, child: child);

  final bool ignoring;

  RenderIgnorePointer createRenderObject() => new RenderIgnorePointer(ignoring: ignoring);

  void updateRenderObject(RenderIgnorePointer renderObject, IgnorePointer oldWidget) {
    renderObject.ignoring = ignoring;
  }
}
