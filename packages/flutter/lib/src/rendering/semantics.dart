// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:sky_services/semantics/semantics.mojom.dart' as mojom;
import 'package:vector_math/vector_math_64.dart';

import 'node.dart';

/// The type of function returned by [RenderObject.getSemanticAnnotators()].
///
/// These callbacks are called with the [SemanticsNode] object that
/// corresponds to the [RenderObject]. (One [SemanticsNode] can
/// correspond to multiple [RenderObject] objects.)
///
/// See [RenderObject.getSemanticAnnotators()] for details on the
/// contract that semantic annotators must follow.
typedef void SemanticAnnotator(SemanticsNode semantics);

/// Interface for [RenderObject]s to implement when they want to support
/// being tapped, etc.
///
/// These handlers will only be called if the relevant flag is set
/// (e.g. [handleSemanticTap]() will only be called if
/// [SemanticsNode.canBeTapped] is true, [handleSemanticScrollDown]() will only
/// be called if [SemanticsNode.canBeScrolledVertically] is true, etc).
abstract class SemanticActionHandler {
  /// Called when the user taps on the render object.
  void handleSemanticTap() { }

  /// Called when the user presses on the render object for a long period of time.
  void handleSemanticLongPress() { }

  /// Called when the user scrolls to the left.
  void handleSemanticScrollLeft() { }

  /// Called when the user scrolls to the right.
  void handleSemanticScrollRight() { }

  /// Called when the user scrolls up.
  void handleSemanticScrollUp() { }

  /// Called when the user scrolls down.
  void handleSemanticScrollDown() { }
}

enum _SemanticFlags {
  mergeAllDescendantsIntoThisNode,
  inheritedMergeAllDescendantsIntoThisNode, // whether an ancestor had mergeAllDescendantsIntoThisNode set
  canBeTapped,
  canBeLongPressed,
  canBeScrolledHorizontally,
  canBeScrolledVertically,
  hasCheckedState,
  isChecked,
}

/// Signature for a function that is called for each [SemanticsNode].
///
/// Return false to stop visiting nodes.
typedef bool SemanticsNodeVisitor(SemanticsNode node);

/// A node that represents some semantic data.
///
/// The semantics tree is maintained during the semantics phase of the pipeline
/// (i.e., during [PipelineOwner.flushSemantics]), which happens after
/// compositing. The semantics tree is then uploaded into the engine for use
/// by assistive technology.
class SemanticsNode extends AbstractNode {
  /// Creates a semantic node.
  ///
  /// Each semantic node has a unique identifier that is assigned when the node
  /// is created.
  SemanticsNode({
    SemanticActionHandler handler
  }) : _id = _generateNewId(),
       _actionHandler = handler;

  /// Creates a semantic node to represent the root of the semantics tree.
  ///
  /// The root node is assigned an identifier of zero.
  SemanticsNode.root({
    SemanticActionHandler handler,
    Object owner
  }) : _id = 0,
       _actionHandler = handler {
    attach(owner);
  }

  static int _lastIdentifier = 0;
  static int _generateNewId() {
    _lastIdentifier += 1;
    return _lastIdentifier;
  }

  final int _id;
  final SemanticActionHandler _actionHandler;


  // GEOMETRY
  // These are automatically handled by RenderObject's own logic

  /// The transform from this node's coordinate system to its parent's coordinate system.
  ///
  /// By default, the transform is null, which represents the identity
  /// transformation (i.e., that this node has the same coorinate system as its
  /// parent).
  Matrix4 get transform => _transform;
  Matrix4 _transform;
  set transform (Matrix4 value) {
    if (!MatrixUtils.matrixEquals(_transform, value)) {
      _transform = value;
      _markDirty();
    }
  }

  /// The bounding box for this node in its coordinate system.
  Rect get rect => _rect;
  Rect _rect = Rect.zero;
  set rect (Rect value) {
    assert(value != null);
    if (_rect != value) {
      _rect = value;
      _markDirty();
    }
  }

  /// Whether [rect] might have been influenced by clips applied by ancestors.
  bool wasAffectedByClip = false;


  // FLAGS AND LABELS
  // These are supposed to be set by SemanticAnnotator obtained from getSemanticAnnotators

  BitField<_SemanticFlags> _flags = new BitField<_SemanticFlags>.filled(_SemanticFlags.values.length, false);

