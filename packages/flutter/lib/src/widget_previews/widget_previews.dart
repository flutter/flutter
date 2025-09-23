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
/// be constant, and callback parameters must also be static and non-private. These
/// restrictions do not apply when creating instances of [Preview] at runtime, including
/// within [Preview.transform()].
///
/// See also:
///   - [MultiPreview], a base class which allows for creating multiple [Preview]s
///     with a single annotation.
///   - [flutter.dev/to/widget-previews](https://flutter.dev/to/widget-previews)
///     for details on getting started with widget previews.
base class Preview {
  /// Annotation used to mark functions that return widget previews.
  const Preview({
    String group = 'Default',
    String? name,
    Size? size,
    double? textScaleFactor,
    WidgetWrapper? wrapper,
    PreviewTheme? theme,
    Brightness? brightness,
    PreviewLocalizations? localizations,
  }) : this._required(
         group: group,
         name: name,
         size: size,
         textScaleFactor: textScaleFactor,
         wrapper: wrapper,
         theme: theme,
         brightness: brightness,
         localizations: localizations,
       );

  // Private constructor used to ensure [PreviewBuilder] stays consistent with this interface.
  const Preview._required({
    required this.group,
    required this.name,
    required this.size,
    required this.textScaleFactor,
    required this.wrapper,
    required this.theme,
    required this.brightness,
    required this.localizations,
  });

  /// {@template widget_preview_group}
  /// The group the preview belongs to.
  ///
  /// Previews with the same group name will be displayed together in the
  /// previewer. If not provided, 'Default' is used.
  /// {@endtemplate}
  final String group;

  /// {@template widget_preview_name}
  /// A description to be displayed alongside the preview.
  ///
  /// If not provided, no name will be associated with the preview.
  /// {@endtemplate}
  final String? name;

  /// {@template widget_preview_size}
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
  /// {@endtemplate}
  final Size? size;

  /// {@template widget_preview_text_scale_factor}
  /// Applies font scaling to text within the previewed widget.
  ///
  /// If not provided, the default text scaling factor provided by [MediaQuery]
  /// will be used.
  /// {@endtemplate}
  final double? textScaleFactor;

  /// {@template widget_preview_wrapper}
  /// Wraps the previewed [Widget] in a [Widget] tree.
  ///
  /// This function can be used to perform dependency injection or setup
  /// additional scaffolding needed to correctly render the preview.
  /// {@endtemplate}
  ///
  /// {@template widget_preview_must_be_static_const}
  /// Note: when provided as an argument to an annotation, this must be a reference to a static,
  /// public function defined as either a top-level function or static member in a class.
  /// {@endtemplate}
  // TODO(bkonyi): provide an example.
  final WidgetWrapper? wrapper;

  /// {@template widget_preview_theme}
  /// A callback to return Material and Cupertino theming data to be applied
  /// to the previewed [Widget].
  /// {@endtemplate}
  ///
  /// {@macro widget_preview_must_be_static_const}
  final PreviewTheme? theme;

  /// {@template widget_preview_brightness}
  /// Sets the initial theme brightness.
  ///
  /// If not provided, the current system default brightness will be used.
  /// {@endtemplate}
  final Brightness? brightness;

  /// {@template widget_preview_localizations}
  /// A callback to return a localization configuration to be applied to the
  /// previewed [Widget].
  /// {@endtemplate}
  ///
  /// {@macro widget_preview_must_be_static_const}
  final PreviewLocalizations? localizations;

  /// Applies a transformation to the current [Preview].
  ///
  /// Overriding this method allows for custom [Preview] implementations to initialize more
  /// complicated previews that would not otherwise be possible due to restrictions around constant
  /// constructors used for annotations.
  ///
  /// See also:
  ///   - [PreviewBuilder], a utility for building and modifying [Preview]s.
  @mustCallSuper
  Preview transform() => this;

  /// Creates a [PreviewBuilder] initialized with the values set in this preview.
  PreviewBuilder toBuilder() => PreviewBuilder._fromPreview(this);
}

