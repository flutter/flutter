// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const Color _kWelcomeBlue = Color(0xFF0175c2);

abstract class WelcomeStep {
  WelcomeStep({this.tickerProvider});
  final TickerProvider tickerProvider;

  String title();
  String subtitle();

  void animate({bool restart});
  Widget imageWidget();
  Widget contentWidget() {
    return Material(
      color: _kWelcomeBlue,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 240.0,
              child: imageWidget(),
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
}
