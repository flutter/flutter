// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/shrine/app.dart';
import 'package:flutter_gallery/demo/shrine/model/app_state_model.dart';

class ShrineDemo extends StatelessWidget {
  ShrineDemo({Key key}) : super(key: key) {
    model.loadProducts();
  }

  static const String routeName = '/shrine'; // Used by the Gallery app.

  final AppStateModel model = AppStateModel();

  @override
  Widget build(BuildContext context) => ShrineApp();
}
