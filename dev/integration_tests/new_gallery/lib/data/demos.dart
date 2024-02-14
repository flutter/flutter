// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations_en.dart'
    show GalleryLocalizationsEn;
import 'package:gallery/codeviewer/code_displayer.dart';
import 'package:gallery/codeviewer/code_segments.dart';
import 'package:gallery/data/icons.dart';
import 'package:gallery/deferred_widget.dart';
import 'package:gallery/demos/cupertino/cupertino_demos.dart'
    deferred as cupertino_demos;
import 'package:gallery/demos/cupertino/demo_types.dart';
import 'package:gallery/demos/material/material_demo_types.dart';
import 'package:gallery/demos/material/material_demos.dart'
    deferred as material_demos;
import 'package:gallery/demos/reference/colors_demo.dart'
    deferred as colors_demo;
import 'package:gallery/demos/reference/motion_demo_container_transition.dart'
    deferred as motion_demo_container;
import 'package:gallery/demos/reference/motion_demo_fade_scale_transition.dart';
import 'package:gallery/demos/reference/motion_demo_fade_through_transition.dart';
import 'package:gallery/demos/reference/motion_demo_shared_x_axis_transition.dart';
import 'package:gallery/demos/reference/motion_demo_shared_y_axis_transition.dart';
import 'package:gallery/demos/reference/motion_demo_shared_z_axis_transition.dart';
import 'package:gallery/demos/reference/transformations_demo.dart'
    deferred as transformations_demo;
import 'package:gallery/demos/reference/two_pane_demo.dart'
    deferred as twopane_demo;
import 'package:gallery/demos/reference/typography_demo.dart'
    deferred as typography;

const _docsBaseUrl = 'https://api.flutter.dev/flutter';
const _docsAnimationsUrl =
    'https://pub.dev/documentation/animations/latest/animations';

enum GalleryDemoCategory {
  study,
  material,
  cupertino,
  other;

  @override
  String toString() {
    return name.toUpperCase();
  }

  String? displayTitle(GalleryLocalizations localizations) {
    switch (this) {
      case GalleryDemoCategory.other:
        return localizations.homeCategoryReference;
      case GalleryDemoCategory.material:
      case GalleryDemoCategory.cupertino:
        return toString();
      case GalleryDemoCategory.study:
    }
    return null;
  }
}

class GalleryDemo {
  const GalleryDemo({
    required this.title,
    required this.category,
    required this.subtitle,
    // This parameter is required for studies.
    this.studyId,
    // Parameters below are required for non-study demos.
    this.slug,
    this.icon,
    this.configurations = const [],
  })  : assert(category == GalleryDemoCategory.study ||
            (slug != null && icon != null)),
        assert(slug != null || studyId != null);

  final String title;
  final GalleryDemoCategory category;
  final String subtitle;
  final String? studyId;
  final String? slug;
  final IconData? icon;
  final List<GalleryDemoConfiguration> configurations;

  String get describe => '${slug ?? studyId}@${category.name}';
}

class GalleryDemoConfiguration {
  const GalleryDemoConfiguration({
    required this.title,
    required this.description,
    required this.documentationUrl,
    required this.buildRoute,
    required this.code,
  });

  final String title;
  final String description;
  final String documentationUrl;
  final WidgetBuilder buildRoute;
  final CodeDisplayer code;
}

/// Awaits all deferred libraries for tests.
Future<void> pumpDeferredLibraries() {
  final futures = <Future<void>>[
    DeferredWidget.preload(cupertino_demos.loadLibrary),
    DeferredWidget.preload(material_demos.loadLibrary),
    DeferredWidget.preload(motion_demo_container.loadLibrary),
    DeferredWidget.preload(colors_demo.loadLibrary),
    DeferredWidget.preload(transformations_demo.loadLibrary),
    DeferredWidget.preload(typography.loadLibrary),
  ];
  return Future.wait(futures);
}

class Demos {
  static Map<String?, GalleryDemo> asSlugToDemoMap(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    return LinkedHashMap<String?, GalleryDemo>.fromIterable(
      all(localizations),
      key: (dynamic demo) => demo.slug as String?,
    );
  }

  static List<GalleryDemo> all(GalleryLocalizations localizations) =>
      studies(localizations).values.toList() +
      materialDemos(localizations) +
      cupertinoDemos(localizations) +
      otherDemos(localizations);

  static List<String> allDescriptions() =>
      all(GalleryLocalizationsEn()).map((demo) => demo.describe).toList();

  static Map<String, GalleryDemo> studies(GalleryLocalizations localizations) {
    return <String, GalleryDemo>{
      'shrine': GalleryDemo(
        title: 'Shrine',
        subtitle: localizations.shrineDescription,
        category: GalleryDemoCategory.study,
        studyId: 'shrine',
      ),
      'rally': GalleryDemo(
        title: 'Rally',
        subtitle: localizations.rallyDescription,
        category: GalleryDemoCategory.study,
        studyId: 'rally',
      ),
      'crane': GalleryDemo(
        title: 'Crane',
        subtitle: localizations.craneDescription,
        category: GalleryDemoCategory.study,
        studyId: 'crane',
      ),
      'fortnightly': GalleryDemo(
        title: 'Fortnightly',
        subtitle: localizations.fortnightlyDescription,
        category: GalleryDemoCategory.study,
        studyId: 'fortnightly',
      ),
      'reply': GalleryDemo(
        title: 'Reply',
        subtitle: localizations.replyDescription,
        category: GalleryDemoCategory.study,
        studyId: 'reply',
      ),
      'starterApp': GalleryDemo(
        title: localizations.starterAppTitle,
        subtitle: localizations.starterAppDescription,
        category: GalleryDemoCategory.study,
        studyId: 'starter',
      ),
    };
  }

