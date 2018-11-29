// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ColorChoice {
  const ColorChoice({@required this.color, @required this.code})
      : assert(color != null),
        assert(code != null);

  final Color color;
  final String code;
}
