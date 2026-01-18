// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'seo_dom.dart';
import 'seo_node.dart';
import 'seo_tag.dart';

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
    assert(manager != null, 'No SeoTree found in widget tree. '
        'Wrap your app with SeoTreeRoot to enable SEO functionality.');
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
///
/// This class maintains the mapping between Flutter widgets and their
/// corresponding DOM elements in the SEO Shadow Tree.
class SeoTreeManager {
  /// Creates an SEO tree manager.
  SeoTreeManager({
    this.enabled = true,
    this.debugVisible = false,
  }) : _domOps = SeoDomOperations();

  /// Whether SEO processing is enabled.
  bool enabled;

  /// Whether the SEO DOM is visible for debugging.
  bool debugVisible;

  /// The platform-specific DOM operations handler.
  final SeoDomOperations _domOps;

  /// All registered SEO tree nodes, keyed by their unique ID.
  final Map<int, SeoTreeNode> _nodes = <int, SeoTreeNode>{};

  /// Parent-child relationships for hierarchical DOM structure.
  final Map<int, int> _parentMap = <int, int>{};

  /// Children of each node.
  final Map<int, List<int>> _childrenMap = <int, List<int>>{};

  /// Counter for generating unique node IDs.
  int _nextId = 0;

  /// Whether the manager has been initialized.
  bool _initialized = false;

  /// Whether the current platform supports SEO operations.
  bool get isSupported => _domOps.isSupported;

  /// Initializes the SEO tree manager.
  ///
  /// On web, this creates the hidden DOM container.
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    if (!enabled || !_domOps.isSupported) return;

