// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Raw data for the animation demo.

import 'package:flutter/material.dart';

const Color _mariner = const Color(0xFF3B5F8F);
const Color _mediumPurple = const Color(0xFF8266D4);
const Color _tomato = const Color(0xFFF95B57);
const Color _mySin = const Color(0xFFF3A646);
const Color _deepCerise = const Color(0xFFD93F9B);

class SectionDetail {
  const SectionDetail({ this.title, this.subtitle, this.imageAsset });
  final String title;
  final String subtitle;
  final String imageAsset;
}

class Section {
  const Section({ this.title, this.backgroundAsset, this.leftColor, this.rightColor, this.details });
  final String title;
  final String backgroundAsset;
  final Color leftColor;
  final Color rightColor;
  final List<SectionDetail> details;

  @override
  bool operator==(Object other) {
    if (other is! Section)
      return false;
    final Section otherSection = other;
    return title == otherSection.title;
  }

  @override
  int get hashCode => title.hashCode;
}

// TODO(hansmuller): replace the SectionDetail images and text. Get rid of
// the const vars like _eyeglassesDetail and insert a variety of titles and
// image SectionDetails in the allSections list.

const SectionDetail _eyeglassesDetail = const SectionDetail(
  imageAsset: 'packages/flutter_gallery_assets/shrine/products/sunnies.png',
  title: 'Flutter enables interactive animation',
  subtitle: '3K views - 5 days',
);

const SectionDetail _eyeglassesImageDetail = const SectionDetail(
  imageAsset: 'packages/flutter_gallery_assets/shrine/products/sunnies.png',
);

const SectionDetail _seatingDetail = const SectionDetail(
  imageAsset: 'packages/flutter_gallery_assets/shrine/products/lawn_chair.png',
  title: 'Flutter enables interactive animation',
  subtitle: '3K views - 5 days',
);

const SectionDetail _seatingImageDetail = const SectionDetail(
  imageAsset: 'packages/flutter_gallery_assets/shrine/products/lawn_chair.png',
);

const SectionDetail _decorationDetail = const SectionDetail(
  imageAsset: 'packages/flutter_gallery_assets/shrine/products/lipstick.png',
  title: 'Flutter enables interactive animation',
  subtitle: '3K views - 5 days',
);

const SectionDetail _decorationImageDetail = const SectionDetail(
  imageAsset: 'packages/flutter_gallery_assets/shrine/products/lipstick.png',
);

const SectionDetail _protectionDetail = const SectionDetail(
  imageAsset: 'packages/flutter_gallery_assets/shrine/products/helmet.png',
  title: 'Flutter enables interactive animation',
  subtitle: '3K views - 5 days',
);

const SectionDetail _protectionImageDetail = const SectionDetail(
  imageAsset: 'packages/flutter_gallery_assets/shrine/products/helmet.png',
);

final List<Section> allSections = <Section>[
  const Section(
    title: 'EYEGLASSES',
    leftColor: _mediumPurple,
    rightColor: _mariner,
    backgroundAsset: 'packages/flutter_gallery_assets/shrine/products/sunnies.png',
    details: const <SectionDetail>[
      _eyeglassesDetail,
      _eyeglassesImageDetail,
      _eyeglassesDetail,
      _eyeglassesDetail,
      _eyeglassesDetail,
      _eyeglassesDetail,
    ],
  ),
  const Section(
    title: 'SEATING',
    leftColor: _tomato,
    rightColor: _mediumPurple,
    backgroundAsset: 'packages/flutter_gallery_assets/shrine/products/lawn_chair.png',
    details: const <SectionDetail>[
      _seatingDetail,
      _seatingImageDetail,
      _seatingDetail,
      _seatingDetail,
      _seatingDetail,
      _seatingDetail,
    ],
  ),
  const Section(
    title: 'DECORATION',
    leftColor: _mySin,
    rightColor: _tomato,
    backgroundAsset: 'packages/flutter_gallery_assets/shrine/products/lipstick.png',
    details: const <SectionDetail>[
      _decorationDetail,
      _decorationImageDetail,
      _decorationDetail,
      _decorationDetail,
      _decorationDetail,
      _decorationDetail,
    ],
  ),
  const Section(
    title: 'PROTECTION',
    leftColor: Colors.white,
    rightColor: _tomato,
    backgroundAsset: 'packages/flutter_gallery_assets/shrine/products/helmet.png',
    details: const <SectionDetail>[
      _protectionDetail,
      _protectionImageDetail,
      _protectionDetail,
      _protectionDetail,
      _protectionDetail,
      _protectionDetail,
    ],
  ),
];
