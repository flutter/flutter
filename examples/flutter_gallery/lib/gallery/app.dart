// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

import '../demo/all.dart';
import 'home.dart';

final Map<String, WidgetBuilder> kRoutes = <String, WidgetBuilder>{
  ShrineDemo.routeName: (BuildContext context) => new ShrineDemo(),
  Calculator.routeName: (BuildContext context) => new Calculator(),
  ContactsDemo.routeName: (BuildContext context) => new ContactsDemo(),
  TabsFabDemo.routeName: (BuildContext context) => new TabsFabDemo(),
  ButtonsDemo.routeName: (BuildContext context) => new ButtonsDemo(),
  CardsDemo.routeName: (BuildContext context) => new CardsDemo(),
  ChipDemo.routeName: (BuildContext context) => new ChipDemo(),
  DatePickerDemo.routeName: (BuildContext context) => new DatePickerDemo(),
  DataTableDemo.routeName: (BuildContext context) => new DataTableDemo(),
  DialogDemo.routeName: (BuildContext context) => new DialogDemo(),
  DropDownDemo.routeName: (BuildContext context) => new DropDownDemo(),
  TwoLevelListDemo.routeName: (BuildContext context) => new TwoLevelListDemo(),
  GridListDemo.routeName: (BuildContext context) => new GridListDemo(),
  IconsDemo.routeName: (BuildContext context) => new IconsDemo(),
  LeaveBehindDemo.routeName: (BuildContext context) => new LeaveBehindDemo(),
  ListDemo.routeName: (BuildContext context) => new ListDemo(),
  MenuDemo.routeName: (BuildContext context) => new MenuDemo(),
  ModalBottomSheetDemo.routeName: (BuildContext context) => new ModalBottomSheetDemo(),
  OverscrollDemo.routeName: (BuildContext context) => new OverscrollDemo(),
  PageSelectorDemo.routeName: (BuildContext context) => new PageSelectorDemo(),
  PersistentBottomSheetDemo.routeName: (BuildContext context) => new PersistentBottomSheetDemo(),
  ProgressIndicatorDemo.routeName: (BuildContext context) => new ProgressIndicatorDemo(),
  ScrollableTabsDemo.routeName: (BuildContext context) => new ScrollableTabsDemo(),
  SelectionControlsDemo.routeName: (BuildContext context) => new SelectionControlsDemo(),
  SliderDemo.routeName: (BuildContext context) => new SliderDemo(),
  SnackBarDemo.routeName: (BuildContext context) => new SnackBarDemo(),
  TabsDemo.routeName: (BuildContext context) => new TabsDemo(),
  TextFieldDemo.routeName: (BuildContext context) => new TextFieldDemo(),
  TimePickerDemo.routeName: (BuildContext context) => new TimePickerDemo(),
  TooltipDemo.routeName: (BuildContext context) => new TooltipDemo(),
  ColorsDemo.routeName: (BuildContext context) => new ColorsDemo(),
  TypographyDemo.routeName: (BuildContext context) => new TypographyDemo(),
};

final ThemeData _kGalleryLightTheme = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: Colors.purple
);

final ThemeData _kGalleryDarkTheme = new ThemeData(
  brightness: ThemeBrightness.dark,
  primarySwatch: Colors.purple
);

class GalleryApp extends StatefulWidget {
  GalleryApp({ Key key }) : super(key: key);

  @override
  GalleryAppState createState() => new GalleryAppState();
}

class GalleryAppState extends State<GalleryApp> {
  bool _useLightTheme = true;
  bool _showPerformanceOverlay = false;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Gallery',
      theme: _useLightTheme ? _kGalleryLightTheme : _kGalleryDarkTheme,
      showPerformanceOverlay: _showPerformanceOverlay,
      routes: kRoutes,
      home: new GalleryHome(
        useLightTheme: _useLightTheme,
        onThemeChanged: (bool value) { setState(() { _useLightTheme = value; }); },
        showPerformanceOverlay: _showPerformanceOverlay,
        onShowPerformanceOverlayChanged: (bool value) { setState(() { _showPerformanceOverlay = value; }); },
        timeDilation: timeDilation,
        onTimeDilationChanged: (double value) { setState(() { timeDilation = value; }); }
      )
    );
  }
}
