// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, RRect, Path, hashValues;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

typedef AnnotationSearch<S> = bool Function(AnnotationResult<S> result, Offset localPosition);

/// Data collected during an annotation search about a specific annotation.
///
/// See also:
///
///  * [AnnotationResult], which is a collection of this class.
@immutable
class AnnotationEntry<T> {
  /// Create an entry of found annotation by providing the object and related
  /// information.
  const AnnotationEntry({
    @required this.annotation,
    @required this.localPosition,
  }) : assert(localPosition != null);

  /// The annotation object that is found.
  final T annotation;

  /// The target location described by the local coordinate space of the
  /// annotator.
  final Offset localPosition;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AnnotationEntry<T>
        && other.annotation == annotation
        && other.localPosition == localPosition;
  }

  @override
  int get hashCode {
    return hashValues(annotation, localPosition);
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'AnnotationEntry')}(annotation: $annotation, localPostion: $localPosition)';
  }
}

/// The result of an annotation search.
///
/// See also:
///
///  * [AnnotationEntry], which is the information for a specific annotation.
class AnnotationResult<T> {
  /// Creates and configure an empty annotation result.
  ///
  /// The `stopsAtFirstResult` defaults to false.
  AnnotationResult({this.stopsAtFirstResult = false});

  /// Whether the search should stop at the first qualified result.
  ///
  /// Set this to true if only the first result is needed, thus being more
  /// efficient. Otherwise, the search will walk the entire tree.
  final bool stopsAtFirstResult;

  /// Add a new entry to the end of the result.
  ///
  /// Usually, entries should be added in order from most specific to least
  /// specific, typically during an upward walk of the tree.
  void add(AnnotationEntry<T> entry) => _entries.add(entry);

  /// An unmodifiable list of [AnnotationEntry] objects recorded.
  ///
  /// The first entry is the most specific, typically the one at the leaf of
  /// tree.
  Iterable<AnnotationEntry<T>> get entries => _entries;

  /// An unmodifiable list of annotations recorded.
  ///
  /// The first entry is the most specific, typically the one at the leaf of
  /// tree.
  ///
  /// It is similar to [entries] but does not contain other information.
  Iterable<T> get annotations sync* {
    for (final AnnotationEntry<T> entry in _entries)
      yield entry.annotation;
  }
  final List<AnnotationEntry<T>> _entries = <AnnotationEntry<T>>[];
}

/// A node in the annotator tree.
///
/// During painting, the render tree generates a tree of annotators that do not
/// directly affect painting, but associtate specific regions on the screen with
/// metadata that can be searched between frames. This class is the base class for
/// all annotators.
///
/// Some annotators can have their properties mutated, or generate result only at
/// the time of searching. An annotator will not notify anyone if its property or
/// the result it will generate has changed.
abstract class Annotator extends AbstractNode with DiagnosticableTreeMixin {
  @override
  ContainerAnnotator get parent => super.parent as ContainerAnnotator;

  /// This Annotator's next sibling in the parent Annotator's child list.
  Annotator get nextSibling => _nextSibling;
  Annotator _nextSibling;

  /// This Annotator's previous sibling in the parent Annotator's child list.
  Annotator get previousSibling => _previousSibling;
  Annotator _previousSibling;

  /// Removes this layer from its parent annotator's child list.
  ///
  /// This has no effect if the annotator's parent is already null.
  @mustCallSuper
  void remove() {
    parent?.removeChild(this);
  }

  /// Search this annotator and its subtree for annotations of type `S` at the
  /// location described by `localPosition`.
  ///
  /// The annotations are searched in post-order, and should result in an order
  /// from visually front to back. Annotations must meet the given restrictions,
  /// such as type and position.
  ///
  /// The [result] parameter is where the method outputs the resulting
  /// annotations. New annotations found during the walk are added to the tail.
  /// The [result] also contains configurations of this search, such as
  /// whether the search should stop at the first result.
  ///
  /// The return value indicates the opacity of the subtree, including this
  /// annotator, in terms of annotation of this type. If the method returns true,
  /// then the search has been absorbed and this annotator's parent should skip
  /// the siblings behind this annotator. If the return value is false, then the
  /// parent might continue with other siblings.
  bool search<S>(AnnotationResult<S> result, Offset localPosition);
}

