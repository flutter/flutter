// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show Rect, SemanticsAction, SemanticsFlags;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

import 'debug.dart';
import 'node.dart';
import 'semantics_event.dart';

export 'dart:ui' show SemanticsAction;
export 'semantics_event.dart';

/// Signature for a function that is called for each [SemanticsNode].
///
/// Return false to stop visiting nodes.
///
/// Used by [SemanticsNode.visitChildren].
typedef bool SemanticsNodeVisitor(SemanticsNode node);

/// A tag for a [SemanticsNode].
///
/// Tags can be interpreted by the parent of a [SemanticsNode]
/// and depending on the presence of a tag the parent can for example decide
/// how to add the tagged note as a child. Tags are not sent to the engine.
///
/// As an example, the [RenderSemanticsGestureHandler] uses tags to determine
/// if a child node should be excluded from the scrollable area for semantic
/// purposes.
///
/// The provided [name] is only used for debugging. Two tags created with the
/// same [name] and the `new` operator are not considered identical. However,
/// two tags created with the same [name] and the `const` operator are always
/// identical.
class SemanticsTag {
  /// Creates a [SemanticsTag].
  ///
  /// The provided [name] is only used for debugging. Two tags created with the
  /// same [name] and the `new` operator are not considered identical. However,
  /// two tags created with the same [name] and the `const` operator are always
  /// identical.
  const SemanticsTag(this.name);

  /// A human-readable name for this tag used for debugging.
  ///
  /// This string is not used to determine if two tags are identical.
  final String name;

  @override
  String toString() => '$runtimeType($name)';
}

/// Summary information about a [SemanticsNode] object.
///
/// A semantics node might [SemanticsNode.mergeAllDescendantsIntoThisNode],
/// which means the individual fields on the semantics node don't fully describe
/// the semantics at that node. This data structure contains the full semantics
/// for the node.
///
/// Typically obtained from [SemanticsNode.getSemanticsData].
@immutable
class SemanticsData extends Diagnosticable {
  /// Creates a semantics data object.
  ///
  /// The [flags], [actions], [label], and [Rect] arguments must not be null.
  ///
  /// If [label] is not empty, then [textDirection] must also not be null.
  const SemanticsData({
    @required this.flags,
    @required this.actions,
    @required this.label,
    @required this.textDirection,
    @required this.rect,
    this.tags,
    this.transform,
  }) : assert(flags != null),
       assert(actions != null),
       assert(label != null),
       assert(label == '' || textDirection != null, 'A SemanticsData object with label "$label" had a null textDirection.'),
       assert(rect != null);

  /// A bit field of [SemanticsFlags] that apply to this node.
  final int flags;

  /// A bit field of [SemanticsAction]s that apply to this node.
  final int actions;

  /// A textual description of this node.
  ///
  /// The text's reading direction is given by [textDirection].
  final String label;

  /// The reading direction for the text in [label].
  final TextDirection textDirection;

  /// The bounding box for this node in its coordinate system.
  final Rect rect;

  /// The set of [SemanticsTag]s associated with this node.
  final Set<SemanticsTag> tags;

  /// The transform from this node's coordinate system to its parent's coordinate system.
  ///
  /// By default, the transform is null, which represents the identity
  /// transformation (i.e., that this node has the same coorinate system as its
  /// parent).
  final Matrix4 transform;

  /// Whether [flags] contains the given flag.
  bool hasFlag(SemanticsFlags flag) => (flags & flag.index) != 0;

  /// Whether [actions] contains the given action.
  bool hasAction(SemanticsAction action) => (actions & action.index) != 0;

  @override
  String toStringShort() => '$runtimeType';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(new DiagnosticsProperty<Rect>('rect', rect, showName: false));
    properties.add(new TransformProperty('transform', transform, showName: false, defaultValue: null));
    final List<String> actionSummary = <String>[];
    for (SemanticsAction action in SemanticsAction.values.values) {
      if ((actions & action.index) != 0)
        actionSummary.add(describeEnum(action));
    }
    properties.add(new IterableProperty<String>('actions', actionSummary, ifEmpty: null));

    final List<String> flagSummary = <String>[];
    for (SemanticsFlags flag in SemanticsFlags.values.values) {
      if ((flags & flag.index) != 0)
        flagSummary.add(describeEnum(flag));
    }
    properties.add(new IterableProperty<String>('flags', flagSummary, ifEmpty: null));
    properties.add(new StringProperty('label', label, defaultValue: ''));
    properties.add(new EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! SemanticsData)
      return false;
    final SemanticsData typedOther = other;
    return typedOther.flags == flags
        && typedOther.actions == actions
        && typedOther.label == label
        && typedOther.textDirection == textDirection
        && typedOther.rect == rect
        && setEquals(typedOther.tags, tags)
        && typedOther.transform == transform;
  }

  @override
  int get hashCode => hashValues(flags, actions, label, textDirection, rect, tags, transform);
}

