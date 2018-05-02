// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../demo/all.dart';
import 'icons.dart';

class GalleryDemoCategory {
  const GalleryDemoCategory._({ this.name, this.icon });
  @required final String name;
  @required final IconData icon;

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

const GalleryDemoCategory _kDemos = const GalleryDemoCategory._(
  name: 'Vignettes',
  icon: GalleryIcons.animation,
);

const GalleryDemoCategory _kStyle = const GalleryDemoCategory._(
  name: 'Style',
  icon: GalleryIcons.custom_typography,
);

const GalleryDemoCategory _kMaterialComponents = const GalleryDemoCategory._(
  name: 'Material',
  icon: GalleryIcons.category_mdc,
);

const GalleryDemoCategory _kCupertinoComponents = const GalleryDemoCategory._(
  name: 'Cupertino',
  icon: GalleryIcons.phone_iphone,
);

const GalleryDemoCategory _kMedia = const GalleryDemoCategory._(
  name: 'Media',
  icon: GalleryIcons.drive_video,
);

class GalleryDemo {
  const GalleryDemo({
    @required this.title,
    @required this.icon,
    this.subtitle,
    @required this.category,
    @required this.routeName,
    @required this.buildRoute,
  }) : assert(title != null),
       assert(category != null),
       assert(routeName != null),
       assert(buildRoute != null);

  final String title;
  final IconData icon;
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
      icon: GalleryIcons.shrine,
      category: _kDemos,
      routeName: ShrineDemo.routeName,
      buildRoute: (BuildContext context) => new ShrineDemo(),
    ),
    new GalleryDemo(
      title: 'Contact profile',
      subtitle: 'Address book entry with a flexible appbar',
      icon: GalleryIcons.account_box,
      category: _kDemos,
      routeName: ContactsDemo.routeName,
      buildRoute: (BuildContext context) => new ContactsDemo(),
    ),
    new GalleryDemo(
      title: 'Animation',
      subtitle: 'Section organizer',
      icon: GalleryIcons.animation,
      category: _kDemos,
      routeName: AnimationDemo.routeName,
      buildRoute: (BuildContext context) => const AnimationDemo(),
    ),

    // Style
    new GalleryDemo(
      title: 'Colors',
      subtitle: 'All of the predefined colors',
      icon: GalleryIcons.colors,
      category: _kStyle,
      routeName: ColorsDemo.routeName,
      buildRoute: (BuildContext context) => new ColorsDemo(),
    ),
    new GalleryDemo(
      title: 'Typography',
      subtitle: 'All of the predefined text styles',
      icon: GalleryIcons.custom_typography,
      category: _kStyle,
      routeName: TypographyDemo.routeName,
      buildRoute: (BuildContext context) => new TypographyDemo(),
    ),