/// The base class for annotators that have a list of children.
abstract class ContainerAnnotator extends Annotator {
  /// The first composited Annotator in this Annotator's child list.
  Annotator get firstChild => _firstChild;
  Annotator _firstChild;

  /// The last composited Annotator in this Annotator's child list.
  Annotator get lastChild => _lastChild;
  Annotator _lastChild;

  /// Returns whether this Annotator has at least one child Annotator.
  bool get hasChildren => _firstChild != null;

  @override
  void attach(Object owner) {
    super.attach(owner);
    Annotator child = firstChild;
    while (child != null) {
      child.attach(owner);
      child = child.nextSibling;
    }
  }

  @override
  void detach() {
    super.detach();
    Annotator child = firstChild;
    while (child != null) {
      child.detach();
      child = child.nextSibling;
    }
  }

  /// Adds the given Annotator to the end of this Annotator's child list.
  void append(Annotator child) {
    assert(child != this);
    assert(child != firstChild);
    assert(child != lastChild);
    assert(child.parent == null);
    assert(!child.attached);
    assert(child.nextSibling == null);
    assert(child.previousSibling == null);
    assert(() {
      Annotator node = this;
      while (node.parent != null)
        node = node.parent;
      assert(node != child); // indicates we are about to create a cycle
      return true;
    }());
    adoptChild(child);
    child._previousSibling = lastChild;
    if (lastChild != null)
      lastChild._nextSibling = child;
    _lastChild = child;
    _firstChild ??= child;
    assert(child.attached == attached);
  }

  // Implementation of [Annotator.remove].
  @protected
  void removeChild(Annotator child) {
    assert(child.parent == this);
    assert(child.attached == attached);
    // assert(_debugUltimatePreviousSiblingOf(child, equals: firstChild));
    // assert(_debugUltimateNextSiblingOf(child, equals: lastChild));
    if (child._previousSibling == null) {
      assert(_firstChild == child);
      _firstChild = child._nextSibling;
    } else {
      child._previousSibling._nextSibling = child.nextSibling;
    }
    if (child._nextSibling == null) {
      assert(lastChild == child);
      _lastChild = child.previousSibling;
    } else {
      child.nextSibling._previousSibling = child.previousSibling;
    }
    assert((firstChild == null) == (lastChild == null));
    assert(firstChild == null || firstChild.attached == attached);
    assert(lastChild == null || lastChild.attached == attached);
    // assert(firstChild == null || _debugUltimateNextSiblingOf(firstChild, equals: lastChild));
    // assert(lastChild == null || _debugUltimatePreviousSiblingOf(lastChild, equals: firstChild));
    child._previousSibling = null;
    child._nextSibling = null;
    dropChild(child);
    assert(!child.attached);
  }

  /// Removes all of this Annotator's children from its child list.
  void removeAllChildren() {
    Annotator child = firstChild;
    while (child != null) {
      final Annotator next = child.nextSibling;
      child._previousSibling = null;
      child._nextSibling = null;
      assert(child.attached == attached);
      dropChild(child);
      child = next;
    }
    _firstChild = null;
    _lastChild = null;
  }

  @override
  bool search<S>(AnnotationResult<S> result, Offset localPosition) {
    for (Annotator child = lastChild; child != null; child = child.previousSibling) {
      final bool isAbsorbed = child.search<S>(result, localPosition);
      if (isAbsorbed)
        return true;
      if (result.stopsAtFirstResult && result.entries.isNotEmpty)
        return isAbsorbed;
    }
    return false;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    if (firstChild == null)
      return children;
    Annotator child = firstChild;
    int count = 1;
    while (true) {
      children.add(child.toDiagnosticsNode(name: 'child $count'));
      if (child == lastChild)
        break;
      count += 1;
      child = child.nextSibling;
    }
    return children;
  }
}

/// An annotator that positions its subtree at an offset from its parent
/// annotator.
class OffsetAnnotator extends ContainerAnnotator {
  /// Create an [OffsetAnnotator].
  ///
  /// The [offset] defaults to [Offset.zero] and must not be null.
  OffsetAnnotator({Offset offset = Offset.zero})
    : assert(offset != null),
      _offset = offset;

  /// Offset from parent in the parent's coordinate system.
  Offset get offset => _offset;
  Offset _offset;
  set offset(Offset value) {
    assert(value != null);
    _offset = value;
  }

