// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export 'src/navigation_non_web/url_strategy.dart'
    if (dart.library.ui_web) 'src/navigation/url_strategy.dart';
