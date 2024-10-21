// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Flutter code sample for [AnimatedValue].

void main() => runApp(const AnimatedValueApp());

/// Prizes come in all shapes!
enum Prize implements Key {
  circle,
  triangle,
  square,
  hexagon;

  @override
  String toString() => name;
}

final math.Random rng = math.Random();

class PrizeSpinner extends StatelessWidget {
  const PrizeSpinner({super.key});

  static final double randomDirection = rng.nextDouble();

  // This build method returns an AnimatedRotation, which is a subtype
  // of AnimatedValue!
  @override
  Widget build(BuildContext context) {
    final Prize? prize = FreePrizes.maybeOf(context);

    final double turns;
    if (prize != null) {
      // The spinner should end up at the center of the section.
      turns = (prize.index * 2 + 1) / (Prize.values.length * 2);
    } else {
      // Before the first spin, load the spinner facing a random direction.
      turns = randomDirection;
    }

    // Changing a widget's key will cause its state to reset.
    // So if an AnimatedValue widget animates from an initialValue,
    // changing the key will make the animation run again!

    return AnimatedRotation(
      key: prize,
      turns: turns,
      initialTurns: prize != null ? turns - 2 : null,
      duration: const Duration(seconds: 2),
      curve: Curves.easeOutCubic,
      onEnd: () {
        if (prize != null) {
          FreePrizes.recolor(context);

          showDialog<void>(
            context: context,
            builder: (BuildContext context) => PrizePopup(prize: prize),
          );
        }
      },
      child: const Align(
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.arrow_right_alt_rounded,
          size: 125,
          color: Color(0xff202020),
        ),
      ),
    );
  }
}

abstract interface class _PrizeScope {
  /// Randomize the prize!
  void randomize();

  /// Color the screen!
  void recolor();
}

class FreePrizes extends InheritedWidget {
  const FreePrizes({super.key, this.prize, required super.child});

  final Prize? prize;

  static Prize? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FreePrizes>()?.prize;
  }

  static _PrizeScope _prizeScope(BuildContext context) {
    return context.findAncestorStateOfType<_AnimatedValueAppState>()!;
  }

  static void spin(BuildContext context) {
    _prizeScope(context).randomize();
  }

  static void recolor(BuildContext context) {
    _prizeScope(context).recolor();
  }

  @override
  bool updateShouldNotify(FreePrizes oldWidget) => prize != oldWidget.prize;
}

class AnimatedValueApp extends StatefulWidget {
  const AnimatedValueApp({super.key});

  @override
  State<AnimatedValueApp> createState() => _AnimatedValueAppState();
}

class _AnimatedValueAppState extends State<AnimatedValueApp> implements _PrizeScope {
  Prize? prize;

  static final int prizeCount = Prize.values.length;
  @override
  void randomize() {
    int? newIndex = prize?.index;
    if (newIndex != null) {
      // Never the same prize twice in a row!
      newIndex += 1 + rng.nextInt(prizeCount - 1);
      newIndex %= prizeCount;
    }
    setState(() {
      prize = Prize.values[newIndex ?? rng.nextInt(prizeCount)];
    });
  }

  static const Color _startingColor = Colors.deepPurple;
  Color seedColor = _startingColor;

  @override
  void recolor() {
    setState(() {
      seedColor = switch (prize!) {
        Prize.circle => Colors.green,
        Prize.triangle => Colors.red,
        Prize.square => Colors.blue,
        Prize.hexagon => Colors.purple,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    AppBarTheme? appBarTheme;
    if (seedColor != _startingColor) {
      appBarTheme = AppBarTheme(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      );
    }
    return FreePrizes(
      prize: prize,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: colorScheme,
          appBarTheme: appBarTheme,
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('Animated Value demo')),
          body: const Center(child: AnimatedValueExample()),
        ),
      ),
    );
  }
}

class AnimatedValueExample extends StatefulWidget {
  const AnimatedValueExample({super.key});

  @override
  State<AnimatedValueExample> createState() => _AnimatedSlideExampleState();
}