/// The base class used to define a custom 'multi-preview' annotation.
///
/// Marking functions that return a widget preview with an instance of [MultiPreview] is the
/// equivalent of applying each [Preview] instance in the `previews` field to the function.
///
/// {@tool snippet}
/// This sample shows two ways to define multiple previews for a single preview function.
///
/// The first approach uses a [MultiPreview] implementation that creates previews using light and
/// dark mode themes.
///
/// The second approach uses multiple [Preview] annotations to achieve the same result.
///
/// ```dart
/// final class BrightnessPreview extends MultiPreview {
///   const BrightnessPreview();
///
///   @override
///   // ignore: avoid_field_initializers_in_const_classes
///   final List<Preview> previews = const <Preview>[
///     Preview(name: 'Light', brightness: Brightness.light),
///     Preview(name: 'Dark', brightness: Brightness.dark),
///   ];
/// }
///
/// // Using a multi-preview to create 'Light' and 'Dark' previews.
/// @BrightnessPreview()
/// WidgetBuilder brightnessPreview() {
///   return (BuildContext context) {
///     final ThemeData theme = Theme.of(context);
///     return Text('Brightness: ${theme.brightness}');
///   };
/// }
///
/// // Using multiple Preview annotations to create 'Light' and 'Dark' previews.
/// @Preview(name: 'Light', brightness: Brightness.light)
/// @Preview(name: 'Dark', brightness: Brightness.dark)
/// WidgetBuilder brightnessPreviewManual() {
///   return (BuildContext context) {
///     final ThemeData theme = Theme.of(context);
///     return Text('Brightness: ${theme.brightness}');
///   };
/// }
/// ```
/// {@end-tool}
///
/// **Important Note:** all values provided to [MultiPreview] derived annotations must
/// be constant, and callback parameters must also be static and non-private. These
/// restrictions do not apply when creating instances of [MultiPreview] at runtime, including
/// within [Preview.transform()].
///
/// See also:
///   - [Preview], the annotation used to mark functions that return a widget preview.
///   - [flutter.dev/to/widget-previews](https://flutter.dev/to/widget-previews)
///     for details on getting started with widget previews.
abstract base class MultiPreview {
  /// Creates a [MultiPreview] annotation instance.
  const MultiPreview();

  /// The set of [Preview]s to be created for the annotated function.
  List<Preview> get previews;

  /// Applies a transformation to each [Preview] in [previews].
  ///
  /// Overriding this method allows for [MultiPreview] implementations to initialize more
  /// complicated previews that would not otherwise be possible due to restrictions around constant
  /// constructors used for annotations.
  ///
  /// See also:
  ///   - [PreviewBuilder], a utility for building and modifying [Preview]s.
  @mustCallSuper
  List<Preview> transform() => previews.map((Preview e) => e.transform()).toList();
}

/// A utility class used to build a [Preview] instance.
final class PreviewBuilder {
  /// Creates a [PreviewBuilder] with no initial state.
  PreviewBuilder();

  /// Creates a [PreviewBuilder] initialized with the values set in [preview].
  PreviewBuilder._fromPreview(Preview preview)
    : group = preview.group,
      name = preview.name,
      size = preview.size,
      textScaleFactor = preview.textScaleFactor,
      wrapper = preview.wrapper,
      theme = preview.theme,
      brightness = preview.brightness,
      localizations = preview.localizations;

  /// {@macro widget_preview_group}
  String? group;

  /// {@macro widget_preview_name}
  String? name;

  /// {@macro widget_preview_size}
  Size? size;

  /// {@macro widget_preview_text_scale_factor}
  double? textScaleFactor;

  /// {@macro widget_preview_wrapper}
  WidgetWrapper? wrapper;

  /// Applies [newWrapper] to the returned value of the current [wrapper].
  void addWrapper(WidgetWrapper newWrapper) {
    final WidgetWrapper? wrapperLocal = wrapper;
    if (wrapperLocal != null) {
      wrapper = (Widget widget) => newWrapper(wrapperLocal(widget));
      return;
    }
    wrapper = newWrapper;
  }

  /// {@macro widget_preview_theme}
  PreviewTheme? theme;

  /// {@macro widget_preview_brightness}
  Brightness? brightness;

  /// {@macro widget_preview_localizations}
  PreviewLocalizations? localizations;

  /// Returns the [Preview] instance created from the builder's state.
  Preview build() {
    return Preview._required(
      group: group ?? 'Default',
      name: name,
      size: size,
      textScaleFactor: textScaleFactor,
      wrapper: wrapper,
      theme: theme,
      brightness: brightness,
      localizations: localizations,
    );
  }
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
///
/// NOTE: this interface is not stable and **will change**.
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
