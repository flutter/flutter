// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;

/// [Color] constants which represent Material design's
/// [color palette](http://material.google.com/style/color.html).
///
/// Instead of using an absolute color from these palettes, consider using
/// [Theme.of] to obtain the local [ThemeData] structure, which exposes the
/// colors selected for the current theme, such as [ThemeData.primaryColor] and
/// [ThemeData.accentColor] (among many others).
///
/// To select a specific color from one of the swatches, index into the swatch
/// using an integer for the specific color desired, as follows:
///
/// ```dart
/// Colors.green[400]  // Selects a mid-range green.
/// ```
///
/// Most swatches have colors from 100 to 900 in increments of one hundred, plus
/// the color 50. The smaller the number, the more pale the color. The greater
/// the number, the darker the color. The accent swatches (e.g. [redAccent]) only
/// have the values 100, 200, 400, and 700.
///
/// In addition, a series of blacks and whites with common opacities are
/// available. For example, [black54] is a pure black with 54% opacity.
class Colors {
  Colors._();

  /// Completely invisible.
  static const Color transparent = const Color(0x00000000);


  /// Completely opaque black.
  static const Color black   = const Color(0xFF000000);

  /// Black with 87% opacity.
  ///
  /// This is a good contrasting color for text in light themes.
  ///
  /// See also:
  ///
  /// * [Typography.black], which uses this color for its text styles.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Color black87 = const Color(0xDD000000);

  /// Black with 54% opacity.
  ///
  /// This is a color commonly used for headings in light themes.
  ///
  /// See also:
  ///
  /// * [Typography.black], which uses this color for its text styles.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Color black54 = const Color(0x8A000000);

  /// Black with 38% opacity.
  ///
  /// Used for the placeholder text in data tables in light themes.
  static const Color black38 = const Color(0x61000000);

  /// Black with 45% opacity.
  ///
  /// Used for modal barriers.
  static const Color black45 = const Color(0x73000000);

  /// Black with 26% opacity.
  ///
  /// Used for disabled radio buttons and the text of disabled flat buttons in light themes.
  ///
  /// See also:
  ///
  /// * [ThemeData.disabledColor], which uses this color by default in light themes.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Color black26 = const Color(0x42000000);

  /// Black with 12% opacity.
  ///
  /// Used for the background of disabled raised buttons in light themes.
  static const Color black12 = const Color(0x1F000000);


  /// Completely opaque white.
  ///
  /// This is a good contrasting color for the [ThemeData.primaryColor] in the
  /// dark theme. See [ThemeData.brightness].
  ///
  /// See also:
  ///
  /// * [Typography.white], which uses this color for its text styles.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Color white   = const Color(0xFFFFFFFF);

  /// White with 70% opacity.
  ///
  /// This is a color commonly used for headings in dark themes.
  ///
  /// See also:
  ///
  /// * [Typography.white], which uses this color for its text styles.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Color white70 = const Color(0xB3FFFFFF);

  /// White with 32% opacity.
  ///
  /// Used for disabled radio buttons and the text of disabled flat buttons in dark themes.
  ///
  /// See also:
  ///
  /// * [ThemeData.disabledColor], which uses this color by default in dark themes.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Color white30 = const Color(0x4DFFFFFF);

  /// White with 12% opacity.
  ///
  /// Used for the background of disabled raised buttons in dark themes.
  static const Color white12 = const Color(0x1FFFFFFF);

  /// White with 10% opacity.
  static const Color white10 = const Color(0x1AFFFFFF);


