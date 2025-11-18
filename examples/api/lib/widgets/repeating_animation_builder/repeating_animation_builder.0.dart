// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Flutter code sample for [RepeatingAnimationBuilder].
void main() {
  runApp(const RepeatingAnimationBuilderExampleApp());
}

class RepeatingAnimationBuilderExampleApp extends StatelessWidget {
  const RepeatingAnimationBuilderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const RepeatingAnimationBuilderExample(),
    );
  }
}

class RepeatingAnimationBuilderExample extends StatefulWidget {
  const RepeatingAnimationBuilderExample({super.key});

  @override
  State<RepeatingAnimationBuilderExample> createState() => _RepeatingAnimationBuilderExampleState();
}

class _RepeatingAnimationBuilderExampleState extends State<RepeatingAnimationBuilderExample> {
  bool _isPaused = false;
  bool _isReversing = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RepeatingAnimationBuilder'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RepeatingAnimationBuilder<double>(
        animatable: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 4),
        paused: _isPaused,
        repeatMode: _isReversing ? RepeatMode.reverse : RepeatMode.restart,
        curve: Curves.easeInOut,
        builder: (BuildContext context, double value, Widget? child) {
          return Stack(
            children: <Widget>[
              Center(
                child: Transform.rotate(angle: value * 0.5 * math.pi, child: child),
              ),
              _buildControls(colors, value),
            ],
          );
        },
        child: _buildFlowerGem(colors),
      ),
    );
  }

  /// Builds the layered visual of the flower and the gem.
  Widget _buildFlowerGem(ColorScheme colors) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            decoration: ShapeDecoration(
              color: colors.primaryContainer.withOpacity(0.5),
              shape: StarBorder(
                points: 8,
                innerRadiusRatio: 0.7,
                pointRounding: 0.5,
                side: BorderSide(color: colors.primary, width: 2),
              ),
            ),
          ),
          RepeatingAnimationBuilder<double>(
            animatable: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(seconds: 2),
            paused: _isPaused,
            repeatMode: RepeatMode.reverse,
            curve: Curves.easeInOutSine,
            builder: (BuildContext context, double value, Widget? child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: colors.primary.withOpacity(value * 0.7), blurRadius: 25),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: _buildGemCore(colors),
          ),
        ],
      ),
    );
  }

  /// Builds the static, non-animated core of the gem.
  Widget _buildGemCore(ColorScheme colors) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: <Color>[colors.primary, colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  /// Builds the controls area at the bottom of the screen.
  Widget _buildControls(ColorScheme colors, double animationValue) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildPlayPauseButton(colors, animationValue),
          const SizedBox(height: 24),
          _buildReverseToggle(colors),
        ],
      ),
    );
  }

  /// Builds the custom Play/Pause button with a progress indicator border.
  Widget _buildPlayPauseButton(ColorScheme colors, double animationValue) {
    const double buttonSize = 88.0;
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      // InkWell provides the ripple effect on tap.
      child: InkWell(
        borderRadius: BorderRadius.circular(buttonSize / 2),
        onTap: () => setState(() => _isPaused = !_isPaused),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // The progress indicator is the bottom layer, acting as a border.
            SizedBox.expand(
              // This makes the indicator fill the SizedBox
              child: CircularProgressIndicator(
                value: animationValue,
                strokeWidth: 6,
                backgroundColor: colors.surfaceVariant.withOpacity(0.3),
                color: colors.primary,
              ),
            ),
            // The solid button core is the middle layer.
            Container(
              margin: const EdgeInsets.all(8), // Inset from the progress ring
              decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primary),
            ),
            // The icon is the top layer.
            Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 40, color: colors.onPrimary),
          ],
        ),
      ),
    );
  }

  /// Builds the animation mode toggle control.
  Widget _buildReverseToggle(ColorScheme colors) {
    return GestureDetector(
      // The entire area is clickable.
      onTap: () => setState(() => _isReversing = !_isReversing),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: colors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _isReversing ? Icons.sync : Icons.sync_disabled,
              color: colors.onSurface,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isReversing ? 'Back & Forth' : 'Forward Only',
              style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _isReversing,
              onChanged: (bool value) {
                setState(() {
                  _isReversing = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
