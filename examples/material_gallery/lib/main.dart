// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'demo/chip_demo.dart';
import 'demo/date_picker_demo.dart';
import 'demo/drop_down_demo.dart';
import 'demo/modal_bottom_sheet_demo.dart';
import 'demo/page_selector_demo.dart';
import 'demo/persistent_bottom_sheet_demo.dart';
import 'demo/progress_indicator_demo.dart';
import 'demo/toggle_controls_demo.dart';
import 'demo/scrolling_techniques_demo.dart';
import 'demo/slider_demo.dart';
import 'demo/tabs_demo.dart';
import 'demo/tabs_fab_demo.dart';
import 'demo/time_picker_demo.dart';
import 'demo/two_level_list_demo.dart';
import 'demo/weathers_demo.dart';

typedef Widget GalleryDemoBuilder();

class GalleryDemo {
  GalleryDemo({ this.title, this.builder });

  final String title;
  final GalleryDemoBuilder builder;
}

class GallerySection extends StatelessComponent {
  GallerySection({ this.title, this.image, this.colors, this.demos });

  final String title;
  final String image;
  final Map<int, Color> colors;
  final List<GalleryDemo> demos;

  void showDemo(GalleryDemo demo, BuildContext context, ThemeData theme) {
    Navigator.push(context, new MaterialPageRoute(
      builder: (BuildContext context) {
        Widget child = (demo.builder == null) ? null : demo.builder();
        return new Theme(data: theme, child: child);
      }
    ));
  }

  void showDemos(BuildContext context) {
    final theme = new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: colors
    );
    final appBarHeight = 200.0;
    final scrollableKey = new ValueKey<String>(title); // assume section titles differ
    Navigator.push(context, new MaterialPageRoute(
      builder: (BuildContext context) {
        return new Theme(
          data: theme,
          child: new Scaffold(
            appBarHeight: appBarHeight,
            appBarBehavior: AppBarBehavior.scroll,
            scrollableKey: scrollableKey,
            toolBar: new ToolBar(
              flexibleSpace: (BuildContext context) => new FlexibleSpaceBar(title: new Text(title))
            ),
            body: new Material(
              child: new MaterialList(
                scrollableKey: scrollableKey,
                scrollablePadding: new EdgeDims.only(top: appBarHeight),
                type: MaterialListType.oneLine,
                children: (demos ?? <GalleryDemo>[]).map((GalleryDemo demo) {
                  return new ListItem(
                    center: new Text(demo.title, style: theme.text.subhead),
                    onTap: () { showDemo(demo, context, theme); }
                  );
                })
              )
            )
          )
        );
      }
    ));
  }

  Widget build (BuildContext context) {
    final theme = new ThemeData(
      brightness: ThemeBrightness.dark,
      primarySwatch: colors
    );
    return new Theme(
      data: theme,
      child: new Flexible(
        child: new GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () { showDemos(context); },
          child: new Container(
            height: 256.0,
            margin: const EdgeDims.all(4.0),
            decoration: new BoxDecoration(backgroundColor: theme.primaryColor),
            child: new Column(
              children: <Widget>[
                new Flexible(
                  child: new Padding(
                    padding: const EdgeDims.symmetric(horizontal: 12.0),
                    child: new AssetImage(
                      name: image,
                      alignment: const FractionalOffset(0.5, 0.5),
                      fit: ImageFit.contain
                    )
                  )
                ),
                new Padding(
                  padding: const EdgeDims.all(16.0),
                  child: new Align(
                    alignment: const FractionalOffset(0.0, 1.0),
                    child: new Text(title, style: theme.text.title)
                  )
                )
              ]
            )
          )
        )
      )
    );
  }
}

class GalleryHome extends StatelessComponent {

  Widget build(BuildContext context) {
    return new Scaffold(
      appBarHeight: 128.0,
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
                    new GalleryDemo(title: 'Weathers', builder: () => new WeathersDemo())
                  ]
                ),
                new GallerySection(
                  title: 'Style',
                  image: 'assets/section_style.png',
                  colors: Colors.green
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
                    new GalleryDemo(title: 'Modal Bottom Sheet', builder: () => new ModalBottomSheetDemo()),
                    new GalleryDemo(title: 'Persistent Bottom Sheet', builder: () => new PersistentBottomSheetDemo()),
                    new GalleryDemo(title: 'Chips', builder: () => new ChipDemo()),
                    new GalleryDemo(title: 'Progress Indicators', builder: () => new ProgressIndicatorDemo()),
                    new GalleryDemo(title: 'Sliders', builder: () => new SliderDemo()),
                    new GalleryDemo(title: 'Selection Controls', builder: () => new ToggleControlsDemo()),
                    new GalleryDemo(title: 'Dropdown Button', builder: () => new DropDownDemo()),
                    new GalleryDemo(title: 'Tabs', builder: () => new TabsDemo()),
                    new GalleryDemo(title: 'Expland/Collapse List Control', builder: () => new TwoLevelListDemo()),
                    new GalleryDemo(title: 'Page Selector', builder: () => new PageSelectorDemo()),
                    new GalleryDemo(title: 'Date Picker', builder: () => new DatePickerDemo()),
                    new GalleryDemo(title: 'Time Picker', builder: () => new TimePickerDemo()),
                    new GalleryDemo(title: 'Floation Action Button', builder: () => new TabsFabDemo())
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

void main() {
  runApp(new MaterialApp(
    title: 'Material Gallery',
    routes: {
      '/': (RouteArguments args) => new GalleryHome()
    }
  ));
}
