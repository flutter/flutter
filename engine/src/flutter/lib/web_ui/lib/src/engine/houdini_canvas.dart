// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(yjbanov): optimization opportunities (see also houdini_painter.js)
// - collapse non-drawing paint operations
// - avoid producing DOM-based clips if there is no text
// - evaluate using stylesheets for static CSS properties
// - evaluate reusing houdini canvases
// @dart = 2.6
part of engine;

/// A canvas that renders to a combination of HTML DOM and CSS Custom Paint API.
///
/// This canvas produces paint commands for houdini_painter.js to apply. This
/// class must be kept in sync with houdini_painter.js.
class HoudiniCanvas extends EngineCanvas with SaveElementStackTracking {
  @override
  final html.Element rootElement = html.Element.tag('flt-houdini');

  /// The rectangle positioned relative to the parent layer's coordinate system
  /// where this canvas paints.
  ///
  /// Painting outside the bounds of this rectangle is cropped.
  final ui.Rect bounds;

  HoudiniCanvas(this.bounds) {
    // TODO(yjbanov): would it be faster to specify static values in a
    //                stylesheet and let the browser apply them?
    rootElement.style
      ..position = 'absolute'
      ..top = '0'
      ..left = '0'
      ..width = '${bounds.size.width}px'
      ..height = '${bounds.size.height}px'
      ..backgroundImage = 'paint(flt)';
  }

  /// Prepare to reuse this canvas by clearing it's current contents.
  @override
  void clear() {
    super.clear();
    _serializedCommands = <List<dynamic>>[];
    // TODO(yjbanov): we should measure if reusing old elements is beneficial.
    domRenderer.clearDom(rootElement);
  }

  /// Paint commands serialized for sending to the CSS custom painter.
  List<List<dynamic>> _serializedCommands = <List<dynamic>>[];

  void apply(PaintCommand command) {
    // Some commands are applied purely in HTML DOM and do not need to be
    // serialized.
    if (command is! PaintDrawParagraph &&
        command is! PaintDrawImageRect &&
        command is! PaintTransform) {
      command.serializeToCssPaint(_serializedCommands);
    }
    command.apply(this);
  }

  /// Sends the paint commands to the CSS custom painter for painting.
  void commit() {
    if (_serializedCommands.isNotEmpty) {
      rootElement.style.setProperty('--flt', json.encode(_serializedCommands));
    } else {
      rootElement.style.removeProperty('--flt');
    }
  }

  @override
  void clipRect(ui.Rect rect) {
    final html.Element clip = html.Element.tag('flt-clip-rect');
    final String cssTransform = matrix4ToCssTransform(
        transformWithOffset(currentTransform, ui.Offset(rect.left, rect.top)));
    clip.style
      ..overflow = 'hidden'
      ..position = 'absolute'
      ..transform = cssTransform
      ..width = '${rect.width}px'
      ..height = '${rect.height}px';

    // The clipping element will translate the coordinate system as well, which
    // is not what a clip should do. To offset that we translate in the opposite
    // direction.
    super.translate(-rect.left, -rect.top);

    currentElement.append(clip);
    pushElement(clip);
  }

  @override
  void clipRRect(ui.RRect rrect) {
    final ui.Rect outer = rrect.outerRect;
    if (rrect.isRect) {
      clipRect(outer);
      return;
    }

    final html.Element clip = html.Element.tag('flt-clip-rrect');
    final html.CssStyleDeclaration style = clip.style;
    style
      ..overflow = 'hidden'
      ..position = 'absolute'
      ..transform = 'translate(${outer.left}px, ${outer.right}px)'
      ..width = '${outer.width}px'
      ..height = '${outer.height}px';

    if (rrect.tlRadiusY == rrect.tlRadiusX) {
      style.borderTopLeftRadius = '${rrect.tlRadiusX}px';
    } else {
      style.borderTopLeftRadius = '${rrect.tlRadiusX}px ${rrect.tlRadiusY}px';
    }

    if (rrect.trRadiusY == rrect.trRadiusX) {
      style.borderTopRightRadius = '${rrect.trRadiusX}px';
    } else {
      style.borderTopRightRadius = '${rrect.trRadiusX}px ${rrect.trRadiusY}px';
    }

    if (rrect.brRadiusY == rrect.brRadiusX) {
      style.borderBottomRightRadius = '${rrect.brRadiusX}px';
    } else {
      style.borderBottomRightRadius =
          '${rrect.brRadiusX}px ${rrect.brRadiusY}px';
    }

    if (rrect.blRadiusY == rrect.blRadiusX) {
      style.borderBottomLeftRadius = '${rrect.blRadiusX}px';
    } else {
      style.borderBottomLeftRadius =
          '${rrect.blRadiusX}px ${rrect.blRadiusY}px';
    }

    // The clipping element will translate the coordinate system as well, which
    // is not what a clip should do. To offset that we translate in the opposite
    // direction.
    super.translate(-rrect.left, -rrect.top);

    currentElement.append(clip);
    pushElement(clip);
  }

