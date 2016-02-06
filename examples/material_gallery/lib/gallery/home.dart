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
import '../demo/modal_bottom_sheet_demo.dart';
import '../demo/page_selector_demo.dart';
import '../demo/persistent_bottom_sheet_demo.dart';
import '../demo/progress_indicator_demo.dart';
import '../demo/toggle_controls_demo.dart';
import '../demo/scrolling_techniques_demo.dart';
import '../demo/slider_demo.dart';
import '../demo/snack_bar_demo.dart';
import '../demo/tabs_demo.dart';
import '../demo/tabs_fab_demo.dart';
import '../demo/time_picker_demo.dart';
import '../demo/two_level_list_demo.dart';
import '../demo/typography_demo.dart';
import '../demo/weathers_demo.dart';
import '../demo/fitness_demo.dart';

class GalleryHome extends StatefulComponent {
  GalleryHome({ Key key }) : super(key: key);

  GalleryHomeState createState() => new GalleryHomeState();
}

class GalleryHomeState extends State<GalleryHome> {
  Widget build(BuildContext context) {
    return new Scaffold(
      appBarHeight: 128.0,
      drawer: new GalleryDrawer(),
      toolBar: new ToolBar(
        flexibleSpace: (BuildContext context) {
          return new Container(
            padding: const EdgeDims.only(left: 16.0, bottom: 24.0),
            height: 128.0,
            child: new Align(
              alignment: const FractionalOffset(0.0, 1.0),
              child: new Text('Flutter Gallery', style: Typography.white.headline)
            )
          );
        }
      ),
      body: new Padding(
        padding: const EdgeDims.all(4.0),
        child: new Block(
          children: <Widget>[
            new Row(
              children: <Widget>[
                new GallerySection(
                  title: 'Animation',
                  image: 'assets/section_animation.png',
                  colors: Colors.purple,
                  demos: <GalleryDemo>[
                    new GalleryDemo(title: 'Weathers', builder: () => new WeathersDemo()),
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
                    new GalleryDemo(title: 'Cards', builder: () => new CardsDemo()),
                    new GalleryDemo(title: 'Chips', builder: () => new ChipDemo()),
                    new GalleryDemo(title: 'Date Picker', builder: () => new DatePickerDemo()),
                    new GalleryDemo(title: 'Dialog', builder: () => new DialogDemo()),
                    new GalleryDemo(title: 'Dropdown Button', builder: () => new DropDownDemo()),
                    new GalleryDemo(title: 'Expland/Collapse List Control', builder: () => new TwoLevelListDemo()),
                    new GalleryDemo(title: 'Floating Action Button', builder: () => new TabsFabDemo()),
                    new GalleryDemo(title: 'Modal Bottom Sheet', builder: () => new ModalBottomSheetDemo()),
                    new GalleryDemo(title: 'Page Selector', builder: () => new PageSelectorDemo()),
                    new GalleryDemo(title: 'Persistent Bottom Sheet', builder: () => new PersistentBottomSheetDemo()),
                    new GalleryDemo(title: 'Progress Indicators', builder: () => new ProgressIndicatorDemo()),
                    new GalleryDemo(title: 'Selection Controls', builder: () => new ToggleControlsDemo()),
                    new GalleryDemo(title: 'Sliders', builder: () => new SliderDemo()),
                    new GalleryDemo(title: 'SnackBar', builder: () => new SnackBarDemo()),
                    new GalleryDemo(title: 'Tabs', builder: () => new TabsDemo()),
                    new GalleryDemo(title: 'Time Picker', builder: () => new TimePickerDemo())
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
                  colors: Colors.lightGreen
                )
              ]
            )
          ]
        )
      )
    );
  }
}
