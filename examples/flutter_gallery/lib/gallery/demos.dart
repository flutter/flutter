// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../demo/all.dart';

class GalleryDemoCategory {
  const GalleryDemoCategory({ this.name, this.icon });
  @required final String name;
  @required final String icon;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final GalleryDemoCategory typedOther = other;
    return typedOther.name == name && typedOther.icon == icon;
  }

  @override
  int get hashCode => hashValues(name, icon);

  @override
  String toString() {
    return '$runtimeType($name)';
  }
}

const GalleryDemoCategory _kDemos = const GalleryDemoCategory(
  name: 'Demos',
);

const GalleryDemoCategory _kStyle = const GalleryDemoCategory(
  name: 'Style',
);

const GalleryDemoCategory _kMaterialComponents = const GalleryDemoCategory(
  name: 'Material components',
);

const GalleryDemoCategory _kCupertinoComponents = const GalleryDemoCategory(
  name: 'Cupertino components',
);

const GalleryDemoCategory _kMedia = const GalleryDemoCategory(
  name: 'Media',
);

class GalleryDemo {
  const GalleryDemo({
    @required this.title,
    this.icon,
    this.subtitle,
    @required this.category,
    @required this.routeName,
    @required this.buildRoute,
  }) : assert(title != null),
       assert(category != null),
       assert(routeName != null),
       assert(buildRoute != null);

  final String title;
  final String icon;
  final String subtitle;
  final GalleryDemoCategory category;
  final String routeName;
  final WidgetBuilder buildRoute;

  @override
  String toString() {
    return '$runtimeType($title $routeName)';
  }
}

