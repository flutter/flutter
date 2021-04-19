// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

Future<void> Function(String, ByteData?, ui.PlatformMessageResponseCallback?)? pluginMessageCallHandler;