class _SemanticsDiagnosticableNode extends DiagnosticableNode<SemanticsNode> {
  _SemanticsDiagnosticableNode({
    String name,
    @required SemanticsNode value,
    @required DiagnosticsTreeStyle style,
    @required this.childOrder,
  }) : super(
    name: name,
    value: value,
    style: style,
  );

  final DebugSemanticsDumpOrder childOrder;

  @override
  List<DiagnosticsNode> getChildren() {
    if (value != null)
      return value.debugDescribeChildren(childOrder: childOrder);

    return const <DiagnosticsNode>[];
  }
}

/// A node that represents some semantic data.
///
/// The semantics tree is maintained during the semantics phase of the pipeline
/// (i.e., during [PipelineOwner.flushSemantics]), which happens after
/// compositing. The semantics tree is then uploaded into the engine for use
/// by assistive technology.
class SemanticsNode extends AbstractNode with DiagnosticableTreeMixin {
  /// Creates a semantic node.
  ///
  /// Each semantic node has a unique identifier that is assigned when the node
  /// is created.
  SemanticsNode({
    VoidCallback showOnScreen,
  }) : id = _generateNewId(),
       _showOnScreen = showOnScreen;

  /// Creates a semantic node to represent the root of the semantics tree.
  ///
  /// The root node is assigned an identifier of zero.
  SemanticsNode.root({
    VoidCallback showOnScreen,
    SemanticsOwner owner,
  }) : id = 0,
       _showOnScreen = showOnScreen {
    attach(owner);
  }

  static int _lastIdentifier = 0;
  static int _generateNewId() {
    _lastIdentifier += 1;
    return _lastIdentifier;
  }

  /// The unique identifier for this node.
  ///
  /// The root node has an id of zero. Other nodes are given a unique id when
  /// they are created.
  final int id;

  final VoidCallback _showOnScreen;

  // GEOMETRY

  /// The transform from this node's coordinate system to its parent's coordinate system.
  ///
  /// By default, the transform is null, which represents the identity
  /// transformation (i.e., that this node has the same coorinate system as its
  /// parent).
  Matrix4 get transform => _transform;
  Matrix4 _transform;
  set transform(Matrix4 value) {
    if (!MatrixUtils.matrixEquals(_transform, value)) {
      _transform = MatrixUtils.isIdentity(value) ? null : value;
      _markDirty();
    }
  }

  /// The bounding box for this node in its coordinate system.
  Rect get rect => _rect;
  Rect _rect = Rect.zero;
  set rect(Rect value) {
    assert(value != null);
    if (_rect != value) {
      _rect = value;
      _markDirty();
    }
  }

  /// Whether [rect] was affected by a clip from an ancestors.
  ///
  /// If this is true it means that an ancestor imposed a clip on this
  /// [SemanticsNode]. However, it does not mean that the clip had any effect
  /// on the [rect] whatsoever.
  bool wasAffectedByClip = false;

  /// Whether the node is invisible.
  ///
  /// A node whose [rect] is outside of the bounds of the screen and hence not
  /// reachable for users is considered invisible if its semantic information
  /// is not merged into a (partially) visible parent as indicated by
  /// [isMergedIntoParent].
  ///
  /// An invisible node can be safely dropped from the semantic tree without
  /// loosing semantic information that is relevant for describing the content
  /// currently shown on screen.
  bool get isInvisible => !isMergedIntoParent && rect.isEmpty;

  // MERGING

  /// Whether this node merges its semantic information into an ancestor node.
  bool get isMergedIntoParent => _isMergedIntoParent;
  bool _isMergedIntoParent = false;
  set isMergedIntoParent(bool value) {
    assert(value != null);
    if (_isMergedIntoParent == value)
      return;
    _isMergedIntoParent = value;
    _markDirty();
  }

  /// Whether this node is taking part in a merge of semantic information.
  ///
  /// This returns true if the node is either merged into an ancestor node or if
  /// decedent nodes are merged into this node.
  ///
  /// See also:
  ///  * [isMergedIntoParent]
  ///  * [mergeAllDescendantsIntoThisNode]
  bool get isPartOfNodeMerging => mergeAllDescendantsIntoThisNode || isMergedIntoParent;

  /// Whether this node and all of its descendants should be treated as one logical entity.
  bool get mergeAllDescendantsIntoThisNode => _mergeAllDescendantsIntoThisNode;
  bool _mergeAllDescendantsIntoThisNode = _kEmptyConfig.isMergingSemanticsOfDescendants;


  // CHILDREN

  /// Contains the children in inverse hit test order (i.e. paint order).
  List<SemanticsNode> _children;

