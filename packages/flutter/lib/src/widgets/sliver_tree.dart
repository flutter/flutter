// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'icon.dart';
import 'icon_data.dart';
import 'implicit_animations.dart';
import 'scroll_delegate.dart';
import 'sliver.dart';
import 'sliver_varied_extent_list.dart';
import 'text.dart';
import 'ticker_provider.dart';

// TODO(Piinks): still to cover
//  * Clip layers for animations
//  * Breadth/depth traversal - parent data
//  * Semantics
//  * Example code
//  * pipe through indentation as an enhanced enum, remove from row builder, implement in render object
//  * Tests

/// A data structure for configuring children of a [SliverTree].
///
/// A [SliverTreeNode.content] can be of any type, but must correspond with the
/// same type of the [SliverTree].
///
/// Getters for [depth], [parent] and [isExpanded] are managed by the
/// [SliverTree]'s state.
class SliverTreeNode<T> {
  /// Creates a [SliverTreeNode] instance for use in a [SliverTree].
  SliverTreeNode(
    this.content, {
    List<SliverTreeNode<T>>? children,
    bool expanded = false,
  }) : _expanded = children != null && children.isNotEmpty && expanded,
       children = children ?? <SliverTreeNode<T>>[];

  /// The subject matter of the node.
  ///
  /// Must correspond with the type of [SliverTree].
  final T content;

  /// Other [SliverTreeNode]s this this node will be [parent] to.
  final List<SliverTreeNode<T>> children;

  /// Whether or not this node is expanded in the tree.
  ///
  /// Cannot be expanded is there are no children.
  bool get isExpanded => _expanded;
  bool _expanded;

  /// The number of parent nodes between this node and the root of the tree.
  int? get depth => _depth;
  int? _depth;

  /// The parent [SliverTreeNode] of this node.
  SliverTreeNode<T>? get parent => _parent;
  SliverTreeNode<T>? _parent;

  @override
  String toString() {
    return 'SliverTreeNode: $content, depth: ${depth == 0 ? 'root' : depth}, '
      '${children.isEmpty ? 'leaf' : 'parent, expanded: $isExpanded'}';
  }
}

/// Signature for a function that creates a [Widget] to represent the given
/// [SliverTreeNode] in the [SliverTree].
///
/// Used by [SliverTree.treeRowBuilder] to build rows on demand for the
/// tree.
typedef TreeRowBuilder = Widget Function(
  BuildContext context,
  SliverTreeNode<dynamic> node, {
  AnimationStyle? animationStyle,
});

/// Signature for a function that returns an extent for the given
/// [SliverTreeNode] in the [SliverTree].
///
/// Used by [SliverTree.treeRowExtentBuilder] to size rows on demand in the
/// tree. The provided [SliverLayoutDimensions] provide information about the
/// current scroll state and [Viewport] dimensions.
///
/// See also:
///
///   * [SliverVariedExtentList], which uses a similar item extent builder for
///     dynamic child sizing in the list.
typedef TreeRowExtentBuilder = double Function(
  SliverTreeNode<dynamic> node,
  SliverLayoutDimensions dimensions,
);

/// Signature for a function that is called when a [SliverTreeNode] is toggled,
/// changing its expanded state.
///
/// See also:
///
///   * [SliverTreeNode.toggleNode], for controlling node expansion
///     programmatically.
typedef TreeNodeCallback = void Function(SliverTreeNode<dynamic> node);

/// A mixin for classes implementing a tree structure as expected by a
/// [TreeController].
///
/// Used by [SliverTree] to implement an interface for the [TreeController].
///
/// This allows the [TreeController] to be used in other widgets that implement
/// this interface.
mixin TreeStateMixin<T> {
  /// Returns whether or not the given [SliverTreeNode] is expanded.
  bool isExpanded(SliverTreeNode<T> node);

  /// Returns whether or not the given [SliverTreeNode] is enclosed within its parent
  /// [SliverTreeNode].
  ///
  /// If the [TreeNode.parent] [isExpanded], or this is a root node, the given
  /// node is active and this method will return true. This does not reflect
  /// whether or not the node is visible in the [Viewport].
  bool isActive(SliverTreeNode<T> node);

  /// Switches the given [SliverTreeNode]s expanded state.
  ///
  /// May trigger an animation to reveal or hide the node's children based on
  /// the [SliverTree.animationStyle].
  ///
  /// If the node does not have any children, nothing will happen.
  void toggleNode(SliverTreeNode<T> node);

  /// Closes all parent [SliverTreeNode]s in the tree.
  void collapseAll();

  /// Expands all parent [SliverTreeNode]s in the tree.
  void expandAll();

  /// Retrieves the [SliverTreeNode] containing the associated content, if it exists.
  ///
  /// If no node exists, this will return null. This does not reflect whether
  /// or not a node [isActive], or if it is visible in the viewport.
  SliverTreeNode<T>? getNodeFor(T content);
}

