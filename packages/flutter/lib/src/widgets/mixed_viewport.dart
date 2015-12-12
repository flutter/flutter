// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'basic.dart';

typedef Widget IndexedBuilder(BuildContext context, int index); // return null if index is greater than index of last entry
typedef void ExtentsUpdateCallback(double newExtents);
typedef void InvalidatorCallback(Iterable<int> indices);
typedef void InvalidatorAvailableCallback(InvalidatorCallback invalidator);

enum _ChangeDescription { none, scrolled, resized }

class MixedViewport extends RenderObjectWidget {
  MixedViewport({
    Key key,
    this.startOffset: 0.0,
    this.direction: ScrollDirection.vertical,
    this.builder,
    this.token,
    this.onExtentsUpdate,
    this.onInvalidatorAvailable
  }) : super(key: key);

  final double startOffset;
  final ScrollDirection direction;
  final IndexedBuilder builder;
  final Object token; // change this if the list changed (i.e. there are added, removed, or resorted items)
  final ExtentsUpdateCallback onExtentsUpdate;
  final InvalidatorAvailableCallback onInvalidatorAvailable; // call the callback this gives to invalidate sizes

  _MixedViewportElement createElement() => new _MixedViewportElement(this);

  // we don't pass constructor arguments to the RenderBlockViewport() because until
  // we know our children, the constructor arguments we could give have no effect
  RenderBlockViewport createRenderObject() => new RenderBlockViewport();

  _ChangeDescription evaluateChangesFrom(MixedViewport oldWidget) {
    if (direction != oldWidget.direction ||
        builder != oldWidget.builder ||
        token != oldWidget.token)
      return _ChangeDescription.resized;
    if (startOffset != oldWidget.startOffset)
      return _ChangeDescription.scrolled;
    return _ChangeDescription.none;
  }

  // all the actual work is done in the element
}

class _ChildKey {
  const _ChildKey(this.type, this.key);
  factory _ChildKey.fromWidget(Widget widget) => new _ChildKey(widget.runtimeType, widget.key);
  final Type type;
  final Key key;
  bool operator ==(dynamic other) {
    if (other is! _ChildKey)
      return false;
    final _ChildKey typedOther = other;
    return type == typedOther.type &&
           key == typedOther.key;
  }
  int get hashCode => hashValues(type, key);
  String toString() => "_ChildKey(type: $type, key: $key)";
}

class _MixedViewportElement extends RenderObjectElement<MixedViewport> {
  _MixedViewportElement(MixedViewport widget) : super(widget) {
    if (widget.onInvalidatorAvailable != null)
      widget.onInvalidatorAvailable(invalidate);
  }

  /// _childExtents contains the extents of each child from the top of the list
  /// up to the last one we've ever created.
  final List<double> _childExtents = <double>[];

  /// _childOffsets contains the offsets of the top of each child from the top
  /// of the list up to the last one we've ever created, and the offset of the
  /// end of the last one. The first value is always 0.0. If there are no
  /// children, that is the only value. The offset of the end of the last child
  /// created (the actual last child, if didReachLastChild is true), is also the
  /// distance from the top (left) of the first child to the bottom (right) of
  /// the last child created.
  final List<double> _childOffsets = <double>[0.0];

  /// Whether childOffsets includes the offset of the last child.
  bool _didReachLastChild = false;

  /// The index of the first child whose bottom edge is below the top of the
  /// viewport.
  int _firstVisibleChildIndex;

  /// The currently visibly children.
  Map<_ChildKey, Element> _childrenByKey = new Map<_ChildKey, Element>();

  /// The child offsets that we've been told are invalid.
  final Set<int> _invalidIndices = new Set<int>();

  /// Returns false if any of the previously-cached offsets have been marked as
  /// invalid and need to be updated.
  bool get isValid => _invalidIndices.length == 0;

  /// The constraints for which the current offsets are valid.
  BoxConstraints _lastLayoutConstraints;

  /// The last value that was sent to onExtentsUpdate.
  double _lastReportedExtents;

  RenderBlockViewport get renderObject => super.renderObject;

  /// Notify the BlockViewport that the children at indices have, or might have,
  /// changed size. Call this whenever the dimensions of a particular child
  /// change, so that the rendering will be updated accordingly. A pointer to
  /// this method is provided via the onInvalidatorAvailable callback.
  void invalidate(Iterable<int> indices) {
    assert(indices.length > 0);
    _invalidIndices.addAll(indices);
    renderObject.markNeedsLayout();
  }