List<GalleryDemo> _buildGalleryDemos() {
  final List<GalleryDemo> galleryDemos = <GalleryDemo>[
    // Demos
    new GalleryDemo(
      title: 'Shrine',
      subtitle: 'Basic shopping app',
      category: _kDemos,
      routeName: ShrineDemo.routeName,
      buildRoute: (BuildContext context) => new ShrineDemo(),
    ),
    new GalleryDemo(
      title: 'Contact profile',
      subtitle: 'Address book entry with a flexible appbar',
      category: _kDemos,
      routeName: ContactsDemo.routeName,
      buildRoute: (BuildContext context) => new ContactsDemo(),
    ),
    new GalleryDemo(
      title: 'Animation',
      subtitle: 'Section organizer',
      category: _kDemos,
      routeName: AnimationDemo.routeName,
      buildRoute: (BuildContext context) => const AnimationDemo(),
    ),

    // Material Components
    new GalleryDemo(
      title: 'Backdrop',
      subtitle: 'Select a front layer from back layer',
      category: _kMaterialComponents,
      routeName: BackdropDemo.routeName,
      buildRoute: (BuildContext context) => new BackdropDemo(),
    ),
    new GalleryDemo(
      title: 'Bottom app bar',
      subtitle: 'With repositionable floating action button',
      category: _kMaterialComponents,
      routeName: BottomAppBarDemo.routeName,
      buildRoute: (BuildContext context) => new BottomAppBarDemo(),
    ),
    new GalleryDemo(
      title: 'Bottom navigation',
      subtitle: 'Bottom navigation with cross-fading views',
      category: _kMaterialComponents,
      routeName: BottomNavigationDemo.routeName,
      buildRoute: (BuildContext context) => new BottomNavigationDemo(),
    ),
    new GalleryDemo(
      title: 'Buttons',
      subtitle: 'All kinds: flat, raised, dropdown, icon, etc',
      category: _kMaterialComponents,
      routeName: ButtonsDemo.routeName,
      buildRoute: (BuildContext context) => new ButtonsDemo(),
    ),
    new GalleryDemo(
      title: 'Cards',
      subtitle: 'Material with rounded corners and a drop shadow',
      category: _kMaterialComponents,
      routeName: CardsDemo.routeName,
      buildRoute: (BuildContext context) => new CardsDemo(),
    ),
    new GalleryDemo(
      title: 'Chips',
      subtitle: 'Label with an optional delete button and avatar',
      category: _kMaterialComponents,
      routeName: ChipDemo.routeName,
      buildRoute: (BuildContext context) => new ChipDemo(),
    ),
    new GalleryDemo(
      title: 'Data tables',
      subtitle: 'Rows and columns',
      category: _kMaterialComponents,
      routeName: DataTableDemo.routeName,
      buildRoute: (BuildContext context) => new DataTableDemo(),
    ),
    new GalleryDemo(
      title: 'Date and time pickers',
      subtitle: 'Date and time selection widgets',
      category: _kMaterialComponents,
      routeName: DateAndTimePickerDemo.routeName,
      buildRoute: (BuildContext context) => new DateAndTimePickerDemo(),
    ),
    new GalleryDemo(
      title: 'Dialog',
      subtitle: 'All kinds: simple, alert, fullscreen, etc',
      category: _kMaterialComponents,
      routeName: DialogDemo.routeName,
      buildRoute: (BuildContext context) => new DialogDemo(),
    ),
    new GalleryDemo(
      title: 'Drawer',
      subtitle: 'Navigation drawer with a standard header',
      category: _kMaterialComponents,
      routeName: DrawerDemo.routeName,
      buildRoute: (BuildContext context) => new DrawerDemo(),
    ),
    new GalleryDemo(
      title: 'Expand/collapse list control',
      subtitle: 'List with one level of sublists',
      category: _kMaterialComponents,
      routeName: TwoLevelListDemo.routeName,
      buildRoute: (BuildContext context) => new TwoLevelListDemo(),
    ),
    new GalleryDemo(
      title: 'Expansion panels',
      subtitle: 'List of expanding panels',
      category: _kMaterialComponents,
      routeName: ExpansionPanelsDemo.routeName,
      buildRoute: (BuildContext context) => new ExpansionPanelsDemo(),
    ),
    new GalleryDemo(
      title: 'Floating action button',
      subtitle: 'Action buttons with transitions',
      category: _kMaterialComponents,
      routeName: TabsFabDemo.routeName,
      buildRoute: (BuildContext context) => new TabsFabDemo(),
    ),
    new GalleryDemo(
      title: 'Grid',
      subtitle: 'Row and column layout',
      category: _kMaterialComponents,
      routeName: GridListDemo.routeName,
      buildRoute: (BuildContext context) => const GridListDemo(),
    ),
    new GalleryDemo(
      title: 'Icons',
      subtitle: 'Enabled and disabled icons with varying opacity',
      category: _kMaterialComponents,
      routeName: IconsDemo.routeName,
      buildRoute: (BuildContext context) => new IconsDemo(),
    ),
    new GalleryDemo(
      title: 'Leave-behind list items',
      subtitle: 'List items with hidden actions',
      category: _kMaterialComponents,
      routeName: LeaveBehindDemo.routeName,
      buildRoute: (BuildContext context) => const LeaveBehindDemo(),
    ),
    new GalleryDemo(
      title: 'List',
      subtitle: 'Layout variations for scrollable lists',
      category: _kMaterialComponents,
      routeName: ListDemo.routeName,
      buildRoute: (BuildContext context) => const ListDemo(),
    ),
    new GalleryDemo(
      title: 'Menus',
      subtitle: 'Menu buttons and simple menus',
      category: _kMaterialComponents,
      routeName: MenuDemo.routeName,
      buildRoute: (BuildContext context) => const MenuDemo(),
    ),
    new GalleryDemo(
      title: 'Modal bottom sheet',
      subtitle: 'Modal sheet that slides up from the bottom',
      category: _kMaterialComponents,
      routeName: ModalBottomSheetDemo.routeName,
      buildRoute: (BuildContext context) => new ModalBottomSheetDemo(),
    ),
    new GalleryDemo(
      title: 'Page selector',
      subtitle: 'PageView with indicator',
      category: _kMaterialComponents,
      routeName: PageSelectorDemo.routeName,
      buildRoute: (BuildContext context) => new PageSelectorDemo(),
    ),
    new GalleryDemo(
      title: 'Persistent bottom sheet',
      subtitle: 'Sheet that slides up from the bottom',
      category: _kMaterialComponents,
      routeName: PersistentBottomSheetDemo.routeName,
      buildRoute: (BuildContext context) => new PersistentBottomSheetDemo(),
    ),
    new GalleryDemo(
      title: 'Progress indicators',
      subtitle: 'All kinds: linear, circular, indeterminate, etc',
      category: _kMaterialComponents,
      routeName: ProgressIndicatorDemo.routeName,
      buildRoute: (BuildContext context) => new ProgressIndicatorDemo(),
    ),
    new GalleryDemo(
      title: 'Pull to refresh',
      subtitle: 'Refresh indicators',
      category: _kMaterialComponents,
      routeName: OverscrollDemo.routeName,
      buildRoute: (BuildContext context) => const OverscrollDemo(),
    ),
    new GalleryDemo(
      title: 'Scrollable tabs',
      subtitle: 'Tab bar that scrolls',
      category: _kMaterialComponents,
      routeName: ScrollableTabsDemo.routeName,
      buildRoute: (BuildContext context) => new ScrollableTabsDemo(),
    ),
    new GalleryDemo(
      title: 'Selection controls',
      subtitle: 'Checkboxes, radio buttons, and switches',
      category: _kMaterialComponents,
      routeName: SelectionControlsDemo.routeName,
      buildRoute: (BuildContext context) => new SelectionControlsDemo(),
    ),
    new GalleryDemo(
      title: 'Sliders',
      subtitle: 'Widgets that select a value by dragging the slider thumb',
      category: _kMaterialComponents,
      routeName: SliderDemo.routeName,
      buildRoute: (BuildContext context) => new SliderDemo(),
    ),
    new GalleryDemo(
      title: 'Snackbar',
      subtitle: 'Temporary message that appears at the bottom',
      category: _kMaterialComponents,
      routeName: SnackBarDemo.routeName,
      buildRoute: (BuildContext context) => const SnackBarDemo(),
    ),
    new GalleryDemo(
      title: 'Tabs',
      subtitle: 'Tabs with independently scrollable views',
      category: _kMaterialComponents,
      routeName: TabsDemo.routeName,
      buildRoute: (BuildContext context) => new TabsDemo(),
    ),
    new GalleryDemo(
      title: 'Text fields',
      subtitle: 'Single line of editable text and numbers',
      category: _kMaterialComponents,
      routeName: TextFormFieldDemo.routeName,
      buildRoute: (BuildContext context) => const TextFormFieldDemo(),
    ),
    new GalleryDemo(
      title: 'Tooltips',
      subtitle: 'Short message displayed after a long-press',
      category: _kMaterialComponents,
      routeName: TooltipDemo.routeName,
      buildRoute: (BuildContext context) => new TooltipDemo(),
    ),

    // Cupertino Components
    new GalleryDemo(
      title: 'Activity Indicator',
      subtitle: 'Cupertino styled activity indicator',
      category: _kCupertinoComponents,
      routeName: CupertinoProgressIndicatorDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoProgressIndicatorDemo(),
    ),
    new GalleryDemo(
      title: 'Buttons',
      subtitle: 'Cupertino styled buttons',
      category: _kCupertinoComponents,
      routeName: CupertinoButtonsDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoButtonsDemo(),
    ),
    new GalleryDemo(
      title: 'Dialogs',
      subtitle: 'Cupertino styled dialogs',
      category: _kCupertinoComponents,
      routeName: CupertinoDialogDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoDialogDemo(),
    ),
    new GalleryDemo(
      title: 'Navigation',
      subtitle: 'Cupertino styled navigation patterns',
      category: _kCupertinoComponents,
      routeName: CupertinoNavigationDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoNavigationDemo(),
    ),
    new GalleryDemo(
      title: 'Pickers',
      subtitle: 'Cupertino styled pickers',
      category: _kCupertinoComponents,
      routeName: CupertinoPickerDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoPickerDemo(),
    ),
    new GalleryDemo(
      title: 'Pull to refresh',
      subtitle: 'Cupertino styled refresh controls',
      category: _kCupertinoComponents,
      routeName: CupertinoRefreshControlDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoRefreshControlDemo(),
    ),
    new GalleryDemo(
      title: 'Sliders',
      subtitle: 'Cupertino styled sliders',
      category: _kCupertinoComponents,
      routeName: CupertinoSliderDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoSliderDemo(),
    ),
    new GalleryDemo(
      title: 'Switches',
      subtitle: 'Cupertino styled switches',
      category: _kCupertinoComponents,
      routeName: CupertinoSwitchDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoSwitchDemo(),
    ),

    // Media
    new GalleryDemo(
      title: 'Animated images',
      subtitle: 'GIF and WebP animations',
      category: _kMedia,
      routeName: ImagesDemo.routeName,
      buildRoute: (BuildContext context) => new ImagesDemo(),
    ),
    new GalleryDemo(
      title: 'Video',
      subtitle: 'Video playback',
      category: _kMedia,
      routeName: VideoDemo.routeName,
      buildRoute: (BuildContext context) => const VideoDemo(),
    ),

    // Style
    new GalleryDemo(
      title: 'Colors',
      subtitle: 'All of the predefined colors',
      category: _kStyle,
      routeName: ColorsDemo.routeName,
      buildRoute: (BuildContext context) => new ColorsDemo(),
    ),
    new GalleryDemo(
      title: 'Typography',
      subtitle: 'All of the predefined text styles',
      category: _kStyle,
      routeName: TypographyDemo.routeName,
      buildRoute: (BuildContext context) => new TypographyDemo(),
    )
  ];

  // Keep Pesto around for its regression test value. It is not included
  // in (release builds) the performance tests.
  assert(() {
    galleryDemos.insert(0,
      new GalleryDemo(
        title: 'Pesto',
        subtitle: 'Simple recipe browser',
        category: _kDemos,
        routeName: PestoDemo.routeName,
        buildRoute: (BuildContext context) => const PestoDemo(),
      ),
    );
    return true;
  }());

  return galleryDemos;
}

final List<GalleryDemo> kAllGalleryDemos = _buildGalleryDemos();

final List<GalleryDemoCategory> kAllGalleryDemoCategories = new Set<GalleryDemoCategory>.from(
    kAllGalleryDemos.map((GalleryDemo demo) => demo.category)
).toList();

final Map<GalleryDemoCategory, List<GalleryDemo>> kGalleryCategoryToDemos =
  new Map<GalleryDemoCategory, List<GalleryDemo>>.fromIterable(
    kAllGalleryDemoCategories,
    value: (category) {
      return kAllGalleryDemos.where((GalleryDemo demo) => demo.category == category).toList();
    },
  );
