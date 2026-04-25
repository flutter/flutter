// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Animations class to compute animation values for overlay widgets.
///
/// Values are loosely based on Material Design specs, which are minimal.
class Animations {
  Animations(
    this.openController,
    this.tapController,
    this.rippleController,
    this.dismissController,
  );
  final AnimationController openController;
  final AnimationController tapController;
  final AnimationController rippleController;
  final AnimationController dismissController;

  static const double backgroundMaxOpacity = 0.96;
  static const double backgroundTapRadius = 20.0;
  static const double rippleMaxOpacity = 0.75;
  static const double tapTargetToContentDistance = 20.0;
  static const double tapTargetMaxRadius = 44.0;
  static const double tapTargetMinRadius = 20.0;
  static const double tapTargetRippleRadius = 64.0;

  Animation<double> backgroundOpacity(FeatureDiscoveryStatus status) {
    switch (status) {
      case FeatureDiscoveryStatus.closed:
        return const AlwaysStoppedAnimation<double>(0);
      case FeatureDiscoveryStatus.open:
        return Tween<double>(begin: 0, end: backgroundMaxOpacity)
            .chain(CurveTween(curve: const Interval(0, 0.5, curve: Curves.ease)))
            .animate(openController);
      case FeatureDiscoveryStatus.tap:
        return Tween<double>(
          begin: backgroundMaxOpacity,
          end: 0,
        ).chain(CurveTween(curve: Curves.ease)).animate(tapController);
      case FeatureDiscoveryStatus.dismiss:
        return Tween<double>(begin: backgroundMaxOpacity, end: 0)
            .chain(CurveTween(curve: const Interval(0.2, 1.0, curve: Curves.ease)))
            .animate(dismissController);
      case FeatureDiscoveryStatus.ripple:
        return const AlwaysStoppedAnimation<double>(backgroundMaxOpacity);
    }
  }

  Animation<double> backgroundRadius(FeatureDiscoveryStatus status, double backgroundRadiusMax) {
    switch (status) {
      case FeatureDiscoveryStatus.closed:
        return const AlwaysStoppedAnimation<double>(0);
      case FeatureDiscoveryStatus.open:
        return Tween<double>(begin: 0, end: backgroundRadiusMax)
            .chain(CurveTween(curve: const Interval(0, 0.5, curve: Curves.ease)))
            .animate(openController);
      case FeatureDiscoveryStatus.tap:
        return Tween<double>(
          begin: backgroundRadiusMax,
          end: backgroundRadiusMax + backgroundTapRadius,
        ).chain(CurveTween(curve: Curves.ease)).animate(tapController);
      case FeatureDiscoveryStatus.dismiss:
        return Tween<double>(
          begin: backgroundRadiusMax,
          end: 0,
        ).chain(CurveTween(curve: Curves.ease)).animate(dismissController);
      case FeatureDiscoveryStatus.ripple:
        return AlwaysStoppedAnimation<double>(backgroundRadiusMax);
    }
  }

  Animation<Offset> backgroundCenter(FeatureDiscoveryStatus status, Offset start, Offset end) {
    switch (status) {
      case FeatureDiscoveryStatus.closed:
        return AlwaysStoppedAnimation<Offset>(start);
      case FeatureDiscoveryStatus.open:
        return Tween<Offset>(begin: start, end: end)
            .chain(CurveTween(curve: const Interval(0, 0.5, curve: Curves.ease)))
            .animate(openController);
      case FeatureDiscoveryStatus.tap:
        return Tween<Offset>(
          begin: end,
          end: start,
        ).chain(CurveTween(curve: Curves.ease)).animate(tapController);
      case FeatureDiscoveryStatus.dismiss:
        return Tween<Offset>(
          begin: end,
          end: start,
        ).chain(CurveTween(curve: Curves.ease)).animate(dismissController);
      case FeatureDiscoveryStatus.ripple:
        return AlwaysStoppedAnimation<Offset>(end);
    }
  }

  Animation<double> contentOpacity(FeatureDiscoveryStatus status) {
    switch (status) {
      case FeatureDiscoveryStatus.closed:
        return const AlwaysStoppedAnimation<double>(0);
      case FeatureDiscoveryStatus.open:
        return Tween<double>(begin: 0, end: 1.0)
            .chain(CurveTween(curve: const Interval(0.4, 0.7, curve: Curves.ease)))
            .animate(openController);
      case FeatureDiscoveryStatus.tap:
        return Tween<double>(begin: 1.0, end: 0)
            .chain(CurveTween(curve: const Interval(0, 0.4, curve: Curves.ease)))
            .animate(tapController);
      case FeatureDiscoveryStatus.dismiss:
        return Tween<double>(begin: 1.0, end: 0)
            .chain(CurveTween(curve: const Interval(0, 0.4, curve: Curves.ease)))
            .animate(dismissController);
      case FeatureDiscoveryStatus.ripple:
        return const AlwaysStoppedAnimation<double>(1.0);
    }
  }

