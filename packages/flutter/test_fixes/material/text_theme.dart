// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  // Changes made in https://github.com/flutter/flutter/pull/48547
  var textTheme = TextTheme(
    display4: displayStyle4,
    display3: displayStyle3,
    display2: displayStyle2,
    display1: displayStyle1,
    headline: headlineStyle,
    title: titleStyle,
    subhead: subheadStyle,
    body2: body2Style,
    body1: body1Style,
    caption: captionStyle,
    button: buttonStyle,
    subtitle: subtitleStyle,
    overline: overlineStyle,
  );
  var errorTextTheme = TextTheme(error: '');

  // Changes made in https://github.com/flutter/flutter/pull/48547
  var copiedTextTheme = TextTheme.copyWith(
    display4: displayStyle4,
    display3: displayStyle3,
    display2: displayStyle2,
    display1: displayStyle1,
    headline: headlineStyle,
    title: titleStyle,
    subhead: subheadStyle,
    body2: body2Style,
    body1: body1Style,
    caption: captionStyle,
    button: buttonStyle,
    subtitle: subtitleStyle,
    overline: overlineStyle,
  );
  var errorCopiedTextTheme = TextTheme.copyWith(error: '');

  // Changes made in https://github.com/flutter/flutter/pull/48547
  var style;
  style = textTheme.display4;
  style = textTheme.display3;
  style = textTheme.display2;
  style = textTheme.display1;
  style = textTheme.headline;
  style = textTheme.title;
  style = textTheme.subhead;
  style = textTheme.body2;
  style = textTheme.body1;
  style = textTheme.caption;
  style = textTheme.button;
  style = textTheme.subtitle;
  style = textTheme.overline;

  // Changes made in https://github.com/flutter/flutter/pull/109817
  var anotherTextTheme = TextTheme(
    headline1: headline1Style,
    headline2: headline2Style,
    headline3: headline3Style,
    headline4: headline4Style,
    headline5: headline5Style,
    headline6: headline6Style,
    subtitle1: subtitle1Style,
    subtitle2: subtitle2Style,
    bodyText1: bodyText1Style,
    bodyText2: bodyText2Style,
    caption: captionStyle,
    button: buttonStyle,
    overline: overlineStyle,
  );
  var anotherErrorTextTheme = TextTheme(error: '');

  // Changes made in https://github.com/flutter/flutter/pull/109817
  var anotherCopiedTextTheme = TextTheme.copyWith(
    headline1: headline1Style,
    headline2: headline2Style,
    headline3: headline3Style,
    headline4: headline4Style,
    headline5: headline5Style,
    headline6: headline6Style,
    subtitle1: subtitle1Style,
    subtitle2: subtitle2Style,
    bodyText1: bodyText1Style,
    bodyText2: bodyText2Style,
    caption: captionStyle,
    button: buttonStyle,
    overline: overlineStyle,
  );
  var anotherErrorCopiedTextTheme = TextTheme.copyWith(error: '');

  // Changes made in https://github.com/flutter/flutter/pull/109817
  var style;
  style = textTheme.headline1;
  style = textTheme.headline2;
  style = textTheme.headline3;
  style = textTheme.headline4;
  style = textTheme.headline5;
  style = textTheme.headline6;
  style = textTheme.subtitle1;
  style = textTheme.subtitle2;
  style = textTheme.bodyText1;
  style = textTheme.bodyText2;
  style = textTheme.caption;
  style = textTheme.button;
  style = textTheme.overline;
}
