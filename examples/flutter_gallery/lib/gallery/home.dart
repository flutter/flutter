// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../calculator/interface.dart';
import '../demo/all.dart';
import 'drawer.dart';
import 'header.dart';
import 'item.dart';

const double _kFlexibleSpaceMaxHeight = 256.0;

class GalleryHome extends StatefulWidget {
  GalleryHome({
    Key key,
    this.useLightTheme,
    this.onThemeChanged,
    this.timeDilation,
    this.onTimeDilationChanged,
    this.showPerformanceOverlay,
    this.onShowPerformanceOverlayChanged
  }) : super(key: key) {
    assert(onThemeChanged != null);
    assert(onTimeDilationChanged != null);
    assert(onShowPerformanceOverlayChanged != null);
  }

  final bool useLightTheme;
  final ValueChanged<bool> onThemeChanged;

  final double timeDilation;
  final ValueChanged<double> onTimeDilationChanged;

  final bool showPerformanceOverlay;
  final ValueChanged<bool> onShowPerformanceOverlayChanged;

  @override
  GalleryHomeState createState() => new GalleryHomeState();
}

class GalleryHomeState extends State<GalleryHome> {
  final Key _homeKey = new ValueKey<String>("Gallery Home");

  @override
  Widget build(BuildContext context) {
    final double statusBarHight = (MediaQuery.of(context)?.padding ?? EdgeInsets.zero).top;

    return new Scaffold(
      key: _homeKey,
      drawer: new GalleryDrawer(
        useLightTheme: config.useLightTheme,
        onThemeChanged: config.onThemeChanged,
        timeDilation: config.timeDilation,
        onTimeDilationChanged: config.onTimeDilationChanged,
        showPerformanceOverlay: config.showPerformanceOverlay,
        onShowPerformanceOverlayChanged: config.onShowPerformanceOverlayChanged
      ),
      appBar: new AppBar(
        expandedHeight: _kFlexibleSpaceMaxHeight,
        flexibleSpace: new FlexibleSpaceBar(
          title: new Text('Flutter gallery'),
          background: new GalleryHeader()
        )
      ),
      appBarBehavior: AppBarBehavior.under,
      body: new TwoLevelList(
        padding: new EdgeInsets.only(top: _kFlexibleSpaceMaxHeight + statusBarHight),
        type: MaterialListType.oneLine,
        children: <Widget>[
          new TwoLevelSublist(
            leading: new Icon(icon: Icons.star),
            title: new Text('Demos'),
            children: <Widget>[
              new GalleryItem(title: 'Weather', routeName: WeatherDemo.routeName),
              new GalleryItem(title: 'Fitness', routeName: FitnessDemo.routeName),
              new GalleryItem(title: 'Fancy lines', routeName: DrawingDemo.routeName),
              new GalleryItem(title: 'Calculator', routeName: Calculator.routeName),
              new GalleryItem(title: 'Flexible space toolbar', routeName: FlexibleSpaceDemo.routeName),
              new GalleryItem(title: 'Floating action button', routeName: TabsFabDemo.routeName),
            ]
          ),
          new TwoLevelSublist(
            leading: new Icon(icon: Icons.extension),
            title: new Text('Components'),
            children: <Widget>[
              new GalleryItem(title: 'Buttons', routeName: ButtonsDemo.routeName),
              new GalleryItem(title: 'Cards', routeName: CardsDemo.routeName),
              new GalleryItem(title: 'Chips', routeName: ChipDemo.routeName),
              new GalleryItem(title: 'Date picker', routeName: DatePickerDemo.routeName),
              new GalleryItem(title: 'Data tables', routeName: DataTableDemo.routeName),
              new GalleryItem(title: 'Dialog', routeName: DialogDemo.routeName),
              new GalleryItem(title: 'Drop-down button', routeName: DropDownDemo.routeName),
              new GalleryItem(title: 'Expand/collapse list control', routeName: TwoLevelListDemo.routeName),
              new GalleryItem(title: 'Grid', routeName: GridListDemo.routeName),
              new GalleryItem(title: 'Icons', routeName: IconsDemo.routeName),
              new GalleryItem(title: 'Leave-behind list items', routeName: LeaveBehindDemo.routeName),
              new GalleryItem(title: 'List', routeName: ListDemo.routeName),
              new GalleryItem(title: 'Menus', routeName: MenuDemo.routeName),
              new GalleryItem(title: 'Modal bottom sheet', routeName: ModalBottomSheetDemo.routeName),
              new GalleryItem(title: 'Over-scroll', routeName: OverscrollDemo.routeName),
              new GalleryItem(title: 'Page selector', routeName: PageSelectorDemo.routeName),
              new GalleryItem(title: 'Persistent bottom sheet', routeName: PersistentBottomSheetDemo.routeName),
              new GalleryItem(title: 'Progress indicators', routeName: ProgressIndicatorDemo.routeName),
              new GalleryItem(title: 'Scrollable tabs', routeName: ScrollableTabsDemo.routeName),
              new GalleryItem(title: 'Selection controls', routeName: SelectionControlsDemo.routeName),
              new GalleryItem(title: 'Sliders', routeName: SliderDemo.routeName),
              new GalleryItem(title: 'Snackbar', routeName: SnackBarDemo.routeName),
              new GalleryItem(title: 'Tabs', routeName: TabsDemo.routeName),
              new GalleryItem(title: 'Text fields', routeName: TextFieldDemo.routeName),
              new GalleryItem(title: 'Time picker', routeName: TimePickerDemo.routeName),
              new GalleryItem(title: 'Tooltips', routeName: TooltipDemo.routeName),
            ]
          ),
          new TwoLevelSublist(
            leading: new Icon(icon: Icons.color_lens),
            title: new Text('Style'),
            children: <Widget>[
              new GalleryItem(title: 'Colors', routeName: ColorsDemo.routeName),
              new GalleryItem(title: 'Typography', routeName: TypographyDemo.routeName),
            ]
          )
        ]
      )
    );
  }
}