    _domOps.initialize(debugVisible: debugVisible);
  }

  /// Updates manager settings.
  void updateSettings({bool? enabled, bool? debugVisible}) {
    if (enabled != null) {
      this.enabled = enabled;
      if (!enabled) {
        // Clear all nodes when disabled
        for (final node in _nodes.values.toList()) {
          unregister(node);
        }
      } else if (_initialized) {
        // Re-initialize if enabled and was previously initialized
        _domOps.initialize(debugVisible: this.debugVisible);
      }
    }
    if (debugVisible != null) {
      this.debugVisible = debugVisible;
      _domOps.setDebugVisible(debugVisible);
    }
  }

  /// Registers a new SEO node from a widget.
  ///
  /// Returns a [SeoTreeNode] that can be used to update or remove the node.
  ///
  /// If [parentNode] is provided, the new node will be inserted as a child
  /// of that node in the DOM hierarchy.
  SeoTreeNode register(SeoNode node, BuildContext context, {SeoTreeNode? parentNode}) {
    if (!enabled || !_domOps.isSupported) {
      return SeoTreeNode._disabled();
    }

    final id = _nextId++;

    // Create the DOM element
    final domElement = _domOps.createElement(node);

    final treeNode = SeoTreeNode._(
      id: id,
      node: node,
      manager: this,
      domElement: domElement,
    );

    _nodes[id] = treeNode;

    // Handle parent-child relationship
    if (parentNode != null && !parentNode._disabled && _nodes.containsKey(parentNode.id)) {
      _parentMap[id] = parentNode.id;
      _childrenMap.putIfAbsent(parentNode.id, () => []).add(id);
      _domOps.appendChild(parentNode.domElement, domElement);
    } else {
      // Append to root
      _domOps.appendChild(null, domElement);
    }

    return treeNode;
  }

  /// Unregisters an SEO node.
  void unregister(SeoTreeNode treeNode) {
    if (!enabled || treeNode._disabled || !_domOps.isSupported) return;

    final id = treeNode.id;

    // Remove all children first (recursively)
    final children = _childrenMap[id]?.toList() ?? [];
    for (final childId in children) {
      final childNode = _nodes[childId];
      if (childNode != null) {
        unregister(childNode);
      }
    }

    // Remove from parent's children list
    final parentId = _parentMap[id];
    if (parentId != null) {
      _childrenMap[parentId]?.remove(id);
    }

    // Remove DOM element
    _domOps.removeElement(treeNode.domElement);

    // Clean up maps
    _nodes.remove(id);
    _parentMap.remove(id);
    _childrenMap.remove(id);
  }

  /// Updates the document head with meta tags.
  void updateHead({
    String? title,
    String? description,
    String? canonicalUrl,
    String? ogTitle,
    String? ogDescription,
    String? ogImage,
    String? ogUrl,
    String? ogType,
    String? twitterCard,
    String? twitterTitle,
    String? twitterDescription,
    String? twitterImage,
    String? robots,
    Map<String, String>? customMeta,
  }) {
    if (!enabled || !_domOps.isSupported) return;

    _domOps.updateHead(
      title: title,
      description: description,
      canonicalUrl: canonicalUrl,
      ogTitle: ogTitle,
      ogDescription: ogDescription,
      ogImage: ogImage,
      ogUrl: ogUrl,
      ogType: ogType,
      twitterCard: twitterCard,
      twitterTitle: twitterTitle,
      twitterDescription: twitterDescription,
      twitterImage: twitterImage,
      robots: robots,
      customMeta: customMeta,
    );
  }

  /// Adds structured data JSON-LD to the document.
  ///
  /// [id] is a unique identifier for this script element.
  /// [jsonString] is the JSON-LD content.
  void addStructuredData(String id, String jsonString) {
    if (!enabled || !_domOps.isSupported) return;
    _domOps.addStructuredDataById(id, jsonString);
  }

  /// Removes structured data from the document by ID.
  void removeStructuredData(String id) {
    if (!enabled || !_domOps.isSupported) return;
    _domOps.removeStructuredDataById(id);
  }

  /// Generates the complete SEO tree as an HTML string.
  ///
  /// This is useful for server-side rendering or debugging.
  String toHtml() {
    final buffer = StringBuffer();
    buffer.writeln('<div id="flutter-seo-root" aria-hidden="true">');

    // Build hierarchical HTML by finding root nodes (those without parents)
    final rootNodeIds = _nodes.keys.where((id) => !_parentMap.containsKey(id));

    for (final id in rootNodeIds) {
      _writeNodeHtml(buffer, id, indent: 1);
    }

    buffer.writeln('</div>');
    return buffer.toString();
  }

  void _writeNodeHtml(StringBuffer buffer, int nodeId, {int indent = 0}) {
    final node = _nodes[nodeId];
    if (node == null) return;

    final childIds = _childrenMap[nodeId] ?? [];

    if (childIds.isEmpty) {
      buffer.writeln(node.node.toHtml(indent: indent));
    } else {
      // Write opening tag with children
      final indentStr = '  ' * indent;
      buffer.write('$indentStr<${node.node.tag.htmlTag}');

      for (final attr in node.node.attributes.entries) {
        buffer.write(' ${attr.key}="${_escapeHtml(attr.value)}"');
      }

      buffer.writeln('>');

      // Write text content if present
      if (node.node.textContent != null) {
        buffer.writeln('$indentStr  ${_escapeHtml(node.node.textContent!)}');
      }

      // Write children
      for (final childId in childIds) {
        _writeNodeHtml(buffer, childId, indent: indent + 1);
      }

      buffer.writeln('$indentStr</${node.node.tag.htmlTag}>');
    }
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Disposes of the manager and cleans up resources.
  void dispose() {
    _nodes.clear();
    _parentMap.clear();
    _childrenMap.clear();
    _domOps.dispose();
    _initialized = false;
  }
}

/// Represents a node in the SEO Shadow Tree.
///
/// This is returned when registering an [SeoNode] with the [SeoTreeManager].
class SeoTreeNode {
  SeoTreeNode._({
    required this.id,
    required SeoNode node,
    required this.manager,
    this.domElement,
  })  : _node = node,
        _disabled = false;

  SeoTreeNode._disabled()
      : id = -1,
        _node = const SeoNode(tag: SeoTag.span),
        manager = null,
        domElement = null,
        _disabled = true;

  /// Unique identifier for this tree node.
  final int id;

  /// The SEO node data.
  SeoNode _node;

  /// Reference to the tree manager.
  final SeoTreeManager? manager;

  /// The DOM element (web only).
  final Object? domElement;

  /// Whether this node is disabled (on non-web platforms).
  final bool _disabled;

  /// The current SEO node.
  SeoNode get node => _node;

  /// Whether this node is disabled.
  bool get isDisabled => _disabled;

  /// Updates the SEO node data.
  void update(SeoNode newNode) {
    if (_disabled) return;
    if (_node == newNode) return;

    _node = newNode;
    manager?._domOps.updateElement(domElement, newNode);
  }
}
