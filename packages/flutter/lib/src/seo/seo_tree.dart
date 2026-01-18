// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'seo_node.dart';

/// Manages the SEO Shadow Tree for a Flutter Web application.
///
/// The [SeoTree] is responsible for:
/// - Maintaining the hierarchy of SEO nodes
/// - Synchronizing with the widget tree
/// - Generating the hidden DOM structure for crawlers
///
/// ## Usage
///
/// Wrap your app with [SeoTreeRoot] to enable SEO functionality:
///
/// ```dart
/// void main() {
///   runApp(
///     SeoTreeRoot(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// Then use [Seo] widgets throughout your app to mark semantic content.
///
/// {@category SEO}
class SeoTree extends InheritedWidget {
  /// Creates an SEO tree provider.
  const SeoTree({
    super.key,
    required this.manager,
    required super.child,
  });

  /// The SEO tree manager instance.
  final SeoTreeManager manager;

  /// Returns the [SeoTreeManager] from the nearest [SeoTree] ancestor.
  ///
  /// Returns null if no [SeoTree] exists in the widget tree.
  static SeoTreeManager? maybeOf(BuildContext context) {
    final seoTree = context.dependOnInheritedWidgetOfExactType<SeoTree>();
    return seoTree?.manager;
  }

  /// Returns the [SeoTreeManager] from the nearest [SeoTree] ancestor.
  ///
  /// Throws if no [SeoTree] exists in the widget tree.
  static SeoTreeManager of(BuildContext context) {
    final manager = maybeOf(context);
    assert(manager != null, 'No SeoTree found in widget tree');
    return manager!;
  }

  @override
  bool updateShouldNotify(SeoTree oldWidget) {
    return manager != oldWidget.manager;
  }
}

/// Root widget that initializes the SEO Shadow Tree.
///
/// This must be placed at the root of your widget tree (above MaterialApp)
/// to enable SEO functionality.
///
/// ```dart
/// void main() {
///   runApp(
///     SeoTreeRoot(
///       sitemapBaseUrl: 'https://example.com',
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// {@category SEO}
class SeoTreeRoot extends StatefulWidget {
  /// Creates an SEO tree root.
  const SeoTreeRoot({
    super.key,
    required this.child,
    this.sitemapBaseUrl,
    this.enabled = true,
    this.debugShowSeoTree = false,
  });

  /// The child widget tree.
  final Widget child;

  /// Base URL for sitemap generation.
  final String? sitemapBaseUrl;

  /// Whether SEO functionality is enabled.
  ///
  /// Set to false to disable SEO processing (e.g., during development
  /// or on non-web platforms).
  final bool enabled;

  /// Whether to show the SEO tree in debug mode.
  ///
  /// When true, the hidden SEO DOM is made visible for debugging.
  final bool debugShowSeoTree;

  @override
  State<SeoTreeRoot> createState() => _SeoTreeRootState();
}

class _SeoTreeRootState extends State<SeoTreeRoot> {
  late SeoTreeManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = SeoTreeManager(
      enabled: widget.enabled,
      debugVisible: widget.debugShowSeoTree,
    );
    _manager.initialize();
  }

  @override
  void didUpdateWidget(SeoTreeRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled ||
        widget.debugShowSeoTree != oldWidget.debugShowSeoTree) {
      _manager.updateSettings(
        enabled: widget.enabled,
        debugVisible: widget.debugShowSeoTree,
      );
    }
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SeoTree(
      manager: _manager,
      child: widget.child,
    );
  }
}

/// Manages the SEO Shadow Tree state and DOM operations.
class SeoTreeManager {
  /// Creates an SEO tree manager.
  SeoTreeManager({
    this.enabled = true,
    this.debugVisible = false,
  });

  /// Whether SEO processing is enabled.
  bool enabled;

  /// Whether the SEO DOM is visible for debugging.
  bool debugVisible;

  /// All registered SEO tree nodes, keyed by their unique ID.
  final Map<int, SeoTreeNode> _nodes = <int, SeoTreeNode>{};

  /// Counter for generating unique node IDs.
  int _nextId = 0;

  /// Whether the manager has been initialized.
  bool _initialized = false;

  /// The root DOM element for the SEO tree (web only).
  /// In actual implementation, this would be an html.Element
  Object? _rootElement;

