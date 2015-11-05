// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

class _Tracing {
  void begin(String name) native "Tracing_begin";
  void end(String name) native "Tracing_end";
}

final _Tracing tracing = new _Tracing();
