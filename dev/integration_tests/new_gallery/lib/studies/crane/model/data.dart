// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../../../gallery_localizations.dart';
import 'destination.dart';

List<FlyDestination> getFlyDestinations(BuildContext context) {
  final GalleryLocalizations localizations = GalleryLocalizations.of(context)!;
  return <FlyDestination>[
    FlyDestination(
      id: 0,
      destination: localizations.craneFly0,
      stops: 1,
      duration: const Duration(hours: 6, minutes: 15),
      assetSemanticLabel: localizations.craneFly0SemanticLabel,
    ),
    FlyDestination(
      id: 1,
      destination: localizations.craneFly1,
      stops: 0,
      duration: const Duration(hours: 13, minutes: 30),
      assetSemanticLabel: localizations.craneFly1SemanticLabel,
      imageAspectRatio: 400 / 410,
    ),
    FlyDestination(
      id: 2,
      destination: localizations.craneFly2,
      stops: 0,
      duration: const Duration(hours: 5, minutes: 16),
      assetSemanticLabel: localizations.craneFly2SemanticLabel,
      imageAspectRatio: 400 / 394,
    ),
    FlyDestination(
      id: 3,
      destination: localizations.craneFly3,
      stops: 2,
      duration: const Duration(hours: 19, minutes: 40),
      assetSemanticLabel: localizations.craneFly3SemanticLabel,
      imageAspectRatio: 400 / 377,
    ),
    FlyDestination(
      id: 4,
      destination: localizations.craneFly4,
      stops: 0,
      duration: const Duration(hours: 8, minutes: 24),
      assetSemanticLabel: localizations.craneFly4SemanticLabel,
      imageAspectRatio: 400 / 308,
    ),
    FlyDestination(
      id: 5,
      destination: localizations.craneFly5,
      stops: 1,
      duration: const Duration(hours: 14, minutes: 12),
      assetSemanticLabel: localizations.craneFly5SemanticLabel,
      imageAspectRatio: 400 / 418,
    ),
    FlyDestination(
      id: 6,
      destination: localizations.craneFly6,
      stops: 0,
      duration: const Duration(hours: 5, minutes: 24),
      assetSemanticLabel: localizations.craneFly6SemanticLabel,
      imageAspectRatio: 400 / 345,
    ),
    FlyDestination(
      id: 7,
      destination: localizations.craneFly7,
      stops: 1,
      duration: const Duration(hours: 5, minutes: 43),
      assetSemanticLabel: localizations.craneFly7SemanticLabel,
      imageAspectRatio: 400 / 408,
    ),
    FlyDestination(
      id: 8,
      destination: localizations.craneFly8,
      stops: 0,
      duration: const Duration(hours: 8, minutes: 25),
      assetSemanticLabel: localizations.craneFly8SemanticLabel,
      imageAspectRatio: 400 / 399,
    ),
    FlyDestination(
      id: 9,
      destination: localizations.craneFly9,
      stops: 1,
      duration: const Duration(hours: 15, minutes: 52),
      assetSemanticLabel: localizations.craneFly9SemanticLabel,
      imageAspectRatio: 400 / 379,
    ),
    FlyDestination(
      id: 10,
      destination: localizations.craneFly10,
      stops: 0,
      duration: const Duration(hours: 5, minutes: 57),
      assetSemanticLabel: localizations.craneFly10SemanticLabel,
      imageAspectRatio: 400 / 307,
    ),
    FlyDestination(
      id: 11,
      destination: localizations.craneFly11,
      stops: 1,
      duration: const Duration(hours: 13, minutes: 24),
      assetSemanticLabel: localizations.craneFly11SemanticLabel,
      imageAspectRatio: 400 / 369,
    ),
    FlyDestination(
      id: 12,
      destination: localizations.craneFly12,
      stops: 2,
      duration: const Duration(hours: 10, minutes: 20),
      assetSemanticLabel: localizations.craneFly12SemanticLabel,
      imageAspectRatio: 400 / 394,
    ),
    FlyDestination(
      id: 13,
      destination: localizations.craneFly13,
      stops: 0,
      duration: const Duration(hours: 7, minutes: 15),
      assetSemanticLabel: localizations.craneFly13SemanticLabel,
      imageAspectRatio: 400 / 433,
    ),
  ];
}

