// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'seo_node.dart';
import 'seo_tag.dart';
import 'seo_widget.dart';

/// A widget that creates a semantic link for SEO purposes.
///
/// [SeoLink] generates both:
/// 1. A visual Flutter widget that responds to taps
/// 2. A hidden `<a href="...">` element in the SEO Shadow Tree
///
/// This ensures that search engine crawlers can discover and follow links
/// while maintaining Flutter's visual design.
///
/// ## Basic Usage
///
/// ```dart
/// SeoLink(
///   href: '/products',
///   child: Text('View Products'),
/// )
/// ```
///
/// ## With Navigation
///
/// ```dart
/// SeoLink(
///   href: '/product/123',
///   onTap: () => Navigator.pushNamed(context, '/product/123'),
///   child: ProductCard(product),
/// )
/// ```
///
/// ## External Links
///
/// ```dart
/// SeoLink(
///   href: 'https://flutter.dev',
///   external: true,
///   rel: 'noopener noreferrer',
///   child: Text('Flutter Website'),
/// )
/// ```
///
/// {@category SEO}
class SeoLink extends StatelessWidget {
  /// Creates an SEO-enabled link widget.
  const SeoLink({
    super.key,
    required this.href,
    required this.child,
    this.onTap,
    this.title,
    this.rel,
    this.external = false,
    this.enabled = true,
  });

  /// The URL this link points to.
  ///
  /// For internal navigation, use paths like `/products` or `/product/123`.
  /// For external links, use full URLs like `https://example.com`.
  final String href;

  /// The widget to display as the link content.
  final Widget child;

  /// Called when the link is tapped.
  ///
  /// If null, defaults to using `Navigator.pushNamed` with [href].
  final VoidCallback? onTap;

  /// The title attribute for the link (shown on hover in browsers).
  final String? title;

  /// The rel attribute for the link.
  ///
  /// Common values:
  /// - `nofollow` - Tells search engines not to follow this link
  /// - `noopener` - Prevents the new page from accessing window.opener
  /// - `noreferrer` - Prevents passing the referrer header
  /// - `sponsored` - Indicates a paid/sponsored link
  /// - `ugc` - User-generated content
  final String? rel;

  /// Whether this is an external link.
  ///
  /// External links open in a new tab/window and automatically add
  /// `target="_blank"` and `rel="noopener"` for security.
  final bool external;

  /// Whether the link is interactive.
  ///
  /// When false, the link is rendered for SEO but doesn't respond to taps.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Build attributes map
    final attributes = <String, String>{
      'href': href,
      if (title != null) 'title': title!,
      if (external) 'target': '_blank',
    };

    // Handle rel attribute
    if (rel != null || external) {
      final relValues = <String>[];
      if (rel != null) {
        relValues.addAll(rel!.split(' '));
      }
      if (external && !relValues.contains('noopener')) {
        relValues.add('noopener');
      }
      attributes['rel'] = relValues.join(' ');
    }

    // Extract text from child for SEO
    String? linkText;
    if (child is Text) {
      linkText = (child as Text).data;
    }

    Widget result = Seo(
      tag: SeoTag.a,
      text: linkText,
      attributes: attributes,
      child: child,
    );

    // Add tap handling if enabled
    if (enabled) {
      result = GestureDetector(
        onTap: onTap ?? () => _defaultOnTap(context),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: result,
        ),
      );
    }

    return result;
  }

  void _defaultOnTap(BuildContext context) {
    if (external) {
      // For external links, use url_launcher or similar
      // In production, this would launch the URL
      debugPrint('Opening external URL: $href');
    } else {
      // For internal links, use Navigator
      Navigator.of(context).pushNamed(href);
    }
  }
}

/// A widget that creates a semantic button for SEO purposes.
///
/// While buttons are generally not crawlable, [SeoButton] can provide
/// context about the action for accessibility and structured data.
///
/// {@category SEO}
class SeoButton extends StatelessWidget {
  /// Creates an SEO-aware button widget.
  const SeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
  });

  /// The accessible label for the button.
  final String label;

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// The widget to display as the button content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: child,
      ),
    );
  }
}

