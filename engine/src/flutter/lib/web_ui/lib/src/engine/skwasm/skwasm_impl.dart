// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
// The web_sdk/sdk_rewriter.dart uses this directive.
// ignore: unnecessary_library_directive
library skwasm_impl;

import 'dart:ffi';

export 'skwasm_impl/canvas.dart';
export 'skwasm_impl/font_collection.dart';
export 'skwasm_impl/image.dart';
export 'skwasm_impl/layers.dart';
export 'skwasm_impl/paint.dart';
export 'skwasm_impl/paragraph.dart';
export 'skwasm_impl/path.dart';
export 'skwasm_impl/path_metrics.dart';
export 'skwasm_impl/picture.dart';
export 'skwasm_impl/raw/js_functions.dart';
export 'skwasm_impl/raw/raw_canvas.dart';
export 'skwasm_impl/raw/raw_geometry.dart';
export 'skwasm_impl/raw/raw_memory.dart';
export 'skwasm_impl/raw/raw_paint.dart';
export 'skwasm_impl/raw/raw_path.dart';
export 'skwasm_impl/raw/raw_path_metrics.dart';
export 'skwasm_impl/raw/raw_picture.dart';
export 'skwasm_impl/raw/raw_surface.dart';
export 'skwasm_impl/renderer.dart';
export 'skwasm_impl/scene_builder.dart';
export 'skwasm_impl/surface.dart';
export 'skwasm_impl/vertices.dart';
