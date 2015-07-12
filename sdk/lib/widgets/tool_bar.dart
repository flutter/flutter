// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/theme.dart';

import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/theme/shadows.dart';
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/theme/view_configuration.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/icon.dart';

class ToolBar extends Component {

  ToolBar({
    String key,
    this.left,
    this.center,
    this.right,
    this.backgroundColor
  }) : super(key: key);

  final Widget left;
  final Widget center;
  final List<Widget> right;
  final Color backgroundColor;

  Widget build() {
    Color toolbarColor = backgroundColor;
    IconThemeData iconThemeData;
    TextStyle defaultTextStyle = typography.white.title;
    if (toolbarColor == null) {
      ThemeData themeData = Theme.of(this);
      toolbarColor = themeData.primaryColor;
      if (themeData.primaryColorBrightness == ThemeBrightness.light) {
        defaultTextStyle = typography.black.title;
        iconThemeData = const IconThemeData(color: IconThemeColor.black);
      } else {
        iconThemeData = const IconThemeData(color: IconThemeColor.white);
      }
    }

    List<Widget> children = new List<Widget>();
    if (left != null)
      children.add(left);

    if (center != null) {
      children.add(
        new Flexible(
          child: new Padding(
            child: center,
            padding: new EdgeDims.only(left: 24.0)
          )
        )
      );
    }

    if (right != null)
      children.addAll(right);

    Widget content = new Container(
      child: new DefaultTextStyle(
        style: defaultTextStyle,
        child: new Flex(
          [new Container(child: new Flex(children), height: kToolBarHeight)],
          alignItems: FlexAlignItems.end
        )
      ),
      padding: new EdgeDims.symmetric(horizontal: 8.0),
      decoration: new BoxDecoration(
        backgroundColor: toolbarColor,
        boxShadow: shadows[2]
      )
    );

    if (iconThemeData != null)
      content = new IconTheme(data: iconThemeData, child: content);
    return content;
  }

}
