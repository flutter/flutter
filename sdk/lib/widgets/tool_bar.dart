// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/theme.dart';

import '../painting/text_style.dart';
import '../rendering/flex.dart';
import '../theme/shadows.dart';
import '../theme/typography.dart' as typography;
import '../theme/view_configuration.dart';
import 'basic.dart';
import 'default_text_style.dart';
import 'icon.dart';

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
    IconThemeColor iconThemeColor = IconThemeColor.white;
    TextStyle defaultTextStyle = typography.white.title;
    if (toolbarColor == null) {
      ThemeData themeData = Theme.of(this);
      toolbarColor = themeData.primaryColor;
      if (themeData.primaryColorBrightness == ThemeBrightness.light) {
        iconThemeColor = IconThemeColor.black;
        defaultTextStyle = typography.black.title;
      }
    }

    List<Widget> children = new List<Widget>();
    if (left != null)
      children.add(left);

    if (center != null) {
      children.add(
        new Flexible(
          child: new Padding(
            child: new DefaultTextStyle(
              style: defaultTextStyle,
              child: center
            ),
            padding: new EdgeDims.only(left: 24.0)
          )
        )
      );
    }

    if (right != null)
      children.addAll(right);

    return new Container(
      child: new IconTheme(
        data: new IconThemeData(color: iconThemeColor),
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
  }

}