  void _setFlag(_SemanticFlags flag, bool value, { bool needsHandler: false }) {
    assert(value != null);
    assert((!needsHandler) || (_actionHandler != null) || (value == false));
    if (_flags[flag] != value) {
      _flags[flag] = value;
      _markDirty();
    }
  }

  bool _canHandle(_SemanticFlags flag) {
    return _actionHandler != null && _flags[flag];
  }

  /// Whether all this node and all of its descendants should be treated as one logical entity.
  bool get mergeAllDescendantsIntoThisNode => _flags[_SemanticFlags.mergeAllDescendantsIntoThisNode];
  set mergeAllDescendantsIntoThisNode(bool value) => _setFlag(_SemanticFlags.mergeAllDescendantsIntoThisNode, value);

  bool get _inheritedMergeAllDescendantsIntoThisNode => _flags[_SemanticFlags.inheritedMergeAllDescendantsIntoThisNode];
  set _inheritedMergeAllDescendantsIntoThisNode(bool value) => _setFlag(_SemanticFlags.inheritedMergeAllDescendantsIntoThisNode, value);

  bool get _shouldMergeAllDescendantsIntoThisNode => mergeAllDescendantsIntoThisNode || _inheritedMergeAllDescendantsIntoThisNode;

  /// Whether this node responds to tap gestures.
  bool get canBeTapped => _flags[_SemanticFlags.canBeTapped];
  set canBeTapped(bool value) => _setFlag(_SemanticFlags.canBeTapped, value, needsHandler: true);

  /// Whether this node responds to long-press gestures.
  bool get canBeLongPressed => _flags[_SemanticFlags.canBeLongPressed];
  set canBeLongPressed(bool value) => _setFlag(_SemanticFlags.canBeLongPressed, value, needsHandler: true);

  /// Whether this node responds to horizontal scrolling.
  bool get canBeScrolledHorizontally => _flags[_SemanticFlags.canBeScrolledHorizontally];
  set canBeScrolledHorizontally(bool value) => _setFlag(_SemanticFlags.canBeScrolledHorizontally, value, needsHandler: true);

  /// Whether this node responds to vertical scrolling.
  bool get canBeScrolledVertically => _flags[_SemanticFlags.canBeScrolledVertically];
  set canBeScrolledVertically(bool value) => _setFlag(_SemanticFlags.canBeScrolledVertically, value, needsHandler: true);

  /// Whether this node has Boolean state that can be controlled by the user.
  bool get hasCheckedState => _flags[_SemanticFlags.hasCheckedState];
  set hasCheckedState(bool value) => _setFlag(_SemanticFlags.hasCheckedState, value);

  /// If this node has Boolean state that can be controlled by the user, whether that state is on or off, cooresponding to `true` and `false`, respectively.
  bool get isChecked => _flags[_SemanticFlags.isChecked];
  set isChecked(bool value) => _setFlag(_SemanticFlags.isChecked, value);

  /// A textual description of this node.
  String get label => _label;
  String _label = '';
  set label(String value) {
    assert(value != null);
    if (_label != value) {
      _label = value;
      _markDirty();
    }
  }

  /// Restore this node to its default state.
  void reset() {
    bool hadInheritedMergeAllDescendantsIntoThisNode = _inheritedMergeAllDescendantsIntoThisNode;
    _flags.reset();
    if (hadInheritedMergeAllDescendantsIntoThisNode)
      _inheritedMergeAllDescendantsIntoThisNode = true;
    _label = '';
    _markDirty();
  }

  List<SemanticsNode> _newChildren;

  /// Append the given children as children of this node.
  void addChildren(Iterable<SemanticsNode> children) {
    _newChildren ??= <SemanticsNode>[];
    _newChildren.addAll(children);
    // we do the asserts afterwards because children is an Iterable
    // and doing the asserts before would mean the behavior is
    // different in checked mode vs release mode (if you walk an
    // iterator after having reached the end, it'll just start over;
    // the values are not cached).
    assert(!_newChildren.any((SemanticsNode child) => child == this));
    assert(() {
      SemanticsNode ancestor = this;
      while (ancestor.parent is SemanticsNode)
        ancestor = ancestor.parent;
      assert(!_newChildren.any((SemanticsNode child) => child == ancestor));
      return true;
    });
    assert(() {
      Set<SemanticsNode> seenChildren = new Set<SemanticsNode>();
      for (SemanticsNode child in _newChildren)
        assert(seenChildren.add(child)); // check for duplicate adds
      return true;
    });
  }

