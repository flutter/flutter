// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [SplashBox].

void main() => runApp(const SplashBoxExampleApp());

class SplashBoxExampleApp extends StatefulWidget {
  const SplashBoxExampleApp() : super(key: const AppKey());

  @override
  State<SplashBoxExampleApp> createState() => _SplashBoxExampleAppState();
}

class _SplashBoxExampleAppState extends State<SplashBoxExampleApp> {
  Hue hue = Hue(0);
  Brightness brightness = Brightness.light;

  /// [AnimatedTheme] is an [ImplicitlyAnimatedWidget] that
  /// creates a smooth transition when the [ThemeData] changes.
  ///
  /// The [Material] widget also uses implicit animations to create
  /// a similar effect.
  ///
  /// Since [MaterialApp] includes an [AnimatedTheme], any color from
  /// `Theme.of(context).colorScheme` will have a smooth transition,
  /// so we can use a [SplashBox] for improved performance.
  ThemeData get theme {
    final Color color = hue.toColor();

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        primaryFixed: color,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: color,
        foregroundColor: Colors.black,
      ),
    );
  }

  /// Since this app uses a [GlobalKey], we can cycle the hue
  /// by calling [Hue.cycle].
  void cycleHue() {
    setState(() {
      hue = hue.next;
      if (hue.colorName == 'red') {
        brightness = switch (brightness) {
          Brightness.light => Brightness.dark,
          Brightness.dark => Brightness.light,
        };
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      home: const SplashBoxExample(),
    );
  }
}

class SplashBoxExample extends StatelessWidget {
  const SplashBoxExample({super.key});

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primaryFixed;

    final Widget child = Text(
      Hue.nameOf(color),
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('SplashBox example')),
      body: Center(
        child: SizedBox(
          width: 200,
          height: 100,
          child: GradientButton(
            onPressed: Hue.cycle,
            color: color,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// If you use a [Material] widget to build a button,
/// it will have a solid color.
///
/// The `Ink` widget allows painting a decoration on top of
/// a [Material], but it has a few downsides (see the [Ink]
/// documentation for more details).
///
/// Instead, we can use [SplashBox] to give our button a
/// super fun gradient!
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.color,
    required this.onPressed,
    required this.child,
  });

  final Color color;
  final VoidCallback? onPressed;
  final Widget child;

  /// This getter creates a [SplashBox] using the values passed
  /// to the widget.
  ///
  /// Setting the [SplashBox.color] is optional, but doing so
  /// allows the widget's descendants to access its value,
  /// using the [Splash.of] method.
  ///
  /// ```dart
  /// final Color? color = Splash.of(context).color;
  /// ```
  SplashBox get splashBox {
    return SplashBox(
      color: color,
      child: InkWell(
        onTap: onPressed,
        overlayColor: WidgetStatePropertyAll<Color>(
          color.withOpacity(1 / 8),
        ),
        child: Center(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = switch (Theme.of(context).brightness) {
      Brightness.light => true,
      Brightness.dark => false,
    };

    final ShapeBorder shape = ContinuousRectangleBorder(
      side: BorderSide(color: color, width: 4.0),
      borderRadius: BorderRadius.circular(48.0),
    );

    final Gradient gradient;
    if (isLight) {
      final HSLColor hslColor = HSLColor.fromColor(color);
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          hslColor.withLightness(0.85).toColor(),
          hslColor.withSaturation(0.85).toColor(),
        ],
      );
    } else {
      gradient = LinearGradient(
        begin: const Alignment(0, -1.125),
        end: const Alignment(0, 1.75),
        colors: <Color>[color, Colors.black],
      );
    }

    return PhysicalShape(
      clipper: ShapeBorderClipper(shape: shape),
      color: color,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      elevation: 8.0,
      shadowColor: isLight ? Colors.black45 : Colors.black,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
        child: splashBox,
      ),
    );
  }
}

/// Using a global key allows us to call functions from the app's [State]
/// anywhere we'd like, and [GlobalObjectKey] is great because it has
/// a `const` constructor.
class AppKey extends GlobalObjectKey<_SplashBoxExampleAppState> {
  /// We're using the [Hue] type as the [GlobalObjectKey] argument,
  /// but any constant [Object] works.
  ///
  /// Since this constructor creates the same constant value each time,
  /// each [AppKey] instance will point to the same [State].
  const AppKey() : super(Hue);
}

/// This is an "extension type": it's similar to making a class
/// with just 1 member:
///
/// ```dart
/// class Hue {
///   Hue(this.hue);
///
///   final int hue;
/// }
/// ```
///
/// But extension types have better performance!
///
/// more info: https://dart.dev/language/extension-types
extension type Hue(int hue) {
  factory Hue.fromColor(Color color) {
    final double hue = HSLColor.fromColor(color).hue;
    final int roundedHue = (hue / 15 - 0.4).round() * 15;
    return Hue(roundedHue);
  }

  static void cycle() => const AppKey().currentState!.cycleHue();

  /// Returns a [Hue], 15 degrees down the color wheel.
  Hue get next => Hue((hue + 15) % 360);

  Color toColor() {
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 1.0, 0.5).toColor();
  }

  /// A rationale for 'summer' can be found at https://hue-man.app/summer
  ///
  /// All other color names are pulled from one Wikipedia page:
  /// https://en.wikipedia.org/wiki/Secondary_color?oldid=1222912753#RGB_and_CMYK
  String get colorName => switch (hue) {
    0   => 'red',
    15  => 'vermilion',
    30  => 'orange',
    45  => 'amber',
    60  => 'yellow',
    75  => 'lime',
    90  => 'summer',
    105 => 'harlequin',
    120 => 'green',
    135 => 'erin',
    150 => 'spring',
    165 => 'aquamarine',
    180 => 'cyan',
    195 => 'capri',
    210 => 'azure',
    225 => 'cerulean',
    240 => 'blue',
    255 => 'indigo',
    270 => 'violet',
    285 => 'purple',
    300 => 'magenta',
    315 => 'cerise',
    330 => 'rose',
    345 => 'crimson',
    _   => '',
  };

  /// Returns a [Color]'s name as a [String], based on its [Hue].
  static String nameOf(Color color) => Hue.fromColor(color).colorName;
}
