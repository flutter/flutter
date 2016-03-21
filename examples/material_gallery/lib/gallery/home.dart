// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'demo.dart';
import 'drawer.dart';
import 'section.dart';

import '../demo/buttons_demo.dart';
import '../demo/cards_demo.dart';
import '../demo/colors_demo.dart';
import '../demo/chip_demo.dart';
import '../demo/date_picker_demo.dart';
import '../demo/dialog_demo.dart';
import '../demo/drop_down_demo.dart';
import '../demo/fitness_demo.dart';
import '../demo/grid_list_demo.dart';
import '../demo/icons_demo.dart';
import '../demo/leave_behind_demo.dart';
import '../demo/list_demo.dart';
import '../demo/modal_bottom_sheet_demo.dart';
import '../demo/menu_demo.dart';
import '../demo/page_selector_demo.dart';
import '../demo/persistent_bottom_sheet_demo.dart';
import '../demo/progress_indicator_demo.dart';
import '../demo/toggle_controls_demo.dart';
import '../demo/scrolling_techniques_demo.dart';
import '../demo/slider_demo.dart';
import '../demo/snack_bar_demo.dart';
import '../demo/scrollable_tabs_demo.dart';
import '../demo/tabs_demo.dart';
import '../demo/tabs_fab_demo.dart';
import '../demo/text_field_demo.dart';
import '../demo/time_picker_demo.dart';
import '../demo/tooltip_demo.dart';
import '../demo/two_level_list_demo.dart';
import '../demo/typography_demo.dart';
import '../demo/weather_demo.dart';

class GalleryHome extends StatefulWidget {
  GalleryHome({ Key key }) : super(key: key);

  @override
  GalleryHomeState createState() => new GalleryHomeState();
}

class GalleryHomeState extends State<GalleryHome> {
  @override
  Widget build(BuildContext context) {
    final double appBarHeight = 128.0;
    return new Scaffold(
      drawer: new GalleryDrawer(),
      appBar: new AppBar(
        expandedHeight: appBarHeight,
        flexibleSpace: (BuildContext context) {
          return new Container(
            padding: const EdgeInsets.only(left: 64.0),
            height: appBarHeight,
            child: new Align(
              alignment: const FractionalOffset(0.0, 1.0),
              child: new Text('Flutter Gallery', style: Typography.white.headline)
            )
          );
        }
      ),
      body: new Block(
        padding: const EdgeInsets.all(4.0),
        children: <Widget>[
          new Row(
            children: <Widget>[
              new GallerySection(
                title: 'Animation',
                image: 'assets/section_animation.png',
                colors: Colors.purple,
                demos: <GalleryDemo>[
                  new GalleryDemo(title: 'Weather', builder: () => new WeatherDemo()),
                  new GalleryDemo(title: 'Fitness', builder: () => new FitnessDemo())
                ]
              ),
              new GallerySection(
                title: 'Style',
                image: 'assets/section_style.png',
                colors: Colors.green,
                demos: <GalleryDemo>[
                  new GalleryDemo(title: 'Colors', builder: () => new ColorsDemo()),
                  new GalleryDemo(title: 'Typography', builder: () => new TypographyDemo())
                ]
              )
            ]
          ),
          new Row(
            children: <Widget>[
              new GallerySection(
                title: 'Layout',
                image: 'assets/section_layout.png',
                colors: Colors.pink
              ),
              new GallerySection(
                title: 'Components',
                image: 'assets/section_components.png',
                colors: Colors.amber,
                demos: <GalleryDemo>[
                  new GalleryDemo(title: 'Buttons', builder: () => new ButtonsDemo()),
                  new GalleryDemo(title: 'Buttons: Floating Action Button', builder: () => new TabsFabDemo()),
                  new GalleryDemo(title: 'Cards', builder: () => new CardsDemo()),
                  new GalleryDemo(title: 'Chips', builder: () => new ChipDemo()),
                  new GalleryDemo(title: 'Date Picker', builder: () => new DatePickerDemo()),
                  new GalleryDemo(title: 'Dialog', builder: () => new DialogDemo()),
                  new GalleryDemo(title: 'Dropdown Button', builder: () => new DropDownDemo()),
                  new GalleryDemo(title: 'Expand/Collapse List Control', builder: () => new TwoLevelListDemo()),
                  new GalleryDemo(title: 'Grid', builder: () => new GridListDemo()),
                  new GalleryDemo(title: 'Icons', builder: () => new IconsDemo()),
                  new GalleryDemo(title: 'Leave-behind List Items', builder: () => new LeaveBehindDemo()),
                  new GalleryDemo(title: 'List', builder: () => new ListDemo()),
                  new GalleryDemo(title: 'Modal Bottom Sheet', builder: () => new ModalBottomSheetDemo()),
                  new GalleryDemo(title: 'Menus', builder: () => new MenuDemo()),
                  new GalleryDemo(title: 'Page Selector', builder: () => new PageSelectorDemo()),
                  new GalleryDemo(title: 'Persistent Bottom Sheet', builder: () => new PersistentBottomSheetDemo()),
                  new GalleryDemo(title: 'Progress Indicators', builder: () => new ProgressIndicatorDemo()),
                  new GalleryDemo(title: 'Scrollable Tabs', builder: () => new ScrollableTabsDemo()),
                  new GalleryDemo(title: 'Selection Controls', builder: () => new ToggleControlsDemo()),
                  new GalleryDemo(title: 'Sliders', builder: () => new SliderDemo()),
                  new GalleryDemo(title: 'SnackBar', builder: () => new SnackBarDemo()),
                  new GalleryDemo(title: 'Tabs', builder: () => new TabsDemo()),
                  new GalleryDemo(title: 'Text Fields', builder: () => new TextFieldDemo()),
                  new GalleryDemo(title: 'Time Picker', builder: () => new TimePickerDemo()),
                  new GalleryDemo(title: 'Tooltips', builder: () => new TooltipDemo())
                ]
              )
            ]
          ),
          new Row(
            children: <Widget>[
              new GallerySection(
                title: 'Patterns',
                image: 'assets/section_patterns.png',
                colors: Colors.cyan,
                demos: <GalleryDemo>[
                  new GalleryDemo(title: 'Scrolling Techniques', builder: () => new ScrollingTechniquesDemo())
                ]
              ),
              new GallerySection(
                title: 'Usability',
                image: 'assets/section_usability.png',
                colors: Colors.lightGreen,
                demos: <GalleryDemo>[
                  new GalleryDemo(title: 'Tooltips', builder: () => new TooltipDemo())
                ]
              )
            ]
          )
        ]
      )
    );
  }
}
