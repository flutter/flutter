// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/material.dart';

import '../demo/all.dart';

typedef Widget GalleryDemoBuilder();

class GalleryItem extends StatelessWidget {
  GalleryItem({ this.title, this.category: 'Components', this.routeName, this.buildRoute }) {
    assert(title != null);
    assert(category != null);
    assert(routeName != null);
    assert(buildRoute != null);
  }

  final String title;
  final String category;
  final String routeName;
  final WidgetBuilder buildRoute;

  @override
  Widget build(BuildContext context) {
    return new TwoLevelListItem(
      title: new Text(title),
      onTap: () {
        if (routeName != null) {
          Timeline.instantSync('Start Transition', arguments: <String, String>{
            'from': '/',
            'to': routeName
          });
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
    category: 'Demos',
    routeName: PestoDemo.routeName,
    buildRoute: (BuildContext context) => new PestoDemo()
  ),
  new GalleryItem(
    title: 'Shrine',
    category: 'Demos',
    routeName: ShrineDemo.routeName,
    buildRoute: (BuildContext context) => new ShrineDemo()
  ),
  new GalleryItem(
    title: 'Calculator',
    category: 'Demos',
    routeName: CalculatorDemo.routeName,
    buildRoute: (BuildContext context) => new CalculatorDemo()
  ),
  new GalleryItem(
    title: 'Contacts',
    category: 'Demos',
    routeName: ContactsDemo.routeName,
    buildRoute: (BuildContext context) => new ContactsDemo()
  ),
  // Components
  new GalleryItem(
    title: 'Buttons',
    routeName: ButtonsDemo.routeName,
    buildRoute: (BuildContext context) => new ButtonsDemo()
  ),
  new GalleryItem(
    title: 'Cards',
    routeName: CardsDemo.routeName,
    buildRoute: (BuildContext context) => new CardsDemo()
  ),
  new GalleryItem(
    title: 'Chips',
    routeName: ChipDemo.routeName,
    buildRoute: (BuildContext context) => new ChipDemo()
  ),
  new GalleryItem(
    title: 'Date picker',
    routeName: DatePickerDemo.routeName,
    buildRoute: (BuildContext context) => new DatePickerDemo()
  ),
  new GalleryItem(
    title: 'Data tables',
    routeName: DataTableDemo.routeName,
    buildRoute: (BuildContext context) => new DataTableDemo()
  ),
  new GalleryItem(
    title: 'Dialog',
    routeName: DialogDemo.routeName,
    buildRoute: (BuildContext context) => new DialogDemo()
  ),
  new GalleryItem(
    title: 'Expand/collapse list control',
    routeName: TwoLevelListDemo.routeName,
    buildRoute: (BuildContext context) => new TwoLevelListDemo()
  ),
  new GalleryItem(
    title: 'Floating action button',
    routeName: TabsFabDemo.routeName,
    buildRoute: (BuildContext context) => new TabsFabDemo()
  ),
  new GalleryItem(
    title: 'Grid',
    routeName: GridListDemo.routeName,
    buildRoute: (BuildContext context) => new GridListDemo()
  ),
  new GalleryItem(
    title: 'Icons',
    routeName: IconsDemo.routeName,
    buildRoute: (BuildContext context) => new IconsDemo()
  ),
  new GalleryItem(
    title: 'Leave-behind list items',
    routeName: LeaveBehindDemo.routeName,
    buildRoute: (BuildContext context) => new LeaveBehindDemo()
  ),
  new GalleryItem(
    title: 'List',
    routeName: ListDemo.routeName,
    buildRoute: (BuildContext context) => new ListDemo()
  ),
  new GalleryItem(
    title: 'Menus',
    routeName: MenuDemo.routeName,
    buildRoute: (BuildContext context) => new MenuDemo()
  ),
  new GalleryItem(
    title: 'Modal bottom sheet',
    routeName: ModalBottomSheetDemo.routeName,
    buildRoute: (BuildContext context) => new ModalBottomSheetDemo()
  ),
  new GalleryItem(
    title: 'Over-scroll',
    routeName: OverscrollDemo.routeName,
    buildRoute: (BuildContext context) => new OverscrollDemo()
  ),
  new GalleryItem(
    title: 'Page selector',
    routeName: PageSelectorDemo.routeName,
    buildRoute: (BuildContext context) => new PageSelectorDemo()
  ),
  new GalleryItem(
    title: 'Persistent bottom sheet',
    routeName: PersistentBottomSheetDemo.routeName,
    buildRoute: (BuildContext context) => new PersistentBottomSheetDemo()
  ),
  new GalleryItem(
    title: 'Progress indicators',
    routeName: ProgressIndicatorDemo.routeName,
    buildRoute: (BuildContext context) => new ProgressIndicatorDemo()
  ),
  new GalleryItem(
    title: 'Scrollable tabs',
    routeName: ScrollableTabsDemo.routeName,
    buildRoute: (BuildContext context) => new ScrollableTabsDemo()
  ),
  new GalleryItem(
    title: 'Selection controls',
    routeName: SelectionControlsDemo.routeName,
    buildRoute: (BuildContext context) => new SelectionControlsDemo()
  ),
  new GalleryItem(
    title: 'Sliders',
    routeName: SliderDemo.routeName,
    buildRoute: (BuildContext context) => new SliderDemo()
  ),
  new GalleryItem(
    title: 'Snackbar',
    routeName: SnackBarDemo.routeName,
    buildRoute: (BuildContext context) => new SnackBarDemo()
  ),
  new GalleryItem(
    title: 'Tabs',
    routeName: TabsDemo.routeName,
    buildRoute: (BuildContext context) => new TabsDemo()
  ),
  new GalleryItem(
    title: 'Text fields',
    routeName: TextFieldDemo.routeName,
    buildRoute: (BuildContext context) => new TextFieldDemo()
  ),
  new GalleryItem(
    title: 'Time picker',
    routeName: TimePickerDemo.routeName,
    buildRoute: (BuildContext context) => new TimePickerDemo()
  ),
  new GalleryItem(
    title: 'Tooltips',
    routeName: TooltipDemo.routeName,
    buildRoute: (BuildContext context) => new TooltipDemo()
  ),
  // Styles
  new GalleryItem(
    title: 'Colors',
    category: 'Style',
    routeName: ColorsDemo.routeName,
    buildRoute: (BuildContext context) => new ColorsDemo()
  ),
  new GalleryItem(
    title: 'Typography',
    category: 'Style',
    routeName: TypographyDemo.routeName,
    buildRoute: (BuildContext context) => new TypographyDemo()
  )
];