/// Enables control over the [TreeNodes] of a [SliverTree].
///
/// It can be useful to expand or collapse nodes of the tree
/// programmatically, for example to reconfigure an existing node
/// based on a system event. To do so, create an [SliverTree]
/// with an [TreeController] that's owned by a stateful widget
/// or look up the tile's automatically created [TreeController]
/// with [TreeController.of]
///
/// The controller's methods to expand or collapse nodes cause the
/// the [SliverTree] to rebuild, so they may not be called from
/// a build method.
class TreeController {
  /// Create a controller to be used with [SliverTree.controller].
  TreeController();

  TreeStateMixin<dynamic>? _state;

  /// Whether the given [SliverTreeNode] built with this controller is in an
  /// expanded state.
  ///
  /// This property doesn't take the animation into account. It reports `true`
  /// even if the expansion animation is not completed.
  ///
  /// See also:
  ///
  ///  * [expandNode], which expands a given [SliverTreeNode].
  ///  * [collapseNode], which collapses a given [SliverTreeNode].
  ///  * [SliverTree.controller] to create an SliverTree with a controller.
  bool isExpanded(SliverTreeNode<dynamic> node) {
    assert(_state != null);
    return _state!.isExpanded(node);
  }

  /// Whether or not the given [SliverTreeNode] is enclosed within its parent
  /// [SliverTreeNode].
  ///
  /// If the [TreeNode.parent] [isExpanded], or this is a root node, the given
  /// node is active and this method will return true. This does not reflect
  /// whether or not the node is visible in the [Viewport].
  bool isActive(SliverTreeNode<dynamic> node) {
    assert(_state != null);
    return _state!.isActive(node);
  }

  /// Returns the [SliverTreeNode] containing the associated content, if it exists.
  ///
  /// If no node exists, this will return null. This does not reflect whether
  /// or not a node [isActive], or if it is currently visible in the viewport.
  SliverTreeNode<dynamic>? getNodeFor(dynamic content) {
    assert(_state != null);
    return _state!.getNodeFor(content);
  }

  /// Switches the given [SliverTreeNode]s expanded state.
  ///
  /// May trigger an animation to reveal or hide the node's children based on
  /// the [SliverTree.animationStyle].
  ///
  /// If the node does not have any children, nothing will happen.
  void toggleNode(SliverTreeNode<dynamic> node) {
    assert(_state != null);
    return _state!.toggleNode(node);
  }

  /// Expands the [SliverTreeNode] that was built with this controller.
  ///
  /// If the node is already in the expanded state (see [isExpanded]), calling
  /// this method has no effect.
  ///
  /// Calling this method may cause the [SliverTree] to rebuild, so it may
  /// not be called from a build method.
  ///
  /// Calling this method will trigger an [SliverTree.onNodeToggle] callback.
  ///
  /// See also:
  ///
  ///  * [collapseNode], which collapses the [SliverTreeNode].
  ///  * [isExpanded] to check whether the tile is expanded.
  ///  * [SliverTree.controller] to create an SliverTree with a controller.
  void expandNode(SliverTreeNode<dynamic> node) {
    assert(_state != null);
    if (!node.isExpanded) {
      _state!.toggleNode(node);
    }
  }

  /// Expands all parent [SliverTreeNode]s in the tree.
  void expandAll() {
    assert(_state != null);
    _state!.expandAll();
  }

  /// Closes all parent [SliverTreeNode]s in the tree.
  void collapseAll() {
    assert(_state != null);
    _state!.collapseAll();
  }

  /// Collapses the [SliverTreeNode] that was built with this controller.
  ///
  /// If the node is already in the collapsed state (see [isExpanded]), calling
  /// this method has no effect.
  ///
  /// Calling this method may cause the [SliverTree] to rebuild, so it may
  /// not be called from a build method.
  ///
  /// Calling this method will trigger an [SliverTree.onNodeToggle] callback.
  ///
  /// See also:
  ///
  ///  * [expandNode], which expands the tile.
  ///  * [isExpanded] to check whether the tile is expanded.
  ///  * [SliverTree.controller] to create an SliverTree with a controller.
  void collapseNode(SliverTreeNode<dynamic> node) {
    assert(_state != null);
    if (node.isExpanded) {
      _state!.toggleNode(node);
    }
  }