    // Material Components
    new GalleryDemo(
      title: 'Backdrop',
      subtitle: 'Select a front layer from back layer',
      icon: GalleryIcons.backdrop,
      category: _kMaterialComponents,
      routeName: BackdropDemo.routeName,
      buildRoute: (BuildContext context) => new BackdropDemo(),
    ),
    new GalleryDemo(
      title: 'Bottom app bar',
      subtitle: 'Optional floating action button notch',
      icon: GalleryIcons.bottom_app_bar,
      category: _kMaterialComponents,
      routeName: BottomAppBarDemo.routeName,
      buildRoute: (BuildContext context) => new BottomAppBarDemo(),
    ),
    new GalleryDemo(
      title: 'Bottom navigation',
      subtitle: 'Bottom navigation with cross-fading views',
      icon: GalleryIcons.bottom_navigation,
      category: _kMaterialComponents,
      routeName: BottomNavigationDemo.routeName,
      buildRoute: (BuildContext context) => new BottomNavigationDemo(),
    ),
    new GalleryDemo(
      title: 'Buttons',
      subtitle: 'All kinds: flat, raised, dropdown, icon, etc',
      icon: GalleryIcons.generic_buttons,
      category: _kMaterialComponents,
      routeName: ButtonsDemo.routeName,
      buildRoute: (BuildContext context) => new ButtonsDemo(),
    ),
    new GalleryDemo(
      title: 'Cards',
      subtitle: 'Material with rounded corners and a drop shadow',
      icon: GalleryIcons.cards,
      category: _kMaterialComponents,
      routeName: CardsDemo.routeName,
      buildRoute: (BuildContext context) => new CardsDemo(),
    ),
    new GalleryDemo(
      title: 'Chips',
      subtitle: 'Label with an optional delete button and avatar',
      icon: GalleryIcons.chips,
      category: _kMaterialComponents,
      routeName: ChipDemo.routeName,
      buildRoute: (BuildContext context) => new ChipDemo(),
    ),
    new GalleryDemo(
      title: 'Data tables',
      subtitle: 'Rows and columns',
      icon: GalleryIcons.data_table,
      category: _kMaterialComponents,
      routeName: DataTableDemo.routeName,
      buildRoute: (BuildContext context) => new DataTableDemo(),
    ),
    new GalleryDemo(
      title: 'Date and time pickers',
      subtitle: 'Date and time selection widgets',
      icon: GalleryIcons.event,
      category: _kMaterialComponents,
      routeName: DateAndTimePickerDemo.routeName,
      buildRoute: (BuildContext context) => new DateAndTimePickerDemo(),
    ),
    new GalleryDemo(
      title: 'Dialog',
      subtitle: 'All kinds: simple, alert, fullscreen, etc',
      icon: GalleryIcons.dialogs,
      category: _kMaterialComponents,
      routeName: DialogDemo.routeName,
      buildRoute: (BuildContext context) => new DialogDemo(),
    ),
    new GalleryDemo(
      title: 'Drawer',
      subtitle: 'Navigation drawer with a standard header',
      icon: GalleryIcons.menu,
      category: _kMaterialComponents,
      routeName: DrawerDemo.routeName,
      buildRoute: (BuildContext context) => new DrawerDemo(),
    ),
    new GalleryDemo(
      title: 'Expand/collapse list control',
      subtitle: 'List with one level of sublists',
      icon: GalleryIcons.expand_all,
      category: _kMaterialComponents,
      routeName: TwoLevelListDemo.routeName,
      buildRoute: (BuildContext context) => new TwoLevelListDemo(),
    ),
    new GalleryDemo(
      title: 'Expansion panels',
      subtitle: 'List of expanding panels',
      icon: GalleryIcons.expand_all,
      category: _kMaterialComponents,
      routeName: ExpansionPanelsDemo.routeName,
      buildRoute: (BuildContext context) => new ExpansionPanelsDemo(),
    ),
    new GalleryDemo(
      title: 'Floating action button',
      subtitle: 'Action buttons with transitions',
      icon: GalleryIcons.buttons,
      category: _kMaterialComponents,
      routeName: TabsFabDemo.routeName,
      buildRoute: (BuildContext context) => new TabsFabDemo(),
    ),
    new GalleryDemo(
      title: 'Grid',
      subtitle: 'Row and column layout',
      icon: GalleryIcons.grid_on,
      category: _kMaterialComponents,
      routeName: GridListDemo.routeName,
      buildRoute: (BuildContext context) => const GridListDemo(),
    ),
    new GalleryDemo(
      title: 'Icons',
      subtitle: 'Enabled and disabled icons with varying opacity',
      icon: GalleryIcons.sentiment_very_satisfied,
      category: _kMaterialComponents,
      routeName: IconsDemo.routeName,
      buildRoute: (BuildContext context) => new IconsDemo(),
    ),
    new GalleryDemo(
      title: 'Leave-behind list items',
      subtitle: 'List items with hidden actions',
      icon: GalleryIcons.lists_leave_behind,
      category: _kMaterialComponents,
      routeName: LeaveBehindDemo.routeName,
      buildRoute: (BuildContext context) => const LeaveBehindDemo(),
    ),
    new GalleryDemo(
      title: 'List',
      subtitle: 'Layout variations for scrollable lists',
      icon: GalleryIcons.list_alt,
      category: _kMaterialComponents,
      routeName: ListDemo.routeName,
      buildRoute: (BuildContext context) => const ListDemo(),
    ),
    new GalleryDemo(
      title: 'Menus',
      subtitle: 'Menu buttons and simple menus',
      icon: GalleryIcons.more_vert,
      category: _kMaterialComponents,
      routeName: MenuDemo.routeName,
      buildRoute: (BuildContext context) => const MenuDemo(),
    ),
    new GalleryDemo(
      title: 'Modal bottom sheet',
      subtitle: 'Modal sheet that slides up from the bottom',
      icon: GalleryIcons.bottom_sheets,
      category: _kMaterialComponents,
      routeName: ModalBottomSheetDemo.routeName,
      buildRoute: (BuildContext context) => new ModalBottomSheetDemo(),
    ),
    new GalleryDemo(
      title: 'Page selector',
      subtitle: 'PageView with indicator',
      icon: GalleryIcons.page_control,
      category: _kMaterialComponents,
      routeName: PageSelectorDemo.routeName,
      buildRoute: (BuildContext context) => new PageSelectorDemo(),
    ),
    new GalleryDemo(
      title: 'Persistent bottom sheet',
      subtitle: 'Sheet that slides up from the bottom',
      icon: GalleryIcons.bottom_sheet_persistent,
      category: _kMaterialComponents,
      routeName: PersistentBottomSheetDemo.routeName,
      buildRoute: (BuildContext context) => new PersistentBottomSheetDemo(),
    ),
    new GalleryDemo(
      title: 'Progress indicators',
      subtitle: 'All kinds: linear, circular, indeterminate, etc',
      icon: GalleryIcons.progress_activity,
      category: _kMaterialComponents,
      routeName: ProgressIndicatorDemo.routeName,
      buildRoute: (BuildContext context) => new ProgressIndicatorDemo(),
    ),
    new GalleryDemo(
      title: 'Pull to refresh',
      subtitle: 'Refresh indicators',
      icon: GalleryIcons.refresh,
      category: _kMaterialComponents,
      routeName: OverscrollDemo.routeName,
      buildRoute: (BuildContext context) => const OverscrollDemo(),
    ),
    new GalleryDemo(
      title: 'Scrollable tabs',
      subtitle: 'Tab bar that scrolls',
      category: _kMaterialComponents,
      icon: GalleryIcons.tabs,
      routeName: ScrollableTabsDemo.routeName,
      buildRoute: (BuildContext context) => new ScrollableTabsDemo(),
    ),
    new GalleryDemo(
      title: 'Selection controls',
      subtitle: 'Checkboxes, radio buttons, and switches',
      icon: GalleryIcons.check_box,
      category: _kMaterialComponents,
      routeName: SelectionControlsDemo.routeName,
      buildRoute: (BuildContext context) => new SelectionControlsDemo(),
    ),
    new GalleryDemo(
      title: 'Sliders',
      subtitle: 'Widgets that select a value by dragging the slider thumb',
      icon: GalleryIcons.sliders,
      category: _kMaterialComponents,
      routeName: SliderDemo.routeName,
      buildRoute: (BuildContext context) => new SliderDemo(),
    ),
    new GalleryDemo(
      title: 'Snackbar',
      subtitle: 'Temporary message that appears at the bottom',
      icon: GalleryIcons.snackbar,
      category: _kMaterialComponents,
      routeName: SnackBarDemo.routeName,
      buildRoute: (BuildContext context) => const SnackBarDemo(),
    ),
    new GalleryDemo(
      title: 'Tabs',
      subtitle: 'Tabs with independently scrollable views',
      icon: GalleryIcons.tabs,
      category: _kMaterialComponents,
      routeName: TabsDemo.routeName,
      buildRoute: (BuildContext context) => new TabsDemo(),
    ),
    new GalleryDemo(
      title: 'Text fields',
      subtitle: 'Single line of editable text and numbers',
      icon: GalleryIcons.text_fields_alt,
      category: _kMaterialComponents,
      routeName: TextFormFieldDemo.routeName,
      buildRoute: (BuildContext context) => const TextFormFieldDemo(),
    ),
    new GalleryDemo(
      title: 'Tooltips',
      subtitle: 'Short message displayed after a long-press',
      icon: GalleryIcons.tooltip,
      category: _kMaterialComponents,
      routeName: TooltipDemo.routeName,
      buildRoute: (BuildContext context) => new TooltipDemo(),
    ),

