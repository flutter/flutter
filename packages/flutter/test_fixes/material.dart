// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  // Generic reference variables.
  BuildContext context;

  // Changes made in https://github.com/flutter/flutter/pull/26259
  const Scaffold scaffold = Scaffold(resizeToAvoidBottomPadding: true);
  final bool resize = scaffold.resizeToAvoidBottomPadding;

  // Change made in https://github.com/flutter/flutter/pull/15303
  showDialog(child: Text('Fix me.'));

  // Changes made in https://github.com/flutter/flutter/pull/44189
  const Element element = Element(myWidget);
  element.inheritFromElement(ancestor);
  element.inheritFromWidgetOfExactType(targetType);
  element.ancestorInheritedElementForWidgetOfExactType(targetType);
  element.ancestorWidgetOfExactType(targetType);
  element.ancestorStateOfType(TypeMatcher<targetType>());
  element.rootAncestorStateOfType(TypeMatcher<targetType>());
  element.ancestorRenderObjectOfType(TypeMatcher<targetType>());

  // Changes made in https://github.com/flutter/flutter/pull/45941
  final WidgetsBinding binding = WidgetsBinding.instance!;
  binding.deferFirstFrameReport();
  binding.allowFirstFrameReport();

  // Changes made in https://github.com/flutter/flutter/pull/44189
  const StatefulElement statefulElement = StatefulElement(myWidget);
  statefulElement.inheritFromElement(ancestor);

  // Changes made in https://github.com/flutter/flutter/pull/44189
  const BuildContext buildContext = Element(myWidget);
  buildContext.inheritFromElement(ancestor);
  buildContext.inheritFromWidgetOfExactType(targetType);
  buildContext.ancestorInheritedElementForWidgetOfExactType(targetType);
  buildContext.ancestorWidgetOfExactType(targetType);
  buildContext.ancestorStateOfType(TypeMatcher<targetType>());
  buildContext.rootAncestorStateOfType(TypeMatcher<targetType>());
  buildContext.ancestorRenderObjectOfType(TypeMatcher<targetType>());

  // Changes made in https://github.com/flutter/flutter/pull/66305
  const Stack stack = Stack(overflow: Overflow.visible);
  const Stack stack = Stack(overflow: Overflow.clip);
  final behavior = stack.overflow;

  // Changes made in https://github.com/flutter/flutter/pull/61648
  const Form form = Form(autovalidate: true);
  const Form form = Form(autovalidate: false);
  final autoMode = form.autovalidate;

  // Changes made in https://github.com/flutter/flutter/pull/61648
  const FormField formField = FormField(autovalidate: true);
  const FormField formField = FormField(autovalidate: false);
  final autoMode = formField.autovalidate;

  // Changes made in https://github.com/flutter/flutter/pull/61648
  const TextFormField textFormField = TextFormField(autovalidate: true);
  const TextFormField textFormField = TextFormField(autovalidate: false);

  // Changes made in https://github.com/flutter/flutter/pull/61648
  const DropdownButtonFormField dropDownButtonFormField = DropdownButtonFormField(autovalidate: true);
  const DropdownButtonFormField dropdownButtonFormField = DropdownButtonFormField(autovalidate: false);

  // Changes made in https://github.com/flutter/flutter/pull/48547
  var TextTheme textTheme = TextTheme(
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

  // Changes made in https://github.com/flutter/flutter/pull/48547
  var TextTheme copiedTextTheme = TextTheme.copyWith(
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

  // Changes made in https://github.com/flutter/flutter/pull/68736
  MediaQuery.of(context, nullOk: true);
  MediaQuery.of(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/70726
  Navigator.of(context, nullOk: true);
  Navigator.of(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/68908
  ScaffoldMessenger.of(context, nullOk: true);
  ScaffoldMessenger.of(context, nullOk: false);
  Scaffold.of(context, nullOk: true);
  Scaffold.of(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/68910
  Router.of(context, nullOk: true);
  Router.of(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/68911
  Localizations.localeOf(context, nullOk: true);
  Localizations.localeOf(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/68917
  FocusTraversalOrder.of(context, nullOk: true);
  FocusTraversalOrder.of(context, nullOk: false);
  FocusTraversalGroup.of(context, nullOk: true);
  FocusTraversalGroup.of(context, nullOk: false);
  Focus.of(context, nullOk: true);
  Focus.of(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/68921
  Shortcuts.of(context, nullOk: true);
  Shortcuts.of(context, nullOk: false);
  Actions.find(context, nullOk: true);
  Actions.find(context, nullOk: false);
  Actions.handler(context, nullOk: true);
  Actions.handler(context, nullOk: false);
  Actions.invoke(context, nullOk: true);
  Actions.invoke(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/68925
  AnimatedList.of(context, nullOk: true);
  AnimatedList.of(context, nullOk: false);
  SliverAnimatedList.of(context, nullOk: true);
  SliverAnimatedList.of(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/68905
  MaterialBasedCupertinoThemeData.resolveFrom(context, nullOk: true);
  MaterialBasedCupertinoThemeData.resolveFrom(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/72043
  TextField(maxLengthEnforced: true);
  TextField(maxLengthEnforced: false);
  final TextField textField;
  textField.maxLengthEnforced;
  TextFormField(maxLengthEnforced: true);
  TextFormField(maxLengthEnforced: false);
}