  /// Finds the [TreeController] for the closest [SliverTree] instance
  /// that encloses the given context.
  ///
  /// If no [SliverTree] encloses the given context, calling this
  /// method will cause an assert in debug mode, and throw an
  /// exception in release mode.
  ///
  /// To return null if there is no [SliverTree] use [maybeOf] instead.
  ///
  /// {@tool dartpad}
  /// Typical usage of the [TreeController.of] function is to call it
  /// from within the `build` method of a descendant of an [SliverTree].
  ///
  /// When the [SliverTree] is actually created in the same `build`
  /// function as the callback that refers to the controller, then the
  /// `context` argument to the `build` function can't be used to find
  /// the [TreeController] (since it's "above" the widget
  /// being returned in the widget tree). In cases like that you can
  /// add a [Builder] widget, which provides a new scope with a
  /// [BuildContext] that is "under" the [SliverTree]:
  ///
  // TODO(Piinks): add sample code
  /// {@end-tool}
  static TreeController of(BuildContext context) {
    final _SliverTreeState<dynamic>? result =
        context.findAncestorStateOfType<_SliverTreeState<dynamic>>();
    if (result != null) {
      return result.controller;
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
        'TreeController.of() called with a context that does not contain a '
        'SliverTree.',
      ),
      ErrorDescription(
        'No SliverTree ancestor could be found starting from the context that '
        'was passed to TreeController.of(). '
        'This usually happens when the context provided is from the same '
        'StatefulWidget as that whose build function actually creates the '
        'SliverTree widget being sought.',
      ),
      ErrorHint(
        'There are several ways to avoid this problem. The simplest is to use '
        'a Builder to get a context that is "under" the SliverTree. For an '
        'example of this, please see the documentation for TreeController.of():\n'
        '  https://api.flutter.dev/flutter/material/TreeController/of.html',
      ),
      ErrorHint(
        'A more efficient solution is to split your build function into '
        'several widgets. This introduces a new context from which you can '
        'obtain the SliverTree. In this solution, you would have an outer '
        'widget that creates the SliverTree populated by instances of your new '
        'inner widgets, and then in these inner widgets you would use '
        'TreeController.of().',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// Finds the [SliverTree] from the closest instance of this class that
  /// encloses the given context and returns its [TreeController].
  ///
  /// If no [SliverTree] encloses the given context then return null.
  /// To throw an exception instead, use [of] instead of this function.
  ///
  /// See also:
  ///
  ///  * [of], a similar function to this one that throws if no [SliverTree]
  ///    encloses the given context. Also includes some sample code in its
  ///    documentation.
  static TreeController? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_SliverTreeState<dynamic>>()?.controller;
  }
}

/// A sliver for lazily displaying [SliverTreeNode]s that expand and collapse in a
/// vertically scrolling [Viewport].
class SliverTree<T> extends StatefulWidget {
  /// Creates an instance of a SliverTree.
  // TODO(Piinks): Add semantic info to constructor (see build in state)
  const SliverTree({
    super.key,
    required this.tree,
    this.treeRowBuilder = SliverTree.defaultTreeRowBuilder,
    this.treeRowExtentBuilder = SliverTree.defaultTreeRowExtentBuilder,
    this.controller,
    this.onNodeToggle,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.findChildIndexCallback,
    this.animationStyle,
  });

  /// The list of [SliverTreeNode]s that may be displayed in the [SliverTree].
  ///
  /// Beyond root nodes, whether or not a given [SliverTreeNode] is displayed depends
  /// on the [SliverTreeNode.isExpanded] value of its parent. The [SliverTree] will
  /// set the [SliverTreeNode.parent] and [SliverTreeNode.depth] as nodes are built on
  /// demand to ensure the integrity of the tree.
  final List<SliverTreeNode<T>> tree;

  /// Called to build and entry of the [SliverTree] for the given node.
  ///
  /// By default, if this is unset, the [SliverTree.defaultTreeRowBuilder] is
  /// used.
  final TreeRowBuilder treeRowBuilder;

  /// Called to calculate the extent of the widget built for the given
  /// [SliverTreeNode].
  ///
  /// By default, if this is unset, the [SliverTree.defaultTreeRowExtentBuilder]
  /// is used.
  ///
  /// See also:
  ///
  ///   * [SliverVariedExtentList.itemExtentBuilder], a very similar method that
  ///     allows users to dynamically compute extents on demand.
  final TreeRowExtentBuilder treeRowExtentBuilder;

  /// If provided, the controller can be used to expand and collapse
  /// [SliverTreeNode]s, or lookup information about the current state of the
  /// [SliverTree].
  final TreeController? controller;

  /// Called when a [SliverTreeNode] expands or collapses.
  ///
  /// This will not be called if a [SliverTreeNode] does not have any children.
  final TreeNodeCallback? onNodeToggle;

  /// {@macro flutter.widgets.SliverChildBuilderDelegate.addAutomaticKeepAlives}
  final bool addAutomaticKeepAlives;

  /// {@macro flutter.widgets.SliverChildBuilderDelegate.addRepaintBoundaries}
  final bool addRepaintBoundaries;

  /// {@macro flutter.widgets.SliverChildBuilderDelegate.addSemanticIndexes}
  final bool addSemanticIndexes;

  /// {@macro flutter.widgets.SliverChildBuilderDelegate.findChildIndexCallback}
  final int? Function(Key)? findChildIndexCallback;

  /// Used to override the toggle animation's curve and duration.
  ///
  /// If [AnimationStyle.duration] is provided, it will be used to override
  /// the [SliverTree.defaultAnimationDuration], which defaults to 150
  /// milliseconds.
  ///
  /// If [AnimationStyle.curve] is provided, it will be used to override
  /// the [SliverTree.defaultAnimationCurve], defaults to [Curves.linear].
  ///
  /// To disable the tree animation, use [AnimationStyle.noAnimation].
  final AnimationStyle? animationStyle;