  /// The red primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.red[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [redAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> red = const <int, Color>{
     50: const Color(0xFFFFEBEE),
    100: const Color(0xFFFFCDD2),
    200: const Color(0xFFEF9A9A),
    300: const Color(0xFFE57373),
    400: const Color(0xFFEF5350),
    500: const Color(0xFFF44336),
    600: const Color(0xFFE53935),
    700: const Color(0xFFD32F2F),
    800: const Color(0xFFC62828),
    900: const Color(0xFFB71C1C),
  };

  /// The red accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.redAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [red], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> redAccent = const <int, Color>{
    100: const Color(0xFFFF8A80),
    200: const Color(0xFFFF5252),
    400: const Color(0xFFFF1744),
    700: const Color(0xFFD50000),
  };

  /// The pink primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.pink[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [pinkAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> pink = const <int, Color>{
     50: const Color(0xFFFCE4EC),
    100: const Color(0xFFF8BBD0),
    200: const Color(0xFFF48FB1),
    300: const Color(0xFFF06292),
    400: const Color(0xFFEC407A),
    500: const Color(0xFFE91E63),
    600: const Color(0xFFD81B60),
    700: const Color(0xFFC2185B),
    800: const Color(0xFFAD1457),
    900: const Color(0xFF880E4F),
  };

  /// The pink accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.pinkAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [pink], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> pinkAccent = const <int, Color>{
    100: const Color(0xFFFF80AB),
    200: const Color(0xFFFF4081),
    400: const Color(0xFFF50057),
    700: const Color(0xFFC51162),
  };

  /// The purple primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.purple[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [purpleAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> purple = const <int, Color>{
     50: const Color(0xFFF3E5F5),
    100: const Color(0xFFE1BEE7),
    200: const Color(0xFFCE93D8),
    300: const Color(0xFFBA68C8),
    400: const Color(0xFFAB47BC),
    500: const Color(0xFF9C27B0),
    600: const Color(0xFF8E24AA),
    700: const Color(0xFF7B1FA2),
    800: const Color(0xFF6A1B9A),
    900: const Color(0xFF4A148C),
  };

  /// The purple accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.purpleAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [purple], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> purpleAccent = const <int, Color>{
    100: const Color(0xFFEA80FC),
    200: const Color(0xFFE040FB),
    400: const Color(0xFFD500F9),
    700: const Color(0xFFAA00FF),
  };

  /// The deep purple primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.deepPurple[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [deepPurpleAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> deepPurple = const <int, Color>{
     50: const Color(0xFFEDE7F6),
    100: const Color(0xFFD1C4E9),
    200: const Color(0xFFB39DDB),
    300: const Color(0xFF9575CD),
    400: const Color(0xFF7E57C2),
    500: const Color(0xFF673AB7),
    600: const Color(0xFF5E35B1),
    700: const Color(0xFF512DA8),
    800: const Color(0xFF4527A0),
    900: const Color(0xFF311B92),
  };

  /// The deep purple accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.deepPurpleAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [deepPurple], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> deepPurpleAccent = const <int, Color>{
    100: const Color(0xFFB388FF),
    200: const Color(0xFF7C4DFF),
    400: const Color(0xFF651FFF),
    700: const Color(0xFF6200EA),
  };

  /// The indigo primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.indigo[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [indigoAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> indigo = const <int, Color>{
     50: const Color(0xFFE8EAF6),
    100: const Color(0xFFC5CAE9),
    200: const Color(0xFF9FA8DA),
    300: const Color(0xFF7986CB),
    400: const Color(0xFF5C6BC0),
    500: const Color(0xFF3F51B5),
    600: const Color(0xFF3949AB),
    700: const Color(0xFF303F9F),
    800: const Color(0xFF283593),
    900: const Color(0xFF1A237E),
  };

  /// The indigo accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.indigoAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [indigo], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> indigoAccent = const <int, Color>{
    100: const Color(0xFF8C9EFF),
    200: const Color(0xFF536DFE),
    400: const Color(0xFF3D5AFE),
    700: const Color(0xFF304FFE),
  };

  /// The blue primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.blue[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [blueAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> blue = const <int, Color>{
     50: const Color(0xFFE3F2FD),
    100: const Color(0xFFBBDEFB),
    200: const Color(0xFF90CAF9),
    300: const Color(0xFF64B5F6),
    400: const Color(0xFF42A5F5),
    500: const Color(0xFF2196F3),
    600: const Color(0xFF1E88E5),
    700: const Color(0xFF1976D2),
    800: const Color(0xFF1565C0),
    900: const Color(0xFF0D47A1),
  };

  /// The blue accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.blueAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [blue], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> blueAccent = const <int, Color>{
    100: const Color(0xFF82B1FF),
    200: const Color(0xFF448AFF),
    400: const Color(0xFF2979FF),
    700: const Color(0xFF2962FF),
  };

  /// The light blue primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.lightBlue[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [lightBlueAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> lightBlue = const <int, Color>{
     50: const Color(0xFFE1F5FE),
    100: const Color(0xFFB3E5FC),
    200: const Color(0xFF81D4FA),
    300: const Color(0xFF4FC3F7),
    400: const Color(0xFF29B6F6),
    500: const Color(0xFF03A9F4),
    600: const Color(0xFF039BE5),
    700: const Color(0xFF0288D1),
    800: const Color(0xFF0277BD),
    900: const Color(0xFF01579B),
  };

  /// The light blue accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.lightBlueAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [lightBlue], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> lightBlueAccent = const <int, Color>{
    100: const Color(0xFF80D8FF),
    200: const Color(0xFF40C4FF),
    400: const Color(0xFF00B0FF),
    700: const Color(0xFF0091EA),
  };

  /// The cyan primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.cyan[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [cyanAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> cyan = const <int, Color>{
     50: const Color(0xFFE0F7FA),
    100: const Color(0xFFB2EBF2),
    200: const Color(0xFF80DEEA),
    300: const Color(0xFF4DD0E1),
    400: const Color(0xFF26C6DA),
    500: const Color(0xFF00BCD4),
    600: const Color(0xFF00ACC1),
    700: const Color(0xFF0097A7),
    800: const Color(0xFF00838F),
    900: const Color(0xFF006064),
  };

  /// The cyan accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.cyanAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [cyan], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> cyanAccent = const <int, Color>{
    100: const Color(0xFF84FFFF),
    200: const Color(0xFF18FFFF),
    400: const Color(0xFF00E5FF),
    700: const Color(0xFF00B8D4),
  };

  /// The teal primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.teal[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [tealAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> teal = const <int, Color>{
     50: const Color(0xFFE0F2F1),
    100: const Color(0xFFB2DFDB),
    200: const Color(0xFF80CBC4),
    300: const Color(0xFF4DB6AC),
    400: const Color(0xFF26A69A),
    500: const Color(0xFF009688),
    600: const Color(0xFF00897B),
    700: const Color(0xFF00796B),
    800: const Color(0xFF00695C),
    900: const Color(0xFF004D40),
  };

  /// The teal accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.tealAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [teal], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> tealAccent = const <int, Color>{
    100: const Color(0xFFA7FFEB),
    200: const Color(0xFF64FFDA),
    400: const Color(0xFF1DE9B6),
    700: const Color(0xFF00BFA5),
  };

  /// The green primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.green[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [greenAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> green = const <int, Color>{
     50: const Color(0xFFE8F5E9),
    100: const Color(0xFFC8E6C9),
    200: const Color(0xFFA5D6A7),
    300: const Color(0xFF81C784),
    400: const Color(0xFF66BB6A),
    500: const Color(0xFF4CAF50),
    600: const Color(0xFF43A047),
    700: const Color(0xFF388E3C),
    800: const Color(0xFF2E7D32),
    900: const Color(0xFF1B5E20),
  };

  /// The green accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.greenAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [green], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> greenAccent = const <int, Color>{
    100: const Color(0xFFB9F6CA),
    200: const Color(0xFF69F0AE),
    400: const Color(0xFF00E676),
    700: const Color(0xFF00C853),
  };

  /// The light green primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.lightGreen[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [lightGreenAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> lightGreen = const <int, Color>{
     50: const Color(0xFFF1F8E9),
    100: const Color(0xFFDCEDC8),
    200: const Color(0xFFC5E1A5),
    300: const Color(0xFFAED581),
    400: const Color(0xFF9CCC65),
    500: const Color(0xFF8BC34A),
    600: const Color(0xFF7CB342),
    700: const Color(0xFF689F38),
    800: const Color(0xFF558B2F),
    900: const Color(0xFF33691E),
  };

  /// The light green accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.lightGreenAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [lightGreen], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> lightGreenAccent = const <int, Color>{
    100: const Color(0xFFCCFF90),
    200: const Color(0xFFB2FF59),
    400: const Color(0xFF76FF03),
    700: const Color(0xFF64DD17),
  };

  /// The lime primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.lime[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [limeAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> lime = const <int, Color>{
     50: const Color(0xFFF9FBE7),
    100: const Color(0xFFF0F4C3),
    200: const Color(0xFFE6EE9C),
    300: const Color(0xFFDCE775),
    400: const Color(0xFFD4E157),
    500: const Color(0xFFCDDC39),
    600: const Color(0xFFC0CA33),
    700: const Color(0xFFAFB42B),
    800: const Color(0xFF9E9D24),
    900: const Color(0xFF827717),
  };

  /// The lime accent primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.limeAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [lime], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> limeAccent = const <int, Color>{
    100: const Color(0xFFF4FF81),
    200: const Color(0xFFEEFF41),
    400: const Color(0xFFC6FF00),
    700: const Color(0xFFAEEA00),
  };

  /// The yellow primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.yellow[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [yellowAccentAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> yellow = const <int, Color>{
     50: const Color(0xFFFFFDE7),
    100: const Color(0xFFFFF9C4),
    200: const Color(0xFFFFF59D),
    300: const Color(0xFFFFF176),
    400: const Color(0xFFFFEE58),
    500: const Color(0xFFFFEB3B),
    600: const Color(0xFFFDD835),
    700: const Color(0xFFFBC02D),
    800: const Color(0xFFF9A825),
    900: const Color(0xFFF57F17),
  };

  /// The yellow accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.yellowAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [yellow], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> yellowAccent = const <int, Color>{
    100: const Color(0xFFFFFF8D),
    200: const Color(0xFFFFFF00),
    400: const Color(0xFFFFEA00),
    700: const Color(0xFFFFD600),
  };

  /// The amber primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.amber[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [amberAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> amber = const <int, Color>{
     50: const Color(0xFFFFF8E1),
    100: const Color(0xFFFFECB3),
    200: const Color(0xFFFFE082),
    300: const Color(0xFFFFD54F),
    400: const Color(0xFFFFCA28),
    500: const Color(0xFFFFC107),
    600: const Color(0xFFFFB300),
    700: const Color(0xFFFFA000),
    800: const Color(0xFFFF8F00),
    900: const Color(0xFFFF6F00),
  };

  /// The amber accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.amberAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [amber], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> amberAccent = const <int, Color>{
    100: const Color(0xFFFFE57F),
    200: const Color(0xFFFFD740),
    400: const Color(0xFFFFC400),
    700: const Color(0xFFFFAB00),
  };

  /// The orange primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.orange[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [orangeAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> orange = const <int, Color>{
     50: const Color(0xFFFFF3E0),
    100: const Color(0xFFFFE0B2),
    200: const Color(0xFFFFCC80),
    300: const Color(0xFFFFB74D),
    400: const Color(0xFFFFA726),
    500: const Color(0xFFFF9800),
    600: const Color(0xFFFB8C00),
    700: const Color(0xFFF57C00),
    800: const Color(0xFFEF6C00),
    900: const Color(0xFFE65100),
  };

  /// The orange accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.orangeAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [orange], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> orangeAccent = const <int, Color>{
    100: const Color(0xFFFFD180),
    200: const Color(0xFFFFAB40),
    400: const Color(0xFFFF9100),
    700: const Color(0xFFFF6D00),
  };

  /// The deep orange primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.deepOrange[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [deepOrangeAccent], the corresponding accent colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> deepOrange = const <int, Color>{
     50: const Color(0xFFFBE9E7),
    100: const Color(0xFFFFCCBC),
    200: const Color(0xFFFFAB91),
    300: const Color(0xFFFF8A65),
    400: const Color(0xFFFF7043),
    500: const Color(0xFFFF5722),
    600: const Color(0xFFF4511E),
    700: const Color(0xFFE64A19),
    800: const Color(0xFFD84315),
    900: const Color(0xFFBF360C),
  };

  /// The deep orange accent swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.deepOrangeAccent[400],
  ///  ),
  /// ```
  ///
  /// See also:
  ///
  /// * [deepOrange], the corresponding primary colors.
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> deepOrangeAccent = const <int, Color>{
    100: const Color(0xFFFF9E80),
    200: const Color(0xFFFF6E40),
    400: const Color(0xFFFF3D00),
    700: const Color(0xFFDD2C00),
  };

  /// The brown primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.brown[400],
  ///  ),
  /// ```
  ///
  /// This swatch has no corresponding accent swatch.
  ///
  /// See also:
  ///
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> brown = const <int, Color>{
     50: const Color(0xFFEFEBE9),
    100: const Color(0xFFD7CCC8),
    200: const Color(0xFFBCAAA4),
    300: const Color(0xFFA1887F),
    400: const Color(0xFF8D6E63),
    500: const Color(0xFF795548),
    600: const Color(0xFF6D4C41),
    700: const Color(0xFF5D4037),
    800: const Color(0xFF4E342E),
    900: const Color(0xFF3E2723),
  };

  /// The grey primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.grey[400],
  ///  ),
  /// ```
  ///
  /// This swatch has no corresponding accent swatch.
  ///
  /// This swatch, in addition to the values 50 and 100 to 900 in 100
  /// increments, also features the special values 350 and 850. The 350 value is
  /// used for raised button while pressed in light themes, and 850 is used for
  /// the background color of the dark theme. See [ThemeData.brightness].
  ///
  /// See also:
  ///
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> grey = const <int, Color>{
     50: const Color(0xFFFAFAFA),
    100: const Color(0xFFF5F5F5),
    200: const Color(0xFFEEEEEE),
    300: const Color(0xFFE0E0E0),
    350: const Color(0xFFD6D6D6), // only for raised button while pressed in light theme
    400: const Color(0xFFBDBDBD),
    500: const Color(0xFF9E9E9E),
    600: const Color(0xFF757575),
    700: const Color(0xFF616161),
    800: const Color(0xFF424242),
    850: const Color(0xFF303030), // only for background color in dark theme
    900: const Color(0xFF212121),
  };

  /// The blue-grey primary swatch.
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.blueGrey[400],
  ///  ),
  /// ```
  ///
  /// This swatch has no corresponding accent swatch.
  ///
  /// See also:
  ///
  /// * [Theme.of], which allows you to select colors from the current theme
  ///   rather than hard-coding colors in your build methods.
  static const Map<int, Color> blueGrey = const <int, Color>{
     50: const Color(0xFFECEFF1),
    100: const Color(0xFFCFD8DC),
    200: const Color(0xFFB0BEC5),
    300: const Color(0xFF90A4AE),
    400: const Color(0xFF78909C),
    500: const Color(0xFF607D8B),
    600: const Color(0xFF546E7A),
    700: const Color(0xFF455A64),
    800: const Color(0xFF37474F),
    900: const Color(0xFF263238),
  };

  /// The material design primary color swatches (except grey).
  static const List<Map<int, Color>> primaries = const <Map<int, Color>>[
    red,
    pink,
    purple,
    deepPurple,
    indigo,
    blue,
    lightBlue,
    cyan,
    teal,
    green,
    lightGreen,
    lime,
    yellow,
    amber,
    orange,
    deepOrange,
    brown,
    // grey intentionally omitted
    blueGrey,
  ];

  /// The material design accent color swatches.
  static const List<Map<int, Color>> accents = const <Map<int, Color>>[
    redAccent,
    pinkAccent,
    purpleAccent,
    deepPurpleAccent,
    indigoAccent,
    blueAccent,
    lightBlueAccent,
    cyanAccent,
    tealAccent,
    greenAccent,
    lightGreenAccent,
    limeAccent,
    yellowAccent,
    amberAccent,
    orangeAccent,
    deepOrangeAccent,
  ];
}
