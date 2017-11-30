// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';
import 'proxy_box.dart';

/// The interface used by [CustomPaint] (in the widgets library) and
/// [RenderCustomPaint] (in the rendering library).
///
/// To implement a custom painter, either subclass or implement this interface
/// to define your custom paint delegate. [CustomPaint] subclasses must
/// implement the [paint] and [shouldRepaint] methods, and may optionally also
/// implement the [hitTest] method.
///
/// The [paint] method is called whenever the custom object needs to be repainted.
///
/// The [shouldRepaint] method is called when a new instance of the class
/// is provided, to check if the new instance actually represents different
/// information.
///
/// The most efficient way to trigger a repaint is to either extend this class
/// and supply a `repaint` argument to the constructor of the [CustomPainter],
/// where that object notifies its listeners when it is time to repaint, or to
/// extend [Listenable] (e.g. via [ChangeNotifier]) and implement
/// [CustomPainter], so that the object itself provides the notifications
/// directly. In either case, the [CustomPaint] widget or [RenderCustomPaint]
/// render object will listen to the [Listenable] and repaint whenever the
/// animation ticks, avoiding both the build and layout phases of the pipeline.
///
/// The [hitTest] method is called when the user interacts with the underlying
/// render object, to determine if the user hit the object or missed it.
///
/// ## Sample code
///
/// This sample extends the same code shown for [RadialGradient] to create a
/// custom painter that paints a sky.
///
/// ```dart
/// class Sky extends CustomPainter {
///   @override
///   void paint(Canvas canvas, Size size) {
///     var rect = Offset.zero & size;
///     var gradient = new RadialGradient(
///       center: const Alignment(0.7, -0.6),
///       radius: 0.2,
///       colors: [const Color(0xFFFFFF00), const Color(0xFF0099FF)],
///       stops: [0.4, 1.0],
///     );
///     canvas.drawRect(
///       rect,
///       new Paint()..shader = gradient.createShader(rect),
///     );
///   }
///
///   @override
///   bool shouldRepaint(Sky oldDelegate) {
///     // Since this Sky painter has no fields, it always paints
///     // the same thing, and therefore we return false here. If
///     // we had fields (set from the constructor) then we would
///     // return true if any of them differed from the same
///     // fields on the oldDelegate.
///     return false;
///   }
/// }
/// ```
///
/// See also:
///
///  * [Canvas], the class that a custom painter uses to paint.
///  * [CustomPaint], the widget that uses [CustomPainter], and whose sample
///    code shows how to use the above `Sky` class.
///  * [RadialGradient], whose sample code section shows a different take
///    on the sample code above.
abstract class CustomPainter extends Listenable {
  /// Creates a custom painter.
  ///
  /// The painter will repaint whenever `repaint` notifies its listeners.
  const CustomPainter({ Listenable repaint }) : _repaint = repaint;

  final Listenable _repaint;

  /// Register a closure to be notified when it is time to repaint.
  ///
  /// The [CustomPainter] implementation merely forwards to the same method on
  /// the [Listenable] provided to the constructor in the `repaint` argument, if
  /// it was not null.
  @override
  void addListener(VoidCallback listener) => _repaint?.addListener(listener);

  /// Remove a previously registered closure from the list of closures that the
  /// object notifies when it is time to repaint.
  ///
  /// The [CustomPainter] implementation merely forwards to the same method on
  /// the [Listenable] provided to the constructor in the `repaint` argument, if
  /// it was not null.
  @override
  void removeListener(VoidCallback listener) => _repaint?.removeListener(listener);

