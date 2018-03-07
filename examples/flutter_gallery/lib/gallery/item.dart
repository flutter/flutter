// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../demo/all.dart';

typedef Widget GalleryDemoBuilder();

class GalleryItem extends StatelessWidget {
  const GalleryItem({
    @required this.title,
    this.subtitle,
    @required this.category,
    @required this.routeName,
    @required this.buildRoute,
  }) : assert(title != null),
       assert(category != null),
       assert(routeName != null),
       assert(buildRoute != null);

  final String title;
  final String subtitle;
  final String category;
  final String routeName;
  final WidgetBuilder buildRoute;

  @override
  Widget build(BuildContext context) {
    return new ListTile(
      title: new Text(title),
      subtitle: new Text(subtitle),
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

List<GalleryItem> _buildGalleryItems() {
  // When editing this list, make sure you keep it in sync with
  // the list in ../../test_driver/transitions_perf_test.dart
  final List<GalleryItem> galleryItems = <GalleryItem>[
    // Demos
    new GalleryItem(
      title: 'Shrine',
      subtitle: 'Basic shopping app',
      category: 'Demos',
      routeName: ShrineDemo.routeName,
      buildRoute: (BuildContext context) => new ShrineDemo(),
    ),
    new GalleryItem(
      title: 'Contact profile',
      subtitle: 'Address book entry with a flexible appbar',
      category: 'Demos',
      routeName: ContactsDemo.routeName,
      buildRoute: (BuildContext context) => new ContactsDemo(),
    ),
    new GalleryItem(
      title: 'Animation',
      subtitle: 'Section organizer',
      category: 'Demos',
      routeName: AnimationDemo.routeName,
      buildRoute: (BuildContext context) => const AnimationDemo(),
    ),
    new GalleryItem(
      title: 'Video',
      subtitle: 'Video playback',
      category: 'Demos',
      routeName: VideoDemo.routeName,
      buildRoute: (BuildContext context) => const VideoDemo(),
    ),
    // Material Components
    new GalleryItem(
      title: 'Bottom navigation',
      subtitle: 'Bottom navigation with cross-fading views',
      category: 'Material Components',
      routeName: BottomNavigationDemo.routeName,
      buildRoute: (BuildContext context) => new BottomNavigationDemo(),
    ),
    new GalleryItem(
      title: 'Buttons',
      subtitle: 'All kinds: flat, raised, dropdown, icon, etc',
      category: 'Material Components',
      routeName: ButtonsDemo.routeName,
      buildRoute: (BuildContext context) => new ButtonsDemo(),
    ),
    new GalleryItem(
      title: 'Cards',
      subtitle: 'Material with rounded corners and a drop shadow',
      category: 'Material Components',
      routeName: CardsDemo.routeName,
      buildRoute: (BuildContext context) => new CardsDemo(),
    ),
    new GalleryItem(
      title: 'Chips',
      subtitle: 'Label with an optional delete button and avatar',
      category: 'Material Components',
      routeName: ChipDemo.routeName,
      buildRoute: (BuildContext context) => new ChipDemo(),
    ),
    new GalleryItem(
      title: 'Data tables',
      subtitle: 'Data tables',
      category: 'Material Components',
      routeName: DataTableDemo.routeName,
      buildRoute: (BuildContext context) => new DataTableDemo(),
    ),
    new GalleryItem(
      title: 'Date and time pickers',
      subtitle: 'Date and time selection widgets',
      category: 'Material Components',
      routeName: DateAndTimePickerDemo.routeName,
      buildRoute: (BuildContext context) => new DateAndTimePickerDemo(),
    ),
    new GalleryItem(
      title: 'Dialog',
      subtitle: 'All kinds: simple, alert, fullscreen, etc',
      category: 'Material Components',
      routeName: DialogDemo.routeName,
      buildRoute: (BuildContext context) => new DialogDemo(),
    ),
    new GalleryItem(
      title: 'Drawer',
      subtitle: 'Navigation drawer with a standard header',
      category: 'Material Components',
      routeName: DrawerDemo.routeName,
      buildRoute: (BuildContext context) => new DrawerDemo(),
    ),
    new GalleryItem(
      title: 'Expand/collapse list control',
      subtitle: 'List with one level of sublists',
      category: 'Material Components',
      routeName: TwoLevelListDemo.routeName,
      buildRoute: (BuildContext context) => new TwoLevelListDemo(),
    ),
    new GalleryItem(
      title: 'Expansion panels',
      subtitle: 'List of expanding panels',
      category: 'Material Components',
      routeName: ExpansionPanelsDemo.routeName,
      buildRoute: (BuildContext context) => new ExpansionPanelsDemo(),
    ),
    new GalleryItem(
      title: 'Floating action button',
      subtitle: 'Action buttons with transitions',
      category: 'Material Components',
      routeName: TabsFabDemo.routeName,
      buildRoute: (BuildContext context) => new TabsFabDemo(),
    ),
    new GalleryItem(
      title: 'Grid',
      subtitle: 'Row and column layout',
      category: 'Material Components',
      routeName: GridListDemo.routeName,
      buildRoute: (BuildContext context) => const GridListDemo(),
    ),
    new GalleryItem(
      title: 'Icons',
      subtitle: 'Enabled and disabled icons with varying opacity',
      category: 'Material Components',
      routeName: IconsDemo.routeName,
      buildRoute: (BuildContext context) => new IconsDemo(),
    ),
    new GalleryItem(
      title: 'Leave-behind list items',
      subtitle: 'List items with hidden actions',
      category: 'Material Components',
      routeName: LeaveBehindDemo.routeName,
      buildRoute: (BuildContext context) => const LeaveBehindDemo(),
    ),
    new GalleryItem(
      title: 'List',
      subtitle: 'Layout variations for scrollable lists',
      category: 'Material Components',
      routeName: ListDemo.routeName,
      buildRoute: (BuildContext context) => const ListDemo(),
    ),
    new GalleryItem(
      title: 'Menus',
      subtitle: 'Menu buttons and simple menus',
      category: 'Material Components',
      routeName: MenuDemo.routeName,
      buildRoute: (BuildContext context) => const MenuDemo(),
    ),
    new GalleryItem(
      title: 'Modal bottom sheet',
      subtitle: 'Modal sheet that slides up from the bottom',
      category: 'Material Components',
      routeName: ModalBottomSheetDemo.routeName,
      buildRoute: (BuildContext context) => new ModalBottomSheetDemo(),
    ),
    new GalleryItem(
      title: 'Page selector',
      subtitle: 'PageView with indicator',
      category: 'Material Components',
      routeName: PageSelectorDemo.routeName,
      buildRoute: (BuildContext context) => new PageSelectorDemo(),
    ),
    new GalleryItem(
      title: 'Persistent bottom sheet',
      subtitle: 'Sheet that slides up from the bottom',
      category: 'Material Components',
      routeName: PersistentBottomSheetDemo.routeName,
      buildRoute: (BuildContext context) => new PersistentBottomSheetDemo(),
    ),
    new GalleryItem(
      title: 'Progress indicators',
      subtitle: 'All kinds: linear, circular, indeterminate, etc',
      category: 'Material Components',
      routeName: ProgressIndicatorDemo.routeName,
      buildRoute: (BuildContext context) => new ProgressIndicatorDemo(),
    ),
    new GalleryItem(
      title: 'Pull to refresh',
      subtitle: 'Refresh indicators',
      category: 'Material Components',
      routeName: OverscrollDemo.routeName,
      buildRoute: (BuildContext context) => const OverscrollDemo(),
    ),
    new GalleryItem(
      title: 'Scrollable tabs',
      subtitle: 'Tab bar that scrolls',
      category: 'Material Components',
      routeName: ScrollableTabsDemo.routeName,
      buildRoute: (BuildContext context) => new ScrollableTabsDemo(),
    ),
    new GalleryItem(
      title: 'Selection controls',
      subtitle: 'Checkboxes, radio buttons, and switches',
      category: 'Material Components',
      routeName: SelectionControlsDemo.routeName,
      buildRoute: (BuildContext context) => new SelectionControlsDemo(),
    ),
    new GalleryItem(
      title: 'Sliders',
      subtitle: 'Widgets that select a value by dragging the slider thumb',
      category: 'Material Components',
      routeName: SliderDemo.routeName,
      buildRoute: (BuildContext context) => new SliderDemo(),
    ),
    new GalleryItem(
      title: 'Snackbar',
      subtitle: 'Temporary message that appears at the bottom',
      category: 'Material Components',
      routeName: SnackBarDemo.routeName,
      buildRoute: (BuildContext context) => const SnackBarDemo(),
    ),
    new GalleryItem(
      title: 'Tabs',
      subtitle: 'Tabs with independently scrollable views',
      category: 'Material Components',
      routeName: TabsDemo.routeName,
      buildRoute: (BuildContext context) => new TabsDemo(),
    ),
    new GalleryItem(
      title: 'Text fields',
      subtitle: 'Single line of editable text and numbers',
      category: 'Material Components',
      routeName: TextFormFieldDemo.routeName,
      buildRoute: (BuildContext context) => const TextFormFieldDemo(),
    ),
    new GalleryItem(
      title: 'Tooltips',
      subtitle: 'Short message displayed after a long-press',
      category: 'Material Components',
      routeName: TooltipDemo.routeName,
      buildRoute: (BuildContext context) => new TooltipDemo(),
    ),
    // Cupertino Components
    new GalleryItem(
      title: 'Activity Indicator',
      subtitle: 'Cupertino styled activity indicator',
      category: 'Cupertino Components',
      routeName: CupertinoProgressIndicatorDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoProgressIndicatorDemo(),
    ),
    new GalleryItem(
      title: 'Buttons',
      subtitle: 'Cupertino styled buttons',
      category: 'Cupertino Components',
      routeName: CupertinoButtonsDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoButtonsDemo(),
    ),
    new GalleryItem(
      title: 'Dialogs',
      subtitle: 'Cupertino styled dialogs',
      category: 'Cupertino Components',
      routeName: CupertinoDialogDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoDialogDemo(),
    ),
    new GalleryItem(
      title: 'Navigation',
      subtitle: 'Cupertino styled navigation patterns',
      category: 'Cupertino Components',
      routeName: CupertinoNavigationDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoNavigationDemo(),
    ),
    new GalleryItem(
      title: 'Pickers',
      subtitle: 'Cupertino styled pickers',
      category: 'Cupertino Components',
      routeName: CupertinoPickerDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoPickerDemo(),
    ),
    new GalleryItem(
      title: 'Sliders',
      subtitle: 'Cupertino styled sliders',
      category: 'Cupertino Components',
      routeName: CupertinoSliderDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoSliderDemo(),
    ),
    new GalleryItem(
      title: 'Switches',
      subtitle: 'Cupertino styled switches',
      category: 'Cupertino Components',
      routeName: CupertinoSwitchDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoSwitchDemo(),
    ),
    // Media
    new GalleryItem(
      title: 'Animated images',
      subtitle: 'GIF and WebP animations',
      category: 'Media',
      routeName: ImagesDemo.routeName,
      buildRoute: (BuildContext context) => new ImagesDemo(),
    ),
    // Styles
    new GalleryItem(
      title: 'Colors',
      subtitle: 'All of the predefined colors',
      category: 'Style',
      routeName: ColorsDemo.routeName,
      buildRoute: (BuildContext context) => new ColorsDemo(),
    ),
    new GalleryItem(
      title: 'Typography',
      subtitle: 'All of the predefined text styles',
      category: 'Style',
      routeName: TypographyDemo.routeName,
      buildRoute: (BuildContext context) => new TypographyDemo(),
    )
  ];

  // Keep Pesto around for its regression test value. It is not included
  // in (release builds) the performance tests.
  assert(() {
    galleryItems.insert(0,
      new GalleryItem(
        title: 'Pesto',
        subtitle: 'Simple recipe browser',
        category: 'Demos',
        routeName: PestoDemo.routeName,
        buildRoute: (BuildContext context) => const PestoDemo(),
      ),
    );
    return true;
  }());

  return galleryItems;
}

final List<GalleryItem> kAllGalleryItems = _buildGalleryItems();
