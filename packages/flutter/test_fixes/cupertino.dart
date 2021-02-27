// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

void main() {
  // Generic reference variables.
  BuildContext context;

  // Change made in https://github.com/flutter/flutter/pull/41859
  const CupertinoTextThemeData themeData = CupertinoTextThemeData(brightness: Brightness.dark);
  themeData.copyWith(brightness: Brightness.light);

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

  // Changes made in https://github.com/flutter/flutter/pull/68736
  MediaQuery.of(context, nullOk: true);
  MediaQuery.of(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/70726
  Navigator.of(context, nullOk: true);
  Navigator.of(context, nullOk: false);

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
  CupertinoDynamicColor.resolve(Color(0), context, nullOk: true);
  CupertinoDynamicColor.resolve(Color(0), context, nullOk: false);
  CupertinoDynamicColor.resolveFrom(context, nullOk: true);
  CupertinoDynamicColor.resolveFrom(context, nullOk: false);
  CupertinoUserInterfaceLevel.of(context, nullOk: true);
  CupertinoUserInterfaceLevel.of(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/68736
  CupertinoTheme.brightnessOf(context, nullOk: true);
  CupertinoTheme.brightnessOf(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/68905
  CupertinoThemeData.resolveFrom(context, nullOk: true);
  CupertinoThemeData.resolveFrom(context, nullOk: false);
  NoDefaultCupertinoThemeData.resolveFrom(context, nullOk: true);
  NoDefaultCupertinoThemeData.resolveFrom(context, nullOk: false);
  CupertinoTextThemeData.resolveFrom(context, nullOk: true);
  CupertinoTextThemeData.resolveFrom(context, nullOk: false);

  // Changes made in https://github.com/flutter/flutter/pull/72043
  CupertinoTextField(maxLengthEnforced: true);
  CupertinoTextField(maxLengthEnforced: false);
  CupertinoTextField.borderless(maxLengthEnforced: true);
  CupertinoTextField.borderless(maxLengthEnforced: false);
  final CupertinoTextField textField;
  textField.maxLengthEnforced;
}