  /// Called whenever the object needs to paint. The given [Canvas] has its
  /// coordinate space configured such that the origin is at the top left of the
  /// box. The area of the box is the size of the [size] argument.
  ///
  /// Paint operations should remain inside the given area. Graphical operations
  /// outside the bounds may be silently ignored, clipped, or not clipped.
  ///
  /// Implementations should be wary of correctly pairing any calls to
  /// [Canvas.save]/[Canvas.saveLayer] and [Canvas.restore], otherwise all
  /// subsequent painting on this canvas may be affected, with potentially
  /// hilarious but confusing results.
  ///
  /// To paint text on a [Canvas], use a [TextPainter].
  ///
  /// To paint an image on a [Canvas]:
  ///
  /// 1. Obtain an [ImageStream], for example by calling [ImageProvider.resolve]
  ///    on an [AssetImage] or [NetworkImage] object.
  ///
  /// 2. Whenever the [ImageStream]'s underlying [ImageInfo] object changes
  ///    (see [ImageStream.addListener]), create a new instance of your custom
  ///    paint delegate, giving it the new [ImageInfo] object.
  ///
  /// 3. In your delegate's [paint] method, call the [Canvas.drawImage],
  ///    [Canvas.drawImageRect], or [Canvas.drawImageNine] methods to paint the
  ///    [ImageInfo.image] object, applying the [ImageInfo.scale] value to
  ///    obtain the correct rendering size.
  void paint(Canvas canvas, Size size);

  List<CustomPainterSemantics> buildSemantics(Size size) {
    return const <CustomPainterSemantics>[];
  }

  /// Called whenever a new instance of the custom painter delegate class is
  /// provided to the [RenderCustomPaint] object, or any time that a new
  /// [CustomPaint] object is created with a new instance of the custom painter
  /// delegate class (which amounts to the same thing, because the latter is
  /// implemented in terms of the former).
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If the method returns false, then the [paint] call might be optimized
  /// away.
  ///
  /// It's possible that the [paint] method will get called even if
  /// [shouldRepaint] returns false (e.g. if an ancestor or descendant needed to
  /// be repainted). It's also possible that the [paint] method will get called
  /// without [shouldRepaint] being called at all (e.g. if the box changes
  /// size).
  ///
  /// If a custom delegate has a particularly expensive paint function such that
  /// repaints should be avoided as much as possible, a [RepaintBoundary] or
  /// [RenderRepaintBoundary] (or other render object with
  /// [RenderObject.isRepaintBoundary] set to true) might be helpful.
  bool shouldRepaint(covariant CustomPainter oldDelegate);

  /// Called whenever a hit test is being performed on an object that is using
  /// this custom paint delegate.
  ///
  /// The given point is relative to the same coordinate space as the last
  /// [paint] call.
  ///
  /// The default behavior is to consider all points to be hits for
  /// background painters, and no points to be hits for foreground painters.
  ///
  /// Return true if the given position corresponds to a point on the drawn
  /// image that should be considered a "hit", false if it corresponds to a
  /// point that should be considered outside the painted image, and null to use
  /// the default behavior.
  bool hitTest(Offset position) => null;

  @override
  String toString() => '${describeIdentity(this)}(${ _repaint?.toString() ?? "" })';
}

@immutable
class CustomPainterSemantics {
  const CustomPainterSemantics({
    this.key,
    @required this.rect,
    @required this.properties,
    this.transform,
    this.tags,
  });

  final Key key;
  final Rect rect;
  final Matrix4 transform;
  final SemanticsProperties properties;
  final Set<SemanticsTag> tags;
}

/// Provides a canvas on which to draw during the paint phase.
///
/// When asked to paint, [RenderCustomPaint] first asks its [painter] to paint
/// on the current canvas, then it paints its child, and then, after painting
/// its child, it asks its [foregroundPainter] to paint. The coordinate system of
/// the canvas matches the coordinate system of the [CustomPaint] object. The
/// painters are expected to paint within a rectangle starting at the origin and
/// encompassing a region of the given size. (If the painters paint outside
/// those bounds, there might be insufficient memory allocated to rasterize the
/// painting commands and the resulting behavior is undefined.)
///
/// Painters are implemented by subclassing or implementing [CustomPainter].
///
/// Because custom paint calls its painters during paint, you cannot mark the
/// tree as needing a new layout during the callback (the layout for this frame
/// has already happened).
///
/// Custom painters normally size themselves to their child. If they do not have
/// a child, they attempt to size themselves to the [preferredSize], which
/// defaults to [Size.zero].
///
/// See also:
///
///  * [CustomPainter], the class that custom painter delegates should extend.
///  * [Canvas], the API provided to custom painter delegates.
class RenderCustomPaint extends RenderProxyBox {
  /// Creates a render object that delegates its painting.
  RenderCustomPaint({
    CustomPainter painter,
    CustomPainter foregroundPainter,
    Size preferredSize: Size.zero,
    this.isComplex: false,
    this.willChange: false,
    RenderBox child,
  }) : assert(preferredSize != null),
       _painter = painter,
       _foregroundPainter = foregroundPainter,
       _preferredSize = preferredSize,
       super(child);

