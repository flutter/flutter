// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ShrineStyle extends TextStyle {
  const ShrineStyle.roboto(double size, FontWeight weight, Color color)
    : super(inherit: false, color: color, fontSize: size, fontWeight: weight, textBaseline: TextBaseline.alphabetic);

  const ShrineStyle.abrilFatface(double size, FontWeight weight, Color color)
    : super(inherit: false, color: color, fontFamily: 'AbrilFatface', fontSize: size, fontWeight: weight, textBaseline: TextBaseline.alphabetic);
}

TextStyle robotoRegular12(Color color) => ShrineStyle.roboto(12.0, FontWeight.w500, color);
TextStyle robotoLight12(Color color) => ShrineStyle.roboto(12.0, FontWeight.w300, color);
TextStyle robotoRegular14(Color color) => ShrineStyle.roboto(14.0, FontWeight.w500, color);
TextStyle robotoMedium14(Color color) => ShrineStyle.roboto(14.0, FontWeight.w600, color);
TextStyle robotoLight14(Color color) => ShrineStyle.roboto(14.0, FontWeight.w300, color);
TextStyle robotoRegular16(Color color) => ShrineStyle.roboto(16.0, FontWeight.w500, color);
TextStyle robotoRegular20(Color color) => ShrineStyle.roboto(20.0, FontWeight.w500, color);
TextStyle abrilFatfaceRegular24(Color color) => ShrineStyle.abrilFatface(24.0, FontWeight.w500, color);
TextStyle abrilFatfaceRegular34(Color color) => ShrineStyle.abrilFatface(34.0, FontWeight.w500, color);

/// The TextStyles and Colors used for titles, labels, and descriptions. This
/// InheritedWidget is shared by all of the routes and widgets created for
/// the Shrine app.
class ShrineTheme extends InheritedWidget {
  ShrineTheme({ Key key, @required Widget child })
    : assert(child != null),
      super(key: key, child: child);

  final Color cardBackgroundColor = Colors.white;
  final Color appBarBackgroundColor = Colors.white;
  final Color dividerColor = const Color(0xFFD9D9D9);
  final Color priceHighlightColor = const Color(0xFFFFE0E0);

  final TextStyle appBarTitleStyle = robotoRegular20(Colors.black87);
  final TextStyle vendorItemStyle = robotoRegular12(const Color(0xFF81959D));
  final TextStyle priceStyle = robotoRegular14(Colors.black87);
  final TextStyle featureTitleStyle = abrilFatfaceRegular34(const Color(0xFF0A3142));
  final TextStyle featurePriceStyle = robotoRegular16(Colors.black87);
  final TextStyle featureStyle = robotoLight14(Colors.black54);
  final TextStyle orderTitleStyle = abrilFatfaceRegular24(Colors.black87);
  final TextStyle orderStyle = robotoLight14(Colors.black54);
  final TextStyle vendorTitleStyle = robotoMedium14(Colors.black87);
  final TextStyle vendorStyle = robotoLight14(Colors.black54);
  final TextStyle quantityMenuStyle = robotoLight14(Colors.black54);

  static ShrineTheme of(BuildContext context) => context.inheritFromWidgetOfExactType(ShrineTheme);

  @override
  bool updateShouldNotify(ShrineTheme oldWidget) => false;
}