  @override
  void clipPath(ui.Path path) {
    // TODO(yjbanov): implement.
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    // Drawn using CSS Paint.
  }

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, SurfacePaintData paint) {
    // Drawn using CSS Paint.
  }

  @override
  void drawPaint(SurfacePaintData paint) {
    // Drawn using CSS Paint.
  }

  @override
  void drawRect(ui.Rect rect, SurfacePaintData paint) {
    // Drawn using CSS Paint.
  }

  @override
  void drawRRect(ui.RRect rrect, SurfacePaintData paint) {
    // Drawn using CSS Paint.
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, SurfacePaintData paint) {
    // Drawn using CSS Paint.
  }

  @override
  void drawOval(ui.Rect rect, SurfacePaintData paint) {
    // Drawn using CSS Paint.
  }

  @override
  void drawCircle(ui.Offset c, double radius, SurfacePaintData paint) {
    // Drawn using CSS Paint.
  }

  @override
  void drawPath(ui.Path path, SurfacePaintData paint) {
    // Drawn using CSS Paint.
  }

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    // Drawn using CSS Paint.
  }

  @override
  void drawImage(ui.Image image, ui.Offset p, SurfacePaintData paint) {
    // TODO(yjbanov): implement.
  }

  @override
  void drawImageRect(
      ui.Image image, ui.Rect src, ui.Rect dst, SurfacePaintData paint) {
    // TODO(yjbanov): implement src rectangle
    final HtmlImage htmlImage = image;
    final html.Element imageBox = html.Element.tag('flt-img');
    final String cssTransform = matrix4ToCssTransform(
        transformWithOffset(currentTransform, ui.Offset(dst.left, dst.top)));
    imageBox.style
      ..position = 'absolute'
      ..transformOrigin = '0 0 0'
      ..width = '${dst.width.toInt()}px'
      ..height = '${dst.height.toInt()}px'
      ..transform = cssTransform
      ..backgroundImage = 'url(${htmlImage.imgElement.src})'
      ..backgroundRepeat = 'norepeat'
      ..backgroundSize = '${dst.width}px ${dst.height}px';
    currentElement.append(imageBox);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    final html.Element paragraphElement =
        _drawParagraphElement(paragraph, offset, transform: currentTransform);
    currentElement.append(paragraphElement);
  }

  @override
  void drawVertices(
      ui.Vertices vertices, ui.BlendMode blendMode, SurfacePaintData paint) {
    // TODO(flutter_web): implement.
  }

  @override
  void drawPoints(ui.PointMode pointMode, Float32List points,
      double strokeWidth, ui.Color color) {
    // TODO(flutter_web): implement.
  }

  @override
  void endOfPaint() {}
}

class _SaveElementStackEntry {
  _SaveElementStackEntry({
    @required this.savedElement,
    @required this.transform,
  });

  final html.Element savedElement;
  final Matrix4 transform;
}

/// Provides save stack tracking functionality to implementations of
/// [EngineCanvas].
mixin SaveElementStackTracking on EngineCanvas {
  static final Vector3 _unitZ = Vector3(0.0, 0.0, 1.0);

  final List<_SaveElementStackEntry> _saveStack = <_SaveElementStackEntry>[];

  /// The element at the top of the element stack, or [rootElement] if the stack
  /// is empty.
  html.Element get currentElement =>
      _elementStack.isEmpty ? rootElement : _elementStack.last;

  /// The stack that maintains the DOM elements used to express certain paint
  /// operations, such as clips.
  final List<html.Element> _elementStack = <html.Element>[];

  /// Pushes the [element] onto the element stack for the purposes of applying
  /// a paint effect using a DOM element, e.g. for clipping.
  ///
  /// The [restore] method automatically pops the element off the stack.
  void pushElement(html.Element element) {
    _elementStack.add(element);
  }

  /// Empties the save stack and the element stack, and resets the transform
  /// and clip parameters.
  ///
  /// Classes that override this method must call `super.clear()`.
  @override
  void clear() {
    _saveStack.clear();
    _elementStack.clear();
    _currentTransform = Matrix4.identity();
  }

  /// The current transformation matrix.
  Matrix4 get currentTransform => _currentTransform;
  Matrix4 _currentTransform = Matrix4.identity();

  /// Saves current clip and transform on the save stack.
  ///
  /// Classes that override this method must call `super.save()`.
  @override
  void save() {
    _saveStack.add(_SaveElementStackEntry(
      savedElement: currentElement,
      transform: _currentTransform.clone(),
    ));
  }

  /// Restores current clip and transform from the save stack.
  ///
  /// Classes that override this method must call `super.restore()`.
  @override
  void restore() {
    if (_saveStack.isEmpty) {
      return;
    }
    final _SaveElementStackEntry entry = _saveStack.removeLast();
    _currentTransform = entry.transform;

    // Pop out of any clips.
    while (currentElement != entry.savedElement) {
      _elementStack.removeLast();
    }
  }

  /// Multiplies the [currentTransform] matrix by a translation.
  ///
  /// Classes that override this method must call `super.translate()`.
  @override
  void translate(double dx, double dy) {
    _currentTransform.translate(dx, dy);
  }

  /// Scales the [currentTransform] matrix.
  ///
  /// Classes that override this method must call `super.scale()`.
  @override
  void scale(double sx, double sy) {
    _currentTransform.scale(sx, sy);
  }

  /// Rotates the [currentTransform] matrix.
  ///
  /// Classes that override this method must call `super.rotate()`.
  @override
  void rotate(double radians) {
    _currentTransform.rotate(_unitZ, radians);
  }

  /// Skews the [currentTransform] matrix.
  ///
  /// Classes that override this method must call `super.skew()`.
  @override
  void skew(double sx, double sy) {
    // DO NOT USE Matrix4.skew(sx, sy)! It treats sx and sy values as radians,
    // but in our case they are transform matrix values.
    final Matrix4 skewMatrix = Matrix4.identity();
    final Float32List storage = skewMatrix.storage;
    storage[1] = sy;
    storage[4] = sx;
    _currentTransform.multiply(skewMatrix);
  }

  /// Multiplies the [currentTransform] matrix by another matrix.
  ///
  /// Classes that override this method must call `super.transform()`.
  @override
  void transform(Float32List matrix4) {
    _currentTransform.multiply(Matrix4.fromFloat32List(matrix4));
  }
}
