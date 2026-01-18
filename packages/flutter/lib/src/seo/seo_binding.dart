// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'seo_tree.dart';

/// Mixin for [WidgetsBinding] that initializes SEO functionality.
///
/// This binding should be included in your app's binding if you need
/// custom binding configuration:
///
/// ```dart
/// class MyAppBinding extends WidgetsFlutterBinding
///     with SeoBinding {
///   @override
///   void initInstances() {
///     super.initInstances();
///     // Custom initialization
///   }
/// }
/// ```
///
/// For most apps, simply use [SeoTreeRoot] at the top of your widget tree.
///
/// {@category SEO}
mixin SeoBinding on BindingBase {
  /// Whether the app is running on the web platform.
  static bool get isWebPlatform => kIsWeb;

  /// Whether SEO functionality should be enabled.
  ///
  /// This is true only on web platforms.
  bool get seoEnabled => isWebPlatform;

  /// The global SEO tree manager, if initialized.
  static SeoTreeManager? _globalManager;

  /// Gets the global SEO tree manager.
  ///
  /// Returns null if not on web or not initialized.
  static SeoTreeManager? get globalManager => _globalManager;

  /// Initializes the global SEO tree manager.
  ///
  /// This is called automatically by [SeoTreeRoot], but can be called
  /// manually for custom initialization.
  static void initializeGlobalManager({
    bool enabled = true,
    bool debugVisible = false,
  }) {
    if (!kIsWeb) return;

    _globalManager ??= SeoTreeManager(
      enabled: enabled,
      debugVisible: debugVisible,
    );
    _globalManager!.initialize();
  }

  /// Disposes the global SEO tree manager.
  static void disposeGlobalManager() {
    _globalManager?.dispose();
    _globalManager = null;
  }
}

/// Configuration options for SEO functionality.
///
/// Pass this to [SeoTreeRoot] or use with [SeoBinding] for custom configuration.
///
/// {@category SEO}
class SeoConfig {
  /// Creates SEO configuration.
  const SeoConfig({
    this.enabled = true,
    this.debugShowTree = false,
    this.sitemapBaseUrl,
    this.defaultTitle,
    this.titleTemplate,
    this.defaultDescription,
    this.defaultOgImage,
    this.twitterSite,
    this.googleVerification,
    this.bingVerification,
  });

  /// Whether SEO functionality is enabled.
  final bool enabled;

  /// Whether to show the SEO tree for debugging.
  final bool debugShowTree;

  /// Base URL for sitemap generation.
  final String? sitemapBaseUrl;

  /// Default page title (used when no title is specified).
  final String? defaultTitle;

  /// Template for page titles.
  ///
  /// Use `%s` as a placeholder for the page-specific title.
  /// Example: `'%s | My Website'` produces `'Home | My Website'`
  final String? titleTemplate;

  /// Default meta description.
  final String? defaultDescription;

  /// Default Open Graph image URL.
  final String? defaultOgImage;

  /// Twitter @username for the site.
  final String? twitterSite;

  /// Google Search Console verification code.
  final String? googleVerification;

  /// Bing Webmaster Tools verification code.
  final String? bingVerification;

  /// Applies the title template to a page title.
  String formatTitle(String pageTitle) {
    if (titleTemplate == null) return pageTitle;
    return titleTemplate!.replaceAll('%s', pageTitle);
  }

  /// Creates a copy with the given overrides.
  SeoConfig copyWith({
    bool? enabled,
    bool? debugShowTree,
    String? sitemapBaseUrl,
    String? defaultTitle,
    String? titleTemplate,
    String? defaultDescription,
    String? defaultOgImage,
    String? twitterSite,
    String? googleVerification,
    String? bingVerification,
  }) {
    return SeoConfig(
      enabled: enabled ?? this.enabled,
      debugShowTree: debugShowTree ?? this.debugShowTree,
      sitemapBaseUrl: sitemapBaseUrl ?? this.sitemapBaseUrl,
      defaultTitle: defaultTitle ?? this.defaultTitle,
      titleTemplate: titleTemplate ?? this.titleTemplate,
      defaultDescription: defaultDescription ?? this.defaultDescription,
      defaultOgImage: defaultOgImage ?? this.defaultOgImage,
      twitterSite: twitterSite ?? this.twitterSite,
      googleVerification: googleVerification ?? this.googleVerification,
      bingVerification: bingVerification ?? this.bingVerification,
    );
  }
}

/// Provides [SeoConfig] to the widget tree.
///
/// This allows SEO widgets to access global configuration without
/// requiring explicit parameters.
///
/// ```dart
/// SeoConfigProvider(
///   config: SeoConfig(
///     titleTemplate: '%s | My App',
///     twitterSite: '@myapp',
///   ),
///   child: MaterialApp(...),
/// )
/// ```
///
/// {@category SEO}
class SeoConfigProvider extends InheritedWidget {
  /// Creates an SEO config provider.
  const SeoConfigProvider({
    super.key,
    required this.config,
    required super.child,
  });

  /// The SEO configuration.
  final SeoConfig config;

  /// Gets the [SeoConfig] from the nearest ancestor.
  static SeoConfig of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<SeoConfigProvider>();
    return provider?.config ?? const SeoConfig();
  }

  /// Gets the [SeoConfig] from the nearest ancestor, or null if none exists.
  static SeoConfig? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<SeoConfigProvider>();
    return provider?.config;
  }

  @override
  bool updateShouldNotify(SeoConfigProvider oldWidget) {
    return config != oldWidget.config;
  }
}
