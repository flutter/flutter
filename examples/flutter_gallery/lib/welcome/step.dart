// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

abstract class WelcomeStep {
  String title();
  String subtitle();
  List<String> imageUris();

  double _startPixels = 0.0;

  AnimationController _inAnimationController;
  AnimationController _outAnimationController;

  AnimationController get inAnimation => _inAnimationController;
  AnimationController get outAnimation => _outAnimationController;

  Widget imageWidget();
  Widget contentWidget() => Material(
        color: Colors.blue, // const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 240.0,
                child: Image.asset(imageUris().first),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: Text(
                  title(),
                  style: const TextStyle(
                    fontFamily: 'GoogleSans',
                    fontSize: 24.0,
                    color: Colors.white,
                    height: 0.8,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  subtitle(),
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
