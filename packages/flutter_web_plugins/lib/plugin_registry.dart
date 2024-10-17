// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export 'src/non_web/plugin_registry.dart'
    if (dart.library.ui_web) 'src/plugin_registry.dart';