  /// Initializes the SEO tree manager.
  ///
  /// On web, this creates the hidden DOM container.
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    if (!enabled) return;

    // In web implementation:
    // _rootElement = html.DivElement()
    //   ..id = 'flutter-seo-root'
    //   ..setAttribute('aria-hidden', 'true')
    //   ..style.cssText = _hiddenStyles;
    // html.document.body!.append(_rootElement);

    debugPrint('SeoTreeManager: Initialized');
  }

  /// Updates manager settings.
  void updateSettings({bool? enabled, bool? debugVisible}) {
    if (enabled != null) this.enabled = enabled;
    if (debugVisible != null) {
      this.debugVisible = debugVisible;
      _updateRootVisibility();
    }
  }

  void _updateRootVisibility() {
    // Update CSS to show/hide the SEO tree for debugging
  }

  /// Registers a new SEO node from a widget.
  ///
  /// Returns a [SeoTreeNode] that can be used to update or remove the node.
  SeoTreeNode register(SeoNode node, BuildContext context) {
    if (!enabled) {
      return SeoTreeNode._disabled();
    }

    final id = _nextId++;
    final treeNode = SeoTreeNode._(
      id: id,
      node: node,
      manager: this,
    );

    _nodes[id] = treeNode;
    _insertDomNode(treeNode);

    return treeNode;
  }

  /// Unregisters an SEO node.
  void unregister(SeoTreeNode treeNode) {
    if (!enabled || treeNode._disabled) return;

    _nodes.remove(treeNode.id);
    _removeDomNode(treeNode);
  }

  void _insertDomNode(SeoTreeNode treeNode) {
    // In web implementation, create and insert the DOM element
    // final element = _createDomElement(treeNode.node);
    // _rootElement.append(element);
    // treeNode._domElement = element;
  }

  void _removeDomNode(SeoTreeNode treeNode) {
    // In web implementation, remove the DOM element
    // treeNode._domElement?.remove();
  }

  void _updateDomNode(SeoTreeNode treeNode) {
    // In web implementation, update the DOM element
  }

  /// Generates the complete SEO tree as an HTML string.
  ///
  /// This is useful for server-side rendering or debugging.
  String toHtml() {
    final buffer = StringBuffer();
    buffer.writeln('<div id="flutter-seo-root" aria-hidden="true">');

    // Build a hierarchical structure from flat nodes
    // For simplicity, just output all nodes at root level
    for (final treeNode in _nodes.values) {
      buffer.writeln(treeNode.node.toHtml(indent: 1));
    }

    buffer.writeln('</div>');
    return buffer.toString();
  }

  /// Disposes of the manager and cleans up resources.
  void dispose() {
    _nodes.clear();
    // In web implementation:
    // _rootElement?.remove();
    _rootElement = null;
    _initialized = false;
  }

  static const String _hiddenStyles = '''
    position: absolute !important;
    width: 1px !important;
    height: 1px !important;
    padding: 0 !important;
    margin: -1px !important;
    overflow: hidden !important;
    clip: rect(0, 0, 0, 0) !important;
    white-space: nowrap !important;
    border: 0 !important;
    pointer-events: none !important;
    user-select: none !important;
    z-index: -1 !important;
  ''';
}

/// Represents a node in the SEO Shadow Tree.
///
/// This is returned when registering an [SeoNode] with the [SeoTreeManager].
class SeoTreeNode {
  SeoTreeNode._({
    required this.id,
    required SeoNode node,
    required this.manager,
  })  : _node = node,
        _disabled = false;

  SeoTreeNode._disabled()
      : id = -1,
        _node = const SeoNode(tag: SeoTag.span),
        manager = null,
        _disabled = true;

  /// Unique identifier for this tree node.
  final int id;

  /// The SEO node data.
  SeoNode _node;

  /// Reference to the tree manager.
  final SeoTreeManager? manager;

  /// Whether this node is disabled (on non-web platforms).
  final bool _disabled;

  /// The current SEO node.
  SeoNode get node => _node;

  /// Updates the SEO node data.
  void update(SeoNode newNode) {
    if (_disabled) return;
    if (_node == newNode) return;

    _node = newNode;
    manager?._updateDomNode(this);
  }
}

// Required import for SeoTag (would normally be in same package)
import 'seo_tag.dart';