  @override
  bool search<S>(AnnotationResult<S> result, Offset localPosition) {
    return super.search(result, localPosition - offset);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
  }
}

/// An annotator that applies a given transformation matrix to its children.
///
/// This class inherits from [OffsetAnnotator] to make it one of the annotators
/// that can be used at the root of a [RenderObject] hierarchy.
class TransformAnnotator extends OffsetAnnotator {
  /// Create an [TransformAnnotator].
  ///
  /// All parameters are optional, but [transform] must have an non-null value
  /// before this annotator can be searched. The [offset] defaults to
  /// [Offset.zero] and must not be null.
  TransformAnnotator({Matrix4 transform, Offset offset = Offset.zero})
    : _transform = transform,
      super(offset: offset);

  /// The matrix to apply.
  ///
  /// This transform is applied to the annotated region before [offset], if both
  /// are set.
  ///
  /// The [transform] property must be non-null before the annotator is searched.
  Matrix4 get transform => _transform;
  Matrix4 _transform;
  set transform(Matrix4 value) {
    assert(value != null);
    assert(value.storage.every((double component) => component.isFinite));
    if (value == _transform)
      return;
    _transform = value;
    _inverseDirty = true;
  }

  Matrix4 _invertedTransform;
  bool _inverseDirty = true;

  Offset _transformOffset(Offset localPosition) {
    if (_inverseDirty) {
      _invertedTransform = Matrix4.tryInvert(
        removePerspectiveTransform(transform)
      );
      _inverseDirty = false;
    }
    if (_invertedTransform == null)
      return null;

    return transformPoint(_invertedTransform, localPosition);
  }

  @override
  bool search<S>(AnnotationResult<S> result, Offset localPosition) {
    final Offset transformedOffset = _transformOffset(localPosition);
    if (transformedOffset == null)
      return false;
    return super.search<S>(result, transformedOffset);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Matrix4>('transform', transform, defaultValue: null));
  }

  // TODO(dkwingsmt): This function is copied from MatrixUtils. Resolve this
  // duplication.
  /// Applies the given matrix as a perspective transform to the given point.
  ///
  /// This function assumes the given point has a z-coordinate of 0.0. The
  /// z-coordinate of the result is ignored.
  static Offset transformPoint(Matrix4 transform, Offset point) {
    final Float64List storage = transform.storage;
    final double x = point.dx;
    final double y = point.dy;

    // Directly simulate the transform of the vector (x, y, 0, 1),
    // dropping the resulting Z coordinate, and normalizing only
    // if needed.

    final double rx = storage[0] * x + storage[4] * y + storage[12];
    final double ry = storage[1] * x + storage[5] * y + storage[13];
    final double rw = storage[3] * x + storage[7] * y + storage[15];
    if (rw == 1.0) {
      return Offset(rx, ry);
    } else {
      return Offset(rx / rw, ry / rw);
    }
  }

  // TODO(dkwingsmt): This function is copied from PointerEvent. Resolve this
  // duplication.
  /// Removes the "perspective" component from `transform`.
  ///
  /// When applying the resulting transform matrix to a point with a
  /// z-coordinate of zero (which is generally assumed for all points
  /// represented by an [Offset]), the other coordinates will get transformed as
  /// before, but the new z-coordinate is going to be zero again. This is
  /// achieved by setting the third column and third row of the matrix to
  /// "0, 0, 1, 0".
  static Matrix4 removePerspectiveTransform(Matrix4 transform) {
    final Vector4 vector = Vector4(0, 0, 1, 0);
    return transform.clone()
      ..setColumn(2, vector)
      ..setRow(2, vector);
  }
}

/// The base class for annoators that only accepts positions within the
/// designated region.
///
/// Subclasses should override [contains] to define whether a position
/// is within the clip.
abstract class ClipAnnotator extends ContainerAnnotator {
  /// Override this method to define whether a position is within the clip,
  /// thus allowed to proceed with the children.
  ///
  /// The `localPosition` is the position in the local coordinate of this
  /// annotator, transformed by its ancestors.
  bool contains(Offset localPosition);

  @override
  bool search<S>(AnnotationResult<S> result, Offset localPosition) {
    if (!contains(localPosition))
      return false;
    return super.search(result, localPosition);
  }
}