  /// A default of [Curves.linear], which is used in the tree's expanding and
  /// collapsing node animation.
  static const Curve defaultAnimationCurve = Curves.linear;

  /// A default [Duration] of 150 milliseconds, which is used in the tree's
  /// expanding and collapsing node animation.
  static const Duration defaultAnimationDuration = Duration(milliseconds: 150);

  /// A wrapper method for triggering the expansion or collapse of a [SliverTreeNode].
  ///
  /// Use as part of [SliverTree.defaultTreeRowBuilder] to wrap the leading icon
  /// of parent [TreeNodes] such that tapping on it triggers the animation.
  ///
  /// If defining your own [SliverTree.treeRowBuilder], this method can be used
  /// to wrap any part, or all, of the returned widget in order to trigger the
  /// change in state for the node.
  static Widget toggleNodeWith({
    required SliverTreeNode<dynamic> node,
    required Widget child,
  }) {
    return Builder(builder: (BuildContext context) {
      return GestureDetector(
        onTap: () {
          TreeController.of(context).toggleNode(node);
        },
        child: child,
      );
    });
  }

  /// Returns the fixed default extent for rows in the tree, which is 40 pixels.
  ///
  /// Used by [SliverTree.defaultTreeRowExtentBuilder].
  static double defaultTreeRowExtentBuilder(
    SliverTreeNode<dynamic> node,
    SliverLayoutDimensions dimensions,
  ) {
    return 40.0;
  }

  /// Returns the default tree row for a given [SliverTreeNode].
  ///
  /// Used by [SliverTree.defaultTreeRowBuilder].
  ///
  /// This will return a [Row] containing the [toString] of [SliverTreeNode.content].
  /// If the [SliverTreeNode] is a parent of additional nodes, a arrow icon will
  /// precede the content, and will trigger an expand and collapse animation
  /// when tapped.
  static Widget defaultTreeRowBuilder(
    BuildContext context,
    SliverTreeNode<dynamic> node, {
    AnimationStyle? animationStyle
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: <Widget>[
        // Indent
        SizedBox.square(dimension: node.depth! * 10.0),
        // Icon for parent nodes
        toggleNodeWith(
          node: node,
          child: SizedBox.square(
            dimension: 34.0,
            child: node.children.isNotEmpty
                ? AnimatedRotation(
                    turns: node.isExpanded ? 0.25 : 0.0,
                    duration: animationStyle?.duration ?? defaultAnimationDuration,
                    curve: animationStyle?.curve ?? defaultAnimationCurve,
                    child: const Icon(IconData(0x25BA), size: 15),
                  )
                : null,
          ),
        ),
        // Spacer
        const SizedBox(width: 8.0),
        // Content
        Text(node.content.toString()),
      ]),
    );
  }

  @override
  State<SliverTree<T>> createState() => _SliverTreeState<T>();
}

// Used in _SliverTreeState for code simplicity.
typedef _AnimationRecord = ({
  AnimationController controller,
  Animation<double> animation,
  UniqueKey key,
});

class _SliverTreeState<T> extends State<SliverTree<T>> with TickerProviderStateMixin, TreeStateMixin<T> {
  TreeController get controller => _treeController!;
  TreeController? _treeController;

  final List<SliverTreeNode<T>> _activeNodes = <SliverTreeNode<T>>[];
  void _unpackActiveNodes({
    int depth = 0,
    List<SliverTreeNode<T>>? nodes,
    SliverTreeNode<T>? parent,
  }) {
    if (nodes == null) {
      _activeNodes.clear();
      nodes = widget.tree;
    }
    for (final SliverTreeNode<T> node in nodes) {
      node._depth = depth;
      node._parent = parent;
      _activeNodes.add(node);
      if (node.children.isNotEmpty && node.isExpanded) {
        _unpackActiveNodes(
          depth: depth + 1,
          nodes: node.children,
          parent: node,
        );
      }
    }
  }

  final Map<SliverTreeNode<T>, _AnimationRecord> _currentAnimationForParent = <SliverTreeNode<T>, _AnimationRecord>{};
  final Map<UniqueKey, SliverTreeNodesAnimation> _activeAnimations = <UniqueKey, SliverTreeNodesAnimation>{};

  @override
  void initState() {
    _unpackActiveNodes();
    assert(widget.controller?._state == null);
    _treeController = widget.controller ?? TreeController();
    _treeController!._state = this;
    super.initState();
  }

