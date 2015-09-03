// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:vector_math/vector_math.dart';

import 'package:sky/base/image_resource.dart';
import 'package:sky/mojo/asset_bundle.dart';
import 'package:sky/mojo/net/image_cache.dart' as image_cache;
import 'package:sky/painting/text_painter.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/src/rendering/block.dart';
import 'package:sky/src/rendering/box.dart';
import 'package:sky/src/rendering/flex.dart';
import 'package:sky/src/rendering/grid.dart';
import 'package:sky/src/rendering/image.dart';
import 'package:sky/src/rendering/object.dart';
import 'package:sky/src/rendering/paragraph.dart';
import 'package:sky/src/rendering/proxy_box.dart';
import 'package:sky/src/rendering/shifted_box.dart';
import 'package:sky/src/rendering/stack.dart';
import 'package:sky/src/rendering/viewport.dart';
import 'package:sky/src/widgets/default_text_style.dart';
import 'package:sky/src/widgets/framework.dart';

export 'package:sky/base/hit_test.dart' show EventDisposition, combineEventDispositions;
export 'package:sky/painting/text_style.dart';
export 'package:sky/src/rendering/block.dart' show BlockDirection;
export 'package:sky/src/rendering/box.dart' show BoxConstraints;
export 'package:sky/src/rendering/flex.dart' show FlexJustifyContent, FlexAlignItems, FlexDirection;
export 'package:sky/src/rendering/object.dart' show Point, Offset, Size, Rect, Color, Paint, Path;
export 'package:sky/src/rendering/proxy_box.dart' show BackgroundImage, BoxDecoration, BoxDecorationPosition, BoxShadow, Border, BorderSide, EdgeDims, Shape;
export 'package:sky/src/rendering/toggleable.dart' show ValueChanged;
export 'package:sky/src/rendering/viewport.dart' show ScrollDirection;

// PAINTING NODES

class Opacity extends OneChildRenderObjectWrapper {
  Opacity({ Key key, this.opacity, Widget child })
    : super(key: key, child: child) {
    assert(opacity >= 0.0 && opacity <= 1.0);
  }

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
    : super(key: key, child: child) {
    assert(color != null);
    assert(transferMode != null);
  }

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

  RenderDecoratedBox createNode() => new RenderDecoratedBox(decoration: decoration, position: position);
  RenderDecoratedBox get renderObject => super.renderObject;

  void syncRenderObject(DecoratedBox old) {
    super.syncRenderObject(old);
    renderObject.decoration = decoration;
    renderObject.position = position;
  }
}

class CustomPaint extends OneChildRenderObjectWrapper {
  CustomPaint({ Key key, this.callback, this.token, Widget child })
    : super(key: key, child: child) {
    assert(callback != null);
  }

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
  Transform({ Key key, this.transform, this.origin, Widget child })
    : super(key: key, child: child) {
    assert(transform != null);
  }

  final Matrix4 transform;
  final Offset origin;

  RenderTransform createNode() => new RenderTransform(transform: transform, origin: origin);
  RenderTransform get renderObject => super.renderObject;

  void syncRenderObject(Transform old) {
    super.syncRenderObject(old);
    renderObject.transform = transform;
    renderObject.origin = origin;
  }
}

class Padding extends OneChildRenderObjectWrapper {
  Padding({ Key key, this.padding, Widget child })
    : super(key: key, child: child) {
    assert(padding != null);
  }

  final EdgeDims padding;

  RenderPadding createNode() => new RenderPadding(padding: padding);
  RenderPadding get renderObject => super.renderObject;

  void syncRenderObject(Padding old) {
    super.syncRenderObject(old);
    renderObject.padding = padding;
  }
}

class Align extends OneChildRenderObjectWrapper {
  Align({ Key key, this.horizontal: 0.5, this.vertical: 0.5, Widget child })
    : super(key: key, child: child) {
    assert(horizontal != null);
    assert(vertical != null);
  }

  final double horizontal;
  final double vertical;

  RenderPositionedBox createNode() => new RenderPositionedBox(horizontal: horizontal, vertical: vertical);
  RenderPositionedBox get renderObject => super.renderObject;

  void syncRenderObject(Align old) {
    super.syncRenderObject(old);
    renderObject.horizontal = horizontal;
    renderObject.vertical = vertical;
  }
}

class Center extends Align {
  Center({ Key key, Widget child })
    : super(key: key, child: child);
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
    : super(key: key, child: child) {
    assert(constraints != null);
  }

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
    : super(key: key, child: child) {
    assert(aspectRatio != null);
  }

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

  RenderShrinkWrapWidth createNode() => new RenderShrinkWrapWidth(stepWidth: stepWidth, stepHeight: stepHeight);
  RenderShrinkWrapWidth get renderObject => super.renderObject;

  void syncRenderObject(ShrinkWrapWidth old) {
    super.syncRenderObject(old);
    renderObject.stepWidth = stepWidth;
    renderObject.stepHeight = stepHeight;
  }
}