  static List<GalleryDemo> materialDemos(GalleryLocalizations localizations) {
    LibraryLoader materialDemosLibrary = material_demos.loadLibrary;
    return [
      GalleryDemo(
        title: localizations.demoAppBarTitle,
        icon: GalleryIcons.appbar,
        slug: 'app-bar',
        subtitle: localizations.demoAppBarSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoAppBarTitle,
            description: localizations.demoAppBarDescription,
            documentationUrl: '$_docsBaseUrl/material/AppBar-class.html',
            buildRoute: (_) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.AppBarDemo(),
            ),
            code: CodeSegments.appbarDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoBannerTitle,
        icon: GalleryIcons.listsLeaveBehind,
        slug: 'banner',
        subtitle: localizations.demoBannerSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoBannerTitle,
            description: localizations.demoBannerDescription,
            documentationUrl:
                '$_docsBaseUrl/material/MaterialBanner-class.html',
            buildRoute: (_) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.BannerDemo(),
            ),
            code: CodeSegments.bannerDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoBottomAppBarTitle,
        icon: GalleryIcons.bottomAppBar,
        slug: 'bottom-app-bar',
        subtitle: localizations.demoBottomAppBarSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoBottomAppBarTitle,
            description: localizations.demoBottomAppBarDescription,
            documentationUrl: '$_docsBaseUrl/material/BottomAppBar-class.html',
            buildRoute: (_) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.BottomAppBarDemo(),
            ),
            code: CodeSegments.bottomAppBarDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoBottomNavigationTitle,
        icon: GalleryIcons.bottomNavigation,
        slug: 'bottom-navigation',
        subtitle: localizations.demoBottomNavigationSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoBottomNavigationPersistentLabels,
            description: localizations.demoBottomNavigationDescription,
            documentationUrl:
                '$_docsBaseUrl/material/BottomNavigationBar-class.html',
            buildRoute: (_) => DeferredWidget(
                materialDemosLibrary,
                () => material_demos.BottomNavigationDemo(
                      type: BottomNavigationDemoType.withLabels,
                      restorationId: 'bottom_navigation_labels_demo',
                    )),
            code: CodeSegments.bottomNavigationDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoBottomNavigationSelectedLabel,
            description: localizations.demoBottomNavigationDescription,
            documentationUrl:
                '$_docsBaseUrl/material/BottomNavigationBar-class.html',
            buildRoute: (_) => DeferredWidget(
                materialDemosLibrary,
                () => material_demos.BottomNavigationDemo(
                      type: BottomNavigationDemoType.withoutLabels,
                      restorationId: 'bottom_navigation_without_labels_demo',
                    )),
            code: CodeSegments.bottomNavigationDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoBottomSheetTitle,
        icon: GalleryIcons.bottomSheets,
        slug: 'bottom-sheet',
        subtitle: localizations.demoBottomSheetSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoBottomSheetPersistentTitle,
            description: localizations.demoBottomSheetPersistentDescription,
            documentationUrl: '$_docsBaseUrl/material/BottomSheet-class.html',
            buildRoute: (_) => DeferredWidget(
                materialDemosLibrary,
                () => material_demos.BottomSheetDemo(
                      type: BottomSheetDemoType.persistent,
                    )),
            code: CodeSegments.bottomSheetDemoPersistent,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoBottomSheetModalTitle,
            description: localizations.demoBottomSheetModalDescription,
            documentationUrl: '$_docsBaseUrl/material/BottomSheet-class.html',
            buildRoute: (_) => DeferredWidget(
                materialDemosLibrary,
                () => material_demos.BottomSheetDemo(
                      type: BottomSheetDemoType.modal,
                    )),
            code: CodeSegments.bottomSheetDemoModal,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoButtonTitle,
        icon: GalleryIcons.genericButtons,
        slug: 'button',
        subtitle: localizations.demoButtonSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoTextButtonTitle,
            description: localizations.demoTextButtonDescription,
            documentationUrl: '$_docsBaseUrl/material/TextButton-class.html',
            buildRoute: (_) => DeferredWidget(materialDemosLibrary,
                () => material_demos.ButtonDemo(type: ButtonDemoType.text)),
            code: CodeSegments.buttonDemoText,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoElevatedButtonTitle,
            description: localizations.demoElevatedButtonDescription,
            documentationUrl:
                '$_docsBaseUrl/material/ElevatedButton-class.html',
            buildRoute: (_) => DeferredWidget(materialDemosLibrary,
                () => material_demos.ButtonDemo(type: ButtonDemoType.elevated)),
            code: CodeSegments.buttonDemoElevated,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoOutlinedButtonTitle,
            description: localizations.demoOutlinedButtonDescription,
            documentationUrl:
                '$_docsBaseUrl/material/OutlinedButton-class.html',
            buildRoute: (_) => DeferredWidget(materialDemosLibrary,
                () => material_demos.ButtonDemo(type: ButtonDemoType.outlined)),
            code: CodeSegments.buttonDemoOutlined,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoToggleButtonTitle,
            description: localizations.demoToggleButtonDescription,
            documentationUrl: '$_docsBaseUrl/material/ToggleButtons-class.html',
            buildRoute: (_) => DeferredWidget(materialDemosLibrary,
                () => material_demos.ButtonDemo(type: ButtonDemoType.toggle)),
            code: CodeSegments.buttonDemoToggle,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoFloatingButtonTitle,
            description: localizations.demoFloatingButtonDescription,
            documentationUrl:
                '$_docsBaseUrl/material/FloatingActionButton-class.html',
            buildRoute: (_) => DeferredWidget(materialDemosLibrary,
                () => material_demos.ButtonDemo(type: ButtonDemoType.floating)),
            code: CodeSegments.buttonDemoFloating,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoCardTitle,
        icon: GalleryIcons.cards,
        slug: 'card',
        subtitle: localizations.demoCardSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCardTitle,
            description: localizations.demoCardDescription,
            documentationUrl: '$_docsBaseUrl/material/Card-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.CardsDemo(),
            ),
            code: CodeSegments.cardsDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoChipTitle,
        icon: GalleryIcons.chips,
        slug: 'chip',
        subtitle: localizations.demoChipSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoActionChipTitle,
            description: localizations.demoActionChipDescription,
            documentationUrl: '$_docsBaseUrl/material/ActionChip-class.html',
            buildRoute: (context) => DeferredWidget(materialDemosLibrary,
                () => material_demos.ChipDemo(type: ChipDemoType.action)),
            code: CodeSegments.chipDemoAction,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoChoiceChipTitle,
            description: localizations.demoChoiceChipDescription,
            documentationUrl: '$_docsBaseUrl/material/ChoiceChip-class.html',
            buildRoute: (context) => DeferredWidget(materialDemosLibrary,
                () => material_demos.ChipDemo(type: ChipDemoType.choice)),
            code: CodeSegments.chipDemoChoice,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoFilterChipTitle,
            description: localizations.demoFilterChipDescription,
            documentationUrl: '$_docsBaseUrl/material/FilterChip-class.html',
            buildRoute: (context) => DeferredWidget(materialDemosLibrary,
                () => material_demos.ChipDemo(type: ChipDemoType.filter)),
            code: CodeSegments.chipDemoFilter,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoInputChipTitle,
            description: localizations.demoInputChipDescription,
            documentationUrl: '$_docsBaseUrl/material/InputChip-class.html',
            buildRoute: (context) => DeferredWidget(materialDemosLibrary,
                () => material_demos.ChipDemo(type: ChipDemoType.input)),
            code: CodeSegments.chipDemoInput,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoDataTableTitle,
        icon: GalleryIcons.dataTable,
        slug: 'data-table',
        subtitle: localizations.demoDataTableSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoDataTableTitle,
            description: localizations.demoDataTableDescription,
            documentationUrl: '$_docsBaseUrl/material/DataTable-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.DataTableDemo(),
            ),
            code: CodeSegments.dataTableDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoDialogTitle,
        icon: GalleryIcons.dialogs,
        slug: 'dialog',
        subtitle: localizations.demoDialogSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoAlertDialogTitle,
            description: localizations.demoAlertDialogDescription,
            documentationUrl: '$_docsBaseUrl/material/AlertDialog-class.html',
            buildRoute: (context) => DeferredWidget(materialDemosLibrary,
                () => material_demos.DialogDemo(type: DialogDemoType.alert)),
            code: CodeSegments.dialogDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoAlertTitleDialogTitle,
            description: localizations.demoAlertDialogDescription,
            documentationUrl: '$_docsBaseUrl/material/AlertDialog-class.html',
            buildRoute: (context) => DeferredWidget(
                materialDemosLibrary,
                () =>
                    material_demos.DialogDemo(type: DialogDemoType.alertTitle)),
            code: CodeSegments.dialogDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoSimpleDialogTitle,
            description: localizations.demoSimpleDialogDescription,
            documentationUrl: '$_docsBaseUrl/material/SimpleDialog-class.html',
            buildRoute: (context) => DeferredWidget(materialDemosLibrary,
                () => material_demos.DialogDemo(type: DialogDemoType.simple)),
            code: CodeSegments.dialogDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoFullscreenDialogTitle,
            description: localizations.demoFullscreenDialogDescription,
            documentationUrl:
                '$_docsBaseUrl/widgets/PageRoute/fullscreenDialog.html',
            buildRoute: (context) => DeferredWidget(
                materialDemosLibrary,
                () =>
                    material_demos.DialogDemo(type: DialogDemoType.fullscreen)),
            code: CodeSegments.dialogDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoDividerTitle,
        icon: GalleryIcons.divider,
        slug: 'divider',
        subtitle: localizations.demoDividerSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoDividerTitle,
            description: localizations.demoDividerDescription,
            documentationUrl: '$_docsBaseUrl/material/Divider-class.html',
            buildRoute: (_) => DeferredWidget(
                materialDemosLibrary,
                () => material_demos.DividerDemo(
                    type: DividerDemoType.horizontal)),
            code: CodeSegments.dividerDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoVerticalDividerTitle,
            description: localizations.demoDividerDescription,
            documentationUrl:
                '$_docsBaseUrl/material/VerticalDivider-class.html',
            buildRoute: (_) => DeferredWidget(
                materialDemosLibrary,
                () =>
                    material_demos.DividerDemo(type: DividerDemoType.vertical)),
            code: CodeSegments.verticalDividerDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoGridListsTitle,
        icon: GalleryIcons.gridOn,
        slug: 'grid-lists',
        subtitle: localizations.demoGridListsSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoGridListsImageOnlyTitle,
            description: localizations.demoGridListsDescription,
            documentationUrl: '$_docsBaseUrl/widgets/GridView-class.html',
            buildRoute: (context) => DeferredWidget(
                materialDemosLibrary,
                () => material_demos.GridListDemo(
                    type: GridListDemoType.imageOnly)),
            code: CodeSegments.gridListsDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoGridListsHeaderTitle,
            description: localizations.demoGridListsDescription,
            documentationUrl: '$_docsBaseUrl/widgets/GridView-class.html',
            buildRoute: (context) => DeferredWidget(
                materialDemosLibrary,
                () =>
                    material_demos.GridListDemo(type: GridListDemoType.header)),
            code: CodeSegments.gridListsDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoGridListsFooterTitle,
            description: localizations.demoGridListsDescription,
            documentationUrl: '$_docsBaseUrl/widgets/GridView-class.html',
            buildRoute: (context) => DeferredWidget(
                materialDemosLibrary,
                () =>
                    material_demos.GridListDemo(type: GridListDemoType.footer)),
            code: CodeSegments.gridListsDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoListsTitle,
        icon: GalleryIcons.listAlt,
        slug: 'lists',
        subtitle: localizations.demoListsSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoOneLineListsTitle,
            description: localizations.demoListsDescription,
            documentationUrl: '$_docsBaseUrl/material/ListTile-class.html',
            buildRoute: (context) => DeferredWidget(materialDemosLibrary,
                () => material_demos.ListDemo(type: ListDemoType.oneLine)),
            code: CodeSegments.listDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoTwoLineListsTitle,
            description: localizations.demoListsDescription,
            documentationUrl: '$_docsBaseUrl/material/ListTile-class.html',
            buildRoute: (context) => DeferredWidget(materialDemosLibrary,
                () => material_demos.ListDemo(type: ListDemoType.twoLine)),
            code: CodeSegments.listDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoMenuTitle,
        icon: GalleryIcons.moreVert,
        slug: 'menu',
        subtitle: localizations.demoMenuSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoContextMenuTitle,
            description: localizations.demoMenuDescription,
            documentationUrl: '$_docsBaseUrl/material/PopupMenuItem-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.MenuDemo(type: MenuDemoType.contextMenu),
            ),
            code: CodeSegments.menuDemoContext,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoSectionedMenuTitle,
            description: localizations.demoMenuDescription,
            documentationUrl: '$_docsBaseUrl/material/PopupMenuItem-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.MenuDemo(type: MenuDemoType.sectionedMenu),
            ),
            code: CodeSegments.menuDemoSectioned,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoChecklistMenuTitle,
            description: localizations.demoMenuDescription,
            documentationUrl:
                '$_docsBaseUrl/material/CheckedPopupMenuItem-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.MenuDemo(type: MenuDemoType.checklistMenu),
            ),
            code: CodeSegments.menuDemoChecklist,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoSimpleMenuTitle,
            description: localizations.demoMenuDescription,
            documentationUrl: '$_docsBaseUrl/material/PopupMenuItem-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.MenuDemo(type: MenuDemoType.simpleMenu),
            ),
            code: CodeSegments.menuDemoSimple,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoNavigationDrawerTitle,
        icon: GalleryIcons.menu,
        slug: 'nav_drawer',
        subtitle: localizations.demoNavigationDrawerSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoNavigationDrawerTitle,
            description: localizations.demoNavigationDrawerDescription,
            documentationUrl: '$_docsBaseUrl/material/Drawer-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.NavDrawerDemo(),
            ),
            code: CodeSegments.navDrawerDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoNavigationRailTitle,
        icon: GalleryIcons.navigationRail,
        slug: 'nav_rail',
        subtitle: localizations.demoNavigationRailSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoNavigationRailTitle,
            description: localizations.demoNavigationRailDescription,
            documentationUrl:
                '$_docsBaseUrl/material/NavigationRail-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.NavRailDemo(),
            ),
            code: CodeSegments.navRailDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoPickersTitle,
        icon: GalleryIcons.event,
        slug: 'pickers',
        subtitle: localizations.demoPickersSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoDatePickerTitle,
            description: localizations.demoDatePickerDescription,
            documentationUrl: '$_docsBaseUrl/material/showDatePicker.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.PickerDemo(type: PickerDemoType.date),
            ),
            code: CodeSegments.pickerDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoTimePickerTitle,
            description: localizations.demoTimePickerDescription,
            documentationUrl: '$_docsBaseUrl/material/showTimePicker.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.PickerDemo(type: PickerDemoType.time),
            ),
            code: CodeSegments.pickerDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoDateRangePickerTitle,
            description: localizations.demoDateRangePickerDescription,
            documentationUrl: '$_docsBaseUrl/material/showDateRangePicker.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.PickerDemo(type: PickerDemoType.range),
            ),
            code: CodeSegments.pickerDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoProgressIndicatorTitle,
        icon: GalleryIcons.progressActivity,
        slug: 'progress-indicator',
        subtitle: localizations.demoProgressIndicatorSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCircularProgressIndicatorTitle,
            description: localizations.demoCircularProgressIndicatorDescription,
            documentationUrl:
                '$_docsBaseUrl/material/CircularProgressIndicator-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.ProgressIndicatorDemo(
                type: ProgressIndicatorDemoType.circular,
              ),
            ),
            code: CodeSegments.progressIndicatorsDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoLinearProgressIndicatorTitle,
            description: localizations.demoLinearProgressIndicatorDescription,
            documentationUrl:
                '$_docsBaseUrl/material/LinearProgressIndicator-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.ProgressIndicatorDemo(
                type: ProgressIndicatorDemoType.linear,
              ),
            ),
            code: CodeSegments.progressIndicatorsDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoSelectionControlsTitle,
        icon: GalleryIcons.checkBox,
        slug: 'selection-controls',
        subtitle: localizations.demoSelectionControlsSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoSelectionControlsCheckboxTitle,
            description: localizations.demoSelectionControlsCheckboxDescription,
            documentationUrl: '$_docsBaseUrl/material/Checkbox-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.SelectionControlsDemo(
                type: SelectionControlsDemoType.checkbox,
              ),
            ),
            code: CodeSegments.selectionControlsDemoCheckbox,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoSelectionControlsRadioTitle,
            description: localizations.demoSelectionControlsRadioDescription,
            documentationUrl: '$_docsBaseUrl/material/Radio-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.SelectionControlsDemo(
                type: SelectionControlsDemoType.radio,
              ),
            ),
            code: CodeSegments.selectionControlsDemoRadio,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoSelectionControlsSwitchTitle,
            description: localizations.demoSelectionControlsSwitchDescription,
            documentationUrl: '$_docsBaseUrl/material/Switch-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.SelectionControlsDemo(
                type: SelectionControlsDemoType.switches,
              ),
            ),
            code: CodeSegments.selectionControlsDemoSwitches,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoSlidersTitle,
        icon: GalleryIcons.sliders,
        slug: 'sliders',
        subtitle: localizations.demoSlidersSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoSlidersTitle,
            description: localizations.demoSlidersDescription,
            documentationUrl: '$_docsBaseUrl/material/Slider-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.SlidersDemo(type: SlidersDemoType.sliders),
            ),
            code: CodeSegments.slidersDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoRangeSlidersTitle,
            description: localizations.demoRangeSlidersDescription,
            documentationUrl: '$_docsBaseUrl/material/RangeSlider-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.SlidersDemo(
                  type: SlidersDemoType.rangeSliders),
            ),
            code: CodeSegments.rangeSlidersDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoCustomSlidersTitle,
            description: localizations.demoCustomSlidersDescription,
            documentationUrl: '$_docsBaseUrl/material/SliderTheme-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.SlidersDemo(
                  type: SlidersDemoType.customSliders),
            ),
            code: CodeSegments.customSlidersDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoSnackbarsTitle,
        icon: GalleryIcons.snackbar,
        slug: 'snackbars',
        subtitle: localizations.demoSnackbarsSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoSnackbarsTitle,
            description: localizations.demoSnackbarsDescription,
            documentationUrl: '$_docsBaseUrl/material/SnackBar-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.SnackbarsDemo(),
            ),
            code: CodeSegments.snackbarsDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoTabsTitle,
        icon: GalleryIcons.tabs,
        slug: 'tabs',
        subtitle: localizations.demoTabsSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoTabsScrollingTitle,
            description: localizations.demoTabsDescription,
            documentationUrl: '$_docsBaseUrl/material/TabBar-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.TabsDemo(type: TabsDemoType.scrollable),
            ),
            code: CodeSegments.tabsScrollableDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoTabsNonScrollingTitle,
            description: localizations.demoTabsDescription,
            documentationUrl: '$_docsBaseUrl/material/TabBar-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.TabsDemo(type: TabsDemoType.nonScrollable),
            ),
            code: CodeSegments.tabsNonScrollableDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoTextFieldTitle,
        icon: GalleryIcons.textFieldsAlt,
        slug: 'text-field',
        subtitle: localizations.demoTextFieldSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoTextFieldTitle,
            description: localizations.demoTextFieldDescription,
            documentationUrl: '$_docsBaseUrl/material/TextField-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.TextFieldDemo(),
            ),
            code: CodeSegments.textFieldDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
      GalleryDemo(
        title: localizations.demoTooltipTitle,
        icon: GalleryIcons.tooltip,
        slug: 'tooltip',
        subtitle: localizations.demoTooltipSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoTooltipTitle,
            description: localizations.demoTooltipDescription,
            documentationUrl: '$_docsBaseUrl/material/Tooltip-class.html',
            buildRoute: (context) => DeferredWidget(
              materialDemosLibrary,
              () => material_demos.TooltipDemo(),
            ),
            code: CodeSegments.tooltipDemo,
          ),
        ],
        category: GalleryDemoCategory.material,
      ),
    ];
  }

  static List<GalleryDemo> cupertinoDemos(GalleryLocalizations localizations) {
    LibraryLoader cupertinoLoader = cupertino_demos.loadLibrary;
    return [
      GalleryDemo(
        title: localizations.demoCupertinoActivityIndicatorTitle,
        icon: GalleryIcons.cupertinoProgress,
        slug: 'cupertino-activity-indicator',
        subtitle: localizations.demoCupertinoActivityIndicatorSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoActivityIndicatorTitle,
            description:
                localizations.demoCupertinoActivityIndicatorDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoActivityIndicator-class.html',
            buildRoute: (_) => DeferredWidget(
              cupertinoLoader,
              () => cupertino_demos.CupertinoProgressIndicatorDemo(),
            ),
            code: CodeSegments.cupertinoActivityIndicatorDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoCupertinoAlertsTitle,
        icon: GalleryIcons.dialogs,
        slug: 'cupertino-alerts',
        subtitle: localizations.demoCupertinoAlertsSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoAlertTitle,
            description: localizations.demoCupertinoAlertDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoAlertDialog-class.html',
            buildRoute: (_) => DeferredWidget(
                cupertinoLoader,
                () => cupertino_demos.CupertinoAlertDemo(
                    type: AlertDemoType.alert)),
            code: CodeSegments.cupertinoAlertDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoAlertWithTitleTitle,
            description: localizations.demoCupertinoAlertDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoAlertDialog-class.html',
            buildRoute: (_) => DeferredWidget(
                cupertinoLoader,
                () => cupertino_demos.CupertinoAlertDemo(
                    type: AlertDemoType.alertTitle)),
            code: CodeSegments.cupertinoAlertDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoAlertButtonsTitle,
            description: localizations.demoCupertinoAlertDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoAlertDialog-class.html',
            buildRoute: (_) => DeferredWidget(
                cupertinoLoader,
                () => cupertino_demos.CupertinoAlertDemo(
                    type: AlertDemoType.alertButtons)),
            code: CodeSegments.cupertinoAlertDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoAlertButtonsOnlyTitle,
            description: localizations.demoCupertinoAlertDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoAlertDialog-class.html',
            buildRoute: (_) => DeferredWidget(
                cupertinoLoader,
                () => cupertino_demos.CupertinoAlertDemo(
                    type: AlertDemoType.alertButtonsOnly)),
            code: CodeSegments.cupertinoAlertDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoActionSheetTitle,
            description: localizations.demoCupertinoActionSheetDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoActionSheet-class.html',
            buildRoute: (_) => DeferredWidget(
                cupertinoLoader,
                () => cupertino_demos.CupertinoAlertDemo(
                    type: AlertDemoType.actionSheet)),
            code: CodeSegments.cupertinoAlertDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoCupertinoButtonsTitle,
        icon: GalleryIcons.genericButtons,
        slug: 'cupertino-buttons',
        subtitle: localizations.demoCupertinoButtonsSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoButtonsTitle,
            description: localizations.demoCupertinoButtonsDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoButton-class.html',
            buildRoute: (_) => DeferredWidget(
              cupertinoLoader,
              () => cupertino_demos.CupertinoButtonDemo(),
            ),
            code: CodeSegments.cupertinoButtonDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoCupertinoContextMenuTitle,
        icon: GalleryIcons.moreVert,
        slug: 'cupertino-context-menu',
        subtitle: localizations.demoCupertinoContextMenuSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoContextMenuTitle,
            description: localizations.demoCupertinoContextMenuDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoContextMenu-class.html',
            buildRoute: (_) => DeferredWidget(
              cupertinoLoader,
              () => cupertino_demos.CupertinoContextMenuDemo(),
            ),
            code: CodeSegments.cupertinoContextMenuDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoCupertinoNavigationBarTitle,
        icon: GalleryIcons.bottomSheetPersistent,
        slug: 'cupertino-navigation-bar',
        subtitle: localizations.demoCupertinoNavigationBarSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoNavigationBarTitle,
            description: localizations.demoCupertinoNavigationBarDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoNavigationBar-class.html',
            buildRoute: (_) => DeferredWidget(
              cupertinoLoader,
              () => cupertino_demos.CupertinoNavigationBarDemo(),
            ),
            code: CodeSegments.cupertinoNavigationBarDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoCupertinoPickerTitle,
        icon: GalleryIcons.listAlt,
        slug: 'cupertino-picker',
        subtitle: localizations.demoCupertinoPickerSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoPickerTitle,
            description: localizations.demoCupertinoPickerDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoDatePicker-class.html',
            buildRoute: (_) => DeferredWidget(
                cupertinoLoader,
                // ignore: prefer_const_constructors
                () => cupertino_demos.CupertinoPickerDemo()),
            code: CodeSegments.cupertinoPickersDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoCupertinoScrollbarTitle,
        icon: GalleryIcons.listAlt,
        slug: 'cupertino-scrollbar',
        subtitle: localizations.demoCupertinoScrollbarSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoScrollbarTitle,
            description: localizations.demoCupertinoScrollbarDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoScrollbar-class.html',
            buildRoute: (_) => DeferredWidget(
                cupertinoLoader,
                // ignore: prefer_const_constructors
                () => cupertino_demos.CupertinoScrollbarDemo()),
            code: CodeSegments.cupertinoScrollbarDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoCupertinoSegmentedControlTitle,
        icon: GalleryIcons.tabs,
        slug: 'cupertino-segmented-control',
        subtitle: localizations.demoCupertinoSegmentedControlSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoSegmentedControlTitle,
            description: localizations.demoCupertinoSegmentedControlDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoSegmentedControl-class.html',
            buildRoute: (_) => DeferredWidget(
              cupertinoLoader,
              () => cupertino_demos.CupertinoSegmentedControlDemo(),
            ),
            code: CodeSegments.cupertinoSegmentedControlDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoCupertinoSliderTitle,
        icon: GalleryIcons.sliders,
        slug: 'cupertino-slider',
        subtitle: localizations.demoCupertinoSliderSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoSliderTitle,
            description: localizations.demoCupertinoSliderDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoSlider-class.html',
            buildRoute: (_) => DeferredWidget(
              cupertinoLoader,
              () => cupertino_demos.CupertinoSliderDemo(),
            ),
            code: CodeSegments.cupertinoSliderDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoSelectionControlsSwitchTitle,
        icon: GalleryIcons.cupertinoSwitch,
        slug: 'cupertino-switch',
        subtitle: localizations.demoCupertinoSwitchSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoSelectionControlsSwitchTitle,
            description: localizations.demoCupertinoSwitchDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoSwitch-class.html',
            buildRoute: (_) => DeferredWidget(
              cupertinoLoader,
              () => cupertino_demos.CupertinoSwitchDemo(),
            ),
            code: CodeSegments.cupertinoSwitchDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoCupertinoTabBarTitle,
        icon: GalleryIcons.bottomNavigation,
        slug: 'cupertino-tab-bar',
        subtitle: localizations.demoCupertinoTabBarSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoTabBarTitle,
            description: localizations.demoCupertinoTabBarDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoTabBar-class.html',
            buildRoute: (_) => DeferredWidget(
              cupertinoLoader,
              () => cupertino_demos.CupertinoTabBarDemo(),
            ),
            code: CodeSegments.cupertinoNavigationDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoCupertinoTextFieldTitle,
        icon: GalleryIcons.textFieldsAlt,
        slug: 'cupertino-text-field',
        subtitle: localizations.demoCupertinoTextFieldSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoTextFieldTitle,
            description: localizations.demoCupertinoTextFieldDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoTextField-class.html',
            buildRoute: (_) => DeferredWidget(
              cupertinoLoader,
              () => cupertino_demos.CupertinoTextFieldDemo(),
            ),
            code: CodeSegments.cupertinoTextFieldDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
      GalleryDemo(
        title: localizations.demoCupertinoSearchTextFieldTitle,
        icon: GalleryIcons.search,
        slug: 'cupertino-search-text-field',
        subtitle: localizations.demoCupertinoSearchTextFieldSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoCupertinoSearchTextFieldTitle,
            description: localizations.demoCupertinoSearchTextFieldDescription,
            documentationUrl:
                '$_docsBaseUrl/cupertino/CupertinoSearchTextField-class.html',
            buildRoute: (_) => DeferredWidget(
              cupertinoLoader,
              () => cupertino_demos.CupertinoSearchTextFieldDemo(),
            ),
            code: CodeSegments.cupertinoTextFieldDemo,
          ),
        ],
        category: GalleryDemoCategory.cupertino,
      ),
    ];
  }

  static List<GalleryDemo> otherDemos(GalleryLocalizations localizations) {
    return [
      GalleryDemo(
        title: localizations.demoTwoPaneTitle,
        icon: GalleryIcons.bottomSheetPersistent,
        slug: 'two-pane',
        subtitle: localizations.demoTwoPaneSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoTwoPaneFoldableLabel,
            description: localizations.demoTwoPaneFoldableDescription,
            documentationUrl:
                'https://pub.dev/documentation/dual_screen/latest/dual_screen/TwoPane-class.html',
            buildRoute: (_) => DeferredWidget(
              twopane_demo.loadLibrary,
              () => twopane_demo.TwoPaneDemo(
                type: twopane_demo.TwoPaneDemoType.foldable,
                restorationId: 'two_pane_foldable',
              ),
            ),
            code: CodeSegments.twoPaneDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoTwoPaneTabletLabel,
            description: localizations.demoTwoPaneTabletDescription,
            documentationUrl:
                'https://pub.dev/documentation/dual_screen/latest/dual_screen/TwoPane-class.html',
            buildRoute: (_) => DeferredWidget(
              twopane_demo.loadLibrary,
              () => twopane_demo.TwoPaneDemo(
                type: twopane_demo.TwoPaneDemoType.tablet,
                restorationId: 'two_pane_tablet',
              ),
            ),
            code: CodeSegments.twoPaneDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoTwoPaneSmallScreenLabel,
            description: localizations.demoTwoPaneSmallScreenDescription,
            documentationUrl:
                'https://pub.dev/documentation/dual_screen/latest/dual_screen/TwoPane-class.html',
            buildRoute: (_) => DeferredWidget(
              twopane_demo.loadLibrary,
              () => twopane_demo.TwoPaneDemo(
                type: twopane_demo.TwoPaneDemoType.smallScreen,
                restorationId: 'two_pane_single',
              ),
            ),
            code: CodeSegments.twoPaneDemo,
          ),
        ],
        category: GalleryDemoCategory.other,
      ),
      GalleryDemo(
        title: localizations.demoMotionTitle,
        icon: GalleryIcons.animation,
        slug: 'motion',
        subtitle: localizations.demoMotionSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoContainerTransformTitle,
            description: localizations.demoContainerTransformDescription,
            documentationUrl: '$_docsAnimationsUrl/OpenContainer-class.html',
            buildRoute: (_) => DeferredWidget(
              motion_demo_container.loadLibrary,
              () => motion_demo_container.OpenContainerTransformDemo(),
            ),
            code: CodeSegments.openContainerTransformDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoSharedXAxisTitle,
            description: localizations.demoSharedAxisDescription,
            documentationUrl:
                '$_docsAnimationsUrl/SharedAxisTransition-class.html',
            buildRoute: (_) => const SharedXAxisTransitionDemo(),
            code: CodeSegments.sharedXAxisTransitionDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoSharedYAxisTitle,
            description: localizations.demoSharedAxisDescription,
            documentationUrl:
                '$_docsAnimationsUrl/SharedAxisTransition-class.html',
            buildRoute: (_) => const SharedYAxisTransitionDemo(),
            code: CodeSegments.sharedYAxisTransitionDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoSharedZAxisTitle,
            description: localizations.demoSharedAxisDescription,
            documentationUrl:
                '$_docsAnimationsUrl/SharedAxisTransition-class.html',
            buildRoute: (_) => const SharedZAxisTransitionDemo(),
            code: CodeSegments.sharedZAxisTransitionDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoFadeThroughTitle,
            description: localizations.demoFadeThroughDescription,
            documentationUrl:
                '$_docsAnimationsUrl/FadeThroughTransition-class.html',
            buildRoute: (_) => const FadeThroughTransitionDemo(),
            code: CodeSegments.fadeThroughTransitionDemo,
          ),
          GalleryDemoConfiguration(
            title: localizations.demoFadeScaleTitle,
            description: localizations.demoFadeScaleDescription,
            documentationUrl:
                '$_docsAnimationsUrl/FadeScaleTransition-class.html',
            buildRoute: (_) => const FadeScaleTransitionDemo(),
            code: CodeSegments.fadeScaleTransitionDemo,
          ),
        ],
        category: GalleryDemoCategory.other,
      ),
      GalleryDemo(
        title: localizations.demoColorsTitle,
        icon: GalleryIcons.colors,
        slug: 'colors',
        subtitle: localizations.demoColorsSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoColorsTitle,
            description: localizations.demoColorsDescription,
            documentationUrl: '$_docsBaseUrl/material/MaterialColor-class.html',
            buildRoute: (_) => DeferredWidget(
              colors_demo.loadLibrary,
              () => colors_demo.ColorsDemo(),
            ),
            code: CodeSegments.colorsDemo,
          ),
        ],
        category: GalleryDemoCategory.other,
      ),
      GalleryDemo(
        title: localizations.demoTypographyTitle,
        icon: GalleryIcons.customTypography,
        slug: 'typography',
        subtitle: localizations.demoTypographySubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demoTypographyTitle,
            description: localizations.demoTypographyDescription,
            documentationUrl: '$_docsBaseUrl/material/TextTheme-class.html',
            buildRoute: (_) => DeferredWidget(
              typography.loadLibrary,
              () => typography.TypographyDemo(),
            ),
            code: CodeSegments.typographyDemo,
          ),
        ],
        category: GalleryDemoCategory.other,
      ),
      GalleryDemo(
        title: localizations.demo2dTransformationsTitle,
        icon: GalleryIcons.gridOn,
        slug: '2d-transformations',
        subtitle: localizations.demo2dTransformationsSubtitle,
        configurations: [
          GalleryDemoConfiguration(
            title: localizations.demo2dTransformationsTitle,
            description: localizations.demo2dTransformationsDescription,
            documentationUrl:
                '$_docsBaseUrl/widgets/GestureDetector-class.html',
            buildRoute: (_) => DeferredWidget(
              transformations_demo.loadLibrary,
              () => transformations_demo.TransformationsDemo(),
            ),
            code: CodeSegments.transformationsDemo,
          ),
        ],
        category: GalleryDemoCategory.other,
      ),
    ];
  }
}