class _AnimatedSlideExampleState extends State<AnimatedValueExample> {
  static const List<Polygon> polygons = <Polygon>[
    Polygon(sides: 6, color: Colors.purple, alignment: Alignment(0.55, -0.55)),
    Polygon(sides: 4, color: Colors.blue, alignment: Alignment(-0.55, -0.55)),
    Polygon(sides: 3, color: Colors.red, alignment: Alignment(-0.55, 0.55)),
    Polygon(sides: 0, color: Colors.green, alignment: Alignment(0.55, 0.55)),
  ];

  static const Widget wheel = FittedBox(
    child: Padding(
      padding: EdgeInsets.all(25.0),
      child: SizedBox.square(
        dimension: 200,
        child: _WheelBase(
          child: SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  height: 2,
                  child: ColoredBox(color: Color(0xff8a6f5b)),
                ),
                SizedBox(
                  width: 2,
                  height: double.infinity,
                  child: ColoredBox(color: Color(0xff8a6f5b)),
                ),
                ...polygons,
                PrizeSpinner(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  static const ButtonStyle buttonStyle = ButtonStyle(
    padding: WidgetStatePropertyAll<EdgeInsets>(
      EdgeInsets.symmetric(horizontal: 30, vertical: 20),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Expanded(child: wheel),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: FilledButton(
            style: buttonStyle,
            onPressed: () => FreePrizes.spin(context),
            child: const Text('Spin!'),
          ),
        ),
      ],
    );
  }
}

class _WheelBase extends StatelessWidget {
  const _WheelBase({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return PhysicalShape(
      clipper: const ShapeBorderClipper(shape: CircleBorder()),
      color: colorScheme.surfaceContainer,
      elevation: 1.0,
      child: child,
    );
  }
}

class Polygon extends StatelessWidget {
  const Polygon({
    super.key,
    required this.sides,
    required this.color,
    this.alignment = Alignment.center,
  });
  final int sides;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: CustomPaint(
        size: const Size(32, 32),
        painter: PolygonPainter(sides: sides, color: color),
      ),
    );
  }
}

class PolygonPainter extends CustomPainter {
  const PolygonPainter({
    required this.sides,
    required this.color,
  }) : step = 2 * math.pi / sides;

  final int sides;
  final Color color;

  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()..color = color;

    if (sides == 0) {
      canvas.drawCircle(const Offset(16, 16), 15, fill);
      return;
    }

    final Path path = Path();
    for (int i = 0; i < sides; i += 1) {
      final double theta = math.pi / 2 + step * (i + 0.5);
      final double x = 16 + 16 * math.cos(theta);
      final double y = 16 + 16 * math.sin(theta);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path..close(), fill);
  }

  @override
  bool shouldRepaint(PolygonPainter oldDelegate) => false;
}

class PrizePopup extends StatefulWidget {
  const PrizePopup({super.key, required this.prize});
  final Prize prize;

  @override
  State<PrizePopup> createState() => _PrizePopupState();
}

class _PrizePopupState extends State<PrizePopup> {
  double scale = 0.5;
  void grow() {
    setState(() {
      scale *= 1.5;
    });
  }

  late final Prize _prize = widget.prize;
  late final Text description = Text('You won a $_prize!');
  late final Polygon shape = switch (_prize) {
    Prize.circle   => const Polygon(sides: 0, color: Colors.green),
    Prize.triangle => const Polygon(sides: 3, color: Colors.red),
    Prize.square   => const Polygon(sides: 4, color: Colors.blue),
    Prize.hexagon  => const Polygon(sides: 6, color: Colors.purple),
  };

  @override
  Widget build(BuildContext context) {
    final AnimatedValue<double> animatedValue = AnimatedScale(
      scale: scale,
      duration: Durations.medium1,
      curve: Curves.ease,
      child: shape,
    );

    return AlertDialog(
      title: const Text('Congrats'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          description,
          const SizedBox(height: 16),
          SizedBox(
            height: 32,
            child: animatedValue,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('done'),
        ),
        FilledButton(
          onPressed: grow,
          child: const Text('tap to grow'),
        ),
      ],
    );
  }
}
