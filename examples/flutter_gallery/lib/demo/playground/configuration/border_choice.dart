// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class BorderChoice {
  const BorderChoice({
    @required this.type, 
    @required this.code
  }) : assert(type != null), assert(code != null);

  final String type;
  final String code;
}