  /// Forget all the known child offsets.
  void _resetCache() {
    _childExtents.clear();
    _childOffsets.clear();
    _childOffsets.add(0.0);
    _didReachLastChild = false;
    _invalidIndices.clear();
  }

  void visitChildren(ElementVisitor visitor) {
    for (Element child in _childrenByKey.values)
      visitor(child);
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    renderObject.callback = layout;
    renderObject.totalExtentCallback = _noIntrinsicExtent;
    renderObject.maxCrossAxisExtentCallback = _noIntrinsicExtent;
    renderObject.minCrossAxisExtentCallback = _noIntrinsicExtent;
  }

  void unmount() {
    renderObject.callback = null;
    renderObject.totalExtentCallback = null;
    renderObject.minCrossAxisExtentCallback = null;
    renderObject.maxCrossAxisExtentCallback = null;
    super.unmount();
  }

  double _noIntrinsicExtent(BoxConstraints constraints) {
    assert(() {
      'MixedViewport does not support returning intrinsic dimensions. ' +
      'Calculating the intrinsic dimensions would require walking the entire child list, ' +
      'which defeats the entire point of having a lazily-built list of children.';
      return false;
    });
    return null;
  }

  static const Object _omit = const Object(); // used as a slot when it's not yet time to attach the child

  void update(MixedViewport newWidget) {
    _ChangeDescription changes = newWidget.evaluateChangesFrom(widget);
    super.update(newWidget);
    if (changes == _ChangeDescription.resized)
      _resetCache();
    if (changes != _ChangeDescription.none || !isValid) {
      renderObject.markNeedsLayout();
    } else {
      // We have to reinvoke our builders because they might return new data.
      // Consider a stateful component that owns us. The builder it gives us
      // includes some of the state from that component. The component calls
      // setState() on itself. It rebuilds. Part of that involves rebuilding
      // us, but now what? If we don't reinvoke the builders. then they will
      // not be rebuilt, and so the new state won't be used.
      // Note that if the builders are to change so much that the _sizes_ of
      // the children would change, then the parent must change the 'token'.
      if (!renderObject.needsLayout)
        reinvokeBuilders();
    }
  }

  void reinvokeBuilders() {
    // we just need to redraw our existing widgets as-is
    if (_childrenByKey.length > 0) {
      assert(_firstVisibleChildIndex >= 0);
      assert(renderObject != null);
      final int startIndex = _firstVisibleChildIndex;
      int lastIndex = startIndex + _childrenByKey.length - 1;
      Element nextSibling = null;
      for (int index = lastIndex; index >= startIndex; index -= 1) {
        final Widget newWidget = _buildWidgetAt(index);
        final _ChildKey key = new _ChildKey.fromWidget(newWidget);
        final Element oldElement = _childrenByKey[key];
        assert(oldElement != null);
        final Element newElement = updateChild(oldElement, newWidget, nextSibling);
        assert(newElement != null);
        _childrenByKey[key] = newElement;
        // Verify that it hasn't changed size.
        // If this assertion fires, it means you didn't call "invalidate"
        // before changing the size of one of your items.
        assert(_debugIsSameSize(newElement, index, _lastLayoutConstraints));
        nextSibling = newElement;
      }
    }
  }

  void layout(BoxConstraints constraints) {
    if (constraints != _lastLayoutConstraints) {
      _resetCache();
      _lastLayoutConstraints = constraints;
    }
    BuildableElement.lockState(() {
      _doLayout(constraints);
    }, building: true);
    if (widget.onExtentsUpdate != null) {
      final double newExtents = _didReachLastChild ? _childOffsets.last : null;
      if (newExtents != _lastReportedExtents) {
        _lastReportedExtents = newExtents;
        widget.onExtentsUpdate(_lastReportedExtents);
      }
    }
  }

  /// Binary search to find the index of the child responsible for rendering a given pixel
  int _findIndexForOffsetBeforeOrAt(double offset) {
    int left = 0;
    int right = _childOffsets.length - 1;
    while (right >= left) {
      int middle = left + ((right - left) ~/ 2);
      if (_childOffsets[middle] < offset) {
        left = middle + 1;
      } else if (_childOffsets[middle] > offset) {
        right = middle - 1;
      } else {
        return middle;
      }
    }
    return right;
  }

  /// Calls the builder. This is for the case where you don't know if you have a child at this index.
  Widget _maybeBuildWidgetAt(int index) {
    if (widget.builder == null)
      return null;
    final Widget newWidget = widget.builder(this, index);
    assert(() {
      'Every widget in a list must have a list-unique key.';
      return newWidget == null || newWidget.key != null;
    });
    return newWidget;
  }

