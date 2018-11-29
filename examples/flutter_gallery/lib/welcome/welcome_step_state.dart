// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

abstract class WelcomeStepState<T extends StatefulWidget> extends State<T> {
  /// Animates the welcome step content. It's possible that this method is
  /// implemented and does nothing. It depends on the implementation
  /// within the step widget.
  void animate({bool restart = false});
}