// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'dart:math' as math;

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
//  * Animation for expand/collapse - custom render object
//  * Breadth/depth traversal - parent data
//  * Semantics
//  * Example code
//  * text direction
//  * pipe through indentation
//  * Tests

/// A data structure for configuring children of a [SliverTree].
///
/// A [SliverTreeNode.content] can be of any type, but must correspond with the same
/// type of the [SliverTree].
///
/// Getters for [depth], [parent] and [isExpanded] are managed by the
/// [SliverTree]'s state.
class SliverTreeNode<T> {
  /// Creates a [SliverTreeNode] instance for use in a [SliverTree].
  SliverTreeNode(
    this.content, {
    List<SliverTreeNode<T>>? children,
    bool expanded = false,
  })  : _expanded = children != null && children.isNotEmpty && expanded,
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

// For code simplicity where used in the widget layer.
typedef _AnimationRecord = ({
  AnimationController controller,
  Animation<double> animation,
});

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
            dimension: 36.0,
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
        const SizedBox(width: 10.0),
        // Content
        Text(node.content.toString()),
      ]),
    );
  }

  @override
  State<SliverTree<T>> createState() => _SliverTreeState<T>();
}

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
  // double? _animationValueFor(SliverTreeNode<T> node) {
  //   if (node.parent == null) {
  //     return null;
  //   }
  //   return _currentAnimationForParent[node.parent!]?.animation.value;
  // }

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
          hasAnimatingChildren: _currentAnimationForParent.keys.contains(node),
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
      final UniqueKey animationKey = UniqueKey();
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
              _activeAnimations.remove(animationKey);
              _currentAnimationForParent.remove(node);
            case AnimationStatus.forward:
            case AnimationStatus.reverse:
          }
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
      );
      final SliverTreeNodesAnimation animatingChildren = (
        // TODO : Fix
        fromIndex: 0,
        toIndex: 0,
        value: newAnimation.value,
      );
      // TODO: Update every other currently running naimation whose index has changed!
      _activeAnimations[animationKey] = animatingChildren;
      _unpackActiveNodes();
      switch (node._expanded) {
        case true:
          // Expanding
          controller.forward();
        case false:
          // Collapsing
          controller.reverse();
      }
    });
  }
}

// Used to pass information down to _RenderSliverTree.
// The depth is used for breadth first traversal, where as depth first traversal
// follows the indexed order. The animationValue is used to compute the offset
// of children that are currently coming into or out of view.
class _TreeNodeParentData extends SliverMultiBoxAdaptorParentData {
  // Whether or not this node is a parent whose child nodes are currently
  // animating.
  //
  // The parent and its animating children are kept alive if scrolled away while
  // the animation is underway so that the relative positioning due to the
  // animation can be respected.
  bool hasAnimatingChildren = false;

  // The depth of the node, used by the render object to traverse nodes in a
  // depth or breadth order.
  int depth = 0;
}

class _TreeNodeParentDataWidget extends ParentDataWidget<_TreeNodeParentData> {
  const _TreeNodeParentDataWidget({
    this.hasAnimatingChildren = false,
    required this.depth,
    required super.child,
  }) : assert(depth >= 0);

  final bool hasAnimatingChildren;
  final int depth;

  @override
  void applyParentData(RenderObject renderObject) {
    final _TreeNodeParentData parentData = renderObject.parentData! as _TreeNodeParentData;
    bool needsLayout = false;
    if (parentData.hasAnimatingChildren != hasAnimatingChildren) {
      parentData.hasAnimatingChildren = hasAnimatingChildren;
      needsLayout = true;
    }

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

// For code simplicity where used in the rendering layer.
///
typedef SliverTreeNodesAnimation = ({
  int fromIndex,
  int toIndex,
  double value,
});

// This will likely need to move to the same file as RenderSliverMultiBoxAdaptor
// to access private API around keep alives
// Lazily lays out children in the tree, accounting for animation offsets.
///
class RenderSliverTree extends RenderSliverVariedExtentList {
  ///
  RenderSliverTree({
    required super.childManager,
    required super.itemExtentBuilder,
    required Map<UniqueKey, SliverTreeNodesAnimation> activeAnimations,
  }) : _activeAnimations = activeAnimations {
    _updateAnimationCache();
  }

  ///
  Map<UniqueKey, SliverTreeNodesAnimation> get activeAnimations => _activeAnimations;
  Map<UniqueKey, SliverTreeNodesAnimation> _activeAnimations;
  set activeAnimations(Map<UniqueKey, SliverTreeNodesAnimation> value) {
    if (_activeAnimations == value) {
      return;
    }
    _activeAnimations = value;
    _updateAnimationCache();
    markNeedsLayout();
  }

  Map<int, UniqueKey> _animationLeadingIndices = <int, UniqueKey>{};
  // Map<int, UniqueKey> _animationIndices = <int, UniqueKey>{};
  Map<UniqueKey, double> _animationOffsets = <UniqueKey, double>{};
  void _updateAnimationCache() {
    // _animationIndices.clear();
    _animationLeadingIndices.clear();
    _activeAnimations.forEach((UniqueKey key, SliverTreeNodesAnimation animation) {
      _animationLeadingIndices[animation.fromIndex] = key;
      // for (int i = animation.fromIndex; i <= animation.toIndex; i++) {
      //   _animationIndices[i] = key;
      // }
    });
    // Remove any stored offsets that are no longer actively animating.
    _animationOffsets.removeWhere((UniqueKey key, _) => !_activeAnimations.keys.contains(key));
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TreeNodeParentData) {
      child.parentData = _TreeNodeParentData();
    }
  }

  late SliverLayoutDimensions _currentLayoutDimensions;
  @override
  void performLayout() {
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
        if (_animationOffsets[_animationLeadingIndices[index]] == null) {
          // We have not computed the distance this block is traversing over the
          // lifetime of the animation.
          _computeAnimationOffsetFor(_animationLeadingIndices[index]!, position);
        }
        totalAnimationOffset += _animationOffsets[_animationLeadingIndices[index]]!;
      }
      position += itemExtent - totalAnimationOffset;
      ++index;
    }
    return index - 1;
  }

  void _computeAnimationOffsetFor(UniqueKey key, double position) {
    assert(_activeAnimations[key] != null);
    final targetPosition = constraints.scrollOffset + constraints.remainingCacheExtent;
    double currentPosition = position;
    // We animate only a portion of children that would be visible/in the cache
    // extent, unless all would fit on the screen.
    final int startingIndex = _activeAnimations[key]!.fromIndex;
    final int lastIndex = _activeAnimations[key]!.toIndex;
    int currentIndex = startingIndex;
    double totalOffset = 0.0;
    while (startingIndex <= lastIndex && currentPosition < targetPosition) {

    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // account for clips needed for animating segments
    super.paint(context, offset);
  }

  // visit children methods - depth versus breadth traversal

  // See methods in RenderSliverFixedExtentBoxAdaptor as well

  // Don't forget keep alives
}
