// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  // Generic reference variables.
  BuildContext context;
  RenderObjectWidget renderObjectWidget;
  RenderObject renderObject;
  Object object;

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

  // Changes made in https://github.com/flutter/flutter/pull/59127
  const BottomNavigationBarItem bottomNavigationBarItem = BottomNavigationBarItem(title: myTitle);
  bottomNavigationBarItem.title;

  // Changes made in https://github.com/flutter/flutter/pull/65246
  RectangularSliderTrackShape(disabledThumbGapWidth: 2.0);

  // Changes made in https://github.com/flutter/flutter/pull/46115
  const InputDecoration inputDecoration = InputDecoration(hasFloatingPlaceholder: true);
  InputDecoration(hasFloatingPlaceholder: false);
  InputDecoration();
  InputDecoration.collapsed(hasFloatingPlaceholder: true);
  InputDecoration.collapsed(hasFloatingPlaceholder: false);
  InputDecoration.collapsed();
  inputDecoration.hasFloatingPlaceholder;
  const InputDecorationTheme inputDecorationTheme = InputDecorationTheme(hasFloatingPlaceholder: true);
  InputDecorationTheme(hasFloatingPlaceholder: false);
  InputDecorationTheme();
  inputDecorationTheme.hasFloatingPlaceholder;
  inputDecorationTheme.copyWith(hasFloatingPlaceholder: false);
  inputDecorationTheme.copyWith(hasFloatingPlaceholder: true);
  inputDecorationTheme.copyWith();

  // Changes made in https://github.com/flutter/flutter/pull/66482
  ThemeData(textSelectionColor: Colors.red);
  ThemeData(cursorColor: Colors.blue);
  ThemeData(textSelectionHandleColor: Colors.yellow);
  ThemeData(useTextSelectionTheme: false);
  ThemeData(textSelectionColor: Colors.red, useTextSelectionTheme: false);
  ThemeData(cursorColor: Colors.blue, useTextSelectionTheme: false);
  ThemeData(textSelectionHandleColor: Colors.yellow, useTextSelectionTheme: false);
  ThemeData(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
  );
  ThemeData(
    textSelectionHandleColor: Colors.yellow,
    cursorColor: Colors.blue,
  );
  ThemeData(
    textSelectionColor: Colors.red,
    textSelectionHandleColor: Colors.yellow,
  );
  ThemeData(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    useTextSelectionTheme: false,
  );
  ThemeData(
    textSelectionHandleColor: Colors.yellow,
    cursorColor: Colors.blue,
    useTextSelectionTheme: true,
  );
  ThemeData(
    textSelectionColor: Colors.red,
    textSelectionHandleColor: Colors.yellow,
    useTextSelectionTheme: false,
  );
  ThemeData(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    textSelectionHandleColor: Colors.yellow,
  );
  ThemeData(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    textSelectionHandleColor: Colors.yellow,
    useTextSelectionTheme: false,
  );
  ThemeData.raw(textSelectionColor: Colors.red);
  ThemeData.raw(cursorColor: Colors.blue);
  ThemeData.raw(textSelectionHandleColor: Colors.yellow);
  ThemeData.raw(useTextSelectionTheme: false);
  ThemeData.raw(textSelectionColor: Colors.red, useTextSelectionTheme: false);
  ThemeData.raw(cursorColor: Colors.blue, useTextSelectionTheme: false);
  ThemeData.raw(textSelectionHandleColor: Colors.yellow, useTextSelectionTheme: false);
  ThemeData.raw(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
  );
  ThemeData.raw(
    textSelectionHandleColor: Colors.yellow,
    cursorColor: Colors.blue,
  );
  ThemeData.raw(
    textSelectionColor: Colors.red,
    textSelectionHandleColor: Colors.yellow,
  );
  ThemeData.raw(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    useTextSelectionTheme: false,
  );
  ThemeData.raw(
    textSelectionHandleColor: Colors.yellow,
    cursorColor: Colors.blue,
    useTextSelectionTheme: true,
  );
  ThemeData.raw(
    textSelectionColor: Colors.red,
    textSelectionHandleColor: Colors.yellow,
    useTextSelectionTheme: false,
  );
  ThemeData.raw(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    textSelectionHandleColor: Colors.yellow,
  );
  ThemeData.raw(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    textSelectionHandleColor: Colors.yellow,
    useTextSelectionTheme: false,
  );

  // Changes made in https://github.com/flutter/flutter/pull/79160
  Draggable draggable = Draggable();
  draggable = Draggable(dragAnchor: DragAnchor.child);
  draggable = Draggable(dragAnchor: DragAnchor.pointer);
  draggable.dragAnchor;

  // Changes made in https://github.com/flutter/flutter/pull/79160
  LongPressDraggable longPressDraggable = LongPressDraggable();
  longPressDraggable = LongPressDraggable(dragAnchor: DragAnchor.child);
  longPressDraggable = LongPressDraggable(dragAnchor: DragAnchor.pointer);
  longPressDraggable.dragAnchor;

  // Changes made in https://github.com/flutter/flutter/pull/64254
  final LeafRenderObjectElement leafElement = LeafRenderObjectElement();
  leafElement.insertChildRenderObject(renderObject, object);
  leafElement.moveChildRenderObject(renderObject, object);
  leafElement.removeChildRenderObject(renderObject);
  final ListWheelElement listWheelElement = ListWheelElement();
  listWheelElement.insertChildRenderObject(renderObject, object);
  listWheelElement.moveChildRenderObject(renderObject, object);
  listWheelElement.removeChildRenderObject(renderObject);
  final MultiChildRenderObjectElement multiChildRenderObjectElement = MultiChildRenderObjectElement();
  multiChildRenderObjectElement.insertChildRenderObject(renderObject, object);
  multiChildRenderObjectElement.moveChildRenderObject(renderObject, object);
  multiChildRenderObjectElement.removeChildRenderObject(renderObject);
  final SingleChildRenderObjectElement singleChildRenderObjectElement = SingleChildRenderObjectElement();
  singleChildRenderObjectElement.insertChildRenderObject(renderObject, object);
  singleChildRenderObjectElement.moveChildRenderObject(renderObject, object);
  singleChildRenderObjectElement.removeChildRenderObject(renderObject);
  final SliverMultiBoxAdaptorElement sliverMultiBoxAdaptorElement = SliverMultiBoxAdaptorElement();
  sliverMultiBoxAdaptorElement.insertChildRenderObject(renderObject, object);
  sliverMultiBoxAdaptorElement.moveChildRenderObject(renderObject, object);
  sliverMultiBoxAdaptorElement.removeChildRenderObject(renderObject);
  final RenderObjectToWidgetElement renderObjectToWidgetElement = RenderObjectToWidgetElement(widget);
  renderObjectToWidgetElement.insertChildRenderObject(renderObject, object);
  renderObjectToWidgetElement.moveChildRenderObject(renderObject, object);
  renderObjectToWidgetElement.removeChildRenderObject(renderObject);

  // Changes made in https://github.com/flutter/flutter/pull/81336
  ThemeData themeData = ThemeData();
  themeData = ThemeData(accentColor: Colors.red);
  themeData = ThemeData(accentColor: Colors.red, primarySwatch: Colors.blue);
  themeData = ThemeData(accentColor: Colors.red, colorScheme: ColorScheme.light());
  themeData = ThemeData(accentColor: Colors.red, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData = ThemeData.raw(accentColor: Colors.red);
  themeData = ThemeData.raw(accentColor: Colors.red, primarySwatch: Colors.blue);
  themeData = ThemeData.raw(accentColor: Colors.red, colorScheme: ColorScheme.light());
  themeData = ThemeData.raw(accentColor: Colors.red, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData = themeData.copyWith(accentColor: Colors.red);
  themeData = themeData.copyWith(accentColor: Colors.red, primarySwatch: Colors.blue);
  themeData = themeData.copyWith(accentColor: Colors.red, colorScheme: ColorScheme.light());
  themeData = themeData.copyWith(accentColor: Colors.red, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData.accentColor;

  // Changes made in https://github.com/flutter/flutter/pull/81336
  ThemeData themeData = ThemeData();
  themeData = ThemeData(accentColorBrightness: Brightness.dark);
  themeData = ThemeData.raw(accentColorBrightness: Brightness.dark);
  themeData = themeData.copyWith(accentColorBrightness: Brightness.dark);
  themeData.accentColorBrightness; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/81336
  ThemeData themeData = ThemeData();
  themeData = ThemeData(accentTextTheme: TextTheme());
  themeData = ThemeData.raw(accentTextTheme: TextTheme());
  themeData = themeData.copyWith(accentTextTheme: TextTheme());
  themeData.accentTextTheme; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/81336
  ThemeData themeData = ThemeData();
  themeData = ThemeData(accentIconTheme: IconThemeData());
  themeData = ThemeData.raw(accentIconTheme: IconThemeData());
  themeData = themeData.copyWith(accentIconTheme: IconThemeData());
  themeData.accentIconTheme; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/81336
  ThemeData themeData = ThemeData();
  themeData = ThemeData(buttonColor: Colors.red);
  themeData = ThemeData.raw(buttonColor: Colors.red);
  themeData = themeData.copyWith(buttonColor: Colors.red);
  themeData.buttonColor; // Removing field reference not supported.

  // Changes made in https://flutter.dev/docs/release/breaking-changes/clip-behavior
  ListWheelScrollView listWheelScrollView = ListWheelScrollView();
  listWheelScrollView = ListWheelScrollView(clipToSize: true);
  listWheelScrollView = ListWheelScrollView(clipToSize: false);
  listWheelScrollView = ListWheelScrollView.useDelegate();
  listWheelScrollView = ListWheelScrollView.useDelegate(clipToSize: true);
  listWheelScrollView = ListWheelScrollView.useDelegate(clipToSize: false);
  listWheelScrollView.clipToSize;
  ListWheelViewport listWheelViewport = ListWheelViewport();
  listWheelViewport = ListWheelViewport(clipToSize: true);
  listWheelViewport = ListWheelViewport(clipToSize: false);
  listWheelViewport.clipToSize;

  // Changes made in https://github.com/flutter/flutter/pull/87281
  ThemeData themeData = ThemeData();
  themeData = ThemeData(fixTextFieldOutlineLabel: true);
  themeData = ThemeData.raw(fixTextFieldOutlineLabel: true);
  themeData = themeData.copyWith(fixTextFieldOutlineLabel: true);
  themeData.fixTextFieldOutlineLabel; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/87839
  final OverscrollIndicatorNotification notification = OverscrollIndicatorNotification(leading: true);
  notification.disallowGlow();

  // Changes made in https://github.com/flutter/flutter/pull/86198
  AppBar appBar = AppBar();
  appBar = AppBar(brightness: Brightness.light);
  appBar = AppBar(brightness: Brightness.dark);
  appBar.brightness;

  SliverAppBar sliverAppBar = SliverAppBar();
  sliverAppBar = SliverAppBar(brightness: Brightness.light);
  sliverAppBar = SliverAppBar(brightness: Brightness.dark);
  sliverAppBar.brightness;

  AppBarTheme appBarTheme = AppBarTheme();
  appBarTheme = AppBarTheme(brightness: Brightness.light);
  appBarTheme = AppBarTheme(brightness: Brightness.dark);
  appBarTheme = appBarTheme.copyWith(brightness: Brightness.light);
  appBarTheme = appBarTheme.copyWith(brightness: Brightness.dark);
  appBarTheme.brightness;

  TextTheme myTextTheme = TextTheme();
  AppBar appBar = AppBar();
  appBar = AppBar(textTheme: myTextTheme);
  appBar = AppBar(textTheme: myTextTheme);

  SliverAppBar sliverAppBar = SliverAppBar();
  sliverAppBar = SliverAppBar(textTheme: myTextTheme);
  sliverAppBar = SliverAppBar(textTheme: myTextTheme);

  AppBarTheme appBarTheme = AppBarTheme();
  appBarTheme = AppBarTheme(textTheme: myTextTheme);
  appBarTheme = AppBarTheme(textTheme: myTextTheme);
  appBarTheme = appBarTheme.copyWith(textTheme: myTextTheme);
  appBarTheme = appBarTheme.copyWith(textTheme: myTextTheme);

  AppBar appBar = AppBar();
  appBar = AppBar(backwardsCompatibility: true);
  appBar = AppBar(backwardsCompatibility: false));
  appBar.backwardsCompatibility; // Removing field reference not supported.

  SliverAppBar sliverAppBar = SliverAppBar();
  sliverAppBar = SliverAppBar(backwardsCompatibility: true);
  sliverAppBar = SliverAppBar(backwardsCompatibility: false);
  sliverAppBar.backwardsCompatibility; // Removing field reference not supported.

  AppBarTheme appBarTheme = AppBarTheme();
  appBarTheme = AppBarTheme(backwardsCompatibility: true);
  appBarTheme = AppBarTheme(backwardsCompatibility: false);
  appBarTheme = appBarTheme.copyWith(backwardsCompatibility: true);
  appBarTheme = appBarTheme.copyWith(backwardsCompatibility: false);
  appBarTheme.backwardsCompatibility; // Removing field reference not supported.

  AppBarTheme appBarTheme = AppBarTheme();
  appBarTheme.color;
}