  @override
  void didUpdateWidget(SliverTree<T> oldWidget) {
    // Internal or provided, there is always a tree controller.
    assert(_treeController != null);
    if (oldWidget.controller == null && widget.controller != null) {
      // A new tree controller has been provided, update and dispose of the
      // internally generated one.
      _treeController!._state = null;
      _treeController = widget.controller;
      _treeController!._state = this;
    } else if (oldWidget.controller != null && widget.controller == null) {
      // A tree controller had been provided, but was removed. We need to create
      // one internally.
      assert(oldWidget.controller == _treeController);
      oldWidget.controller!._state = null;
      _treeController = TreeController();
      _treeController!._state = this;
    } else if (oldWidget.controller != widget.controller) {
      assert(oldWidget.controller != null);
      assert(widget.controller != null);
      assert(oldWidget.controller == _treeController);
      // The tree is still being provided a controller, but it has changed. Just
      // update it.
      _treeController!._state = null;
      _treeController = widget.controller;
      _treeController!._state = this;
    }
    // Internal or provided, there is always a tree controller.
    assert(_treeController != null);
    assert(_treeController!._state != null);
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _treeController!._state = null;
    for (final _AnimationRecord record in _currentAnimationForParent.values) {
      record.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SliverTree(
      itemCount: _activeNodes.length,
      activeAnimations: _activeAnimations,
      itemBuilder: (BuildContext context, int index) {
        final SliverTreeNode<T> node = _activeNodes[index];
        Widget child = widget.treeRowBuilder(
          context,
          node,
          animationStyle: widget.animationStyle,
        );

        if (widget.addRepaintBoundaries) {
          child = RepaintBoundary(child: child);
        }
        if (widget.addSemanticIndexes) {
          // TODO(Piinks): see todo on constructor
          // final int? semanticIndex = widget.semanticIndexCallback(child, index);
          // if (semanticIndex != null) {
            child = IndexedSemantics(index: index/*semanticIndex + semanticIndexOffset*/, child: child);
          // }
        }

        return _TreeNodeParentDataWidget(
          depth: node.depth!,
          child: child,
        );
      },
      itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) {
        return widget.treeRowExtentBuilder(_activeNodes[index], dimensions);
      },
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      findChildIndexCallback: widget.findChildIndexCallback,
    );
  }

  // TreeStateMixin Implementation

  @override
  bool isExpanded(SliverTreeNode<T> node) {
    return _getNode(node.content, widget.tree)?.isExpanded ?? false;
  }

  @override
  bool isActive(SliverTreeNode<T> node) => _activeNodes.contains(node);

  @override
  SliverTreeNode<T>? getNodeFor(T content) => _getNode(content, widget.tree);
  SliverTreeNode<T>? _getNode(T content, List<SliverTreeNode<T>> tree) {
    for (final SliverTreeNode<T> node in tree) {
      if (node.content == content) {
        return node;
      }
      if (node.children.isNotEmpty) {
        return _getNode(content, node.children);
      }
    }
    return null;
  }

  @override
  void expandAll() => _expand(widget.tree);
  void _expand(List<SliverTreeNode<T>> tree) {
    for (final SliverTreeNode<T> node in tree) {
      if (node.children.isNotEmpty) {
        if (!node.isExpanded) {
          toggleNode(node);
        }
        _expand(node.children);
      }
    }
  }

  @override
  void collapseAll() => _collapse(widget.tree);
  void _collapse(List<SliverTreeNode<T>> tree) {
    for (final SliverTreeNode<T> node in tree) {
      if (node.children.isNotEmpty) {
        if (node.isExpanded) {
          toggleNode(node);
        }
        _collapse(node.children);
      }
    }
  }

  void _updateActiveAnimations() {
    // The indexes of various child node animations can change constantly based
    // on more nodes being expanded or collapsed. Compile the indexes and their
    // animations keys each time we build with an updated active node list.
    _activeAnimations.clear();
    for (final SliverTreeNode<T> node in _currentAnimationForParent.keys) {
      final _AnimationRecord animationRecord = _currentAnimationForParent[node]!;
      final int leadingChildIndex = _activeNodes.indexOf(node) + 1;
      final SliverTreeNodesAnimation animatingChildren = (
        fromIndex: leadingChildIndex,
        toIndex: leadingChildIndex + node.children.length - 1,
        value: animationRecord.animation.value,
      );
      _activeAnimations[animationRecord.key] = animatingChildren;
    }
  }