/// A widget that groups navigation links for SEO purposes.
///
/// Wraps navigation links in a `<nav>` element, which helps search engines
/// understand the site structure.
///
/// ```dart
/// SeoNav(
///   label: 'Main navigation',
///   children: [
///     SeoLink(href: '/', child: Text('Home')),
///     SeoLink(href: '/products', child: Text('Products')),
///     SeoLink(href: '/about', child: Text('About')),
///   ],
/// )
/// ```
///
/// {@category SEO}
class SeoNav extends StatelessWidget {
  /// Creates an SEO navigation container.
  const SeoNav({
    super.key,
    required this.children,
    this.label,
    this.direction = Axis.horizontal,
    this.spacing = 8.0,
  });

  /// The navigation link widgets.
  final List<Widget> children;

  /// An accessible label for this navigation region.
  final String? label;

  /// The direction to lay out the navigation items.
  final Axis direction;

  /// The spacing between navigation items.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Seo(
      tag: SeoTag.nav,
      attributes: {
        if (label != null) 'aria-label': label!,
      },
      child: Flex(
        direction: direction,
        mainAxisSize: MainAxisSize.min,
        children: _addSpacing(children),
      ),
    );
  }

  List<Widget> _addSpacing(List<Widget> widgets) {
    if (widgets.isEmpty) return widgets;

    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(SizedBox(
          width: direction == Axis.horizontal ? spacing : 0,
          height: direction == Axis.vertical ? spacing : 0,
        ));
      }
    }
    return result;
  }
}

/// A breadcrumb navigation widget for SEO.
///
/// Generates proper breadcrumb structured data for search engines.
///
/// ```dart
/// SeoBreadcrumbs(
///   items: [
///     SeoBreadcrumbItem(label: 'Home', href: '/'),
///     SeoBreadcrumbItem(label: 'Products', href: '/products'),
///     SeoBreadcrumbItem(label: 'Widgets', href: '/products/widgets'),
///   ],
/// )
/// ```
///
/// {@category SEO}
class SeoBreadcrumbs extends StatelessWidget {
  /// Creates SEO breadcrumb navigation.
  const SeoBreadcrumbs({
    super.key,
    required this.items,
    this.separator = ' › ',
  });

  /// The breadcrumb items, in order from root to current page.
  final List<SeoBreadcrumbItem> items;

  /// The separator between breadcrumb items.
  final String separator;

  @override
  Widget build(BuildContext context) {
    return Seo(
      tag: SeoTag.nav,
      attributes: const {'aria-label': 'Breadcrumb'},
      child: Seo(
        tag: SeoTag.ol,
        attributes: const {
          'itemscope': '',
          'itemtype': 'https://schema.org/BreadcrumbList',
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildItems(context),
        ),
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final result = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      result.add(
        Seo(
          tag: SeoTag.li,
          attributes: {
            'itemprop': 'itemListElement',
            'itemscope': '',
            'itemtype': 'https://schema.org/ListItem',
          },
          child: isLast
              ? Seo(
                  tag: SeoTag.span,
                  attributes: const {'itemprop': 'name'},
                  text: item.label,
                  child: Text(item.label),
                )
              : SeoLink(
                  href: item.href!,
                  child: Text(item.label),
                ),
        ),
      );

      if (!isLast) {
        result.add(Text(separator));
      }
    }

    return result;
  }
}

/// An item in a breadcrumb navigation.
class SeoBreadcrumbItem {
  /// Creates a breadcrumb item.
  const SeoBreadcrumbItem({
    required this.label,
    this.href,
  });

  /// The display label for this breadcrumb.
  final String label;

  /// The URL this breadcrumb links to.
  ///
  /// Can be null for the current (last) item.
  final String? href;
}