  Animation<double> rippleOpacity(FeatureDiscoveryStatus status) {
    switch (status) {
      case FeatureDiscoveryStatus.ripple:
        return Tween<double>(begin: rippleMaxOpacity, end: 0)
            .chain(CurveTween(curve: const Interval(0.3, 0.8, curve: Curves.ease)))
            .animate(rippleController);
      case FeatureDiscoveryStatus.closed:
      case FeatureDiscoveryStatus.open:
      case FeatureDiscoveryStatus.tap:
      case FeatureDiscoveryStatus.dismiss:
        return const AlwaysStoppedAnimation<double>(0);
    }
  }

  Animation<double> rippleRadius(FeatureDiscoveryStatus status) {
    switch (status) {
      case FeatureDiscoveryStatus.ripple:
        if (rippleController.value >= 0.3 && rippleController.value <= 0.8) {
          return Tween<double>(begin: tapTargetMaxRadius, end: 79.0)
              .chain(CurveTween(curve: const Interval(0.3, 0.8, curve: Curves.ease)))
              .animate(rippleController);
        }
        return const AlwaysStoppedAnimation<double>(tapTargetMaxRadius);
      case FeatureDiscoveryStatus.closed:
      case FeatureDiscoveryStatus.open:
      case FeatureDiscoveryStatus.tap:
      case FeatureDiscoveryStatus.dismiss:
        return const AlwaysStoppedAnimation<double>(0);
    }
  }

  Animation<double> tapTargetOpacity(FeatureDiscoveryStatus status) {
    switch (status) {
      case FeatureDiscoveryStatus.closed:
        return const AlwaysStoppedAnimation<double>(0);
      case FeatureDiscoveryStatus.open:
        return Tween<double>(begin: 0, end: 1.0)
            .chain(CurveTween(curve: const Interval(0, 0.4, curve: Curves.ease)))
            .animate(openController);
      case FeatureDiscoveryStatus.tap:
        return Tween<double>(begin: 1.0, end: 0)
            .chain(CurveTween(curve: const Interval(0.1, 0.6, curve: Curves.ease)))
            .animate(tapController);
      case FeatureDiscoveryStatus.dismiss:
        return Tween<double>(begin: 1.0, end: 0)
            .chain(CurveTween(curve: const Interval(0.2, 0.8, curve: Curves.ease)))
            .animate(dismissController);
      case FeatureDiscoveryStatus.ripple:
        return const AlwaysStoppedAnimation<double>(1.0);
    }
  }

  Animation<double> tapTargetRadius(FeatureDiscoveryStatus status) {
    switch (status) {
      case FeatureDiscoveryStatus.closed:
        return const AlwaysStoppedAnimation<double>(tapTargetMinRadius);
      case FeatureDiscoveryStatus.open:
        return Tween<double>(begin: tapTargetMinRadius, end: tapTargetMaxRadius)
            .chain(CurveTween(curve: const Interval(0, 0.4, curve: Curves.ease)))
            .animate(openController);
      case FeatureDiscoveryStatus.ripple:
        if (rippleController.value < 0.3) {
          return Tween<double>(begin: tapTargetMaxRadius, end: tapTargetRippleRadius)
              .chain(CurveTween(curve: const Interval(0, 0.3, curve: Curves.ease)))
              .animate(rippleController);
        } else if (rippleController.value < 0.6) {
          return Tween<double>(begin: tapTargetRippleRadius, end: tapTargetMaxRadius)
              .chain(CurveTween(curve: const Interval(0.3, 0.6, curve: Curves.ease)))
              .animate(rippleController);
        }
        return const AlwaysStoppedAnimation<double>(tapTargetMaxRadius);
      case FeatureDiscoveryStatus.tap:
        return Tween<double>(
          begin: tapTargetMaxRadius,
          end: tapTargetMinRadius,
        ).chain(CurveTween(curve: Curves.ease)).animate(tapController);
      case FeatureDiscoveryStatus.dismiss:
        return Tween<double>(
          begin: tapTargetMaxRadius,
          end: tapTargetMinRadius,
        ).chain(CurveTween(curve: Curves.ease)).animate(dismissController);
    }
  }
}

/// Enum to indicate the current status of a [FeatureDiscovery] widget.
enum FeatureDiscoveryStatus {
  closed, // Overlay is closed.
  open, // Overlay is opening.
  ripple, // Overlay is rippling.
  tap, // Overlay is tapped.
  dismiss, // Overlay is being dismissed.
}
