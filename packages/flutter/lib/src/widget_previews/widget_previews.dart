// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:/flutter/cupertino.dart';
/// @docImport 'package:/flutter/material.dart';
library;

import 'package:flutter/cupertino.dart' show CupertinoThemeData;
import 'package:flutter/material.dart' show Brightness, ThemeData;
import 'package:flutter/widgets.dart';

/// Signature for callbacks that build theming data used when creating a [Preview].
typedef PreviewTheme = PreviewThemeData Function();

/// Signature for callbacks that wrap a [Widget] with another [Widget] when creating a [Preview].
typedef WidgetWrapper = Widget Function(Widget);

/// Signature for callbacks that build localization data used when creating a [Preview].
typedef PreviewLocalizations = PreviewLocalizationsData Function();

/// Annotation used to mark functions that return a widget preview.
///
/// NOTE: this interface is not stable and **will change**.
///
/// {@tool snippet}
///
/// Functions annotated with `@Preview()` must return a `Widget` or
/// `WidgetBuilder` and be public. This annotation can only be applied
/// to top-level functions, static methods defined within a class, and
/// public `Widget` constructors and factories with no required arguments.
///
/// ```dart
/// @Preview(name: 'Top-level preview')
/// Widget preview() => const Text('Foo');
///
/// @Preview(name: 'Builder preview')
/// WidgetBuilder builderPreview() {
///   return (BuildContext context) {
///     return const Text('Builder');
///   };
/// }
///
/// class MyWidget extends StatelessWidget {
///   @Preview(name: 'Constructor preview')
///   const MyWidget.preview({super.key});
///
///   @Preview(name: 'Factory constructor preview')
///   factory MyWidget.factoryPreview() => const MyWidget.preview();
///
///   @Preview(name: 'Static preview')
///   static Widget previewStatic() => const Text('Static');
///
///   @override
///   Widget build(BuildContext context) {
///     return const Text('MyWidget');
///   }
/// }
/// ```
/// {@end-tool}
///
/// **Important Note:** all values provided to the `@Preview()` annotation must
/// be constant and non-private.
// TODO(bkonyi): link to actual documentation when available.
base class Preview {
  /// Annotation used to mark functions that return widget previews.
  const Preview({
    this.name,
    this.size,
    this.textScaleFactor,
    this.wrapper,
    this.theme,
    this.brightness,
    this.localizations,
  });

  /// A description to be displayed alongside the preview.
  ///
  /// If not provided, no name will be associated with the preview.
  final String? name;

  /// Artificial constraints to be applied to the previewed widget.
  ///
  /// If not provided, the previewed widget will attempt to set its own
  /// constraints.
  ///
  /// If a dimension has a value of `double.infinity`, the previewed widget
  /// will attempt to set its own constraints in the relevant dimension.
  ///
  /// To set a single dimension and allow the other to set its own constraints, use
  /// [Size.fromHeight] or [Size.fromWidth].
  final Size? size;

  /// Applies font scaling to text within the previewed widget.
  ///
  /// If not provided, the default text scaling factor provided by [MediaQuery]
  /// will be used.
  final double? textScaleFactor;

  /// Wraps the previewed [Widget] in a [Widget] tree.
  ///
  /// This function can be used to perform dependency injection or setup
  /// additional scaffolding needed to correctly render the preview.
  ///
  /// Note: this must be a reference to a static, public function defined as
  /// either a top-level function or static member in a class.
  // TODO(bkonyi): provide an example.
  final WidgetWrapper? wrapper;

  /// A callback to return Material and Cupertino theming data to be applied
  /// to the previewed [Widget].
  ///
  /// Note: this must be a reference to a static, public function defined as
  /// either a top-level function or static member in a class.
  final PreviewTheme? theme;

  /// Sets the initial theme brightness.
  ///
  /// If not provided, the current system default brightness will be used.
  final Brightness? brightness;

  /// A callback to return a localization configuration to be applied to the
  /// previewed [Widget].
  ///
  /// Note: this must be a reference to a static, public function defined as
  /// either a top-level function or static member in a class.
  final PreviewLocalizations? localizations;
}