/// An annotator that clips its children using a rectangle.
class ClipRectAnnotator extends ClipAnnotator {
  /// Creates an annotator with a rectangular clip.
  ///
  /// The [clipRect] argument is required and must not be null.
  ClipRectAnnotator({@required this.clipRect}) : assert(clipRect != null);

  /// The rectangle to clip in the parent's coordinate system.
  final Rect clipRect;

  @override
  bool contains(Offset localPosition) => clipRect.contains(localPosition);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Rect>('clipRect', clipRect));
  }
}

/// An annotator that clips its children using a rounded rectangle.
class ClipRRectAnnotator extends ClipAnnotator {
  /// Creates an annotator with a rounded rectangular clip.
  ///
  /// The [clipRRect] argument is required and must not be null.
  ClipRRectAnnotator({@required this.clipRRect}) : assert(clipRRect != null);

  /// The rounded rectangle to clip in the parent's coordinate system.
  final RRect clipRRect;

  @override
  bool contains(Offset localPosition) => clipRRect.contains(localPosition);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RRect>('clipRRect', clipRRect));
  }
}

/// An annotator that clips its children using a path.
class ClipPathAnnotator extends ClipAnnotator {
  /// Creates an annotator with a path.
  ///
  /// The [clipPath] argument is required and must not be null.
  ClipPathAnnotator({@required this.clipPath}) : assert(clipPath != null);

  /// The path to clip in the parent's coordinate system.
  final Path clipPath;

  @override
  bool contains(Offset localPosition) => clipPath.contains(localPosition);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Path>('clipPath', clipPath));
  }
}

/// An annotator that provides a specific type of annotation.
///
/// When the annotator is searched, it first searches its children, then if the
/// type matches, calls [onSearchSelf] with the offset specified by
/// [searchSelfOffset]. The returned opacity is true if either any of its
/// children or [onSearchSelf] returns true.
///
/// This annotator is typically used by a render object that want to annotate its
/// region with a predetermined annotation type.
class SingleTypeAnnotator<T> extends ContainerAnnotator {
  /// Create a [SingleTypeAnnotator].
  ///
  /// The `debugOwner` parameter is optional. Other parameters must not be null.
  ///
  /// When used by a render object, the `onSearchSelf` argument should be a
  /// callback that, assuming the type matches, appends the annotation if other
  /// restrictions are met (i.e. whether its size contains the provided location,
  /// which has been offset by `searchSelfOffset`). The `searchSelfOffset` is
  /// typically the offset provided by the object's `paint` method, while the
  /// `debugOwner` is typically the object itself.
  SingleTypeAnnotator(this.onSearchSelf, this.searchSelfOffset, {this.debugOwner})
    : assert(onSearchSelf != null),
      assert(searchSelfOffset != null);

  /// A callback that is called after searching the children only if the type
  /// matches.
  ///
  /// The arguments for this callback will be the ones passed to [search], except
  /// that the `localPosition` has been subtracted by [searchSelfOffset].
  final AnnotationSearch<T> onSearchSelf;

  /// An offset that will be subtracted from the position when calling
  /// `onSearchSelf`.
  ///
  /// This offset will not affect how the children annotators are searched.
  final Offset searchSelfOffset;

  @override
  bool search<S>(AnnotationResult<S> result, Offset localPosition) {
    final bool absorbedByChildren = super.search(result, localPosition);
    if (result.entries.isNotEmpty && result.stopsAtFirstResult)
      return absorbedByChildren;
    if (T != S)
      return absorbedByChildren;
    final AnnotationResult<T> typedResult = result as AnnotationResult<T>;
    final bool absorbedBySelf = onSearchSelf(typedResult, localPosition - searchSelfOffset);
    return absorbedByChildren || absorbedBySelf;
  }

  /// The annotator's owner.
  ///
  /// This is used in the [toString] serialization to report the object for which
  /// this annotator was created, to aid in debugging.
  final Object debugOwner;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('searchSelfOffset', searchSelfOffset));
    properties.add(DiagnosticsProperty<Object>('debugOwner', debugOwner, defaultValue: null));
  }
}

class AlwaysEmptyContainerAnnotator extends ContainerAnnotator {
  @override
  Annotator get firstChild => null;

  @override
  Annotator get lastChild => null;

  @override
  void append(Annotator child) {}

  @override
  @protected
  void removeChild(Annotator child) {}
}