// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'dart:ui';
///
/// @docImport 'app.dart';
/// @docImport 'basic.dart';
/// @docImport 'editable_text.dart';
library;

import 'binding.dart';
import 'framework.dart';
import 'localizations.dart';

// This file is intentionally not exported from the widgets library. It lets
// [WidgetsApp] tell text widgets ([RichText], [EditableText]) when the
// application's locale is only a fallback, without adding public API.
//
// See https://github.com/flutter/flutter/issues/194931.

/// Returns the locale that text widgets should use for rendering (font
/// fallback, shaping) when they are not given an explicit locale.
///
/// This is usually [Localizations.maybeLocaleOf]. However, when the
/// application's locale was only picked because the user's preferred locale
/// is not one of the app's supported locales (for example, the default
/// `en_US` on a `zh_CN` device), this returns null. Passing no locale to the
/// engine lets the platform's text stack use the operating system's default
/// locale, which picks the right glyphs for scripts such as Han.
///
/// A descendant [Localizations] widget that selects a different locale (for
/// example [Localizations.override]) is respected.
Locale? textLocaleOf(BuildContext context) {
  final Locale? locale = Localizations.maybeLocaleOf(context);
  if (locale == null) {
    return null;
  }
  final _TextLocaleScope? scope = context.dependOnInheritedWidgetOfExactType<_TextLocaleScope>();
  if (scope != null && scope.fallbackApplicationLocale == locale) {
    return null;
  }
  return locale;
}

/// Records, for [textLocaleOf], whether [applicationLocale] is the user's
/// preferred locale or only a fallback for it.
///
/// Used by [WidgetsApp] directly below its application-level [Localizations].
class TextLocaleScope extends StatefulWidget {
  /// Creates a [TextLocaleScope].
  const TextLocaleScope({
    super.key,
    required this.applicationLocale,
    required this.explicitLocale,
    required this.child,
  });

  /// The locale that the application resolved to, from
  /// [LocalizationsResolver.locale].
  final Locale applicationLocale;

  /// The locale explicitly requested by the application (for example
  /// [WidgetsApp.locale]), if any.
  ///
  /// When null, the user's preferred locale is the first locale in
  /// [PlatformDispatcher.locales].
  final Locale? explicitLocale;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<TextLocaleScope> createState() => _TextLocaleScopeState();
}

class _TextLocaleScopeState extends State<TextLocaleScope> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    setState(() {
      // The preferred locale is read from the platform dispatcher in build.
    });
  }

  Locale? get _preferredLocale {
    if (widget.explicitLocale != null) {
      return widget.explicitLocale;
    }
    final List<Locale> locales = WidgetsBinding.instance.platformDispatcher.locales;
    return locales.isEmpty ? null : locales.first;
  }

  @override
  Widget build(BuildContext context) {
    final Locale? preferredLocale = _preferredLocale;
    final bool isPreferredLocaleSupported =
        preferredLocale == null || preferredLocale == widget.applicationLocale;
    return _TextLocaleScope(
      fallbackApplicationLocale: isPreferredLocaleSupported ? null : widget.applicationLocale,
      child: widget.child,
    );
  }
}

class _TextLocaleScope extends InheritedWidget {
  const _TextLocaleScope({required this.fallbackApplicationLocale, required super.child});

  /// The application locale when it is only a fallback for the user's
  /// unsupported preferred locale, otherwise null.
  final Locale? fallbackApplicationLocale;

  @override
  bool updateShouldNotify(_TextLocaleScope oldWidget) {
    return fallbackApplicationLocale != oldWidget.fallbackApplicationLocale;
  }
}