  /// The background custom paint delegate.
  ///
  /// This painter, if non-null, is called to paint behind the children.
  CustomPainter get painter => _painter;
  CustomPainter _painter;
  /// Set a new background custom paint delegate.
  ///
  /// If the new delegate is the same as the previous one, this does nothing.
  ///
  /// If the new delegate is the same class as the previous one, then the new
  /// delegate has its [CustomPainter.shouldRepaint] called; if the result is
  /// true, then the delegate will be called.
  ///
  /// If the new delegate is a different class than the previous one, then the
  /// delegate will be called.
  ///
  /// If the new value is null, then there is no background custom painter.
  set painter(CustomPainter value) {
    if (_painter == value)
      return;
    final CustomPainter oldPainter = _painter;
    _painter = value;
    _didUpdatePainter(_painter, oldPainter);
  }

  /// The foreground custom paint delegate.
  ///
  /// This painter, if non-null, is called to paint in front of the children.
  CustomPainter get foregroundPainter => _foregroundPainter;
  CustomPainter _foregroundPainter;
  /// Set a new foreground custom paint delegate.
  ///
  /// If the new delegate is the same as the previous one, this does nothing.
  ///
  /// If the new delegate is the same class as the previous one, then the new
  /// delegate has its [CustomPainter.shouldRepaint] called; if the result is
  /// true, then the delegate will be called.
  ///
  /// If the new delegate is a different class than the previous one, then the
  /// delegate will be called.
  ///
  /// If the new value is null, then there is no foreground custom painter.
  set foregroundPainter(CustomPainter value) {
    if (_foregroundPainter == value)
      return;
    final CustomPainter oldPainter = _foregroundPainter;
    _foregroundPainter = value;
    _didUpdatePainter(_foregroundPainter, oldPainter);
  }

  void _didUpdatePainter(CustomPainter newPainter, CustomPainter oldPainter) {
    if (newPainter == null) {
      assert(oldPainter != null); // We should be called only for changes.
      markNeedsPaint();
    } else if (oldPainter == null ||
        newPainter.runtimeType != oldPainter.runtimeType ||
        newPainter.shouldRepaint(oldPainter)) {
      markNeedsPaint();
    }
    if (attached) {
      oldPainter?.removeListener(markNeedsPaint);
      newPainter?.addListener(markNeedsPaint);
    }
  }

  /// The size that this [RenderCustomPaint] should aim for, given the layout
  /// constraints, if there is no child.
  ///
  /// Defaults to [Size.zero].
  ///
  /// If there's a child, this is ignored, and the size of the child is used
  /// instead.
  Size get preferredSize => _preferredSize;
  Size _preferredSize;
  set preferredSize(Size value) {
    assert(value != null);
    if (preferredSize == value)
      return;
    _preferredSize = value;
    markNeedsLayout();
  }

  /// Whether to hint that this layer's painting should be cached.
  ///
  /// The compositor contains a raster cache that holds bitmaps of layers in
  /// order to avoid the cost of repeatedly rendering those layers on each
  /// frame.  If this flag is not set, then the compositor will apply its own
  /// heuristics to decide whether the this layer is complex enough to benefit
  /// from caching.
  bool isComplex;

  /// Whether the raster cache should be told that this painting is likely
  /// to change in the next frame.
  bool willChange;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _painter?.addListener(markNeedsPaint);
    _foregroundPainter?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _painter?.removeListener(markNeedsPaint);
    _foregroundPainter?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    if (_foregroundPainter != null && (_foregroundPainter.hitTest(position) ?? false))
      return true;
    return super.hitTestChildren(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    return _painter != null && (_painter.hitTest(position) ?? true);
  }

  @override
  void performResize() {
    size = constraints.constrain(preferredSize);
  }