class ShrinkWrapHeight extends OneChildRenderObjectWrapper {
  ShrinkWrapHeight({ Key key, Widget child })
    : super(key: key, child: child);

  RenderShrinkWrapHeight createNode() => new RenderShrinkWrapHeight();
  RenderShrinkWrapHeight get renderObject => super.renderObject;

  // Nothing to sync, so we don't implement syncRenderObject()
}

class Baseline extends OneChildRenderObjectWrapper {
  Baseline({ Key key, this.baseline, this.baselineType: TextBaseline.alphabetic, Widget child })
    : super(key: key, child: child) {
    assert(baseline != null);
    assert(baselineType != null);
  }

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
    this.scrollDirection: ScrollDirection.vertical,
    this.scrollOffset: Offset.zero,
    Widget child
  }) : super(key: key, child: child) {
    assert(scrollDirection != null);
    assert(scrollOffset != null);
  }

  final ScrollDirection scrollDirection;
  final Offset scrollOffset;

  RenderViewport createNode() => new RenderViewport(scrollDirection: scrollDirection, scrollOffset: scrollOffset);
  RenderViewport get renderObject => super.renderObject;

  void syncRenderObject(Viewport old) {
    super.syncRenderObject(old);
    // Order dependency: RenderViewport validates scrollOffset based on scrollDirection.
    renderObject.scrollDirection = scrollDirection;
    renderObject.scrollOffset = scrollOffset;
  }
}

class SizeObserver extends OneChildRenderObjectWrapper {
  SizeObserver({ Key key, this.callback, Widget child })
    : super(key: key, child: child) {
    assert(callback != null);
  }

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
    this.foregroundDecoration,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.transform
  }) : super(key: key);

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

  Widget build() {
    Widget current = child;

    if (child == null && (width == null || height == null))
      current = new ConstrainedBox(constraints: BoxConstraints.expand);

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

class BlockBody extends MultiChildRenderObjectWrapper {
  BlockBody(List<Widget> children, {
    Key key,
    this.direction: BlockDirection.vertical
  }) : super(key: key, children: children) {
    assert(direction != null);
  }

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

  void updateParentData(RenderObject child, Positioned positioned) {
    _updateParentDataWithValues(child, positioned?.top, positioned?.right, positioned?.bottom, positioned?.left);
  }

  void _updateParentDataWithValues(RenderObject child, double top, double right, double bottom, double left) {
    assert(child.parentData is StackParentData);
    final StackParentData parentData = child.parentData;
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

class Positioned extends ParentDataNode {
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
       'Positioned must placed directly inside a Stack';
       return ancestor is Stack;
     });
   }
}

class Grid extends MultiChildRenderObjectWrapper {
  Grid(List<Widget> children, { Key key, this.maxChildExtent })
    : super(key: key, children: children) {
    assert(maxChildExtent != null);
  }

  final double maxChildExtent;

  RenderGrid createNode() => new RenderGrid(maxChildExtent: maxChildExtent);
  RenderGrid get renderObject => super.renderObject;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    renderObject.maxChildExtent = maxChildExtent;
  }
}

class Flex extends MultiChildRenderObjectWrapper {
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

  RenderFlex createNode() => new RenderFlex(direction: direction);
  RenderFlex get renderObject => super.renderObject;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    renderObject.direction = direction;
    renderObject.justifyContent = justifyContent;
    renderObject.alignItems = alignItems;
    renderObject.textBaseline = textBaseline;
  }

  void updateParentData(RenderObject child, Flexible flexible) {
    _updateParentDataWithValues(child, flexible?.flex);
  }

  void _updateParentDataWithValues(RenderObject child, int flex) {
    assert(child.parentData is FlexParentData);
    final FlexParentData parentData = child.parentData;
    if (parentData.flex != flex) {
      parentData.flex = flex;
      renderObject.markNeedsLayout();
    }
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

class Flexible extends ParentDataNode {
  Flexible({ Key key, this.flex: 1, Widget child })
    : super(key: key, child: child);

  final int flex;

  void debugValidateAncestor(Widget ancestor) {
    assert(() {
      'Flexible must placed directly inside a Flex';
      return ancestor is Flex;
    });
  }
}

class Paragraph extends LeafRenderObjectWrapper {
  Paragraph({ Key key, this.text }) : super(key: key) {
    assert(text != null);
  }

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
  Text(this.data, { Key key, TextStyle this.style }) : super(key: key) {
    assert(data != null);
  }

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
  }) : super(key: key) {
    assert(image != null);
  }

  ImageResource image;
  double width;
  double height;
  sky.ColorFilter colorFilter;
  ImageFit fit;
  ImageRepeat repeat;

  sky.Image _resolvedImage;

  void _handleImageChanged(sky.Image resolvedImage) {
    assert(mounted);
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

  void syncConstructorArguments(ImageListener source) {
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
      super(key: new ObjectKey(renderBox));

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
    ancestor.detachChildRenderObject(this);
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