/// A collection of localization objects and callbacks for use in widget previews.
base class PreviewLocalizationsData {
  /// Creates a collection of localization objects and callbacks for use in
  /// widget previews.
  const PreviewLocalizationsData({
    this.locale,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
  });

  /// {@macro flutter.widgets.widgetsApp.locale}
  ///
  /// See also:
  ///
  ///  * [localeResolutionCallback], which can override the default
  ///    [supportedLocales] matching algorithm.
  ///  * [localizationsDelegates], which collectively define all of the localized
  ///    resources used by this preview.
  final Locale? locale;

  /// {@macro flutter.widgets.widgetsApp.supportedLocales}
  ///
  /// See also:
  ///
  ///  * [localeResolutionCallback], an app callback that resolves the app's locale
  ///    when the device's locale changes.
  ///  * [localizationsDelegates], which collectively define all of the localized
  ///    resources used by this app.
  ///  * [basicLocaleListResolution], the default locale resolution algorithm.
  final List<Locale> supportedLocales;

  /// The delegates for this preview's [Localizations] widget.
  ///
  /// The delegates collectively define all of the localized resources
  /// for this preview's [Localizations] widget.
  final Iterable<LocalizationsDelegate<Object?>>? localizationsDelegates;

  /// {@macro flutter.widgets.widgetsApp.localeListResolutionCallback}
  ///
  /// This callback considers the entire list of preferred locales.
  ///
  /// This algorithm should be able to handle a null or empty list of preferred locales,
  /// which indicates Flutter has not yet received locale information from the platform.
  ///
  /// See also:
  ///
  ///  * [basicLocaleListResolution], the default locale resolution algorithm.
  final LocaleListResolutionCallback? localeListResolutionCallback;

  /// {@macro flutter.widgets.widgetsApp.localeListResolutionCallback}
  ///
  /// This callback considers only the default locale, which is the first locale
  /// in the preferred locales list. It is preferred to set [localeListResolutionCallback]
  /// over [localeResolutionCallback] as it provides the full preferred locales list.
  ///
  /// This algorithm should be able to handle a null locale, which indicates
  /// Flutter has not yet received locale information from the platform.
  ///
  /// See also:
  ///
  ///  * [basicLocaleListResolution], the default locale resolution algorithm.
  final LocaleResolutionCallback? localeResolutionCallback;
}

/// A collection of [ThemeData] and [CupertinoThemeData] instances for use in
/// widget previews.
base class PreviewThemeData {
  /// Creates a collection of [ThemeData] and [CupertinoThemeData] instances
  /// for use in widget previews.
  ///
  /// If a theme isn't provided for a specific configuration, no theme data
  /// will be applied and the default theme will be used.
  const PreviewThemeData({
    this.materialLight,
    this.materialDark,
    this.cupertinoLight,
    this.cupertinoDark,
  });

  /// The Material [ThemeData] to apply when light mode is enabled.
  final ThemeData? materialLight;

  /// The Material [ThemeData] to apply when dark mode is enabled.
  final ThemeData? materialDark;

  /// The Cupertino [CupertinoThemeData] to apply when light mode is enabled.
  final CupertinoThemeData? cupertinoLight;

  /// The Cupertino [CupertinoThemeData] to apply when dark mode is enabled.
  final CupertinoThemeData? cupertinoDark;

  /// Returns the pair of [ThemeData] and [CupertinoThemeData] corresponding to
  /// the value of [brightness].
  (ThemeData?, CupertinoThemeData?) themeForBrightness(Brightness brightness) {
    if (brightness == Brightness.light) {
      return (materialLight, cupertinoLight);
    }
    return (materialDark, cupertinoDark);
  }
}
