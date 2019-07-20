// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


Future<void> obtainKey() async {
  final AssetImage assetImage = AssetImage('packages/shrine_images/10-0.jpg', bundle: rootBundle, package: null);
  return assetImage.obtainKey(ImageConfiguration.empty);
}
