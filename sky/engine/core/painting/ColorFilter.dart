// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// Extends the generated _ColorFilter interface via the PrivateDart attribute.
class ColorFilter extends _ColorFilter {
  // This is the only ColorFilter type we need, but use a named constructor so
  // we can add more in the future.
  ColorFilter.mode(Color color, TransferMode transferMode)
      : super(color, transferMode) {}
}