  void _replaceChildren(List<SemanticsNode> newChildren) {
    assert(!newChildren.any((SemanticsNode child) => child == this));
    assert(() {
      SemanticsNode ancestor = this;
      while (ancestor.parent is SemanticsNode)
        ancestor = ancestor.parent;
      assert(!newChildren.any((SemanticsNode child) => child == ancestor));
      return true;
    }());
    assert(() {
      final Set<SemanticsNode> seenChildren = new Set<SemanticsNode>();
      for (SemanticsNode child in newChildren)
        assert(seenChildren.add(child)); // check for duplicate adds
      return true;
    }());

    // The goal of this function is updating sawChange.
    if (_children != null) {
      for (SemanticsNode child in _children)
        child._dead = true;
    }
    if (newChildren != null) {
      for (SemanticsNode child in newChildren) {
        assert(!child.isInvisible, 'Child with id ${child.id} is invisible and should not be added to tree.');
        child._dead = false;
      }
    }
    bool sawChange = false;
    if (_children != null) {
      for (SemanticsNode child in _children) {
        if (child._dead) {
          if (child.parent == this) {
            // we might have already had our child stolen from us by
            // another node that is deeper in the tree.
            dropChild(child);
          }
          sawChange = true;
        }
      }
    }
    if (newChildren != null) {
      for (SemanticsNode child in newChildren) {
        if (child.parent != this) {
          if (child.parent != null) {
            // we're rebuilding the tree from the bottom up, so it's possible
            // that our child was, in the last pass, a child of one of our
            // ancestors. In that case, we drop the child eagerly here.
            // TODO(ianh): Find a way to assert that the same node didn't
            // actually appear in the tree in two places.
            child.parent?.dropChild(child);
          }
          assert(!child.attached);
          adoptChild(child);
          sawChange = true;
        }
      }
    }
    if (!sawChange && _children != null) {
      assert(newChildren != null);
      assert(newChildren.length == _children.length);
      // Did the order change?
      for (int i = 0; i < _children.length; i++) {
        if (_children[i].id != newChildren[i].id) {
          sawChange = true;
          break;
        }
      }
    }
    final List<SemanticsNode> oldChildren = _children;
    _children = newChildren;
    oldChildren?.clear();
    newChildren = oldChildren;
    if (sawChange)
      _markDirty();
  }

  /// Whether this node has a non-zero number of children.
  bool get hasChildren => _children?.isNotEmpty ?? false;
  bool _dead = false;

  /// The number of children this node has.
  int get childrenCount => hasChildren ? _children.length : 0;

  /// Visits the immediate children of this node.
  ///
  /// This function calls visitor for each child in a pre-order travseral
  /// until visitor returns false. Returns true if all the visitor calls
  /// returned true, otherwise returns false.
  void visitChildren(SemanticsNodeVisitor visitor) {
    if (_children != null) {
      for (SemanticsNode child in _children) {
        if (!visitor(child))
          return;
      }
    }
  }

  /// Visit all the descendants of this node.
  ///
  /// This function calls visitor for each descendant in a pre-order travseral
  /// until visitor returns false. Returns true if all the visitor calls
  /// returned true, otherwise returns false.
  bool _visitDescendants(SemanticsNodeVisitor visitor) {
    if (_children != null) {
      for (SemanticsNode child in _children) {
        if (!visitor(child) || !child._visitDescendants(visitor))
          return false;
      }
    }
    return true;
  }

  // AbstractNode OVERRIDES

  @override
  SemanticsOwner get owner => super.owner;

  @override
  SemanticsNode get parent => super.parent;

  @override
  void redepthChildren() {
    if (_children != null) {
      for (SemanticsNode child in _children)
        redepthChild(child);
    }
  }

  @override
  void attach(SemanticsOwner owner) {
    super.attach(owner);
    assert(!owner._nodes.containsKey(id));
    owner._nodes[id] = this;
    owner._detachedNodes.remove(this);
    if (_dirty) {
      _dirty = false;
      _markDirty();
    }
    if (_children != null) {
      for (SemanticsNode child in _children)
        child.attach(owner);
    }
  }

  @override
  void detach() {
    assert(owner._nodes.containsKey(id));
    assert(!owner._detachedNodes.contains(this));
    owner._nodes.remove(id);
    owner._detachedNodes.add(this);
    super.detach();
    assert(owner == null);
    if (_children != null) {
      for (SemanticsNode child in _children) {
        // The list of children may be stale and may contain nodes that have
        // been assigned to a different parent.
        if (child.parent == this)
          child.detach();
      }
    }
    // The other side will have forgotten this node if we ever send
    // it again, so make sure to mark it dirty so that it'll get
    // sent if it is resurrected.
    _markDirty();
  }

  // DIRTY MANAGEMENT

  bool _dirty = false;
  void _markDirty() {
    if (_dirty)
      return;
    _dirty = true;
    if (attached) {
      assert(!owner._detachedNodes.contains(this));
      owner._dirtyNodes.add(this);
    }
  }

  bool _isDifferentFromCurrentSemanticAnnotation(SemanticsConfiguration config) {
    return _label != config.label ||
        _flags != config._flags ||
        _textDirection != config.textDirection ||
        _actionsAsBitMap(_actions) != _actionsAsBitMap(config._actions) ||
        _mergeAllDescendantsIntoThisNode != config.isMergingSemanticsOfDescendants;
  }

  // TAGS, LABELS, ACTIONS

