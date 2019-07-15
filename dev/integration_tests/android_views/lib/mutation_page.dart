// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'page.dart';
import 'simple_platform_view.dart';

MethodChannel channel = const MethodChannel('android_views_integration');

class MutationCompositionPage extends Page {
  const MutationCompositionPage()
      : super('Mutation composition', const ValueKey<String>('MutationPage'));

  @override
  Widget build(BuildContext context) {
    return MutationCompositionBody();
  }
}

class MutationCompositionBody extends StatefulWidget {
  @override
  State createState() => MutationCompositionBodyState();
}

class MutationCompositionBodyState extends State<MutationCompositionBody> {
  static const int kEventsBufferSize = 1000;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      clipper: RRectClipper(),
      child: ClipRect(
        clipper: RectClipper(),
        child: Transform.scale(
          scale: 0.5,
          child: Opacity(
            opacity: 0.2,
            child: Opacity(
                opacity: 0.5,
                child: Transform.rotate(
                  angle: 2.3,
                  child: ClipPath(
                    clipper: PathClipper(),
                    child: Transform.translate(
                      offset: const Offset(0, 30),
                      child: const SimplePlatformView(
                          key: ValueKey<String>('platform_view')),
                    ),
                  ),
                )),
          ),
        ),
      ),
    );
  }
}

class PathClipper extends CustomClipper<Path> {
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }

  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(20, 20);
    path.lineTo(20, 50);
    path.lineTo(40, 50);
    path.quadraticBezierTo(50, 50, 60, 40);
    path.cubicTo(60, 40, 70, 40, 60, 30);
    path.close();
    return path;
  }
}

class RectClipper extends CustomClipper<Rect> {
  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }

  @override
  Rect getClip(Size size) {
    return const Rect.fromLTRB(100, 20, 200, 200);
  }
}

class RRectClipper extends CustomClipper<RRect> {
  @override
  bool shouldReclip(CustomClipper<RRect> oldClipper) {
    return true;
  }

  @override
  RRect getClip(Size size) {
    return RRect.fromLTRBAndCorners(20, 100, 80, 200,
        topLeft: const Radius.circular(10),
        bottomRight: const Radius.circular(10));
  }
}
