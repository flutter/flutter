// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/material.dart';

import '../demo/all.dart';

typedef Widget GalleryDemoBuilder();

class GalleryItem extends StatelessWidget {
  GalleryItem({ this.title, this.subtitle, this.category: 'Components', this.routeName, this.buildRoute }) {
    assert(title != null);
    assert(category != null);
    assert(routeName != null);
    assert(buildRoute != null);
  }

  final String title;
  final String subtitle;
  final String category;
  final String routeName;
  final WidgetBuilder buildRoute;

  @override
  Widget build(BuildContext context) {
    return new ListItem(
      title: new Text(title),
      subtitle: new Text(subtitle),
      onTap: () {
        if (routeName != null) {
          Timeline.instantSync('Start Transition', arguments: <String, String>{
            'from': '/',
            'to': routeName
          });
          print("GalleryItem.pushNamed $routeName");
          Navigator.pushNamed(context, routeName);
        }
      }
    );
  }
}

final List<GalleryItem> kAllGalleryItems = <GalleryItem>[
  // Demos
  new GalleryItem(
    title: 'Pesto',
    subtitle: 'A simple recipe browser',
    category: 'Demos',
    routeName: PestoDemo.routeName,
    buildRoute: (BuildContext context) => new PestoDemo()
  ),
  new GalleryItem(
    title: 'Shrine',
    subtitle:'A basic shopping app',
    category: 'Demos',
    routeName: ShrineDemo.routeName,
    buildRoute: (BuildContext context) => new ShrineDemo()
  ),
  new GalleryItem(
    title: 'Contacts',
    category: 'Demos',
    subtitle: 'Highlights the flexible appbar',
    routeName: ContactsDemo.routeName,
    buildRoute: (BuildContext context) => new ContactsDemo()
  ),
  // Components
  new GalleryItem(
    title: 'Buttons',
    subtitle: 'All kinds: flat, raised, dropdown, icon, etc',
    routeName: ButtonsDemo.routeName,
    buildRoute: (BuildContext context) => new ButtonsDemo()
  ),
  new GalleryItem(
    title: 'Cards',
    subtitle: 'Material with rounded corners and a drop shadow',
    routeName: CardsDemo.routeName,
    buildRoute: (BuildContext context) => new CardsDemo()
  ),
  new GalleryItem(
    title: 'Chips',
    subtitle: 'A label with an optional delete button and avatar',
    routeName: ChipDemo.routeName,
    buildRoute: (BuildContext context) => new ChipDemo()
  ),
  new GalleryItem(
    title: 'Date picker',
    subtitle: 'Choose month, day, and year',
    routeName: DatePickerDemo.routeName,
    buildRoute: (BuildContext context) => new DatePickerDemo()
  ),
  new GalleryItem(
    title: 'Dialog',
    subtitle: 'All kinds: simple, alert, fullscreen, etc',
    routeName: DialogDemo.routeName,
    buildRoute: (BuildContext context) => new DialogDemo()
  ),
  new GalleryItem(
    title: 'Expand/collapse list control',
    subtitle: 'A list with one level of sublists',
    routeName: TwoLevelListDemo.routeName,
    buildRoute: (BuildContext context) => new TwoLevelListDemo()
  ),
  new GalleryItem(
    title: 'Floating action button',
    subtitle: 'Demos action button transitions',
    routeName: TabsFabDemo.routeName,
    buildRoute: (BuildContext context) => new TabsFabDemo()
  ),
  new GalleryItem(
    title: 'Grid',
    subtitle: 'Row and column layout',
    routeName: GridListDemo.routeName,
    buildRoute: (BuildContext context) => new GridListDemo()
  ),
  new GalleryItem(
    title: 'Icons',
    subtitle: 'Enabled and disabled icons with varying opacity',
    routeName: IconsDemo.routeName,
    buildRoute: (BuildContext context) => new IconsDemo()
  ),
  new GalleryItem(
    title: 'Leave-behind list items',
    subtitle: 'Drag items to expose hidden actions',
    routeName: LeaveBehindDemo.routeName,
    buildRoute: (BuildContext context) => new LeaveBehindDemo()
  ),
  new GalleryItem(
    title: 'List',
    subtitle: 'All the layout variations for scrollable lists',
    routeName: ListDemo.routeName,
    buildRoute: (BuildContext context) => new ListDemo()
  ),
  new GalleryItem(
    title: 'Menus',
    subtitle: 'Menu buttons and simple menus',
    routeName: MenuDemo.routeName,
    buildRoute: (BuildContext context) => new MenuDemo()
  ),
  new GalleryItem(
    title: 'Modal bottom sheet',
    subtitle: 'A modal sheet that slides up from the bottom',
    routeName: ModalBottomSheetDemo.routeName,
    buildRoute: (BuildContext context) => new ModalBottomSheetDemo()
  ),
  new GalleryItem(
    title: 'Over-scroll',
    subtitle: 'Refresh and overscroll indicators',
    routeName: OverscrollDemo.routeName,
    buildRoute: (BuildContext context) => new OverscrollDemo()
  ),
  new GalleryItem(
    title: 'Page selector',
    subtitle: 'A pageable list and other widgets',
    routeName: PageSelectorDemo.routeName,
    buildRoute: (BuildContext context) => new PageSelectorDemo()
  ),
  new GalleryItem(
    title: 'Persistent bottom sheet',
    subtitle: 'A sheet that slides up from the bottom',
    routeName: PersistentBottomSheetDemo.routeName,
    buildRoute: (BuildContext context) => new PersistentBottomSheetDemo()
  ),
  new GalleryItem(
    title: 'Progress indicators',
    subtitle: 'All kinds: linear, circular, indeterminate, etc',
    routeName: ProgressIndicatorDemo.routeName,
    buildRoute: (BuildContext context) => new ProgressIndicatorDemo()
  ),
  new GalleryItem(
    title: 'Scrollable tabs',
    subtitle: 'A tab bar that scrolls',
    routeName: ScrollableTabsDemo.routeName,
    buildRoute: (BuildContext context) => new ScrollableTabsDemo()
  ),
  new GalleryItem(
    title: 'Selection controls',
    subtitle: 'Checkboxes, radio buttons, and switches',
    routeName: SelectionControlsDemo.routeName,
    buildRoute: (BuildContext context) => new SelectionControlsDemo()
  ),
  new GalleryItem(
    title: 'Sliders',
    subtitle: 'Select a value by dragging the slider thumb',
    routeName: SliderDemo.routeName,
    buildRoute: (BuildContext context) => new SliderDemo()
  ),
  new GalleryItem(
    title: 'Snackbar',
    subtitle: 'Temporary message that appears at the bottom',
    routeName: SnackBarDemo.routeName,
    buildRoute: (BuildContext context) => new SnackBarDemo()
  ),
  new GalleryItem(
    title: 'Tabs',
    subtitle: 'Tabs with independently scrollable views',
    routeName: TabsDemo.routeName,
    buildRoute: (BuildContext context) => new TabsDemo()
  ),
  new GalleryItem(
    title: 'Text fields',
    subtitle: 'A Single line of editable text',
    routeName: TextFieldDemo.routeName,
    buildRoute: (BuildContext context) => new TextFieldDemo()
  ),
  new GalleryItem(
    title: 'Time picker',
    subtitle: 'Choose a hours and minutes',
    routeName: TimePickerDemo.routeName,
    buildRoute: (BuildContext context) => new TimePickerDemo()
  ),
  new GalleryItem(
    title: 'Tooltips',
    subtitle: 'Display a short message on long-press',
    routeName: TooltipDemo.routeName,
    buildRoute: (BuildContext context) => new TooltipDemo()
  ),
  // Styles
  new GalleryItem(
    title: 'Animation',
    subtitle: 'Material motion for points and rectangles',
    category: 'Style',
    routeName: AnimationDemo.routeName,
    buildRoute: (BuildContext context) => new AnimationDemo()
  ),
  new GalleryItem(
    title: 'Colors',
    subtitle: 'All of the predefined colors',
    category: 'Style',
    routeName: ColorsDemo.routeName,
    buildRoute: (BuildContext context) => new ColorsDemo()
  ),
  new GalleryItem(
    title: 'Typography',
    subtitle: 'All of the predefined text styles',
    category: 'Style',
    routeName: TypographyDemo.routeName,
    buildRoute: (BuildContext context) => new TypographyDemo()
  )
];
