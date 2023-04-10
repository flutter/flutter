// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'dart:typed_data';

import 'package:ui/src/engine.dart';

class SkwasmFontCollection implements FlutterFontCollection {
  @override
  void clear() {
    // TODO(jacksongardner): implement clear
  }

  @override
  FutureOr<void> debugDownloadTestFonts() {
    // TODO(jacksongardner): implement debugDownloadTestFonts
  }

  @override
  Future<void> downloadAssetFonts(AssetManager assetManager) async {
    // TODO(jacksongardner): implement downloadAssetFonts
  }

  @override
  Future<void> loadFontFromList(Uint8List list, {String? fontFamily}) async {
    // TODO(jacksongardner): implement loadFontFromList
  }

  @override
  void registerDownloadedFonts() {
    // TODO(jacksongardner): implement registerDownloadedFonts
  }
}
