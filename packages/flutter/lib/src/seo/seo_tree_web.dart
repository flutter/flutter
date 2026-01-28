// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

import 'seo_node.dart';
import 'seo_tag.dart';

/// Web implementation of SEO DOM operations.
///
/// This class handles actual DOM manipulation for Flutter Web applications,
/// creating a hidden semantic HTML structure that search engines can crawl.
class SeoDomOperations {
  /// Creates a web DOM operations handler.
  SeoDomOperations();

  /// The root container element for the SEO Shadow Tree.
  html.Element? _rootElement;

  /// Map of managed meta tags by name/property.
  final Map<String, html.MetaElement> _metaTags = {};

  /// The current title element.
  html.Element? _titleElement;

  /// The canonical link element.
  html.LinkElement? _canonicalLink;

  /// Whether this platform supports SEO DOM operations.
  bool get isSupported => true;

  /// Initializes the SEO root element in the document body.
  void initialize({bool debugVisible = false}) {
    if (_rootElement != null) return;

    // Create the root container
    _rootElement = html.DivElement()
      ..id = 'flutter-seo-root'
      ..setAttribute('aria-hidden', 'true')
      ..setAttribute('role', 'presentation');

    // Apply hidden styles (or debug-visible styles)
    _applyRootStyles(debugVisible);

    // Insert at the beginning of body, after canvas
    final body = html.document.body;
    if (body != null) {
      // Find the Flutter canvas/glass-pane
      final flutterRoot =
          body.querySelector('flt-glass-pane') ??
          body.querySelector('flutter-view') ??
          body.firstChild;

      if (flutterRoot != null && flutterRoot.nextNode != null) {
        body.insertBefore(_rootElement!, flutterRoot.nextNode);
      } else {
        body.append(_rootElement!);
      }
    }
  }

  void _applyRootStyles(bool debugVisible) {
    if (_rootElement == null) return;

    if (debugVisible) {
      _rootElement!.style
        ..position = 'fixed'
        ..top = '0'
        ..left = '0'
        ..right = '0'
        ..bottom = '0'
        ..backgroundColor = 'rgba(255, 255, 0, 0.1)'
        ..border = '3px dashed red'
        ..overflow = 'auto'
        ..zIndex = '999999'
        ..pointerEvents = 'none'
        ..padding = '20px'
        ..fontFamily = 'monospace'
        ..fontSize = '14px'
        ..color = '#333';
    } else {
      _rootElement!.style
        ..position = 'absolute'
        ..width = '1px'
        ..height = '1px'
        ..padding = '0'
        ..margin = '-1px'
        ..overflow = 'hidden'
        ..setProperty('clip', 'rect(0, 0, 0, 0)')
        ..whiteSpace = 'nowrap'
        ..border = '0'
        ..pointerEvents = 'none'
        ..setProperty('user-select', 'none')
        ..zIndex = '-1';
    }
  }

  /// Creates a DOM element from an SEO node.
  html.Element? createElement(SeoNode node) {
    final tagName = node.tag.htmlTag;

    // Create the appropriate element
    html.Element element;

    switch (tagName) {
      case 'a':
        element = html.AnchorElement();
        break;
      case 'img':
        element = html.ImageElement();
        break;
      case 'input':
        element = html.InputElement();
        break;
      case 'button':
        element = html.ButtonElement();
        break;
      case 'form':
        element = html.FormElement();
        break;
      case 'select':
        element = html.SelectElement();
        break;
      case 'textarea':
        element = html.TextAreaElement();
        break;
      case 'table':
        element = html.TableElement();
        break;
      case 'tr':
        element = html.TableRowElement();
        break;
      case 'td':
        element = html.TableCellElement();
        break;
      case 'th':
        element = html.TableCellElement();
        break;
      case 'ul':
        element = html.UListElement();
        break;
      case 'ol':
        element = html.OListElement();
        break;
      case 'li':
        element = html.LIElement();
        break;
      case 'dl':
        element = html.DListElement();
        break;
      case 'br':
        element = html.BRElement();
        break;
      case 'hr':
        element = html.HRElement();
        break;
      case 'span':
        element = html.SpanElement();
        break;
      case 'div':
        element = html.DivElement();
        break;
      case 'p':
        element = html.ParagraphElement();
        break;
      case 'h1':
        element = html.HeadingElement.h1();
        break;
      case 'h2':
        element = html.HeadingElement.h2();
        break;
      case 'h3':
        element = html.HeadingElement.h3();
        break;
      case 'h4':
        element = html.HeadingElement.h4();
        break;
      case 'h5':
        element = html.HeadingElement.h5();
        break;
      case 'h6':
        element = html.HeadingElement.h6();
        break;
      default:
        element = html.Element.tag(tagName);
    }

    // Set attributes
    for (final entry in node.attributes.entries) {
      if (entry.value.isEmpty) {
        element.setAttribute(entry.key, '');
      } else {
        element.setAttribute(entry.key, entry.value);
      }
    }

    // Set text content if present and no children
    if (node.textContent != null && node.children.isEmpty) {
      element.text = node.textContent;
    }

    // Recursively create and append children
    for (final childNode in node.children) {
      final childElement = createElement(childNode);
      if (childElement != null) {
        element.append(childElement);
      }
    }

    return element;
  }

