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
      : super('Mutation Composition Tests',
            const ValueKey<String>('MutationPage'));

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
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Column(
            children: <Widget>[
              composition1(platformViewToMutate('0')),
              composition2(platformViewToMutate('1')),
              composition3(platformViewToMutate('2'))
            ],
          ),
          Column(
            children: <Widget>[
              composition1(containerToMutate()),
              composition2(containerToMutate()),
              composition3(containerToMutate())
            ],
          )
        ],
      ),
      padding: const EdgeInsets.all(40),
    );
  }

  Widget composition1(Widget child) {
    return Transform.scale(
      scale: 0.5,
      child: Opacity(
        opacity: 0.2,
        child: Opacity(
            opacity: 0.5,
            child: Transform.rotate(
              angle: 1,
              child: ClipRect(
                clipper: RectClipper(),
                child: Transform.translate(
                  offset: const Offset(0, 30),
                  child: child,
                ),
              ),
            )),
      ),
    );
  }

  Widget composition2(Widget child) {
    return ClipRRect(clipper: RRectClipper(), child: child);
  }

  Widget composition3(Widget child) {
    return ClipPath(clipper: PathClipper(), child: child);
  }

  Widget containerToMutate() {
    return Container(
        width: 150, height: 150, child: Container(color: Color(0xFF0000FF)));
  }

  Widget platformViewToMutate(String id) {
    return Container(
        width: 150,
        height: 150,
        child: SimplePlatformView(key: ValueKey<String>('platform_view+$id')));
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
    path.moveTo(75, 0);
    path.lineTo(0, 100);
    path.quadraticBezierTo(37.5, 150, 75, 100);
    path.lineTo(0, 100);
    path.cubicTo(90, 150, 120, 130, 150, 100);
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
    return const Rect.fromLTRB(10, 10, 100, 100);
  }
}

class RRectClipper extends CustomClipper<RRect> {
  @override
  bool shouldReclip(CustomClipper<RRect> oldClipper) {
    return true;
  }

  @override
  RRect getClip(Size size) {
    return RRect.fromLTRBAndCorners(10, 10, 100, 100,
        topLeft: const Radius.circular(10),
        bottomRight: const Radius.circular(10));
  }
}
