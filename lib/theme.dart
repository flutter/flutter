import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff695f11),
      surfaceTint: Color(0xff695f11),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xfff3e48a),
      onPrimaryContainer: Color(0xff504700),
      secondary: Color(0xff645f41),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffebe3bd),
      onSecondaryContainer: Color(0xff4c472b),
      tertiary: Color(0xff416651),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffc3ecd2),
      onTertiaryContainer: Color(0xff294e3b),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff9eb),
      onSurface: Color(0xff1d1c13),
      onSurfaceVariant: Color(0xff4a4739),
      outline: Color(0xff7b7768),
      outlineVariant: Color(0xffccc6b5),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff323027),
      inversePrimary: Color(0xffd6c871),
      primaryFixed: Color(0xfff3e48a),
      onPrimaryFixed: Color(0xff201c00),
      primaryFixedDim: Color(0xffd6c871),
      onPrimaryFixedVariant: Color(0xff504700),
      secondaryFixed: Color(0xffebe3bd),
      onSecondaryFixed: Color(0xff1f1c05),
      secondaryFixedDim: Color(0xffcfc7a2),
      onSecondaryFixedVariant: Color(0xff4c472b),
      tertiaryFixed: Color(0xffc3ecd2),
      onTertiaryFixed: Color(0xff002112),
      tertiaryFixedDim: Color(0xffa7d0b6),
      onTertiaryFixedVariant: Color(0xff294e3b),
      surfaceDim: Color(0xffdfdacc),
      surfaceBright: Color(0xfffff9eb),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff9f3e5),
      surfaceContainer: Color(0xfff3ede0),
      surfaceContainerHigh: Color(0xffede8da),
      surfaceContainerHighest: Color(0xffe8e2d5),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff3d3700),
      surfaceTint: Color(0xff695f11),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff796e20),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff3b371c),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff736e4e),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff183d2b),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff4f7560),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff9eb),
      onSurface: Color(0xff13110a),
      onSurfaceVariant: Color(0xff39362a),
      outline: Color(0xff565345),
      outlineVariant: Color(0xff716d5e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff323027),
      inversePrimary: Color(0xffd6c871),
      primaryFixed: Color(0xff796e20),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff5f5506),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff736e4e),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff5a5538),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff4f7560),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff375c48),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffcbc6b9),
      surfaceBright: Color(0xfffff9eb),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff9f3e5),
      surfaceContainer: Color(0xffede8da),
      surfaceContainerHigh: Color(0xffe2dccf),
      surfaceContainerHighest: Color(0xffd6d1c4),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff322c00),
      surfaceTint: Color(0xff695f11),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff534a00),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff302c13),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff4e4a2d),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff0c3321),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff2c503d),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff9eb),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff2f2c20),
      outlineVariant: Color(0xff4c493c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff323027),
      inversePrimary: Color(0xffd6c871),
      primaryFixed: Color(0xff534a00),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff3a3300),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff4e4a2d),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff373319),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff2c503d),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff143927),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbdb8ac),
      surfaceBright: Color(0xfffff9eb),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff6f0e2),
      surfaceContainer: Color(0xffe8e2d5),
      surfaceContainerHigh: Color(0xffd9d4c7),
      surfaceContainerHighest: Color(0xffcbc6b9),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffd6c871),
      surfaceTint: Color(0xffd6c871),
      onPrimary: Color(0xff373100),
      primaryContainer: Color(0xff504700),
      onPrimaryContainer: Color(0xfff3e48a),
      secondary: Color(0xffcfc7a2),
      onSecondary: Color(0xff353117),
      secondaryContainer: Color(0xff4c472b),
      onSecondaryContainer: Color(0xffebe3bd),
      tertiary: Color(0xffa7d0b6),
      onTertiary: Color(0xff113725),
      tertiaryContainer: Color(0xff294e3b),
      onTertiaryContainer: Color(0xffc3ecd2),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff15130c),
      onSurface: Color(0xffe8e2d5),
      onSurfaceVariant: Color(0xffccc6b5),
      outline: Color(0xff959181),
      outlineVariant: Color(0xff4a4739),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe8e2d5),
      inversePrimary: Color(0xff695f11),
      primaryFixed: Color(0xfff3e48a),
      onPrimaryFixed: Color(0xff201c00),
      primaryFixedDim: Color(0xffd6c871),
      onPrimaryFixedVariant: Color(0xff504700),
      secondaryFixed: Color(0xffebe3bd),
      onSecondaryFixed: Color(0xff1f1c05),
      secondaryFixedDim: Color(0xffcfc7a2),
      onSecondaryFixedVariant: Color(0xff4c472b),
      tertiaryFixed: Color(0xffc3ecd2),
      onTertiaryFixed: Color(0xff002112),
      tertiaryFixedDim: Color(0xffa7d0b6),
      onTertiaryFixedVariant: Color(0xff294e3b),
      surfaceDim: Color(0xff15130c),
      surfaceBright: Color(0xff3b3930),
      surfaceContainerLowest: Color(0xff100e07),
      surfaceContainerLow: Color(0xff1d1c13),
      surfaceContainer: Color(0xff212017),
      surfaceContainerHigh: Color(0xff2c2a21),
      surfaceContainerHighest: Color(0xff37352c),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffecde84),
      surfaceTint: Color(0xffd6c871),
      onPrimary: Color(0xff2b2600),
      primaryContainer: Color(0xff9e9241),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffe5ddb7),
      onSecondary: Color(0xff2a260d),
      secondaryContainer: Color(0xff989170),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffbde6cc),
      onTertiary: Color(0xff042c1b),
      tertiaryContainer: Color(0xff729982),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff15130c),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffe2dcca),
      outline: Color(0xffb7b2a1),
      outlineVariant: Color(0xff959080),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe8e2d5),
      inversePrimary: Color(0xff514800),
      primaryFixed: Color(0xfff3e48a),
      onPrimaryFixed: Color(0xff141100),
      primaryFixedDim: Color(0xffd6c871),
      onPrimaryFixedVariant: Color(0xff3d3700),
      secondaryFixed: Color(0xffebe3bd),
      onSecondaryFixed: Color(0xff141100),
      secondaryFixedDim: Color(0xffcfc7a2),
      onSecondaryFixedVariant: Color(0xff3b371c),
      tertiaryFixed: Color(0xffc3ecd2),
      onTertiaryFixed: Color(0xff00150a),
      tertiaryFixedDim: Color(0xffa7d0b6),
      onTertiaryFixedVariant: Color(0xff183d2b),
      surfaceDim: Color(0xff15130c),
      surfaceBright: Color(0xff47443b),
      surfaceContainerLowest: Color(0xff080703),
      surfaceContainerLow: Color(0xff1f1e15),
      surfaceContainer: Color(0xff2a281f),
      surfaceContainerHigh: Color(0xff353329),
      surfaceContainerHighest: Color(0xff403e34),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfffff1a1),
      surfaceTint: Color(0xffd6c871),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffd2c46d),
      onPrimaryContainer: Color(0xff0e0b00),
      secondary: Color(0xfff9f0ca),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffcbc39f),
      onSecondaryContainer: Color(0xff0e0b00),
      tertiary: Color(0xffd0fadf),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffa3ccb3),
      onTertiaryContainer: Color(0xff000e06),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff15130c),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfff6f0dd),
      outlineVariant: Color(0xffc8c2b1),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe8e2d5),
      inversePrimary: Color(0xff514800),
      primaryFixed: Color(0xfff3e48a),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffd6c871),
      onPrimaryFixedVariant: Color(0xff141100),
      secondaryFixed: Color(0xffebe3bd),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffcfc7a2),
      onSecondaryFixedVariant: Color(0xff141100),
      tertiaryFixed: Color(0xffc3ecd2),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffa7d0b6),
      onTertiaryFixedVariant: Color(0xff00150a),
      surfaceDim: Color(0xff15130c),
      surfaceBright: Color(0xff535046),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff212017),
      surfaceContainer: Color(0xff323027),
      surfaceContainerHigh: Color(0xff3e3b32),
      surfaceContainerHighest: Color(0xff49473d),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.background,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