  Map<SemanticsAction, VoidCallback> _actions = _kEmptyConfig._actions;

  /// The [SemanticsTag]s this node is tagged with.
  ///
  /// Tags are used during the construction of the semantics tree. They are not
  /// transfered to the engine.
  Set<SemanticsTag> tags;

  /// Whether this node is tagged with `tag`.
  bool isTagged(SemanticsTag tag) => tags != null && tags.contains(tag);

  int _flags = _kEmptyConfig._flags;

  bool _hasFlag(SemanticsFlags flag) => _flags & flag.index != 0;

  /// A textual description of this node.
  ///
  /// The text's reading direction is given by [textDirection].
  String get label => _label;
  String _label = _kEmptyConfig.label;

  /// The reading direction for [label].
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection = _kEmptyConfig.textDirection;

  int _actionsAsBitMap(Map<SemanticsAction, VoidCallback> actions) {
    return actions.keys.fold(0, (int prev, SemanticsAction action) => prev |= action.index);
  }

  bool _canPerformAction(SemanticsAction action) => _actions.containsKey(action);

  static final SemanticsConfiguration _kEmptyConfig = new SemanticsConfiguration();

  void updateWith({
    @required SemanticsConfiguration config,
    @required  List<SemanticsNode> childrenInInversePaintOrder,
  }) {
    config ??= _kEmptyConfig;
    if (_isDifferentFromCurrentSemanticAnnotation(config))
      _markDirty();

    _label = config.label;
    _flags = config._flags;
    _textDirection = config.textDirection;
    _actions = new Map<SemanticsAction, VoidCallback>.from(config._actions);
    _mergeAllDescendantsIntoThisNode = config.isMergingSemanticsOfDescendants;
    _replaceChildren(childrenInInversePaintOrder ?? const <SemanticsNode>[]);
  }


  /// Returns a summary of the semantics for this node.
  ///
  /// If this node has [mergeAllDescendantsIntoThisNode], then the returned data
  /// includes the information from this node's descendants. Otherwise, the
  /// returned data matches the data on this node.
  SemanticsData getSemanticsData() {
    int flags = _flags;
    int actions = _actionsAsBitMap(_actions);
    String label = _label;
    TextDirection textDirection = _textDirection;
    Set<SemanticsTag> mergedTags = tags == null ? null : new Set<SemanticsTag>.from(tags);

    if (mergeAllDescendantsIntoThisNode) {
      _visitDescendants((SemanticsNode node) {
        assert(node.isMergedIntoParent);
        flags |= node._flags;
        actions |= _actionsAsBitMap(node._actions);
        textDirection ??= node._textDirection;
        if (node.tags != null) {
          mergedTags ??= new Set<SemanticsTag>();
          mergedTags.addAll(node.tags);
        }
        if (node._label.isNotEmpty) {
          String nestedLabel = node._label;
          if (textDirection != node._textDirection && node._textDirection != null) {
            switch (node._textDirection) {
              case TextDirection.rtl:
                nestedLabel = '${Unicode.RLE}$nestedLabel${Unicode.PDF}';
                break;
              case TextDirection.ltr:
                nestedLabel = '${Unicode.LRE}$nestedLabel${Unicode.PDF}';
                break;
            }
          }
          if (label.isEmpty)
            label = nestedLabel;
          else
            label = '$label\n$nestedLabel';
        }
        return true;
      });
    }

    return new SemanticsData(
      flags: flags,
      actions: actions,
      label: label,
      textDirection: textDirection,
      rect: rect,
      transform: transform,
      tags: mergedTags,
    );
  }

  static Float64List _initIdentityTransform() {
    return new Matrix4.identity().storage;
  }

  static final Int32List _kEmptyChildList = new Int32List(0);
  static final Float64List _kIdentityTransform = _initIdentityTransform();

  void _addToUpdate(ui.SemanticsUpdateBuilder builder) {
    assert(_dirty);
    final SemanticsData data = getSemanticsData();
    Int32List children;
    if (!hasChildren || mergeAllDescendantsIntoThisNode) {
      children = _kEmptyChildList;
    } else {
      final int childCount = _children.length;
      children = new Int32List(childCount);
      for (int i = 0; i < childCount; ++i)
        children[i] = _children[i].id;
    }
    builder.updateNode(
      id: id,
      flags: data.flags,
      actions: data.actions,
      rect: data.rect,
      label: data.label,
      textDirection: data.textDirection,
      transform: data.transform?.storage ?? _kIdentityTransform,
      children: children,
    );
    _dirty = false;
  }

  /// Sends a [SemanticsEvent] associated with this [SemanticsNode].
  ///
  /// Semantics events should be sent to inform interested parties (like
  /// the accessibility system of the operating system) about changes to the UI.
  ///
  /// For example, if this semantics node represents a scrollable list, a
  /// [ScrollCompletedSemanticsEvent] should be sent after a scroll action is completed.
  /// That way, the operating system can give additional feedback to the user
  /// about the state of the UI (e.g. on Android a ping sound is played to
  /// indicate a successful scroll in accessibility mode).
  void sendEvent(SemanticsEvent event) {
    if (!attached)
      return;
    final Map<String, dynamic> annotatedEvent = <String, dynamic>{
      'nodeId': id,
      'type': event.type,
      'data': event.toMap(),
    };
    SystemChannels.accessibility.send(annotatedEvent);
  }