    // Cupertino Components
    new GalleryDemo(
      title: 'Activity Indicator',
      subtitle: 'Cupertino styled activity indicator',
      icon: GalleryIcons.cupertino_progress,
      category: _kCupertinoComponents,
      routeName: CupertinoProgressIndicatorDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoProgressIndicatorDemo(),
    ),
    new GalleryDemo(
      title: 'Buttons',
      subtitle: 'Cupertino styled buttons',
      icon: GalleryIcons.generic_buttons,
      category: _kCupertinoComponents,
      routeName: CupertinoButtonsDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoButtonsDemo(),
    ),
    new GalleryDemo(
      title: 'Dialogs',
      subtitle: 'Cupertino styled dialogs',
      icon: GalleryIcons.dialogs,
      category: _kCupertinoComponents,
      routeName: CupertinoDialogDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoDialogDemo(),
    ),
    new GalleryDemo(
      title: 'Navigation',
      subtitle: 'Cupertino styled navigation patterns',
      icon: GalleryIcons.bottom_navigation,
      category: _kCupertinoComponents,
      routeName: CupertinoNavigationDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoNavigationDemo(),
    ),
    new GalleryDemo(
      title: 'Pickers',
      subtitle: 'Cupertino styled pickers',
      icon: GalleryIcons.event,
      category: _kCupertinoComponents,
      routeName: CupertinoPickerDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoPickerDemo(),
    ),
    new GalleryDemo(
      title: 'Pull to refresh',
      subtitle: 'Cupertino styled refresh controls',
      icon: GalleryIcons.cupertino_pull_to_refresh,
      category: _kCupertinoComponents,
      routeName: CupertinoRefreshControlDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoRefreshControlDemo(),
    ),
    new GalleryDemo(
      title: 'Sliders',
      subtitle: 'Cupertino styled sliders',
      icon: GalleryIcons.sliders,
      category: _kCupertinoComponents,
      routeName: CupertinoSliderDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoSliderDemo(),
    ),
    new GalleryDemo(
      title: 'Switches',
      subtitle: 'Cupertino styled switches',
      icon: GalleryIcons.cupertino_switch,
      category: _kCupertinoComponents,
      routeName: CupertinoSwitchDemo.routeName,
      buildRoute: (BuildContext context) => new CupertinoSwitchDemo(),
    ),