  /// Appends a child element to a parent.
  void appendChild(Object? parent, Object? child) {
    if (parent == null && child is html.Element) {
      _rootElement?.append(child);
    } else if (parent is html.Element && child is html.Element) {
      parent.append(child);
    }
  }

  /// Removes an element from the DOM.
  void removeElement(Object? element) {
    if (element is html.Element) {
      element.remove();
    }
  }

  /// Updates an element's content based on an SEO node.
  void updateElement(Object? element, SeoNode node) {
    if (element is! html.Element) return;

    // Update attributes
    // First, remove attributes not in the new node
    final existingAttrs = element.attributes.keys.toList();
    for (final attr in existingAttrs) {
      if (!node.attributes.containsKey(attr)) {
        element.removeAttribute(attr);
      }
    }

    // Then set new/updated attributes
    for (final entry in node.attributes.entries) {
      element.setAttribute(entry.key, entry.value);
    }

    // Update text content if no children
    if (node.children.isEmpty && node.textContent != null) {
      element.text = node.textContent;
    }
  }

  /// Sets the visibility of the SEO root for debugging.
  void setDebugVisible(bool visible) {
    _applyRootStyles(visible);
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
    final head = html.document.head;
    if (head == null) return;

    // Update title
    if (title != null) {
      _titleElement ??= head.querySelector('title');
      if (_titleElement == null) {
        _titleElement = html.Element.tag('title');
        head.append(_titleElement!);
      }
      _titleElement!.text = title;
    }

    // Update canonical URL
    if (canonicalUrl != null) {
      _canonicalLink ??= head.querySelector('link[rel="canonical"]') as html.LinkElement?;
      if (_canonicalLink == null) {
        _canonicalLink = html.LinkElement()..rel = 'canonical';
        head.append(_canonicalLink!);
      }
      _canonicalLink!.href = canonicalUrl;
    }

    // Update meta tags
    _setMetaTag(head, 'name', 'description', description);
    _setMetaTag(head, 'name', 'robots', robots);

    // Open Graph tags
    _setMetaTag(head, 'property', 'og:title', ogTitle);
    _setMetaTag(head, 'property', 'og:description', ogDescription);
    _setMetaTag(head, 'property', 'og:image', ogImage);
    _setMetaTag(head, 'property', 'og:url', ogUrl);
    _setMetaTag(head, 'property', 'og:type', ogType);

    // Twitter Card tags
    _setMetaTag(head, 'name', 'twitter:card', twitterCard);
    _setMetaTag(head, 'name', 'twitter:title', twitterTitle);
    _setMetaTag(head, 'name', 'twitter:description', twitterDescription);
    _setMetaTag(head, 'name', 'twitter:image', twitterImage);

    // Custom meta tags
    if (customMeta != null) {
      for (final entry in customMeta.entries) {
        _setMetaTag(head, 'name', entry.key, entry.value);
      }
    }
  }

  void _setMetaTag(html.HeadElement head, String attribute, String name, String? content) {
    if (content == null) return;

    final key = '$attribute:$name';
    var meta = _metaTags[key];

    if (meta == null) {
      // Try to find existing tag
      meta = head.querySelector('meta[$attribute="$name"]') as html.MetaElement?;

      if (meta == null) {
        meta = html.MetaElement();
        meta.setAttribute(attribute, name);
        head.append(meta);
      }

      _metaTags[key] = meta;
    }

    meta.content = content;
  }

  /// Map of managed structured data scripts by ID.
  final Map<String, html.ScriptElement> _structuredDataScripts = {};

  /// Adds structured data JSON-LD to the document head.
  html.ScriptElement? addStructuredData(Map<String, dynamic> data) {
    final head = html.document.head;
    if (head == null) return null;

    final script = html.ScriptElement()
      ..type = 'application/ld+json'
      ..text = jsonEncode(data);

    head.append(script);
    return script;
  }

  /// Adds structured data JSON-LD to the document head by ID.
  void addStructuredDataById(String id, String jsonString) {
    final head = html.document.head;
    if (head == null) return;

    // Remove existing script with same ID if present
    removeStructuredDataById(id);

    final script = html.ScriptElement()
      ..type = 'application/ld+json'
      ..id = id
      ..text = jsonString;

    head.append(script);
    _structuredDataScripts[id] = script;
  }

  /// Removes structured data from the document.
  void removeStructuredData(Object? element) {
    if (element is html.ScriptElement) {
      element.remove();
    }
  }

  /// Removes structured data from the document by ID.
  void removeStructuredDataById(String id) {
    final script = _structuredDataScripts.remove(id);
    script?.remove();
  }

  /// Returns the root element.
  html.Element? get rootElement => _rootElement;

  /// Disposes of resources and removes the SEO root from the DOM.
  void dispose() {
    _rootElement?.remove();
    _rootElement = null;

    // Remove managed meta tags
    for (final meta in _metaTags.values) {
      meta.remove();
    }
    _metaTags.clear();

    // Remove managed structured data scripts
    for (final script in _structuredDataScripts.values) {
      script.remove();
    }
    _structuredDataScripts.clear();

    _canonicalLink?.remove();
    _canonicalLink = null;
  }
}