  @override
  String toStringShort() => '$runtimeType#$id';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    bool hideOwner = true;
    if (_dirty) {
      final bool inDirtyNodes = owner != null && owner._dirtyNodes.contains(this);
      properties.add(new FlagProperty('inDirtyNodes', value: inDirtyNodes, ifTrue: 'dirty', ifFalse: 'STALE'));
      hideOwner = inDirtyNodes;
    }
    properties.add(new DiagnosticsProperty<SemanticsOwner>('owner', owner, level: hideOwner ? DiagnosticLevel.hidden : DiagnosticLevel.info));
    properties.add(new FlagProperty('isPartOfNodeMerging', value: isPartOfNodeMerging, ifTrue: 'leaf merge'));
    final Offset offset = transform != null ? MatrixUtils.getAsTranslation(transform) : null;
    if (offset != null) {
      properties.add(new DiagnosticsProperty<Rect>('rect', rect.shift(offset), showName: false));
    } else {
      final double scale = transform != null ? MatrixUtils.getAsScale(transform) : null;
      String description;
      if (scale != null) {
        description = '$rect scaled by ${scale.toStringAsFixed(1)}x';
      } else if (transform != null && !MatrixUtils.isIdentity(transform)) {
        final String matrix = transform.toString().split('\n').take(4).map((String line) => line.substring(4)).join('; ');
        description = '$rect with transform [$matrix]';
      }
      properties.add(new DiagnosticsProperty<Rect>('rect', rect, description: description, showName: false));
    }
    properties.add(new FlagProperty('wasAffectedByClip', value: wasAffectedByClip, ifTrue: 'clipped'));
    final List<String> actions = _actions.keys.map((SemanticsAction action) => describeEnum(action)).toList()..sort();
    properties.add(new IterableProperty<String>('actions', actions, ifEmpty: null));
    if (_hasFlag(SemanticsFlags.hasCheckedState))
      properties.add(new FlagProperty('isChecked', value: _hasFlag(SemanticsFlags.isChecked), ifTrue: 'checked', ifFalse: 'unchecked'));
    properties.add(new FlagProperty('isSelected', value: _hasFlag(SemanticsFlags.isSelected), ifTrue: 'selected'));
    properties.add(new StringProperty('label', _label, defaultValue: ''));
    properties.add(new EnumProperty<TextDirection>('textDirection', _textDirection, defaultValue: null));
  }

  /// Returns a string representation of this node and its descendants.
  ///
  /// The order in which the children of the [SemanticsNode] will be printed is
  /// controlled by the [childOrder] parameter.
  @override
  String toStringDeep({
    String prefixLineOne: '',
    String prefixOtherLines,
    DiagnosticLevel minLevel: DiagnosticLevel.debug,
    DebugSemanticsDumpOrder childOrder: DebugSemanticsDumpOrder.traversal,
  }) {
    assert(childOrder != null);
    return toDiagnosticsNode(childOrder: childOrder).toStringDeep(prefixLineOne: prefixLineOne, prefixOtherLines: prefixOtherLines, minLevel: minLevel);
  }

  @override
  DiagnosticsNode toDiagnosticsNode({
    String name,
    DiagnosticsTreeStyle style: DiagnosticsTreeStyle.dense,
    DebugSemanticsDumpOrder childOrder: DebugSemanticsDumpOrder.traversal,
  }) {
    return new _SemanticsDiagnosticableNode(
      name: name,
      value: this,
      style: style,
      childOrder: childOrder,
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren({ DebugSemanticsDumpOrder childOrder: DebugSemanticsDumpOrder.inverseHitTest }) {
    return _getChildrenInOrder(childOrder)
      .map<DiagnosticsNode>((SemanticsNode node) => node.toDiagnosticsNode(childOrder: childOrder))
      .toList();
  }

  Iterable<SemanticsNode> _getChildrenInOrder(DebugSemanticsDumpOrder childOrder) {
    assert(childOrder != null);
    if (_children == null)
      return const <SemanticsNode>[];

    switch (childOrder) {
      case DebugSemanticsDumpOrder.traversal:
        return new List<SemanticsNode>.from(_children)..sort(_geometryComparator);
      case DebugSemanticsDumpOrder.inverseHitTest:
        return _children;
    }
    assert(false);
    return null;
  }

  static int _geometryComparator(SemanticsNode a, SemanticsNode b) {
    final Rect rectA = a.transform == null ? a.rect : MatrixUtils.transformRect(a.transform, a.rect);
    final Rect rectB = b.transform == null ? b.rect : MatrixUtils.transformRect(b.transform, b.rect);
    final int top = rectA.top.compareTo(rectB.top);
    return top == 0 ? rectA.left.compareTo(rectB.left) : top;
  }
}

/// Owns [SemanticsNode] objects and notifies listeners of changes to the
/// render tree semantics.
///
/// To listen for semantic updates, call [PipelineOwner.ensureSemantics] to
/// obtain a [SemanticsHandle]. This will create a [SemanticsOwner] if
/// necessary.
class SemanticsOwner extends ChangeNotifier {
  final Set<SemanticsNode> _dirtyNodes = new Set<SemanticsNode>();
  final Map<int, SemanticsNode> _nodes = <int, SemanticsNode>{};
  final Set<SemanticsNode> _detachedNodes = new Set<SemanticsNode>();

  /// The root node of the semantics tree, if any.
  ///
  /// If the semantics tree is empty, returns null.
  SemanticsNode get rootSemanticsNode => _nodes[0];

  @override
  void dispose() {
    _dirtyNodes.clear();
    _nodes.clear();
    _detachedNodes.clear();
    super.dispose();
  }

  /// Update the semantics using [Window.updateSemantics].
  void sendSemanticsUpdate() {
    if (_dirtyNodes.isEmpty)
      return;
    final List<SemanticsNode> visitedNodes = <SemanticsNode>[];
    while (_dirtyNodes.isNotEmpty) {
      final List<SemanticsNode> localDirtyNodes = _dirtyNodes.where((SemanticsNode node) => !_detachedNodes.contains(node)).toList();
      _dirtyNodes.clear();
      _detachedNodes.clear();
      localDirtyNodes.sort((SemanticsNode a, SemanticsNode b) => a.depth - b.depth);
      visitedNodes.addAll(localDirtyNodes);
      for (SemanticsNode node in localDirtyNodes) {
        assert(node._dirty);
        assert(node.parent == null || !node.parent.isPartOfNodeMerging || node.isMergedIntoParent);
        if (node.isPartOfNodeMerging) {
          assert(node.mergeAllDescendantsIntoThisNode || node.parent != null);
          // if we're merged into our parent, make sure our parent is added to the dirty list
          if (node.parent != null && node.parent.isPartOfNodeMerging)
            node.parent._markDirty(); // this can add the node to the dirty list
        }
      }
    }
    visitedNodes.sort((SemanticsNode a, SemanticsNode b) => a.depth - b.depth);
    final ui.SemanticsUpdateBuilder builder = new ui.SemanticsUpdateBuilder();
    for (SemanticsNode node in visitedNodes) {
      assert(node.parent?._dirty != true); // could be null (no parent) or false (not dirty)
      // The _serialize() method marks the node as not dirty, and
      // recurses through the tree to do a deep serialization of all
      // contiguous dirty nodes. This means that when we return here,
      // it's quite possible that subsequent nodes are no longer
      // dirty. We skip these here.
      // We also skip any nodes that were reset and subsequently
      // dropped entirely (RenderObject.markNeedsSemanticsUpdate()
      // calls reset() on its SemanticsNode if onlyChanges isn't set,
      // which happens e.g. when the node is no longer contributing
      // semantics).
      if (node._dirty && node.attached)
        node._addToUpdate(builder);
    }
    _dirtyNodes.clear();
    ui.window.updateSemantics(builder.build());
    notifyListeners();
  }

  VoidCallback _getSemanticsActionHandlerForId(int id, SemanticsAction action) {
    SemanticsNode result = _nodes[id];
    if (result != null && result.isPartOfNodeMerging && !result._canPerformAction(action)) {
      result._visitDescendants((SemanticsNode node) {
        if (node._canPerformAction(action)) {
          result = node;
          return false; // found node, abort walk
        }
        return true; // continue walk
      });
    }
    if (result == null || !result._canPerformAction(action))
      return null;
    return result._actions[action];
  }

  /// Asks the [SemanticsNode] with the given id to perform the given action.
  ///
  /// If the [SemanticsNode] has not indicated that it can perform the action,
  /// this function does nothing.
  void performAction(int id, SemanticsAction action) {
    assert(action != null);
    final VoidCallback handler = _getSemanticsActionHandlerForId(id, action);
    if (handler != null) {
      handler();
      return;
    }

    // Default actions if no [handler] was provided.
    if (action == SemanticsAction.showOnScreen && _nodes[id]._showOnScreen != null)
      _nodes[id]._showOnScreen();
  }

  VoidCallback _getSemanticsActionHandlerForPosition(SemanticsNode node, Offset position, SemanticsAction action) {
    if (node.transform != null) {
      final Matrix4 inverse = new Matrix4.identity();
      if (inverse.copyInverse(node.transform) == 0.0)
        return null;
      position = MatrixUtils.transformPoint(inverse, position);
    }
    if (!node.rect.contains(position))
      return null;
    if (node.mergeAllDescendantsIntoThisNode) {
      SemanticsNode result;
      node._visitDescendants((SemanticsNode child) {
        if (child._canPerformAction(action)) {
          result = child;
          return false;
        }
        return true;
      });
      return result?._actions[action];
    }
    if (node.hasChildren) {
      for (SemanticsNode child in node._children.reversed) {
        final VoidCallback handler = _getSemanticsActionHandlerForPosition(child, position, action);
        if (handler != null)
          return handler;
      }
    }
    return node._canPerformAction(action) ? node._actions[action] : null;
  }

  /// Asks the [SemanticsNode] at the given position to perform the given action.
  ///
  /// If the [SemanticsNode] has not indicated that it can perform the action,
  /// this function does nothing.
  void performActionAt(Offset position, SemanticsAction action) {
    assert(action != null);
    final SemanticsNode node = rootSemanticsNode;
    if (node == null)
      return;
    final VoidCallback handler = _getSemanticsActionHandlerForPosition(node, position, action);
    if (handler != null)
      handler();
  }

  @override
  String toString() => describeIdentity(this);
}

/// Describes the semantic information associated with the owning
/// [RenderObject].
///
/// The information provided in the configuration is used to to generate the
/// semantics tree.
class SemanticsConfiguration {

  // SEMANTIC BOUNDARY BEHAVIOR

  /// Whether the [RenderObject] owner of this configuration wants to own its
  /// own [SemanticsNode].
  ///
  /// When set to true semantic information associated with the [RenderObject]
  /// owner of this configuration or any of its defendants will not leak into
  /// parents. The [SemanticsNode] generated out of this configuration will
  /// act as a boundary.
  ///
  /// Whether descendants of the owning [RenderObject] can add their semantic
  /// information to the [SemanticsNode] introduced by this configuration
  /// is controlled by [explicitChildNodes].
  ///
  /// This has to be true if [isMergingDescendantsIntoOneNode] is also true.
  bool get isSemanticBoundary => _isSemanticBoundary;
  bool _isSemanticBoundary = false;
  set isSemanticBoundary(bool value) {
    assert(!isMergingDescendantsIntoOneNode || value);
    _isSemanticBoundary = value;
  }

  /// Whether the configuration forces all children of the owning [RenderObject]
  /// that want to contribute semantic information to the semantics tree to do
  /// so in the form of explicit [SemanticsNode]s.
  ///
  /// When set to false children of the owning [RenderObject] are allowed to
  /// annotate [SemanticNode]s of their parent with the semantic information
  /// they want to contribute to the semantic tree.
  /// When set to true the only way for children of the owning [RenderObject]
  /// to contribute semantic information to the semantic tree is to introduce
  /// new explicit [SemanticNode]s to the tree.
  ///
  /// This setting is often used in combination with [isSemanticBoundary] to
  /// create semantic boundaries that are either writable or not for children.
  bool explicitChildNodes = false;

  /// Whether the owning [RenderObject] makes other [RenderObjects] previously
  /// painted within the same semantic boundary unreachable for accessibility
  /// purposes.
  ///
  /// If set to true, the semantic information for all siblings and cousins of
  /// this node, that are earlier in a depth-first pre-order traversal, are
  /// dropped from the semantics tree up until a semantic boundary (as defined
  /// by [isSemanticBoundary]) is reached.
  ///
  /// If [isSemanticBoundary] and [isBlockingSemanticsOfPreviouslyPaintedNodes]
  /// is set on the same node, all previously painted siblings and cousins up
  /// until the next ancestor that is a semantic boundary are dropped.
  ///
  /// Paint order as established by [visitChildrenForSemantics] is used to
  /// determine if a node is previous to this one.
  bool isBlockingSemanticsOfPreviouslyPaintedNodes = false;

  /// Whether the semantics information of all descendants should be merged
  /// into the owning [RenderObject] semantics node.
  ///
  /// When this is set to true the [SemanticsNode] of the owning [RenderObject]
  /// will not have any children.
  ///
  /// Setting this to true requires that [isSemanticBoundary] is also true.
  bool get isMergingDescendantsIntoOneNode => _isMergingDescendantsIntoOneNode;
  bool _isMergingDescendantsIntoOneNode = false;
  set isMergingDescendantsIntoOneNode(bool value) {
    assert(isSemanticBoundary);
    _isMergingDescendantsIntoOneNode = isMergingDescendantsIntoOneNode;
  }

  // SEMANTIC ANNOTATIONS
  // These will end up on [SemanticNode]s generated from
  // [SemanticsConfiguration]s.

  /// Whether this configuration is empty.
  ///
  /// An empty configuration doesn't contain any semantic information that it
  /// wants to contribute to the semantics tree.
  bool get hasBeenAnnotated => _hasBeenAnnotated;
  bool _hasBeenAnnotated = false;

  /// The actions (with associated action handlers) that this configuration
  /// would like to contribute to the semantics tree.
  ///
  /// See also:
  /// * [addAction] to add an action.
  final Map<SemanticsAction, VoidCallback> _actions = <SemanticsAction, VoidCallback>{};

  /// Adds an `action` to the semantics tree.
  ///
  /// Whenever the user performs `action` the provided `handler` is called.
  void addAction(SemanticsAction action, VoidCallback handler) {
    _actions[action] = handler;
    _hasBeenAnnotated = true;
  }

  /// Returns the action handler registered for [action] or null if none was
  /// registered.
  ///
  /// See also:
  ///  * [addAction] to add an action.
  VoidCallback getActionHandler(SemanticsAction action) => _actions[action];

  /// Whether the semantic information provided by the owning [RenderObject] and
  /// all of its descendants should be treated as one logical entity.
  ///
  /// If set to true, the descendants of the owning [RenderObject]'s
  /// [SemanticsNode] will merge their semantic information into the
  /// [SemanticsNode] representing the owning [RenderObject].
  bool get isMergingSemanticsOfDescendants => _isMergingSemanticsOfDescendants;
  bool _isMergingSemanticsOfDescendants = false;
  set isMergingSemanticsOfDescendants(bool value) {
    _isMergingSemanticsOfDescendants = value;
    _hasBeenAnnotated = true;
  }

  /// A textual description of the owning [RenderObject].
  ///
  /// The text's reading direction is given by [textDirection].
  String get label => _label;
  String _label = '';
  set label(String label) {
    _label = label;
    _hasBeenAnnotated = true;
  }

  /// The reading direction for the text in [label].
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection textDirection) {
    _textDirection = textDirection;
    _hasBeenAnnotated = true;
  }

  /// Whether the owning [RenderObject] is selected (true) or not (false).
  set isSelected(bool value) {
    _setFlag(SemanticsFlags.isSelected, value);
  }

  /// If this node has Boolean state that can be controlled by the user, whether
  /// that state is on or off, corresponding to true and false, respectively.
  ///
  /// Do not set this to any value if the owning [RenderObject] doesn't have
  /// Booleans state that can be controlled by the user.
  set isChecked(bool value) {
    _setFlag(SemanticsFlags.hasCheckedState, true);
    _setFlag(SemanticsFlags.isChecked, value);
  }

  // TAGS

  Iterable<SemanticsTag> get tagsForChildren => _tagsForChildren;
  Set<SemanticsTag> _tagsForChildren;

  void addTagForChildren(SemanticsTag tag) {
    _tagsForChildren ??= new Set<SemanticsTag>();
    _tagsForChildren.add(tag);
  }

  // INTERNAL FLAG MANAGEMENT

  int _flags = 0;
  void _setFlag(SemanticsFlags flag, bool value) {
    if (value) {
      _flags |= flag.index;
    } else {
      _flags &= ~flag.index;
    }
    _hasBeenAnnotated = true;
  }

  // CONFIGURATION COMBINATION LOGIC

  /// Whether this configuration is compatible with the provided `other`
  /// configuration.
  ///
  /// Two configurations are said to be compatible if they can be added to the
  /// same [SemanticsNode] without losing any semantics information.
  bool isCompatibleWith(SemanticsConfiguration other) {
    if (other == null || !other.hasBeenAnnotated || !hasBeenAnnotated)
      return true;
    if (_actions.keys.toSet().intersection(other._actions.keys.toSet()).isNotEmpty)
      return false;
    if ((_flags & other._flags) != 0)
      return false;
    return true;
  }

  /// Absorb the semantic information from `other` into this configuration.
  ///
  /// This adds the semantic information of both configurations and saves the
  /// result in this configuration.
  ///
  /// Only configurations that have [explicitChildNodes] set to false can
  /// absorb other configurations and its recommended to only absorb compatible
  /// configurations as determined by [isCompatibleWith].
  void absorb(SemanticsConfiguration other) {
    assert(!explicitChildNodes);

    if (!other.hasBeenAnnotated)
      return;

    _actions.addAll(other._actions);
    _flags |= other._flags;

    textDirection ??= other.textDirection;
    if (other.label.isNotEmpty) {
      String nestedLabel = other.label;
      if (textDirection != other.textDirection && other.textDirection != null) {
        switch (other.textDirection) {
          case TextDirection.rtl:
            nestedLabel = '${Unicode.RLE}$nestedLabel${Unicode.PDF}';
            break;
          case TextDirection.ltr:
            nestedLabel = '${Unicode.LRE}$nestedLabel${Unicode.PDF}';
            break;
        }
      }
      if (label.isEmpty)
        label = nestedLabel;
      else
        label = '$label\n$nestedLabel';
    }

    _hasBeenAnnotated = _hasBeenAnnotated || other._hasBeenAnnotated;
  }

  /// Returns an exact copy of this configuration.
  SemanticsConfiguration copy() {
    return new SemanticsConfiguration()
      ..isSemanticBoundary = isSemanticBoundary
      ..explicitChildNodes = explicitChildNodes
      .._hasBeenAnnotated = _hasBeenAnnotated
      .._textDirection = _textDirection
      .._label = _label
      .._flags = _flags
      .._actions.addAll(_actions);
  }
}
