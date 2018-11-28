// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'choices.dart';
import 'constants.dart';

String codeSnippetForColor(Color color) {
  return kColorChoices.firstWhere((ColorChoice c) => c.color == color).code;
}

String codeSnippetForBorder(String type) {
  return kBorderChoices.firstWhere((BorderChoice b) => b.type == type).code;
}

String codeSnippetForIcon(IconData icon) {
  return kIconChoices.firstWhere((IconChoice b) => b.icon == icon).code;
}

ShapeBorder borderShapeFromString(String type, [bool side = true]) {
  
  BorderSide borderSide = const BorderSide(
    color: Colors.grey,
    width: 2.0,
  );

  borderSide = side ? borderSide : BorderSide.none;

  switch (type) {
    case 'square':
      return RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, side: borderSide);
    case 'rounded':
      return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), side: borderSide);
    case 'beveled':
      return BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: borderSide.copyWith(width: 1.0));
    case 'stadium':
      return StadiumBorder(side: borderSide);
  }
}
