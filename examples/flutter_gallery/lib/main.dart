// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Thanks for checking out Flutter!
// Like what you see? Tweet us @flutterio

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/shrine/model/app_state_model.dart';
import 'package:scoped_model/scoped_model.dart';

import 'gallery/app.dart';

void main() {
  final AppStateModel model = AppStateModel()..loadProducts();

  runApp(ScopedModel<AppStateModel>(
    model: model,
    child: const GalleryApp(),
  ));
  //runApp(const GalleryApp());
}