  void _paintWithPainter(Canvas canvas, Offset offset, CustomPainter painter) {
    int debugPreviousCanvasSaveCount;
    canvas.save();
    assert(() { debugPreviousCanvasSaveCount = canvas.getSaveCount(); return true; }());
    if (offset != Offset.zero)
      canvas.translate(offset.dx, offset.dy);
    painter.paint(canvas, size);
    assert(() {
      // This isn't perfect. For example, we can't catch the case of
      // someone first restoring, then setting a transform or whatnot,
      // then saving.
      // If this becomes a real problem, we could add logic to the
      // Canvas class to lock the canvas at a particular save count
      // such that restore() fails if it would take the lock count
      // below that number.
      final int debugNewCanvasSaveCount = canvas.getSaveCount();
      if (debugNewCanvasSaveCount > debugPreviousCanvasSaveCount) {
        throw new FlutterError(
          'The $painter custom painter called canvas.save() or canvas.saveLayer() at least '
          '${debugNewCanvasSaveCount - debugPreviousCanvasSaveCount} more '
          'time${debugNewCanvasSaveCount - debugPreviousCanvasSaveCount == 1 ? '' : 's' } '
          'than it called canvas.restore().\n'
          'This leaves the canvas in an inconsistent state and will probably result in a broken display.\n'
          'You must pair each call to save()/saveLayer() with a later matching call to restore().'
        );
      }
      if (debugNewCanvasSaveCount < debugPreviousCanvasSaveCount) {
        throw new FlutterError(
          'The $painter custom painter called canvas.restore() '
          '${debugPreviousCanvasSaveCount - debugNewCanvasSaveCount} more '
          'time${debugPreviousCanvasSaveCount - debugNewCanvasSaveCount == 1 ? '' : 's' } '
          'than it called canvas.save() or canvas.saveLayer().\n'
          'This leaves the canvas in an inconsistent state and will result in a broken display.\n'
          'You should only call restore() if you first called save() or saveLayer().'
        );
      }
      return debugNewCanvasSaveCount == debugPreviousCanvasSaveCount;
    }());
    canvas.restore();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_painter != null) {
      _paintWithPainter(context.canvas, offset, _painter);
      _setRasterCacheHints(context);
    }
    super.paint(context, offset);
    if (_foregroundPainter != null) {
      _paintWithPainter(context.canvas, offset, _foregroundPainter);
      _setRasterCacheHints(context);
    }
  }

  void _setRasterCacheHints(PaintingContext context) {
    if (isComplex)
      context.setIsComplexHint();
    if (willChange)
      context.setWillChangeHint();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
  }

  /// Describe the semantics of the picture painted by the [painter].
  List<SemanticsNode> _backgroundSemantics;

  /// Describe the semantics of the picture painted by the [foregroundPainter].
  List<SemanticsNode> _foregroundSemantics;

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    assert(children.isEmpty);

    final List<CustomPainterSemantics> backgroundSemantics = painter?.buildSemantics(size);
    _backgroundSemantics = _updateSemanticsChildren(_backgroundSemantics, backgroundSemantics);

    final List<CustomPainterSemantics> foregroundSemantics = foregroundPainter?.buildSemantics(size);
    _foregroundSemantics = _updateSemanticsChildren(_foregroundSemantics, foregroundSemantics);

    final bool hasBackgroundSemantics = _backgroundSemantics != null && _backgroundSemantics.isNotEmpty;
    final bool hasForegroundSemantics = _foregroundSemantics != null && _foregroundSemantics.isNotEmpty;

    if (hasBackgroundSemantics && hasForegroundSemantics) {
      super.assembleSemanticsNode(node, config, <SemanticsNode>[]
        ..addAll(_backgroundSemantics)
        ..addAll(_foregroundSemantics));
    } else if (hasBackgroundSemantics) {
      super.assembleSemanticsNode(node, config, _backgroundSemantics);
    } else if (hasForegroundSemantics) {
      super.assembleSemanticsNode(node, config, _foregroundSemantics);
    } else {
      super.assembleSemanticsNode(node, config, const <SemanticsNode>[]);
    }
  }

  /// Updates `semanticsChildren` from `newSemantics`.
  ///
  /// The algorithm tries to be as close to [RenderObjectElement.updateChildren]
  /// as possible, deviating only where the concepts diverge between widgets and
  /// semantics.
  static List<SemanticsNode> _updateSemanticsChildren(
    List<SemanticsNode> oldSemantics,
    List<CustomPainterSemantics> newChildSemantics,
  ) {
    oldSemantics = oldSemantics ?? const <SemanticsNode>[];
    newChildSemantics = newChildSemantics ?? const <CustomPainterSemantics>[];

    // Diffs the new child semantics list (newChildSemantics) with
    // the old list (this._semanticsChildren), and update this._semanticsChildren
    // accordingly.

    // The cases it tries to optimize for are:
    //  - the old list is empty
    //  - the lists are identical
    //  - there is an insertion or removal of one or more child nodes in
    //    only one place in the list
    // If a child with a key is in both lists, it will be synced.
    // Child nodes without keys might be synced but there is no guarantee.

    // The general approach is to sync the entire new list backwards, as follows:
    // 1. Walk the lists from the top, syncing nodes, until you no longer have
    //    matching nodes.
    // 2. Walk the lists from the bottom, without syncing nodes, until you no
    //    longer have matching nodes. We'll sync these nodes at the end. We
    //    don't sync them now because we want to sync all the nodes in order
    //    from beginning to end.
    // At this point we narrowed the old and new lists to the point
    // where the nodes no longer match.
    // 3. Walk the narrowed part of the old list to get the list of
    //    keys and sync null with non-keyed items.
    // 4. Walk the narrowed part of the new list forwards:
    //     * Sync non-keyed items with null
    //     * Sync keyed items with the source if it exists, else with null.
    // 5. Walk the bottom of the list again, syncing the nodes.
    // 6. Sync null with any items in the list of keys that are still
    //    mounted.

    assert(() {
      final Map<Key, int> keys = new HashMap<Key, int>();
      final StringBuffer errors = new StringBuffer();
      for (int i = 0; i < newChildSemantics.length; i += 1) {
        final CustomPainterSemantics child = newChildSemantics[i];
        if (child.key != null && keys.containsKey(child.key)) {
          errors.writeln(
            '- duplicate key ${child.key} found at position $i',
          );
        }
        keys[child.key] = i;
      }

      if (errors.isNotEmpty) {
        throw new AssertionError(
          'Failed to update the list of CustomPainterSemantics:\n'
          '$errors'
        );
      }

      return true;
    }());

    int newChildrenTop = 0;
    int oldChildrenTop = 0;
    int newChildrenBottom = newChildSemantics.length - 1;
    int oldChildrenBottom = oldSemantics.length - 1;

    final List<SemanticsNode> newChildren = oldSemantics.length == newChildSemantics.length
        ? oldSemantics
        : new List<SemanticsNode>(newChildSemantics.length);

    // Update the top of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
      final CustomPainterSemantics newSemantics = newChildSemantics[newChildrenTop];
      if (!_canUpdateSemanticsChild(oldChild, newSemantics))
        break;
      final SemanticsNode newChild = _updateSemanticsChild(oldChild, newSemantics);
      newChildren[newChildrenTop] = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Scan the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final SemanticsNode oldChild = oldSemantics[oldChildrenBottom];
      final CustomPainterSemantics newChild = newChildSemantics[newChildrenBottom];
      if (!_canUpdateSemanticsChild(oldChild, newChild))
        break;
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    // Scan the old children in the middle of the list.
    final bool haveOldChildren = oldChildrenTop <= oldChildrenBottom;
    Map<Key, SemanticsNode> oldKeyedChildren;
    if (haveOldChildren) {
      oldKeyedChildren = <Key, SemanticsNode>{};
      while (oldChildrenTop <= oldChildrenBottom) {
        final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
        if (oldChild.key != null)
          oldKeyedChildren[oldChild.key] = oldChild;
        oldChildrenTop += 1;
      }
    }

    // Update the middle of the list.
    while (newChildrenTop <= newChildrenBottom) {
      SemanticsNode oldChild;
      final CustomPainterSemantics newSemantics = newChildSemantics[newChildrenTop];
      if (haveOldChildren) {
        final Key key = newSemantics.key;
        if (key != null) {
          oldChild = oldKeyedChildren[key];
          if (oldChild != null) {
            if (_canUpdateSemanticsChild(oldChild, newSemantics)) {
              // we found a match!
              // remove it from oldKeyedChildren so we don't unsync it later
              oldKeyedChildren.remove(key);
            } else {
              // Not a match, let's pretend we didn't see it for now.
              oldChild = null;
            }
          }
        }
      }
      assert(oldChild == null || _canUpdateSemanticsChild(oldChild, newSemantics));
      final SemanticsNode newChild = _updateSemanticsChild(oldChild, newSemantics);
      assert(oldChild == newChild || oldChild == null);
      newChildren[newChildrenTop] = newChild;
      newChildrenTop += 1;
    }

    // We've scanned the whole list.
    assert(oldChildrenTop == oldChildrenBottom + 1);
    assert(newChildrenTop == newChildrenBottom + 1);
    assert(newChildSemantics.length - newChildrenTop == oldSemantics.length - oldChildrenTop);
    newChildrenBottom = newChildSemantics.length - 1;
    oldChildrenBottom = oldSemantics.length - 1;

    // Update the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
      final CustomPainterSemantics newSemantics = newChildSemantics[newChildrenTop];
      assert(_canUpdateSemanticsChild(oldChild, newSemantics));
      final SemanticsNode newChild = _updateSemanticsChild(oldChild, newSemantics);
      assert(oldChild == newChild);
      newChildren[newChildrenTop] = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    assert(() {
      for (SemanticsNode node in newChildren) {
        assert(node != null);
      }
      return true;
    }());

    return newChildren;
  }

  static bool _canUpdateSemanticsChild(SemanticsNode oldChild, CustomPainterSemantics newSemantics) {
    return oldChild.key == newSemantics.key;
  }

  static SemanticsNode _updateSemanticsChild(SemanticsNode oldChild, CustomPainterSemantics newSemantics) {
    final SemanticsNode newChild = oldChild ?? new SemanticsNode(
      key: newSemantics.key,
    );

    final SemanticsProperties properties = newSemantics.properties;
    final SemanticsConfiguration config = new SemanticsConfiguration();

    if (properties.checked != null) {
      config.isChecked = properties.checked;
    }
    if (properties.selected != null) {
      config.isSelected = properties.selected;
    }
    if (properties.button != null) {
      config.isButton = properties.button;
    }
    if (properties.label != null) {
      config.label = properties.label;
    }
    if (properties.value != null) {
      config.value = properties.value;
    }
    if (properties.increasedValue != null) {
      config.increasedValue = properties.increasedValue;
    }
    if (properties.decreasedValue != null) {
      config.decreasedValue = properties.decreasedValue;
    }
    if (properties.hint != null) {
      config.hint = properties.hint;
    }
    if (properties.textDirection != null) {
      config.textDirection = properties.textDirection;
    }
    if (properties.onTap != null) {
      config.addAction(SemanticsAction.tap, properties.onTap);
    }
    if (properties.onLongPress != null) {
      config.addAction(SemanticsAction.longPress, properties.onLongPress);
    }
    if (properties.onScrollLeft != null) {
      config.addAction(SemanticsAction.scrollLeft, properties.onScrollLeft);
    }
    if (properties.onScrollRight != null) {
      config.addAction(SemanticsAction.scrollRight, properties.onScrollRight);
    }
    if (properties.onScrollUp != null) {
      config.addAction(SemanticsAction.scrollUp, properties.onScrollUp);
    }
    if (properties.onScrollDown != null) {
      config.addAction(SemanticsAction.scrollDown, properties.onScrollDown);
    }
    if (properties.onIncrease != null) {
      config.addAction(SemanticsAction.increase, properties.onIncrease);
    }
    if (properties.onDecrease != null) {
      config.addAction(SemanticsAction.decrease, properties.onDecrease);
    }

    newChild.updateWith(
      config: config,
      // As of now CustomPainter does not support multiple tree levels.
      childrenInInversePaintOrder: const <SemanticsNode>[],
    );

    newChild
      ..rect = newSemantics.rect
      ..transform = newSemantics.transform
      ..tags = newSemantics.tags;

    return newChild;
  }
}
