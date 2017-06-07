// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'sections.dart';

const double kSectionIndicatorWidth = 32.0;

// The card for a single section. Displays the section's gradient and background image.
class SectionCard extends StatelessWidget {
  SectionCard({ Key key, @required this.section })
    : assert(section != null),
      super(key: key);

  final Section section;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.only(bottom: 1.0),
      child: new DecoratedBox(
        decoration: new BoxDecoration(
          borderRadius: new BorderRadius.circular(4.0),
          gradient: new LinearGradient(
            begin: FractionalOffset.topLeft,
            end: FractionalOffset.topRight,
            colors: <Color>[
              section.leftColor,
              section.rightColor,
            ],
          ),
        ),
        child: new Image.asset(
          section.backgroundAsset,
          color: const Color.fromRGBO(255, 255, 255, 0.075),
          colorBlendMode: BlendMode.modulate,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// The title is rendered with two overlapping text widgets that are vertically
// offset a little. It's supposed to look sort-of 3D.
class SectionTitle extends StatelessWidget {
  static const TextStyle sectionTitleStyle = const TextStyle(
    fontFamily: 'Raleway',
    inherit: false,
    fontSize: 24.0,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    textBaseline: TextBaseline.alphabetic,
  );

  static final TextStyle sectionTitleShadowStyle = sectionTitleStyle.copyWith(
    color: const Color(0x19000000),
  );

  SectionTitle({
    Key key,
    @required this.section,
    @required this.scale,
    @required this.opacity,
  }) : assert(section != null),
       assert(scale != null),
       assert(opacity != null && opacity >= 0.0 && opacity <= 1.0),
       super(key: key);

  final Section section;
  final double scale;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return new IgnorePointer(
      child: new Opacity(
        opacity: opacity,
        child: new Transform(
          transform: new Matrix4.identity()..scale(scale),
          alignment: FractionalOffset.center,
          child: new Stack(
            children: <Widget>[
              new Positioned(
                top: 4.0,
                child: new Text(section.title, style: sectionTitleShadowStyle),
              ),
              new Text(section.title, style: sectionTitleStyle),
            ],
          ),
        ),
      ),
    );
  }
}

// Small horizontal bar that indicates the selected section.
class SectionIndicator extends StatelessWidget {
  const SectionIndicator({ Key key, this.opacity: 1.0 }) : super(key: key);

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return new IgnorePointer(
      child: new Container(
        width: kSectionIndicatorWidth,
        height: 3.0,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

// Display a single SectionDetail.
class SectionDetailView extends StatelessWidget {
  SectionDetailView({ Key key, @required this.detail })
    : assert(detail != null && detail.imageAsset != null),
      assert((detail.imageAsset ?? detail.title) != null),
      super(key: key);

  final SectionDetail detail;

  @override
  Widget build(BuildContext context) {
    final Widget image = new DecoratedBox(
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.circular(6.0),
        image: new DecorationImage(
          image: new AssetImage(detail.imageAsset),
          fit: BoxFit.cover,
          alignment: FractionalOffset.center,
        ),
      ),
    );

    Widget item;
    if (detail.title == null && detail.subtitle == null) {
      item = new Container(
        height: 240.0,
        padding: const EdgeInsets.all(16.0),
        child: image,
      );
    } else {
      item = new ListTile(
        title: new Text(detail.title),
        subtitle: new Text(detail.subtitle),
        leading: new SizedBox(width: 32.0, height: 32.0, child: image),
      );
    }

    return new DecoratedBox(
      decoration: new BoxDecoration(color: Colors.grey.shade200),
      child: item,
    );
  }
}