    // Media
    new GalleryDemo(
      title: 'Animated images',
      subtitle: 'GIF and WebP animations',
      icon: GalleryIcons.animation,
      category: _kMedia,
      routeName: ImagesDemo.routeName,
      buildRoute: (BuildContext context) => new ImagesDemo(),
    ),
    new GalleryDemo(
      title: 'Video',
      subtitle: 'Video playback',
      icon: GalleryIcons.drive_video,
      category: _kMedia,
      routeName: VideoDemo.routeName,
      buildRoute: (BuildContext context) => const VideoDemo(),
    ),
  ];

  // Keep Pesto around for its regression test value. It is not included
  // in (release builds) the performance tests.
  assert(() {
    galleryDemos.insert(0,
      new GalleryDemo(
        title: 'Pesto',
        subtitle: 'Simple recipe browser',
        icon: Icons.adjust,
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

final Set<GalleryDemoCategory> kAllGalleryDemoCategories =
  kAllGalleryDemos.map<GalleryDemoCategory>((GalleryDemo demo) => demo.category).toSet();

final Map<GalleryDemoCategory, List<GalleryDemo>> kGalleryCategoryToDemos =
  new Map<GalleryDemoCategory, List<GalleryDemo>>.fromIterable(
    kAllGalleryDemoCategories,
    value: (dynamic category) {
      return kAllGalleryDemos.where((GalleryDemo demo) => demo.category == category).toList();
    },
  );
