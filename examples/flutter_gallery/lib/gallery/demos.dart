// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/customized/home.dart';
import 'package:flutter_gallery/welcome/home.dart';

import '../demo/all.dart';
import 'icons.dart';

class GalleryDemoCategory {
  const GalleryDemoCategory._({this.name, this.icon, this.routePath});
  @required
  final String name;
  @required
  final IconData icon;
  final String routePath;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
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

const GalleryDemoCategory _kDemos = GalleryDemoCategory._(
  name: 'Studies',
  icon: GalleryIcons.playground,
);

const GalleryDemoCategory _kStyle = GalleryDemoCategory._(
  name: 'Style',
  icon: GalleryIcons.custom_typography,
);

const GalleryDemoCategory _kMaterialPlayground = GalleryDemoCategory._(
  name: 'Material Playground',
  icon: GalleryIcons.category_mdc,
  routePath: MaterialPlaygroundDemo.routeName,
);

const GalleryDemoCategory _kMaterialWidgets = GalleryDemoCategory._(
  name: 'Material Widgets',
  icon: GalleryIcons.category_mdc,
);

const GalleryDemoCategory _kCupertinoPlayground = GalleryDemoCategory._(
  name: 'Cupertino Playground',
  icon: GalleryIcons.phone_iphone,
  routePath: CupertinoPlaygroundDemo.routeName,
);

const GalleryDemoCategory _kCupertinoWidgets = GalleryDemoCategory._(
  name: 'Cupertino Widgets',
  icon: GalleryIcons.phone_iphone,
);

// const GalleryDemoCategory _kMedia = GalleryDemoCategory._(
//   name: 'Media',
//   icon: GalleryIcons.drive_video,
// );

class GalleryDemo {
  const GalleryDemo({
    @required this.title,
    @required this.icon,
    this.subtitle,
    @required this.category,
    @required this.routeName,
    this.documentationUrl,
    @required this.buildRoute,
  })  : assert(title != null),
        assert(category != null),
        assert(routeName != null),
        assert(buildRoute != null);

  final String title;
  final IconData icon;
  final String subtitle;
  final GalleryDemoCategory category;
  final String routeName;
  final WidgetBuilder buildRoute;
  final String documentationUrl;

