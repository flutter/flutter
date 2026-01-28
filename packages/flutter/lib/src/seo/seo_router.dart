// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'seo_head.dart';

/// SEO-aware router integration for generating proper URLs and sitemaps.
///
/// [SeoRouter] provides:
/// - Automatic URL generation for routes
/// - Sitemap.xml generation
/// - Proper canonical URL handling
/// - Support for dynamic route parameters
///
/// ## Basic Usage
///
/// ```dart
/// final seoRouter = SeoRouter(
///   baseUrl: 'https://example.com',
///   routes: [
///     SeoRoute(
///       path: '/',
///       title: 'Home',
///       priority: 1.0,
///       changeFrequency: SeoChangeFrequency.daily,
///     ),
///     SeoRoute(
///       path: '/products',
///       title: 'Products',
///       priority: 0.9,
///     ),
///     SeoRoute(
///       path: '/products/:id',
///       title: 'Product Details',
///       dynamicPathGenerator: () async => [
///         '/products/1',
///         '/products/2',
///         '/products/3',
///       ],
///     ),
///   ],
/// );
///
/// // Generate sitemap
/// final sitemap = await seoRouter.generateSitemap();
/// ```
///
/// {@category SEO}
class SeoRouter {
  /// Creates an SEO router.
  const SeoRouter({required this.baseUrl, required this.routes});

  /// The base URL for the website (e.g., 'https://example.com').
  final String baseUrl;

  /// The SEO route configurations.
  final List<SeoRoute> routes;

  /// Generates a sitemap.xml string for all configured routes.
  Future<String> generateSitemap() async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

    for (final route in routes) {
      final paths = await _getPathsForRoute(route);

      for (final path in paths) {
        buffer.writeln('  <url>');
        buffer.writeln('    <loc>$baseUrl$path</loc>');
        if (route.lastModified != null) {
          buffer.writeln('    <lastmod>${_formatDate(route.lastModified!)}</lastmod>');
        }
        if (route.changeFrequency != null) {
          buffer.writeln('    <changefreq>${route.changeFrequency!.value}</changefreq>');
        }
        if (route.priority != null) {
          buffer.writeln('    <priority>${route.priority}</priority>');
        }
        buffer.writeln('  </url>');
      }
    }

    buffer.writeln('</urlset>');
    return buffer.toString();
  }

  /// Generates a robots.txt string.
  String generateRobotsTxt({
    List<String> disallowPaths = const [],
    List<String> allowPaths = const [],
    int? crawlDelay,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('User-agent: *');

    for (final path in allowPaths) {
      buffer.writeln('Allow: $path');
    }

    for (final path in disallowPaths) {
      buffer.writeln('Disallow: $path');
    }

    if (crawlDelay != null) {
      buffer.writeln('Crawl-delay: $crawlDelay');
    }

    buffer.writeln();
    buffer.writeln('Sitemap: $baseUrl/sitemap.xml');

    return buffer.toString();
  }

  Future<List<String>> _getPathsForRoute(SeoRoute route) async {
    if (route.dynamicPathGenerator != null) {
      return route.dynamicPathGenerator!();
    }
    return [route.path];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Gets the SEO route configuration for a given path.
  SeoRoute? getRouteForPath(String path) {
    // First, try exact match
    for (final route in routes) {
      if (route.path == path) {
        return route;
      }
    }

    // Then, try pattern match for dynamic routes
    for (final route in routes) {
      if (_matchesPattern(route.path, path)) {
        return route;
      }
    }

    return null;
  }

  bool _matchesPattern(String pattern, String path) {
    // Convert pattern like /products/:id to regex
    final regexPattern = pattern.replaceAllMapped(RegExp(r':(\w+)'), (match) => r'([^/]+)');
    return RegExp('^$regexPattern\$').hasMatch(path);
  }
}

/// Configuration for an SEO route.
class SeoRoute {
  /// Creates an SEO route configuration.
  const SeoRoute({
    required this.path,
    this.title,
    this.description,
    this.priority,
    this.changeFrequency,
    this.lastModified,
    this.dynamicPathGenerator,
    this.noindex = false,
    this.nofollow = false,
  });

  /// The route path (e.g., '/products' or '/products/:id').
  final String path;

  /// The page title for this route.
  final String? title;

  /// The meta description for this route.
  final String? description;

  /// The sitemap priority (0.0 to 1.0).
  ///
  /// - 1.0: Highest priority (homepage)
  /// - 0.8: High priority (main sections)
  /// - 0.5: Default priority
  /// - 0.3: Low priority (less important pages)
  final double? priority;

  /// How frequently the page is likely to change.
  final SeoChangeFrequency? changeFrequency;

  /// When the page was last modified.
  final DateTime? lastModified;

  /// Generator for dynamic route paths.
  ///
  /// For routes with parameters (e.g., '/products/:id'), this function
  /// should return all valid paths for sitemap generation.
  final Future<List<String>> Function()? dynamicPathGenerator;

  /// Whether to add noindex to this route.
  final bool noindex;

  /// Whether to add nofollow to this route.
  final bool nofollow;

  /// Gets the robots directive for this route.
  SeoRobots get robots => SeoRobots(index: !noindex, follow: !nofollow);
}

/// Sitemap change frequency values.
enum SeoChangeFrequency {
  /// Changes constantly.
  always,

  /// Changes every hour.
  hourly,

  /// Changes every day.
  daily,

  /// Changes every week.
  weekly,

  /// Changes every month.
  monthly,

  /// Changes every year.
  yearly,

  /// Archived content that never changes.
  never,
}

extension on SeoChangeFrequency {
  String get value {
    switch (this) {
      case SeoChangeFrequency.always:
        return 'always';
      case SeoChangeFrequency.hourly:
        return 'hourly';
      case SeoChangeFrequency.daily:
        return 'daily';
      case SeoChangeFrequency.weekly:
        return 'weekly';
      case SeoChangeFrequency.monthly:
        return 'monthly';
      case SeoChangeFrequency.yearly:
        return 'yearly';
      case SeoChangeFrequency.never:
        return 'never';
    }
  }
}

/// A widget that automatically applies SEO configuration from an [SeoRoute].
///
/// Use this with your router to automatically set page titles, descriptions,
/// and canonical URLs based on the current route.
///
/// ```dart
/// SeoRouteWrapper(
///   route: seoRouter.getRouteForPath('/products'),
///   path: '/products',
///   child: ProductsPage(),
/// )
/// ```
///
/// {@category SEO}
class SeoRouteWrapper extends StatelessWidget {
  /// Creates an SEO route wrapper.
  const SeoRouteWrapper({
    super.key,
    required this.route,
    required this.path,
    required this.child,
    this.baseUrl,
    this.titleSuffix,
  });

  /// The SEO route configuration.
  final SeoRoute? route;

  /// The current path.
  final String path;

  /// The page content.
  final Widget child;

  /// The base URL for canonical URL generation.
  final String? baseUrl;

  /// Suffix to append to the title (e.g., ' | My Site').
  final String? titleSuffix;

  @override
  Widget build(BuildContext context) {
    if (route == null) {
      return child;
    }

    String? fullTitle = route!.title;
    if (fullTitle != null && titleSuffix != null) {
      fullTitle = '$fullTitle$titleSuffix';
    }

    String? canonicalUrl;
    if (baseUrl != null) {
      canonicalUrl = '$baseUrl$path';
    }

    return SeoHead(
      title: fullTitle ?? '',
      description: route!.description,
      canonicalUrl: canonicalUrl,
      robots: route!.robots,
      child: child,
    );
  }
}