  List<SemanticsNode> _children;

  /// Whether this node has a non-zero number of children.
  bool get hasChildren => _children?.isNotEmpty ?? false;
  bool _dead = false;

  /// Called during the compilation phase after all the children of this node have been compiled.
  ///
  /// This function lets the semantic node respond to all the changes to its
  /// child list for the given frame at once instead of needing to process the
  /// changes incrementally as new children are compiled.
  void finalizeChildren() {
    if (_children != null) {
      for (SemanticsNode child in _children)
        child._dead = true;
    }
    if (_newChildren != null) {
      for (SemanticsNode child in _newChildren)
        child._dead = false;
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
    if (_newChildren != null) {
      for (SemanticsNode child in _newChildren) {
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
    List<SemanticsNode> oldChildren = _children;
    _children = _newChildren;
    oldChildren?.clear();
    _newChildren = oldChildren;
    if (sawChange)
      _markDirty();
  }

  @override
  SemanticsNode get parent => super.parent;

  @override
  void redepthChildren() {
    if (_children != null) {
      for (SemanticsNode child in _children)
        redepthChild(child);
    }
  }

  // Visits all the descendants of this node, calling visitor for each one, until
  // visitor returns false. Returns true if all the visitor calls returned true,
  // otherwise returns false.
  bool _visitDescendants(SemanticsNodeVisitor visitor) {
    if (_children != null) {
      for (SemanticsNode child in _children) {
        if (!visitor(child) || !child._visitDescendants(visitor))
          return false;
      }
    }
    return true;
  }

  static Map<int, SemanticsNode> _nodes = <int, SemanticsNode>{};
  static Set<SemanticsNode> _detachedNodes = new Set<SemanticsNode>();

  @override
  void attach(Object owner) {
    super.attach(owner);
    assert(!_nodes.containsKey(_id));
    _nodes[_id] = this;
    _detachedNodes.remove(this);
    if (parent != null)
      _inheritedMergeAllDescendantsIntoThisNode = parent._shouldMergeAllDescendantsIntoThisNode;
    if (_children != null) {
      for (SemanticsNode child in _children)
        child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    assert(_nodes.containsKey(_id));
    assert(!_detachedNodes.contains(this));
    _nodes.remove(_id);
    _detachedNodes.add(this);
    if (_children != null) {
      for (SemanticsNode child in _children)
        child.detach();
    }
  }

  static List<SemanticsNode> _dirtyNodes = <SemanticsNode>[];
  bool _dirty = false;
  void _markDirty() {
    if (_dirty)
      return;
    _dirty = true;
    assert(!_dirtyNodes.contains(this));
    assert(!_detachedNodes.contains(this));
    _dirtyNodes.add(this);
  }

  mojom.SemanticsNode _serialize() {
    mojom.SemanticsNode result = new mojom.SemanticsNode();
    result.id = _id;
    if (_dirty) {
      // We could be even more efficient about not sending data here, by only
      // sending the bits that are dirty (tracking the geometry, flags, strings,
      // and children separately). For now, we send all or nothing.
      result.geometry = new mojom.SemanticGeometry();
      result.geometry.transform = transform?.storage;
      result.geometry.top = rect.top;
      result.geometry.left = rect.left;
      result.geometry.width = math.max(rect.width, 0.0);
      result.geometry.height = math.max(rect.height, 0.0);
      result.flags = new mojom.SemanticFlags();
      result.flags.canBeTapped = canBeTapped;
      result.flags.canBeLongPressed = canBeLongPressed;
      result.flags.canBeScrolledHorizontally = canBeScrolledHorizontally;
      result.flags.canBeScrolledVertically = canBeScrolledVertically;
      result.flags.hasCheckedState = hasCheckedState;
      result.flags.isChecked = isChecked;
      result.strings = new mojom.SemanticStrings();
      result.strings.label = label;
      List<mojom.SemanticsNode> children = <mojom.SemanticsNode>[];
      if (_shouldMergeAllDescendantsIntoThisNode) {
        _visitDescendants((SemanticsNode node) {
          result.flags.canBeTapped = result.flags.canBeTapped || node.canBeTapped;
          result.flags.canBeLongPressed = result.flags.canBeLongPressed || node.canBeLongPressed;
          result.flags.canBeScrolledHorizontally = result.flags.canBeScrolledHorizontally || node.canBeScrolledHorizontally;
          result.flags.canBeScrolledVertically = result.flags.canBeScrolledVertically || node.canBeScrolledVertically;
          result.flags.hasCheckedState = result.flags.hasCheckedState || node.hasCheckedState;
          result.flags.isChecked = result.flags.isChecked || node.isChecked;
          if (node.label != '')
            result.strings.label = result.strings.label.isNotEmpty ? '${result.strings.label}\n${node.label}' : node.label;
          node._dirty = false;
          return true; // continue walk
        });
        // and we pretend to have no children
      } else {
        if (_children != null) {
          for (SemanticsNode child in _children)
            children.add(child._serialize());
        }
      }
      result.children = children;
      _dirty = false;
    }
    return result;
  }

  static List<mojom.SemanticsListener> _listeners;

  /// Whether there are currently any consumers of semantic data.
  ///
  /// If there are no consumers of semantic data, there is no need to compile
  /// semantic data into a [SemanticsNode] tree.
  static bool get hasListeners => _listeners != null && _listeners.length > 0;

  /// Called when the first consumer of semantic data arrives.
  ///
  /// Typically set by [RendererBinding].
  static VoidCallback onSemanticsEnabled;

  /// Add a consumer of semantic data.
  ///
  /// After the [PipelineOwner] updates the semantic data for a given frame, it
  /// calls [sendSemanticsTree], which uploads the data to each listener
  /// registered with this function.
  static void addListener(mojom.SemanticsListener listener) {
    if (!hasListeners) {
      assert(onSemanticsEnabled != null); // initialise the binding _before_ adding listeners
      onSemanticsEnabled();
    }
    _listeners ??= <mojom.SemanticsListener>[];
    _listeners.add(listener);
  }

  /// Uploads the semantics tree to the listeners registered with [addListener].
  static void sendSemanticsTree() {
    assert(hasListeners);
    for (SemanticsNode oldNode in _detachedNodes) {
      // The other side will have forgotten this node if we even send
      // it again, so make sure to mark it dirty so that it'll get
      // sent if it is resurrected.
      oldNode._dirty = true;
    }
    _detachedNodes.clear();
    if (_dirtyNodes.isEmpty)
      return;
    _dirtyNodes.sort((SemanticsNode a, SemanticsNode b) => a.depth - b.depth);
    for (int index = 0; index < _dirtyNodes.length; index += 1) {
      // we mutate the list as we walk it here, which is why we use an index instead of an iterator
      SemanticsNode node = _dirtyNodes[index];
      assert(node._dirty);
      assert(node.parent == null || !node.parent._shouldMergeAllDescendantsIntoThisNode || node._inheritedMergeAllDescendantsIntoThisNode);
      if (node._shouldMergeAllDescendantsIntoThisNode) {
        assert(node.mergeAllDescendantsIntoThisNode || node.parent != null);
        if (node.mergeAllDescendantsIntoThisNode ||
            node.parent != null && node.parent._shouldMergeAllDescendantsIntoThisNode) {
          // if we're merged into our parent, make sure our parent is added to the list
          if (node.parent != null && node.parent._shouldMergeAllDescendantsIntoThisNode)
            node.parent._markDirty(); // this can add the node to the dirty list
          // make sure all the descendants are also marked, so that if one gets marked dirty later we know to walk up then too
          if (node._children != null) {
            for (SemanticsNode child in node._children)
              child._inheritedMergeAllDescendantsIntoThisNode = true; // this can add the node to the dirty list
          }
        } else {
          // we previously were being merged but aren't any more
          // update our bits and all our descendants'
          assert(node._inheritedMergeAllDescendantsIntoThisNode);
          assert(!node.mergeAllDescendantsIntoThisNode);
          assert(node.parent == null || !node.parent._shouldMergeAllDescendantsIntoThisNode);
          node._inheritedMergeAllDescendantsIntoThisNode = false;
          if (node._children != null) {
            for (SemanticsNode child in node._children)
              child._inheritedMergeAllDescendantsIntoThisNode = false; // this can add the node to the dirty list
          }
        }
      }
      assert(_dirtyNodes[index] == node); // make sure nothing went in front of us in the list
    }
    _dirtyNodes.sort((SemanticsNode a, SemanticsNode b) => a.depth - b.depth);
    List<mojom.SemanticsNode> updatedNodes = <mojom.SemanticsNode>[];
    for (SemanticsNode node in _dirtyNodes) {
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
        updatedNodes.add(node._serialize());
    }
    for (mojom.SemanticsListener listener in _listeners)
      listener.updateSemanticsTree(updatedNodes);
    _dirtyNodes.clear();
  }

  static SemanticActionHandler _getSemanticActionHandlerForId(int id, { _SemanticFlags neededFlag }) {
    assert(neededFlag != null);
    SemanticsNode result = _nodes[id];
    if (result != null && result._shouldMergeAllDescendantsIntoThisNode && !result._canHandle(neededFlag)) {
      result._visitDescendants((SemanticsNode node) {
        if (node._actionHandler != null && node._flags[neededFlag]) {
          result = node;
          return false; // found node, abort walk
        }
        return true; // continue walk
      });
    }
    if (result == null || !result._canHandle(neededFlag))
      return null;
    return result._actionHandler;
  }

  @override
  String toString() {
    return '$runtimeType($_id'
             '${_dirty ? " (${ _dirtyNodes.contains(this) ? 'dirty' : 'STALE' })" : ""}'
             '${_shouldMergeAllDescendantsIntoThisNode ? " (leaf merge)" : ""}'
             '; $rect'
             '${wasAffectedByClip ? " (clipped)" : ""}'
             '${canBeTapped ? "; canBeTapped" : ""}'
             '${canBeLongPressed ? "; canBeLongPressed" : ""}'
             '${canBeScrolledHorizontally ? "; canBeScrolledHorizontally" : ""}'
             '${canBeScrolledVertically ? "; canBeScrolledVertically" : ""}'
             '${hasCheckedState ? (isChecked ? "; checked" : "; unchecked") : ""}'
             '${label != "" ? "; \"$label\"" : ""}'
           ')';
  }

  /// Returns a string representation of this node and its descendants.
  String toStringDeep([String prefixLineOne = '', String prefixOtherLines = '']) {
    String result = '$prefixLineOne$this\n';
    if (_children != null && _children.isNotEmpty) {
      for (int index = 0; index < _children.length - 1; index += 1) {
        SemanticsNode child = _children[index];
        result += '${child.toStringDeep("$prefixOtherLines \u251C", "$prefixOtherLines \u2502")}';
      }
      result += '${_children.last.toStringDeep("$prefixOtherLines \u2514", "$prefixOtherLines  ")}';
    }
    return result;
  }
}

/// Exposes the [SemanticsNode] tree to the underlying platform.
class SemanticsServer extends mojom.SemanticsServer {
  @override
  void addSemanticsListener(mojom.SemanticsListenerProxy listener) {
    // TODO(abarth): We should remove the listener when this pipe closes.
    // See <https://github.com/flutter/flutter/issues/3342>.
    SemanticsNode.addListener(listener.ptr);
  }

  @override
  void tap(int nodeID) {
    SemanticsNode._getSemanticActionHandlerForId(nodeID, neededFlag: _SemanticFlags.canBeTapped)?.handleSemanticTap();
  }

  @override
  void longPress(int nodeID) {
    SemanticsNode._getSemanticActionHandlerForId(nodeID, neededFlag: _SemanticFlags.canBeLongPressed)?.handleSemanticLongPress();
  }

  @override
  void scrollLeft(int nodeID) {
    SemanticsNode._getSemanticActionHandlerForId(nodeID, neededFlag: _SemanticFlags.canBeScrolledHorizontally)?.handleSemanticScrollLeft();
  }

  @override
  void scrollRight(int nodeID) {
    SemanticsNode._getSemanticActionHandlerForId(nodeID, neededFlag: _SemanticFlags.canBeScrolledHorizontally)?.handleSemanticScrollRight();
  }

  @override
  void scrollUp(int nodeID) {
    SemanticsNode._getSemanticActionHandlerForId(nodeID, neededFlag: _SemanticFlags.canBeScrolledVertically)?.handleSemanticScrollUp();
  }

  @override
  void scrollDown(int nodeID) {
    SemanticsNode._getSemanticActionHandlerForId(nodeID, neededFlag: _SemanticFlags.canBeScrolledVertically)?.handleSemanticScrollDown();
  }
}