  @override
  String toString() {
    return '$runtimeType($title $routeName)';
  }
}

List<GalleryDemo> _buildGalleryDemos() {
  final List<GalleryDemo> galleryDemos = <GalleryDemo>[
    // Demos
    GalleryDemo(
      title: 'Shrine',
      subtitle: 'Basic shopping app',
      icon: GalleryIcons.shrine,
      category: _kDemos,
      routeName: ShrineDemo.routeName,
      buildRoute: (BuildContext context) => const ShrineDemo(),
    ),
    GalleryDemo(
      title: 'Contact profile',
      subtitle: 'Address book entry with a flexible appbar',
      icon: GalleryIcons.account_box,
      category: _kDemos,
      routeName: ContactsDemo.routeName,
      buildRoute: (BuildContext context) => ContactsDemo(),
    ),
    GalleryDemo(
      title: 'Animation',
      subtitle: 'Section organizer',
      icon: GalleryIcons.animation,
      category: _kDemos,
      routeName: AnimationDemo.routeName,
      buildRoute: (BuildContext context) => const AnimationDemo(),
    ),
    GalleryDemo(
      title: 'Customized Design',
      subtitle: 'Activity Tracker',
      icon: GalleryIcons.running,
      category: _kDemos,
      routeName: CustomizedDesign.routeName,
      buildRoute: (BuildContext context) => CustomizedDesign(),
    ),
    GalleryDemo(
      title: 'Welcome Screen',
      subtitle: 'Re-Watch the app introduction',
      icon: GalleryIcons.refresh,
      category: _kDemos,
      routeName: Welcome.routeName,
      buildRoute: (BuildContext context) {
        return Welcome(onDismissed: () => Navigator.of(context).pop());
      },
    ),

    // Style
    GalleryDemo(
      title: 'Colors',
      subtitle: 'All of the predefined colors',
      icon: GalleryIcons.colors,
      category: _kStyle,
      routeName: ColorsDemo.routeName,
      buildRoute: (BuildContext context) => ColorsDemo(),
    ),
    GalleryDemo(
      title: 'Typography',
      subtitle: 'All of the predefined text styles',
      icon: GalleryIcons.custom_typography,
      category: _kStyle,
      routeName: TypographyDemo.routeName,
      buildRoute: (BuildContext context) => TypographyDemo(),
    ),

    // Material Components
    GalleryDemo(
      title: 'Backdrop',
      subtitle: 'Select a front layer from back layer',
      icon: GalleryIcons.backdrop,
      category: _kMaterialWidgets,
      routeName: BackdropDemo.routeName,
      buildRoute: (BuildContext context) => BackdropDemo(),
    ),
    GalleryDemo(
      title: 'Bottom app bar',
      subtitle: 'Optional floating action button notch',
      icon: GalleryIcons.bottom_app_bar,
      category: _kMaterialWidgets,
      routeName: BottomAppBarDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/BottomAppBar-class.html',
      buildRoute: (BuildContext context) => BottomAppBarDemo(),
    ),
    GalleryDemo(
      title: 'Bottom navigation',
      subtitle: 'Bottom navigation with cross-fading views',
      icon: GalleryIcons.bottom_navigation,
      category: _kMaterialWidgets,
      routeName: BottomNavigationDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/BottomNavigationBar-class.html',
      buildRoute: (BuildContext context) => BottomNavigationDemo(),
    ),
    GalleryDemo(
      title: 'Bottom sheet: Modal',
      subtitle: 'A dismissable bottom sheet',
      icon: GalleryIcons.bottom_sheets,
      category: _kMaterialWidgets,
      routeName: ModalBottomSheetDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/showModalBottomSheet.html',
      buildRoute: (BuildContext context) => ModalBottomSheetDemo(),
    ),
    GalleryDemo(
      title: 'Bottom sheet: Persistent',
      subtitle: 'A bottom sheet that sticks around',
      icon: GalleryIcons.bottom_sheet_persistent,
      category: _kMaterialWidgets,
      routeName: PersistentBottomSheetDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/ScaffoldState/showBottomSheet.html',
      buildRoute: (BuildContext context) => PersistentBottomSheetDemo(),
    ),
    GalleryDemo(
      title: 'Buttons',
      subtitle: 'Flat, raised, dropdown, and more',
      icon: GalleryIcons.generic_buttons,
      category: _kMaterialWidgets,
      routeName: ButtonsDemo.routeName,
      buildRoute: (BuildContext context) => ButtonsDemo(),
    ),
    GalleryDemo(
      title: 'Buttons: Floating Action Button',
      subtitle: 'FAB with transitions',
      icon: GalleryIcons.buttons,
      category: _kMaterialWidgets,
      routeName: TabsFabDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/FloatingActionButton-class.html',
      buildRoute: (BuildContext context) => TabsFabDemo(),
    ),
    GalleryDemo(
      title: 'Cards',
      subtitle: 'Baseline cards with rounded corners',
      icon: GalleryIcons.cards,
      category: _kMaterialWidgets,
      routeName: CardsDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/Card-class.html',
      buildRoute: (BuildContext context) => CardsDemo(),
    ),
    GalleryDemo(
      title: 'Chips',
      subtitle: 'Labeled with delete buttons and avatars',
      icon: GalleryIcons.chips,
      category: _kMaterialWidgets,
      routeName: ChipDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/Chip-class.html',
      buildRoute: (BuildContext context) => ChipDemo(),
    ),
    GalleryDemo(
      title: 'Data tables',
      subtitle: 'Rows and columns',
      icon: GalleryIcons.data_table,
      category: _kMaterialWidgets,
      routeName: DataTableDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/PaginatedDataTable-class.html',
      buildRoute: (BuildContext context) => DataTableDemo(),
    ),
    GalleryDemo(
      title: 'Dialogs',
      subtitle: 'Simple, alert, and fullscreen',
      icon: GalleryIcons.dialogs,
      category: _kMaterialWidgets,
      routeName: DialogDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/showDialog.html',
      buildRoute: (BuildContext context) => DialogDemo(),
    ),
    GalleryDemo(
      title: 'Elevations',
      subtitle: 'Shadow values on cards',
      // TODO(larche): Change to custom icon for elevations when one exists.
      icon: GalleryIcons.cupertino_progress,
      category: _kMaterialWidgets,
      routeName: ElevationDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/Material/elevation.html',
      buildRoute: (BuildContext context) => ElevationDemo(),
    ),
    GalleryDemo(
      title: 'Expand/collapse list control',
      subtitle: 'A list with one sub-list level',
      icon: GalleryIcons.expand_all,
      category: _kMaterialWidgets,
      routeName: ExpansionTileListDemo.routeName,
      documentationUrl: 'https://docs.flutter.io/flutter/material/ExpansionTile-class.html',
      buildRoute: (BuildContext context) => ExpansionTileListDemo(),
    ),
    GalleryDemo(
      title: 'Expansion panels',
      subtitle: 'List of expanding panels',
      icon: GalleryIcons.expand_all,
      category: _kMaterialWidgets,
      routeName: ExpansionPanelsDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/ExpansionPanel-class.html',
      buildRoute: (BuildContext context) => ExpansionPanelsDemo(),
    ),
    GalleryDemo(
      title: 'Grid',
      subtitle: 'Row and column layout',
      icon: GalleryIcons.grid_on,
      category: _kMaterialWidgets,
      routeName: GridListDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/widgets/GridView-class.html',
      buildRoute: (BuildContext context) => const GridListDemo(),
    ),
    GalleryDemo(
      title: 'Icons',
      subtitle: 'Enabled and disabled icons with opacity',
      icon: GalleryIcons.sentiment_very_satisfied,
      category: _kMaterialWidgets,
      routeName: IconsDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/IconButton-class.html',
      buildRoute: (BuildContext context) => IconsDemo(),
    ),
    GalleryDemo(
      title: 'Lists',
      subtitle: 'Scrolling list layouts',
      icon: GalleryIcons.list_alt,
      category: _kMaterialWidgets,
      routeName: ListDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/ListTile-class.html',
      buildRoute: (BuildContext context) => const ListDemo(),
    ),
    GalleryDemo(
      title: 'Lists: leave-behind list items',
      subtitle: 'List items with hidden actions',
      icon: GalleryIcons.lists_leave_behind,
      category: _kMaterialWidgets,
      routeName: LeaveBehindDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/widgets/Dismissible-class.html',
      buildRoute: (BuildContext context) => const LeaveBehindDemo(),
    ),
    GalleryDemo(
      title: 'Lists: reorderable',
      subtitle: 'Reorderable lists',
      icon: GalleryIcons.list_alt,
      category: _kMaterialWidgets,
      routeName: ReorderableListDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/ReorderableListView-class.html',
      buildRoute: (BuildContext context) => const ReorderableListDemo(),
    ),
    GalleryDemo(
      title: 'Menus',
      subtitle: 'Menu buttons and simple menus',
      icon: GalleryIcons.more_vert,
      category: _kMaterialWidgets,
      routeName: MenuDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/PopupMenuButton-class.html',
      buildRoute: (BuildContext context) => const MenuDemo(),
    ),
    GalleryDemo(
      title: 'Navigation drawer',
      subtitle: 'Navigation drawer with standard header',
      icon: GalleryIcons.menu,
      category: _kMaterialWidgets,
      routeName: DrawerDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/Drawer-class.html',
      buildRoute: (BuildContext context) => DrawerDemo(),
    ),
    GalleryDemo(
      title: 'Pagination',
      subtitle: 'PageView with indicator',
      icon: GalleryIcons.page_control,
      category: _kMaterialWidgets,
      routeName: PageSelectorDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/TabBarView-class.html',
      buildRoute: (BuildContext context) => PageSelectorDemo(),
    ),
    GalleryDemo(
      title: 'Pickers',
      subtitle: 'Date and time selection widgets',
      icon: GalleryIcons.event,
      category: _kMaterialWidgets,
      routeName: DateAndTimePickerDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/showDatePicker.html',
      buildRoute: (BuildContext context) => DateAndTimePickerDemo(),
    ),
    GalleryDemo(
      title: 'Progress indicators',
      subtitle: 'Linear, circular, indeterminate',
      icon: GalleryIcons.progress_activity,
      category: _kMaterialWidgets,
      routeName: ProgressIndicatorDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/LinearProgressIndicator-class.html',
      buildRoute: (BuildContext context) => ProgressIndicatorDemo(),
    ),
    GalleryDemo(
      title: 'Pull to refresh',
      subtitle: 'Refresh indicators',
      icon: GalleryIcons.refresh,
      category: _kMaterialWidgets,
      routeName: OverscrollDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/RefreshIndicator-class.html',
      buildRoute: (BuildContext context) => const OverscrollDemo(),
    ),
    GalleryDemo(
      title: 'Search',
      subtitle: 'Expandable search',
      icon: Icons.search,
      category: _kMaterialWidgets,
      routeName: SearchDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/showSearch.html',
      buildRoute: (BuildContext context) => SearchDemo(),
    ),
    GalleryDemo(
      title: 'Selection controls',
      subtitle: 'Checkboxes, radio buttons, and switches',
      icon: GalleryIcons.check_box,
      category: _kMaterialWidgets,
      routeName: SelectionControlsDemo.routeName,
      buildRoute: (BuildContext context) => SelectionControlsDemo(),
    ),
    GalleryDemo(
      title: 'Sliders',
      subtitle: 'Widgets for selecting a value by swiping',
      icon: GalleryIcons.sliders,
      category: _kMaterialWidgets,
      routeName: SliderDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/Slider-class.html',
      buildRoute: (BuildContext context) => SliderDemo(),
    ),
    GalleryDemo(
      title: 'Snackbar',
      subtitle: 'Temporary messaging',
      icon: GalleryIcons.snackbar,
      category: _kMaterialWidgets,
      routeName: SnackBarDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/ScaffoldState/showSnackBar.html',
      buildRoute: (BuildContext context) => const SnackBarDemo(),
    ),
    GalleryDemo(
      title: 'Tabs',
      subtitle: 'Tabs with independently scrollable views',
      icon: GalleryIcons.tabs,
      category: _kMaterialWidgets,
      routeName: TabsDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/TabBarView-class.html',
      buildRoute: (BuildContext context) => TabsDemo(),
    ),
    GalleryDemo(
      title: 'Tabs: Scrolling',
      subtitle: 'Tab bar that scrolls',
      category: _kMaterialWidgets,
      icon: GalleryIcons.tabs,
      routeName: ScrollableTabsDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/TabBar-class.html',
      buildRoute: (BuildContext context) => ScrollableTabsDemo(),
    ),
    GalleryDemo(
      title: 'Text fields',
      subtitle: 'Single line of editable text and numbers',
      icon: GalleryIcons.text_fields_alt,
      category: _kMaterialWidgets,
      routeName: TextFormFieldDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/TextFormField-class.html',
      buildRoute: (BuildContext context) => const TextFormFieldDemo(),
    ),
    GalleryDemo(
      title: 'Tooltips',
      subtitle: 'Short message displayed on long-press',
      icon: GalleryIcons.tooltip,
      category: _kMaterialWidgets,
      routeName: TooltipDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/material/Tooltip-class.html',
      buildRoute: (BuildContext context) => TooltipDemo(),
    ),

    // Cupertino Components
    GalleryDemo(
      title: 'Activity Indicator',
      icon: GalleryIcons.cupertino_progress,
      category: _kCupertinoWidgets,
      routeName: CupertinoProgressIndicatorDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/cupertino/CupertinoActivityIndicator-class.html',
      buildRoute: (BuildContext context) => CupertinoProgressIndicatorDemo(),
    ),
    GalleryDemo(
      title: 'Alerts',
      icon: GalleryIcons.dialogs,
      category: _kCupertinoWidgets,
      routeName: CupertinoAlertDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/cupertino/showCupertinoDialog.html',
      buildRoute: (BuildContext context) => CupertinoAlertDemo(),
    ),
    GalleryDemo(
      title: 'Buttons',
      icon: GalleryIcons.generic_buttons,
      category: _kCupertinoWidgets,
      routeName: CupertinoButtonsDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/cupertino/CupertinoButton-class.html',
      buildRoute: (BuildContext context) => CupertinoButtonsDemo(),
    ),
    GalleryDemo(
      title: 'Navigation',
      icon: GalleryIcons.bottom_navigation,
      category: _kCupertinoWidgets,
      routeName: CupertinoNavigationDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/cupertino/CupertinoTabScaffold-class.html',
      buildRoute: (BuildContext context) => CupertinoNavigationDemo(),
    ),
    GalleryDemo(
      title: 'Pickers',
      icon: GalleryIcons.event,
      category: _kCupertinoWidgets,
      routeName: CupertinoPickerDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/cupertino/CupertinoPicker-class.html',
      buildRoute: (BuildContext context) => CupertinoPickerDemo(),
    ),
    GalleryDemo(
      title: 'Pull to refresh',
      icon: GalleryIcons.cupertino_pull_to_refresh,
      category: _kCupertinoWidgets,
      routeName: CupertinoRefreshControlDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/cupertino/CupertinoSliverRefreshControl-class.html',
      buildRoute: (BuildContext context) => CupertinoRefreshControlDemo(),
    ),
    GalleryDemo(
      title: 'Segmented Control',
      icon: GalleryIcons.tabs,
      category: _kCupertinoWidgets,
      routeName: CupertinoSegmentedControlDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/cupertino/CupertinoSegmentedControl-class.html',
      buildRoute: (BuildContext context) => CupertinoSegmentedControlDemo(),
    ),
    GalleryDemo(
      title: 'Sliders',
      icon: GalleryIcons.sliders,
      category: _kCupertinoWidgets,
      routeName: CupertinoSliderDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/cupertino/CupertinoSlider-class.html',
      buildRoute: (BuildContext context) => CupertinoSliderDemo(),
    ),
    GalleryDemo(
      title: 'Switches',
      icon: GalleryIcons.cupertino_switch,
      category: _kCupertinoWidgets,
      routeName: CupertinoSwitchDemo.routeName,
      documentationUrl:
          'https://docs.flutter.io/flutter/cupertino/CupertinoSwitch-class.html',
      buildRoute: (BuildContext context) => CupertinoSwitchDemo(),
    ),
    GalleryDemo(
      title: 'Text Fields',
      icon: GalleryIcons.text_fields_alt,
      category: _kCupertinoWidgets,
      routeName: CupertinoTextFieldDemo.routeName,
      buildRoute: (BuildContext context) => CupertinoTextFieldDemo(),
    ),
    GalleryDemo(
      title: 'Animated images',
      subtitle: 'GIF and WebP animations',
      icon: GalleryIcons.animation,
      category: _kStyle,
      routeName: ImagesDemo.routeName,
      buildRoute: (BuildContext context) => ImagesDemo(),
    ),
    GalleryDemo(
      title: 'Video',
      subtitle: 'Video playback',
      icon: GalleryIcons.drive_video,
      category: _kStyle,
      routeName: VideoDemo.routeName,
      buildRoute: (BuildContext context) => const VideoDemo(),
    ),
  ];

  // Keep Pesto around for its regression test value. It is not included
  // in (release builds) the performance tests.
  assert(() {
    galleryDemos.insert(
      0,
      GalleryDemo(
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

Set<GalleryDemoCategory> _buildCategories() {
  final Set<GalleryDemoCategory> categories = Set<GalleryDemoCategory>();
  if (Platform.isIOS) {
    categories.addAll(<GalleryDemoCategory>[
      _kCupertinoPlayground,
      _kCupertinoWidgets,
      _kMaterialPlayground,
      _kMaterialWidgets
    ]);
  } else {
    categories.addAll(<GalleryDemoCategory>[
      _kMaterialPlayground,
      _kMaterialWidgets,
      _kCupertinoPlayground,
      _kCupertinoWidgets
    ]);
  }
  categories.addAll(<GalleryDemoCategory>[_kDemos, _kStyle,]);
  return categories;
}

final List<GalleryDemo> kAllGalleryDemos = _buildGalleryDemos();
final Set<GalleryDemoCategory> kAllGalleryDemoCategories = _buildCategories();

final Map<GalleryDemoCategory, List<GalleryDemo>> kGalleryCategoryToDemos =
    Map<GalleryDemoCategory, List<GalleryDemo>>.fromIterable(
  kAllGalleryDemoCategories,
  value: (dynamic category) {
    return kAllGalleryDemos
        .where((GalleryDemo demo) => demo.category == category)
        .toList();
  },
);

final Map<String, String> kDemoDocumentationUrl =
    Map<String, String>.fromIterable(
  kAllGalleryDemos.where((GalleryDemo demo) => demo.documentationUrl != null),
  key: (dynamic demo) => demo.routeName,
  value: (dynamic demo) => demo.documentationUrl,
);
