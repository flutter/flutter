// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'page.dart';

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
    return Opacity(
        opacity: 0.2,
        child: Opacity(
            opacity: 0.5,
            child: Transform.rotate(
              angle: 0,
              child: ClipPath(
                clipper: PathClipper(),
                child: Transform.translate(
                  offset: Offset(0, 100),
                  child: UiKitView()
                ),
              ),
            )),
      );
  }

 
}



class PathClipper extends CustomClipper<Path> {
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    // TODO: implement shouldReclip
    return true;
  }

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(50, 50);
    path.lineTo(500, 50);
    path.lineTo(500, 500);
    path.quadraticBezierTo(600, 700, 700, 600);
    path.cubicTo(400, 700, 800, 560, 300, 800);
    path.close();

    path.lineTo(100, 800);
    path.lineTo(100, 100);

    // path.quadraticBezierTo(100, 100, 150 , 105);
    // path.conicTo(110, 110, 220, 220, 5);
    // path.cubicTo(250,250 , 260, 260, 280, 280);
    // path.close();
    return path;
  }
}

class RectClipper extends CustomClipper<Rect> {
  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    // TODO: implement shouldReclip
    return true;
  }

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(50, 200, 1000, 1300);
  }
}