List<SleepDestination> getSleepDestinations(BuildContext context) {
  final GalleryLocalizations localizations = GalleryLocalizations.of(context)!;
  return <SleepDestination>[
    SleepDestination(
      id: 0,
      destination: localizations.craneSleep0,
      total: 2241,
      assetSemanticLabel: localizations.craneSleep0SemanticLabel,
      imageAspectRatio: 400 / 308,
    ),
    SleepDestination(
      id: 1,
      destination: localizations.craneSleep1,
      total: 876,
      assetSemanticLabel: localizations.craneSleep1SemanticLabel,
    ),
    SleepDestination(
      id: 2,
      destination: localizations.craneSleep2,
      total: 1286,
      assetSemanticLabel: localizations.craneSleep2SemanticLabel,
      imageAspectRatio: 400 / 377,
    ),
    SleepDestination(
      id: 3,
      destination: localizations.craneSleep3,
      total: 496,
      assetSemanticLabel: localizations.craneSleep3SemanticLabel,
      imageAspectRatio: 400 / 379,
    ),
    SleepDestination(
      id: 4,
      destination: localizations.craneSleep4,
      total: 390,
      assetSemanticLabel: localizations.craneSleep4SemanticLabel,
      imageAspectRatio: 400 / 418,
    ),
    SleepDestination(
      id: 5,
      destination: localizations.craneSleep5,
      total: 876,
      assetSemanticLabel: localizations.craneSleep5SemanticLabel,
      imageAspectRatio: 400 / 410,
    ),
    SleepDestination(
      id: 6,
      destination: localizations.craneSleep6,
      total: 989,
      assetSemanticLabel: localizations.craneSleep6SemanticLabel,
      imageAspectRatio: 400 / 394,
    ),
    SleepDestination(
      id: 7,
      destination: localizations.craneSleep7,
      total: 306,
      assetSemanticLabel: localizations.craneSleep7SemanticLabel,
      imageAspectRatio: 400 / 266,
    ),
    SleepDestination(
      id: 8,
      destination: localizations.craneSleep8,
      total: 385,
      assetSemanticLabel: localizations.craneSleep8SemanticLabel,
      imageAspectRatio: 400 / 376,
    ),
    SleepDestination(
      id: 9,
      destination: localizations.craneSleep9,
      total: 989,
      assetSemanticLabel: localizations.craneSleep9SemanticLabel,
      imageAspectRatio: 400 / 369,
    ),
    SleepDestination(
      id: 10,
      destination: localizations.craneSleep10,
      total: 1380,
      assetSemanticLabel: localizations.craneSleep10SemanticLabel,
      imageAspectRatio: 400 / 307,
    ),
    SleepDestination(
      id: 11,
      destination: localizations.craneSleep11,
      total: 1109,
      assetSemanticLabel: localizations.craneSleep11SemanticLabel,
      imageAspectRatio: 400 / 456,
    ),
  ];
}

List<EatDestination> getEatDestinations(BuildContext context) {
  final GalleryLocalizations localizations = GalleryLocalizations.of(context)!;
  return <EatDestination>[
    EatDestination(
      id: 0,
      destination: localizations.craneEat0,
      total: 354,
      assetSemanticLabel: localizations.craneEat0SemanticLabel,
      imageAspectRatio: 400 / 444,
    ),
    EatDestination(
      id: 1,
      destination: localizations.craneEat1,
      total: 623,
      assetSemanticLabel: localizations.craneEat1SemanticLabel,
      imageAspectRatio: 400 / 340,
    ),
    EatDestination(
      id: 2,
      destination: localizations.craneEat2,
      total: 124,
      assetSemanticLabel: localizations.craneEat2SemanticLabel,
      imageAspectRatio: 400 / 406,
    ),
    EatDestination(
      id: 3,
      destination: localizations.craneEat3,
      total: 495,
      assetSemanticLabel: localizations.craneEat3SemanticLabel,
      imageAspectRatio: 400 / 323,
    ),
    EatDestination(
      id: 4,
      destination: localizations.craneEat4,
      total: 683,
      assetSemanticLabel: localizations.craneEat4SemanticLabel,
      imageAspectRatio: 400 / 404,
    ),
    EatDestination(
      id: 5,
      destination: localizations.craneEat5,
      total: 786,
      assetSemanticLabel: localizations.craneEat5SemanticLabel,
      imageAspectRatio: 400 / 407,
    ),
    EatDestination(
      id: 6,
      destination: localizations.craneEat6,
      total: 323,
      assetSemanticLabel: localizations.craneEat6SemanticLabel,
      imageAspectRatio: 400 / 431,
    ),
    EatDestination(
      id: 7,
      destination: localizations.craneEat7,
      total: 285,
      assetSemanticLabel: localizations.craneEat7SemanticLabel,
      imageAspectRatio: 400 / 422,
    ),
    EatDestination(
      id: 8,
      destination: localizations.craneEat8,
      total: 323,
      assetSemanticLabel: localizations.craneEat8SemanticLabel,
      imageAspectRatio: 400 / 300,
    ),
    EatDestination(
      id: 9,
      destination: localizations.craneEat9,
      total: 1406,
      assetSemanticLabel: localizations.craneEat9SemanticLabel,
      imageAspectRatio: 400 / 451,
    ),
    EatDestination(
      id: 10,
      destination: localizations.craneEat10,
      total: 849,
      assetSemanticLabel: localizations.craneEat10SemanticLabel,
      imageAspectRatio: 400 / 266,
    ),
  ];
}