  @override
  void toggleNode(SliverTreeNode<T> node) {
    assert(_activeNodes.contains(node));
    if (node.children.isEmpty) {
      // No state to change.
      return;
    }
    setState(() {
      node._expanded = !node._expanded;
      if (widget.onNodeToggle != null) {
        widget.onNodeToggle!(node);
      }
      final AnimationController controller = _currentAnimationForParent[node]?.controller
        ?? AnimationController(
          value: node._expanded ? 0.0 : 1.0,
          vsync: this,
          duration: widget.animationStyle?.duration ?? SliverTree.defaultAnimationDuration,
        )..addStatusListener((AnimationStatus status) {
          switch(status) {
            case AnimationStatus.dismissed:
            case AnimationStatus.completed:
              _currentAnimationForParent[node]!.controller.dispose();
              _currentAnimationForParent.remove(node);
              _updateActiveAnimations();
            case AnimationStatus.forward:
            case AnimationStatus.reverse:
          }
        })..addListener(() {
          setState((){
            _updateActiveAnimations();
          });
        });

      switch(controller.status) {
        case AnimationStatus.forward:
        case AnimationStatus.reverse:
          // We're interrupting an animation already in progress.
          controller.stop();
        case AnimationStatus.dismissed:
        case AnimationStatus.completed:
      }

      final Animation<double> newAnimation = CurvedAnimation(
        parent: controller,
        curve: widget.animationStyle?.curve ?? SliverTree.defaultAnimationCurve,
      );
      _currentAnimationForParent[node] = (
        controller: controller,
        animation: newAnimation,
        // This key helps us keep track of the lifetime of this animation in the
        // render object, since the indexes can change at any time.
        key: UniqueKey(),
      );
      switch (node._expanded) {
        case true:
          // Expanding
          // Adds new nodes that are coming into view.
          _unpackActiveNodes();
          controller.forward();
        case false:
          // Collapsing
          controller.reverse().then((_) {
            // Removes nodes that have been hidden after the collapsing
            // animation completes.
            _unpackActiveNodes();
          });
      }
    });
  }
}

// Used to pass information down to _RenderSliverTree.
// The depth is used for breadth first traversal, where as depth first traversal
// follows the indexed order. The animationValue is used to compute the offset
// of children that are currently coming into or out of view.
class _TreeNodeParentData extends SliverMultiBoxAdaptorParentData {
  // The depth of the node, used by the render object to traverse nodes in a
  // depth or breadth order.
  int depth = 0;
}

class _TreeNodeParentDataWidget extends ParentDataWidget<_TreeNodeParentData> {
  const _TreeNodeParentDataWidget({
    required this.depth,
    required super.child,
  }) : assert(depth >= 0);

  final int depth;

  @override
  void applyParentData(RenderObject renderObject) {
    final _TreeNodeParentData parentData = renderObject.parentData! as _TreeNodeParentData;
    bool needsLayout = false;

    if (parentData.depth != depth) {
      assert(depth >= 0);
      parentData.depth = depth;
      needsLayout = true;
    }

    if (needsLayout) {
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _SliverTree;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('depth', depth));
  }
}

class _SliverTree extends SliverVariedExtentList {
  _SliverTree({
    required NullableIndexedWidgetBuilder itemBuilder,
    required super.itemExtentBuilder,
    required this.activeAnimations,
    ChildIndexGetter? findChildIndexCallback,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
  }) : super(delegate: SliverChildBuilderDelegate(
    itemBuilder,
    findChildIndexCallback: findChildIndexCallback,
    childCount: itemCount,
    addAutomaticKeepAlives: addAutomaticKeepAlives,
    addRepaintBoundaries: false, // Added in the _SliverTreeState
    addSemanticIndexes: false, // Added in the _SliverTreeState
  ));

  final Map<UniqueKey, SliverTreeNodesAnimation> activeAnimations;

  @override
  RenderSliverTree createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverTree(
      itemExtentBuilder: itemExtentBuilder,
      activeAnimations: activeAnimations,
      childManager: element,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverTree renderObject) {
    renderObject
      ..itemExtentBuilder = itemExtentBuilder
      ..activeAnimations = activeAnimations;
  }
}

/// Represents the animation of the children of a parent [SliverTreeNode] that
/// are animating into or out of view.
///
/// The [fromIndex] and [toIndex] are inclusive of the children following the
/// parent, with the [value] representing the status of the current animation.
///
/// Provided to [RenderSliverTree] by [SliverTree] to properly offset animating
/// children.
typedef SliverTreeNodesAnimation = ({
  int fromIndex,
  int toIndex,
  double value,
});

// This will likely need to move to the same file as RenderSliverMultiBoxAdaptor
// to access private API around keep alives and visiting children in depth and breadth first traversal order

/// A sliver that places multiple [SliverTreeNode]s in a linear array along the
/// main access, while staggering nodes that are animating into and out of view.
///
/// The extent of each child node is determined by the [itemExtentBuilder].
///
/// See also:
///
///   * [SliverTree], the widget that creates and manages this render object.
class RenderSliverTree extends RenderSliverVariedExtentList {
  /// Creates the render object that lays out the [SliverTreeNode]s of a
  /// [SliverTree].
  RenderSliverTree({
    required super.childManager,
    required super.itemExtentBuilder,
    required Map<UniqueKey, SliverTreeNodesAnimation> activeAnimations,
  }) : _activeAnimations = activeAnimations;

  // TODO(Piinks): There are some opportunities to cache even further as far as
  // extents and layout offsets when using itemExtentBuilder from the super
  // class as we do here. I want to yak shave that in a separate change.