  /// Calls the builder. This is for the case where you know that you should have a child there.
  Widget _buildWidgetAt(int index) {
    final Widget newWidget = widget.builder(this, index);
    assert(newWidget != null);
    assert(newWidget.key != null); // every widget in a list must have a list-unique key
    return newWidget;
  }

  /// Given an element configuration, inflates the element, updating the existing one if there was one.
  /// Returns the resulting element.
  Element _inflateOrUpdateWidget(Widget newWidget) {
    final _ChildKey key = new _ChildKey.fromWidget(newWidget);
    final Element oldElement = _childrenByKey[key];
    final Element newElement = updateChild(oldElement, newWidget, _omit);
    assert(newElement != null);
    return newElement;
  }

  // Build the widget at index.
  Element _getElement(int index, BoxConstraints innerConstraints) {
    assert(index <= _childOffsets.length - 1);
    final Widget newWidget = _buildWidgetAt(index);
    final Element newElement = _inflateOrUpdateWidget(newWidget);
    return newElement;
  }

  // Build the widget at index.
  Element _maybeGetElement(int index, BoxConstraints innerConstraints) {
    assert(index <= _childOffsets.length - 1);
    final Widget newWidget = _maybeBuildWidgetAt(index);
    if (newWidget == null)
      return null;
    final Element newElement = _inflateOrUpdateWidget(newWidget);
    return newElement;
  }

  // Build the widget at index, handling the case where there is no such widget.
  // Update the offset for that widget.
  Element _getElementAtLastKnownOffset(int index, BoxConstraints innerConstraints) {

    // Inflate the new widget; if there isn't one, abort early.
    assert(index == _childOffsets.length - 1);
    final Widget newWidget = _maybeBuildWidgetAt(index);
    if (newWidget == null)
      return null;
    final Element newElement = _inflateOrUpdateWidget(newWidget);

    // Update the offsets based on the newElement's dimensions.
    final double newExtent = _getElementExtent(newElement, innerConstraints);
    _childExtents.add(newExtent);
    _childOffsets.add(_childOffsets[index] + newExtent);
    assert(_childExtents.length == _childOffsets.length - 1);

    return newElement;
  }

  /// Returns the intrinsic size of the given element in the scroll direction
  double _getElementExtent(Element element, BoxConstraints innerConstraints) {
    final RenderBox childRenderObject = element.renderObject;
    switch (widget.direction) {
      case ScrollDirection.vertical:
        return childRenderObject.getMaxIntrinsicHeight(innerConstraints);
      case ScrollDirection.horizontal:
        return childRenderObject.getMaxIntrinsicWidth(innerConstraints);
      case ScrollDirection.both:
        assert(false); // we don't support ScrollDirection.both, see issue 888
        return double.NAN;
    }
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    switch (widget.direction) {
      case ScrollDirection.vertical:
        return new BoxConstraints.tightFor(width: constraints.constrainWidth());
      case ScrollDirection.horizontal:
        return new BoxConstraints.tightFor(height: constraints.constrainHeight());
      case ScrollDirection.both:
        assert(false); // we don't support ScrollDirection.both, see issue 888
        return null;
    }
  }

  /// This compares the offsets we had for an element with its current
  /// intrinsic dimensions.
  bool _debugIsSameSize(Element element, int index, BoxConstraints constraints) {
    assert(_invalidIndices.isEmpty);
    BoxConstraints innerConstraints = _getInnerConstraints(constraints);
    double newExtent = _getElementExtent(element, innerConstraints);
    bool result = _childExtents[index] == newExtent;
    if (!result)
      debugPrint("Element $element at index $index was size ${_childExtents[index]} but is now size $newExtent yet no invalidate() was received to that effect");
    return result;
  }

