// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';// show timeDilation;

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
      brightness: Theme.of(context).brightness,
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
      brightness: Theme.of(context).brightness,
      primarySwatch: colors
    );
    final titleTextStyle = theme.text.title.copyWith(
      color: theme.brightness == ThemeBrightness.dark ?  Colors.black : Colors.white
    );
    return new Flexible(
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
                  child: new Text(title, style: titleTextStyle)
                )
              )
            ]
          )
        )
      )
    );
  }
}

class GalleryHome extends StatefulComponent {
  GalleryHomeState createState() => new GalleryHomeState();
}

class GalleryHomeState extends State<GalleryHome> {
  void _changeTheme(BuildContext context, bool value) {
    GalleryApp.of(context).lightTheme = value;
  }

  void _toggleAnimationSpeed() {
    setState((){
      timeDilation = (timeDilation != 1.0) ? 1.0 : 5.0;
    });
  }

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
      drawer: new Drawer(
        child: new Block(
          children: <Widget>[
            new DrawerHeader(child: new Text('Flutter Gallery')),
            new DrawerItem(
              icon: 'image/brightness_5',
              onPressed: () { _changeTheme(context, true); },
              selected: GalleryApp.of(context).lightTheme,
              child: new Row(
                children: <Widget>[
                  new Flexible(child: new Text('Light')),
                  new Radio<bool>(
                    value: true,
                    groupValue: GalleryApp.of(context).lightTheme,
                    onChanged: (bool value) { _changeTheme(context, value); }
                  )
                ]
              )
            ),
            new DrawerItem(
              icon: 'image/brightness_7',
              onPressed: () { _changeTheme(context, false); },
              selected: !GalleryApp.of(context).lightTheme,
              child: new Row(
                children: <Widget>[
                  new Flexible(child: new Text('Dark')),
                  new Radio<bool>(
                    value: false,
                    groupValue: GalleryApp.of(context).lightTheme,
                    onChanged: (bool value) { _changeTheme(context, value); }
                  )
                ]
              )
            ),
            new DrawerDivider(),
            new DrawerItem(
              icon: 'action/hourglass_empty',
              selected: timeDilation != 1.0,
              onPressed: () { _toggleAnimationSpeed(); },
              child: new Row(
                children: <Widget>[
                  new Flexible(child: new Text('Animate Slowly')),
                  new Checkbox(
                    value: timeDilation != 1.0,
                    onChanged: (bool value) { _toggleAnimationSpeed(); }
                  )
                ]
              )
            )
          ]
        )
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
                    new GalleryDemo(title: 'Floating Action Button', builder: () => new TabsFabDemo())
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

class GalleryApp extends StatefulComponent {
  static GalleryAppState of(BuildContext context) => context.ancestorStateOfType(const TypeMatcher<GalleryAppState>());

  GalleryAppState createState() => new GalleryAppState();
}

class GalleryAppState extends State<GalleryApp> {
  bool _lightTheme = true;
  bool get lightTheme => _lightTheme;
  void set lightTheme(bool value) {
    setState(() {
      _lightTheme = value;
    });
  }

  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Material Gallery',
      theme: lightTheme ? new ThemeData.light() : new ThemeData.dark(),
      routes: {
        '/': (RouteArguments args) => new GalleryHome()
      }
    );
  }
}

void main() {
  runApp(new GalleryApp());
}