  /// The currently active [SliverTreeNode] animations.
  ///
  /// Since the index of animating nodes can change at any time, the unique key
  /// is used to track an animation of nodes across frames.
  Map<UniqueKey, SliverTreeNodesAnimation> get activeAnimations => _activeAnimations;
  Map<UniqueKey, SliverTreeNodesAnimation> _activeAnimations;
  set activeAnimations(Map<UniqueKey, SliverTreeNodesAnimation> value) {
    if (_activeAnimations == value) {
      return;
    }
    _activeAnimations = value;
    markNeedsLayout();
  }

  // Maps the index of parents to the animation key of their children.
  final Map<int, UniqueKey> _animationLeadingIndices = <int, UniqueKey>{};
  // Maps ths key of child node animations to the fixed distance they are
  // traversing during the animation. Determined at the start of the animation.
  final Map<UniqueKey, double> _animationOffsets = <UniqueKey, double>{};
  void _updateAnimationCache() {
    _animationLeadingIndices.clear();
    _activeAnimations.forEach((UniqueKey key, SliverTreeNodesAnimation animation) {
      _animationLeadingIndices[animation.fromIndex - 1] = key;
    });
    // Remove any stored offsets or clip layers that are no longer actively
    // animating.
    _animationOffsets.removeWhere((UniqueKey key, _) => !_activeAnimations.keys.contains(key));
    _clipHandles.removeWhere((UniqueKey key, LayerHandle<ClipRectLayer> handle) {
      if (!_activeAnimations.keys.contains(key)) {
        handle.layer = null;
        return true;
      }
      return false;
    });
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TreeNodeParentData) {
      child.parentData = _TreeNodeParentData();
    }
  }

  @override
  void dispose() {
    _clipHandles.removeWhere((UniqueKey key, LayerHandle<ClipRectLayer> handle) {
      handle.layer = null;
      return true;
    });
    super.dispose();
  }

  // TODO(Piinks): This should be made a public getter on the super class.
  // Multiple subclasses are making use of it now, yak shave that refactor
  // separately.
  late SliverLayoutDimensions _currentLayoutDimensions;

  @override
  void performLayout() {
    _updateAnimationCache();
    _currentLayoutDimensions = SliverLayoutDimensions(
        scrollOffset: constraints.scrollOffset,
        precedingScrollExtent: constraints.precedingScrollExtent,
        viewportMainAxisExtent: constraints.viewportMainAxisExtent,
        crossAxisExtent: constraints.crossAxisExtent
    );
    super.performLayout();
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    // itemExtent is deprecated in the super class, we ignore it because we use
    // the builder anyways.
    return _getChildIndexForScrollOffset(scrollOffset);
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    // itemExtent is deprecated in the super class, we ignore it because we use
    // the builder anyways.
    return _getChildIndexForScrollOffset(scrollOffset);
  }

  int _getChildIndexForScrollOffset(double scrollOffset) {
    if (scrollOffset == 0.0) {
      return 0;
    }
    double position = 0.0;
    int index = 0;
    double totalAnimationOffset = 0.0;
    double? itemExtent;
    final int? childCount = childManager.estimatedChildCount;
    while (position < scrollOffset) {
      if (childCount != null && index > childCount - 1) {
        break;
      }

      itemExtent = itemExtentBuilder(index, _currentLayoutDimensions);
      if (itemExtent == null) {
        break;
      }
      if (_animationLeadingIndices.keys.contains(index)) {
        final UniqueKey animationKey = _animationLeadingIndices[index]!;
        if (_animationOffsets[animationKey] == null) {
          // We have not computed the distance this block is traversing over the
          // lifetime of the animation.
          _computeAnimationOffsetFor(animationKey, position);
        }
        // We add the offset accounting for the animation value.
        totalAnimationOffset += _animationOffsets[animationKey]! * (1 - _activeAnimations[animationKey]!.value);
      }
      position += itemExtent - totalAnimationOffset;
      // Reset the animation offset so we do not count it multiple times.
      // totalAnimationOffset = 0.0;
      ++index;
    }
    return index - 1;
  }

  void _computeAnimationOffsetFor(UniqueKey key, double position) {
    assert(_activeAnimations[key] != null);
    final double targetPosition = constraints.scrollOffset + constraints.remainingCacheExtent;
    double currentPosition = position;
    final int startingIndex = _activeAnimations[key]!.fromIndex;
    final int lastIndex = _activeAnimations[key]!.toIndex;
    int currentIndex = startingIndex;
    double totalAnimatingOffset = 0.0;
    // We animate only a portion of children that would be visible/in the cache
    // extent, unless all children would fit on the screen.
    while (currentIndex <= lastIndex && currentPosition < targetPosition) {
      final double itemExtent = itemExtentBuilder(currentIndex, _currentLayoutDimensions)!;
      totalAnimatingOffset += itemExtent;
      currentPosition += itemExtent;
      currentIndex++;
    }
    // For the life of this animation, which affects all children following
    // startingIndex (regardless of if they are a child of the triggering
    // parent), they will be offset by totalAnimatingOffset * the
    // animation value. This is because even though more children can be
    // scrolled into view, the same distance must be maintained for a smooth
    // animation.
    _animationOffsets[key] = totalAnimatingOffset;
  }

  @override
  double indexToLayoutOffset(double itemExtent, int index) {
    // itemExtent is deprecated in the super class, we ignore it because we use
    // the builder anyways.
    double position = 0.0;
    int currentIndex = 0;
    double totalAnimationOffset = 0.0;
    double? itemExtent;
    final int? childCount = childManager.estimatedChildCount;
    while (currentIndex < index) {
      if (childCount != null && currentIndex > childCount - 1) {
        break;
      }

      itemExtent = itemExtentBuilder(currentIndex, _currentLayoutDimensions);
      if (itemExtent == null) {
        break;
      }
      if (_animationLeadingIndices.keys.contains(currentIndex)) {
        final UniqueKey animationKey = _animationLeadingIndices[currentIndex]!;
        assert(_animationOffsets[animationKey] != null);
        // We add the offset accounting for the animation value.
        totalAnimationOffset += _animationOffsets[animationKey]! * (1 - _activeAnimations[animationKey]!.value);
      }
      position += itemExtent;
      currentIndex++;
    }
    return position - totalAnimationOffset;
  }

  final Map<UniqueKey, LayerHandle<ClipRectLayer>> _clipHandles = <UniqueKey, LayerHandle<ClipRectLayer>>{};

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_animationLeadingIndices.isEmpty || firstChild == null) {
      super.paint(context, offset);
      return;
    }
    // Account for clip layers needed for animating segments.
    int leadingIndex = indexOf(firstChild!);
    final List<int> animationIndices = _animationLeadingIndices.keys.toList()..sort();
    final List<({int leadingIndex, int trailingIndex})> paintSegments = <({int leadingIndex, int trailingIndex})>[];
    while (animationIndices.isNotEmpty) {
      final int trailingIndex = animationIndices.removeAt(0);
      paintSegments.add((leadingIndex: leadingIndex, trailingIndex: trailingIndex));
      leadingIndex = trailingIndex + 1;
    }
    paintSegments.add((leadingIndex: leadingIndex, trailingIndex: indexOf(lastChild!)));

    RenderBox? nextChild = firstChild;
    void paintUpTo(int index, RenderBox? child) {
      while (child != null && indexOf(child) <= index) {
        print(indexOf(child));
        final double mainAxisDelta = childMainAxisPosition(child);
        final Offset childOffset = Offset(
          0.0, //TODO(Piinks): Re-implement indent in cross axis position
          (child.parentData! as _TreeNodeParentData).layoutOffset!,
        );

        // If the child's visible interval (mainAxisDelta, mainAxisDelta + paintExtentOf(child))
        // does not intersect the paint extent interval (0, constraints.remainingPaintExtent), it's hidden.
        if (mainAxisDelta < constraints.remainingPaintExtent && mainAxisDelta + paintExtentOf(child) > 0) {
          context.paintChild(child, childOffset);
        }
        child = childAfter(child);
      }
      nextChild = child;
    }
    // Paint, clipping for all but the first segment.
    paintUpTo(paintSegments.removeAt(0).trailingIndex, nextChild);
    // Paint the rest with clip layers.
    while (paintSegments.isNotEmpty) {
      final ({int leadingIndex, int trailingIndex}) segment = paintSegments.removeAt(0);
      // final ({int leadingIndex, int trailingIndex}) segment = paintSegments.removeLast();

      // Rect is calculated by the trailing edge of the parent (preceding
      // leadingIndex), and the trailing edge of the trailing index. We cannot
      // rely on the leading edge of the leading index, because it is currently moving.
      final int parentIndex = math.max(segment.leadingIndex - 1, 0);
      final double leadingOffset = indexToLayoutOffset( 0.0, parentIndex)
        + (parentIndex == 0 ? 0.0 : itemExtentBuilder(parentIndex, _currentLayoutDimensions)!);
      final double trailingOffset = indexToLayoutOffset(0.0, segment.trailingIndex)
        + itemExtentBuilder(segment.trailingIndex, _currentLayoutDimensions)!;
      final Rect rect = Rect.fromPoints(
        Offset(0.0, leadingOffset),
        Offset(constraints.crossAxisExtent, trailingOffset),
      );
      print(rect);
      // We use the same animation key to keep track of the clip layer, unless
      // this is the odd man out segment.
      final UniqueKey key = _animationLeadingIndices[parentIndex]!;
      _clipHandles[key] ??=  LayerHandle<ClipRectLayer>();
      _clipHandles[key]!.layer = context.pushClipRect(
        needsCompositing,
        offset,
        rect,
        (PaintingContext context, Offset offset) {
          paintUpTo(segment.trailingIndex, nextChild);
        },
        oldLayer: _clipHandles[key]!.layer,
      );
    }
  }

  // visit children methods - depth versus breadth traversal

  // Don't forget keep alives
}