  /// This is the core lazy-build algorithm. It builds widgets incrementally
  /// from index 0 until it has built enough widgets to cover itself, and
  /// discards any widgets that are not displayed.
  void _doLayout(BoxConstraints constraints) {
    Map<_ChildKey, Element> newChildren = new Map<_ChildKey, Element>();
    Map<int, Element> builtChildren = new Map<int, Element>();

    // Establish the start and end offsets based on our current constraints.
    double extent;
    switch (widget.direction) {
      case ScrollDirection.vertical:
        extent = constraints.maxHeight;
        assert(extent < double.INFINITY &&
          'There is no point putting a lazily-built vertical MixedViewport inside a box with infinite internal ' +
          'height (e.g. inside something else that scrolls vertically), because it would then just eagerly build ' +
          'all the children. You probably want to put the MixedViewport inside a Container with a fixed height.' is String);
        break;
      case ScrollDirection.horizontal:
        extent = constraints.maxWidth;
        assert(extent < double.INFINITY &&
          'There is no point putting a lazily-built horizontal MixedViewport inside a box with infinite internal ' +
          'width (e.g. inside something else that scrolls horizontally), because it would then just eagerly build ' +
          'all the children. You probably want to put the MixedViewport inside a Container with a fixed width.' is String);
        break;
      case ScrollDirection.both: assert(false); // we don't support ScrollDirection.both, see issue 888
    }
    final double endOffset = widget.startOffset + extent;

    // Create the constraints that we will use to measure the children.
    final BoxConstraints innerConstraints = _getInnerConstraints(constraints);

    // Before doing the actual layout, fix the offsets for the widgets whose
    // size has apparently changed.
    if (!isValid) {
      assert(_childOffsets.length > 0);
      assert(_childOffsets.length == _childExtents.length + 1);
      List<int> invalidIndices = _invalidIndices.toList();
      invalidIndices.sort();
      for (int i = 0; i < invalidIndices.length; i += 1) {

        // Determine the indices for this pass.
        final int widgetIndex = invalidIndices[i];
        if (widgetIndex >= _childExtents.length)
          break; // we don't have that child, so there's nothing to invalidate
        int endIndex; // the last index into _childOffsets that we want to update this round
        if (i == invalidIndices.length - 1) {
          // This is the last invalid index. Update all the remaining entries in _childOffsets.
          endIndex = _childOffsets.length - 1;
        } else {
          endIndex = invalidIndices[i + 1];
          if (endIndex > _childOffsets.length - 1)
            endIndex = _childOffsets.length - 1; // no point updating beyond the last offset we know of
        }
        assert(widgetIndex >= 0);
        assert(endIndex < _childOffsets.length);
        assert(widgetIndex < endIndex);

        // Inflate the widget or update the existing element, as necessary.
        final Element newElement = _getElement(widgetIndex, innerConstraints);

        // Update the offsets based on the newElement's dimensions.
        _childExtents[widgetIndex] = _getElementExtent(newElement, innerConstraints);
        for (int j = widgetIndex + 1; j <= endIndex; j++)
          _childOffsets[j] = _childOffsets[j - 1] + _childExtents[j - 1];
        assert(_childOffsets.length == _childExtents.length + 1);

        // Decide if it's visible.
        final _ChildKey key = new _ChildKey.fromWidget(newElement.widget);
        final bool isVisible = _childOffsets[widgetIndex] < endOffset && _childOffsets[widgetIndex + 1] >= widget.startOffset;
        if (isVisible) {
          // Keep it.
          newChildren[key] = newElement;
          builtChildren[widgetIndex] = newElement;
        } else {
          // Drop it.
          _childrenByKey.remove(key);
          updateChild(newElement, null, null);
        }

      }
      _invalidIndices.clear();
    }

    // Decide what the first child to render should be (startIndex), if any (haveChildren).
    int startIndex;
    bool haveChildren;
    if (endOffset < 0.0) {
      // We're so far scrolled up that nothing is visible.
      haveChildren = false;
    } else if (widget.startOffset <= 0.0) {
      startIndex = 0;
      // If we're scrolled up past the top, then our first visible widget, if
      // any, is the first widget.
      if (_childExtents.length > 0) {
        haveChildren = true;
      } else {
        final Element element = _getElementAtLastKnownOffset(startIndex, innerConstraints);
        if (element != null) {
          newChildren[new _ChildKey.fromWidget(element.widget)] = element;
          builtChildren[startIndex] = element;
          haveChildren = true;
        } else {
          haveChildren = false;
          _didReachLastChild = true;
        }
      }
    } else {
      // We're at some sane (not higher than the top) scroll offset.
      // See if we can already find the offset in our cache.
      startIndex = _findIndexForOffsetBeforeOrAt(widget.startOffset);
      if (startIndex < _childExtents.length) {
        // We already know of a child that would be visible at this offset.
        haveChildren = true;
      } else {
        // We don't have an offset on the list that is beyond the start offset.
        assert(_childOffsets.last <= widget.startOffset);
        // Fill the list until this isn't true or until we know that the
        // list is complete (and thus we are overscrolled).
        while (true) {
          // Get the next element and cache its offset.
          final Element element = _getElementAtLastKnownOffset(startIndex, innerConstraints);
          if (element == null) {
            // Reached the end of the list. We are so far overscrolled, there's nothing to show.
            _didReachLastChild = true;
            haveChildren = false;
            break;
          }
          final _ChildKey key = new _ChildKey.fromWidget(element.widget);
          if (_childOffsets.last > widget.startOffset) {
            // This element is visible! It must thus be our first visible child.
            newChildren[key] = element;
            builtChildren[startIndex] = element;
            haveChildren = true;
            break;
          }
          // This element is not visible. Drop the inflated element.
          // (We've already cached its offset for later use.)
          _childrenByKey.remove(key);
          updateChild(element, null, null);
          startIndex += 1;
          assert(startIndex == _childExtents.length);
        }
        assert(haveChildren == _childOffsets.last > widget.startOffset);
        assert(() {
          if (haveChildren) {
            // We found a child to render. It's the last one for which we have an
            // offset in _childOffsets.
            // If we're here, we have at least one child, so our list has
            // at least two offsets, the top of the child and the bottom
            // of the child.
            assert(_childExtents.length >= 1);
            assert(_childOffsets.length == _childExtents.length + 1);
            assert(startIndex == _childExtents.length - 1);
          }
          return true;
        });
      }
    }
    assert(haveChildren != null);
    assert(haveChildren || _didReachLastChild || endOffset < 0.0);
    assert(startIndex >= 0);
    assert(!haveChildren || startIndex < _childExtents.length);

    // Build the other widgets that are visible.
    int index = startIndex;
    if (haveChildren) {
      // Update the renderObject configuration
      switch (widget.direction) {
        case ScrollDirection.vertical:
          renderObject.direction = BlockDirection.vertical;
          break;
        case ScrollDirection.horizontal:
          renderObject.direction = BlockDirection.horizontal;
          break;
        case ScrollDirection.both: assert(false); // we don't support ScrollDirection.both, see issue 888
      }
      renderObject.startOffset = _childOffsets[index] - widget.startOffset;
      // Build all the widgets we still need.
      while (_childOffsets[index] < endOffset) {
        if (!builtChildren.containsKey(index)) {
          Element element = _maybeGetElement(index, innerConstraints);
          if (element == null) {
            _didReachLastChild = true;
            break;
          }
          if (index == _childExtents.length) {
            // Remember this element's offset.
            final double newExtent = _getElementExtent(element, innerConstraints);
            _childExtents.add(newExtent);
            _childOffsets.add(_childOffsets[index] + newExtent);
            assert(_childOffsets.length == _childExtents.length + 1);
          } else {
            // Verify that it hasn't changed size.
            // If this assertion fires, it means you didn't call "invalidate"
            // before changing the size of one of your items.
            assert(_debugIsSameSize(element, index, constraints));
          }
          // Remember the element for when we place the children.
          final _ChildKey key = new _ChildKey.fromWidget(element.widget);
          newChildren[key] = element;
          builtChildren[index] = element;
        }
        assert(builtChildren[index] != null);
        index += 1;
      }
    }

    // Remove any old children.
    for (_ChildKey oldChildKey in _childrenByKey.keys) {
      if (!newChildren.containsKey(oldChildKey))
        updateChild(_childrenByKey[oldChildKey], null, null);
    }

    if (haveChildren) {
      // Place all our children in our RenderObject.
      // All the children we are placing are in builtChildren and newChildren.
      // We will walk them backwards so we can set the slots at the same time.
      Element nextSibling = null;
      while (index > startIndex) {
        index -= 1;
        final Element element = builtChildren[index];
        if (element.slot != nextSibling)
          updateSlotForChild(element, nextSibling);
        nextSibling = element;
      }
    }

    // Update our internal state.
    _childrenByKey = newChildren;
    _firstVisibleChildIndex = startIndex;
  }

  void updateSlotForChild(Element element, dynamic newSlot) {
    assert(newSlot == null || newSlot == _omit || newSlot is Element);
    super.updateSlotForChild(element, newSlot);
  }

  void insertChildRenderObject(RenderObject child, dynamic slot) {
    if (slot == _omit)
      return;
    assert(slot == null || slot is Element);
    RenderObject nextSibling = slot?.renderObject;
    renderObject.add(child, before: nextSibling);
  }

  void moveChildRenderObject(RenderObject child, dynamic slot) {
    if (slot == _omit)
      return;
    assert(slot == null || slot is Element);
    RenderObject nextSibling = slot?.renderObject;
    assert(nextSibling == null || nextSibling.parent == renderObject);
    if (child.parent == renderObject)
      renderObject.move(child, before: nextSibling);
    else
      renderObject.add(child, before: nextSibling);
  }

  void removeChildRenderObject(RenderObject child) {
    if (child.parent != renderObject)
      return; // probably had slot == _omit when inserted
    renderObject.remove(child);
  }

}
